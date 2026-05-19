// R98 sprint 1 — Korean particle (josa) helper.
//
// 사용자 OCR 보고:
//   "공간가 어느새 한 시간대로 흘러요"
//   → '공간' 은 받침(ㄴ) 끝, 조사 '가' 가 아닌 '이' 가 와야 자연스러움.
//
// 라이브 합성 위치 = `lib/screens/reports/kpop_compat_screen.dart` 안의
// `jiSceneKo` 12 entries × `$mySceneKo가 / $stSceneKo가 / $mySceneKo와` 4 template line
// → 12 × 4 = 48 조합 중 받침 끝 entry 절반 정도가 조사 깨짐.
//
// 본 helper 는 변수+조사 직결합을 끝내고, 끝 글자 받침 여부를 보고
// `이/가`, `은/는`, `을/를`, `과/와` 4 쌍을 자동 선택한다.
//
// 한글 받침 판별:
//   한글 음절 유니코드 = 0xAC00 ~ 0xD7A3.
//   (codeUnit - 0xAC00) % 28 == 0 이면 받침 없음, != 0 이면 받침 있음.
//
// 한자 fallback rule (보수):
//   한자 발음의 한국어 음을 정확히 알 수 없는 일반 한자는 받침 없음 (false) 으로 처리.
//   하지만 본 앱에서 user-facing prose 에 등장하는 한자(천간/지지 등)는
//   대부분 `kpop_compat_screen` 에서 변수에 인용되기 전 한국어 명사로 변환되기
//   때문에 (`jiSceneKo` 처럼) 한자 직접 조사 부착은 사실상 거의 없다.
//   안전하게 보수적인 동작을 위해 한자는 받침 없음 default + 자주 등장하는
//   천간/지지 + 오행 한자에 대해서만 한국 한자음(음독) 기준 받침 여부를 명시한다.
//
// 영문 fallback rule:
//   영어 단어 끝 글자의 발음으로 받침 여부 판별:
//     모음 (a/e/i/o/u/y) 끝 → 받침 없음 (false).
//     자음 끝 → 받침 있음 (true).
//   (정확한 한국어 차용 발음 룰이 아니지만 자연스러움이 더 보장됨.)
//
// 숫자 fallback rule:
//   숫자 끝은 한글 읽기로 결정 (예: `1` 일 → 받침 있음, `2` 이 → 받침 없음,
//   `3` 삼 → 받침 있음, `4` 사 → 받침 없음, ...).
//
// API 사용 예:
//   import 'package:pillarseer/services/korean_josa.dart';
//   '$scene${withSubj(scene)} 어느새 한 시간대로 흘러요.'
//   // '공간' → '공간이 어느새 ...'
//   // '대화' → '대화가 어느새 ...'

/// 천간/지지/오행 등 자주 쓰는 한자에 대한 한국 한자음 기준 받침 여부.
/// `true` = 받침 있음 (이/은/을/과 사용), `false` = 받침 없음 (가/는/를/와 사용).
/// 한자 사전 크기 = 27 (천간 10 + 지지 12 + 오행 5).
const Map<String, bool> _hanjaHasFinalConsonant = {
  // 천간
  '甲': true, // 갑 ㅂ
  '乙': true, // 을 ㄹ
  '丙': true, // 병 ㅇ
  '丁': true, // 정 ㅇ
  '戊': false, // 무
  '己': false, // 기
  '庚': true, // 경 ㅇ
  '辛': true, // 신 ㄴ
  '壬': true, // 임 ㅁ
  '癸': false, // 계
  // 지지
  '子': false, // 자
  '丑': true, // 축 ㄱ
  '寅': true, // 인 ㄴ
  '卯': false, // 묘
  '辰': true, // 진 ㄴ
  '巳': false, // 사
  '午': false, // 오
  '未': false, // 미
  '申': true, // 신 ㄴ
  '酉': false, // 유
  '戌': true, // 술 ㄹ
  '亥': false, // 해
  // 오행
  '木': true, // 목 ㄱ
  '火': false, // 화
  '土': false, // 토 (받침 없음)
  '金': true, // 금 ㅁ
  '水': false, // 수
};

/// 영문 모음 (lower case 기준).
const Set<String> _englishVowels = {'a', 'e', 'i', 'o', 'u', 'y'};

/// 숫자 끝 글자 (0~9) 의 한국어 읽기 받침 여부.
/// `0` 영 (ㅇ 받침) / `1` 일 (ㄹ) / `2` 이 / `3` 삼 (ㅁ) / `4` 사 /
/// `5` 오 / `6` 육 (ㄱ) / `7` 칠 (ㄹ) / `8` 팔 (ㄹ) / `9` 구.
const Map<String, bool> _digitFinalConsonant = {
  '0': true,
  '1': true,
  '2': false,
  '3': true,
  '4': false,
  '5': false,
  '6': true,
  '7': true,
  '8': true,
  '9': false,
};

/// 끝 글자 받침 여부 판별 — 공개 API (test 용).
///
/// 빈 문자열 / null-ish 입력은 받침 없음(false) 로 fallback.
bool hasFinalConsonant(String word) {
  if (word.isEmpty) return false;
  // 끝 글자만 검사.
  final lastChar = word.substring(word.length - 1);
  final cu = lastChar.codeUnitAt(0);
  // 1) 한글 음절.
  if (cu >= 0xAC00 && cu <= 0xD7A3) {
    return ((cu - 0xAC00) % 28) != 0;
  }
  // 2) 한자 exception 사전.
  final hanja = _hanjaHasFinalConsonant[lastChar];
  if (hanja != null) return hanja;
  // 3) 영문.
  final lower = lastChar.toLowerCase();
  if (RegExp(r'[a-z]').hasMatch(lower)) {
    // 영문 모음 끝 → 받침 없음, 자음 끝 → 받침 있음.
    return !_englishVowels.contains(lower);
  }
  // 4) 숫자.
  final digit = _digitFinalConsonant[lastChar];
  if (digit != null) return digit;
  // 5) 그 외 (한자 사전 외 / 구두점 / 기타) → 보수적으로 받침 없음.
  return false;
}

/// 주격 조사 — 받침 있으면 `이`, 없으면 `가`.
String withSubj(String word) => hasFinalConsonant(word) ? '이' : '가';

/// 보조사 — 받침 있으면 `은`, 없으면 `는`.
String withTop(String word) => hasFinalConsonant(word) ? '은' : '는';

/// 목적격 조사 — 받침 있으면 `을`, 없으면 `를`.
String withObj(String word) => hasFinalConsonant(word) ? '을' : '를';

/// 공동격 조사 — 받침 있으면 `과`, 없으면 `와`.
String withWith(String word) => hasFinalConsonant(word) ? '과' : '와';
