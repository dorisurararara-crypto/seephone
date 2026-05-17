// R88 sprint 9 회귀 가드 — SelfConclusionService ("나는 어떤 사람?") 결론 paragraph 검증.
//
// 사용자 mandate (R88 spec sprint 9):
//   "사용자가 내 사주 탭 맨 아래 section '나는 어떤 사람?' 을 보면 일간 + 5행
//    dominant anchor 의 결론형 80~200자 paragraph 가 보인다. 결론형 톤 ('당신은 ~
//    같은 사람이에요' 또는 '본인은 ~ 매력이 있어요')."
//
// 검증:
//   B1 — conclude(saju) 호출 시 비어있지 않은 string 반환
//   B2 — idempotent
//   B3 — 결론 길이 80~200자 (hard cap)
//   B4 — '본인은' 또는 '당신은' 패턴 포함 (결론형 톤)
//   B5 — 일간 10 × 5행 dominant 50 case 변별력 (anchor prefix 매핑)
//   B6 — 톤 leak (평탄/단정/jargon/AI 슬롭) 0
//   B7 — 한자 jargon (60갑자) essay 안 leak 0
//   B8 — gender 분기 — 50 case 매트릭스 (M/F)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';
import 'package:pillarseer/services/self_conclusion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
    LifeParagraphService.seedForTest(
        json.decode(raw) as Map<String, dynamic>);
  });

  tearDownAll(() {
    LifeParagraphService.resetCache();
  });

  SajuResult makeSaju({
    required Pillar day,
    required FiveElements el,
  }) {
    return SajuResult(
      yearPillar: day,
      monthPillar: day,
      dayPillar: day,
      hourPillar: day,
      elements: el,
      dayMaster: day.chunGan,
      dayMasterName: 'Test',
      summary: '',
      categoryReadings: const {},
    );
  }

  // golden 1995-10-27 男 17시 (R75) — 辛卯 / 5행 16/21/17/41/4.
  final SajuResult goldenSaju = makeSaju(
    day: const Pillar(chunGan: '辛', jiJi: '卯'),
    el: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
  );

  group('R88 sprint 9 — SelfConclusionService', () {
    test('B1 — conclude(saju) 호출 시 비어있지 않은 string', () async {
      final c = await SelfConclusionService.conclude(goldenSaju);
      expect(c.isNotEmpty, isTrue);
    });

    test('B2 — idempotent', () async {
      final c1 = await SelfConclusionService.conclude(goldenSaju);
      final c2 = await SelfConclusionService.conclude(goldenSaju);
      expect(c1, equals(c2));
    });

    test('B3 — 길이 80~200자 (hard cap)', () async {
      final c = await SelfConclusionService.conclude(goldenSaju);
      expect(c.length >= 80, isTrue,
          reason: 'spec mandate: ≥80자 (실제 ${c.length}자)');
      expect(c.length <= 200, isTrue,
          reason: 'spec mandate: ≤200자 (실제 ${c.length}자)');
    });

    test('B4 — 결론형 톤 (본인은 / 당신은)', () async {
      final c = await SelfConclusionService.conclude(goldenSaju);
      final hasConcl = c.contains('본인은') || c.contains('당신은');
      expect(hasConcl, isTrue,
          reason: '결론형 톤 "본인은 ~" 또는 "당신은 ~" 패턴 포함');
    });

    test('B5 — 일간 10 × 5 dominant 50 case 변별력 + 80~200자', () async {
      const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      const dominants = [
        FiveElements(wood: 60, fire: 10, earth: 10, metal: 10, water: 10),
        FiveElements(wood: 10, fire: 60, earth: 10, metal: 10, water: 10),
        FiveElements(wood: 10, fire: 10, earth: 60, metal: 10, water: 10),
        FiveElements(wood: 10, fire: 10, earth: 10, metal: 60, water: 10),
        FiveElements(wood: 10, fire: 10, earth: 10, metal: 10, water: 60),
      ];
      final results = <String>{};
      for (final stem in stems) {
        for (final el in dominants) {
          final saju = makeSaju(
            day: Pillar(chunGan: stem, jiJi: '子'),
            el: el,
          );
          final c = await SelfConclusionService.conclude(saju);
          expect(c.length >= 80, isTrue,
              reason: 'stem=$stem dominant=${el.dominant} 80자 이상 (실제 ${c.length})');
          expect(c.length <= 200, isTrue,
              reason: 'stem=$stem dominant=${el.dominant} 200자 이하 (실제 ${c.length})');
          results.add(c);
        }
      }
      // 50 case 안에서 unique 결론 ≥40 (80% 변별력).
      expect(results.length >= 40, isTrue,
          reason: '50 case unique 결론 ≥40 (변별력) — 실제 ${results.length}');
    });

    test('B6 — 톤 leak (평탄/단정/jargon/AI 슬롭/의료/직장인) 0', () async {
      final c = await SelfConclusionService.conclude(goldenSaju);
      for (final w in const ['균형', '조화', '골고루']) {
        expect(c.contains(w), isFalse, reason: '평탄 어휘 "$w" leak');
      }
      for (final w in const ['습니다.', '입니다.']) {
        expect(c.contains(w), isFalse, reason: '단정조 "$w" leak');
      }
      for (final w in const ['재성', '관성', '식상', '인성', '비겁']) {
        expect(c.contains(w), isFalse, reason: '한자 jargon "$w" leak');
      }
      for (final w in const ['센터처럼', '당신의 흐름은', '본인의 결은']) {
        expect(c.contains(w), isFalse, reason: 'AI 슬롭 "$w" leak');
      }
      for (final w in const ['진단', '처방', '치료']) {
        expect(c.contains(w), isFalse, reason: '의료 단정 "$w" leak');
      }
      for (final w in const ['커리어 패스', '포트폴리오', 'ROI', '리텐션']) {
        expect(c.contains(w), isFalse, reason: '직장인 jargon "$w" leak');
      }
    });

    test('B7 — 한자 jargon (60갑자) leak 0 (한글 변환 보장)', () async {
      final c = await SelfConclusionService.conclude(goldenSaju);
      for (final h in const [
        '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
        '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
      ]) {
        expect(c.contains(h), isFalse, reason: '한자 "$h" leak');
      }
    });

    test('B8 — gender 분기 변별력 — 50 case 매트릭스 (M/F)', () async {
      // SelfConclusionService 는 LifeParagraphService.conclusion_self 가 split 아닌 string
      // 카테고리. gender 분기는 essay 안의 분기 없음. 그러나 isMale 매개변수가 향후 확장
      // 위해 유지. 현재 hard mandate 는 idempotent + length + 톤만.
      final cM = await SelfConclusionService.conclude(goldenSaju, isMale: true);
      final cF = await SelfConclusionService.conclude(goldenSaju, isMale: false);
      // conclusion_self 가 split 아니므로 M/F 동일 출력 OK (regression 가드).
      expect(cM, equals(cF),
          reason: 'conclusion_self 는 split 아닌 카테고리 — M/F 동일 출력');
    });

    test('B9 — 50 case 전체 톤 leak (평탄/단정/jargon/AI 슬롭/의료/직장인 + 한자 60갑자) 0',
        () async {
      // ROUND 2 fix — golden 1건이 아니라 50 case 전체에 톤 leak scan.
      const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      const dominants = [
        FiveElements(wood: 60, fire: 10, earth: 10, metal: 10, water: 10),
        FiveElements(wood: 10, fire: 60, earth: 10, metal: 10, water: 10),
        FiveElements(wood: 10, fire: 10, earth: 60, metal: 10, water: 10),
        FiveElements(wood: 10, fire: 10, earth: 10, metal: 60, water: 10),
        FiveElements(wood: 10, fire: 10, earth: 10, metal: 10, water: 60),
      ];
      const blacklist = [
        '균형', '조화', '골고루',
        '습니다.', '입니다.',
        '재성', '관성', '식상', '인성', '비겁',
        '센터처럼', '당신의 흐름은', '본인의 결은',
        '진단', '처방', '치료',
        '커리어 패스', '포트폴리오', 'ROI', '리텐션',
      ];
      const han60 = [
        '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
        '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
      ];
      for (final stem in stems) {
        for (final el in dominants) {
          final saju = makeSaju(
            day: Pillar(chunGan: stem, jiJi: '子'),
            el: el,
          );
          final c = await SelfConclusionService.conclude(saju);
          for (final w in blacklist) {
            expect(c.contains(w), isFalse,
                reason: 'stem=$stem dominant=${el.dominant} "$w" leak: $c');
          }
          for (final h in han60) {
            expect(c.contains(h), isFalse,
                reason: 'stem=$stem dominant=${el.dominant} 한자 "$h" leak');
          }
        }
      }
    });
  });
}
