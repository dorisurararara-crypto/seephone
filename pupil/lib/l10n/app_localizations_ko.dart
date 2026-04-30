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
  String get appName => '동공 지진 탐지기';

  @override
  String get introTitleLine1 => '동공 지진';

  @override
  String get introTitleLine2 => '탐지기';

  @override
  String get introTagline => '카메라로 8가지 얼굴 신호 분석. 거짓말이면 진도 폭발.';

  @override
  String get stepStart => '버튼 누르고 친구 얼굴을 카메라에 비추세요';

  @override
  String get stepAsk => '\"질문하세요\" 가 뜨면 5초 안에 질문';

  @override
  String get stepAnalyze => '5초 동안 동공·표정·비대칭 분석 → 결과';

  @override
  String get startButton => '탐지 시작';

  @override
  String get introInstruction => '※ 친구 얼굴이 화면 중앙에 오게 들고 5초 스캔';

  @override
  String get scanning => 'SCANNING';

  @override
  String get askNow => '이제 진짜 질문!';

  @override
  String get askHint => '거짓말이 의심되는 질문을 친구에게 하세요.\n친구가 답변 시작 직전에 아래 버튼을 누르세요.';

  @override
  String get tapToStart => '탭하면 측정 시작';

  @override
  String get tapToStartHint => '친구 답변 시작 직전에 누르세요';

  @override
  String get baselineCalibration => 'BASELINE CALIBRATION';

  @override
  String get baselineAsk => '이름을 말해보세요';

  @override
  String get baselineHint => '정확도를 위해 친구 평소 신호 측정.\n진실 답변으로 시작합니다.';

  @override
  String get baselineHintShort => '평소 신호 측정 중';

  @override
  String get statusInit => 'INITIALIZING';

  @override
  String get statusBaseline => 'CALIBRATING';

  @override
  String get statusAsk => 'AWAITING QUESTION';

  @override
  String get statusAnalyze => 'ANALYZING';

  @override
  String get statusDone => 'COMPLETE';

  @override
  String get metricBlink => 'BLINK';

  @override
  String get metricGaze => 'GAZE';

  @override
  String get metricAsym => 'ASYM';

  @override
  String get metricStress => 'STRESS';

  @override
  String get metricFrames => 'FRAMES';

  @override
  String get metricSaccade => 'SACCADE';

  @override
  String get metricFlicker => 'FLICKER';

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

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get questionHint => '예: 너 어제 몰래 치킨 먹었지?';

  @override
  String get questionRequired => '질문을 적어주세요';
}
