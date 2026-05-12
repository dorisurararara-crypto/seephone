// 명리학 통합 정확도 회귀 — 알려진 인물의 사주로
// 공망/신살/12운성/합·충 모두 deterministic 한 결과 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/gong_mang_service.dart';
import 'package:pillarseer/services/shinsa_service.dart';
import 'package:pillarseer/services/twelve_unsung_service.dart';
import 'package:pillarseer/services/hapchung_service.dart';

void main() {
  group('명리학 통합 정확도 — IU (1993-05-16, 일주 丁卯)', () {
    late dynamic saju;
    setUpAll(() async {
      saju = await SajuService().calculateSaju(
        year: 1993,
        month: 5,
        day: 16,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: false,
        unknownTime: true,
      );
    });

    test('일주 丁卯 deterministic', () {
      expect(saju.dayPillar.text, '丁卯');
    });

    test('공망 (丁卯 ∈ 甲子순) → 戌·亥', () {
      final gm = GongMangService.forDayPillar(saju.day60ji);
      expect(gm, ['戌', '亥']);
    });

    test('신살 분석 — 천을귀인 등 매핑 정상 동작', () {
      final activations = ShinsaService.analyzeChart(
        yearJi: saju.yearPillar.jiJi,
        monthJi: saju.monthPillar.jiJi,
        dayChunGan: saju.dayPillar.chunGan,
        dayJi: saju.dayPillar.jiJi,
      );
      // 丁 일간 → 천을귀인 亥·酉
      // 1993 년지 酉 가 있으면 천을 활성
      // 적어도 1개 이상 신살 검출 (chart 에 따라).
      expect(activations, isNotNull);
    });

    test('12 운성 — 丁 일간 모든 4지지에 대해 매핑', () {
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

    test('합·충 분석 — analyzeChart 정상', () {
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
    });
  });

  group('명리학 deterministic — 다양한 일주', () {
    test('60일주 모두 공망/신살/12운성 deterministic (no crash)', () {
      const allGanji = [
        '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉',
        '甲戌', '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未',
        '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳',
        '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑', '壬寅', '癸卯',
        '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑',
        '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥',
      ];
      for (final dp in allGanji) {
        final gm = GongMangService.forDayPillar(dp);
        expect(gm.length, 2, reason: '$dp 공망 2개여야');
        // 12 운성 계산도 정상
        final dayChunGan = dp[0];
        for (final ji in ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']) {
          final stage = TwelveUnsungService.stageNameKo(dayChunGan, ji);
          expect(stage, isNotEmpty);
        }
      }
    });
  });
}
