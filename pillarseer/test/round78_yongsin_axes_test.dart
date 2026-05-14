// Round 78 sprint 5 — 용신 5축 (색·방향·음식·시간대·요일) 행동 처방 가드.
// V2 (운세의신 2차) + H9 (today_deep actions) + H15 hint 동적화 입력.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/today_deep_service.dart';
import 'package:pillarseer/services/yongsin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YongsinService 5축 — Round 78 sprint 5', () {
    test('guideAxesKo / guideAxesEn — 5행 5개 모두 5축 비어있지 않음', () {
      for (final y in ['木', '火', '土', '金', '水']) {
        final ko = YongsinService.guideAxesKo(y);
        expect(ko.color.isNotEmpty, isTrue, reason: '$y color ko');
        expect(ko.direction.isNotEmpty, isTrue);
        expect(ko.food.isNotEmpty, isTrue);
        expect(ko.time.isNotEmpty, isTrue);
        expect(ko.weekday.isNotEmpty, isTrue);
        final en = YongsinService.guideAxesEn(y);
        expect(en.color.isNotEmpty, isTrue);
        expect(en.direction.isNotEmpty, isTrue);
        expect(en.food.isNotEmpty, isTrue);
        expect(en.time.isNotEmpty, isTrue);
        expect(en.weekday.isNotEmpty, isTrue);
      }
    });

    test('guideAxesEn em dash 0 (R77 영문 톤 가드)', () {
      for (final y in ['木', '火', '土', '金', '水']) {
        final en = YongsinService.guideAxesEn(y);
        for (final v in [en.color, en.direction, en.food, en.time, en.weekday]) {
          expect(v.contains('—'), isFalse, reason: 'em dash leak: "$v"');
        }
      }
    });

    test('미지원 yongsin → 빈 record', () {
      final ko = YongsinService.guideAxesKo('?');
      expect(ko.color, '');
      expect(ko.direction, '');
      expect(ko.food, '');
      expect(ko.time, '');
      expect(ko.weekday, '');
    });

    test('oneAxisLineKo / oneAxisLineEn — seed 변경 시 분기', () {
      final seeds = [1, 2, 3, 4, 5];
      final set = <String>{};
      for (final s in seeds) {
        set.add(YongsinService.oneAxisLineKo('木', s));
      }
      // 5 axes seed 분기 → ≥3 종.
      expect(set.length, greaterThanOrEqualTo(3));
    });

    test('today_deep actions 에 ctx 용신 5축 1줄 join (ctx 주입)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final reading = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ctx,
      );
      // actions ko 마지막 entry 가 '오늘 한 가지:' prefix (5축 1줄).
      expect(
          reading.actionsKo.any((a) => a.startsWith('오늘 한 가지:')), isTrue,
          reason: 'actions ko 에 5축 1줄 join');
      expect(
          reading.actionsEn.any((a) => a.startsWith('One small move:')), isTrue,
          reason: 'actions en 에 5축 1줄 join');
    });

    test('ctx null 시 5축 1줄 join 0 (회귀 가드)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final reading = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
      );
      expect(
          reading.actionsKo.any((a) => a.startsWith('오늘 한 가지:')), isFalse);
      expect(
          reading.actionsEn.any((a) => a.startsWith('One small move:')), isFalse);
    });

    test('다른 용신 (사용자 X 木 vs Y 火) → 5축 1줄 phrase 차이', () {
      final lineWood = YongsinService.oneAxisLineKo('木', 100);
      final lineFire = YongsinService.oneAxisLineKo('火', 100);
      expect(lineWood != lineFire, isTrue,
          reason: '용신 木 vs 火 같은 seed → 5축 line 다름');
    });

    test('5축 본문 단정 X / 의료 단정 X (톤 가드)', () {
      const forbiddenKo = ['반드시', '꼭', '치료', '병원', '진단'];
      for (final y in ['木', '火', '土', '金', '水']) {
        final ko = YongsinService.guideAxesKo(y);
        final all = [ko.color, ko.direction, ko.food, ko.time, ko.weekday]
            .join(' ');
        for (final w in forbiddenKo) {
          expect(all.contains(w), isFalse, reason: '$y axes ko 에 금칙 "$w"');
        }
      }
    });
  });
}
