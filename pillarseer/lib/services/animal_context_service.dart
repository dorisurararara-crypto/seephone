// Pillar Seer — Round 82 sprint 6: 한글 동물 / 일진 단독 노출 영역에 사주와 관계
// 1줄 helper 를 만들어주는 service.
//
// 사용자 verbatim 9문제 (R82) 중 #7+#8+#9:
//   #7 "금토끼 금원숭이 이런거 나오는데 그게 뭔지 설명도 없고"
//   #8 "조승현아 오늘은 금토끼에 날이야 이건 또 갑자기 뭐하는거며 설명도 없고"
//   #9 "오늘의 일진은 토 쥐 이것만있는데 이것도 설명도 없고"
//
// 본 service 는 두 종류 helper 1줄을 만든다:
//   1) selfPairHelperKo — "당신 일주" 라벨 (예: "금 토끼") 옆 1줄
//   2) todayPillarHelperKo — "오늘의 일진" (예: "丙戌") 옆 1줄, 사용자 일간과의 관계
//
// 절대 룰:
//   - 한자 jargon 노출 X (TenGod.ko 의 "정관 (正官)" 형태 직접 사용 X)
//   - AI 슬롭 X (R77 sprint 4 blacklist 준수)
//   - Apologetic AI 어조 X
//   - 자미두수 별 이름 nameKo 노출 X (R70 mandate)
//   - 평이한 한국 MZ 중학생 K-POP 팬 페르소나 (M5 mandate)
//   - 모든 출력은 ≤60자, 마침표 1회로 끝남.

import 'ten_gods_service.dart';
import '../models/saju_result.dart';

class AnimalContextService {
  AnimalContextService._();

  /// "당신 일주" 라벨 (예: "금 토끼") 옆 1줄 helper.
  /// 사용자 본인의 dayPillar 한국어 의미 (예: "금 토끼" = 辛卯) 가
  /// 단독 노출되는 영역 (예: _FirstFoldGreeting 의 "조승현아, 오늘은 금 토끼의 날이야")
  /// 옆에 사주와의 관계 1줄 helper 를 추가하기 위함.
  ///
  /// 본인의 일주이므로 관계는 "= 평소 본인 분위기" 로 단정.
  /// 60일주 단위로 차이를 두기 위해 천간(10) + 지지(12) → 12 동물 별 한 줄 + 천간 5행 layer.
  ///
  /// 출력 예) "= 단단한 금 + 다정한 토끼. 평소 본인 분위기예요."
  /// R2 codex feedback: 5행 (금/목/화/토/수) 설명 + 12 동물별 설명 둘 다 반영.
  /// 모든 출력 ≤60자 cap (UI 압축 인증).
  static String selfPairHelperKo({
    required String dayChunGan,
    required String dayJiJi,
  }) {
    final el = _ganElement[dayChunGan];
    if (el == null) return _fallbackSelfHelper;
    final elPhrase = _elementSelfPhrase[el] ?? '';
    final animalPhrase = _animalSelfPhrase[dayJiJi] ?? '';
    if (elPhrase.isEmpty || animalPhrase.isEmpty) return _fallbackSelfHelper;
    // "= 단단한 금 + 다정한 토끼. 평소 본인 분위기예요." (≤60자).
    return '= $elPhrase + $animalPhrase. 평소 본인 분위기예요.';
  }

  /// "오늘의 일진" (예: 丙戌 / 戊子) 옆 1줄 helper.
  /// 사용자 일간 (dayChunGan) 과 오늘 일진 천간의 십신 관계 + 오늘 지지 동물 1단어
  /// → 평이한 한국어 1줄. 모든 출력 ≤60자.
  ///
  /// R2 codex feedback: 오늘 지지(동물) phrase 도 반영 (천간 십신만 X).
  /// 출력 예) "= 정관 (잡아주는 톤) — 오늘 戊子(쥐) = 한 박자 늦춰 가요."
  /// 단, 한자 jargon "정관" 자체는 사용자 노출 X — 평이한 자연어로.
  /// "= 잡아주는 분위기 + 쥐 (눈치). 한 박자 늦춰 가요."
  static String todayPillarHelperKo({
    required String userDayChunGan,
    required String todayPillar,
  }) {
    if (todayPillar.length != 2) return _fallbackTodayHelper;
    final todayGan = todayPillar[0];
    final todayJi = todayPillar[1];
    final aShort = animalShort[todayJi] ?? '';
    // 1차: 천간합 우선 (사용자 직관 — "마음이 맞는" 1줄 강한 신호)
    if (_isCheonganHap(userDayChunGan, todayGan)) {
      // R3 codex feedback: 천간합 분기도 일관된 "(오늘 <동물>)" suffix.
      const hapBase = '= 오늘 누군가와 마음이 맞기 쉬운 분위기';
      return aShort.isEmpty
          ? '$hapBase예요.'
          : '$hapBase (오늘 $aShort).';
    }
    final god = TenGodsService.godFor(userDayChunGan, todayGan);
    if (god == null) return _fallbackTodayHelper;
    final base = _tenGodPlainShort[god];
    if (base == null) return _fallbackTodayHelper;
    // 일진 지지 1단어 layer 추가 — "= <십신 평이> (오늘 <동물>)."
    return aShort.isEmpty ? '= $base.' : '= $base (오늘 $aShort).';
  }

