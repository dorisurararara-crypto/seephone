// Pillar Seer — 12 신살(神煞) 서비스.
//
// 신살: 명리학 부수 요소. 사주 원국에 있는 특정 지지(支地) 가 길/흉 의미 가짐.
//
// 코어 4개:
// - 역마(驛馬): 이동·여행·변화. 12지 중 寅申巳亥 (사맹四孟).
// - 도화(桃花): 매력·인기·이성운. 12지 중 子午卯酉 (사패四敗).
// - 화개(華蓋): 종교·예술·고독. 12지 중 辰戌丑未 (사고四庫).
// - 천을귀인(天乙貴人): 가장 길한 신살. 위기에서 도움.
// - 문창귀인(文昌貴人): 학문·시험·창작.
//
// 역마/도화/화개는 일지(또는 년지) 의 삼합(三合) 기반:
//   申子辰 (水) → 寅(역마) 酉(도화) 辰(화개)
//   巳酉丑 (金) → 亥(역마) 午(도화) 丑(화개)
//   寅午戌 (火) → 申(역마) 卯(도화) 戌(화개)
//   亥卯未 (木) → 巳(역마) 子(도화) 未(화개)
//
// 천을·문창귀인은 일간(천간) 기준.

class ShinsaService {
  /// 일지(또는 년지) 기준 역마 지지.
  static String yokmaFor(String reference) {
    return _samhapMap[_samhapGroupOf(reference)]?['역마'] ?? '';
  }

  /// 일지(또는 년지) 기준 도화 지지.
  static String dohwaFor(String reference) {
    return _samhapMap[_samhapGroupOf(reference)]?['도화'] ?? '';
  }

  /// 일지(또는 년지) 기준 화개 지지.
  static String hwagaeFor(String reference) {
    return _samhapMap[_samhapGroupOf(reference)]?['화개'] ?? '';
  }

  /// 일간(천간) 기준 천을귀인 지지 List (2개).
  static List<String> cheonEulGwiInFor(String dayChunGan) {
    return _cheonEulMap[dayChunGan] ?? const [];
  }

  /// 일간(천간) 기준 문창귀인 지지.
  static String munchangFor(String dayChunGan) {
    return _munchangMap[dayChunGan] ?? '';
  }

  /// 양인(羊刃) — 양 천간의 강한 살. 일간이 양 천간일 때 특정 지지.
  /// 甲→卯, 丙→午, 戊→午, 庚→酉, 壬→子.
  /// 음 천간은 일반적으로 양인이 없거나 약함 (학파 차이).
  static String yangInFor(String dayChunGan) {
    const map = {
      '甲': '卯',
      '丙': '午',
      '戊': '午',
      '庚': '酉',
      '壬': '子',
    };
    return map[dayChunGan] ?? '';
  }

  /// 괴강(魁罡) — 강한 기상의 일주. 庚辰·庚戌·壬辰·壬戌·戊戌·戊辰.
  /// 일주 자체로 판단 (일간+일지 조합).
  static bool isGwaegangDayPillar(String dayPillar) {
    const list = ['庚辰', '庚戌', '壬辰', '壬戌', '戊戌', '戊辰'];
    return list.contains(dayPillar);
  }

  /// 백호대살(白虎大煞) — 강한 살의 일주.
  /// 甲辰·乙未·丙戌·丁丑·戊辰·壬戌·癸丑.
  static bool isBaekhoDayPillar(String dayPillar) {
    const list = ['甲辰', '乙未', '丙戌', '丁丑', '戊辰', '壬戌', '癸丑'];
    return list.contains(dayPillar);
  }

