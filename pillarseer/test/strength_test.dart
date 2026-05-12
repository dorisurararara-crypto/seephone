// 신왕/신약 회귀 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/strength_service.dart';

void main() {
  group('StrengthService 신강/신약 판단', () {
    test('일간 木 + 木火 가득 + 寅월 → 신강 (월령 통근)', () {
      final r = StrengthService.judge(
        dayMasterElement: '木',
        monthJi: '寅', // 木 통근
        wood: 40,
        fire: 20,
        earth: 10,
        metal: 10,
        water: 20,
      );
      // 강도 = 木(40) + 水(20) = 60, 월령 통근으로 ×1.5 → 90 → 100 clamp.
      // label = 신강 (score >= 70)
      expect(r.label, '신강');
      expect(r.labelEn, 'Very Strong');
    });

    test('일간 火 + 金水 가득 → 신약', () {
      // 약도: 火 일간 + 木 인성 vs 金水 (재성+관성 비율 ↑)
      // 寅(木) 월령은 木인데 일간 火 의 인성 = 木 → 통근 (강도 boost)
      // Avoid that — 子(水) 월령으로 신약.
      final r = StrengthService.judge(
        dayMasterElement: '火',
        monthJi: '子', // 水 — 火 일간의 인성도 아니고 자기도 아님
        wood: 5,
        fire: 5,
        earth: 10,
        metal: 30,
        water: 50,
      );
      // 강도 = 火(5) + 木(5) = 10. 통근 없음.
      // → 신쇠 (score < 30)
      expect(r.label, anyOf(equals('신쇠'), equals('신약')));
    });

    test('중화 — 5행 균형', () {
      final r = StrengthService.judge(
        dayMasterElement: '土',
        monthJi: '寅', // 木 — 土 일간의 통근 아님
        wood: 20,
        fire: 20,
        earth: 20,
        metal: 20,
        water: 20,
      );
      // 강도 = 土(20) + 火(20) = 40. 통근 없음.
      // → 신약 or 중화 (boundary)
      expect(r.label, anyOf(equals('중화'), equals('신약')));
    });

    test('월령 통근 시 강도 boost — 일간 水 + 子월', () {
      final r = StrengthService.judge(
        dayMasterElement: '水',
        monthJi: '子', // 水 통근
        wood: 20,
        fire: 10,
        earth: 20,
        metal: 20,
        water: 30,
      );
      // 강도 = 水(30) + 金(20) = 50, ×1.5 = 75 → 신강.
      expect(r.label, '신강');
    });

    test('guide 메시지 KO/EN 모두 비어있지 않음', () {
      for (final lbl in ['신강', '신왕', '중화', '신약', '신쇠']) {
        expect(StrengthService.guide(lbl, ko: true), isNotEmpty);
        expect(StrengthService.guide(lbl, ko: false), isNotEmpty);
      }
    });

    test('score 항상 0~100 범위', () {
      final r = StrengthService.judge(
        dayMasterElement: '木',
        monthJi: '寅',
        wood: 100,
        fire: 0,
        earth: 0,
        metal: 0,
        water: 0,
      );
      expect(r.score, greaterThanOrEqualTo(0));
      expect(r.score, lessThanOrEqualTo(100));
    });
  });
}
