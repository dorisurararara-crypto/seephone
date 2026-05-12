// 합·충 회귀 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/hapchung_service.dart';

void main() {
  group('천간 5합', () {
    test('甲-己 → 土', () {
      expect(HapchungService.isCheonganHap('甲', '己'), isTrue);
      expect(HapchungService.cheonganHapElement('甲', '己'), '土');
      expect(HapchungService.isCheonganHap('己', '甲'), isTrue);
    });
    test('乙-庚 → 金', () {
      expect(HapchungService.cheonganHapElement('乙', '庚'), '金');
    });
    test('丙-辛 → 水', () {
      expect(HapchungService.cheonganHapElement('丙', '辛'), '水');
    });
    test('丁-壬 → 木', () {
      expect(HapchungService.cheonganHapElement('丁', '壬'), '木');
    });
    test('戊-癸 → 火', () {
      expect(HapchungService.cheonganHapElement('戊', '癸'), '火');
    });
    test('합 아닌 조합 false', () {
      expect(HapchungService.isCheonganHap('甲', '乙'), isFalse);
      expect(HapchungService.cheonganHapElement('甲', '乙'), '');
    });
  });

  group('지지 6합', () {
    test('6쌍 검증', () {
      expect(HapchungService.isJijiHap('子', '丑'), isTrue);
      expect(HapchungService.isJijiHap('寅', '亥'), isTrue);
      expect(HapchungService.isJijiHap('卯', '戌'), isTrue);
      expect(HapchungService.isJijiHap('辰', '酉'), isTrue);
      expect(HapchungService.isJijiHap('巳', '申'), isTrue);
      expect(HapchungService.isJijiHap('午', '未'), isTrue);
    });
    test('반대 방향도 true', () {
      expect(HapchungService.isJijiHap('丑', '子'), isTrue);
    });
    test('합 아닌 조합 false', () {
      expect(HapchungService.isJijiHap('子', '寅'), isFalse);
    });
  });

  group('지지 6충', () {
    test('6쌍 검증', () {
      expect(HapchungService.isJijiChung('子', '午'), isTrue);
      expect(HapchungService.isJijiChung('丑', '未'), isTrue);
      expect(HapchungService.isJijiChung('寅', '申'), isTrue);
      expect(HapchungService.isJijiChung('卯', '酉'), isTrue);
      expect(HapchungService.isJijiChung('辰', '戌'), isTrue);
      expect(HapchungService.isJijiChung('巳', '亥'), isTrue);
    });
    test('충 아닌 조합 false', () {
      expect(HapchungService.isJijiChung('子', '丑'), isFalse);
      expect(HapchungService.isJijiChung('寅', '巳'), isFalse);
    });
  });

  group('analyzeChart', () {
    test('년주-월주 천간합 + 일주-시주 지지충', () {
      // 甲년 + 己월 = 천간합 土
      // 子일 + 午시 = 지지충
      final r = HapchungService.analyzeChart(
        yearGan: '甲',
        yearJi: '寅',
        monthGan: '己',
        monthJi: '巳',
        dayGan: '丙',
        dayJi: '子',
        hourGan: '丙',
        hourJi: '午',
      );
      // 천간합 甲-己
      expect(
          r.hap.any((e) =>
              e.area1 == 'year' && e.area2 == 'month' && e.element == '土'),
          isTrue);
      // 지지충 子-午
      expect(
          r.chung
              .any((e) => e.area1 == 'day' && e.area2 == 'hour'),
          isTrue);
    });

    test('hour 없으면 hour 관련 검사 안 함', () {
      final r = HapchungService.analyzeChart(
        yearGan: '甲',
        yearJi: '寅',
        monthGan: '乙',
        monthJi: '卯',
        dayGan: '丙',
        dayJi: '辰',
      );
      // 어떤 결과든 hour area 포함 X
      for (final e in r.hap) {
        expect(e.area1, isNot(equals('hour')));
        expect(e.area2, isNot(equals('hour')));
      }
    });
  });

  group('interpretation', () {
    test('합/충 KO/EN 메시지 비어있지 않음', () {
      expect(HapchungService.hapInterpretation(ko: true), isNotEmpty);
      expect(HapchungService.hapInterpretation(ko: false), isNotEmpty);
      expect(HapchungService.chungInterpretation(ko: true), isNotEmpty);
      expect(HapchungService.chungInterpretation(ko: false), isNotEmpty);
    });
  });
}
