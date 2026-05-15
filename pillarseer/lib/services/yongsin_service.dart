// Pillar Seer — 용신(用神) 서비스.
//
// 용신: 사주에서 가장 필요한 오행. 명리학 핵심 — 모든 운기·운명의 기준.
//
// 도출 원리:
// 1. 신왕(身旺) — 일간이 강함 → 일간을 빼앗는 오행이 용신.
//    - 식상(食傷) 용신: 일간이 만드는 오행 (木→火, 火→土, ...)
//    - 재성(財星) 용신: 일간이 극하는 오행 (木→土, 火→金, ...)
//    - 관성(官星) 용신: 일간을 극하는 오행 (木←金, 火←水, ...)
// 2. 신약(身弱) — 일간이 약함 → 일간을 돕는 오행이 용신.
//    - 인성(印星) 용신: 일간을 만들어주는 오행 (木←水, 火←木, ...)
//    - 비겁(比劫) 용신: 일간과 같은 오행
//
// 중화(中和): 균형 → 사주 결핍 오행이 용신 (가장 약한 오행 보충).
//
// Round 83 sprint 6 — 억부 / 조후 / 격국 3 종 분리 표시 wire.
// 사용자 노출 카드에서 3 종 동시 비교 + 신뢰도 라벨 ("강한 확신" / "복합 사주") 노출.

import '../models/saju_result.dart';
import 'ten_gods_service.dart';

class YongsinService {
  /// 일간 오행 + 강약 + 5행 분포 → 용신 오행 (1차) + 희신 (2차).
  ///
  /// Round 80 sprint 6 — `monthBranch` optional 인자 추가 (조후용신 보정).
  /// monthBranch != null → reason 끝에 계절 보정 한 줄 추가 + chowhuYongsin getter
  /// 같이 노출. yongsin/huisin 자체는 backward compat 유지 (R69 회귀 가드).
  static ({String yongsin, String huisin, String reason, String? chowhuYongsin}) judge({
    required String dayMasterElement, // 木/火/土/金/水
    required String strengthLabel, // 신강/신왕/중화/신약/신쇠
    required int wood,
    required int fire,
    required int earth,
    required int metal,
    required int water,
    String? monthBranch, // Round 80 sprint 6 — 조후 보정 입력 (월지).
  }) {
    final dm = dayMasterElement;
    // 5행 → 상생/상극 관계.
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const generatedBy = {
      '木': '水', '火': '木', '土': '火', '金': '土', '水': '金',
    };
    const overcomes = {
      '木': '土', '火': '金', '土': '水', '金': '木', '水': '火',
    };
    const overcomeBy = {
      '木': '金', '火': '水', '土': '木', '金': '火', '水': '土',
    };

    int elementValue(String el) {
      switch (el) {
        case '木':
          return wood;
        case '火':
          return fire;
        case '土':
          return earth;
        case '金':
          return metal;
        case '水':
          return water;
      }
      return 0;
    }

    String yongsin = '';
    String huisin = '';
    String reason = '';

    if (strengthLabel == '신강' || strengthLabel == '신왕') {
      // 일간 강 → 빼앗는 오행 용신.
      // 식상 > 재성 > 관성 우선.
      final siksang = generates[dm] ?? ''; // 일간이 만드는 오행 (식상)
      final jaeseong = overcomes[dm] ?? ''; // 일간이 극하는 오행 (재성)
      final gwanseong = overcomeBy[dm] ?? ''; // 일간을 극하는 오행 (관성)

      // 5행 분포에서 가장 적은 오행이 용신 후보 (균형 회복).
      final candidates = [siksang, jaeseong, gwanseong];
      candidates.sort((a, b) => elementValue(a).compareTo(elementValue(b)));
      yongsin = candidates[0]; // 가장 적은 (가장 필요한)
      huisin = candidates[1];
      reason = '신강 사주 — 일간을 빼앗는 오행이 용신. '
          '$dm 일간 + 식상($siksang)/재성($jaeseong)/관성($gwanseong) 중 부족한 $yongsin 가 1차 용신.';
    } else if (strengthLabel == '신약' || strengthLabel == '신쇠') {
      // 일간 약 → 돕는 오행 용신.
      // 인성 > 비겁 우선.
      final inseong = generatedBy[dm] ?? ''; // 일간을 만들어주는 오행 (인성)
      final bigeop = dm; // 일간과 같은 오행 (비겁)

      // 5행 분포에서 인성·비겁 중 약한 쪽 보충.
      final candidates = [inseong, bigeop];
      candidates.sort((a, b) => elementValue(a).compareTo(elementValue(b)));
      yongsin = candidates[0];
      huisin = candidates[1];
      reason = '신약 사주 — 일간을 돕는 오행이 용신. '
          '$dm 일간 + 인성($inseong)/비겁($bigeop) 중 부족한 $yongsin 가 1차 용신.';
    } else {
      // 중화 — 5행 중 가장 약한 오행 = 용신.
      const all = ['木', '火', '土', '金', '水'];
      final sorted = List<String>.from(all)
        ..sort((a, b) => elementValue(a).compareTo(elementValue(b)));
      yongsin = sorted[0];
      huisin = sorted[1];
      reason = '중화 사주 — 5행 균형. 가장 부족한 $yongsin 가 용신 (균형 회복).';
    }

    String? chowhu;
    if (monthBranch != null && monthBranch.isNotEmpty) {
      chowhu = _chowhuYongsinFor(monthBranch);
      if (chowhu != null) {
        final season = _seasonOfMonth(monthBranch);
        if (chowhu == yongsin) {
          reason += ' 계절 조후 ($season)도 같은 $chowhu 라 정합도가 한 번 더 올라가요.';
        } else {
          reason += ' 계절 조후 ($season)는 $chowhu 쪽이 필요한데, '
              '강약 우선 $yongsin 와 차이가 있어요. 둘 다 활용하면 균형이 더 좋아져요.';
        }
      }
    }

    return (
      yongsin: yongsin,
      huisin: huisin,
      reason: reason,
      chowhuYongsin: chowhu,
    );
  }

