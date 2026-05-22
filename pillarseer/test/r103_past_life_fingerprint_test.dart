// R103 sprint 1 — fingerprint diversity 가드.
//
// 사용자 mandate "다 똑같다" 직발. 50 sample (10 셀럽 × 5 seed) 기준:
//   1) first sentence unique ratio   ≥ 0.92
//   2) first-3 sentence unique ratio ≥ 0.90
//   3) full body unique ratio        ≥ 0.96
//   4) 같은 셀럽 5 seed 안에서 동일 핵심 직업/장소 반복 ≤ 1
//
// R108 ② Sprint 2 — 장편(longform) 마이그레이션 대응:
//   이 테스트의 표본 사주(子-未)는 wonjin 관계를 낳는다. wonjin 이 장편으로
//   집필되면서, 한 관계는 deterministic 한 8 arc 풀에서 seed 로 1편을 고른다.
//   장편은 slot 셔플이 아니라 의도된 완결 서사이므로, 같은 arc 가 뽑히면 첫
//   문장이 동일하다 — 구 slot 기준(첫 문장 50종)은 장편과 양립 불가.
//   따라서 결과가 장편이면, "셔플 문장 다양성" 대신 "장편답게 동작하는지"
//   (장편 플래그 / 본문은 셀럽명 주입으로 sample 별 유일 / arc 풀에서 복수
//   작품이 실제로 노출) 를 검증한다. 구 slot 관계는 종전 기준을 그대로 유지.

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

    // 표본 사주(子-未)가 장편 관계인지 1회 판정 — 장편이면 longform 분기.
    Future<bool> sampleIsLongform() async {
      final r = await PastLifeService.generate(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '당신',
        seed: 0,
      );
      return r.isLongform;
    }

    test('first sentence / first-3 / body unique ratio', () async {
      // 사용자가 실제 보는 fingerprint — 셀럽 이름 보존 (user 자체가 같은 사람이므로
      // '당신' 만 고정, celeb 은 그대로). 사용자 mandate "다 똑같다" 검증.
      final firstFps = <String>{};
      final first3Fps = <String>{};
      final bodyFps = <String>{};
      final arcTitles = <String>{};
      final celebArcPairs = <String>{};
      var total = 0;
      final longform = await sampleIsLongform();

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
          if (longform) {
            final r = await PastLifeService.generate(
              user: mk('子'),
              celeb: mk('未'),
              celebName: celeb,
              userName: '당신',
              seed: seed,
            );
            if (r.title.trim().isNotEmpty) {
              arcTitles.add(r.title);
              celebArcPairs.add('$celeb|${r.title}');
            }
          }
        }
      }

      expect(total, 50);
      final bodyRatio = bodyFps.length / total;

      if (longform) {
        // 장편 관계 — 본문은 (셀럽 × arc) 조합 하나당 한 편. deterministic 한
        // 8 arc 풀에서 seed 가 1편을 고르므로, 같은 셀럽이 같은 arc 를 거듭
        // 뽑으면 본문이 동일하다(의도된 완결 서사 — slot 셔플 아님). 따라서
        // "본문 50종" 대신 "서로 다른 (셀럽,arc) 조합 = 서로 다른 본문"
        // (셀럽명·arc 가 다르면 본문도 달라야 함) 과 "arc 풀에서 복수 작품
        // ≥3편 노출" 을 검증한다.
        // ignore: avoid_print
        print('R103 fingerprint(longform) — body=${bodyFps.length} '
            'celebArcPairs=${celebArcPairs.length} '
            'arcTitles=${arcTitles.length}');
        expect(bodyFps.length, celebArcPairs.length,
            reason: '장편 본문 종수 != (셀럽,arc) 조합 종수 — 본문 변별 깨짐 '
                '(body=${bodyFps.length} pairs=${celebArcPairs.length})');
        expect(arcTitles.length, greaterThanOrEqualTo(3),
            reason: '장편 arc 풀에서 노출된 작품 <3종 (got ${arcTitles.length})');
      } else {
        final firstRatio = firstFps.length / total;
        final first3Ratio = first3Fps.length / total;
        // ignore: avoid_print
        print('R103 fingerprint — first=$firstRatio '
            'first3=$first3Ratio body=$bodyRatio');
        expect(firstRatio, greaterThanOrEqualTo(0.92),
            reason: 'first sentence unique < 0.92 (got $firstRatio)');
        expect(first3Ratio, greaterThanOrEqualTo(0.90),
            reason: 'first-3 sentence unique < 0.90 (got $first3Ratio)');
        expect(bodyRatio, greaterThanOrEqualTo(0.96),
            reason: 'body unique < 0.96 (got $bodyRatio)');
      }
    });

    test('같은 셀럽 5 seed 안 — 동일 첫 문장 ≤ 2회 (즉 ≥ 3종)', () async {
      final longform = await sampleIsLongform();
      // 장편 관계는 deterministic 한 8 arc 풀에서 seed 로 1편을 고르므로,
      // 같은 셀럽 5 seed 가 같은 arc 를 다수 골라 첫 문장이 겹칠 수 있다(의도된
      // 완결 서사 — 셔플 아님). 장편이면 이 slot 기준 가드는 skip 한다.
      if (longform) return;
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
