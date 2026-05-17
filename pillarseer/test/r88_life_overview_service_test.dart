// R88 sprint 8 회귀 가드 — LifeOverviewService ("내 사주 큰 그림") anchor 조합 검증.
//
// 사용자 mandate (R88 spec sprint 8):
//   "사용자가 내 사주 탭 두 번째 section '내 사주 큰 그림' 을 보면 일주 + 5행
//    dominant/deficient + 인생 흐름 + 17 카테고리 강한 5 영역 anchor 를 종합한
//    600~900자 한 단락 essay 가 보인다. 같은 사주는 항상 같은 essay (idempotent)."
//
// 검증:
//   B1 — compose(saju) 호출 시 비어 있지 않은 string 반환
//   B2 — idempotent (같은 사주 두 번 호출 → 같은 essay)
//   B3 — 5행 dominant 한자 (예: 木/火/土/金/水) → 한글 라벨 (나무/불/흙/금속/물) 변환
//   B4 — 5행 deficient 약점 anchor 포함
//   B5 — 다른 일간 두 사주 → 다른 essay (변별력)
//   B6 — essay 길이 ≥200자 (anchor 10 합산)
//   B7 — 톤 leak 검증 (평탄/단정/jargon/AI 슬롭/의료/직장인 0)
//   B8 — 1995-10-27 男 17시 (R75 골든) 사주 → essay idempotent

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_overview_service.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';

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

  /// 사주 test factory — required field 모두 채우기.
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

  // 1995-10-27 男 17시 sample (R75 골든 baseline).
  // 일주 辛卯, 5행 16/21/17/41/4.
  final SajuResult goldenSaju = makeSaju(
    year: const Pillar(chunGan: '乙', jiJi: '亥'),
    month: const Pillar(chunGan: '丙', jiJi: '戌'),
    day: const Pillar(chunGan: '辛', jiJi: '卯'),
    hour: const Pillar(chunGan: '丁', jiJi: '酉'),
    el: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
  );

  group('R88 sprint 8 — LifeOverviewService anchor 조합 essay', () {
    test('B1 — compose(saju) 호출 시 비어있지 않은 string 반환', () async {
      final essay = await LifeOverviewService.compose(goldenSaju);
      expect(essay.isNotEmpty, isTrue);
      expect(essay.length >= 80, isTrue,
          reason: 'essay 가 anchor 10 조합 후 적어도 ≥80자');
    });

    test('B2 — idempotent: 같은 사주 두 번 호출 → 같은 essay', () async {
      final e1 = await LifeOverviewService.compose(goldenSaju);
      final e2 = await LifeOverviewService.compose(goldenSaju);
      expect(e1, equals(e2),
          reason: 'idempotent — 같은 입력 → 같은 출력');
    });

    test('B3 — 5행 dominant 한자 → 한글 라벨 변환', () async {
      // golden sample 의 dominant = '金' (41) → '금속'.
      expect(goldenSaju.elements.dominant, equals('金'));
      final essay = await LifeOverviewService.compose(goldenSaju);
      expect(essay.contains('금속'), isTrue,
          reason: '5행 dominant 金 → 한글 "금속" 라벨 포함');
    });

    test('B4 — 5행 deficient 약점 anchor 포함', () async {
      // golden sample 의 deficit = '水' (4) → '물'.
      expect(goldenSaju.elements.deficit, equals('水'));
      final essay = await LifeOverviewService.compose(goldenSaju);
      expect(essay.contains('물'), isTrue,
          reason: '5행 deficient 水 → 한글 "물" 라벨 포함');
    });

    test('B5 — 다른 일간 두 사주 → 다른 essay (변별력)', () async {
      final sajuGap = makeSaju(
        year: const Pillar(chunGan: '甲', jiJi: '子'),
        month: const Pillar(chunGan: '甲', jiJi: '子'),
        day: const Pillar(chunGan: '甲', jiJi: '子'),
        hour: const Pillar(chunGan: '甲', jiJi: '子'),
        el: const FiveElements(wood: 60, fire: 10, earth: 10, metal: 10, water: 10),
      );
      final sajuSin = makeSaju(
        year: const Pillar(chunGan: '辛', jiJi: '丑'),
        month: const Pillar(chunGan: '辛', jiJi: '丑'),
        day: const Pillar(chunGan: '辛', jiJi: '丑'),
        hour: const Pillar(chunGan: '辛', jiJi: '丑'),
        el: const FiveElements(wood: 10, fire: 10, earth: 10, metal: 60, water: 10),
      );
      final eGap = await LifeOverviewService.compose(sajuGap);
      final eSin = await LifeOverviewService.compose(sajuSin);
      expect(eGap != eSin, isTrue,
          reason: '갑 일간 essay ≠ 신 일간 essay');
    });

    test('B6 — essay 길이 600~900자 (spec mandate hard cap)', () async {
      final essay = await LifeOverviewService.compose(goldenSaju);
      expect(essay.length >= 600, isTrue,
          reason: 'spec mandate: essay ≥600자 (실제 ${essay.length}자)');
      expect(essay.length <= 900, isTrue,
          reason: 'spec mandate: essay ≤900자 (실제 ${essay.length}자)');
    });

    test('B6b — essay 안 한자 jargon leak 0 (한글 변환)', () async {
      final essay = await LifeOverviewService.compose(goldenSaju);
      // 사용자 mandate "한자 jargon X". 한자 60갑자 (甲乙丙丁戊己庚辛壬癸 / 子丑寅卯辰巳午未申酉戌亥)
      // 모두 essay 안에서 한글 라벨로 변환되어 노출 X.
      for (final han in const [
        '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
        '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
      ]) {
        expect(essay.contains(han), isFalse,
            reason: '한자 jargon "$han" leak — 한글 라벨 변환 누락');
      }
    });

    test('B7 — 톤 leak 검증 (평탄/단정/jargon/AI 슬롭/의료/직장인 0)', () async {
      final essay = await LifeOverviewService.compose(goldenSaju);
      for (final w in const ['균형', '조화', '골고루']) {
        expect(essay.contains(w), isFalse, reason: '평탄 어휘 "$w" leak');
      }
      for (final w in const ['습니다.', '입니다.']) {
        expect(essay.contains(w), isFalse, reason: '단정조 "$w" leak');
      }
      for (final w in const ['재성', '관성', '식상', '인성', '비겁']) {
        expect(essay.contains(w), isFalse, reason: '한자 jargon "$w" leak');
      }
      for (final w in const ['센터처럼', '당신의 흐름은', '본인의 결은']) {
        expect(essay.contains(w), isFalse, reason: 'AI 슬롭 "$w" leak');
      }
      for (final w in const ['진단', '처방', '치료']) {
        expect(essay.contains(w), isFalse, reason: '의료 단정 "$w" leak');
      }
      for (final w in const ['커리어 패스', '포트폴리오', 'ROI', '리텐션']) {
        expect(essay.contains(w), isFalse, reason: '직장인 jargon "$w" leak');
      }
    });

    test('B8 — gender 분기: 5행 dominant 5종 모두에서 M/F essay 달라야 함', () async {
      // R88 sprint 8 ROUND 3 fix — 木/火/土/金/水 dominant 5종 각각 강세 카테고리 안에
      // 최소 1 개 성별 분기 카테고리 (innateCharacter / loveFate / affection) 포함 보장.
      // 따라서 isMale=true vs false 호출 시 essay 가 서로 달라야 함.
      const dominants = [
        ('木', FiveElements(wood: 60, fire: 10, earth: 10, metal: 10, water: 10)),
        ('火', FiveElements(wood: 10, fire: 60, earth: 10, metal: 10, water: 10)),
        ('土', FiveElements(wood: 10, fire: 10, earth: 60, metal: 10, water: 10)),
        ('金', FiveElements(wood: 10, fire: 10, earth: 10, metal: 60, water: 10)),
        ('水', FiveElements(wood: 10, fire: 10, earth: 10, metal: 10, water: 60)),
      ];
      for (final (han, el) in dominants) {
        final saju = makeSaju(
          year: const Pillar(chunGan: '甲', jiJi: '子'),
          month: const Pillar(chunGan: '甲', jiJi: '子'),
          day: const Pillar(chunGan: '甲', jiJi: '子'),
          hour: const Pillar(chunGan: '甲', jiJi: '子'),
          el: el,
        );
        expect(saju.elements.dominant, equals(han));
        final eM = await LifeOverviewService.compose(saju, isMale: true);
        final eF = await LifeOverviewService.compose(saju, isMale: false);
        expect(eM != eF, isTrue,
            reason:
                '$han dominant 에서 M/F essay 달라야 함 (성별 분기 카테고리 반영 보장)');
      }
    });

    test('B8b — 10 일간 × 5 dominant × 2 gender = 100 case 매트릭스: 한자 leak 0 + 600~900자', () async {
      // ROUND 4 fix — × 2 gender 까지 확장. 총 100 case.
      const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      const dominants = [
        ('木', FiveElements(wood: 60, fire: 10, earth: 10, metal: 10, water: 10)),
        ('火', FiveElements(wood: 10, fire: 60, earth: 10, metal: 10, water: 10)),
        ('土', FiveElements(wood: 10, fire: 10, earth: 60, metal: 10, water: 10)),
        ('金', FiveElements(wood: 10, fire: 10, earth: 10, metal: 60, water: 10)),
        ('水', FiveElements(wood: 10, fire: 10, earth: 10, metal: 10, water: 60)),
      ];
      const genders = [true, false];
      const allHan = [
        '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
        '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
      ];
      for (final stem in stems) {
        for (final (han, el) in dominants) {
          for (final isMale in genders) {
            final saju = makeSaju(
              year: Pillar(chunGan: stem, jiJi: '子'),
              month: Pillar(chunGan: stem, jiJi: '子'),
              day: Pillar(chunGan: stem, jiJi: '子'),
              hour: Pillar(chunGan: stem, jiJi: '子'),
              el: el,
            );
            final essay = await LifeOverviewService.compose(saju, isMale: isMale);
            expect(essay.length >= 600, isTrue,
                reason:
                    'stem=$stem dominant=$han isMale=$isMale essay ≥600자 (실제 ${essay.length})');
            expect(essay.length <= 900, isTrue,
                reason:
                    'stem=$stem dominant=$han isMale=$isMale essay ≤900자 (실제 ${essay.length})');
            for (final ch in allHan) {
              expect(essay.contains(ch), isFalse,
                  reason: 'stem=$stem dominant=$han isMale=$isMale essay 안 한자 "$ch" leak');
            }
          }
        }
      }
    });

    test('B9 — 5행 dominant 5종 (木火土金水) 모두 한글 라벨 매핑 작동', () async {
      // 각 dominant 5행 → essay 에 해당 한글 등장.
      const cases = [
        ('木', '나무', FiveElements(wood: 60, fire: 10, earth: 10, metal: 10, water: 10)),
        ('火', '불', FiveElements(wood: 10, fire: 60, earth: 10, metal: 10, water: 10)),
        ('土', '흙', FiveElements(wood: 10, fire: 10, earth: 60, metal: 10, water: 10)),
        ('金', '금속', FiveElements(wood: 10, fire: 10, earth: 10, metal: 60, water: 10)),
        ('水', '물', FiveElements(wood: 10, fire: 10, earth: 10, metal: 10, water: 60)),
      ];
      for (final (han, ko, el) in cases) {
        final saju = makeSaju(
          year: const Pillar(chunGan: '甲', jiJi: '子'),
          month: const Pillar(chunGan: '甲', jiJi: '子'),
          day: const Pillar(chunGan: '甲', jiJi: '子'),
          hour: const Pillar(chunGan: '甲', jiJi: '子'),
          el: el,
        );
        expect(saju.elements.dominant, equals(han));
        final essay = await LifeOverviewService.compose(saju);
        expect(essay.contains(ko), isTrue,
            reason: 'dominant $han → essay 안 "$ko" 한글 라벨 포함');
      }
    });
  });
}
