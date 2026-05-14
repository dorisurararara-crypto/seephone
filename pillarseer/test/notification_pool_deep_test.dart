// Round 76 sprint 6 — NotificationPoolService.pickDeep 검증.
// 사용자 사주 + 오늘 일진 → today_event 기반 본문.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/notification_pool_service.dart';

void main() {
  final saju = SajuResult.dummy();
  final date = DateTime(2026, 5, 14);

  group('pickDeep 결정성', () {
    test('같은 입력 100회 → 같은 ko/en 반환', () {
      String? prevKo;
      String? prevEn;
      for (var i = 0; i < 100; i++) {
        final p = NotificationPoolService.pickDeep(
          date: date,
          saju: saju,
          todayPillar: '丙戌',
          todayScore: 60,
        );
        prevKo ??= p.ko;
        prevEn ??= p.en;
        expect(p.ko, prevKo);
        expect(p.en, prevEn);
      }
    });
  });

  group('pickDeep 톤', () {
    test('ko 본문 300자 이내 + 가능성 헷지 + 금지 패턴 0', () {
      // 5 오늘 천간 × 6 오늘 지지 = 30 case.
      const stems = ['甲', '丙', '戊', '庚', '壬'];
      const branches = ['子', '辰', '戌', '寅', '亥', '酉'];
      final hedge = RegExp(
          r'(생기기 쉬워요|흐름이 강해요|가능성이 있어요|쉬워요|흔들릴 수 있어요|쌓이기 쉬워요)');
      final forbid =
          RegExp(r'(반드시|사고가 날|큰돈을 잃|병원|이성과 만납니다)');
      for (final s in stems) {
        for (final b in branches) {
          final p = NotificationPoolService.pickDeep(
            date: date,
            saju: saju,
            todayPillar: '$s$b',
            todayScore: 60,
          );
          expect(p.ko.length, lessThanOrEqualTo(300));
          expect(p.en.length, lessThanOrEqualTo(300));
          expect(hedge.hasMatch(p.ko), isTrue, reason: 'no hedge: ${p.ko}');
          expect(forbid.hasMatch(p.ko), isFalse, reason: 'forbidden: ${p.ko}');
          // EN body는 "Today" 로 시작 (사용자 verbatim 영문 톤).
          expect(p.en.contains('Today'), isTrue);
        }
      }
    });
  });

  group('pickFor (fallback) 호환', () {
    test('사주 없는 경우 — 기존 pickFor 50문구 풀 정상', () {
      final p = NotificationPoolService.pickFor(date, '丙戌');
      expect(p.ko.isNotEmpty, isTrue);
      expect(p.en.isNotEmpty, isTrue);
    });
  });
}
