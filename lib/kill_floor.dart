import 'package:flame/game.dart';
import 'package:flame/components.dart';

/// Invisible death boundary — no UI, just position logic.
/// Renders nothing; the camera scroll itself communicates urgency.
class KillFloor extends PositionComponent with HasGameRef<FlameGame> {
  KillFloor() : super(position: Vector2.zero());

  // Intentionally no render() override — completely invisible.
}
