// Round 82 sprint 8 — saju_deep_slice 30 sample ko 본문 tone audit.
//
// 사용자 verbatim (인수인계.md 2026-05-15 R82 섹션 line 14):
//   "내용도 부자연스러운것도 많고"
//
// 본 test 는 R82 sprint 8 generator 가 재작성한 30 entry sample 영역 ko 본문이
// 다음을 만족하는지 검증:
//   - 한자 jargon blacklist 0 (벼린·도검·정수·본질·결을·구조예요·구조에요)
//   - AI 슬롭 blacklist 0 (흐름이·센터처럼·본인의 결·본인 결 단독·당신의 결 단독)
//   - 5행 골든 sample (idx 27 辛卯, 1995-10-27 男 17시 일주) 본문 보존 + 재작성
//   - 30 sample 영역 ko 본문 각 6 카테고리 (love/career/wealth/health/family/fame/dayMasterDeep) 비어있지 않음
//
// 보존 mandate:
//   - 60 entry 갯수 (240 entry 본문) 변동 X
//   - JSON 형식 보존
//   - R74 ko_content_quality_test 회귀 가드 (회귀 X)
//   - R75/R80 신묘 oneline phrase = "단단한데 말투는 부드러운" (별도 wire, 본 본문과 무관)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // R82 sprint 8 에서 재작성한 30 entry 의 index.
  // file distribution: 0_19 10 entry / 20_39 10 entry / 40_59 10 entry.
  // idx 27 = 5행 골든 sample (1995-10-27 男 17시 일주 辛卯).
  const sampleIndices = <int>{
    // 0_19 file
    2, 6, 8, 10, 11, 13, 14, 15, 18, 19,
    // 20_39 file
    20, 24, 26, 27, 29, 32, 33, 36, 37, 39,
    // 40_59 file
    41, 42, 44, 46, 47, 48, 49, 52, 55, 57,
  };

  const files = <String>[
    'assets/data/saju_deep_slice_0_19.json',
    'assets/data/saju_deep_slice_20_39.json',
    'assets/data/saju_deep_slice_40_59.json',
  ];

  const koFields = <String>[
    'dayMasterDeep',
    'career',
    'wealth',
    'love',
    'health',
    'family',
    'fame',
  ];

  List<Map<String, dynamic>> loadAll() {
    final all = <Map<String, dynamic>>[];
    for (final f in files) {
      final raw = File(f).readAsStringSync();
      final parsed = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      all.addAll(parsed);
    }
    return all;
  }

  group('R82 sprint 8 — saju_deep_slice 30 sample ko tone audit', () {
    test('60 entry × 3 file = 180 entry 보존 (240 entry 갯수 mandate)', () {
      for (final f in files) {
        final data =
            (jsonDecode(File(f).readAsStringSync()) as List).cast<Map<String, dynamic>>();
        expect(data.length, 20,
            reason: 'R82 sprint 8 mandate — 각 file 정확히 20 entry (60 entry / 3 file). file=$f');
      }
    });

    test('30 sample index 모두 존재', () {
      final all = loadAll();
      final allIndices = all.map((e) => e['index'] as int).toSet();
      for (final i in sampleIndices) {
        expect(allIndices.contains(i), isTrue,
            reason: 'R82 sprint 8 — sample idx=$i 누락');
      }
    });

    test('30 sample ko 본문 한자 jargon blacklist 0', () {
      // R82 sprint 8 mandate — 한자 jargon noun 단독 사용 0.
      final all = loadAll();
      final hardBlacklist = <RegExp>[
        RegExp(r'벼린'),
        RegExp(r'도검'),
        RegExp(r'(?<![가-힣])정수(?![가-힣])'),
        RegExp(r'(?<![가-힣])본질(?![가-힣])'),
        RegExp(r'결을\s'),
        RegExp(r'구조예요'),
        RegExp(r'구조에요'),
      ];
      final hits = <String>[];
      for (final e in all) {
        final idx = e['index'] as int;
        if (!sampleIndices.contains(idx)) continue;
        final ko = e['ko'] as Map<String, dynamic>;
        for (final fld in koFields) {
          final v = ko[fld] as String? ?? '';
          for (final pat in hardBlacklist) {
            if (pat.hasMatch(v)) {
              hits.add('idx=$idx $fld: ${pat.pattern}');
            }
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'R82 sprint 8 한자 jargon blacklist hit:\n${hits.join("\n")}');
    });

    test('30 sample ko 본문 AI 슬롭 blacklist 0', () {
      // R82 sprint 8 mandate — AI 슬롭 직역체 noun 단독 패턴 0.
      // "본인 결과" / "본인 결정" 류 정상 어휘는 부정 lookahead 로 제외.
      final all = loadAll();
      final slopBlacklist = <RegExp>[
        RegExp(r'흐름이'),
        RegExp(r'센터처럼'),
        RegExp(r'본인의\s*결(?![과정])'),
        RegExp(r'본인\s+결(?![과정])'),
        RegExp(r'당신의\s*결(?![과정])'),
      ];
      final hits = <String>[];
      for (final e in all) {
        final idx = e['index'] as int;
        if (!sampleIndices.contains(idx)) continue;
        final ko = e['ko'] as Map<String, dynamic>;
        for (final fld in koFields) {
          final v = ko[fld] as String? ?? '';
          for (final pat in slopBlacklist) {
            if (pat.hasMatch(v)) {
              hits.add('idx=$idx $fld: ${pat.pattern}');
            }
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'R82 sprint 8 AI 슬롭 blacklist hit:\n${hits.join("\n")}');
    });

    test('30 sample ko 본문 6 field 모두 비어있지 않음', () {
      final all = loadAll();
      final empty = <String>[];
      for (final e in all) {
        final idx = e['index'] as int;
        if (!sampleIndices.contains(idx)) continue;
        final ko = e['ko'] as Map<String, dynamic>;
        for (final fld in koFields) {
          final v = ko[fld] as String? ?? '';
          if (v.trim().length < 50) {
            empty.add('idx=$idx $fld len=${v.length}');
          }
        }
      }
      expect(empty, isEmpty,
          reason: 'R82 sprint 8 — sample ko 본문 비어있거나 너무 짧음 (<50자):\n${empty.join("\n")}');
    });

    test('5행 골든 sample idx=27 (辛卯) 보존 + 재작성', () {
      // R82 sprint 8 → idx 27 도 30 sample 안 (5행 골든 1995-10-27 男 17시 일주).
      // M4 mandate — algorithmic 변경 X (JSON 본문만 변경).
      final all = loadAll();
      final idx27 = all.firstWhere((e) => e['index'] == 27);
      expect(idx27['ji60'], '辛卯',
          reason: 'idx27 ji60 = 辛卯 보존 mandate (R75/R80 5행 골든)');
      final ko = idx27['ko'] as Map<String, dynamic>;
      expect(ko['dayMasterDeep'], isNotNull);
      // R82 sprint 8 재작성 신호 — 새 phrase "깎일수록 더 분명하게 빛나는" 포함.
      expect(ko['dayMasterDeep'], contains('깎일수록'),
          reason: 'R82 sprint 8 — idx27 dayMasterDeep 재작성 phrase 포함 mandate');
      // R75/R80 신묘 oneline phrase (별도 wire = _oneLineByJi60Ko) 와 별개의 본문 영역.
      // 본 본문에 "벼린" / "벼린 칼" 직접 노출 0.
      expect((ko['dayMasterDeep'] as String).contains('벼린'), isFalse);
    });

    test('30 sample ko 본문 행동 처방 패턴 ≥15% (R73 lock baseline)', () {
      // "오늘 ~ 해봐요" / "한 번 ~ 챙겨봐요" 류 행동 처방 종결 패턴.
      final all = loadAll();
      int totalSentences = 0;
      int actionSentences = 0;
      // R82 sprint 8 r2 — 행동 처방 패턴 확장.
      // diversify r4 산출물 (TURN_B / FRIEND_MEMORY) 의 다양한 action 종결 cover.
      final actionPat = RegExp(
          r'(해봐요|챙겨봐요|보내봐요|골라봐요|꺼내봐요|가봐요|마셔봐요|챙겨요|기록해봐요|잡아봐요|시작해봐요|묵혀봐요|움직여봐요|남겨봐요|마주봐요|기다려봐요|쉬어봐요|들어봐요|적어봐요|미뤄봐요|먼저\s+해봐요|정리해봐요|믿어봐요)\.');
      for (final e in all) {
        final idx = e['index'] as int;
        if (!sampleIndices.contains(idx)) continue;
        final ko = e['ko'] as Map<String, dynamic>;
        for (final fld in koFields) {
          final v = ko[fld] as String? ?? '';
          // 문장 split.
          final sents = v.split(RegExp(r'(?<=[.!?])\s+'));
          for (final s in sents) {
            if (s.trim().isEmpty) continue;
            totalSentences++;
            if (actionPat.hasMatch(s)) {
              actionSentences++;
            }
          }
        }
      }
      expect(totalSentences > 0, isTrue);
      final ratio = actionSentences / totalSentences;
      expect(ratio >= 0.15, isTrue,
          reason:
              'R73 lock — 행동 처방 패턴 ≥15% mandate. actual=${(ratio * 100).toStringAsFixed(1)}% '
              '($actionSentences/$totalSentences)');
    });

    test('30 sample ko 본문 양면 단정 패턴 ≥30% (R73 lock baseline)', () {
      // "강점이지만 ~ 챙겨봐요" / "단, ~ 챙겨봐요" 류 양면 anchor.
      final all = loadAll();
      int totalEntries = 0;
      int bothsideEntries = 0;
      final bothPat = RegExp(r'(강점이지만|단,|단점은|반면)');
      for (final e in all) {
        final idx = e['index'] as int;
        if (!sampleIndices.contains(idx)) continue;
        final ko = e['ko'] as Map<String, dynamic>;
        for (final fld in koFields) {
          final v = ko[fld] as String? ?? '';
          totalEntries++;
          if (bothPat.hasMatch(v)) {
            bothsideEntries++;
          }
        }
      }
      expect(totalEntries > 0, isTrue);
      final ratio = bothsideEntries / totalEntries;
      expect(ratio >= 0.30, isTrue,
          reason:
              'R73 lock — 양면 anchor ≥30% mandate. actual=${(ratio * 100).toStringAsFixed(1)}% '
              '($bothsideEntries/$totalEntries)');
    });

    test('30 sample ko 본문 종결 반복 cap (한 entry 안 같은 종결 ≤2)', () {
      // R74 baseline — 한 entry 안에서 "스타일이에요" / "타입이에요" / "쪽이에요" /
      // "성격이에요" / "느낌이에요" / "구조예요" 같은 종결이 3회 이상 X.
      final all = loadAll();
      final suffixes = <String>['스타일이에요', '타입이에요', '쪽이에요', '성격이에요', '느낌이에요', '편이에요'];
      final hits = <String>[];
      for (final e in all) {
        final idx = e['index'] as int;
        if (!sampleIndices.contains(idx)) continue;
        final ko = e['ko'] as Map<String, dynamic>;
        for (final fld in koFields) {
          final v = ko[fld] as String? ?? '';
          for (final s in suffixes) {
            final ct = RegExp(s).allMatches(v).length;
            if (ct >= 3) {
              hits.add('idx=$idx $fld: "$s" × $ct');
            }
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'R82 sprint 8 — 한 entry 안 종결 반복 ≥3회:\n${hits.join("\n")}');
    });
  });
}
