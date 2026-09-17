import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tower_climb/tower_game.dart';
import 'main_menu_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late TowerGame _game;

  @override
  void initState() {
    super.initState();
    _game = TowerGame(onGameOver: _handleGameOver);
  }

  void _handleGameOver(int score, int best) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        score: score,
        best: best,
        onRestart: () {
          Navigator.of(context).pop();
          setState(() {
            _game = TowerGame(onGameOver: _handleGameOver);
          });
        },
        onMenu: () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainMenuScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) => _HudOverlay(game: game as TowerGame),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}

class _HudOverlay extends StatefulWidget {
  final TowerGame game;
  const _HudOverlay({required this.game});

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> {
  @override
  void initState() {
    super.initState();
    widget.game.addListener(_onGameUpdate);
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameUpdate);
    super.dispose();
  }

  void _onGameUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.game.currentFloor}',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 22,
                    color: const Color(0xFF00E5FF),
                  ),
                ),
                Text(
                  'floor',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: const Color(0xFF555577),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Combo
            if (widget.game.combo > 1)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'x${widget.game.combo}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 18,
                      color: const Color(0xFFFFCC00),
                    ),
                  ),
                  Text(
                    'combo',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: const Color(0xFF888855),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GameOverDialog extends StatelessWidget {
  final int score;
  final int best;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const _GameOverDialog({
    required this.score,
    required this.best,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= best;
    return Dialog(
      backgroundColor: const Color(0xFF0F0F22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            if (isNewBest)
              Text(
                'NEW BEST!',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: const Color(0xFFFFCC00),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Floor $score',
              style: GoogleFonts.pressStart2p(
                fontSize: 22,
                color: const Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Best: $best',
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: const Color(0xFF555577),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF0A0A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'AGAIN',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 14,
                    color: const Color(0xFF0A0A1A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onMenu,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF333355)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'MENU',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 14,
                    color: const Color(0xFF555577),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
