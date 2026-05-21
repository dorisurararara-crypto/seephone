// Round 107 — 영어 모드 내 사주(My Saju) 카테고리 본문 일간별 개인화 검증.
//
// 문제 (R106 까지):
//   kLifeCategoryBodyEn = 17 generic 문자열, 일주/일간 무관.
//   모든 영어 사용자가 똑같은 17 카테고리 글을 봄. 한국어는
//   life_paragraphs.json 일간 stem entry 로 개인화인데 영어는 개인화 0.
//
// R107 fix:
//   kLifeCategoryBodyEnByStem = 일간 10 × 17 카테고리 = 170 본문.
//   categoryBodyEnForStem / categoryBodyEnFor = 사용자 일간으로 170 맵 lookup.
//
// 검증:
//   P1 — 170 본문 모두 채워짐 (일간 10 × 카테고리 17 = 170, 빈 문자열 0).
//   P2 — 일간 다르면 영어 본문 다름 (개인화 — 모든 카테고리에서 변별).
//   P3 — 한 일간 17 카테고리 첫 문장 동일 scaffold 0 (한국어 중복 버그 재발 금지).
//   P4 — 한글(가-힣) leak 0.
//   P5 — v5 voice: 단정 금지 — 조건형(tends/can/often 등) 모든 본문 포함.
//   P6 — 메타 금지: saju 주체 노출 0.
//   P7 — placeholder 문구 0 (Coming soon / switch to Korean).
//   P8 — categoryBodyEnFor: 사용자 사주 일간으로 개인화 본문 반환.
//   P9 — 일간 unknown → generic carrier fallback (crash 0).
//   P10 — idempotent.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_overview_service.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 10 천간 한자.
  const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  const branches = ['子', '丑', '寅', '卯', '辰', '巳'];

  SajuResult sajuWithStem(String stem) {
    return SajuResult(
      yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
      monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'),
      dayPillar: Pillar(chunGan: stem, jiJi: '卯'),
      hourPillar: const Pillar(chunGan: '丁', jiJi: '酉'),
      elements: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
      dayMaster: stem,
      dayMasterName: 'Test',
      summary: '',
      categoryReadings: const {},
    );
  }

  final hangul = RegExp(r'[가-힣]');
  // 단어 단위 — saju / four pillars / destiny chart / fortune-telling.
  final meta = RegExp(
    r'\b(saju|four pillars|destiny chart|fortune-?telling)\b',
    caseSensitive: false,
  );
  final hedges = RegExp(r'\b(tend|tends|can|often|usually|may|might)\b');
  const banned = ['Coming soon', 'switch to Korean', 'please switch'];

  /// 본문 첫 문장 (앞 6 단어) 추출 — scaffold 비교용.
  String firstChunk(String body) {
    final words = body.trim().split(RegExp(r'\s+'));
    return words.take(6).join(' ').toLowerCase();
  }

  group('R107 — 영어 내 사주 일간별 개인화 (170 본문)', () {
    test('P1 — 170 본문 모두 채워짐 (일간 10 × 카테고리 17)', () {
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(body.trim().isNotEmpty, isTrue,
              reason: '일간 $stem / $cat 영어 본문 비어있음');
          expect(body.trim().length, greaterThan(40),
              reason: '일간 $stem / $cat 영어 본문 너무 짧음');
        }
      }
    });

    test('P2 — 일간 다르면 본문 다름 (모든 카테고리에서 변별)', () {
      for (final cat in LifeCategory.values) {
        final seen = <String>{};
        for (final stem in stems) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(seen.contains(body), isFalse,
              reason: '카테고리 $cat — 일간 $stem 본문이 다른 일간과 동일 (개인화 0)');
          seen.add(body);
        }
      }
    });

    test('P3 — 한 일간 17 카테고리 첫 문장 동일 scaffold 0', () {
      for (final stem in stems) {
        final chunks = <String>{};
        for (final cat in LifeCategory.values) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          final chunk = firstChunk(body);
          expect(chunks.contains(chunk), isFalse,
              reason: '일간 $stem — 카테고리 $cat 첫 문장이 같은 일간 다른 카테고리와 동일 scaffold: "$chunk"');
          chunks.add(chunk);
        }
      }
    });

    test('P4 — 한글 leak 0', () {
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(hangul.hasMatch(body), isFalse,
              reason: '일간 $stem / $cat 한글 leak: $body');
        }
      }
    });

    test('P5 — v5 voice 조건형 (단정 금지 — 모든 본문)', () {
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(hedges.hasMatch(body), isTrue,
              reason: '일간 $stem / $cat 조건형 없음 (단정조): $body');
        }
      }
    });

    test('P6 — 메타 금지 (saju 주체 노출 0)', () {
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(meta.hasMatch(body), isFalse,
              reason: '일간 $stem / $cat 메타 leak: $body');
        }
      }
    });

    test('P7 — placeholder 문구 0', () {
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final body =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          for (final b in banned) {
            expect(body.contains(b), isFalse,
                reason: '일간 $stem / $cat placeholder "$b" leak');
          }
        }
      }
    });

    test('P8 — categoryBodyEnFor: 사용자 사주 일간으로 개인화 본문', () {
      for (final stem in stems) {
        final saju = sajuWithStem(stem);
        for (final cat in LifeCategory.values) {
          final viaSaju = LifeParagraphService.categoryBodyEnFor(saju, cat);
          final viaStem =
              LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(viaSaju, viaStem,
              reason: '일간 $stem / $cat — categoryBodyEnFor 가 categoryBodyEnForStem 와 불일치');
          // overview service delegate 도 동일.
          expect(LifeOverviewService.categoryBodyEnFor(saju, cat), viaStem,
              reason: 'LifeOverviewService.categoryBodyEnFor delegate 불일치');
        }
      }
    });

    test('P9 — 일간 unknown → generic carrier fallback (crash 0)', () {
      for (final cat in LifeCategory.values) {
        final body =
            LifeParagraphService.categoryBodyEnForStem('???', cat);
        expect(body.trim().isNotEmpty, isTrue,
            reason: 'unknown 일간 fallback 본문 비어있음');
        expect(body, LifeParagraphService.categoryBodyEn(cat),
            reason: 'unknown 일간 → generic carrier 가 아님');
      }
    });

    test('P10 — idempotent (같은 일간 → 같은 본문)', () {
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final a = LifeParagraphService.categoryBodyEnForStem(stem, cat);
          final b = LifeParagraphService.categoryBodyEnForStem(stem, cat);
          expect(a, b);
        }
      }
    });

    test('P11 — 한글/로마자 alias 키도 한자 키와 동일 본문', () {
      const aliasPairs = {
        '갑': '甲', 'gap': '甲',
        '신': '辛', 'sin': '辛',
        '계': '癸', 'gye': '癸',
      };
      for (final entry in aliasPairs.entries) {
        for (final cat in LifeCategory.values) {
          expect(
            LifeParagraphService.categoryBodyEnForStem(entry.key, cat),
            LifeParagraphService.categoryBodyEnForStem(entry.value, cat),
            reason: 'alias ${entry.key} → ${entry.value} 본문 불일치 ($cat)',
          );
        }
      }
    });

    test('P12 — branch 무관: 일간만 본문 결정 (일주 변화 영향 0)', () {
      // 같은 일간, 다른 지지 → 같은 카테고리 본문 동일 (일간 기반 개인화 확인).
      for (final stem in stems) {
        for (final cat in LifeCategory.values) {
          final bodies = <String>{};
          for (final br in branches) {
            final saju = SajuResult(
              yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
              monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'),
              dayPillar: Pillar(chunGan: stem, jiJi: br),
              hourPillar: const Pillar(chunGan: '丁', jiJi: '酉'),
              elements: const FiveElements(
                  wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
              dayMaster: stem,
              dayMasterName: 'Test',
              summary: '',
              categoryReadings: const {},
            );
            bodies.add(LifeParagraphService.categoryBodyEnFor(saju, cat));
          }
          expect(bodies.length, 1,
              reason: '일간 $stem / $cat — 지지만 달라도 본문이 갈림');
        }
      }
    });
  });
}
