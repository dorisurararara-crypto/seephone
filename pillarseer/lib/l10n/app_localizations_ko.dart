// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppL10nKo extends AppL10n {
  AppL10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '필러시어';

  @override
  String get splashTagline => '오늘 너의 분위기,\n네 글자로 콕 집어 줄게';

  @override
  String get splashTapToSkip => '탭하여 건너뛰기';

  @override
  String get splashSkipSemantic => '스플래시 건너뛰고 계속하기';

  @override
  String get inputTitle => '내 운명 입력';

  @override
  String get inputName => '이름 / 닉네임';

  @override
  String get inputBirthday => '생년월일';

  @override
  String get inputTime => '태어난 시간';

  @override
  String get inputUnknownTime => '태어난 시간을 모름';

  @override
  String get inputBirthCity => '출생지 (선택)';

  @override
  String get inputBirthCityHelper => '모르면 비워둬도 돼. 적으면 더 정확해져.';

  @override
  String get inputCalendar => '달력:';

  @override
  String get inputSolar => '양력';

  @override
  String get inputLunar => '음력';

  @override
  String get inputGender => '성별:';

  @override
  String get inputGenderMale => '남자';

  @override
  String get inputGenderFemale => '여자';

  @override
  String get inputGenderOther => '기타';

  @override
  String get inputGenderOtherModalTitle => '계산 기준을 골라 주세요';

  @override
  String get inputGenderOtherModalBody =>
      '사주 대운 계산은 남/여 기준이 필요해요. 어느 기준으로 계산할까요?';

  @override
  String get inputGenderOtherModalMale => '남 기준으로 계산할게요';

  @override
  String get inputGenderOtherModalFemale => '여 기준으로 계산할게요';

  @override
  String get inputGenderOtherModalCancel => '닫기';

  @override
  String get inputGenderOtherCalcMaleBadge => '계산 기준: 남';

  @override
  String get inputGenderOtherCalcFemaleBadge => '계산 기준: 여';

  @override
  String get inputZasiHelperTitle => '자시(子時)에 태어났네 — 학파마다 일주가 갈려';

  @override
  String get inputZasiHelperBody =>
      '밤 11시부터 새벽 1시는 자시예요. 학파에 따라 23시 출생자의 일주가 달라질 수 있어요. 이 앱은 기본 정자시(밤 11시부터 다음 날로 보는, 한국에서 널리 쓰는 기준)로 계산해요.';

  @override
  String get inputZasiHelperBoundary =>
      '23:00–23:29는 자시 시작 시각, 23:30–00:59는 자시 중·후반이에요. 30분 경계가 학파마다 달라요.';

  @override
  String get inputZasiOptionEarly => '정자시 — 23시 출생은 다음 날 일주 (기본)';

  @override
  String get inputZasiOptionLate => '야자시 — 23시 출생도 같은 날 일주 유지';

  @override
  String get inputFindMyDestiny => '내 사주 보기';

  @override
  String get inputFreeFourPillar => '무료 4기둥 사주. 로그인 불필요.';

  @override
  String get inputErrorNameRequired => '이름을 입력해 주세요';

  @override
  String get inputErrorTimeRequired => '시간을 선택하거나 \'모름\'을 체크해 주세요';

  @override
  String get resultTitle => '당신의 사주';

  @override
  String get resultPillarYear => '년주';

  @override
  String get resultPillarMonth => '월주';

  @override
  String get resultPillarDay => '일주';

  @override
  String get resultPillarHour => '시주';

  @override
  String get resultDayMaster => '일간 (日干)';

  @override
  String get resultFiveElements => '세력 분포 점수 (앱 기준)';

  @override
  String get resultFiveElementsHelper => '숨은 글자, 태어난 달, 뿌리 힘을 같이 본 앱 기준 점수예요.';

  @override
  String get resultDominant => '많이 가진 에너지';

  @override
  String get resultDeficit => '보충 필요';

  @override
  String get resultStrength => '성격';

  @override
  String get resultLove => '애정';

  @override
  String get resultCareer => '직업';

  @override
  String get resultWealth => '재물';

  @override
  String get resultLocked => '잠금';

  @override
  String get resultUnlockFull => '전체 풀이 — Phase 2 출시 예정';

  @override
  String get resultContinueDaily => '오늘의 운세 보기';

  @override
  String get resultShare => '공유하기';

  @override
  String get homeGreetingMorning => '안녕하세요';

  @override
  String get homeGreetingAfternoon => '좋은 오후입니다';

  @override
  String get homeGreetingEvening => '좋은 저녁입니다';

  @override
  String get homeGreetingNight => '편안한 밤 되세요';

  @override
  String get homeTodaysPillar => '오늘의 일진';

  @override
  String get homeScoreOutOf => '/100';

  @override
  String get homeExplanationLow => '오늘은 에너지가 살짝 부딪혀요. 천천히 가면 괜찮아요.';

  @override
  String get homeExplanationMid => '평온한 하루예요. 꾸준한 한 발이 큰 결과로 와요.';

  @override
  String get homeExplanationHigh => '오늘은 평소 리듬이랑 타이밍이 잘 맞아요. 미루던 거 한 번 시도해 봐요.';

  @override
  String get homeCategoryLove => '애정';

  @override
  String get homeCategoryWork => '직업';

  @override
  String get homeCategoryWealth => '재물';

  @override
  String get homeCategoryEnergy => '활력';

  @override
  String get homeLuckyColor => '행운의 색';

  @override
  String get homeLuckyNumber => '행운의 숫자';

  @override
  String get homeLuckyDirection => '행운의 방향';

  @override
  String get homePromoLimited => '한정';

  @override
  String get homePromoTitle => '2026년 신년운세';

  @override
  String get homePromoDesc => '한 해를 좌우할\n144괘 풀이를 만나보세요.';

  @override
  String get navHome => '오늘';

  @override
  String get navReading => '내 사주';

  @override
  String get navReports => '리포트';

  @override
  String get navProfile => '프로필';

  @override
  String get placeholderReportsTitle => '리포트';

  @override
  String get placeholderReportsDesc => '프리미엄 리포트 — 궁합, 토정비결, 택일, 해몽. 곧 추가됩니다.';

  @override
  String get placeholderDiscoverTitle => '탐색';

  @override
  String get placeholderDiscoverDesc =>
      'K-pop 사주, K-drama 미스틱, 한국 운세 이야기. 곧 추가됩니다.';

  @override
  String get placeholderProfileTitle => '프로필';

  @override
  String get placeholderProfileDesc => '내 사주 보관, 다중 프로필 관리, 구독. 곧 추가됩니다.';

  @override
  String get placeholderComingSoon => '준비 중';

  @override
  String get placeholderNotifyMe => '준비되면 알림 받기';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSystem => '시스템 기본';

  @override
  String get settingsLanguageEnglish => 'English (영어)';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeDark => '다크 (기본)';

  @override
  String get settingsNotifications => '일일 알림';

  @override
  String get settingsNotificationsDesc => '매일 아침 오늘의 운세를 받아보세요';

  @override
  String get homeNotifTitle => '매일 아침 8시, 오늘 조심할 것만 알려드려요.';

  @override
  String get homeNotifSubtitle => '광고 푸시 X, 한 줄 알림만 가요';

  @override
  String get homeNotifEnable => '켜기';

  @override
  String get homeNotifOn => '켜짐 · 오전 8:00';

  @override
  String get homeNotifPermissionDenied => 'iOS 설정에서 알림을 허용해 주세요.';

  @override
  String get homeNotifEnabledSnack => '매일 오전 8시 알림이 켜졌어요.';

  @override
  String get homeNotifDisabledSnack => '일일 알림을 껐어요.';

  @override
  String get homeNotifSampleTitle => 'Pillar Seer · 오늘의 한 줄';

  @override
  String get homeNotifSampleBody => '오늘의 점수, 행운의 색, 한 줄 조언을 확인해 보세요.';

  @override
  String homeNotifOnAt(Object hh, Object mm) {
    return '켜짐 · $hh:$mm';
  }

  @override
  String get settingsNotifTimeLabel => '알림 시간';

  @override
  String get settingsNotifTimeHint => '매일 이 시간에 알림이 와요';

  @override
  String get settingsNotifTimePickerTitle => '알림 시간 선택';

  @override
  String settingsNotifTimeDoneSnack(Object hh, Object mm) {
    return '알림 시간을 $hh:$mm로 바꿨어요.';
  }

  @override
  String get todayEventCaption => '오늘 당신에게 생길 수 있는 일';

  @override
  String get todayEventCtaDetail => '자세히 보기';

  @override
  String get todayEventStarHealth => '건강';

  @override
  String get todayEventDetailTitle => '오늘 사건 가능성';

  @override
  String get todayEventWhy => '왜 그런지';

  @override
  String get todayEventCaution => '조심하면 좋은 것';

  @override
  String get todayEventRecommend => '오늘 추천 행동';

  @override
  String get homeHourlyTitle => '오늘의 흐름 ⏰';

  @override
  String get homeHourlySubtitle => '지금 · 다음 · 저녁';

  @override
  String get homeHourlyNow => '지금';

  @override
  String get homeHourlyNext => '다음';

  @override
  String get homeHourlyLater => '저녁';

  @override
  String get homeHourlySeeAll => '오늘 12시간 흐름 전체 보기';

  @override
  String get homeHourlyFullTitle => '오늘의 12시간 흐름';

  @override
  String get homeStreakTitle => '매일 확인 연속';

  @override
  String homeStreakDays(Object days) {
    return '$days일';
  }

  @override
  String homeStreakLongest(Object days) {
    return '최장 $days일';
  }

  @override
  String get homeStreakNewDay => '오늘 +1';

  @override
  String get homeShareCard => '내 사주 공유하기';

  @override
  String get shareCardTitle => '사주 공유';

  @override
  String get shareCardSubtitle => '나의 한 줄 카드를 친구에게 보내요';

  @override
  String get shareCardSave => '이미지로 저장';

  @override
  String get shareCardSaved => '사진 앱에 저장됨';

  @override
  String get shareCardCopy => '텍스트 복사';

  @override
  String get shareCardCopied => '클립보드에 복사됨';

  @override
  String get shareCardClose => '닫기';

  @override
  String get resultBasisTitle => '이 풀이는 어떻게 계산됐어요';

  @override
  String get resultBasisCalendar => '달력';

  @override
  String get resultBasisSolar => '양력';

  @override
  String get resultBasisLunar => '음력 → 양력 (KASI)';

  @override
  String get resultBasisTimezone => '타임존';

  @override
  String get resultBasisTrueSun => '진태양시';

  @override
  String get resultBasisTrueSunOn => '적용됨 (출생지 경도 보정 + 균시차 ±16분)';

  @override
  String get resultBasisTrueSunOff => '표준시만 적용';

  @override
  String get resultBasisManseryeok => '만세력 출처';

  @override
  String get resultBasisManseryeokVal => 'KASI 발표값 대조 검증 (klc 패키지 + 자체 절기)';

  @override
  String get resultBasisYearBoundary => '년 기준';

  @override
  String get resultBasisYearBoundaryVal => '입춘 절입시각 (천체 계산, 약 ±20분)';

  @override
  String get resultPrecisionBadge => '정밀 모드';

  @override
  String get resultBasisDayBoundary => '일 기준';

  @override
  String get resultBasisDayBoundaryVal => '자시 (子時, 23:00 이후 다음날)';

  @override
  String get personalCardTitle => '오늘, 당신을 위한 한 줄';

  @override
  String get personalHeadlineLabel => '당신은';

  @override
  String get personalBodyLabel => '오늘 흐름';

  @override
  String get personalActionLabel => '이거 해보세요';

  @override
  String get personalCautionLabel => '주의할 점';

  @override
  String get settingsTrust => '신뢰 & 데이터';

  @override
  String get settingsTrustHowCalculated => '이 풀이는 어떻게 계산되나요';

  @override
  String get settingsTrustHowCalculatedDesc =>
      'KASI 기준 대조 · 입춘 기준 · 자시 규칙 · 진태양시 · 균시차 · 한국 DST 보정';

  @override
  String get settingsTrustDataLocal => '당신의 데이터는 이 기기 안에만';

  @override
  String get settingsTrustDataLocalDesc => '로그인 없음, 서버 전송 없음, 추적 없음';

  @override
  String get settingsTrustDeleteAll => '내 데이터 모두 삭제';

  @override
  String get settingsTrustDeleteAllDesc => '사주·연속 기록·설정까지 전부 삭제';

  @override
  String get settingsTrustOffline => '오프라인에서도 완전히 동작';

  @override
  String get settingsTrustOfflineDesc => '설치 후 네트워크 없이도 사용 가능';

  @override
  String get settingsDeletedSnack => '모든 데이터를 삭제했어요. 새로 시작합니다.';

  @override
  String get paywallTitle => 'Pillar Seer Pro';

  @override
  String get paywallSubtitle => '내 사주의 전체 흐름을 열어보세요';

  @override
  String get paywallHeadline => '오늘의 한 줄을 넘어서.';

  @override
  String get paywallSubline => '관계·일·돈·타이밍 리포트, 매일 개인화된 깊은 풀이.';

  @override
  String get paywallFreeColumn => '무료';

  @override
  String get paywallProColumn => 'Pro';

  @override
  String get paywallFeature1 => '일주 + 5행 분포';

  @override
  String get paywallFeature2 => '오늘의 30초 요약';

  @override
  String get paywallFeature3 => '시간대별 흐름';

  @override
  String get paywallFeature4 => 'K-pop 셀럽 비교';

  @override
  String get paywallFeature5 => '전체 Life Themes 6 영역';

  @override
  String get paywallFeature6 => '올해 연애 · 궁합 · 중요한 날짜';

  @override
  String get paywallFeature7 => '사람 관계 지도 (십신)';

  @override
  String get paywallFeature8 => '10년 인생 챕터 (大運) 풀 리딩';

  @override
  String get paywallFeature9 => '개인화 알림';

  @override
  String get paywallFeature10 => '다중 프로필 (가족·친구·연인)';

  @override
  String get paywallMonthly => '월간';

  @override
  String get paywallYearly => '연간';

  @override
  String get paywallLifetime => '평생';

  @override
  String get paywallMonthlyPrice => '월 5,900원';

  @override
  String get paywallYearlyPrice => '연 35,000원';

  @override
  String get paywallYearlyHint => '50% 할인';

  @override
  String get paywallLifetimePrice => '59,000원 단건';

  @override
  String get paywallLifetimeHint => '런칭 한정';

  @override
  String get paywallCta => 'Pro 시작하기';

  @override
  String get paywallSoon => '결제 곧 출시 — 이메일 남기면 얼리액세스 안내';

  @override
  String get paywallRestoreLater => '구매 복원 (나중에)';

  @override
  String get paywallClose => '다음에';

  @override
  String get profileReset => '사주 다시 입력';

  @override
  String get profileResetConfirmTitle => '내 사주 입력값을 지울까요?';

  @override
  String get profileResetConfirmDesc => '지우면 처음부터 다시 입력하게 돼요.';

  @override
  String get profileResetConfirmCta => '지우기';

  @override
  String get inputBirthdayManualHint => '직접 입력: YYYY-MM-DD (예: 1996-05-16)';

  @override
  String get inputBirthdayManualInvalid => '날짜 형식이 잘못됐어요 — YYYY-MM-DD';

  @override
  String get inputBirthdayPickButton => '또는 달력에서 선택';

  @override
  String get splashTrust => '절기·진태양시 자동';

  @override
  String get settingsSajuOptions => '사주 계산 옵션';

  @override
  String get settingsLateNightZasi => '야자시 학파 (23시 이후)';

  @override
  String get settingsLateNightZasiDesc =>
      '기본 OFF: 23시 출생은 다음 날 일주 (정자시 — 한국에서 널리 쓰는 기준).\nON: 23시 출생도 같은 날 일주 유지 (야자시 학파).';

  @override
  String get settingsLateNightZasiSnackOn => '야자시 학파 ON — 사주를 다시 입력하면 적용돼요';

  @override
  String get settingsLateNightZasiSnackOff => '야자시 학파 OFF — 사주를 다시 입력하면 적용돼요';

  @override
  String get settingsApplyTrueSunTime => '진태양시 보정 (서울 -32분 + 균시차 ± 16분)';

  @override
  String get settingsApplyTrueSunTimeDesc =>
      '정통 명리학 기본. 끄면 표준시(KST)로 계산.\n출생지 도시명을 입력하면 longitude 자동 보정.';

  @override
  String get settingsApplyTrueSunTimeSnackOn => '진태양시 ON — 다시 입력하면 적용돼요';

  @override
  String get settingsApplyTrueSunTimeSnackOff => '진태양시 OFF — 표준시로 계산됩니다';

  @override
  String get resultTrustLine =>
      'KASI 기준 대조 + 입춘·12절 절입 천체 계산 + 진태양시·균시차 + 한국 DST(1948-1988) 자동 보정.';

  @override
  String get resultProHookHeader => '더 깊게 보고 싶다면?';

  @override
  String get resultProHookYearLoveTitle => '올해 연애 흐름 보기';

  @override
  String get resultProHookYearLoveTeaser => '올해는 관계가 깊어지는 달과 멀어지는 달이 갈려요.';

  @override
  String get resultProHookCompatTitle => '그 사람과 궁합 보기';

  @override
  String get resultProHookCompatTeaser =>
      '상대 생년월일을 넣으면 끌리는 이유와 부딪히는 지점이 한눈에 보여요.';

  @override
  String get resultProHookDatesTitle => '올해 중요한 날짜';

  @override
  String get resultProHookDatesTeaser => '결정·발표·런칭을 위한 길일/피할 날을 미리 확인하세요.';

  @override
  String get resultProHookCta => '자세히 보기';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsPrivacy => '개인정보 처리방침';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsContact => '고객 문의';

  @override
  String get modalComingSoonTitle => 'Phase 2에 추가 예정';

  @override
  String get modalComingSoonDesc => '이 기능은 곧 추가됩니다. 준비되면 알려드릴까요?';

  @override
  String get modalNotifyMe => '알림 받기';

  @override
  String get modalNotNow => '다음에';

  @override
  String get modalNotifyConfirm => '준비되면 알려드리겠습니다!';

  @override
  String get devGateTitle => '코드 입력';

  @override
  String get devGateHint => '코드';

  @override
  String get devGateApply => '적용';

  @override
  String get devGateCancel => '취소';

  @override
  String get devGateUnlocked => 'Pro 기능이 해제되었습니다.';

  @override
  String get devGateLocked => '무료 모드로 돌아갔습니다.';

  @override
  String get devGateInvalid => '인식할 수 없는 코드입니다.';

  @override
  String get resultDayMasterDeepTitle => '당신의 중심 성향 · 日 干';

  @override
  String get resultDayMasterTermHint => '= 일간 (日干) — 사주의 중심';

  @override
  String get resultFiveElementsDetailTitle => '5가지 에너지 균형 · 五 行';

  @override
  String get resultFiveElementsTermHint => '= 오행 (五行) — 당신 안의 다섯 가지 에너지';

  @override
  String get resultTenGodsTitle => '십신 — 사람 관계 지도 · 十 神';

  @override
  String get resultTenGodsTermHint => '= 십신 (十神) — 사람·돈·일이 당신에게 어떻게 보이는지';

  @override
  String get resultLifeThemesTitle => '삶의 큰 그림 · 主 題';

  @override
  String get resultTenYearLuckTitle => '10년 흐름 · 大 運';

  @override
  String get resultTenYearLuckTermHint => '= 대운 (大運) — 지금 살고 있는 10년 흐름';

  @override
  String get resultThisYearTitle => '올해의 흐름 · 歲 運';

  @override
  String get resultThisYearTermHint => '= 세운 (歲運)';

  @override
  String get resultLuckyTitle => '오늘의 행운 · 吉';

  @override
  String get resultIntroLeadIn => '당신은';

  @override
  String get resultIntroLeadOut => '사람이에요.';

  @override
  String get resultFirstTimeBanner => '사주 처음이세요? 30초 가이드 보기 →';

  @override
  String get resultGuideTitle => '30초만에 이해하는 사주';

  @override
  String get resultGuideBody =>
      '생년월일+시간으로 네 기둥(年·月·日·時)이 만들어져요. 그 중 일주(日)가 \'당신을 가장 잘 보여주는 한 글자\'. 5가지 에너지(나무·불·흙·쇠·물)의 균형이 평소 성격을 만들어요. 나머지 풀이(관계·일·운세)는 모두 여기서 시작해요.';

  @override
  String get resultGuideGotIt => '알겠어요';

  @override
  String get resultPillarsCardTitle => '당신의 네 기둥 (年·月·日·時)';

  @override
  String get resultThreeHitHeader => '당신을 30초로 요약하면';

  @override
  String get resultThreeHitPersonalityLabel => '성격';

  @override
  String get resultThreeHitLoveLabel => '연애';

  @override
  String get resultThreeHitTodayLabel => '오늘';

  @override
  String get resultWhyLabel => '이렇게 풀이된 이유:';

  @override
  String get resultEasyModeBannerTitle => '사주 처음이세요?';

  @override
  String get resultEasyModeBannerDesc => '어려운 말 없이 풀어서 보여드릴게요.';

  @override
  String get resultEasyModeBannerCta => '쉽게 보기';

  @override
  String get resultEasyModeBannerSkip => '그냥 볼게요';

  @override
  String get discoverCompareTitle => '나 + ';

  @override
  String discoverCompareSame(Object pillar) {
    return '같은 $pillar 타입 — 분위기가 비슷해요.';
  }

  @override
  String discoverCompareDifferent(Object mine, Object theirs) {
    return '다른 타입: $mine vs $theirs';
  }

  @override
  String get discoverCompareSimilar => '닮은 점';

  @override
  String get discoverCompareContrast => '다른 점';

  @override
  String get discoverCompareShareCard => '공유 카드 만들기';

  @override
  String get discoverCompareSeeChart => '궁합 리포트 보기';

  @override
  String get discoverCompareClose => '닫기';

  @override
  String get resultThemeCareer => '직업';

  @override
  String get resultThemeWealth => '재물';

  @override
  String get resultThemeLove => '애정';

  @override
  String get resultThemeHealth => '건강';

  @override
  String get resultThemeFamily => '가족';

  @override
  String get resultThemeFame => '명예';

  @override
  String get resultProLocked => 'PRO';

  @override
  String get resultUnlockHint => '전체 풀이를 잠금 해제하면 모든 섹션이 열립니다.';

  @override
  String get reportsHomeTitle => '심층 리포트';

  @override
  String get reportsHomeSubtitle => '일진을 넘어선 깊은 풀이.';

  @override
  String get reportsCardCompatibility => '궁합';

  @override
  String get reportsCardCompatibilityDesc => '두 사주의 케미. 오행 조화 + 기둥 공명.';

  @override
  String get reportsCardTojeong => '토정비결 (土亭祕訣)';

  @override
  String get reportsCardTojeongDesc => '신년운세 — 144괘 + 12개월 흐름.';

  @override
  String get reportsCardDatePicking => '택일 (擇日)';

  @override
  String get reportsCardDatePickingDesc => '결혼·개업·이사 등 길일 vs 흉일 가이드.';

  @override
  String get reportsCardDream => '해몽 (解夢)';

  @override
  String get reportsCardDreamDesc => '꿈 상징·테마로 한국 전통 해몽 검색.';

  @override
  String get compatTitle => '궁합 (宮合)';

  @override
  String get compatYouLabel => '나';

  @override
  String get compatPartnerLabel => '상대';

  @override
  String get compatEnterPartner => '상대방의 생일 정보를 입력하세요';

  @override
  String get compatPartnerName => '상대 이름';

  @override
  String get compatCalculate => '궁합 계산';

  @override
  String get compatMatchScore => '궁합 점수';

  @override
  String get compatElementsHeader => '오행 공명';

  @override
  String get compatPillarHeader => '기둥 케미';

  @override
  String get compatVerdictHigh => '자력처럼 끌리는 결합 — 오행이 서로를 살리는 사이클.';

  @override
  String get compatVerdictMid => '균형은 가능한 사이 — 마찰이 두 사람을 다듬으니 솔직함이 필요합니다.';

  @override
  String get compatVerdictLow => '강한 중력의 인연 — 의식하면 빛나고, 방치하면 지칩니다.';

  @override
  String get tojeongTitle => '토정비결 (土亭祕訣)';

  @override
  String get tojeongSubtitle => '올 한 해의 144괘 운세.';

  @override
  String get tojeongHexagram => '당신의 괘';

  @override
  String get tojeongYearOverview => '올해 개관';

  @override
  String get tojeongMonthlyHeader => '월별 흐름';

  @override
  String get datePickTitle => '택일 (擇日)';

  @override
  String get datePickSubtitle => '앞으로 30일 길일을 찾아드립니다.';

  @override
  String get datePickGoodDays => '길일';

  @override
  String get datePickAvoidDays => '피할 날';

  @override
  String get datePickNeutral => '평일';

  @override
  String get datePickReason => '이유';

  @override
  String get dreamTitle => '해몽 (解夢)';

  @override
  String get dreamSearchHint => '꿈 키워드 검색 (예: 뱀, 물)';

  @override
  String get dreamCategoryAll => '전체';

  @override
  String get dreamCategoryAuspicious => '길몽';

  @override
  String get dreamCategoryWarning => '경고';

  @override
  String get dreamCategoryWealth => '재물';

  @override
  String get dreamCategoryLove => '애정';

  @override
  String get dreamCategoryFamily => '가족';

  @override
  String get discoverTitle => '디스커버';

  @override
  String get discoverSubtitle => 'K-pop·K-drama 사주를 풀어보세요.';

  @override
  String get discoverFilterAll => '전체';

  @override
  String get discoverFilterIdol => '아이돌';

  @override
  String get discoverFilterActor => '배우';

  @override
  String get discoverFilterAthlete => '운동선수';

  @override
  String get discoverFilterIcon => '아이콘';

  @override
  String get discoverShareCompare => '내 사주와 비교';

  @override
  String get resultShareHeroLabel => '친구에게 보내기';

  @override
  String get resultShareHeroSub => 'SHARE · 友';

  @override
  String get resultShareAgain => '다시 공유';

  @override
  String get settingsNotificationTone => '알림 톤';

  @override
  String get settingsNotificationToneHint => '어른 톤 / 중고생 톤 — 일상 단어 선택';

  @override
  String get settingsNotificationToneAdult => '어른';

  @override
  String get settingsNotificationToneMz => '중고생';

  @override
  String get profileShareCard => '내 사주 카드 공유';

  @override
  String get profileShareCardFallback => '공유 실패 — 카드 내용을 클립보드에 복사했어요';

  @override
  String get compatPrefilledTag => '셀럽 자동 입력';

  @override
  String get discoverSubRouteLabel => '디스커버';

  @override
  String get kpopEmptyTitle => '내 생일을 먼저 넣어야 케미가 보여요';

  @override
  String get kpopEmptySub => 'BIRTHDATE FIRST · 命';

  @override
  String get kpopEmptyBody => '내 사주 일주를 알아야 최애와의 케미를 비교할 수 있어요.';

  @override
  String get kpopEmptyCta => '생일 입력하러 가기';

  @override
  String get emptyStateSajuRequiredTitle => '사주 정보를 먼저 넣어주세요';

  @override
  String get emptyStateSajuRequiredSub => 'ADD YOUR SAJU · 命';

  @override
  String get emptyStateSajuRequiredBody =>
      '내 사주 네 글자가 있어야 오늘의 풀이와 리포트를 보여줄 수 있어요.';

  @override
  String get emptyStateSajuRequiredCta => '사주 입력하러 가기';

  @override
  String get settingsCalcBasisRow => '사주 계산 기준 안내';

  @override
  String get settingsCalcBasisRowDesc =>
      '이 앱이 진태양시 · 자시 · 절기 · 음력 · 출생지를 어떻게 다루는지 한눈에 봐요';

  @override
  String get infoCalcBasisTitle => '사주 계산 기준 안내';

  @override
  String get infoCalcBasisIntro =>
      '이 앱이 사주를 계산할 때 쓰는 5가지 기준이에요. 어려운 한자말 없이 한 줄씩 풀어드릴게요.';

  @override
  String get infoCalcBasisTrueSunLabel => '진태양시 보정';

  @override
  String get infoCalcBasisTrueSunDesc =>
      '사주는 시계 시간 대신 태양이 실제 가장 높이 뜨는 시각을 기준으로 봐요. 이 앱은 서울 기준으로 약 32분 일찍 보정해서 계산해요.';

  @override
  String get infoCalcBasisJasiLabel => '자시 학파 (밤 11시~새벽 1시)';

  @override
  String get infoCalcBasisJasiDesc =>
      '밤 11시부터 새벽 1시 사이를 자시(子時)라고 불러요. 학파에 따라 일주가 갈리는데, 이 앱은 밤 11시부터 다음 날로 보는 정자시(조자시)를 기본으로 써요.';

  @override
  String get infoCalcBasisSolarTermLabel => '절기 기준 월주';

  @override
  String get infoCalcBasisSolarTermDesc =>
      '달력 1월이 아니라 절기로 사주의 한 달이 바뀌어요. 예를 들어 입춘(양력 2월 4일 무렵)이 한 해의 첫 달 시작점이에요.';

  @override
  String get infoCalcBasisLunarLabel => '음력 · 양력 입력';

  @override
  String get infoCalcBasisLunarDesc =>
      '양력 생일을 기본으로 받고, 음력으로 입력해도 자동으로 양력으로 바꿔서 계산해요. 윤달도 지원해요.';

  @override
  String get infoCalcBasisCityLabel => '출생지 경도 보정';

  @override
  String get infoCalcBasisCityDesc =>
      '서울이 기본이에요. 부산이나 광주처럼 다른 도시에서 태어났으면 도시 경도에 맞게 추가로 보정해요. 해외 출생지 지원은 다음 단계 작업이에요.';

  @override
  String get infoCalcBasisFooter =>
      '더 깊은 계산 기준(억부용신·조후용신·격국용신 등)은 다음 라운드에서 안내해드릴게요.';

  @override
  String get celebDisclosureBanner => '공개 생일 기반의 가벼운 비교예요';

  @override
  String get celebDisclosureBannerHelper =>
      '유명인 출생시간은 공개 자료가 없어서 시주(시각 기둥)는 빼고 일주만 비교해요. 재미로만 봐주세요.';

  @override
  String get celebCardConfidenceLabel => '공개 생일 기반 · 출생시간 미상';

  @override
  String get hourPillarUnknownDisclaimer =>
      '시간을 모르셔서 시주(시각 기둥)는 비워뒀어요. 큰 흐름 위주로 봐주세요.';

  @override
  String get hourPillarUnknownBadge => '시주 미포함 결과';

  @override
  String get timeUnknownAffectsAccuracy => '시간 정보가 없어 이 영역은 정확도가 살짝 떨어져요';
}
