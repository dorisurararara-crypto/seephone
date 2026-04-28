// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '빡신';

  @override
  String get introTitle => '빡신';

  @override
  String get introSubtitle => '디지털 무당 — 폰 흔들고 부적 받기';

  @override
  String get questionLabel => '고민';

  @override
  String get questionHint => '예: 시험 망쳤는데 어떡하지?';

  @override
  String get questionRequired => '고민을 적어주세요';

  @override
  String get homeInputLabel => '— 고민을 적으시오 —';

  @override
  String get homeInputHint => '예: 전 남친한테 카톡할까?';

  @override
  String get homeCta => '폰을 흔들어 점치기';

  @override
  String get homeShakeHint => '위아래로 3번 흔드시오';

  @override
  String get startButton => '굿판 열기';

  @override
  String get shakePrompt => '흔들어';

  @override
  String get shakeHint => '위아래로 흔드시오';

  @override
  String get shakeFallbackButton => '흔들기 안 되면 — 탭으로 진행';

  @override
  String get settings => '설정';

  @override
  String get themeLabel => '테마';

  @override
  String get proBannerText => 'PRO 구독으로 5개 테마 자유 전환';

  @override
  String get proSheetTitle => '빡신 PRO';

  @override
  String get proSheetSubtitle => '5가지 테마 자유 전환 · 한 번 결제로 평생 사용';

  @override
  String get betaFreeNotice =>
      '베타 기간 한정 — 무료 활성화. 정식 출시 시 ₩2,900 단건 결제로 전환됩니다.';

  @override
  String get activateThemePack => '올테마팩 활성화 (베타 무료)';

  @override
  String get later => '나중에';

  @override
  String get close => '닫기';

  @override
  String get save => '저장';

  @override
  String get share => '공유';

  @override
  String get again => '다시 점치기';

  @override
  String get home => '홈으로';

  @override
  String get language => '언어';

  @override
  String get languageAuto => '시스템 기본';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get proActivatedDevHint => '✓ Pro 활성화됨 (장기누름: 해제)';

  @override
  String get proInactiveDevHint => '⚙ Pro 비활성 (장기누름: 개발용 토글)';
}
