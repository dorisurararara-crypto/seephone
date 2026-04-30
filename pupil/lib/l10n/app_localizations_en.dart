// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pupil Tremor Detector';

  @override
  String get appName => 'Pupil Detector';

  @override
  String get introTitleLine1 => 'Pupil Tremor';

  @override
  String get introTitleLine2 => 'Detector';

  @override
  String get introTagline =>
      '8-signal facial analysis via camera. Lies make the magnitude explode.';

  @override
  String get stepStart => 'Tap, point camera at your friend\'s face';

  @override
  String get stepAsk => 'When \"ASK NOW\" appears, ask in 5 sec';

  @override
  String get stepAnalyze => '5-sec analysis: pupils, expression, asymmetry';

  @override
  String get startButton => 'START DETECTION';

  @override
  String get introInstruction => '※ Center your friend\'s face — 5 second scan';

  @override
  String get scanning => 'SCANNING';

  @override
  String get askNow => 'ASK NOW';

  @override
  String get askHint => 'Ask your friend directly, right now';

  @override
  String get statusInit => 'INITIALIZING';

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
    return 'Magnitude $value / 10.0';
  }

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get settings => 'Settings';

  @override
  String get removeAds => 'Remove Ads';

  @override
  String get adsRemovedLabel => 'Ads removed ✓';

  @override
  String get removeAdsDescription =>
      'Removes ads on the result screen. One-time purchase, lifetime access.';

  @override
  String get removeAdsThanks => 'Thank you. Using ad-free.';

  @override
  String get betaFreeNotice =>
      'Beta period — free activation. Will convert to a \$0.99 one-time purchase at launch.';

  @override
  String get activateRemoveAds => 'Activate Ad Removal (Free in Beta)';

  @override
  String get later => 'Later';

  @override
  String get close => 'Close';

  @override
  String get language => 'Language';

  @override
  String get languageAuto => 'System default';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get questionHint => 'e.g. Did you sneak chicken last night?';

  @override
  String get questionRequired => 'Please write a question';
}
