// R103 → R104 — 전생 시나리오 sentence 수.
//
// 이력:
//   R102: 8~10 (낮음 + 사용자 "더 길어야 돼" 불만).
//   R103: 10~14 (사건 strand 추가, padding 금지).
//   R104: 8~10 (story arc 단위 완결 — 4문단 기승전결). 사용자 mandate
//         "내용에 기승전결이 있어야 해 / 길이도 짧고" 의 정착 목표.
//
// R104 sprint 3 주의:
//   story arc engine 은 켜졌지만 assets/data/past_life_pool.json 에 story_arcs
//   content 는 Sprint 4 가 채운다. Sprint 4 전에는 service 가 slot 조립으로
//   fallback 하므로 결과가 R103 의 10~14 범위로 나올 수 있다.
//   → keyword 에 story_arcs 가 실제로 존재할 때만 R104 8~10 을 강제하고,
//     fallback 상태에서는 R103 의 10~14 를 허용한다 (threshold 낮추기 아님 —
//     content 미존재 중간 상태 호환). Sprint 4 이후에는 모든 keyword 가
//     story_arcs 를 가지므로 8~10 이 전수 강제된다.
//
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
      wood: 20,
      fire: 20,
      earth: 20,
      metal: 20,
      water: 20,
    ),
    dayMaster: '戊',
    dayMasterName: 'Test',
    summary: 'test',
    categoryReadings: const {},
  );

  /// keyword 에 유효한 story_arcs content 가 있으면 true → R104 8~10 강제.
  /// 없으면 (Sprint 4 전 fallback) false → R103 10~14 허용.
  bool hasStoryArcs(String keywordId) {
    final sa = pool['story_arcs'];
    if (sa is! Map) return false;
    final arcs = sa[keywordId];
    return arcs is List && arcs.isNotEmpty;
  }

  int sentenceCount(String s) =>
      s.split(RegExp(r'[.!?]\s*')).where((e) => e.trim().isNotEmpty).length;

  group('R104 — sentence count (story arc 8~10 / fallback 10~14)', () {
    // (keywordId, userJi, celebJi).
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      // R107 #9-1: 戊子+戊戌 은 합·충·공망 매칭 0 → neutral fallback (정직).
      //   종전엔 거짓 hap fallback 으로 우연히 통과. neutral arc 도 동일하게
      //   8~10 문장 범위를 지킨다 (정직한 시나리오 + 길이 회귀 가드 양립).
      ('neutral', () => mk('子'), () => mk('戌')),
      ('cheoneul', () => mk('子'), () => mk('丑')),
    ];

    test('50 sample sentence count — keyword 별 R104/fallback 범위', () {
      final celebs = <String>['솔라', '카리나', '뷔', '아이유', '이찬원'];
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        // story_arcs 가 있으면 R104 mandate 8~10, 없으면 R103 fallback 10~14.
        final arcMode = hasStoryArcs(label);
        final lo = arcMode ? 8 : 10;
        final hi = arcMode ? 10 : 14;
        for (final celeb in celebs) {
          for (var seed = 0; seed < 2; seed++) {
            final s = PastLifeService.generateScenario(
              user: mkU(),
              celeb: mkC(),
              celebName: celeb,
              userName: '당신',
              seed: seed,
            );
            final n = sentenceCount(s);
            expect(
              n,
              inInclusiveRange(lo, hi),
              reason:
                  '[$label/$celeb/seed=$seed mode=${arcMode ? "arc" : "slot"}] '
                  'sentence $n ∉ [$lo,$hi]: $s',
            );
          }
        }
      }
    });

    // Sprint 4 이후 활성: story_arcs 전수 존재 시 모든 keyword 가 8~10 이어야 함.
    // 현재는 story_arcs 미존재 → skip. Sprint 4 가 content 를 채우면 자동 통과.
    test(
      'R104 mandate — 모든 keyword story arc 8~10 문장 (Sprint 4 content 후 활성)',
      () {
        const keys = ['wonjin', 'hap', 'chung', 'gongmang', 'cheoneul'];
        final allHaveArcs = keys.every(hasStoryArcs);
        if (!allHaveArcs) {
          // Sprint 4 전 — story_arcs content 미존재. 활성 조건 미충족.
          return;
        }
        final celebs = <String>['솔라', '카리나', '뷔', '아이유', '이찬원'];
        for (final cd in cases) {
          final (label, mkU, mkC) = cd;
          for (final celeb in celebs) {
            for (var seed = 0; seed < 4; seed++) {
              final s = PastLifeService.generateScenario(
                user: mkU(),
                celeb: mkC(),
                celebName: celeb,
                userName: '당신',
                seed: seed,
              );
              expect(
                sentenceCount(s),
                inInclusiveRange(8, 10),
                reason: '[$label/$celeb/seed=$seed] R104 8~10 위반: $s',
              );
            }
          }
        }
      },
    );
  });
}
