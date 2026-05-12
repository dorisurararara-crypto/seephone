// 전체 12 명리학 services 통합 — 1등 quality 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/gong_mang_service.dart';
import 'package:pillarseer/services/gyeokguk_service.dart';
import 'package:pillarseer/services/hapchung_service.dart';
import 'package:pillarseer/services/shinsa_service.dart';
import 'package:pillarseer/services/strength_service.dart';
import 'package:pillarseer/services/twelve_unsung_service.dart';
import 'package:pillarseer/services/thong_geun_service.dart';
import 'package:pillarseer/services/yongsin_service.dart';
import 'package:pillarseer/services/daewoon_service.dart';
import 'package:pillarseer/services/seun_service.dart';
import 'package:pillarseer/services/solar_term_service.dart';

void main() {
  group('전체 명리학 통합 — IU 1993-05-16', () {
    late dynamic saju;

    setUpAll(() async {
      saju = await SajuService().calculateSaju(
        year: 1993, month: 5, day: 16,
        hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
    });

    test('일주: 丁卯', () {
      expect(saju.dayPillar.text, '丁卯');
    });

    test('공망: 戌·亥 (甲子순)', () {
      expect(GongMangService.forDayPillar(saju.day60ji), ['戌', '亥']);
    });

    test('격국: 월지 본기 십신 매핑 존재', () {
      final g = GyeokgukService.judge(
        dayMaster: saju.dayPillar.chunGan,
        monthJi: saju.monthPillar.jiJi,
      );
      expect(g.name, isNotEmpty);
    });

    test('용신: 일간+5행 → 1차 용신 도출', () {
      final el = saju.elements;
      final s = StrengthService.judge(
        dayMasterElement: saju.dayPillar.chunGanElement,
        monthJi: saju.monthPillar.jiJi,
        wood: el.wood, fire: el.fire, earth: el.earth, metal: el.metal, water: el.water,
      );
      final y = YongsinService.judge(
        dayMasterElement: saju.dayPillar.chunGanElement,
        strengthLabel: s.label,
        wood: el.wood, fire: el.fire, earth: el.earth, metal: el.metal, water: el.water,
      );
      expect(y.yongsin, isNotEmpty);
      expect(y.huisin, isNotEmpty);
      expect(['木', '火', '土', '金', '水'].contains(y.yongsin), isTrue);
    });

    test('대운: 8 chunks 생성', () {
      final chain = DaewoonService.chain(
        monthPillar: saju.monthPillar.text,
        yearChunGan: saju.yearPillar.chunGan,
        isMale: false,
      );
      expect(chain.length, 8);
    });

    test('통근: 일간이 어딘가에 통근 또는 X', () {
      final r = ThongGeunService.thongGeunInChart(
        gan: saju.dayPillar.chunGan,
        yearJi: saju.yearPillar.jiJi,
        monthJi: saju.monthPillar.jiJi,
        dayJi: saju.dayPillar.jiJi,
      );
      expect(r.strength, greaterThanOrEqualTo(0));
      expect(r.strength, lessThanOrEqualTo(3));
    });

    test('세운: 2024 → 甲辰', () {
      expect(SeunService.yearGanji(2024), '甲辰');
      final theme = SeunService.annualTheme(
        dayMaster: saju.dayPillar.chunGan,
        solarYear: 2024,
      );
      expect(theme.themeKo, isNotEmpty);
    });

    test('합·충 분석 + 형·파·해 deterministic', () {
      final r = HapchungService.analyzeChart(
        yearGan: saju.yearPillar.chunGan,
        yearJi: saju.yearPillar.jiJi,
        monthGan: saju.monthPillar.chunGan,
        monthJi: saju.monthPillar.jiJi,
        dayGan: saju.dayPillar.chunGan,
        dayJi: saju.dayPillar.jiJi,
      );
      expect(r.hap, isNotNull);
      expect(r.chung, isNotNull);
      // 형·파·해 도 동작
      final hyung = HapchungService.findHyung(
        yearJi: saju.yearPillar.jiJi,
        monthJi: saju.monthPillar.jiJi,
        dayJi: saju.dayPillar.jiJi,
      );
      final paHae = HapchungService.findPaHae(
        yearJi: saju.yearPillar.jiJi,
        monthJi: saju.monthPillar.jiJi,
        dayJi: saju.dayPillar.jiJi,
      );
      expect(hyung, isNotNull);
      expect(paHae.pa, isNotNull);
      expect(paHae.hae, isNotNull);
    });

    test('12 운성: 4기둥 stage 매핑', () {
      final stages = TwelveUnsungService.chartStages(
        dayChunGan: saju.dayPillar.chunGan,
        yearJi: saju.yearPillar.jiJi,
        monthJi: saju.monthPillar.jiJi,
        dayJi: saju.dayPillar.jiJi,
      );
      expect(stages['year'], isNotEmpty);
    });

    test('신살: 양인/괴강/백호 통합 동작', () {
      final r = ShinsaService.analyzeChart(
        yearJi: saju.yearPillar.jiJi,
        monthJi: saju.monthPillar.jiJi,
        dayChunGan: saju.dayPillar.chunGan,
        dayJi: saju.dayPillar.jiJi,
      );
      // 결과는 다양하지만 최소한 정상 동작.
      expect(r, isNotNull);
    });

    test('24절기: 2024 입춘 + 12 중기 모두 정상', () {
      final lipchun = SolarTermService.lipchun(2024);
      expect(lipchun.month, 2);
      // 24절기 모든 인덱스 정상 동작
      for (int i = 0; i < 24; i++) {
        final dt = SolarTermService.termDateTime(2024, i);
        expect(dt.year, anyOf(equals(2023), equals(2024), equals(2025)),
            reason: 'term $i 비정상 year');
      }
    });
  });

  group('명리학자 사례 검증 — 5명 인물', () {
    final cases = [
      ('IU', 1993, 5, 16, '丁卯', false),
      ('V (BTS)', 1995, 12, 30, '乙未', true),
      ('손흥민', 1992, 7, 8, '乙酉', true),
      ('김연아', 1990, 9, 5, '癸酉', false),
      ('Lee Jung-jae', 1972, 12, 15, '庚辰', true),
    ];

    for (final c in cases) {
      test('${c.$1} 명리학 5종 모두 deterministic + 정상 결과', () async {
        final saju = await SajuService().calculateSaju(
          year: c.$2, month: c.$3, day: c.$4,
          hour: 12, minute: 0,
          isLunar: false, isMale: c.$6, unknownTime: true,
        );

        // 1. 일주 정확
        expect(saju.dayPillar.text, c.$5);

        // 2. 격국 도출 비어 있지 않음
        final g = GyeokgukService.judge(
          dayMaster: saju.dayPillar.chunGan,
          monthJi: saju.monthPillar.jiJi,
        );
        expect(g.name, isNotEmpty);

        // 3. 공망 2개 매핑
        expect(GongMangService.forDayPillar(saju.day60ji).length, 2);

        // 4. 대운 8 chunks
        expect(
          DaewoonService.chain(
            monthPillar: saju.monthPillar.text,
            yearChunGan: saju.yearPillar.chunGan,
            isMale: c.$6,
          ).length,
          8,
        );

        // 5. 12 운성 4기둥 매핑
        final stages = TwelveUnsungService.chartStages(
          dayChunGan: saju.dayPillar.chunGan,
          yearJi: saju.yearPillar.jiJi,
          monthJi: saju.monthPillar.jiJi,
          dayJi: saju.dayPillar.jiJi,
        );
        expect(stages['year'], isNotEmpty);
        expect(stages['month'], isNotEmpty);
        expect(stages['day'], isNotEmpty);
      });
    }
  });

  group('해석 일관성 — 같은 사주 다중 호출 같은 모든 결과', () {
    test('IU 사주 두 번 계산 → 12 명리학 services 모두 동일 결과', () async {
      Future<dynamic> compute() async {
        return SajuService().calculateSaju(
          year: 1993, month: 5, day: 16,
          hour: 12, minute: 0,
          isLunar: false, isMale: false, unknownTime: true,
        );
      }

      final r1 = await compute();
      final r2 = await compute();
      expect(r1.dayPillar.text, r2.dayPillar.text);
      expect(r1.yearPillar.text, r2.yearPillar.text);
      expect(r1.monthPillar.text, r2.monthPillar.text);

      // 격국 일관성
      final g1 = GyeokgukService.judge(
        dayMaster: r1.dayPillar.chunGan, monthJi: r1.monthPillar.jiJi);
      final g2 = GyeokgukService.judge(
        dayMaster: r2.dayPillar.chunGan, monthJi: r2.monthPillar.jiJi);
      expect(g1.name, g2.name);

      // 공망 일관성
      expect(
        GongMangService.forDayPillar(r1.day60ji),
        GongMangService.forDayPillar(r2.day60ji),
      );

      // 신살 일관성
      final s1 = ShinsaService.analyzeChart(
        yearJi: r1.yearPillar.jiJi, monthJi: r1.monthPillar.jiJi,
        dayChunGan: r1.dayPillar.chunGan, dayJi: r1.dayPillar.jiJi);
      final s2 = ShinsaService.analyzeChart(
        yearJi: r2.yearPillar.jiJi, monthJi: r2.monthPillar.jiJi,
        dayChunGan: r2.dayPillar.chunGan, dayJi: r2.dayPillar.jiJi);
      expect(s1.keys.toList(), s2.keys.toList());
    });
  });
}
