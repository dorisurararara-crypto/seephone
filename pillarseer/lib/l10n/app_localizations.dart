import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
  /// In en, this message translates to:
  /// **'Pillar Seer'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Read your destiny\nthrough the four pillars'**
  String get splashTagline;

  /// No description provided for @splashTapToSkip.
  ///
  /// In en, this message translates to:
  /// **'tap to skip'**
  String get splashTapToSkip;

  /// No description provided for @splashSkipSemantic.
  ///
  /// In en, this message translates to:
  /// **'Skip splash and continue'**
  String get splashSkipSemantic;

  /// No description provided for @inputTitle.
  ///
  /// In en, this message translates to:
  /// **'ENTER YOUR FATE'**
  String get inputTitle;

  /// No description provided for @inputName.
  ///
  /// In en, this message translates to:
  /// **'Name / Nickname'**
  String get inputName;

  /// No description provided for @inputBirthday.
  ///
  /// In en, this message translates to:
  /// **'Select Birthday'**
  String get inputBirthday;

  /// No description provided for @inputTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get inputTime;

  /// No description provided for @inputUnknownTime.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know my birth time'**
  String get inputUnknownTime;

  /// No description provided for @inputBirthCity.
  ///
  /// In en, this message translates to:
  /// **'Birth City (optional)'**
  String get inputBirthCity;

  /// No description provided for @inputBirthCityHelper.
  ///
  /// In en, this message translates to:
  /// **'For your records — timezone hook coming soon'**
  String get inputBirthCityHelper;

  /// No description provided for @inputCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar:'**
  String get inputCalendar;

  /// No description provided for @inputSolar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get inputSolar;

  /// No description provided for @inputLunar.
  ///
  /// In en, this message translates to:
  /// **'Lunar (soon)'**
  String get inputLunar;

  /// No description provided for @inputGender.
  ///
  /// In en, this message translates to:
  /// **'Gender:'**
  String get inputGender;

  /// No description provided for @inputGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get inputGenderMale;

  /// No description provided for @inputGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get inputGenderFemale;

  /// No description provided for @inputGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get inputGenderOther;

  /// No description provided for @inputFindMyDestiny.
  ///
  /// In en, this message translates to:
  /// **'Find My Destiny'**
  String get inputFindMyDestiny;

  /// No description provided for @inputFreeFourPillar.
  ///
  /// In en, this message translates to:
  /// **'Free 4-pillar reading. No login required.'**
  String get inputFreeFourPillar;

  /// No description provided for @inputErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name to continue'**
  String get inputErrorNameRequired;

  /// No description provided for @inputErrorTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a time or check \'I don\'t know\''**
  String get inputErrorTimeRequired;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR LIFE PATH'**
  String get resultTitle;

  /// No description provided for @resultPillarYear.
  ///
  /// In en, this message translates to:
  /// **'YEAR'**
  String get resultPillarYear;

  /// No description provided for @resultPillarMonth.
  ///
  /// In en, this message translates to:
  /// **'MONTH'**
  String get resultPillarMonth;

  /// No description provided for @resultPillarDay.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get resultPillarDay;

  /// No description provided for @resultPillarHour.
  ///
  /// In en, this message translates to:
  /// **'HOUR'**
  String get resultPillarHour;

  /// No description provided for @resultDayMaster.
  ///
  /// In en, this message translates to:
  /// **'DAY MASTER'**
  String get resultDayMaster;

  /// No description provided for @resultFiveElements.
  ///
  /// In en, this message translates to:
  /// **'FIVE ELEMENTS'**
  String get resultFiveElements;

  /// No description provided for @resultDominant.
  ///
  /// In en, this message translates to:
  /// **'Dominant'**
  String get resultDominant;

  /// No description provided for @resultDeficit.
  ///
  /// In en, this message translates to:
  /// **'Needs balance'**
  String get resultDeficit;

  /// No description provided for @resultStrength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get resultStrength;

  /// No description provided for @resultLove.
  ///
  /// In en, this message translates to:
  /// **'LOVE'**
  String get resultLove;

  /// No description provided for @resultCareer.
  ///
  /// In en, this message translates to:
  /// **'CAREER'**
  String get resultCareer;

  /// No description provided for @resultWealth.
  ///
  /// In en, this message translates to:
  /// **'WEALTH'**
  String get resultWealth;

  /// No description provided for @resultLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get resultLocked;

  /// No description provided for @resultUnlockFull.
  ///
  /// In en, this message translates to:
  /// **'Unlock Full Reading'**
  String get resultUnlockFull;

  /// No description provided for @resultContinueDaily.
  ///
  /// In en, this message translates to:
  /// **'Continue to Daily Reading'**
  String get resultContinueDaily;

  /// No description provided for @resultShare.
  ///
  /// In en, this message translates to:
  /// **'Share My Path'**
  String get resultShare;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get homeGreetingNight;

  /// No description provided for @homeTodaysPillar.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Pillar'**
  String get homeTodaysPillar;

  /// No description provided for @homeScoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get homeScoreOutOf;

  /// No description provided for @homeExplanationLow.
  ///
  /// In en, this message translates to:
  /// **'Today\'s pillar challenges your day master. Take it slow and ground yourself.'**
  String get homeExplanationLow;

  /// No description provided for @homeExplanationMid.
  ///
  /// In en, this message translates to:
  /// **'A neutral day. Steady actions yield best results.'**
  String get homeExplanationMid;

  /// No description provided for @homeExplanationHigh.
  ///
  /// In en, this message translates to:
  /// **'Today\'s energy aligns with your nature. Move boldly.'**
  String get homeExplanationHigh;

  /// No description provided for @homeCategoryLove.
  ///
  /// In en, this message translates to:
  /// **'LOVE'**
  String get homeCategoryLove;

  /// No description provided for @homeCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'WORK'**
  String get homeCategoryWork;

  /// No description provided for @homeCategoryWealth.
  ///
  /// In en, this message translates to:
  /// **'WEALTH'**
  String get homeCategoryWealth;

  /// No description provided for @homeCategoryEnergy.
  ///
  /// In en, this message translates to:
  /// **'ENERGY'**
  String get homeCategoryEnergy;

  /// No description provided for @homeLuckyColor.
  ///
  /// In en, this message translates to:
  /// **'Lucky Color'**
  String get homeLuckyColor;

  /// No description provided for @homeLuckyNumber.
  ///
  /// In en, this message translates to:
  /// **'Lucky Number'**
  String get homeLuckyNumber;

  /// No description provided for @homeLuckyDirection.
  ///
  /// In en, this message translates to:
  /// **'Lucky Direction'**
  String get homeLuckyDirection;

  /// No description provided for @homePromoLimited.
  ///
  /// In en, this message translates to:
  /// **'LIMITED'**
  String get homePromoLimited;

  /// No description provided for @homePromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your 2026 Annual Reading'**
  String get homePromoTitle;

  /// No description provided for @homePromoDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover the 144 hexagrams\nthat shape your year ahead.'**
  String get homePromoDesc;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get navReading;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @placeholderReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'REPORTS'**
  String get placeholderReportsTitle;

  /// No description provided for @placeholderReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium reports — Compatibility, Tojeongbigyeol (Korean New Year fortune), Date Picking, Dream Interpretation. Coming soon.'**
  String get placeholderReportsDesc;

  /// No description provided for @placeholderDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get placeholderDiscoverTitle;

  /// No description provided for @placeholderDiscoverDesc.
  ///
  /// In en, this message translates to:
  /// **'K-pop saju, K-drama mysticism, and Korean fortune-telling stories. Coming soon.'**
  String get placeholderDiscoverDesc;

  /// No description provided for @placeholderProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get placeholderProfileTitle;

  /// No description provided for @placeholderProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Your birth chart archive, multi-profile management, and subscription. Coming soon.'**
  String get placeholderProfileDesc;

  /// No description provided for @placeholderComingSoon.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get placeholderComingSoon;

  /// No description provided for @placeholderNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify me when ready'**
  String get placeholderNotifyMe;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어 (Korean)'**
  String get settingsLanguageKorean;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark (default)'**
  String get settingsThemeDark;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Daily Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get your day\'s energy delivered each morning'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settingsContact;

  /// No description provided for @modalComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming in Phase 2'**
  String get modalComingSoonTitle;

  /// No description provided for @modalComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'This feature is on the way. Want a heads-up when it lands?'**
  String get modalComingSoonDesc;

  /// No description provided for @modalNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify Me'**
  String get modalNotifyMe;

  /// No description provided for @modalNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get modalNotNow;

  /// No description provided for @modalNotifyConfirm.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know!'**
  String get modalNotifyConfirm;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ko':
      return AppL10nKo();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
