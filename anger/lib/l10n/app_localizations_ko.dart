// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '분노 발전소';

  @override
  String get introTitleLine1 => '분노';

  @override
  String get introTitleLine2 => '발전소';

  @override
  String get introTagline => '폰을 미친 듯이 흔들고 화면을 두드려라.\n10초간 측정해서 빡침을 W(와트)로 환산.';

  @override
  String get warningHeader => '주의';

  @override
  String get warningBody => '폰을 꽉 잡으세요. 떨어트리면 본인 책임.\n가능하면 손목 스트랩 권장.';

  @override
  String get startButton => '10초 분노 방출';

  @override
  String get shakeAndTap => '흔들어 두드려';

  @override
  String instantTotal(String instantW, String cumW) {
    return '실시간 ${instantW}W · 누적 ${cumW}W';
  }

  @override
  String tapCount(int count) {
    return '두드림 $count';
  }

  @override
  String get yourAnger => 'YOUR ANGER';

  @override
  String get factory => '— 분노 발전소 —';

  @override
  String get save => '저장';

  @override
  String get share => '공유';

  @override
  String get again => '한 번 더';

  @override
  String get home => '홈으로';

  @override
  String get settings => '설정';

  @override
  String get removeAds => '광고 제거';

  @override
  String get adsRemovedLabel => '광고 제거됨 ✓';

  @override
  String get removeAdsDescription => '결과 화면 광고를 제거합니다. 한 번 결제로 평생 사용.';

  @override
  String get removeAdsThanks => '구매 감사합니다. 광고 없이 사용 중입니다.';

  @override
  String get betaFreeNotice =>
      '베타 기간 한정 — 무료 활성화. 정식 출시 시 ₩1,500 단건 결제로 전환됩니다.';

  @override
  String get activateRemoveAds => '광고 제거 활성화 (베타 무료)';

  @override
  String get later => '나중에';

  @override
  String get close => '닫기';

  @override
  String get language => '언어';

  @override
  String get languageAuto => '시스템 기본';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';
}
