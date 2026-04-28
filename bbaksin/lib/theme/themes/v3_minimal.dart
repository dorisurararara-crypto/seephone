import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_style.dart';

/// V3 — 모던 다크 미니멀 (Apple-like). 검정 배경 + 빨강 액센트 + 깔끔.
class V3MinimalTheme extends BbaksinThemeStyle {
  static const _bg = Color(0xFF0A0A0A);
  static const _accent = Color(0xFFE63946);
  static const _surface = Color(0xFF1A0A0C);
  static const _border = Color(0xFF333333);

  @override
  String get id => 'v3_minimal';
  @override
  String get displayName => '모던 다크 미니멀';
  @override
  String get description => '세련된 프리미엄 톤';
  @override
  Color get previewColor => _accent;
  @override
  Brightness get statusBarBrightness => Brightness.light;

  @override
  ThemeData buildMaterialTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _bg,
        textTheme: GoogleFonts.notoSansKrTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );

  @override
  Decoration buildScreenBackground() => const BoxDecoration(color: _bg);

  @override
  Widget buildBrand(BuildContext context) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '빡',
              style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                fontSize: 36,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            TextSpan(
              text: '神',
              style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                fontSize: 36,
                color: _accent,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      );

  @override
  Widget buildTagline(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'DIGITAL FORTUNE — RAW EDITION',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white60,
            letterSpacing: 1.2,
          ),
        ),
      );

  @override
  Widget buildInputLabel(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white60,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  Widget buildInputBox({
    required TextEditingController controller,
    required String hint,
  }) =>
      TextField(
        controller: controller,
        maxLines: 3,
        style: GoogleFonts.notoSansKr(
            fontSize: 17, color: Colors.white, fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.notoSansKr(
              color: Colors.white38, fontWeight: FontWeight.w300),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _accent, width: 2),
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
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

  @override
  Widget buildShakeHint(String text) => Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.white38,
          letterSpacing: 1.2,
        ),
      );

  @override
  Widget buildShakeCounter(int current, int total) => Text(
        '$current / $total',
        style: GoogleFonts.inter(
          fontSize: 64,
          fontWeight: FontWeight.w900,
          color: _accent,
        ),
      );

  @override
  Widget buildShakePrompt(String text) => Text(
        text,
        style: GoogleFonts.notoSansKr(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1.2,
        ),
      );

  @override
  Widget buildTalisman(String message) => AspectRatio(
        aspectRatio: 9 / 15,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_surface, _bg],
            ),
            border: Border.all(color: _accent, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _accent.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '符 · TALISMAN',
                  style: GoogleFonts.inter(
                    color: _accent,
                    fontSize: 13,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    height: 1.55,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '№ ${(message.hashCode % 1000).toString().padLeft(4, '0')} / 1000',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
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
          Expanded(
            child: OutlinedButton(
              onPressed: onSave,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: onShare,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'SHARE',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget buildWatermark() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '빡神 · BBAKSIN.APP',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white30,
            letterSpacing: 1.5,
          ),
        ),
      );
}
