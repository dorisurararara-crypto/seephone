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

  group('삼합(三合)', () {
    test('申子辰 → 수 (3 areas)', () {
      final r = HapchungService.findSamhap(
        yearJi: '申',
        monthJi: '子',
        dayJi: '辰',
        hourJi: '寅',
      );
      expect(r.length, 1);
      expect(r[0].element, '水');
      expect(r[0].areas, containsAll(['year', 'month', 'day']));
    });
    test('寅午戌 → 화', () {
      final r = HapchungService.findSamhap(
        yearJi: '寅',
        monthJi: '午',
        dayJi: '戌',
      );
      expect(r.length, 1);
      expect(r[0].element, '火');
    });
    test('일부만 있으면 발견 X (반합 X)', () {
      final r = HapchungService.findSamhap(
        yearJi: '申',
        monthJi: '子',
        dayJi: '丑', // 辰 없음
      );
      expect(r, isEmpty);
    });
  });

  group('반합(半合) — 삼합 2/3', () {
    test('申子 = 수 반합 (year+month)', () {
      final r = HapchungService.findBanhap(
        yearJi: '申',
        monthJi: '子',
        dayJi: '寅', // 다른 삼합
      );
      expect(r.length, 1);
      expect(r[0].element, '水');
    });
    test('子辰 = 수 반합', () {
      final r = HapchungService.findBanhap(
        yearJi: '寅',
        monthJi: '子',
        dayJi: '辰',
      );
      expect(r.length, 1);
      expect(r[0].element, '水');
    });
    test('3개 다 있으면 반합 X (완전 삼합)', () {
      final r = HapchungService.findBanhap(
        yearJi: '申',
        monthJi: '子',
        dayJi: '辰',
      );
      // 3개 다 있으면 정확히 2 case 가 아니라 반합 결과 0.
      expect(r, isEmpty);
    });
  });

  group('방합(方合)', () {
    test('寅卯辰 → 목 (봄방)', () {
      final r = HapchungService.findBanghap(
        yearJi: '寅',
        monthJi: '卯',
        dayJi: '辰',
      );
      expect(r.length, 1);
      expect(r[0].element, '木');
    });
    test('亥子丑 → 수 (겨울방)', () {
      final r = HapchungService.findBanghap(
        yearJi: '亥',
        monthJi: '子',
        dayJi: '丑',
        hourJi: '酉',
      );
      expect(r.length, 1);
      expect(r[0].element, '水');
    });
    test('일부만 있으면 발견 X', () {
      final r = HapchungService.findBanghap(
        yearJi: '寅',
        monthJi: '卯',
        dayJi: '巳', // 辰 없음, 巳 = 화방
      );
      expect(r, isEmpty);
    });
  });

  group('형(刑)', () {
    test('三刑 寅巳申 3개 모두 있음', () {
      final r = HapchungService.findHyung(
        yearJi: '寅', monthJi: '巳', dayJi: '申', hourJi: '子',
      );
      expect(r.any((e) => e.type == '三刑'), isTrue);
    });
    test('三刑 丑戌未', () {
      final r = HapchungService.findHyung(
        yearJi: '丑', monthJi: '戌', dayJi: '未',
      );
      expect(r.any((e) => e.type == '三刑'), isTrue);
    });
    test('自刑 辰辰', () {
      final r = HapchungService.findHyung(
        yearJi: '辰', monthJi: '辰', dayJi: '子',
      );
      expect(r.any((e) => e.type == '自刑'), isTrue);
    });
    test('子卯刑', () {
      final r = HapchungService.findHyung(
        yearJi: '子', monthJi: '卯', dayJi: '辰',
      );
      expect(r.any((e) => e.type == '子卯刑'), isTrue);
    });
    test('형 없음', () {
      final r = HapchungService.findHyung(
        yearJi: '寅', monthJi: '卯', dayJi: '辰',
      );
      expect(r, isEmpty);
    });
  });

  group('파(破)·해(害)', () {
    test('子酉 = 파', () {
      expect(HapchungService.isJijiPa('子', '酉'), isTrue);
      expect(HapchungService.isJijiPa('酉', '子'), isTrue);
    });
    test('子未 = 해', () {
      expect(HapchungService.isJijiHae('子', '未'), isTrue);
    });
    test('파/해 아닌 조합 false', () {
      expect(HapchungService.isJijiPa('子', '丑'), isFalse); // 합 아닌가? 합이지만 파는 X
      expect(HapchungService.isJijiHae('子', '子'), isFalse);
    });
    test('findPaHae — chart 적용', () {
      final r = HapchungService.findPaHae(
        yearJi: '子',
        monthJi: '酉',
        dayJi: '未',
        hourJi: '寅',
      );
      // 子-酉 = 파, 子-未 = 해
      expect(r.pa, isNotEmpty);
      expect(r.hae, isNotEmpty);
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
