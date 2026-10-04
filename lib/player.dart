import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:ui' as ui;
import 'audio_manager.dart';
import 'tower_game.dart';
import 'platform.dart';

class Player extends PositionComponent
    with HasGameReference<TowerGame>, CollisionCallbacks {
  Player() : super(priority: 10);

  // ── Asset ──────────────────────────────────────────────────────────────────
  static ui.Image? _sheet;
  static Future<void> preload() async {
    _sheet = await Flame.images.load('character_chubby_64.png');
  }

  // ── Display size ───────────────────────────────────────────────────────────
  // playerWidth = on-screen width of the VISIBLE character. Change this one
  // number to resize him; everything (box, hitbox, sprite) scales with it.
  static const double playerWidth = 44.0;

  // Sprite frame is 64x64; the visible character occupies this box inside it.
  static const double _frameSize = 64.0;
  static const double _visX = 8.0;
  static const double _visY = 3.0;
  static const double _visW = 48.0;
  static const double _visH = 59.0;

  // On-screen pixels per sprite pixel.
  static const double _scale = playerWidth / _visW;

  // Component height = visible character height (feet = bottom edge).
  static const double _charRenderH = _visH * _scale;

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

  // ── Juice tuning ───────────────────────────────────────────────────────────
  // Bounce speeds: base 420, max ~624 (full horizontal speed).
  // A flip needs BOTH a strong bounce AND an upward combo (consecutive
  // landings on higher floors), so bouncing in place never spins.
  static const double spin1Speed = 520.0; // bounce speed for 1 flip...
  static const int spin1Combo = 3; //        ...and combo needed
  static const double spin2Speed = 600.0; // bounce speed for 2 flips...
  static const int spin2Combo = 7; //        ...and combo needed
  static const double _spinStart = 0.02; // jump progress where spin begins
  static const double _spinEnd = 0.92; // ...and where he must be upright again

  static const double _airStretchMax = 0.16; // extra height at full speed
  static const double _landSquashMin = 0.10; // squash on a soft landing
  static const double _landSquashMax = 0.30; // squash on a hard landing
  static const double _springK = 420.0; // landing spring stiffness
  static const double _springC = 17.0; // landing spring damping (lower = bouncier)
  static const double _maxLean = 0.16; // radians (~9°) at full horizontal speed

  // ── State ──────────────────────────────────────────────────────────────────
  bool moveLeft = false;
  bool moveRight = false;

  final Vector2 _velocity = Vector2.zero();
  bool _facingLeft = false;

  // Jump bookkeeping
  double _launchVy = baseBounceVelocity; // vy at the last bounce (negative)
  int _spins = 0; // full rotations for the current bounce
  double _spinDir = 1.0;

  // Visual state (all smooth, nothing ever snaps)
  double _time = 0;
  double _sq = 0; // landing squash spring displacement
  double _sqVel = 0;
  double _air = 0; // velocity-driven stretch (smoothed)
  double _lean = 0; // smoothed lean angle
  double _spinAngle = 0;

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
    if (game.gameState == GameState.paused) return;

    _time += dt;

    // Waiting / checkpoint: no physics, but he still breathes and settles.
    if (game.gameState == GameState.waiting ||
        game.gameState == GameState.checkpoint) {
      _updateVisuals(dt);
      return;
    }

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

    _updateVisuals(dt);
  }

  /// Everything cosmetic: squash spring, air stretch, lean, spin angle.
  void _updateVisuals(double dt) {
    final double d = dt.clamp(0.0, 0.05).toDouble();

    // Landing spring (sub-stepped so a lag spike can't blow it up)
    double remaining = d;
    while (remaining > 0) {
      final double h = min(remaining, 1 / 120);
      final double acc = -_springK * _sq - _springC * _sqVel;
      _sqVel += acc * h;
      _sq += _sqVel * h;
      remaining -= h;
    }

    final bool playing = game.gameState == GameState.playing;

    // Stretch with vertical speed, relaxed at the apex.
    final double airTarget =
        playing ? (_velocity.y.abs() / 700).clamp(0.0, 1.0) * _airStretchMax : 0.0;
    _air += (airTarget - _air) * min(1.0, 14 * d);

    // Lean into horizontal movement.
    final double leanTarget = (_velocity.x / maxHorzSpeed) * _maxLean;
    _lean += (leanTarget - _lean) * min(1.0, 10 * d);

    // Spin: driven by jump progress, finishes exactly upright before landing.
    if (playing && _spins > 0) {
      final double p =
          ((_velocity.y - _launchVy) / (-2 * _launchVy)).clamp(0.0, 1.0);
      final double t = ((p - _spinStart) / (_spinEnd - _spinStart))
          .clamp(0.0, 1.0)
          .toDouble();
      // Mostly linear (constant speed) with softened ends. Pure smoothstep
      // peaks at 1.5x average speed, which made flips look frantic.
      final double eased = 0.5 * t + 0.5 * (t * t * (3 - 2 * t));
      _spinAngle = _spinDir * _spins * 2 * pi * eased;
    } else {
      _spinAngle = 0;
    }
  }

  /// Single place that launches the player upward.
  void _bounce(double vy) {
    // Hit harder → squash deeper.
    final double impact = (_velocity.y.abs() / 700).clamp(0.0, 1.0).toDouble();
    _sq = -(_landSquashMin + (_landSquashMax - _landSquashMin) * impact);
    _sqVel = 0;

    _velocity.y = vy;
    _launchVy = vy;

    _spins = 0;
    _spinDir = _velocity.x < -20
        ? -1.0
        : (_velocity.x > 20 ? 1.0 : (_facingLeft ? -1.0 : 1.0));
  }

  /// Decide how many flips this bounce earns. Must run AFTER the game has
  /// updated its combo for the landing that just happened.
  void _assignSpins() {
    final double speed = _launchVy.abs();
    final int combo = game.combo;
    if (speed >= spin2Speed && combo >= spin2Combo) {
      _spins = 2;
    } else if (speed >= spin1Speed && combo >= spin1Combo) {
      _spins = 1;
    } else {
      _spins = 0;
    }
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
  }

  /// Zero horizontal velocity — called on wall impact.
  void zeroVelocityX() => _velocity.x = 0;

  void stopVerticalMotion() => _velocity.y = 0;

  void resumeFromCheckpoint() {
    _bounce(baseBounceVelocity - _velocity.x.abs() * speedBonusFactor);
    _assignSpins();
  }

  void launchFromStart() {
    _bounce(baseBounceVelocity);
    _assignSpins();
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

    final double feetY = position.y + hitboxOffsetY + hitboxH;
    final double platformTop = platform.position.y;
    if (feetY > platformTop + 16) return; // side hit

    // Snap feet to platform surface
    position.y = platformTop - hitboxOffsetY - hitboxH;

    if (platform.isCheckpoint && game.gameState == GameState.checkpoint) {
      // On checkpoint floor: pin player, no bounce — just a landing squash.
      _sq = -0.25;
      _sqVel = 0;
      _spins = 0;
      _velocity.y = 0;
      game.onPlayerLandedPlatform(platform);
      return;
    }

    // Normal auto-bounce: height scales with horizontal speed
    _bounce(baseBounceVelocity - _velocity.x.abs() * speedBonusFactor);
    if (game.gameState == GameState.playing) {
      final biome = game.stageManager.currentStage(platform.floor).name;
      GameAudioManager.instance.playJumpForBiome(biome);
    }
    game.onPlayerLandedPlatform(platform); // updates game.combo
    _assignSpins();
  }

  // ── Render ─────────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ui.Image? img = _sheet;
    if (img == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, playerWidth, _charRenderH),
        Paint()..color = const ui.Color(0xFF5C8A3C),
      );
      return;
    }

    final bool grounded = game.gameState == GameState.waiting ||
        game.gameState == GameState.checkpoint;

    // Total stretch: + = taller/thinner, − = squashed/wider.
    double s = _sq + _air;
    if (grounded) s += sin(_time * 2.6) * 0.025; // idle breathing
    s = s.clamp(-0.4, 0.4).toDouble();
    final double sy = 1 + s;
    final double sx = 1 - s * 0.6; // cartoon volume preservation

    final Rect src = Rect.fromLTWH(0, 0, _frameSize, _frameSize);
    final Rect dst = Rect.fromLTWH(
      -_visX * _scale,
      -_visY * _scale,
      _frameSize * _scale,
      _frameSize * _scale,
    );

    // Smooth scaling/rotation: nearest-neighbour shimmers when stretched.
    final paint = Paint()..filterQuality = ui.FilterQuality.medium;

    canvas.save();
    canvas.translate(playerWidth / 2, _charRenderH); // feet = scale anchor
    canvas.scale(sx, sy);
    canvas.translate(0, -_charRenderH / 2); // body centre = rotation pivot
    canvas.rotate(_lean + _spinAngle);
    if (_facingLeft) canvas.scale(-1, 1); // flip AFTER rotate: spin stays correct
    canvas.translate(-playerWidth / 2, -_charRenderH / 2);
    canvas.drawImageRect(img, src, dst, paint);
    canvas.restore();
  }
}
