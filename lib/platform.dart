import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GamePlatform extends PositionComponent {
  static const double platformHeight = 14.0;

  final bool isGround;

  GamePlatform({
    required Vector2 position,
    required double width,
    this.isGround = false,
  }) : super(
          position: position,
          size: Vector2(width, platformHeight),
        );

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: size,
        isSolid: false,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Paint topPaint = Paint()
      ..color = isGround
          ? const Color(0xFF00E5FF)
          : const Color(0xFF4488FF)
      ..style = PaintingStyle.fill;

    final Paint bodyPaint = Paint()
      ..color = isGround
          ? const Color(0xFF0077AA)
          : const Color(0xFF223366)
      ..style = PaintingStyle.fill;

    final Paint edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final double w = size.x;
    final double h = size.y;

    // Body
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 3, w, h - 3),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      ),
      bodyPaint,
    );

    // Top surface
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, w, 5),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
      topPaint,
    );

    // Shine strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 1, w - 8, 2),
        const Radius.circular(1),
      ),
      edgePaint,
    );

    // Pixel notches (icy tower style)
    final Paint notchPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (double nx = 8; nx < w - 8; nx += 18) {
      canvas.drawRect(Rect.fromLTWH(nx, 4, 8, 4), notchPaint);
    }
  }
}
