import 'package:flutter_test/flutter_test.dart';
import '../lib/domain/game.dart';

void main() {
  group('game turns', () {
    test('starts with normalized players and zero scores', () {
      final game = createGame([' Ada ', 'Lin']);

      expect(game.players.map((player) => player.name), ['Ada', 'Lin']);
      expect(game.players.map((player) => player.score), [0, 0]);
      expect(game.currentPlayerIndex, 0);
      expect(game.turns, isEmpty);
    });

    test('requires two to four named players', () {
      expect(() => createGame(['Ada']), throwsArgumentError);
      expect(() => createGame(['Ada', '  ']), throwsArgumentError);
      expect(() => createGame(['A', 'B', 'C', 'D', 'E']), throwsArgumentError);
    });

    test('submits a turn, updates its player, and advances turn order', () {
      final game = createGame(['Ada', 'Lin']);
      final next = submitTurn(game, word: 'cat', points: 5);

      expect(next.players.map((player) => player.score), [5, 0]);
      expect(next.turns.single.word, 'CAT');
      expect(next.turns.single.points, 5);
      expect(next.currentPlayerIndex, 1);
    });

    test('wraps turn order after every player has played', () {
      final first = createGame(['Ada', 'Lin']);
      final second = submitTurn(first, word: 'CAT', points: 5);
      final third = submitTurn(second, word: 'DOG', points: 6);

      expect(third.currentPlayerIndex, 0);
      expect(third.players.map((player) => player.score), [5, 6]);
    });

    test('undoes the last turn and restores score and turn order', () {
      final first = createGame(['Ada', 'Lin']);
      final second = submitTurn(first, word: 'CAT', points: 5);
      final third = submitTurn(second, word: 'DOG', points: 6);
      final undone = undoLastTurn(third);

      expect(undone.players.map((player) => player.score), [5, 0]);
      expect(undone.turns, hasLength(1));
      expect(undone.currentPlayerIndex, 1);
    });

    test('rejects invalid points and undo on empty history', () {
      final game = createGame(['Ada', 'Lin']);

      expect(
        () => submitTurn(game, word: 'CAT', points: -1),
        throwsArgumentError,
      );
      expect(
        () => submitTurn(game, word: 'CAT', points: 1.5),
        throwsArgumentError,
      );
      expect(() => undoLastTurn(game), throwsStateError);
    });
  });
}
