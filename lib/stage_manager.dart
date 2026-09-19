import 'dart:math';
import 'package:flame/flame.dart';
import 'dart:ui' as ui;

// ── Stage definition ──────────────────────────────────────────────────────────
class StageConfig {
  final String name;
  final String bgAsset;
  final String floorAsset;

  // Tile width range (min, max) in screen-fraction — fixed for the whole stage
  final double tileMinFraction; // of screen width
  final double tileMaxFraction;

  // Camera auto-scroll speed (world units/sec)
  final double scrollSpeed;

  const StageConfig({
    required this.name,
    required this.bgAsset,
    required this.floorAsset,
    required this.tileMinFraction,
    required this.tileMaxFraction,
    required this.scrollSpeed,
  });
}

const List<StageConfig> kStages = [
  StageConfig(
    name: 'mossy',
    bgAsset: 'mossy/mossy_background.png',
    floorAsset: 'mossy/mossy_floor.png',
    tileMinFraction: 0.35,
    tileMaxFraction: 0.45,
    scrollSpeed: 20,
  ),
  StageConfig(
    name: 'ancient_civilization',
    bgAsset: 'ancient_civilization/ancient_civilization_background.png',
    floorAsset: 'ancient_civilization/ancient_civilization_floor.png',
    tileMinFraction: 0.30,
    tileMaxFraction: 0.40,
    scrollSpeed: 30,
  ),
  StageConfig(
    name: 'eroded',
    bgAsset: 'eroded/eroded_background.png',
    floorAsset: 'eroded/eroded_floor.png',
    tileMinFraction: 0.25,
    tileMaxFraction: 0.30,
    scrollSpeed: 45,
  ),
  StageConfig(
    name: 'desert',
    bgAsset: 'desert/desert_background.png',
    floorAsset: 'desert/desert_floor.png',
    tileMinFraction: 0.20,
    tileMaxFraction: 0.30,
    scrollSpeed: 60,
  ),
  StageConfig(
    name: 'snowy',
    bgAsset: 'snowy/snowy_background.png',
    floorAsset: 'snowy/snowy_floor.png',
    tileMinFraction: 0.15,
    tileMaxFraction: 0.20,
    scrollSpeed: 80,
  ),
  StageConfig(
    name: 'volcanic',
    bgAsset: 'volcanic/volcanic_background.png',
    floorAsset: 'volcanic/volcanic_floor.png',
    tileMinFraction: 0.10,
    tileMaxFraction: 0.15,
    scrollSpeed: 95,
  ),
];

// Crossfade begins this many floors before the stage boundary
const int kBlendStartOffset = 30; // floors 70–100 of each stage

// ── Stage manager ─────────────────────────────────────────────────────────────
class StageManager {
  // Loaded images keyed by asset path
  final Map<String, ui.Image> _images = {};

  // Glitch mode RNG
  final Random _rng = Random();
  int _glitchBgIndex = 0;
  int _glitchFloorIndex = 0;
  double _glitchTimer = 0;
  static const double _glitchInterval = 0.8; // seconds between flickers

  // ── Preload ───────────────────────────────────────────────────────────────
  Future<void> preload() async {
    for (final stage in kStages) {
      _images[stage.bgAsset] = await Flame.images.load(stage.bgAsset);
      _images[stage.floorAsset] = await Flame.images.load(stage.floorAsset);
    }
  }

  // ── Derived state from floor number ───────────────────────────────────────

  /// Index into kStages (0–5). Returns -1 when in glitch mode.
  int stageIndex(int floor) {
    final int idx = floor ~/ 100;
    return idx < kStages.length ? idx : -1;
  }

  bool isGlitchMode(int floor) => floor >= kStages.length * 100;

  /// 0.0 = fully current stage, 1.0 = fully next stage
  double blendFactor(int floor) {
    if (isGlitchMode(floor)) return 0.0;
    final int stageFloor = floor % 100; // 0–99 within the stage
    final int blendStart = 100 - kBlendStartOffset; // = 70
    if (stageFloor < blendStart) return 0.0;
    return (stageFloor - blendStart) / kBlendStartOffset.toDouble();
  }

  StageConfig currentStage(int floor) {
    final int idx = stageIndex(floor).clamp(0, kStages.length - 1);
    return kStages[idx];
  }

  StageConfig? nextStage(int floor) {
    final int idx = stageIndex(floor);
    if (idx < 0 || idx + 1 >= kStages.length) return null;
    return kStages[idx + 1];
  }

  // ── Images ────────────────────────────────────────────────────────────────
  ui.Image? bgImage(int floor) {
    if (isGlitchMode(floor)) return _images[kStages[_glitchBgIndex].bgAsset];
    return _images[currentStage(floor).bgAsset];
  }

  ui.Image? bgImageNext(int floor) {
    if (isGlitchMode(floor)) return null;
    final StageConfig? next = nextStage(floor);
    return next != null ? _images[next.bgAsset] : null;
  }

  ui.Image? floorImage(int floor) {
    if (isGlitchMode(floor))
      return _images[kStages[_glitchFloorIndex].floorAsset];
    return _images[currentStage(floor).floorAsset];
  }

  ui.Image? floorImageNext(int floor) {
    if (isGlitchMode(floor)) return null;
    final StageConfig? next = nextStage(floor);
    return next != null ? _images[next.floorAsset] : null;
  }

  // ── Tile sizing for a given floor ─────────────────────────────────────────
  /// Returns a random tile width in [min, max] for the current stage.
  /// screenWidth is needed to convert fractions to pixels.
  double randomTileWidth(int floor, double screenWidth, Random rng) {
    final StageConfig stage = currentStage(floor);
    final double min = stage.tileMinFraction * screenWidth;
    final double max = stage.tileMaxFraction * screenWidth;
    return min + rng.nextDouble() * (max - min);
  }

  // ── Scroll speed ──────────────────────────────────────────────────────────
  double scrollSpeed(int floor) {
    if (isGlitchMode(floor)) return kStages.last.scrollSpeed * 1.3;
    return currentStage(floor).scrollSpeed;
  }

  // ── Glitch update (call every frame in glitch mode) ───────────────────────
  void updateGlitch(double dt) {
    _glitchTimer += dt;
    if (_glitchTimer >= _glitchInterval) {
      _glitchTimer = 0;
      _glitchBgIndex = _rng.nextInt(kStages.length);
      _glitchFloorIndex = _rng.nextInt(kStages.length);
    }
  }
}
