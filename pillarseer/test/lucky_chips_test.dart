// Lucky chips service test — 6 카테고리 + 한국어 본문 sanity.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/lucky_chips_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  group('LuckyChipsService — 6 chip sanity', () {
    test('1995-10-27 15:43 남자: 6 chip 모두 존재', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ziwei = ZiweiService.calculate(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isMale: true,
      );
      final chips = LuckyChipsService.compute(saju, ziwei);
      expect(chips.length, 6);

      final cats = chips.map((c) => c.category).toList();
      expect(cats, ['색', '숫자', '방향', '음식', '사람띠', '물건']);

      for (final c in chips) {
        expect(c.value, isNotEmpty);
        expect(c.icon, isNotEmpty);
        expect(c.reasonKo.length, greaterThan(40),
            reason: '${c.category} reason too short');
        // 직장인 jargon 금지 (감독 통과 점수).
        expect(c.reasonKo, isNot(contains('업무')));
        expect(c.reasonKo, isNot(contains('성과')));
        expect(c.reasonKo, isNot(contains('KPI')));
      }
    });

    test('일관성 — 같은 입력 = 같은 chip', () async {
      final saju = await SajuService().calculateSaju(
        year: 2010, month: 3, day: 5,
        hour: 9, minute: 0,
        isLunar: false, isMale: false,
      );
      final ziwei = ZiweiService.calculate(
        year: 2010, month: 3, day: 5,
        hour: 9, minute: 0,
        isMale: false,
      );
      final a = LuckyChipsService.compute(saju, ziwei);
      final b = LuckyChipsService.compute(saju, ziwei);
      for (var i = 0; i < 6; i++) {
        expect(a[i].value, b[i].value);
        expect(a[i].reasonKo, b[i].reasonKo);
      }
    });

    test('5 페르소나 — chip 값이 5 행에 따라 분기', () async {
      final personas = [
        (1989, 7, 12, 14, 0, true),
        (1995, 10, 27, 15, 43, true),
        (2008, 3, 5, 9, 15, false),
        (2010, 12, 20, 22, 30, true),
        (1976, 5, 18, 6, 0, false),
      ];
      // 각 페르소나의 색 chip 값이 5 색 후보 중 하나여야.
      const colorPool = {'초록색', '빨강색', '황금색', '흰색', '검정색'};
      for (final p in personas) {
        final saju = await SajuService().calculateSaju(
          year: p.$1, month: p.$2, day: p.$3,
          hour: p.$4, minute: p.$5,
          isLunar: false, isMale: p.$6,
        );
        final ziwei = ZiweiService.calculate(
          year: p.$1, month: p.$2, day: p.$3,
          hour: p.$4, minute: p.$5,
          isMale: p.$6,
        );
        final chips = LuckyChipsService.compute(saju, ziwei);
        expect(colorPool, contains(chips[0].value),
            reason: '${p.$1}-${p.$2}-${p.$3} color');
      }
    });
  });
}
