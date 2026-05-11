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
  /// **'Full Reading — coming in Phase 2'**
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

  /// No description provided for @homeNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Every morning at 8 — just what to watch out for ☀️'**
  String get homeNotifTitle;

  /// No description provided for @homeNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A 1-line daily ping, never a marketing blast'**
  String get homeNotifSubtitle;

  /// No description provided for @homeNotifEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get homeNotifEnable;

  /// No description provided for @homeNotifOn.
  ///
  /// In en, this message translates to:
  /// **'ON · 8:00 AM'**
  String get homeNotifOn;

  /// No description provided for @homeNotifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in iOS Settings to enable.'**
  String get homeNotifPermissionDenied;

  /// No description provided for @homeNotifEnabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Daily 8 AM reading turned on ✨'**
  String get homeNotifEnabledSnack;

  /// No description provided for @homeNotifDisabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Daily notification turned off.'**
  String get homeNotifDisabledSnack;

  /// No description provided for @homeNotifSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pillar Seer · Today\'s Energy'**
  String get homeNotifSampleTitle;

  /// No description provided for @homeNotifSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Open to see today\'s score, lucky color, and one-line guide.'**
  String get homeNotifSampleBody;

  /// No description provided for @homeHourlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s flow ⏰'**
  String get homeHourlyTitle;

  /// No description provided for @homeHourlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three quick windows for the day'**
  String get homeHourlySubtitle;

  /// No description provided for @homeHourlyNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get homeHourlyNow;

  /// No description provided for @homeHourlyNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get homeHourlyNext;

  /// No description provided for @homeHourlyLater.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get homeHourlyLater;

  /// No description provided for @homeHourlySeeAll.
  ///
  /// In en, this message translates to:
  /// **'See full 12-hour flow'**
  String get homeHourlySeeAll;

  /// No description provided for @homeHourlyFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s 12-Hour Flow'**
  String get homeHourlyFullTitle;

  /// No description provided for @homeStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in streak 🔥'**
  String get homeStreakTitle;

  /// No description provided for @homeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String homeStreakDays(Object days);

  /// No description provided for @homeStreakLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest: {days} days'**
  String homeStreakLongest(Object days);

  /// No description provided for @homeStreakNewDay.
  ///
  /// In en, this message translates to:
  /// **'+1 today'**
  String get homeStreakNewDay;

  /// No description provided for @homeShareCard.
  ///
  /// In en, this message translates to:
  /// **'Share my chart'**
  String get homeShareCard;

  /// No description provided for @shareCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your saju'**
  String get shareCardTitle;

  /// No description provided for @shareCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send your Core Self to friends'**
  String get shareCardSubtitle;

  /// No description provided for @shareCardSave.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get shareCardSave;

  /// No description provided for @shareCardSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get shareCardSaved;

  /// No description provided for @shareCardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get shareCardCopy;

  /// No description provided for @shareCardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get shareCardCopied;

  /// No description provided for @shareCardClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get shareCardClose;

  /// No description provided for @resultBasisTitle.
  ///
  /// In en, this message translates to:
  /// **'How this reading was calculated'**
  String get resultBasisTitle;

  /// No description provided for @resultBasisCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get resultBasisCalendar;

  /// No description provided for @resultBasisSolar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get resultBasisSolar;

  /// No description provided for @resultBasisLunar.
  ///
  /// In en, this message translates to:
  /// **'Lunar → Solar (KASI)'**
  String get resultBasisLunar;

  /// No description provided for @resultBasisTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get resultBasisTimezone;

  /// No description provided for @resultBasisTrueSun.
  ///
  /// In en, this message translates to:
  /// **'True Solar Time'**
  String get resultBasisTrueSun;

  /// No description provided for @resultBasisTrueSunOn.
  ///
  /// In en, this message translates to:
  /// **'Applied (Seoul -32 min)'**
  String get resultBasisTrueSunOn;

  /// No description provided for @resultBasisTrueSunOff.
  ///
  /// In en, this message translates to:
  /// **'Standard time only'**
  String get resultBasisTrueSunOff;

  /// No description provided for @resultBasisManseryeok.
  ///
  /// In en, this message translates to:
  /// **'Manseryeok source'**
  String get resultBasisManseryeok;

  /// No description provided for @resultBasisManseryeokVal.
  ///
  /// In en, this message translates to:
  /// **'KASI (Korea Astronomy and Space Science Institute)'**
  String get resultBasisManseryeokVal;

  /// No description provided for @resultBasisYearBoundary.
  ///
  /// In en, this message translates to:
  /// **'Year boundary'**
  String get resultBasisYearBoundary;

  /// No description provided for @resultBasisYearBoundaryVal.
  ///
  /// In en, this message translates to:
  /// **'Ipchun (立春, Feb 4)'**
  String get resultBasisYearBoundaryVal;

  /// No description provided for @resultBasisDayBoundary.
  ///
  /// In en, this message translates to:
  /// **'Day boundary'**
  String get resultBasisDayBoundary;

  /// No description provided for @resultBasisDayBoundaryVal.
  ///
  /// In en, this message translates to:
  /// **'Jashi (子時, 23:00 next-day rule)'**
  String get resultBasisDayBoundaryVal;

  /// No description provided for @personalCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today, for YOU 🎯'**
  String get personalCardTitle;

  /// No description provided for @personalHeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Your read'**
  String get personalHeadlineLabel;

  /// No description provided for @personalBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s flow'**
  String get personalBodyLabel;

  /// No description provided for @personalActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Try this'**
  String get personalActionLabel;

  /// No description provided for @personalCautionLabel.
  ///
  /// In en, this message translates to:
  /// **'Watch for'**
  String get personalCautionLabel;

  /// No description provided for @settingsTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust & Data'**
  String get settingsTrust;

  /// No description provided for @settingsTrustHowCalculated.
  ///
  /// In en, this message translates to:
  /// **'How readings are calculated'**
  String get settingsTrustHowCalculated;

  /// No description provided for @settingsTrustHowCalculatedDesc.
  ///
  /// In en, this message translates to:
  /// **'KASI manseryeok · 立春 year · 23h day rule · True Solar Time'**
  String get settingsTrustHowCalculatedDesc;

  /// No description provided for @settingsTrustDataLocal.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device'**
  String get settingsTrustDataLocal;

  /// No description provided for @settingsTrustDataLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'No login, no servers, no tracking'**
  String get settingsTrustDataLocalDesc;

  /// No description provided for @settingsTrustDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all my data'**
  String get settingsTrustDeleteAll;

  /// No description provided for @settingsTrustDeleteAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Removes saved chart + streak + preferences'**
  String get settingsTrustDeleteAllDesc;

  /// No description provided for @settingsTrustOffline.
  ///
  /// In en, this message translates to:
  /// **'Works fully offline'**
  String get settingsTrustOffline;

  /// No description provided for @settingsTrustOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'Once installed, no network needed'**
  String get settingsTrustOfflineDesc;

  /// No description provided for @settingsDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'All your data was deleted. Welcome back fresh.'**
  String get settingsDeletedSnack;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Pillar Seer Pro'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your full Four Pillars map'**
  String get paywallSubtitle;

  /// No description provided for @paywallHeadline.
  ///
  /// In en, this message translates to:
  /// **'More than today\'s one-liner.'**
  String get paywallHeadline;

  /// No description provided for @paywallSubline.
  ///
  /// In en, this message translates to:
  /// **'Personalized relationship, career, money, and timing reports — every day.'**
  String get paywallSubline;

  /// No description provided for @paywallFreeColumn.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallFreeColumn;

  /// No description provided for @paywallProColumn.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get paywallProColumn;

  /// No description provided for @paywallFeature1.
  ///
  /// In en, this message translates to:
  /// **'Day Master + Five Elements'**
  String get paywallFeature1;

  /// No description provided for @paywallFeature2.
  ///
  /// In en, this message translates to:
  /// **'Today\'s 30-second read'**
  String get paywallFeature2;

  /// No description provided for @paywallFeature3.
  ///
  /// In en, this message translates to:
  /// **'Hourly flow'**
  String get paywallFeature3;

  /// No description provided for @paywallFeature4.
  ///
  /// In en, this message translates to:
  /// **'K-pop celebrity compare'**
  String get paywallFeature4;

  /// No description provided for @paywallFeature5.
  ///
  /// In en, this message translates to:
  /// **'Full Life Themes (6 areas)'**
  String get paywallFeature5;

  /// No description provided for @paywallFeature6.
  ///
  /// In en, this message translates to:
  /// **'Year of Love · Compatibility · Important Dates'**
  String get paywallFeature6;

  /// No description provided for @paywallFeature7.
  ///
  /// In en, this message translates to:
  /// **'Ten Gods relationship map'**
  String get paywallFeature7;

  /// No description provided for @paywallFeature8.
  ///
  /// In en, this message translates to:
  /// **'10-Year Chapter (大運) full reading'**
  String get paywallFeature8;

  /// No description provided for @paywallFeature9.
  ///
  /// In en, this message translates to:
  /// **'Personalized notifications'**
  String get paywallFeature9;

  /// No description provided for @paywallFeature10.
  ///
  /// In en, this message translates to:
  /// **'Multi-profile (family, friends, lovers)'**
  String get paywallFeature10;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get paywallLifetime;

  /// No description provided for @paywallMonthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'\$4.99 / month'**
  String get paywallMonthlyPrice;

  /// No description provided for @paywallYearlyPrice.
  ///
  /// In en, this message translates to:
  /// **'\$29.99 / year'**
  String get paywallYearlyPrice;

  /// No description provided for @paywallYearlyHint.
  ///
  /// In en, this message translates to:
  /// **'Save 50%'**
  String get paywallYearlyHint;

  /// No description provided for @paywallLifetimePrice.
  ///
  /// In en, this message translates to:
  /// **'\$49.99 once'**
  String get paywallLifetimePrice;

  /// No description provided for @paywallLifetimeHint.
  ///
  /// In en, this message translates to:
  /// **'Launch promo'**
  String get paywallLifetimeHint;

  /// No description provided for @paywallCta.
  ///
  /// In en, this message translates to:
  /// **'Start Pro'**
  String get paywallCta;

  /// No description provided for @paywallSoon.
  ///
  /// In en, this message translates to:
  /// **'Payments coming soon — leave your email below for early access'**
  String get paywallSoon;

  /// No description provided for @paywallRestoreLater.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase (later)'**
  String get paywallRestoreLater;

  /// No description provided for @paywallClose.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get paywallClose;

  /// No description provided for @profileReset.
  ///
  /// In en, this message translates to:
  /// **'Reset birth chart'**
  String get profileReset;

  /// No description provided for @splashTrust.
  ///
  /// In en, this message translates to:
  /// **'Korean traditional Four Pillars · made easy'**
  String get splashTrust;

  /// No description provided for @resultTrustLine.
  ///
  /// In en, this message translates to:
  /// **'Based on your birth date·time + Five Elements + Ten Gods.'**
  String get resultTrustLine;

  /// No description provided for @resultProHookHeader.
  ///
  /// In en, this message translates to:
  /// **'Want to go deeper?'**
  String get resultProHookHeader;

  /// No description provided for @resultProHookYearLoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your 2026 Love Chapter'**
  String get resultProHookYearLoveTitle;

  /// No description provided for @resultProHookYearLoveTeaser.
  ///
  /// In en, this message translates to:
  /// **'See which months your bonds deepen vs cool off.'**
  String get resultProHookYearLoveTeaser;

  /// No description provided for @resultProHookCompatTitle.
  ///
  /// In en, this message translates to:
  /// **'Match with that person'**
  String get resultProHookCompatTitle;

  /// No description provided for @resultProHookCompatTeaser.
  ///
  /// In en, this message translates to:
  /// **'Enter their birth date — see why you click & where you clash.'**
  String get resultProHookCompatTeaser;

  /// No description provided for @resultProHookDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Important dates this year'**
  String get resultProHookDatesTitle;

  /// No description provided for @resultProHookDatesTeaser.
  ///
  /// In en, this message translates to:
  /// **'Auspicious vs avoid days for big decisions, signings, launches.'**
  String get resultProHookDatesTeaser;

  /// No description provided for @resultProHookCta.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get resultProHookCta;

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

  /// No description provided for @devGateTitle.
  ///
  /// In en, this message translates to:
  /// **'ENTER CODE'**
  String get devGateTitle;

  /// No description provided for @devGateHint.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get devGateHint;

  /// No description provided for @devGateApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get devGateApply;

  /// No description provided for @devGateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get devGateCancel;

  /// No description provided for @devGateUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Pro features unlocked.'**
  String get devGateUnlocked;

  /// No description provided for @devGateLocked.
  ///
  /// In en, this message translates to:
  /// **'Returned to free mode.'**
  String get devGateLocked;

  /// No description provided for @devGateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Code not recognized.'**
  String get devGateInvalid;

  /// No description provided for @resultDayMasterDeepTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Core Self 🪨'**
  String get resultDayMasterDeepTitle;

  /// No description provided for @resultDayMasterTermHint.
  ///
  /// In en, this message translates to:
  /// **'= Day Master (日干) — the heart of your chart'**
  String get resultDayMasterTermHint;

  /// No description provided for @resultFiveElementsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'5 Energy Balance 🌳🔥🪨⚙️💧'**
  String get resultFiveElementsDetailTitle;

  /// No description provided for @resultFiveElementsTermHint.
  ///
  /// In en, this message translates to:
  /// **'= Five Elements (五行) inside you'**
  String get resultFiveElementsTermHint;

  /// No description provided for @resultTenGodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Relationship Map 🤝'**
  String get resultTenGodsTitle;

  /// No description provided for @resultTenGodsTermHint.
  ///
  /// In en, this message translates to:
  /// **'= Ten Gods (十神) — how people, money, work appear in your chart'**
  String get resultTenGodsTermHint;

  /// No description provided for @resultLifeThemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Big Picture of Your Life 🎬'**
  String get resultLifeThemesTitle;

  /// No description provided for @resultTenYearLuckTitle.
  ///
  /// In en, this message translates to:
  /// **'Your 10-Year Chapter 📚'**
  String get resultTenYearLuckTitle;

  /// No description provided for @resultTenYearLuckTermHint.
  ///
  /// In en, this message translates to:
  /// **'= Great Luck (大運) — the decade you\'re inside'**
  String get resultTenYearLuckTermHint;

  /// No description provided for @resultThisYearTitle.
  ///
  /// In en, this message translates to:
  /// **'This Year\'s Vibe 🎯'**
  String get resultThisYearTitle;

  /// No description provided for @resultThisYearTermHint.
  ///
  /// In en, this message translates to:
  /// **'= Annual Luck (歲運)'**
  String get resultThisYearTermHint;

  /// No description provided for @resultLuckyTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Luck Compass ✨'**
  String get resultLuckyTitle;

  /// No description provided for @resultIntroLeadIn.
  ///
  /// In en, this message translates to:
  /// **'You are'**
  String get resultIntroLeadIn;

  /// No description provided for @resultIntroLeadOut.
  ///
  /// In en, this message translates to:
  /// **'kind of person.'**
  String get resultIntroLeadOut;

  /// No description provided for @resultFirstTimeBanner.
  ///
  /// In en, this message translates to:
  /// **'New to saju? Tap here for a 30-sec guide →'**
  String get resultFirstTimeBanner;

  /// No description provided for @resultGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Saju in 30 Seconds'**
  String get resultGuideTitle;

  /// No description provided for @resultGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Your birth date + time produces 4 pillars (year/month/day/hour). The DAY pillar is your Core Self. The 5 elements (Wood/Fire/Earth/Metal/Water) show your inner balance. The other readings — relationships, career, lucky color — flow from your Core Self.'**
  String get resultGuideBody;

  /// No description provided for @resultGuideGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get resultGuideGotIt;

  /// No description provided for @resultPillarsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your 4 Pillars (Year · Month · Day · Hour)'**
  String get resultPillarsCardTitle;

  /// No description provided for @resultThreeHitHeader.
  ///
  /// In en, this message translates to:
  /// **'Your 30-Second Read'**
  String get resultThreeHitHeader;

  /// No description provided for @resultThreeHitPersonalityLabel.
  ///
  /// In en, this message translates to:
  /// **'PERSONALITY'**
  String get resultThreeHitPersonalityLabel;

  /// No description provided for @resultThreeHitLoveLabel.
  ///
  /// In en, this message translates to:
  /// **'IN LOVE'**
  String get resultThreeHitLoveLabel;

  /// No description provided for @resultThreeHitTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get resultThreeHitTodayLabel;

  /// No description provided for @resultWhyLabel.
  ///
  /// In en, this message translates to:
  /// **'Why it reads this way:'**
  String get resultWhyLabel;

  /// No description provided for @resultEasyModeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'New to saju?'**
  String get resultEasyModeBannerTitle;

  /// No description provided for @resultEasyModeBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'We translate the hard words. Tap to read it the easy way.'**
  String get resultEasyModeBannerDesc;

  /// No description provided for @resultEasyModeBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Easy mode'**
  String get resultEasyModeBannerCta;

  /// No description provided for @resultEasyModeBannerSkip.
  ///
  /// In en, this message translates to:
  /// **'Just show me'**
  String get resultEasyModeBannerSkip;

  /// No description provided for @discoverCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'You + '**
  String get discoverCompareTitle;

  /// No description provided for @discoverCompareSame.
  ///
  /// In en, this message translates to:
  /// **'Same {pillar} type 🔥'**
  String discoverCompareSame(Object pillar);

  /// No description provided for @discoverCompareDifferent.
  ///
  /// In en, this message translates to:
  /// **'Different types: {mine} vs {theirs}'**
  String discoverCompareDifferent(Object mine, Object theirs);

  /// No description provided for @discoverCompareSimilar.
  ///
  /// In en, this message translates to:
  /// **'What you share'**
  String get discoverCompareSimilar;

  /// No description provided for @discoverCompareContrast.
  ///
  /// In en, this message translates to:
  /// **'Where you differ'**
  String get discoverCompareContrast;

  /// No description provided for @discoverCompareShareCard.
  ///
  /// In en, this message translates to:
  /// **'Make share card'**
  String get discoverCompareShareCard;

  /// No description provided for @discoverCompareSeeChart.
  ///
  /// In en, this message translates to:
  /// **'Compatibility report'**
  String get discoverCompareSeeChart;

  /// No description provided for @discoverCompareClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get discoverCompareClose;

  /// No description provided for @resultThemeCareer.
  ///
  /// In en, this message translates to:
  /// **'CAREER'**
  String get resultThemeCareer;

  /// No description provided for @resultThemeWealth.
  ///
  /// In en, this message translates to:
  /// **'WEALTH'**
  String get resultThemeWealth;

  /// No description provided for @resultThemeLove.
  ///
  /// In en, this message translates to:
  /// **'LOVE'**
  String get resultThemeLove;

  /// No description provided for @resultThemeHealth.
  ///
  /// In en, this message translates to:
  /// **'HEALTH'**
  String get resultThemeHealth;

  /// No description provided for @resultThemeFamily.
  ///
  /// In en, this message translates to:
  /// **'FAMILY'**
  String get resultThemeFamily;

  /// No description provided for @resultThemeFame.
  ///
  /// In en, this message translates to:
  /// **'FAME'**
  String get resultThemeFame;

  /// No description provided for @resultProLocked.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get resultProLocked;

  /// No description provided for @resultUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Unlock Full Reading to reveal locked sections.'**
  String get resultUnlockHint;

  /// No description provided for @reportsHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'REPORTS'**
  String get reportsHomeTitle;

  /// No description provided for @reportsHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deep readings beyond your daily pillar.'**
  String get reportsHomeSubtitle;

  /// No description provided for @reportsCardCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get reportsCardCompatibility;

  /// No description provided for @reportsCardCompatibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Two charts, one chemistry. Element match + life-pillar resonance.'**
  String get reportsCardCompatibilityDesc;

  /// No description provided for @reportsCardTojeong.
  ///
  /// In en, this message translates to:
  /// **'Tojeong (土亭祕訣)'**
  String get reportsCardTojeong;

  /// No description provided for @reportsCardTojeongDesc.
  ///
  /// In en, this message translates to:
  /// **'Korean New Year fortune — 144 hexagrams, 12 months ahead.'**
  String get reportsCardTojeongDesc;

  /// No description provided for @reportsCardDatePicking.
  ///
  /// In en, this message translates to:
  /// **'Date Picking (擇日)'**
  String get reportsCardDatePicking;

  /// No description provided for @reportsCardDatePickingDesc.
  ///
  /// In en, this message translates to:
  /// **'Auspicious vs avoid dates for weddings, openings, signings.'**
  String get reportsCardDatePickingDesc;

  /// No description provided for @reportsCardDream.
  ///
  /// In en, this message translates to:
  /// **'Dream (解夢)'**
  String get reportsCardDream;

  /// No description provided for @reportsCardDreamDesc.
  ///
  /// In en, this message translates to:
  /// **'Search Korean dream interpretation by symbol or theme.'**
  String get reportsCardDreamDesc;

  /// No description provided for @compatTitle.
  ///
  /// In en, this message translates to:
  /// **'COMPATIBILITY'**
  String get compatTitle;

  /// No description provided for @compatYouLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get compatYouLabel;

  /// No description provided for @compatPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'PARTNER'**
  String get compatPartnerLabel;

  /// No description provided for @compatEnterPartner.
  ///
  /// In en, this message translates to:
  /// **'Enter your partner\'s birth info'**
  String get compatEnterPartner;

  /// No description provided for @compatPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner Name'**
  String get compatPartnerName;

  /// No description provided for @compatCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate Match'**
  String get compatCalculate;

  /// No description provided for @compatMatchScore.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Score'**
  String get compatMatchScore;

  /// No description provided for @compatElementsHeader.
  ///
  /// In en, this message translates to:
  /// **'Element Resonance'**
  String get compatElementsHeader;

  /// No description provided for @compatPillarHeader.
  ///
  /// In en, this message translates to:
  /// **'Pillar Chemistry'**
  String get compatPillarHeader;

  /// No description provided for @compatVerdictHigh.
  ///
  /// In en, this message translates to:
  /// **'A magnetic alignment — your elements feed each other in cycles of growth.'**
  String get compatVerdictHigh;

  /// No description provided for @compatVerdictMid.
  ///
  /// In en, this message translates to:
  /// **'A workable balance — friction sharpens you, requiring honest communication.'**
  String get compatVerdictMid;

  /// No description provided for @compatVerdictLow.
  ///
  /// In en, this message translates to:
  /// **'An intense gravity — beautiful when conscious, exhausting when unmanaged.'**
  String get compatVerdictLow;

  /// No description provided for @tojeongTitle.
  ///
  /// In en, this message translates to:
  /// **'TOJEONG (土亭祕訣)'**
  String get tojeongTitle;

  /// No description provided for @tojeongSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your 144 hexagram fortune for the year.'**
  String get tojeongSubtitle;

  /// No description provided for @tojeongHexagram.
  ///
  /// In en, this message translates to:
  /// **'Your Hexagram'**
  String get tojeongHexagram;

  /// No description provided for @tojeongYearOverview.
  ///
  /// In en, this message translates to:
  /// **'Year Overview'**
  String get tojeongYearOverview;

  /// No description provided for @tojeongMonthlyHeader.
  ///
  /// In en, this message translates to:
  /// **'Monthly Path'**
  String get tojeongMonthlyHeader;

  /// No description provided for @datePickTitle.
  ///
  /// In en, this message translates to:
  /// **'DATE PICKING'**
  String get datePickTitle;

  /// No description provided for @datePickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find auspicious days in the next 30 days.'**
  String get datePickSubtitle;

  /// No description provided for @datePickGoodDays.
  ///
  /// In en, this message translates to:
  /// **'Auspicious'**
  String get datePickGoodDays;

  /// No description provided for @datePickAvoidDays.
  ///
  /// In en, this message translates to:
  /// **'Avoid'**
  String get datePickAvoidDays;

  /// No description provided for @datePickNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get datePickNeutral;

  /// No description provided for @datePickReason.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get datePickReason;

  /// No description provided for @dreamTitle.
  ///
  /// In en, this message translates to:
  /// **'DREAM INTERPRETATION'**
  String get dreamTitle;

  /// No description provided for @dreamSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search dream symbol (e.g. snake, water)'**
  String get dreamSearchHint;

  /// No description provided for @dreamCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dreamCategoryAll;

  /// No description provided for @dreamCategoryAuspicious.
  ///
  /// In en, this message translates to:
  /// **'Auspicious'**
  String get dreamCategoryAuspicious;

  /// No description provided for @dreamCategoryWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get dreamCategoryWarning;

  /// No description provided for @dreamCategoryWealth.
  ///
  /// In en, this message translates to:
  /// **'Wealth'**
  String get dreamCategoryWealth;

  /// No description provided for @dreamCategoryLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get dreamCategoryLove;

  /// No description provided for @dreamCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get dreamCategoryHealth;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get discoverTitle;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'K-pop & K-drama saju, decoded.'**
  String get discoverSubtitle;

  /// No description provided for @discoverFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoverFilterAll;

  /// No description provided for @discoverFilterIdol.
  ///
  /// In en, this message translates to:
  /// **'Idols'**
  String get discoverFilterIdol;

  /// No description provided for @discoverFilterActor.
  ///
  /// In en, this message translates to:
  /// **'Actors'**
  String get discoverFilterActor;

  /// No description provided for @discoverFilterAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get discoverFilterAthlete;

  /// No description provided for @discoverFilterIcon.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get discoverFilterIcon;

  /// No description provided for @discoverShareCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare with my chart'**
  String get discoverShareCompare;
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
