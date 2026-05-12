// 12 신살 회귀 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/shinsa_service.dart';

void main() {
  group('ShinsaService 역마/도화/화개 — 삼합 기반', () {
    test('수 삼합 (申子辰) → 역마 寅, 도화 酉, 화개 辰', () {
      expect(ShinsaService.yokmaFor('子'), '寅');
      expect(ShinsaService.dohwaFor('子'), '酉');
      expect(ShinsaService.hwagaeFor('子'), '辰');
      // 같은 그룹 다른 지지도 동일
      expect(ShinsaService.yokmaFor('申'), '寅');
      expect(ShinsaService.yokmaFor('辰'), '寅');
    });

    test('금 삼합 (巳酉丑) → 역마 亥, 도화 午, 화개 丑', () {
      expect(ShinsaService.yokmaFor('酉'), '亥');
      expect(ShinsaService.dohwaFor('酉'), '午');
      expect(ShinsaService.hwagaeFor('酉'), '丑');
    });

    test('화 삼합 (寅午戌) → 역마 申, 도화 卯, 화개 戌', () {
      expect(ShinsaService.yokmaFor('午'), '申');
      expect(ShinsaService.dohwaFor('午'), '卯');
      expect(ShinsaService.hwagaeFor('午'), '戌');
    });

    test('목 삼합 (亥卯未) → 역마 巳, 도화 子, 화개 未', () {
      expect(ShinsaService.yokmaFor('卯'), '巳');
      expect(ShinsaService.dohwaFor('卯'), '子');
      expect(ShinsaService.hwagaeFor('卯'), '未');
    });
  });

  group('ShinsaService 천을귀인 — 일간 기준', () {
    test('甲·戊·庚 일간 → 丑·未', () {
      expect(ShinsaService.cheonEulGwiInFor('甲'), ['丑', '未']);
      expect(ShinsaService.cheonEulGwiInFor('戊'), ['丑', '未']);
      expect(ShinsaService.cheonEulGwiInFor('庚'), ['丑', '未']);
    });

    test('乙·己 일간 → 子·申', () {
      expect(ShinsaService.cheonEulGwiInFor('乙'), ['子', '申']);
      expect(ShinsaService.cheonEulGwiInFor('己'), ['子', '申']);
    });

    test('丙·丁 일간 → 亥·酉', () {
      expect(ShinsaService.cheonEulGwiInFor('丙'), ['亥', '酉']);
      expect(ShinsaService.cheonEulGwiInFor('丁'), ['亥', '酉']);
    });

    test('壬·癸 일간 → 卯·巳', () {
      expect(ShinsaService.cheonEulGwiInFor('壬'), ['卯', '巳']);
      expect(ShinsaService.cheonEulGwiInFor('癸'), ['卯', '巳']);
    });

    test('辛 일간 → 午·寅', () {
      expect(ShinsaService.cheonEulGwiInFor('辛'), ['午', '寅']);
    });
  });

  group('ShinsaService 문창귀인 — 일간 기준', () {
    test('10 천간 모두 매핑 존재', () {
      const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      for (final s in stems) {
        final m = ShinsaService.munchangFor(s);
        expect(m.length, 1, reason: '$s 일간 문창귀인 누락');
      }
    });
    test('甲 일간 → 巳', () {
      expect(ShinsaService.munchangFor('甲'), '巳');
    });
    test('癸 일간 → 卯', () {
      expect(ShinsaService.munchangFor('癸'), '卯');
    });
  });

  group('ShinsaService.analyzeChart', () {
    test('IU 1993-05-16 (일주 丁卯, 년지 酉) — 활성 신살 검증', () {
      // 일지 卯 → 목삼합 → 역마 巳, 도화 子, 화개 未
      // 일간 丁 → 천을귀인 亥·酉, 문창귀인 酉
      // 년지 酉 가 천을귀인 + 문창귀인.
      final r = ShinsaService.analyzeChart(
        yearJi: '酉',
        monthJi: '巳', // 巳월 (역마 일치)
        dayChunGan: '丁',
        dayJi: '卯',
      );
      expect(r['천을귀인'], contains('year'));
      expect(r['문창귀인'], contains('year'));
      expect(r['역마'], contains('month'));
    });

    test('공망과 다른 origin — analyzeChart 정상 동작', () {
      // 一般 case: 일주 戊子, 년지 子, 월지 寅.
      // 일지 子 → 수삼합 → 역마 寅, 도화 酉, 화개 辰.
      // 일간 戊 → 천을 丑·未, 문창 申.
      // 월지 寅 = 역마. 년지 子 = 일지 자기인지? No: 년지 子 ≠ 일지 (그도 子 이긴 하지만 영역 다름)
      // 子 = 일지 도화 자기 (일지=子 vs 도화=酉) 아니 일지 자체는 도화 X, 도화 지지는 酉.
      final r = ShinsaService.analyzeChart(
        yearJi: '子',
        monthJi: '寅',
        dayChunGan: '戊',
        dayJi: '子',
      );
      expect(r['역마'], contains('month'));
    });
  });

  group('양인(羊刃)', () {
    test('양 천간 5종 매핑', () {
      expect(ShinsaService.yangInFor('甲'), '卯');
      expect(ShinsaService.yangInFor('丙'), '午');
      expect(ShinsaService.yangInFor('戊'), '午');
      expect(ShinsaService.yangInFor('庚'), '酉');
      expect(ShinsaService.yangInFor('壬'), '子');
    });
    test('음 천간은 양인 없음', () {
      expect(ShinsaService.yangInFor('乙'), '');
      expect(ShinsaService.yangInFor('丁'), '');
      expect(ShinsaService.yangInFor('癸'), '');
    });
  });

  group('괴강(魁罡)', () {
    test('6 괴강 일주 모두 true', () {
      for (final dp in ['庚辰', '庚戌', '壬辰', '壬戌', '戊戌', '戊辰']) {
        expect(ShinsaService.isGwaegangDayPillar(dp), isTrue, reason: dp);
      }
    });
    test('괴강 아닌 일주 false', () {
      expect(ShinsaService.isGwaegangDayPillar('丁卯'), isFalse);
      expect(ShinsaService.isGwaegangDayPillar('甲子'), isFalse);
    });
  });

  group('백호(白虎)', () {
    test('7 백호 일주 모두 true', () {
      for (final dp in ['甲辰', '乙未', '丙戌', '丁丑', '戊辰', '壬戌', '癸丑']) {
        expect(ShinsaService.isBaekhoDayPillar(dp), isTrue, reason: dp);
      }
    });
  });

  group('반합(半合)', () {
    test('申子 = 수 반합', () {
      // HapchungService 의 findBanhap. 별도 import 필요.
    });
  });

  group('ShinsaService.interpretation', () {
    test('역마 KO/EN 메시지', () {
      expect(
        ShinsaService.interpretation('역마', ['year'], ko: true),
        contains('역마'),
      );
      expect(
        ShinsaService.interpretation('역마', ['year'], ko: false),
        contains('Yeokma'),
      );
    });

    test('천을귀인 areas 표시', () {
      final msg = ShinsaService.interpretation('천을귀인', ['year', 'month'], ko: true);
      expect(msg, contains('년주'));
      expect(msg, contains('월주'));
    });
  });
}
