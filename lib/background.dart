import 'dart:ui';

import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'tower_game.dart';

class GameBackground extends Component with HasGameReference<TowerGame> {
  GameBackground() : super(priority: -100);

  @override
  void render(Canvas canvas) {
    final TowerGame g = game;
    final double camY = g.camera.viewfinder.position.y;
    final double w = g.size.x;
    final double h = g.size.y;
    final double visualFloor = g.visualFloor;
    final int stageFloor = visualFloor.floor();
    final double blend = g.stageManager.blendFactor(visualFloor);

    final ui.Image? bgCurrent = g.stageManager.bgImage(stageFloor);
    final ui.Image? bgNext = g.stageManager.bgImageNext(stageFloor);

    // Fill fallback
    canvas.drawRect(
      Rect.fromLTWH(0, camY, w, h),
      Paint()..color = const ui.Color(0xFF0D1B0F),
    );

    if (bgCurrent != null) {
      _drawBgTiled(canvas, bgCurrent, camY, w, h, 1.0);
    }

    // Blend next stage background on top
    if (bgNext != null && blend > 0) {
      _drawBgTiled(canvas, bgNext, camY, w, h, blend);
    }

    // Glitch mode flicker
    if (g.stageManager.isGlitchMode(stageFloor)) {
      g.stageManager.updateGlitch(0); // timer driven by tower_game
    }
  }

  void _drawBgTiled(
    Canvas canvas,
    ui.Image img,
    double camY,
    double w,
    double h,
    double opacity,
  ) {
    final double imgW = img.width.toDouble();
    final double imgH = img.height.toDouble();

    // Scale image to fill screen width, maintain aspect ratio
    final double scale = w / imgW;
    final double tileH = imgH * scale;

    // Parallax: bg scrolls at 40% of camera speed
    final double parallaxY = camY * 0.40;

    // Which tiles are visible + 1 buffer below (for despawn safety)
    final int startTile = (parallaxY / tileH).floor() - 1;
    final int endTile = ((parallaxY + h) / tileH).ceil() + 1; // +1 buffer below

    final Paint paint = Paint()
      ..filterQuality = ui.FilterQuality.low
      ..color = ui.Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));

    final Rect src = Rect.fromLTWH(0, 0, imgW, imgH);

    for (int t = startTile; t <= endTile; t++) {
      final double tileY = camY + (t * tileH - parallaxY);

      // Bottom-edge gradient fade to hide the seam between tiles
      // Draw tile
      canvas.drawImageRect(
        img,
        src,
        Rect.fromLTWH(0, tileY, w, tileH),
        paint,
      );
    }
  }
}
