// R98 sprint 7 — content quality regression guard.
//
// 목적:
//   Sprint 5 audit FAIL + Sprint 2-bis repair 결과를 read-only 테스트로 고정.
//   본 파일은 source/data mutation 없이 assert 만 수행.
//
// 기준값 (Sprint 2-bis 최종 결과):
//   - life_paragraphs.json: top-level keys 70 / recursive strings 1400
//   - sprint 2 risk phrase 9종 모두 0
//   - personality 후반부 unique-suffix:
//       첫 마침표 이후 1.0000 / last-2 1.0000 / last-1 0.9833
//   - innate_character.M boilerplate ("옆에 두고 싶은 친근한 형/오빠") 0
//   - wealth_invest boilerplate ("1~3년 정도 들고 가는") 0
//   - 보너스 boilerplate 3종 0
//   - 신규 잔존: "느낌이 자연스러워요" 70 / "또렷한 면이" 22 /
//                 "한 가지에 깊이 빠지면 주변이 안 보일 정도로 몰입" (Sprint 2-bis 보고 30, 실측 다를 수 있음)
//   - 4개 data 파일에 "당신(은|의|이|에게)" 0
//   - 사용자 OCR 원문 5문장 0
//   - lib P0 forbidden phrase (시그니처 in notification_pool / 두 배로 in life_overview) 0
//   - life_paragraphs.json 짧은 forbidden 12종 0
//
// threshold 는 spec 그대로 사용. margin 이 좁으면 R99 sub-agent 의
// 정상 작업이 깨지므로 임의로 늘리지 않음.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ───────────────── helpers ─────────────────

  final lifePath = 'assets/data/life_paragraphs.json';
  final slicePaths = const <String>[
    'assets/data/saju_deep_slice_0_19.json',
    'assets/data/saju_deep_slice_20_39.json',
    'assets/data/saju_deep_slice_40_59.json',
  ];

  String readFile(String path) => File(path).readAsStringSync();

  Map<String, dynamic> loadLife() {
    final raw = readFile(lifePath);
    final decoded = jsonDecode(raw);
    expect(decoded, isA<Map<String, dynamic>>(),
        reason: '$lifePath top-level 이 Map 이어야 함.');
    return decoded as Map<String, dynamic>;
  }

  int countRecursiveStrings(dynamic node) {
    if (node is String) return 1;
    if (node is List) {
      var total = 0;
      for (final v in node) {
        total += countRecursiveStrings(v);
      }
      return total;
    }
    if (node is Map) {
      var total = 0;
      for (final v in node.values) {
        total += countRecursiveStrings(v);
      }
      return total;
    }
    return 0;
  }

  // life_paragraphs.json 의 모든 personality string 60 + base 10 = 70 수집.
  List<String> collectPersonalities(Map<String, dynamic> data) {
    final out = <String>[];
    data.forEach((_, v) {
      if (v is Map && v['personality'] is String) {
        out.add(v['personality'] as String);
      }
    });
    return out;
  }

  // 첫 마침표 이후 substring trim (Sprint 2-bis 보고 기준).
  String afterFirstPeriod(String s) {
    final idx = s.indexOf('.');
    if (idx < 0 || idx + 1 >= s.length) return s.trim();
    return s.substring(idx + 1).trim();
  }

  // 마지막 N 문장 (마침표 기준) 추출.
  String lastNSentences(String s, int n) {
    // 한국어 문장 끝 '.' / '?' / '!' 기준.
    final parts = s
        .split(RegExp(r'(?<=[\.\?\!])\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length <= n) return parts.join(' ');
    return parts.sublist(parts.length - n).join(' ');
  }

  // ───────────────── 1. 구조 가드 ─────────────────

  group('R98 sprint 7 — 1. life_paragraphs.json 구조 가드', () {
    test('parse OK', () {
      expect(() => loadLife(), returnsNormally,
          reason: '$lifePath JSON parse 실패 — Sprint 2-bis 결과 corrupted 의심');
    });

    test('top-level keys == 70', () {
      final data = loadLife();
      expect(data.keys.length, 70,
          reason: '60 일주 + 10 일간 base = 70 keys 보존 (현재 ${data.keys.length})');
    });

    test('recursive string entry count == 1400', () {
      final data = loadLife();
      final total = countRecursiveStrings(data);
      expect(total, 1400,
          reason: '1400 string entries 보존 (현재 $total)');
    });
  });

  // ───────────────── 2. Sprint 2 risk phrase 0 가드 ─────────────────

  group('R98 sprint 7 — 2. Sprint 2 risk phrase 0 (life_paragraphs.json)', () {
    final raw = readFile(lifePath);

    test('분위기 분위기 0', () {
      expect('분위기 분위기'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 12. Sprint 2-bis 결과: 0.');
    });

    test('광택 있는 결이 0', () {
      expect('광택 있는 결이'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 46. Sprint 2-bis 결과: 0.');
    });

    test('단톡 안 한 마디로 분위기 0', () {
      expect('단톡 안 한 마디로 분위기'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 80. Sprint 2-bis 결과: 0.');
    });

    test(r'결을 .{1,15}풍겨요 RegExp 0', () {
      final n = RegExp(r'결을 .{1,15}풍겨요').allMatches(raw).length;
      expect(n, 0,
          reason: 'Sprint 5 audit baseline: 10. Sprint 2-bis 결과: 0.');
    });

    test('(자기만의|본인만의|본인다운 색|대표 분위기|대표 색깔|고유한 색깔) 한 곡 RegExp 0', () {
      final n = RegExp(r'(자기만의|본인만의|본인다운 색|대표 분위기|대표 색깔|고유한 색깔) 한 곡')
          .allMatches(raw)
          .length;
      expect(n, 0,
          reason: 'Sprint 5 audit baseline: 23. Sprint 2-bis 결과: 0.');
    });

    test('톤 한 곡 0', () {
      expect('톤 한 곡'.allMatches(raw).length, 0,
          reason: 'Sprint 2-bis 결과: 0.');
    });

    test('색 한 곡 / 색깔 한 곡 0', () {
      expect('색 한 곡'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 7. Sprint 2-bis 결과: 0.');
      expect('색깔 한 곡'.allMatches(raw).length, 0,
          reason: 'Sprint 2-bis 결과: 0.');
    });

    test('분위기예요 0', () {
      expect('분위기예요'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 145. Sprint 2-bis 결과: 0.');
    });

    test('인장 분위기 0', () {
      expect('인장 분위기'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 6. Sprint 2-bis 결과: 0.');
    });
  });

  // ───────────────── 3. personality 후반부 변별력 ─────────────────

  group('R98 sprint 7 — 3. personality 후반부 변별력', () {
    test('60 일주 personality 첫 마침표 이후 unique-suffix ratio >= 0.70',
        () {
      final data = loadLife();
      final tails = <String>[];
      for (final p in collectPersonalities(data)) {
        final tail = afterFirstPeriod(p);
        if (tail.isNotEmpty) tails.add(tail);
      }
      // 60 일주 + 10 일간 base = 최대 70.
      expect(tails.length, greaterThanOrEqualTo(60),
          reason: 'personality 필드가 너무 적음 — 데이터 손상 의심 (현재 ${tails.length})');
      final unique = tails.toSet().length;
      final ratio = unique / tails.length;
      // Sprint 2-bis 결과 1.0000. threshold 0.70 (margin 0.30).
      expect(ratio, greaterThanOrEqualTo(0.70),
          reason:
              '첫 마침표 이후 unique ratio $unique/${tails.length} = ${ratio.toStringAsFixed(4)} '
              '< 0.70 — personality 후반부 boilerplate 회귀 (Sprint 2-bis 보고: 1.0000)');
    });

    test('60 일주 personality 마지막 2 문장 unique ratio >= 0.95', () {
      final data = loadLife();
      final tails = <String>[];
      for (final p in collectPersonalities(data)) {
        final tail = lastNSentences(p, 2);
        if (tail.isNotEmpty) tails.add(tail);
      }
      expect(tails.length, greaterThanOrEqualTo(60),
          reason: 'personality 필드가 너무 적음 (현재 ${tails.length})');
      final unique = tails.toSet().length;
      final ratio = unique / tails.length;
      // Sprint 2-bis 결과 1.0000. threshold 0.95.
      expect(ratio, greaterThanOrEqualTo(0.95),
          reason:
              'last-2 unique ratio $unique/${tails.length} = ${ratio.toStringAsFixed(4)} '
              '< 0.95 — personality 끝 2 문장 boilerplate 회귀 (Sprint 2-bis 보고: 1.0000)');
    });
  });

  // ───────────────── 4. innate_character.M boilerplate ─────────────────

  group('R98 sprint 7 — 4. innate_character.M boilerplate', () {
    test('"옆에 두고 싶은 친근한 형/오빠" hit <= 5', () {
      final data = loadLife();
      var hit = 0;
      data.forEach((_, v) {
        if (v is Map) {
          final ic = v['innate_character'];
          if (ic is Map) {
            final m = ic['M'];
            if (m is String && m.contains('옆에 두고 싶은 친근한 형/오빠')) hit++;
          }
        }
      });
      expect(hit, lessThanOrEqualTo(5),
          reason:
              '"옆에 두고 싶은 친근한 형/오빠" hit $hit (Sprint 5 audit baseline: 20+. Sprint 2-bis 결과: 0. threshold: 5)');
    });
  });

  // ───────────────── 5. wealth_invest boilerplate ─────────────────

  group('R98 sprint 7 — 5. wealth_invest boilerplate', () {
    test('"1~3년 정도 들고 가는" hit <= 10', () {
      final data = loadLife();
      var hit = 0;
      data.forEach((_, v) {
        if (v is Map) {
          final w = v['wealth_invest'];
          if (w is String && w.contains('1~3년 정도 들고 가는')) hit++;
        }
      });
      expect(hit, lessThanOrEqualTo(10),
          reason:
              '"1~3년 정도 들고 가는" hit $hit (Sprint 5 audit baseline: 60. Sprint 2-bis 결과: 0. threshold: 10)');
    });
  });

  // ───────────────── 6. 보너스 boilerplate 0 가드 ─────────────────

  group('R98 sprint 7 — 6. 보너스 boilerplate (Sprint 2-bis 가 0 으로 만든 것)', () {
    final raw = readFile(lifePath);

    test('"쟤 은근 진심이다" hit == 0', () {
      expect('쟤 은근 진심이다'.allMatches(raw).length, 0,
          reason: 'Sprint 5 audit baseline: 21+. Sprint 2-bis 결과: 0.');
    });

    test('"한 번 본인 사람이라고 생각한 상대" hit == 0', () {
      expect('한 번 본인 사람이라고 생각한 상대'.allMatches(raw).length, 0,
          reason: 'Sprint 2-bis 결과: 0.');
    });

    test('"상대가 곁을 떠나지 못해요" hit == 0', () {
      expect('상대가 곁을 떠나지 못해요'.allMatches(raw).length, 0,
          reason:
              'Sprint 5 audit baseline: 30+. Sprint 2-bis 결과: 0.');
    });
  });

  // ───────────────── 7. 신규 잔존 패턴 가드 ─────────────────

  group('R98 sprint 7 — 7. 신규 잔존 패턴 (Sprint 2-bis 가 만든 새 boilerplate)', () {
    final raw = readFile(lifePath);

    test('"느낌이 자연스러워요" hit <= 80', () {
      final n = '느낌이 자연스러워요'.allMatches(raw).length;
      expect(n, lessThanOrEqualTo(80),
          reason: '"느낌이 자연스러워요" hit $n (Sprint 2-bis 보고: 70. threshold: 80)');
    });

    test('"또렷한 면이" hit <= 30', () {
      final n = '또렷한 면이'.allMatches(raw).length;
      expect(n, lessThanOrEqualTo(30),
          reason: '"또렷한 면이" hit $n (Sprint 2-bis 보고: 22. threshold: 30)');
    });

    test('"한 가지에 깊이 빠지면 주변이 안 보일 정도로 몰입" hit <= 35', () {
      final n = '한 가지에 깊이 빠지면 주변이 안 보일 정도로 몰입'.allMatches(raw).length;
      expect(n, lessThanOrEqualTo(35),
          reason:
              '"한 가지에 깊이 빠지면 주변이 안 보일 정도로 몰입" hit $n '
              '(Sprint 2-bis 보고: 30. threshold: 35)');
    });
  });

  // ───────────────── 8. data "당신" 가드 ─────────────────

  group('R98 sprint 7 — 8. user-facing 본문 "당신" 가드', () {
    final pattern = RegExp(r'당신(은|의|이|에게)');

    test('life_paragraphs.json 당신(은|의|이|에게) 0', () {
      final raw = readFile(lifePath);
      final n = pattern.allMatches(raw).length;
      expect(n, 0,
          reason: '$lifePath 안에 당신 hits $n (반말+본인 톤 통일 룰 위반)');
    });

    test('saju_deep_slice 3 파일 당신(은|의|이|에게) 0', () {
      for (final p in slicePaths) {
        final raw = readFile(p);
        final n = pattern.allMatches(raw).length;
        expect(n, 0, reason: '$p 안에 당신 hits $n (반말+본인 톤 통일 룰 위반)');
      }
    });
  });

  // ───────────────── 9. 사용자 OCR 원문 5문장 0 가드 ─────────────────

  group('R98 sprint 7 — 9. 사용자 OCR 원문 5문장 0 가드', () {
    // life_paragraphs.json + saju_deep_slice + lib scope.
    const ocrPhrases = <String>[
      '본인 스타일대로 가는 쪽이 정답이에요',
      '사람들이 본인을 바로 기억해요',
      '그게 오늘 본인의 장점이에요',
      '배움이 잘 자리잡는 흐름이에요',
      '오늘 충분한 수면 한 시간이',
    ];

    final dataPaths = <String>[lifePath, ...slicePaths];

    test('5 OCR 원문 모두 4개 data 파일에 0건', () {
      for (final phrase in ocrPhrases) {
        for (final path in dataPaths) {
          final raw = readFile(path);
          final n = phrase.allMatches(raw).length;
          expect(n, 0,
              reason: '$path 안에 사용자 OCR 원문 "$phrase" $n 건 잔존 (mandate: 0)');
        }
      }
    });

    test('5 OCR 원문 모두 lib 전체에 0건', () {
      // lib 디렉토리의 모든 .dart 파일을 재귀 스캔.
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue,
          reason: 'lib/ 디렉토리가 존재하지 않음');
      final dartFiles = libDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(dartFiles.length, greaterThan(10),
          reason: 'lib/*.dart 파일이 비정상적으로 적음 (${dartFiles.length})');

      for (final phrase in ocrPhrases) {
        var hit = 0;
        final hitFiles = <String>[];
        for (final f in dartFiles) {
          final raw = f.readAsStringSync();
          if (raw.contains(phrase)) {
            hit++;
            hitFiles.add(f.path);
          }
        }
        expect(hit, 0,
            reason:
                'lib 안에 사용자 OCR 원문 "$phrase" hit $hit (files: $hitFiles)');
      }
    });
  });

  // ───────────────── 10. P0 lib forbidden phrase 가드 ─────────────────

  group('R98 sprint 7 — 10. P0 lib forbidden phrase (read-only file scan)',
      () {
    test('lib/services/notification_pool_service.dart 에 "시그니처" 0', () {
      final path = 'lib/services/notification_pool_service.dart';
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: '$path not found');
      final raw = f.readAsStringSync();
      final n = '시그니처'.allMatches(raw).length;
      expect(n, 0,
          reason:
              '$path 안에 "시그니처" hit $n (Sprint 5 audit P0: line 172 user-facing fix 필요)');
    });

    test('lib/services/life_overview_service.dart 에 "두 배로" 0', () {
      final path = 'lib/services/life_overview_service.dart';
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: '$path not found');
      final raw = f.readAsStringSync();
      final n = '두 배로'.allMatches(raw).length;
      expect(n, 0,
          reason:
              '$path 안에 "두 배로" hit $n (Sprint 5 audit P0: line 89 user-facing fix 필요)');
    });
  });

  // ───────────────── 11. 짧은 forbidden phrase 0 가드 ─────────────────

  group('R98 sprint 7 — 11. 짧은 forbidden phrase 0 (life_paragraphs.json)',
      () {
    final raw = readFile(lifePath);

    // 사용자 mandate: data 파일 0 baseline.
    const forbiddens = <String>[
      '결이에요',
      '시그니처',
      '본성이',
      '그대로 묻어나요',
      '자아의 무게로 자리잡고 있어요',
      '단정하고 세련된 본성이',
      '정답이에요',
      '두 배로',
      '단 한 번의 정답',
      '다음 분기 전체',
      '한 단계 위',
      '본인답게 가는 게',
    ];

    for (final phrase in forbiddens) {
      test('"$phrase" hit == 0', () {
        final n = phrase.allMatches(raw).length;
        expect(n, 0,
            reason:
                '$lifePath 안에 "$phrase" hit $n (Sprint 5 audit baseline: 0. Sprint 2-bis 결과: 0)');
      });
    }
  });
}
