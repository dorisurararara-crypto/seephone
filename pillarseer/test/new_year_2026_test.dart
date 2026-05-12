// 2026 신년운세 — KASI 12절 source-of-truth 잠금 테스트.
//
// codex Round 4 권고: "12개 전체 exact DateTime + name/stem/branch 테이블 잠금".
// 화면(_NewYear2026Screen) 과 이 테스트가 모두 JolCalendar2026 을 참조.
// 1분이라도 어긋나면 즉시 깨지도록 strict equality + ±20분 sanity check 양쪽 모두 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/jol_calendar_2026.dart';
import 'package:pillarseer/services/solar_term_service.dart';

/// 2026 KASI 12절 exact-value source-of-truth — 테스트 골든 테이블.
/// 인덱스 순서 = SolarTermService.jolLongitudes (0=입춘 ... 11=소한).
/// 출처: KASI 월력요항 2026 KST 절입시각.
final List<({
  int jolIndex,
  DateTime dt,
  String monthBranch,
  String monthStem,
  String nameKo,
  String nameEn,
})> _kasiTable = [
  (jolIndex: 0,  dt: DateTime(2026, 2, 4, 5, 2),    monthBranch: '寅', monthStem: '庚', nameKo: '입춘', nameEn: 'Ipchun'),
  (jolIndex: 1,  dt: DateTime(2026, 3, 5, 22, 58),  monthBranch: '卯', monthStem: '辛', nameKo: '경칩', nameEn: 'Gyeongchip'),
  (jolIndex: 2,  dt: DateTime(2026, 4, 5, 3, 39),   monthBranch: '辰', monthStem: '壬', nameKo: '청명', nameEn: 'Cheongmyeong'),
  (jolIndex: 3,  dt: DateTime(2026, 5, 5, 20, 48),  monthBranch: '巳', monthStem: '癸', nameKo: '입하', nameEn: 'Ipha'),
  (jolIndex: 4,  dt: DateTime(2026, 6, 6, 0, 48),   monthBranch: '午', monthStem: '甲', nameKo: '망종', nameEn: 'Mangjong'),
  (jolIndex: 5,  dt: DateTime(2026, 7, 7, 10, 56),  monthBranch: '未', monthStem: '乙', nameKo: '소서', nameEn: 'Soseo'),
  (jolIndex: 6,  dt: DateTime(2026, 8, 7, 20, 42),  monthBranch: '申', monthStem: '丙', nameKo: '입추', nameEn: 'Ipchu'),
  (jolIndex: 7,  dt: DateTime(2026, 9, 7, 23, 41),  monthBranch: '酉', monthStem: '丁', nameKo: '백로', nameEn: 'Baekro'),
  (jolIndex: 8,  dt: DateTime(2026, 10, 8, 15, 29), monthBranch: '戌', monthStem: '戊', nameKo: '한로', nameEn: 'Hanro'),
  (jolIndex: 9,  dt: DateTime(2026, 11, 7, 18, 52), monthBranch: '亥', monthStem: '己', nameKo: '입동', nameEn: 'Ipdong'),
  (jolIndex: 10, dt: DateTime(2026, 12, 7, 11, 52), monthBranch: '子', monthStem: '庚', nameKo: '대설', nameEn: 'Daeseol'),
  (jolIndex: 11, dt: DateTime(2026, 1, 5, 17, 23),  monthBranch: '丑', monthStem: '辛', nameKo: '소한', nameEn: 'Sohan'),
];

