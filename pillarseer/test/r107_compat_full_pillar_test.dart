// R107 #5 — 궁합이 일주만 보는 문제 fix 의 회귀 가드.
//
// 직전 _analyze 는 두 사람의 일주(일간/일지) 만으로 점수·본문을 짰다. "두 사람
// 전체 사주 궁합" 인데 사실상 일주 궁합이었다. R107 #5 에서 년주·월주(·시주)
// 지지 간 합/충 + 천간 합 을 보조 anchor 로 summary/friction 본문에 한 줄씩
// additive 로 더했다.
//
// 이 테스트가 검증하는 것:
//   ① 변별 — 일주는 동일하고 년주만 다른 두 짝이 summary 본문이 달라진다.
//   ② 변별 — 월주만 다른 두 짝도 본문이 달라진다.
//   ③ 거짓 0 — 년·월·시주 합충이 전혀 없는 짝은 보조 anchor 문장이 안 나온다.
//   ④ 거짓 0 — 한쪽이라도 출생시 모름(hourPillar=null) 이면 시주 충 문장 X.
//   ⑤ 실제 anchor — 년주 충 짝은 friction 에 년주 충 한 줄이 실제로 나온다.
//   ⑥ 회귀 — 5섹션 구조 보존 + 일주 중심 본문 보존.

import 'package:flutter_test/flutter_test.dart';

import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/compatibility_screen.dart' as compat;

// ───────────────── fixtures ─────────────────

