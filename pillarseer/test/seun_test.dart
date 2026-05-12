// 세운 회귀.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/seun_service.dart';
import 'package:pillarseer/models/saju_result.dart';

void main() {
  group('SeunService.yearGanji', () {
    test('2024 = 甲辰', () {
      expect(SeunService.yearGanji(2024), '甲辰');
    });
    test('2000 = 庚辰', () {
      expect(SeunService.yearGanji(2000), '庚辰');
    });
    test('1990 = 庚午', () {
      expect(SeunService.yearGanji(1990), '庚午');
    });
  });

  group('SeunService.annualTheme', () {
    test('甲 일간 + 2024 (甲辰) → 비견', () {
      final r = SeunService.annualTheme(dayMaster: '甲', solarYear: 2024);
      expect(r.godGan, TenGod.bigyeon);
      expect(r.themeKo, contains('비견'));
      expect(r.themeEn, contains('Peer'));
    });

    test('丙 일간 + 2024 (甲辰) → 편인 (木 → 火 同 polarity)', () {
      // 甲(양 木) generates 丙(양 火), 같은 양양 → 편인
      final r = SeunService.annualTheme(dayMaster: '丙', solarYear: 2024);
      expect(r.godGan, TenGod.pyeonin);
    });

    test('테마 메시지 비어있지 않음', () {
      final r = SeunService.annualTheme(dayMaster: '甲', solarYear: 2024);
      expect(r.themeKo, isNotEmpty);
      expect(r.themeEn, isNotEmpty);
    });
  });
}
