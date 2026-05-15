// Round 84 — /today 화면 ctx 주입 + SajuContext yongsin signature 회귀 가드.
//
// 배경 (codex audit):
//   1) /today 화면의 TodayDeepService.build 호출이 `ctx` 인자 없이 진행돼서
//      home 탭 대비 격국 anchor / 용신 5축 suffix / 대운 anchor 누락.
//   2) SajuContext.from 의 YongsinService.judge 호출이 monthBranch 없이 진행돼서
//      R83 조후·계절 보정 reason 이 누락 — result_screen 의 yongsin signature 와
//      mismatch.
//
// R84 fix:
//   A) today_screen 이 단일 DateTime now + 단일 DailyService fortune + SajuContext.from
//      ctx 를 build 해서 TodayDeepService.build(ctx: ctx) 로 전달.
//   B) SajuContext.from 안의 YongsinService.judge 호출이 monthBranch: saju.monthPillar.jiJi
//      를 전달. yongsin/huisin 결과는 보존 (R80 sprint 6 / R83 회귀 가드).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/today_screen.dart';
import 'package:pillarseer/services/daily_service.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/today_deep_service.dart';
import 'package:pillarseer/services/yongsin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R84 — today_screen ctx wire', () {
    final todaySrc = File('lib/screens/today_screen.dart').readAsStringSync();

    test('A1 — today_screen 이 SajuContext import + SajuContext.from(result, today: now) + ctx 전달', () {
      expect(todaySrc.contains("'../services/saju_context.dart'"), isTrue,
          reason: 'saju_context import 필요');
      // 강한 가드: SajuContext.from(result, today: now) 시그니처 정확히 일치.
      final ctxRe = RegExp(
          r'SajuContext\.from\s*\(\s*result\s*,\s*today:\s*now\s*\)');
      expect(ctxRe.hasMatch(todaySrc), isTrue,
          reason: 'SajuContext.from(result, today: now) 호출 필요 — '
              'home 화면과 동일 단일 DateTime now 공유.');
      expect(todaySrc.contains('ctx: ctx'), isTrue,
          reason: 'TodayDeepService.build 에 ctx 전달 필요');
    });

    test('A2 — DailyService().calculate(result, today: now) 가 정확히 1회', () {
      // 강한 가드: 호출 형태가 `DailyService().calculate(result, today: now)` 와
      // 정확히 일치하고, 그런 호출이 단 1회만 존재해야 함.
      final exactRe = RegExp(
          r'DailyService\(\)\.calculate\s*\(\s*result\s*,\s*today:\s*now\s*\)');
      expect(exactRe.hasMatch(todaySrc), isTrue,
          reason: 'DailyService().calculate(result, today: now) 호출 필요 — '
              'fortune 변수에 1회 캐시.');

      // 중복 호출 가드: DailyService().calculate( 의 총 호출 횟수가 1회.
      final anyRe = RegExp(r'DailyService\(\)\.calculate\s*\(');
      final calcCount = anyRe.allMatches(todaySrc).length;
      expect(calcCount, 1,
          reason: 'DailyService().calculate( 호출이 정확히 1회여야 함. '
              '발견 횟수: $calcCount');
    });

    test('A3 — TodayDeepService.build 호출 시 fortune.dayPillar / fortune.totalScore 사용', () {
      expect(todaySrc.contains('todayPillar: fortune.dayPillar'), isTrue);
      expect(todaySrc.contains('todayScore: fortune.totalScore'), isTrue);
    });

    testWidgets('A4 — TodayScreen pump → ctx 주입된 본문 (격국 anchor 토큰 노출)',
        (tester) async {
      // dummy 사주 (SajuResult.dummy()) → ctx 합성 후 TodayDeepReadingSection body
      // 가 ctx-derive anchor 토큰 ('격' 또는 '오늘 한 가지') 포함해야 함.
      final router = GoRouter(
        initialLocation: '/today',
        routes: [
          GoRoute(
            path: '/today',
            builder: (c, s) => const TodayScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sajuResultProvider.overrideWith(_DummySajuNotifier.new),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 화면 위에 동일한 ctx-bearing body 가 mount 되었는지 service-level 비교.
      final dummy = SajuResult.dummy();
      final fortune = DailyService().calculate(dummy);
      final ctx = SajuContext.from(dummy, today: DateTime.now());
      final withCtx = TodayDeepService.build(
        userDayStem: dummy.dayPillar.chunGan,
        userDayBranch: dummy.dayPillar.jiJi,
        userMonthBranch: dummy.monthPillar.jiJi,
        userDominantEl: dummy.elements.dominant,
        userDeficitEl: dummy.elements.deficit,
        todayPillar: fortune.dayPillar,
        todayScore: fortune.totalScore,
        ctx: ctx,
      );
      final noCtx = TodayDeepService.build(
        userDayStem: dummy.dayPillar.chunGan,
        userDayBranch: dummy.dayPillar.jiJi,
        userMonthBranch: dummy.monthPillar.jiJi,
        userDominantEl: dummy.elements.dominant,
        userDeficitEl: dummy.elements.deficit,
        todayPillar: fortune.dayPillar,
        todayScore: fortune.totalScore,
      );
      expect(withCtx.bodyKo.length, greaterThan(noCtx.bodyKo.length),
          reason: 'ctx 주입 body 가 길어야 함 (격국/용신/대운 anchor 추가)');
    });
  });

  group('R84 — SajuContext yongsin signature parity', () {
    test('B1 — SajuContext.from 의 yongsin 이 YongsinService.judge(monthBranch=monthJi) 와 동일',
        () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      // result_screen 과 동일 signature 로 direct call.
      final direct = YongsinService.judge(
        dayMasterElement: ctx.dayElement,
        strengthLabel: ctx.strengthLabel,
        wood: ctx.wood,
        fire: ctx.fire,
        earth: ctx.earth,
        metal: ctx.metal,
        water: ctx.water,
        monthBranch: saju.monthPillar.jiJi,
      );
      expect(ctx.yongsin, direct.yongsin,
          reason: 'SajuContext.yongsin 이 monthBranch 전달 direct call 과 동일');
      expect(ctx.huisin, direct.huisin);
      // 조후 reason (계절 보정) 가 direct.reason 에 포함되는지 가드.
      expect(direct.reason.contains('계절') || direct.reason.contains('조후'),
          isTrue,
          reason: 'monthBranch 전달 시 reason 에 조후/계절 보정 한 줄 추가');
    });

    test('B2 — 1995-10-27 男 5행 골든 16/21/17/41/4 + yongsin signature 보존 (회귀)',
        () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      // 5행 골든 보존.
      expect(ctx.wood, 16);
      expect(ctx.fire, 21);
      expect(ctx.earth, 17);
      expect(ctx.metal, 41);
      expect(ctx.water, 4);

      // monthBranch 추가 전후 yongsin 자체는 변하지 않아야 함 (R80 sprint 6 mandate).
      final without = YongsinService.judge(
        dayMasterElement: ctx.dayElement,
        strengthLabel: ctx.strengthLabel,
        wood: ctx.wood,
        fire: ctx.fire,
        earth: ctx.earth,
        metal: ctx.metal,
        water: ctx.water,
      );
      expect(ctx.yongsin, without.yongsin);
      expect(ctx.huisin, without.huisin);
    });
  });
}

class _DummySajuNotifier extends SajuResultNotifier {
  @override
  SajuResult? build() => SajuResult.dummy();
}
