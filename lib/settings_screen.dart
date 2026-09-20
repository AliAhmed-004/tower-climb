import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'audio_manager.dart';
import 'menu_theme.dart';

class SettingsScreen extends StatefulWidget {
  final String biome;
  const SettingsScreen({super.key, required this.biome});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _volume;
  late final BiomeMenuTheme _theme;

  @override
  void initState() {
    super.initState();
    _volume = GameAudioManager.instance.masterVolume;
    _theme = BiomeMenuTheme.forBiome(widget.biome);
  }

  Future<void> _setVolume(double value) async {
    setState(() => _volume = value);
    await GameAudioManager.instance.setMasterVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _theme.panel.withValues(alpha: 0.97),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SETTINGS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 16,
                        color: _theme.accent,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: _theme.muted),
                    tooltip: 'Close',
                  ),
                ],
              ),
              Container(
                height: 2,
                color: _theme.border,
              ),
              const SizedBox(height: 24),
              Text(
                'MASTER VOLUME',
                style: GoogleFonts.pressStart2p(
                  fontSize: 11,
                  color: _theme.accent,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.volume_down, color: _theme.muted),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: _setVolume,
                      activeColor: _theme.primary,
                      inactiveColor: _theme.border,
                    ),
                  ),
                  Icon(Icons.volume_up, color: _theme.muted),
                ],
              ),
              Text(
                '${(_volume * 100).round()}%',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: _theme.accent,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _theme.border),
                    foregroundColor: _theme.muted,
                  ),
                  child: Text(
                    'BACK',
                    style: GoogleFonts.pressStart2p(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
