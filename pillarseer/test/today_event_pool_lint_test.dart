// Round 76 — today_event_pool.json 스키마 + 톤 lint.
//
// 검증:
// 1) 5 십성 그룹 × 6 카테고리 = 30 key, 각 3 set.
// 2) 각 entry: body/caution/recommend 모두 ≤120자.
// 3) body 가능성 헷지 패턴 1개 이상 (verbatim).
// 4) 금지 패턴 0 (반드시 / 사고가 / 큰돈을 잃 / 병원 / 이성과 만납니다).
// 5) shinsa 8 key 존재.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> pool;
  setUpAll(() {
    final file = File('assets/data/today_event_pool.json');
    expect(file.existsSync(), isTrue,
        reason: 'assets/data/today_event_pool.json missing');
    pool = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  group('today_event_pool 스키마', () {
    test('30 key (5 그룹 × 6 카테고리) — 각 3 set', () {
      final events = pool['events'] as Map<String, dynamic>;
      const groups = ['비겁', '식상', '재성', '관성', '인성'];
      const cats = ['relationship', 'money', 'work', 'love', 'health', 'luck'];
      for (final g in groups) {
        for (final c in cats) {
          final key = '${g}_$c';
          expect(events.containsKey(key), isTrue, reason: '$key 누락');
          final list = events[key] as List;
          expect(list.length, 3, reason: '$key set 수 != 3');
          for (final e in list) {
            final m = e as Map<String, dynamic>;
            expect(m.containsKey('body'), isTrue);
            expect(m.containsKey('caution'), isTrue);
            expect(m.containsKey('recommend'), isTrue);
          }
        }
      }
    });

    test('shinsa 8 key', () {
      final shinsa = pool['shinsa'] as Map<String, dynamic>;
      const keys = ['도화', '역마', '문창귀인', '천을귀인', '양인', '백호', '괴강', '화개'];
      for (final k in keys) {
        expect(shinsa.containsKey(k), isTrue, reason: 'shinsa $k 누락');
        expect((shinsa[k] as String).length, lessThanOrEqualTo(120));
      }
    });
  });

  group('today_event_pool 톤', () {
    // 가능성 헷지 패턴 — 사용자 verbatim + 자연 변형 모두 허용 (단정 X).
    final hedge = RegExp(
        r'(쉬워요|흐름이 강해요|가능성이 강해요|가능성이 있어요|쌓이기 쉬워요|흔들릴 수 있어요|커지기 쉬워요|들어올|올라오는|들어오는|기회가|있는 날|어울리는 날|있을 흐름|풀리는 흐름|흐름이에요|잘 풀리는|만날 수 있어요|떠오르기 쉬워요|들어와|수 있어요|쉬운 날|살아날|살아나기|가능성이|올라올)');
    final forbid = RegExp(r'(반드시|사고가 날|큰돈을 잃|병원|이성과 만납니다)');

    test('events 본문 ≤120자 + 가능성 헷지 + 금지 패턴 0', () {
      final events = pool['events'] as Map<String, dynamic>;
      events.forEach((key, list) {
        for (final e in (list as List)) {
          final m = e as Map<String, dynamic>;
          final body = m['body'] as String;
          final caution = m['caution'] as String;
          final recommend = m['recommend'] as String;
          expect(body.length, lessThanOrEqualTo(120),
              reason: '$key body > 120: $body');
          expect(caution.length, lessThanOrEqualTo(120),
              reason: '$key caution > 120: $caution');
          expect(recommend.length, lessThanOrEqualTo(120),
              reason: '$key recommend > 120: $recommend');
          expect(hedge.hasMatch(body), isTrue,
              reason: '$key body no hedge: $body');
          expect(forbid.hasMatch(body), isFalse,
              reason: '$key body forbidden: $body');
          expect(forbid.hasMatch(caution), isFalse,
              reason: '$key caution forbidden: $caution');
          expect(forbid.hasMatch(recommend), isFalse,
              reason: '$key recommend forbidden: $recommend');
        }
      });
    });

    test('shinsa 본문 가능성 헷지 + 금지 0', () {
      final shinsa = pool['shinsa'] as Map<String, dynamic>;
      shinsa.forEach((k, v) {
        final s = v as String;
        expect(hedge.hasMatch(s), isTrue, reason: 'shinsa $k no hedge: $s');
        expect(forbid.hasMatch(s), isFalse,
            reason: 'shinsa $k forbidden: $s');
      });
    });
  });
}