  /// 사주 4기둥에서 어떤 신살이 활성화 되는지 찾기.
  /// 일지(또는 년지) 기준 역마/도화/화개 + 일간 기준 천을·문창.
  /// 결과: 신살 이름 → 활성화 영역 (year/month/day/hour) List.
  static Map<String, List<String>> analyzeChart({
    required String yearJi,
    required String monthJi,
    required String dayChunGan,
    required String dayJi,
    String? hourJi,
  }) {
    final result = <String, List<String>>{};

    // 역마/도화/화개 — 일지 기준 (가장 흔한 학파).
    final yokma = yokmaFor(dayJi);
    final dohwa = dohwaFor(dayJi);
    final hwagae = hwagaeFor(dayJi);
    final cheonEul = cheonEulGwiInFor(dayChunGan);
    final munchang = munchangFor(dayChunGan);
    final yangIn = yangInFor(dayChunGan);

    void check(String name, bool match, String area) {
      if (!match) return;
      result.putIfAbsent(name, () => []).add(area);
    }

    // 4기둥 지지 각각 신살 매칭.
    final pillars = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      // 일지 자신은 reference 이지만, 다른 신살도 가질 수 있음.
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];
    for (final (area, ji) in pillars) {
      check('역마', ji == yokma, area);
      check('도화', ji == dohwa, area);
      check('화개', ji == hwagae, area);
      check('천을귀인', cheonEul.contains(ji), area);
      check('문창귀인', ji == munchang, area);
      check('양인', yangIn.isNotEmpty && ji == yangIn, area);
    }
    // 일주 자체 신살 (괴강, 백호) — 일주 영역에만.
    final dayPillarStr = '$dayChunGan$dayJi';
    if (isGwaegangDayPillar(dayPillarStr)) {
      result.putIfAbsent('괴강', () => []).add('day');
    }
    if (isBaekhoDayPillar(dayPillarStr)) {
      result.putIfAbsent('백호', () => []).add('day');
    }
    return result;
  }

  /// 신살 이름 + 활성화 영역 → 한 줄 의미.
  static String interpretation(String name, List<String> areas,
      {bool ko = false}) {
    if (ko) {
      const koMap = {
        '역마': '🐎 역마(驛馬) — 이동·변화·여행이 인생의 흐름을 만들어요. 한 자리에 머물면 답답함이 커져요.',
        '도화': '🌸 도화(桃花) — 매력과 이성운, 예술 감각. 표현이 곧 자원이 되는 사주.',
        '화개': '🪔 화개(華蓋) — 종교·예술·고독의 깊이. 혼자만의 시간이 가장 큰 자원.',
        '천을귀인': '✨ 천을귀인(天乙貴人) — 가장 길한 신살. 위기 순간 도움 주는 귀인이 있어요.',
        '문창귀인': '📚 문창귀인(文昌貴人) — 학문·시험·창작·기획에서 빛납니다.',
        '양인': '⚔️ 양인(羊刃) — 강한 결단력·승부근성. 잘 쓰면 권위, 못 쓰면 충돌. 양 천간 사주 핵심 살.',
        '괴강': '🌑 괴강(魁罡) — 강한 기상·리더십·고독. 庚辰/庚戌/壬辰/壬戌/戊戌/戊辰 일주. 본인 스타일로 살면 큰 사람.',
        '백호': '🐅 백호(白虎) — 격렬한 흐름. 큰 변화 후 새 사이클. 위기 통과의 자리.',
      };
      final base = koMap[name] ?? '';
      if (areas.isEmpty) return base;
      final areaStr = areas.map(_areaKo).join('·');
      return '$base ($areaStr 영역)';
    }
    const enMap = {
      '역마': '🐎 Yeokma (驛馬) — movement, travel, and change shape your life path.',
      '도화': '🌸 Dohwa (桃花) — magnetism, charm, art. Expression itself is your resource.',
      '화개': '🪔 Hwagae (華蓋) — religion, art, solitude. Alone time is your biggest asset.',
      '천을귀인': '✨ Cheoneul Guin (天乙貴人) — most auspicious. A guardian helps in crises.',
      '문창귀인': '📚 Munchang Guin (文昌貴人) — shines in study, exams, creation.',
      '양인': '⚔️ Yangin (羊刃) — decisive force, competitive edge. Used well: authority. Used poorly: clash.',
      '괴강': '🌑 Gwaegang (魁罡) — strong presence and solitude. Day pillars 庚辰/庚戌/壬辰/壬戌/戊戌/戊辰.',
      '백호': '🐅 Baekho (白虎) — intense forces, crisis-to-renewal. Strong protective edge.',
    };
    final base = enMap[name] ?? '';
    if (areas.isEmpty) return base;
    final areaStr = areas.map(_areaEn).join('/');
    return '$base ($areaStr area)';
  }

  static String _areaKo(String area) {
    switch (area) {
      case 'year':
        return '년주';
      case 'month':
        return '월주';
      case 'day':
        return '일주';
      case 'hour':
        return '시주';
    }
    return area;
  }

  static String _areaEn(String area) =>
      {'year': 'year', 'month': 'month', 'day': 'day', 'hour': 'hour'}[area] ??
      area;

  // ─── private data ────────────────────────────────────────────

  /// 12지 → 삼합 그룹 (0=수, 1=금, 2=화, 3=목).
  static int _samhapGroupOf(String ji) {
    switch (ji) {
      case '申':
      case '子':
      case '辰':
        return 0; // 수 삼합
      case '巳':
      case '酉':
      case '丑':
        return 1; // 금 삼합
      case '寅':
      case '午':
      case '戌':
        return 2; // 화 삼합
      case '亥':
      case '卯':
      case '未':
        return 3; // 목 삼합
    }
    return -1;
  }

  /// 삼합 그룹 → {역마/도화/화개}.
  static const Map<int, Map<String, String>> _samhapMap = {
    0: {'역마': '寅', '도화': '酉', '화개': '辰'}, // 수 삼합 (申子辰)
    1: {'역마': '亥', '도화': '午', '화개': '丑'}, // 금 삼합 (巳酉丑)
    2: {'역마': '申', '도화': '卯', '화개': '戌'}, // 화 삼합 (寅午戌)
    3: {'역마': '巳', '도화': '子', '화개': '未'}, // 목 삼합 (亥卯未)
  };

  /// 일간 → 천을귀인 지지 2개.
  /// 출처: 정통 명리학 三命通會.
  static const Map<String, List<String>> _cheonEulMap = {
    '甲': ['丑', '未'],
    '戊': ['丑', '未'],
    '庚': ['丑', '未'],
    '乙': ['子', '申'],
    '己': ['子', '申'],
    '丙': ['亥', '酉'],
    '丁': ['亥', '酉'],
    '壬': ['卯', '巳'],
    '癸': ['卯', '巳'],
    '辛': ['午', '寅'],
  };

  /// 일간 → 문창귀인 지지.
  static const Map<String, String> _munchangMap = {
    '甲': '巳',
    '乙': '午',
    '丙': '申',
    '戊': '申',
    '丁': '酉',
    '己': '酉',
    '庚': '亥',
    '辛': '子',
    '壬': '寅',
    '癸': '卯',
  };
}
