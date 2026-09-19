import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'tower_game.dart';

class GamePlatform extends PositionComponent with HasGameReference<TowerGame> {
  static const double collisionHeight = 20.0;
  static const double renderHeight = 32.0;

  final bool isCheckpoint;

  // Each platform captures its blend state at spawn time so it doesn't
  // change appearance mid-screen as the player climbs
  final ui.Image? _floorImg;
  final ui.Image? _floorImgNext;
  final double _blendAtSpawn;

  GamePlatform({
    required Vector2 position,
    required double width,
    this.isCheckpoint = false,
    required ui.Image? floorImg,
    required ui.Image? floorImgNext,
    required double blendAtSpawn,
  })  : _floorImg = floorImg,
        _floorImgNext = floorImgNext,
        _blendAtSpawn = blendAtSpawn,
        super(
          position: position,
          size: Vector2(width, collisionHeight),
          priority: 0,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(size: size, isSolid: false));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_floorImg == null) {
      // Fallback rect
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, renderHeight),
        Paint()..color = const ui.Color(0xFF4A6741),
      );
      return;
    }

    _drawTiledFloor(canvas, _floorImg!, 1.0);

    if (_floorImgNext != null && _blendAtSpawn > 0) {
      _drawTiledFloor(canvas, _floorImgNext!, _blendAtSpawn);
    }

    // Checkpoint gets a bright top rim to make it visually distinct
    if (isCheckpoint) {
      final ui.Gradient rimGrad = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, 5),
        [
          const ui.Color(0xCCFFE066),
          const ui.Color(0x00FFE066),
        ],
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, 5),
        Paint()..shader = rimGrad,
      );
    }

    // Standard top-edge highlight + drop shadow for all platforms
    final ui.Gradient topRim = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, 4),
      [
        const ui.Color(0x99FFFFFF),
        const ui.Color(0x00FFFFFF),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 4),
      Paint()..shader = topRim,
    );

    final ui.Gradient shadow = ui.Gradient.linear(
      Offset(0, renderHeight),
      Offset(0, renderHeight + 10),
      [
        const ui.Color(0x55000000),
        const ui.Color(0x00000000),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(-2, renderHeight, size.x + 4, 10),
      Paint()..shader = shadow,
    );
  }

  void _drawTiledFloor(Canvas canvas, ui.Image img, double opacity) {
    final double srcW = img.width.toDouble();
    final double srcH = img.height.toDouble();
    final double tileW = srcW * (renderHeight / srcH);

    final Paint paint = Paint()
      ..filterQuality = ui.FilterQuality.medium
      ..color = ui.Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, renderHeight));

    double drawnX = 0;
    while (drawnX < size.x) {
      final double drawW = (size.x - drawnX).clamp(0, tileW);
      final double srcDrawW = srcW * (drawW / tileW);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, srcDrawW, srcH),
        Rect.fromLTWH(drawnX, 0, drawW, renderHeight),
        paint,
      );
      drawnX += tileW;
    }

    canvas.restore();
  }
}
