import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// An invisible (but rendered) death line that rises with the camera.
class KillFloor extends PositionComponent with HasGameRef<FlameGame> {
  KillFloor() : super(position: Vector2.zero());

  @override
  void render(Canvas canvas) {
    final double w = gameRef.size.x;

    // Danger line
    final linePaint = Paint()
      ..color = const Color(0xAAFF2244)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, 0), Offset(w, 0), linePaint);

    // Glow below
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x44FF2244),
          const Color(0x00FF2244),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, 40));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 40), glowPaint);
  }
}
