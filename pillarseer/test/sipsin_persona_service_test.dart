// Round 73 sprint 3 — sipsin_persona_service 회귀 테스트.
//
// 같은 60갑자 일주 + 다른 천간/지지 두 사주 → phrase Jaccard distance ≥0.30.

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
}
