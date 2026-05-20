// R105 Sprint 1 — 최애의 사주 거짓말방지 가드.
//
// 검증 (mandate):
//   1) celeb_facts.json / celeb_saju_readings.json 는 valid JSON + _meta 존재.
//   2) celeb_saju_readings 의 모든 usedFactId 가 celeb_facts 에 존재.
//   3) used fact 는 confidence=verified + sourceIds 1개 이상.
//   4) 모든 fact 의 source URL 은 wikipedia.org 또는 공식 allowlist 도메인만.
//   5) R105 reading 본문(sections.bodyKo)에 시주/時柱/"태어난 시간" 류 단정 0.
//   6) curated reading(sections 비어있지 않은 셀럽)만 노출 — 화면 코드가
//      isCurated 로 가드하는지 source grep.
//
// 이 테스트가 fail 하면 출처 없는 사실 주장 또는 시주 단정이 침투한 것이다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> facts;
  late Map<String, dynamic> readings;

  // 출처 도메인 allowlist — wikipedia + 공식.
  const allowedDomains = <String>[
    'wikipedia.org',
    'ko.wikipedia.org',
    'en.wikipedia.org',
  ];

  // 시주 단정 금지 표현.
  const forbiddenHourTerms = <String>[
    '시주',
    '時柱',
    '태어난 시간',
    '태어난 시각',
    '출생 시간',
    '출생시간',
    '출생 시각',
    '몇 시에 태어',
  ];

  setUpAll(() {
    facts =
        jsonDecode(File('assets/data/celeb_facts.json').readAsStringSync())
            as Map<String, dynamic>;
    readings =
        jsonDecode(
              File('assets/data/celeb_saju_readings.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
  });

  group('R105 — JSON 무결성', () {
    test('celeb_facts.json / celeb_saju_readings.json 는 _meta 보유', () {
      expect(facts.containsKey('_meta'), isTrue, reason: 'facts _meta 누락');
      expect(
        readings.containsKey('_meta'),
        isTrue,
        reason: 'readings _meta 누락',
      );
    });

    test('seed 셀럽 iu / rm 가 양쪽 파일에 존재', () {
      for (final id in ['iu', 'rm']) {
        expect(facts.containsKey(id), isTrue, reason: 'facts 에 $id 누락');
        expect(readings.containsKey(id), isTrue, reason: 'readings 에 $id 누락');
      }
    });
  });

  group('R105 — fact 출처 / confidence 가드', () {
    test('모든 fact 의 source URL 은 wikipedia / 공식 allowlist 만', () {
      facts.forEach((id, value) {
        if (id == '_meta') return;
        final entry = value as Map<String, dynamic>;
        final sources = (entry['sources'] as List?) ?? const [];
        for (final s in sources) {
          final url = ((s as Map<String, dynamic>)['url'] as String?) ?? '';
          final ok = allowedDomains.any((d) => url.contains(d));
          expect(ok, isTrue, reason: '$id source URL 이 allowlist 밖: "$url"');
        }
        // 각 fact 의 confidence 값은 verified | unverified 만.
        final factList = (entry['facts'] as List?) ?? const [];
        for (final f in factList) {
          final conf = (f as Map<String, dynamic>)['confidence'] as String?;
          expect(
            conf == 'verified' || conf == 'unverified',
            isTrue,
            reason: '$id fact confidence 값 위반: "$conf"',
          );
        }
      });
    });

    test('used fact 는 모두 존재 + verified + sourceIds 1개 이상', () {
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final usedIds =
            ((value as Map<String, dynamic>)['usedFactIds'] as List?) ??
            const [];
        if (usedIds.isEmpty) return;

        final celebFacts = facts[id];
        expect(
          celebFacts,
          isNotNull,
          reason: '$id 가 usedFactIds 를 쓰는데 celeb_facts 에 셀럽 entry 없음',
        );
        final factList =
            ((celebFacts as Map<String, dynamic>)['facts'] as List?) ??
            const [];
        final byId = <String, Map<String, dynamic>>{
          for (final f in factList)
            (f as Map<String, dynamic>)['id'] as String: f,
        };
        for (final used in usedIds) {
          final f = byId[used as String];
          expect(f, isNotNull, reason: '$id usedFactId "$used" 가 facts 에 없음');
          expect(
            f!['confidence'],
            'verified',
            reason: '$id usedFactId "$used" 가 verified 아님',
          );
          final srcIds = (f['sourceIds'] as List?) ?? const [];
          expect(
            srcIds.isNotEmpty,
            isTrue,
            reason: '$id usedFactId "$used" 의 sourceIds 가 비어있음',
          );
        }
      });
    });
  });

  group('R105 — reading 본문 시주 단정 금지', () {
    test('sections.bodyKo 에 시주/時柱/태어난 시간 류 0', () {
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final sections =
            ((value as Map<String, dynamic>)['sections'] as List?) ?? const [];
        for (final s in sections) {
          final body = ((s as Map<String, dynamic>)['bodyKo'] as String?) ?? '';
          for (final term in forbiddenHourTerms) {
            expect(
              body.contains(term),
              isFalse,
              reason: '$id 본문에 시주 단정 표현 "$term" 발견',
            );
          }
        }
      });
    });

    test('chart.hourPillar 는 항상 null', () {
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final chart =
            (value as Map<String, dynamic>)['chart'] as Map<String, dynamic>;
        expect(
          chart['hourPillar'],
          isNull,
          reason: '$id chart.hourPillar 가 null 아님',
        );
      });
    });
  });

  group('R105 — curated-only 노출 정책', () {
    test('celebrity_saju_screen 이 isCurated 로 picker 를 가드', () {
      final src = File(
        'lib/screens/reports/celebrity_saju_screen.dart',
      ).readAsStringSync();
      // curated = sections 비어있지 않은 셀럽만 노출.
      expect(src.contains('isCurated'), isTrue, reason: 'isCurated 가드 누락');
      expect(
        src.contains('sections.isNotEmpty'),
        isTrue,
        reason: 'isCurated 정의가 sections.isNotEmpty 가 아님',
      );
      // picker 에 curated 만 add 하는지.
      expect(
        src.contains('if (reading != null && reading.isCurated)'),
        isTrue,
        reason: 'picker 가 curated 만 추가하지 않음',
      );
    });

    test('화면/검증기 코드에 시주 단정 표현 leak 0', () {
      for (final path in [
        'lib/screens/reports/celebrity_saju_screen.dart',
        'lib/services/celeb_chart_validator.dart',
      ]) {
        final src = File(path).readAsStringSync();
        // 사용자 노출 라벨 후보 — '時柱' 한자 / "태어난 시간" 단정.
        // ("출생 시간은 알려지지 않아" 같은 부정 문장은 시주 미상 고지이므로 OK.)
        expect(src.contains('時柱'), isFalse, reason: '$path 에 時柱 한자 leak');
      }
    });
  });
}
