# Flutter Word Game Scorekeeper — Revised Plan

## Goal

Port the current Scrabble-style scorekeeper to Flutter, keeping the core app small and dependency-light. Build and run the Android version on the available emulator. If the core app is finished early, try a simple Android home-screen widget that shows the current players and scores.

## Local setup found

- Flutter 3.47.5 and Dart 3.13.4 are installed.
- Android SDK and emulator tools are installed.
- An Android virtual device named `FlashcardApp_VM_Pixel_10a` is available, but no emulator is running now.
- The current browser version and Node tests are uncommitted. Keep them available as a reference until the Flutter app passes its core checks.

## Core Flutter scope

- Create a Flutter project at the repository root for Android.
- Keep the same game flow: 2–4 named players, word entry, automatic English letter-value calculation, blank tiles, selected letter and word bonuses, optional 50-point seven-tile bonus, running totals, turn history, and undo.
- Show a score preview and current player before a turn is submitted.
- Use Material widgets and a compact responsive layout.
- Keep the score calculation and turn state as small, testable Dart code. Use Flutter SDK widgets and simple built-in state management; add no third-party packages for the core app.
- Keep game state in memory for the core version; a new game or app restart resets it.

## Widget stretch goal

If the core app is running reliably on the emulator and time remains, add an Android home-screen widget showing player names, current totals, and whose turn is next. Refresh it after each submitted score and when a new game starts.

Flutter UI widgets cannot directly serve as Android home-screen widgets. The `home_widget` package can bridge Flutter data to a home-screen widget, but the widget still needs native Android setup and code. Keep the widget Android-only for this pass and defer it if it threatens the core app or class-time limit. [Package details](https://pub.dev/packages/home_widget) · [Flutter platform integration](https://docs.flutter.dev/platform-integration/platform-channels)

## Not in scope

- Cloud sync, accounts, network services, or a database.
- Dictionary validation, word legality checks, board placement, or cross-word scoring.
- iOS home-screen widget support.
- Additional state-management or UI libraries for the core app.

## Stages and time budget

1. **Plan and confirm — 5 min.** Confirm Flutter-at-root, core scope, and Android widget as a stretch goal.
2. **Test — 10 min.** Port the existing scoring and turn tests to Dart before replacing the implementation. Cover letter values, blanks, multipliers, seven-tile bonus, player rotation, and undo.
3. **Implement — 25 min.** Scaffold the Flutter app, build the score-entry and scoreboard screens, and port the tested domain logic. Keep dependencies limited to Flutter SDK packages.
4. **Review — 8 min.** Review scoring behavior, input validation, accessible controls, and Android project changes.
5. **Verify — 7 min.** Run `flutter test` and `flutter analyze`; build and launch on the Android emulator if available.
6. **Buffer — 5 min.** Resolve SDK or emulator setup issues and leave the app demo-ready.
7. **Stretch goal.** Only after the core passes, add the Android widget and verify it on the emulator. The widget may require more time than remains in the 60-minute core schedule.

## Acceptance checks

- The Flutter app launches on the Android emulator.
- It calculates a word score from tile values and selected bonuses, including blank tiles and the optional seven-tile bonus.
- Submitted turns update the correct player, total, history, and next-player indicator.
- Undo restores the prior score and turn order.
- Dart unit tests pass, and `flutter analyze` reports no app issues.
- If completed, the Android widget displays the latest saved game scores after a turn is submitted.

## Approval gate

This plan replaces the browser-first implementation plan. Do not start Flutter scaffolding or code changes until the user approves this revised plan. After approval, proceed through Test, Implement, Review, and Verify in order; treat the Android home-screen widget as optional stretch work.
