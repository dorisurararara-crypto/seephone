// Pillar Seer — 합·충(合冲) 서비스.
//
// 명리학: 사주 원국 천간/지지 사이의 강한 관계.
// - 천간 5합(天干五合): 짝지간 결합
// - 지지 6합(六合): 짝지간 결합
// - 지지 6충(六沖): 짝지간 충돌
// - 삼합(三合): 3개 지지의 결합
// - 방합(方合): 같은 계절 3지지의 결합

class HapchungService {
  /// 천간 5합 (天干五合) — 음양 천간 짝지 5쌍.
  /// 변화: 甲己→土, 乙庚→金, 丙辛→水, 丁壬→木, 戊癸→火
  static const Map<String, ({String partner, String element})> _cheonganHap = {
    '甲': (partner: '己', element: '土'),
    '己': (partner: '甲', element: '土'),
    '乙': (partner: '庚', element: '金'),
    '庚': (partner: '乙', element: '金'),
    '丙': (partner: '辛', element: '水'),
    '辛': (partner: '丙', element: '水'),
    '丁': (partner: '壬', element: '木'),
    '壬': (partner: '丁', element: '木'),
    '戊': (partner: '癸', element: '火'),
    '癸': (partner: '戊', element: '火'),
  };

  /// 지지 6합 (六合) — 짝지간 결합.
  static const Map<String, String> _jijiHap = {
    '子': '丑',
    '丑': '子',
    '寅': '亥',
    '亥': '寅',
    '卯': '戌',
    '戌': '卯',
    '辰': '酉',
    '酉': '辰',
    '巳': '申',
    '申': '巳',
    '午': '未',
    '未': '午',
  };

  /// 지지 6충 (六沖) — 짝지간 충돌.
  static const Map<String, String> _jijiChung = {
    '子': '午',
    '午': '子',
    '丑': '未',
    '未': '丑',
    '寅': '申',
    '申': '寅',
    '卯': '酉',
    '酉': '卯',
    '辰': '戌',
    '戌': '辰',
    '巳': '亥',
    '亥': '巳',
  };

  /// 천간이 다른 천간과 합인지 검사.
  static bool isCheonganHap(String a, String b) {
    return _cheonganHap[a]?.partner == b;
  }

  /// 천간합 화 오행 반환 (예: 甲己 → 土).
  static String cheonganHapElement(String a, String b) {
    if (_cheonganHap[a]?.partner == b) {
      return _cheonganHap[a]!.element;
    }
    return '';
  }

  /// 지지가 다른 지지와 합인지 검사.
  static bool isJijiHap(String a, String b) {
    return _jijiHap[a] == b;
  }

  /// 지지가 다른 지지와 충인지 검사.
  static bool isJijiChung(String a, String b) {
    return _jijiChung[a] == b;
  }

  /// 사주 4기둥에서 활성화된 합·충 관계 분석.
  /// 결과: {합: [(area1, area2, type)], 충: [(area1, area2)]}.
  static ({
    List<({String area1, String area2, String element})> hap,
    List<({String area1, String area2})> chung,
  }) analyzeChart({
    required String yearGan,
    required String yearJi,
    required String monthGan,
    required String monthJi,
    required String dayGan,
    required String dayJi,
    String? hourGan,
    String? hourJi,
  }) {
    final hap = <({String area1, String area2, String element})>[];
    final chung = <({String area1, String area2})>[];

    final ganPairs = <(String, String)>[
      ('year', yearGan),
      ('month', monthGan),
      ('day', dayGan),
      if (hourGan != null) ('hour', hourGan),
    ];
    final jiPairs = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];

    // 천간 5합 — 모든 조합 검사.
    for (int i = 0; i < ganPairs.length; i++) {
      for (int j = i + 1; j < ganPairs.length; j++) {
        final (a1, g1) = ganPairs[i];
        final (a2, g2) = ganPairs[j];
        if (isCheonganHap(g1, g2)) {
          hap.add(
              (area1: a1, area2: a2, element: cheonganHapElement(g1, g2)));
        }
      }
    }

