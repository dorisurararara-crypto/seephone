// Pillar Seer placeholder test. Real widget/integration tests TBD.
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  group('SajuService', () {
    final service = SajuService();

    test('60갑자 인덱스 → Pillar 변환', () {
      // 인덱스 0 = 甲子, 17 = 辛巳, 59 = 癸亥
      expect(service.pillarFromIndex(0).text, '甲子');
      expect(service.pillarFromIndex(17).text, '辛巳');
      expect(service.pillarFromIndex(59).text, '癸亥');
      // mod 60 wrap
      expect(service.pillarFromIndex(60).text, '甲子');
    });

    test('1996-04-15 14:30 사주 계산', () async {
      final result = await service.calculateSaju(
        year: 1996, month: 4, day: 15, hour: 14, minute: 30,
        isLunar: false, isMale: true,
      );
      expect(result.dayPillar.text.length, 2);
      // 5행 백분율 합은 반올림 오차로 100±3 허용
      final sum = result.elements.wood + result.elements.fire +
             result.elements.earth + result.elements.metal +
             result.elements.water;
      expect(sum, greaterThanOrEqualTo(97));
      expect(sum, lessThanOrEqualTo(103));
    });
  });
}
