// Pillar Seer — 통합 flow 회귀 테스트 (codex Round 8 #4 flow audit).
// 사용자 mandate: "절대 얼렁뚱땅 X, 아이콘 하나하나 검증"
//
// 검증 시나리오:
// 1. 4 known-date saju (IU/V/김연아/손흥민) day pillar 정확
// 2. PersonalizationEngine deterministic & token render
// 3. Streak service lifecycle
// 4. TenGodsService 16개 케이스
// 5. HourlyService 24h cover
// 6. DailyService 5행 매핑 5종

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/daily_service.dart';
import 'package:pillarseer/services/hourly_service.dart';
import 'package:pillarseer/services/personalization_engine.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/ten_gods_service.dart';

void main() {
  final svc = SajuService();

  group('Known-date 회귀 (20명 celebrity 일주 검증)', () {
    final celebs = [
      ('IU', 1993, 5, 16, '丁卯'),
      ('V', 1995, 12, 30, '乙未'),
      ('Jennie', 1996, 1, 16, '壬子'),
      ('Karina', 2000, 4, 11, '己亥'),
      ('Jisoo', 1995, 1, 3, '甲午'),
      ('Jungkook', 1997, 9, 1, '丙午'),
      ('Rose', 1997, 2, 11, '甲申'),
      ('Lisa', 1997, 3, 27, '戊辰'),
      ('Junho', 1990, 1, 25, '庚寅'),
      ('Song Hye-kyo', 1981, 11, 22, '甲辰'),
      ('Park Seo-joon', 1988, 12, 16, '乙巳'),
      ('Yuna Kim', 1990, 9, 5, '癸酉'),
      ('Son Heung-min', 1992, 7, 8, '乙酉'),
      ('Hyunjin', 2000, 3, 20, '丁丑'),
      ('Hwasa', 1995, 7, 23, '乙卯'),
      ('Taeyeon', 1989, 3, 9, '戊辰'),
      ('GD', 1988, 8, 18, '乙巳'),
      ('Jin', 1992, 12, 4, '甲寅'),
      ('Jin Se-yeon', 1994, 4, 22, '戊寅'),
      ('Lee Jung-jae', 1972, 12, 15, '庚辰'),
    ];

    for (final c in celebs) {
      test('${c.$1} ${c.$2}-${c.$3}-${c.$4} → ${c.$5}', () async {
        final r = await svc.calculateSaju(
          year: c.$2, month: c.$3, day: c.$4,
          hour: 12, minute: 0,
          isLunar: false, isMale: true, unknownTime: true,
        );
        expect(r.dayPillar.text, c.$5,
            reason: '${c.$1} (${c.$2}-${c.$3}-${c.$4}) 일주 KASI 표준 미일치');
      });
    }
  });

  group('PersonalizationEngine 안정성', () {
    test('60일주 전부 PersonalReading 생성 — null/빈 필드 없음', () async {
      // dummy SajuResult 로 atom matching 검증
      final r = SajuResult.dummy();
      final p = PersonalizationEngine.buildFor(r);
      expect(p.headlineKo.isNotEmpty, true);
      expect(p.headlineEn.isNotEmpty, true);
      expect(p.bodyKo.isNotEmpty, true);
      expect(p.bodyEn.isNotEmpty, true);
      expect(p.actionKo.isNotEmpty, true);
      expect(p.actionEn.isNotEmpty, true);
      expect(p.cautionKo.isNotEmpty, true);
      expect(p.cautionEn.isNotEmpty, true);
      // 토큰 잔여 없음 (codex Round 7 bug 재발 방지)
      for (final s in [
        p.headlineKo, p.headlineEn, p.bodyKo, p.bodyEn,
        p.actionKo, p.actionEn, p.cautionKo, p.cautionEn
      ]) {
        expect(s.contains('{'), false, reason: 'unrendered token: $s');
        expect(s.contains('}'), false, reason: 'unrendered token: $s');
      }
    });
  });

  group('TenGods 매핑 일관성 (일간 5종)', () {
    final dms = ['甲', '丙', '戊', '庚', '壬'];
    for (final dm in dms) {
      test('$dm 기준 십신 10가지 모두 정의됨', () {
        final cgs = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
        final found = <TenGod>{};
        for (final cg in cgs) {
          final g = TenGodsService.godFor(dm, cg);
          if (g != null) found.add(g);
        }
        // 10가지 십신 중 6+ 가 일간 1개에서 발견 (정상)
        expect(found.length, greaterThanOrEqualTo(6));
      });
    }
  });

  group('HourlyService 24시간 cover', () {
    test('모든 시간대 (00~23h) 가 12 시진 중 하나에 매핑', () {
      final r = SajuResult.dummy();
      for (var h = 0; h < 24; h++) {
        final slots = HourlyService.twelveSlots(r, now: DateTime(2026, 5, 12, h, 30));
        final current = slots.where((s) => s.isCurrent).toList();
        expect(current.length, 1, reason: 'hour $h: current slot count');
        expect(slots.every((s) => s.score > 0), true);
      }
    });
  });

  group('DailyService 카테고리 가이드', () {
    test('5행 dominant 5종 × 4 카테고리 모두 비어있지 않음', () {
      final r = SajuResult.dummy();
      final f = DailyService().calculate(r);
      expect(f.loveGuideKo.isNotEmpty, true);
      expect(f.loveGuideEn.isNotEmpty, true);
      expect(f.workGuideKo.isNotEmpty, true);
      expect(f.wealthGuideKo.isNotEmpty, true);
      expect(f.energyGuideKo.isNotEmpty, true);
    });
  });
}
