// R90 sprint 6 — 30 sample paragraph 추출 (codex audit 입력).
// 본인 / 여친 / 5행 5종 / 격국 2 / 십성 2 = 10 case × 3 카테고리 = 30 sample.
// stdout 으로 sample 출력 → codex audit 으로 9.9+ PASS 검증.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_category_fragment_service.dart';
import 'package:pillarseer/services/life_overview_service.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';
import 'package:pillarseer/services/self_conclusion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('R90 sprint 6 — 30 sample dump (codex audit 입력)', () async {
    LifeParagraphService.resetCache();
    LifeCategoryFragmentService.resetCache();

    SajuResult mk({
      required Pillar y,
      required Pillar m,
      required Pillar d,
      required Pillar h,
      required FiveElements el,
      required bool isMale,
    }) =>
        SajuResult(
          yearPillar: y,
          monthPillar: m,
          dayPillar: d,
          hourPillar: h,
          elements: el,
          dayMaster: d.chunGan,
          dayMasterName: '',
          summary: '',
          categoryReadings: const {},
          isMale: isMale,
        );

    final cases = <(String, SajuResult)>[
      (
        '01_본인_辛卯_戌월_金압도',
        mk(
          y: const Pillar(chunGan: '乙', jiJi: '亥'),
          m: const Pillar(chunGan: '丙', jiJi: '戌'),
          d: const Pillar(chunGan: '辛', jiJi: '卯'),
          h: const Pillar(chunGan: '丁', jiJi: '酉'),
          el: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
          isMale: true,
        ),
      ),
      (
        '02_여친_辛卯_寅월_木압도',
        mk(
          y: const Pillar(chunGan: '癸', jiJi: '酉'),
          m: const Pillar(chunGan: '甲', jiJi: '寅'),
          d: const Pillar(chunGan: '辛', jiJi: '卯'),
          h: const Pillar(chunGan: '己', jiJi: '亥'),
          el: const FiveElements(wood: 38, fire: 5, earth: 14, metal: 28, water: 15),
          isMale: false,
        ),
      ),
      (
        '03_甲日_寅월_木압도',
        mk(
          y: const Pillar(chunGan: '丙', jiJi: '寅'),
          m: const Pillar(chunGan: '甲', jiJi: '寅'),
          d: const Pillar(chunGan: '甲', jiJi: '子'),
          h: const Pillar(chunGan: '乙', jiJi: '丑'),
          el: const FiveElements(wood: 55, fire: 15, earth: 10, metal: 5, water: 15),
          isMale: true,
        ),
      ),
      (
        '04_丙日_午월_火압도',
        mk(
          y: const Pillar(chunGan: '丙', jiJi: '午'),
          m: const Pillar(chunGan: '甲', jiJi: '午'),
          d: const Pillar(chunGan: '丙', jiJi: '寅'),
          h: const Pillar(chunGan: '丁', jiJi: '巳'),
          el: const FiveElements(wood: 15, fire: 55, earth: 10, metal: 5, water: 15),
          isMale: false,
        ),
      ),
      (
        '05_戊日_未월_土압도',
        mk(
          y: const Pillar(chunGan: '戊', jiJi: '辰'),
          m: const Pillar(chunGan: '己', jiJi: '未'),
          d: const Pillar(chunGan: '戊', jiJi: '戌'),
          h: const Pillar(chunGan: '丁', jiJi: '丑'),
          el: const FiveElements(wood: 5, fire: 15, earth: 55, metal: 15, water: 10),
          isMale: true,
        ),
      ),
      (
        '06_庚日_酉월_金압도',
        mk(
          y: const Pillar(chunGan: '辛', jiJi: '酉'),
          m: const Pillar(chunGan: '己', jiJi: '酉'),
          d: const Pillar(chunGan: '庚', jiJi: '申'),
          h: const Pillar(chunGan: '辛', jiJi: '巳'),
          el: const FiveElements(wood: 5, fire: 10, earth: 15, metal: 55, water: 15),
          isMale: true,
        ),
      ),
      (
        '07_壬日_子월_水압도',
        mk(
          y: const Pillar(chunGan: '癸', jiJi: '亥'),
          m: const Pillar(chunGan: '甲', jiJi: '子'),
          d: const Pillar(chunGan: '壬', jiJi: '子'),
          h: const Pillar(chunGan: '辛', jiJi: '亥'),
          el: const FiveElements(wood: 5, fire: 5, earth: 10, metal: 25, water: 55),
          isMale: false,
        ),
      ),
      (
        '08_乙日_酉월_정관격',
        mk(
          y: const Pillar(chunGan: '丁', jiJi: '巳'),
          m: const Pillar(chunGan: '己', jiJi: '酉'),
          d: const Pillar(chunGan: '乙', jiJi: '亥'),
          h: const Pillar(chunGan: '辛', jiJi: '巳'),
          el: const FiveElements(wood: 10, fire: 25, earth: 15, metal: 35, water: 15),
          isMale: false,
        ),
      ),
      (
        '09_丁日_亥월_편관격',
        mk(
          y: const Pillar(chunGan: '甲', jiJi: '子'),
          m: const Pillar(chunGan: '乙', jiJi: '亥'),
          d: const Pillar(chunGan: '丁', jiJi: '巳'),
          h: const Pillar(chunGan: '癸', jiJi: '卯'),
          el: const FiveElements(wood: 25, fire: 25, earth: 5, metal: 5, water: 40),
          isMale: true,
        ),
      ),
      (
        '10_己日_未월_식신격',
        mk(
          y: const Pillar(chunGan: '辛', jiJi: '未'),
          m: const Pillar(chunGan: '辛', jiJi: '未'),
          d: const Pillar(chunGan: '己', jiJi: '亥'),
          h: const Pillar(chunGan: '辛', jiJi: '酉'),
          el: const FiveElements(wood: 5, fire: 10, earth: 35, metal: 35, water: 15),
          isMale: false,
        ),
      ),
    ];

    final buf = StringBuffer();
    for (final (label, saju) in cases) {
      final overview = await LifeOverviewService.compose(saju, isMale: saju.isMale ?? true);
      final earlyLife = await LifeParagraphService.paragraphForSajuStatic(
        saju: saju,
        category: LifeCategory.earlyLife,
        gender: (saju.isMale ?? true) ? 'M' : 'F',
      );
      final concl = await SelfConclusionService.conclude(saju, isMale: saju.isMale ?? true);

      buf.writeln('===== $label =====');
      buf.writeln('--- [overview] ---');
      buf.writeln(overview);
      buf.writeln('--- [earlyLife] ---');
      buf.writeln(earlyLife);
      buf.writeln('--- [conclusion] ---');
      buf.writeln(concl);
      buf.writeln();
    }

    // 파일 출력 — codex audit input.
    final file = File('/tmp/r90_sample_30.txt');
    file.writeAsStringSync(buf.toString());
    // 길이 sanity.
    expect(buf.toString().length, greaterThan(10000));
    // ignore: avoid_print
    print('R90 sample dump → ${file.path} (${buf.length} chars)');
  });
}
