import 'package:flame_audio/flame_audio.dart'; // re-exports audioplayers' AudioPlayer
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_config.dart';
import 'stage_manager.dart';

/// Per-biome background music with cross-biome crossfade.
///
/// Convention: each biome plays `<name>/<name>_bgm.mp3`. Add a biome (a new
/// [StageConfig] + its mp3) and it plays with no code change here. A biome
/// with no bgm file is silently skipped.
///
/// Volumes track [StageManager.blendFactor] — the same 0→1 ramp over floors
/// 70–99 the visuals crossfade on — so audio hands off in lockstep with the
/// picture. Reconciles at most two live tracks (current + incoming) per frame.
class BiomeBgm {
  BiomeBgm();

  final Map<String, AudioPlayer> _players = {};
  final Set<String> _loading = {};
  final Set<String> _missing = {}; // biomes with no bgm file — don't retry
  bool _paused = false;

  String _path(String biome) => '$biome/${biome}_bgm.mp3';

  Future<void> _ensure(String biome) async {
    if (_players.containsKey(biome) ||
        _loading.contains(biome) ||
        _missing.contains(biome)) {
      return;
    }
    _loading.add(biome);
    try {
      // Start silent; the next update() frame sets the real volume.
      final player = await FlameAudio.loop(_path(biome), volume: 0);
      if (_paused) await player.pause();
      _players[biome] = player;
    } catch (_) {
      _missing.add(biome); // asset absent — stay quiet for this biome
    } finally {
      _loading.remove(biome);
    }
  }

  /// Call every frame with the live floor and master volume.
  void update(StageManager stages, int floor, double master) {
    if (_paused) return;

    final String current = stages.currentStage(floor).name;
    final double blend = stages.blendFactor(floor); // 0 until floor 70
    final String? next = stages.nextStage(floor)?.name;

    final Map<String, double> want = {current: 1.0 - blend};
    if (blend > 0 && next != null) want[next] = blend;

    want.keys.forEach(_ensure);

    for (final entry in _players.entries.toList()) {
      final double? mix = want[entry.key];
      if (mix == null) {
        entry.value.stop();
        entry.value.dispose();
        _players.remove(entry.key);
      } else {
        entry.value.setVolume((master * AudioMix.bgm * mix).clamp(0.0, 1.0));
      }
    }
  }

  Future<void> pause() async {
    _paused = true;
    for (final p in _players.values) {
      await p.pause();
    }
  }

  Future<void> resume() async {
    _paused = false;
    for (final p in _players.values) {
      await p.resume();
    }
  }

  Future<void> stopAll() async {
    for (final p in _players.values) {
      await p.stop();
      await p.dispose();
    }
    _players.clear();
    _loading.clear();
    _missing.clear();
    _paused = false;
  }
}

class GameAudioManager {
  GameAudioManager._();
  static final GameAudioManager instance = GameAudioManager._();

  static const _masterVolumeKey = 'master_volume';
  double masterVolume = 1.0;
  SharedPreferences? _preferences;

  final BiomeBgm biomeBgm = BiomeBgm();

  // Pooled sfx players. FlameAudio.play() leaks a native player per call
  // (audioplayers never disposes it), which piles up over a run. Pools reuse a
  // fixed set of players instead.
  AudioPool? _jumpPool;
  AudioPool? _buttonPool;
  AudioPool? _checkpointPool;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    masterVolume = _preferences?.getDouble(_masterVolumeKey) ?? 1.0;
    _jumpPool = await _makePool('jump.wav', 4); // overlaps on fast bounces
    _buttonPool = await _makePool('button_click.wav', 2);
    _checkpointPool = await _makePool('checkpoint.wav', 2);
  }

  Future<AudioPool?> _makePool(String file, int maxPlayers) async {
    try {
      return await FlameAudio.createPool(file, minPlayers: 1, maxPlayers: maxPlayers);
    } catch (_) {
      return null; // missing asset tolerated
    }
  }

  Future<void> setMasterVolume(double value) async {
    masterVolume = value.clamp(0.0, 1.0);
    await _preferences?.setDouble(_masterVolumeKey, masterVolume);
    // Background volume follows on the next frame's biomeBgm.update().
  }

  Future<void> _play(AudioPool? pool, double mix) async {
    if (pool == null) return; // missing asset
    await pool.start(volume: (masterVolume * mix).clamp(0.0, 1.0));
  }

  Future<void> playButtonClick() => _play(_buttonPool, AudioMix.button);

  Future<void> playCheckpoint() => _play(_checkpointPool, AudioMix.checkpoint);

  // Jump is shared across biomes for now; add per-biome overrides here later.
  Future<void> playJumpForBiome(String biome) => _play(_jumpPool, AudioMix.jump);
}
