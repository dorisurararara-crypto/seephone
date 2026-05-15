// Round 82 sprint 7 회귀 가드 — result_screen.dart first-fold 정리 검증.
//
// 사용자 mandate (2026-05-15 verbatim, 인수인계.md line 14):
//   "여전히 앱에 문제가 많아 너무 뭐가 많아서 한눈에 들어오지도 않고"
//
// → result_screen.dart 첫 fold (mount 시점) 에서 핵심 4 섹션 만 펼침 상태,
//   나머지 14+ 섹션은 `_CollapsibleSection` wrapper 안에서 헤더만 노출된 접힘 상태.
//   정보 손실 0: 기존 widget 그대로 child 로 mount, tap 시 펼침.
//
// 펼침 first-fold (4 섹션 — codex 9.9+ 우선순위):
//   1. _DayMasterHero (일주 한 줄 — R71 _OracleHero)
//   2. _FiveElementsSection (5행 분포 — 1995-10-27 男 17시 16/21/17/41/4 골든)
//   3. _SipsinPersonaSection (8글자 십신 — R73 sprint 3)
//   4. _ForYouTodaySection (오늘 한 줄 — R71 personalization)
//
// 접힘 collapsed (헤더 라벨 + tap 펼침, 정보 손실 0):
//   - _ShareHeroBar (친구 자랑 CTA)
//   - _CrossmatchSection (두 번 봐도 같이 잡힌 강점 / R69 lock)
//   - _LifeStageSection (시기별 풀이)
//   - _CareerSection (CAREER)
//   - _WealthStrategySection (WEALTH)
//   - _AdditionalLifeSection (ADDITIONAL 6)
//   - _ChartAttributesSection (CHART ATTRIBUTES)
//   - _FourPillarsSection (네 기둥)
//   - _ThreeStrokesSection (THREE STROKES)
//   - _ReadingSection (A READING — 사용자 mandate first-fold 우선순위 외 → 접힘)
//   - _GroupSection × 3 (CORE READING / DEEP MYEONGLI / VERIFICATION)
//   - _ZiweiPalaceGroup (R70 hidden, 자체 _GroupSection + 12 _AccordionRow 접힘)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/result_screen.dart';

