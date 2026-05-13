// Pillar Seer — 통근(通根)·투간(透干) 서비스.
//
// 명리학 핵심:
// - 통근(通根): 천간이 지지의 본기/중기/여기 안에 자기 오행을 가짐 → 그 천간이 강해짐.
// - 투간(透干): 지지의 천간 (본기/중기/여기) 가 사주 천간에 드러남 → 그 지지 영향력 강.
//
// 지지의 천간 구성 (지장간 支藏干):
//   子 — 癸 (본기만)
//   丑 — 己 본기, 癸 중기, 辛 여기
//   寅 — 甲 본기, 丙 중기, 戊 여기
//   卯 — 乙 (본기만)
//   辰 — 戊 본기, 乙 중기, 癸 여기
//   巳 — 丙 본기, 戊 중기, 庚 여기
//   午 — 丁 본기, 己 중기
//   未 — 己 본기, 丁 중기, 乙 여기
//   申 — 庚 본기, 壬 중기, 戊 여기
//   酉 — 辛 (본기만)
//   戌 — 戊 본기, 辛 중기, 丁 여기
//   亥 — 壬 본기, 甲 중기

class ThongGeunService {
  /// 12지 → 지장간 List (본기, 중기, 여기 순).
  /// 본기는 항상 포함, 중기·여기는 있을 때만.
  static const Map<String, List<String>> jijangGan = {
    '子': ['癸'],
    '丑': ['己', '癸', '辛'],
    '寅': ['甲', '丙', '戊'],
    '卯': ['乙'],
    '辰': ['戊', '乙', '癸'],
    '巳': ['丙', '戊', '庚'],
    '午': ['丁', '己'],
    '未': ['己', '丁', '乙'],
    '申': ['庚', '壬', '戊'],
    '酉': ['辛'],
    '戌': ['戊', '辛', '丁'],
    '亥': ['壬', '甲'],
  };

  /// 12지 → 지장간 비율 (전통 명리학 표준: 본기 0.6 / 중기 0.3 / 여기 0.1).
  /// 정기만 있으면 1.0, 정기+중기 2개면 0.7/0.3.
  /// 각 지지 ratio 합은 정확히 1.0.
  static const Map<String, Map<String, double>> jijangGanRatio = {
    '子': {'癸': 1.0},
    '丑': {'己': 0.6, '癸': 0.3, '辛': 0.1},
    '寅': {'甲': 0.6, '丙': 0.3, '戊': 0.1},
    '卯': {'乙': 1.0},
    '辰': {'戊': 0.6, '乙': 0.3, '癸': 0.1},
    '巳': {'丙': 0.6, '戊': 0.3, '庚': 0.1},
    '午': {'丁': 0.7, '己': 0.3},
    '未': {'己': 0.6, '丁': 0.3, '乙': 0.1},
    '申': {'庚': 0.6, '壬': 0.3, '戊': 0.1},
    '酉': {'辛': 1.0},
    '戌': {'戊': 0.6, '辛': 0.3, '丁': 0.1},
    '亥': {'壬': 0.7, '甲': 0.3},
  };

  /// 천간 → 5행 (public).
  static String ganElement(String gan) => _elementOf(gan);

  /// 천간 → 5행.
  static String _elementOf(String gan) {
    const map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[gan] ?? '';
  }

  /// 천간이 지지에 통근하는지 + 통근 강도 (본기=강, 중기=중, 여기=약).
  /// 반환: 통근 강도 (0 = 없음, 1 = 여기, 2 = 중기, 3 = 본기).
  static int thongGeunStrength(String gan, String ji) {
    final ganEl = _elementOf(gan);
    final inner = jijangGan[ji] ?? const [];
    for (int i = 0; i < inner.length; i++) {
      if (_elementOf(inner[i]) == ganEl) {
        // i=0 본기 → 3, i=1 중기 → 2, i=2 여기 → 1
        return 3 - i;
      }
    }
    return 0;
  }

  /// 천간이 사주 4지지 어딘가에 통근하는지 — 가장 강한 통근 + 지지 위치.
  static ({int strength, String? area, String? ji}) thongGeunInChart({
    required String gan,
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    int best = 0;
    String? bestArea;
    String? bestJi;
    final pairs = <(String, String)>[
      ('year', yearJi),
      ('month', monthJi),
      ('day', dayJi),
      if (hourJi != null) ('hour', hourJi),
    ];
    for (final (area, ji) in pairs) {
      final s = thongGeunStrength(gan, ji);
      if (s > best) {
        best = s;
        bestArea = area;
        bestJi = ji;
      }
    }
    return (strength: best, area: bestArea, ji: bestJi);
  }

  /// 지지의 지장간이 사주 다른 천간에 투출(透出, 透干) 되었는지.
  /// 반환: 투간한 천간 List.
  static List<String> tugaeChart({
    required String ji,
    required List<String> chartGans, // 4기둥 천간 list
  }) {
    final inner = jijangGan[ji] ?? const [];
    final out = <String>[];
    for (final innerGan in inner) {
      if (chartGans.contains(innerGan) && !out.contains(innerGan)) {
        out.add(innerGan);
      }
    }
    return out;
  }

  /// 통근 강도 → 한 줄 의미.
  static String thongGeunLabel(int strength, {bool ko = false}) {
    if (ko) {
      switch (strength) {
        case 3:
          return '본기 통근 — 강함';
        case 2:
          return '중기 통근 — 보통';
        case 1:
          return '여기 통근 — 약함';
      }
      return '통근 없음 — 부유';
    }
    switch (strength) {
      case 3:
        return 'Core rooted — strong';
      case 2:
        return 'Middle rooted — moderate';
      case 1:
        return 'Trace rooted — weak';
    }
    return 'No root — floating';
  }
}
