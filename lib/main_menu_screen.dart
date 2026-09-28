import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/flame.dart';
import 'audio_manager.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'stage_manager.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  ui.Image? _bgImage;
  ui.Image? _characterImage;
  late String _biome;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _loadAssets();
  }

  // Remembered across menu shows so the same biome doesn't repeat back-to-back.
  static int? _lastStageIndex;

  Future<void> _loadAssets() async {
    // Pick a random stage, but not the one shown last time.
    int index = Random().nextInt(kStages.length);
    if (kStages.length > 1 && index == _lastStageIndex) {
      index = (index + 1) % kStages.length;
    }
    _lastStageIndex = index;
    final stage = kStages[index];
    _biome = stage.name;

    // Background music matching the shown biome.
    GameAudioManager.instance.biomeBgm
        .playStatic(_biome, GameAudioManager.instance.masterVolume);

    final bg = await Flame.images.load(stage.bgAsset);
    final char = await Flame.images.load('character.png');
    if (mounted) {
      setState(() {
        _bgImage = bg;
        _characterImage = char;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startGame() {
    GameAudioManager.instance.playButtonClick();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _openSettings() {
    GameAudioManager.instance.playButtonClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => SettingsScreen(biome: _biome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B0F),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background — shown even while loading via fallback colour
            if (_bgImage != null)
              FadeTransition(
                opacity: _fadeAnim,
                child: _GameBackground(image: _bgImage!),
              ),

            // Vignette
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0x00000000), Color(0xBB000000)],
                ),
              ),
            ),

            // Top / bottom dark bands
            Column(
              children: [
                Container(
                  height: size.height * 0.22,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xDD000000), Color(0x00000000)],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  height: size.height * 0.30,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xEE000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'S P U D B Y T E',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 7,
                            color: const Color(0xFF7AAF6A),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFD4E8A0), Color(0xFF8AB860)],
                          ).createShader(bounds),
                          child: Text(
                            'TOWER',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 44,
                              color: Colors.white,
                              letterSpacing: 6,
                              shadows: const [
                                Shadow(
                                    color: Color(0xFF2A4A1A),
                                    offset: Offset(3, 3)),
                              ],
                            ),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFE0A0), Color(0xFFCC9944)],
                          ).createShader(bounds),
                          child: Text(
                            'CLIMB',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 44,
                              color: Colors.white,
                              letterSpacing: 6,
                              height: 1.15,
                              shadows: const [
                                Shadow(
                                    color: Color(0xFF4A2A00),
                                    offset: Offset(3, 3)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'how high can you go?',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            color: const Color(0xFF8A9A7A),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x55000000),
                              border: Border.all(
                                color: const Color(0xFF8A9A7A),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SETTINGS',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 10,
                                color: const Color(0xFFD4E8A0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Character always present — placeholder sized box while loading
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: _characterImage != null
                          ? _CharacterWidget(image: _characterImage!)
                          : const SizedBox(width: 50, height: 100),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Play button
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) =>
                        Transform.scale(scale: _pulseAnim.value, child: child),
                    child: GestureDetector(
                      onTap: _startGame,
                      child: Container(
                        width: 220,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFD4A84B), Color(0xFF8A6420)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFFE8C870), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCC9922)
                                  .withValues(alpha: 0.5),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                            const BoxShadow(
                              color: Color(0xFF3A2000),
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'PLAY',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 20,
                            color: const Color(0xFF1A0E00),
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HintChip(label: '← left half'),
                        SizedBox(width: 12),
                        _HintChip(label: 'right half →'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameBackground extends StatelessWidget {
  final ui.Image image;
  const _GameBackground({required this.image});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BgPainter(image));
}

class _BgPainter extends CustomPainter {
  final ui.Image image;
  _BgPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();
    final double scale = max(size.width / imgW, size.height / imgH);
    final double drawW = imgW * scale;
    final double drawH = imgH * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromLTWH(
          (size.width - drawW) / 2, (size.height - drawH) / 2, drawW, drawH),
      Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..colorFilter =
            const ui.ColorFilter.mode(Color(0x55000000), BlendMode.darken),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.image != image;
}

class _CharacterWidget extends StatelessWidget {
  final ui.Image image;
  const _CharacterWidget({required this.image});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(80, 150), painter: _CharacterPainter(image));
}

class _CharacterPainter extends CustomPainter {
  final ui.Image image;
  _CharacterPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // Full image is the tight-cropped character
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
        image, src, dst, Paint()..filterQuality = ui.FilterQuality.medium);

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 4),
        width: size.width * 0.6,
        height: 8,
      ),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_CharacterPainter old) => old.image != image;
}

class _HintChip extends StatelessWidget {
  final String label;
  const _HintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3A4A2A)),
        borderRadius: BorderRadius.circular(4),
        color: const Color(0x33000000),
      ),
      child: Text(
        label,
        style: GoogleFonts.pressStart2p(
            fontSize: 7, color: const Color(0xFF5A7A4A)),
      ),
    );
  }
}
