/// Per-sound volume mix, all relative to master volume (0..1).
///
/// One place to balance the game's audio. Background music sits loudest;
/// sound effects sit under it so they never drown the track. Tune here.
class AudioMix {
  AudioMix._();

  /// Background music — the bed everything else sits on.
  static const double bgm = 0.8;

  /// Checkpoint chime — a rare event, mid level.
  static const double checkpoint = 0.4;

  /// UI button click — quiet.
  static const double button = 0.3;

  /// Jump — fires constantly, so quietest.
  static const double jump = 0.2;
}
