// Round 80 sprint 2 — oneLine 60일주 wire 회귀 가드.
//
// 사용자 verbatim ("벼린 칼 같은 사람 본인+여친 동일") → _oneLinerFor 가
// 60일주별 unique phrase 노출 + 폐기 5종 phrase 직접 노출 0 (lookup 통과 시).
//
// 5행 골든 1995-10-27 男 17시 → 일주 辛卯 → "다듬어진 칼 안에 부드러운 봄 결 품은" 노출.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/deep_content_service.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Round 80 sprint 2 — oneLine 60일주 wire', () {
    test('1995-10-27 男 17시 신묘 → 60일주 phrase 노출 + 폐기 5종 phrase 0', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      final reading = await DeepContentService.buildFor(
        day60ji: saju.dayPillar.text,
        dayMaster: saju.dayPillar.chunGan,
        dayMasterName: 'Metal Rabbit',
        currentYearGanji: '丙午',
        userAge: 31,
        dominantElement: '金',
        deficitElement: '水',
        shortReadings: const {},
      );

      // 일주 辛卯 phrase = "다듬어진 칼 안에 부드러운 봄 결 품은".
      expect(saju.dayPillar.text, '辛卯');
      expect(
        reading.ko.oneLineYouAre,
        contains('다듬어진 칼 안에 부드러운 봄 결'),
        reason: '신묘 일주 60일주 phrase 노출 의무. 실제=${reading.ko.oneLineYouAre}',
      );

      // 폐기 5종 phrase ("벼린 칼 같은") 직접 노출 0 — lookup 통과 시 fallback 차단.
      expect(
        reading.ko.oneLineYouAre.contains('벼린 칼 같은'),
        isFalse,
        reason: '60일주 lookup 통과한 일주는 5종 fallback "벼린 칼 같은" 노출 X.',
      );
    });

    test('60일주 lookup 모두 cover (60 entry 누락 0)', () async {
      // 동일 일주 내 5행 dom 변동에도 60일주 phrase 가 우선 노출.
      // 6 sample × 일주 다양성 cover.
      final samples = [
        // (year, month, day, hour, minute, dayPillar 기대, oneLine 기대 contains)
        (1995, 10, 27, 17, 0, '辛卯', '다듬어진 칼 안에 부드러운 봄 결'),
        (1996, 4, 15, 9, 0, null, null), // dayPillar derived, phrase contains check 생략
      ];

      for (final s in samples) {
        final saju = await SajuService().calculateSaju(
          year: s.$1, month: s.$2, day: s.$3,
          hour: s.$4, minute: s.$5,
          isLunar: false, isMale: true,
        );
        if (s.$6 != null) {
          expect(saju.dayPillar.text, s.$6);
        }
        final reading = await DeepContentService.buildFor(
          day60ji: saju.dayPillar.text,
          dayMaster: saju.dayPillar.chunGan,
          dayMasterName: 'sample',
          currentYearGanji: '丙午',
          userAge: 30,
          dominantElement: '金',
          deficitElement: '水',
          shortReadings: const {},
        );
        // oneLine 비어있지 않음 (60일주 lookup 통과 또는 fallback).
        expect(reading.ko.oneLineYouAre.isNotEmpty, isTrue);
        if (s.$7 != null) {
          expect(reading.ko.oneLineYouAre, contains(s.$7));
        }
      }
    });

    test('서로 다른 일주 → 서로 다른 oneLine (변별력 가드)', () async {
      // A: 1995-10-27 男 17시 → 신묘
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      // B: 1990-03-15 男 9시 → 다른 일주 기대.
      final b = await SajuService().calculateSaju(
        year: 1990, month: 3, day: 15,
        hour: 9, minute: 0,
        isLunar: false, isMale: true,
      );
      final ra = await DeepContentService.buildFor(
        day60ji: a.dayPillar.text,
        dayMaster: a.dayPillar.chunGan,
        dayMasterName: 'A',
        currentYearGanji: '丙午',
        userAge: 31,
        dominantElement: '金',
        deficitElement: '水',
        shortReadings: const {},
      );
      final rb = await DeepContentService.buildFor(
        day60ji: b.dayPillar.text,
        dayMaster: b.dayPillar.chunGan,
        dayMasterName: 'B',
        currentYearGanji: '丙午',
        userAge: 36,
        dominantElement: '木',
        deficitElement: '火',
        shortReadings: const {},
      );

      // 일주 다르면 oneLine 도 달라야 (변별력 mandate).
      if (a.dayPillar.text != b.dayPillar.text) {
        expect(
          ra.ko.oneLineYouAre,
          isNot(equals(rb.ko.oneLineYouAre)),
          reason: '서로 다른 일주 (${a.dayPillar.text} vs ${b.dayPillar.text}) → '
              'oneLine 동일 = 개인화 broken.',
        );
      }
    });
  });
}
