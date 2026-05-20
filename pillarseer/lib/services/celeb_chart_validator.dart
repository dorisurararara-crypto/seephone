// Pillar Seer — 셀럽 3주(年月日) 계산 검증기 (R105 Sprint 1, "최애의 사주").
//
// 셀럽은 출생 시(時)가 공개되지 않았으므로 네 번째 기둥(hourPillar)을 절대
// 생성·암시하지 않는다. 사주는 年柱·月柱·日柱 세 기둥만 다룬다.
//
// 핵심 동작:
//   1) 출생일 YYYY-MM-DD 를 기존 사주 엔진(ManseryeokService)으로 unknownTime=true
//      계산 → 年月日 3주를 얻는다 (hourPillar 는 항상 null).
//   2) 같은 날짜를 00:00 / 12:00 / 23:00 세 시각으로 계산해 年柱·月柱 안정성을
//      교차검증한다. 셋이 모두 같으면 confidence=stable, 절기/입춘 경계로 月柱 또는
//      年柱가 바뀌면 boundary_ambiguous.
//      (unknownTime=true 라 시간이 본래 무시되지만, 엔진 회귀나 경계 데이터를
//       방어적으로 잡기 위한 교차검증이다.)
//   3) 계산된 日柱가 celebrities.json 의 dayPillar 와 다르면 검증 실패.
//
// 사용처: test/r105_*.dart 회귀 가드. 화면 코드는 celeb_saju_readings.json 의
// 미리 계산된 chart 를 읽으므로 런타임에 이 검증기를 호출하지 않는다.

import 'manseryeok_service.dart';

/// 셀럽 한 명의 3주 계산 결과 + 안정성 라벨.
class CelebChartResult {
  /// celebrities.json 의 셀럽 id.
  final String celebId;

  /// 年柱 한자 2자.
  final String yearPillar;

  /// 月柱 한자 2자.
  final String monthPillar;

  /// 日柱 한자 2자.
  final String dayPillar;

  /// `stable` = 00/12/23h 계산이 모두 동일.
  /// `boundary_ambiguous` = 절기/입춘 경계로 年柱 또는 月柱가 시각에 따라 흔들림.
  final String confidence;

  /// 셀럽 출생 시(時)는 공개되지 않으므로 네 번째 기둥은 항상 null.
  Object? get hourPillar => null;

  const CelebChartResult({
    required this.celebId,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.confidence,
  });

  bool get isStable => confidence == 'stable';
  bool get isBoundaryAmbiguous => confidence == 'boundary_ambiguous';
}

/// 셀럽 3주 계산 검증기.
class CelebChartValidator {
  CelebChartValidator._();

  /// 교차검증에 쓰는 시각 — 자정 직후 / 정오 / 자시 진입 직전.
  static const List<int> _probeHours = [0, 12, 23];

  /// 출생일 [birth] (YYYY-MM-DD) 를 기존 엔진으로 계산해 3주 + 안정성 라벨을 낸다.
  /// 날짜 파싱 실패 시 null.
  static CelebChartResult? computeChart({
    required String celebId,
    required String birth,
    bool isMale = true,
  }) {
    final parsed = _parseBirth(birth);
    if (parsed == null) return null;
    final (year, month, day) = parsed;

    final years = <String>{};
    final months = <String>{};
    final days = <String>{};
    String? lastYear;
    String? lastMonth;
    String? lastDay;

    for (final hour in _probeHours) {
      final r = ManseryeokService.calculate(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: 0,
        isLunar: false,
        isMale: isMale,
        // 셀럽 = 출생 시(時) 미상. 네 번째 기둥 미계산 보장.
        unknownTime: true,
      );
      // 방어선: 엔진이 unknownTime 계약을 어기면 즉시 드러나게 한다.
      if (r.hourPillar != null) {
        return null;
      }
      years.add(r.yearPillar.text);
      months.add(r.monthPillar.text);
      days.add(r.dayPillar.text);
      lastYear = r.yearPillar.text;
      lastMonth = r.monthPillar.text;
      lastDay = r.dayPillar.text;
    }

    final stable = years.length == 1 && months.length == 1;
    return CelebChartResult(
      celebId: celebId,
      yearPillar: lastYear!,
      monthPillar: lastMonth!,
      dayPillar: lastDay!,
      confidence: stable ? 'stable' : 'boundary_ambiguous',
    );
  }

  /// 계산된 [computed] 의 日柱가 celebrities.json 의 [recordedDayPillar] 와
  /// 일치하는지 검사. 불일치면 false → 회귀 가드 테스트가 fail.
  static bool dayPillarMatches({
    required CelebChartResult computed,
    required String recordedDayPillar,
  }) {
    return computed.dayPillar == recordedDayPillar.trim();
  }

  /// YYYY-MM-DD → (year, month, day). 형식이 어긋나면 null.
  static (int, int, int)? _parseBirth(String birth) {
    final parts = birth.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return (y, m, d);
  }
}
