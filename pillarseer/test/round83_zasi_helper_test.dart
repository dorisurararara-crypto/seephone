// Round 83 sprint 4 (P1-B) — 23시 자시 학파 입력 안내 회귀 가드.
//
// 사용자 mandate (외부 reviewer P0 #4):
//   "23시~00:59 출생자는 학파에 따라 일주가 달라질 수 있다는 즉시 안내 + 정자시/야자시
//   선택지 input 안에 노출 (Settings 숨김 X)."
//
// 검증:
//   1) source-string grep — helper widget + ValueKey + 도메인 어휘 1줄 풀이 wire.
//   2) widget test (실제 입력 시뮬) — HH ∈ {23, 00} 일 때만 mount, _unknownTime 시 unmount,
//      학파 inline 옵션 탭 → `sajuSettingsProvider.useLateNightZasi` 토글.
//   3) R71 회귀 가드 보존 (showDatePicker / showTimePicker 0).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/providers/saju_settings_provider.dart';
import 'package:pillarseer/screens/input_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // sajuSettingsProvider 가 SharedPreferences 의존 — mock init 으로 isolate.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Round 83 sprint 4 — input_screen 자시 helper (source grep)', () {
    final inputFile = File('lib/screens/input_screen.dart').readAsStringSync();

    test('_ZasiHelperBlock widget mount + ValueKey 노출', () {
      expect(inputFile.contains('_ZasiHelperBlock'), isTrue,
          reason: 'P1-B: 자시 helper widget mount 필수');
      expect(inputFile.contains("'zasi-helper-block'"), isTrue,
          reason: 'P1-B: helper widget keyId — test 식별');
      expect(inputFile.contains("'zasi-option-early'"), isTrue,
          reason: 'P1-B: 정자시 inline 옵션 keyId');
      expect(inputFile.contains("'zasi-option-late'"), isTrue,
          reason: 'P1-B: 야자시 inline 옵션 keyId');
    });

    test('_isZasiHourEntered helper — HH ∈ {23, 00} && !_unknownTime', () {
      // mount 조건 helper 가 코드 안에 존재 (HH=23 또는 HH=0 조건 명시).
      expect(inputFile.contains('_isZasiHourEntered'), isTrue,
          reason: 'P1-B: mount 조건 helper 명시');
      expect(inputFile.contains('hh == 23 || hh == 0'), isTrue,
          reason: 'P1-B: 자시 = HH 23 또는 00');
      expect(inputFile.contains('if (_unknownTime) return false'), isTrue,
          reason: 'P1-B: 시간 모름 시 helper mount 0');
    });

    test('학파 inline 옵션 → sajuSettingsProvider.setUseLateNightZasi wire', () {
      expect(inputFile.contains('setUseLateNightZasi(false)'), isTrue,
          reason: 'P1-B: 정자시 tap → useLateNightZasi=false');
      expect(inputFile.contains('setUseLateNightZasi(true)'), isTrue,
          reason: 'P1-B: 야자시 tap → useLateNightZasi=true');
    });

    test('R71 회귀 가드 보존 — showDatePicker / showTimePicker 0건', () {
      expect(inputFile.contains('showDatePicker'), isFalse,
          reason: 'R71 회귀: 달력 dialog 사용 X');
      expect(inputFile.contains('showTimePicker'), isFalse,
          reason: 'R71 회귀: 휠 picker 사용 X');
    });
  });

  group('Round 83 sprint 4 — arb 신규 key (ko/en 1줄 풀이 wire)', () {
    test('app_ko.arb 5 신규 key + "정자시" / "야자시" 도메인 어휘', () {
      final ko = File('lib/l10n/app_ko.arb').readAsStringSync();
      expect(ko.contains('inputZasiHelperTitle'), isTrue);
      expect(ko.contains('inputZasiHelperBody'), isTrue);
      expect(ko.contains('inputZasiHelperBoundary'), isTrue);
      expect(ko.contains('inputZasiOptionEarly'), isTrue);
      expect(ko.contains('inputZasiOptionLate'), isTrue);
      // M5 mandate — 사주 도메인 어휘 옆 1줄 평이 풀이 wire.
      expect(ko.contains('정자시'), isTrue,
          reason: 'M5: 정자시 어휘 노출 (옆 1줄 풀이 wire)');
      expect(ko.contains('야자시'), isTrue,
          reason: 'M5: 야자시 어휘 노출 (옆 1줄 풀이 wire)');
      expect(ko.contains('일주'), isTrue,
          reason: 'M5: 일주 어휘 노출 (학파 차이 결과 설명)');
      expect(ko.contains('30분 경계') || ko.contains('30분'), isTrue,
          reason: 'P1-B: 30분 경계 명시 (개발자 용어 boundary 금지 mandate)');
      // 추가 회귀 가드 — 사용자 노출 본문에 개발자 영문 약어 'boundary' / 'mainstream' 0.
      expect(ko.contains('boundary'), isFalse,
          reason: 'spec §0 mandate: 개발자 용어 boundary UI 노출 금지');
      expect(ko.contains('mainstream'), isFalse,
          reason: 'spec §0 mandate: 영문 약어 mainstream UI 노출 금지');
    });

    test('app_en.arb 5 신규 key', () {
      final en = File('lib/l10n/app_en.arb').readAsStringSync();
      expect(en.contains('inputZasiHelperTitle'), isTrue);
      expect(en.contains('inputZasiHelperBody'), isTrue);
      expect(en.contains('inputZasiHelperBoundary'), isTrue);
      expect(en.contains('inputZasiOptionEarly'), isTrue);
      expect(en.contains('inputZasiOptionLate'), isTrue);
    });
  });

  group('Round 83 sprint 4 — widget test (실제 입력 시뮬)', () {
    Widget scaffold(ProviderContainer? container) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (c, s) => const InputScreen()),
          GoRoute(
              path: '/result',
              builder: (c, s) => const Scaffold(body: Text('result'))),
        ],
      );
      return UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('ko'),
        ),
      );
    }

    testWidgets('HH=12 입력 → helper mount 0', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(scaffold(container));
      await tester.pumpAndSettle();

      // HHMM hint 의 TextField 찾아 "1200" 입력.
      final timeField = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      expect(timeField, findsOneWidget);
      await tester.enterText(timeField, '1200');
      await tester.pump();

      expect(find.byKey(const ValueKey('zasi-helper-block')), findsNothing,
          reason: 'HH=12 는 자시 아님 → helper mount 0');
    });

    testWidgets('HH=23 입력 → helper mount + 정자시/야자시 두 옵션 노출',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(scaffold(container));
      await tester.pumpAndSettle();

      final timeField = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      await tester.enterText(timeField, '2330');
      await tester.pump();

      expect(find.byKey(const ValueKey('zasi-helper-block')), findsOneWidget,
          reason: 'HH=23 → helper mount');
      expect(find.byKey(const ValueKey('zasi-option-early')), findsOneWidget,
          reason: '정자시 inline 옵션 노출');
      expect(find.byKey(const ValueKey('zasi-option-late')), findsOneWidget,
          reason: '야자시 inline 옵션 노출');
    });

    testWidgets('HH=23 입력 시 실제 본문에 "정자시" / "야자시" / "일주" 도메인 어휘 노출',
        (tester) async {
      // B 9.7 → 9.9 보강 — source grep 외에 widget tree 의 실제 렌더 본문 검증.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(scaffold(container));
      await tester.pumpAndSettle();

      final timeField = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      await tester.enterText(timeField, '2300');
      await tester.pump();

      // M5 mandate — 사주 도메인 어휘 옆 1줄 평이 풀이 wire 검증.
      expect(find.textContaining('정자시'), findsWidgets,
          reason: 'M5: 정자시 어휘 widget tree 노출');
      expect(find.textContaining('야자시'), findsWidgets,
          reason: 'M5: 야자시 어휘 widget tree 노출');
      expect(find.textContaining('일주'), findsWidgets,
          reason: 'M5: 일주 어휘 widget tree 노출');
      expect(find.textContaining('자시'), findsWidgets,
          reason: 'M5: 자시 어휘 widget tree 노출');

      // spec §0 mandate — 영문 약어 사용자 UI 노출 0 (widget level 회귀 가드).
      expect(find.textContaining('boundary'), findsNothing,
          reason: 'spec §0: boundary 영문 약어 UI 노출 금지');
      expect(find.textContaining('mainstream'), findsNothing,
          reason: 'spec §0: mainstream 영문 약어 UI 노출 금지');
    });

    testWidgets('HH=00 입력 → helper mount', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(scaffold(container));
      await tester.pumpAndSettle();

      final timeField = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      await tester.enterText(timeField, '0030');
      await tester.pump();

      expect(find.byKey(const ValueKey('zasi-helper-block')), findsOneWidget,
          reason: 'HH=00 → 자시 후반 → helper mount');
    });

    testWidgets('학파 옵션 탭 → useLateNightZasi state 토글', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(scaffold(container));
      await tester.pumpAndSettle();

      final timeField = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      await tester.enterText(timeField, '2300');
      await tester.pump();

      // 초기 default = useLateNightZasi=false.
      expect(container.read(sajuSettingsProvider).useLateNightZasi, isFalse);

      // 야자시 옵션 — off-screen 가능성 회피 위해 ensureVisible 후 tap.
      final lateOpt = find.byKey(const ValueKey('zasi-option-late'));
      await tester.ensureVisible(lateOpt);
      await tester.pumpAndSettle();
      await tester.tap(lateOpt);
      await tester.pumpAndSettle();
      expect(container.read(sajuSettingsProvider).useLateNightZasi, isTrue,
          reason: '야자시 tap → state.useLateNightZasi=true');

      // 정자시 옵션 탭.
      final earlyOpt = find.byKey(const ValueKey('zasi-option-early'));
      await tester.ensureVisible(earlyOpt);
      await tester.pumpAndSettle();
      await tester.tap(earlyOpt);
      await tester.pumpAndSettle();
      expect(container.read(sajuSettingsProvider).useLateNightZasi, isFalse,
          reason: '정자시 tap → state.useLateNightZasi=false');
    });

    testWidgets('"시간 모름" 체크 → HHMM clear + helper unmount',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(scaffold(container));
      await tester.pumpAndSettle();

      final timeField = find.widgetWithText(TextField, 'HHMM (예: 0830)');
      await tester.enterText(timeField, '2300');
      await tester.pump();
      expect(find.byKey(const ValueKey('zasi-helper-block')), findsOneWidget,
          reason: '시간 모름 체크 전 — helper mount');

      // "시간 모름" Checkbox 의 onChanged 직접 호출 — 22×22 size tap area 회피.
      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      cb.onChanged?.call(true);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('zasi-helper-block')), findsNothing,
          reason: '시간 모름 = 학파 선택 의미 없음 → helper unmount');
    });
  });
}
