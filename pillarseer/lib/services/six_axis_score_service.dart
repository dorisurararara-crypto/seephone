// Pillar Seer — 6각 Radar 점수 서비스.
//
// 1등 한국 운세 앱이 가진 시그니처 = 6축 radar chart (총운/재물/연애/...).
// 우리 차별점: **사주 점수 ↔ 자미두수 점수** 를 따로 계산 →
// 두 값 차이 ≤ 20 일 때 "교차 일치 ✨" 배지.
//
// 6 축 = 본성 · 연애 · 일 · 돈 · 건강 · 평판.
// (가족 축은 [4] 행운 chip 의 '사람띠'로 흡수, K-POP 페르소나 우선순위 반영.)

import '../models/saju_result.dart';
import 'ziwei_service.dart';

class SixAxisScore {
  /// 6 축 사주 점수 (0~100).
  final Map<String, int> sajuScores;

  /// 6 축 자미두수 점수 (0~100).
  final Map<String, int> ziweiScores;

  /// 6 축 통합 점수 (사주 60% + 자미두수 40% — 사주 일주가 더 견고한 ground).
  final Map<String, int> combinedScores;

  /// 두 score 차이 ≤ 20 → true (✨ 표시 대상).
  final Map<String, bool> crossMatches;

  /// 축 라벨 순서 (radar 시계 12시부터 시계방향) — 한글 (내부 key).
  /// 내부 key 는 호환성을 위해 '본성' 으로 유지 (Map 조회용).
  static const axes = ['본성', '연애', '일', '돈', '건강', '평판'];

  /// 한글 라벨 (UI 노출 — useKo == true). Round 77 Sprint 6 mandate — MZ 중학생 K-POP 팬 단어.
  /// 중심 성향 → 성격 / 일 → 공부 (학생 페르소나) / 건강 → 체력 / 평판 → 인기.
  static const axesKo = ['성격', '연애', '공부', '돈', '체력', '인기'];

  /// 영문 라벨 (UI 노출 — useKo == false). axes 순서와 1:1 대응.
  /// Round 77 Sprint 6 — 'Work' → 'Study' (글로벌 K-팬 학생 페르소나).
  static const axesEn = ['Nature', 'Love', 'Study', 'Money', 'Health', 'Fame'];

  /// useKo flag → 노출용 라벨 list.
  static List<String> axesFor({required bool useKo}) => useKo ? axesKo : axesEn;

  const SixAxisScore({
    required this.sajuScores,
    required this.ziweiScores,
    required this.combinedScores,
    required this.crossMatches,
  });

  /// 일치(✨)한 축 개수 (0~6).
  int get matchCount {
    var n = 0;
    for (final v in crossMatches.values) {
      if (v) n++;
    }
    return n;
  }

  /// 일치한 축 라벨 list (순서 = axes 순, 한글 key).
  List<String> get matchedAxes =>
      axes.where((a) => crossMatches[a] == true).toList(growable: false);

  /// 일치한 축의 영문 라벨 list (순서 = axes 순).
  List<String> get matchedAxesEn {
    final out = <String>[];
    for (var i = 0; i < axes.length; i++) {
      if (crossMatches[axes[i]] == true) out.add(axesEn[i]);
    }
    return out;
  }

  /// useKo flag → 일치한 축 라벨 list.
  List<String> matchedAxesFor({required bool useKo}) {
    if (!useKo) return matchedAxesEn;
    final out = <String>[];
    for (var i = 0; i < axes.length; i++) {
      if (crossMatches[axes[i]] == true) out.add(axesKo[i]);
    }
    return out;
  }

  /// 통합 평균 (사용자에게 보여줄 단일 점수 후보).
  int get combinedAverage {
    if (combinedScores.isEmpty) return 0;
    var sum = 0;
    for (final v in combinedScores.values) {
      sum += v;
    }
    return (sum / combinedScores.length).round();
  }
}