    // 지지 6합 + 6충 — 모든 조합 검사.
    for (int i = 0; i < jiPairs.length; i++) {
      for (int j = i + 1; j < jiPairs.length; j++) {
        final (a1, j1) = jiPairs[i];
        final (a2, j2) = jiPairs[j];
        if (isJijiHap(j1, j2)) {
          hap.add((area1: a1, area2: a2, element: ''));
        }
        if (isJijiChung(j1, j2)) {
          chung.add((area1: a1, area2: a2));
        }
      }
    }

    return (hap: hap, chung: chung);
  }

  /// 합 결과 한 줄 의미.
  static String hapInterpretation({bool ko = false}) {
    return ko
        ? '합(合)이 강한 사주 — 협력·조화·결합의 결이 큽니다. 단, 합이 많으면 자기 결을 잃기 쉬워 의식적 분리가 필요.'
        : 'Strong "hap" (合) chart — alliance, harmony, and merging. But too many alliances can blur your own grain; conscious separation matters.';
  }

  /// 삼합(三合) — 3개 지지의 강한 결합. 그룹별 오행 화.
  /// 申子辰 → 水, 巳酉丑 → 金, 寅午戌 → 火, 亥卯未 → 木.
  static const Map<String, ({List<String> members, String element})>
      _samhapGroups = {
    'water': (members: ['申', '子', '辰'], element: '水'),
    'metal': (members: ['巳', '酉', '丑'], element: '金'),
    'fire': (members: ['寅', '午', '戌'], element: '火'),
    'wood': (members: ['亥', '卯', '未'], element: '木'),
  };

  /// 방합(方合) — 같은 계절 3개 지지의 결합. 그룹별 오행.
  /// 寅卯辰 → 木(봄방), 巳午未 → 火(여름방), 申酉戌 → 金(가을방), 亥子丑 → 水(겨울방).
  static const Map<String, ({List<String> members, String element})>
      _banghapGroups = {
    'spring': (members: ['寅', '卯', '辰'], element: '木'),
    'summer': (members: ['巳', '午', '未'], element: '火'),
    'autumn': (members: ['申', '酉', '戌'], element: '金'),
    'winter': (members: ['亥', '子', '丑'], element: '水'),
  };

  /// 사주 4지지에 삼합 3개 모두 포함되어 있는지 검사 (완전 삼합).
  /// 또는 2개만 있어도 "반합(半合)" 으로 약한 합. 여기서는 3개 완전합만 검사.
  static List<({String element, List<String> areas})> findSamhap({
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    final out = <({String element, List<String> areas})>[];
    final pairs = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];
    for (final group in _samhapGroups.values) {
      final areas = <String>[];
      for (final (a, j) in pairs) {
        if (group.members.contains(j)) areas.add(a);
      }
      if (areas.length >= 3) {
        out.add((element: group.element, areas: areas));
      }
    }
    return out;
  }

  /// 반합(半合) — 삼합 3지지 중 2개만 있을 때. 약한 합.
  /// 申子辰 의 2개 (예: 申子, 子辰, 申辰) — 水 약합.
  static List<({String element, List<String> areas})> findBanhap({
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    final out = <({String element, List<String> areas})>[];
    final pairs = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];
    for (final group in _samhapGroups.values) {
      final areas = <String>[];
      for (final (a, j) in pairs) {
        if (group.members.contains(j)) areas.add(a);
      }
      // 정확히 2개여야 반합 (3개는 완전 삼합 이미 다른 함수에서 잡힘)
      if (areas.length == 2) {
        out.add((element: group.element, areas: areas));
      }
    }
    return out;
  }

  /// 4지지에 방합 3개 모두 포함 검사.
  static List<({String element, List<String> areas})> findBanghap({
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    final out = <({String element, List<String> areas})>[];
    final pairs = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];
    for (final group in _banghapGroups.values) {
      final areas = <String>[];
      for (final (a, j) in pairs) {
        if (group.members.contains(j)) areas.add(a);
      }
      if (areas.length >= 3) {
        out.add((element: group.element, areas: areas));
      }
    }
    return out;
  }

  /// 충 결과 한 줄 의미.
  static String chungInterpretation({bool ko = false}) {
    return ko
        ? '충(沖)이 있는 사주 — 갈등·변동·전환의 결. 충은 부서지는 게 아니라 다듬는 과정. 큰 변화의 신호일 수 있어요.'
        : '"Chung" (沖) in chart — friction, motion, transition. Not breaking but sharpening. Often a signal of pending major change.';
  }
}
