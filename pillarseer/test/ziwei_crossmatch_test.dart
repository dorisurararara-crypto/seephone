// crossmatch 통합 테스트 — 1995-10-27 15:43 남자.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';
import 'package:pillarseer/services/ziwei_crossmatch_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('1995-10-27 15:43 남자 — 사주↔자미두수 교차 일치 print', () async {
    final svc = SajuService();
    final saju = await svc.calculateSaju(
      year: 1995,
      month: 10,
      day: 27,
      hour: 15,
      minute: 43,
      isLunar: false,
      isMale: true,
    );
    final ziwei = ZiweiService.calculate(
      year: 1995,
      month: 10,
      day: 27,
      hour: 15,
      minute: 43,
      isMale: true,
    );
    print('=== 사주 ↔ 자미두수 교차 일치 (1995-10-27 15:43 남) ===');
    print('사주: ${saju.pillarsText}  / 일주 = ${saju.dayPillar.pairKorean}');
    print('  5행 dominant: ${saju.elements.dominant}  deficit: ${saju.elements.deficit}');
    print('자미두수: 명궁 ${ziwei.mingPalace.headerKo}  /  신궁 ${ziwei.shenPalace.headerKo}');
    print('  명궁 주성: ${ziwei.mingPalace.majorStars.map((s) => s.nameKo).toList()}');
    print('  명궁 길성: ${ziwei.mingPalace.luckyStars}');
    final hits = ZiweiCrossmatchService.find(saju, ziwei);
    print('=== 공통 결론 ${hits.length} 개 ===');
    for (final cm in hits) {
      print('• [${cm.topic}] ${cm.combinedKo}');
      print('   사주: ${cm.sajuSide}');
      print('   자미: ${cm.ziweiSide}');
    }
    expect(hits.length, greaterThanOrEqualTo(3));
  });
}
