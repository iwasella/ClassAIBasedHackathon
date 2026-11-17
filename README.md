# Lettercount

A lightweight Flutter scorekeeper for Scrabble-style word games. It calculates tile points, selected letter and word bonuses, and the seven-tile bonus. Games stay in memory and reset when the app closes.

## Run on Android

Start the `FlashcardApp_VM_Pixel_10a` emulator from Android Studio or run `flutter emulators --launch FlashcardApp_VM_Pixel_10a`, then:

```sh
flutter pub get
flutter run
```

## Checks

```sh
flutter test
flutter analyze
```

The app has no third-party runtime dependencies. The Android home-screen widget is a stretch goal and is not included in the core build.
