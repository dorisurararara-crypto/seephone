import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'빡신'**
  String get appTitle;

  /// No description provided for @introTitle.
  ///
  /// In ko, this message translates to:
  /// **'빡신'**
  String get introTitle;

  /// No description provided for @introSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'디지털 무당 — 폰 흔들고 부적 받기'**
  String get introSubtitle;

  /// No description provided for @questionLabel.
  ///
  /// In ko, this message translates to:
  /// **'고민'**
  String get questionLabel;

  /// No description provided for @questionHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 시험 망쳤는데 어떡하지?'**
  String get questionHint;

  /// No description provided for @questionRequired.
  ///
  /// In ko, this message translates to:
  /// **'고민을 적어주세요'**
  String get questionRequired;

  /// No description provided for @homeInputLabel.
  ///
  /// In ko, this message translates to:
  /// **'— 고민을 적으시오 —'**
  String get homeInputLabel;

  /// No description provided for @homeInputHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 전 남친한테 카톡할까?'**
  String get homeInputHint;

  /// No description provided for @homeCta.
  ///
  /// In ko, this message translates to:
  /// **'폰을 흔들어 점치기'**
  String get homeCta;

  /// No description provided for @homeShakeHint.
  ///
  /// In ko, this message translates to:
  /// **'위아래로 3번 흔드시오'**
  String get homeShakeHint;

  /// No description provided for @startButton.
  ///
  /// In ko, this message translates to:
  /// **'굿판 열기'**
  String get startButton;

  /// No description provided for @shakePrompt.
  ///
  /// In ko, this message translates to:
  /// **'흔들어'**
  String get shakePrompt;

  /// No description provided for @shakeHint.
  ///
  /// In ko, this message translates to:
  /// **'위아래로 흔드시오'**
  String get shakeHint;

  /// No description provided for @shakeFallbackButton.
  ///
  /// In ko, this message translates to:
  /// **'흔들기 안 되면 — 탭으로 진행'**
  String get shakeFallbackButton;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @themeLabel.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeLabel;

  /// No description provided for @proBannerText.
  ///
  /// In ko, this message translates to:
  /// **'PRO 구독으로 5개 테마 자유 전환'**
  String get proBannerText;

  /// No description provided for @proSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'빡신 PRO'**
  String get proSheetTitle;

  /// No description provided for @proSheetSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'5가지 테마 자유 전환 · 한 번 결제로 평생 사용'**
  String get proSheetSubtitle;

  /// No description provided for @betaFreeNotice.
  ///
  /// In ko, this message translates to:
  /// **'베타 기간 한정 — 무료 활성화. 정식 출시 시 ₩2,900 단건 결제로 전환됩니다.'**
  String get betaFreeNotice;

  /// No description provided for @activateThemePack.
  ///
  /// In ko, this message translates to:
  /// **'올테마팩 활성화 (베타 무료)'**
  String get activateThemePack;

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get later;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get share;

  /// No description provided for @again.
  ///
  /// In ko, this message translates to:
  /// **'다시 점치기'**
  String get again;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get home;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @languageAuto.
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본'**
  String get languageAuto;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @proActivatedDevHint.
  ///
  /// In ko, this message translates to:
  /// **'✓ Pro 활성화됨 (장기누름: 해제)'**
  String get proActivatedDevHint;

  /// No description provided for @proInactiveDevHint.
  ///
  /// In ko, this message translates to:
  /// **'⚙ Pro 비활성 (장기누름: 개발용 토글)'**
  String get proInactiveDevHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
