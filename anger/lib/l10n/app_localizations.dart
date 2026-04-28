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
  /// **'분노 발전소'**
  String get appTitle;

  /// No description provided for @introTitleLine1.
  ///
  /// In ko, this message translates to:
  /// **'분노'**
  String get introTitleLine1;

  /// No description provided for @introTitleLine2.
  ///
  /// In ko, this message translates to:
  /// **'발전소'**
  String get introTitleLine2;

  /// No description provided for @introTagline.
  ///
  /// In ko, this message translates to:
  /// **'폰을 미친 듯이 흔들고 화면을 두드려라.\n10초간 측정해서 빡침을 W(와트)로 환산.'**
  String get introTagline;

  /// No description provided for @warningHeader.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get warningHeader;

  /// No description provided for @warningBody.
  ///
  /// In ko, this message translates to:
  /// **'폰을 꽉 잡으세요. 떨어트리면 본인 책임.\n가능하면 손목 스트랩 권장.'**
  String get warningBody;

  /// No description provided for @startButton.
  ///
  /// In ko, this message translates to:
  /// **'10초 분노 방출'**
  String get startButton;

  /// No description provided for @shakeAndTap.
  ///
  /// In ko, this message translates to:
  /// **'흔들어 두드려'**
  String get shakeAndTap;

  /// No description provided for @instantTotal.
  ///
  /// In ko, this message translates to:
  /// **'실시간 {instantW}W · 누적 {cumW}W'**
  String instantTotal(String instantW, String cumW);

  /// No description provided for @tapCount.
  ///
  /// In ko, this message translates to:
  /// **'두드림 {count}'**
  String tapCount(int count);

  /// No description provided for @yourAnger.
  ///
  /// In ko, this message translates to:
  /// **'YOUR ANGER'**
  String get yourAnger;

  /// No description provided for @factory.
  ///
  /// In ko, this message translates to:
  /// **'— 분노 발전소 —'**
  String get factory;

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
  /// **'한 번 더'**
  String get again;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @removeAds.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거'**
  String get removeAds;

  /// No description provided for @adsRemovedLabel.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거됨 ✓'**
  String get adsRemovedLabel;

  /// No description provided for @removeAdsDescription.
  ///
  /// In ko, this message translates to:
  /// **'결과 화면 광고를 제거합니다. 한 번 결제로 평생 사용.'**
  String get removeAdsDescription;

  /// No description provided for @removeAdsThanks.
  ///
  /// In ko, this message translates to:
  /// **'구매 감사합니다. 광고 없이 사용 중입니다.'**
  String get removeAdsThanks;

  /// No description provided for @betaFreeNotice.
  ///
  /// In ko, this message translates to:
  /// **'베타 기간 한정 — 무료 활성화. 정식 출시 시 ₩1,500 단건 결제로 전환됩니다.'**
  String get betaFreeNotice;

  /// No description provided for @activateRemoveAds.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거 활성화 (베타 무료)'**
  String get activateRemoveAds;

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
