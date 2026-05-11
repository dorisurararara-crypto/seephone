// Pillar Seer — 사주 결과 모델.
// 60갑자(六十甲子) 기반 4기둥 8자 + 5행 분포 + 일간(日干) + 8섹션 풀이.

class FiveElements {
  final int wood;   // 木 (0~100, %)
  final int fire;   // 火
  final int earth;  // 土
  final int metal;  // 金
  final int water;  // 水

  const FiveElements({
    required this.wood,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
  });

  /// 가장 강한 5행
  String get dominant {
    final m = {'木': wood, '火': fire, '土': earth, '金': metal, '水': water};
    return m.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// 가장 약한 5행 (보충 필요)
  String get deficit {
    final m = {'木': wood, '火': fire, '土': earth, '金': metal, '水': water};
    return m.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }
}

class Pillar {
  final String chunGan;  // 천간 (甲乙丙丁戊己庚辛壬癸)
  final String jiJi;     // 지지 (子丑寅卯辰巳午未申酉戌亥)

  const Pillar({required this.chunGan, required this.jiJi});

  String get text => '$chunGan$jiJi';

  /// 천간의 5행
  String get chunGanElement {
    const map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[chunGan] ?? '?';
  }

  /// 천간의 음양 (true = 양, false = 음)
  bool get chunGanYang {
    const map = {
      '甲': true, '乙': false,
      '丙': true, '丁': false,
      '戊': true, '己': false,
      '庚': true, '辛': false,
      '壬': true, '癸': false,
    };
    return map[chunGan] ?? true;
  }

  /// 지지의 5행
  String get jiJiElement {
    const map = {
      '子': '水', '丑': '土', '寅': '木', '卯': '木',
      '辰': '土', '巳': '火', '午': '火', '未': '土',
      '申': '金', '酉': '金', '戌': '土', '亥': '水',
    };
    return map[jiJi] ?? '?';
  }

  /// 천간 영문 (Yin/Yang + 5행)
  String get chunGanEnglish {
    const map = {
      '甲': 'Yang Wood', '乙': 'Yin Wood',
      '丙': 'Yang Fire', '丁': 'Yin Fire',
      '戊': 'Yang Earth', '己': 'Yin Earth',
      '庚': 'Yang Metal', '辛': 'Yin Metal',
      '壬': 'Yang Water', '癸': 'Yin Water',
    };
    return map[chunGan] ?? '?';
  }

  /// 지지 영문 (12지 동물)
  String get jiJiEnglish {
    const map = {
      '子': 'Rat', '丑': 'Ox', '寅': 'Tiger', '卯': 'Rabbit',
      '辰': 'Dragon', '巳': 'Snake', '午': 'Horse', '未': 'Goat',
      '申': 'Monkey', '酉': 'Rooster', '戌': 'Dog', '亥': 'Pig',
    };
    return map[jiJi] ?? '?';
  }

  /// 일주 영문 이름 (예: Earth Tiger, Wood Dragon)
  String get pairEnglish {
    const elementName = {
      '木': 'Wood', '火': 'Fire', '土': 'Earth', '金': 'Metal', '水': 'Water',
    };
    return '${elementName[chunGanElement] ?? "?"} $jiJiEnglish';
  }
}

/// 십신 (十神) — 일간 기준 다른 천간/지지의 관계
/// 10가지: 比肩/劫財/食神/傷官/偏財/正財/偏官(七殺)/正官/偏印/正印
enum TenGod {
  bigyeon,     // 比肩 — Same element same polarity (peer)
  geopjae,     // 劫財 — Same element opp polarity (rival)
  siksin,      // 食神 — I-generate same polarity (output, joy)
  sanggwan,    // 傷官 — I-generate opp polarity (output, rebellious)
  pyeonjae,    // 偏財 — I-overcome same polarity (windfall wealth)
  jeongjae,    // 正財 — I-overcome opp polarity (stable wealth)
  pyeongwan,   // 偏官 — Overcomes-me same polarity (power, 七殺)
  jeonggwan,   // 正官 — Overcomes-me opp polarity (authority)
  pyeonin,     // 偏印 — Generates-me same polarity (unconventional knowledge)
  jeongin,     // 正印 — Generates-me opp polarity (mother, classical knowledge)
}

extension TenGodNames on TenGod {
  String get en {
    switch (this) {
      case TenGod.bigyeon: return 'Peer (比肩)';
      case TenGod.geopjae: return 'Rival (劫財)';
      case TenGod.siksin: return 'Output (食神)';
      case TenGod.sanggwan: return 'Hurting Output (傷官)';
      case TenGod.pyeonjae: return 'Windfall Wealth (偏財)';
      case TenGod.jeongjae: return 'Stable Wealth (正財)';
      case TenGod.pyeongwan: return 'Authority (偏官)';
      case TenGod.jeonggwan: return 'Officer (正官)';
      case TenGod.pyeonin: return 'Unconventional Resource (偏印)';
      case TenGod.jeongin: return 'Direct Resource (正印)';
    }
  }

