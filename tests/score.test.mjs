import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateWordScore } from '../score.mjs';

test('scores letters using standard English tile values without bonuses', () => {
  const result = calculateWordScore({ word: 'quiz' });

  assert.equal(result.normalizedWord, 'QUIZ');
  assert.deepEqual(result.tileScores, [10, 1, 1, 10]);
  assert.equal(result.letterSubtotal, 22);
  assert.equal(result.total, 22);
});

test('scores words without case sensitivity and trims surrounding whitespace', () => {
  const result = calculateWordScore({ word: '  Cat  ' });

  assert.equal(result.normalizedWord, 'CAT');
  assert.equal(result.total, 5);
});

test('scores a blank tile as zero while retaining the represented letter', () => {
  const result = calculateWordScore({ word: 'CAT', blankIndexes: [1] });

  assert.deepEqual(result.tileScores, [3, 0, 1]);
  assert.equal(result.total, 4);
});

test('applies letter premiums before the word premium', () => {
  const result = calculateWordScore({
    word: 'CAT',
    letterMultipliers: [1, 2, 3],
    wordMultiplier: 2,
  });

  assert.deepEqual(result.scoredTileValues, [3, 2, 3]);
  assert.equal(result.letterSubtotal, 8);
  assert.equal(result.wordSubtotal, 16);
  assert.equal(result.total, 16);
});

test('adds the seven-tile bonus after word multipliers', () => {
  const result = calculateWordScore({ word: 'EXAMPLE', wordMultiplier: 3, bingo: true });

  assert.equal(result.letterSubtotal, 18);
  assert.equal(result.wordSubtotal, 54);
  assert.equal(result.bingoBonus, 50);
  assert.equal(result.total, 104);
});

test('rejects an empty word', () => {
  assert.throws(() => calculateWordScore({ word: '   ' }), /word/i);
});

test('rejects non-English letters and punctuation', () => {
  assert.throws(() => calculateWordScore({ word: 'word!' }), /letters/i);
  assert.throws(() => calculateWordScore({ word: 'café' }), /letters/i);
});

test('rejects invalid blank indexes and duplicate blank indexes', () => {
  assert.throws(() => calculateWordScore({ word: 'CAT', blankIndexes: [-1] }), /blank/i);
  assert.throws(() => calculateWordScore({ word: 'CAT', blankIndexes: [0, 0] }), /blank/i);
});

test('rejects invalid letter or word multipliers', () => {
  assert.throws(() => calculateWordScore({ word: 'CAT', letterMultipliers: [1, 2] }), /multiplier/i);
  assert.throws(() => calculateWordScore({ word: 'CAT', letterMultipliers: [1, 4, 1] }), /multiplier/i);
  assert.throws(() => calculateWordScore({ word: 'CAT', wordMultiplier: 4 }), /multiplier/i);
});

test('rejects seven-tile bonus when the played word has fewer than seven tiles', () => {
  assert.throws(() => calculateWordScore({ word: 'CAT', bingo: true }), /seven|7/i);
});
