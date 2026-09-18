import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/flame.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  // Assets
  ui.Image? _bgImage;
  ui.Image? _characterImage;

  // Animations
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

  Future<void> _loadAssets() async {
    final bg = await Flame.images.load('background.png');
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
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
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
            // ── Background image (full bleed, slightly darkened) ────────────
            if (_bgImage != null)
              FadeTransition(
                opacity: _fadeAnim,
                child: _GameBackground(image: _bgImage!),
              ),

            // Dark vignette overlay so text is always readable
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0x00000000),
                    Color(0xBB000000),
                  ],
                ),
              ),
            ),

            // Dark band at top and bottom for legibility
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

            // ── Content ─────────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Title
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        // Eyebrow text
                        Text(
                          'S P U D B Y T E',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 7,
                            color: const Color(0xFF7AAF6A),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Main title — stacked, earthy green palette
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFD4E8A0), // light moss
                              Color(0xFF8AB860), // mid green
                            ],
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
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFE0A0),
                              Color(0xFFCC9944),
                            ],
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
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
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
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Character — floating animation
                  if (_characterImage != null)
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: _CharacterWidget(image: _characterImage!),
                      ),
                    )
                  else
                    const SizedBox(height: 100),

                  const Spacer(flex: 1),

                  // Play button
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    ),
                    child: GestureDetector(
                      onTap: _startGame,
                      child: Container(
                        width: 220,
                        height: 60,
                        decoration: BoxDecoration(
                          // Earthy golden button to match the ruins palette
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFD4A84B),
                              Color(0xFF8A6420),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFE8C870),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCC9922).withOpacity(0.5),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                            const BoxShadow(
                              color: Color(0xFF3A2000),
                              offset: Offset(3, 3),
                              blurRadius: 0,
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

                  // Controls hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HintChip(label: '← left half'),
                        const SizedBox(width: 12),
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

// ── Background widget ──────────────────────────────────────────────────────────
class _GameBackground extends StatelessWidget {
  final ui.Image image;
  const _GameBackground({required this.image});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BgPainter(image));
  }
}

class _BgPainter extends CustomPainter {
  final ui.Image image;
  _BgPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill screen, darken slightly
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();

    // Cover: scale so image fills screen, crop centre
    final double scaleX = size.width / imgW;
    final double scaleY = size.height / imgH;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double drawW = imgW * scale;
    final double drawH = imgH * scale;
    final double offsetX = (size.width - drawW) / 2;
    final double offsetY = (size.height - drawH) / 2;

    // Draw darkened background
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromLTWH(offsetX, offsetY, drawW, drawH),
      Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..colorFilter = const ui.ColorFilter.mode(
          Color(0x55000000), // 33% darkening
          BlendMode.darken,
        ),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.image != image;
}

// ── Character widget ───────────────────────────────────────────────────────────
class _CharacterWidget extends StatelessWidget {
  final ui.Image image;
  const _CharacterWidget({required this.image});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 150),
      painter: _CharacterPainter(image),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final ui.Image image;
  _CharacterPainter(this.image);

  // Character occupies x=124-370, y=35-469 in the 500x500 image
  static const Rect _src = Rect.fromLTRB(124, 35, 370, 469);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      _src,
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..filterQuality = ui.FilterQuality.medium
        // Subtle drop shadow via colour filter — just a faint tint
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
    );

    // Character ground shadow
    final shadowPaint = Paint()
      ..color = const Color(0x44000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 4),
        width: size.width * 0.6,
        height: 8,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(_CharacterPainter old) => old.image != image;
}

// ── Hint chip ─────────────────────────────────────────────────────────────────
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
          fontSize: 7,
          color: const Color(0xFF5A7A4A),
        ),
      ),
    );
  }
}
