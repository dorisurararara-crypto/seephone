// Pillar Seer — 공망(空亡) 서비스.
//
// 명리학 공망: 60갑자 사이클에서 10천간(10干)과 12지지(12支)가
// 매칭되지 않는 마지막 2개의 지지. 각 순(旬, 10일 묶음)에 2개의 지지가 공망.
//
// 6 순 × 10 갑자 = 60. 각 순의 처음 갑자가 순두(旬頭).
//
// - 甲子순 (甲子~癸酉): 戌·亥 공망
// - 甲戌순 (甲戌~癸未): 申·酉 공망
// - 甲申순 (甲申~癸巳): 午·未 공망
// - 甲午순 (甲午~癸卯): 辰·巳 공망
// - 甲辰순 (甲辰~癸丑): 寅·卯 공망
// - 甲寅순 (甲寅~癸亥): 子·丑 공망
//
// 일주 기준 공망: 일주 천간/지지로 어느 순에 속하는지 찾아 공망 지지 반환.
// 공망에 해당하는 지지가 사주 원국 (년/월/시) 에 있으면 해당 영역의 "공허·결핍·외로움" 의미.

class GongMangService {
  /// 일주 (예: "甲子") → 공망 지지 2개 (예: ["戌", "亥"]).
  static List<String> forDayPillar(String dayPillar) {
    if (dayPillar.length != 2) return const [];
    final idx = _dayPillarIndex(dayPillar);
    if (idx < 0) return const [];
    final soonIdx = idx ~/ 10; // 0=甲子순, 1=甲戌순, ..., 5=甲寅순
    return _gongMangBySoon[soonIdx];
  }

  /// 사주 4기둥에서 공망에 걸리는 영역 (year/month/hour) 찾기.
  /// 반환: 영역명 List (예: ["year", "month"]).
  /// 일주는 자기 자신이라 공망 대상에서 제외.
  static List<String> affectedAreas({
    required String dayPillar,
    required String yearJi,
    required String monthJi,
    String? hourJi,
  }) {
    final gm = forDayPillar(dayPillar);
    if (gm.isEmpty) return const [];
    final out = <String>[];
    if (gm.contains(yearJi)) out.add('year');
    if (gm.contains(monthJi)) out.add('month');
    if (hourJi != null && gm.contains(hourJi)) out.add('hour');
    return out;
  }

  /// 공망 의미 — locale-aware short description.
  /// [areas] forDayPillar 결과 적용 영역. 영역별 다른 의미.
  static String interpretation(List<String> areas, {bool ko = false}) {
    if (areas.isEmpty) {
      return ko
          ? '원국에 공망 없음 — 4기둥 모두 안정적으로 자리를 채웁니다.'
          : 'No void (空亡) in your chart — all four pillars fill their place.';
    }
    final parts = <String>[];
    for (final area in areas) {
      parts.add(_areaMessage(area, ko));
    }
    return parts.join(' ');
  }

  static String _areaMessage(String area, bool ko) {
    if (ko) {
      switch (area) {
        case 'year':
          return '년주 공망 — 사회·조직·집안 인연에서 "있어야 할 게 비어있는" 느낌이 반복됩니다. 의지하지 말고 스스로 결을 짜는 사주.';
        case 'month':
          return '월주 공망 — 부모·형제·환경 영역에서 결핍이 작동합니다. 이상보다 현실을 직시하는 데서 강해집니다.';
        case 'hour':
          return '시주 공망 — 말년·자녀·내면 영역의 공허감. 그 비움이 내적 깊이로 전환되면 가장 큰 성숙이 옵니다.';
      }
    } else {
      switch (area) {
        case 'year':
          return 'Year-pillar void — recurring "missing piece" in family lineage and social roots. Strongest when self-defined, not inherited.';
        case 'month':
          return 'Month-pillar void — deficit in parental/environmental field. Real circumstances sharpen you more than ideals.';
        case 'hour':
          return 'Hour-pillar void — late-life or inner emptiness. When turned into depth, it becomes the most mature stage.';
      }
    }
    return '';
  }

  // ─── private data ────────────────────────────────────────────

  // 60갑자 인덱스: 甲子=0, 乙丑=1, ..., 癸亥=59.
  static const List<String> _gan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];
  static const List<String> _ji = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  static int _dayPillarIndex(String dp) {
    if (dp.length != 2) return -1;
    final g = _gan.indexOf(dp[0]);
    final j = _ji.indexOf(dp[1]);
    if (g < 0 || j < 0) return -1;
    // 60갑자: i % 10 = g, i % 12 = j 인 i (0~59) 찾기.
    for (int i = 0; i < 60; i++) {
      if (i % 10 == g && i % 12 == j) return i;
    }
    return -1;
  }

  static const List<List<String>> _gongMangBySoon = [
    ['戌', '亥'], // 甲子순 (idx 0~9)
    ['申', '酉'], // 甲戌순 (idx 10~19)
    ['午', '未'], // 甲申순 (idx 20~29)
    ['辰', '巳'], // 甲午순 (idx 30~39)
    ['寅', '卯'], // 甲辰순 (idx 40~49)
    ['子', '丑'], // 甲寅순 (idx 50~59)
  ];
}
