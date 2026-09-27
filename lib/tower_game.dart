import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'player.dart';
import 'platform.dart';
import 'background.dart';
import 'kill_floor.dart';
import 'stage_manager.dart';

enum GameState { waiting, playing, checkpoint, paused, over }

class TowerGame extends FlameGame
    with HasCollisionDetection, MultiTouchDragDetector, ChangeNotifier {
  final void Function(int score, int best) onGameOver;

  TowerGame({required this.onGameOver});

  // ── Stage ──────────────────────────────────────────────────────────────────
  final StageManager stageManager = StageManager();

  // ── State ──────────────────────────────────────────────────────────────────
  late Player player;
  final List<GamePlatform> platforms = [];
  late KillFloor killFloor;

  GameState gameState = GameState.waiting;
  int currentFloor = 0;
  int combo = 0;
  int _bestFloor = 0;

  // The floor the player is currently standing on (used for checkpoint detect)
  int _lastLandedFloor = 0;

  bool _leftDown = false;
  bool _rightDown = false;
  final Map<int, bool> _activeTouches = {};

  // Platform generation
  final Random _rng = Random();
  double _highestPlatformY = 0;
  int _platformCount = 0;

  // Camera
  double _cameraTargetY = 0;
  double _autoScrollY = 0;

  // Checkpoint: camera resumes after player lands ABOVE the checkpoint floor
  bool _checkpointLanded = false; // player has bounced off checkpoint
  int _checkpointFloor = 0;
  bool _checkpointCameraLocked = false;
  bool _checkpointCameraSettled = false;
  double _checkpointCameraTargetY = 0;
  int _checkpointReleaseFloor = 0;

  // Glitch mode timer (drives background flicker)
  double _glitchTimer = 0;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const double platformSpacing = 82.0; // reachable without momentum
  static const double killFloorGrace = platformSpacing * 3.0;

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  // ── Load ───────────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    await stageManager.preload();
    await Player.preload();

    world.add(GameBackground());
    _spawnStartingPlatforms();

    final double groundFloorY = size.y - 60;
    player = Player();
    player.position = Vector2(
      size.x / 2 - Player.playerWidth / 2,
      groundFloorY - Player.hitboxOffsetY - Player.hitboxH,
    );
    world.add(player);

    killFloor = KillFloor();
    world.add(killFloor);

    final double groundCamY = (size.y - 60) - size.y * 0.75;
    camera.viewfinder.position = Vector2(0, groundCamY);
    _cameraTargetY = groundCamY;
    _autoScrollY = groundCamY;
    killFloor.position.y =
        camera.viewfinder.position.y + size.y + killFloorGrace;
  }

  // ── Spawning ───────────────────────────────────────────────────────────────
  void _spawnStartingPlatforms() {
    _addPlatform(
      x: 0,
      y: size.y - 60,
      width: size.x,
      isGround: true,
      floor: 0,
    );
    _highestPlatformY = size.y - 60;
    for (int i = 0; i < 8; i++) {
      _spawnNextPlatform();
    }
  }

  void _spawnNextPlatform() {
    // What floor will this platform be?
    final int platformFloor =
        _worldYToFloor(_highestPlatformY - platformSpacing);

    // Checkpoint: every 100th floor gets a full-width platform
    final bool isCheckpoint = platformFloor > 0 && platformFloor % 100 == 0;

    double w;
    double x;

    if (isCheckpoint) {
      w = size.x;
      x = 0;
    } else {
      w = stageManager.randomTileWidth(platformFloor, size.x, _rng);
      // Clamp so platform stays fully within screen edges
      x = _rng.nextDouble() * (size.x - w);
    }

    final double y = _highestPlatformY - platformSpacing;

    _addPlatform(
        x: x, y: y, width: w, floor: platformFloor, isCheckpoint: isCheckpoint);
    _highestPlatformY = y;
    _platformCount++;
  }

  void _addPlatform({
    required double x,
    required double y,
    required double width,
    required int floor,
    bool isGround = false,
    bool isCheckpoint = false,
  }) {
    final double blend = stageManager.blendFactor(floor);
    final p = GamePlatform(
      position: Vector2(x, y),
      width: width,
      isCheckpoint: isCheckpoint,
      floor: floor,
      floorImg: stageManager.floorImage(floor),
      floorImgNext: stageManager.floorImageNext(floor),
      blendAtSpawn: blend,
    );
    world.add(p);
    platforms.add(p);
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    if (gameState == GameState.over || gameState == GameState.paused) return;
    super.update(dt);

    // Background music crossfades with the biome (same blendFactor as visuals).
    GameAudioManager.instance.biomeBgm
        .update(stageManager, currentFloor, GameAudioManager.instance.masterVolume);

    // Glitch mode background flicker
    if (stageManager.isGlitchMode(currentFloor)) {
      _glitchTimer += dt;

      if (_glitchTimer > 0.8) {
        _glitchTimer = 0;
        stageManager.updateGlitch(dt);
      }
    }

    if (gameState == GameState.waiting) {
      player.moveLeft = _leftDown;
      player.moveRight = _rightDown;

      player.groundSlide(dt, braking: !_leftDown && !_rightDown);
      _clampPlayerToWalls();

      player.position.y = size.y - 60 - Player.hitboxOffsetY - Player.hitboxH;
      killFloor.position.y =
          camera.viewfinder.position.y + size.y + killFloorGrace;

      return;
    }

    if (gameState == GameState.checkpoint) {
      // Frozen: player stands on checkpoint while camera settles
      // Input is still live so player can move left/right on the checkpoint floor
      player.moveLeft = _leftDown;
      player.moveRight = _rightDown;

      player.groundSlide(dt, braking: !_leftDown && !_rightDown);
      _clampPlayerToWalls();

      final double currentCamY = camera.viewfinder.position.y;
      final double nextCamY = currentCamY +
          (_checkpointCameraTargetY - currentCamY) * min(1.0, 5 * dt);
      camera.viewfinder.position = Vector2(0, nextCamY);
      _checkpointCameraSettled =
          (nextCamY - _checkpointCameraTargetY).abs() < 0.5;

      killFloor.position.y =
          camera.viewfinder.position.y + size.y + killFloorGrace;

      return;
    }

    // ── Playing ──────────────────────────────────────────────────────────────
    player.moveLeft = _leftDown;
    player.moveRight = _rightDown;

    if (!_checkpointCameraLocked) {
      // Scroll speed comes from stage manager — fixed per stage
      final double scrollSpeed = stageManager.scrollSpeed(currentFloor);
      _autoScrollY -= scrollSpeed * dt;

      final double playerFollowY = player.position.y - size.y * 0.4;
      _cameraTargetY = min(playerFollowY, _autoScrollY);

      final double currentCamY = camera.viewfinder.position.y;
      camera.viewfinder.position = Vector2(
        0,
        currentCamY + (_cameraTargetY - currentCamY) * 8 * dt,
      );

      if (camera.viewfinder.position.y < _autoScrollY) {
        _autoScrollY = camera.viewfinder.position.y;
      }
    }

    killFloor.position.y =
        camera.viewfinder.position.y + size.y + killFloorGrace;

    // Despawn platforms: keep 3 floors below viewport bottom
    final double despawnY =
        camera.viewfinder.position.y + size.y + (platformSpacing * 3);
    platforms.removeWhere((p) {
      if (p.position.y > despawnY) {
        p.removeFromParent();
        return true;
      }
      return false;
    });

    // Spawn ahead
    while (_highestPlatformY > camera.viewfinder.position.y - size.y * 0.6) {
      _spawnNextPlatform();
    }

    // Death
    if (player.position.y > killFloor.position.y) {
      _triggerGameOver();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _clampPlayerToWalls() {
    if (player.position.x < 0) {
      player.position.x = 0;
      player.zeroVelocityX();
    }
    if (player.position.x + Player.playerWidth > size.x) {
      player.position.x = size.x - Player.playerWidth;
      player.zeroVelocityX();
    }
  }

  int _worldYToFloor(double worldY) {
    return max(0, ((size.y - 60 - worldY) / platformSpacing).floor());
  }

  double get visualFloor =>
      max(0.0, (size.y - 60 - player.position.y) / platformSpacing);

  // ── Collision callbacks ────────────────────────────────────────────────────
  void onPlayerLandedPlatform(GamePlatform platform) {
    final int floor = platform.floor;

    if (gameState == GameState.playing) {
      // Checkpoint detection
      if (platform.isCheckpoint && floor != _checkpointFloor) {
        _checkpointFloor = floor;
        _checkpointReleaseFloor = floor + 4;
        _checkpointCameraLocked = true;
        _checkpointCameraSettled = false;
        _checkpointCameraTargetY =
            platform.position.y - size.y + GamePlatform.renderHeight;
        player.stopVerticalMotion();
        currentFloor = floor;
        GameAudioManager.instance.playCheckpoint();
        gameState = GameState.checkpoint;
        notifyListeners();
        return;
      }

      // Camera resumes after first landing above a checkpoint
      if (gameState == GameState.playing && !_checkpointLanded) {
        _checkpointLanded = true;
      }

      combo = floor > _lastLandedFloor ? combo + 1 : 0;
      _lastLandedFloor = floor;
      if (floor > currentFloor) {
        currentFloor = floor;
        if (_checkpointCameraLocked &&
            currentFloor >= _checkpointReleaseFloor) {
          _checkpointCameraLocked = false;
          _autoScrollY = camera.viewfinder.position.y;
        }
      }
      notifyListeners();
    }
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    final bool isLeft = info.eventPosition.global.x < size.x / 2;
    _activeTouches[pointerId] = isLeft;
    _updateSides();

    if (gameState == GameState.waiting)
      _launch();
    else if (gameState == GameState.checkpoint && _checkpointCameraSettled) {
      _resumeFromCheckpoint();
    }
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    final bool isLeft = info.eventPosition.global.x < size.x / 2;
    _activeTouches[pointerId] = isLeft;
    _updateSides();
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    _activeTouches.remove(pointerId);
    _updateSides();
  }

  @override
  void onDragCancel(int pointerId) {
    _activeTouches.remove(pointerId);
    _updateSides();
  }

  void _updateSides() {
    _leftDown = _activeTouches.values.any((isLeft) => isLeft);
    _rightDown = _activeTouches.values.any((isLeft) => !isLeft);
  }

  // ── Wall clamp (replaces wrap) ─────────────────────────────────────────────
  // Called from player.dart via game reference after horizontal movement
  void clampPlayerToWalls() => _clampPlayerToWalls();

  // ── Launch / resume ────────────────────────────────────────────────────────
  void _launch() {
    player.launchFromStart();
    GameAudioManager.instance.playJumpForBiome(
      stageManager.currentStage(currentFloor).name,
    );
    gameState = GameState.playing;
    _autoScrollY = camera.viewfinder.position.y;
    notifyListeners();
  }

  void _resumeFromCheckpoint() {
    player.resumeFromCheckpoint();
    gameState = GameState.playing;
    notifyListeners();
  }

  void pauseGame() {
    if (gameState != GameState.playing) return;
    gameState = GameState.paused;
    GameAudioManager.instance.biomeBgm.pause();
    notifyListeners();
  }

  void resumeGame() {
    if (gameState != GameState.paused) return;
    gameState = GameState.playing;
    GameAudioManager.instance.biomeBgm.resume();
    notifyListeners();
  }

  // ── Game over ──────────────────────────────────────────────────────────────
  void _triggerGameOver() {
    if (gameState == GameState.over) return;
    gameState = GameState.over;
    GameAudioManager.instance.biomeBgm.stopAll();
    if (currentFloor > _bestFloor) _bestFloor = currentFloor;
    onGameOver(currentFloor, _bestFloor);
  }

  @override
  void onRemove() {
    GameAudioManager.instance.biomeBgm.stopAll();
    super.onRemove();
  }
}
