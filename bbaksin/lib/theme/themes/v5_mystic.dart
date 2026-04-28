import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_style.dart';

/// V5 — 다크 미스틱 (진짜 점집). 검정·보라 + 골드 + serif. 기본 테마.
class V5MysticTheme extends BbaksinThemeStyle {
  static const _bg = Color(0xFF0F0813);
  static const _bgTop = Color(0xFF2A1438);
  static const _gold = Color(0xFFD4A437);
  static const _text = Color(0xFFE0D5E5);
  static const _muted = Color(0xFFA89DB5);
  static const _purple = Color(0xFF4A1F5C);

  @override
  String get id => 'v5_mystic';
  @override
  String get displayName => '다크 미스틱';
  @override
  String get description => '진짜 점집 같은 신비로운 톤 (기본)';
  @override
  Color get previewColor => _gold;
  @override
  Brightness get statusBarBrightness => Brightness.light;

  @override
  ThemeData buildMaterialTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _bg,
        textTheme: GoogleFonts.notoSerifKrTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );

  @override
  Decoration buildScreenBackground() => const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [_bgTop, _bg],
          stops: [0.0, 0.7],
        ),
      );

  @override
  Widget buildBrand(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빡神',
            style: GoogleFonts.notoSerifKr(
              fontWeight: FontWeight.w900,
              fontSize: 38,
              color: _gold,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '— bbaksin —',
            style: GoogleFonts.cormorantGaramond(
              fontStyle: FontStyle.italic,
              fontSize: 18,
              color: _text.withValues(alpha: 0.6),
            ),
          ),
        ],
      );

  @override
  Widget buildTagline(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          '디지털 점집',
          style: GoogleFonts.notoSerifKr(
            fontSize: 11,
            color: _muted,
            letterSpacing: 4,
            fontWeight: FontWeight.w400,
          ),
        ),
      );

  @override
  Widget buildInputLabel(String text) => Text(
        '— ${text.toLowerCase()} —',
        style: GoogleFonts.cormorantGaramond(
          fontStyle: FontStyle.italic,
          fontSize: 16,
          color: _muted,
        ),
      );

  @override
  Widget buildInputBox({
    required TextEditingController controller,
    required String hint,
  }) =>
      Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x4DD4A437)),
            bottom: BorderSide(color: Color(0x4DD4A437)),
          ),
        ),
        child: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.notoSerifKr(
            fontSize: 17,
            color: _text,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.notoSerifKr(
              color: _muted,
              fontStyle: FontStyle.italic,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: InputBorder.none,
          ),
        ),
      );

  @override
  Widget buildCta({required String label, required VoidCallback? onPressed}) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _gold,
            side: const BorderSide(color: _gold, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.notoSerifKr(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
        ),
      );

  @override
  Widget buildShakeHint(String text) => Text(
        '— $text —',
        textAlign: TextAlign.center,
        style: GoogleFonts.cormorantGaramond(
          fontStyle: FontStyle.italic,
          fontSize: 13,
          color: const Color(0xFF6E5B7A),
          letterSpacing: 1,
        ),
      );

  @override
  Widget buildShakeCounter(int current, int total) => Text(
        '$current / $total',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 80,
          fontWeight: FontWeight.w400,
          color: _gold,
          fontStyle: FontStyle.italic,
        ),
      );

  @override
  Widget buildShakePrompt(String text) => Text(
        text,
        style: GoogleFonts.notoSerifKr(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: _text,
        ),
      );

  @override
  Widget buildTalisman(String message) => AspectRatio(
        aspectRatio: 9 / 15,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [Color(0xFF1F1029), _bg],
              center: Alignment.center,
              radius: 1.0,
            ),
            border: Border.all(color: _gold, width: 1),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 6,
                child: Text('✦',
                    style: GoogleFonts.cormorantGaramond(
                        color: _gold, fontSize: 14)),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Text('✦',
                    style: GoogleFonts.cormorantGaramond(
                        color: _gold, fontSize: 14)),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '— TALISMAN —',
                        style: GoogleFonts.cormorantGaramond(
                          color: _gold,
                          fontSize: 11,
                          letterSpacing: 5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerifKr(
                          color: _text,
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '— 신령님 —',
                        style: GoogleFonts.cormorantGaramond(
                          color: _gold.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                foregroundColor: _text,
                side: const BorderSide(color: _purple),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: onShare,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                'SHARE',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget buildWatermark() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          '— bbaksin —',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 11,
            color: const Color(0xFF6E5B7A),
            fontStyle: FontStyle.italic,
            letterSpacing: 2,
          ),
        ),
      );
}
