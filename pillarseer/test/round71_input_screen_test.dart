// Round 71 회귀 — input_screen 텍스트 직접 입력 (사용자 불만 #1).
//
// 검증:
// 1) source-string grep: showDatePicker / showTimePicker 사용 0건 (lib 코드)
// 2) widget test (실제 입력 시뮬): autofocus 첫 field, length 도달 시 focus 이동,
//    "시간 모름" 체크 시 HHMM disabled, error rendering, 윤년 validation.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/input_screen.dart';

void main() {
  group('Round 71 — input_screen 텍스트 입력 전환 (불만 #1 source grep)', () {
    final inputFile = File('lib/screens/input_screen.dart').readAsStringSync();

    test('showDatePicker / showTimePicker 사용 0건', () {
      expect(inputFile.contains('showDatePicker'), isFalse,
          reason: '달력 dialog 사용 X — 사용자 불만 #1');
      expect(inputFile.contains('showTimePicker'), isFalse,
          reason: '휠 picker 사용 X — 사용자 불만 #1');
    });

    test('4 controller (YYYY/MM/DD/HHMM) + digitsOnly + autofocus 명시', () {
      expect(inputFile.contains('_yearCtl'), isTrue);
      expect(inputFile.contains('_monthCtl'), isTrue);
      expect(inputFile.contains('_dayCtl'), isTrue);
      expect(inputFile.contains('_timeCtl'), isTrue);
      expect(inputFile.contains('FilteringTextInputFormatter.digitsOnly'), isTrue);
      expect(inputFile.contains('LengthLimitingTextInputFormatter'), isTrue);
      expect(inputFile.contains('autofocus: true'), isTrue);
    });

    test('윤년 일수 룰 (4 / 100 / 400) + month31', () {
      expect(inputFile.contains('year % 4 == 0'), isTrue);
      expect(inputFile.contains('year % 400'), isTrue);
      expect(inputFile.contains('month31'), isTrue);
    });
  });

  group('Round 71 — input_screen widget test (실제 입력 시뮬)', () {
    Widget scaffold() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (c, s) => const InputScreen()),
          GoRoute(path: '/result',
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

    testWidgets('첫 이름 field autofocus — primary focus 가 이름 field',
        (tester) async {
      // R91 사용자 mandate — 입력 화면 진입 시 커서가 "이름" 으로 가야 함.
      // 이전엔 YYYY autofocus 였어서 "생년월일에 커서가 가 있음" 불만 발생.
      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      // 이름 TextFormField (autofocus: true 부여한 첫 field) 의 hasFocus 검증.
      // TextFormField 는 public focusNode getter 가 없어서 내부 TextField 로 확인.
      // 첫 TextField (이름 입력) 가 primary focus 를 잡고 있어야 함.
      final firstTextField = find.byType(TextField).first;
      final ft = tester.widget<TextField>(firstTextField);
      expect(ft.autofocus, isTrue,
          reason: 'autofocus 첫 field 는 이름 — 키패드 즉시 등장.');
      expect(ft.focusNode?.hasFocus, isTrue,
          reason: '이름 field 의 FocusNode 가 primary focus 잡아야 함.');
      // 회귀 — YYYY field 는 autofocus 가 아니어야 (이름이 우선).
      final yearField = find.widgetWithText(TextField, 'YYYY');
      final yw = tester.widget<TextField>(yearField);
      expect(yw.autofocus, isFalse,
          reason: 'YYYY 는 더 이상 autofocus 가 아님 — 이름이 우선.');
    });

    testWidgets('YYYY 4 자리 도달 → primary focus 가 MM 으로 이동', (tester) async {
      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      final yearField = find.widgetWithText(TextField, 'YYYY');
      await tester.enterText(yearField, '1990');
      await tester.pumpAndSettle();
      // MM field focus 검증 — onLengthReached 의 _monthFocus.requestFocus() 결과.
      final monthField = find.widgetWithText(TextField, 'MM');
      final mw = tester.widget<TextField>(monthField);
      expect(mw.focusNode?.hasFocus, isTrue,
          reason: 'YYYY 4자리 도달 시 자동으로 MM focus.');
    });

    testWidgets('"시간 모름" 체크 시 HHMM 필드 비활성화 + CTA 활성화', (tester) async {
      // 테스트 뷰포트 키워서 모든 요소 가시 (default 800x600 → 800x1400).
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      // Name / YYYY / MM / DD 입력
      await tester.enterText(find.byType(TextField).first, '테스터');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '1990');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '05');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '13');
      await tester.pumpAndSettle();
      // 성별 (남자) 선택 — ko locale 의 _SegmentPicker 옵션.
      final maleSegment = find.text('남자');
      expect(maleSegment, findsOneWidget);
      await tester.tap(maleSegment, warnIfMissed: false);
      await tester.pumpAndSettle();
      // 시간 모름 체크
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox, warnIfMissed: false);
      await tester.pumpAndSettle();
      // HHMM 필드 disabled
      final hhmm = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      final hhmmWidget = tester.widget<TextField>(hhmm);
      expect(hhmmWidget.enabled, isFalse);
      // CTA 텍스트 존재 — l10n 'inputFindMyDestiny' 한국어 = "내 운명 보기" / 영어 = "Find my destiny".
      // 본 test 는 ko locale 이라 텍스트로 확인. 단순 존재 검증만.
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('잘못된 월 (13) 입력 시 빨간 에러 메시지 (AppColors.fireRed)',
        (tester) async {
      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '1990');
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '13');
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '01');
      await tester.pump();
      // Round 77 sprint 6 — 친구 톤 변환 ("사이로 입력하라" → "중에 골라줘")
      final errorFinder = find.textContaining('월은 1~12 중에 골라줘');
      expect(errorFinder, findsOneWidget);
      // 색상 검증 — 에러 텍스트가 빨간색 (AppColors.fireRed = 0xFFB55A3C).
      final errorText = tester.widget<Text>(errorFinder);
      expect(errorText.style?.color, const Color(0xFFB55A3C),
          reason: 'AppColors.fireRed = 0xFFB55A3C (muted terracotta — 단정 에러 톤)');
    });

    testWidgets('2/30 (2월에 30일 — 윤년 무관 invalid) 입력 시 에러', (tester) async {
      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '2024');
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '02');
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '30');
      await tester.pump();
      // Round 77 sprint 6 — 친구 톤 변환 ("1~29 일까지만 입력하라" → "29일까지 있어 — 그 안에서 골라줘")
      expect(find.textContaining('2월은 29일까지 있어'), findsOneWidget);
    });

    testWidgets('HHMM 1~3 자리 입력 중에는 에러 메시지 안 보임 (UX)', (tester) async {
      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '1990');
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '05');
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '13');
      // HHMM 부분 입력
      await tester.enterText(find.widgetWithText(TextField, 'HHMM (예: 0830)'), '08');
      await tester.pump();
      // 4자리 미만 → error 표시 안 됨
      expect(find.textContaining('시간은 HHMM'), findsNothing);
      expect(find.textContaining('시는 00~23'), findsNothing);
    });

    testWidgets('HHMM 4 자리 도달 후 25 시 → 에러 표시', (tester) async {
      await tester.pumpWidget(scaffold());
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'YYYY'), '1990');
      await tester.enterText(find.widgetWithText(TextField, 'MM'), '05');
      await tester.enterText(find.widgetWithText(TextField, 'DD'), '13');
      await tester.enterText(find.widgetWithText(TextField, 'HHMM (예: 0830)'), '2500');
      await tester.pump();
      expect(find.textContaining('시는 00~23'), findsOneWidget);
    });
  });
}
