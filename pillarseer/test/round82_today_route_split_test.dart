// Round 82 sprint 2 회귀 가드 — `/today` route 분리 완료 검증.
//
// 사용자 mandate (2026-05-15 verbatim):
//   "내 사주탭에 오늘 당신에게 생길수 있는일이 왜있는거며 (오늘탭에 있어야함)"
//
// → result_screen.dart 에서 TodayEventDetailSection mount / class / anchor key / scroll
//   logic 모두 제거. /today 탭 (today_screen.dart) + widgets/today_event_detail_section.dart
//   에만 정의·노출. 알림 deep-link `/result?anchor=today_event` 는 router redirect (R79
//   sprint 7) 로 `/today` 로 흘러감.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/today_screen.dart';
import 'package:pillarseer/widgets/today_event_detail_section.dart';

void main() {
  group('R82 sprint 2 — /today route 분리 회귀 가드', () {
    final resultSrc =
        File('lib/screens/result_screen.dart').readAsStringSync();
    final todaySrc =
        File('lib/screens/today_screen.dart').readAsStringSync();
    final widgetPath = 'lib/widgets/today_event_detail_section.dart';

    test('B1 — result_screen.dart 안에 TodayEventDetailSection 사용 0', () {
      expect(resultSrc.contains('TodayEventDetailSection'), isFalse,
          reason: 'result_screen 에 today_event widget 잔존');
    });

    test('B1b — result_screen.dart 안에 anchor key / scroll logic / today_event_service import 0',
        () {
      expect(resultSrc.contains('kTodayEventDetailAnchor'), isFalse,
          reason: 'anchor key 잔존');
      expect(resultSrc.contains("'today_event'"), isFalse,
          reason: 'anchor query 검사 logic 잔존');
      expect(resultSrc.contains('today_event_service.dart'), isFalse,
          reason: 'today_event_service import 잔존');
    });

    test('B2 — widgets/today_event_detail_section.dart file 존재 + class 정의', () {
      final file = File(widgetPath);
      expect(file.existsSync(), isTrue, reason: '$widgetPath 미생성');
      final src = file.readAsStringSync();
      expect(src.contains('class TodayEventDetailSection'), isTrue);
      expect(src.contains('final SajuResult result;'), isTrue,
          reason: 'TodayEventDetailSection.result 시그니처 보존');
      expect(src.contains('final bool useKo;'), isTrue,
          reason: 'TodayEventDetailSection.useKo 시그니처 보존');
      // 본문 l10n key 모두 보존.
      expect(src.contains('todayEventCaption'), isTrue);
      expect(src.contains('todayEventWhy'), isTrue);
      expect(src.contains('todayEventCaution'), isTrue);
      expect(src.contains('todayEventRecommend'), isTrue);
    });

    test('B3 — today_screen.dart import path 가 widgets/today_event_detail_section.dart', () {
      expect(
        todaySrc.contains("'../widgets/today_event_detail_section.dart'"),
        isTrue,
        reason: 'today_screen import 신규 widget file',
      );
      expect(todaySrc.contains('TodayEventDetailSection('), isTrue,
          reason: 'today_screen mount');
      // R79 의 result_screen import 잔존 X.
      expect(
        todaySrc.contains("'result_screen.dart' show TodayEventDetailSection"),
        isFalse,
        reason: 'today_screen 의 R79 backward import 제거',
      );
    });

    test('B4 — router.dart 의 `/result?anchor=today_event` → `/today` redirect rule 보존',
        () {
      final routerSrc = File('lib/router.dart').readAsStringSync();
      expect(routerSrc.contains("anchor"), isTrue,
          reason: 'router redirect anchor 검사');
      expect(routerSrc.contains("'today_event'"), isTrue,
          reason: 'redirect anchor 값');
      expect(routerSrc.contains("return '/today'"), isTrue,
          reason: 'redirect target');
    });

    testWidgets(
        'B5 — TodayScreen pump → TodayEventDetailSection 1개 노출 (오늘 카드 mount)',
        (tester) async {
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TodayEventDetailSection), findsOneWidget,
          reason: 'TodayScreen 에 TodayEventDetailSection 1개 mount');
    });
  });
}

class _DummySajuNotifier extends SajuResultNotifier {
  @override
  SajuResult? build() => SajuResult.dummy();
}
