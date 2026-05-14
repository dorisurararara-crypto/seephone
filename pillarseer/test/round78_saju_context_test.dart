// Round 78 sprint 1 — SajuContext 회귀 가드.
//
// 1995-10-27 男 골든 사주 입력 시 SajuContext 가 핵심 field (5행 / 격국 / 용신 /
// 신살 / 신강신약 / 십신 freq) 를 올바르게 합성한다.
// 5행 16/21/17/41/4 mandate 보존.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SajuContext — Round 78 sprint 1', () {
    test('1995-10-27 男 신묘 — 5행 16/21/17/41/4 보존 + 일간 辛(金)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      // 5행 골든 — Round 75 calibration 결과 (16/21/17/41/4).
      expect(ctx.wood, 16);
      expect(ctx.fire, 21);
      expect(ctx.earth, 17);
      expect(ctx.metal, 41);
      expect(ctx.water, 4);

      // 일간 辛 → 금 / 음.
      expect(ctx.dayMaster, '辛');
      expect(ctx.dayElement, '金');
      expect(ctx.dayYang, isFalse);

      // 월지 戌 → 가을.
      expect(ctx.monthBranch, '戌');
      expect(ctx.season, '가을');

      // dominant 金, deficit 水 (4%).
      expect(ctx.dominantElement, '金');
      expect(ctx.deficitElement, '水');
    });

    test('1995-10-27 男 — 격국·용신·기신·신살·대운 합성 (모두 비어있지 않음)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      // 격국 short — body 본문 노출용. 한자 '(' 본문 누출 X 가드.
      expect(ctx.gyeokgukShort.isNotEmpty, isTrue);
      expect(ctx.gyeokgukShort.contains('('), isFalse,
          reason: 'gyeokgukShort 에 본문 한자/괄호 누출 — body 가드 위반: ${ctx.gyeokgukShort}');
      // gyeokgukFull 은 jargon 라벨 dictionary — 한자 포함 OK.
      expect(ctx.gyeokgukFull.contains('('), isTrue);

      // 용신·희신·기신 모두 5행 1글자.
      const els = {'木', '火', '土', '金', '水'};
      expect(els.contains(ctx.yongsin), isTrue, reason: 'yongsin: ${ctx.yongsin}');
      expect(els.contains(ctx.huisin), isTrue);
      expect(els.contains(ctx.gisin), isTrue, reason: 'gisin: ${ctx.gisin}');
      // 기신 != 용신 (overcome 관계 강제).
      expect(ctx.gisin == ctx.yongsin, isFalse);

      // 신강/신약 라벨 5종 중 1개.
      expect(['신강', '신왕', '중화', '신약', '신쇠'].contains(ctx.strengthLabel),
          isTrue);

      // 신살 set 은 가능 list 의 subset.
      // 1995-10-27 男 (辛卯 일주) — 일지 卯 samhap '亥卯未'(木) → 역마=巳/도화=子/화개=未
      // 4기둥 (乙亥/丙戌/辛卯/丙申) 와 매칭되는 신살 없음 → activeShinsa 빈 set 정상.
      // 신살 합성 _경로_ 가 동작하는지를 가드하기 위해 다른 케이스로 비어있지 않음 확인.
      const allShinsa = {
        '역마', '도화', '화개', '천을귀인', '문창귀인', '양인', '괴강', '백호'
      };
      for (final s in ctx.activeShinsa) {
        expect(allShinsa.contains(s), isTrue, reason: 'unknown shinsa: $s');
      }

      // 현재 대운 합성 — userAge null 이면 currentDaewoon null OK.
      // userAge 입력 케이스 별도 test 에서 가드.
    });

    test('신살 합성 경로 — 1998-06-15 男 (癸巳 일주) → 도화·천을귀인 활성', () async {
      // 癸 일간 cheonEulGwiIn = [卯, 巳] — 일지 巳 매칭.
      // 일지 巳 samhap 巳酉丑(金) → 도화=午 — 월지 午 / 시지 午 매칭.
      // ⇒ activeShinsa 가 {도화, 천을귀인} 포함 → 합성 path 가드.
      final saju = await SajuService().calculateSaju(
        year: 1998, month: 6, day: 15,
        hour: 12, minute: 0,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju);
      expect(ctx.activeShinsa.isNotEmpty, isTrue,
          reason: '신살 합성 경로 — activeShinsa 빈 set 이면 합성 누락');
      expect(ctx.activeShinsa.contains('도화'), isTrue,
          reason: '도화 활성 필수 — 일지 巳 → 도화=午 매칭');
      expect(ctx.activeShinsa.contains('천을귀인'), isTrue,
          reason: '천을귀인 활성 필수 — 癸 일간 cheonEul=[卯,巳] + 일지 巳 매칭');
    });

    test('userAge 자동 산출 (SajuService) → currentDaewoon + currentDaewoonGod 합성', () async {
      // SajuService 가 today 기반 만 나이 (clamp 1..120) 를 자동 산출 →
      // SajuContext 는 그 userAge 위에 DaewoonService.chain + currentChunk 합성.
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      expect(ctx.userAge, isNotNull,
          reason: 'SajuService 가 today 기반 자동 userAge 산출');
      expect(ctx.userAge!, greaterThanOrEqualTo(20));
      expect(ctx.userAge!, lessThanOrEqualTo(40));

      // currentDaewoon 합성됨 — chain 미도달 사용자는 null fallback.
      // 30대 사용자는 보통 2-3 대운 chunk 보유.
      expect(ctx.currentDaewoon, isNotNull,
          reason: '30대 사용자 — 대운 chunk 진입 후');
      expect(ctx.currentDaewoon!.ganji.length, 2);
      expect(['木', '火', '土', '金', '水']
          .contains(ctx.currentDaewoon!.element), isTrue);

      // currentDaewoonGod 십신 enum.
      expect(ctx.currentDaewoonGod, isNotNull);
    });

    test('1995-10-27 男 — 십신 freq + today 일진 + chartSeed', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      // 십신 freq sum ≥ 4 (4기둥 x 2 = 최대 8, but 일간 자기자리 제외 등 변동).
      final total = ctx.tenGodFrequency.values.fold<int>(0, (a, b) => a + b);
      expect(total, greaterThanOrEqualTo(4));

      // 오늘 일진 ganji (2026-05-14) — saju_service 동일 식 (1900-01-01 = 甲戌, idx 10)
      // 2026-05-14 = 戊子 (Julian Day diff 46154 → idx 24).
      expect(ctx.todayPillar, '戊子',
          reason: '2026-05-14 일진 ganji 기대=戊子, 실제=${ctx.todayPillar}');

      // todayGod 은 일간 辛 기준 — 戊(土) → 辛(金) = 인성 (생아). 정인.
      expect(ctx.todayGod, isNotNull);

      // chartSeed deterministic — 같은 입력 → 같은 seed.
      final ctx2 = SajuContext.from(saju, today: DateTime(2026, 5, 14));
      expect(ctx2.chartSeed, ctx.chartSeed);
    });

    test('서로 다른 일간 (金 vs 木) → ctx field 차이 ≥3 + 일간 명시 가드', () async {
      // A: 1995-10-27 男 — 일간 辛 (金).
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // B: 1996-04-15 男 — 봄 출생 (寅卯辰 월령). 일간이 木 또는 수 인지 명시 가드.
      final b = await SajuService().calculateSaju(
        year: 1996, month: 4, day: 15,
        hour: 9, minute: 0,
        isLunar: false, isMale: true,
      );
      final ca = SajuContext.from(a, today: DateTime(2026, 5, 14));
      final cb = SajuContext.from(b, today: DateTime(2026, 5, 14));

      // A 는 確 金 일간 (golden).
      expect(ca.dayElement, '金');
      // B 는 A 와 다른 5행 일간 (목/화/토/수 중 1).
      expect(ca.dayElement == cb.dayElement, isFalse,
          reason: 'A=${ca.dayElement} vs B=${cb.dayElement} 동일하면 분기 입력 부족');

      int diffs = 0;
      if (ca.dayMaster != cb.dayMaster) diffs++;
      if (ca.dayElement != cb.dayElement) diffs++;
      if (ca.dominantElement != cb.dominantElement) diffs++;
      if (ca.season != cb.season) diffs++;
      if (ca.gyeokgukShort != cb.gyeokgukShort) diffs++;
      if (ca.yongsin != cb.yongsin) diffs++;
      if (ca.strengthLabel != cb.strengthLabel) diffs++;
      if (ca.chartSeed != cb.chartSeed) diffs++;

      expect(diffs, greaterThanOrEqualTo(3),
          reason: '두 다른 사주 ctx field 차이 ≥3 — 실제 $diffs');
    });

    test('today 미공급 → todayPillar/todayGod null, chartSeed deterministic (2회 호출 동일)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx1 = SajuContext.from(saju);
      final ctx2 = SajuContext.from(saju);

      expect(ctx1.todayPillar, isNull);
      expect(ctx1.todayGod, isNull);
      expect(ctx1.todayRelations, isEmpty);

      // today 미공급 시에도 seed deterministic — 2회 호출 동일.
      expect(ctx1.chartSeed, ctx2.chartSeed);
      expect(ctx1.chartSeed, greaterThan(0));
    });

    test('todayRelations 범위는 명시적 (천간합/지지합/지지충 3종) — 형/파/해 미포함', () async {
      // SajuContext 의 todayRelations 는 HapchungService 의 합/충 단일 pair 만 wire.
      // 형(刑)/파(破)/해(害) 는 신살 service 위임 (별 sprint) — 본 ctx 단계에서 명시.
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));
      const allowed = {'천간합', '지지합', '지지충'};
      for (final r in ctx.todayRelations) {
        expect(allowed.contains(r), isTrue, reason: 'unknown relation: $r');
      }
    });
  });
}
