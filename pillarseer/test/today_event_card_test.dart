// Round 76 sprint 5 — today_event UI 검증.
// 1) service-level: 결정성 / 별점 범위 / sourceReason 한자 jargon 0
// 2) widget-level: home_screen 의 _TodayEventCard 는 private 라 직접 빌드 X — 대신
//    source grep 으로 회귀 방어 + TodayScreen 전체 pump 으로 카드 텍스트 확인.
// Round 82 sprint 2 — result_screen 에서 TodayEventDetailSection 완전 제거 (사용자
// mandate "내 사주 = 평생사주만"). 본 file 의 backward compat 가드는 R82 의 신정책으로
// update — result_screen 에는 today_event 노출 0, TodayScreen 에 mount 유지.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/premium_provider.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/today_screen.dart';
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

    test('home_screen 에 _TodayEventCard 존재 + CTA /today (Round 79 sprint 7 화면 분리)',
        () {
      expect(home.contains('_TodayEventCard'), isTrue);
      expect(home.contains('todayEventCaption'), isTrue);
      expect(home.contains('todayEventCtaDetail'), isTrue);
      // Round 79 sprint 7 — push target: /result?anchor=today_event → /today.
      // 사용자 mandate "내 사주 = 평생사주만" — 신규 진입은 /today 별 페이지.
      expect(home.contains("'/today'"), isTrue);
    });

    test('result_screen 에 TodayEventDetailSection / anchor key 0 (R82 sprint 2 분리)', () {
      // Round 82 sprint 2 — 사용자 mandate "내 사주 = 평생사주만". result_screen 안에서
      // TodayEventDetailSection 사용 / 정의 / anchor key 모두 0. 알림 deep-link 호환은
      // router 의 `/result?anchor=today_event` → `/today` redirect (R79 sprint 7) 가 처리.
      expect(result.contains('TodayEventDetailSection'), isFalse);
      expect(result.contains('kTodayEventDetailAnchor'), isFalse);
      // todayEventCaption/Why/Caution/Recommend l10n key 는 home_screen / today widget 에서
      // 사용 — result_screen 에는 0.
      expect(result.contains('todayEventCaption'), isFalse);
      expect(result.contains('todayEventWhy'), isFalse);
      expect(result.contains('todayEventCaution'), isFalse);
      expect(result.contains('todayEventRecommend'), isFalse);
    });

    test('today_screen 에 TodayEventDetailSection mount + 신규 widget file import (R82 sprint 2)', () {
      final today =
          File('lib/screens/today_screen.dart').readAsStringSync();
      expect(today.contains('TodayEventDetailSection'), isTrue,
          reason: 'today_screen TodayEventDetailSection mount');
      expect(
        today.contains("'../widgets/today_event_detail_section.dart'"),
        isTrue,
        reason: 'today_screen import path → widgets/today_event_detail_section.dart',
      );
      // 이전 result_screen import (R79 sprint 7) 은 제거됨.
      expect(today.contains("'result_screen.dart' show TodayEventDetailSection"),
          isFalse,
          reason: 'today_screen 의 R79 backward import 제거');
    });

    test('widgets/today_event_detail_section.dart file 존재 + class 정의 (R82 sprint 2)', () {
      final widget =
          File('lib/widgets/today_event_detail_section.dart').readAsStringSync();
      expect(widget.contains('class TodayEventDetailSection'), isTrue);
      expect(widget.contains('TODAY EVENT'), isTrue);
      expect(widget.contains('todayEventCaption'), isTrue);
      expect(widget.contains('todayEventWhy'), isTrue);
      expect(widget.contains('todayEventCaution'), isTrue);
      expect(widget.contains('todayEventRecommend'), isTrue);
    });

    test('호칭 회귀 가드 — lib/ 전역에서 "너에게" / "너의 사주" 0건', () {
      // Round 77 sprint 2 — Round 74 호칭 mandate 회귀 방어.
      // "당신" 톤 통일. lib/ 의 .dart / .arb 파일에서 "너" 호칭이 다시 들어오면 즉시 fail.
      final libDir = Directory('lib');
      final hits = <String>[];
      for (final ent in libDir.listSync(recursive: true)) {
        if (ent is! File) continue;
        if (!ent.path.endsWith('.dart') && !ent.path.endsWith('.arb')) continue;
        final src = ent.readAsStringSync();
        if (src.contains('너에게') || src.contains('너의 사주')) {
          hits.add(ent.path);
        }
      }
      expect(hits, isEmpty, reason: '호칭 회귀: ${hits.join(", ")}');
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

  // Round 82 sprint 2 — TodayScreen 직접 pump → caption + detail row 렌더 확인.
  // 사용자 mandate "내 사주 = 평생사주만". 오늘 카드는 `/today` 단독 노출.
  testWidgets('TodayScreen pump — detail caption 노출 + detail row 렌더',
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
          // R110 Sprint 2 — 오늘 사건 상세는 프리미엄 게이트 뒤. 본문 렌더
          // 회귀를 보려면 unlocked 상태에서 검증한다.
          isPremiumUnlockedProvider.overrideWithValue(true),
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
    // 캡션 — l10n key todayEventCaption == "오늘 당신에게 생길 수 있는 일" (Round 77 호칭 통일).
    expect(find.text('오늘 당신에게 생길 수 있는 일'), findsWidgets);
    final whyOrCaution = find.text('왜 그런지'.toUpperCase()).evaluate().isNotEmpty ||
        find.text('조심하면 좋은 것'.toUpperCase()).evaluate().isNotEmpty ||
        find.text('오늘 추천 행동'.toUpperCase()).evaluate().isNotEmpty;
    expect(whyOrCaution, isTrue,
        reason: 'detail row label 하나도 노출되지 않음');
  });
}

/// Round 77 sprint 8 — test fixture (production code 에서 dummy 호출 제거 후).
class _DummySajuNotifier extends SajuResultNotifier {
  @override
  SajuResult? build() => SajuResult.dummy();
}
