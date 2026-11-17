class PlayerScore {
  const PlayerScore({required this.name, required this.score});

  final String name;
  final int score;

  PlayerScore copyWith({String? name, int? score}) =>
      PlayerScore(name: name ?? this.name, score: score ?? this.score);
}

class PlayedTurn {
  const PlayedTurn({
    required this.playerIndex,
    required this.word,
    required this.points,
  });

  final int playerIndex;
  final String word;
  final int points;
}

class GameState {
  const GameState({
    required this.players,
    required this.turns,
    required this.currentPlayerIndex,
  });

  final List<PlayerScore> players;
  final List<PlayedTurn> turns;
  final int currentPlayerIndex;
}

GameState createGame(List<String> names) {
  if (names.length < 2 || names.length > 4) {
    throw ArgumentError('A game needs two to four players.');
  }
  final normalizedNames = names.map((name) => name.trim()).toList();
  if (normalizedNames.any((name) => name.isEmpty)) {
    throw ArgumentError('Every player needs a name.');
  }

  return GameState(
    players: List.unmodifiable(
      normalizedNames.map((name) => PlayerScore(name: name, score: 0)),
    ),
    turns: const [],
    currentPlayerIndex: 0,
  );
}

GameState submitTurn(
  GameState game, {
  required String word,
  required num points,
}) {
  if (game.players.isEmpty) throw ArgumentError('A game needs players.');
  if (word.trim().isEmpty)
    throw ArgumentError.value(word, 'word', 'A word is required.');
  if (points is! int || points < 0) {
    throw ArgumentError.value(
      points,
      'points',
      'Turn points must be a non-negative whole number.',
    );
  }

  final playerIndex = game.currentPlayerIndex;
  final players = [...game.players];
  players[playerIndex] = players[playerIndex].copyWith(
    score: players[playerIndex].score + points,
  );

  return GameState(
    players: List.unmodifiable(players),
    turns: List.unmodifiable([
      ...game.turns,
      PlayedTurn(
        playerIndex: playerIndex,
        word: word.trim().toUpperCase(),
        points: points,
      ),
    ]),
    currentPlayerIndex: (playerIndex + 1) % players.length,
  );
}

GameState undoLastTurn(GameState game) {
  if (game.turns.isEmpty) throw StateError('There is no turn to undo.');
  final lastTurn = game.turns.last;
  final players = [...game.players];
  players[lastTurn.playerIndex] = players[lastTurn.playerIndex].copyWith(
    score: players[lastTurn.playerIndex].score - lastTurn.points,
  );

  return GameState(
    players: List.unmodifiable(players),
    turns: List.unmodifiable(game.turns.take(game.turns.length - 1)),
    currentPlayerIndex: lastTurn.playerIndex,
  );
}
