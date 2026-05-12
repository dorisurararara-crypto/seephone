// Pillar Seer — 대운(大運) 서비스.
//
// 대운: 10년 단위 운기 흐름. 사주 분석에서 가장 중요한 timing 도구.
//
// 결정 원리:
// 1. 월주(月柱) 천간/지지를 시작점.
// 2. **양남음녀 (양 천간 + 남자 OR 음 천간 + 여자)**: 60갑자 순행 (월주 + 1, + 2...)
//    **음남양녀**: 역행 (월주 - 1, - 2...)
// 3. 첫 대운 시작 나이: 출생일 ~ 전절(前節) 또는 후절(後節) 까지 일수 ÷ 3
//    (단순화: 모든 사람이 3살부터 첫 대운 시작 — UI 표시용)
// 4. 10년 단위 갑자 cycle.

class DaewoonService {
  static const List<String> _gan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];
  static const List<String> _ji = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  /// 양 천간: 甲丙戊庚壬. 음: 乙丁己辛癸.
  static bool _isYang(String gan) =>
      ['甲', '丙', '戊', '庚', '壬'].contains(gan);

  /// 60갑자 인덱스 (甲子=0, ..., 癸亥=59).
  static int _ganjiIndex(String ganji) {
    if (ganji.length != 2) return -1;
    final g = _gan.indexOf(ganji[0]);
    final j = _ji.indexOf(ganji[1]);
    if (g < 0 || j < 0) return -1;
    for (int i = 0; i < 60; i++) {
      if (i % 10 == g && i % 12 == j) return i;
    }
    return -1;
  }

  /// 인덱스 → 60갑자 텍스트.
  static String _ganjiAt(int idx) {
    final i = ((idx % 60) + 60) % 60;
    return '${_gan[i % 10]}${_ji[i % 12]}';
  }

  /// 8개 대운 chain — [{age, ganji, element}, ...].
  static List<({int age, String ganji, String element})> chain({
    required String monthPillar, // 월주 (예: "乙丑")
    required String yearChunGan, // 년주 천간 (양/음 판단용)
    required bool isMale,
    int startAge = 3, // 첫 대운 시작 나이 (default 3, 정확한 계산은 별도)
  }) {
    final yang = _isYang(yearChunGan);
    final forward = (yang && isMale) || (!yang && !isMale);
    final monthIdx = _ganjiIndex(monthPillar);
    if (monthIdx < 0) return const [];

    const elementOf = {
      '甲': '木', '乙': '木', '丙': '火', '丁': '火',
      '戊': '土', '己': '土', '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };

    final out = <({int age, String ganji, String element})>[];
    for (int k = 1; k <= 8; k++) {
      final idx = forward ? monthIdx + k : monthIdx - k;
      final ganji = _ganjiAt(idx);
      final element = elementOf[ganji[0]] ?? '?';
      final age = startAge + (k - 1) * 10;
      out.add((age: age, ganji: ganji, element: element));
    }
    return out;
  }

  /// 현재 사용자 나이에 해당하는 대운 (None if before first chunk).
  static ({int age, String ganji, String element})? currentChunk({
    required List<({int age, String ganji, String element})> chain,
    required int userAge,
  }) {
    for (int i = chain.length - 1; i >= 0; i--) {
      if (userAge >= chain[i].age) return chain[i];
    }
    return null;
  }

  /// 대운 한 줄 의미 (locale-aware).
  static String description({bool ko = false}) {
    return ko
        ? '대운(大運)은 사주의 10년 단위 운기 흐름. 월주에서 시작하여 양남음녀는 순행, 음남양녀는 역행. 각 chunk 10년이 인생의 한 챕터.'
        : 'Daewoon (大運) — life unfolds in 10-year chunks beginning from the month pillar. Yang-male/Yin-female go forward; Yin-male/Yang-female go backward.';
  }
}
