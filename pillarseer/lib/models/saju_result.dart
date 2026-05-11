// Pillar Seer — 사주 결과 모델.
// 60갑자(六十甲子) 기반 4기둥 8자 + 5행 분포 + 일간(日干) + 풀이.

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

class SajuResult {
  final Pillar yearPillar;
  final Pillar monthPillar;
  final Pillar dayPillar;
  final Pillar? hourPillar;  // 시간 모르면 null
  final FiveElements elements;
  final String dayMaster;     // 일간 (Day Master) — 천간 1자
  final String dayMasterName; // 일간 별칭 ("Earth Tiger", "Wood Dragon" 등)
  final String summary;       // 한 줄 요약
  final Map<String, String> categoryReadings; // {category: text}

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
  });

  /// 4기둥 8자 텍스트 (예: "癸卯 丙辰 戊寅 己未")
  String get pillarsText {
    final parts = [yearPillar.text, monthPillar.text, dayPillar.text];
    if (hourPillar != null) parts.add(hourPillar!.text);
    return parts.join(' ');
  }

  /// 일주 60갑자 (예: "戊寅")
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
