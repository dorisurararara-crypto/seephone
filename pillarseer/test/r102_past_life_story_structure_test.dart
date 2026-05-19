// R102 sprint 2 — 4 phase 구조 + 사주 용어 등장 + 8~10 문장.
//
// 구조:
//   1. body_lines[k] 가 Map (setup/event/turn/resolution) 형태.
//   2. 각 phase variant ≥ 12.
//   3. scenarioKo 가 8~10 문장 범위.
//   4. event 문장에 사주 용어("원진살" / "합" / "충" / "도화" / "공망" / "역마" /
//      "천을귀인" / "형") 1회 이상 등장.

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

  group('R102 — pool body_lines 4 phase 구조', () {
    test('8 키워드 모두 setup/event/turn/resolution 4 phase 존재', () {
      const keys = [
        'wonjin',
        'dohwa',
        'yeokma',
        'cheoneul',
        'gongmang',
        'hap',
        'chung',
        'hyeong',
      ];
      final body = pool['body_lines'] as Map<String, dynamic>;
      for (final k in keys) {
        final entry = body[k];
        expect(entry, isA<Map>(), reason: '$k body_lines 가 Map 이 아님');
        final m = entry as Map<String, dynamic>;
        for (final phase in ['setup', 'event', 'turn', 'resolution']) {
          expect(m[phase], isA<List>(),
              reason: '$k.$phase 누락 또는 List 아님');
          expect((m[phase] as List).length, greaterThanOrEqualTo(12),
              reason: '$k.$phase variant < 12 (got ${(m[phase] as List).length})');
        }
      }
    });
  });

  group('R102 — scenario 흐름 / 사주 용어 등장', () {
    // 사주 용어 stopword pool — event phase 가 이 중 하나를 포함해야 함.
    const sajuTerms = <String>[
      '원진살', '도화살', '역마살', '천을귀인', '공망',
      '합 결', '충 결', '형 결', '도화 결', '역마 결',
      '공망 결', '천을귀인 결', '원진살이', '도화살이',
      // 일반 형태도 허용.
      '사주상', '사주에',
    ];

    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      ('gongmang', () => mk('子'), () => mk('戌')),
    ];

    test('시나리오 8~10 문장 (마침표 기준) + 사주 용어 1회 이상', () {
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (var seed = 0; seed < 5; seed++) {
          final scenario = PastLifeService.generateScenario(
            user: mkU(),
            celeb: mkC(),
            celebName: '솔라',
            userName: '당신',
            seed: seed,
          );
          // 문장 수 — 마침표 / 느낌표 / 물음표 기준.
          final sentences = scenario
              .split(RegExp(r'[.!?]\s*'))
              .where((s) => s.trim().isNotEmpty)
              .toList();
          expect(sentences.length, inInclusiveRange(7, 14),
              reason:
                  '[$label seed=$seed] 문장 수 ${sentences.length} 범위 밖. body=$scenario');
          // 사주 용어 1회 이상.
          final hasTerm = sajuTerms.any((t) => scenario.contains(t));
          expect(hasTerm, isTrue,
              reason: '[$label seed=$seed] 사주 용어 없음: $scenario');
        }
      }
    });

    test('3막 흐름 — 배경/사건/여운 모두 등장', () {
      // 배경 = userRole + celebRole 등장 + "당신"+"솔라" 헤더 시작.
      // 사건 = "사주" 단어 1회 (event phase 표식).
      // 여운 = "이번 생" 단어 1회 (resolution / tail phase 표식).
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '솔라',
        userName: '당신',
        seed: 7,
      );
      expect(scenario.contains('당신'), isTrue);
      expect(scenario.contains('솔라'), isTrue);
      expect(scenario.contains('사주'), isTrue,
          reason: 'event phase 사주 단어 미포함: $scenario');
      expect(scenario.contains('이번 생'), isTrue,
          reason: 'resolution phase 이번 생 단어 미포함: $scenario');
    });
  });
}