void main() {
  group('JolCalendar2026 — 12절 KASI exact-value table', () {
    test('12 entries 존재 + 순서 = SolarTermService.jolLongitudes 인덱스', () {
      expect(JolCalendar2026.all.length, 12);
      expect(JolCalendar2026.displayOrder.length, 12);
      for (int i = 0; i < 12; i++) {
        expect(JolCalendar2026.byJolIndex(i).jolIndex, i,
            reason: 'jolIndex $i identity broken');
      }
    });

    // 12개 모두 exact DateTime + name + branch + stem 잠금.
    // 1분이라도 어긋나면 깨지도록 strict equality.
    for (final row in _kasiTable) {
      test(
          'jolIndex ${row.jolIndex} (${row.nameKo}) — exact DateTime + 월지 ${row.monthBranch} + 월간 ${row.monthStem}',
          () {
        final slot = JolCalendar2026.byJolIndex(row.jolIndex);
        expect(slot.dateTime, row.dt,
            reason: '${slot.nameKo}: KASI ${row.dt.toIso8601String()} '
                'vs slot ${slot.dateTime.toIso8601String()}');
        expect(slot.monthBranch, row.monthBranch,
            reason: '${slot.nameKo} 月支 mismatch');
        expect(slot.monthStem, row.monthStem,
            reason: '${slot.nameKo} 月干 mismatch');
        expect(slot.nameKo, row.nameKo);
        expect(slot.nameEn, row.nameEn);
      });
    }

    test('display order = 양력 1월 소한 → 12월 대설', () {
      final ord = JolCalendar2026.displayOrder;
      expect(ord.first.nameKo, '소한');
      expect(ord.first.monthBranch, '丑');
      expect(ord.last.nameKo, '대설');
      expect(ord.last.monthBranch, '子');
      // chronological
      for (int i = 1; i < ord.length; i++) {
        expect(ord[i].dateTime.isAfter(ord[i - 1].dateTime), true,
            reason:
                'idx $i (${ord[i].nameKo}) is not after idx ${i - 1} (${ord[i - 1].nameKo})');
      }
    });

    test('丙년 五虎遁 표 정확성 (寅 庚 시작)', () {
      // 寅 庚, 卯 辛, 辰 壬, 巳 癸, 午 甲, 未 乙, 申 丙, 酉 丁, 戌 戊, 亥 己, 子 庚, 丑 辛
      const expected = [
        ('寅', '庚'), ('卯', '辛'), ('辰', '壬'), ('巳', '癸'),
        ('午', '甲'), ('未', '乙'), ('申', '丙'), ('酉', '丁'),
        ('戌', '戊'), ('亥', '己'), ('子', '庚'), ('丑', '辛'),
      ];
      for (int i = 0; i < 12; i++) {
        final slot = JolCalendar2026.byJolIndex(i);
        expect(slot.monthBranch, expected[i].$1);
        expect(slot.monthStem, expected[i].$2);
      }
    });
  });

  group('JolCalendar2026 vs SolarTermService — KASI ±20분 (천체 계산)', () {
    // SolarTermService.jolDateTime(year, jolIndex) 는 year-day mod 365.2422 로 wraparound
    // 처리하므로 소한(285°) 도 year=2026 입력으로 2026-01-05 가 반환됨.
    for (int i = 0; i < 12; i++) {
      final slot = JolCalendar2026.byJolIndex(i);
      test('jolIndex $i (${slot.nameKo}) — calc vs KASI ±20분', () {
        final calc = SolarTermService.jolDateTime(2026, i);
        final diff = calc.difference(slot.dateTime).inMinutes.abs();
        expect(diff, lessThanOrEqualTo(20),
            reason:
                '${slot.nameKo} KASI=${slot.dateTime} calc=$calc diff=$diff 분');
      });
    }
  });

  group('display string 형식', () {
    test('displayKo: 입춘 2/4 05:02', () {
      expect(JolCalendar2026.byJolIndex(0).displayKo, '입춘 2/4 05:02');
    });
    test('displayEn: Ipchun · Feb 4 05:02', () {
      expect(JolCalendar2026.byJolIndex(0).displayEn, 'Ipchun · Feb 4 05:02');
    });
    test('displayKo: 경칩 3/5 22:58', () {
      expect(JolCalendar2026.byJolIndex(1).displayKo, '경칩 3/5 22:58');
    });
    test('displayKo: 대설 12/7 11:52', () {
      expect(JolCalendar2026.byJolIndex(10).displayKo, '대설 12/7 11:52');
    });
    test('displayKo: 소한 1/5 17:23', () {
      expect(JolCalendar2026.byJolIndex(11).displayKo, '소한 1/5 17:23');
    });
  });

  group('SolarTermService.lipchun(2026) — KASI 입춘 ±20분', () {
    test('입춘 2026 = 2/4 05:02 ±20분', () {
      final calc = SolarTermService.lipchun(2026);
      final kasi = DateTime(2026, 2, 4, 5, 2);
      final diff = calc.difference(kasi).inMinutes.abs();
      expect(diff, lessThanOrEqualTo(20));
    });
  });
}
