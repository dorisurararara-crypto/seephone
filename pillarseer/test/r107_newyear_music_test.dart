// R107 #6 + #7 — 신년운세 돈 문단 재성 분기 + 음악 처방 단정 제거 가드.
//
// #6 신년운세:
//   기존 _AnnualSummary 의 [6] 사람·관계·돈 문단과 _TwelveAreas 의 WEALTH
//   카드가 "정재보다 편재 성격의 한 해" 를 사용자 재성 구조와 무관하게 고정
//   삽입했다. R107 #6 은 ctx.tenGodFrequency 의 정재·편재 카운트로 5 분기
//   (jeong / pyeon / balanced / light / none).
//
// #7 음악 처방:
//   music_pharmacy_service 본문이 "100% 충전됩니다" 로 절대 단정했다.
//   R107 #7 은 조건형("채우는 데 도움이 돼요")으로 교체.
//
// 검증 축:
//   1) wealthShapeFromFreq 가 정재·편재 카운트별로 정확히 분기.
//   2) 5 shape 모두 서로 다른 돈 문단을 만든다.
//   3) 신년 총평 본문에 "정재보다 편재" 고정구가 없다 (KO/EN).
//   4) 음악 처방 KO/EN 본문에 "100%" / 절대 단정구가 0.
//   5) 음악 처방 본문에 조건형(도움 / can / tends) 이 있다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/new_year_2026_screen.dart';
import 'package:pillarseer/services/music_pharmacy_service.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R107 #6 — wealthShape 재성 분기', () {
    test('정재·편재 카운트별 분기 라벨이 정확하다', () {
      ({String expected, int j, int p}) c(String e, int j, int p) =>
          (expected: e, j: j, p: p);
      for (final tc in [
        c('none', 0, 0),
        c('light', 1, 0),
        c('light', 0, 1),
        c('jeong', 2, 1),
        c('jeong', 3, 0),
        c('pyeon', 1, 2),
        c('pyeon', 0, 3),
        c('balanced', 2, 2),
      ]) {
        final freq = <TenGod, int>{
          TenGod.jeongjae: tc.j,
          TenGod.pyeonjae: tc.p,
        };
        final shape = NewYear2026Screen.wealthShapeFromFreqForTest(freq);
        expect(shape, tc.expected, reason: 'j=${tc.j} p=${tc.p}');
      }
    });

    test('5 shape 모두 서로 다른 돈 문단을 만든다 (KO)', () {
      final texts = <String>{};
      for (final tc in [
        (j: 0, p: 0), // none
        (j: 1, p: 0), // light
        (j: 3, p: 1), // jeong
        (j: 1, p: 3), // pyeon
        (j: 2, p: 2), // balanced
      ]) {
        final ctx = _stubCtx(jeong: tc.j, pyeon: tc.p);
        texts.add(NewYear2026Screen.wealthFlowKoForTest(ctx));
      }
      expect(texts.length, 5, reason: '5 shape 모두 고유 문단이어야');
    });

    test('각 돈 문단에 "정재보다 편재" 고정구가 없다 (KO)', () {
      for (final tc in [
        (j: 0, p: 0),
        (j: 1, p: 0),
        (j: 3, p: 1),
        (j: 1, p: 3),
        (j: 2, p: 2),
      ]) {
        final ctx = _stubCtx(jeong: tc.j, pyeon: tc.p);
        final t = NewYear2026Screen.wealthFlowKoForTest(ctx);
        expect(t.contains('정재보다 편재'), isFalse, reason: t);
      }
    });
  });

  group('R107 #6 — 신년 총평 본문 회귀', () {
    test('재성 구조가 다른 두 사주 → 총평 본문이 달라진다 (KO)', () async {
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final b = await SajuService().calculateSaju(
        year: 1988, month: 6, day: 12,
        hour: 6, minute: 0,
        isLunar: false, isMale: false,
      );
      final ctxA = SajuContext.from(a, today: DateTime(2026, 1, 1));
      final ctxB = SajuContext.from(b, today: DateTime(2026, 1, 1));
      final shapeA = NewYear2026Screen.wealthShapeForTest(ctxA);
      final shapeB = NewYear2026Screen.wealthShapeForTest(ctxB);

      final summaryA =
          NewYear2026Screen.annualSummaryBodyForTest(saju: a, useKo: true);
      final summaryB =
          NewYear2026Screen.annualSummaryBodyForTest(saju: b, useKo: true);

      if (shapeA != shapeB) {
        expect(summaryA, isNot(equals(summaryB)),
            reason: 'shape 다름($shapeA/$shapeB)인데 총평 동일');
      }
      expect(summaryA.contains('정재보다 편재'), isFalse);
      expect(summaryB.contains('정재보다 편재'), isFalse);
      // 총평 본문은 비어 있지 않다 (회귀 가드).
      expect(summaryA.trim().length, greaterThan(800));
      expect(summaryB.trim().length, greaterThan(800));
    });

    test('영문 총평에 "more windfall than fixed" 고정구가 없다', () async {
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final en =
          NewYear2026Screen.annualSummaryBodyForTest(saju: a, useKo: false);
      expect(en.contains('more windfall than fixed'), isFalse);
      expect(en.toLowerCase().contains('money'), isTrue);
    });
  });

  group('R107 #7 — 음악 처방 단정 제거', () {
    late Map<String, dynamic> songs;
    late List<Map<String, dynamic>> celebs;

    setUpAll(() async {
      songs = json.decode(
        await File('assets/data/celeb_songs.json').readAsString(),
      ) as Map<String, dynamic>;
      celebs = (json.decode(
        await File('assets/data/celebrities.json').readAsString(),
      ) as List)
          .cast<Map<String, dynamic>>();
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(celebs: celebs, songs: songs);
    });

    tearDownAll(MusicPharmacyService.resetCacheForTest);

    test('KO/EN 본문에 "100%" 절대 단정구가 0 (전 5행 × 8 seed)', () {
      final cases = <(String, int, int, int, int, int)>[
        ('wood', 1, 5, 5, 5, 5),
        ('fire', 5, 1, 5, 5, 5),
        ('earth', 5, 5, 1, 5, 5),
        ('metal', 5, 5, 5, 1, 5),
        ('water', 5, 5, 5, 5, 1),
      ];
      for (final c in cases) {
        final (label, w, f, e, m, wa) = c;
        for (var seed = 1; seed <= 8; seed++) {
          final p = MusicPharmacyService.prescribeSync(
            user: _makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
            userName: '미나',
            seed: seed,
          );
          expect(p, isNotNull, reason: '$label seed=$seed null');
          final ko = p!.prescriptionText;
          final en = p.prescriptionTextEn;
          expect(ko.contains('100%'), isFalse,
              reason: '$label seed=$seed KO "100%" leak: $ko');
          expect(en.contains('100%'), isFalse,
              reason: '$label seed=$seed EN "100%" leak: $en');
          expect(ko.contains('충전됩니다'), isFalse,
              reason: '$label seed=$seed KO "충전됩니다" 단정 leak: $ko');
        }
      }
    });

    test('KO 본문에 조건형(도움)이 있다', () {
      final p = MusicPharmacyService.prescribeSync(
        user: _makeSaju(wood: 5, fire: 1, earth: 5, metal: 5, water: 5),
        userName: '미나',
        seed: 3,
      );
      expect(p, isNotNull);
      expect(p!.prescriptionText.contains('도움'), isTrue,
          reason: 'KO 조건형 없음: ${p.prescriptionText}');
    });

    test('EN 본문에 조건형(can / tends / might)이 있다', () {
      final p = MusicPharmacyService.prescribeSync(
        user: _makeSaju(wood: 5, fire: 1, earth: 5, metal: 5, water: 5),
        userName: 'Mina',
        seed: 3,
      );
      expect(p, isNotNull);
      final t = p!.prescriptionTextEn.toLowerCase();
      expect(t.contains('can ') || t.contains('tends') || t.contains('might'),
          isTrue,
          reason: 'EN 조건형 없음: ${p.prescriptionTextEn}');
    });
  });
}

