// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pillar Seer';

  @override
  String get splashTagline =>
      'Your day, read from\nthe four pillars of your birth.';

  @override
  String get splashTapToSkip => 'tap to skip';

  @override
  String get splashSkipSemantic => 'Skip splash and continue';

  @override
  String get inputTitle => 'TELL US ABOUT YOU';

  @override
  String get inputName => 'Name / Nickname';

  @override
  String get inputBirthday => 'Select Birthday';

  @override
  String get inputTime => 'Select Time';

  @override
  String get inputUnknownTime => 'I don\'t know my birth time';

  @override
  String get inputBirthCity => 'Birth City (optional)';

  @override
  String get inputBirthCityHelper =>
      'Skip if you don\'t know. Adding makes it more accurate.';

  @override
  String get inputCalendar => 'Calendar:';

  @override
  String get inputSolar => 'Solar';

  @override
  String get inputLunar => 'Lunar';

  @override
  String get inputGender => 'Gender:';

  @override
  String get inputGenderMale => 'Male';

  @override
  String get inputGenderFemale => 'Female';

  @override
  String get inputGenderOther => 'Other';

  @override
  String get inputGenderOtherModalTitle => 'Pick a calculation basis';

  @override
  String get inputGenderOtherModalBody =>
      'Saju luck-pillar math needs a male/female basis. Which basis should we use?';

  @override
  String get inputGenderOtherModalMale => 'Use male basis';

  @override
  String get inputGenderOtherModalFemale => 'Use female basis';

  @override
  String get inputGenderOtherModalCancel => 'Close';

  @override
  String get inputGenderOtherCalcMaleBadge => 'Calc basis: male';

  @override
  String get inputGenderOtherCalcFemaleBadge => 'Calc basis: female';

  @override
  String get inputZasiHelperTitle =>
      'Born during Jasi (子時) — schools disagree on the day pillar';

  @override
  String get inputZasiHelperBody =>
      'The hour from 11pm to 1am is called Jasi. Different schools assign 23:00 births to different day pillars. This app defaults to the early-Jasi rule (11pm = next day\'s pillar, Korean mainstream).';

  @override
  String get inputZasiHelperBoundary =>
      '23:00–23:29 is the start of Jasi; 23:30–00:59 is its second half. The 30-minute boundary varies by school.';

  @override
  String get inputZasiOptionEarly =>
      'Early Jasi — 23:00 birth uses next day\'s pillar (default)';

  @override
  String get inputZasiOptionLate =>
      'Late Jasi — 23:00 birth keeps same day\'s pillar';

  @override
  String get inputFindMyDestiny => 'Find My Destiny';

  @override
  String get inputFreeFourPillar => 'Free 4-pillar reading. No login required.';

  @override
  String get inputErrorNameRequired => 'Please enter your name to continue';

  @override
  String get inputErrorTimeRequired =>
      'Please select a time or check \'I don\'t know\'';

  @override
  String get resultTitle => 'YOUR FOUR PILLARS';

  @override
  String get resultPillarYear => 'YEAR';

  @override
  String get resultPillarMonth => 'MONTH';

  @override
  String get resultPillarDay => 'DAY';

  @override
  String get resultPillarHour => 'HOUR';

  @override
  String get resultDayMaster => 'DAY MASTER';

  @override
  String get resultFiveElements => 'Element strength score (app-calibrated)';

  @override
  String get resultFiveElementsHelper =>
      'An app-calibrated score combining hidden stems, the birth month, and root strength.';

  @override
  String get resultDominant => 'Dominant';

  @override
  String get resultDeficit => 'Needs balance';

  @override
  String get resultStrength => 'STRENGTH';

  @override
  String get resultLove => 'LOVE';

  @override
  String get resultCareer => 'CAREER';

  @override
  String get resultWealth => 'WEALTH';

  @override
  String get resultLocked => 'LOCKED';

  @override
  String get resultUnlockFull => 'See detailed reading';

  @override
  String get resultContinueDaily => 'Continue to Daily Reading';

  @override
  String get resultShare => 'Share My Path';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGreetingNight => 'Good night';

  @override
  String get homeTodaysPillar => 'Today\'s Pillar';

  @override
  String get homeScoreOutOf => '/100';

  @override
  String get homeExplanationLow =>
      'Today\'s pillar pushes against your day master. Take it slow and stay close to your basics.';

  @override
  String get homeExplanationMid =>
      'A neutral day. Steady actions yield best results.';

  @override
  String get homeExplanationHigh =>
      'Today lines up well with your day master. A good day to move on something.';

  @override
  String get homeCategoryLove => 'LOVE';

  @override
  String get homeCategoryWork => 'WORK';

  @override
  String get homeCategoryWealth => 'WEALTH';

  @override
  String get homeCategoryEnergy => 'ENERGY';

  @override
  String get homeLuckyColor => 'Lucky Color';

  @override
  String get homeLuckyNumber => 'Lucky Number';

  @override
  String get homeLuckyDirection => 'Lucky Direction';

  @override
  String get homePromoLimited => 'LIMITED';

  @override
  String get homePromoTitle => 'Your 2026 Annual Reading';

  @override
  String get homePromoDesc =>
      'Discover the 144 hexagrams\nthat shape your year ahead.';

  @override
  String get navHome => 'Today';

  @override
  String get navReading => 'My Saju';

  @override
  String get navReports => 'More';

  @override
  String get navProfile => 'Profile';

  @override
  String get placeholderReportsTitle => 'More';

  @override
  String get placeholderReportsDesc =>
      'Compatibility, yearly flow, and dream readings in one place.';

  @override
  String get placeholderDiscoverTitle => 'DISCOVER';

  @override
  String get placeholderDiscoverDesc =>
      'Browse K-pop saju, K-drama figures, and Korean fortune-telling stories.';

  @override
  String get placeholderProfileTitle => 'PROFILE';

  @override
  String get placeholderProfileDesc =>
      'Review your birth chart input, settings, and reset options.';

  @override
  String get placeholderComingSoon => 'In preparation';

  @override
  String get placeholderNotifyMe => 'Notify me when ready';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어 (Korean)';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark (default)';

  @override
  String get settingsNotifications => 'Daily Notifications';

  @override
  String get settingsNotificationsDesc =>
      'Get your day\'s energy delivered each morning';

  @override
  String get homeNotifTitle =>
      'Every morning at 8 — just what to watch out for.';

  @override
  String get homeNotifSubtitle =>
      'A 1-line daily ping, never a marketing blast';

  @override
  String get homeNotifEnable => 'Turn on';

  @override
  String get homeNotifOn => 'ON · 8:00 AM';

  @override
  String get homeNotifPermissionDenied =>
      'Allow notifications in iOS Settings to enable.';

  @override
  String get homeNotifEnabledSnack => 'Daily 8 AM reading turned on.';

  @override
  String get homeNotifDisabledSnack => 'Daily notification turned off.';

  @override
  String get homeNotifSampleTitle => 'Pillar Seer · Your day, in one line';

  @override
  String get homeNotifSampleBody =>
      'Open to see today\'s score, lucky color, and one-line guide.';

  @override
  String homeNotifOnAt(Object hh, Object mm) {
    return 'ON · $hh:$mm';
  }

  @override
  String get settingsNotifTimeLabel => 'Notification time';

  @override
  String get settingsNotifTimeHint => 'We\'ll ping you at this hour every day';

  @override
  String get settingsNotifTimePickerTitle => 'Pick notification time';

  @override
  String settingsNotifTimeDoneSnack(Object hh, Object mm) {
    return 'Notification time set to $hh:$mm.';
  }

  @override
  String get settingsNotifSlotsLabel => 'When to get notified';

  @override
  String get settingsNotifSlotsHint =>
      'Pick the times of day you want — morning, afternoon, evening. Each one reads a little differently';

  @override
  String get settingsNotifSlotMorning => 'Morning';

  @override
  String get settingsNotifSlotAfternoon => 'Afternoon';

  @override
  String get settingsNotifSlotEvening => 'Evening';

  @override
  String get settingsNotifSlotMorningDesc =>
      'A preview before the day gets going';

  @override
  String get settingsNotifSlotAfternoonDesc => 'What changes after noon';

  @override
  String get settingsNotifSlotEveningDesc =>
      'Wrapping up today, a peek at tomorrow';

  @override
  String settingsNotifSlotDoneSnack(Object slot, Object hh, Object mm) {
    return '$slot notification set to $hh:$mm.';
  }

  @override
  String settingsNotifSlotOnSnack(Object slot) {
    return '$slot notification turned on.';
  }

  @override
  String settingsNotifSlotOffSnack(Object slot) {
    return '$slot notification turned off.';
  }

  @override
  String settingsNotifSlotPickerTitle(Object slot) {
    return 'Pick $slot notification time';
  }

  @override
  String homeNotifOnSlots(Object count) {
    return 'ON · $count times';
  }

  @override
  String get todayEventCaption => 'What\'s likely for you today';

  @override
  String get todayEventCtaDetail => 'See details';

  @override
  String get todayEventStarHealth => 'Health';

  @override
  String get todayEventDetailTitle => 'Today\'s likely event';

  @override
  String get todayEventWhy => 'Why';

  @override
  String get todayEventCaution => 'Worth watching';

  @override
  String get todayEventRecommend => 'Worth trying';

  @override
  String get homeHourlyTitle => 'Today\'s flow ⏰';

  @override
  String get homeHourlySubtitle => 'Three quick windows for the day';

  @override
  String get homeHourlyNow => 'NOW';

  @override
  String get homeHourlyNext => 'NEXT';

  @override
  String get homeHourlyLater => 'LATER';

  @override
  String get homeHourlySeeAll => 'See full 12-hour flow';

  @override
  String get homeHourlyFullTitle => 'Today\'s 12-Hour Flow';

  @override
  String get homeStreakTitle => 'Daily check-in streak';

  @override
  String homeStreakDays(Object days) {
    return '$days days';
  }

  @override
  String homeStreakLongest(Object days) {
    return 'Longest: $days days';
  }

  @override
  String get homeStreakNewDay => '+1 today';

  @override
  String get homeShareCard => 'Share my chart';

  @override
  String get shareCardTitle => 'Share your saju';

  @override
  String get shareCardSubtitle => 'Send your Core Self to friends';

  @override
  String get shareCardSave => 'Save image';

  @override
  String get shareCardSaved => 'Saved to Photos';

  @override
  String get shareCardCopy => 'Copy text';

  @override
  String get shareCardCopied => 'Copied to clipboard';

  @override
  String get shareCardClose => 'Close';

  @override
  String get resultBasisTitle => 'How this reading was calculated';

  @override
  String get resultBasisCalendar => 'Calendar';

  @override
  String get resultBasisSolar => 'Solar';

  @override
  String get resultBasisLunar => 'Lunar → Solar (KASI)';

  @override
  String get resultBasisTimezone => 'Timezone';

  @override
  String get resultBasisTrueSun => 'True Solar Time';

  @override
  String get resultBasisTrueSunOn =>
      'Applied (birth-city longitude + equation of time ±16 min)';

  @override
  String get resultBasisTrueSunOff => 'Standard time only';

  @override
  String get resultBasisManseryeok => 'Manseryeok source';

  @override
  String get resultBasisManseryeokVal =>
      'Cross-verified vs KASI (klc package + custom solar terms)';

  @override
  String get resultBasisYearBoundary => 'Year boundary';

  @override
  String get resultBasisYearBoundaryVal =>
      'Ipchun (立春) — astronomical, ~±20 min accuracy';

  @override
  String get resultPrecisionBadge => 'Precision';

  @override
  String get resultBasisDayBoundary => 'Day boundary';

  @override
  String get resultBasisDayBoundaryVal => 'Jashi (子時, 23:00 next-day rule)';

  @override
  String get personalCardTitle => 'For You Today · 今 日';

  @override
  String get personalHeadlineLabel => 'Your read';

  @override
  String get personalBodyLabel => 'Today\'s flow';

  @override
  String get personalActionLabel => 'Try this';

  @override
  String get personalCautionLabel => 'Watch for';

  @override
  String get settingsTrust => 'Trust & Data';

  @override
  String get settingsTrustHowCalculated => 'How readings are calculated';

  @override
  String get settingsTrustHowCalculatedDesc =>
      'Cross-verified vs KASI · 立春 year · 23h day rule · True Solar Time · Equation of Time · Korean DST';

  @override
  String get settingsTrustDataLocal => 'Your data stays on this device';

  @override
  String get settingsTrustDataLocalDesc => 'No login, no servers, no tracking';

  @override
  String get settingsTrustDeleteAll => 'Delete all my data';

  @override
  String get settingsTrustDeleteAllDesc =>
      'Removes saved chart + streak + preferences';

  @override
  String get settingsTrustOffline => 'Works fully offline';

  @override
  String get settingsTrustOfflineDesc => 'Once installed, no network needed';

  @override
  String get settingsDeletedSnack =>
      'All your data was deleted. Welcome back fresh.';

  @override
  String get paywallTitle => 'Pillar Seer Pro';

  @override
  String get paywallSubtitle => 'Go deeper into your Four Pillars map';

  @override
  String get paywallHeadline => 'More than today\'s one-liner.';

  @override
  String get paywallSubline =>
      'Personalized relationship, career, money, and timing reports — every day.';

  @override
  String get paywallFreeColumn => 'Free';

  @override
  String get paywallProColumn => 'Pro';

  @override
  String get paywallFeature1 => 'Day Master + Five Elements';

  @override
  String get paywallFeature2 => 'Today\'s 30-second read';

  @override
  String get paywallFeature3 => 'Hourly flow';

  @override
  String get paywallFeature4 => 'K-pop celebrity compare';

  @override
  String get paywallFeature5 => 'Full Life Themes (6 areas)';

  @override
  String get paywallFeature6 =>
      'Year of Love · Compatibility · Important Dates';

  @override
  String get paywallFeature7 => 'Ten Gods relationship map';

  @override
  String get paywallFeature8 => '10-Year Chapter (大運) full reading';

  @override
  String get paywallFeature9 => 'Personalized notifications';

  @override
  String get paywallFeature10 => 'Multi-profile (family, friends, lovers)';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallLifetime => 'Lifetime';

  @override
  String get paywallMonthlyPrice => '\$4.99 / month';

  @override
  String get paywallYearlyPrice => '\$29.99 / year';

  @override
  String get paywallYearlyHint => 'Save 50%';

  @override
  String get paywallLifetimePrice => '\$49.99 once';

  @override
  String get paywallLifetimeHint => 'Launch promo';

  @override
  String get paywallCta => 'Start Pro';

  @override
  String get paywallSoon => 'Deep features are in preparation';

  @override
  String get paywallRestoreLater => 'Restore purchase (later)';

  @override
  String get paywallClose => 'Maybe later';

  @override
  String get profileReset => 'Reset birth chart';

  @override
  String get profileResetConfirmTitle => 'Reset your saju input?';

  @override
  String get profileResetConfirmDesc =>
      'You\'ll start over from the input screen.';

  @override
  String get profileResetConfirmCta => 'Reset';

  @override
  String get inputBirthdayManualHint =>
      'Type directly: YYYY-MM-DD (e.g. 1996-05-16)';

  @override
  String get inputBirthdayManualInvalid =>
      'Invalid date — use YYYY-MM-DD format';

  @override
  String get inputBirthdayPickButton => 'Or pick from calendar';

  @override
  String get splashTrust => 'Solar-term · true-solar-time · DST aware';

  @override
  String get settingsSajuOptions => 'Saju Computation Options';

  @override
  String get settingsLateNightZasi => 'Late-night Zashi rule (23:00+)';

  @override
  String get settingsLateNightZasiDesc =>
      'OFF (default): 23:00 birth uses next-day pillar (early Zashi — Korean mainstream).\nON: 23:00 birth stays same-day pillar (late Zashi school).';

  @override
  String get settingsLateNightZasiSnackOn =>
      'Late-night Zashi ON — recompute saju from input to apply.';

  @override
  String get settingsLateNightZasiSnackOff =>
      'Late-night Zashi OFF — recompute saju from input to apply.';

  @override
  String get settingsApplyTrueSunTime =>
      'True solar time (Seoul -32 min + EoT ±16 min)';

  @override
  String get settingsApplyTrueSunTimeDesc =>
      'Orthodox myeongli default. Off uses raw KST.\nEntering a Korean city auto-applies longitude offset.';

  @override
  String get settingsApplyTrueSunTimeSnackOn =>
      'True solar time ON — recompute to apply.';

  @override
  String get settingsApplyTrueSunTimeSnackOff =>
      'True solar time OFF — using raw KST.';

  @override
  String get resultTrustLine =>
      'Cross-verified vs KASI + astronomical solar-term datetimes + true solar time with equation-of-time + Korean DST (1948-1988) auto-applied.';

  @override
  String get resultProHookHeader => 'Want to go deeper?';

  @override
  String get resultProHookYearLoveTitle => 'Your 2026 Love Chapter';

  @override
  String get resultProHookYearLoveTeaser =>
      'See which months your bonds deepen vs cool off.';

  @override
  String get resultProHookCompatTitle => 'Match with that person';

  @override
  String get resultProHookCompatTeaser =>
      'Enter their birth date — see why you click & where you clash.';

  @override
  String get resultProHookDatesTitle => 'Important dates this year';

  @override
  String get resultProHookDatesTeaser =>
      'Auspicious vs avoid days for big decisions, signings, launches.';

  @override
  String get resultProHookCta => 'Open →';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsContact => 'Contact Support';

  @override
  String get modalComingSoonTitle => 'Feature in preparation';

  @override
  String get modalComingSoonDesc =>
      'This feature is still being refined. Want a heads-up when it lands?';

  @override
  String get modalNotifyMe => 'Notify Me';

  @override
  String get modalNotNow => 'Not now';

  @override
  String get modalNotifyConfirm => 'We\'ll let you know!';

  @override
  String get devGateTitle => 'ENTER CODE';

  @override
  String get devGateHint => 'Code';

  @override
  String get devGateApply => 'Apply';

  @override
  String get devGateCancel => 'Cancel';

  @override
  String get devGateUnlocked => 'Pro features unlocked.';

  @override
  String get devGateLocked => 'Returned to free mode.';

  @override
  String get devGateInvalid => 'Code not recognized.';

  @override
  String get resultDayMasterDeepTitle => 'Your Core Self · 日 干';

  @override
  String get resultDayMasterTermHint =>
      '= Day Master (日干) — the heart of your chart';

  @override
  String get resultFiveElementsDetailTitle => 'Five Elements · 五 行';

  @override
  String get resultFiveElementsTermHint => '= Five Elements (五行) inside you';

  @override
  String get resultTenGodsTitle => 'Ten Gods · 十 神';

  @override
  String get resultTenGodsTermHint =>
      '= Ten Gods (十神) — how people, money, work appear in your chart';

  @override
  String get resultLifeThemesTitle => 'Life Themes · 主 題';

  @override
  String get resultTenYearLuckTitle => 'Ten-Year Chapter · 大 運';

  @override
  String get resultTenYearLuckTermHint =>
      '= Great Luck (大運) — the decade you\'re inside';

  @override
  String get resultThisYearTitle => 'This Year · 歲 運';

  @override
  String get resultThisYearTermHint => '= Annual Luck (歲運)';

  @override
  String get resultLuckyTitle => 'Lucky Compass · 吉';

  @override
  String get resultIntroLeadIn => 'You are the';

  @override
  String get resultIntroLeadOut => 'type of person.';

  @override
  String get resultFirstTimeBanner =>
      'New to saju? Tap here for a 30-sec guide →';

  @override
  String get resultGuideTitle => 'Saju in 30 Seconds';

  @override
  String get resultGuideBody =>
      'Your birth date + time produces 4 pillars (year/month/day/hour). The DAY pillar is your Core Self. The 5 elements (Wood/Fire/Earth/Metal/Water) show your inner balance. The other readings — relationships, career, lucky color — flow from your Core Self.';

  @override
  String get resultGuideGotIt => 'Got it';

  @override
  String get resultPillarsCardTitle =>
      'Your 4 Pillars (Year · Month · Day · Hour)';

  @override
  String get resultThreeHitHeader => 'Your 30-Second Read';

  @override
  String get resultThreeHitPersonalityLabel => 'PERSONALITY';

  @override
  String get resultThreeHitLoveLabel => 'IN LOVE';

  @override
  String get resultThreeHitTodayLabel => 'TODAY';

  @override
  String get resultWhyLabel => 'Why it reads this way:';

  @override
  String get resultEasyModeBannerTitle => 'New to saju?';

  @override
  String get resultEasyModeBannerDesc =>
      'We translate the hard words. Tap to read it the easy way.';

  @override
  String get resultEasyModeBannerCta => 'Easy mode';

  @override
  String get resultEasyModeBannerSkip => 'Just show me';

  @override
  String get discoverCompareTitle => 'You + ';

  @override
  String discoverCompareSame(Object pillar) {
    return 'Same $pillar type — you two move in sync.';
  }

  @override
  String discoverCompareDifferent(Object mine, Object theirs) {
    return 'Different types: $mine vs $theirs';
  }

  @override
  String get discoverCompareSimilar => 'What you share';

  @override
  String get discoverCompareContrast => 'Where you differ';

  @override
  String get discoverCompareShareCard => 'Make share card';

  @override
  String get discoverCompareSeeChart => 'Compatibility report';

  @override
  String get discoverCompareClose => 'Close';

  @override
  String get resultThemeCareer => 'CAREER';

  @override
  String get resultThemeWealth => 'WEALTH';

  @override
  String get resultThemeLove => 'LOVE';

  @override
  String get resultThemeHealth => 'HEALTH';

  @override
  String get resultThemeFamily => 'FAMILY';

  @override
  String get resultThemeFame => 'FAME';

  @override
  String get resultProLocked => 'PRO';

  @override
  String get resultUnlockHint =>
      'More sections will open when deep features are ready.';

  @override
  String get reportsHomeTitle => 'More';

  @override
  String get reportsHomeSubtitle =>
      'Extra readings for when you need more than today\'s summary.';

  @override
  String get reportsCardCompatibility => 'Compatibility';

  @override
  String get reportsCardCompatibilityDesc =>
      'Two charts, one chemistry. Element match + life-pillar resonance.';

  @override
  String get reportsCardTojeong => 'Tojeong (土亭祕訣)';

  @override
  String get reportsCardTojeongDesc =>
      'Korean New Year fortune — 144 hexagrams, 12 months ahead.';

  @override
  String get reportsCardDatePicking => 'Date Picking (擇日)';

  @override
  String get reportsCardDatePickingDesc =>
      'Auspicious vs avoid dates for weddings, openings, signings.';

  @override
  String get reportsCardDream => 'Dream (解夢)';

  @override
  String get reportsCardDreamDesc =>
      'Search Korean dream interpretation by symbol or theme.';

  @override
  String get compatTitle => 'COMPATIBILITY';

  @override
  String get compatYouLabel => 'YOU';

  @override
  String get compatPartnerLabel => 'PARTNER';

  @override
  String get compatEnterPartner => 'Enter your partner\'s birth info';

  @override
  String get compatPartnerName => 'Partner Name';

  @override
  String get compatCalculate => 'Calculate Match';

  @override
  String get compatMatchScore => 'Compatibility Score';

  @override
  String get compatElementsHeader => 'Element Resonance';

  @override
  String get compatPillarHeader => 'Pillar Chemistry';

  @override
  String get compatVerdictHigh =>
      'A magnetic alignment — your elements feed each other in cycles of growth.';

  @override
  String get compatVerdictMid =>
      'A workable balance — friction sharpens you, requiring honest communication.';

  @override
  String get compatVerdictLow =>
      'An intense gravity — beautiful when conscious, exhausting when unmanaged.';

  @override
  String get tojeongTitle => 'TOJEONG (土亭祕訣)';

  @override
  String get tojeongSubtitle => 'Your 144 hexagram fortune for the year.';

  @override
  String get tojeongHexagram => 'Your Hexagram';

  @override
  String get tojeongYearOverview => 'Year Overview';

  @override
  String get tojeongMonthlyHeader => 'Monthly Path';

  @override
  String get datePickTitle => 'DATE PICKING';

  @override
  String get datePickSubtitle => 'Find auspicious days in the next 30 days.';

  @override
  String get datePickGoodDays => 'Auspicious';

  @override
  String get datePickAvoidDays => 'Avoid';

  @override
  String get datePickNeutral => 'Neutral';

  @override
  String get datePickReason => 'Why';

  @override
  String get dreamTitle => 'DREAM INTERPRETATION';

  @override
  String get dreamSearchHint => 'Search dream symbol (e.g. snake, water)';

  @override
  String get dreamCategoryAll => 'All';

  @override
  String get dreamCategoryAuspicious => 'Auspicious';

  @override
  String get dreamCategoryWarning => 'Warning';

  @override
  String get dreamCategoryWealth => 'Wealth';

  @override
  String get dreamCategoryLove => 'Love';

  @override
  String get dreamCategoryFamily => 'Family';

  @override
  String get discoverTitle => 'DISCOVER';

  @override
  String get discoverSubtitle => 'K-pop & K-drama saju, decoded.';

  @override
  String get discoverFilterAll => 'All';

  @override
  String get discoverFilterIdol => 'Idols';

  @override
  String get discoverFilterActor => 'Actors';

  @override
  String get discoverFilterAthlete => 'Athletes';

  @override
  String get discoverFilterIcon => 'Icons';

  @override
  String get discoverShareCompare => 'Compare with my chart';

  @override
  String get resultShareHeroLabel => 'Share with a friend';

  @override
  String get resultShareHeroSub => 'SHARE · 友';

  @override
  String get resultShareAgain => 'Share again';

  @override
  String get settingsNotificationTone => 'Notification tone';

  @override
  String get settingsNotificationToneHint =>
      'Adult tone vs. teen tone — daily vocabulary';

  @override
  String get settingsNotificationToneAdult => 'Adult';

  @override
  String get settingsNotificationToneMz => 'Teen';

  @override
  String get profileShareCard => 'Share my saju card';

  @override
  String get profileShareCardFallback =>
      'Share failed — card text copied to clipboard';

  @override
  String get compatPrefilledTag => 'Celebrity prefilled';

  @override
  String get discoverSubRouteLabel => 'DISCOVER';

  @override
  String get kpopEmptyTitle => 'Add your birthday first to see chemistry';

  @override
  String get kpopEmptySub => 'BIRTHDATE FIRST · 命';

  @override
  String get kpopEmptyBody =>
      'We need your day-pillar to compare you with your bias.';

  @override
  String get kpopEmptyCta => 'Enter my birthday';

  @override
  String get emptyStateSajuRequiredTitle => 'Add your saju info first';

  @override
  String get emptyStateSajuRequiredSub => 'ADD YOUR SAJU · 命';

  @override
  String get emptyStateSajuRequiredBody =>
      'We need your four pillars to show your daily reading and reports.';

  @override
  String get emptyStateSajuRequiredCta => 'Enter my saju';

  @override
  String get settingsCalcBasisRow => 'How your saju is calculated';

  @override
  String get settingsCalcBasisRowDesc =>
      'See how this app handles true sun time, the late-night Jasi hour, solar terms, lunar input, and birth-city longitude.';

  @override
  String get infoCalcBasisTitle => 'How your saju is calculated';

  @override
  String get infoCalcBasisIntro =>
      'These are the five rules this app uses when it reads your saju. One short line each — no heavy jargon.';

  @override
  String get infoCalcBasisTrueSunLabel => 'True sun time correction';

  @override
  String get infoCalcBasisTrueSunDesc =>
      'Saju uses the real sun\'s noon, not your wall clock. This app shifts the time by about 32 minutes from the Korean standard, calibrated for Seoul.';

  @override
  String get infoCalcBasisJasiLabel => 'Jasi hour rules (11pm to 1am)';

  @override
  String get infoCalcBasisJasiDesc =>
      'The hour between 11pm and 1am is called Jasi (子時). Schools disagree on which day\'s pillar to use; this app\'s default treats 11pm as the start of the next day\'s pillar.';

  @override
  String get infoCalcBasisSolarTermLabel => 'Monthly pillar by solar terms';

  @override
  String get infoCalcBasisSolarTermDesc =>
      'Saju months don\'t follow the calendar. They switch on solar terms — for example, Ipchun around February 4 is treated as the year\'s first month.';

  @override
  String get infoCalcBasisLunarLabel => 'Lunar and solar input';

  @override
  String get infoCalcBasisLunarDesc =>
      'You enter your birthday in the solar calendar by default. Lunar input is converted automatically, with leap-month support.';

  @override
  String get infoCalcBasisCityLabel => 'Birth-city longitude correction';

  @override
  String get infoCalcBasisCityDesc =>
      'Seoul is the default. Korean cities such as Busan or Gwangju get an extra correction based on their longitude. Birthplaces abroad are planned for a later release.';

  @override
  String get infoCalcBasisFooter =>
      'Deeper rules (eokbu / johu / gyeokguk yongsin) are documented in a later round.';

  @override
  String get celebDisclosureBanner => 'Light comparison from public birthdays';

  @override
  String get celebDisclosureBannerHelper =>
      'Celebrity birth times are rarely public, so we drop the hour pillar and compare day pillars only. Treat it as a fun read.';

  @override
  String get celebCardConfidenceLabel => 'Public birthday · birth time unknown';

  @override
  String get hourPillarUnknownDisclaimer =>
      'You did not enter a birth time, so the hour pillar is left blank. Read the broader flow rather than fine timing.';

  @override
  String get hourPillarUnknownBadge => 'Result without hour pillar';

  @override
  String get timeUnknownAffectsAccuracy =>
      'Without a birth time, this section reads a little less sharp';

  @override
  String get lunarConversionFailedWarning =>
      'We could not convert that lunar date, so the chart was calculated using your input as a solar date. Please double-check your birth date.';
}
