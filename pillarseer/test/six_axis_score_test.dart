// 6각 score service test — 60 일주 × 다양한 자미두수 명반에 대한 sanity.
//
// 보장 항목:
// 1) 점수 0~100 범위
// 2) 일관성 — 같은 입력 → 같은 출력
// 3) 일치(✨) 1 개 이상 (실제 사용자 페르소나 기준)
// 4) 6 축 모두 채워짐

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/six_axis_score_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  group('SixAxisScoreService — 산식 sanity', () {
    test('1995-10-27 15:43 남자: 6 축 모두 0~100 범위', () async {
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
      final s = SixAxisScoreService.compute(saju, ziwei);

      for (final axis in SixAxisScore.axes) {
        final saj = s.sajuScores[axis]!;
        final ziw = s.ziweiScores[axis]!;
        final com = s.combinedScores[axis]!;
        expect(saj, inInclusiveRange(0, 100), reason: '사주 $axis');
        expect(ziw, inInclusiveRange(0, 100), reason: '자미 $axis');
        expect(com, inInclusiveRange(0, 100), reason: '통합 $axis');
      }
      expect(s.crossMatches.length, 6);
    });

    test('일치(✨) — 사용자 페르소나 기준 1 개 이상', () async {
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
      final s = SixAxisScoreService.compute(saju, ziwei);
      expect(s.matchCount, greaterThanOrEqualTo(1));
      expect(s.matchCount, lessThanOrEqualTo(6));
    });

    test('일관성 — 같은 입력 두 번 호출 = 같은 출력', () async {
      final saju = await SajuService().calculateSaju(
        year: 2002, month: 4, day: 15,
        hour: 8, minute: 30,
        isLunar: false, isMale: false,
      );
      final ziwei = ZiweiService.calculate(
        year: 2002, month: 4, day: 15,
        hour: 8, minute: 30,
        isMale: false,
      );
      final s1 = SixAxisScoreService.compute(saju, ziwei);
      final s2 = SixAxisScoreService.compute(saju, ziwei);
      for (final axis in SixAxisScore.axes) {
        expect(s1.sajuScores[axis], s2.sajuScores[axis]);
        expect(s1.ziweiScores[axis], s2.ziweiScores[axis]);
        expect(s1.combinedScores[axis], s2.combinedScores[axis]);
        expect(s1.crossMatches[axis], s2.crossMatches[axis]);
      }
    });

    test('다양한 페르소나 5명 — 모두 0~100 범위 + 일치 0~6', () async {
      final personas = [
        (1989, 7, 12, 14, 0, true),    // 80년대 남
        (1995, 10, 27, 15, 43, true),  // 90년대 K팝팬 남
        (2008, 3, 5, 9, 15, false),    // MZ 중학생 여
        (2010, 12, 20, 22, 30, true),  // MZ 중학생 남
        (1976, 5, 18, 6, 0, false),    // 70년대 여
      ];
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
        final s = SixAxisScoreService.compute(saju, ziwei);
        for (final axis in SixAxisScore.axes) {
          expect(s.combinedScores[axis], inInclusiveRange(0, 100),
              reason: '${p.$1}-${p.$2}-${p.$3} $axis');
        }
        expect(s.matchCount, inInclusiveRange(0, 6));
      }
    });

    test('matchedAxes — 축 라벨 순서 보존', () async {
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
      final s = SixAxisScoreService.compute(saju, ziwei);
      final matched = s.matchedAxes;
      // 순서가 6축 정의 순서 안에서 보존되는지.
      for (var i = 1; i < matched.length; i++) {
        final prev = SixAxisScore.axes.indexOf(matched[i - 1]);
        final curr = SixAxisScore.axes.indexOf(matched[i]);
        expect(curr, greaterThan(prev));
      }
    });
  });
}
