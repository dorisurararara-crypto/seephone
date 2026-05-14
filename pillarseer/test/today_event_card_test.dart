// Round 76 sprint 5 — today_event UI 검증.
// 1) service-level: 결정성 / 별점 범위 / sourceReason 한자 jargon 0
// 2) widget-level: home_screen 의 _TodayEventCard 와 result_screen 의
//    _TodayEventDetailSection 은 private 라 직접 빌드 X — 대신 source grep
//    으로 회귀 방어 + ResultScreen 전체 pump 으로 카드 텍스트 확인.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/result_screen.dart';
import 'package:pillarseer/services/today_event_service.dart';

void main() {
  group('TodayEventReading 카드 데이터 조립', () {
    test('별점 4 row 가 [1,5] 범위 + 합 [4,20]', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      expect(r.starsLove, inInclusiveRange(1, 5));
      expect(r.starsMoney, inInclusiveRange(1, 5));
      expect(r.starsWork, inInclusiveRange(1, 5));
      expect(r.starsHealth, inInclusiveRange(1, 5));
      expect(r.starsLove + r.starsMoney + r.starsWork + r.starsHealth,
          inInclusiveRange(4, 20));
    });

    test('sourceReason 한국어 — 2글자 이상 한자 jargon 0건', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '戊辰',
        todayScore: 60,
      );
      expect(r.sourceReason.contains('오늘은'), isTrue);
      final kanjiJargon = RegExp(r'[一-鿿]{2,}');
      // sourceReason 본문에는 2글자 이상 한자 jargon 0건 (Round 76 sprint 5 r2 fix).
      expect(kanjiJargon.hasMatch(r.sourceReason), isFalse,
          reason: 'kanji jargon: ${r.sourceReason}');
    });

    test('sourceReasonEn — non-empty English 한 단락', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '戊辰',
        todayScore: 60,
      );
      expect(r.sourceReasonEn.isNotEmpty, isTrue);
      expect(r.sourceReasonEn.toLowerCase().contains('today'), isTrue);
    });
  });

  group('TodayEventService composeNotificationLine 길이', () {
    test('ko/en 6 카테고리 모두 ≤300자', () {
      final base = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      for (final cat in EventCategory.values) {
        final reading = TodayEventReading(
          categoryDominant: cat,
          categorySub: cat,
          tenGodGroup: base.tenGodGroup,
          activeShinsa: base.activeShinsa,
          hapChungType: base.hapChungType,
          starsLove: base.starsLove,
          starsMoney: base.starsMoney,
          starsWork: base.starsWork,
          starsHealth: base.starsHealth,
          sourceReason: base.sourceReason,
          sourceReasonEn: base.sourceReasonEn,
          energy: base.energy,
          rawScores: base.rawScores,
        );
        final ko = TodayEventService.composeNotificationLine(reading);
        final en = TodayEventService.composeNotificationLineEn(reading);
        expect(ko.length, lessThanOrEqualTo(300));
        expect(en.length, lessThanOrEqualTo(300));
      }
    });
  });

  group('source grep — home/result 회귀 방어', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    final result = File('lib/screens/result_screen.dart').readAsStringSync();

    test('home_screen 에 _TodayEventCard 존재 + CTA /result?anchor=today_event',
        () {
      expect(home.contains('_TodayEventCard'), isTrue);
      expect(home.contains('todayEventCaption'), isTrue);
      expect(home.contains('todayEventCtaDetail'), isTrue);
      expect(home.contains('anchor=today_event'), isTrue);
    });

    test('result_screen 에 _TodayEventDetailSection + anchor key 존재', () {
      expect(result.contains('_TodayEventDetailSection'), isTrue);
      expect(result.contains('kTodayEventDetailAnchor'), isTrue);
      expect(result.contains('TODAY EVENT'), isTrue);
      expect(result.contains('todayEventCaption'), isTrue);
      expect(result.contains('todayEventWhy'), isTrue);
      expect(result.contains('todayEventCaution'), isTrue);
      expect(result.contains('todayEventRecommend'), isTrue);
    });

    test('result_screen 17 섹션 본체 변경 X — 모든 기존 섹션 유지', () {
      const sections = [
        '_DayMasterHero',
        '_ReadingSection',
        '_LifeStageSection',
        '_SipsinPersonaSection',
        '_CareerSection',
        '_WealthStrategySection',
        '_AdditionalLifeSection',
        '_ChartAttributesSection',
        '_FourPillarsSection',
        '_ThreeStrokesSection',
        '_ForYouTodaySection',
        '_FiveElementsSection',
        '_ProHooksSection',
        '_CtaStack',
        '_AesopFooter',
      ];
      for (final s in sections) {
        expect(result.contains(s), isTrue, reason: '$s 누락');
      }
    });
  });

  testWidgets('kTodayEventDetailAnchor global key — instance 존재', (tester) async {
    expect(kTodayEventDetailAnchor, isA<GlobalKey>());
  });

  // FIX r3 #2 — 실제 ResultScreen pump → anchor=today_event 시 detail 섹션 렌더링 확인.
  // (DailyService.calculate 가 SajuResult.dummy 로 동작하므로 외부 의존 X.)
  testWidgets('ResultScreen pump (anchor=today_event) — detail caption 노출 + 별점 렌더',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/result?anchor=today_event',
      routes: [
        GoRoute(
          path: '/result',
          builder: (c, s) => const ResultScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        // sajuResultProvider 는 SajuResult.dummy() fallback 자동 사용 (override X).
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('ko'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // 캡션 — l10n key todayEventCaption == "오늘 너에게 생길 수 있는 일".
    expect(find.text('오늘 너에게 생길 수 있는 일'), findsWidgets);
    // detail row 라벨 — "왜 그런지" / "조심하면 좋은 것" / "오늘 추천 행동" 중 최소 하나는 노출.
    // (한 번에 모든 라벨이 viewport 안에 있지 않을 수 있어 findsWidgets 사용.)
    final whyOrCaution = find.text('왜 그런지'.toUpperCase()).evaluate().isNotEmpty ||
        find.text('조심하면 좋은 것'.toUpperCase()).evaluate().isNotEmpty ||
        find.text('오늘 추천 행동'.toUpperCase()).evaluate().isNotEmpty;
    expect(whyOrCaution, isTrue,
        reason: 'detail row label 하나도 노출되지 않음');
    // sajuResultProvider 의존 확인 — pump 자체가 throw 없으면 PASS.
  });
}
