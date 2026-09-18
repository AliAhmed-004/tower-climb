import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'platform.dart';
import 'background.dart';
import 'kill_floor.dart';

class TowerGame extends FlameGame
    with HasCollisionDetection, TapDetector, ChangeNotifier {
  final void Function(int score, int best) onGameOver;

  TowerGame({required this.onGameOver});

  // ── State ──────────────────────────────────────────────────────────────────
  late Player player;
  final List<GamePlatform> platforms = [];
  late KillFloor killFloor;

  int currentFloor = 0;
  int combo = 0;
  int _bestFloor = 0;

  bool _leftDown = false;
  bool _rightDown = false;
  bool _gameOver = false;

  // Platform generation
  final Random _rng = Random();
  double _highestPlatformY = 0;
  int _platformCount = 0;

  // Camera tracking
  double _cameraTargetY = 0;

  // Auto-scroll: tracks the autonomous upward creep of the camera
  double _autoScrollY =
      0; // world-Y the auto-scroll has reached (most negative = highest)

  // ── Constants ──────────────────────────────────────────────────────────────
  static const double platformSpacing = 110.0;

  // How far below the BOTTOM of the viewport the kill floor sits.
  // 3 floors of grace = player can fall back ~3 platforms before dying.
  static const double killFloorGrace = platformSpacing * 3.0;

  // Auto-scroll speed range (world units/sec, negative = upward).
  // At floor 0 the camera barely moves; by floor 50 it's aggressive.
  static const double _scrollSpeedMin = 12.0; // early game — barely noticeable
  static const double _scrollSpeedMax = 110.0; // late game — proper chase
  static const double _scrollRampFloors = 60.0; // floors over which speed ramps

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    // Preload platform spritesheet before any platforms are spawned
    await GamePlatform.preload();
    await Player.preload();
    await GameBackground.preload();

    // Background
    world.add(GameBackground());

    // Spawn starting platforms (ground + a few easy ones)
    _spawnStartingPlatforms();

    // Player — starts on the ground platform
    player = Player();
    player.position = Vector2(
      size.x / 2 - Player.playerWidth / 2,
      _highestPlatformY - Player.playerHeight - 2,
    );
    world.add(player);

    // Kill floor
    killFloor = KillFloor();
    world.add(killFloor);

    _cameraTargetY = 0;
    _autoScrollY = 0;
  }

  void _spawnStartingPlatforms() {
    // Ground — full width
    _addPlatform(
      x: 0,
      y: size.y - 60,
      width: size.x,
      isGround: true,
    );
    _highestPlatformY = size.y - 60;

    // A few easy stepping stones above
    for (int i = 0; i < 6; i++) {
      _spawnNextPlatform(forced: true);
    }
  }

  void _spawnNextPlatform({bool forced = false}) {
    final double difficulty = min(_platformCount / 30.0, 1.0);

    final double minWidth = _lerp(size.x * 0.28, size.x * 0.12, difficulty);
    final double maxWidth = _lerp(size.x * 0.45, size.x * 0.25, difficulty);
    final double platformWidth =
        minWidth + _rng.nextDouble() * (maxWidth - minWidth);

    final double maxX = size.x - platformWidth;
    final double x = _rng.nextDouble() * maxX;

    final double spacingVariance = _lerp(20, 40, difficulty);
    final double yGap = platformSpacing + _rng.nextDouble() * spacingVariance;
    final double y = _highestPlatformY - yGap;

    _addPlatform(x: x, y: y, width: platformWidth);
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

  // ── Per-frame update ───────────────────────────────────────────────────────
  @override
  void update(double dt) {
    if (_gameOver) return;
    super.update(dt);

    // Horizontal input → player
    player.moveLeft = _leftDown;
    player.moveRight = _rightDown;

    // ── Auto-scroll speed (scales with floor, capped at max) ─────────────────
    final double scrollT = (currentFloor / _scrollRampFloors).clamp(0.0, 1.0);
    final double scrollSpeed = _lerp(_scrollSpeedMin, _scrollSpeedMax, scrollT);

    // Advance the autonomous scroll upward (negative Y direction)
    _autoScrollY -= scrollSpeed * dt;

    // Player-follow target: keep player ~40% from top
    final double playerFollowY = player.position.y - size.y * 0.4;

    // Camera target = whichever is higher (more negative): player-follow OR auto-scroll.
    // This means: camera chases the player when they're climbing fast,
    // but keeps creeping up on its own when the player stalls.
    _cameraTargetY = min(playerFollowY, _autoScrollY);

    // Smooth lerp toward target — snappy enough to feel responsive
    final double currentCamY = camera.viewfinder.position.y;
    final double newCamY =
        currentCamY + (_cameraTargetY - currentCamY) * 8 * dt;
    camera.viewfinder.position = Vector2(0, newCamY);

    // Keep auto-scroll in sync if camera was already ahead (e.g. player jumped high)
    if (camera.viewfinder.position.y < _autoScrollY) {
      _autoScrollY = camera.viewfinder.position.y;
    }

    // Kill floor: a few floors below the BOTTOM edge of the viewport (invisible)
    killFloor.position.y =
        camera.viewfinder.position.y + size.y + killFloorGrace;

    // Despawn platforms that are too far below
    platforms.removeWhere((p) {
      if (p.position.y > camera.viewfinder.position.y + size.y + 200) {
        p.removeFromParent();
        return true;
      }
      return false;
    });

    // Spawn new platforms ahead of player
    while (_highestPlatformY > camera.viewfinder.position.y - size.y * 0.5) {
      _spawnNextPlatform();
    }

    // Floor score
    final int floor = _worldYToFloor(player.position.y);
    if (floor > currentFloor) {
      currentFloor = floor;
      notifyListeners();
    }

    // Player fell below kill floor (which is already off the bottom of the screen)
    if (player.position.y > killFloor.position.y) {
      _triggerGameOver();
    }
  }

  int _worldYToFloor(double worldY) {
    // Ground is at ~size.y - 60; each platformSpacing ≈ one floor
    final double groundY = size.y - 60;
    return max(0, ((groundY - worldY) / platformSpacing).floor());
  }

  // ── Collision callbacks (called by Player) ─────────────────────────────────
  void onPlayerLandedPlatform(GamePlatform platform) {
    final int floor = _worldYToFloor(platform.position.y);
    if (floor > currentFloor) {
      combo++;
    } else {
      combo = 0;
    }
    notifyListeners();
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  @override
  void onTapDown(TapDownInfo info) {
    final double x = info.eventPosition.global.x;
    if (x < size.x / 2) {
      _leftDown = true;
    } else {
      _rightDown = true;
    }
  }

  @override
  void onTapUp(TapUpInfo info) {
    _leftDown = false;
    _rightDown = false;
  }

  @override
  void onTapCancel() {
    _leftDown = false;
    _rightDown = false;
  }

  // ── Game over ──────────────────────────────────────────────────────────────
  void _triggerGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    if (currentFloor > _bestFloor) _bestFloor = currentFloor;
    onGameOver(currentFloor, _bestFloor);
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
