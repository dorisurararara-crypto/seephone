import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/saju_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null) return;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delay = reduceMotion
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 1800);
    _timer = Timer(delay, _go);
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final hasSaju = ref.read(sajuResultProvider) != null;
    context.go(hasSaju ? '/home' : '/input');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final logo = Image.asset(
      'assets/icon/splash_logo.png',
      width: 180,
      height: 180,
      semanticLabel: 'Pillar Seer logo',
    );
    final title = const Text(
      'PILLAR SEER',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 8,
        color: AppColors.ghostlyWhite,
      ),
    );
    const tagline = Text(
      'Read your destiny\nthrough the four pillars',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: AppColors.moonlightGray,
        height: 1.6,
        letterSpacing: 0.5,
      ),
    );

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go, // tap-to-skip
        child: Container(
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
              if (!reduceMotion) ..._buildStars(context),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: reduceMotion
                      ? [
                          logo,
                          const SizedBox(height: 28),
                          title,
                          const SizedBox(height: 12),
                          tagline,
                        ]
                      : [
                          logo
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                  begin: const Offset(0.7, 0.7),
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack)
                              .shimmer(
                                  delay: 900.ms,
                                  duration: 1200.ms,
                                  color: AppColors.celestialGold),
                          const SizedBox(height: 28),
                          title
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 600.ms)
                              .moveY(begin: 20, end: 0),
                          const SizedBox(height: 12),
                          tagline.animate().fadeIn(delay: 800.ms, duration: 600.ms),
                        ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Skip splash and continue',
                    child: TextButton(
                      onPressed: _go,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.fadedSilver,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minimumSize: const Size(120, 44),
                      ),
                      child: const Text(
                        'tap to skip',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.fadedSilver,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStars(BuildContext context) {
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
    final size = MediaQuery.of(context).size;
    return stars
        .map((s) => Positioned(
              left: size.width * s.x,
              top: size.height * s.y,
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
  final double x;
  final double y;
  final double size;
  final int delayMs;
  const _Star(this.x, this.y, this.size, this.delayMs);
}
