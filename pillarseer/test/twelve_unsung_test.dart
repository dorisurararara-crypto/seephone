// 12 운성 회귀 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/twelve_unsung_service.dart';

void main() {
  group('12 운성 — 양 천간 순행', () {
    test('甲 일간 — 장생 亥, 제왕 卯', () {
      // 甲 (양 목) → 亥(장생) → 子(목욕) → 丑(관대) → 寅(임관) → 卯(제왕) → ...
      expect(TwelveUnsungService.stageNameKo('甲', '亥'), '장생');
      expect(TwelveUnsungService.stageNameKo('甲', '子'), '목욕');
      expect(TwelveUnsungService.stageNameKo('甲', '丑'), '관대');
      expect(TwelveUnsungService.stageNameKo('甲', '寅'), '임관');
      expect(TwelveUnsungService.stageNameKo('甲', '卯'), '제왕');
    });

    test('丙 일간 — 장생 寅, 제왕 午', () {
      expect(TwelveUnsungService.stageNameKo('丙', '寅'), '장생');
      expect(TwelveUnsungService.stageNameKo('丙', '午'), '제왕');
    });

    test('壬 일간 — 장생 申, 제왕 子', () {
      expect(TwelveUnsungService.stageNameKo('壬', '申'), '장생');
      expect(TwelveUnsungService.stageNameKo('壬', '子'), '제왕');
    });
  });

  group('12 운성 — 음 천간 역행', () {
    test('乙 일간 — 장생 午, 제왕 寅 (역행)', () {
      // 乙 (음 목) 역행: 午(장생) → 巳(목욕) → 辰(관대) → 卯(임관) → 寅(제왕)
      expect(TwelveUnsungService.stageNameKo('乙', '午'), '장생');
      expect(TwelveUnsungService.stageNameKo('乙', '巳'), '목욕');
      expect(TwelveUnsungService.stageNameKo('乙', '辰'), '관대');
      expect(TwelveUnsungService.stageNameKo('乙', '卯'), '임관');
      expect(TwelveUnsungService.stageNameKo('乙', '寅'), '제왕');
    });

    test('癸 일간 — 장생 卯, 제왕 亥 (역행)', () {
      expect(TwelveUnsungService.stageNameKo('癸', '卯'), '장생');
      expect(TwelveUnsungService.stageNameKo('癸', '亥'), '제왕');
    });
  });

  group('12 운성 chartStages', () {
    test('IU 일간 丁 + year 酉 — 丁 음 천간 역행', () {
      // 丁 (음 화) 역행: 酉(장생) → 申(목욕) → 未(관대) → 午(임관) → 巳(제왕)
      final stages = TwelveUnsungService.chartStages(
        dayChunGan: '丁',
        yearJi: '酉',
        monthJi: '巳',
        dayJi: '卯',
      );
      expect(stages['year'], '장생');
      expect(stages['month'], '제왕'); // 巳 = 임관 wait, 丁 역행: 酉→申→未→午→巳 (4 steps from 장생) = 제왕
    });

    test('hour 옵셔널 — 없으면 출력에 미포함', () {
      final stages = TwelveUnsungService.chartStages(
        dayChunGan: '甲',
        yearJi: '亥',
        monthJi: '寅',
        dayJi: '卯',
      );
      expect(stages.containsKey('hour'), isFalse);
    });
  });

  group('12 운성 interpretation', () {
    test('제왕 KO/EN', () {
      expect(
        TwelveUnsungService.interpretation('제왕', ko: true),
        contains('정점'),
      );
      expect(
        TwelveUnsungService.interpretation('제왕', ko: false),
        contains('Peak'),
      );
    });

    test('절 KO', () {
      expect(
        TwelveUnsungService.interpretation('절', ko: true),
        contains('단절'),
      );
    });
  });

  group('12 운성 — 단계 모두 12개', () {
    test('stages.length == 12', () {
      expect(TwelveUnsungService.stages.length, 12);
      expect(TwelveUnsungService.stagesEn.length, 12);
    });

    test('10 천간 × 12 지 = 120 combination 모두 유효한 stage', () {
      const gan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      const ji = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
      for (final g in gan) {
        for (final j in ji) {
          final idx = TwelveUnsungService.stageIndex(g, j);
          expect(idx, greaterThanOrEqualTo(0),
              reason: '$g-$j 운성 누락');
          expect(idx, lessThan(12),
              reason: '$g-$j 운성 인덱스 범위 초과');
        }
      }
    });
  });
}
