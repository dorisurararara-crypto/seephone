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
  /// **'동공 지진 탐지기'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'동공 지진 탐지기'**
  String get appName;

  /// No description provided for @introTitleLine1.
  ///
  /// In ko, this message translates to:
  /// **'동공 지진'**
  String get introTitleLine1;

  /// No description provided for @introTitleLine2.
  ///
  /// In ko, this message translates to:
  /// **'탐지기'**
  String get introTitleLine2;

  /// No description provided for @introTagline.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 8가지 얼굴 신호 분석. 거짓말이면 진도 폭발.'**
  String get introTagline;

  /// No description provided for @stepStart.
  ///
  /// In ko, this message translates to:
  /// **'버튼 누르고 친구 얼굴을 카메라에 비추세요'**
  String get stepStart;

  /// No description provided for @stepAsk.
  ///
  /// In ko, this message translates to:
  /// **'\"질문하세요\" 가 뜨면 5초 안에 질문'**
  String get stepAsk;

  /// No description provided for @stepAnalyze.
  ///
  /// In ko, this message translates to:
  /// **'5초 동안 동공·표정·비대칭 분석 → 결과'**
  String get stepAnalyze;

  /// No description provided for @startButton.
  ///
  /// In ko, this message translates to:
  /// **'탐지 시작'**
  String get startButton;

  /// No description provided for @introInstruction.
  ///
  /// In ko, this message translates to:
  /// **'※ 친구 얼굴이 화면 중앙에 오게 들고 5초 스캔'**
  String get introInstruction;

  /// No description provided for @scanning.
  ///
  /// In ko, this message translates to:
  /// **'SCANNING'**
  String get scanning;

  /// No description provided for @askNow.
  ///
  /// In ko, this message translates to:
  /// **'이제 진짜 질문!'**
  String get askNow;

  /// No description provided for @askHint.
  ///
  /// In ko, this message translates to:
  /// **'거짓말이 의심되는 질문을 친구에게 하세요.\n친구가 답변 시작 직전에 아래 버튼을 누르세요.'**
  String get askHint;

  /// No description provided for @tapToStart.
  ///
  /// In ko, this message translates to:
  /// **'탭하면 측정 시작'**
  String get tapToStart;

  /// No description provided for @tapToStartHint.
  ///
  /// In ko, this message translates to:
  /// **'친구 답변 시작 직전에 누르세요'**
  String get tapToStartHint;

  /// No description provided for @baselineCalibration.
  ///
  /// In ko, this message translates to:
  /// **'BASELINE CALIBRATION'**
  String get baselineCalibration;

  /// No description provided for @baselineAsk.
  ///
  /// In ko, this message translates to:
  /// **'이름을 말해보세요'**
  String get baselineAsk;

  /// No description provided for @baselineHint.
  ///
  /// In ko, this message translates to:
  /// **'정확도를 위해 친구 평소 신호 측정.\n진실 답변으로 시작합니다.'**
  String get baselineHint;

  /// No description provided for @baselineHintShort.
  ///
  /// In ko, this message translates to:
  /// **'평소 신호 측정 중'**
  String get baselineHintShort;

  /// No description provided for @statusInit.
  ///
  /// In ko, this message translates to:
  /// **'INITIALIZING'**
  String get statusInit;

  /// No description provided for @statusBaseline.
  ///
  /// In ko, this message translates to:
  /// **'CALIBRATING'**
  String get statusBaseline;

  /// No description provided for @statusAsk.
  ///
  /// In ko, this message translates to:
  /// **'AWAITING QUESTION'**
  String get statusAsk;

  /// No description provided for @statusAnalyze.
  ///
  /// In ko, this message translates to:
  /// **'ANALYZING'**
  String get statusAnalyze;

  /// No description provided for @statusDone.
  ///
  /// In ko, this message translates to:
  /// **'COMPLETE'**
  String get statusDone;

  /// No description provided for @metricBlink.
  ///
  /// In ko, this message translates to:
  /// **'BLINK'**
  String get metricBlink;

  /// No description provided for @metricGaze.
  ///
  /// In ko, this message translates to:
  /// **'GAZE'**
  String get metricGaze;

  /// No description provided for @metricAsym.
  ///
  /// In ko, this message translates to:
  /// **'ASYM'**
  String get metricAsym;

  /// No description provided for @metricStress.
  ///
  /// In ko, this message translates to:
  /// **'STRESS'**
  String get metricStress;

  /// No description provided for @metricFrames.
  ///
  /// In ko, this message translates to:
  /// **'FRAMES'**
  String get metricFrames;

  /// No description provided for @metricSaccade.
  ///
  /// In ko, this message translates to:
  /// **'SACCADE'**
  String get metricSaccade;

  /// No description provided for @metricFlicker.
  ///
  /// In ko, this message translates to:
  /// **'FLICKER'**
  String get metricFlicker;

  /// No description provided for @magnitudeLabel.
  ///
  /// In ko, this message translates to:
  /// **'PUPIL TREMOR MAGNITUDE'**
  String get magnitudeLabel;

  /// No description provided for @magnitudeUnit.
  ///
  /// In ko, this message translates to:
  /// **'진도 {value} / 10.0'**
  String magnitudeUnit(String value);

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

  /// No description provided for @scanAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 측정'**
  String get scanAgain;

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

  /// No description provided for @questionLabel.
  ///
  /// In ko, this message translates to:
  /// **'QUESTION'**
  String get questionLabel;

  /// No description provided for @questionHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 너 어제 몰래 치킨 먹었지?'**
  String get questionHint;

  /// No description provided for @questionRequired.
  ///
  /// In ko, this message translates to:
  /// **'질문을 적어주세요'**
  String get questionRequired;
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
