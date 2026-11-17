import 'package:flutter_test/flutter_test.dart';
import '../lib/domain/score.dart';

void main() {
  group('calculateWordScore', () {
    test('scores standard English tile values', () {
      final score = calculateWordScore(word: 'quiz');

      expect(score.normalizedWord, 'QUIZ');
      expect(score.tileScores, [10, 1, 1, 10]);
      expect(score.letterSubtotal, 22);
      expect(score.total, 22);
    });

    test('trims surrounding whitespace and ignores letter case', () {
      final score = calculateWordScore(word: '  Cat  ');

      expect(score.normalizedWord, 'CAT');
      expect(score.total, 5);
    });

    test('scores blank tiles as zero', () {
      final score = calculateWordScore(word: 'CAT', blankIndexes: {1});

      expect(score.tileScores, [3, 0, 1]);
      expect(score.total, 4);
    });

    test('applies letter premiums before a word premium', () {
      final score = calculateWordScore(
        word: 'CAT',
        letterMultipliers: [1, 2, 3],
        wordMultiplier: 2,
      );

      expect(score.scoredTileValues, [3, 2, 3]);
      expect(score.letterSubtotal, 8);
      expect(score.wordSubtotal, 16);
      expect(score.total, 16);
    });

    test('adds a seven-tile bonus after the word multiplier', () {
      final score = calculateWordScore(
        word: 'EXAMPLE',
        wordMultiplier: 3,
        bingo: true,
      );

      expect(score.letterSubtotal, 18);
      expect(score.wordSubtotal, 54);
      expect(score.bingoBonus, 50);
      expect(score.total, 104);
    });

    test('rejects empty words and non-English letters', () {
      expect(() => calculateWordScore(word: '   '), throwsArgumentError);
      expect(() => calculateWordScore(word: 'word!'), throwsArgumentError);
      expect(() => calculateWordScore(word: 'café'), throwsArgumentError);
    });

    test('rejects invalid blank indexes and multipliers', () {
      expect(
        () => calculateWordScore(word: 'CAT', blankIndexes: {-1}),
        throwsArgumentError,
      );
      expect(
        () => calculateWordScore(word: 'CAT', letterMultipliers: [1, 2]),
        throwsArgumentError,
      );
      expect(
        () => calculateWordScore(word: 'CAT', wordMultiplier: 4),
        throwsArgumentError,
      );
      expect(
        () => calculateWordScore(word: 'CAT', bingo: true),
        throwsArgumentError,
      );
    });
  });
}
