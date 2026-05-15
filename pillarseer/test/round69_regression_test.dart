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

    test('6 axis: matchCount = 5/6 (R80 sprint 4 신살 anchor 추가 후)', () {
      final s = SixAxisScoreService.compute(saju, ziwei);
      expect(s.matchCount, 5);
      expect(s.matchedAxes, ['연애', '일', '돈', '건강', '평판']);
      // R80 sprint 4 — _stableJitter range ±2→±4 + _shinsaAnchor (양인/괴강/
      // 백호/천을/문창) wire 후 lock 갱신. 본인+여친 변별력 확대 mandate.
      // 신묘 일주 (양인 X, 괴강 X, 백호 X, 천을 X, 문창 X) — 신살 anchor 0
      // 이지만 jitter range 확대로 점수 변동.
      expect(s.combinedScores['본성'], 78);
      expect(s.combinedScores['연애'], 78);
      expect(s.combinedScores['일'], 72);
      expect(s.combinedScores['돈'], 74);
      expect(s.combinedScores['건강'], 57);
      expect(s.combinedScores['평판'], 71);
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
