import 'package:flutter/material.dart';

class BiomeMenuTheme {
  final Color background;
  final Color panel;
  final Color primary;
  final Color primaryText;
  final Color accent;
  final Color muted;
  final Color border;

  const BiomeMenuTheme({
    required this.background,
    required this.panel,
    required this.primary,
    required this.primaryText,
    required this.accent,
    required this.muted,
    required this.border,
  });

  static BiomeMenuTheme forBiome(String biome) {
    switch (biome) {
      case 'ancient_civilization':
        return const BiomeMenuTheme(
          background: Color(0xFF1D1710),
          panel: Color(0xFF2C2115),
          primary: Color(0xFFC58B45),
          primaryText: Color(0xFF1A0E00),
          accent: Color(0xFFE8C870),
          muted: Color(0xFF9C8059),
          border: Color(0xFF6E4D2C),
        );
      case 'eroded':
        return const BiomeMenuTheme(
          background: Color(0xFF201B18),
          panel: Color(0xFF302722),
          primary: Color(0xFFB97855),
          primaryText: Color(0xFF1C100B),
          accent: Color(0xFFE0A77D),
          muted: Color(0xFFA18778),
          border: Color(0xFF755446),
        );
      case 'desert':
        return const BiomeMenuTheme(
          background: Color(0xFF2A1B0D),
          panel: Color(0xFF3B2815),
          primary: Color(0xFFD49A45),
          primaryText: Color(0xFF211000),
          accent: Color(0xFFF1C36A),
          muted: Color(0xFFB49764),
          border: Color(0xFF7B5A2D),
        );
      case 'snowy':
        return const BiomeMenuTheme(
          background: Color(0xFF101D2A),
          panel: Color(0xFF172C3D),
          primary: Color(0xFF78B8D1),
          primaryText: Color(0xFF07141C),
          accent: Color(0xFFBCE8F5),
          muted: Color(0xFF8EAFBE),
          border: Color(0xFF41697A),
        );
      case 'volcanic':
        return const BiomeMenuTheme(
          background: Color(0xFF260F0B),
          panel: Color(0xFF3A1710),
          primary: Color(0xFFD35432),
          primaryText: Color(0xFF210700),
          accent: Color(0xFFFFA04F),
          muted: Color(0xFFB9785F),
          border: Color(0xFF793426),
        );
      case 'mossy':
      default:
        return const BiomeMenuTheme(
          background: Color(0xFF0D1B0F),
          panel: Color(0xFF142615),
          primary: Color(0xFFD4A84B),
          primaryText: Color(0xFF1A0E00),
          accent: Color(0xFFD4E8A0),
          muted: Color(0xFF8A9A7A),
          border: Color(0xFF3A4A2A),
        );
    }
  }
}
