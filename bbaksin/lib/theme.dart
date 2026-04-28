import 'package:flutter/material.dart';

// TODO: 디자인 변종 선택 후 전체 스왑 (variants.html에서 픽한 컬러·폰트로).
// 현재는 placeholder.

class BbaksinColors {
  static const hanji = Color(0xFFF4E4BC);
  static const bujeokRed = Color(0xFFC8102E);
  static const ink = Color(0xFF1A1A1A);
  static const accentYellow = Color(0xFFF4D35E);
}

class BbaksinTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BbaksinColors.bujeokRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: BbaksinColors.hanji,
      fontFamily: 'Pretendard',
    );
  }
}
