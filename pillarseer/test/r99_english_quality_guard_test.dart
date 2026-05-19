// R99 English quality regression guard.
//
// 목적:
//   R99 sprint 1~4 가 정리한 영어 본문 품질을 read-only 테스트로 고정.
//   본 파일은 source / data mutation 없이 assert 만 수행.
//
// 보호 대상:
//   1. saju_deep_slice 3 파일 (0_19 / 20_39 / 40_59) 의 EN 본문
//   2. celebrities.json blurbEn (223 entry)
//   3. R99 sprint 3 가 손댄 lib + l10n 파일들
//
// Guard set:
//   A. Forbidden 35 phrase (case-insensitive) — saju slice 3 + celebs blurbEn +
//      R99 sprint 3 hit 5 파일에 0 건.
//   B. saju_deep_slice EN paragraph (60일주 × 7 슬롯 = 420) 의 first-3-word
//      unique ratio — per-slice + global. 회귀 가드 floor.
//   C. celebrities blurbEn first-3-word unique ratio >= 0.92 + stock-lead
//      ratio <= 0.35 + 223 entry 전수 blurbEn non-empty.
//   D. JSON 구조 무결성 (parse OK / count / 핵심 키 유지).
//
// 임계값 root note:
//   Codex R99 spec 은 saju slice 의 global first-3 unique ratio 를 0.90 으로
//   요구했으나, 실제 sprint 2b-1 (slice_0_19) = 0.864 / sprint 2b-2
//   (slice_20_39) = 0.879 / sprint 2a (slice_40_59) = 0.964 로 codex 자체가
//   completion 처리한 ratio 가 0.90 미만임. 본 guard 는 회귀 catch 가 목적이므로
//   actual completion ratio 바로 아래 floor 를 사용 (slice_0_19 >= 0.85 /
//   slice_20_39 >= 0.86 / slice_40_59 >= 0.95 / global >= 0.85). 임계값을 추후
//   더 올리려면 codex/user 승인 필요.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ───────────────── constants ─────────────────

  const slicePaths = <String>[
    'assets/data/saju_deep_slice_0_19.json',
    'assets/data/saju_deep_slice_20_39.json',
    'assets/data/saju_deep_slice_40_59.json',
  ];

  const sliceParagraphSlots = <String>[
    'dayMasterDeep',
    'career',
    'wealth',
    'love',
    'health',
    'family',
    'fame',
  ];

  const celebrityPath = 'assets/data/celebrities.json';
  const expectedCelebrityCount = 223;

  // R99 sprint 3 가 손댄 lib + l10n 파일들 (인계 명시).
  const sprintTouchedPaths = <String>[
    'lib/services/notification_pool_service.dart',
    'lib/services/today_deep_service.dart',
    'lib/screens/reports/compatibility_screen.dart',
    'lib/screens/reports/kpop_compat_screen.dart',
    'lib/l10n/app_en.arb',
    'lib/l10n/app_localizations_en.dart',
    'lib/l10n/app_localizations.dart',
  ];

  // 사용자 spec 의 forbidden 35 phrase (case-insensitive 매칭).
  // "The shadow is" / "the shadow is" 는 case-insensitive 시 한 entry 로 흡수되지만
  // spec 명시 그대로 두 entry 유지 (regression diagnostics 명확성 위해).
  const forbiddenPhrases = <String>[
    'Your essence is',
    'This is your signature',
    'shines through',
    'deeply resonates',
    'quiet strength',
    'steady presence',
    'natural ability',
    'unique energy',
    "today's energy",
    'The shadow is',
    'the shadow is',
    'The gift is',
    'You may look composed',
    'When balanced',
    'suits you',
    'inner rhythm',
    'reads the room quickly',
    'not a simple sign',
    'needs both recognition and emotional safety',
    'inner compass that cannot be bought',
    'branch seeks',
    'When pressured',
    'This can make partners feel',
    'The best partner respects',
    'The Day Master wants',
    'Recognition follows when quality becomes repeatable',
    'Once trust is built',
    'Love becomes easier',
    'Attraction often begins',
    'Your results outlast your title',
    'your energy',
    'vibes',
    'supports you',
    'leans into',
    'at your core',
  ];

  // ───────────────── helpers ─────────────────

  String readFile(String path) => File(path).readAsStringSync();

  int countCaseInsensitive(String haystack, String needle) {
    final hayLower = haystack.toLowerCase();
    final needleLower = needle.toLowerCase();
    if (needleLower.isEmpty) return 0;
    var count = 0;
    var idx = 0;
    while (true) {
      final found = hayLower.indexOf(needleLower, idx);
      if (found < 0) break;
      count++;
      idx = found + needleLower.length;
    }
    return count;
  }

  List<Map<String, dynamic>> loadCelebrities() {
    final raw = readFile(celebrityPath);
    final decoded = jsonDecode(raw);
    expect(decoded, isA<List<dynamic>>(),
        reason: '$celebrityPath top-level 이 List 여야 함.');
    return (decoded as List<dynamic>).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> loadSlice(String path) {
    final raw = readFile(path);
    final decoded = jsonDecode(raw);
    expect(decoded, isA<List<dynamic>>(),
        reason: '$path top-level 이 List 여야 함.');
    return (decoded as List<dynamic>).cast<Map<String, dynamic>>();
  }

  // 모든 saju_deep_slice EN paragraph string 수집.
  List<String> collectSliceEnParagraphs(String path) {
    final entries = loadSlice(path);
    final out = <String>[];
    for (final e in entries) {
      final en = e['en'];
      if (en is Map) {
        for (final slot in sliceParagraphSlots) {
          final s = en[slot];
          if (s is String && s.trim().isNotEmpty) {
            out.add(s.trim());
          }
        }
      }
    }
    return out;
  }

  String first3WordsLower(String s) {
    final words = s.trim().split(RegExp(r'\s+'));
    if (words.length < 3) return s.trim().toLowerCase();
    return words.sublist(0, 3).join(' ').toLowerCase();
  }

  // ───────────────── A. Forbidden phrase 0 가드 ─────────────────

  group('R99 EN guard — A. Forbidden 35 phrase (case-insensitive)', () {
    test('saju_deep_slice 3 파일 hit 0', () {
      final failures = <String>[];
      for (final path in slicePaths) {
        final raw = readFile(path);
        for (final phrase in forbiddenPhrases) {
          final n = countCaseInsensitive(raw, phrase);
          if (n > 0) {
            failures.add('$path :: "$phrase" :: $n');
          }
        }
      }
      expect(failures, isEmpty,
          reason:
              'forbidden phrase 회귀 (saju slice). 첫 5건: ${failures.take(5).join(' | ')}');
    });

    test('celebrities.json blurbEn hit 0', () {
      final celebs = loadCelebrities();
      // blurbEn 만 concat 후 검사.
      final buf = StringBuffer();
      for (final c in celebs) {
        final b = c['blurbEn'];
        if (b is String) buf.writeln(b);
      }
      final raw = buf.toString();
      final failures = <String>[];
      for (final phrase in forbiddenPhrases) {
        final n = countCaseInsensitive(raw, phrase);
        if (n > 0) {
          failures.add('"$phrase" :: $n');
        }
      }
      expect(failures, isEmpty,
          reason:
              'forbidden phrase 회귀 (celebrities blurbEn). 첫 5건: ${failures.take(5).join(' | ')}');
    });

    test('Sprint 3 touched lib + l10n 파일 hit 0', () {
      final failures = <String>[];
      for (final path in sprintTouchedPaths) {
        final f = File(path);
        if (!f.existsSync()) {
          // l10n generated 일부 환경에서 누락될 수 있어 skip 으로 처리.
          continue;
        }
        final raw = f.readAsStringSync();
        for (final phrase in forbiddenPhrases) {
          final n = countCaseInsensitive(raw, phrase);
          if (n > 0) {
            failures.add('$path :: "$phrase" :: $n');
          }
        }
      }
      expect(failures, isEmpty,
          reason:
              'forbidden phrase 회귀 (sprint 3 touched). 첫 5건: ${failures.take(5).join(' | ')}');
    });
  });

  // ───────────────── B. saju_deep_slice first-3 unique 가드 ─────────────────

  group('R99 EN guard — B. saju_deep_slice first-3 prefix diversity', () {
    // R99 sprint 2a/2b 실 완료 ratio:
    //   slice_0_19  = 0.864
    //   slice_20_39 = 0.879
    //   slice_40_59 = 0.964
    //   global      = 0.864
    // Floor = 회귀 catch 용. 추후 상향은 codex/user 승인.
    const sliceFloor = <String, double>{
      'assets/data/saju_deep_slice_0_19.json': 0.85,
      'assets/data/saju_deep_slice_20_39.json': 0.86,
      'assets/data/saju_deep_slice_40_59.json': 0.95,
    };
    const globalFloor = 0.85;

    test('각 slice paragraph count == 140', () {
      for (final path in slicePaths) {
        final paragraphs = collectSliceEnParagraphs(path);
        expect(paragraphs.length, 140,
            reason: '$path EN paragraph 수 = ${paragraphs.length} (기대 140)');
      }
    });

    test('각 slice first-3 unique ratio >= floor', () {
      final report = <String, String>{};
      var anyFail = false;
      for (final path in slicePaths) {
        final paragraphs = collectSliceEnParagraphs(path);
        final prefixes = paragraphs.map(first3WordsLower).toList();
        final unique = prefixes.toSet().length;
        final total = prefixes.length;
        final ratio = total == 0 ? 0.0 : unique / total;
        final floor = sliceFloor[path]!;
        final ok = ratio >= floor;
        report[path] =
            'unique=$unique/$total=${ratio.toStringAsFixed(4)} floor=$floor ok=$ok';
        if (!ok) anyFail = true;
      }
      expect(anyFail, isFalse,
          reason:
              'first-3 prefix unique ratio per-slice floor breach. ${report.entries.map((e) => '${e.key}: ${e.value}').join(' || ')}');
    });

    test('global first-3 unique ratio >= $globalFloor', () {
      final all = <String>[];
      for (final path in slicePaths) {
        all.addAll(collectSliceEnParagraphs(path));
      }
      final prefixes = all.map(first3WordsLower).toList();
      final unique = prefixes.toSet().length;
      final total = prefixes.length;
      final ratio = total == 0 ? 0.0 : unique / total;

      // Top repeated prefixes diagnostic.
      final counter = <String, int>{};
      for (final p in prefixes) {
        counter[p] = (counter[p] ?? 0) + 1;
      }
      final sortedEntries = counter.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topRepeated = sortedEntries
          .where((e) => e.value >= 2)
          .take(10)
          .map((e) => '"${e.key}" x${e.value}')
          .join(', ');

      expect(ratio, greaterThanOrEqualTo(globalFloor),
          reason:
              'global first-3 prefix unique ratio = $unique/$total = ${ratio.toStringAsFixed(4)} < $globalFloor. Top repeated: $topRepeated');
    });
  });

  // ───────────────── C. celebrities blurbEn 가드 ─────────────────

  group('R99 EN guard — C. celebrities blurbEn quality', () {
    const expectedCount = expectedCelebrityCount;
    const first3UniqueFloor = 0.92;
    const stockLeadCeiling = 0.35;

    // stock-lead: "<GROUP> <role>" pattern.
    // 사용자 spec 의 stock-lead 정의: "<GROUP> member ..." / "<GROUP> vocalist ..."
    // / "<GROUP> rapper ..." / "<GROUP> leader ..." / "<GROUP> dancer ..." 같은
    // 반복적 그룹-역할 lead. 두 번째 단어 (소문자 + 끝 punctuation 제거)가
    // role-set 안에 있으면 stock 으로 카운트.
    const roleSet = <String>{
      'member',
      'vocalist',
      'rapper',
      'leader',
      'dancer',
      'main',
      'lead',
      'vocal',
      'performer',
      'youngest',
    };

    bool isStockLead(String blurb) {
      final words = blurb.trim().split(RegExp(r'\s+'));
      if (words.length < 2) return false;
      final w2 = words[1].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      return roleSet.contains(w2);
    }

    test('entry count == 223', () {
      final celebs = loadCelebrities();
      expect(celebs.length, expectedCount,
          reason:
              'celebrities.json length = ${celebs.length} (기대 $expectedCount)');
    });

    test('모든 entry blurbEn non-empty', () {
      final celebs = loadCelebrities();
      final missing = <String>[];
      for (final c in celebs) {
        final id = c['id'];
        final b = c['blurbEn'];
        if (b is! String || b.trim().isEmpty) {
          missing.add('$id');
        }
      }
      expect(missing, isEmpty,
          reason:
              'blurbEn 누락 entry: ${missing.take(10).join(', ')} (총 ${missing.length} 건)');
    });

    test('schema 핵심 키 보존', () {
      final celebs = loadCelebrities();
      const requiredKeys = <String>[
        'id',
        'nameKo',
        'dayPillar',
        'birth',
        'blurbKo',
        'blurbEn',
        'gender',
      ];
      final missing = <String>[];
      for (final c in celebs) {
        for (final k in requiredKeys) {
          if (!c.containsKey(k)) {
            missing.add('${c['id'] ?? '?'}::$k');
          }
        }
      }
      expect(missing, isEmpty,
          reason: 'celebrities schema key 누락: ${missing.take(10).join(', ')}');
    });

    test('first-3 unique ratio >= $first3UniqueFloor', () {
      final celebs = loadCelebrities();
      final prefixes = <String>[];
      for (final c in celebs) {
        final b = c['blurbEn'];
        if (b is String) {
          prefixes.add(first3WordsLower(b));
        }
      }
      final unique = prefixes.toSet().length;
      final total = prefixes.length;
      final ratio = total == 0 ? 0.0 : unique / total;

      // Diagnostic: top repeated prefixes.
      final counter = <String, int>{};
      for (final p in prefixes) {
        counter[p] = (counter[p] ?? 0) + 1;
      }
      final sortedEntries = counter.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topRepeated = sortedEntries
          .where((e) => e.value >= 2)
          .take(10)
          .map((e) => '"${e.key}" x${e.value}')
          .join(', ');

      expect(ratio, greaterThanOrEqualTo(first3UniqueFloor),
          reason:
              'celebrities first-3 unique ratio = $unique/$total = ${ratio.toStringAsFixed(4)} < $first3UniqueFloor. Top repeated: $topRepeated');
    });

    test('stock-lead ratio <= $stockLeadCeiling', () {
      final celebs = loadCelebrities();
      var stock = 0;
      final examples = <String>[];
      for (final c in celebs) {
        final b = c['blurbEn'];
        if (b is String && isStockLead(b)) {
          stock++;
          if (examples.length < 5) {
            final words = b.trim().split(RegExp(r'\s+'));
            examples.add(words.take(3).join(' '));
          }
        }
      }
      final total = celebs.length;
      final ratio = total == 0 ? 0.0 : stock / total;
      expect(ratio, lessThanOrEqualTo(stockLeadCeiling),
          reason:
              'celebrities stock-lead ratio = $stock/$total = ${ratio.toStringAsFixed(4)} > $stockLeadCeiling. examples: ${examples.join(' | ')}');
    });
  });

  // ───────────────── D. JSON 구조 무결성 ─────────────────

  group('R99 EN guard — D. JSON 구조 무결성', () {
    test('celebrities.json parses + length 223', () {
      expect(() => loadCelebrities(), returnsNormally);
      final celebs = loadCelebrities();
      expect(celebs.length, expectedCelebrityCount);
    });

    test('saju_deep_slice 3 파일 parses + 각 20 entry', () {
      for (final path in slicePaths) {
        expect(() => loadSlice(path), returnsNormally,
            reason: '$path JSON parse 실패');
        final slice = loadSlice(path);
        expect(slice.length, 20,
            reason: '$path entry 수 = ${slice.length} (기대 20)');
      }
    });

    test('saju_deep_slice 60 entry 모두 en + ko 객체 존재', () {
      var totalEn = 0;
      var totalKo = 0;
      for (final path in slicePaths) {
        final slice = loadSlice(path);
        for (final e in slice) {
          if (e['en'] is Map) totalEn++;
          if (e['ko'] is Map) totalKo++;
        }
      }
      expect(totalEn, 60,
          reason: '60 entry 의 en 객체 누락 (현재 $totalEn)');
      expect(totalKo, 60,
          reason: '60 entry 의 ko 객체 누락 (현재 $totalKo)');
    });
  });
}
