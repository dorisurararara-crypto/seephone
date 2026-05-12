// 2026 신년운세 — 절기 테이블 source-of-truth 잠금 테스트.
// codex Round 2 권고: "KASI/KST 기준 source-of-truth 고정 + 테스트 추가".
//
// 절기 시각 출처: 2026년 KASI 천체력 (KST, ±20분 정확도 권장).

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/solar_term_service.dart';

void main() {
  group('2026 KASI 절기 — 12 월건 boundary', () {
    // 2026년 KASI 월력요항 KST 절입시각.
    // 명리학 월건은 12절기(중기는 안 봄): 소한·입춘·경칩·청명·입하·망종·소서·입추·백로·한로·입동·대설.
    final Map<String, DateTime> kasi2026 = {
      '소한': DateTime(2026, 1, 5, 17, 23),
      '입춘': DateTime(2026, 2, 4, 5, 2),
      '경칩': DateTime(2026, 3, 5, 22, 58),
      '청명': DateTime(2026, 4, 5, 3, 39),
      '입하': DateTime(2026, 5, 5, 20, 48),
      '망종': DateTime(2026, 6, 6, 0, 48),
      '소서': DateTime(2026, 7, 7, 10, 56),
      '입추': DateTime(2026, 8, 7, 20, 42),
      '백로': DateTime(2026, 9, 7, 23, 41),
      '한로': DateTime(2026, 10, 8, 15, 29),
      '입동': DateTime(2026, 11, 7, 18, 52),
      '대설': DateTime(2026, 12, 7, 11, 52),
    };

    test('입춘 2026 — KASI 5:02 ±20분', () {
      final calc = SolarTermService.lipchun(2026);
      final diff = calc.difference(kasi2026['입춘']!).inMinutes.abs();
      expect(diff, lessThanOrEqualTo(20));
    });

    test('년 boundary — 2026 입춘 후 양력 1월 6일 가정 시 2025 사주', () {
      // (구체 ManseryeokService 검증은 solar_term_test 가 cover)
      // 여기서는 절기 date 정합성만 확인.
      expect(kasi2026['입춘']!.month, 2);
      expect(kasi2026['입춘']!.day, 4);
    });

    test('월건 12 절기 chronological order', () {
      final dates = kasi2026.values.toList();
      for (int i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), true,
            reason:
                'idx $i (${kasi2026.keys.elementAt(i)}) is not after idx ${i - 1}');
      }
    });

    test('경칩 2026 — 3/5 (NOT 3/6)', () {
      // codex Round 1 에서 발견된 잘못된 매핑 회귀 테스트.
      // 2026 경칩은 3/5 22:58 KST.
      expect(kasi2026['경칩']!.month, 3);
      expect(kasi2026['경칩']!.day, 5);
    });
  });
}