  /// 월지 → 계절 조후 용신 (계절 보온/식힘).
  /// 봄(寅卯辰) 火 / 여름(巳午未) 水 / 가을(申酉戌) 木 / 겨울(亥子丑) 火.
  static String? _chowhuYongsinFor(String monthBranch) {
    const map = {
      '寅': '火', '卯': '火', '辰': '火',
      '巳': '水', '午': '水', '未': '水',
      '申': '木', '酉': '木', '戌': '木',
      '亥': '火', '子': '火', '丑': '火',
    };
    return map[monthBranch];
  }

  static String _seasonOfMonth(String monthBranch) {
    const spring = {'寅', '卯', '辰'};
    const summer = {'巳', '午', '未'};
    const autumn = {'申', '酉', '戌'};
    const winter = {'亥', '子', '丑'};
    if (spring.contains(monthBranch)) return '봄';
    if (summer.contains(monthBranch)) return '여름';
    if (autumn.contains(monthBranch)) return '가을';
    if (winter.contains(monthBranch)) return '겨울';
    return '계절';
  }

  /// 용신 오행 → 실생활 보충 방법 (locale-aware).
  /// Round 83 sprint 6 — ko 본문에서 "기운" jargon 제거 (M5 mandate). 5축 행동
  /// 처방은 그대로 유지 — 친근 명사 ("나무 / 불 / 흙 / 쇠 / 물") 로 시작.
  static String compensationGuide(String yongsin, {bool ko = false}) {
    if (ko) {
      const koMap = {
        '木': '나무 보충 — 식물 키우기, 산책, 동쪽 활동, 초록색·청색, 신맛 음식.',
        '火': '불 보충 — 햇빛, 운동, 남쪽 활동, 빨간색·자주색, 쓴맛 음식.',
        '土': '흙 보충 — 산·들·중앙, 노란색·갈색, 단맛 음식, 안정된 루틴.',
        '金': '쇠 보충 — 정리·청소, 서쪽 활동, 흰색·은색, 매운맛 음식, 명료한 결정.',
        '水': '물 보충 — 휴식·수면, 북쪽 활동, 검은색·파란색, 짠맛 음식, 직관 시간.',
      };
      return koMap[yongsin] ?? '';
    }
    const enMap = {
      '木': 'Boost Wood — plants, walks, east direction, green/blue, sour food.',
      '火': 'Boost Fire — sunlight, exercise, south, red/purple, bitter food.',
      '土': 'Boost Earth — mountains, center, yellow/brown, sweet food, steady routine.',
      '金': 'Boost Metal — organize, west, white/silver, spicy food, clear decisions.',
      '水': 'Boost Water — rest, north, black/blue, salty food, intuition time.',
    };
    return enMap[yongsin] ?? '';
  }

