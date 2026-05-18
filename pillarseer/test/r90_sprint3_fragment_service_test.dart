// R90 sprint 3 — LifeCategoryFragmentService 회귀 가드.
//
// 사용자 mandate verbatim:
// > "원래 사주는 일주로만 봐?? 내 사주가 곧 평생사주인데 왜 신묘일주만 말하지??"
//
// 본인 vs 여친 (같은 신묘 일주 + 다른 사주) → 다른 fragment 셋 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_category_fragment_service.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R90 sprint 3 — LifeCategoryFragmentService', () {
    setUp(() => LifeCategoryFragmentService.resetCache());

    // 본인 사주 (1995-10-27 男 17시) — 5행 골든 16/21/17/41/4, 신묘 일주.
    final sajuMe = SajuResult(
      yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
      monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'), // 戌 → 가을
      dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
      hourPillar: const Pillar(chunGan: '丁', jiJi: '酉'),
      elements: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
      dayMaster: '辛',
      dayMasterName: 'Yin Metal Rabbit',
      summary: '',
      categoryReadings: const {},
      isMale: true,
    );

    // 여친 사주 — 같은 신묘 일주, 다른 월/년/시.
    final sajuGf = SajuResult(
      yearPillar: const Pillar(chunGan: '癸', jiJi: '酉'),
      monthPillar: const Pillar(chunGan: '甲', jiJi: '寅'), // 寅 → 봄
      dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
      hourPillar: const Pillar(chunGan: '己', jiJi: '亥'),
      elements: const FiveElements(wood: 38, fire: 5, earth: 14, metal: 28, water: 15),
      dayMaster: '辛',
      dayMasterName: 'Yin Metal Rabbit',
      summary: '',
      categoryReadings: const {},
      isMale: false,
    );

    test('B1 — anchorsFor 5축 모두 추출 (본인)', () {
      final a = LifeCategoryFragmentService.anchorsFor(sajuMe);
      expect(a['5행압도'], '金'); // metal 41 dominant
      expect(a['5행공허'], '水'); // water 4 deficit
      expect(a['월령'], '가을'); // 戌 → 가을
      expect(a['십성주력'], isNotEmpty); // TenGod top — 정확 값은 binding 후 측정.
      expect(a['격국'], isNotEmpty); // 戌 본기 戊 = 정인 (辛 일간) → 정인격
    });

    test('B2 — anchorsFor 본인 vs 여친 차이 (anchor 다층화 효과)', () {
      final a = LifeCategoryFragmentService.anchorsFor(sajuMe);
      final b = LifeCategoryFragmentService.anchorsFor(sajuGf);
      // 같은 일주 (신묘) 지만 5행 압도 + 월령 + 십성 + 격국 중 ≥2 축이 달라야 함.
      var diff = 0;
      for (final k in ['5행압도', '5행공허', '월령', '십성주력', '격국']) {
        if (a[k] != b[k]) diff += 1;
      }
      expect(diff, greaterThanOrEqualTo(2),
          reason: 'anchor 5축 중 ≥2 축 달라야 본문 차별화 가능');
    });

    test('B3 — fragmentsFor earlyLife = ["월령", "5행압도"] 두 fragment', () async {
      final frag = await LifeCategoryFragmentService.fragmentsFor(
        saju: sajuMe,
        category: LifeCategory.earlyLife,
      );
      expect(frag.length, 2);
      for (final f in frag) {
        expect(f.length, greaterThanOrEqualTo(20));
        expect(f.length, lessThanOrEqualTo(200));
      }
    });

    test('B4 — fragmentsFor 본인 vs 여친 (같은 카테고리) → 다른 fragment 셋', () async {
      for (final cat in [
        LifeCategory.earlyLife,
        LifeCategory.midLife,
        LifeCategory.personality,
        LifeCategory.loveFate,
        LifeCategory.wealth,
      ]) {
        final fMe = await LifeCategoryFragmentService.fragmentsFor(
            saju: sajuMe, category: cat, gender: 'M');
        final fGf = await LifeCategoryFragmentService.fragmentsFor(
            saju: sajuGf, category: cat, gender: 'F');
        // 두 fragment list 가 정확히 같으면 anchor 다층화 효과 0 → FAIL.
        expect(fMe, isNot(equals(fGf)),
            reason: '$cat 카테고리에서 본인/여친 fragment 셋이 동일하면 다층화 효과 X');
      }
    });

    test('B5 — fragmentsFor idempotent (같은 사주 → 같은 출력)', () async {
      final f1 = await LifeCategoryFragmentService.fragmentsFor(
          saju: sajuMe, category: LifeCategory.personality);
      final f2 = await LifeCategoryFragmentService.fragmentsFor(
          saju: sajuMe, category: LifeCategory.personality);
      expect(f1, equals(f2));
    });

    test('B6 — conclusionSelf 카테고리 = fragment X (LifeOverviewService 가 빌드)', () async {
      final frag = await LifeCategoryFragmentService.fragmentsFor(
          saju: sajuMe, category: LifeCategory.conclusionSelf);
      expect(frag, isEmpty);
    });
  });

  group('R90 sprint 2/3 — LifeParagraphService.paragraphForSaju injection', () {
    setUp(() {
      LifeCategoryFragmentService.resetCache();
      LifeParagraphService.resetCache();
    });

    final sajuMe = SajuResult(
      yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
      monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'),
      dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
      hourPillar: const Pillar(chunGan: '丁', jiJi: '酉'),
      elements: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
      dayMaster: '辛',
      dayMasterName: 'Yin Metal Rabbit',
      summary: '',
      categoryReadings: const {},
      isMale: true,
    );

    final sajuGf = SajuResult(
      yearPillar: const Pillar(chunGan: '癸', jiJi: '酉'),
      monthPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
      dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
      hourPillar: const Pillar(chunGan: '己', jiJi: '亥'),
      elements: const FiveElements(wood: 38, fire: 5, earth: 14, metal: 28, water: 15),
      dayMaster: '辛',
      dayMasterName: 'Yin Metal Rabbit',
      summary: '',
      categoryReadings: const {},
      isMale: false,
    );

    test('C1 — paragraphForSaju 본인 / 여친 → 다른 본문 (같은 신묘)', () async {
      for (final cat in [
        LifeCategory.earlyLife,
        LifeCategory.midLife,
        LifeCategory.personality,
        LifeCategory.loveFate,
        LifeCategory.wealth,
      ]) {
        final pMe = await LifeParagraphService.paragraphForSajuStatic(
            saju: sajuMe, category: cat, gender: 'M');
        final pGf = await LifeParagraphService.paragraphForSajuStatic(
            saju: sajuGf, category: cat, gender: 'F');
        // 본문 길이 ≥ 100 (base + fragment).
        expect(pMe.length, greaterThan(100));
        expect(pGf.length, greaterThan(100));
        // 같은 신묘 일주여도 fragment 결합 후 본문 달라야.
        expect(pMe, isNot(equals(pGf)),
            reason: '$cat — 본인/여친 본문이 100% 동일하면 R89 결함 재발');
      }
    });

    test('C2 — paragraphForSaju 본인 vs 여친 Jaccard ≥40% (anchor 다층화 효과)', () async {
      // 6 핵심 카테고리.
      final cats = [
        LifeCategory.earlyLife,
        LifeCategory.midLife,
        LifeCategory.personality,
        LifeCategory.loveFate,
        LifeCategory.wealth,
        LifeCategory.affection,
      ];
      var totalDiffRatio = 0.0;
      for (final cat in cats) {
        final pMe = await LifeParagraphService.paragraphForSajuStatic(
            saju: sajuMe, category: cat, gender: 'M');
        final pGf = await LifeParagraphService.paragraphForSajuStatic(
            saju: sajuGf, category: cat, gender: 'F');
        // 4-gram Jaccard.
        Set<String> ngrams(String s, int n) {
          final out = <String>{};
          for (int i = 0; i + n <= s.length; i++) {
            out.add(s.substring(i, i + n));
          }
          return out;
        }

        final a = ngrams(pMe, 4);
        final b = ngrams(pGf, 4);
        final inter = a.intersection(b).length;
        final union = a.union(b).length;
        final sim = union == 0 ? 0.0 : inter / union;
        final diff = 1 - sim;
        totalDiffRatio += diff;
      }
      final avgDiff = totalDiffRatio / cats.length;
      // Jaccard 차별성 ≥ 0.40.
      expect(avgDiff, greaterThanOrEqualTo(0.40),
          reason:
              '본인(辛卯+戌월) vs 여친(辛卯+寅월) 평균 본문 차별성 = ${(avgDiff * 100).toStringAsFixed(1)}%. R90 baseline ≥ 40%.');
    });
  });
}
