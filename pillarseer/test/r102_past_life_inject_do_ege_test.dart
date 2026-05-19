// R102 sprint 2 — inject() 의 "$X 도" / "$Y 에게" placeholder 잔존 0 가드.
//
// 사용자 OCR verbatim ("김채원 도") 정확 회귀.

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

  group('R102 — placeholder + " 도" / " 에게" 잔존 0', () {
    // wonjin (子-未) / gongmang (子-戌) / hap (子-丑) / chung (子-午) 모두 검증.
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('gongmang', () => mk('子'), () => mk('戌')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
    ];

    final celebNames = <String>['김채원', '솔라', '아이유', '카리나'];
    final userNames = <String>['당신', '주현', '도리'];

    test('150 시나리오 — celeb/user 직후 " 도" 잔존 0', () {
      var n = 0;
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (final cn in celebNames) {
          for (final un in userNames) {
            for (var s = 0; s < 4; s++) {
              final scenario = PastLifeService.generateScenario(
                user: mkU(),
                celeb: mkC(),
                celebName: cn,
                userName: un,
                seed: s,
              );
              // 정확 패턴 — placeholder 잔존이 아닌, 실명 + 공백 + "도/에게" 패턴.
              expect(scenario.contains('$cn 도'), isFalse,
                  reason: '[$label seed=$s] "$cn 도" 잔존: $scenario');
              expect(scenario.contains('$cn 에게'), isFalse,
                  reason: '[$label seed=$s] "$cn 에게" 잔존: $scenario');
              expect(scenario.contains('$un 도'), isFalse,
                  reason: '[$label seed=$s] "$un 도" 잔존: $scenario');
              expect(scenario.contains('$un 에게'), isFalse,
                  reason: '[$label seed=$s] "$un 에게" 잔존: $scenario');
              // 추가 방어 — " 에서 " " 에 " " 부터 " 등 receive 조사 잔존 0.
              expect(scenario.contains('$cn 에서'), isFalse);
              expect(scenario.contains('$un 에서'), isFalse);
              expect(scenario.contains('$cn 부터'), isFalse);
              expect(scenario.contains('$un 부터'), isFalse);
              n++;
            }
          }
        }
      }
      // 4 case × 4 celeb × 3 user × 4 seed = 192 샘플.
      expect(n, greaterThanOrEqualTo(150));
    });
  });
}
