// Round 69 회귀 — 1995-10-27 15:43 남자 페르소나 정확한 값 lock.
// codex audit Round 1 FIX#4: 범위 sanity 만으론 부족, exact value 고정.
//
// 이 값이 깨지면: 산식 변경 의도가 있는지 먼저 확인.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/five_day_trend_service.dart';
import 'package:pillarseer/services/lucky_chips_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/six_axis_score_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  group('Round 69 regression — 1995-10-27 15:43 남자 (신묘 일주)', () {
    late SajuResult saju;
    late ZiweiResult ziwei;
    setUpAll(() async {
      saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      ziwei = ZiweiService.calculate(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isMale: true,
      );
    });

    test('6 axis: matchCount = 4/6 (연애·돈·건강·평판 ✨)', () {
      final s = SixAxisScoreService.compute(saju, ziwei);
      expect(s.matchCount, 4);
      expect(s.matchedAxes, ['연애', '돈', '건강', '평판']);
      // 통합 점수 (사주 60% + 자미 40%) — round 산식 변경 시 같이 갱신.
      expect(s.combinedScores['본성'], 83);
      expect(s.combinedScores['연애'], 71);
      expect(s.combinedScores['일'], 79);
      expect(s.combinedScores['돈'], 80);
      expect(s.combinedScores['건강'], 80);
      expect(s.combinedScores['평판'], 70);
    });

    test('5 일 trend: 56 / 53 / 33 / 36 / 76 (2026-05-13 기준)', () {
      final points = FiveDayTrendService.compute(
        saju,
        today: DateTime(2026, 5, 13),
      );
      expect(points.map((p) => p.score).toList(), [56, 53, 33, 36, 76]);
      expect(points.map((p) => p.label).toList(),
          ['그제', '어제', '오늘', '내일', '모레']);
    });

    test('Lucky chips 6: 색·숫자·방향·음식·사람띠·물건 값 고정', () {
      final chips = LuckyChipsService.compute(saju, ziwei);
      expect(chips.length, 6);
      expect(chips[0].category, '색');
      expect(chips[0].value, '검정색');
      expect(chips[1].category, '숫자');
      expect(chips[1].value, '1');
      expect(chips[2].category, '방향');
      expect(chips[2].value, '북쪽');
      expect(chips[3].category, '음식');
      expect(chips[3].value, '생선 미역국');
      expect(chips[4].category, '사람띠');
      expect(chips[4].value, '돼지띠 또는 최씨');
      expect(chips[5].category, '물건');
      expect(chips[5].value, '물병');
      // 근거 본문 직설 친근 톤 키워드 보장 — 한자 jargon 없음.
      for (final c in chips) {
        expect(c.reasonKo, isNot(contains('일간')));
        expect(c.reasonKo, isNot(contains('일진')));
        expect(c.reasonKo, isNot(contains('극합')));
        expect(c.reasonKo, isNot(contains('식상')));
        expect(c.reasonKo, isNot(contains('정관')));
      }
    });
  });
}
