import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'platform.dart';
import 'background.dart';
import 'kill_floor.dart';

enum GameState { waiting, playing, over }

class TowerGame extends FlameGame
    with HasCollisionDetection, MultiTouchDragDetector, ChangeNotifier {
  final void Function(int score, int best) onGameOver;

  TowerGame({required this.onGameOver});

  // ── State ──────────────────────────────────────────────────────────────────
  late Player player;
  final List<GamePlatform> platforms = [];
  late KillFloor killFloor;

  GameState gameState = GameState.waiting;
  int currentFloor = 0;
  int combo        = 0;
  int _bestFloor   = 0;

  bool _leftDown  = false;
  bool _rightDown = false;

  final Map<int, bool> _activeTouches = {}; // pointerId → isLeftSide

  // Platform generation
  final Random _rng = Random();
  double _highestPlatformY = 0;
  int _platformCount = 0;

  // Camera
  double _cameraTargetY = 0;
  double _autoScrollY   = 0;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const double platformSpacing   = 110.0;
  static const double killFloorGrace    = platformSpacing * 3.0;
  static const double _scrollSpeedMin  = 12.0;
  static const double _scrollSpeedMax  = 110.0;
  static const double _scrollRampFloors = 60.0;

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  // ── Load ───────────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    await GamePlatform.preload();
    await Player.preload();
    await GameBackground.preload();

    world.add(GameBackground());
    _spawnStartingPlatforms();

    final double groundFloorY = size.y - 60;
    player = Player();
    player.position = Vector2(
      size.x / 2 - Player.playerWidth / 2,
      groundFloorY - Player.playerHeight,
    );
    world.add(player);

    killFloor = KillFloor();
    world.add(killFloor);

    // Camera: ground sits ~75% down the screen
    final double groundCamY = (size.y - 60) - size.y * 0.75;
    camera.viewfinder.position = Vector2(0, groundCamY);
    _cameraTargetY = groundCamY;
    _autoScrollY   = groundCamY;

    killFloor.position.y = camera.viewfinder.position.y + size.y + killFloorGrace;
  }

  // ── Spawning ───────────────────────────────────────────────────────────────
  void _spawnStartingPlatforms() {
    _addPlatform(x: 0, y: size.y - 60, width: size.x, isGround: true);
    _highestPlatformY = size.y - 60;
    for (int i = 0; i < 6; i++) { _spawnNextPlatform(forced: true); }
  }

  void _spawnNextPlatform({bool forced = false}) {
    final double difficulty = min(_platformCount / 30.0, 1.0);
    final double minWidth   = _lerp(size.x * 0.28, size.x * 0.12, difficulty);
    final double maxWidth   = _lerp(size.x * 0.45, size.x * 0.25, difficulty);
    final double w = minWidth + _rng.nextDouble() * (maxWidth - minWidth);
    final double x = _rng.nextDouble() * (size.x - w);
    final double gap = platformSpacing + _rng.nextDouble() * _lerp(20, 40, difficulty);
    final double y = _highestPlatformY - gap;

    _addPlatform(x: x, y: y, width: w);
    _highestPlatformY = y;
    _platformCount++;
  }

  void _addPlatform({
    required double x,
    required double y,
    required double width,
    bool isGround = false,
  }) {
    final p = GamePlatform(
      position: Vector2(x, y),
      width: width,
      isGround: isGround,
      rng: _rng,
    );
    world.add(p);
    platforms.add(p);
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    if (gameState == GameState.over) return;
    super.update(dt);

    if (gameState == GameState.waiting) {
      // Player can walk left/right on the ground, camera stays frozen
      player.moveLeft  = _leftDown;
      player.moveRight = _rightDown;
      player.groundSlide(dt, braking: !_leftDown && !_rightDown);

      // Pin to ground
      player.position.y = size.y - 60 - Player.playerHeight;

      // Wrap horizontally
      if (player.position.x + Player.playerWidth < 0) player.position.x = size.x;
      if (player.position.x > size.x) player.position.x = -Player.playerWidth;

      killFloor.position.y = camera.viewfinder.position.y + size.y + killFloorGrace;
      return;
    }

    // ── Playing ──────────────────────────────────────────────────────────────
    player.moveLeft  = _leftDown;
    player.moveRight = _rightDown;

    final double scrollT     = (currentFloor / _scrollRampFloors).clamp(0.0, 1.0);
    final double scrollSpeed = _lerp(_scrollSpeedMin, _scrollSpeedMax, scrollT);
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

    killFloor.position.y = camera.viewfinder.position.y + size.y + killFloorGrace;

    platforms.removeWhere((p) {
      if (p.position.y > camera.viewfinder.position.y + size.y + 200) {
        p.removeFromParent();
        return true;
      }
      return false;
    });

    while (_highestPlatformY > camera.viewfinder.position.y - size.y * 0.5) {
      _spawnNextPlatform();
    }

    final int floor = _worldYToFloor(player.position.y);
    if (floor > currentFloor) {
      currentFloor = floor;
      notifyListeners();
    }

    if (player.position.y > killFloor.position.y) {
      _triggerGameOver();
    }
  }

  int _worldYToFloor(double worldY) {
    return max(0, ((size.y - 60 - worldY) / platformSpacing).floor());
  }

  // ── Collision ──────────────────────────────────────────────────────────────
  void onPlayerLandedPlatform(GamePlatform platform) {
    if (gameState != GameState.playing) return;
    final int floor = _worldYToFloor(platform.position.y);
    combo = floor > currentFloor ? combo + 1 : 0;
    notifyListeners();
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    final bool isLeft = info.eventPosition.global.x < size.x / 2;
    _activeTouches[pointerId] = isLeft;
    _updateSides();

    // Any tap while waiting launches the game
    if (gameState == GameState.waiting) _launch();
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
    _leftDown  = _activeTouches.values.any((isLeft) => isLeft);
    _rightDown = _activeTouches.values.any((isLeft) => !isLeft);
  }

  // ── Launch ─────────────────────────────────────────────────────────────────
  void _launch() {
    gameState    = GameState.playing;
    _autoScrollY = camera.viewfinder.position.y;
    notifyListeners();
  }

  // ── Game over ──────────────────────────────────────────────────────────────
  void _triggerGameOver() {
    if (gameState == GameState.over) return;
    gameState = GameState.over;
    if (currentFloor > _bestFloor) _bestFloor = currentFloor;
    onGameOver(currentFloor, _bestFloor);
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
