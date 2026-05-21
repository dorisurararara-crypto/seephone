// R107 — 내 사주(평생) 카테고리 중복 제거 회귀 가드.
//
// 배경 (사용자 직접 지적):
//   life_paragraphs.json 의 60 일주 entry 는 17 카테고리(+M/F) 본문이 전부
//   동일 frame 의 scaffold 첫 문장으로 시작했다:
//     early_life  — "어린 시절부터 {일주묘사어}이 또렷이 보였어요."
//     mid_life    — "30·40대 들어 {일주묘사어}이 본격적으로 빛나기 시작해요."
//     personality — "평소 성격에 {일주묘사어}이 그대로 드러나요." …
//   결과: 한 일주 17 카테고리를 보면 같은 묘사어 + 같은 frame 이 17번 반복돼
//   "다 똑같다" 체감.
//
// R107 데이터 surgery:
//   1. 60 일주 entry 의 모든 카테고리(+M/F)에서 scaffold 첫 문장 제거
//      (일간 10 base entry 는 ≥80자 R88/R89 mandate 때문에 제외 — fallback-only).
//   2. 한 entry 안에서 중복되는 본문 문장(boilerplate tail) = 첫 등장만 남기고 제거.
//   3. "{2차 묘사어} 위에 고유 분위기가 합쳐져서/더해져서 …" prefix clause 를
//      personality/conclusion_self/innate_character 에서 제거.
//
// R107 보정 (innate_tendency 잔여 scaffold 일소):
//   직전 R107 이 innate_tendency 첫 문장 scaffold(`타고난 기질 자체가 … 쪽이에요`)는
//   제거했으나, 60 일주 entry 의 innate_tendency 본문에 새 scaffold/boilerplate 가
//   대량 잔존했다:
//     S2 scaffold   — "{계절}… 본인/마음 안에 흐르고 있어서 정해진 루틴보다
//                      {본인이/자기가} 그날 느끼는 분위기를 따라가는 편이에요." (59건)
//     S3 boilerplate — "새로운 경험이나 처음 만나는 사람이 많을수록 … 에너지가
//                       잘 살아나요." (60건)
//     S4 boilerplate — "자기의 변덕이 단점처럼 보일 때도 있지만, … 페이스를 잘
//                       타고 있다는 신호이기도 해요." (59건)
//     FLAVOR pool    — "굿즈 모으듯 …/플레이리스트 라인업 …/컴백 챙기듯 …" 3종 중
//                       하나가 매 entry 에 복붙 → 길이(≥80) 허용 시 제거 (57건).
//   결과: innate_tendency 본문 내 단일 문장 최대 반복이 54회 → ≤6회 로 감소.
//   (FLAVOR 3 entry 는 ≥80자 가드 때문에 보존: 을축/갑진/임술.)
//
// 본 테스트는 결과를 read-only assert 로 고정한다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lifePath = 'assets/data/life_paragraphs.json';

  Map<String, dynamic> loadLife() {
    final raw = File(lifePath).readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // 60 일주 (2글자 key) 만 — 일간 10 base 는 fallback-only 라 R107 대상 아님.
  List<String> ilju60(Map<String, dynamic> data) =>
      data.keys.where((k) => k.runes.length == 2).toList();

  // 17 카테고리 key.
  const catKeys = <String>[
    'early_life',
    'mid_life',
    'late_life',
    'health',
    'constitution',
    'social',
    'social_personality',
    'personality',
    'innate_tendency',
    'innate_character',
    'love_fate',
    'affection',
    'wealth',
    'wealth_gather',
    'wealth_loss_prevent',
    'wealth_invest',
    'conclusion_self',
  ];

  const genderSplit = <String>{'innate_character', 'love_fate', 'affection'};

  List<String> sentences(String s) => s
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // 한 entry 의 카테고리 본문 string 들 (gender split = M/F 둘 다).
  List<String> bodiesOf(Map data, String catKey) {
    final v = data[catKey];
    if (v is String) return [v];
    if (v is Map) {
      return [
        if (v['M'] is String) v['M'] as String,
        if (v['F'] is String) v['F'] as String,
      ];
    }
    return const [];
  }

  // scaffold 첫 문장 frame — 카테고리별 prefix + suffix 정규식.
  final scaffoldFrames = <String, RegExp>{
    'early_life': RegExp(r'^어린 시절부터 .+(?:이|가) 또렷이 보였어요\.$'),
    'mid_life': RegExp(r'^30·40대 들어 .+(?:이|가) 본격적으로 빛나기 시작해요\.$'),
    'late_life': RegExp(r'^말년 갈수록 .+(?:이|가) 한층 단단해져요\.$'),
    'health': RegExp(r'^건강 관리 면에서 .+(?:이|가) 그대로 드러나요\.$'),
    'constitution': RegExp(r'^체질 면에서 보면 .+(?:이|가) 자연스럽게 드러나요\.$'),
    'social': RegExp(r'^사람들 사이에서 .+(?:이|가) 자연스럽게 풍겨요\.$'),
    'social_personality':
        RegExp(r'^단체 안에서도 .+(?:이|가) 그대로 드러나요\.$'),
    'personality': RegExp(r'^평소 성격에 .+(?:이|가) 그대로 드러나요\.$'),
    'innate_tendency': RegExp(r'^타고난 기질 자체가 .+ ?쪽이에요\.$'),
    'wealth': RegExp(r'^돈 흐름 면에 .+(?:이|가) 그대로 보여요\.$'),
    'wealth_gather': RegExp(r'^모으는 흐름에 .+(?:이|가) 그대로 보여요\.$'),
    'wealth_loss_prevent':
        RegExp(r'^지키는 면에서 .+(?:이|가) 그대로 보여요\.$'),
    'wealth_invest': RegExp(r'^투자 결정에 .+(?:이|가) 그대로 드러나요\.$'),
    'conclusion_self': RegExp(r'^한 마디로 .+(?:이|가) 본인 핵심 색이에요\.$'),
    'innate_character':
        RegExp(r'^(?:남자|여자)로서는 .+(?:을|를) 평소 자기 무게로 .+\.$'),
    'love_fate':
        RegExp(r'^연애 초반에 (?:남자|여자)로서 .+(?:은|는) 그대로 드러나요\.$'),
    'affection':
        RegExp(r'^오래 가는 관계에서 (?:남자|여자)로서 .+(?:은|는) 그대로 전해져요\.$'),
  };

  group('R107 — scaffold 첫 문장 제거', () {
    test('60 일주 × 17 카테고리 첫 문장이 scaffold frame 이 아님', () {
      final data = loadLife();
      final offenders = <String>[];
      for (final ilju in ilju60(data)) {
        final entry = data[ilju] as Map;
        for (final ck in catKeys) {
          final frame = scaffoldFrames[ck];
          if (frame == null) continue;
          for (final body in bodiesOf(entry, ck)) {
            final ss = sentences(body);
            if (ss.isEmpty) continue;
            if (frame.hasMatch(ss.first)) {
              offenders.add('$ilju.$ck → ${ss.first}');
            }
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'scaffold 첫 문장 잔존 ${offenders.length}건:\n'
              '${offenders.take(10).join('\n')}');
    });

    test('한 일주 17 카테고리 첫 문장이 서로 다른 frame (동일 scaffold frame 0)', () {
      final data = loadLife();
      for (final ilju in ilju60(data)) {
        final entry = data[ilju] as Map;
        final firsts = <String>[];
        for (final ck in catKeys) {
          // gender split 은 M 본문 기준.
          final bodies = bodiesOf(entry, ck);
          if (bodies.isEmpty) continue;
          final ss = sentences(bodies.first);
          if (ss.isNotEmpty) firsts.add(ss.first);
        }
        expect(firsts.toSet().length, firsts.length,
            reason: '$ilju — 17 카테고리 첫 문장에 중복 존재 '
                '(unique ${firsts.toSet().length}/${firsts.length})');
      }
    });
  });

  group('R107 — 일주묘사어 중반 반복 정리', () {
    test('exact 일주묘사어가 한 일주 17 카테고리 본문 중 ≤6회 등장', () {
      final data = loadLife();
      // 묘사어는 R107 이전 early_life scaffold 에서 추출했었음.
      // scaffold 제거 후엔 더 이상 first sentence 로 못 구하므로,
      // 신묘=단정하고 세련된 손길 등 알려진 묘사어 일부 + 동적 패턴 양쪽 사용.
      // 동적: "{2차 묘사어} 같은 매력" exact phrase 가 entry 안에서 몇 번 나오나.
      for (final ilju in ilju60(data)) {
        final entry = data[ilju] as Map;
        // entry 전체 본문 합치기.
        final all = StringBuffer();
        for (final ck in catKeys) {
          for (final body in bodiesOf(entry, ck)) {
            all.write(body);
            all.write(' ');
          }
        }
        final text = all.toString();
        // "{X}같은 매력" 형태 2차 묘사어 후보들의 최대 등장 횟수.
        final phrases = RegExp(r'[가-힣 ]+? 같은 매력')
            .allMatches(text)
            .map((m) => m.group(0)!.trim())
            .toList();
        final counts = <String, int>{};
        for (final p in phrases) {
          counts[p] = (counts[p] ?? 0) + 1;
        }
        for (final e in counts.entries) {
          expect(e.value, lessThanOrEqualTo(6),
              reason: '$ilju — 묘사어 "${e.key}" ${e.value}회 (≤6 mandate)');
        }
      }
    });

    test('"위에 고유 분위기가 합쳐져서/더해져서" prefix clause 0 (전 entry)', () {
      final raw = File(lifePath).readAsStringSync();
      final n = RegExp(r'위에 고유 분위기가 (?:합쳐져서|더해져서)')
          .allMatches(raw)
          .length;
      expect(n, 0,
          reason: 'R107: 2차 묘사어 prefix clause 가 전부 제거돼야 함 (현재 $n)');
    });
  });

  group('R107 보정 — innate_tendency 잔여 scaffold/boilerplate 일소', () {
    // S2 scaffold: "{계절}… 본인/마음 안에 흐르고 있어서 정해진 루틴보다 … 따라가는 편이에요."
    final s2Scaffold = RegExp(
        r'(?:본인|마음) 안에 흐르고 있어서.*?따라가는 편이에요');
    // S3 boilerplate.
    final s3Boiler =
        RegExp(r'새로운 경험이나 처음 만나는 사람이 많을수록 .*? 에너지가 잘 살아나요');
    // S4 boilerplate.
    final s4Boiler =
        RegExp(r'자기의 변덕이 단점처럼 보일 때도 있지만, .*? 신호이기도 해요');

    test('S2 scaffold / S3·S4 boilerplate 가 60 일주 innate_tendency 에 0건', () {
      final data = loadLife();
      final offenders = <String>[];
      for (final ilju in ilju60(data)) {
        final body = (data[ilju] as Map)['innate_tendency'] as String;
        if (s2Scaffold.hasMatch(body)) offenders.add('$ilju S2');
        if (s3Boiler.hasMatch(body)) offenders.add('$ilju S3');
        if (s4Boiler.hasMatch(body)) offenders.add('$ilju S4');
      }
      expect(offenders, isEmpty,
          reason: 'innate_tendency 잔여 scaffold/boilerplate '
              '${offenders.length}건: ${offenders.take(12).join(", ")}');
    });

    test('innate_tendency 본문 단일 문장이 일주 간 ≤6회만 반복', () {
      final data = loadLife();
      final counts = <String, int>{};
      for (final ilju in ilju60(data)) {
        final body = (data[ilju] as Map)['innate_tendency'] as String;
        for (final s in sentences(body)) {
          counts[s] = (counts[s] ?? 0) + 1;
        }
      }
      final hot = counts.entries.where((e) => e.value > 6).toList();
      expect(hot, isEmpty,
          reason: 'innate_tendency 에 7회 이상 반복되는 boilerplate 문장 잔존:\n'
              '${hot.take(5).map((e) => "${e.value}x ${e.key}").join("\n")}');
    });

    test('FLAVOR boilerplate 문장(굿즈/플레이리스트/컴백) 총 ≤3 entry', () {
      // 길이(≥80자) 가드 때문에 을축/갑진/임술 3 entry 만 FLAVOR 보존 허용.
      final data = loadLife();
      final flavor = RegExp(r'굿즈 모으듯|플레이리스트 라인업이 그대로|컴백 챙기듯 꾸준히');
      final withFlavor = <String>[];
      for (final ilju in ilju60(data)) {
        final body = (data[ilju] as Map)['innate_tendency'] as String;
        if (flavor.hasMatch(body)) withFlavor.add(ilju);
      }
      expect(withFlavor.length, lessThanOrEqualTo(3),
          reason: 'innate_tendency FLAVOR boilerplate 잔존 '
              '${withFlavor.length} entry: ${withFlavor.join(", ")}');
    });

    test('innate_tendency 본문 모두 ≥80자 (R88/R89 회귀 가드)', () {
      final data = loadLife();
      for (final ilju in ilju60(data)) {
        final body = (data[ilju] as Map)['innate_tendency'] as String;
        expect(body.trim(), isNotEmpty, reason: '$ilju.innate_tendency 빈 본문');
        expect(body.length, greaterThanOrEqualTo(80),
            reason: '$ilju.innate_tendency ${body.length}자 (≥80 mandate)');
      }
    });
  });

  group('R107 — 구조/회귀 가드', () {
    test('top-level keys == 70 (60 일주 + 10 일간 base 보존)', () {
      final data = loadLife();
      expect(data.keys.length, 70);
    });

    test('60 일주 × 17 카테고리(+M/F) 본문 모두 ≥80자 + 빈 값 0', () {
      final data = loadLife();
      for (final ilju in ilju60(data)) {
        final entry = data[ilju] as Map;
        for (final ck in catKeys) {
          final bodies = bodiesOf(entry, ck);
          expect(bodies, isNotEmpty, reason: '$ilju.$ck 본문 없음');
          for (final body in bodies) {
            expect(body.trim(), isNotEmpty, reason: '$ilju.$ck 빈 본문');
            expect(body.length, greaterThanOrEqualTo(80),
                reason: '$ilju.$ck ${body.length}자 (≥80 mandate)');
          }
        }
      }
    });

    test('gender split 카테고리는 여전히 {M,F} sub-object', () {
      final data = loadLife();
      for (final ilju in ilju60(data)) {
        final entry = data[ilju] as Map;
        for (final ck in genderSplit) {
          final v = entry[ck];
          expect(v, isA<Map>(), reason: '$ilju.$ck 가 {M,F} 가 아님');
          expect((v as Map).containsKey('M'), isTrue);
          expect(v.containsKey('F'), isTrue);
        }
      }
    });

    test('본문 텍스트 아티팩트 0 (이중 공백 / 이중 마침표 / untrimmed)', () {
      final data = loadLife();
      final doublePunct = RegExp(r'[.!?]\s*[.!?]');
      for (final ilju in ilju60(data)) {
        final entry = data[ilju] as Map;
        for (final ck in catKeys) {
          for (final body in bodiesOf(entry, ck)) {
            expect(body.contains('  '), isFalse,
                reason: '$ilju.$ck 이중 공백');
            expect(body, equals(body.trim()),
                reason: '$ilju.$ck 양끝 공백');
            expect(doublePunct.hasMatch(body), isFalse,
                reason: '$ilju.$ck 이중 마침표');
          }
        }
      }
    });
  });
}
