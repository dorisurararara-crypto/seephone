import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/input');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF311B92),
              Color(0xFF1A0B2E),
              Color(0xFF0A0612),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Star field (background twinkles)
            ..._buildStars(),
            // Center logo + text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/splash_logo.png',
                    width: 180,
                    height: 180,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.7, 0.7), duration: 700.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 1200.ms, duration: 1500.ms, color: AppColors.celestialGold),
                  const SizedBox(height: 28),
                  const Text(
                    'PILLAR SEER',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: AppColors.ghostlyWhite,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 800.ms)
                      .moveY(begin: 20, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'Read your destiny\nthrough the four pillars',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.moonlightGray,
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1100.ms, duration: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStars() {
    // Static star field — positions chosen for visual balance
    final stars = <_Star>[
      _Star(0.10, 0.15, 2.5, 600),
      _Star(0.85, 0.18, 3.0, 800),
      _Star(0.20, 0.30, 2.0, 1000),
      _Star(0.75, 0.32, 2.5, 1200),
      _Star(0.05, 0.55, 3.0, 700),
      _Star(0.92, 0.50, 2.0, 900),
      _Star(0.15, 0.78, 2.5, 1100),
      _Star(0.80, 0.82, 3.0, 1300),
      _Star(0.50, 0.08, 2.0, 1400),
      _Star(0.45, 0.92, 2.5, 1500),
    ];
    return stars
        .map((s) => Positioned(
              left: MediaQuery.of(context).size.width * s.x,
              top: MediaQuery.of(context).size.height * s.y,
              child: Container(
                width: s.size,
                height: s.size,
                decoration: BoxDecoration(
                  color: AppColors.celestialGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.celestialGold.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: Duration(milliseconds: s.delayMs))
                  .then()
                  .fadeOut(duration: 2.seconds, delay: 1.seconds),
            ))
        .toList();
  }
}

class _Star {
  final double x; // 0~1 (% of width)
  final double y;
  final double size;
  final int delayMs;
  const _Star(this.x, this.y, this.size, this.delayMs);
}
