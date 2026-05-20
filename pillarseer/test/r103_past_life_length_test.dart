// R103 sprint 1 — 시나리오 sentence 수 10~14.
//
// R102: 8~10 (낮음 + 사용자 "더 길어야 돼" 불만).
// R103: 10~14 (사건 strand 추가, padding 금지).
// 마침표 / 느낌표 / 물음표 기준 sentence 분할.

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

  group('R103 — sentence count 10~14', () {
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      ('gongmang', () => mk('子'), () => mk('戌')),
      ('cheoneul', () => mk('子'), () => mk('丑')),
    ];

    test('50 sample sentence count ∈ [10, 14]', () {
      final celebs = <String>['솔라', '카리나', '뷔', '아이유', '이찬원'];
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (final celeb in celebs) {
          for (var seed = 0; seed < 2; seed++) {
            final s = PastLifeService.generateScenario(
              user: mkU(),
              celeb: mkC(),
              celebName: celeb,
              userName: '당신',
              seed: seed,
            );
            final sentences = s
                .split(RegExp(r'[.!?]\s*'))
                .where((e) => e.trim().isNotEmpty)
                .toList();
            expect(sentences.length, inInclusiveRange(10, 14),
                reason:
                    '[$label/$celeb/seed=$seed] sentence ${sentences.length} ∉ [10,14]: $s');
          }
        }
      }
    });
  });
}
