import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Starfield background
          const _StarfieldBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Title
                Column(
                  children: [
                    Text(
                      'TOWER',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 42,
                        color: const Color(0xFF00E5FF),
                        letterSpacing: 4,
                        shadows: [
                          const Shadow(
                            color: Color(0x8800E5FF),
                            offset: Offset(0, 0),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RUSH',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 42,
                        color: Colors.white,
                        letterSpacing: 4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'how high can you go?',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 9,
                        color: const Color(0xFF888899),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Character preview — simple pixel art guy
                const _PixelCharacterPreview(),

                const Spacer(flex: 1),

                // Play button
                ScaleTransition(
                  scale: _pulseAnim,
                  child: GestureDetector(
                    onTap: _startGame,
                    child: Container(
                      width: 220,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'PLAY',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 20,
                          color: const Color(0xFF0A0A1A),
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Controls hint
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HintChip(label: '← left half'),
                      const SizedBox(width: 16),
                      _HintChip(label: 'right half →'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  const _HintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF333355)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.pressStart2p(
          fontSize: 7,
          color: const Color(0xFF555577),
        ),
      ),
    );
  }
}

class _PixelCharacterPreview extends StatelessWidget {
  const _PixelCharacterPreview();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 64),
      painter: _PixelCharacterPainter(),
    );
  }
}

class _PixelCharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final px = size.width / 6;
    final py = size.height / 8;

    void drawPixel(int x, int y, Color color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(x * px, y * py, px, py),
        paint,
      );
    }

    // Head
    const headColor = Color(0xFFFFCC88);
    for (int x = 1; x <= 4; x++) {
      for (int y = 0; y <= 1; y++) {
        drawPixel(x, y, headColor);
      }
    }
    // Eyes
    drawPixel(2, 1, const Color(0xFF222244));
    drawPixel(4, 1, const Color(0xFF222244));

    // Body
    const bodyColor = Color(0xFF00E5FF);
    for (int x = 1; x <= 4; x++) {
      for (int y = 2; y <= 4; y++) {
        drawPixel(x, y, bodyColor);
      }
    }

    // Legs
    const legColor = Color(0xFF224488);
    drawPixel(1, 5, legColor);
    drawPixel(2, 5, legColor);
    drawPixel(3, 5, legColor);
    drawPixel(4, 5, legColor);
    drawPixel(1, 6, legColor);
    drawPixel(4, 6, legColor);

    // Shoes
    const shoeColor = Color(0xFFFFFFFF);
    drawPixel(0, 7, shoeColor);
    drawPixel(1, 7, shoeColor);
    drawPixel(2, 7, shoeColor);
    drawPixel(4, 7, shoeColor);
    drawPixel(5, 7, shoeColor);
  }

  @override
  bool shouldRepaint(_PixelCharacterPainter oldDelegate) => false;
}

class _StarfieldBackground extends StatelessWidget {
  const _StarfieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _StarfieldPainter(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  static const _stars = [
    (0.1, 0.05), (0.3, 0.12), (0.7, 0.08), (0.9, 0.15),
    (0.05, 0.25), (0.45, 0.2), (0.6, 0.3), (0.85, 0.22),
    (0.15, 0.4), (0.55, 0.35), (0.75, 0.45), (0.95, 0.38),
    (0.25, 0.55), (0.5, 0.6), (0.8, 0.52), (0.1, 0.65),
    (0.4, 0.7), (0.65, 0.68), (0.9, 0.72), (0.2, 0.8),
    (0.35, 0.88), (0.7, 0.82), (0.05, 0.9), (0.55, 0.92),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);
    for (final (x, y) in _stars) {
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}
