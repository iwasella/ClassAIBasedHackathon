import { calculateWordScore, LETTER_VALUES } from './score.mjs';
import { createGame, submitTurn, undoLastTurn } from './game.mjs';

const setupScreen = document.querySelector('#setup-screen');
const gameScreen = document.querySelector('#game-screen');
const setupForm = document.querySelector('#setup-form');
const playerInputs = document.querySelector('#player-inputs');
const setupCount = document.querySelector('#setup-count');
const setupError = document.querySelector('#setup-error');
const addPlayerButton = document.querySelector('#add-player-button');
const newGameButton = document.querySelector('#new-game-button');
const scoreList = document.querySelector('#score-list');
const roundCount = document.querySelector('#round-count');
const currentPlayerLabel = document.querySelector('#current-player-label');
const turnForm = document.querySelector('#turn-form');
const wordInput = document.querySelector('#word-input');
const tileSettings = document.querySelector('#tile-settings');
const tileCount = document.querySelector('#tile-count');
const wordMultiplierInput = document.querySelector('#word-multiplier');
const bingoCheckbox = document.querySelector('#bingo-checkbox');
const scorePreview = document.querySelector('#score-preview');
const turnError = document.querySelector('#turn-error');
const submitTurnButton = document.querySelector('#submit-turn-button');
const turnHistory = document.querySelector('#turn-history');
const undoButton = document.querySelector('#undo-button');

let game = null;
let blankIndexes = new Set();
let letterMultipliers = [];