  /// 천간 5합 (甲己 / 乙庚 / 丙辛 / 丁壬 / 戊癸)
  static bool _isCheonganHap(String a, String b) {
    const pairs = {'甲': '己', '乙': '庚', '丙': '辛', '丁': '壬', '戊': '癸'};
    if (pairs[a] == b) return true;
    if (pairs[b] == a) return true;
    return false;
  }

  /// 천간 5행
  static const _ganElement = {
    '甲': '木', '乙': '木',
    '丙': '火', '丁': '火',
    '戊': '土', '己': '土',
    '庚': '金', '辛': '金',
    '壬': '水', '癸': '水',
  };

  /// 12 지지 동물 별 selfPair phrase — "다정한 토끼" / "재치 있는 원숭이" 류.
  /// "AAA 한 BBB" 패턴 — 12 동물 모두 (한국 동물 이미지 + K-POP MZ 친화).
  /// 한자 jargon X / AI 슬롭 X / Apologetic AI X. 모든 entry ≤12자.
  static const _animalSelfPhrase = {
    '子': '눈치 빠른 쥐',
    '丑': '꾸준한 소',
    '寅': '용감한 호랑이',
    '卯': '다정한 토끼',
    '辰': '큰 그림의 용',
    '巳': '센스 좋은 뱀',
    '午': '에너지 말',
    '未': '부드러운 양',
    '申': '재치 있는 원숭이',
    '酉': '꼼꼼한 닭',
    '戌': '의리 있는 개',
    '亥': '속 깊은 돼지',
  };

  /// 천간 5행 별 selfPair phrase — "단단한 금" / "단단한 목" 류. ≤8자.
  static const _elementSelfPhrase = {
    '木': '단단한 목',
    '火': '뜨거운 화',
    '土': '든든한 토',
    '金': '단단한 금',
    '水': '유연한 수',
  };

  /// 12 지지 동물 별 todayPillar suffix 단어 — UI 압축 cap (≤4자).
  /// "(오늘 토끼)" 같이 sub-clause 에 들어가는 짧은 layer. public — test 가 참조.
  static const Map<String, String> animalShort = {
    '子': '쥐',
    '丑': '소',
    '寅': '호랑이',
    '卯': '토끼',
    '辰': '용',
    '巳': '뱀',
    '午': '말',
    '未': '양',
    '申': '원숭이',
    '酉': '닭',
    '戌': '개',
    '亥': '돼지',
  };

  /// 십신 → 짧은 평이 한국어 phrase (≤40자, UI 압축).
  /// "= " prefix 와 마침표는 호출 측에서 붙임.
  /// 한자 jargon 노출 X — "정관" / "식신" 같은 단어 사용 X.
  static const Map<TenGod, String> _tenGodPlainShort = {
    TenGod.bigyeon: '당신과 같은 분위기. 본인 페이스로 가기 좋아요',
    TenGod.geopjae: '비슷한데 살짝 부딪힐 수도 있는 분위기',
    TenGod.siksin: '표현하기 좋은 분위기. 말 한 마디 잘 받아져요',
    TenGod.sanggwan: '한 마디 던지기 좋아요. 톤은 한 단계 부드럽게',
    TenGod.pyeonjae: '작은 결과·돈 잡기 좋은 분위기',
    TenGod.jeongjae: '꾸준한 결과·돈 챙기기 좋은 분위기',
    TenGod.pyeongwan: '살짝 압박 들어와요. 한 박자 늦춰 가요',
    TenGod.jeonggwan: '잡아주는 분위기. 약속 지키면 잘 풀려요',
    TenGod.pyeonin: '챙겨주는 분위기. 도움 청해도 잘 받아요',
    TenGod.jeongin: '받쳐주는 분위기. 도와줄 사람이 와요',
  };

  static const String _fallbackSelfHelper = '평소 본인의 분위기예요.';
  static const String _fallbackTodayHelper = '= 평범하게 흘러가는 분위기예요.';
}
