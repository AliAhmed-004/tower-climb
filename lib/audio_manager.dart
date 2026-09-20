import 'package:flame_audio/flame_audio.dart';

class BiomeAudioProfile {
  final String jumpAsset;
  final String? backgroundAsset;
  final double jumpVolumeScale;
  final double backgroundVolumeScale;

  const BiomeAudioProfile({
    required this.jumpAsset,
    this.backgroundAsset,
    this.jumpVolumeScale = 1.0,
    this.backgroundVolumeScale = 0.6,
  });
}

class GameAudioManager {
  GameAudioManager._();
  static final GameAudioManager instance = GameAudioManager._();

  double masterVolume = 1.0;

  final Map<String, BiomeAudioProfile> _biomes = {
    'mossy': const BiomeAudioProfile(
      jumpAsset: 'jump.wav',
      backgroundAsset: null,
      jumpVolumeScale: 1.0,
      backgroundVolumeScale: 0.6,
    ),
    'ancient_civilization': const BiomeAudioProfile(
      jumpAsset: 'jump.wav',
      backgroundAsset: null,
      jumpVolumeScale: 1.0,
      backgroundVolumeScale: 0.6,
    ),
    'eroded': const BiomeAudioProfile(
      jumpAsset: 'jump.wav',
      backgroundAsset: null,
      jumpVolumeScale: 1.0,
      backgroundVolumeScale: 0.6,
    ),
    'desert': const BiomeAudioProfile(
      jumpAsset: 'jump.wav',
      backgroundAsset: null,
      jumpVolumeScale: 1.0,
      backgroundVolumeScale: 0.6,
    ),
    'snowy': const BiomeAudioProfile(
      jumpAsset: 'jump.wav',
      backgroundAsset: null,
      jumpVolumeScale: 1.0,
      backgroundVolumeScale: 0.6,
    ),
    'volcanic': const BiomeAudioProfile(
      jumpAsset: 'jump.wav',
      backgroundAsset: null,
      jumpVolumeScale: 1.0,
      backgroundVolumeScale: 0.6,
    ),
  };

  Future<void> init() async {
    await FlameAudio.audioCache.loadAll([
      'button_click.wav',
      'jump.wav',
      'checkpoint.wav',
    ]);
  }

  Future<void> playSfx(
    String assetName, {
    double? volume,
  }) async {
    final safeVolume = (volume ?? masterVolume).clamp(0.0, 1.0);

    try {
      await FlameAudio.play(assetName, volume: safeVolume);
    } catch (_) {
      // Missing asset is tolerated until biome-specific sounds are added.
    }
  }

  Future<void> playButtonClick() =>
      playSfx('button_click.wav', volume: masterVolume);

  Future<void> playCheckpoint() =>
      playSfx('checkpoint.wav', volume: masterVolume);

  Future<void> playJumpForBiome(String biome) {
    final profile = _biomes[biome] ?? const BiomeAudioProfile(jumpAsset: 'jump.wav');
    return playSfx(
      profile.jumpAsset,
      volume: masterVolume * profile.jumpVolumeScale,
    );
  }

  Future<void> playBiomeBackground(String biome) async {
    final profile = _biomes[biome];
    final asset = profile?.backgroundAsset;
    if (asset == null || asset.isEmpty) return;

    try {
      await FlameAudio.bgm.play(
        asset,
        volume: masterVolume * (profile?.backgroundVolumeScale ?? 0.6),
      );
    } catch (_) {
      // Background asset is optional and may be added later per biome.
    }
  }

  void stopBackground() {
    FlameAudio.bgm.stop();
  }
}