  /// Round 78 sprint 5 — 용신 5축 (색·방향·음식·시간대·요일) 행동 처방 record.
  /// 25 entry (5행 × 5축) 모두 ko/en + body 1줄 — H9/H15 분기 입력.
  ///
  /// 운세의신 V2 분석 결과 흡수 — 추상 "용신 木 이에요" → 5축 실생활 행동 처방.
  static ({String color, String direction, String food, String time, String weekday})
      guideAxesKo(String yongsin) {
    const map = {
      '木': (
        color: '초록·청색 (옷·소품 한 가지)',
        direction: '동·동남쪽 활동',
        food: '신맛 (식초·라임·풋사과)',
        time: '새벽~아침 (寅卯시 3-7시)',
        weekday: '목요일',
      ),
      '火': (
        color: '빨강·자주 (옷·소품 한 가지)',
        direction: '남쪽 활동',
        food: '쓴맛 (커피·녹차·고들빼기)',
        time: '오전 (巳午시 9시-13시)',
        weekday: '화요일',
      ),
      '土': (
        color: '노랑·갈색 (옷·소품 한 가지)',
        direction: '중앙·북동 활동',
        food: '단맛 (꿀·고구마)',
        time: '환절기 시간대 (辰未戌丑시)',
        weekday: '토요일',
      ),
      '金': (
        color: '흰·은색 (옷·소품 한 가지)',
        direction: '서·서북쪽 활동',
        food: '매운맛 (마늘·생강)',
        time: '오후 (申酉시 15-19시)',
        weekday: '금요일',
      ),
      '水': (
        color: '검정·청남 (옷·소품 한 가지)',
        direction: '북쪽 활동',
        food: '짠맛 (해조류·생선)',
        time: '늦은 밤 (亥子시 21시-1시)',
        weekday: '수요일',
      ),
    };
    return map[yongsin] ??
        (color: '', direction: '', food: '', time: '', weekday: '');
  }

  /// 영문 5축 record. R77 plain casual + em dash 가드 (em dash 0).
  static ({String color, String direction, String food, String time, String weekday})
      guideAxesEn(String yongsin) {
    const map = {
      '木': (
        color: 'green or blue (one item)',
        direction: 'east or southeast',
        food: 'sour (vinegar, lime, green apple)',
        time: 'early morning (3-7 am)',
        weekday: 'Thursday',
      ),
      '火': (
        color: 'red or purple (one item)',
        direction: 'south',
        food: 'bitter (coffee, green tea)',
        time: 'late morning (9 am-1 pm)',
        weekday: 'Tuesday',
      ),
      '土': (
        color: 'yellow or brown (one item)',
        direction: 'center or northeast',
        food: 'sweet (honey, sweet potato)',
        time: 'transition hours',
        weekday: 'Saturday',
      ),
      '金': (
        color: 'white or silver (one item)',
        direction: 'west or northwest',
        food: 'spicy (garlic, ginger)',
        time: 'afternoon (3-7 pm)',
        weekday: 'Friday',
      ),
      '水': (
        color: 'black or navy (one item)',
        direction: 'north',
        food: 'salty (seaweed, fish)',
        time: 'late night (9 pm-1 am)',
        weekday: 'Wednesday',
      ),
    };
    return map[yongsin] ??
        (color: '', direction: '', food: '', time: '', weekday: '');
  }

  /// 용신 5축 중 1축 한 줄 — deterministic seed 로 선택.
  /// today_deep / home_screen 행동 처방 본문에 join 용.
  static String oneAxisLineKo(String yongsin, int seed) {
    final axes = guideAxesKo(yongsin);
    if (axes.color.isEmpty) return '';
    final list = [axes.color, axes.direction, axes.food, axes.time, axes.weekday];
    final idx = (seed.abs()) % list.length;
    return list[idx];
  }

  static String oneAxisLineEn(String yongsin, int seed) {
    final axes = guideAxesEn(yongsin);
    if (axes.color.isEmpty) return '';
    final list = [axes.color, axes.direction, axes.food, axes.time, axes.weekday];
    final idx = (seed.abs()) % list.length;
    return list[idx];
  }

  // ── Round 83 sprint 6 — 격국용신 + 3 종 분리 + 신뢰도 라벨 ──

