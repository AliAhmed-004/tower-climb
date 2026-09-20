# Tower Climb

Tower Climb is a mobile-first vertical platformer built with Flutter and Flame. The player starts on a ground platform, bounces upward by landing on increasingly higher platforms, survives checkpoint floors, and tries to climb as far as possible before falling past the death boundary.

## What is in the game

- Endless vertical climb loop with procedural platform generation
- Touch controls split by screen half: left side moves left, right side moves right
- Auto-scrolling camera and rising difficulty as floors increase
- Checkpoint floors every 100 floors that freeze the camera and resume play after a brief settle
- Stage progression across six visual themes: mossy, ancient civilization, eroded, desert, snowy, volcanic
- Combo and floor tracking in the HUD
- Retro menu screen with animated title and stage background art

## Tech stack

- Flutter
- Flame game engine
- Google Fonts for retro pixel-styled UI
- Custom sprite and tile assets under `assets/images/`

## Project structure

- `lib/main.dart` — app bootstrapping and orientation setup
- `lib/main_menu_screen.dart` — animated start menu and title screen
- `lib/game_screen.dart` — active game screen, overlays, HUD, checkpoint prompts, and game-over dialog
- `lib/tower_game.dart` — game loop, spawn system, camera logic, checkpoint flow, input, and death triggers
- `lib/player.dart` — player movement, gravity, bounce physics, wall clamping, collision handling
- `lib/platform.dart` — platform rendering and stage tile visuals
- `lib/background.dart` — parallax background rendering and stage blending
- `lib/stage_manager.dart` — stage definitions, asset loading, blending, and glitch mode
- `lib/kill_floor.dart` — invisible death boundary below the active camera
- `test/widget_test.dart` — default Flutter smoke test

## Controls

- Tap the left half of the screen to move left
- Tap the right half of the screen to move right
- Tap anywhere to launch the run from the start prompt
- When the camera settles on a checkpoint, tap again to resume from that checkpoint

## Run locally

```bash
flutter pub get
flutter run
```

For a quick test pass:

```bash
flutter test
```

## Notes

- The app is configured for portrait mode with immersive fullscreen behavior.
- Asset loading is handled through Flame image cache using the stage-specific background and floor textures.
- The game uses a fixed platform spacing and a stage blend window to transition between biome themes without abrupt visual jumps.
- There is a "glitch mode" after the final stage threshold, which swaps backgrounds and floor art at intervals for an unstable final stretch.

## Asset layout

The project loads art from the following categories:

- `assets/images/character.png`
- `assets/images/mossy/`
- `assets/images/ancient_civilization/`
- `assets/images/eroded/`
- `assets/images/desert/`
- `assets/images/snowy/`
- `assets/images/volcanic/`

This README reflects the current app behavior and structure, not the default Flutter starter template.
