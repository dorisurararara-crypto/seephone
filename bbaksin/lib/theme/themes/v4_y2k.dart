import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_style.dart';

/// V4 — Y2K 그라데이션 (MZ Insta). 핑크·퍼플·블루 그라데이션 + 홀로그램.
class V4Y2kTheme extends BbaksinThemeStyle {
  static const _pink = Color(0xFFFF6B9D);
  static const _purple = Color(0xFFC44ED4);
  static const _blue = Color(0xFF4D9BFF);

  @override
  String get id => 'v4_y2k';
  @override
  String get displayName => 'Y2K 그라데이션';
  @override
  String get description => '인스타·MZ 친화적 톤';
  @override
  Color get previewColor => _purple;
  @override
  Brightness get statusBarBrightness => Brightness.light;

  @override
  ThemeData buildMaterialTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _purple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _purple,
        textTheme: GoogleFonts.notoSansKrTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );

  @override
  Decoration buildScreenBackground() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink, _purple, _blue],
        ),
      );

  @override
  Widget buildBrand(BuildContext context) => ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Color(0xFFFFD6E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: Text(
          '빡신',
          style: GoogleFonts.blackHanSans(
            fontSize: 56,
            color: Colors.white,
            height: 0.95,
            letterSpacing: -1,
            shadows: [
              const Shadow(
                color: Color(0x66FFFFFF),
                blurRadius: 30,
              ),
            ],
          ),
        ),
      );

  @override
  Widget buildTagline(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '✨ 매운맛 디지털 점집 ✨',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  @override
  Widget buildInputLabel(String text) => Text(
        text,
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  Widget buildInputBox({
    required TextEditingController controller,
    required String hint,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              maxLines: 3,
              style: GoogleFonts.notoSansKr(
                fontSize: 16,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.notoSansKr(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                contentPadding: const EdgeInsets.all(18),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      );

  @override
  Widget buildCta({required String label, required VoidCallback? onPressed}) =>
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _purple,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 8,
            shadowColor: Colors.black26,
          ),
          child: Text(
            '$label ✦',
            style: GoogleFonts.blackHanSans(fontSize: 22),
          ),
        ),
      );

  @override
  Widget buildShakeHint(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSansKr(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  Widget buildShakeCounter(int current, int total) => Text(
        '$current / $total',
        style: GoogleFonts.blackHanSans(
          fontSize: 64,
          color: Colors.white,
        ),
      );

  @override
  Widget buildShakePrompt(String text) => Text(
        '$text ✨',
        style: GoogleFonts.blackHanSans(fontSize: 44, color: Colors.white),
      );

  @override
  Widget buildTalisman(String message) => AspectRatio(
        aspectRatio: 9 / 15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Text('✦',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Text('✧',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: Text('✦',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '✦ 부적 ✦',
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.blackHanSans(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.4,
                            shadows: const [
                              Shadow(
                                color: Color(0x4D000000),
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget buildActionButtons({
    required VoidCallback onSave,
    required VoidCallback onShare,
  }) =>
      Row(
        children: [
          Expanded(child: _btn(label: '저장', primary: false, onPressed: onSave)),
          const SizedBox(width: 10),
          Expanded(
              child: _btn(label: '공유 →', primary: true, onPressed: onShare)),
        ],
      );

  Widget _btn({
    required String label,
    required bool primary,
    required VoidCallback onPressed,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: primary
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              foregroundColor: primary ? _purple : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: primary
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );

  @override
  Widget buildWatermark() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '@bbaksin.app',
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
