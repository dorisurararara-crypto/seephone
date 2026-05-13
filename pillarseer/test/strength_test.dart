// 신왕/신약 회귀 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/strength_service.dart';

void main() {
  group('StrengthService 신강/신약 판단', () {
    test('일간 甲(木) + 寅월 + 사주 木 다수 통근 → 신강', () {
      // 신모델: element % 는 이미 지장간 비율 + 월령 ×2.5 반영된 값으로 입력.
      // 추가로 일간 천간 + 4지지 제공하면 일간 통근 점수 가산.
      final r = StrengthService.judge(
        dayMasterElement: '木',
        monthJi: '寅', // 木 본기
        wood: 40, fire: 20, earth: 10, metal: 10, water: 20,
        dayMaster: '甲', // 일간 天干
        yearJi: '寅', // 甲 본기 → +6
        dayJi: '卯',  // 乙(木) 본기 → 甲의 木 같음 +6
        hourJi: '辰', // 乙 중기 → +3 (木 통근)
      );
      // base = 木(40) + 水(20) = 60
      // root bonus = year寅 6 + month寅 6×1.5=9 + day卯 6 + hour辰 3 = 24 → clamp 20
      // total 60+20 = 80 → 신강
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

    test('일간 壬(水) + 子월 + 申子 水 통근 → 신강', () {
      // 신모델: 일간 통근 점수로 신강 달성.
      final r = StrengthService.judge(
        dayMasterElement: '水',
        monthJi: '子', // 癸(水) 본기
        wood: 20, fire: 10, earth: 20, metal: 20, water: 30,
        dayMaster: '壬', // 일간 天干 (水)
        yearJi: '申', // 壬 중기(水) → +3
        dayJi: '子',  // 癸 본기(水) → +6
        hourJi: '亥', // 壬 본기(水) → +6
      );
      // base = 水(30) + 金(20) = 50
      // root bonus = year申 3 + month子 6×1.5=9 + day子 6 + hour亥 6 = 24 → clamp 20
      // total 50+20 = 70 → 신강 (≥70)
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
