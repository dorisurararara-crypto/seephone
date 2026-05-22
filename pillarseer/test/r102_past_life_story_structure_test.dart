// R102 → R104 — 전생 시나리오 구조 가드.
//
// 이력:
//   R102: body_lines 4 phase (setup/event/turn/resolution) slot 풀 구조.
//   R104: story arc 단위 단일 선택 — arc 하나가 4문단(기/승/전/결) 완결 단편.
//
// R104 sprint 3 변경:
//   - story_arcs 가 있으면 4문단 8~10문장, fallback 이면 R103 7~14 허용.
//   - 기존 slot 키(body_lines 4 phase)는 fallback 용도로 잔존 — 하위호환
//     가드로 "존재" 만 확인하고, 크기 강제는 유지(아직 slot fallback 이 실제로
//     쓰이므로 회귀 가드). story_arcs schema 검증은 r104_past_life_arc_test 로 분리.
//   - keyword extraction / 사주 용어 등장 / 기승전결 흐름 같은 무관 회귀 가드는 보존.

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

  bool hasStoryArcs(String keywordId) {
    final sa = pool['story_arcs'];
    if (sa is! Map) return false;
    final arcs = sa[keywordId];
    return arcs is List && arcs.isNotEmpty;
  }

  // R108 ② — 장편(longform) keyword 판정. 장편 관계는 의도된 완결 장편
  // 서사라 slot 기준 문장 수(8~10/7~14)·사주 용어 등장 가드가 적용되지
  // 않는다(design doc: "사주 해석 단정 불필요"). 장편 본문 구조 가드는
  // r108_past_life_longform_test.dart 가 전담한다.
  bool isLongformKeyword(String keywordId) {
    final sa = pool['story_arcs'];
    if (sa is! Map) return false;
    final arcs = sa[keywordId];
    if (arcs is! List || arcs.isEmpty) return false;
    final first = arcs.first;
    return first is Map && first['format'] == 'longform';
  }

  int sentenceCount(String s) =>
      s.split(RegExp(r'[.!?]\s*')).where((e) => e.trim().isNotEmpty).length;

  group('R104 — slot fallback body_lines 4 phase (하위호환 가드)', () {
    test('8 키워드 모두 setup/event/turn/resolution 4 phase 존재 (slot fallback)', () {
      // story_arcs 가 모든 keyword 를 덮으면 slot 은 안 쓰이지만, schema 정리는
      // 별도 round 로 미뤄 slot 키는 보존(삭제 금지). fallback 안전망으로 유지.
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
          expect(m[phase], isA<List>(), reason: '$k.$phase 누락 또는 List 아님');
          expect(
            (m[phase] as List).length,
            greaterThanOrEqualTo(12),
            reason: '$k.$phase variant < 12 (got ${(m[phase] as List).length})',
          );
        }
      }
    });
  });

  group('R104 — scenario 흐름 / 사주 용어 등장', () {
    // 사주 용어 stopword pool — 본문이 이 중 하나를 포함해야 함.
    const sajuTerms = <String>[
      '원진살',
      '도화살',
      '역마살',
      '천을귀인',
      '공망',
      '합 결',
      '충 결',
      '형 결',
      '도화 결',
      '역마 결',
      '공망 결',
      '천을귀인 결',
      '원진살이',
      '도화살이',
      '사주상',
      '사주에',
    ];

    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      // R107 #9-1: 戊子+戊戌 은 합·충·공망 어느 것도 매칭 0 → neutral fallback.
      //   종전엔 거짓 hap fallback ("합 결") 으로 우연히 통과했었음.
      //   이제 정직하게 neutral keyword 로 분류된다. neutral 시나리오는
      //   거짓 살(煞) 단정을 안 하므로 saju-jargon 가 아닌 "사주" 단어로 가드.
      ('neutral', () => mk('子'), () => mk('戌')),
    ];

    test('시나리오 문장 수 (arc 8~10 / fallback 7~14) + 사주 용어 1회 이상', () {
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        if (isLongformKeyword(label)) continue; // 장편은 slot 문장 수 대상 아님.
        // R104 arc mode 면 8~10, fallback 이면 R103 호환 7~14 허용.
        final arcMode = hasStoryArcs(label);
        final lo = arcMode ? 8 : 7;
        final hi = arcMode ? 10 : 14;
        for (var seed = 0; seed < 5; seed++) {
          final scenario = PastLifeService.generateScenario(
            user: mkU(),
            celeb: mkC(),
            celebName: '솔라',
            userName: '당신',
            seed: seed,
          );
          final n = sentenceCount(scenario);
          expect(
            n,
            inInclusiveRange(lo, hi),
            reason:
                '[$label seed=$seed mode=${arcMode ? "arc" : "slot"}] '
                '문장 수 $n 범위 밖. body=$scenario',
          );
          // 사주 용어는 arc/fallback 양쪽에서 1회 이상이어야 함 (회귀 가드).
          // R107 #9-1: neutral 은 거짓 살(煞) 단정을 안 하는 정직한 keyword 라
          //   jargon 대신 "사주" 단어 포함만 확인 (거짓말 0 보장).
          if (label == 'neutral') {
            expect(
              scenario.contains('사주'),
              isTrue,
              reason: '[$label seed=$seed] "사주" 단어 없음: $scenario',
            );
          } else {
            final hasTerm = sajuTerms.any((t) => scenario.contains(t));
            expect(
              hasTerm,
              isTrue,
              reason: '[$label seed=$seed] 사주 용어 없음: $scenario',
            );
          }
        }
      }
    });

    test('기승전결 흐름 — 배경/사건/여운 모두 등장', () {
      // 배경 = 이름 inject 등장. 사건 = "사주" 단어. 여운 = "이번 생" / "지금 생"류.
      // R108 ② — 이 가드는 slot fallback 의 기승전결 구조를 검증한다. 장편화된
      // 관계는 더 이상 slot 사주-용어 단정을 안 하므로(design doc), 아직 slot 인
      // keyword 로 검사한다. Sprint 4 에서 chung 장편화로 yeokma(子-寅) 쌍으로
      // 교체했으나, Sprint 7 에서 yeokma 도 장편화 — 아직 slot 인 neutral
      // (戊子+戊戌, 합·충·공망 매칭 0) 쌍으로 재교체. 장편 구조 가드는
      // r108_past_life_longform_test.dart 가 전담.
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('戌'),
        celebName: '솔라',
        userName: '당신',
        seed: 7,
      );
      expect(scenario.contains('당신'), isTrue);
      expect(scenario.contains('솔라'), isTrue);
      expect(
        scenario.contains('사주'),
        isTrue,
        reason: '사건 단계 사주 단어 미포함: $scenario',
      );
      // resolution(결) 표식 — _capRepetition 이 "이번 생" 을 변형할 수 있으므로
      // 변형 alt("지금 생"/"오늘의 생"/"여기 이 생"/"이쪽 생") 도 허용.
      final hasResolutionMarker =
          scenario.contains('이번 생') ||
          scenario.contains('지금 생') ||
          scenario.contains('오늘의 생') ||
          scenario.contains('여기 이 생') ||
          scenario.contains('이쪽 생');
      expect(
        hasResolutionMarker,
        isTrue,
        reason: '결(여운) 단계 "이번 생"류 단어 미포함: $scenario',
      );
    });
  });
}
