// R103 sprint 3 — 사주 입력 focus chain 회귀 test.
//
// 사용자 mandate verbatim:
//   "처음 사주입력할때 태어난 날짜치면 자동으로 시간으로 넘어가는데 시간치면 자동으로
//    태어난 지역으로 안넘어가 태어난지역 끝났으면 키보드가 닫혀야하고"
//
// 검증 3종:
//   1) source-string grep — 핵심 wire 가 코드에 존재:
//      - `_cityFocus` FocusNode 선언 + dispose
//      - HHMM `_NumberField` 의 `onLengthReached: () => _cityFocus.requestFocus()`
//      - city `TextFormField` 의 `focusNode: _cityFocus`
//      - city 의 `textInputAction: TextInputAction.done`
//      - city 의 `onFieldSubmitted` 또는 `primaryFocus?.unfocus()`
//   2) widget test — 실제 입력 시뮬:
//      - 날짜 8자 (YYYY+MM+DD) 자동 chain → HHMM focus
//      - HHMM 4자 → city focus 자동 이동 (R103 sprint 3 신규 wire)
//      - city onFieldSubmitted → primary focus null (keyboard dismiss)
//   3) FocusNode list + TextInputAction 자료형 검증

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/input_screen.dart';

void main() {
  group('R103 sprint 3 — focus chain source grep', () {
    final inputFile =
        File('lib/screens/input_screen.dart').readAsStringSync();

    test('_cityFocus FocusNode 선언 + dispose 존재', () {
      // FocusNode 생성 패턴 — `_cityFocus = FocusNode()` 또는 `_cityFocus = FocusNode();`
      expect(inputFile.contains('_cityFocus = FocusNode()'), isTrue,
          reason: 'State class 에 _cityFocus FocusNode 선언 필요 (R103 sprint 3 wire)');
      expect(inputFile.contains('_cityFocus.dispose()'), isTrue,
          reason: 'dispose() 에 _cityFocus.dispose() 필수 — leak 방지');
    });

    test('HHMM onLengthReached → _cityFocus.requestFocus() chain wire', () {
      // 사용자 mandate "시간치면 자동으로 태어난 지역으로 안넘어가" 직발 fix.
      expect(
        inputFile.contains('_cityFocus.requestFocus()'),
        isTrue,
        reason: 'HHMM 4자 도달 시 city focus 로 자동 이동 wire (R103 sprint 3)',
      );
      // baseline `onLengthReached: null` 잔존 0 회귀.
      // (다른 _NumberField 가 null 인 경우는 없지만 baseline bug line 의 null 잔존만 검증)
      expect(
        inputFile.contains('onLengthReached: null'),
        isFalse,
        reason:
            'baseline L331 의 `onLengthReached: null` 가 잔존하면 사용자 mandate fix 가 미적용.',
      );
    });

    test('city TextFormField — focusNode + textInputAction.done + onFieldSubmitted', () {
      expect(inputFile.contains('focusNode: _cityFocus'), isTrue,
          reason: 'city TextFormField 에 focusNode: _cityFocus wire (R103 sprint 3)');
      expect(inputFile.contains('TextInputAction.done'), isTrue,
          reason: 'iOS Done 키 / Android ✓ 키 wire — 사용자 mandate "키보드가 닫혀야"');
      // onFieldSubmitted 또는 onEditingComplete 중 하나 + unfocus 호출 존재.
      final hasSubmittedUnfocus = inputFile.contains('onFieldSubmitted') &&
          inputFile.contains('primaryFocus?.unfocus()');
      expect(hasSubmittedUnfocus, isTrue,
          reason: 'city 입력 후 Done 누르면 keyboard dismiss (R103 sprint 3 mandate)');
    });
  });

  group('R103 sprint 3 — focus chain widget test', () {
    Widget scaffold() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (c, s) => const InputScreen()),
          GoRoute(
              path: '/result',
              builder: (c, s) => const Scaffold(body: Text('result'))),
        ],
      );
      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('ko'),
        ),
      );
    }

    testWidgets('HHMM 4 자리 도달 → city TextFormField 로 focus 이동 (R103 sprint 3)',
        (tester) async {
      // 테스트 viewport 키워서 city field 까지 hit-test 가능하게.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();

      // 날짜 chain: YYYY → MM → DD → HHMM (baseline 작동 검증 회귀)
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '1990');
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '05');
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '13');
      await tester.pumpAndSettle();
      // DD 완료 시 HHMM focus 인지 확인 (baseline L303-305 정상 동작 회귀).
      final hhmm = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      final hhmmW = tester.widget<TextField>(hhmm);
      expect(hhmmW.focusNode?.hasFocus, isTrue,
          reason: 'DD 2자 도달 시 HHMM focus (baseline 회귀)');

      // R103 sprint 3 핵심 검증 — HHMM 4 자리 도달 시 city focus 자동 이동.
      await tester.enterText(hhmm, '0830');
      await tester.pumpAndSettle();

      // city TextFormField 의 focusNode 가 _cityFocus 인지 확인. TextFormField 내부
      // TextField 의 focusNode 가 hasFocus 여야 한다.
      // 'inputBirthCityHelper' hint 가 ko locale 에서는 "예: 서울 / 도쿄 등 (선택)" 비슷.
      // l10n 텍스트는 변할 수 있으므로 ancestor TextField 중 _cityFocus 가 attach 된 것을 찾는다.
      // 더 안전한 방법: 전체 TextField 의 focusNode.hasFocus == true 인 항목 확인.
      final allTfs = find.byType(TextField);
      final focused = allTfs.evaluate().where((el) {
        final w = el.widget as TextField;
        return w.focusNode?.hasFocus == true;
      }).toList();
      expect(focused.length, 1,
          reason: 'HHMM 4자 도달 후 정확히 하나의 TextField 가 focus 를 가져야 함 (city).');
      // focused TextField 는 HHMM 가 아니어야 함 (city 로 이동했어야).
      final focusedTf = focused.single.widget as TextField;
      expect(focusedTf.maxLines == 1 || focusedTf.maxLines == null, isTrue);
      // hint 가 'HHMM' 또는 'YYYY/MM/DD' 인 TextField 는 city 가 아님.
      final hintText = focusedTf.decoration?.hintText ?? '';
      expect(hintText.contains('HHMM'), isFalse,
          reason: 'HHMM 4자 후 focus 는 city 로 넘어가야 함 (HHMM 잔류 X).');
      expect(hintText.contains('YYYY'), isFalse);
      expect(hintText.contains('MM') && hintText.length <= 5, isFalse);
    });

    testWidgets('city TextFormField textInputAction = done (Done 키 wire)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();

      // city TextFormField 의 내부 TextField 를 찾는다 — l10n hint 텍스트로 식별.
      // ko locale: l.inputBirthCityHelper.
      // 우회: 모든 TextField 중 textInputAction == TextInputAction.done 인 항목 1개 존재해야 함.
      final allTfs = find.byType(TextField);
      final doneTfs = allTfs.evaluate().where((el) {
        final w = el.widget as TextField;
        return w.textInputAction == TextInputAction.done;
      }).toList();
      expect(doneTfs.length, greaterThanOrEqualTo(1),
          reason:
              'city TextFormField 에 TextInputAction.done 적용 — iOS Done 키 / Android ✓ 키 mandate');
    });

    testWidgets('city onFieldSubmitted → primary focus null (keyboard dismiss)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();

      // city focus 강제 → 입력 → Done(submit) 시뮬.
      // 1) HHMM 까지 입력 후 자동 chain 으로 city focus.
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '1990');
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '05');
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '13');
      await tester.pumpAndSettle();
      await tester
          .enterText(find.widgetWithText(TextField, 'HHMM (예: 0830)'), '0830');
      await tester.pumpAndSettle();

      // 현재 city focus 상태인지 확인.
      var allTfs = find.byType(TextField);
      var focused = allTfs.evaluate().where((el) {
        final w = el.widget as TextField;
        return w.focusNode?.hasFocus == true;
      }).toList();
      expect(focused.length, 1);
      final cityFocused = focused.single.widget as TextField;
      final cityFocusNode = cityFocused.focusNode!;
      // city 입력.
      await tester.enterText(focused.single.widget == cityFocused
          ? find.byWidget(cityFocused)
          : find.byType(TextField).last, '서울');
      await tester.pumpAndSettle();

      // onFieldSubmitted 호출 시뮬.
      // TextInputAction.done 으로 submitted 발생 → onFieldSubmitted callback → unfocus.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // primary focus 가 city focus 가 아니어야 (unfocused).
      expect(cityFocusNode.hasFocus, isFalse,
          reason: 'Done 액션 후 city focus 가 unfocused — keyboard dismiss mandate');
      // FocusManager.instance.primaryFocus 는 unfocus 후 root FocusScopeNode 일 수 있음.
      // 실제 unfocus 호출 결과는 hasFocus == false 로 충분.
    });
  });
}
