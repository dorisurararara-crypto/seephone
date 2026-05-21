// R107 — 최애의 사주 셀럽 차트 검증 로그(chartValidation) 무결성 가드.
//
// codex 재검수 지적: "셀럽 차트 계산 근거가 stable 메타 문자열만 있고 외부
// 재검증 로그가 부족하다." → R107 에서 각 셀럽 chart 에 chartValidation 추가.
//
// 검증 (거짓말 0 / 회귀 0):
//   1) celeb_saju_readings.json 의 30명 전원 chart.chartValidation 존재.
//   2) chartValidation 의 birthInput 이 celebrities.json 의 birth 와 일치.
//   3) CelebChartValidator 를 지금 다시 돌린 값이 저장된 chart 와 일치 (불일치 0).
//   4) chartValidation.recomputed / probes 가 live 재계산값과 글자 단위 일치 —
//      손계산·날조 0 임을 보장.
//   5) chartValidation.confidence 근거(probe 안정성)가 실제 probe 결과와 모순 없음.
//   6) hourPillar 는 여전히 전원 null (시주 금지 불변).
//
// 회귀 보호: fail 하면 만세력 엔진 회귀 또는 chartValidation 날조. threshold 금지.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/celeb_chart_validator.dart';
import 'package:pillarseer/services/manseryeok_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> readings;
  late Map<String, Map<String, dynamic>> celebsById;

  setUpAll(() {
    readings = jsonDecode(
      File('assets/data/celeb_saju_readings.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final celebs = (jsonDecode(
      File('assets/data/celebrities.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    celebsById = {for (final c in celebs) c['id'] as String: c};
  });

  Iterable<String> celebIds() =>
      readings.keys.where((k) => k != '_meta');

  group('R107 — chartValidation 존재 + 구조', () {
    test('30명 전원 chart.chartValidation 존재 + 필수 필드', () {
      final ids = celebIds().toList();
      expect(ids.length, 30, reason: '셀럽 reading 수 baseline');
      for (final id in ids) {
        final chart =
            (readings[id] as Map<String, dynamic>)['chart']
                as Map<String, dynamic>;
        final cv = chart['chartValidation'];
        expect(cv, isA<Map<String, dynamic>>(),
            reason: '$id chartValidation 누락');
        final m = cv as Map<String, dynamic>;
        for (final key in const [
          'method',
          'validatorVersion',
          'computedDate',
          'birthInput',
          'birthSourceId',
          'probeHours',
          'probes',
          'recomputed',
          'matchesChart',
          'confidenceBasis',
        ]) {
          expect(m.containsKey(key), isTrue,
              reason: '$id chartValidation.$key 누락');
        }
        expect(m['matchesChart'], isTrue,
            reason: '$id chartValidation.matchesChart 가 true 가 아님');
        expect((m['probes'] as List).length, 3,
            reason: '$id probes 는 3시각이어야 함');
      }
    });

    test('birthInput 이 celebrities.json 의 birth 와 일치', () {
      for (final id in celebIds()) {
        final cv = ((readings[id] as Map<String, dynamic>)['chart']
            as Map<String, dynamic>)['chartValidation'] as Map<String, dynamic>;
        final celeb = celebsById[id];
        expect(celeb, isNotNull,
            reason: '$id celebrities.json 에 없음');
        expect(cv['birthInput'], celeb!['birth'],
            reason: '$id birthInput != celebrities.json birth');
        expect(cv['birthSourceId'], 'celebrities.json#$id',
            reason: '$id birthSourceId 형식 위반');
      }
    });
  });

  group('R107 — validator 재계산 일치 (거짓말 0)', () {
    test('live 재계산값이 저장 chart 및 chartValidation 과 글자 단위 일치', () {
      final mismatches = <String>[];

      for (final id in celebIds()) {
        final chart =
            (readings[id] as Map<String, dynamic>)['chart']
                as Map<String, dynamic>;
        final cv = chart['chartValidation'] as Map<String, dynamic>;
        final celeb = celebsById[id]!;
        final birth = celeb['birth'] as String;
        final isMale = (celeb['gender'] as String?) == 'M';

        // (a) 저장 chart 와 live computeChart 일치.
        final computed = CelebChartValidator.computeChart(
          celebId: id,
          birth: birth,
          isMale: isMale,
        );
        if (computed == null) {
          mismatches.add('$id: computeChart 실패 (birth=$birth)');
          continue;
        }
        if (computed.hourPillar != null) {
          mismatches.add('$id: hourPillar != null — 시주 금지 위반');
        }
        if (chart['yearPillar'] != computed.yearPillar ||
            chart['monthPillar'] != computed.monthPillar ||
            chart['dayPillar'] != computed.dayPillar ||
            chart['confidence'] != computed.confidence) {
          mismatches.add(
            '$id: 저장 chart != live computeChart '
            '(${chart['yearPillar']}/${chart['monthPillar']}/'
            '${chart['dayPillar']}/${chart['confidence']} vs '
            '${computed.yearPillar}/${computed.monthPillar}/'
            '${computed.dayPillar}/${computed.confidence})',
          );
        }

        // (b) chartValidation.recomputed 가 live computeChart 와 일치.
        final rec = cv['recomputed'] as Map<String, dynamic>;
        if (rec['yearPillar'] != computed.yearPillar ||
            rec['monthPillar'] != computed.monthPillar ||
            rec['dayPillar'] != computed.dayPillar) {
          mismatches.add(
            '$id: chartValidation.recomputed 가 live 값과 불일치 (날조 의심)',
          );
        }

        // (c) chartValidation.probes 가 live 3시각 재계산과 글자 단위 일치.
        final parts = birth.split('-');
        final y = int.parse(parts[0]);
        final mo = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        final probes = (cv['probes'] as List).cast<Map<String, dynamic>>();
        for (var i = 0; i < probes.length; i++) {
          final p = probes[i];
          final hour = p['hour'] as int;
          final r = ManseryeokService.calculate(
            year: y,
            month: mo,
            day: d,
            hour: hour,
            minute: 0,
            isLunar: false,
            isMale: isMale,
            unknownTime: true,
          );
          if (p['yearPillar'] != r.yearPillar.text ||
              p['monthPillar'] != r.monthPillar.text ||
              p['dayPillar'] != r.dayPillar.text) {
            mismatches.add(
              '$id: probe[$hour시] 저장값 != live 재계산값 (날조 의심)',
            );
          }
        }
      }

      // ignore: avoid_print
      print(
        'R107 chartValidation audit — 30명 / live 재계산 불일치 '
        '${mismatches.length}',
      );
      if (mismatches.isNotEmpty) {
        // ignore: avoid_print
        print('R107 mismatches:\n  ${mismatches.join('\n  ')}');
      }
      expect(mismatches, isEmpty,
          reason: 'chartValidation 이 live 재계산과 불일치 — 데이터 회귀 또는 날조');
    });

    test('confidence 근거가 probe 안정성과 모순 없음', () {
      for (final id in celebIds()) {
        final chart =
            (readings[id] as Map<String, dynamic>)['chart']
                as Map<String, dynamic>;
        final cv = chart['chartValidation'] as Map<String, dynamic>;
        final probes = (cv['probes'] as List).cast<Map<String, dynamic>>();
        final years = probes.map((p) => p['yearPillar']).toSet();
        final months = probes.map((p) => p['monthPillar']).toSet();
        final stableByProbe = years.length == 1 && months.length == 1;
        final expected = stableByProbe ? 'stable' : 'boundary_ambiguous';
        expect(chart['confidence'], expected,
            reason: '$id confidence 가 probe 안정성과 모순');
      }
    });
  });

  group('R107 — 회귀 불변', () {
    test('chart.hourPillar 전원 null (시주 금지 불변)', () {
      for (final id in celebIds()) {
        final chart =
            (readings[id] as Map<String, dynamic>)['chart']
                as Map<String, dynamic>;
        expect(chart['hourPillar'], isNull,
            reason: '$id hourPillar != null — 시주 금지 위반');
      }
    });

    test('기존 chart 3주 / usedFactIds / sections 키 보존', () {
      for (final id in celebIds()) {
        final entry = readings[id] as Map<String, dynamic>;
        final chart = entry['chart'] as Map<String, dynamic>;
        expect((chart['yearPillar'] as String).length, 2);
        expect((chart['monthPillar'] as String).length, 2);
        expect((chart['dayPillar'] as String).length, 2);
        expect(entry['usedFactIds'], isA<List<dynamic>>(),
            reason: '$id usedFactIds 누락');
        expect(entry['sections'], isA<List<dynamic>>(),
            reason: '$id sections 누락');
      }
    });
  });
}
