// R102 sprint 2 — seed determinism 회귀.
//
//   1) 같은 seed → 같은 시나리오.
//   2) 다른 seed → 다른 시나리오 (variance 가드).

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

  group('R102 — seed determinism', () {
    test('같은 (user, celeb, seed) → 같은 시나리오', () {
      final u = mk('子');
      final c = mk('未');
      final a = PastLifeService.generateScenario(
        user: u, celeb: c,
        celebName: '솔라', userName: '당신',
        seed: 42,
      );
      final b = PastLifeService.generateScenario(
        user: u, celeb: c,
        celebName: '솔라', userName: '당신',
        seed: 42,
      );
      expect(a, equals(b));
    });

    test('다른 seed → 다른 시나리오 variance ≥ 5/10', () {
      final u = mk('子');
      final c = mk('未');
      final base = PastLifeService.generateScenario(
        user: u, celeb: c,
        celebName: '솔라', userName: '당신',
        seed: 0,
      );
      var diff = 0;
      for (var s = 1; s <= 10; s++) {
        final other = PastLifeService.generateScenario(
          user: u, celeb: c,
          celebName: '솔라', userName: '당신',
          seed: s,
        );
        if (other != base) diff++;
      }
      expect(diff, greaterThanOrEqualTo(5),
          reason: 'seed variance 부족: $diff/10');
    });
  });
}
