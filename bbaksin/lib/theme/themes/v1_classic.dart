import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_style.dart';

/// V1 — Pure 한국 전통 (Classic). 한지 베이지 + 부적 빨강 + 먹.
class V1ClassicTheme extends BbaksinThemeStyle {
  static const _hanji = Color(0xFFF4E4BC);
  static const _bujeokRed = Color(0xFFC8102E);
  static const _ink = Color(0xFF1A1A1A);
  static const _yellow = Color(0xFFF4D35E);

  @override
  String get id => 'v1_classic';
  @override
  String get displayName => 'Pure 한국 전통';
  @override
  String get description => '진짜 부적 같은 클래식 톤';
  @override
  Color get previewColor => _bujeokRed;
  @override
  Brightness get statusBarBrightness => Brightness.dark;

  @override
  ThemeData buildMaterialTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _bujeokRed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _hanji,
        textTheme: GoogleFonts.gowunBatangTextTheme(),
      );

  @override
  Decoration buildScreenBackground() => const BoxDecoration(color: _hanji);

  @override
  Widget buildBrand(BuildContext context) => Text(
        '빡神',
        style: GoogleFonts.nanumMyeongjo(
          fontWeight: FontWeight.w800,
          fontSize: 38,
          color: _bujeokRed,
          height: 1,
        ),
      );

  @override
  Widget buildTagline(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '디지털 점집 · 매운맛 부적',
          style: GoogleFonts.gowunBatang(
            fontSize: 12,
            color: Colors.black54,
            letterSpacing: 1,
          ),
        ),
      );

  @override
  Widget buildInputLabel(String text) => Text(
        text,
        style: GoogleFonts.gowunBatang(fontSize: 13, color: Colors.black54),
      );

  @override
  Widget buildInputBox({
    required TextEditingController controller,
    required String hint,
  }) =>
      TextField(
        controller: controller,
        maxLines: 3,
        style: GoogleFonts.gowunBatang(fontSize: 16, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.gowunBatang(color: Colors.black38),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _bujeokRed, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _bujeokRed, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _bujeokRed, width: 2),
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
            backgroundColor: _bujeokRed,
            foregroundColor: _hanji,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.nanumMyeongjo(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

  @override
  Widget buildShakeHint(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.gowunBatang(fontSize: 11, color: Colors.black45),
      );

  @override
  Widget buildShakeCounter(int current, int total) => Text(
        '$current / $total',
        style: GoogleFonts.nanumMyeongjo(
          fontSize: 64,
          fontWeight: FontWeight.w800,
          color: _bujeokRed,
        ),
      );

  @override
  Widget buildShakePrompt(String text) => Text(
        text,
        style: GoogleFonts.nanumMyeongjo(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      );

  @override
  Widget buildTalisman(String message) => AspectRatio(
        aspectRatio: 9 / 15,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bujeokRed,
            border: Border.all(color: _ink, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _yellow, width: 8),
              color: _bujeokRed,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 14,
                  child: Text(
                    '神',
                    style: GoogleFonts.nanumMyeongjo(
                      color: _yellow,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Text(
                    '神',
                    style: GoogleFonts.nanumMyeongjo(
                      color: _yellow,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '符',
                          style: GoogleFonts.nanumMyeongjo(
                            color: _yellow,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nanumMyeongjo(
                            color: _hanji,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
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
                foregroundColor: _ink,
                side: const BorderSide(color: _ink, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                '저장',
                style: GoogleFonts.gowunBatang(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: onShare,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: _hanji,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                '공유',
                style: GoogleFonts.gowunBatang(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );

  @override
  Widget buildWatermark() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '— 빡神 — bbaksin.app',
          style: GoogleFonts.gowunBatang(
            fontSize: 10,
            color: Colors.black45,
          ),
        ),
      );
}
