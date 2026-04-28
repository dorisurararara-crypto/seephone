import 'package:flutter/material.dart';

/// 빡신 테마 추상 인터페이스. 각 변종 (V1~V5) 이 이 클래스를 구현.
///
/// 단순 컬러 토큰만으로는 표현 안 되는 부분 (부적 디자인, CTA 버튼 모양 등)
/// 은 widget builder 로 위임.
abstract class BbaksinThemeStyle {
  String get id;
  String get displayName;
  String get description;

  /// 미리보기·설정 화면용 대표 색.
  Color get previewColor;

  /// MaterialApp 에 들어갈 기본 ThemeData (Material 위젯 톤 통일용).
  ThemeData buildMaterialTheme();

  /// SystemUiOverlayStyle (상태바 색상). Brightness 기준.
  Brightness get statusBarBrightness;

  /// 화면 배경 (단색·그라데이션 등). Container.decoration 으로 사용.
  Decoration buildScreenBackground();

  // ───── 홈 화면 ─────
  Widget buildBrand(BuildContext context);
  Widget buildTagline(BuildContext context);
  Widget buildInputLabel(String text);
  Widget buildInputBox({
    required TextEditingController controller,
    required String hint,
  });
  Widget buildCta({
    required String label,
    required VoidCallback? onPressed,
  });
  Widget buildShakeHint(String text);

  // ───── 점치기 화면 ─────
  Widget buildShakeCounter(int current, int total);
  Widget buildShakePrompt(String text);

  // ───── 결과 화면 ─────
  Widget buildTalisman(String message);
  Widget buildActionButtons({
    required VoidCallback onSave,
    required VoidCallback onShare,
  });
  Widget buildWatermark();
}
