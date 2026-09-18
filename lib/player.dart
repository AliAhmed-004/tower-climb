import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:ui' as ui;
import 'tower_game.dart';
import 'platform.dart';

class Player extends PositionComponent
    with HasGameRef<TowerGame>, CollisionCallbacks {
  // ── Asset ──────────────────────────────────────────────────────────────────
  // character.png is a single idle frame: 500x500, character at x=134-360, y=45-469
  // We cropped it to 246x444 (character_cropped.png) with 10px padding
  static ui.Image? _sheet;

  static Future<void> preload() async {
    _sheet = await Flame.images.load('character.png');
  }

  // ── Display size ───────────────────────────────────────────────────────────
  // Source is 500x500 with character ~226x424px inside
  // We want the rendered character ~40px wide on screen
  static const double playerWidth = 40.0;
  static const double playerHeight = 75.0; // maintain aspect ~226:424

  // Source rect of the character within the 500x500 image
  static const double _srcX = 124.0;
  static const double _srcY = 35.0;
  static const double _srcW = 246.0;
  static const double _srcH = 444.0;

  // ── Physics ────────────────────────────────────────────────────────────────
  static const double gravity = 900.0;
  static const double moveSpeed = 240.0;
  static const double maxHorzSpeed = 320.0;
  static const double friction = 0.82;
  static const double baseBounceVelocity = -420.0;
  static const double speedBonusFactor = 0.65;

  // ── State ──────────────────────────────────────────────────────────────────
  bool moveLeft = false;
  bool moveRight = false;

  Vector2 _velocity = Vector2.zero();
  bool _onGround = false;
  bool _facingLeft = false;

  // Simple 2-frame bob for idle feel (no full animation yet)
  double _bobTimer = 0;
  double _bobOffset = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    size = Vector2(playerWidth, playerHeight);
    add(RectangleHitbox(size: size, isSolid: true));
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    // Horizontal
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

    // Gravity
    _velocity.y += gravity * dt;

    // Move
    position += _velocity * dt;

    // Horizontal wrap
    final double sw = gameRef.size.x;
    if (position.x + playerWidth < 0) position.x = sw;
    if (position.x > sw) position.x = -playerWidth;

    _onGround = false;

    // Idle bob
    _bobTimer += dt;
    _bobOffset = _onGround ? (sin(_bobTimer * 3.0) * 1.5) : 0;
  }

  // ── Collision ──────────────────────────────────────────────────────────────
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is GamePlatform) _handlePlatformCollision(other);
  }

  void _handlePlatformCollision(GamePlatform platform) {
    if (_velocity.y <= 0) return;
    final double playerBottom = position.y + playerHeight;
    final double platformTop = platform.position.y;
    if (playerBottom > platformTop + 16) return; // side hit

    position.y = platformTop - playerHeight;
    _onGround = true;
    _velocity.y = baseBounceVelocity - _velocity.x.abs() * speedBonusFactor;

    gameRef.onPlayerLandedPlatform(platform);
  }

  // ── Render ─────────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ui.Image? img = _sheet;
    if (img == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, _bobOffset, playerWidth, playerHeight),
        Paint()..color = const ui.Color(0xFF5C8A3C),
      );
      return;
    }

    final Rect src = Rect.fromLTWH(_srcX, _srcY, _srcW, _srcH);
    final Rect dst = Rect.fromLTWH(0, _bobOffset, playerWidth, playerHeight);

    if (_facingLeft) {
      // Flip horizontally around the centre of the sprite
      canvas.save();
      canvas.translate(playerWidth, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(
          img, src, dst, Paint()..filterQuality = ui.FilterQuality.medium);
      canvas.restore();
    } else {
      canvas.drawImageRect(
          img, src, dst, Paint()..filterQuality = ui.FilterQuality.medium);
    }
  }
}
