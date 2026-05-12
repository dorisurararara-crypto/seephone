// 용신(用神) 회귀.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/yongsin_service.dart';

void main() {
  group('YongsinService 용신 도출', () {
    test('신강 사주 + 木 일간 + 木 가득 → 토/금/수 중 부족한 게 용신', () {
      final r = YongsinService.judge(
        dayMasterElement: '木',
        strengthLabel: '신강',
        wood: 40, fire: 20, earth: 10, metal: 15, water: 15,
      );
      // 木 일간 강. 식상=火(20), 재성=土(10), 관성=金(15).
      // 가장 적은 = 土 (10) — 용신
      expect(r.yongsin, '土');
      expect(r.reason, contains('신강'));
    });

    test('신약 사주 + 火 일간 → 木(인성) 또는 火(비겁)', () {
      final r = YongsinService.judge(
        dayMasterElement: '火',
        strengthLabel: '신약',
        wood: 10, fire: 10, earth: 20, metal: 30, water: 30,
      );
      // 火 일간 약. 인성=木(10), 비겁=火(10). 같으면 첫 번째 (인성).
      // sort stable — yongsin 木 또는 火
      expect(r.yongsin, anyOf(equals('木'), equals('火')));
      expect(r.reason, contains('신약'));
    });

    test('중화 사주 — 가장 약한 오행 용신', () {
      final r = YongsinService.judge(
        dayMasterElement: '土',
        strengthLabel: '중화',
        wood: 30, fire: 25, earth: 20, metal: 15, water: 10,
      );
      // 水(10) 가장 약 → 용신
      expect(r.yongsin, '水');
      expect(r.huisin, '金');
    });

    test('compensationGuide KO/EN 5행 모두 매핑', () {
      for (final el in ['木', '火', '土', '金', '水']) {
        expect(
          YongsinService.compensationGuide(el, ko: true),
          isNotEmpty,
        );
        expect(
          YongsinService.compensationGuide(el, ko: false),
          isNotEmpty,
        );
      }
    });

    test('yongsin/huisin 비어 있지 않음', () {
      final r = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신왕',
        wood: 10, fire: 25, earth: 20, metal: 30, water: 15,
      );
      expect(r.yongsin, isNotEmpty);
      expect(r.huisin, isNotEmpty);
      expect(r.yongsin, isNot(equals(r.huisin)));
    });
  });
}
