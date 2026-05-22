// R103 Sprint 2 — 전생 화면 스크롤 nested-scroll fix 회귀 가드.
//
// 사용자 mandate verbatim (R103 sprint 0 baseline §3):
//   "이 메뉴도 역시 스크롤이 이상하게 돼"
//
// Baseline 진단 (docs/operating_memory/r103_sprint0_baseline.md §3-2):
//   - past_life_screen.dart L411-420: `_StarPickerList` 안에 nested ListView.separated.
//   - 부모 ListView (L178) + 자식 ListView (L420) → gesture hit-test fight.
//   - 자식의 `Container(height: 260)` fixed height 때문에 부모/자식 사이 swipe 가
//     picker 안에서 소비 → 결과 카드 본문 스크롤이 끊김.
//
// Sprint 2 fix:
//   1) `_StarPickerList` 의 nested `ListView.separated` 에 `shrinkWrap: true` +
//      `physics: NeverScrollableScrollPhysics()` 추가 — gesture 는 부모 ListView 만
//      처리. lazy build 는 ListView.separated builder 가 그대로 유지.
//   2) `Container(height: 260)` fixed height 제거 — picker 가 부모 ListView 안에서
//      flow content 처럼 흐름. 사용자가 picker 영역에서 시작한 드래그가 picker 안에서
//      소비되지 않고 그대로 부모 scroll 로 전달됨.
//   3) 부모 ListView 에 `Key('past_life_primary_scroll')` 키 부여 — single primary
//      scroll 명시.
//   4) `RepaintBoundary` (결과 카드 공유 기능 대비) 는 그대로 유지.
//
// 본 테스트는 (test env rootBundle 한계로 source grep + 표면 widget smoke 중심):
//   - Source string grep — fixed-height 260 제거 / shrinkWrap / NeverScrollable 보존
//   - 207 entries lazy build 보존 (ListView.builder/separated 사용 여부)
//   - widget smoke — me 있을 때 화면이 mount 되고 appBar 가 노출.
//     (rootBundle 가 test 환경에서 assets/data/celebrities.json 을 로딩하지 못해
//     picker body 검증은 source grep 으로 대체. R101 smoke 와 동일 패턴.)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/reports/past_life_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // ─────────────────── 1. source string grep ───────────────────

  group('past_life_screen.dart — R103 sprint 2 scroll fix source grep', () {
    final src = File(
      'lib/screens/reports/past_life_screen.dart',
    ).readAsStringSync();

    test('fixed `height: 260` 제거 — nested scroll trap 제거', () {
      // _StarPickerList Container 의 height: 260 hard-coded 가 picker 의
      // gesture trap 의 한 축. R103 sprint 2 에서 제거.
      expect(
        src.contains('height: 260'),
        isFalse,
        reason: 'fixed Container(height: 260) 가 picker 에 남아 있음 (scroll trap)',
      );
    });

    test('nested ListView 에 shrinkWrap + NeverScrollableScrollPhysics 보존', () {
      // 부모 ListView 단일 primary scroll 을 위해 자식 ListView 는 절대
      // gesture 를 가져가면 안 됨.
      expect(
        src.contains('shrinkWrap: true'),
        isTrue,
        reason: '_StarPickerList nested ListView 에 shrinkWrap 누락',
      );
      expect(
        src.contains('NeverScrollableScrollPhysics'),
        isTrue,
        reason: '_StarPickerList nested ListView 에 NeverScrollable 누락',
      );
    });

    test('207 entries lazy build 보존 — ListView.builder/separated 유지', () {
      // 207 cells 를 Column 으로 한 번에 build 하면 첫 paint 가 무거움.
      // ListView.separated (itemBuilder lazy) 를 그대로 두고 shrinkWrap 만 추가.
      expect(
        src.contains('ListView.separated'),
        isTrue,
        reason: 'picker 가 ListView.separated 가 아님 — lazy build 깨질 위험',
      );
      expect(
        src.contains('itemCount: stars.length'),
        isTrue,
        reason: 'itemCount 누락 — lazy build 안 됨',
      );
    });

    test('parent ListView primary scroll key 부여', () {
      expect(
        src.contains("Key('past_life_primary_scroll')"),
        isTrue,
        reason: '부모 ListView 에 primary scroll key 누락',
      );
    });

    test('picker ListView 에 key 부여 — physics 검증용', () {
      expect(
        src.contains("Key('past_life_star_picker_list')"),
        isTrue,
        reason: 'picker ListView key 누락',
      );
    });

    test('RepaintBoundary 보존 (Sprint 5 공유 기능 대비)', () {
      // R101 sprint 5 에서 추가된 RepaintBoundary 가 scroll fix 때문에
      // 제거되면 안 됨.
      expect(
        src.contains('RepaintBoundary'),
        isTrue,
        reason: 'RepaintBoundary 가 R103 scroll fix 로 제거됨 (회귀)',
      );
      expect(
        src.contains('past_life_repaint_boundary'),
        isTrue,
        reason: 'RepaintBoundary key 누락',
      );
    });

    test('picker 가 부모 ListView 의 자식으로 mount — Scaffold 의 body 가 ListView', () {
      // 부모 ListView 가 SafeArea 안에 mount.
      expect(
        src.contains('Widget _buildBody'),
        isTrue,
        reason: '_buildBody 함수 누락',
      );
      expect(
        src.contains('return ListView('),
        isTrue,
        reason: '부모 ListView 가 아님 — single primary scroll 깨짐',
      );
    });

    test('R103 sprint 2 변경 사유 주석 — 향후 R104+ regress 방지', () {
      // 다음 sprint 가 picker 를 손볼 때 "왜 shrinkWrap + Never 인지" 가 명시되어
      // 있어야 함. 사유 주석이 없으면 다음 세션이 잘못 되돌릴 위험.
      expect(
        src.contains('R103 sprint 2'),
        isTrue,
        reason: 'R103 sprint 2 사유 주석 누락 — future regress 위험',
      );
    });
  });

  // ─────────────────── 2. widget smoke — me 있을 때 화면 mount ───────────────────

  Widget hostWith({SajuResult? me}) {
    final router = GoRouter(
      initialLocation: '/reports/past-life',
      routes: [
        GoRoute(
          path: '/reports/past-life',
          builder: (c, s) => const PastLifeScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (c, s) => const Scaffold(body: Text('reports-home')),
        ),
        GoRoute(
          path: '/input',
          builder: (c, s) => const Scaffold(body: Text('input')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        if (me != null)
          sajuResultProvider.overrideWith(() => _SeedNotifier(me)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('ko'),
      ),
    );
  }

  group('PastLifeScreen — R103 sprint 2 widget smoke', () {
    testWidgets('me 있을 때 appBar 마운트 + 스크롤 fix 후에도 crash 0', (tester) async {
      // R101 smoke 와 동일 패턴 — rootBundle 한계로 picker body 는 mount 안 되지만,
      // appBar / Scaffold 는 mount 됨. R103 변경이 crash 를 일으키지 않음을 가드.
      await tester.pumpWidget(hostWith(me: _makeSaju()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // appBar title.
      expect(
        find.text('전생 · 緣'),
        findsOneWidget,
        reason: 'R103 변경 후 appBar mount 실패 → 화면 crash 회귀',
      );
      // R109 FIX 2 — 리포트 상세는 push 된 full-screen. 하단 탭(shell) 없음.
      expect(find.text('더 보기'), findsNothing);
    });

    testWidgets('me 없을 때 NeedSaju + 사주 입력 CTA — R103 변경이 NeedSaju 회귀 X', (
      tester,
    ) async {
      await tester.pumpWidget(hostWith());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('사주를 입력'), findsOneWidget);
      expect(find.text('사주 입력하기'), findsOneWidget);
    });
  });

  // ─────────────────── 3. integration — R101 smoke 와 공존 ───────────────────

  group('R103 sprint 2 — R101 smoke / R102 회귀 가드', () {
    final src = File(
      'lib/screens/reports/past_life_screen.dart',
    ).readAsStringSync();

    test(
      'R101 sprint 5 key 모두 보존 — name / search / result body / picker row',
      () {
        for (final k in [
          'past_life_name_field',
          'past_life_search_field',
          'past_life_result_body',
          'past_life_result_card',
          'past_life_star_row_',
        ]) {
          expect(
            src.contains(k),
            isTrue,
            reason: 'R101 key "$k" 가 R103 sprint 2 에서 제거됨 (회귀)',
          );
        }
      },
    );

    test('R101 hero / 라벨 보존 + R104 다시 뽑기 부재', () {
      expect(src.contains('팬심 1순위 · 전생 인연'), isTrue);
      expect(src.contains('전생의 악연 혹은 인연'), isTrue);
      // R104 sprint 2 — "다시 뽑기" 는 사용자 mandate 로 제거됨. 보존이 아닌 부재 가드.
      expect(
        src.contains('다시 뽑기'),
        isFalse,
        reason: 'R104: 다시 뽑기 라벨 잔존 (scroll fix 와 무관, 제거 회귀 금지)',
      );
    });

    test('PastLifeService.primeCache / generate 진입점 보존', () {
      expect(src.contains('PastLifeService.primeCache'), isTrue);
      expect(src.contains('PastLifeService.generate'), isTrue);
    });
  });
}

SajuResult _makeSaju() {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
    dayPillar: const Pillar(chunGan: '戊', jiJi: '子'),
    hourPillar: const Pillar(chunGan: '己', jiJi: '未'),
    elements: const FiveElements(
      wood: 20,
      fire: 20,
      earth: 20,
      metal: 20,
      water: 20,
    ),
    dayMaster: '戊',
    dayMasterName: 'Earth Rat',
    summary: 'test',
    categoryReadings: const {},
  );
}

class _SeedNotifier extends SajuResultNotifier {
  _SeedNotifier(this._seed);
  final SajuResult _seed;

  @override
  SajuResult? build() => _seed;
}
