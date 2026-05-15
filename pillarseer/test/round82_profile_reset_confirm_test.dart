// Round 82 sprint 11 — Profile reset confirm 모달 회귀 가드.
//
// 외부 reviewer P1 #7 (verbatim, docs/round82_spec.md §3 sprint 11):
//   "Profile reset 은 바로 provider 를 clear 하고 input 으로 이동. Settings 의
//    'Delete all' 은 confirm dialog 가 있는데 Profile reset 은 더 가볍게 처리됨."
//
// → profile_screen.dart 의 reset _MenuRow onTap 을 즉시 clear 가 아니라
//   `_confirmReset(context, ref, l)` 호출로 변경. AlertDialog 1회 (Settings 의
//   `_confirmDeleteAll` 패턴 일관) 후 "지우기" 분기에서만 기존 reset 동작 실행.
//
// 본 test 의 testable 행동 (B1+B2+B3):
//   B1 — Profile reset row tap 시 AlertDialog 1개 mount, 즉시 provider clear 0.
//   B2 — dialog "취소" tap 시 dialog dismiss + provider 보존 + route 보존.
//   B3 — dialog "지우기" tap 시 provider clear + `/input` 으로 go.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/profile_screen.dart';

void main() {
  group('R82 sprint 11 — Profile reset confirm 모달 회귀 가드', () {
    final src =
        File('lib/screens/profile_screen.dart').readAsStringSync();

    test('S1 — profile_screen.dart 에 즉시 clear 호출 (`onTap: () { ... .clear(); ... }`) 잔존 0',
        () {
      // _MenuRow(label: l.profileReset, ...) 블록 추출.
      final anchor = 'label: l.profileReset';
      final idx = src.indexOf(anchor);
      expect(idx, greaterThan(0),
          reason: 'profile_screen 에 profileReset _MenuRow anchor 누락');
      // anchor 직후 400 char 안에 동기 즉시 clear 패턴 ("onTap: () {" → `clear()`)
      // 잔존 0. confirm dialog 경유는 `onTap: () => _confirmReset(...)` 형태.
      final block = src.substring(idx, idx + 400);
      expect(block.contains('_confirmReset(context, ref, l)'), isTrue,
          reason: 'reset row 가 _confirmReset 으로 dispatch 되지 않음');
      // 즉시 clear pattern (anchor 직후 inline block 안에) 잔존 0.
      // 동기 inline `onTap: () { ref.read(sajuResultProvider...).clear();` 흔적.
      expect(
        block.contains(
            'onTap: () {\n                ref.read(sajuResultProvider'),
        isFalse,
        reason: '즉시 clear 패턴 (dialog 우회) 잔존',
      );
    });

    test('S2 — _confirmReset 함수 정의 + dialog 패턴 (title/desc/cancel/confirm)', () {
      expect(src.contains('Future<void> _confirmReset('), isTrue,
          reason: '_confirmReset 함수 정의 누락');
      expect(src.contains('showDialog<bool>'), isTrue,
          reason: 'showDialog<bool> 패턴 누락');
      expect(src.contains('l.profileResetConfirmTitle'), isTrue,
          reason: 'dialog title l10n key 미사용');
      expect(src.contains('l.profileResetConfirmDesc'), isTrue,
          reason: 'dialog desc l10n key 미사용');
      expect(src.contains('l.profileResetConfirmCta'), isTrue,
          reason: 'dialog confirm CTA l10n key 미사용');
      expect(src.contains('l.modalNotNow'), isTrue,
          reason: 'dialog cancel CTA 기존 modalNotNow 재사용 누락');
      // "지우기" 분기에서만 기존 reset 동작 실행.
      expect(
        src.contains("if (ok != true || !context.mounted) return;"),
        isTrue,
        reason: '"취소" 분기 early-return guard 누락',
      );
      expect(
        src.contains('ref.read(sajuResultProvider.notifier).clear()'),
        isTrue,
        reason: 'sajuResultProvider.clear() 호출 누락',
      );
      expect(
        src.contains('ref.read(userBirthInfoProvider.notifier).clear()'),
        isTrue,
        reason: 'userBirthInfoProvider.clear() 호출 누락',
      );
      expect(src.contains("context.go('/input')"), isTrue,
          reason: '`/input` go 호출 누락');
    });

    testWidgets(
        'B1 — Profile reset row tap → AlertDialog 1개 mount, 즉시 provider clear 0',
        (tester) async {
      // R82 sprint 11 — Profile header Row 가 letter-spacing 5 로 인해 390 폭에서
      // 87px overflow (pre-existing layout, sprint 11 의 fix scope 아님). 본 test
      // 는 reset row + dialog 동작 검증이 scope → 600 폭으로 overflow 회피.
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          sajuResultProvider.overrideWith(_DummySajuNotifier.new),
          userBirthInfoProvider.overrideWith(_DummyBirthInfoNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      // sanity — pre-tap provider state 보존 확인용.
      expect(container.read(sajuResultProvider), isNotNull,
          reason: 'pre-tap sajuResult dummy mount');
      expect(container.read(userBirthInfoProvider), isNotNull,
          reason: 'pre-tap userBirthInfo dummy mount');

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (c, s) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/input',
            builder: (c, s) => const _StubInputScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (c, s) => const _StubInputScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Profile 의 reset row label = `l.profileReset` UPPERCASE = "사주 다시 입력"
      // (한글은 UPPERCASE 변환 no-op). _MenuRow Text 는 한글 그대로 mount.
      final resetLabel = find.text('사주 다시 입력');
      expect(resetLabel, findsOneWidget,
          reason: 'Profile reset row 라벨 mount 누락');

      await tester.tap(resetLabel);
      await tester.pump(); // dialog open
      await tester.pump(const Duration(milliseconds: 200));

      // B1 — AlertDialog 1개 mount.
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'reset row tap 후 AlertDialog 미 mount');
      // dialog title — `profileResetConfirmTitle` ko = "내 사주 입력값을 지울까요?"
      expect(find.text('내 사주 입력값을 지울까요?'), findsOneWidget,
          reason: 'dialog title 본문 누락');

      // 즉시 clear 0 — provider state 보존.
      expect(container.read(sajuResultProvider), isNotNull,
          reason: 'dialog mount 시점에 sajuResult 이미 clear 된 상태 (잘못)');
      expect(container.read(userBirthInfoProvider), isNotNull,
          reason: 'dialog mount 시점에 userBirthInfo 이미 clear 된 상태 (잘못)');
    });

    testWidgets('B2 — dialog "취소" tap → dialog dismiss + provider 보존',
        (tester) async {
      // R82 sprint 11 — Profile header Row 가 letter-spacing 5 로 인해 390 폭에서
      // 87px overflow (pre-existing layout, sprint 11 의 fix scope 아님). 본 test
      // 는 reset row + dialog 동작 검증이 scope → 600 폭으로 overflow 회피.
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          sajuResultProvider.overrideWith(_DummySajuNotifier.new),
          userBirthInfoProvider.overrideWith(_DummyBirthInfoNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (c, s) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/input',
            builder: (c, s) => const _StubInputScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (c, s) => const _StubInputScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('사주 다시 입력'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'B2 precondition: dialog mount');

      // 취소 CTA = `modalNotNow` UPPERCASE = "다음에".
      final cancel = find.text('다음에');
      expect(cancel, findsOneWidget, reason: 'dialog 취소 CTA 라벨 누락');
      await tester.tap(cancel);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // dialog dismiss.
      expect(find.byType(AlertDialog), findsNothing,
          reason: '"취소" tap 후 dialog 미 dismiss');
      // provider 보존.
      expect(container.read(sajuResultProvider), isNotNull,
          reason: '"취소" tap 후 sajuResult 가 clear 됨 (잘못)');
      expect(container.read(userBirthInfoProvider), isNotNull,
          reason: '"취소" tap 후 userBirthInfo 가 clear 됨 (잘못)');
      // route 보존 — Profile reset row 라벨 여전히 mount.
      expect(find.text('사주 다시 입력'), findsOneWidget,
          reason: '"취소" tap 후 Profile route 보존 X');
    });

    testWidgets(
        'B3 — dialog "지우기" tap → provider clear + `/input` 으로 go',
        (tester) async {
      // R82 sprint 11 — Profile header Row 가 letter-spacing 5 로 인해 390 폭에서
      // 87px overflow (pre-existing layout, sprint 11 의 fix scope 아님). 본 test
      // 는 reset row + dialog 동작 검증이 scope → 600 폭으로 overflow 회피.
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          sajuResultProvider.overrideWith(_DummySajuNotifier.new),
          userBirthInfoProvider.overrideWith(_DummyBirthInfoNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (c, s) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/input',
            builder: (c, s) => const _StubInputScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (c, s) => const _StubInputScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('사주 다시 입력'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 지우기 CTA = `profileResetConfirmCta` UPPERCASE = "지우기".
      final confirm = find.text('지우기');
      expect(confirm, findsOneWidget, reason: 'dialog 지우기 CTA 라벨 누락');
      await tester.tap(confirm);
      // dialog dismiss + go('/input') redirect chain.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // dialog dismiss.
      expect(find.byType(AlertDialog), findsNothing,
          reason: '"지우기" tap 후 dialog 미 dismiss');
      // provider clear.
      expect(container.read(sajuResultProvider), isNull,
          reason: '"지우기" tap 후 sajuResult 미 clear');
      expect(container.read(userBirthInfoProvider), isNull,
          reason: '"지우기" tap 후 userBirthInfo 미 clear');
      // /input 으로 이동 — _StubInputScreen mount.
      expect(find.byType(_StubInputScreen), findsOneWidget,
          reason: '"지우기" tap 후 `/input` redirect 누락');
    });
  });
}

/// 사주가 mount 된 상태에서 reset 시나리오를 테스트하기 위한 dummy notifier.
class _DummySajuNotifier extends SajuResultNotifier {
  @override
  SajuResult? build() => SajuResult.dummy();
}

/// 입력 정보가 mount 된 상태에서 reset 시나리오를 테스트하기 위한 dummy notifier.
class _DummyBirthInfoNotifier extends UserBirthInfoNotifier {
  @override
  UserBirthInfo? build() => UserBirthInfo(
        name: '테스트',
        birthDate: DateTime(1995, 10, 27),
        birthHour: 17,
        birthMinute: 0,
        birthCity: '서울',
        isLunar: false,
        isMale: true,
        gender: UserGender.male,
      );
}

/// `/input` 으로 go 후 mount 검증을 위한 stub.
class _StubInputScreen extends StatelessWidget {
  const _StubInputScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('STUB_INPUT')));
}
