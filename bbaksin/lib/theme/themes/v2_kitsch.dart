import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_style.dart';

/// V2 — B급 키치 (최고심 톤). 노란 배경 + 핑크 부적 + 손글씨.
class V2KitschTheme extends BbaksinThemeStyle {
  static const _yellowBg = Color(0xFFFFE5A0);
  static const _kitschRed = Color(0xFFFF4D4D);
  static const _pink = Color(0xFFFFB3D9);
  static const _outline = Color(0xFF2C2C2C);

  @override
  String get id => 'v2_kitsch';
  @override
  String get displayName => 'B급 키치';
  @override
  String get description => '최고심 톤, 친근하고 귀여움';
  @override
  Color get previewColor => _kitschRed;
  @override
  Brightness get statusBarBrightness => Brightness.dark;

  @override
  ThemeData buildMaterialTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kitschRed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _yellowBg,
        textTheme: GoogleFonts.gaeguTextTheme(),
      );

  @override
  Decoration buildScreenBackground() =>
      const BoxDecoration(color: _yellowBg);

  @override
  Widget buildBrand(BuildContext context) => Transform.rotate(
        angle: -0.035,
        child: Text(
          '빡신!',
          style: GoogleFonts.blackHanSans(
            fontSize: 44,
            color: _kitschRed,
            height: 1,
          ),
        ),
      );

  @override
  Widget buildTagline(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '욕쟁이 무당의 부적 점집 ⚡',
          style: GoogleFonts.gaegu(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _outline,
          ),
        ),
      );

  @override
  Widget buildInputLabel(String text) => Text(
        text,
        style: GoogleFonts.gaegu(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _outline,
        ),
      );

  @override
  Widget buildInputBox({
    required TextEditingController controller,
    required String hint,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outline, width: 3),
          boxShadow: const [
            BoxShadow(color: _outline, offset: Offset(4, 4)),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.gaegu(
            fontSize: 18,
            color: _outline,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.gaegu(color: Colors.black38, fontSize: 18),
            contentPadding: const EdgeInsets.all(18),
            border: InputBorder.none,
          ),
        ),
      );

  @override
  Widget buildCta({required String label, required VoidCallback? onPressed}) =>
      Transform.rotate(
        angle: -0.015,
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: _outline, offset: Offset(4, 4)),
              ],
            ),
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _kitschRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: _outline, width: 3),
                ),
                elevation: 0,
              ),
              child: Text(
                '$label 🌀',
                style: GoogleFonts.blackHanSans(fontSize: 22),
              ),
            ),
          ),
        ),
      );

  @override
  Widget buildShakeHint(String text) => Text(
        '$text ㅇㅇ',
        textAlign: TextAlign.center,
        style: GoogleFonts.gaegu(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _outline,
        ),
      );

  @override
  Widget buildShakeCounter(int current, int total) => Text(
        '$current / $total',
        style: GoogleFonts.blackHanSans(fontSize: 64, color: _kitschRed),
      );

  @override
  Widget buildShakePrompt(String text) => Transform.rotate(
        angle: -0.02,
        child: Text(
          '$text!!!',
          style: GoogleFonts.blackHanSans(fontSize: 44, color: _outline),
        ),
      );

  @override
  Widget buildTalisman(String message) => Transform.rotate(
        angle: -0.025,
        child: AspectRatio(
          aspectRatio: 9 / 14,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _pink,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _outline, width: 4),
              boxShadow: const [
                BoxShadow(color: _outline, offset: Offset(6, 6)),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 4,
                  left: 4,
                  child: Text('✦', style: TextStyle(fontSize: 22)),
                ),
                const Positioned(
                  bottom: 4,
                  right: 4,
                  child: Text('✦', style: TextStyle(fontSize: 22)),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/backgrounds/v2_doki.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.gaegu(
                          color: _outline,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          height: 1.4,
                        ),
                      ),
                    ],
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
          Expanded(child: _btn(label: '저장', primary: false, onPressed: onSave)),
          const SizedBox(width: 10),
          Expanded(
              child:
                  _btn(label: '공유 💌', primary: true, onPressed: onShare)),
        ],
      );

  Widget _btn({
    required String label,
    required bool primary,
    required VoidCallback onPressed,
  }) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: _outline, offset: Offset(3, 3))],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primary ? _outline : Colors.white,
            foregroundColor: primary ? _yellowBg : _outline,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _outline, width: 3),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: GoogleFonts.gaegu(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      );

  @override
  Widget buildWatermark() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '빡신 · bbaksin.app',
          style: GoogleFonts.gaegu(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black45,
          ),
        ),
      );
}
