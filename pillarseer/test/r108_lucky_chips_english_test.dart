// R108 ① — Lucky Chips 영어 carrier 가드.
// 영어 모드 Today 화면에서 한글 누락(칩 라벨·값·"왜 행운인지" 본문) 일소.
// categoryEn / valueEn / reasonEn 전수 + 한글 leak 0 + 5행 전 분기 커버.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/lucky_chips_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

// 한글 음절·자모 + 한자 — 영어 carrier 에 있으면 leak.
final _krLeak = RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏一-鿿]');

void main() {
  group('R108 ① — Lucky Chips 영어 carrier', () {
    test('1995-10-27 남자: 6 chip 영어 필드 전수 + 한글 leak 0', () async {
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

      final catsEn = chips.map((c) => c.categoryEn).toList();
      expect(catsEn,
          ['Color', 'Number', 'Direction', 'Food', 'People', 'Object']);

      for (final c in chips) {
        expect(c.valueEn, isNotEmpty, reason: '${c.categoryEn} valueEn empty');
        expect(c.reasonEn.length, greaterThan(40),
            reason: '${c.categoryEn} reasonEn too short');
        // 영어 carrier 에 한글·한자 leak 0.
        expect(_krLeak.hasMatch(c.categoryEn), isFalse,
            reason: '${c.categoryEn} categoryEn leaks Korean');
        expect(_krLeak.hasMatch(c.valueEn), isFalse,
            reason: '${c.categoryEn} valueEn leaks Korean: ${c.valueEn}');
        expect(_krLeak.hasMatch(c.reasonEn), isFalse,
            reason: '${c.categoryEn} reasonEn leaks Korean');
        // 직장인 jargon 금지 (한국어 본문과 동일 라인).
        expect(c.reasonEn.toLowerCase(), isNot(contains('kpi')));
      }
    });

    test('일관성 — 같은 입력 = 같은 영어 carrier', () async {
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
        expect(a[i].valueEn, b[i].valueEn);
        expect(a[i].reasonEn, b[i].reasonEn);
      }
    });

    test('5 페르소나 — 영어 carrier 도 5행 분기 + leak 0', () async {
      final personas = [
        (1989, 7, 12, 14, 0, true),
        (1995, 10, 27, 15, 43, true),
        (2008, 3, 5, 9, 15, false),
        (2010, 12, 20, 22, 30, true),
        (1976, 5, 18, 6, 0, false),
      ];
      const colorPoolEn = {'Green', 'Red', 'Gold', 'White', 'Black'};
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
        expect(colorPoolEn, contains(chips[0].valueEn),
            reason: '${p.$1}-${p.$2}-${p.$3} colorEn');
        for (final c in chips) {
          expect(_krLeak.hasMatch(c.reasonEn), isFalse,
              reason: '${p.$1}-${p.$2}-${p.$3} ${c.categoryEn} reasonEn leak');
          expect(_krLeak.hasMatch(c.valueEn), isFalse,
              reason: '${p.$1}-${p.$2}-${p.$3} ${c.categoryEn} valueEn leak');
        }
      }
    });
  });
}
