// 공망(空亡) 서비스 회귀 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/gong_mang_service.dart';

void main() {
  group('GongMangService.forDayPillar', () {
    test('甲子순 (甲子~癸酉) → 戌·亥 공망', () {
      expect(GongMangService.forDayPillar('甲子'), ['戌', '亥']);
      expect(GongMangService.forDayPillar('乙丑'), ['戌', '亥']);
      expect(GongMangService.forDayPillar('癸酉'), ['戌', '亥']);
    });
    test('甲戌순 (甲戌~癸未) → 申·酉 공망', () {
      expect(GongMangService.forDayPillar('甲戌'), ['申', '酉']);
      expect(GongMangService.forDayPillar('戊寅'), ['申', '酉']);
      expect(GongMangService.forDayPillar('癸未'), ['申', '酉']);
    });
    test('甲申순 → 午·未 공망', () {
      expect(GongMangService.forDayPillar('甲申'), ['午', '未']);
      expect(GongMangService.forDayPillar('癸巳'), ['午', '未']);
    });

    test('IU 일주 丁卯 → 甲子순 戌·亥 공망 (regression)', () {
      // 丁卯 (idx 3) ∈ 甲子순 (0-9)
      expect(GongMangService.forDayPillar('丁卯'), ['戌', '亥']);
    });
    test('甲午순 → 辰·巳 공망', () {
      expect(GongMangService.forDayPillar('甲午'), ['辰', '巳']);
    });
    test('甲辰순 → 寅·卯 공망', () {
      expect(GongMangService.forDayPillar('甲辰'), ['寅', '卯']);
    });
    test('甲寅순 (甲寅~癸亥) → 子·丑 공망', () {
      expect(GongMangService.forDayPillar('甲寅'), ['子', '丑']);
      expect(GongMangService.forDayPillar('癸亥'), ['子', '丑']);
    });

    test('Invalid input → empty list', () {
      expect(GongMangService.forDayPillar(''), isEmpty);
      expect(GongMangService.forDayPillar('A'), isEmpty);
      expect(GongMangService.forDayPillar('ABC'), isEmpty);
    });
  });

  group('GongMangService.affectedAreas', () {
    test('일주 甲子 + 년지 戌 → year 공망', () {
      final r = GongMangService.affectedAreas(
        dayPillar: '甲子',
        yearJi: '戌',
        monthJi: '寅',
      );
      expect(r, contains('year'));
      expect(r, isNot(contains('month')));
    });

    test('일주 甲子 + 시지 亥 → hour 공망', () {
      final r = GongMangService.affectedAreas(
        dayPillar: '甲子',
        yearJi: '寅',
        monthJi: '卯',
        hourJi: '亥',
      );
      expect(r, contains('hour'));
    });

    test('공망 없음', () {
      final r = GongMangService.affectedAreas(
        dayPillar: '甲子',
        yearJi: '寅',
        monthJi: '卯',
        hourJi: '辰',
      );
      expect(r, isEmpty);
    });
  });

  group('GongMangService.interpretation', () {
    test('빈 영역 KO/EN', () {
      expect(
        GongMangService.interpretation([], ko: true),
        contains('원국에 공망 없음'),
      );
      expect(
        GongMangService.interpretation([], ko: false),
        contains('No void'),
      );
    });

    test('year/month/hour 영역별 메시지 KO', () {
      expect(
        GongMangService.interpretation(['year'], ko: true),
        contains('년주 공망'),
      );
      expect(
        GongMangService.interpretation(['month'], ko: true),
        contains('월주 공망'),
      );
      expect(
        GongMangService.interpretation(['hour'], ko: true),
        contains('시주 공망'),
      );
    });

    test('영역별 메시지 EN', () {
      expect(
        GongMangService.interpretation(['year'], ko: false),
        contains('Year-pillar'),
      );
    });
  });
}
