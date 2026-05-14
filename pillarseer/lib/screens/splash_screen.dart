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
  static const _ssYear = int.fromEnvironment('SCREENSHOT_YEAR', defaultValue: 1996);
  static const _ssMonth = int.fromEnvironment('SCREENSHOT_MONTH', defaultValue: 4);
  static const _ssDay = int.fromEnvironment('SCREENSHOT_DAY', defaultValue: 15);
  static const _ssHour = int.fromEnvironment('SCREENSHOT_HOUR', defaultValue: 14);
  static const _ssMin = int.fromEnvironment('SCREENSHOT_MIN', defaultValue: 30);
  static const _ssName = String.fromEnvironment('SCREENSHOT_NAME', defaultValue: 'Demo');
  static const _ssMale = bool.fromEnvironment('SCREENSHOT_MALE', defaultValue: true);

  void _go() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    if (_screenshotMode) {
      final svc = SajuService();
      final result = await svc.calculateSaju(
        year: _ssYear, month: _ssMonth, day: _ssDay,
        hour: _ssHour, minute: _ssMin,
        isLunar: false, isMale: _ssMale,
      );
      ref.read(sajuResultProvider.notifier).set(result);
      ref.read(userBirthInfoProvider.notifier).set(UserBirthInfo(
            name: _ssName,
            birthDate: DateTime(_ssYear, _ssMonth, _ssDay),
            birthHour: _ssHour,
            birthMinute: _ssMin,
            birthCity: '',
            isLunar: false,
            isMale: _ssMale,
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

    // Round 77 sprint 6 — 한국어 메인 + 영문 sub. letter-spacing 4 메인 X.
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final brand = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          useKo ? '필러시어' : 'Pillar Seer',
          style: GoogleFonts.notoSerifKr(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PILLAR SEER',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppColors.taupe.withValues(alpha: 0.8),
          ),
        ),
      ],
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
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.inkLight,
            height: 1.6,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.splashTrust,
          style: GoogleFonts.notoSansKr(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppColors.taupe,
            letterSpacing: 0.2,
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
                      l.splashTapToSkip,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: AppColors.taupe,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w400,
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
