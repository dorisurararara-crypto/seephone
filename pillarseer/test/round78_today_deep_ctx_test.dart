// Round 78 sprint 4 — today_deep_service ctx 주입 후 격국·용신 derive 가드.
//
// 같은 십신·dayEnergy 라도 격국·용신 다르면 본문 phrase 차이 ≥1 보장.
// ctx null 시 R77 기존 형태 그대로 (회귀 가드).

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/today_deep_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TodayDeepService ctx — Round 78 sprint 4', () {
    test('ctx null 시 R77 기존 form 보존 (회귀 가드)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final readingNoCtx = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
      );
      // R77 form — body 에 격국/용신 단어 0.
      expect(readingNoCtx.bodyKo.contains('격'), isFalse);
      expect(readingNoCtx.bodyEn.contains('Stable'), isFalse);
      expect(readingNoCtx.bodyKo.isNotEmpty, isTrue);
    });

    test('ctx 주입 시 격국 anchor + 용신 suffix 본문 추가', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final readingWithCtx = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ctx,
      );
      // body 에 격국 단어 ('격') 또는 yongsin "오늘" prefix 포함.
      expect(
          readingWithCtx.bodyKo.contains('격') ||
              readingWithCtx.bodyKo.contains('오늘'),
          isTrue,
          reason: 'ctx 주입 본문에 격국 anchor 또는 yongsin suffix 포함');
    });

    test('같은 사주에서 ctx 없음 vs ctx 있음 → 본문 차이', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final noCtx = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
      );
      final withCtx = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ctx,
      );
      expect(withCtx.bodyKo.length, greaterThan(noCtx.bodyKo.length));
      expect(withCtx.bodyEn.length, greaterThan(noCtx.bodyEn.length));
    });

    test('두 다른 사주 (같은 천간 일진) → 격국·용신 다르면 body 차이', () async {
      // A: 1995-10-27 男 (辛 일간)
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // B: 1971-09-04 男 (辛 일간 가능성 - 그래도 다른 격국/용신)
      final b = await SajuService().calculateSaju(
        year: 1971, month: 9, day: 4,
        hour: 10, minute: 0,
        isLunar: false, isMale: true,
      );
      final ca = SajuContext.from(a, today: DateTime(2026, 5, 14));
      final cb = SajuContext.from(b, today: DateTime(2026, 5, 14));

      final readingA = TodayDeepService.build(
        userDayStem: a.dayPillar.chunGan,
        userDayBranch: a.dayPillar.jiJi,
        userMonthBranch: a.monthPillar.jiJi,
        userDominantEl: a.elements.dominant,
        userDeficitEl: a.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ca,
      );
      final readingB = TodayDeepService.build(
        userDayStem: b.dayPillar.chunGan,
        userDayBranch: b.dayPillar.jiJi,
        userMonthBranch: b.monthPillar.jiJi,
        userDominantEl: b.elements.dominant,
        userDeficitEl: b.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: cb,
      );
      // 두 사용자 ctx 가 다르면 body 도 다름 (격국/용신 derive 차이).
      if (ca.gyeokgukShort != cb.gyeokgukShort ||
          ca.yongsin != cb.yongsin) {
        expect(readingA.bodyKo != readingB.bodyKo, isTrue,
            reason:
                'A.gyeokguk=${ca.gyeokgukShort}/yongsin=${ca.yongsin} vs B.gyeokguk=${cb.gyeokgukShort}/yongsin=${cb.yongsin}');
      }
    });

    test('restDay 금칙어 — ctx suffix 에 "도전·승부·발표" 0', () async {
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
        todayScore: 15, // restDay
        ctx: ctx,
      );
      const forbidden = ['도전', '승부', '발표', '공식 자리', '승진'];
      for (final w in forbidden) {
        expect(reading.bodyKo.contains(w), isFalse,
            reason: 'restDay body 에 금칙 "$w" leak');
      }
    });
  });
}
