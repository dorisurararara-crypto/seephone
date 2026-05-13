// 5 일 trend service test.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/five_day_trend_service.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  group('FiveDayTrendService — 5 일 점수 sanity', () {
    test('1995-10-27 15:43 남자: 5 점 모두 0~100 범위', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final today = DateTime(2026, 5, 13);
      final points = FiveDayTrendService.compute(saju, today: today);
      expect(points.length, 5);
      for (final p in points) {
        expect(p.score, inInclusiveRange(0, 100), reason: p.label);
      }
      expect(points[0].label, '그제');
      expect(points[1].label, '어제');
      expect(points[2].label, '오늘');
      expect(points[3].label, '내일');
      expect(points[4].label, '모레');
      expect(points[2].isToday, true);
      // Round 73: labelEn 1:1 대응 검증 — 영문 모드 한글 leak 0건
      expect(points[0].labelEn, '−2D');
      expect(points[1].labelEn, '−1D');
      expect(points[2].labelEn, 'TODAY');
      expect(points[3].labelEn, '+1D');
      expect(points[4].labelEn, '+2D');
      expect(points[2].labelFor(useKo: true), '오늘');
      expect(points[2].labelFor(useKo: false), 'TODAY');
    });

    test('일관성 — 같은 날 두 번 호출 = 같은 5 점', () async {
      final saju = await SajuService().calculateSaju(
        year: 2010, month: 3, day: 5,
        hour: 9, minute: 0,
        isLunar: false, isMale: false,
      );
      final today = DateTime(2026, 5, 13);
      final a = FiveDayTrendService.compute(saju, today: today);
      final b = FiveDayTrendService.compute(saju, today: today);
      for (var i = 0; i < 5; i++) {
        expect(a[i].score, b[i].score);
        expect(a[i].date, b[i].date);
      }
    });

    test('날짜 sequence — -2 ~ +2 정확', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final today = DateTime(2026, 5, 13);
      final points = FiveDayTrendService.compute(saju, today: today);
      expect(points[0].date, DateTime(2026, 5, 11));
      expect(points[1].date, DateTime(2026, 5, 12));
      expect(points[2].date, DateTime(2026, 5, 13));
      expect(points[3].date, DateTime(2026, 5, 14));
      expect(points[4].date, DateTime(2026, 5, 15));
    });
  });
}