  String get ko {
    switch (this) {
      case TenGod.bigyeon: return '비견 (比肩)';
      case TenGod.geopjae: return '겁재 (劫財)';
      case TenGod.siksin: return '식신 (食神)';
      case TenGod.sanggwan: return '상관 (傷官)';
      case TenGod.pyeonjae: return '편재 (偏財)';
      case TenGod.jeongjae: return '정재 (正財)';
      case TenGod.pyeongwan: return '편관 (偏官)';
      case TenGod.jeonggwan: return '정관 (正官)';
      case TenGod.pyeonin: return '편인 (偏印)';
      case TenGod.jeongin: return '정인 (正印)';
    }
  }
}

/// 십신 row — pillar 위치 + 천간/지지 십신 ID
class TenGodRow {
  final String position;   // year / month / day / hour
  final TenGod? chunGanGod;
  final TenGod? jiJiGod;

  const TenGodRow({
    required this.position,
    this.chunGanGod,
    this.jiJiGod,
  });
}

/// 8섹션 풀이 (en / ko 한 언어 set)
class DeepReading {
  final String dayMasterDeep;
  final String career;
  final String wealth;
  final String love;
  final String health;
  final String family;
  final String fame;
  final String luckyColor;
  final int luckyNumber;
  final String luckyDirection;
  final String tenYearLuck;
  final String thisYear;
  // 30-second 3-hit summary (codex PM 권고)
  final String oneLineYouAre;     // "큰 산 같은" — 임팩트 한 줄
  final String personalityHook;   // 성격 한 방
  final String loveHook;          // 연애 한 방
  final String todayHook;         // 오늘/올해 액션 한 방
  final String whyReason;         // 왜 그렇게 풀이되는지 1줄 근거

  const DeepReading({
    required this.dayMasterDeep,
    required this.career,
    required this.wealth,
    required this.love,
    required this.health,
    required this.family,
    required this.fame,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyDirection,
    required this.tenYearLuck,
    required this.thisYear,
    this.oneLineYouAre = '',
    this.personalityHook = '',
    this.loveHook = '',
    this.todayHook = '',
    this.whyReason = '',
  });

  factory DeepReading.fallback({
    required String day60ji,
    required String name,
    required String dayMasterDeep,
    required String love,
    required String wealth,
    required String career,
  }) {
    return DeepReading(
      dayMasterDeep: dayMasterDeep,
      career: career,
      wealth: wealth,
      love: love,
      health: 'Your $day60ji body holds steady energy when five elements flow. '
          'Pay attention to imbalance areas — they whisper before they shout.',
      family: 'Family for $day60ji becomes a soft mirror of self — tend it, '
          'and the chord of belonging keeps your nervous system rooted.',
      fame: 'Public recognition arrives when $name owns the room it was '
          'born to lead. Visibility favors authenticity, not performance.',
      luckyColor: 'Celestial Gold',
      luckyNumber: 7,
      luckyDirection: 'East',
      tenYearLuck: 'Your 10-year window opens richer themes as your '
          'great-luck pillar shifts. Track decade gates rather than '
          'fixating on weeks.',
      thisYear: 'This year places your day master against a fresh ganji. '
          'Read your strongest months and protect your weakest — momentum '
          'belongs to those who notice their own season.',
    );
  }
}

class SajuResult {
  final Pillar yearPillar;
  final Pillar monthPillar;
  final Pillar dayPillar;
  final Pillar? hourPillar;
  final FiveElements elements;
  final String dayMaster;     // 일간 천간
  final String dayMasterName; // 영문 별칭
  final String summary;       // 한 줄 요약
  final Map<String, String> categoryReadings; // legacy short readings
  final DeepReading? deepEn;  // 8섹션 풀이 (영어)
  final DeepReading? deepKo;  // 8섹션 풀이 (한국어)
  final List<TenGodRow> tenGods;
  final int? userAge;         // 만 나이 — 대운 계산용
  final String? currentYearGanji; // 올해 60갑자

  const SajuResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.elements,
    required this.dayMaster,
    required this.dayMasterName,
    required this.summary,
    required this.categoryReadings,
    this.deepEn,
    this.deepKo,
    this.tenGods = const [],
    this.userAge,
    this.currentYearGanji,
  });

  String get pillarsText {
    final parts = [yearPillar.text, monthPillar.text, dayPillar.text];
    if (hourPillar != null) parts.add(hourPillar!.text);
    return parts.join(' ');
  }

  String get day60ji => dayPillar.text;

  factory SajuResult.dummy() {
    return SajuResult(
      yearPillar: const Pillar(chunGan: '癸', jiJi: '卯'),
      monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
      dayPillar: const Pillar(chunGan: '戊', jiJi: '寅'),
      hourPillar: const Pillar(chunGan: '己', jiJi: '未'),
      elements: const FiveElements(wood: 35, fire: 25, earth: 30, metal: 5, water: 5),
      dayMaster: '戊',
      dayMasterName: 'Earth Tiger',
      summary: 'You are a mountain that shelters tigers — patient, ancient, quietly enormous.',
      categoryReadings: const {
        'personality': 'Unshaken as a mountain — patient, deep-rooted, quietly enormous in influence.',
        'love': 'Your love carries the dignity of a spring tiger — warm but proud. Trust broken heals slowly.',
        'money': 'Wealth gathers slowly but firmly. Land, real estate, and long-term assets favor you.',
        'career': 'Natural leadership emerges in established institutions and traditional fields.',
      },
    );
  }
}
