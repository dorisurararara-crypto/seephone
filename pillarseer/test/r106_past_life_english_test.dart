// R106 P5 — 전생 시나리오 영어 모드 가드.
//
// 문제 (담당 spec verbatim):
//   전생 시나리오 화면이 100% 한국어 — useKo 언어 분기가 0개. 영어 모드에서
//   UI 라벨·본문이 전부 한국어로 샌다.
//
// R106 P5 변경:
//   - assets/data/past_life_pool.json 에 eras_en + story_arcs_en (8 keyword ×
//     8 arc = 64) 추가. 한국어 키(eras/story_arcs/templates/body_lines)는 불변.
//   - PastLifeScenario 에 scenarioEn / headlineEn 필드 추가.
//   - PastLifeKeyword 에 labelEn extension getter 추가.
//   - past_life_screen.dart 의 모든 한국어 UI 문자열을 useKo 분기.
//
// 본 가드:
//   1. 서비스 — generate() 가 영어 본문(가-힣 0)을 산출하는지.
//   2. 영어 본문에 placeholder 잔존($) 0, 메타/단정 voice.
//   3. 한국어 경로 회귀 0 — scenarioKo/headlineKo 는 한국어 그대로.
//   4. 화면 — past_life_screen.dart 에 useKo 분기 존재 + 한국어 하드코딩 0.
//   5. labelEn / labelKo 8 keyword 전부 채워짐.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hangul = RegExp(r'[가-힣]');

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

  SajuResult mk(String gan, String dJi) => SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
    dayPillar: Pillar(chunGan: gan, jiJi: dJi),
    hourPillar: null,
    elements: const FiveElements(
      wood: 20,
      fire: 20,
      earth: 20,
      metal: 20,
      water: 20,
    ),
    dayMaster: gan,
    dayMasterName: 'Test',
    summary: 'test',
    categoryReadings: const {},
  );

  // ─── 1. 영어 풀 존재 + schema ───────────────────────────────────────
  group('R106 P5 — past_life_pool.json 영어 풀', () {
    test('eras_en + story_arcs_en 키 존재', () {
      expect(pool['eras_en'], isA<List>());
      expect((pool['eras_en'] as List).isNotEmpty, isTrue);
      expect(pool['story_arcs_en'], isA<Map>());
    });

    test('한국어 키(eras/story_arcs/templates/body_lines) 불변 — 회귀 0', () {
      // 영어 추가가 한국어 키를 건드리지 않았는지.
      expect(pool['eras'], isA<List>());
      expect(pool['story_arcs'], isA<Map>());
      expect(pool['templates'], isA<Map>());
      expect(pool['body_lines'], isA<Map>());
      // eras_en 은 한국어 eras 와 다른 별도 리스트.
      expect(identical(pool['eras'], pool['eras_en']), isFalse);
    });

    test('story_arcs_en — 8 keyword 전부, keyword 당 arc 8개', () {
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
      final en = pool['story_arcs_en'] as Map;
      for (final k in keys) {
        expect(en.containsKey(k), isTrue, reason: 'story_arcs_en 에 $k 누락');
        expect((en[k] as List).length, 8, reason: '$k arc 수 != 8');
      }
    });

    test('story_arcs_en 모든 arc — gi/seung/jeon/gyeol 4문단 + 가-힣 0', () {
      final en = pool['story_arcs_en'] as Map;
      for (final k in en.keys) {
        for (final a in en[k] as List) {
          final m = a as Map;
          final p = m['paragraphs'] as Map;
          for (final phase in const ['gi', 'seung', 'jeon', 'gyeol']) {
            final v = p[phase];
            expect(v, isA<String>(), reason: '${m['id']}.$phase 누락');
            expect(
              hangul.hasMatch(v as String),
              isFalse,
              reason: '${m['id']}.$phase 에 한글 leak: $v',
            );
          }
          // role 문자열에 placeholder 없음.
          expect((m['userRole'] as String).contains(r'$'), isFalse);
          expect((m['celebRole'] as String).contains(r'$'), isFalse);
        }
      }
    });

    test('eras_en — 한글 0', () {
      for (final e in pool['eras_en'] as List) {
        expect(hangul.hasMatch(e as String), isFalse, reason: 'eras_en 한글: $e');
      }
    });
  });

  // ─── 2. 서비스 영어 산출물 ──────────────────────────────────────────
  group('R106 P5 — PastLifeService 영어 시나리오', () {
    test('generate() — scenarioEn / headlineEn 채워짐 + 가-힣 0', () async {
      // 子-未 원진 페어 → primary = wonjin.
      final r = await PastLifeService.generate(
        user: mk('戊', '子'),
        celeb: mk('丁', '未'),
        celebName: 'IU',
        userName: 'Alex',
        kind: 'idol',
      );
      expect(r.scenarioEn.isNotEmpty, isTrue, reason: 'scenarioEn 비어 있음');
      expect(r.headlineEn.isNotEmpty, isTrue, reason: 'headlineEn 비어 있음');
      expect(
        hangul.hasMatch(r.scenarioEn),
        isFalse,
        reason: 'scenarioEn 한글 leak: ${r.scenarioEn}',
      );
      expect(
        hangul.hasMatch(r.headlineEn),
        isFalse,
        reason: 'headlineEn 한글 leak: ${r.headlineEn}',
      );
    });

    test('영어 본문 — placeholder(\$) 잔존 0', () async {
      final r = await PastLifeService.generate(
        user: mk('戊', '子'),
        celeb: mk('丁', '未'),
        celebName: 'IU',
        userName: 'Alex',
        kind: 'idol',
      );
      expect(
        r.scenarioEn.contains(r'$'),
        isFalse,
        reason: 'scenarioEn placeholder 잔존: ${r.scenarioEn}',
      );
      expect(r.headlineEn.contains(r'$'), isFalse);
    });

    test('영어 본문 — userName / celebName 주입 확인', () async {
      final r = await PastLifeService.generate(
        user: mk('戊', '子'),
        celeb: mk('丁', '未'),
        celebName: 'Wonyoung',
        userName: 'Jamie',
        kind: 'idol',
      );
      expect(r.scenarioEn.contains('Wonyoung'), isTrue);
      expect(r.scenarioEn.contains('Jamie'), isTrue);
      expect(r.headlineEn.contains('Wonyoung'), isTrue);
      expect(r.headlineEn.contains('Jamie'), isTrue);
    });

    test('영어 본문 — 단정 voice (조건형 어휘 존재, 절대 단정 회피)', () async {
      // v5 voice: 사용자 미래/감정을 사실 단정하지 않고 조건형으로.
      // 영어 arc 풀 전체에 조건형 marker 가 충분히 박혀 있는지 표본 검사.
      var conditionalHits = 0;
      final en = pool['story_arcs_en'] as Map;
      final markers = RegExp(
        r'\b(might|may|can|tends? to|tended to|could)\b',
        caseSensitive: false,
      );
      for (final k in en.keys) {
        for (final a in en[k] as List) {
          final p = (a as Map)['paragraphs'] as Map;
          final blob = (p.values).join(' ');
          if (markers.hasMatch(blob)) conditionalHits++;
        }
      }
      // 64 arc 전부 조건형 marker 를 포함해야 한다.
      expect(conditionalHits, 64, reason: '조건형 voice 누락 arc 존재');
    });

    test('영어 본문 — 메타 노출 0 (saju/사주차트 를 화자·주체로 쓰지 않음)', () async {
      // 금지: "your chart" / "your saju" / "the saju" 처럼 사주(차트)를 화자·주체로
      // 노출. (sea/navigation chart 같은 일반 명사 "the chart" 는 메타 아님 — 허용.)
      final en = pool['story_arcs_en'] as Map;
      final meta = RegExp(
        r'\b(your chart|your saju|the saju|your reading|the reading says)\b',
        caseSensitive: false,
      );
      for (final k in en.keys) {
        for (final a in en[k] as List) {
          final p = (a as Map)['paragraphs'] as Map;
          final blob = (p.values).join(' ');
          expect(
            meta.hasMatch(blob),
            isFalse,
            reason: '${(a)['id']} 메타 노출: $blob',
          );
        }
      }
    });
  });

  // ─── 3. 한국어 경로 회귀 0 ──────────────────────────────────────────
  group('R106 P5 — 한국어 경로 회귀 0', () {
    test('scenarioKo / headlineKo 는 한국어 그대로', () async {
      final r = await PastLifeService.generate(
        user: mk('戊', '子'),
        celeb: mk('丁', '未'),
        celebName: '아이유',
        userName: '지민',
        kind: 'idol',
      );
      expect(r.scenarioKo.isNotEmpty, isTrue);
      expect(r.headlineKo.isNotEmpty, isTrue);
      expect(
        hangul.hasMatch(r.scenarioKo),
        isTrue,
        reason: 'scenarioKo 가 한국어가 아님 — 회귀',
      );
      expect(hangul.hasMatch(r.headlineKo), isTrue);
      // 한국어 본문에 영어 arc 가 새지 않았는지.
      expect(r.scenarioKo.contains('tends to'), isFalse);
    });

    test('generateScenario (sync API) 시그니처 불변 — 한국어 반환', () {
      final s = PastLifeService.generateScenario(
        user: mk('戊', '子'),
        celeb: mk('丁', '未'),
        celebName: '카리나',
        userName: '지민',
        seed: 1,
        kind: 'idol',
      );
      expect(s.isNotEmpty, isTrue);
      expect(hangul.hasMatch(s), isTrue, reason: 'generateScenario 한국어 아님');
    });

    test('seed deterministic — 같은 입력 → 같은 EN/KO 본문', () async {
      Future<PastLifeScenario> gen() => PastLifeService.generate(
        user: mk('戊', '子'),
        celeb: mk('丁', '未'),
        celebName: 'IU',
        userName: 'Alex',
        seed: 42,
        kind: 'idol',
      );
      final a = await gen();
      final b = await gen();
      expect(a.scenarioEn, b.scenarioEn);
      expect(a.headlineEn, b.headlineEn);
      expect(a.scenarioKo, b.scenarioKo);
    });
  });

  // ─── 4. labelEn / labelKo 8 keyword ─────────────────────────────────
  group('R106 P5 — keyword 라벨', () {
    test('8 keyword 모두 labelKo(한글) + labelEn(영문) 채워짐', () {
      for (final kw in PastLifeKeyword.values) {
        expect(kw.labelKo.isNotEmpty, isTrue, reason: '${kw.name} labelKo 빔');
        expect(kw.labelEn.isNotEmpty, isTrue, reason: '${kw.name} labelEn 빔');
        expect(
          hangul.hasMatch(kw.labelKo),
          isTrue,
          reason: '${kw.name} labelKo 한글 아님',
        );
        expect(
          hangul.hasMatch(kw.labelEn),
          isFalse,
          reason: '${kw.name} labelEn 한글 leak: ${kw.labelEn}',
        );
      }
    });
  });

  // ─── 5. 화면 useKo 분기 ─────────────────────────────────────────────
  group('R106 P5 — past_life_screen.dart useKo 분기', () {
    final src = File(
      'lib/screens/reports/past_life_screen.dart',
    ).readAsStringSync();

    test('useKo 산출 패턴 존재 (compatibility_screen 과 동일)', () {
      expect(
        src.contains('Localizations.maybeLocaleOf(context)'),
        isTrue,
        reason: 'useKo 언어 분기 산출이 없음',
      );
      expect(src.contains('_useKo('), isTrue);
    });

    test('useKo 분기가 충분히 적용됨 (>= 15회)', () {
      final n = RegExp(r'useKo').allMatches(src).length;
      expect(n >= 15, isTrue, reason: 'useKo 분기 너무 적음: $n');
    });

    test('영어 모드 라벨 — 핵심 UI 영문 문자열 존재', () {
      // 영어 분기 산출물이 실제로 영문을 노출하는지.
      for (final en in const [
        'PAST LIFE · 緣',
        'Pick another',
        'Your pick:',
        'Search by your favorite',
        'Enter birth details',
      ]) {
        expect(src.contains(en), isTrue, reason: '영문 라벨 누락: $en');
      }
    });

    test('한국어 UI 라벨은 useKo 한쪽 분기로만 — 무조건 한국어 없음', () {
      // 핵심 한국어 라벨의 string literal (' 로 감싼 형태) 이 useKo 삼항 분기
      // 안에 있는지. 주석 속 한국어는 literal 이 아니므로 무시된다.
      for (final ko in const [
        "'다른 최애 고르기'",
        "'선택한 최애: \$celebName'",
        "'사주 입력하기'",
        "'최애 이름으로 검색'",
      ]) {
        expect(src.contains(ko), isTrue, reason: '한국어 라벨 literal 이 사라짐: $ko');
        // 해당 literal 직전 24자 안에 useKo 삼항 분기(? marker) 가 있어야 함.
        final idx = src.indexOf(ko);
        final ctx = src.substring(idx < 24 ? 0 : idx - 24, idx);
        expect(
          ctx.contains('useKo ?'),
          isTrue,
          reason: '$ko 가 useKo 삼항 분기 밖 — 영어 모드에서 한국어 leak',
        );
      }
    });

    test('AppBar 타이틀이 useKo 분기 (전생 · 緣 무조건 노출 아님)', () {
      expect(src.contains("useKo ? '전생 · 緣' : 'PAST LIFE · 緣'"), isTrue);
    });

    test('결과 카드 본문 — useKo 시 scenarioEn 분기', () {
      // _ResultCard 가 영어 모드에서 scenarioEn / headlineEn 을 노출.
      expect(src.contains('scenario.scenarioEn'), isTrue);
      expect(src.contains('scenario.headlineEn'), isTrue);
      expect(src.contains('k.labelEn'), isTrue);
    });
  });
}
