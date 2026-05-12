// 2026 신년운세 — KASI 12절 source-of-truth 잠금 테스트.
//
// codex Round 3 권고: "_slots 를 구조화하고 SolarTermService.jolDateTime() 과 직접 비교".
// JolCalendar2026 이 source-of-truth, 화면(_NewYear2026Screen) 과 이 테스트가 모두 참조.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/jol_calendar_2026.dart';
import 'package:pillarseer/services/solar_term_service.dart';

void main() {
  group('JolCalendar2026 — 12절 KASI source-of-truth', () {
    test('12 entries 존재', () {
      expect(JolCalendar2026.all.length, 12);
      expect(JolCalendar2026.displayOrder.length, 12);
    });

    test('display order = 1월 → 12월 (소한 시작, 대설 끝)', () {
      final ord = JolCalendar2026.displayOrder;
      expect(ord.first.nameKo, '소한');
      expect(ord.first.monthBranch, '丑');
      expect(ord.last.nameKo, '대설');
      expect(ord.last.monthBranch, '子');
    });

    test('경칩 2026 = 3/5 22:58 (NOT 3/6)', () {
      final gc = JolCalendar2026.byJolIndex(1);
      expect(gc.nameKo, '경칩');
      expect(gc.dateTime.month, 3);
      expect(gc.dateTime.day, 5);
      expect(gc.dateTime.hour, 22);
      expect(gc.dateTime.minute, 58);
      expect(gc.monthBranch, '卯');
      expect(gc.monthStem, '辛');
    });

    test('입춘 2026 = 2/4 05:02', () {
      final ic = JolCalendar2026.byJolIndex(0);
      expect(ic.nameKo, '입춘');
      expect(ic.dateTime, DateTime(2026, 2, 4, 5, 2));
      expect(ic.monthBranch, '寅');
      expect(ic.monthStem, '庚');
    });

    test('소한 2026 = 1/5 17:23', () {
      final sh = JolCalendar2026.byJolIndex(11);
      expect(sh.nameKo, '소한');
      expect(sh.dateTime, DateTime(2026, 1, 5, 17, 23));
      expect(sh.monthBranch, '丑');
      expect(sh.monthStem, '辛');
    });

    test('丙년 五虎遁 — 月干 정확성', () {
      // 寅 庚, 卯 辛, 辰 壬, 巳 癸, 午 甲, 未 乙, 申 丙, 酉 丁, 戌 戊, 亥 己, 子 庚, 丑 辛
      const expected = [
        ('寅', '庚'), ('卯', '辛'), ('辰', '壬'), ('巳', '癸'),
        ('午', '甲'), ('未', '乙'), ('申', '丙'), ('酉', '丁'),
        ('戌', '戊'), ('亥', '己'), ('子', '庚'), ('丑', '辛'),
      ];
      for (int i = 0; i < 12; i++) {
        final slot = JolCalendar2026.byJolIndex(i);
        expect(slot.monthBranch, expected[i].$1,
            reason: 'jolIndex $i branch mismatch');
        expect(slot.monthStem, expected[i].$2,
            reason: 'jolIndex $i stem mismatch');
      }
    });

    test('chronological order (소한 1월 → 입춘 2월 → ... 대설 12월)', () {
      final ord = JolCalendar2026.displayOrder;
      for (int i = 1; i < ord.length; i++) {
        expect(ord[i].dateTime.isAfter(ord[i - 1].dateTime), true,
            reason:
                'idx $i (${ord[i].nameKo}) is not after idx ${i - 1} (${ord[i - 1].nameKo})');
      }
    });
  });

  group('JolCalendar2026 vs SolarTermService — 천체 계산과 ±20분 일치', () {
    // 입춘(0) ~ 대설(10) — 2026 year 입력으로 계산.
    // 소한(11) 은 2026 양력 1월 발생 → SolarTermService 입력은 2025.
    for (int i = 0; i < 12; i++) {
      test('jolIndex $i (${JolCalendar2026.byJolIndex(i).nameKo}) — KASI ±20분 이내', () {
        final diff = JolCalendar2026.minutesDiff(i);
        final slot = JolCalendar2026.byJolIndex(i);
        expect(diff, lessThanOrEqualTo(20),
            reason:
                '${slot.nameKo} KASI=${slot.dateTime} vs SolarTermService calc, diff=$diff 분');
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
