# Tower Climb

Tower Climb is a mobile-first vertical platformer built with [Flutter](https://flutter.dev/) and [Flame](https://flame-engine.org/).

Bounce from platform to platform, climb through six biomes, reach checkpoint floors, and set a new personal best before falling into the void.

## Features

- Endless vertical climbing with procedural platform generation
- Simple touch controls designed for portrait play
- Auto-scrolling camera with faster movement in later biomes
- Six visual stages with biome-specific backgrounds, platforms, and music
- Smooth visual and audio crossfades between stages
- Checkpoints every 100 floors
- Combo tracking and current-floor HUD
- Pause menu with resume, settings, and main-menu actions
- Persisted master-volume setting
- Retro pixel-art presentation with animated menu elements
- Glitch mode beyond the final stage

## How to play

| Action | Input |
| --- | --- |
| Move left | Tap or hold the left half of the screen |
| Move right | Tap or hold the right half of the screen |
| Start a run | Tap anywhere on the launch prompt |
| Continue after a checkpoint | Tap the checkpoint prompt |
| Pause | Tap the pause button in the HUD |

The player bounces automatically when landing on a platform. Stay aligned, keep climbing, and avoid falling below the death boundary.

## Stages

Each stage covers 100 floors. Platforms become narrower and the camera accelerates as the climb continues.

1. Mossy — floors 0–99
2. Ancient Civilization — floors 100–199
3. Eroded — floors 200–299
4. Desert — floors 300–399
5. Snowy — floors 400–499
6. Volcanic — floors 500–599

At floor 600, the game enters glitch mode. Background and platform art flicker between stages while the climb speed increases.

## Tech stack

- Flutter and Dart
- Flame game engine
- `flame_audio` for music and sound effects
- `google_fonts` for the pixel-style interface
- `shared_preferences` for persisted audio settings

## Project structure

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App startup, portrait orientation, fullscreen mode |
| `lib/main_menu_screen.dart` | Animated menu, stage preview, and play flow |
| `lib/game_screen.dart` | Flame view, HUD, pause flow, checkpoints, and game-over dialog |
| `lib/tower_game.dart` | Game loop, camera, spawning, input, scoring, and game state |
| `lib/player.dart` | Movement, gravity, bounce physics, collisions, and wall limits |
| `lib/platform.dart` | Platform rendering and stage transitions |
| `lib/background.dart` | Parallax background rendering |
| `lib/stage_manager.dart` | Stage definitions, asset loading, blending, and glitch mode |
| `lib/audio_manager.dart` | Biome music, pooled sound effects, pause/resume, and volume |
| `lib/settings_screen.dart` | Master-volume settings dialog |
| `test/widget_test.dart` | Flutter widget smoke test |

## Run locally

### Requirements

- Flutter SDK with Dart 3
- A connected Android or iOS device, emulator, or simulator

### Commands

```bash
flutter pub get
flutter run
```

Run the test suite:

```bash
flutter test
```

Check code quality:

```bash
flutter analyze
```

## Assets

Game assets live under `assets/`:

```text
assets/
├── audio/
│   ├── <biome>/<biome>_bgm.mp3
│   ├── button_click.wav
│   ├── checkpoint.wav
│   └── jump.wav
├── images/
│   ├── character.png
│   ├── character_chubby_64.png
│   └── <biome>/
│       ├── <biome>_background.png
│       └── <biome>_floor.png
└── icon.png
```

To add a biome, define a `StageConfig` in `lib/stage_manager.dart`, add its background and platform images, add its music file to `pubspec.yaml`, and include the matching asset files.

## Current platform target

The game is configured for portrait orientation and immersive fullscreen play. Touch input is the primary control method.

## License

No open-source license has been selected yet. Add a license before distributing the project under open-source terms.
