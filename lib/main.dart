import 'package:flutter/material.dart';

import 'domain/game.dart';
import 'domain/score.dart';

const _paper = Color(0xFFF4F3EE);
const _card = Color(0xFFFFFEFA);
const _ink = Color(0xFF17251F);
const _muted = Color(0xFF707B73);
const _green = Color(0xFF145B42);
const _line = Color(0xFFE5E5DC);

void main() => runApp(const LettercountApp());

class LettercountApp extends StatelessWidget {
  const LettercountApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lettercount',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(seedColor: _green),
      appBarTheme: const AppBarTheme(
        backgroundColor: _paper,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    ),
    home: const ScorekeeperPage(),
  );
}

class ScorekeeperPage extends StatefulWidget {
  const ScorekeeperPage({super.key});

  @override
  State<ScorekeeperPage> createState() => _ScorekeeperPageState();
}

class _ScorekeeperPageState extends State<ScorekeeperPage> {
  final List<TextEditingController> _playerControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _wordController = TextEditingController();
  final Set<int> _blankIndexes = {};
  List<int> _letterMultipliers = [];
  GameState? _game;
  int _wordMultiplier = 1;
  bool _bingo = false;
  String? _setupError;
  String? _turnError;

  @override
  void dispose() {
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    _wordController.dispose();
    super.dispose();
  }

  void _onWordChanged(String value) {
    final length = value.trim().length;
    setState(() {
      _blankIndexes.removeWhere((index) => index >= length);
      _letterMultipliers = List.generate(
        length,
        (index) =>
            index < _letterMultipliers.length ? _letterMultipliers[index] : 1,
      );
      if (length != 7) _bingo = false;
      _turnError = null;
    });
  }

  WordScore? get _preview {
    final word = _wordController.text.trim();
    if (word.isEmpty) return null;
    try {
      return calculateWordScore(
        word: word,
        blankIndexes: _blankIndexes,
        letterMultipliers: _letterMultipliers,
        wordMultiplier: _wordMultiplier,
        bingo: _bingo,
      );
    } on ArgumentError {
      return null;
    }
  }

  void _startGame() {
    try {
      final nextGame = createGame(
        _playerControllers.map((controller) => controller.text).toList(),
      );
      setState(() {
        _game = nextGame;
        _setupError = null;
      });
    } on ArgumentError catch (error) {
      setState(() => _setupError = error.message.toString());
    }
  }

  void _addPlayer() {
    if (_playerControllers.length >= 4) return;
    setState(() => _playerControllers.add(TextEditingController()));
  }

  void _removePlayer(int index) {
    if (_playerControllers.length <= 2) return;
    setState(() {
      _playerControllers.removeAt(index).dispose();
    });
  }

  void _toggleBlank(int index) {
    setState(() {
      if (!_blankIndexes.add(index)) _blankIndexes.remove(index);
    });
  }

  void _setLetterMultiplier(int index, int value) {
    setState(() => _letterMultipliers[index] = value);
  }

  void _submitTurn() {
    final currentGame = _game;
    if (currentGame == null) return;
    try {
      final score = calculateWordScore(
        word: _wordController.text,
        blankIndexes: _blankIndexes,
        letterMultipliers: _letterMultipliers,
        wordMultiplier: _wordMultiplier,
        bingo: _bingo,
      );
      final nextGame = submitTurn(
        currentGame,
        word: score.normalizedWord,
        points: score.total,
      );
      setState(() {
        _game = nextGame;
        _blankIndexes.clear();
        _letterMultipliers = [];
        _wordMultiplier = 1;
        _bingo = false;
        _turnError = null;
        _wordController.clear();
      });
      FocusScope.of(context).unfocus();
    } on ArgumentError catch (error) {
      setState(() => _turnError = error.message.toString());
    }
  }

  void _undoTurn() {
    final currentGame = _game;
    if (currentGame == null) return;
    try {
      final previousGame = undoLastTurn(currentGame);
      setState(() {
        _game = previousGame;
        _blankIndexes.clear();
        _letterMultipliers = [];
        _wordMultiplier = 1;
        _bingo = false;
        _turnError = null;
        _wordController.clear();
      });
    } on StateError catch (error) {
      setState(() => _turnError = error.message);
    }
  }

