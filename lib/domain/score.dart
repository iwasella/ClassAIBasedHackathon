const letterValues = <String, int>{
  'A': 1,
  'B': 3,
  'C': 3,
  'D': 2,
  'E': 1,
  'F': 4,
  'G': 2,
  'H': 4,
  'I': 1,
  'J': 8,
  'K': 5,
  'L': 1,
  'M': 3,
  'N': 1,
  'O': 1,
  'P': 3,
  'Q': 10,
  'R': 1,
  'S': 1,
  'T': 1,
  'U': 1,
  'V': 4,
  'W': 4,
  'X': 8,
  'Y': 4,
  'Z': 10,
};

class WordScore {
  const WordScore({
    required this.normalizedWord,
    required this.tileScores,
    required this.scoredTileValues,
    required this.letterSubtotal,
    required this.wordMultiplier,
    required this.wordSubtotal,
    required this.bingoBonus,
    required this.total,
  });

  final String normalizedWord;
  final List<int> tileScores;
  final List<int> scoredTileValues;
  final int letterSubtotal;
  final int wordMultiplier;
  final int wordSubtotal;
  final int bingoBonus;
  final int total;
}

WordScore calculateWordScore({
  required String word,
  Set<int> blankIndexes = const {},
  List<int>? letterMultipliers,
  int wordMultiplier = 1,
  bool bingo = false,
}) {
  final normalizedWord = word.trim().toUpperCase();
  if (normalizedWord.isEmpty) {
    throw ArgumentError.value(word, 'word', 'Word cannot be empty.');
  }
  if (!RegExp(r'^[A-Z]+$').hasMatch(normalizedWord)) {
    throw ArgumentError.value(word, 'word', 'Use English letters only.');
  }
  if (blankIndexes.any(
    (index) => index < 0 || index >= normalizedWord.length,
  )) {
    throw ArgumentError.value(
      blankIndexes,
      'blankIndexes',
      'Blank tile positions must be within the word.',
    );
  }
  if (![1, 2, 3].contains(wordMultiplier)) {
    throw ArgumentError.value(
      wordMultiplier,
      'wordMultiplier',
      'Use a word multiplier of 1, 2, or 3.',
    );
  }
  if (bingo && normalizedWord.length != 7) {
    throw ArgumentError('The seven-tile bonus requires exactly seven tiles.');
  }

  final multipliers =
      letterMultipliers ?? List<int>.filled(normalizedWord.length, 1);
  if (multipliers.length != normalizedWord.length ||
      multipliers.any((multiplier) => ![1, 2, 3].contains(multiplier))) {
    throw ArgumentError.value(
      letterMultipliers,
      'letterMultipliers',
      'Use one multiplier of 1, 2, or 3 per letter.',
    );
  }

  final tileScores = <int>[];
  final scoredTileValues = <int>[];
  for (var index = 0; index < normalizedWord.length; index++) {
    final value = blankIndexes.contains(index)
        ? 0
        : letterValues[normalizedWord[index]]!;
    tileScores.add(value);
    scoredTileValues.add(value * multipliers[index]);
  }

  final letterSubtotal = scoredTileValues.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  final wordSubtotal = letterSubtotal * wordMultiplier;
  final bingoBonus = bingo ? 50 : 0;

  return WordScore(
    normalizedWord: normalizedWord,
    tileScores: List.unmodifiable(tileScores),
    scoredTileValues: List.unmodifiable(scoredTileValues),
    letterSubtotal: letterSubtotal,
    wordMultiplier: wordMultiplier,
    wordSubtotal: wordSubtotal,
    bingoBonus: bingoBonus,
    total: wordSubtotal + bingoBonus,
  );
}
