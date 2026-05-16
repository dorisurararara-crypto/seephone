// Round 78 sprint 7 — 대운 단계 + 신년 12달 격국·용신 derive (V3 + V6 + H7).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/new_year_2026_screen.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/today_deep_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('today_deep daewoon anchor — Round 78 sprint 7 V3', () {
    test('ctx.currentDaewoonGod 보유 시 body 에 대운 십신 anchor 합성', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));
      expect(ctx.currentDaewoonGod, isNotNull,
          reason: '1995-10-27 男 — userAge ~30 → 대운 진입 후');
      final reading = TodayDeepService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        userDominantEl: saju.elements.dominant,
        userDeficitEl: saju.elements.deficit,
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ctx,
      );
      // bodyKo 에 "대운" 단어 포함 (한국어 anchor).
      expect(reading.bodyKo.contains('대운'), isTrue,
          reason: '대운 anchor 한국어 wire');
      expect(reading.bodyEn.contains('cycle'), isTrue,
          reason: '대운 anchor 영어 wire');
    });

    test('두 다른 대운 십신 ctx → body 차이 (hard guard)', () {
      // 직접 SajuContext fixture — 두 ctx 가 currentDaewoonGod 가 다른 케이스 강제.
      final ctxA = SajuContext(
        dayMaster: '甲', dayElement: '木', dayYang: true,
        monthBranch: '寅', season: '봄',
        wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
        dominantElement: '木', deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '비견격',
        gyeokgukFull: '비견격 (比肩格)',
        yongsin: '火', huisin: '土', gisin: '水',
        activeShinsa: const {},
        gongMangAreas: const [],
        currentDaewoon: (age: 30, ganji: '丁卯', element: '火'),
        currentDaewoonGod: TenGod.sanggwan, // 상관 대운
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: 30,
      );
      final ctxB = SajuContext(
        dayMaster: '甲', dayElement: '木', dayYang: true,
        monthBranch: '寅', season: '봄',
        wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
        dominantElement: '木', deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '비견격',
        gyeokgukFull: '비견격 (比肩格)',
        yongsin: '火', huisin: '土', gisin: '水',
        activeShinsa: const {},
        gongMangAreas: const [],
        currentDaewoon: (age: 70, ganji: '辛酉', element: '金'),
        currentDaewoonGod: TenGod.jeonggwan, // 정관 대운
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: 70,
      );
      // 두 ctx 대운 십신 다름 강제 단정.
      expect(ctxA.currentDaewoonGod != ctxB.currentDaewoonGod, isTrue);

      final readingA = TodayDeepService.build(
        userDayStem: '甲', userDayBranch: '寅', userMonthBranch: '寅',
        userDominantEl: '木', userDeficitEl: '水',
        todayPillar: '丙戌', todayScore: 50,
        ctx: ctxA,
      );
      final readingB = TodayDeepService.build(
        userDayStem: '甲', userDayBranch: '寅', userMonthBranch: '寅',
        userDominantEl: '木', userDeficitEl: '水',
        todayPillar: '丙戌', todayScore: 50,
        ctx: ctxB,
      );
      expect(readingA.bodyKo != readingB.bodyKo, isTrue,
          reason:
              'A (${ctxA.currentDaewoonGod!.ko}) vs B (${ctxB.currentDaewoonGod!.ko}) → 본문 차이 필수');
    });

    test('ctx.currentDaewoon null 시 대운 anchor 빈 (guard 가드)', () {
      // currentDaewoon null + currentDaewoonGod null → anchor X.
      final ctx = SajuContext(
        dayMaster: '甲', dayElement: '木', dayYang: true,
        monthBranch: '寅', season: '봄',
        wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
        dominantElement: '木', deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '비견격',
        gyeokgukFull: '비견격 (比肩格)',
        yongsin: '火', huisin: '土', gisin: '水',
        activeShinsa: const {},
        gongMangAreas: const [],
        currentDaewoon: null,
        currentDaewoonGod: null,
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: null,
      );
      final reading = TodayDeepService.build(
        userDayStem: '甲', userDayBranch: '寅', userMonthBranch: '寅',
        userDominantEl: '木', userDeficitEl: '水',
        todayPillar: '丙戌', todayScore: 50,
        ctx: ctx,
      );
      expect(reading.bodyKo.contains('대운'), isFalse);
      expect(reading.bodyEn.contains('cycle'), isFalse);
    });

    test('대운 anchor 10 십신 모두 ko/en non-empty', () {
      // 직접 SajuContext 합성으로 10 십신 cover.
      for (final god in TenGod.values) {
        final ctx = SajuContext(
          dayMaster: '甲', dayElement: '木', dayYang: true,
          monthBranch: '寅', season: '봄',
          wood: 50, fire: 10, earth: 10, metal: 10, water: 20,
          dominantElement: '木', deficitElement: '火',
          tenGodFrequency: const {},
          strengthLabel: '중화',
          gyeokgukShort: '비견격',
          gyeokgukFull: '비견격 (比肩格)',
          yongsin: '火', huisin: '土', gisin: '水',
          activeShinsa: const {},
          gongMangAreas: const [],
          currentDaewoon: (age: 30, ganji: '甲子', element: '木'),
          currentDaewoonGod: god,
          todayPillar: null, todayGod: null, todayRelations: const [],
          chartSeed: 1, userAge: 30,
        );
        final reading = TodayDeepService.build(
          userDayStem: '甲', userDayBranch: '寅', userMonthBranch: '寅',
          userDominantEl: '木', userDeficitEl: '火',
          todayPillar: '丙戌', todayScore: 50,
          ctx: ctx,
        );
        expect(reading.bodyKo.contains('대운'), isTrue,
            reason: '$god 대운 anchor ko');
        expect(reading.bodyEn.contains('cycle'), isTrue,
            reason: '$god 대운 anchor en');
      }
    });
  });

  group('new_year_2026 격국 derive — Round 78 sprint 7 V6 + H7', () {
    test('new_year_2026_screen 코드에 격국 anchor + 용신 suffix wire', () {
      final src = File('lib/screens/reports/new_year_2026_screen.dart')
          .readAsStringSync();
      expect(src.contains('DynamicTextResolver.gyeokgukAnchor'), isTrue);
      expect(src.contains('DynamicTextResolver.yongsinSuffix'), isTrue);
      expect(src.contains('SajuContext.from'), isTrue);
    });

    test('NewYear2026Screen.moodFor — 같은 절기 + 다른 격국 ctx → 본문 다름', () {
      // 두 ctx 격국 다름 (정관격 vs 식신격) + 동일 용신 (火) → mood 본문 차이.
      final ctxA = SajuContext(
        dayMaster: '甲', dayElement: '木', dayYang: true,
        monthBranch: '寅', season: '봄',
        wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
        dominantElement: '木', deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '정관격',
        gyeokgukFull: '정관격 (正官格)',
        yongsin: '火', huisin: '土', gisin: '水',
        activeShinsa: const {}, gongMangAreas: const [],
        currentDaewoon: null, currentDaewoonGod: null,
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: null,
      );
      final ctxB = SajuContext(
        dayMaster: '甲', dayElement: '木', dayYang: true,
        monthBranch: '寅', season: '봄',
        wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
        dominantElement: '木', deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '식신격',
        gyeokgukFull: '식신격 (食神格)',
        yongsin: '火', huisin: '土', gisin: '水',
        activeShinsa: const {}, gongMangAreas: const [],
        currentDaewoon: null, currentDaewoonGod: null,
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: null,
      );
      // 입춘 (index 1).
      final moodA = NewYear2026Screen.moodFor(ctx: ctxA, index: 1, useKo: true);
      final moodB = NewYear2026Screen.moodFor(ctx: ctxB, index: 1, useKo: true);
      expect(moodA != moodB, isTrue,
          reason: '같은 입춘 라벨 + 다른 격국 (정관 vs 식신) → 본문 차이');
      // R86 — 사용자 mandate: 격국 jargon ("정관격" / "식신격") 본문 노출 0.
      // 격국별 변별력은 anchor phrase 차이로 유지 (위 != 검증으로 충분).
      expect(moodA.contains('정관격'), isFalse,
          reason: 'R86 — 격국 jargon 본문 노출 0');
      expect(moodB.contains('식신격'), isFalse,
          reason: 'R86 — 격국 jargon 본문 노출 0');
    });

    test('NewYear2026Screen.moodFor — 영문 locale + em dash leak 0 (suffix 한정)', () {
      final ctx = SajuContext(
        dayMaster: '甲', dayElement: '木', dayYang: true,
        monthBranch: '寅', season: '봄',
        wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
        dominantElement: '木', deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '정관격',
        gyeokgukFull: '정관격 (正官格)',
        yongsin: '火', huisin: '土', gisin: '水',
        activeShinsa: const {}, gongMangAreas: const [],
        currentDaewoon: null, currentDaewoonGod: null,
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: null,
      );
      // 12 절기 cover.
      for (int i = 0; i < 12; i++) {
        final mood = NewYear2026Screen.moodFor(ctx: ctx, index: i, useKo: false);
        // 영문 base entries 는 em dash 보유 (기존 절기 라벨, 회귀 가드) — 검증 X.
        // 신규 anchor/suffix 부분 (마지막 줄) 만 em dash 0 가드.
        final lines = mood.split('\n');
        if (lines.length >= 2) {
          final suffix = lines.last;
          // 영문 격국 anchor + 용신 suffix 본문에 em dash 0.
          expect(suffix.contains('—'), isFalse,
              reason: 'index $i en suffix em dash leak: "$suffix"');
        }
      }
    });
  });

  group('대운 anchor 톤 가드 — restDay 금칙어', () {
    test('대운 anchor 본문 폐기 phrase 0', () {
      // 본 검증은 _daewoonAnchor private 이므로 source grep.
      final src = File('lib/services/today_deep_service.dart').readAsStringSync();
      const forbidden = ['본인의 결', '센터처럼', '리텐션', '퍼포먼스'];
      for (final w in forbidden) {
        // anchor map 영역만 검사 — _daewoonAnchor 함수 ~ map 정의 끝까지.
        final start = src.indexOf('_daewoonAnchor');
        final end = src.indexOf('_elementOfStem');
        if (start >= 0 && end > start) {
          final part = src.substring(start, end);
          expect(part.contains(w), isFalse,
              reason: 'daewoon anchor map 본문에 금칙 "$w" leak');
        }
      }
    });
  });
}
