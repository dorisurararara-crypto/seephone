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
  String get introTitleLine1 => 'Pupil Tremor';

  @override
  String get introTitleLine2 => 'Detector';

  @override
  String get introTagline =>
      'Measure your friend\'s pupil tremor with the camera. Lies make the magnitude explode.';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get questionHint => 'e.g. Did you sneak chicken last night?';

  @override
  String get startButton => 'Open camera & start scan';

  @override
  String get introInstruction =>
      '※ Center your friend\'s face, ask the question, then scan for 3 seconds.';

  @override
  String get questionRequired => 'Please write a question';

  @override
  String get scanning => 'SCANNING';

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
}
