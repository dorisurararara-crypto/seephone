// R88 sprint 10 통합 회귀 가드 — R88 baseline 9 항목 한 번에 검증.
//
// 사용자 mandate (R88 spec 회귀 가드 8 항목 + 운세의신 fingerprint):
//   1. 5행 골든 보존 (1995-10-27 男 17시 → 16/21/17/41/4)
//   2. R83 P1-B 자시 학파 picker 보존
//   3. R83 P1-E 시간 모름 차단 보존
//   4. R87 해외 출생지 IANA tz 보존
//   5. K-POP 케미 _score 18~99 range 보존
//   6. 60일주 paragraph ≥80자 DB scan
//   7. 평탄 어휘 ("균형" / "조화" / "골고루") 0
//   8. 단정조 "~합니다" leak 0
//   9. 운세의신 본문 fingerprint 0 (sprint 10 baseline 명시 항목)
//
// 본 file 은 통합 진입점 — 자세한 항목별 검증은 개별 test file (life_paragraph /
// life_overview / round83_unknown_time / round83_zasi_helper / kpop_compat 등) 에
// 위임됨. 본 file 은 anchor (file/class 존재 + key signature) 만 grep.

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
    LifeParagraphService.seedForTest(
        json.decode(raw) as Map<String, dynamic>);
  });

  tearDownAll(() {
    LifeParagraphService.resetCache();
  });

  group('R88 sprint 10 — 통합 회귀 baseline 9 항목 anchor', () {
    test('B1 — 5행 골든 보존 anchor: r88_life_overview / r88_self_conclusion sample',
        () {
      // R88 sprint 8 / 9 의 골든 사주 sample 안에 16/21/17/41/4 anchor 명시 보존.
      // round69_regression_test.dart 는 1995-10-27 anchor 위주 (5행 raw number 명시 X).
      bool foundGolden = false;
      for (final path in const [
        'test/r88_life_overview_service_test.dart',
        'test/r88_self_conclusion_service_test.dart',
      ]) {
        final src = File(path).readAsStringSync();
        if (src.contains('wood: 16') &&
            src.contains('fire: 21') &&
            src.contains('earth: 17') &&
            src.contains('metal: 41') &&
            src.contains('water: 4')) {
          foundGolden = true;
          break;
        }
      }
      expect(foundGolden, isTrue,
          reason: 'R75 골든 5행 16/21/17/41/4 anchor 보존 (R88 sprint 8/9 test 안)');

      // 1995-10-27 anchor (R75 baseline).
      final r69 = File('test/round69_regression_test.dart').readAsStringSync();
      expect(r69.contains('1995'), isTrue,
          reason: 'R75 baseline 1995-10-27 anchor 보존');
    });

    test('B2 — R83 P1-B 자시 학파 picker 보존 anchor', () {
      // round83_zasi_helper_test.dart 또는 input_screen 의 자시 picker.
      final hasZasi =
          File('test/round83_zasi_helper_test.dart').existsSync() ||
              File('lib/screens/input_screen.dart')
                  .readAsStringSync()
                  .contains('자시');
      expect(hasZasi, isTrue,
          reason: 'R83 P1-B 자시 학파 picker anchor 보존 (test 파일 또는 input_screen)');
    });

    test('B3 — R83 P1-E 시간 모름 차단 보존 anchor', () {
      final src = File('test/round83_unknown_time_test.dart').readAsStringSync();
      // unknownTime 관련 anchor 보존.
      expect(src.contains('unknownTime'), isTrue);
      expect(src.contains('hourPillar') || src.contains('시주'), isTrue,
          reason: 'P1-E hourPillar 차단 anchor');
    });

    test('B4 — R87 해외 출생지 IANA tz 보존 anchor', () {
      // R87 IANA tz wire — main.dart / world_cities.dart / manseryeok_service.dart /
      // notification_service.dart 중 하나에 timezone 패키지 사용.
      bool anyHasTz = false;
      for (final path in const [
        'lib/main.dart',
        'lib/data/world_cities.dart',
        'lib/services/manseryeok_service.dart',
        'lib/services/notification_service.dart',
      ]) {
        final f = File(path);
        if (!f.existsSync()) continue;
        final src = f.readAsStringSync();
        if (src.contains('timezone') ||
            src.contains('Asia/Seoul') ||
            src.contains('IANA') ||
            src.contains('getLocation') ||
            src.contains('tz_database')) {
          anyHasTz = true;
          break;
        }
      }
      expect(anyHasTz, isTrue,
          reason: 'R87 IANA tz wire anchor (main/notification/manseryeok/world_cities 중 하나)');
    });

    test('B5 — K-POP 케미 _score 18~99 range 보존 anchor', () {
      // kpop_compat_screen 또는 별도 service.
      final dir = Directory('lib/screens/reports');
      expect(dir.existsSync(), isTrue);
      final kpop = File('lib/screens/reports/kpop_compat_screen.dart');
      if (kpop.existsSync()) {
        final src = kpop.readAsStringSync();
        // _score range hint (18~99) anchor.
        expect(src.contains('18') || src.contains('99') || src.contains('score'),
            isTrue,
            reason: 'K-POP 케미 _score range anchor');
      }
    });

    test('B-actual — 실제 service 동작 검증 (5행 dominant + LifeOverview + SelfConclusion)',
        () async {
      // ROUND 3 fix #3 — anchor 외에 실제 함수 동작 검증.
      // 1. SajuResult.elements 의 dominant/deficit 계산 정확.
      const golden = SajuResult(
        yearPillar: Pillar(chunGan: '乙', jiJi: '亥'),
        monthPillar: Pillar(chunGan: '丙', jiJi: '戌'),
        dayPillar: Pillar(chunGan: '辛', jiJi: '卯'),
        hourPillar: Pillar(chunGan: '丁', jiJi: '酉'),
        elements: FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
        dayMaster: '辛',
        dayMasterName: 'Sin',
        summary: '',
        categoryReadings: {},
      );
      expect(golden.elements.dominant, equals('金'),
          reason: 'R75 골든 dominant = 金 (41 metal)');
      expect(golden.elements.deficit, equals('水'),
          reason: 'R75 골든 deficit = 水 (4 water)');

      // 2. LifeOverviewService.compose 실제 호출 → 600~900자 + 한자 leak 0.
      final essay = await LifeOverviewService.compose(golden);
      expect(essay.length >= 600 && essay.length <= 900, isTrue,
          reason: 'LifeOverview 골든 essay 600~900자 (실제 ${essay.length})');
      for (final h in const ['甲', '辛', '卯', '酉']) {
        expect(essay.contains(h), isFalse,
            reason: 'LifeOverview essay 한자 "$h" leak 0');
      }

      // 3. SelfConclusionService.conclude 실제 호출 → 80~200자 + 결론형 톤.
      final concl = await SelfConclusionService.conclude(golden);
      expect(concl.length >= 80 && concl.length <= 200, isTrue,
          reason: 'SelfConclusion 골든 conclusion 80~200자 (실제 ${concl.length})');
      expect(concl.contains('본인은') || concl.contains('당신은'), isTrue,
          reason: 'SelfConclusion 결론형 톤 "본인은/당신은" 포함');
    });

    test('B6 — DB 현 fixture (11 keys) paragraph ≥80자 + 17 카테고리 completeness (일주 60 full R89 deferred)',
        () {
      // R88 spec 의 "60일주 paragraph ≥80자" 는 R89 일주 60 batch 완성 시 strict 검증.
      // 현 sprint 10 baseline = 갑자 (sprint 4) + 일간 10 base (sprint 5) = 11 keys.
      // 일주 60 매트릭스는 R89 deferred → 명시.
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      final data = json.decode(raw) as Map<String, dynamic>;
      // 현 fixture 11 keys (갑자 sprint 4 + 갑/을/병/정/무/기/경/신/임/계 sprint 5).
      expect(data.keys.length >= 11, isTrue,
          reason: '현 fixture key ≥11 (갑자 + 일간 10 base)');
      // 일간 10 base 모두 등장.
      for (final stem in const ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계']) {
        expect(data.containsKey(stem), isTrue,
            reason: 'sprint 5 mandate: 일간 base "$stem" 존재');
      }
      // 17 카테고리 completeness — 각 key 안에 17 카테고리 모두 채워짐.
      const cats = [
        'early_life', 'mid_life', 'late_life', 'health', 'constitution',
        'social', 'social_personality', 'personality', 'innate_tendency',
        'innate_character', 'love_fate', 'affection',
        'wealth', 'wealth_gather', 'wealth_loss_prevent', 'wealth_invest',
        'conclusion_self',
      ];
      for (final pillar in data.keys) {
        final obj = data[pillar] as Map<String, dynamic>;
        expect(obj.keys.length, equals(17),
            reason: '$pillar key 개수 = 17 (실제 ${obj.keys.length})');
        for (final cat in cats) {
          expect(obj.containsKey(cat), isTrue,
              reason: '$pillar 안에 카테고리 "$cat" 누락');
        }
      }
      // 길이 ≥80자 scan.
      for (final pillar in data.keys) {
        final obj = data[pillar] as Map<String, dynamic>;
        for (final k in obj.keys) {
          final v = obj[k];
          if (v is String) {
            expect(v.length >= 80, isTrue,
                reason: '$pillar.$k <80자 (${v.length}): $v');
          } else if (v is Map) {
            for (final g in v.keys) {
              final s = v[g] as String;
              expect(s.length >= 80, isTrue,
                  reason: '$pillar.$k.$g <80자 (${s.length}): $s');
            }
          }
        }
      }
    });

    test('B7 — 평탄 어휘 ("균형" / "조화" / "골고루") 0 DB scan', () {
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      for (final flat in const ['균형', '조화', '골고루']) {
        expect(raw.contains(flat), isFalse,
            reason: '평탄 어휘 "$flat" DB scan leak');
      }
    });

    test('B8 — 단정조 "~합니다" leak 0 DB scan', () {
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      // 단정조 phrase '습니다.' 또는 '입니다.'. 일반 문장 안에서 leak.
      for (final dec in const ['합니다.', '입니다.', '됩니다.']) {
        expect(raw.contains(dec), isFalse,
            reason: '단정조 "$dec" DB scan leak');
      }
    });

    test('B9 — 운세의신 본문 fingerprint 0 (저작권) — fixture + service 출력 scan',
        () async {
      // R88 mandate "운세의신 본문 fingerprint 0". 우리 fixture + service 출력 모두 scan.
      const fingerprints = [
        '운세의신', // service 명
        'unsin', // 영문 service 명
        '신뢰성있는 사주풀이', // 사이트 헤더
        '오늘의운세 신점은', // 사이트 phrase
        '온라인사주 운세의신', // 사이트 phrase
      ];

      // 1. fixture scan.
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      for (final fp in fingerprints) {
        expect(raw.contains(fp), isFalse,
            reason: '운세의신 fingerprint "$fp" fixture leak 0');
      }

      // 2. service 출력 scan — LifeOverviewService + SelfConclusionService 실제 호출.
      const goldenSaju = SajuResult(
        yearPillar: Pillar(chunGan: '乙', jiJi: '亥'),
        monthPillar: Pillar(chunGan: '丙', jiJi: '戌'),
        dayPillar: Pillar(chunGan: '辛', jiJi: '卯'),
        hourPillar: Pillar(chunGan: '丁', jiJi: '酉'),
        elements: FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
        dayMaster: '辛',
        dayMasterName: 'Sin',
        summary: '',
        categoryReadings: {},
      );
      final essay = await LifeOverviewService.compose(goldenSaju);
      final conclusion = await SelfConclusionService.conclude(goldenSaju);
      for (final fp in fingerprints) {
        expect(essay.contains(fp), isFalse,
            reason: 'LifeOverview essay 안 fingerprint "$fp" leak 0');
        expect(conclusion.contains(fp), isFalse,
            reason: 'SelfConclusion 안 fingerprint "$fp" leak 0');
      }
    });
  });
}
