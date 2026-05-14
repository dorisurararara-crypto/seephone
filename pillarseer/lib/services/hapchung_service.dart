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
        ? '합(合)이 강한 사주 — 협력·조화·결합의 흐름이 커요. 단, 합이 많으면 자기 기준을 잃기 쉬워 의식적 분리가 필요해요.'
        : 'Strong "hap" (合) chart — alliance, harmony, and merging. But too many alliances can blur your own identity; conscious separation matters.';
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

  /// 형(刑) — 지지 충돌 관계. 충 보다 더 깊은 갈등.
  /// 三刑: 寅巳申 (무은지형), 丑戌未 (지세지형).
  /// 自刑: 辰辰, 午午, 酉酉, 亥亥.
  /// 子卯刑 (무례지형).
  static const List<Set<String>> _samhyungGroups = [
    {'寅', '巳', '申'}, // 무은지형
    {'丑', '戌', '未'}, // 지세지형
  ];
  static const List<String> _jaHyung = ['辰', '午', '酉', '亥']; // 자형
  static const List<Set<String>> _twoHyung = [
    {'子', '卯'}, // 무례지형
  ];

  /// 사주 4지지에서 형(刑) 활성 검사.
  static List<({String type, List<String> jis})> findHyung({
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    final out = <({String type, List<String> jis})>[];
    final allJi = <String>[yearJi, monthJi, dayJi];
    if (hourJi != null) allJi.add(hourJi);

    // 三刑: 3개 다 있어야 (분리 검사).
    for (final group in _samhyungGroups) {
      final present = allJi.where(group.contains).toSet();
      if (present.length == 3) {
        out.add((type: '三刑', jis: present.toList()));
      }
    }
    // 자형: 같은 지지 2번 이상.
    for (final j in _jaHyung) {
      final count = allJi.where((x) => x == j).length;
      if (count >= 2) {
        out.add((type: '自刑', jis: [j, j]));
      }
    }
    // 子卯刑.
    for (final group in _twoHyung) {
      final present = allJi.where(group.contains).toSet();
      if (present.length == 2) {
        out.add((type: '子卯刑', jis: present.toList()));
      }
    }
    return out;
  }

  /// 파(破) — 6쌍 지지 깨짐.
  static const List<Set<String>> _paPairs = [
    {'子', '酉'}, {'午', '卯'}, {'巳', '申'},
    {'寅', '亥'}, {'辰', '丑'}, {'戌', '未'},
  ];

  static bool isJijiPa(String a, String b) {
    for (final p in _paPairs) {
      if (p.contains(a) && p.contains(b) && a != b) return true;
    }
    return false;
  }

  /// 해(害) — 6쌍 지지 해침.
  static const List<Set<String>> _haePairs = [
    {'子', '未'}, {'丑', '午'}, {'寅', '巳'},
    {'卯', '辰'}, {'申', '亥'}, {'酉', '戌'},
  ];

  static bool isJijiHae(String a, String b) {
    for (final p in _haePairs) {
      if (p.contains(a) && p.contains(b) && a != b) return true;
    }
    return false;
  }

  /// 사주 4지지에서 파·해 활성 검사.
  static ({
    List<({String area1, String area2})> pa,
    List<({String area1, String area2})> hae,
  }) findPaHae({
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    final pairs = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];
    final pa = <({String area1, String area2})>[];
    final hae = <({String area1, String area2})>[];
    for (int i = 0; i < pairs.length; i++) {
      for (int j = i + 1; j < pairs.length; j++) {
        final (a1, j1) = pairs[i];
        final (a2, j2) = pairs[j];
        if (isJijiPa(j1, j2)) {
          pa.add((area1: a1, area2: a2));
        }
        if (isJijiHae(j1, j2)) {
          hae.add((area1: a1, area2: a2));
        }
      }
    }
    return (pa: pa, hae: hae);
  }

  /// 형(刑) 한 줄 의미.
  static String hyungInterpretation({bool ko = false}) {
    return ko
        ? '형(刑) 사주 — 충(沖) 보다 깊은 내부 갈등. 三刑은 권력·승부의 결, 自刑은 자기 충돌, 子卯刑은 예의 갈등. 정리·인내가 답.'
        : 'Hyung (刑) — deeper than chung. 三刑 = power/contest; 自刑 = self-conflict; 子卯刑 = etiquette tension. Patience and refinement help.';
  }

  /// 파/해 한 줄 의미.
  static String paHaeInterpretation({bool ko = false}) {
    return ko
        ? '파(破)·해(害) — 작은 갈등 신호. 파는 깨짐, 해는 해침. 합·충 보다 약하지만 누적되면 영향.'
        : 'Pa (破) / Hae (害) — minor friction. 破 breaks alliance, 害 inflicts harm. Subtler than hap/chung but cumulative.';
  }

  /// 충 결과 한 줄 의미.
  static String chungInterpretation({bool ko = false}) {
    return ko
        ? '충(沖)이 있는 사주 — 갈등·변동·전환의 결. 충은 부서지는 게 아니라 다듬는 과정. 큰 변화의 신호일 수 있어요.'
        : '"Chung" (沖) in chart — friction, motion, transition. Not breaking but sharpening. Often a signal of pending major change.';
  }
}
