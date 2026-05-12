// 콘텐츠 무결성 회귀 테스트 — codex Round 30 권고.
// 1. dreams.json 중복 없음, 빈 의미 없음
// 2. category 가 UI 필터 enum 안에만 존재
// 3. 모든 entry KO + EN 동등

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dreams.json 무결성', () {
    late List<Map<String, dynamic>> dreams;
    setUpAll(() {
      final raw =
          File('assets/data/dreams.json').readAsStringSync();
      dreams = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    });

    test('en 키워드 중복 없음', () {
      final seen = <String, int>{};
      for (final d in dreams) {
        final en = d['en'] as String;
        seen[en] = (seen[en] ?? 0) + 1;
      }
      final dups = seen.entries.where((e) => e.value > 1).toList();
      expect(dups, isEmpty, reason: 'duplicate en keys: $dups');
    });

    test('ko 키워드 중복 없음', () {
      final seen = <String, int>{};
      for (final d in dreams) {
        final ko = d['ko'] as String;
        seen[ko] = (seen[ko] ?? 0) + 1;
      }
      final dups = seen.entries.where((e) => e.value > 1).toList();
      expect(dups, isEmpty, reason: 'duplicate ko keys: $dups');
    });

    test('빈 의미·키워드 없음', () {
      for (final d in dreams) {
        expect((d['en'] as String).trim(), isNotEmpty);
        expect((d['ko'] as String).trim(), isNotEmpty);
        expect((d['meaningEn'] as String).trim(), isNotEmpty);
        expect((d['meaningKo'] as String).trim(), isNotEmpty);
      }
    });

    test('category 가 UI 필터 enum 안에만 (auspicious/wealth/love/family/warning)', () {
      const allowed = {'auspicious', 'wealth', 'love', 'family', 'warning'};
      final invalid = <String>{};
      for (final d in dreams) {
        final cat = d['cat'] as String;
        if (!allowed.contains(cat)) invalid.add(cat);
      }
      expect(invalid, isEmpty,
          reason:
              'unknown categories present: $invalid (allowed: $allowed)');
    });

    test('auspicious bool 필드 존재', () {
      for (final d in dreams) {
        expect(d['auspicious'], isA<bool>(),
            reason: 'auspicious 필드 누락/타입 오류: ${d['en']}');
      }
    });

    test('전체 entry 수 >= 40 (출시 데이터셋 최소)', () {
      expect(dreams.length, greaterThanOrEqualTo(40),
          reason: 'dataset 너무 작음 — 깊이 부족');
    });
  });

  group('l10n KO/EN parity 무결성', () {
    test('주요 한국어 leak 후보 — 한국 모드에서 영어 단어 미노출', () {
      // 자주 leak 되는 패턴들이 KO arb 안에 직접 영어 표기로 잠겨 있지 않은지.
      // English 단어가 한국어 strings 안에 들어가 있으면 번역 흔적 의심.
      final koArb =
          File('lib/l10n/app_ko.arb').readAsStringSync();
      // 사주 핵심 용어인데 영어로만 적혀있으면 leak 의심.
      // 의도적 영어 brand 단어 (KASI, Pillar Seer, K-pop, Phase, Pro, AM, PM) 는 OK.
      final suspectPatterns = [
        'Day Master',
        'Day Pillar',
        'Yang Wood',
        'Yin Wood',
        'Yang Fire',
        'Yin Fire',
      ];
      for (final p in suspectPatterns) {
        expect(koArb.contains(p), isFalse,
            reason:
                'KO arb 에 "$p" 발견 — 한국 모드에서 영어 leak 가능성');
      }
    });

    test('주요 영문 leak 후보 — 영어 모드에서 한국 표기 미노출', () {
      final enArb =
          File('lib/l10n/app_en.arb').readAsStringSync();
      // 한국어 brand 단어는 OK ("한국어", 한국어 KASI 보충 표기 등).
      // 핵심 사주 용어 한국어 음을 영어 strings 에서 단독 노출하면 안 됨.
      final suspectPatterns = [
        '나무',
        '불 (火)',
        '쇠',
        '물 (水)',
        '갑목',
        '을목',
      ];
      for (final p in suspectPatterns) {
        expect(enArb.contains(p), isFalse,
            reason:
                'EN arb 에 "$p" 발견 — 영어 모드에서 한국어 leak 가능성');
      }
    });
  });

  group('celebrities.json 무결성', () {
    late List<Map<String, dynamic>> celebs;
    setUpAll(() {
      final raw =
          File('assets/data/celebrities.json').readAsStringSync();
      celebs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    });

    test('id 중복 없음', () {
      final seen = <String, int>{};
      for (final c in celebs) {
        final id = c['id'] as String;
        seen[id] = (seen[id] ?? 0) + 1;
      }
      final dups = seen.entries.where((e) => e.value > 1).toList();
      expect(dups, isEmpty);
    });

    test('필수 필드: nameEn/nameKo/dayPillar/blurbKo', () {
      for (final c in celebs) {
        expect((c['nameEn'] as String).trim(), isNotEmpty);
        expect((c['nameKo'] as String).trim(), isNotEmpty);
        expect((c['dayPillar'] as String).trim(), hasLength(2));
        expect((c['blurbKo'] as String).trim(), isNotEmpty);
        expect((c['blurbEn'] as String).trim(), isNotEmpty);
      }
    });
  });
}
