// Pillar Seer — 신왕/신약(身旺·身弱) 판단 서비스.
//
// 명리학에서 일간(日干)의 강약을 판단하는 핵심 도구.
// 일간을 돕는 기운(인성·비겁) vs 일간을 빼앗는 기운(식상·재성·관성) 비교.
//
// 강도 = 인성·비겁 합 → 신왕(身旺), 강도 + 식상재성관성 비교.
//
// 월지(月支) 가 일간을 도와주는 오행이면 월령(月令)이 통근(通根) — 강도 ×2.
//
// 결과:
// - 신강(身强): 강도 > 60% — 일간이 매우 강함. 식상·재성·관성 운에 빛남.
// - 신왕(身旺): 강도 55-60% — 일간 강함.
// - 중화(中和): 강도 45-55% — 균형. 이상적.
// - 신약(身弱): 강도 40-45% — 일간 약함.
// - 신쇠(身衰): 강도 < 40% — 일간 매우 약함. 인성·비겁 운에 살림.

class StrengthService {
  /// 일간 오행 + 4기둥 5행 분포 + 월지 → 신강/신약 판단.
  /// 반환: 강도 점수 (0~100) + 라벨.
  static ({int score, String label, String labelEn}) judge({
    required String dayMasterElement, // e.g. '木'
    required String monthJi, // 월지 ji
    required int wood, // 5행 % 분포 (0~100)
    required int fire,
    required int earth,
    required int metal,
    required int water,
  }) {
    // 1. 일간 + 인성 (生我) — 강한 자기 기운.
    // 생아 (인성): 일간 오행을 만들어주는 오행.
    //   목 ← 수 (水生木)
    //   화 ← 목 (木生火)
    //   토 ← 화 (火生土)
    //   금 ← 토 (土生金)
    //   수 ← 금 (金生水)
    const inseong = {
      '木': '水', '火': '木', '土': '火', '金': '土', '水': '金',
    };
    // 비겁: 일간과 같은 오행.
    final dm = dayMasterElement;
    final ins = inseong[dm] ?? '';

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

    int strong = elementValue(dm) + elementValue(ins);
    // 식상·재성·관성 합 = 100 - strong. (현재는 강도만 평가에 사용.)

    // 2. 월지(월령) 통근 — 월지가 일간 또는 인성 오행이면 강도 ×1.5.
    const jiElement = {
      '寅': '木', '卯': '木',
      '巳': '火', '午': '火',
      '辰': '土', '戌': '土', '丑': '土', '未': '土',
      '申': '金', '酉': '金',
      '亥': '水', '子': '水',
    };
    final monthEl = jiElement[monthJi] ?? '';
    if (monthEl == dm || monthEl == ins) {
      strong = (strong * 1.5).round().clamp(0, 100);
    }

    final score = strong.clamp(0, 100);

    String label;
    String labelEn;
    if (score >= 70) {
      label = '신강';
      labelEn = 'Very Strong';
    } else if (score >= 55) {
      label = '신왕';
      labelEn = 'Strong';
    } else if (score >= 45) {
      label = '중화';
      labelEn = 'Balanced';
    } else if (score >= 30) {
      label = '신약';
      labelEn = 'Weak';
    } else {
      label = '신쇠';
      labelEn = 'Very Weak';
    }
    return (score: score, label: label, labelEn: labelEn);
  }

  /// 강약 → 운기 가이드 (한 줄).
  static String guide(String label, {bool ko = false}) {
    if (ko) {
      const koMap = {
        '신강':
            '신강 사주 — 일간 매우 강함. 식상·재성·관성(표현/사업/지위) 운에 가장 빛납니다. 자기 결을 다듬는 방향 권장.',
        '신왕':
            '신왕 사주 — 일간 강함. 일을 끝까지 가져가는 힘이 있어요. 외부 기운을 받아들이는 데 신경.',
        '중화':
            '중화 사주 — 가장 균형 잡힌 결. 어떤 운기든 잘 받아들입니다. 가장 자유로운 사주.',
        '신약':
            '신약 사주 — 일간 약함. 인성·비겁(배움/동료) 운에 살아납니다. 협력과 휴식이 자원.',
        '신쇠':
            '신쇠 사주 — 일간 매우 약함. 자기 페이스 보호가 가장 중요. 큰 도전보다 깊이 있는 한 분야 전문.',
      };
      return koMap[label] ?? '';
    }
    const enMap = {
      '신강':
          'Very strong day master. Shines in expression/business/title (output·wealth·officer luck). Refine your own grain.',
      '신왕':
          'Strong day master — finishing power. Mind absorbing external energy.',
      '중화':
          'Balanced — receives all luck types well. The freest chart.',
      '신약':
          'Weak day master — thrives on resource/peer luck (learning/team). Collaboration and rest are your assets.',
      '신쇠':
          'Very weak day master — protect your pace. Depth in one specialty beats big challenges.',
    };
    return enMap[label] ?? '';
  }
}
