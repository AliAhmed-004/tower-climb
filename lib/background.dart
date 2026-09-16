import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A simple infinite tiling background that scrolls with the world.
class GameBackground extends Component with HasGameRef<FlameGame> {
  static const double _tileH = 120.0;

  // Pre-defined star positions per tile row (x fraction, size)
  static const List<(double, double)> _starPattern = [
    (0.08, 1.2), (0.23, 0.8), (0.51, 1.5), (0.74, 1.0), (0.91, 0.7),
    (0.14, 0.9), (0.38, 1.3), (0.62, 0.6), (0.85, 1.1),
    (0.05, 0.8), (0.30, 1.0), (0.55, 1.4), (0.78, 0.9), (0.96, 1.2),
  ];

  @override
  void render(Canvas canvas) {
    final double camY = gameRef.camera.viewfinder.position.y;
    final double w = gameRef.size.x;
    final double h = gameRef.size.y;

    // Fill base
    canvas.drawRect(
      Rect.fromLTWH(0, camY, w, h),
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Tile stars across visible area
    final int startTile = (camY / _tileH).floor() - 1;
    final int endTile = ((camY + h) / _tileH).ceil() + 1;

    final starPaint = Paint()..color = Colors.white.withOpacity(0.45);
    for (int t = startTile; t <= endTile; t++) {
      final double tileY = t * _tileH;
      // Use tile index to vary which stars are "bright"
      final int offset = t.abs() % _starPattern.length;
      for (int i = 0; i < _starPattern.length; i++) {
        final (double xf, double sz) = _starPattern[(i + offset) % _starPattern.length];
        final bool bright = (i + t) % 7 == 0;
        starPaint.color = bright
            ? Colors.white.withOpacity(0.7)
            : Colors.white.withOpacity(0.25);
        canvas.drawCircle(
          Offset(xf * w, tileY + (i * _tileH / _starPattern.length)),
          sz,
          starPaint,
        );
      }
    }

    // Subtle height-based gradient tint — gets more purple as you go higher
    // (higher = more negative Y in world space)
    final double heightFraction =
        ((-camY) / 5000.0).clamp(0.0, 1.0);
    if (heightFraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, camY, w, h),
        Paint()
          ..color =
              const Color(0xFF220044).withOpacity(heightFraction * 0.35),
      );
    }
  }
}
