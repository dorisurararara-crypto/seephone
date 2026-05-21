// R107 — 최애의 사주 검증 로그 생성기 (1회성).
//
// celebrities.json 의 각 셀럽 출생일을 CelebChartValidator 로 실제 계산하여
// (00:00 / 12:00 / 23:00 세 시각 교차검증) 검증 근거를 stdout 에 JSON 으로 출력.
// 출력 결과를 celeb_saju_readings.json 의 각 entry.chart.chartValidation 으로 병합.
//
// 손으로 차트를 지어내지 않는다 — 전부 validator 실측값.
//
// 실행: flutter test tool/r107_compute_celeb_validation.dart 형태가 아니라
//   dart 단독 실행이 불가하므로 (flutter_test 바인딩 필요), test 파일로 구동한다.
//   r107_celeb_chart_validation_test.dart 내부에서 동일 로직을 직접 호출한다.

import 'dart:convert';
import 'dart:io';

import 'package:pillarseer/services/celeb_chart_validator.dart';
import 'package:pillarseer/services/manseryeok_service.dart';

/// 셀럽 한 명의 검증 로그를 산출한다. validator 와 동일한 probe 시각으로
/// 3시각 각각의 年月日 을 함께 기록해 재현 가능하게 만든다.
Map<String, dynamic> buildValidation({
  required String celebId,
  required String birth,
  required bool isMale,
}) {
  final result = CelebChartValidator.computeChart(
    celebId: celebId,
    birth: birth,
    isMale: isMale,
  );
  if (result == null) {
    return {'error': 'compute_failed', 'birth': birth};
  }

  final parts = birth.split('-');
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);

  final probes = <Map<String, dynamic>>[];
  for (final hour in const [0, 12, 23]) {
    final r = ManseryeokService.calculate(
      year: y,
      month: m,
      day: d,
      hour: hour,
      minute: 0,
      isLunar: false,
      isMale: isMale,
      unknownTime: true,
    );
    probes.add({
      'hour': hour,
      'yearPillar': r.yearPillar.text,
      'monthPillar': r.monthPillar.text,
      'dayPillar': r.dayPillar.text,
    });
  }

  final years = probes.map((p) => p['yearPillar']).toSet();
  final months = probes.map((p) => p['monthPillar']).toSet();
  final days = probes.map((p) => p['dayPillar']).toSet();
  final stable = years.length == 1 && months.length == 1;

  return {
    'method': 'celeb_chart_validator',
    'birthInput': birth,
    'probeHours': const [0, 12, 23],
    'probes': probes,
    'yearPillarStable': years.length == 1,
    'monthPillarStable': months.length == 1,
    'dayPillarStable': days.length == 1,
    'computed': {
      'yearPillar': result.yearPillar,
      'monthPillar': result.monthPillar,
      'dayPillar': result.dayPillar,
    },
    'confidence': result.confidence,
    'confidenceBasis': stable
        ? '00:00 / 12:00 / 23:00 세 시각 모두 年柱·月柱 동일 → stable'
        : '시각에 따라 年柱 또는 月柱 변동 → boundary_ambiguous (절기/입춘 경계)',
  };
}

/// celebrities.json 을 읽어 readings 의 30명 검증 로그를 stdout 에 출력.
void runComputation() {
  final celebsRaw = File('assets/data/celebrities.json').readAsStringSync();
  final celebs = (jsonDecode(celebsRaw) as List).cast<Map<String, dynamic>>();
  final cmap = {for (final c in celebs) c['id'] as String: c};

  final readingsRaw =
      File('assets/data/celeb_saju_readings.json').readAsStringSync();
  final readings = jsonDecode(readingsRaw) as Map<String, dynamic>;

  final out = <String, dynamic>{};
  readings.forEach((id, value) {
    if (id == '_meta') return;
    final celeb = cmap[id];
    if (celeb == null) {
      out[id] = {'error': 'not_in_celebrities_json'};
      return;
    }
    out[id] = buildValidation(
      celebId: id,
      birth: celeb['birth'] as String,
      isMale: (celeb['gender'] as String?) == 'M',
    );
  });

  stdout.writeln('===R107_VALIDATION_JSON_BEGIN===');
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln('===R107_VALIDATION_JSON_END===');
}
