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
  String get splashTagline => '사주 네 기둥으로\n당신의 운명을 읽다';

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
  String get inputBirthCityHelper => '기록용 — 시간대 자동 보정 곧 추가';

  @override
  String get inputCalendar => '달력:';

  @override
  String get inputSolar => '양력';

  @override
  String get inputLunar => '음력 (준비 중)';

  @override
  String get inputGender => '성별:';

  @override
  String get inputGenderMale => '남자';

  @override
  String get inputGenderFemale => '여자';

  @override
  String get inputGenderOther => '기타';

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
  String get resultFiveElements => '오행 분포';

  @override
  String get resultDominant => '강한 기운';

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
  String get resultUnlockFull => '전체 풀이 잠금 해제';

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
  String get homeExplanationLow => '오늘 일진이 일간을 극합니다. 천천히 움직이고 중심을 지키세요.';

  @override
  String get homeExplanationMid => '평온한 하루입니다. 꾸준한 행동이 최선의 결과를 가져옵니다.';

  @override
  String get homeExplanationHigh => '오늘 기운이 본성과 어울립니다. 과감하게 움직이세요.';

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
  String get navHome => '홈';

  @override
  String get navReading => '사주';

  @override
  String get navReports => '리포트';

  @override
  String get navDiscover => '탐색';

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
}
