// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bbaksin';

  @override
  String get introTitle => 'Bbaksin';

  @override
  String get introSubtitle =>
      'Digital Shaman — Shake your phone, receive a talisman.';

  @override
  String get questionLabel => 'WORRY';

  @override
  String get questionHint => 'e.g. I bombed my test, what do I do?';

  @override
  String get questionRequired => 'Please write your worry';

  @override
  String get homeInputLabel => '— Tell the shaman —';

  @override
  String get homeInputHint => 'e.g. Should I text my ex?';

  @override
  String get homeCta => 'Shake to receive a fortune';

  @override
  String get homeShakeHint => 'Shake up & down 3 times';

  @override
  String get startButton => 'Open the Ritual';

  @override
  String get shakePrompt => 'SHAKE';

  @override
  String get shakeHint => 'Shake up and down';

  @override
  String get shakeFallbackButton => 'Shake not working? Tap to continue';

  @override
  String get settings => 'Settings';

  @override
  String get themeLabel => 'Themes';

  @override
  String get proBannerText => 'Unlock all 5 themes with PRO';

  @override
  String get proSheetTitle => 'BBAKSIN PRO';

  @override
  String get proSheetSubtitle =>
      'Switch all 5 themes freely · One-time purchase, lifetime';

  @override
  String get betaFreeNotice =>
      'Beta period — free activation. Will convert to a \$1.99 one-time purchase at launch.';

  @override
  String get activateThemePack => 'Activate Theme Pack (Free in Beta)';

  @override
  String get later => 'Later';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get again => 'Read Again';

  @override
  String get home => 'Home';

  @override
  String get language => 'Language';

  @override
  String get languageAuto => 'System default';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get proActivatedDevHint => '✓ Pro activated (long-press to disable)';

  @override
  String get proInactiveDevHint => '⚙ Pro inactive (long-press: dev toggle)';
}
