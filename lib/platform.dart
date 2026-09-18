import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:ui' as ui;

class GamePlatform extends PositionComponent {
  static const double collisionHeight = 20.0;
  static const double renderHeight = 32.0; // sprite renders slightly taller

  static ui.Image? _floorImage;

  static Future<void> preload() async {
    _floorImage = await Flame.images.load('rocky_floor.png');
  }

  final bool isGround;

  GamePlatform({
    required Vector2 position,
    required double width,
    this.isGround = false,
    Random? rng,
  }) : super(
          position: position,
          size: Vector2(width, collisionHeight),
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(size: size, isSolid: false));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ui.Image? img = _floorImage;
    if (img == null) {
      // Fallback: plain rect
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, collisionHeight),
        Paint()..color = const ui.Color(0xFF4A6741),
      );
      return;
    }

    final double srcW = img.width.toDouble();
    final double srcH = img.height.toDouble();

    // Scale one tile so its height == renderHeight, then tile horizontally
    final double tileScreenW = srcW * (renderHeight / srcH);

    final Paint paint = Paint()..filterQuality = ui.FilterQuality.medium;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, renderHeight));

    double drawnX = 0;
    while (drawnX < size.x) {
      final double drawW = (size.x - drawnX).clamp(0, tileScreenW);
      final double srcDrawW = srcW * (drawW / tileScreenW);

      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, srcDrawW, srcH),
        Rect.fromLTWH(drawnX, 0, drawW, renderHeight),
        paint,
      );
      drawnX += tileScreenW;
    }

    canvas.restore();
  }
}
