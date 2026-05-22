// R108 ② — 전생 스토리 인터넷소설 장편화 가드.
//
// Sprint 0 인프라:
//   - past_life_pool.json 의 story_arcs 각 arc 가 longform 메타
//     (relation/genre/era/title/logline/estReadMinutes) 를 추가로 가진다.
//   - 집필이 끝난 관계의 arc 에는 format:"longform" + chapters[] + epilogue 가
//     붙어 service 가 장편 경로(_composeLongform)로 라우팅한다.
//   - longform 본문 변수는 $userName / $celebName 2종만. 폐기 변수
//     ($era/$userRole/$celebRole) 는 longform 본문/heading/epilogue 에 0.
//   - 관계 매핑(extractKeywords/hasWonjin)·arc 선택 로직 불변.
//   - longform / 구 슬롯 양립 — 기존 paragraphs 필드 fallback 보존.
//
// 집필 완료 관계는 [longformWrittenRelations] 에 등록되며, 그 관계 arc 는
// assets 에서 format:"longform" + 분량 가드를 enforce 한다. Sprint 0 = 빈 집합.

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

  // ─── helpers ─────────────────────────────────────────────────────────

  SajuResult mk({
    required String yGan,
    required String yJi,
    required String mGan,
    required String mJi,
    required String dGan,
    required String dJi,
  }) => SajuResult(
    yearPillar: Pillar(chunGan: yGan, jiJi: yJi),
    monthPillar: Pillar(chunGan: mGan, jiJi: mJi),
    dayPillar: Pillar(chunGan: dGan, jiJi: dJi),
    hourPillar: null,
    elements: const FiveElements(
      wood: 20,
      fire: 20,
      earth: 20,
      metal: 20,
      water: 20,
    ),
    dayMaster: dGan,
    dayMasterName: 'Test',
    summary: 'test',
    categoryReadings: const {},
  );

  const keywordIds = <String>[
    'wonjin',
    'dohwa',
    'yeokma',
    'cheoneul',
    'gongmang',
    'hap',
    'chung',
    'hyeong',
    'neutral',
  ];

  // 장편 본편으로 집필 완료된 관계. 그 관계 arc 는 assets 에서 format:"longform"
  // + 분량 가드를 enforce 한다. Sprint 1 이 dohwa 8편 (5,700~8,800자, 5챕터)
  // 을, Sprint 2 가 wonjin 8편 (7,100~8,400자, 5챕터) 을, Sprint 3 이 hap
  // 8편 (7,100~8,300자, 5챕터) 을, Sprint 4 가 chung 8편 (7,900~8,700자,
  // 7챕터) 을 채움. Sprint 5~8 가 관계를 채울 때마다 추가, Sprint 10 에서
  // skip-list 제거.
  const longformWrittenRelations = <String>{
    'dohwa',
    'wonjin',
    'hap',
    'chung',
  };

  // 장편 본문 분량 floor (총 글자 수). 기존 슬롯 arc(~460자)의 10배 이상 =
  // design doc "최소 10배" mandate 충족. 집필된 dohwa 8편은 모두 5,700자 이상.
  const longformCharFloor = 5000;

  // ─── 1. longform 메타 skeleton — 66 arc 전수 ──────────────────────────
  group('R108 ② — longform 메타 skeleton', () {
    test('story_arcs 9 관계 전수 존재 + 개수 {8×8, neutral 2}', () {
      final sa = pool['story_arcs'] as Map;
      for (final k in keywordIds) {
        expect(sa[k], isA<List>(), reason: 'story_arcs[$k] 누락');
      }
      for (final k in keywordIds.where((k) => k != 'neutral')) {
        expect((sa[k] as List).length, 8, reason: 'story_arcs[$k] 8편');
      }
      expect((sa['neutral'] as List).length, 2);
    });

    test('각 arc — longform 메타 필드 전수 존재', () {
      final sa = pool['story_arcs'] as Map;
      for (final k in keywordIds) {
        for (final raw in sa[k] as List) {
          final a = raw as Map;
          final id = a['id'];
          expect(a['relation'], k, reason: '$id relation 불일치');
          expect(a['genre'], isA<String>(), reason: '$id genre 누락');
          expect((a['genre'] as String).trim(), isNotEmpty);
          expect(a['era'], isA<String>(), reason: '$id era 누락');
          expect((a['era'] as String).trim(), isNotEmpty);
          expect(a['title'], isA<String>(), reason: '$id title 누락');
          expect((a['title'] as String).trim(), isNotEmpty);
          expect(a['logline'], isA<String>(), reason: '$id logline 누락');
          expect((a['logline'] as String).trim(), isNotEmpty);
          expect(a['estReadMinutes'], isA<int>(), reason: '$id estReadMinutes');
        }
      }
    });

    test('arc id 전수 유니크 + 관계 prefix 정합', () {
      final sa = pool['story_arcs'] as Map;
      final all = <String>{};
      for (final k in keywordIds) {
        for (final raw in sa[k] as List) {
          final id = (raw as Map)['id'] as String;
          expect(all.add(id), isTrue, reason: 'arc id 중복: $id');
          expect(id.startsWith('${k}_'), isTrue, reason: '$id prefix 불일치');
        }
      }
      expect(all.length, 66);
    });

    test('longform / 구 슬롯 양립 — paragraphs fallback 필드 보존', () {
      final sa = pool['story_arcs'] as Map;
      for (final k in keywordIds) {
        for (final raw in sa[k] as List) {
          final a = raw as Map;
          final p = a['paragraphs'];
          expect(p, isA<Map>(), reason: '${a['id']} paragraphs fallback 누락');
          for (final phase in ['gi', 'seung', 'jeon', 'gyeol']) {
            expect(
              (p as Map)[phase],
              isA<String>(),
              reason: '${a['id']}.$phase fallback 누락',
            );
          }
        }
      }
      expect(pool['templates'], isA<Map>());
      expect(pool['body_lines'], isA<Map>());
      expect(pool['eras'], isA<List>());
    });

    test('_meta.version = r108-longform', () {
      expect((pool['_meta'] as Map)['version'], 'r108-longform');
    });
  });

  // ─── 2. longform 라우팅 — in-memory fixture ───────────────────────────
  // assets 에 format:"longform" arc 가 아직 없을 수 있으므로(집필 sprint 가
  // 채움) 장편 합성 경로는 fixture 로 검증한다.
  group('R108 ② — longform 합성 경로 (fixture)', () {
    Map<String, dynamic> longformArc(String id) => {
      'id': id,
      'format': 'longform',
      'relation': 'wonjin',
      'genre': '경성 모던 로맨스',
      'era': '1929 경성, 그해 겨울',
      'title': r'$userName과 $celebName의 겨울',
      'logline': '진눈깨비 날리던 경성역.',
      'estReadMinutes': 24,
      'chapters': [
        {
          'no': 1,
          'heading': '진눈깨비',
          'body': r'$userName이 $celebName을 처음 본 건 경성역 앞이었다. '
              r'$celebName은 검은 코트를 입고 있었다.',
        },
        {
          'no': 2,
          'heading': '창가의 손님',
          'body': r'$celebName이 $userName의 카페 창가에 앉았다. 매일 같은 시간이었다.',
        },
      ],
      'epilogue': r'그리고 100년 뒤, $userName은 길에서 $celebName을 다시 본다.',
    };

    Map<String, dynamic> fixturePool(List<Map<String, dynamic>> wonjinArcs) {
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
        'story_arcs': {'wonjin': wonjinArcs},
      };
      return json.decode(json.encode(raw)) as Map<String, dynamic>;
    }

    test('longform arc → isLongform + chapters/epilogue 채워짐', () {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(fixturePool([longformArc('wonjin_01')]));
      final s = PastLifeService.generateScenario(
        user: mk(yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰', dGan: '戊', dJi: '子'),
        celeb: mk(yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉', dGan: '己', dJi: '未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
      );
      // 변수 inject 됨, 잔존 0.
      expect(s.contains('지민'), isTrue);
      expect(s.contains('카리나'), isTrue);
      for (final ph in const [
        r'$userName',
        r'$celebName',
        r'$userRole',
        r'$celebRole',
        r'$era',
      ]) {
        expect(s.contains(ph), isFalse, reason: 'placeholder "$ph" 잔존: $s');
      }
      // 챕터 본문 + epilogue 가 scenarioKo 에 모두 포함 (heading 은 별도 필드).
      expect(s.contains('경성역'), isTrue, reason: '챕터 본문 누락: $s');
      expect(s.contains('매일 같은 시간'), isTrue, reason: '챕터 2 본문 누락: $s');
      expect(s.contains('100년 뒤'), isTrue, reason: 'epilogue 누락: $s');
      PastLifeService.resetCacheForTest();
    });

    test('generate() — isLongform / genre / title / chapters 메타 노출', () async {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(fixturePool([longformArc('wonjin_01')]));
      final r = await PastLifeService.generate(
        user: mk(yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰', dGan: '戊', dJi: '子'),
        celeb: mk(yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉', dGan: '己', dJi: '未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
      );
      expect(r.isLongform, isTrue);
      expect(r.genre, '경성 모던 로맨스');
      expect(r.era, '1929 경성, 그해 겨울');
      expect(r.estReadMinutes, 24);
      expect(r.chapters.length, 2);
      expect(r.chapters.first.no, 1);
      expect(r.chapters.first.heading, '진눈깨비');
      expect(r.chapters.first.body.contains('지민'), isTrue);
      expect(r.epilogue.contains('카리나'), isTrue);
      // title 도 변수 치환됨.
      expect(r.title.contains(r'$'), isFalse);
      expect(r.title.contains('지민'), isTrue);
      PastLifeService.resetCacheForTest();
    });

    test('longform 경로 — seed deterministic', () {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(fixturePool([longformArc('wonjin_01')]));
      String g(int seed) => PastLifeService.generateScenario(
        user: mk(yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰', dGan: '戊', dJi: '子'),
        celeb: mk(yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉', dGan: '己', dJi: '未'),
        celebName: '카리나',
        userName: '지민',
        seed: seed,
      );
      expect(g(7), g(7));
      PastLifeService.resetCacheForTest();
    });

    test('구 슬롯 arc(format 없음) → isLongform false (양립)', () async {
      // format 없는 구 paragraphs arc → 기존 경로, isLongform false.
      final legacyArc = <String, dynamic>{
        'id': 'wonjin_01',
        'userRole': '몰락한 귀족',
        'celebRole': '떠돌이 악사',
        'eraHints': ['조선 후기'],
        'paragraphs': {
          'gi': r'$era, $userName은 $userRole였어요. $celebName은 $celebRole였어요.',
          'seung': r'사주에 박힌 원진살이 둘을 묶었어요. $userName은 매일 갔어요.',
          'jeon': r'$celebName이 떠나야 했어요. $userName은 못 붙잡았어요.',
          'gyeol': r'그 결이 이번 생까지 왔어요. $userName은 알아봤어요.',
        },
        'modernPunchlineByKind': {
          'idol': r'그래서 $celebName 앨범을 또 사요.',
          'actor': r'그래서 $celebName 작품을 다 봐요.',
          'athlete': r'그래서 $celebName 경기를 다 봐요.',
          'icon': r'그래서 $celebName을 응원해요.',
        },
      };
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(fixturePool([legacyArc]));
      final r = await PastLifeService.generate(
        user: mk(yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰', dGan: '戊', dJi: '子'),
        celeb: mk(yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉', dGan: '己', dJi: '未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
      );
      expect(r.isLongform, isFalse, reason: '구 슬롯 arc 는 longform 아님');
      expect(r.chapters, isEmpty);
      expect(r.scenarioKo, isNotEmpty);
      PastLifeService.resetCacheForTest();
    });
  });

  // ─── 2-b. 장편 리더 UI — past_life_screen.dart ────────────────────────
  group('R108 ② — 장편 리더 UI', () {
    final src = File(
      'lib/screens/reports/past_life_screen.dart',
    ).readAsStringSync();

    test('장편 본문 위젯 _LongformBody + 메타칩 _MetaChip 존재', () {
      expect(src.contains('_LongformBody'), isTrue);
      expect(src.contains('_MetaChip'), isTrue);
    });

    test('isLongform 분기 — 챕터 헤더 / epilogue / 메타칩 노출', () {
      expect(src.contains('scenario.isLongform'), isTrue);
      expect(src.contains('past_life_epilogue'), isTrue);
      expect(src.contains('scenario.chapters'), isTrue);
      expect(src.contains('scenario.estReadMinutes'), isTrue);
    });

    test('장편이면 작품 제목 / 시놉시스를 헤드라인·부제로', () {
      expect(src.contains('scenario.title'), isTrue);
      expect(src.contains('scenario.logline'), isTrue);
    });

    test('past_life_result_body 키 유지 (스모크 회귀 가드)', () {
      expect(src.contains('past_life_result_body'), isTrue);
    });

    test('useKo 분기 — 약 N분 읽기 / ~N min read', () {
      expect(src.contains('분 읽기'), isTrue);
      expect(src.contains('min read'), isTrue);
    });
  });

  // ─── 3. 관계 매핑 불변 (회귀 가드) ────────────────────────────────────
  group('R108 ② — 관계 매핑 불변', () {
    test('원진 子-未 → wonjin (extractKeywords 불변)', () {
      final kws = PastLifeService.extractKeywords(
        mk(yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰', dGan: '戊', dJi: '子'),
        mk(yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉', dGan: '己', dJi: '未'),
      );
      expect(kws, contains(PastLifeKeyword.wonjin));
    });

    test('hasWonjin 6쌍 양방향 불변', () {
      for (final p in const [
        ['子', '未'],
        ['丑', '午'],
        ['寅', '酉'],
        ['卯', '申'],
        ['辰', '亥'],
        ['巳', '戌'],
      ]) {
        expect(PastLifeService.hasWonjin(p[0], p[1]), isTrue);
        expect(PastLifeService.hasWonjin(p[1], p[0]), isTrue);
      }
    });
  });

  // ─── 4. 집필 완료 관계 — assets longform 가드 (enforce) ────────────────
  group('R108 ② — 집필 완료 관계 longform 가드', () {
    test('집필 완료 관계 arc — format:"longform" + chapters[{no,heading,body}] + epilogue', () {
      final sa = pool['story_arcs'] as Map;
      for (final k in longformWrittenRelations) {
        for (final raw in sa[k] as List) {
          final a = raw as Map;
          final id = a['id'];
          expect(a['format'], 'longform', reason: '$id format 누락');
          expect(a['chapters'], isA<List>(), reason: '$id chapters 누락');
          expect((a['chapters'] as List), isNotEmpty);
          for (final c in a['chapters'] as List) {
            final cm = c as Map;
            expect(cm['no'], isA<int>(), reason: '$id chapter no');
            expect((cm['heading'] as String).trim(), isNotEmpty);
            expect((cm['body'] as String).trim(), isNotEmpty);
          }
          expect((a['epilogue'] as String).trim(), isNotEmpty);
        }
      }
    });

    test('집필 완료 관계 arc — 본문 합 ≥ floor, 챕터 5~7편 + 번호 연속', () {
      final sa = pool['story_arcs'] as Map;
      for (final k in longformWrittenRelations) {
        for (final raw in sa[k] as List) {
          final a = raw as Map;
          var total = 0;
          final nos = <int>[];
          for (final c in a['chapters'] as List) {
            final cm = c as Map;
            total += (cm['body'] as String).length;
            nos.add(cm['no'] as int);
          }
          total += (a['epilogue'] as String).length;
          final floor = k == 'neutral' ? 3000 : longformCharFloor;
          expect(
            total,
            greaterThanOrEqualTo(floor),
            reason: '${a['id']} 본문 합 $total자 < $floor (장편 분량 미달)',
          );
          if (k != 'neutral') {
            expect(
              (a['chapters'] as List).length,
              inInclusiveRange(5, 7),
              reason: '${a['id']} 챕터 수 범위 밖',
            );
          }
          // 챕터 번호 1..N 연속.
          expect(
            nos,
            List.generate(nos.length, (i) => i + 1),
            reason: '${a['id']} 챕터 번호 비연속: $nos',
          );
          // estReadMinutes 합리적 범위.
          final est = a['estReadMinutes'] as int;
          expect(
            est,
            inInclusiveRange(k == 'neutral' ? 6 : 14, 36),
            reason: '${a['id']} estReadMinutes $est 범위 밖',
          );
        }
      }
    });

    test('집필 완료 관계 arc — title 전수 유니크 (장르·작품 변별)', () {
      final sa = pool['story_arcs'] as Map;
      final titles = <String>{};
      for (final k in longformWrittenRelations) {
        for (final raw in sa[k] as List) {
          final t = (raw as Map)['title'] as String;
          expect(titles.add(t), isTrue, reason: 'title 중복: $t');
        }
      }
    });

    test('집필 완료 관계 본문 — 폐기 변수 0 + 영문 그룹명 leak 0', () {
      final sa = pool['story_arcs'] as Map;
      const banned = [r'$era', r'$userRole', r'$celebRole'];
      const forbidden = <String>[
        'LE SSERAFIM', 'BLACKPINK', 'SEVENTEEN', 'BTS', 'TWICE',
        'aespa', 'IVE', 'ITZY', 'Water ', 'Wood ', 'Fire ',
      ];
      for (final k in longformWrittenRelations) {
        for (final raw in sa[k] as List) {
          final a = raw as Map;
          final blob = <String>[
            a['title'] as String,
            a['epilogue'] as String,
            for (final c in a['chapters'] as List)
              ...[(c as Map)['heading'] as String, c['body'] as String],
          ].join(' ');
          for (final b in banned) {
            expect(blob.contains(b), isFalse, reason: '${a['id']} 폐기 변수 "$b"');
          }
          for (final f in forbidden) {
            expect(blob.contains(f), isFalse, reason: '${a['id']} 금지 영문 "$f"');
          }
        }
      }
    });
  });
}
