// Round 106 (P5) — 내 사주(My Saju) 화면 영어 모드 갭 일소 검증.
//
// 문제 (영어 모드 갭):
//  ① LIFE OVERVIEW 본문이 'A single-paragraph life essay — please switch to
//     Korean...' placeholder.
//  ② SELF CONCLUSION 본문이 'A one-paragraph friendly verdict … switch to
//     Korean.' placeholder.
//  ③ 17 카테고리 본문이 전부 'Coming soon for "X".'.
//
// P5 fix:
//  - LifeOverviewService.composeEn / SelfConclusionService.concludeEn /
//    LifeParagraphService.categoryBodyEn = 실제 영어 본문 생성.
//
// 검증:
//  E1 — composeEn / concludeEn / categoryBodyEn 모두 비어있지 않음.
//  E2 — placeholder 문구('Coming soon' / 'switch to Korean') 0.
//  E3 — 영어 본문 안 한글 누출 0.
//  E4 — v5 voice: 단정 금지 — 조건형(tends to / can / often 등) 포함.
//  E5 — 메타 금지: 'chart' 외 'saju' 주체 노출 0 (영어 본문).
//  E6 — idempotent (같은 사주 → 같은 영어 본문).
//  E7 — 변별력: 다른 일간 두 사주 → 다른 LIFE OVERVIEW 영어 essay.
//  E8 — 17 카테고리 영어 본문 17종 모두 채워짐 + 영어 섹션 제목 raw key 노출 0.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_overview_service.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';
import 'package:pillarseer/services/self_conclusion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
    LifeParagraphService.seedForTest(json.decode(raw) as Map<String, dynamic>);
  });

  tearDownAll(() {
    LifeParagraphService.resetCache();
  });

  SajuResult makeSaju({
    required Pillar year,
    required Pillar month,
    required Pillar day,
    required Pillar hour,
    required FiveElements el,
  }) {
    return SajuResult(
      yearPillar: year,
      monthPillar: month,
      dayPillar: day,
      hourPillar: hour,
      elements: el,
      dayMaster: day.chunGan,
      dayMasterName: 'Test',
      summary: '',
      categoryReadings: const {},
    );
  }

  // 1995-10-27 男 17시 sample 근사 (R75 골든 baseline 영역).
  final golden = makeSaju(
    year: const Pillar(chunGan: '乙', jiJi: '亥'),
    month: const Pillar(chunGan: '丙', jiJi: '戌'),
    day: const Pillar(chunGan: '辛', jiJi: '卯'),
    hour: const Pillar(chunGan: '丁', jiJi: '酉'),
    el: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
  );

  // 다른 일간 사주 (변별력 검증용).
  final other = makeSaju(
    year: const Pillar(chunGan: '戊', jiJi: '辰'),
    month: const Pillar(chunGan: '甲', jiJi: '寅'),
    day: const Pillar(chunGan: '甲', jiJi: '子'),
    hour: const Pillar(chunGan: '丙', jiJi: '午'),
    el: const FiveElements(wood: 44, fire: 22, earth: 18, metal: 6, water: 10),
  );

  final hangul = RegExp(r'[가-힣]');

  test('E1 — composeEn / concludeEn / categoryBodyEn 비어있지 않음', () async {
    final overview = await LifeOverviewService.composeEn(golden);
    final conclusion = await SelfConclusionService.concludeEn(golden);
    expect(overview.trim().isNotEmpty, isTrue);
    expect(conclusion.trim().isNotEmpty, isTrue);
    for (final cat in LifeCategory.values) {
      expect(LifeParagraphService.categoryBodyEn(cat).trim().isNotEmpty, isTrue,
          reason: 'category $cat 영어 본문 비어있음');
    }
  });

  test('E2 — placeholder 문구 0', () async {
    final texts = <String>[
      await LifeOverviewService.composeEn(golden),
      await SelfConclusionService.concludeEn(golden),
      for (final cat in LifeCategory.values)
        LifeParagraphService.categoryBodyEn(cat),
    ];
    const banned = ['Coming soon', 'switch to Korean', 'please switch'];
    for (final t in texts) {
      for (final b in banned) {
        expect(t.contains(b), isFalse,
            reason: 'placeholder "$b" leak: $t');
      }
    }
  });

  test('E3 — 영어 본문 안 한글 누출 0', () async {
    final texts = <String>[
      await LifeOverviewService.composeEn(golden, isMale: true),
      await LifeOverviewService.composeEn(other, isMale: false),
      await SelfConclusionService.concludeEn(golden),
      for (final cat in LifeCategory.values)
        LifeParagraphService.categoryBodyEn(cat),
      for (final k in kLifeCategoryTitleEn.keys) lifeCategoryTitleEn(k),
    ];
    for (final t in texts) {
      expect(hangul.hasMatch(t), isFalse, reason: '한글 leak: $t');
    }
  });

  test('E4 — v5 voice 조건형 (단정 금지)', () async {
    final overview = await LifeOverviewService.composeEn(golden);
    final conclusion = await SelfConclusionService.concludeEn(golden);
    final hedges = RegExp(r'\b(tend|tends|can|often|usually|may)\b');
    expect(hedges.hasMatch(overview), isTrue,
        reason: 'overview 조건형 없음: $overview');
    expect(hedges.hasMatch(conclusion), isTrue,
        reason: 'conclusion 조건형 없음: $conclusion');
    for (final cat in LifeCategory.values) {
      expect(hedges.hasMatch(LifeParagraphService.categoryBodyEn(cat)), isTrue,
          reason: 'category $cat 조건형 없음');
    }
  });

  test('E5 — 메타 금지 (saju 주체 노출 0)', () async {
    final texts = <String>[
      await LifeOverviewService.composeEn(golden),
      await SelfConclusionService.concludeEn(golden),
      for (final cat in LifeCategory.values)
        LifeParagraphService.categoryBodyEn(cat),
    ];
    final meta = RegExp(r'\b(saju|four pillars|destiny chart|fortune-?telling)\b',
        caseSensitive: false);
    for (final t in texts) {
      expect(meta.hasMatch(t), isFalse, reason: 'meta leak: $t');
    }
  });

  test('E6 — idempotent', () async {
    final o1 = await LifeOverviewService.composeEn(golden);
    final o2 = await LifeOverviewService.composeEn(golden);
    expect(o1, o2);
    final c1 = await SelfConclusionService.concludeEn(golden);
    final c2 = await SelfConclusionService.concludeEn(golden);
    expect(c1, c2);
  });

  test('E7 — 변별력 (다른 일간 → 다른 essay)', () async {
    final a = await LifeOverviewService.composeEn(golden);
    final b = await LifeOverviewService.composeEn(other);
    expect(a == b, isFalse, reason: '다른 일간인데 essay 동일');
  });

  test('E8 — 17 카테고리 영어 제목 raw key 노출 0', () {
    for (final entry in kLifeCategoryTitleEn.entries) {
      final title = lifeCategoryTitleEn(entry.key);
      expect(title.contains('_'), isFalse, reason: 'raw key leak: $title');
      // 제목이 전부 대문자 raw key (EARLY LIFE 식) 가 아님 — Title Case.
      expect(title, isNot(equals(entry.key.toUpperCase().replaceAll('_', ' '))));
    }
  });
}
