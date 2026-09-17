import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:tower_climb/tower_game.dart';
import 'platform.dart';

class Player extends PositionComponent
    with HasGameRef<TowerGame>, CollisionCallbacks {
  static const double playerWidth = 28.0;
  static const double playerHeight = 40.0;

  static const double gravity = 900.0;
  static const double moveSpeed = 240.0;
  static const double maxHorzSpeed = 320.0;
  static const double friction = 0.82; // applied per frame (exponential decay)

  // Bounce height scales with horizontal speed:
  // faster run → higher bounce
  static const double baseBounceVelocity = -420.0;
  static const double speedBonusFactor = 0.65; // added per unit of |horzVel|

  bool moveLeft = false;
  bool moveRight = false;

  Vector2 _velocity = Vector2.zero();
  bool _onGround = false;

  // Running animation
  int _animFrame = 0;
  double _animTimer = 0;
  static const double _animInterval = 0.1;

  @override
  Future<void> onLoad() async {
    size = Vector2(playerWidth, playerHeight);
    add(
      RectangleHitbox(
        size: Vector2(playerWidth, playerHeight),
        isSolid: true,
      ),
    );
  }

  @override
  void update(double dt) {
    // ── Horizontal movement ──────────────────────────────────────────────────
    if (moveLeft) {
      _velocity.x -= moveSpeed * dt * 6;
    }
    if (moveRight) {
      _velocity.x += moveSpeed * dt * 6;
    }

    // Clamp and apply friction when no input
    if (!moveLeft && !moveRight) {
      _velocity.x *= pow(friction, dt * 60).toDouble();
    }
    _velocity.x = _velocity.x.clamp(-maxHorzSpeed, maxHorzSpeed);

    // ── Gravity ──────────────────────────────────────────────────────────────
    _velocity.y += gravity * dt;

    // ── Move ─────────────────────────────────────────────────────────────────
    position += _velocity * dt;

    // ── Wrap horizontally ─────────────────────────────────────────────────────
    final double screenW = gameRef.size.x;
    if (position.x + playerWidth < 0) position.x = screenW;
    if (position.x > screenW) position.x = -playerWidth;

    _onGround = false;

    // ── Animation ────────────────────────────────────────────────────────────
    if (moveLeft || moveRight) {
      _animTimer += dt;
      if (_animTimer >= _animInterval) {
        _animTimer = 0;
        _animFrame = (_animFrame + 1) % 4;
      }
    } else {
      _animFrame = 0;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is GamePlatform) {
      _handlePlatformCollision(other, intersectionPoints);
    }
  }

  void _handlePlatformCollision(
      GamePlatform platform, Set<Vector2> intersectionPoints) {
    // Only bounce when falling down onto top of platform
    if (_velocity.y <= 0) return;

    // Check player's feet are near top of platform
    final double playerBottom = position.y + playerHeight;
    final double platformTop = platform.position.y;

    if (playerBottom > platformTop + 16) return; // side collision, ignore

    // Snap to platform surface
    position.y = platformTop - playerHeight;
    _velocity.y = 0;
    _onGround = true;

    // Auto-bounce: height proportional to horizontal speed
    final double speedBonus = _velocity.x.abs() * speedBonusFactor;
    _velocity.y = baseBounceVelocity - speedBonus;

    gameRef.onPlayerLandedPlatform(platform);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawCharacter(canvas);
  }

  void _drawCharacter(Canvas canvas) {
    final bool facingLeft = _velocity.x < -10;
    final bool inAir = !_onGround;
    final paint = Paint()..style = PaintingStyle.fill;

    // Flip canvas if facing left
    if (facingLeft) {
      canvas.save();
      canvas.translate(playerWidth, 0);
      canvas.scale(-1, 1);
    }

    // Body colour shifts when comboing
    final Color bodyColor =
        gameRef.combo > 3 ? const Color(0xFFFFCC00) : const Color(0xFF00E5FF);

    // ── Pixel art (6×8 grid, each pixel = 4×5px) ───────────────────────────
    const double px = 4.0;
    const double py = 5.0;

    void pixel(int x, int y, Color c) {
      paint.color = c;
      canvas.drawRect(
        Rect.fromLTWH(x * px + 2, y * py, px - 0.5, py - 0.5),
        paint,
      );
    }

    // Head
    for (int x = 1; x <= 4; x++) {
      pixel(x, 0, const Color(0xFFFFCC88));
      pixel(x, 1, const Color(0xFFFFCC88));
    }
    // Eyes
    pixel(2, 1, const Color(0xFF222244));
    pixel(4, 1, const Color(0xFF222244));

    // Body
    for (int x = 1; x <= 4; x++) {
      for (int y = 2; y <= 4; y++) {
        pixel(x, y, bodyColor);
      }
    }

    // Legs — animated
    final int frame = inAir ? 2 : _animFrame;
    switch (frame % 4) {
      case 0: // stand
        for (int x = 1; x <= 4; x++) {
          pixel(x, 5, const Color(0xFF224488));
          pixel(x, 6, const Color(0xFF224488));
        }
      case 1: // stride a
        pixel(1, 5, const Color(0xFF224488));
        pixel(2, 5, const Color(0xFF224488));
        pixel(3, 6, const Color(0xFF224488));
        pixel(4, 6, const Color(0xFF224488));
        pixel(3, 5, const Color(0xFF224488));
        pixel(4, 5, const Color(0xFF224488));
      case 2: // air / jump
        pixel(1, 5, const Color(0xFF224488));
        pixel(2, 5, const Color(0xFF224488));
        pixel(4, 5, const Color(0xFF224488));
        pixel(5, 5, const Color(0xFF224488));
        pixel(1, 6, const Color(0xFF224488));
        pixel(5, 6, const Color(0xFF224488));
      case 3: // stride b
        pixel(1, 6, const Color(0xFF224488));
        pixel(2, 6, const Color(0xFF224488));
        pixel(3, 5, const Color(0xFF224488));
        pixel(4, 5, const Color(0xFF224488));
        pixel(1, 5, const Color(0xFF224488));
        pixel(4, 6, const Color(0xFF224488));
    }

    // Shoes
    for (int x = 0; x <= 2; x++) pixel(x, 7, Colors.white);
    for (int x = 3; x <= 5; x++) pixel(x, 7, Colors.white);

    if (facingLeft) canvas.restore();
  }
}
