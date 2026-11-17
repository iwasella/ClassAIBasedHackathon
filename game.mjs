export function createGame(names) {
  if (!Array.isArray(names) || names.length < 2 || names.length > 4) {
    throw new Error('A game needs two to four players.');
  }
  const normalizedNames = names.map(name => typeof name === 'string' ? name.trim() : '');
  if (normalizedNames.some(name => !name)) throw new Error('Every player needs a name.');

  return {
    players: normalizedNames.map(name => ({ name, score: 0 })),
    turns: [],
    currentPlayerIndex: 0,
  };
}

export function submitTurn(game, { word, points }) {
  if (!game || !Array.isArray(game.players) || !Array.isArray(game.turns)) throw new TypeError('A game is required.');
  if (typeof word !== 'string' || !word.trim()) throw new Error('A word is required for each turn.');
  if (!Number.isInteger(points) || points < 0) throw new Error('Turn points must be a non-negative whole number.');
  const playerIndex = game.currentPlayerIndex;
  const turn = { playerIndex, word: word.trim().toUpperCase(), points };
  const players = game.players.map((player, index) => index === playerIndex
    ? { ...player, score: player.score + points }
    : player);

  return {
    ...game,
    players,
    turns: [...game.turns, turn],
    currentPlayerIndex: (playerIndex + 1) % players.length,
  };
}

export function undoLastTurn(game) {
  if (!game || !Array.isArray(game.turns) || game.turns.length === 0) throw new Error('There is no turn to undo.');
  const turns = game.turns.slice(0, -1);
  const lastTurn = game.turns.at(-1);
  const players = game.players.map((player, index) => index === lastTurn.playerIndex
    ? { ...player, score: player.score - lastTurn.points }
    : player);

  return {
    ...game,
    players,
    turns,
    currentPlayerIndex: lastTurn.playerIndex,
  };
}
