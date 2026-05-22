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

  // R108 ② sprint 8 — 66 arc 전수 longform 완결로 hasStoryArcs/isLongformKeyword
  // 분기가 더는 필요 없어졌다(모든 관계 arc 가 longform). slot arc 기승전결
  // 구조 가드는 아래 'slot arc 기승전결 흐름' group 이 합성 fixture 로 전담.

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

  // R108 ② sprint 8 — 한국어 66 arc 전수 longform 완결. assets 의 모든 관계
  // arc 가 format:"longform" 이 되어, slot 비-longform(_composeFromStoryArc 의
  // paragraphs 경로 / _composeFromPool) 을 trigger 하는 실관계 arc 가 0이 됐다.
  // 그러나 slot-fallback 경로 자체는 코드에 남아 있고(중간 상태·미집필 arc 안전망),
  // 그 기승전결 구조 가드의 설계 의도는 보존해야 한다. 따라서 아래 group 은
  // assets 실관계 대신, in-memory 합성(synthetic) 비-longform story_arc 를
  // seed 해 slot arc 경로(_composeFromStoryArc paragraphs)를 직접 검증한다.
  // (R104 sprint 3 의 의도 = arc 하나가 4문단 기/승/전/결 완결 단편.)
  group('R104 — slot arc 기승전결 흐름 (synthetic 비-longform fixture)', () {
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

    // 비-longform(구 schema) story_arc — paragraphs 4문단(기/승/전/결) +
    // modernPunchlineByKind 4종. format 키 없음 → _composeFromStoryArc 의
    // paragraphs 경로를 탄다. 본문에 사주 용어 + 결(여운) 표식을 심어, slot
    // arc 기승전결 구조 가드를 그대로 enforce 한다.
    Map<String, dynamic> slotArc(String id) => {
      'id': id,
      'userRole': '몰락한 귀족',
      'celebRole': '떠돌이 악사',
      'eraHints': ['조선 후기 한양'],
      'paragraphs': {
        'gi': r'$era, $userName은 $userRole였고 $celebName은 $celebRole였어요. '
            r'두 사람의 사주에 원진살이 박혀 있었어요.',
        'seung': r'사주상 원진살이 둘을 묶었어요. $userName은 어느 새벽 '
            r'$celebName에게 쪽지 한 장을 건넸어요.',
        'jeon': r'$celebName이 먼 길을 떠나야 했고 $userName은 끝내 못 '
            r'붙잡았어요. 그날의 발길이 오래 마음에 남았어요.',
        'gyeol': r'그 원진살의 결이 이번 생까지 흘러왔어요. $userName은 '
            r'$celebName을 한눈에 알아봤어요.',
      },
      'modernPunchlineByKind': {
        'idol': r'그래서 $userName은 $celebName 무대를 또 챙겨 봐요.',
        'actor': r'그래서 $userName은 $celebName 작품을 다 챙겨 봐요.',
        'athlete': r'그래서 $userName은 $celebName 경기를 다 챙겨 봐요.',
        'icon': r'그래서 $userName은 $celebName을 응원하게 된 거예요.',
      },
    };

    // slot arc fixture pool — story_arcs 에 wonjin 만 비-longform 으로 둔다.
    // 子-未 쌍이 wonjin primary 로 매핑돼, 이 합성 arc 경로를 탄다.
    Map<String, dynamic> slotFixturePool() {
      final raw = <String, dynamic>{
        '_meta': {'version': 'r108-test'},
        'eras': ['먼 옛날'],
        'relations': [
          {'user': '나그네', 'celeb': '벗'},
        ],
        'endings': ['그 흐름이 닿아 있어요.'],
        'templates': {
          'wonjin': {
            'intros': ['그렇게 시작됐어요.'],
            'tails': ['그래서 그래요.'],
            'headers': [r'$userName과 $celebName이 $era에서 만났어요.'],
          },
        },
        'body_lines': {
          'wonjin': {
            'setup': [r'$userName과 $celebName의 전생.'],
            'event': ['깊은 결이 흘렀어요.'],
            'turn': ['갈라놓았어요.'],
            'resolution': ['여운이 따라왔어요.'],
          },
        },
        'story_arcs': {
          'wonjin': [slotArc('wonjin_01')],
        },
      };
      return json.decode(json.encode(raw)) as Map<String, dynamic>;
    }

    setUp(() {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(slotFixturePool());
    });

    tearDown(() {
      // 다른 group 이 실 assets pool 을 쓰도록 복원.
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);
    });

    test('slot arc — 4문단 8~10문장 + 사주 용어 1회 이상', () {
      for (var seed = 0; seed < 5; seed++) {
        final scenario = PastLifeService.generateScenario(
          user: mk('子'),
          celeb: mk('未'),
          celebName: '솔라',
          userName: '당신',
          seed: seed,
        );
        final n = sentenceCount(scenario);
        expect(
          n,
          inInclusiveRange(8, 10),
          reason: '[slot arc seed=$seed] 문장 수 $n 범위 밖. body=$scenario',
        );
        final hasTerm = sajuTerms.any((t) => scenario.contains(t));
        expect(
          hasTerm,
          isTrue,
          reason: '[slot arc seed=$seed] 사주 용어 없음: $scenario',
        );
      }
    });

    test('기승전결 흐름 — 배경/사건/여운 모두 등장', () {
      // 배경 = 이름 inject 등장. 사건 = "사주" 단어. 여운 = "이번 생" / "지금 생"류.
      // R108 ② sprint 8 — 66 arc 전수 longform 화로 slot 실관계 표본이 0이 돼,
      // 이 가드를 합성 비-longform story_arc fixture 로 마이그레이션했다.
      // 검증 의도(slot arc 의 기승전결 4문단 구조)는 그대로 보존된다. 장편
      // 구조 가드는 r108_past_life_longform_test.dart 가 전담.
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
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
