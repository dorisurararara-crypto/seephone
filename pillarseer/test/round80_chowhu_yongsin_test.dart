// Round 80 sprint 6 — 조후용신 (계절 보정) wire 회귀 가드.
//
// yongsin_service.judge() 가 monthBranch 받으면 chowhuYongsin getter 노출
// + reason 끝에 계절 보정 한 줄 추가. yongsin/huisin 자체는 backward compat.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/yongsin_service.dart';

void main() {
  group('Round 80 sprint 6 — 조후용신 wire', () {
    test('1995-10-27 男 신묘 (가을 戌월) — 조후 木 노출', () {
      final r = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16,
        fire: 21,
        earth: 17,
        metal: 41,
        water: 4,
        monthBranch: '戌',
      );
      expect(r.chowhuYongsin, '木');
      expect(r.reason, contains('가을'));
      expect(r.reason, contains('木'));
    });

    test('monthBranch 없이 호출 (backward compat) — chowhuYongsin null', () {
      final r = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16,
        fire: 21,
        earth: 17,
        metal: 41,
        water: 4,
      );
      expect(r.chowhuYongsin, isNull);
      expect(r.reason, isNot(contains('계절 조후')));
    });

    test('계절별 chowhuYongsin 매핑', () {
      // 봄 (寅) → 火.
      var r = YongsinService.judge(
        dayMasterElement: '木', strengthLabel: '중화',
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20,
        monthBranch: '寅',
      );
      expect(r.chowhuYongsin, '火');
      expect(r.reason, contains('봄'));

      // 여름 (午) → 水.
      r = YongsinService.judge(
        dayMasterElement: '火', strengthLabel: '중화',
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20,
        monthBranch: '午',
      );
      expect(r.chowhuYongsin, '水');
      expect(r.reason, contains('여름'));

      // 가을 (申) → 木.
      r = YongsinService.judge(
        dayMasterElement: '金', strengthLabel: '중화',
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20,
        monthBranch: '申',
      );
      expect(r.chowhuYongsin, '木');
      expect(r.reason, contains('가을'));

      // 겨울 (子) → 火.
      r = YongsinService.judge(
        dayMasterElement: '水', strengthLabel: '중화',
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20,
        monthBranch: '子',
      );
      expect(r.chowhuYongsin, '火');
      expect(r.reason, contains('겨울'));
    });

    test('yongsin 결과 자체는 monthBranch 유무 관계없이 동일 (회귀)', () {
      final without = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16, fire: 21, earth: 17, metal: 41, water: 4,
      );
      final withMonth = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16, fire: 21, earth: 17, metal: 41, water: 4,
        monthBranch: '戌',
      );
      expect(without.yongsin, withMonth.yongsin);
      expect(without.huisin, withMonth.huisin);
    });
  });
}
