// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '동공 지진 탐지기';

  @override
  String get introTitleLine1 => '동공 지진';

  @override
  String get introTitleLine2 => '탐지기';

  @override
  String get introTagline => '카메라로 친구 눈동자 떨림을 측정. 거짓말이면 진도 폭발.';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get questionHint => '예: 너 어제 몰래 치킨 먹었지?';

  @override
  String get startButton => '카메라 켜고 스캔 시작';

  @override
  String get introInstruction => '※ 친구 얼굴이 화면 중앙에 오게 들고, 질문하고, 답할 때 3초 스캔합니다';

  @override
  String get questionRequired => '질문을 적어주세요';

  @override
  String get scanning => 'SCANNING';

  @override
  String get magnitudeLabel => 'PUPIL TREMOR MAGNITUDE';

  @override
  String magnitudeUnit(String value) {
    return '진도 $value / 10.0';
  }

  @override
  String get save => '저장';

  @override
  String get share => '공유';

  @override
  String get scanAgain => '다시 측정';

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
