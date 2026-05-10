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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 80,
              color: AppColors.celestialGold,
            )
            .animate()
            .fadeIn(duration: 1.seconds)
            .scale(delay: 500.ms)
            .shimmer(delay: 2.seconds),
            const SizedBox(height: 24),
            Text(
              'PILLAR SEER',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 32,
                letterSpacing: 8,
              ),
            ).animate().fadeIn(delay: 1.seconds).moveY(begin: 20, end: 0),
          ],
        ),
      ),
    );
  }
}