function makeElement(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function renderPlayerInputs(names = ['Player 1', 'Player 2']) {
  playerInputs.replaceChildren();
  names.forEach((name, index) => {
    const row = makeElement('div', 'player-input-row');
    row.append(makeElement('span', 'player-number', String(index + 1).padStart(2, '0')));
    const input = makeElement('input', 'player-name-input');
    input.type = 'text';
    input.name = 'player';
    input.maxLength = 24;
    input.autocomplete = 'off';
    input.placeholder = `Player ${index + 1}`;
    input.value = name.startsWith('Player ') ? '' : name;
    input.setAttribute('aria-label', `Player ${index + 1} name`);
    row.append(input);
    if (index > 1) {
      const removeButton = makeElement('button', 'remove-player', '×');
      removeButton.type = 'button';
      removeButton.setAttribute('aria-label', `Remove player ${index + 1}`);
      removeButton.addEventListener('click', () => {
        const currentNames = [...playerInputs.querySelectorAll('input')].map(item => item.value);
        currentNames.splice(index, 1);
        renderPlayerInputs(currentNames);
      });
      row.append(removeButton);
    }
    playerInputs.append(row);
  });
  setupCount.textContent = `${String(names.length).padStart(2, '0')} / 04`;
  addPlayerButton.hidden = names.length >= 4;
}

function readPlayerNames() {
  return [...playerInputs.querySelectorAll('input')].map(input => input.value.trim());
}

function renderScoreboard() {
  if (!game) return;
  scoreList.replaceChildren();
  game.players.forEach((player, index) => {
    const isCurrent = index === game.currentPlayerIndex;
    const row = makeElement('div', `score-row${isCurrent ? ' is-current' : ''}`);
    const playerBlock = makeElement('div', 'score-player');
    const avatar = makeElement('span', 'player-avatar', player.name.trim().charAt(0).toUpperCase());
    avatar.setAttribute('aria-hidden', 'true');
    const nameBlock = makeElement('div', 'player-name-block');
    nameBlock.append(makeElement('div', 'score-player-name', player.name));
    nameBlock.append(makeElement('div', 'player-status', isCurrent ? 'UP NEXT' : 'IN THE GAME'));
    playerBlock.append(avatar, nameBlock);
    const total = makeElement('div', 'player-total-block');
    total.append(makeElement('div', 'player-total', String(player.score)));
    total.append(makeElement('div', 'player-points-label', 'POINTS'));
    row.append(playerBlock, total);
    scoreList.append(row);
  });

  currentPlayerLabel.textContent = game.players[game.currentPlayerIndex].name.toUpperCase();
  roundCount.textContent = `ROUND ${String(Math.floor(game.turns.length / game.players.length) + 1).padStart(2, '0')}`;
  undoButton.disabled = game.turns.length === 0;
  renderHistory();
}

function renderHistory() {
  turnHistory.replaceChildren();
  if (game.turns.length === 0) {
    turnHistory.append(makeElement('p', 'history-empty', 'Your plays will show up here.'));
    return;
  }
  game.turns.slice().reverse().forEach((turn, reverseIndex) => {
    const index = game.turns.length - reverseIndex;
    const row = makeElement('div', 'history-row');
    const number = makeElement('span', 'history-number', String(index).padStart(2, '0'));
    const detail = makeElement('div', 'history-detail');
    detail.append(makeElement('div', 'history-word', turn.word));
    detail.append(makeElement('div', 'history-player', game.players[turn.playerIndex].name));
    row.append(number, detail, makeElement('strong', 'history-points', `+${turn.points}`));
    turnHistory.append(row);
  });
}

function updateTileSettings() {
  const word = wordInput.value.trim().toUpperCase();
  const letters = [...word];
  tileCount.textContent = `${letters.length} ${letters.length === 1 ? 'TILE' : 'TILES'}`;
  bingoCheckbox.disabled = letters.length !== 7;
  if (letters.length !== 7) bingoCheckbox.checked = false;
  blankIndexes = new Set([...blankIndexes].filter(index => index < letters.length));
  letterMultipliers = letters.map((_, index) => [1, 2, 3].includes(letterMultipliers[index]) ? letterMultipliers[index] : 1);

  if (letters.length === 0) {
    tileSettings.replaceChildren(makeElement('p', 'tile-prompt', 'Type a word above to set tile values.'));
    updatePreview();
    return;
  }

  tileSettings.replaceChildren();
  letters.forEach((letter, index) => {
    const isBlank = blankIndexes.has(index);
    const card = makeElement('div', `tile-setting${isBlank ? ' is-blank' : ''}`);
    const face = makeElement('span', 'tile-face');
    face.append(makeElement('b', '', letter));
    face.append(makeElement('small', '', String(isBlank ? 0 : LETTER_VALUES[letter])));
    const blankToggle = makeElement('button', 'blank-toggle', isBlank ? 'BLANK' : 'TILE');
    blankToggle.type = 'button';
    blankToggle.setAttribute('aria-label', `${isBlank ? 'Use letter value for' : 'Mark as blank'} tile ${index + 1} (${letter})`);
    blankToggle.setAttribute('aria-pressed', String(isBlank));
    blankToggle.addEventListener('click', () => {
      if (blankIndexes.has(index)) blankIndexes.delete(index);
      else blankIndexes.add(index);
      updateTileSettings();
    });
    const multiplier = document.createElement('select');
    multiplier.className = 'letter-multiplier';
    multiplier.setAttribute('aria-label', `Letter multiplier for tile ${index + 1}`);
    for (const value of [1, 2, 3]) {
      const option = document.createElement('option');
      option.value = String(value);
      option.textContent = value === 1 ? '×1' : `×${value}L`;
      multiplier.append(option);
    }
    multiplier.value = String(letterMultipliers[index]);
    multiplier.addEventListener('change', () => {
      letterMultipliers[index] = Number(multiplier.value);
      updatePreview();
    });
    card.append(face, blankToggle, multiplier);
    tileSettings.append(card);
  });
  updatePreview();
}

function updatePreview() {
  const word = wordInput.value.trim();
  const breakdown = scorePreview.querySelector('.preview-breakdown span:last-child');
  const total = scorePreview.querySelector('.preview-total strong');
  if (!word) {
    breakdown.textContent = '—';
    total.textContent = '0';
    submitTurnButton.disabled = true;
    turnError.textContent = '';
    return;
  }
  try {
    const result = calculateWordScore({
      word,
      blankIndexes: [...blankIndexes],
      letterMultipliers,
      wordMultiplier: Number(wordMultiplierInput.value),
      bingo: bingoCheckbox.checked,
    });
    const parts = [`${result.letterSubtotal} letters`];
    if (result.wordMultiplier > 1) parts.push(`×${result.wordMultiplier} word`);
    if (result.bingoBonus) parts.push('+50 seven-tile');
    breakdown.textContent = `${parts.join('  ·  ')} = ${result.total}`;
    total.textContent = String(result.total);
    submitTurnButton.disabled = false;
    turnError.textContent = '';
  } catch (error) {
    breakdown.textContent = 'Check your word and bonuses';
    total.textContent = '—';
    submitTurnButton.disabled = true;
    turnError.textContent = error.message;
  }
}

function resetTurnForm() {
  turnForm.reset();
  blankIndexes = new Set();
  letterMultipliers = [];
  turnError.textContent = '';
  updateTileSettings();
  wordInput.focus();
}

addPlayerButton.addEventListener('click', () => {
  const names = readPlayerNames();
  if (names.length < 4) {
    names.push('');
    renderPlayerInputs(names);
    playerInputs.querySelectorAll('input').at(-1)?.focus();
  }
});

setupForm.addEventListener('submit', event => {
  event.preventDefault();
  setupError.textContent = '';
  try {
    game = createGame(readPlayerNames());
    setupScreen.hidden = true;
    gameScreen.hidden = false;
    renderScoreboard();
    wordInput.focus();
  } catch (error) {
    setupError.textContent = error.message;
  }
});

wordInput.addEventListener('input', updateTileSettings);
wordMultiplierInput.addEventListener('change', updatePreview);
bingoCheckbox.addEventListener('change', updatePreview);

turnForm.addEventListener('submit', event => {
  event.preventDefault();
  turnError.textContent = '';
  try {
    const result = calculateWordScore({
      word: wordInput.value,
      blankIndexes: [...blankIndexes],
      letterMultipliers,
      wordMultiplier: Number(wordMultiplierInput.value),
      bingo: bingoCheckbox.checked,
    });
    game = submitTurn(game, { word: result.normalizedWord, points: result.total });
    renderScoreboard();
    resetTurnForm();
  } catch (error) {
    turnError.textContent = error.message;
  }
});

undoButton.addEventListener('click', () => {
  try {
    game = undoLastTurn(game);
    renderScoreboard();
    resetTurnForm();
  } catch (error) {
    turnError.textContent = error.message;
  }
});

newGameButton.addEventListener('click', () => {
  game = null;
  turnForm.reset();
  setupForm.reset();
  setupError.textContent = '';
  turnError.textContent = '';
  blankIndexes = new Set();
  letterMultipliers = [];
  updateTileSettings();
  renderPlayerInputs();
  setupScreen.hidden = false;
  gameScreen.hidden = true;
  document.querySelector('#setup-form input').focus();
});

renderPlayerInputs();