class SixAxisScoreService {
  /// 사주 + 자미두수 → 6각 score.
  ///
  /// [today] 는 향후 일진 가중치 확장용. 현재는 일관성 유지 위해 사주·자미두수만 사용.
  static SixAxisScore compute(
    SajuResult saju,
    ZiweiResult ziwei, {
    DateTime? today,
  }) {
    final saju6 = <String, int>{
      '본성': _sajuNature(saju),
      '연애': _sajuLove(saju),
      '일': _sajuWork(saju),
      '돈': _sajuMoney(saju),
      '건강': _sajuHealth(saju),
      '평판': _sajuFame(saju),
    };
    final ziwei6 = <String, int>{
      '본성': _ziweiNature(ziwei),
      '연애': _ziweiLove(ziwei),
      '일': _ziweiWork(ziwei),
      '돈': _ziweiMoney(ziwei),
      '건강': _ziweiHealth(ziwei),
      '평판': _ziweiFame(ziwei),
    };
    final combined = <String, int>{};
    final matches = <String, bool>{};
    for (final axis in SixAxisScore.axes) {
      final s = saju6[axis]!;
      final z = ziwei6[axis]!;
      combined[axis] = (s * 0.6 + z * 0.4).round().clamp(0, 100);
      matches[axis] = (s - z).abs() <= 20;
    }
    return SixAxisScore(
      sajuScores: saju6,
      ziweiScores: ziwei6,
      combinedScores: combined,
      crossMatches: matches,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 사주 6축 산식 (단순화, 일관성 보장)
  // ─────────────────────────────────────────────────────────

  /// 본성 — 일간 강약 + 5행 균형도.
  /// 균형 잡힌 사주 = 본성 점수 높음.
  static int _sajuNature(SajuResult saju) {
    final el = saju.elements;
    final values = [el.wood, el.fire, el.earth, el.metal, el.water];
    final mean = values.reduce((a, b) => a + b) / 5.0;
    // variance: 작을수록 균형
    var variance = 0.0;
    for (final v in values) {
      variance += (v - mean) * (v - mean);
    }
    final std = (variance / 5).abs();
    // std 0 → 100, std 1000 → 50.
    final balance = (100 - (std / 12)).clamp(40, 100).toInt();
    // 일간 강약 보너스: 일간 5행이 dominant 면 +5, deficit 이면 -5.
    final dayEl = saju.dayPillar.chunGanElement;
    var bonus = 0;
    if (dayEl == el.dominant) bonus = 5;
    if (dayEl == el.deficit) bonus = -5;
    return (balance + bonus).clamp(30, 100);
  }

  /// 연애 — 일지 5행 + 음양 + 합/충 (단순).
  static int _sajuLove(SajuResult saju) {
    // 일지가 도화살(子·午·卯·酉) 이면 +10.
    final dayJi = saju.dayPillar.jiJi;
    final dohwa = {'子', '午', '卯', '酉'}.contains(dayJi);
    // 음간 (乙·丁·己·辛·癸) 이 양간보다 부드러운 연애 톤 → +5.
    final yin = !saju.dayPillar.chunGanYang;
    // base: 일지 5행 vs 일간 5행 상생 관계.
    final dayEl = saju.dayPillar.chunGanElement;
    final jiEl = saju.dayPillar.jiJiElement;
    var base = 60;
    if (dayEl == jiEl) base = 75;
    if (_generates(dayEl, jiEl) || _generates(jiEl, dayEl)) base = 80;
    if (_overcomes(dayEl, jiEl) || _overcomes(jiEl, dayEl)) base = 55;
    var score = base;
    if (dohwa) score += 10;
    if (yin) score += 5;
    // 일주별 변동 (60갑자 1개당 ±3) — 같은 일주는 항상 같은 점수.
    score += _stableJitter(saju.day60ji, 'love') * 3;
    return score.clamp(30, 100);
  }

  /// 일 — 일간 강도 + 천간/지지 5행 매치.
  static int _sajuWork(SajuResult saju) {
    final el = saju.elements;
    final dayEl = saju.dayPillar.chunGanElement;
    final dayElPct = _elPercent(el, dayEl);
    // 일간이 30~50% 면 강함 → 일에 강함, 90: 60: 70 weight.
    int base;
    if (dayElPct >= 25 && dayElPct <= 45) {
      base = 85;
    } else if (dayElPct < 15) {
      base = 50;
    } else {
      base = 70;
    }
    // 양간(甲·丙·戊·庚·壬) +5: 추진력.
    if (saju.dayPillar.chunGanYang) base += 5;
    base += _stableJitter(saju.day60ji, 'work') * 3;
    return base.clamp(30, 100);
  }

  /// 돈 — dominant 5행 + 일지 안정성.
  static int _sajuMoney(SajuResult saju) {
    final el = saju.elements;
    // 土·金 dominant → 안정 자산형 +.
    final dom = el.dominant;
    int base = 65;
    if (dom == '土' || dom == '金') base = 78;
    if (dom == '水') base = 68;
    if (dom == '火') base = 62;
    // 일지가 진/술/축/미(고庫지) → 재고: 돈 모이는 자리.
    final gozi = {'辰', '戌', '丑', '未'}.contains(saju.dayPillar.jiJi);
    if (gozi) base += 8;
    base += _stableJitter(saju.day60ji, 'money') * 3;
    return base.clamp(30, 100);
  }

  /// 건강 — 5행 균형 + deficit 페널티.
  static int _sajuHealth(SajuResult saju) {
    final el = saju.elements;
    final values = [el.wood, el.fire, el.earth, el.metal, el.water];
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final spread = max - min;
    int base;
    if (spread <= 15) {
      base = 88;
    } else if (spread <= 30) {
      base = 72;
    } else if (spread <= 50) {
      base = 58;
    } else {
      base = 48;
    }
    base += _stableJitter(saju.day60ji, 'health') * 2;
    return base.clamp(30, 100);
  }

  /// 평판 — 천간 양/음 + 일주 인기형 (子午卯酉 도화 + 寅申巳亥 역마).
  static int _sajuFame(SajuResult saju) {
    int base = 65;
    final dayJi = saju.dayPillar.jiJi;
    if ({'子', '午', '卯', '酉'}.contains(dayJi)) base += 10; // 도화 인기
    if ({'寅', '申', '巳', '亥'}.contains(dayJi)) base += 6; // 역마 활동
    if (saju.dayPillar.chunGanYang) base += 5;
    base += _stableJitter(saju.day60ji, 'fame') * 3;
    return base.clamp(30, 100);
  }

  // ─────────────────────────────────────────────────────────
  // 자미두수 6축 산식 — 명궁/관련 궁 주성·길성 기반
  // ─────────────────────────────────────────────────────────

  static int _ziweiNature(ZiweiResult ziwei) {
    final ming = ziwei.mingPalace;
    int base = 60;
    // 명궁 주성: 자미·천부 +15 (제왕성), 칠살·파군 +10 (강함), 그 외 +5.
    for (final s in ming.majorStars) {
      if (s.keyEn == 'ziwei' || s.keyEn == 'tianfu') {
        base += 15;
        break;
      }
      if (s.keyEn == 'qisha' || s.keyEn == 'pojun' || s.keyEn == 'tanlang') {
        base += 10;
        break;
      }
      base += 5;
      break;
    }
    if (ming.majorStars.isEmpty) base -= 5; // 무주성궁
    // 6길성 보너스
    base += ming.luckyStars.length * 3;
    base -= ming.badStars.length * 4;
    return base.clamp(30, 100);
  }

  static int _ziweiLove(ZiweiResult ziwei) {
    final buchu = ziwei.gungByName('부처궁');
    int base = 60;
    if (buchu != null) {
      for (final s in buchu.majorStars) {
        if (s.keyEn == 'tianji' ||
            s.keyEn == 'taiyin' ||
            s.keyEn == 'tiantong' ||
            s.keyEn == 'tianfu') {
          base += 12;
          break;
        }
        if (s.keyEn == 'tanlang') {
          base += 8;
          break;
        }
        base += 5;
        break;
      }
      base += buchu.luckyStars.length * 3;
      base -= buchu.badStars.length * 4;
    }
    return base.clamp(30, 100);
  }

  static int _ziweiWork(ZiweiResult ziwei) {
    final guanrok = ziwei.gungByName('관록궁');
    int base = 60;
    if (guanrok != null) {
      for (final s in guanrok.majorStars) {
        if (s.keyEn == 'ziwei' ||
            s.keyEn == 'taiyang' ||
            s.keyEn == 'qisha' ||
            s.keyEn == 'wuqu') {
          base += 14;
          break;
        }
        if (s.keyEn == 'jumen' ||
            s.keyEn == 'tianji' ||
            s.keyEn == 'tianliang') {
          base += 10;
          break;
        }
        base += 5;
        break;
      }
      base += guanrok.luckyStars.length * 3;
      base -= guanrok.badStars.length * 4;
    }
    return base.clamp(30, 100);
  }

  static int _ziweiMoney(ZiweiResult ziwei) {
    final jaebaek = ziwei.gungByName('재백궁');
    int base = 60;
    if (jaebaek != null) {
      for (final s in jaebaek.majorStars) {
        if (s.keyEn == 'wuqu' || s.keyEn == 'tianfu' || s.keyEn == 'taiyang') {
          base += 13;
          break;
        }
        if (s.keyEn == 'taiyin' || s.keyEn == 'tanlang') {
          base += 10;
          break;
        }
        base += 5;
        break;
      }
      base += jaebaek.luckyStars.length * 3;
      base -= jaebaek.badStars.length * 4;
    }
    return base.clamp(30, 100);
  }

  static int _ziweiHealth(ZiweiResult ziwei) {
    final jilek = ziwei.gungByName('질액궁');
    int base = 65;
    if (jilek != null) {
      // 흉성 적을수록 좋음.
      base -= jilek.badStars.length * 6;
      base += jilek.luckyStars.length * 4;
      // 주성 없으면 무탈, 있으면 약간 +.
      if (jilek.majorStars.isNotEmpty) base += 3;
    }
    return base.clamp(30, 100);
  }

  static int _ziweiFame(ZiweiResult ziwei) {
    final ming = ziwei.mingPalace;
    final guanrok = ziwei.gungByName('관록궁');
    int base = 60;
    // 명궁에 태양·자미 → 인기.
    for (final s in ming.majorStars) {
      if (s.keyEn == 'taiyang' || s.keyEn == 'ziwei') {
        base += 12;
        break;
      }
      if (s.keyEn == 'tanlang' || s.keyEn == 'lianzhen') {
        base += 8;
        break;
      }
      base += 4;
      break;
    }
    if (guanrok != null) {
      base += guanrok.luckyStars.length * 2;
    }
    base += ming.luckyStars.length * 3;
    return base.clamp(30, 100);
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  static bool _generates(String a, String b) {
    const map = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    return map[a] == b;
  }

  static bool _overcomes(String a, String b) {
    const map = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
    return map[a] == b;
  }

  static int _elPercent(FiveElements el, String dayEl) {
    final m = {
      '木': el.wood,
      '火': el.fire,
      '土': el.earth,
      '金': el.metal,
      '水': el.water,
    };
    return m[dayEl] ?? 0;
  }

  /// 같은 일주 + 같은 축 라벨 = 항상 같은 값 (-2~+2).
  /// 점수 단조로움 방지용 미세 변동.
  static int _stableJitter(String day60ji, String axisKey) {
    final seed =
        (day60ji.codeUnits.fold<int>(0, (a, b) => a + b) +
            axisKey.codeUnits.fold<int>(0, (a, b) => a + b)) %
        5;
    return seed - 2; // -2 ~ +2
  }
}
