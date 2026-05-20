// R104 sprint 3 — 전생 본문 story arc 엔진 가드.
//
// 전환 mandate (사용자 verbatim, codex 두뇌 경유):
//   "내용에 기승전결이 있어야 해 / 너무 ai같고 재미없어 / 길이도 짧고"
//
// R104 엔진 = slot 랜덤 조립 → keyword × story arc 단일 선택.
//   - arc 하나가 원인→사건→전환→이번 생 punchline 의 완결 단편.
//   - paragraphs gi/seung/jeon/gyeol 4문단 + modernPunchlineByKind[kind].
//   - 목표 4문단 8~10문장. seed deterministic.
//
// 본 파일은 story_arcs parser shape 검증을 in-memory fixture 로 한다 (assets
// content 가 Sprint 4 전이라 없어도 통과). 실제 assets story_arcs content
// count 강제는 마지막 group 에서 story_arcs 가 채워진 뒤 자동 활성화된다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── helpers ─────────────────────────────────────────────────────────
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

  int sentenceCount(String s) =>
      s.split(RegExp(r'[.!?]\s*')).where((e) => e.trim().isNotEmpty).length;

  /// gi/seung/jeon/gyeol + kind punchline 으로 8~10문장 target arc 한 개.
  /// 각 문단이 2~3문장을 담아 4문단 합 8~10문장이 되도록 작성.
  Map<String, dynamic> arc({
    required String id,
    String userRole = '몰락한 귀족',
    String celebRole = '떠돌이 악사',
    List<String> eraHints = const ['조선 후기'],
  }) {
    return {
      'id': id,
      'tone': 'bittersweet',
      'userRole': userRole,
      'celebRole': celebRole,
      'eraHints': eraHints,
      'paragraphs': {
        'gi':
            r'$era, $userName은 $userRole였어요. '
            r'$celebName은 $celebRole였고, 둘은 시장 골목에서 처음 마주쳤어요.',
        'seung':
            r'사주에 박힌 원진살이 둘을 한 줄에 묶었어요. '
            r'$userName은 $celebName의 노래를 매일 들으러 갔어요.',
        'jeon':
            r'어느 밤 $celebName이 도성을 떠나야 했어요. '
            r'$userName은 끝내 붙잡지 못했어요.',
        'gyeol':
            r'그 미움과 끌림이 이번 생까지 따라왔어요. '
            r'$userName은 다시 $celebName을 알아봤어요.',
      },
      'modernPunchlineByKind': {
        'idol': r'그래서 $celebName의 앨범을 또 사고 있는 거예요.',
        'actor': r'그래서 $celebName이 나오는 작품을 다 챙겨 보는 거예요.',
        'athlete': r'그래서 $celebName의 경기를 한 경기도 놓치지 않는 거예요.',
        'icon': r'그래서 $celebName을 오래 응원하게 된 거예요.',
      },
    };
  }

  /// story_arcs 를 포함한 in-memory pool fixture.
  ///
  /// json.decode(json.encode(...)) round-trip 으로 모든 nested map 을
  /// `Map<String, dynamic>` 로 정규화 — 실제 assets 로드(rootBundle + json.decode)
  /// 와 동일한 타입 형태가 되어 slot fallback 의 cast 와도 호환된다.
  ///
  /// slot 키(templates/body_lines/relations 등)도 최소한으로 채워, story_arcs
  /// 미존재/invalid keyword 가 slot fallback 으로 빠져도 예외 없이 동작하게 한다.
  Map<String, dynamic> fixturePool({
    required Map<String, List<Map<String, dynamic>>> storyArcs,
  }) {
    final slotBody = <String, dynamic>{
      'setup': [r'$userName과 $celebName의 전생이 시작됐어요.'],
      'event': ['깊은 결이 사주에 흘렀어요.'],
      'event_sub': ['어느 밤 작은 쪽지가 오갔어요.'],
      'turn': ['시간이 둘을 갈라놓았어요.'],
      'resolution': ['그 결의 여운이 이번 생까지 따라왔어요.'],
    };
    final slotTpl = <String, dynamic>{
      'headers': [r'$userName과 $celebName이 $era에서 처음 마주쳤어요.'],
      'intros': ['둘의 인연은 그렇게 시작됐어요.'],
      'tails': ['그래서 지금도 마음이 그쪽으로 기우는 거예요.'],
    };
    final raw = <String, dynamic>{
      '_meta': {'version': 'r104-test-fixture'},
      'eras': ['먼 옛날', '고려 시대', '조선 초기'],
      'relations': [
        {'user': '나그네', 'celeb': '벗'},
        {'user': '서생', 'celeb': '악공'},
      ],
      'endings': ['그 흐름이 지금까지 닿아 있어요.'],
      'templates': {'wonjin': slotTpl, 'dohwa': slotTpl, 'hap': slotTpl},
      'body_lines': {'wonjin': slotBody, 'dohwa': slotBody, 'hap': slotBody},
      'story_arcs': storyArcs,
    };
    // round-trip 정규화 — 모든 Map 을 Map<String, dynamic> 로.
    return json.decode(json.encode(raw)) as Map<String, dynamic>;
  }

  tearDown(() {
    PastLifeService.resetCacheForTest();
  });

  // ─── 1. parser shape — gi/seung/jeon/gyeol required ──────────────────
  group('R104 — story_arcs parser shape', () {
    test('gi/seung/jeon/gyeol 4문단 arc → story arc 경로로 본문 생성', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [arc(id: 'w1')],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'), // 子-未 원진 → primary = wonjin.
        celebName: '카리나',
        userName: '지민',
        seed: 1,
        kind: 'idol',
      );
      // arc 4문단 + punchline 이 모두 inject 됐는지.
      expect(s.contains('지민'), isTrue, reason: 'userName 미inject: $s');
      expect(s.contains('카리나'), isTrue, reason: 'celebName 미inject: $s');
      expect(s.contains('몰락한 귀족'), isTrue, reason: 'arc userRole 미inject: $s');
      expect(s.contains('떠돌이 악사'), isTrue, reason: 'arc celebRole 미inject: $s');
      expect(s.contains('조선 후기'), isTrue, reason: 'eraHints \$era 미inject: $s');
      expect(s.contains('앨범'), isTrue, reason: 'idol punchline 미append: $s');
      // placeholder 잔존 0.
      expect(s.contains(r'$'), isFalse, reason: 'placeholder 잔존: $s');
    });

    test('gyeol 누락 arc → invalid 처리 후 slot fallback (앱 안 깨짐)', () {
      // gyeol 이 없는 invalid arc 만 있는 keyword → _selectStoryArc null →
      // slot 조립 fallback. fixture slot 풀은 비어 있으므로 hard fallback 류
      // 최소 문장이라도 안전하게 반환되어야 한다 (예외 X).
      final brokenArc = arc(id: 'broken');
      (brokenArc['paragraphs'] as Map).remove('gyeol');
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [brokenArc],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      // 예외 없이 String 을 반환해야 함.
      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
      );
      expect(s, isA<String>());
      expect(s.trim(), isNotEmpty);
    });

    test('story_arcs 없는 keyword → slot fallback (중간 상태 안전)', () {
      // story_arcs 에 dohwa 만 있고 wonjin 은 없음 → wonjin 은 slot fallback.
      final pool = fixturePool(
        storyArcs: {
          'dohwa': [arc(id: 'd1')],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'), // wonjin primary — story_arcs 에 없음.
        celebName: '카리나',
        userName: '지민',
        seed: 1,
      );
      expect(s, isA<String>());
      expect(s.trim(), isNotEmpty);
    });
  });

  // ─── 2. kind punchline fallback ──────────────────────────────────────
  group('R104 — kind punchline fallback', () {
    test('athlete kind 지원 — athlete punchline 사용', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [arc(id: 'w1')],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '손흥민',
        userName: '지민',
        seed: 1,
        kind: 'athlete',
      );
      expect(s.contains('경기'), isTrue, reason: 'athlete punchline 미사용: $s');
    });

    test('unknown kind → icon punchline fallback', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [arc(id: 'w1')],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
        kind: 'comedian', // schema 에 없는 kind.
      );
      expect(
        s.contains('응원하게 된 거예요'),
        isTrue,
        reason: 'unknown kind → icon fallback 실패: $s',
      );
    });

    test('kind 미명시 → 기본값 icon punchline', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [arc(id: 'w1')],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
        // kind 인자 생략.
      );
      expect(s.contains('응원하게 된 거예요'), isTrue, reason: 'kind 기본값 icon 미적용: $s');
    });

    test('punchline 의 특정 kind 키가 비면 icon 으로 fallback', () {
      final a = arc(id: 'w1');
      (a['modernPunchlineByKind'] as Map)['athlete'] = '';
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [a],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '손흥민',
        userName: '지민',
        seed: 1,
        kind: 'athlete', // athlete 키가 빈 문자열 → icon fallback.
      );
      expect(
        s.contains('응원하게 된 거예요'),
        isTrue,
        reason: '빈 punchline 키 → icon fallback 실패: $s',
      );
    });
  });

  // ─── 3. seed deterministic arc selection ─────────────────────────────
  group('R104 — seed deterministic arc selection', () {
    test('같은 seed → 같은 arc / 같은 본문', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [
            arc(id: 'a', userRole: '몰락한 귀족'),
            arc(id: 'b', userRole: '궁중 화공'),
            arc(id: 'c', userRole: '변방 군관'),
            arc(id: 'd', userRole: '저잣거리 약초꾼'),
            arc(id: 'e', userRole: '필사 서생'),
            arc(id: 'f', userRole: '나루터 사공'),
          ],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      String gen(int seed) => PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '지민',
        seed: seed,
      );
      expect(gen(7), equals(gen(7)));
      expect(gen(123), equals(gen(123)));
    });

    test('다른 seed → arc 선택 변동 (variance ≥ 3종 / 10 seed)', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [
            arc(id: 'a', userRole: '몰락한 귀족'),
            arc(id: 'b', userRole: '궁중 화공'),
            arc(id: 'c', userRole: '변방 군관'),
            arc(id: 'd', userRole: '저잣거리 약초꾼'),
            arc(id: 'e', userRole: '필사 서생'),
            arc(id: 'f', userRole: '나루터 사공'),
          ],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      final seen = <String>{};
      for (var seed = 0; seed < 10; seed++) {
        final s = PastLifeService.generateScenario(
          user: mk('子'),
          celeb: mk('未'),
          celebName: '카리나',
          userName: '지민',
          seed: seed,
        );
        seen.add(s);
      }
      expect(
        seen.length,
        greaterThanOrEqualTo(3),
        reason: 'arc 선택 variance 부족: ${seen.length}종 / 10 seed',
      );
    });
  });

  // ─── 4. 8~10 sentence target helper ──────────────────────────────────
  group('R104 — 8~10 sentence target', () {
    test('4문단 arc + punchline → 8~10문장', () {
      final pool = fixturePool(
        storyArcs: {
          'wonjin': [arc(id: 'w1')],
        },
      );
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);

      for (final kind in ['idol', 'actor', 'athlete', 'icon']) {
        final s = PastLifeService.generateScenario(
          user: mk('子'),
          celeb: mk('未'),
          celebName: '카리나',
          userName: '지민',
          seed: 1,
          kind: kind,
        );
        final n = sentenceCount(s);
        expect(
          n,
          inInclusiveRange(8, 10),
          reason: '[kind=$kind] story arc 문장 $n ∉ [8,10]: $s',
        );
      }
    });
  });

  // ─── 5. assets story_arcs content count (Sprint 4 content 후 활성) ────
  group('R104 — assets story_arcs content (Sprint 4 가 채운 뒤 활성)', () {
    late Map<String, dynamic> assetsPool;
    setUpAll(() async {
      final f = File('assets/data/past_life_pool.json');
      assetsPool = json.decode(await f.readAsString()) as Map<String, dynamic>;
    });

    const keywordIds = <String>[
      'wonjin',
      'dohwa',
      'yeokma',
      'cheoneul',
      'gongmang',
      'hap',
      'chung',
      'hyeong',
    ];

    test(
      'assets story_arcs — 8 keyword 모두 arc ≥ 6, 목표 8 [Sprint 4 content 후 활성]',
      () {
        final sa = assetsPool['story_arcs'];
        if (sa is! Map) {
          // Sprint 4 전 — story_arcs 키 미존재. 게이트 미활성.
          return;
        }
        for (final k in keywordIds) {
          final arcs = sa[k];
          expect(
            arcs,
            isA<List>(),
            reason: 'assets story_arcs[$k] 누락 또는 List 아님',
          );
          final list = arcs as List;
          expect(
            list.length,
            greaterThanOrEqualTo(6),
            reason: 'assets story_arcs[$k] ${list.length}개 < 6 (R104 최소)',
          );
          // 목표 8 — 미달 시 reason 으로 명시 (강제는 ≥6, 경고 수준 8).
          if (list.length < 8) {
            // ignore: avoid_print
            print('[R104] story_arcs[$k] ${list.length}개 — 목표 8 미달');
          }
        }
      },
    );

    test('assets story_arcs — 각 arc shape 무결성 [Sprint 4 content 후 활성]', () {
      final sa = assetsPool['story_arcs'];
      if (sa is! Map) {
        return; // Sprint 4 전.
      }
      sa.forEach((k, arcs) {
        final list = arcs as List;
        for (var i = 0; i < list.length; i++) {
          final a = list[i] as Map;
          // id 유니크 (keyword 내).
          expect(a['id'], isA<String>(), reason: '$k arc[$i] id 누락');
          // paragraphs 4문단.
          final p = a['paragraphs'] as Map;
          for (final phase in ['gi', 'seung', 'jeon', 'gyeol']) {
            expect(
              p[phase],
              isA<String>(),
              reason: '$k arc[$i].$phase 누락 또는 string 아님',
            );
            // paragraphs 는 배열 금지 — string 만.
            expect(
              p[phase],
              isNot(isA<List>()),
              reason: '$k arc[$i].$phase 가 배열 (배열 금지)',
            );
          }
          // kind punchline 4종.
          final punch = a['modernPunchlineByKind'] as Map;
          for (final kind in ['idol', 'actor', 'athlete', 'icon']) {
            expect(
              punch[kind],
              isA<String>(),
              reason: '$k arc[$i] punchline.$kind 누락',
            );
          }
        }
        // id 유니크성.
        final ids = list.map((a) => (a as Map)['id']).toList();
        expect(
          ids.toSet().length,
          equals(ids.length),
          reason: '$k story_arcs id 중복',
        );
      });
    });
  });
}
