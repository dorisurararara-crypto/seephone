// R110 Sprint 2 — 무료/프리미엄 게이트 회귀 가드.
//
// monetization_playbook.md §"무료 / 프리미엄 경계 (9개 기능)" 를 코드가 그대로
// 지키는지 검증한다. 두 층위로 본다:
//   A. PremiumGate / PremiumLockedSection 위젯 메커니즘 — 실제 mount 검증.
//      - locked 상태: unlocked 본문이 *mount 되지 않는다* (truncate/blur 아님).
//      - unlocked 상태: 본문이 그대로 mount.
//   B. 9개 화면 source — 게이트가 playbook 경계대로 걸렸는지.
//   C. 금지 문구 scan — "준비 중/193/paywall" 을 lock 혜택으로 팔지 않는다.
//
// Sprint 1 IAP 인프라(test/r110_purchase_service_test.dart 54개) 와 독립 —
// 이 파일은 게이트 적용만 본다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillarseer/providers/premium_provider.dart';
import 'package:pillarseer/services/jol_calendar_2026.dart';
import 'package:pillarseer/services/premium_gate_policy.dart';
import 'package:pillarseer/widgets/premium_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // ── A. PremiumGate / PremiumLockedSection 위젯 메커니즘 ──────────────────

  group('A. PremiumGate 위젯 메커니즘', () {
    Widget host({required bool unlocked}) => ProviderScope(
          overrides: [
            isPremiumUnlockedProvider.overrideWithValue(unlocked),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PremiumGate(
                feature: PremiumFeature.mySajuCategory,
                label: '재물운',
                unlocked: (_) => const Text('PREMIUM_BODY_VISIBLE'),
                locked: (_) => const PremiumLockedSection(
                  feature: PremiumFeature.mySajuCategory,
                  title: '재물운',
                  description: '12개 인생 영역 풀이는 프리미엄팩에서 열려요.',
                ),
              ),
            ),
          ),
        );

    testWidgets('A1 — locked 상태: 프리미엄 본문 mount 안 됨', (tester) async {
      await tester.pumpWidget(host(unlocked: false));
      await tester.pump();
      expect(find.text('PREMIUM_BODY_VISIBLE'), findsNothing,
          reason: 'locked 인데 프리미엄 본문이 mount 됨 — 섹션 단위 잠금 위반');
      // 잠금 placeholder 는 보인다 (기능 고장처럼 보이면 안 됨).
      expect(find.byKey(const Key('premium_locked_mySajuCategory')), findsOneWidget);
    });

    testWidgets('A2 — unlocked 상태: 기존 본문 그대로 mount', (tester) async {
      await tester.pumpWidget(host(unlocked: true));
      await tester.pump();
      expect(find.text('PREMIUM_BODY_VISIBLE'), findsOneWidget,
          reason: 'unlocked 인데 본문이 mount 안 됨');
      expect(find.byKey(const Key('premium_locked_mySajuCategory')), findsNothing,
          reason: 'unlocked 인데 잠금 placeholder 가 남음');
    });

    testWidgets('A3 — 잠긴 항목 탭 → onPremiumLockedTap hook 호출', (tester) async {
      final original = kPremiumLockedTapOverride;
      PremiumLockContext? captured;
      kPremiumLockedTapOverride = (lock) => captured = lock;
      addTearDown(() => kPremiumLockedTapOverride = original);

      await tester.pumpWidget(host(unlocked: false));
      await tester.pump();
      await tester.tap(find.byKey(const Key('premium_locked_mySajuCategory')));
      await tester.pump();

      expect(captured, isNotNull, reason: '잠긴 항목 탭이 hook 으로 모이지 않음');
      expect(captured!.feature, PremiumFeature.mySajuCategory);
      expect(captured!.label, '재물운');
    });
  });

  // ── B. 9개 화면 게이트 적용 ──────────────────────────────────────────────

  group('B. 9기능 게이트 적용 (source)', () {
    String read(String path) => File(path).readAsStringSync();

    test('B0 — premium_gate_policy: 무료 5 / 프리미엄 12 비율', () {
      // playbook ① — 17카테고리 중 무료 5개.
      expect(kFreeMySajuCategoryKeys.length, 5,
          reason: 'playbook ① 무료 카테고리는 정확히 5개');
      expect(isFreeMySajuCategory('personality'), isTrue);
      expect(isFreeMySajuCategory('wealth'), isFalse,
          reason: '재물운은 프리미엄');
      expect(kSelfConclusionIsPremium, isTrue);
    });

    test('B1 — ① 내 사주: _CategorySectionCard + _SelfConclusionCard 게이트', () {
      final src = read('lib/screens/result_screen.dart');
      expect(src.contains('PremiumGate('), isTrue,
          reason: 'result_screen 에 PremiumGate 미적용');
      expect(src.contains('PremiumFeature.mySajuCategory'), isTrue);
      expect(src.contains('PremiumFeature.mySajuConclusion'), isTrue);
      expect(src.contains('isFreeMySajuCategory('), isTrue,
          reason: '무료/프리미엄 카테고리 분기가 정책 helper 를 거치지 않음');
    });

    test('B1b — ① 내 사주 무료 핵심 5: 오행 균형·보조 정보·오늘 조언이 게이트 밖', () {
      // R110 Sprint 2 REWORK — playbook 무료 핵심 5("나는 어떤 사람인가 +
      // 오행 균형 + 십신 성향 + 강점/주의점 + 오늘 바로 써먹는 조언")를
      // 화면 상단 무료 모듈이 함께 충족한다. _FiveElementsSection(오행 균형)·
      // _ChartAttributesSection(오행/강약/용신)·_ForYouTodaySection(강점/
      // 주의점·오늘 조언)이 모두 build 트리에 mount 되고, 첫 PremiumGate 보다
      // *앞* 에 있어야 한다(= 무료).
      final src = read('lib/screens/result_screen.dart');
      // build() 본체만 검사 — class 정의가 아니라 실제 mount 호출 위치.
      final buildIdx = src.indexOf('class _ResultScreenState extends');
      final buildEnd = src.indexOf('// ──────────── R88 sprint 3');
      expect(buildIdx, greaterThan(-1));
      expect(buildEnd, greaterThan(buildIdx));
      final buildScope = src.substring(buildIdx, buildEnd);

      final fiveIdx = buildScope.indexOf('_FiveElementsSection(');
      final chartIdx = buildScope.indexOf('_ChartAttributesSection(');
      final todayIdx = buildScope.indexOf('_ForYouTodaySection(');
      final gateIdx = buildScope.indexOf('PremiumGate(');
      expect(fiveIdx, greaterThan(-1),
          reason: '_FiveElementsSection 이 build 트리에 mount 안 됨');
      expect(chartIdx, greaterThan(-1),
          reason: '_ChartAttributesSection 이 build 트리에 mount 안 됨 (무료 보조 정보)');
      expect(todayIdx, greaterThan(-1),
          reason: '_ForYouTodaySection 이 build 트리에 mount 안 됨 (무료 오늘 조언)');
      expect(gateIdx, greaterThan(-1), reason: 'PremiumGate 미적용');
      expect(fiveIdx < gateIdx, isTrue,
          reason: '_FiveElementsSection(무료)이 PremiumGate 앞에 있어야 함');
      expect(chartIdx < gateIdx, isTrue,
          reason: '_ChartAttributesSection(무료)이 PremiumGate 앞에 있어야 함');
      expect(todayIdx < gateIdx, isTrue,
          reason: '_ForYouTodaySection(무료 오늘 조언)이 PremiumGate 앞에 있어야 함');
    });

    test('B2 — ② 오늘의 사주: TodayDeep/EventDetail 프리미엄, V5 무료', () {
      final src = read('lib/screens/today_screen.dart');
      expect(src.contains('PremiumFeature.todayDeep'), isTrue);
      // v5 loader 는 게이트 밖(무료).
      final v5Idx = src.indexOf('TodayV5Loader(');
      final gateIdx = src.indexOf('PremiumGate(');
      expect(v5Idx, greaterThan(-1));
      expect(gateIdx, greaterThan(-1));
      expect(v5Idx < gateIdx, isTrue,
          reason: 'TodayV5Loader(무료)는 PremiumGate 앞에 있어야 함');
      // 심층/사건 상세는 게이트 뒤.
      expect(src.indexOf('TodayDeepReadingSection(') > gateIdx, isTrue);
      expect(src.indexOf('TodayEventDetailSection(') > gateIdx, isTrue);
    });

    test('B3 — ③ 궁합: _DetailSection 프리미엄, Score 무료', () {
      final src = read('lib/screens/reports/compatibility_screen.dart');
      expect(src.contains('PremiumFeature.compatibilityDetail'), isTrue);
      // _ScoreSection 은 게이트 밖.
      final scoreIdx = src.indexOf('_ScoreSection(score:');
      final gateIdx = src.indexOf('PremiumFeature.compatibilityDetail');
      expect(scoreIdx, greaterThan(-1));
      expect(scoreIdx < gateIdx, isTrue,
          reason: '_ScoreSection(무료)이 게이트 앞에 있어야 함');
    });

    test('B4 — ④ 신년: 무료 3개월 + (12개월 전체·12영역) 프리미엄', () {
      // R110 Sprint 2 REWORK — playbook ④ "연간 총평 + 3개월" 무료 /
      // "12개월 전체 + 12영역 상세" 프리미엄.
      final src = read('lib/screens/reports/new_year_2026_screen.dart');
      expect(src.contains('PremiumFeature.newYearAreas'), isTrue);
      final summaryIdx = src.indexOf('_AnnualSummary(saju:');
      final gateIdx = src.indexOf('PremiumFeature.newYearAreas');
      expect(summaryIdx, greaterThan(-1));
      expect(summaryIdx < gateIdx, isTrue,
          reason: '_AnnualSummary(무료)가 게이트 앞에 있어야 함');
      // 무료 3개월 섹션이 build 트리에 mount 되고 게이트보다 앞(무료).
      final freeIdx = src.indexOf('_FreeMonthlyPreview(saju:');
      expect(freeIdx, greaterThan(-1),
          reason: '무료 3개월 섹션(_FreeMonthlyPreview)이 build 트리에 없음');
      expect(freeIdx < gateIdx, isTrue,
          reason: '_FreeMonthlyPreview(무료 3개월)가 게이트 앞에 있어야 함');
      // _FreeMonthlyPreview 는 새 데이터 없이 moodFor + displayOrder 재사용.
      expect(src.contains('JolCalendar2026.displayOrder'), isTrue);
      expect(src.contains('NewYear2026Screen.moodFor('), isTrue);
      // R110 Sprint 2 REWORK2 — 무료 3개월 off-by-one 회귀 가드.
      // displayOrder[0] 은 소한(丑) — 입춘(寅)이 아니다. 무료 3개월이
      // displayOrder 앞 3개(丑·寅·卯)를 그대로 쓰면 안 된다. _FreeMonthlyPreview
      // 본문 범위만 잘라 검사한다.
      final freeBodyStart = src.indexOf('class _FreeMonthlyPreview');
      final freeBodyEnd = src.indexOf('class _MonthlyFlow');
      expect(freeBodyStart, greaterThan(-1));
      expect(freeBodyEnd, greaterThan(freeBodyStart));
      final freeScope = src.substring(freeBodyStart, freeBodyEnd);
      // displayOrder 를 skip(1) 해 소한을 건너뛴다 — 입춘부터 시작.
      expect(freeScope.contains('.skip(') && freeScope.contains('JolCalendar2026.displayOrder'),
          isTrue,
          reason: '무료 3개월이 displayOrder 를 skip 없이 앞 3개(丑·寅·卯)를 씀 — 소한 off-by-one');
      // displayOrder 를 인덱스 0 부터 쓰는 패턴(slots[i] + index: i 동시)이면
      // 소한 丑 부터 시작한다 — 금지. moodFor 에 raw 'index: i,' 가 가면 안 된다.
      expect(freeScope.contains('index: i,'), isFalse,
          reason: '무료 3개월 moodFor 가 displayOrder index 0(소한)부터 씀 — 입춘 보정 누락');
      // PremiumGate unlocked child 안에 _MonthlyFlow + _TwelveAreas 둘 다 존재.
      final unlockedIdx = src.indexOf('unlocked: (_) => Column(', gateIdx);
      expect(unlockedIdx, greaterThan(gateIdx),
          reason: 'PremiumGate unlocked child 가 Column 묶음이 아님');
      // '\n' 줄머리 'locked:' 만 잡는다 ('unlocked:' 의 부분 문자열 회피).
      final lockedIdx = src.indexOf('\n              locked: (_) =>', unlockedIdx);
      expect(lockedIdx, greaterThan(unlockedIdx),
          reason: 'PremiumGate locked child 시작 위치를 찾지 못함');
      final unlockedScope = src.substring(unlockedIdx, lockedIdx);
      expect(unlockedScope.contains('_MonthlyFlow(saju:'), isTrue,
          reason: 'PremiumGate unlocked 안에 _MonthlyFlow(12개월 전체) 누락');
      expect(unlockedScope.contains('_TwelveAreas(theme:'), isTrue,
          reason: 'PremiumGate unlocked 안에 _TwelveAreas(12영역) 누락');
    });

    test('B4b — ④ 신년 무료 3개월 = 입춘 이후 寅·卯·辰 (소한 off-by-one 가드)', () {
      // displayOrder[0] 이 소한(丑)이라는 전제 위에서, 무료 3개월 selection 이
      // 寅·卯·辰 (입춘·경칩·청명) 인지 검증한다. _FreeMonthlyPreview 가 쓰는
      // skip(1).take(3) 와 동일한 selection 을 재현해 본다.
      final displayOrder = JolCalendar2026.displayOrder;
      expect(displayOrder[0].monthBranch, '丑',
          reason: 'displayOrder[0] 은 소한 丑 — 이 전제가 깨지면 무료 3개월 보정도 깨짐');
      expect(displayOrder[0].nameKo, '소한');
      // _FreeMonthlyPreview 와 동일한 selection: skip(1).take(3).
      final freeSlots = displayOrder.skip(1).take(3).toList();
      expect(freeSlots.map((s) => s.monthBranch).toList(), ['寅', '卯', '辰'],
          reason: '무료 3개월은 입춘 이후 寅·卯·辰 이어야 함');
      expect(freeSlots.map((s) => s.nameKo).toList(), ['입춘', '경칩', '청명']);
      // 천간까지 검증 — 丙년 五虎遁: 寅 庚 / 卯 辛 / 辰 壬.
      expect(freeSlots.map((s) => s.monthStem).toList(), ['庚', '辛', '壬']);
    });

    test('B5 — ⑤ 셀럽: Top 30 선택 무료, 심층 본문만 프리미엄', () {
      // R110 Sprint 2 REWORK — playbook ⑤ "Top 30 기본 공개 / 심층 확장
      // 프리미엄". 추가 선택 자체를 막지 않는다.
      final src = read('lib/screens/reports/celebrity_saju_screen.dart');
      expect(src.contains('PremiumFeature.celebrityMore'), isTrue);
      // _selectStar 가 isPremiumUnlockedProvider 로 추가 선택을 막지 않는다.
      final selStart = src.indexOf('void _selectStar(');
      final selEnd = src.indexOf('void _chooseOtherStar(');
      expect(selStart, greaterThan(-1));
      expect(selEnd, greaterThan(selStart));
      final selScope = src.substring(selStart, selEnd);
      expect(selScope.contains('isPremiumUnlockedProvider'), isFalse,
          reason: '_selectStar 가 프리미엄 여부로 추가 선택을 막음 — Top 30 무료 위반');
      // _viewedFreeCeleb 기반 차단 제거됨.
      expect(src.contains('_viewedFreeCeleb'), isFalse,
          reason: '_viewedFreeCeleb 추가 선택 차단이 남아 있음');
      // 심층 7섹션 본문이 PremiumGate 로 감싸짐.
      expect(src.contains('PremiumGate('), isTrue,
          reason: '심층 본문이 PremiumGate 로 감싸지지 않음');
      final gateIdx = src.indexOf('PremiumGate(');
      final unlockedIdx = src.indexOf('unlocked: (_) =>', gateIdx);
      // '\n' 줄머리 'locked:' 만 잡는다 ('unlocked:' 의 부분 문자열 회피).
      final lockedIdx = src.indexOf('\n                      locked: (_) =>', unlockedIdx);
      expect(unlockedIdx, greaterThan(gateIdx));
      expect(lockedIdx, greaterThan(unlockedIdx),
          reason: 'PremiumGate locked child 시작 위치를 찾지 못함');
      final gateScope = src.substring(unlockedIdx, lockedIdx);
      expect(gateScope.contains('_SectionBody(reading: reading, useKo: useKo)'),
          isTrue,
          reason: 'PremiumGate unlocked 가 심층 _SectionBody 를 감싸지 않음');
      // 무료 lead(첫 섹션)는 게이트 밖.
      expect(src.contains('leadOnly: true'), isTrue,
          reason: '무료 lead(_SectionBody leadOnly) 누락');
      // curated only — 준비 중 셀럽은 lock 혜택으로 노출되지 않는다.
      expect(src.contains('reading.isCurated'), isTrue);
    });

    test('B6 — ⑥ 전생: 첫 1편 무료, 추가 생성 프리미엄', () {
      final src = read('lib/screens/reports/past_life_screen.dart');
      expect(src.contains('PremiumFeature.pastLifeMore'), isTrue);
      expect(src.contains('_viewedFreeStory'), isTrue);
    });

    test('B7 — ⑦ 음악: 곡/아티스트 무료, 효능/부작용/복용법/reroll 프리미엄', () {
      final src = read('lib/screens/reports/music_pharmacy_screen.dart');
      expect(src.contains('PremiumFeature.musicDetail'), isTrue);
      expect(src.contains('showDetail'), isTrue,
          reason: '_PrescriptionCard 가 상세 섹션 게이트 플래그를 받지 않음');
      // PRESCRIBED(곡/아티스트)는 게이트 밖, EFFECT 는 게이트 안.
      final prescribedIdx = src.indexOf("'처방 항목'");
      final showDetailIdx = src.indexOf('if (showDetail)');
      expect(prescribedIdx, greaterThan(-1));
      expect(showDetailIdx, greaterThan(-1));
      expect(prescribedIdx < showDetailIdx, isTrue,
          reason: '처방 항목(무료)이 상세 게이트 앞에 있어야 함');
    });

    test('B8 — ⑧ 자미두수: kIsZiweiUiHidden 유지, 신규 노출 없음', () {
      final src = read('lib/screens/result_screen.dart');
      expect(src.contains('const bool kIsZiweiUiHidden = true;'), isTrue,
          reason: '숨김 자미두수 UI 플래그가 변경됨');
      // _ZiweiPalaceGroup / _CrossmatchSection 은 build 트리에 mount 되면 안 됨.
      final buildIdx = src.indexOf('class _ResultScreenState extends');
      final buildEnd = src.indexOf('// ──────────── small primitives');
      final buildScope = src.substring(buildIdx, buildEnd);
      expect(buildScope.contains('_ZiweiPalaceGroup('), isFalse,
          reason: '숨김 자미두수가 새로 노출됨');
      expect(buildScope.contains('_CrossmatchSection('), isFalse);
    });

    test('B9 — ⑨ 알림: 아침 슬롯 무료, 오후/저녁 프리미엄', () {
      final src = read('lib/screens/settings_screen.dart');
      expect(src.contains('PremiumFeature.notificationSlots'), isTrue);
      // 마스터 _NotifSwitch(1개 기본 알림)는 게이트 밖.
      expect(src.contains('_NotifSwitch()'), isTrue);
      // morning 슬롯은 무료로 통과.
      expect(src.contains('slot != NotificationSlot.morning'), isTrue,
          reason: '아침 슬롯 무료 분기 누락');
    });
  });

  // ── C. 금지 문구 scan ───────────────────────────────────────────────────

  group('C. lock 혜택 금지 문구 scan', () {
    final gateFiles = <String>[
      'lib/widgets/premium_gate.dart',
      'lib/services/premium_gate_policy.dart',
      'lib/screens/result_screen.dart',
      'lib/screens/today_screen.dart',
      'lib/screens/settings_screen.dart',
      'lib/screens/reports/compatibility_screen.dart',
      'lib/screens/reports/new_year_2026_screen.dart',
      'lib/screens/reports/celebrity_saju_screen.dart',
      'lib/screens/reports/past_life_screen.dart',
      'lib/screens/reports/music_pharmacy_screen.dart',
    ];

    test('C1 — premium_gate 사용자 문구에 "준비 중/193" 없음', () {
      // premium_gate.dart 의 lock placeholder 가 사용자에게 노출하는 문자열에
      // "준비 중" 톤이 있으면 미완성 기능처럼 보인다. 주석(// …)은 정책 설명이라
      // 제외하고, 코드 라인만 검사한다.
      final codeLines = File('lib/widgets/premium_gate.dart')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(codeLines.contains('준비 중'), isFalse,
          reason: 'lock placeholder 코드가 "준비 중" 톤 — 미완성 기능처럼 보임');
      expect(codeLines.contains('193'), isFalse);
    });

    test('C2 — playbook 금지 문구 미사용', () {
      const forbidden = [
        '운명을 모두 확인하려면 결제',
        '오늘 안 보면 놓칩니다',
        '곧 가격이 오릅니다',
        '준비 중인 기능까지',
      ];
      for (final f in gateFiles) {
        final src = File(f).readAsStringSync();
        for (final phrase in forbidden) {
          expect(src.contains(phrase), isFalse,
              reason: '$f 에 금지 문구 "$phrase"');
        }
      }
    });
  });
}
