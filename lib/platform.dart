import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'dart:ui' as ui;

class GamePlatform extends PositionComponent {
  // Sprite source rects in earthy_floors.png (256px wide sheet)
  // Each entry is the y-start of a platform row in the sheet.
  // We measured 8 rows; we use the cleanest-looking ones.
  static const List<_TileRow> _variants = [
    _TileRow(y: 0, h: 24), // variant 0 — clean cracked stone
    _TileRow(y: 25, h: 23), // variant 1 — mossy cracks
    _TileRow(y: 51, h: 28), // variant 2 — wider stone
    _TileRow(y: 82, h: 28), // variant 3
    _TileRow(y: 112, h: 32), // variant 4
    _TileRow(y: 146, h: 29), // variant 5
    _TileRow(y: 178, h: 26), // variant 6
  ];

  // Ground uses the last row (tallest, most detailed)
  static const _TileRow _groundRow = _TileRow(y: 208, h: 48);

  // Shared spritesheet image — loaded once, reused by all instances
  static ui.Image? _sheetImage;

  static Future<void> preload() async {
    _sheetImage = await Flame.images.load('earthy_floors.png');
  }

  // ── Fields ──────────────────────────────────────────────────────────────────
  final bool isGround;
  final int _variantIndex;

  // Collision height matches render height so landing feels accurate
  static const double collisionHeight = 20.0;

  GamePlatform({
    required Vector2 position,
    required double width,
    this.isGround = false,
    int? variantIndex,
    Random? rng,
  })  : _variantIndex =
            variantIndex ?? (rng ?? Random()).nextInt(_variants.length),
        super(
          position: position,
          size: Vector2(width, collisionHeight),
        );

  @override
  Future<void> onLoad() async {
    // Collision box only covers the top surface where the player lands
    add(
      RectangleHitbox(
        size: Vector2(size.x, collisionHeight),
        isSolid: false,
      ),
    );
  }

  // How tall the platform renders on screen (logical pixels).
  // Kept fixed regardless of platform width so it never looks magnified.
  static const double renderHeight = 20.0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ui.Image? img = _sheetImage;
    if (img == null) return;

    final _TileRow row = isGround ? _groundRow : _variants[_variantIndex];

    // Tile the sprite across the platform width at a fixed render height.
    // This means a wide platform shows multiple repetitions of the texture
    // rather than one blurry stretched copy — much crisper at any width.
    const double srcW = 256.0;
    final double srcH = row.h.toDouble();

    // How wide one tile is on screen, scaled so height == renderHeight
    final double tileScreenW = srcW * (renderHeight / srcH);

    final Paint paint = Paint();
    double drawnX = 0.0;

    canvas.save();
    // Clip so the last tile doesn't overdraw past the platform edge
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, renderHeight));

    while (drawnX < size.x) {
      // For the last tile, only draw as much of the source as needed
      final double remaining = size.x - drawnX;
      final double drawW = remaining.clamp(0, tileScreenW);
      final double srcDrawW = srcW * (drawW / tileScreenW);

      final Rect src = Rect.fromLTWH(0, row.y.toDouble(), srcDrawW, srcH);
      final Rect dst = Rect.fromLTWH(drawnX, 0, drawW, renderHeight);

      canvas.drawImageRect(img, src, dst, paint);
      drawnX += tileScreenW;
    }

    canvas.restore();
  }
}

class _TileRow {
  final int y;
  final int h;
  const _TileRow({required this.y, required this.h});
}
