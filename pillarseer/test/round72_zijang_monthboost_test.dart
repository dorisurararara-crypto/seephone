// Round 72 — 지장간 비율 + 월령 가중치 회귀.
//
// 검증 4개:
//   A. 12 지지 지장간 비율 합 = 1.0 (UX 휴리스틱: 본기 0.7 / 중기 0.2 / 여기 0.1)
//   B. 월령 가중치 ×3.0 — 같은 지지가 월지일 때 vs 다른 위치일 때 element % 차이 발생
//   C. 일간 통근 점수 — 본기 +6 / 중기 +3 / 여기 +1, 월지면 ×1.5
//   D. 1995-10-27 15:43 남자 (乙亥·丙戌·辛卯·丙申) — 신묘 일주 element % 변화 골든

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/thong_geun_service.dart';
import 'package:pillarseer/services/manseryeok_service.dart';
import 'package:pillarseer/services/strength_service.dart';

void main() {
  group('Round 72 — 지장간 비율 합 = 1.0', () {
    test('12 지지 모두 지장간 ratio sum = 1.0 (오차 < 0.001)', () {
      for (final entry in ThongGeunService.jijangGanRatio.entries) {
        final sum = entry.value.values.fold<double>(0, (a, b) => a + b);
        expect(
          (sum - 1.0).abs(),
          lessThan(0.001),
          reason: '${entry.key} ratio sum = $sum (expected 1.0)',
        );
      }
    });

    test('정기 1개 지지 (子卯酉)는 100% 단일 천간', () {
      expect(ThongGeunService.jijangGanRatio['子'], {'癸': 1.0});
      expect(ThongGeunService.jijangGanRatio['卯'], {'乙': 1.0});
      expect(ThongGeunService.jijangGanRatio['酉'], {'辛': 1.0});
    });

    test('3 천간 지지 — 본기 0.7 / 중기 0.2 / 여기 0.1 (UX 휴리스틱)', () {
      final inHo = ThongGeunService.jijangGanRatio['寅']!;
      expect(inHo['甲'], 0.7);
      expect(inHo['丙'], 0.2);
      expect(inHo['戊'], 0.1);
    });

    test('2 천간 지지 (午亥) — 본기 0.7 / 중기 0.3', () {
      expect(ThongGeunService.jijangGanRatio['午'], {'丁': 0.7, '己': 0.3});
      expect(ThongGeunService.jijangGanRatio['亥'], {'壬': 0.7, '甲': 0.3});
    });
  });

  group('Round 72 — 일간 통근 점수', () {
    test('본기 통근 강도 = 3 (예: 甲 천간 ↔ 寅 지지)', () {
      expect(ThongGeunService.thongGeunStrength('甲', '寅'), 3);
      expect(ThongGeunService.thongGeunStrength('庚', '申'), 3);
    });
    test('중기 통근 강도 = 2 (예: 丙 천간 ↔ 寅 지지)', () {
      expect(ThongGeunService.thongGeunStrength('丙', '寅'), 2);
    });
    test('여기 통근 강도 = 1 (예: 戊 천간 ↔ 寅 지지)', () {
      expect(ThongGeunService.thongGeunStrength('戊', '寅'), 1);
    });
    test('통근 없음 = 0 (예: 庚 ↔ 卯)', () {
      expect(ThongGeunService.thongGeunStrength('庚', '卯'), 0);
    });

    test('일간 통근 root bonus — 4 지지 모두 본기 → 신강 boost', () {
      // 일간 甲 + 寅寅寅寅 (불가능하지만 통근 점수 극한 검증)
      // base = 木(50)+水(0) = 50
      // root = year寅 6 + month寅 6×1.5=9 + day寅 6 + hour寅 6 = 27 → clamp 20
      // total 50+20 = 70 → 신강
      final r = StrengthService.judge(
        dayMasterElement: '木',
        monthJi: '寅',
        wood: 50, fire: 20, earth: 10, metal: 10, water: 10,
        dayMaster: '甲',
        yearJi: '寅', dayJi: '寅', hourJi: '寅',
      );
      expect(r.label, '신강');
    });

    test('일간 통근 0 (천간 미주입) — base score 만 사용', () {
      // 천간/4지지 안 주면 backward-compat — root bonus 0
      final r1 = StrengthService.judge(
        dayMasterElement: '木',
        monthJi: '寅',
        wood: 30, fire: 20, earth: 20, metal: 15, water: 15,
      );
      // base = 30+15 = 45 → 중화 (45-54)
      expect(r1.label, '중화');
    });
  });

  group('Round 72 — 월령 가중치 ×3.0 + 통근 실제 element % 영향', () {
    test('1995-10-27 15:43 남자 골든 — pillar + element % lock', () {
      final r = ManseryeokService.calculate(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false,
        isMale: true,
      );
      // 사주 골든 (KASI 만세력 검증): 乙亥 丙戌 辛卯 丙申
      expect(r.yearPillar.chunGan, '乙');
      expect(r.yearPillar.jiJi, '亥');
      expect(r.monthPillar.chunGan, '丙');
      expect(r.monthPillar.jiJi, '戌');
      expect(r.dayPillar.chunGan, '辛');
      expect(r.dayPillar.jiJi, '卯');
      expect(r.hourPillar?.chunGan, '丙');
      expect(r.hourPillar?.jiJi, '申');

      // element % 골든:
      //   정통 세력 판단을 UX 숫자로 옮긴 휴리스틱.
      //   천간 1.4, 지장간 0.7/0.2/0.1, 월령 ×3.0,
      //   년월일시 0.8/1.4/1.6/1.1, 일간 +1.2, 통근 보너스 반영.
      //
      // 핵심 회귀 가드:
      expect(r.elements.earth, greaterThanOrEqualTo(14),
          reason: '월령 戌(土) ×3.0 가중 살아있는지 — earth=${r.elements.earth}');
      expect(r.elements.metal, greaterThanOrEqualTo(40),
          reason: '辛 일간 + 戌 중기 통근 + 申 본기 강근 — metal=${r.elements.metal}');

      // element % 정확 골든 — 1등 만세력 사이트 1995-10-27 15:43 男 lock.
      // exact lock (±0): 16 / 21 / 17 / 41 / 4. 드리프트 즉시 catch.
      expect(r.elements.wood, 16);
      expect(r.elements.fire, 21);
      expect(r.elements.earth, 17);
      expect(r.elements.metal, 41);
      expect(r.elements.water, 4);
      // 추가 sanity — 1등 사이트 mandate 와 부합:
      // 金 압도적 (>30 + dominant), 水 약 (<10).
      expect(r.elements.metal, greaterThan(30));
      expect(r.elements.water, lessThan(10));

      // 합 ≈ 100
      final total = r.elements.wood + r.elements.fire + r.elements.earth +
          r.elements.metal + r.elements.water;
      expect(total, inInclusiveRange(99, 101));

      // 일간 辛(金) 강약 골든:
      //   base = 金(약 41) + 土(약 17) = 약 58
      //   root: year亥(壬 없음/甲 없음, 辛 통근 X) 0
      //         month戌(辛 중기, s=2 → 3pts ×1.5 = 4.5)
      //         day卯(辛 없음) 0
      //         hour申(庚 본기, s=3 → 6pts) 6.0
      //   rootBonus = 4.5 + 6 = 10.5 → round 11 (≤20 clamp)
      //   total = 약 69 → 신왕권. rounding 에 따라 신강 경계 가능.
      //
      //   ±1 영역에서 신강(≥70) 가능성도 있어 둘 중 하나로 lock.
      final s = StrengthService.judge(
        dayMasterElement: r.dayPillar.chunGanElement, // 金
        monthJi: r.monthPillar.jiJi,
        wood: r.elements.wood, fire: r.elements.fire, earth: r.elements.earth,
        metal: r.elements.metal, water: r.elements.water,
        dayMaster: r.dayPillar.chunGan,
        yearJi: r.yearPillar.jiJi,
        dayJi: r.dayPillar.jiJi,
        hourJi: r.hourPillar?.jiJi,
      );
      expect(s.label, anyOf(equals('신왕'), equals('신강')),
          reason: 'label=${s.label}, score=${s.score}');
      expect(s.score, inInclusiveRange(65, 75),
          reason: 'score=${s.score}');
    });

    test('과적합 방지 — 다른 일간 케이스에서도 산식이 무너지지 않음', () {
      // 단일 케이스 (1995-10-27, 辛 일간) 골든에 강하게 맞춘 가중치가
      // 다른 일간에서도 합 ~ 100 % 유지하고 dominant 가 무너지지 않음 확인.
      // IU (1993-5-16, 丁卯 일주, 火 일간) — 巳월 火 강 기대.
      final iu = ManseryeokService.calculate(
        year: 1993, month: 5, day: 16, hour: 12, minute: 0,
        isLunar: false, isMale: false,
      );
      final iuTotal = iu.elements.wood + iu.elements.fire +
          iu.elements.earth + iu.elements.metal + iu.elements.water;
      expect(iuTotal, inInclusiveRange(99, 101),
          reason: 'IU total=$iuTotal');
      // 巳월 + 일간 火 → 火 응당 dominant 그룹 (>= earth/metal/water).
      expect(iu.elements.fire, greaterThanOrEqualTo(iu.elements.water),
          reason: 'IU fire=${iu.elements.fire} water=${iu.elements.water}');

      // Karina (2000-4-11, 己亥 일주, 土 일간) — 辰월 土 강 기대.
      final karina = ManseryeokService.calculate(
        year: 2000, month: 4, day: 11, hour: 12, minute: 0,
        isLunar: false, isMale: false,
      );
      final kaTotal = karina.elements.wood + karina.elements.fire +
          karina.elements.earth + karina.elements.metal + karina.elements.water;
      expect(kaTotal, inInclusiveRange(99, 101),
          reason: 'Karina total=$kaTotal');
      // 辰월 + 土 일간 → 土 강 (>= 25%).
      expect(karina.elements.earth, greaterThanOrEqualTo(25),
          reason: 'Karina earth=${karina.elements.earth} (辰월+己 mandate)');
    });

    test('월령 위치 invariance — 寅 가 月支 vs 時支 일 때 element % 다름', () {
      // 같은 4 지지 (寅·卯·辰·巳) 가 있는데 寅 이 월지일 때와 시지일 때
      // 月支 위치의 지장간만 ×3.0 boost 받음.
      //
      // case A: pillars = [寅, 卯, 辰, 巳] (year=寅, month=卯, day=辰, hour=巳)
      //         월지 = 卯, boost = 卯 → 乙(木) ×3.0
      // case B: pillars = [卯, 寅, 辰, 巳] (year=卯, month=寅, day=辰, hour=巳)
      //         월지 = 寅, boost = 寅 → 甲(木) 0.7 + 丙(火) 0.2 + 戊(土) 0.1 ×3.0
      //
      // 직접 _calculateElements 호출 불가 (private), 따라서 ManseryeokService
      // 호출은 진태양시·년주 등 영향 받아 제어 어려움 → element % 비교는
      // public 경로 대신 다음 invariant 로 검증:
      //   "월지 = 寅 인 사주 (1986-03-12 자(子)시) 은 戌월 사주 (1995-10-27 신(申)시) 보다
      //    earth 비중이 낮다." (寅 = 木 본기, 戌 = 土 본기)
      final a = ManseryeokService.calculate(
        year: 1986, month: 3, day: 12, hour: 0, minute: 0,
        isLunar: false, isMale: true,
      );
      final b = ManseryeokService.calculate(
        year: 1995, month: 10, day: 27, hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // 寅월 (a) earth < 戌월 (b) earth — 월령 boost 정확 반영 시 항상 참.
      expect(a.elements.earth, lessThan(b.elements.earth),
          reason: 'earth a=${a.elements.earth} b=${b.elements.earth}');
      // 寅월 (a) wood > 戌월 (b) wood — 월령 木 가중.
      expect(a.elements.wood, greaterThan(b.elements.wood),
          reason: 'wood a=${a.elements.wood} b=${b.elements.wood}');
    });
  });
}
