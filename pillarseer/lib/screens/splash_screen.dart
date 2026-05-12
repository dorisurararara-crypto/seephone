import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../providers/saju_provider.dart';
import '../services/saju_service.dart';

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
        : const Duration(milliseconds: 1500);
    _timer = Timer(delay, _go);
  }

  /// Screenshot 모드 — --dart-define=SCREENSHOT_MODE=true 빌드 시
  /// 더미 사주를 seed 하고 SCREENSHOT_ROUTE 로 이동. App Store screenshot 캡쳐용.
  static const _screenshotMode =
      bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);
  /// 어느 라우트로 점프할지 (기본 /result)
  static const _screenshotRoute =
      String.fromEnvironment('SCREENSHOT_ROUTE', defaultValue: '/result');

  void _go() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    if (_screenshotMode) {
      final svc = SajuService();
      final result = await svc.calculateSaju(
        year: 1996, month: 4, day: 15, hour: 14, minute: 30,
        isLunar: false, isMale: true,
      );
      ref.read(sajuResultProvider.notifier).set(result);
      ref.read(userBirthInfoProvider.notifier).set(UserBirthInfo(
            name: 'Demo',
            birthDate: DateTime(1996, 4, 15),
            birthHour: 14,
            birthMinute: 30,
            birthCity: '',
            isLunar: false,
          ));
      if (!mounted) return;
      context.go(_screenshotRoute);
      return;
    }
    final hasSaju = ref.read(sajuResultProvider) != null;
    if (!mounted) return;
    context.go(hasSaju ? '/home' : '/input');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final logoMark = Text(
      '命',
      style: GoogleFonts.notoSerifKr(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        color: AppColors.ink,
        height: 1.0,
      ),
    );

    final brand = Text(
      'PILLAR  SEER',
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 8,
        color: AppColors.ink,
      ),
    );

    final tagline = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 1, color: AppColors.line),
        const SizedBox(height: 16),
        Text(
          l.splashTagline,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerifKr(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: AppColors.inkLight,
            height: 1.7,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.splashTrust.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    final stack = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: reduceMotion
          ? [
              logoMark,
              const SizedBox(height: 24),
              brand,
              const SizedBox(height: 28),
              tagline,
            ]
          : [
              logoMark
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .moveY(begin: 12, end: 0, duration: 700.ms),
              const SizedBox(height: 24),
              brand
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .moveY(begin: 8, end: 0),
              const SizedBox(height: 28),
              tagline.animate().fadeIn(delay: 800.ms, duration: 600.ms),
            ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: Stack(
          children: [
            Center(child: stack),
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: Center(
                child: Semantics(
                  button: true,
                  label: l.splashSkipSemantic,
                  child: TextButton(
                    onPressed: _go,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.taupe,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: const Size(120, 44),
                    ),
                    child: Text(
                      l.splashTapToSkip.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.taupe,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