/// element 분포만 제어하는 최소 SajuResult — music pharmacy 는 elements 만 본다.
SajuResult _makeSaju({
  required int wood,
  required int fire,
  required int earth,
  required int metal,
  required int water,
}) {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '癸', jiJi: '卯'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
    dayPillar: const Pillar(chunGan: '戊', jiJi: '寅'),
    hourPillar: const Pillar(chunGan: '己', jiJi: '未'),
    elements: FiveElements(
      wood: wood,
      fire: fire,
      earth: earth,
      metal: metal,
      water: water,
    ),
    dayMaster: '戊',
    dayMasterName: 'Test',
    summary: 'test',
    categoryReadings: const {},
  );
}

/// 정재·편재 카운트만 제어하는 SajuContext stub.
/// _AnnualSummary._wealthFlowKo / wealthShape 는 tenGodFrequency 만 본다.
SajuContext _stubCtx({required int jeong, required int pyeon}) {
  return SajuContext(
    dayMaster: '甲',
    dayElement: '木',
    dayYang: true,
    monthBranch: '寅',
    season: 'spring',
    wood: 20,
    fire: 20,
    earth: 20,
    metal: 20,
    water: 20,
    dominantElement: '木',
    deficitElement: '金',
    tenGodFrequency: <TenGod, int>{
      TenGod.jeongjae: jeong,
      TenGod.pyeonjae: pyeon,
    },
    strengthLabel: '중화',
    gyeokgukShort: '비전형',
    gyeokgukFull: '비전형 격국',
    yongsin: '火',
    huisin: '木',
    gisin: '水',
    activeShinsa: const <String>{},
    gongMangAreas: const [],
    currentDaewoon: null,
    currentDaewoonGod: null,
    todayPillar: null,
    todayGod: null,
    todayRelations: const [],
    chartSeed: 1,
    userAge: null,
  );
}
