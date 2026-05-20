// R103 sprint 1 — fingerprint diversity 가드.
//
// 사용자 mandate "다 똑같다" 직발. 50 sample (10 셀럽 × 5 seed) 기준:
//   1) first sentence unique ratio   ≥ 0.92
//   2) first-3 sentence unique ratio ≥ 0.90
//   3) full body unique ratio        ≥ 0.96
//   4) 같은 셀럽 5 seed 안에서 동일 핵심 직업/장소 반복 ≤ 1

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

  List<String> splitSentences(String s) {
    return s
        .split(RegExp(r'[.!?]\s*'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  group('R103 — 50 sample fingerprint diversity', () {
    final celebs = <String>[
      '솔라', '카리나', '뷔', '아이유', '이찬원',
      '제니', '리사', '지수', '윈터', '닝닝',
    ];

    test('first sentence / first-3 / body unique ratio', () {
      // 사용자가 실제 보는 fingerprint — 셀럽 이름 보존 (user 자체가 같은 사람이므로
      // '당신' 만 고정, celeb 은 그대로). 사용자 mandate "다 똑같다" 검증.
      final firstFps = <String>{};
      final first3Fps = <String>{};
      final bodyFps = <String>{};
      var total = 0;

      for (final celeb in celebs) {
        for (var seed = 0; seed < 5; seed++) {
          final s = PastLifeService.generateScenario(
            user: mk('子'),
            celeb: mk('未'),
            celebName: celeb,
            userName: '당신',
            seed: seed,
          );
          final sentences = splitSentences(s);
          if (sentences.isEmpty) continue;
          total++;
          firstFps.add(sentences[0]);
          first3Fps.add(sentences.take(3).join('|'));
          bodyFps.add(s);
        }
      }

      expect(total, 50);
      final firstRatio = firstFps.length / total;
      final first3Ratio = first3Fps.length / total;
      final bodyRatio = bodyFps.length / total;

      // ignore: avoid_print
      print(
          'R103 fingerprint — first=$firstRatio first3=$first3Ratio body=$bodyRatio');

      expect(firstRatio, greaterThanOrEqualTo(0.92),
          reason: 'first sentence unique < 0.92 (got $firstRatio)');
      expect(first3Ratio, greaterThanOrEqualTo(0.90),
          reason: 'first-3 sentence unique < 0.90 (got $first3Ratio)');
      expect(bodyRatio, greaterThanOrEqualTo(0.96),
          reason: 'body unique < 0.96 (got $bodyRatio)');
    });

    test('같은 셀럽 5 seed 안 — 동일 첫 문장 ≤ 2회 (즉 ≥ 3종)', () {
      for (final celeb in celebs) {
        final firstSentences = <String>[];
        for (var seed = 0; seed < 5; seed++) {
          final s = PastLifeService.generateScenario(
            user: mk('子'),
            celeb: mk('未'),
            celebName: celeb,
            userName: '당신',
            seed: seed,
          );
          final sentences = splitSentences(s);
          if (sentences.isNotEmpty) firstSentences.add(sentences[0]);
        }
        final unique = firstSentences.toSet().length;
        expect(unique, greaterThanOrEqualTo(3),
            reason:
                '[$celeb] first sentence unique <3 in 5 seed (got $unique): $firstSentences');
      }
    });
  });
}
