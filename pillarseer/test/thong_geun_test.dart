// 통근·투간 회귀.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/thong_geun_service.dart';

void main() {
  group('통근 강도', () {
    test('甲 일간 + 寅 (본기 甲 → 木) = 본기 통근 3', () {
      expect(ThongGeunService.thongGeunStrength('甲', '寅'), 3);
    });

    test('甲 일간 + 卯 (본기 乙 → 木) = 본기 통근 3', () {
      // 乙 도 木 이므로 통근.
      expect(ThongGeunService.thongGeunStrength('甲', '卯'), 3);
    });

    test('甲 일간 + 辰 (중기 乙 → 木) = 중기 통근 2', () {
      // 辰 = 戊 본기 (土), 乙 중기 (木), 癸 여기 (水)
      // 甲 → 木 → 乙 (중기) 매칭 = 2
      expect(ThongGeunService.thongGeunStrength('甲', '辰'), 2);
    });

    test('甲 일간 + 子 (癸 본기 → 水) = 통근 X', () {
      expect(ThongGeunService.thongGeunStrength('甲', '子'), 0);
    });

    test('庚 일간 + 申 (庚 본기 → 金) = 본기 통근 3', () {
      expect(ThongGeunService.thongGeunStrength('庚', '申'), 3);
    });

    test('庚 일간 + 丑 (辛 여기 → 金) = 여기 통근 1', () {
      // 丑 = 己 본기 (土), 癸 중기 (水), 辛 여기 (金)
      // 庚 → 金 → 辛 (여기) = 1
      expect(ThongGeunService.thongGeunStrength('庚', '丑'), 1);
    });
  });

  group('chart 안에서 통근 찾기', () {
    test('壬 일간 + 申子辰 — 申(壬 중기)에 통근', () {
      // 壬 = 水. 申 (지장간 庚壬戊). 중기 壬 → 통근 2.
      final r = ThongGeunService.thongGeunInChart(
        gan: '壬',
        yearJi: '申',
        monthJi: '寅',
        dayJi: '辰',
      );
      // 申 중기 壬 (壬 자기) → 통근 2. 또는 子가 본기 癸 (水) → 3.
      // 子가 없으므로 申 = 2.
      expect(r.strength, equals(2));
      expect(r.area, equals('year'));
    });
  });

  group('투간', () {
    test('辰 지장간 (戊乙癸) — chart 천간에 乙·癸 있으면 투간', () {
      final r = ThongGeunService.tugaeChart(
        ji: '辰',
        chartGans: ['乙', '甲', '癸', '丙'],
      );
      expect(r, containsAll(['乙', '癸']));
    });

    test('투간 없음 — 지장간 천간이 chart에 없으면', () {
      final r = ThongGeunService.tugaeChart(
        ji: '子', // 癸 본기
        chartGans: ['甲', '乙', '丙'], // 癸 없음
      );
      expect(r, isEmpty);
    });
  });

  group('label', () {
    test('통근 강도 라벨 KO/EN', () {
      for (int s = 0; s <= 3; s++) {
        expect(ThongGeunService.thongGeunLabel(s, ko: true), isNotEmpty);
        expect(ThongGeunService.thongGeunLabel(s, ko: false), isNotEmpty);
      }
    });
  });
}
