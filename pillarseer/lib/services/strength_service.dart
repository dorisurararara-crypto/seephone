// Pillar Seer — 신왕/신약(身旺·身弱) 판단 서비스.
//
// 명리학에서 일간(日干)의 강약을 판단하는 핵심 도구.
// 일간을 돕는 기운(인성·비겁) vs 일간을 빼앗는 기운(식상·재성·관성) 비교.
//
// 강도 base = 인성 % + 비겁 % (element % 는 이미 지장간 비율 + 월령 ×2.5 가중 반영).
// 강도 보너스 = 일간 통근(通根) — 4 지지 지장간 안에 일간 오행이 본기/중기/여기 있을 때
//              (월지면 ×1.5 추가). 본기 +6 / 중기 +3 / 여기 +1, 합 0-20 으로 clamp.
//
// 결과:
// - 신강(身强): 강도 ≥70 — 일간 매우 강함.
// - 신왕(身旺): 강도 55-69 — 일간 강함.
// - 중화(中和): 강도 45-54 — 균형. 이상적.
// - 신약(身弱): 강도 30-44 — 일간 약함.
// - 신쇠(身衰): 강도 <30 — 일간 매우 약함.

import 'thong_geun_service.dart';

class StrengthService {
  /// 일간 통근 root bonus — 본기 (jang=3) 점수.
  static const double rootCorePts = 6.0;
  /// 일간 통근 root bonus — 중기 (jang=2) 점수.
  static const double rootMiddlePts = 3.0;
  /// 일간 통근 root bonus — 여기 (jang=1) 점수.
  static const double rootTracePts = 1.0;
  /// 월지(月支) 위치 통근 시 추가 배수.
  static const double monthRootMultiplier = 1.5;
  /// 일간 통근 점수 최대 clamp.
  static const int rootBonusMaxClamp = 20;

  /// 강약 라벨 임계값 — score ≥ 임계 → 해당 label.
  /// 신강 ≥70 / 신왕 ≥55 / 중화 ≥45 / 신약 ≥30 / 신쇠 <30.
  static const int thresholdVeryStrong = 70;
  static const int thresholdStrong = 55;
  static const int thresholdBalanced = 45;
  static const int thresholdWeak = 30;
  /// 일간 오행 + 4기둥 5행 분포 + 월지 → 신강/신약 판단.
  ///
  /// element 분포 (`wood..water`) 는 이미 지장간 비율 + 월령 가중치(×2.5) 반영된
  /// 값을 전제 (ManseryeokService._calculateElements). 따라서 여기서는 추가 월령
  /// boost 를 곱하지 않고, 대신 [dayMaster] 천간 + 4 지지가 제공되면 **일간 통근**
  /// 점수를 별도 가산.
  ///
  /// [dayMaster] (예: '甲'), [yearJi]/[dayJi]/[hourJi] 가 모두 null 이면 일간 통근
  /// 가산 0 — 기존 호출부와 호환.
  static ({int score, String label, String labelEn}) judge({
    required String dayMasterElement, // e.g. '木'
    required String monthJi, // 월지 ji
    required int wood, // 5행 % 분포 (0~100)
    required int fire,
    required int earth,
    required int metal,
    required int water,
    String? dayMaster, // 일간 천간 (선택) — 통근 정확 계산용
    String? yearJi,
    String? dayJi,
    String? hourJi,
  }) {
    // 1. 일간 + 인성 (生我) — 강한 자기 기운.
    // 생아 (인성): 일간 오행을 만들어주는 오행.
    //   목 ← 수 (水生木) / 화 ← 목 / 토 ← 화 / 금 ← 토 / 수 ← 금
    const inseong = {
      '木': '水', '火': '木', '土': '火', '金': '土', '水': '金',
    };
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

    // 2. 일간 통근 (通根) — 4 지지 지장간 안에 일간 오행이 있을 때 root bonus.
    //    본기 +6 / 중기 +3 / 여기 +1, 월지 위치면 ×1.5. 총합 0-20 clamp.
    if (dayMaster != null) {
      double rootBonus = 0;
      final jis = <(String area, String? ji)>[
        ('year', yearJi),
        ('month', monthJi),
        ('day', dayJi),
        ('hour', hourJi),
      ];
      for (final (area, ji) in jis) {
        if (ji == null) continue;
        final s = ThongGeunService.thongGeunStrength(dayMaster, ji);
        if (s == 0) continue;
        double pts = s == 3
            ? rootCorePts
            : (s == 2 ? rootMiddlePts : rootTracePts);
        if (area == 'month') pts *= monthRootMultiplier;
        rootBonus += pts;
      }
      strong += rootBonus.clamp(0, rootBonusMaxClamp.toDouble()).round();
    }

    final score = strong.clamp(0, 100);

    String label;
    String labelEn;
    if (score >= thresholdVeryStrong) {
      label = '신강';
      labelEn = 'Very Strong';
    } else if (score >= thresholdStrong) {
      label = '신왕';
      labelEn = 'Strong';
    } else if (score >= thresholdBalanced) {
      label = '중화';
      labelEn = 'Balanced';
    } else if (score >= thresholdWeak) {
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
