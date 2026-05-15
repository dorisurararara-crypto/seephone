// Round 73 sprint 3 + R84 Batch 1+2+3 — sipsin_persona_service 회귀 테스트.
//
// - 같은 60갑자 일주 + 다른 천간/지지 두 사주 → phrase Jaccard distance ≥0.30.
// - R84 Batch 1+2+3: 120 entries + key set 유지 / blocked phrases 제거 (Batch 1
//   bigyeon/geopjae/siksin/sanggwan + Batch 2 pyeonjae/jeongjae/pyeongwan +
//   Batch 3 jeonggwan/pyeonin/jeongin → 전체 10 십신 120 entries) /
//   compute ko 안에 컨텍스트 anchor (계절·신강약·5행·일주) 최소 2개 노출.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/sipsin_persona_service.dart';

double jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 0.0;
  final inter = a.intersection(b).length;
  final union = a.union(b).length;
  return 1.0 - (inter / union);
}

Set<String> tokens(String s) {
  // 한글 어절 split + minimum length 2.
  return s
      .replaceAll(RegExp(r'[\.,!?·~]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length >= 2)
      .toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final f = File('assets/data/sipsin_persona.json');
    final raw = await f.readAsString();
    final map = json.decode(raw) as Map<String, dynamic>;
    SipsinPersonaService.seedForTest(map);
  });

  group('SipsinPersonaService — Round 73 sprint 3', () {
    test('1995-10-27 신묘 case — 4 카테고리 모두 paragraph ≥50자 (ko)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final r = await SipsinPersonaService.compute(saju);
      for (final cat in SipsinPersonaService.categories) {
        expect(r.ko[cat]!.length, greaterThanOrEqualTo(50),
            reason: '$cat ko too short: ${r.ko[cat]}');
        expect(r.en[cat]!.length, greaterThanOrEqualTo(40),
            reason: '$cat en too short: ${r.en[cat]}');
      }
    });

    test('TenGodsService 십신 분포 작동 — freq Map 비어있지 않음', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final r = await SipsinPersonaService.compute(saju);
      expect(r.freq.isNotEmpty, true);
      expect(r.dominantSipsin, isNotNull);
    });

    test('같은 60갑자 일주 + 다른 8글자 두 사주 → Jaccard distance ≥0.30', () async {
      // 1995-10-27 vs 다른 신묘 일주 사주
      final svc = SajuService();
      final a = await svc.calculateSaju(
        year: 1995, month: 10, day: 27, hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // 신묘 일주 + 다른 월/년 — 60일 주기
      final b = await svc.calculateSaju(
        year: 2055, month: 4, day: 5, hour: 9, minute: 0,
        isLunar: false, isMale: true,
      );
      final ra = await SipsinPersonaService.compute(a);
      final rb = await SipsinPersonaService.compute(b);

      // 4 카테고리 결합 phrase 의 token Jaccard distance 측정
      final tokensA = <String>{};
      final tokensB = <String>{};
      for (final cat in SipsinPersonaService.categories) {
        tokensA.addAll(tokens(ra.ko[cat]!));
        tokensB.addAll(tokens(rb.ko[cat]!));
      }
      final d = jaccard(tokensA, tokensB);
      expect(d, greaterThanOrEqualTo(0.30),
          reason: 'Jaccard distance $d < 0.30 — phrases too similar');
    });

    test('일관성 — 같은 사주 두 번 호출 = 같은 phrase', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final a = await SipsinPersonaService.compute(saju);
      final b = await SipsinPersonaService.compute(saju);
      for (final cat in SipsinPersonaService.categories) {
        expect(a.ko[cat], b.ko[cat]);
      }
    });
  });

  group('SipsinPersonaService — R84 Batch 1+2+3 인격 풀이 보강', () {
    const sipsins = [
      'bigyeon', 'geopjae', 'siksin', 'sanggwan',
      'pyeonjae', 'jeongjae', 'pyeongwan', 'jeonggwan',
      'pyeonin', 'jeongin',
    ];
    const freqs = ['1', '2', '3+'];
    const cats = ['persona', 'career', 'wealth', 'love'];
    // R84 Batch 1+2+3 — 전체 10 십신 × 3 freq × 4 cat = 120 entries 모두
    // blocked phrase scan 대상.
    const blocked = [
      '발목 잡',
      '본인 강점도 또렷',
      '그 방향이 당신한테 맞',
      '그쪽으로 가면',
      '몸이 닳',
      '기운',
    ];

    test('120 entries + key set 유지', () async {
      final f = File('assets/data/sipsin_persona.json');
      final raw = await f.readAsString();
      final map = json.decode(raw) as Map<String, dynamic>;
      final entries = Map<String, dynamic>.from(map)..remove('_meta');
      expect(entries.length, 120, reason: 'entry count drift');

      for (final s in sipsins) {
        for (final fq in freqs) {
          for (final c in cats) {
            final key = '${s}_${fq}_$c';
            expect(entries.containsKey(key), true, reason: 'missing $key');
            final e = entries[key] as Map<String, dynamic>;
            expect(e.containsKey('ko'), true, reason: '$key missing ko');
            expect(e.containsKey('en'), true, reason: '$key missing en');
            final ko = e['ko'] as String;
            final en = e['en'] as String;
            expect(ko.length, greaterThanOrEqualTo(40),
                reason: '$key ko too short: $ko');
            expect(en.length, greaterThanOrEqualTo(30),
                reason: '$key en too short: $en');
          }
        }
      }
    });

    test('Batch 1+2+3 — 전체 120 ko entries blocked phrases 제거', () async {
      final f = File('assets/data/sipsin_persona.json');
      final raw = await f.readAsString();
      final map = json.decode(raw) as Map<String, dynamic>;
      var scanned = 0;
      for (final k in map.keys) {
        if (k == '_meta') continue;
        final ko = (map[k] as Map)['ko'] as String;
        for (final b in blocked) {
          expect(ko.contains(b), false,
              reason: '$k contains blocked "$b": $ko');
        }
        scanned += 1;
      }
      expect(scanned, 120, reason: 'expected to scan 120 ko entries');
    });

    test('compute ko — 컨텍스트 anchor (계절/신강약/5행/일주) ≥2 등장', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final r = await SipsinPersonaService.compute(saju);
      final allKo = r.ko.values.join(' ');

      const seasons = ['봄', '여름', '가을', '겨울'];
      const strengthLabels = ['신강', '신왕', '중화', '신약', '신쇠'];
      const elements = ['목', '화', '토', '금', '수'];
      const dayPillarTerms = ['일간', '일주'];

      final hits = <String>{};
      for (final t in [...seasons, ...strengthLabels, ...elements, ...dayPillarTerms]) {
        if (allKo.contains(t)) hits.add(t);
      }
      expect(hits.length, greaterThanOrEqualTo(2),
          reason: 'anchor terms not embedded: hits=$hits / ko=${r.ko}');
    });

    test('compute 결정성 — 같은 saju 두 번 호출 = 같은 결과', () async {
      final saju = await SajuService().calculateSaju(
        year: 1988, month: 6, day: 15,
        hour: 8, minute: 30,
        isLunar: false, isMale: false,
      );
      final a = await SipsinPersonaService.compute(saju);
      final b = await SipsinPersonaService.compute(saju);
      for (final cat in SipsinPersonaService.categories) {
        expect(a.ko[cat], b.ko[cat], reason: '$cat ko 결정성 broken');
        expect(a.en[cat], b.en[cat], reason: '$cat en 결정성 broken');
      }
    });
  });
}
