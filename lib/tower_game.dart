import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:icy_tower/background.dart';
import 'package:icy_tower/kill_floor.dart';
import 'package:icy_tower/platform.dart';
import 'package:icy_tower/player.dart';

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

  // ── Constants ──────────────────────────────────────────────────────────────
  static const double platformSpacing = 110.0;
  static const double killFloorLag = 420.0; // px below top of viewport

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

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

    final double minWidth = _lerp(size.x * 0.55, size.x * 0.22, difficulty);
    final double maxWidth = _lerp(size.x * 0.75, size.x * 0.42, difficulty);
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

    // Smooth camera follow (chase player upward, never scroll down)
    final double desiredCamY = player.position.y - size.y * 0.4;
    if (desiredCamY < _cameraTargetY) {
      _cameraTargetY = desiredCamY;
    }
    // Smooth lerp toward target
    final double currentCamY = camera.viewfinder.position.y;
    final double newCamY =
        currentCamY + (_cameraTargetY - currentCamY) * 8 * dt;
    camera.viewfinder.position = Vector2(0, newCamY);

    // Kill floor follows camera
    killFloor.position.y = camera.viewfinder.position.y + killFloorLag;

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

    // Player fell below kill floor
    if (player.position.y > killFloor.position.y + 50) {
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
