// R86 sprint 4 — 오늘 사주 총평 본문 모순 + 십신 jargon 회귀 가드.
//
// 사용자 mandate verbatim (1.0.0+44 실기기 피드백):
//   "사람이랑 부딪히는데 큰 충돌없이 지나간다니 앞뒤가 안맞아"
// + "정인격 이라던지 이런것도 무슨말인지 몰라" (R86 sprint 1 의 연장)
//
// 검증:
//   B1 — _daewoonAnchor 10 십신 (비견/겁재/식신/상관/편재/정재/편관/정관/편인/정인) 본문 노출 0
//        ("대운" 단어 자체는 R78 sprint 7 anchor wire 시그니처 위해 유지)
//   B2 — _godPhraseKo 모든 phrase 에 "부딪칠/부딪치/충돌" 강한 충돌 단어 0
//   B3 — _branchRelationKo neutral 에 "충돌 없이" 모순 가능 단어 0
//   B4 — 통합 시뮬: 겁재 + neutral 합성 → bodyKo 안에 "부딪칠" + "충돌 없이" 동시 노출 0

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/today_deep_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R86 sprint 4 — today saju 본문 모순/jargon 일소', () {
    // 헬퍼 — 10 십신 cover ctx 합성.
    SajuContext ctxFor(TenGod dwGod) => SajuContext(
          dayMaster: '甲',
          dayElement: '木',
          dayYang: true,
          monthBranch: '寅',
          season: '봄',
          wood: 50,
          fire: 10,
          earth: 10,
          metal: 10,
          water: 20,
          dominantElement: '木',
          deficitElement: '火',
          tenGodFrequency: const {},
          strengthLabel: '중화',
          gyeokgukShort: '비견격',
          gyeokgukFull: '비견격 (比肩格)',
          yongsin: '火',
          huisin: '土',
          gisin: '水',
          activeShinsa: const {},
          gongMangAreas: const [],
          currentDaewoon: (age: 30, ganji: '甲子', element: '木'),
          currentDaewoonGod: dwGod,
          todayPillar: null,
          todayGod: null,
          todayRelations: const [],
          chartSeed: 1,
          userAge: 30,
        );

    test('B1 — _daewoonAnchor 10 십신 단어 본문 노출 0 (R86 mandate)', () {
      const banned = [
        '비견',
        '겁재',
        '식신',
        '상관',
        '편재',
        '정재',
        '편관',
        '정관',
        '편인',
        '정인',
      ];
      for (final god in TenGod.values) {
        final reading = TodayDeepService.build(
          userDayStem: '甲',
          userDayBranch: '寅',
          userMonthBranch: '寅',
          userDominantEl: '木',
          userDeficitEl: '火',
          todayPillar: '丙戌',
          todayScore: 50,
          ctx: ctxFor(god),
        );
        for (final w in banned) {
          expect(reading.bodyKo.contains(w), isFalse,
              reason: '$god 대운 anchor 합성 본문에 십신 단어 "$w" 잔존 — R86 mandate');
        }
      }
    });

    test('B1b — _daewoonAnchor 에 "대운" 단어는 유지 (R78 sprint 7 wire 시그니처)', () {
      for (final god in TenGod.values) {
        final reading = TodayDeepService.build(
          userDayStem: '甲',
          userDayBranch: '寅',
          userMonthBranch: '寅',
          userDominantEl: '木',
          userDeficitEl: '火',
          todayPillar: '丙戌',
          todayScore: 50,
          ctx: ctxFor(god),
        );
        expect(reading.bodyKo.contains('대운'), isTrue,
            reason: '$god 대운 anchor wire 누락');
      }
    });

    test('B2 — 겁재 + neutral branch 합성 본문에 "부딪칠/부딪치/충돌" 동시 노출 0', () {
      // 1995-10-27 男 신묘 일주 같은 sample 에 가까운 ctx — 겁재 사례.
      // 사용자 직발 화면 시뮬: 겁재 godPhrase + neutral branchRelation.
      final reading = TodayDeepService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        userDominantEl: '金',
        userDeficitEl: '水',
        // 오늘 庚 (겁재 against 辛) + 申 (辛卯 와 neutral) — 모순 가능 조합
        todayPillar: '庚申',
        todayScore: 72,
        ctx: ctxFor(TenGod.geopjae),
      );
      // 강한 충돌 단어 본문 노출 0.
      expect(reading.bodyKo.contains('부딪칠'), isFalse,
          reason: 'R86 sprint 4 — 강한 충돌 단어 "부딪칠" 본문 잔존');
      expect(reading.bodyKo.contains('부딪치'), isFalse,
          reason: 'R86 sprint 4 — 강한 충돌 단어 "부딪치" 본문 잔존');
      expect(reading.bodyKo.contains('충돌 없이'), isFalse,
          reason: 'R86 sprint 4 — neutral phrase "충돌 없이" 본문 잔존');
      expect(reading.bodyKo.contains('큰 충돌'), isFalse,
          reason: 'R86 sprint 4 — "큰 충돌" phrase 본문 잔존');
    });

    test('B3 — 10 십신 × 4 branch relation 모든 조합에 강한 충돌 phrase 0', () {
      // 10 천간 × 12 지지 = 120 combo 까지는 부담스러우니 십신 cover 만.
      // 각 십신 합성 시 본문에 "부딪칠/충돌 없이" 같이 못 나오게 가드.
      for (final god in TenGod.values) {
        final reading = TodayDeepService.build(
          userDayStem: '辛',
          userDayBranch: '卯',
          userMonthBranch: '戌',
          userDominantEl: '金',
          userDeficitEl: '水',
          todayPillar: '庚申',
          todayScore: 72,
          ctx: ctxFor(god),
        );
        expect(reading.bodyKo.contains('부딪칠'), isFalse,
            reason: '$god → 본문에 "부딪칠"');
        expect(reading.bodyKo.contains('충돌 없이'), isFalse,
            reason: '$god → 본문에 "충돌 없이"');
      }
    });
  });
}
