// R103 sprint 1 — phrase cap 강화 가드.
//
// 사용자 mandate "다 똑같다" 직발. R102 cap 보다 강화:
//   "사주상"               ≤ 1
//   "이번 생"              ≤ 1
//   "그 옛"                ≤ 1
//   "두 사람은"            = 0
//   "결이 두 사람 사이에"  = 0

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> pool;

  setUpAll(() async {
    final f = File('assets/data/past_life_pool.json');
    pool = json.decode(await f.readAsString()) as Map<String, dynamic>;
    PastLifeService.resetCacheForTest();
    PastLifeService.seedForTest(pool);
  });

  tearDownAll(() {
    PastLifeService.resetCacheForTest();
  });

  SajuResult mk(String dJi) => SajuResult(
        yearPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
        monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
        dayPillar: Pillar(chunGan: '戊', jiJi: dJi),
        hourPillar: null,
        elements: const FiveElements(
            wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
        dayMaster: '戊',
        dayMasterName: 'Test',
        summary: 'test',
        categoryReadings: const {},
      );

  int countOccurrences(String s, String needle) {
    if (needle.isEmpty) return 0;
    var n = 0;
    var i = 0;
    while (true) {
      final idx = s.indexOf(needle, i);
      if (idx < 0) break;
      n++;
      i = idx + needle.length;
    }
    return n;
  }

  group('R103 — phrase cap 강화', () {
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      ('gongmang', () => mk('子'), () => mk('戌')),
    ];

    test('50 sample — 5 phrase cap 모두 통과', () {
      final celebs = <String>['솔라', '카리나', '뷔', '아이유', '이찬원'];
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (final celeb in celebs) {
          for (var seed = 0; seed < 3; seed++) {
            final s = PastLifeService.generateScenario(
              user: mkU(),
              celeb: mkC(),
              celebName: celeb,
              userName: '당신',
              seed: seed,
            );
            // 사주상 ≤ 1
            expect(countOccurrences(s, '사주상'), lessThanOrEqualTo(1),
                reason: '[$label/$celeb/seed=$seed] 사주상 > 1: $s');
            // 이번 생 ≤ 1
            expect(countOccurrences(s, '이번 생'), lessThanOrEqualTo(1),
                reason: '[$label/$celeb/seed=$seed] 이번 생 > 1: $s');
            // 그 옛 ≤ 1
            expect(countOccurrences(s, '그 옛'), lessThanOrEqualTo(1),
                reason: '[$label/$celeb/seed=$seed] 그 옛 > 1: $s');
            // 두 사람은 = 0
            expect(countOccurrences(s, '두 사람은'), 0,
                reason: '[$label/$celeb/seed=$seed] 두 사람은 > 0: $s');
            // "결이 두 사람 사이에" = 0
            expect(countOccurrences(s, '결이 두 사람 사이에'), 0,
                reason:
                    '[$label/$celeb/seed=$seed] 결이 두 사람 사이에 > 0: $s');
          }
        }
      }
    });
  });
}