  void _newGame() {
    setState(() {
      _game = null;
      _blankIndexes.clear();
      _letterMultipliers = [];
      _wordMultiplier = 1;
      _bingo = false;
      _setupError = null;
      _turnError = null;
      _wordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const _Brand(),
        actions: [
          if (game != null)
            TextButton.icon(
              onPressed: _newGame,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('New game'),
              style: TextButton.styleFrom(foregroundColor: _muted),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, _) {
            final content = game == null
                ? _SetupScreen(
                    controllers: _playerControllers,
                    error: _setupError,
                    onAddPlayer: _addPlayer,
                    onRemovePlayer: _removePlayer,
                    onStart: _startGame,
                  )
                : _GameScreen(
                    game: game,
                    wordController: _wordController,
                    blankIndexes: _blankIndexes,
                    letterMultipliers: _letterMultipliers,
                    wordMultiplier: _wordMultiplier,
                    bingo: _bingo,
                    preview: _preview,
                    error: _turnError,
                    onWordChanged: _onWordChanged,
                    onToggleBlank: _toggleBlank,
                    onLetterMultiplierChanged: _setLetterMultiplier,
                    onWordMultiplierChanged: (value) =>
                        setState(() => _wordMultiplier = value),
                    onBingoChanged: (value) => setState(() => _bingo = value),
                    onSubmit: _submitTurn,
                    onUndo: _undoTurn,
                  );

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.stacked_bar_chart_rounded,
          color: Color(0xFFD4EE87),
          size: 18,
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        'lettercount',
        style: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
      ),
    ],
  );
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({
    required this.controllers,
    required this.error,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    required this.onStart,
  });

  final List<TextEditingController> controllers;
  final String? error;
  final VoidCallback onAddPlayer;
  final ValueChanged<int> onRemovePlayer;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;
    const intro = _Intro();
    final setup = _SetupCard(
      controllers: controllers,
      error: error,
      onAddPlayer: onAddPlayer,
      onRemovePlayer: onRemovePlayer,
      onStart: onStart,
    );

    if (!wide)
      return Column(children: [intro, const SizedBox(height: 24), setup]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: _Intro()),
        const SizedBox(width: 54),
        SizedBox(width: 420, child: setup),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(label: 'MADE FOR GAME NIGHT'),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.02,
              letterSpacing: -2.2,
              color: _ink,
            ),
            children: const [
              TextSpan(text: 'Make every\n'),
              TextSpan(
                text: 'letter count.',
                style: TextStyle(color: _green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'A little less math. A lot more wordplay. Add your players and let the points take care of themselves.',
          style: TextStyle(color: _muted, height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 30),
        const _TileStillLife(),
      ],
    ),
  );
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.controllers,
    required this.error,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    required this.onStart,
  });

  final List<TextEditingController> controllers;
  final String? error;
  final VoidCallback onAddPlayer;
  final ValueChanged<int> onRemovePlayer;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(label: 'NEW GAME'),
        const SizedBox(height: 7),
        Text(
          'Who\'s playing?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add 2–4 players to get started.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 22),
        for (var index = 0; index < controllers.length; index++) ...[
          Row(
            children: [
              Container(
                width: 32,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  key: ValueKey('player-$index'),
                  controller: controllers[index],
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Player ${index + 1}',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              if (index > 1)
                IconButton(
                  tooltip: 'Remove player ${index + 1}',
                  onPressed: () => onRemovePlayer(index),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (controllers.length < 4)
          OutlinedButton.icon(
            onPressed: onAddPlayer,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add another player'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              foregroundColor: _green,
              side: const BorderSide(color: Color(0xFFCBD5CA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: const TextStyle(color: Color(0xFFB54736), fontSize: 12),
          ),
        ],
        const SizedBox(height: 15),
        FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(49),
            backgroundColor: _green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Start a new game'),
              Icon(Icons.north_east_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const Center(
          child: Text(
            'Scores stay on this device while the page is open.',
            style: TextStyle(color: Color(0xFF92998F), fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _GameScreen extends StatelessWidget {
  const _GameScreen({
    required this.game,
    required this.wordController,
    required this.blankIndexes,
    required this.letterMultipliers,
    required this.wordMultiplier,
    required this.bingo,
    required this.preview,
    required this.error,
    required this.onWordChanged,
    required this.onToggleBlank,
    required this.onLetterMultiplierChanged,
    required this.onWordMultiplierChanged,
    required this.onBingoChanged,
    required this.onSubmit,
    required this.onUndo,
  });

  final GameState game;
  final TextEditingController wordController;
  final Set<int> blankIndexes;
  final List<int> letterMultipliers;
  final int wordMultiplier;
  final bool bingo;
  final WordScore? preview;
  final String? error;
  final ValueChanged<String> onWordChanged;
  final ValueChanged<int> onToggleBlank;
  final void Function(int index, int value) onLetterMultiplierChanged;
  final ValueChanged<int> onWordMultiplierChanged;
  final ValueChanged<bool> onBingoChanged;
  final VoidCallback onSubmit;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final entry = _EntryPanel(
      game: game,
      wordController: wordController,
      blankIndexes: blankIndexes,
      letterMultipliers: letterMultipliers,
      wordMultiplier: wordMultiplier,
      bingo: bingo,
      preview: preview,
      error: error,
      onWordChanged: onWordChanged,
      onToggleBlank: onToggleBlank,
      onLetterMultiplierChanged: onLetterMultiplierChanged,
      onWordMultiplierChanged: onWordMultiplierChanged,
      onBingoChanged: onBingoChanged,
      onSubmit: onSubmit,
    );
    final scoreboard = _Scoreboard(game: game, onUndo: onUndo);
    if (MediaQuery.sizeOf(context).width < 780) {
      return Column(children: [entry, const SizedBox(height: 15), scoreboard]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 11, child: scoreboard),
        const SizedBox(width: 16),
        Expanded(flex: 9, child: entry),
      ],
    );
  }
}

class _EntryPanel extends StatelessWidget {
  const _EntryPanel({
    required this.game,
    required this.wordController,
    required this.blankIndexes,
    required this.letterMultipliers,
    required this.wordMultiplier,
    required this.bingo,
    required this.preview,
    required this.error,
    required this.onWordChanged,
    required this.onToggleBlank,
    required this.onLetterMultiplierChanged,
    required this.onWordMultiplierChanged,
    required this.onBingoChanged,
    required this.onSubmit,
  });

  final GameState game;
  final TextEditingController wordController;
  final Set<int> blankIndexes;
  final List<int> letterMultipliers;
  final int wordMultiplier;
  final bool bingo;
  final WordScore? preview;
  final String? error;
  final ValueChanged<String> onWordChanged;
  final ValueChanged<int> onToggleBlank;
  final void Function(int index, int value) onLetterMultiplierChanged;
  final ValueChanged<int> onWordMultiplierChanged;
  final ValueChanged<bool> onBingoChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final word = wordController.text.trim().toUpperCase();
    final currentPlayer = game.players[game.currentPlayerIndex].name;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow(label: 'YOUR TURN'),
                    const SizedBox(height: 7),
                    Text(
                      'Add a word',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: const Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF80AA5B),
                ),
                label: Text(
                  currentPlayer.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: const Color(0xFFEDF4E5),
                side: BorderSide.none,
                labelStyle: const TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Word played'),
          TextField(
            controller: wordController,
            onChanged: onWordChanged,
            maxLength: 15,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. QUIZ',
              counterText: '',
            ),
          ),
          const SizedBox(height: 19),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel('Your tiles'),
              Text(
                '${word.length} ${word.length == 1 ? 'TILE' : 'TILES'}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (word.isEmpty)
            const SizedBox(
              height: 72,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Type a word above to set tile values.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 7,
              children: [
                for (var index = 0; index < word.length; index++)
                  _LetterTile(
                    letter: word[index],
                    value: blankIndexes.contains(index)
                        ? 0
                        : (letterValues[word[index]] ?? 0),
                    isBlank: blankIndexes.contains(index),
                    multiplier: letterMultipliers.length > index
                        ? letterMultipliers[index]
                        : 1,
                    onBlankTap: () => onToggleBlank(index),
                    onMultiplierSelected: (value) =>
                        onLetterMultiplierChanged(index, value),
                  ),
              ],
            ),
          const SizedBox(height: 17),
          if (word.isNotEmpty && preview == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Use English letters only and remove spaces.',
                style: TextStyle(color: Color(0xFFB54736), fontSize: 11),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Word bonus'),
                    DropdownButtonFormField<int>(
                      initialValue: wordMultiplier,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('No bonus')),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Double word ×2'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Triple word ×3'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onWordMultiplierChanged(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CheckboxListTile(
                  value: bingo,
                  onChanged: word.length == 7
                      ? (value) => onBingoChanged(value ?? false)
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: const Color(0xFFF7F7F1),
                  title: const Text(
                    'Seven tiles',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    '+50 bonus',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _ScorePreview(score: preview),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Color(0xFFB54736), fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: preview == null ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add score'),
                Icon(Icons.north_east_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Letter premiums apply to new tiles only. Check the board, then mark your bonuses here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 9, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.value,
    required this.isBlank,
    required this.multiplier,
    required this.onBlankTap,
    required this.onMultiplierSelected,
  });

  final String letter;
  final int value;
  final bool isBlank;
  final int multiplier;
  final VoidCallback onBlankTap;
  final ValueChanged<int> onMultiplierSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
    decoration: BoxDecoration(
      color: isBlank ? const Color(0xFFF4F0DF) : Colors.white,
      border: Border.all(color: isBlank ? const Color(0xFFDED6B5) : _line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Stack(
          children: [
            Container(
              width: 29,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isBlank
                    ? const Color(0xFFE4DFC9)
                    : const Color(0xFFF6EBC9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Positioned(
              right: 3,
              bottom: 1,
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 21,
          child: TextButton(
            onPressed: onBlankTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isBlank ? 'BLANK' : 'TILE',
              style: const TextStyle(
                fontSize: 8,
                letterSpacing: .3,
                color: _muted,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 18,
          child: PopupMenuButton<int>(
            tooltip: 'Letter bonus',
            padding: EdgeInsets.zero,
            onSelected: onMultiplierSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text('No letter bonus')),
              PopupMenuItem(value: 2, child: Text('Double letter ×2')),
              PopupMenuItem(value: 3, child: Text('Triple letter ×3')),
            ],
            child: Center(
              child: Text(
                multiplier == 1 ? '×1' : '×${multiplier}L',
                style: const TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScorePreview extends StatelessWidget {
  const _ScorePreview({required this.score});

  final WordScore? score;

  @override
  Widget build(BuildContext context) {
    final breakdown = score == null
        ? '—'
        : [
            '${score!.letterSubtotal} letters',
            if (score!.wordMultiplier > 1) '×${score!.wordMultiplier} word',
            if (score!.bingoBonus > 0) '+50 seven-tile',
          ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5ED),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score preview',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
              Flexible(
                child: Text(
                  breakdown,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE0E8D8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Turn total',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                score?.total.toString() ?? '0',
                style: const TextStyle(
                  color: _green,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.game, required this.onUndo});

  final GameState game;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final round = game.turns.length ~/ game.players.length + 1;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow(label: 'THE TABLE'),
                  const SizedBox(height: 7),
                  Text(
                    'Scoreboard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7ED),
                  border: Border.all(color: const Color(0xFFE1E7D6)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ROUND ${round.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF66795A),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          for (var index = 0; index < game.players.length; index++) ...[
            _PlayerRow(
              player: game.players[index],
              index: index,
              isCurrent: index == game.currentPlayerIndex,
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 10),
          const Divider(color: _line),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Eyebrow(label: 'PLAY BY PLAY'),
              TextButton.icon(
                onPressed: game.turns.isEmpty ? null : onUndo,
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Undo last', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF668272),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (game.turns.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 11),
              child: Text(
                'Your plays will show up here.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            )
          else
            for (
              var reverseIndex = game.turns.length - 1;
              reverseIndex >= 0;
              reverseIndex--
            )
              _TurnRow(
                index: reverseIndex + 1,
                turn: game.turns[reverseIndex],
                playerName:
                    game.players[game.turns[reverseIndex].playerIndex].name,
              ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.index,
    required this.isCurrent,
  });

  final PlayerScore player;
  final int index;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    const avatarColors = [
      Color(0xFFDCE9CE),
      Color(0xFFF2DFD2),
      Color(0xFFE3E2F1),
      Color(0xFFDCEAF0),
    ];
    const foregroundColors = [
      Color(0xFF285743),
      Color(0xFF87543E),
      Color(0xFF5B5F89),
      Color(0xFF456A7E),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFF0F5E9) : const Color(0xFFF8F8F3),
        border: Border.all(
          color: isCurrent ? const Color(0xFFCBDAB8) : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColors[index % avatarColors.length],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: foregroundColors[index % foregroundColors.length],
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent ? 'UP NEXT' : 'IN THE GAME',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 8,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.score}',
                style: const TextStyle(
                  fontSize: 21,
                  height: 1,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'POINTS',
                style: TextStyle(color: _muted, fontSize: 8, letterSpacing: .7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({
    required this.index,
    required this.turn,
    required this.playerName,
  });

  final int index;
  final PlayedTurn turn;
  final String playerName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFF0F0E9))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            index.toString().padLeft(2, '0'),
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                turn.word,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                playerName,
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          '+${turn.points}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _card,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B22342A),
          blurRadius: 28,
          offset: Offset(0, 11),
        ),
      ],
    ),
    child: child,
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF74A653),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          color: _green,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF56645A),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _TileStillLife extends StatelessWidget {
  const _TileStillLife();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      _DecorativeTile(
        letter: 'C',
        value: '3',
        color: Color(0xFFFFFEFA),
        angle: -0.12,
      ),
      _DecorativeTile(
        letter: 'A',
        value: '1',
        color: Color(0xFFD9EDB5),
        angle: 0.06,
      ),
      _DecorativeTile(
        letter: 'T',
        value: '1',
        color: Color(0xFFF4B49E),
        angle: -0.04,
      ),
      SizedBox(width: 18),
      Text(
        'a good place\nto start  ↗',
        style: TextStyle(
          color: Color(0xFF89938B),
          fontSize: 11,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _DecorativeTile extends StatelessWidget {
  const _DecorativeTile({
    required this.letter,
    required this.value,
    required this.color,
    required this.angle,
  });

  final String letter;
  final String value;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 53,
      height: 58,
      margin: const EdgeInsets.only(right: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFFE3E3D8)),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F303829),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 4,
            child: Text(
              value,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
