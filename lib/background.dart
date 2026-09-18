import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'dart:ui' as ui;

class GameBackground extends Component with HasGameRef<FlameGame> {
  static ui.Image? _bgImage;
  static ui.Image? _wallImage;

  static Future<void> preload() async {
    _bgImage = await Flame.images.load('background.png');
    _wallImage = await Flame.images.load('rocky_wall.png');
  }

  @override
  void render(Canvas canvas) {
    final double camY = gameRef.camera.viewfinder.position.y;
    final double w = gameRef.size.x;
    final double h = gameRef.size.y;

    // ── Background ─────────────────────────────────────────────────────────
    final ui.Image? bg = _bgImage;
    if (bg != null) {
      // Tile the square background vertically as the player climbs.
      // Slow parallax: bg scrolls at 30% of camera speed.
      final double parallaxY = camY * 0.30;
      final double tileH = w; // square tile scaled to screen width

      final int startTile = (parallaxY / tileH).floor() - 1;
      final int endTile = ((parallaxY + h) / tileH).ceil() + 1;

      final Paint bgPaint = Paint()..filterQuality = ui.FilterQuality.low;
      for (int t = startTile; t <= endTile; t++) {
        final Rect src =
            Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble());
        final Rect dst =
            Rect.fromLTWH(0, camY + (t * tileH - parallaxY), w, tileH);
        canvas.drawImageRect(bg, src, dst, bgPaint);
      }
    } else {
      // Fallback solid colour
      canvas.drawRect(
        Rect.fromLTWH(0, camY, w, h),
        Paint()..color = const ui.Color(0xFF0D1B0F),
      );
    }

    // ── Side walls ─────────────────────────────────────────────────────────
    final ui.Image? wall = _wallImage;
    if (wall != null) {
      // Wall scrolls at 60% of camera — closer than bg, further than platforms
      final double wallParallaxY = camY * 0.60;
      final double wallW = w * 0.18; // ~18% of screen width each side
      final double wallSrcW = wall.width.toDouble();
      final double wallSrcH = wall.height.toDouble();
      // Scale: fit wall width to wallW, tile vertically
      final double scale = wallW / wallSrcW;
      final double wallTileH = wallSrcH * scale;

      final int startT = (wallParallaxY / wallTileH).floor() - 1;
      final int endT = ((wallParallaxY + h) / wallTileH).ceil() + 1;

      final Paint wallPaint = Paint()
        ..filterQuality = ui.FilterQuality.low
        ..color =
            const ui.Color(0xCCFFFFFF); // slight transparency to not overpower

      final Rect wallSrc = Rect.fromLTWH(0, 0, wallSrcW, wallSrcH);

      for (int t = startT; t <= endT; t++) {
        final double tileY = camY + (t * wallTileH - wallParallaxY);
        // Left wall
        canvas.drawImageRect(wall, wallSrc,
            Rect.fromLTWH(0, tileY, wallW, wallTileH), wallPaint);
        // Right wall (flip horizontally)
        canvas.save();
        canvas.translate(w, tileY);
        canvas.scale(-1, 1);
        canvas.drawImageRect(
            wall, wallSrc, Rect.fromLTWH(0, 0, wallW, wallTileH), wallPaint);
        canvas.restore();
      }
    }
  }
}
