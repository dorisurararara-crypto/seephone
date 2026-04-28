// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Anger Power';

  @override
  String get introTitleLine1 => 'ANGER';

  @override
  String get introTitleLine2 => 'POWER';

  @override
  String get introTagline =>
      'Shake your phone and pound the screen.\nWe measure 10 seconds and convert your rage into watts (W).';

  @override
  String get warningHeader => 'Warning';

  @override
  String get warningBody =>
      'Hold your phone tight. Drops are on you.\nA wrist strap is recommended.';

  @override
  String get startButton => 'Release 10s of Rage';

  @override
  String get shakeAndTap => 'Shake & Tap';

  @override
  String instantTotal(String instantW, String cumW) {
    return 'Live ${instantW}W · Total ${cumW}W';
  }

  @override
  String tapCount(int count) {
    return 'Taps $count';
  }

  @override
  String get yourAnger => 'YOUR ANGER';

  @override
  String get factory => '— Anger Power —';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get again => 'Once More';

  @override
  String get home => 'Home';

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