  /// 격국 보좌 용신 (격국용신).
  ///
  /// 명리 학파 simplification — 격국 (월지 본기 십신) 기준 보좌 오행:
  /// - 정관격 / 편관격 (관성격) → 인성 (관성 통제, 일간 보호) = 일간을 생하는 오행
  /// - 정인격 / 편인격 (인성격) → 관성 (인성 살림) = 일간을 극하는 오행
  /// - 정재격 / 편재격 (재성격) → 식상 (재성 살림) = 일간이 생하는 오행
  /// - 식신격 / 상관격 (식상격) → 재성 (식상 결실) = 일간이 극하는 오행
  /// - 건록격 (비견) → 식상 (강한 일간 설기) = 일간이 생하는 오행
  /// - 양인격 (겁재) → 관성 (강한 일간 제어) = 일간을 극하는 오행
  /// - 그 외 → null
  ///
  /// dayMasterElement: 木/火/土/金/水 (일간 5행).
  /// dayMaster: 천간 (甲乙丙丁戊己庚辛壬癸).
  /// monthJi: 월지 (子丑寅...).
  static String? gyeokgukYongsinFor({
    required String dayMaster,
    required String dayMasterElement,
    required String monthJi,
  }) {
    final god = TenGodsService.godForJiJi(dayMaster, monthJi);
    if (god == null) return null;
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const generatedBy = {
      '木': '水', '火': '木', '土': '火', '金': '土', '水': '金',
    };
    const overcomes = {
      '木': '土', '火': '金', '土': '水', '金': '木', '水': '火',
    };
    const overcomeBy = {
      '木': '金', '火': '水', '土': '木', '金': '火', '水': '土',
    };
    switch (god) {
      case TenGod.jeonggwan:
      case TenGod.pyeongwan:
        // 관성격 → 인성 보좌 (일간을 생하는 오행).
        return generatedBy[dayMasterElement];
      case TenGod.jeongin:
      case TenGod.pyeonin:
        // 인성격 → 관성 보좌 (일간을 극하는 오행).
        return overcomeBy[dayMasterElement];
      case TenGod.jeongjae:
      case TenGod.pyeonjae:
        // 재성격 → 식상 보좌 (일간이 생하는 오행).
        return generates[dayMasterElement];
      case TenGod.siksin:
      case TenGod.sanggwan:
        // 식상격 → 재성 보좌 (일간이 극하는 오행).
        return overcomes[dayMasterElement];
      case TenGod.bigyeon:
        // 건록격 → 식상 보좌.
        return generates[dayMasterElement];
      case TenGod.geopjae:
        // 양인격 → 관성 보좌.
        return overcomeBy[dayMasterElement];
    }
  }

  /// 3 종 용신 (억부 / 조후 / 격국) 신뢰도 분석.
  ///
  /// 사용자 노출 라벨:
  /// - 3 종 (또는 정보 있는 종) 모두 동일 → "강한 확신" / "Strong consensus".
  /// - 2 종 동일 → "두 줄기가 함께 보이는 복합 사주" / "Two streams aligned".
  /// - 모두 다름 → "여러 방향이 같이 보이는 사주" / "Three streams woven".
  /// - 정보 1 종 이하 → "한 줄기 기준" / "Single stream".
  ///
  /// 친근 helper (선택):
  /// - 일치 → "세 기준이 같아서 더 또렷한 방향이에요."
  /// - 부분 일치 → "두 기준이 같이 가리켜요."
  /// - 모두 다름 → "기준마다 살짝 달라요. 셋 다 참고하면 좋아요."
  static ({String labelKo, String labelEn, String helperKo, String helperEn, int agreement})
      confidence({
    String? eokbu,
    String? chowhu,
    String? gyeokguk,
  }) {
    final list = <String>[
      if (eokbu != null && eokbu.isNotEmpty) eokbu,
      if (chowhu != null && chowhu.isNotEmpty) chowhu,
      if (gyeokguk != null && gyeokguk.isNotEmpty) gyeokguk,
    ];
    if (list.length <= 1) {
      return (
        labelKo: '한 줄기 기준',
        labelEn: 'Single stream',
        helperKo: '하나의 기준만 잡혀요. 다른 기준은 정보가 부족해요.',
        helperEn: 'Only one stream available. Other streams lack data.',
        agreement: 1,
      );
    }
    // 빈도 계산.
    final counts = <String, int>{};
    for (final e in list) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount == list.length) {
      // 전부 동일.
      return (
        labelKo: '강한 확신',
        labelEn: 'Strong consensus',
        helperKo: '세 기준이 같은 방향을 가리켜요. 또렷한 신호예요.',
        helperEn: 'All three streams agree. A clear signal.',
        agreement: 3,
      );
    } else if (maxCount >= 2) {
      // 2 종 동일.
      return (
        labelKo: '두 줄기가 함께 보이는 복합 사주',
        labelEn: 'Two streams aligned',
        helperKo: '두 기준이 같이 가리켜요. 두 방향을 함께 활용해보세요.',
        helperEn: 'Two streams agree. Use both directions together.',
        agreement: 2,
      );
    } else {
      // 모두 다름.
      return (
        labelKo: '여러 방향이 같이 보이는 사주',
        labelEn: 'Three streams woven',
        helperKo: '기준마다 살짝 달라요. 셋 다 참고하면 좋아요.',
        helperEn: 'Each stream points differently. All three are useful.',
        agreement: 1,
      );
    }
  }

  /// 5행 → 한국어 친근 명사 ("나무 / 불 / 흙 / 쇠 / 물").
  /// 격국용신 / 조후용신 / 억부용신 사용자 노출 라벨 옆 1줄 풀이 wire 용.
  static String elementKo(String el) {
    const m = {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'};
    return m[el] ?? el;
  }
}
