// R102 sprint 2 — 반복 어휘 cap.
//
//   "두 사람은" ≤ 2회
//   "자연스럽게" ≤ 1회
//   "결" 단독 어절 ≤ 2회
//   "당신과 X" 헤더 패턴 ≤ 2회
//   "이었어요" / "였어요" 결말 ≤ 3회

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

  int countOccurrences(String s, String needle) {
    if (needle.isEmpty) return 0;
    var n = 0;
    var i = 0;
    while (true) {
      final idx = s.indexOf(needle, i);
      if (idx < 0) break;
      n++;
      i = idx + needle.length;
    }
    return n;
  }

  /// "결" 단독 어절 — 다음 글자가 조사가 아닌 경우만 카운트.
  int countStandaloneJiel(String s) {
    var n = 0;
    for (var i = 0; i < s.length; i++) {
      if (s[i] != '결') continue;
      final next = i + 1 < s.length ? s[i + 1] : '';
      const attached = {
        '을', '이', '은', '의', '과', '도', '에', '만', '까지', '로',
        '에서', '부터', '보다', '처럼', '한테', '치', '단',
      };
      if (attached.contains(next)) continue;
      n++;
    }
    return n;
  }

  // R108 ② — 장편(longform) keyword 판정. 장편 관계는 의도된 완결 서사라
  // slot 기준 어휘 cap(셔플 반복 억제)이 적용되지 않는다. 장편 본문 가드는
  // r108_past_life_longform_test.dart 가 전담한다.
  bool isLongformKeyword(String keywordId) {
    final sa = pool['story_arcs'];
    if (sa is! Map) return false;
    final arcs = sa[keywordId];
    if (arcs is! List || arcs.isEmpty) return false;
    final first = arcs.first;
    return first is Map && first['format'] == 'longform';
  }

  group('R102 — 반복 어휘 cap', () {
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      ('gongmang', () => mk('子'), () => mk('戌')),
    ];

    test('30 시나리오 — cap 통과', () {
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        if (isLongformKeyword(label)) continue; // 장편은 slot cap 대상 아님.
        for (var seed = 0; seed < 8; seed++) {
          final scenario = PastLifeService.generateScenario(
            user: mkU(),
            celeb: mkC(),
            celebName: '솔라',
            userName: '당신',
            seed: seed,
          );
          expect(countOccurrences(scenario, '두 사람은'), lessThanOrEqualTo(2),
              reason: '[$label seed=$seed] "두 사람은" > 2: $scenario');
          expect(countOccurrences(scenario, '자연스럽게'), lessThanOrEqualTo(1),
              reason: '[$label seed=$seed] "자연스럽게" > 1: $scenario');
          expect(countStandaloneJiel(scenario), lessThanOrEqualTo(2),
              reason: '[$label seed=$seed] "결" 단독 어절 > 2: $scenario');
          expect(countOccurrences(scenario, '당신과 솔라'), lessThanOrEqualTo(2),
              reason: '[$label seed=$seed] "당신과 솔라" > 2: $scenario');
          // "이었어요" + "였어요" 합쳐 3 초과 시 다양화 적용된 결과 == ≤ 3.
          final ieot = countOccurrences(scenario, '이었어요.');
          final yeot = countOccurrences(scenario, '였어요.');
          expect(ieot, lessThanOrEqualTo(3),
              reason: '[$label seed=$seed] "이었어요." > 3: $scenario');
          expect(yeot, lessThanOrEqualTo(3),
              reason: '[$label seed=$seed] "였어요." > 3: $scenario');
        }
      }
    });
  });
}