/// year/month/day/hour pillar 를 모두 지정할 수 있는 SajuResult builder.
/// 'AB' 형식 (천간+지지). hour 가 null 이면 출생시 모름.
SajuResult _mk({
  required String year,
  required String month,
  required String day,
  String? hour,
}) {
  Pillar p(String s) => Pillar(chunGan: s[0], jiJi: s[1]);
  return SajuResult(
    yearPillar: p(year),
    monthPillar: p(month),
    dayPillar: p(day),
    hourPillar: hour == null ? null : p(hour),
    elements: const FiveElements(
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
    dayMaster: day[0],
    dayMasterName: '_',
    summary: '_',
    categoryReadings: const {},
  );
}

void main() {
  // ── ① 년주만 다른 두 짝 — summary 본문 변별 ──────────────────────────────
  test('① 일주 동일 + 년주만 다름 → summary 본문이 달라진다 (KO/EN)', () {
    final me = _mk(year: '甲子', month: '丙寅', day: '辛卯');
    // partner A — 년주 子(나와 동일, 합/충 아님), partner B — 년주 丑(나의 子와 육합).
    final partnerNoYearHap = _mk(year: '甲子', month: '戊辰', day: '己亥');
    final partnerYearHap = _mk(year: '乙丑', month: '戊辰', day: '己亥');
    for (final useKo in [true, false]) {
      final a = compat.analyzeCompatForTest(
        me: me, partner: partnerNoYearHap, useKo: useKo);
      final b = compat.analyzeCompatForTest(
        me: me, partner: partnerYearHap, useKo: useKo);
      // 일주 짝(辛卯 × 己亥) 은 동일 — 직전 코드라면 summary 가 100% 같았을 것.
      expect(a.summary == b.summary, isFalse,
          reason: '년주만 다른데 summary 가 동일 — 년주 anchor 가 본문에 반영 안 됨 '
              '(useKo=$useKo).');
      // 일주 중심 본문은 보존 — 두 본문 모두 비어있지 않다.
      expect(a.summary.trim().isNotEmpty, isTrue);
      expect(b.summary.trim().isNotEmpty, isTrue);
    }
  });

  // ── ② 월주만 다른 두 짝 — summary 본문 변별 ──────────────────────────────
  test('② 일주·년주 동일 + 월주만 다름 → summary 본문이 달라진다 (KO/EN)', () {
    final me = _mk(year: '甲子', month: '丙寅', day: '辛卯');
    // 월주 寅(나와 동일, 합/충 아님) vs 월주 亥(나의 寅과 육합).
    final partnerNoMonthHap = _mk(year: '甲申', month: '丙寅', day: '己亥');
    final partnerMonthHap = _mk(year: '甲申', month: '丁亥', day: '己亥');
    for (final useKo in [true, false]) {
      final a = compat.analyzeCompatForTest(
        me: me, partner: partnerNoMonthHap, useKo: useKo);
      final b = compat.analyzeCompatForTest(
        me: me, partner: partnerMonthHap, useKo: useKo);
      expect(a.summary == b.summary, isFalse,
          reason: '월주만 다른데 summary 가 동일 — 월주 anchor 미반영 (useKo=$useKo).');
    }
  });

  // ── ③ 년·월·시주 합충 전혀 없음 → 보조 anchor 문장 0 (거짓 합충 X) ──────────
  test('③ 년·월·시주 합충 0 → summary 에 보조 anchor 문장이 안 나온다 (거짓 0)', () {
    // 모든 pillar 가 서로 합/충 아님. me 년 子 / 월 子 / 시 子, partner 년 寅 / 월 卯 / 시 辰.
    // 子와 寅·卯·辰 은 육합도 충도 아니다. 천간도 합 아님.
    final me = _mk(year: '甲子', month: '甲子', day: '辛卯', hour: '甲子');
    final partner = _mk(year: '丙寅', month: '丁卯', day: '己亥', hour: '戊辰');
    for (final useKo in [true, false]) {
      final a = compat.analyzeCompatForTest(me: me, partner: partner, useKo: useKo);
      final body = a.summary;
      if (useKo) {
        expect(body.contains('태어난 해의 기운'), isFalse,
            reason: '년주 합충 없는데 년주 anchor 문장 노출 — 거짓 합충.');
        expect(body.contains('자란 계절의 결'), isFalse,
            reason: '월주 합충 없는데 월주 anchor 문장 노출 — 거짓 합충.');
      } else {
        expect(body.contains('birth-year energies'), isFalse,
            reason: 'year-pillar anchor shown without an actual relation.');
        expect(body.contains('seasons you grew up in'), isFalse,
            reason: 'month-pillar anchor shown without an actual relation.');
      }
    }
  });

  // ── ④ 시주 — 한쪽이라도 출생시 모름 → 시주 충 문장 X (거짓 0) ────────────────
  test('④ partner 출생시 모름(hourPillar=null) → friction 에 시주 충 문장 X', () {
    // me·partner 의 시주가 子·午 충이 되도록 잡되, partner 의 hourPillar 를 null 로.
    final me = _mk(year: '甲子', month: '丙寅', day: '辛卯', hour: '甲子');
    // partner hour 미입력 → 시주 충 판정 자체가 불가 → 'unknown'.
    final partnerNoHour = _mk(year: '甲子', month: '丙寅', day: '己亥', hour: null);
    for (final useKo in [true, false]) {
      final a = compat.analyzeCompatForTest(
        me: me, partner: partnerNoHour, useKo: useKo);
      final friction = a.friction;
      if (useKo) {
        expect(friction.contains('시주 충'), isFalse,
            reason: '출생시 모름인데 시주 충 단정 — 거짓.');
      } else {
        expect(friction.contains('hour-pillar clash'), isFalse,
            reason: 'hour-pillar clash claimed despite unknown birth time.');
      }
    }
  });

  // ── ⑤ 년주 충 짝 → friction 에 년주 충 한 줄이 실제로 나온다 ──────────────────
  test('⑤ 년주가 충(子·午)인 짝 → friction 에 년주 충 anchor 가 실제로 나온다', () {
    // me 년 子, partner 년 午 → 子午 충. 시주 미입력 → 시주 문장은 안 나와야.
    final me = _mk(year: '甲子', month: '丙寅', day: '辛卯');
    final partner = _mk(year: '甲午', month: '丙寅', day: '己亥');
    final ko = compat.analyzeCompatForTest(me: me, partner: partner, useKo: true);
    final en = compat.analyzeCompatForTest(me: me, partner: partner, useKo: false);
    expect(ko.friction.contains('년주 충'), isTrue,
        reason: '실제 년주 충(子午)인데 friction 에 년주 충 anchor 누락.');
    expect(en.friction.contains('year-pillar clash'), isTrue,
        reason: 'actual year-pillar clash missing from friction (EN).');
    // 시주는 두 사람 다 모름 → 시주 충 문장은 안 나온다.
    expect(ko.friction.contains('시주 충'), isFalse);
    expect(en.friction.contains('hour-pillar clash'), isFalse);
  });

  // ── ⑥ 회귀 — 5섹션 구조 보존 + 일주 중심 본문 보존 ─────────────────────────
  test('⑥ 회귀 — 5섹션 모두 채워짐 + 일주 중심 본문 보존', () {
    final me = _mk(year: '乙亥', month: '丙戌', day: '辛卯', hour: '丁酉');
    final partner = _mk(year: '甲子', month: '丙寅', day: '甲子', hour: '甲子');
    for (final useKo in [true, false]) {
      final a = compat.analyzeCompatForTest(me: me, partner: partner, useKo: useKo);
      expect(a.summary.trim().isNotEmpty, isTrue);
      expect(a.attract.trim().isNotEmpty, isTrue);
      expect(a.friction.trim().isNotEmpty, isTrue);
      expect(a.loveMarriage.trim().isNotEmpty, isTrue);
      expect(a.actions.length, greaterThanOrEqualTo(4));
    }
  });

  // ── ⑦ 변별 — 시주만 다른 두 짝 (둘 다 출생시 있음) → 본문 변별 ───────────────
  test('⑦ 두 사람 다 출생시 있고 시주만 충 여부 다름 → friction 본문 변별', () {
    final me = _mk(year: '甲申', month: '丙申', day: '辛卯', hour: '甲子');
    // partner A — 시주 子(나와 동일, 충 아님), B — 시주 午(나의 子와 충).
    final partnerNoHourClash =
        _mk(year: '甲申', month: '丙申', day: '己亥', hour: '甲子');
    final partnerHourClash =
        _mk(year: '甲申', month: '丙申', day: '己亥', hour: '甲午');
    for (final useKo in [true, false]) {
      final a = compat.analyzeCompatForTest(
        me: me, partner: partnerNoHourClash, useKo: useKo);
      final b = compat.analyzeCompatForTest(
        me: me, partner: partnerHourClash, useKo: useKo);
      expect(a.friction == b.friction, isFalse,
          reason: '두 사람 다 출생시 있고 시주 충 여부가 다른데 friction 동일 '
              '(useKo=$useKo).');
      if (useKo) {
        expect(b.friction.contains('시주 충'), isTrue,
            reason: '실제 시주 충(子午)인데 friction 에 시주 충 anchor 누락.');
      } else {
        expect(b.friction.contains('hour-pillar clash'), isTrue,
            reason: 'actual hour-pillar clash missing from friction (EN).');
      }
    }
  });
}
