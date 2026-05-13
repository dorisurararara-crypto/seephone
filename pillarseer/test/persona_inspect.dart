// 사용자 페르소나 1995-10-27 15:43 남자 — 6 축 + 5 일 + chips 콘솔 출력 (audit용).
// flutter test test/persona_inspect.dart 으로 실행.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/five_day_trend_service.dart';
import 'package:pillarseer/services/lucky_chips_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/six_axis_score_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  test('1995-10-27 15:43 남자 — audit dump', () async {
    final saju = await SajuService().calculateSaju(
      year: 1995, month: 10, day: 27,
      hour: 15, minute: 43,
      isLunar: false, isMale: true,
    );
    final ziwei = ZiweiService.calculate(
      year: 1995, month: 10, day: 27,
      hour: 15, minute: 43,
      isMale: true,
    );

    final buf = StringBuffer();
    buf.writeln('==== Saju ====');
    buf.writeln('일주: ${saju.dayPillar.text} (${saju.dayPillar.pairKoreanMeaning})');
    buf.writeln('5행: 목${saju.elements.wood} 화${saju.elements.fire} '
        '토${saju.elements.earth} 금${saju.elements.metal} 수${saju.elements.water}');
    buf.writeln('dom=${saju.elements.dominant}, def=${saju.elements.deficit}');

    buf.writeln('\n==== 6 axis ====');
    final s = SixAxisScoreService.compute(saju, ziwei);
    for (final axis in SixAxisScore.axes) {
      final saj = s.sajuScores[axis];
      final ziw = s.ziweiScores[axis];
      final com = s.combinedScores[axis];
      final m = s.crossMatches[axis] == true ? '✨' : ' ';
      buf.writeln('  $axis: saju=$saj ziwei=$ziw combined=$com $m');
    }
    buf.writeln('matchCount=${s.matchCount}, matchedAxes=${s.matchedAxes}');
    buf.writeln('combinedAvg=${s.combinedAverage}');

    buf.writeln('\n==== 5 day trend ====');
    final points = FiveDayTrendService.compute(saju, today: DateTime(2026, 5, 13));
    for (final p in points) {
      buf.writeln('  ${p.label}: ${p.score}  (${p.date})');
    }

    buf.writeln('\n==== Lucky chips ====');
    final chips = LuckyChipsService.compute(saju, ziwei);
    for (final c in chips) {
      buf.writeln('  ${c.icon} ${c.category}: ${c.value}');
      buf.writeln('     ${c.reasonKo}');
    }
    // ignore: avoid_print
    print(buf.toString());
  });
}
