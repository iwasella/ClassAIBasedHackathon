export const LETTER_VALUES = Object.freeze({
  A: 1, B: 3, C: 3, D: 2, E: 1, F: 4, G: 2, H: 4, I: 1, J: 8,
  K: 5, L: 1, M: 3, N: 1, O: 1, P: 3, Q: 10, R: 1, S: 1, T: 1,
  U: 1, V: 4, W: 4, X: 8, Y: 4, Z: 10,
});

const isIntegerIn = (value, allowed) => Number.isInteger(value) && allowed.includes(value);

export function calculateWordScore({
  word,
  blankIndexes = [],
  letterMultipliers,
  wordMultiplier = 1,
  bingo = false,
}) {
  if (typeof word !== 'string') throw new TypeError('Word must be text.');
  const normalizedWord = word.trim().toUpperCase();
  if (!normalizedWord) throw new Error('Word cannot be empty.');
  if (!/^[A-Z]+$/.test(normalizedWord)) throw new Error('Word must contain English letters only.');
  if (!Array.isArray(blankIndexes)) throw new TypeError('Blank tile indexes must be a list.');
  if (new Set(blankIndexes).size !== blankIndexes.length || blankIndexes.some(index => !Number.isInteger(index) || index < 0 || index >= normalizedWord.length)) {
    throw new Error('Blank tile indexes must be unique positions in the word.');
  }
  if (!isIntegerIn(wordMultiplier, [1, 2, 3])) throw new Error('Word multiplier must be 1, 2, or 3.');
  if (typeof bingo !== 'boolean') throw new TypeError('Seven-tile bonus must be on or off.');
  if (bingo && normalizedWord.length !== 7) throw new Error('Seven-tile bonus requires exactly seven tiles.');

  const multipliers = letterMultipliers ?? Array(normalizedWord.length).fill(1);
  if (!Array.isArray(multipliers) || multipliers.length !== normalizedWord.length || multipliers.some(value => !isIntegerIn(value, [1, 2, 3]))) {
    throw new Error('Letter multipliers must contain one value of 1, 2, or 3 per letter.');
  }

  const blankSet = new Set(blankIndexes);
  const tileScores = [...normalizedWord].map((letter, index) => blankSet.has(index) ? 0 : LETTER_VALUES[letter]);
  const scoredTileValues = tileScores.map((value, index) => value * multipliers[index]);
  const letterSubtotal = scoredTileValues.reduce((sum, value) => sum + value, 0);
  const wordSubtotal = letterSubtotal * wordMultiplier;
  const bingoBonus = bingo ? 50 : 0;

  return {
    normalizedWord,
    tileScores,
    scoredTileValues,
    letterSubtotal,
    wordMultiplier,
    wordSubtotal,
    bingoBonus,
    total: wordSubtotal + bingoBonus,
  };
}
