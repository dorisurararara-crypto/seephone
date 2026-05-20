// R105 Sprint 1 — 최애의 사주 셀럽 3주 계산 회귀/거짓말방지 가드.
//
// 검증 (mandate):
//   1) celebrities.json 223명 전원 dayPillar 길이 2 + birth 파싱 가능.
//   2) 셀럽 chart audit — CelebChartValidator 가 계산한 日柱가 celebrities.json 의
//      dayPillar 와 모두 일치 (불일치 0). boundary_ambiguous 셀럽 수 보고.
//   3) 시주는 항상 null — 셀럽 출생 시(時) 미상, 時柱 생성 금지.
//   4) celeb_saju_readings.json 의 chart.hourPillar 는 전부 null.
//
// 회귀 보호: 이 테스트가 fail 하면 만세력 엔진 또는 celebrities.json dayPillar 가
// 깨진 것이다. threshold 를 낮추지 말 것.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/celeb_chart_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> celebs;

  setUpAll(() {
    final raw = File('assets/data/celebrities.json').readAsStringSync();
    celebs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  group('R105 — celebrities.json schema', () {
    test('223명 전원 dayPillar 길이 2 + birth 파싱 가능', () {
      expect(celebs.length, 223, reason: 'celebrities.json entry 수 baseline');
      for (final c in celebs) {
        final id = c['id'] as String? ?? '(no id)';
        final dp = (c['dayPillar'] as String?) ?? '';
        expect(dp.length, 2, reason: '$id dayPillar 길이 != 2 ("$dp")');
        final birth = (c['birth'] as String?) ?? '';
        final parts = birth.split('-');
        expect(parts.length, 3, reason: '$id birth 형식 위반 ("$birth")');
        expect(int.tryParse(parts[0]), isNotNull, reason: '$id birth year');
        expect(int.tryParse(parts[1]), isNotNull, reason: '$id birth month');
        expect(int.tryParse(parts[2]), isNotNull, reason: '$id birth day');
      }
    });
  });

  group('R105 — 셀럽 3주 계산 검증기', () {
    test('계산된 日柱가 celebrities.json dayPillar 와 모두 일치 (불일치 0)', () {
      final mismatches = <String>[];
      var boundaryAmbiguous = 0;
      var failedToCompute = 0;

      for (final c in celebs) {
        final id = c['id'] as String? ?? '(no id)';
        final birth = (c['birth'] as String?) ?? '';
        final recorded = (c['dayPillar'] as String?) ?? '';
        final isMale = (c['gender'] as String?) == 'M';

        final chart = CelebChartValidator.computeChart(
          celebId: id,
          birth: birth,
          isMale: isMale,
        );
        if (chart == null) {
          failedToCompute++;
          mismatches.add('$id: chart 계산 실패 (birth=$birth)');
          continue;
        }
        // 시주는 항상 null.
        expect(
          chart.hourPillar,
          isNull,
          reason: '$id hourPillar 가 null 이 아님 — 시주 생성 금지 위반',
        );
        if (!CelebChartValidator.dayPillarMatches(
          computed: chart,
          recordedDayPillar: recorded,
        )) {
          mismatches.add(
            '$id: 계산 ${chart.dayPillar} != 기록 $recorded (birth=$birth)',
          );
        }
        if (chart.isBoundaryAmbiguous) boundaryAmbiguous++;
      }

      // 보고용 로그.
      // ignore: avoid_print
      print(
        'R105 chart audit — 총 ${celebs.length}명 / '
        'dayPillar 불일치 ${mismatches.length} / '
        'boundary_ambiguous $boundaryAmbiguous / '
        '계산실패 $failedToCompute',
      );
      if (boundaryAmbiguous > 0) {
        // ignore: avoid_print
        print('R105 boundary_ambiguous count = $boundaryAmbiguous');
      }
      if (mismatches.isNotEmpty) {
        // ignore: avoid_print
        print('R105 mismatches:\n  ${mismatches.join('\n  ')}');
      }

      expect(
        mismatches,
        isEmpty,
        reason: 'dayPillar 불일치 발견 — 만세력 엔진 또는 데이터 회귀',
      );
    });
  });

  group('R105 — celeb_saju_readings chart 무결성', () {
    test('모든 셀럽 chart.hourPillar 는 null (시주 금지)', () {
      final raw = File(
        'assets/data/celeb_saju_readings.json',
      ).readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((id, value) {
        if (id == '_meta') return;
        final chart = (value as Map<String, dynamic>)['chart'];
        expect(chart, isA<Map<String, dynamic>>(), reason: '$id chart 누락');
        expect(
          (chart as Map<String, dynamic>)['hourPillar'],
          isNull,
          reason: '$id chart.hourPillar 가 null 이 아님 — 시주 금지 위반',
        );
        expect(
          (chart['yearPillar'] as String?)?.length,
          2,
          reason: '$id yearPillar 길이 != 2',
        );
        expect(
          (chart['monthPillar'] as String?)?.length,
          2,
          reason: '$id monthPillar 길이 != 2',
        );
        expect(
          (chart['dayPillar'] as String?)?.length,
          2,
          reason: '$id dayPillar 길이 != 2',
        );
      });
    });

    test('seed 셀럽(iu/rm) chart 가 계산값과 일치', () {
      final raw = File(
        'assets/data/celeb_saju_readings.json',
      ).readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final id in ['iu', 'rm']) {
        final celeb = celebs.firstWhere((c) => c['id'] == id);
        final birth = celeb['birth'] as String;
        final isMale = (celeb['gender'] as String?) == 'M';
        final computed = CelebChartValidator.computeChart(
          celebId: id,
          birth: birth,
          isMale: isMale,
        );
        expect(computed, isNotNull, reason: '$id chart 계산 실패');
        final chart =
            (map[id] as Map<String, dynamic>)['chart'] as Map<String, dynamic>;
        expect(
          chart['yearPillar'],
          computed!.yearPillar,
          reason: '$id yearPillar mismatch',
        );
        expect(
          chart['monthPillar'],
          computed.monthPillar,
          reason: '$id monthPillar mismatch',
        );
        expect(
          chart['dayPillar'],
          computed.dayPillar,
          reason: '$id dayPillar mismatch',
        );
        expect(
          chart['confidence'],
          computed.confidence,
          reason: '$id confidence mismatch',
        );
      }
    });
  });
}
