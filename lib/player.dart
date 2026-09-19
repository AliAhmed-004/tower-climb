import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:ui' as ui;
import 'tower_game.dart';
import 'platform.dart';

class Player extends PositionComponent
    with HasGameReference<TowerGame>, CollisionCallbacks {
  // ── Asset ──────────────────────────────────────────────────────────────────
  static ui.Image? _sheet;
  static Future<void> preload() async {
    _sheet = await Flame.images.load('character.png');
  }

  // ── Display size ───────────────────────────────────────────────────────────
  // character.png is the tight-cropped idle frame
  static const double playerWidth = 40.0;

  // Source rect — full image is the character, no wasted padding
  static const double _srcX = 0;
  static const double _srcY = 0;
  static const double _srcW = 500.0; // update if image differs
  static const double _srcH = 500.0;

  // Rendered height maintains 1:1 aspect of the source
  static const double _charRenderH =
      playerWidth * (_srcH / _srcW); // = 40px for 1:1

  // Hitbox covers lower 85% — excludes a little head clearance
  static const double hitboxH = _charRenderH * 0.85;
  static const double hitboxOffsetY = _charRenderH - hitboxH;

  // ── Physics ────────────────────────────────────────────────────────────────
  static const double gravity = 900.0;
  static const double moveSpeed = 240.0;
  static const double maxHorzSpeed = 340.0;
  static const double friction = 0.82;
  static const double baseBounceVelocity = -420.0;
  static const double speedBonusFactor = 0.60;

  // ── State ──────────────────────────────────────────────────────────────────
  bool moveLeft = false;
  bool moveRight = false;

  final Vector2 _velocity = Vector2.zero();
  bool _facingLeft = false;

  double _bobTimer = 0;
  double _bobOffset = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    size = Vector2(playerWidth, _charRenderH);
    add(RectangleHitbox(
      size: Vector2(playerWidth, hitboxH),
      position: Vector2(0, hitboxOffsetY),
      isSolid: true,
    ));
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    if (moveLeft) {
      _velocity.x -= moveSpeed * dt * 6;
      _facingLeft = true;
    }
    if (moveRight) {
      _velocity.x += moveSpeed * dt * 6;
      _facingLeft = false;
    }

    if (!moveLeft && !moveRight) {
      _velocity.x *= pow(friction, dt * 60).toDouble();
    }
    _velocity.x = _velocity.x.clamp(-maxHorzSpeed, maxHorzSpeed);

    _velocity.y += gravity * dt;
    position += _velocity * dt;

    // Solid walls — clamp position and kill horizontal velocity on impact
    game.clampPlayerToWalls();

    _bobTimer += dt;
    _bobOffset = sin(_bobTimer * 3.0) * 1.0;
  }

  /// Horizontal-only movement for waiting / checkpoint states (no gravity/bounce).
  void groundSlide(double dt, {required bool braking}) {
    if (!braking) {
      if (moveLeft) {
        _velocity.x -= moveSpeed * dt * 6;
        _facingLeft = true;
      }
      if (moveRight) {
        _velocity.x += moveSpeed * dt * 6;
        _facingLeft = false;
      }
    }
    _velocity.x *= pow(friction, dt * 60).toDouble();
    _velocity.x = _velocity.x.clamp(-maxHorzSpeed, maxHorzSpeed);
    position.x += _velocity.x * dt;

    _bobTimer += dt;
    _bobOffset = sin(_bobTimer * 3.0) * 1.0;
  }

  /// Zero horizontal velocity — called on wall impact.
  void zeroVelocityX() => _velocity.x = 0;

  // ── Collision ──────────────────────────────────────────────────────────────
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is GamePlatform) _handlePlatformCollision(other);
  }

  void _handlePlatformCollision(GamePlatform platform) {
    if (_velocity.y <= 0) return;

    final double feetY = position.y + hitboxOffsetY + hitboxH;
    final double platformTop = platform.position.y;
    if (feetY > platformTop + 16) return; // side hit

    // Snap feet to platform surface
    position.y = platformTop - hitboxOffsetY - hitboxH;

    if (platform.isCheckpoint && game.gameState == GameState.checkpoint) {
      // On checkpoint floor: pin player, no bounce
      _velocity.y = 0;
      game.onPlayerLandedPlatform(platform);
      return;
    }

    // Normal auto-bounce: height scales with horizontal speed
    _velocity.y = baseBounceVelocity - _velocity.x.abs() * speedBonusFactor;
    game.onPlayerLandedPlatform(platform);
  }

  // ── Render ─────────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ui.Image? img = _sheet;
    if (img == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, _bobOffset, playerWidth, _charRenderH),
        Paint()..color = const ui.Color(0xFF5C8A3C),
      );
      return;
    }

    final Rect src = const Rect.fromLTWH(_srcX, _srcY, _srcW, _srcH);
    final Rect dst = Rect.fromLTWH(0, _bobOffset, playerWidth, _charRenderH);
    final paint = Paint()..filterQuality = ui.FilterQuality.medium;

    if (_facingLeft) {
      canvas.save();
      canvas.translate(playerWidth, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(img, src, dst, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(img, src, dst, paint);
    }
  }
}
