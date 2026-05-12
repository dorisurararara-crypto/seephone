// 대운 회귀.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/daewoon_service.dart';

void main() {
  group('대운 chain', () {
    test('양남: 월주 乙丑, 년간 甲 (양), 남자 → 순행 (丙寅, 丁卯, ...)', () {
      final chain = DaewoonService.chain(
        monthPillar: '乙丑',
        yearChunGan: '甲', // 양
        isMale: true,
        startAge: 3,
      );
      expect(chain.length, 8);
      expect(chain[0].ganji, '丙寅'); // 乙丑 + 1
      expect(chain[1].ganji, '丁卯'); // + 2
      expect(chain[0].age, 3);
      expect(chain[1].age, 13);
    });

    test('음녀: 월주 乙丑, 년간 乙 (음), 여자 → 순행', () {
      final chain = DaewoonService.chain(
        monthPillar: '乙丑',
        yearChunGan: '乙', // 음
        isMale: false,
      );
      // 음+여자 = 음녀 = 순행
      expect(chain[0].ganji, '丙寅');
    });

    test('양녀: 월주 乙丑, 년간 甲 (양), 여자 → 역행', () {
      final chain = DaewoonService.chain(
        monthPillar: '乙丑',
        yearChunGan: '甲',
        isMale: false,
      );
      // 양+여 = 양녀 = 역행 (乙丑 - 1 = 甲子)
      expect(chain[0].ganji, '甲子');
    });

    test('음남: 월주 丙寅, 년간 乙 (음), 남자 → 역행', () {
      final chain = DaewoonService.chain(
        monthPillar: '丙寅',
        yearChunGan: '乙',
        isMale: true,
      );
      // 음+남 = 음남 = 역행 (丙寅 - 1 = 乙丑)
      expect(chain[0].ganji, '乙丑');
    });

    test('chain 길이 항상 8', () {
      final chain = DaewoonService.chain(
        monthPillar: '甲子',
        yearChunGan: '甲',
        isMale: true,
      );
      expect(chain.length, 8);
    });

    test('각 chunk 10년 간격', () {
      final chain = DaewoonService.chain(
        monthPillar: '甲子',
        yearChunGan: '甲',
        isMale: true,
        startAge: 5,
      );
      expect(chain[0].age, 5);
      expect(chain[1].age, 15);
      expect(chain[7].age, 75);
    });

    test('currentChunk — 나이별 정확', () {
      final chain = DaewoonService.chain(
        monthPillar: '甲子',
        yearChunGan: '甲',
        isMale: true,
        startAge: 3,
      );
      // age 27 → 3, 13, 23 중 가장 큰 = 23 chunk
      final r = DaewoonService.currentChunk(chain: chain, userAge: 27);
      expect(r?.age, 23);
    });

    test('currentChunk — 시작 전 = null', () {
      final chain = DaewoonService.chain(
        monthPillar: '甲子',
        yearChunGan: '甲',
        isMale: true,
        startAge: 10,
      );
      final r = DaewoonService.currentChunk(chain: chain, userAge: 5);
      expect(r, isNull);
    });
  });
}
