import test from 'node:test';
import assert from 'node:assert/strict';
import { createGame, submitTurn, undoLastTurn } from '../game.mjs';

test('creates a game with normalized player names and zero scores', () => {
  const game = createGame([' Ada ', 'Lin']);

  assert.deepEqual(game.players, [
    { name: 'Ada', score: 0 },
    { name: 'Lin', score: 0 },
  ]);
  assert.equal(game.currentPlayerIndex, 0);
  assert.deepEqual(game.turns, []);
});

test('requires two to four non-empty player names', () => {
  assert.throws(() => createGame(['Ada']), /two|2/i);
  assert.throws(() => createGame(['Ada', '  ']), /name/i);
  assert.throws(() => createGame(['A', 'B', 'C', 'D', 'E']), /four|4/i);
});

test("submits a turn, updates the player's total, and advances the turn", () => {
  const started = createGame(['Ada', 'Lin']);
  const next = submitTurn(started, { word: 'CAT', points: 5 });

  assert.deepEqual(next.players.map(player => player.score), [5, 0]);
  assert.equal(next.turns.length, 1);
  assert.deepEqual(next.turns[0], { playerIndex: 0, word: 'CAT', points: 5 });
  assert.equal(next.currentPlayerIndex, 1);
});

test('rotates back to the first player after every player has taken a turn', () => {
  const started = createGame(['Ada', 'Lin']);
  const afterAda = submitTurn(started, { word: 'CAT', points: 5 });
  const afterLin = submitTurn(afterAda, { word: 'DOG', points: 6 });

  assert.equal(afterLin.currentPlayerIndex, 0);
  assert.deepEqual(afterLin.players.map(player => player.score), [5, 6]);
});

test('undoes the last turn, restores the score, and returns turn to that player', () => {
  const started = createGame(['Ada', 'Lin']);
  const afterAda = submitTurn(started, { word: 'CAT', points: 5 });
  const afterLin = submitTurn(afterAda, { word: 'DOG', points: 6 });
  const undone = undoLastTurn(afterLin);

  assert.deepEqual(undone.players.map(player => player.score), [5, 0]);
  assert.equal(undone.turns.length, 1);
  assert.equal(undone.currentPlayerIndex, 1);
});

test('rejects invalid turn points and undo when the history is empty', () => {
  const game = createGame(['Ada', 'Lin']);

  assert.throws(() => submitTurn(game, { word: 'CAT', points: -1 }), /points/i);
  assert.throws(() => submitTurn(game, { word: 'CAT', points: 1.5 }), /points/i);
  assert.throws(() => undoLastTurn(game), /turn/i);
});
