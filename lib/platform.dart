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

  // Visual height comes from the sprite row; collision uses the top portion only
  static const double collisionHeight = 14.0;

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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final ui.Image? img = _sheetImage;
    if (img == null) return; // fallback: invisible until loaded

    final _TileRow row = isGround ? _groundRow : _variants[_variantIndex];

    // Source rect — full width of the sheet, the specific row
    final Rect src = Rect.fromLTWH(
      0,
      row.y.toDouble(),
      256,
      row.h.toDouble(),
    );

    // Destination rect — stretch to fit platform width, keep sprite height
    // We draw slightly above y=0 so the sprite's visual body aligns with
    // the collision box top, and the sprite hangs down below.
    final double spriteH = row.h * (size.x / 256); // scale proportionally
    final Rect dst = Rect.fromLTWH(0, 0, size.x, spriteH);

    canvas.drawImageRect(img, src, dst, Paint());
  }
}

class _TileRow {
  final int y;
  final int h;
  const _TileRow({required this.y, required this.h});
}