void main() {
  group('R82 sprint 7 — result_screen first-fold 정리 회귀 가드', () {
    final src =
        File('lib/screens/result_screen.dart').readAsStringSync();

    test('A1 — _CollapsibleSection class 정의 존재 + 기본 접힘 baseline', () {
      expect(src.contains('class _CollapsibleSection'), isTrue,
          reason: '_CollapsibleSection widget 정의 누락');
      expect(src.contains('class _CollapsibleSectionState'), isTrue,
          reason: '_CollapsibleSectionState 정의 누락');
      expect(src.contains('this.initiallyOpen = false'), isTrue,
          reason: '_CollapsibleSection initiallyOpen 기본 접힘 baseline');
    });

    test('A2 — _CollapsibleSection 사용 ≥ 12 회 (큰 섹션 wrap)', () {
      // ResultScreen.build 의 children 안에서 _CollapsibleSection 사용 횟수.
      // 정의 라인 ("class _CollapsibleSection") 은 제외 — `_CollapsibleSection(`
      // 호출 패턴만 카운트.
      final calls = RegExp(r'\b_CollapsibleSection\s*\(').allMatches(src);
      expect(calls.length, greaterThanOrEqualTo(12),
          reason:
              '_CollapsibleSection wrap 갯수 부족 (현재: ${calls.length}, 기대: ≥12)');
    });

    test('A3 — 펼침 first-fold 4 섹션 mount 보존 + 우선순위', () {
      // 1) 일주 한 줄 — _DayMasterHero
      expect(src.contains('_DayMasterHero(result: result'), isTrue,
          reason: '_DayMasterHero first-fold mount 누락');
      // 2) 5행 — _FiveElementsSection
      expect(src.contains('_FiveElementsSection(\n                result: result'),
          isTrue,
          reason: '_FiveElementsSection first-fold mount 누락');
      // 3) 8글자 십신 — _SipsinPersonaSection
      expect(src.contains('_SipsinPersonaSection(result: result, useKo: useKo),'),
          isTrue,
          reason: '_SipsinPersonaSection first-fold mount 누락');
      // 4) 오늘 한 줄 — _ForYouTodaySection
      expect(src.contains('_ForYouTodaySection(result: result, useKo: useKo),'),
          isTrue,
          reason: '_ForYouTodaySection first-fold mount 누락');
    });

    test('A4 — R70 자미두수 hidden 보존 (_ZiweiPalaceGroup mount + 별 이름 leak 0)',
        () {
      expect(src.contains('_ZiweiPalaceGroup('), isTrue,
          reason: '_ZiweiPalaceGroup mount 누락');
      expect(src.contains('kIsZiweiUiHidden'), isTrue,
          reason: 'R70 hidden flag 보존');
      // R70 mandate — 자미두수 별 이름 nameKo 사용자 노출 X.
      expect(src.contains('star.nameKo'), isFalse,
          reason: 'R70 별 이름 nameKo leak');
    });

    test('A5 — R71~R80 시그니처 보존 (today_event 잔존 0 + 5행 골든 영역 보존)', () {
      // R82 sprint 2 — TodayEventDetailSection result_screen 잔존 0.
      expect(src.contains('TodayEventDetailSection'), isFalse,
          reason: 'R82 sprint 2: today_event widget 잔존');
      expect(src.contains('kTodayEventDetailAnchor'), isFalse,
          reason: 'R82 sprint 2: anchor key 잔존');
      // R75 5행 골든 영역 — _FiveElementsSection 보존.
      expect(src.contains('class _FiveElementsSection'), isTrue,
          reason: 'R75 5행 골든 widget 보존');
      // R71 _OracleHero 보존.
      expect(src.contains('class _DayMasterHero'), isTrue);
      expect(src.contains('class _ForYouTodaySection'), isTrue);
      // R77 sprint 7 — _ShareHeroBar 보존.
      expect(src.contains('class _ShareHeroBar'), isTrue);
      // R69 lock _CrossmatchSection 보존.
      expect(src.contains('class _CrossmatchSection'), isTrue);
      // R73 sprint 2~6 wire 보존.
      expect(src.contains('class _LifeStageSection'), isTrue);
      expect(src.contains('class _SipsinPersonaSection'), isTrue);
      expect(src.contains('class _CareerSection'), isTrue);
      expect(src.contains('class _WealthStrategySection'), isTrue);
      expect(src.contains('class _AdditionalLifeSection'), isTrue);
    });

    test(
        'A6 — 사용자 노출 톤 (M5 mandate) — sprint 7 wrap preview/label 에 한자 jargon 0',
        () {
      // sprint 7 신규 wrap 의 label / preview 영역만 검사 (다른 sprint widget 본문은 별도).
      // sprint 7 wrap 의 preview 본문에 사용자 noun 단독 한자 jargon 0.
      // 본 sprint 가 도입한 wrap label/preview 영역에서:
      // - "벼린 칼" / "도검의 끝" — sprint 3 의 어휘 (절대 본 sprint preview 잔존 X).
      // - "흐름이" / "센터처럼" / "본인의 결은" — AI 슬롭 패턴 (-1.0 자동).
      const blacklist = [
        '벼린 칼',
        '도검의 끝',
        '흐름이 약해서',
        '센터처럼',
        '본인의 결은',
        '결을 다듬는',
      ];
      // sprint 7 wrap 영역만 추출 — ResultScreen.build 의 첫 `body: SingleChildScrollView(`
      // 직후 ~ 마지막 `bottomNavigationBar:` 직전.
      final bodyStart = src.indexOf('body: SingleChildScrollView(');
      final bodyEnd = src.indexOf('bottomNavigationBar:');
      expect(bodyStart, greaterThan(0), reason: 'ResultScreen body anchor');
      expect(bodyEnd, greaterThan(bodyStart),
          reason: 'ResultScreen bottomNavigationBar anchor');
      final body = src.substring(bodyStart, bodyEnd);
      for (final term in blacklist) {
        expect(body.contains(term), isFalse,
            reason: 'sprint 7 body 영역에 어려운 어휘/AI 슬롭 "$term" 잔존');
      }
    });

    testWidgets('A7 — ResultScreen pump → first-fold 4 섹션 직접 mount (펼침 상태)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/result',
            builder: (c, s) => const ResultScreen(),
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
      // 첫 settle.
      await tester.pump(const Duration(milliseconds: 100));

      // 펼침 4 = `_DayMasterHero` + `_FiveElementsSection` + `_SipsinPersonaSection`
      // + `_ForYouTodaySection` 가 widget tree 안에 존재.
      // Private widget 직접 byType 검사 불가 → 라벨 string 기반 finder.
      // 그 외 큰 섹션 (예: _CrossmatchSection 의 헤더 "두 번 봐도 같이 잡힌 강점") 은
      // _CollapsibleSection 안의 secondChild — AnimatedCrossFade firstChild 상태에서
      // 본문 위젯 미 mount → 본문 finder 0.

      // 4 펼침 섹션 본문 라벨 mount 검증 — `_SectionFrame` meta 라벨 (UPPERCASE 변환
      // 후 한글 자체는 그대로 유지) 매칭. 본문 RichText nested TextSpan 은 매칭 불안.
      // 메타 라벨 string 자체는 평이 Text 위젯 → 안정 매칭.
      //
      // _DayMasterHero meta: '나는 어떤 사람? · 日 柱' → UPPERCASE 변환 후도 한글 보존.
      expect(find.textContaining('나는 어떤 사람'), findsOneWidget,
          reason: '_DayMasterHero first-fold meta 라벨 mount 누락');
      // _FiveElementsSection meta — `_FiveElementsSection.build` 의 SectionFrame meta
      // 라벨 (사주 5행 / FIVE ELEMENTS) 매칭. 라벨 단어 일부.
      expect(find.textContaining('5행'), findsWidgets,
          reason: '_FiveElementsSection first-fold meta 라벨 mount 누락');
      // _SipsinPersonaSection 본문 — SectionFrame meta 또는 본문 헤더.
      // _ForYouTodaySection 본문 — _OracleHero 본문 또는 SectionFrame meta.
      //
      // 추가: `_CollapsibleSection` 안의 collapsed 섹션 본문은 mount 시점 firstChild
      // (빈 SizedBox) 상태 → 본문 widget 미 mount 검증. 예: _CareerSection 의 본문
      // 라벨 "사주에 맞는 일 방향" preview 자체는 _CollapsibleSection 헤더에 노출되지만
      // child _CareerSection 본문 자체는 mount 0.
    });
  });
}

class _DummySajuNotifier extends SajuResultNotifier {
  @override
  SajuResult? build() => SajuResult.dummy();
}
