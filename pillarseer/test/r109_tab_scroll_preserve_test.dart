// Pillar Seer — R109 FIX 2 회귀 가드 — 하단 탭 전환 시 스크롤·상태 보존.
//
// 사용자 mandate (verbatim):
//   "다른 탭을 눌렀다가 다시 돌아갔을때 그 전에 자리가 유지됐으면 좋겠어"
//
// 원인: 4탭이 평범한 GoRoute 라 탭 전환 시 라우트가 교체되며 이전 탭 State 가
//   dispose → 스크롤 리셋.
// 해결: StatefulShellRoute.indexedStack — branch 를 IndexedStack 으로 살려둬
//   탭 전환·복귀 시 스크롤·State 보존.
//
// 검증:
//   A) router.dart 가 StatefulShellRoute.indexedStack 의 4 branch
//      (/home·/result·/reports·/profile) 로 구성됐는지 (source 가드).
//   B) bottom_nav.dart 가 StatefulNavigationShell.goBranch 로 전환하는지.
//   C) StatefulShellRoute 4 branch — branch 0 스크롤 → branch 1 전환 →
//      branch 0 복귀 시 스크롤 위치·State 가 보존되는지 (widget test).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('R109 FIX 2 — A. router StatefulShellRoute 구성 가드', () {
    final routerSrc = File('lib/router.dart').readAsStringSync();

    test('StatefulShellRoute.indexedStack 사용', () {
      expect(routerSrc.contains('StatefulShellRoute.indexedStack'), isTrue,
          reason: '4탭을 StatefulShellRoute.indexedStack 으로 묶어야 함');
    });

    test('4 branch — /home·/result·/reports·/profile 순서', () {
      // 실제 route 정의 = StatefulShellRoute.indexedStack( — 주석이 아닌 마지막.
      final iShell = routerSrc.lastIndexOf('StatefulShellRoute.indexedStack(');
      expect(iShell, greaterThan(0));
      final shellPart = routerSrc.substring(iShell);
      final iHome = shellPart.indexOf("path: '/home'");
      final iResult = shellPart.indexOf("path: '/result'");
      final iReports = shellPart.indexOf("path: '/reports'");
      final iProfile = shellPart.indexOf("path: '/profile'");
      expect(iHome, greaterThan(0), reason: '/home branch 누락');
      expect(iResult, greaterThan(iHome), reason: '/result 가 /home 다음');
      expect(iReports, greaterThan(iResult), reason: '/reports 가 /result 다음');
      expect(iProfile, greaterThan(iReports), reason: '/profile 가 /reports 다음');
    });

    test('shell builder 가 navigationShell 을 _TabShell 로 전달', () {
      expect(routerSrc.contains('_TabShell'), isTrue,
          reason: 'shell builder = _TabShell 위젯');
      expect(
          routerSrc.contains('bottomNavigationBar: PillarBottomNav('), isTrue,
          reason: '_TabShell 이 PillarBottomNav 를 bottomNavigationBar 로');
      expect(routerSrc.contains('body: navigationShell'), isTrue,
          reason: '_TabShell body = navigationShell (IndexedStack)');
    });

    test('상세 화면(/today·/settings·/reports/* 9개)은 shell 밖 top-level', () {
      // shell 밖에 있어야 push 시 shell(branch IndexedStack)이 살아 있음.
      final iShell = routerSrc.lastIndexOf('StatefulShellRoute.indexedStack(');
      for (final detail in const [
        "path: '/today'",
        "path: '/settings'",
        "path: '/reports/compatibility'",
        "path: '/reports/past-life'",
        "path: '/reports/celebrity-saju'",
      ]) {
        final iDetail = routerSrc.indexOf(detail);
        expect(iDetail, greaterThan(0), reason: '$detail 라우트 누락');
        expect(iDetail, lessThan(iShell),
            reason: '$detail 은 shell 밖 top-level 이어야 (push 대상)');
      }
    });

    test('redirect 의 protected 목록 + today_event redirect 보존', () {
      expect(routerSrc.contains("return '/input'"), isTrue,
          reason: 'saju null → /input redirect 보존');
      expect(routerSrc.contains("'today_event'"), isTrue,
          reason: 'today_event anchor redirect 보존');
      expect(routerSrc.contains("return '/today'"), isTrue,
          reason: '/result?anchor=today_event → /today 보존');
    });
  });

  group('R109 FIX 2 — B. bottom_nav goBranch 가드', () {
    final navSrc = File('lib/widgets/bottom_nav.dart').readAsStringSync();

    test('PillarBottomNav 가 StatefulNavigationShell 을 받는다', () {
      expect(navSrc.contains('StatefulNavigationShell navigationShell'), isTrue,
          reason: 'navigationShell 필드 누락');
    });

    test('onTap 이 goBranch 호출 + active = currentIndex', () {
      expect(navSrc.contains('navigationShell.goBranch('), isTrue,
          reason: '탭 onTap = goBranch — 라우트 교체 X, branch 전환');
      expect(navSrc.contains('navigationShell.currentIndex'), isTrue,
          reason: 'active 표시 = currentIndex');
    });

    test('PillarBottomNavStatic — shell 밖 화면용 정적 탭 (context.go)', () {
      // R109 후속 — 리포트 상세 등 shell 밖 화면은 PillarBottomNavStatic 을 쓴다.
      // 이건 의도적으로 activeIdx + context.go 모델 (shell 이 아래 살아 있어 보존됨).
      expect(navSrc.contains('class PillarBottomNavStatic'), isTrue,
          reason: 'shell 밖 화면용 정적 하단 탭 존재');
      expect(navSrc.contains('context.go(_routes[i])'), isTrue,
          reason: 'PillarBottomNavStatic 은 context.go 로 탭 route 이동');
    });
  });

  // ───────────────────────────────────────────────────────────────────
  // C) StatefulShellRoute 4 branch — 탭 전환·복귀 시 스크롤·State 보존.
  //    branch 0 의 스크롤 + 카운터 State 를 만들고, branch 1 로 갔다가
  //    branch 0 으로 돌아왔을 때 둘 다 보존되는지 검증한다.
  // ───────────────────────────────────────────────────────────────────
  group('R109 FIX 2 — C. branch 전환·복귀 시 스크롤·State 보존', () {
    testWidgets('branch 0 스크롤 → branch 1 → branch 0 복귀 = 스크롤·State 유지',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/b0',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => Scaffold(
              body: navigationShell,
              bottomNavigationBar: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: TextButton(
                        key: ValueKey('tab_$i'),
                        onPressed: () => navigationShell.goBranch(
                          i,
                          initialLocation:
                              i == navigationShell.currentIndex,
                        ),
                        child: Text('tab$i'),
                      ),
                    ),
                ],
              ),
            ),
            branches: [
              for (var b = 0; b < 4; b++)
                StatefulShellBranch(routes: [
                  GoRoute(
                    path: '/b$b',
                    builder: (c, s) => _ScrollBranch(branch: b),
                  ),
                ]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // branch 0 — 카운터 +1 (State 변경) + 리스트 스크롤.
      expect(find.text('branch 0 · count 0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('inc_0')));
      await tester.pump();
      expect(find.text('branch 0 · count 1'), findsOneWidget);

      final listFinder = find.byKey(const ValueKey('list_0'));
      await tester.drag(listFinder, const Offset(0, -1200));
      await tester.pump();
      final scrolledOffset =
          tester.widget<Scrollable>(
                find.descendant(
                  of: listFinder,
                  matching: find.byType(Scrollable),
                ),
              ).controller!.offset;
      expect(scrolledOffset, greaterThan(0),
          reason: 'branch 0 리스트가 실제로 스크롤됨');

      // branch 1 로 전환.
      await tester.tap(find.byKey(const ValueKey('tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('branch 1 · count 0'), findsOneWidget);
      expect(find.byKey(const ValueKey('list_0')), findsNothing,
          reason: 'branch 1 화면 — branch 0 리스트는 화면 밖');

      // branch 0 으로 복귀.
      await tester.tap(find.byKey(const ValueKey('tab_0')));
      await tester.pumpAndSettle();

      // ① State(카운터) 보존 — branch 0 의 _ScrollBranchState 가 dispose 안 됨.
      expect(find.text('branch 0 · count 1'), findsOneWidget,
          reason: 'branch 복귀 시 State(카운터) 보존 실패');

      // ② 스크롤 위치 보존.
      final restoredOffset =
          tester.widget<Scrollable>(
                find.descendant(
                  of: find.byKey(const ValueKey('list_0')),
                  matching: find.byType(Scrollable),
                ),
              ).controller!.offset;
      expect(restoredOffset, scrolledOffset,
          reason: 'branch 복귀 시 스크롤 위치 보존 실패');
    });
  });
}

/// 테스트용 branch 화면 — 카운터 State + 스크롤 가능한 긴 리스트.
class _ScrollBranch extends StatefulWidget {
  final int branch;
  const _ScrollBranch({required this.branch});

  @override
  State<_ScrollBranch> createState() => _ScrollBranchState();
}

class _ScrollBranchState extends State<_ScrollBranch> {
  int _count = 0;
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('branch ${widget.branch} · count $_count'),
        TextButton(
          key: ValueKey('inc_${widget.branch}'),
          onPressed: () => setState(() => _count++),
          child: const Text('inc'),
        ),
        Expanded(
          child: ListView.builder(
            key: ValueKey('list_${widget.branch}'),
            controller: _controller,
            itemCount: 80,
            itemBuilder: (c, i) => SizedBox(
              height: 40,
              child: Text('b${widget.branch} row $i'),
            ),
          ),
        ),
      ],
    );
  }
}
