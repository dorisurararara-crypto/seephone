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

class YongsinService {
  /// 일간 오행 + 강약 + 5행 분포 → 용신 오행 (1차) + 희신 (2차).
  static ({String yongsin, String huisin, String reason}) judge({
    required String dayMasterElement, // 木/火/土/金/水
    required String strengthLabel, // 신강/신왕/중화/신약/신쇠
    required int wood,
    required int fire,
    required int earth,
    required int metal,
    required int water,
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

    return (yongsin: yongsin, huisin: huisin, reason: reason);
  }

  /// 용신 오행 → 실생활 보충 방법 (locale-aware).
  static String compensationGuide(String yongsin, {bool ko = false}) {
    if (ko) {
      const koMap = {
        '木': '나무 기운 보충 — 식물 키우기, 산책, 동쪽 활동, 초록색·청색, 신맛 음식.',
        '火': '불 기운 보충 — 햇빛, 운동, 남쪽 활동, 빨간색·자주색, 쓴맛 음식.',
        '土': '흙 기운 보충 — 산·들·중앙, 노란색·갈색, 단맛 음식, 안정된 루틴.',
        '金': '쇠 기운 보충 — 정리·청소, 서쪽 활동, 흰색·은색, 매운맛 음식, 명료한 결정.',
        '水': '물 기운 보충 — 휴식·수면, 북쪽 활동, 검은색·파란색, 짠맛 음식, 직관 시간.',
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
}
