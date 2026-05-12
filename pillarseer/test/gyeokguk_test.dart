// 격국 회귀.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/gyeokguk_service.dart';

void main() {
  group('GyeokgukService.judge', () {
    test('甲 일간 + 子월 (子의 본기 癸 = 정인) → 정인격', () {
      final r = GyeokgukService.judge(dayMaster: '甲', monthJi: '子');
      expect(r.name, contains('정인격'));
    });

    test('甲 일간 + 寅월 (子의 본기 甲 = 비견) → 건록격', () {
      final r = GyeokgukService.judge(dayMaster: '甲', monthJi: '寅');
      expect(r.name, contains('건록격'));
    });

    test('丙 일간 + 子월 (癸 = 정관) → 정관격', () {
      // 丙 火, 癸 水, 화 ↔ 수: 수가 화를 극 → 음양 다름 → 정관
      final r = GyeokgukService.judge(dayMaster: '丙', monthJi: '子');
      expect(r.name, contains('정관격'));
    });

    test('丙 일간 + 申월 (庚 = 편재) → 편재격', () {
      // 丙 火, 庚 金. 화가 금을 극 → 음양 같음 (양양) → 편재
      final r = GyeokgukService.judge(dayMaster: '丙', monthJi: '申');
      expect(r.name, contains('편재격'));
    });

    test('description 비어있지 않음', () {
      final r = GyeokgukService.judge(dayMaster: '甲', monthJi: '寅');
      expect(r.desc, isNotEmpty);
      expect(r.descEn, isNotEmpty);
    });
  });
}
