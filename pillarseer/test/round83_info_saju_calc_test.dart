// Round 83 sprint 2 — "사주 계산 기준 안내" 페이지 (P1-G) 회귀 가드.
//
// 사용자 verbatim mapping (R83 backlog P1-G):
//   외부 reviewer 권고 = "앱 내 '사주 계산 기준' 설명 페이지 추가 — 진태양시 /
//   자시 학파 / 절기 / 음력 / 도시 경도 명시 → 사용자 신뢰도 transparency"
//
// ── Sprint 계약 = testable 5 행동 ──
//   행동 1 = `lib/screens/info_saju_calc_screen.dart` 파일 존재 + InfoSajuCalcScreen
//     widget export.
//   행동 2 = Settings 화면 widget pump 시 진입점 row 1개 mount (label = settingsCalcBasisRow).
//   행동 3 = InfoSajuCalcScreen widget pump 시 5 영역 label 모두 mount (진태양시 /
//     자시 / 절기 / 음력 / 출생지) + 각 영역 description text mount.
//   행동 4 = 페이지 사용자 노출 본문 (arb key 의 value) 에 한자 jargon noun blacklist
//     단독 노출 0 (본질 / 정수 / 운기 / 운명). 단 사주 도메인 화이트리스트는 OK.
//   행동 5 = 페이지가 쓰는 모든 신규 arb key 가 app_ko.arb + app_en.arb 둘 다 존재.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/info_saju_calc_screen.dart';
import 'package:pillarseer/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R83 sprint 2 — 사주 계산 기준 안내 페이지 (P1-G)', () {
    // 본 sprint 의 신규 arb key 14개. 아래 test 가 그대로 reference.
    const newArbKeys = <String>[
      'settingsCalcBasisRow',
      'settingsCalcBasisRowDesc',
      'infoCalcBasisTitle',
      'infoCalcBasisIntro',
      'infoCalcBasisTrueSunLabel',
      'infoCalcBasisTrueSunDesc',
      'infoCalcBasisJasiLabel',
      'infoCalcBasisJasiDesc',
      'infoCalcBasisSolarTermLabel',
      'infoCalcBasisSolarTermDesc',
      'infoCalcBasisLunarLabel',
      'infoCalcBasisLunarDesc',
      'infoCalcBasisCityLabel',
      'infoCalcBasisCityDesc',
      'infoCalcBasisFooter',
    ];

    // ── 행동 1 — 파일 존재 + 클래스 export ──

    test('행동1.B1 — info_saju_calc_screen.dart 파일 존재 + InfoSajuCalcScreen 클래스 정의',
        () {
      final file = File('lib/screens/info_saju_calc_screen.dart');
      expect(file.existsSync(), isTrue,
          reason: 'info_saju_calc_screen.dart 파일 신규 생성 누락');
      final src = file.readAsStringSync();
      expect(src.contains('class InfoSajuCalcScreen'), isTrue,
          reason: 'InfoSajuCalcScreen 클래스 정의 누락');
      // const constructor — go_router builder 에서 `const InfoSajuCalcScreen()`.
      expect(src.contains('const InfoSajuCalcScreen('), isTrue,
          reason: 'const constructor 누락 → router 등록 const 안 됨');
    });

    test('행동1.B1b — router.dart 에 신규 route 등록 (/settings/saju-calc-basis)', () {
      final src = File('lib/router.dart').readAsStringSync();
      expect(src.contains("path: '/settings/saju-calc-basis'"), isTrue,
          reason: '신규 route path 등록 누락');
      expect(src.contains('InfoSajuCalcScreen()'), isTrue,
          reason: 'router builder 가 InfoSajuCalcScreen 호출 안 함');
    });

    // ── 행동 2 — Settings 진입점 row mount ──

    Widget settingsScaffold() {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
          GoRoute(
              path: '/settings/saju-calc-basis',
              builder: (c, s) => const InfoSajuCalcScreen()),
          GoRoute(
              path: '/profile',
              builder: (c, s) => const Scaffold(body: Text('profile'))),
          GoRoute(
              path: '/input',
              builder: (c, s) => const Scaffold(body: Text('input'))),
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

    testWidgets('행동2.B2 — Settings 화면에 "사주 계산 기준 안내" 진입점 row 1개 mount',
        (tester) async {
      // ListView lazy build → 작은 viewport 에서 row 가 mount 안 될 수 있음.
      // tester.view.physicalSize 를 크게 잡고, scrollUntilVisible 로 row mount 보장.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(settingsScaffold());
      await tester.pumpAndSettle();
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      final rowLabel = ko['settingsCalcBasisRow'] as String;
      // _InfoRow 가 title 을 toUpperCase 한 뒤 Text 표시 → 한글이라 무영향.
      final rowFinder = find.text(rowLabel.toUpperCase());
      // ListView 가 lazy build → row 영역까지 scroll.
      await tester.scrollUntilVisible(rowFinder, 200,
          scrollable: find.byType(Scrollable).first);
      expect(rowFinder, findsWidgets,
          reason: 'Settings 진입점 row label 미발견: "$rowLabel"');
    });

    testWidgets('행동2.B2b — Settings 진입점 row tap 시 InfoSajuCalcScreen 으로 navigate',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(settingsScaffold());
      await tester.pumpAndSettle();
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      final rowLabel = (ko['settingsCalcBasisRow'] as String).toUpperCase();
      final rowFinder = find.text(rowLabel);
      await tester.scrollUntilVisible(rowFinder, 200,
          scrollable: find.byType(Scrollable).first);
      // tap.
      await tester.tap(rowFinder.last);
      await tester.pumpAndSettle();
      // 페이지 title (infoCalcBasisTitle) 등장 확인 (AppBar title).
      final title = (ko['infoCalcBasisTitle'] as String).toUpperCase();
      expect(find.text(title), findsWidgets,
          reason: 'tap 후 InfoSajuCalcScreen title 미발견');
    });

    // ── 행동 3 — 5 영역 label + description mount ──

    Widget pageScaffold() {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('ko'),
          home: const InfoSajuCalcScreen(),
        ),
      );
    }

    testWidgets('행동3.B3 — 5 영역 label 모두 mount (진태양시 / 자시 / 절기 / 음력 / 출생지)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(pageScaffold());
      await tester.pumpAndSettle();
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      // ko value 그대로 mount (한글이라 toUpperCase 영향 없음).
      expect(find.text(ko['infoCalcBasisTrueSunLabel'] as String),
          findsOneWidget,
          reason: '진태양시 영역 라벨 mount 누락');
      expect(find.text(ko['infoCalcBasisJasiLabel'] as String), findsOneWidget,
          reason: '자시 영역 라벨 mount 누락');
      expect(find.text(ko['infoCalcBasisSolarTermLabel'] as String),
          findsOneWidget,
          reason: '절기 영역 라벨 mount 누락');
      expect(find.text(ko['infoCalcBasisLunarLabel'] as String), findsOneWidget,
          reason: '음력 영역 라벨 mount 누락');
      expect(find.text(ko['infoCalcBasisCityLabel'] as String), findsOneWidget,
          reason: '출생지 영역 라벨 mount 누락');
    });

    testWidgets('행동3.B3b — 5 영역 description 모두 mount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(pageScaffold());
      await tester.pumpAndSettle();
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      for (final key in [
        'infoCalcBasisTrueSunDesc',
        'infoCalcBasisJasiDesc',
        'infoCalcBasisSolarTermDesc',
        'infoCalcBasisLunarDesc',
        'infoCalcBasisCityDesc',
      ]) {
        expect(find.text(ko[key] as String), findsOneWidget,
            reason: '$key description mount 누락');
      }
    });

    testWidgets('행동3.B3c — 페이지 intro + footer mount', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(pageScaffold());
      await tester.pumpAndSettle();
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      // intro 는 상단이라 그대로 mount.
      expect(find.text(ko['infoCalcBasisIntro'] as String), findsOneWidget,
          reason: '페이지 intro mount 누락');
      // footer 는 viewport 끝까지 scroll 해서 mount.
      final footerFinder = find.text(ko['infoCalcBasisFooter'] as String);
      await tester.scrollUntilVisible(footerFinder, 200,
          scrollable: find.byType(Scrollable).first);
      expect(footerFinder, findsOneWidget,
          reason: '페이지 footer mount 누락');
    });

    // ── 행동 4 — 사용자 노출 본문 한자 jargon blacklist 0 ──

    test('행동4.B4 — 페이지 ko 본문에 한자 jargon noun blacklist 0', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      // R82 sprint 5 palace_helper_anchor 의 blacklist 와 동일.
      // 사주 도메인 화이트리스트 (사주 / 일주 / 진태양시 / 자시 / 절기 / 음력 /
      // 양력 / 도시 경도 / 일진) 는 본 페이지에서 옆에 1줄 풀이 wire 가 있으므로
      // 허용.
      const jargonBlacklist = <String>[
        '본질',
        '정수',
        '운기',
        '운명', // 단 "당신의 운명" 류는 아예 사용 X — split 후 verbatim 매칭.
      ];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final jargon in jargonBlacklist) {
          expect(v.contains(jargon), isFalse,
              reason: '신규 arb key "$k" 의 ko value 에 한자 jargon "$jargon" 노출: "$v"');
        }
      }
    });

    test('행동4.B4b — 페이지 ko 본문에 AI 슬롭 / Apologetic AI 패턴 0', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      // R82 sprint 3 + sprint 5 의 slop scanner 와 동일 root.
      const slopBlacklist = <String>[
        '죄송하지만',
        '단정 짓기 어렵',
        '말씀드리기 어렵',
        '센터처럼',
        '본인의 결',
        '벼린 칼',
        '도검의 끝',
      ];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final slop in slopBlacklist) {
          expect(v.contains(slop), isFalse,
              reason: '신규 arb key "$k" 의 ko value 에 AI 슬롭 "$slop" 노출: "$v"');
        }
      }
    });

    test('행동4.B4c — 페이지 ko 본문에 의료 단정 phrase 0', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      const medicalBlacklist = <String>['진단', '치료해', '병원 가야', '약 먹어야'];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final med in medicalBlacklist) {
          expect(v.contains(med), isFalse,
              reason: '신규 arb key "$k" 의 ko value 에 의료 단정 "$med" 노출: "$v"');
        }
      }
    });

    test('행동4.B4d — 페이지 ko 본문에 자미두수 별 nameKo 0 (R70 mandate)', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      const starNamesKo = <String>[
        '자미성',
        '천기성',
        '태양성',
        '무곡성',
        '천동성',
        '염정성',
        '천부성',
        '태음성',
        '탐랑성',
        '거문성',
        '천상성',
        '천량성',
        '칠살성',
        '파군성',
        '문창성',
        '문곡성',
        '천괴성',
        '천월성',
        '좌보성',
        '우필성',
        '녹존성',
        '천마성',
      ];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final star in starNamesKo) {
          expect(v.contains(star), isFalse,
              reason:
                  'R70 mandate 위반: arb key "$k" 의 ko value 에 자미두수 별 이름 "$star" leak: "$v"');
        }
      }
    });

    test('행동4.B4e — 페이지 ko 본문에 사주 도메인 어휘 화이트리스트 옆 1줄 풀이 wire',
        () {
      // 화이트리스트 어휘를 사용하는 라벨 (label)/desc 영역에 옆에 1줄 풀이
      // (괄호 안 한자 또는 1줄 친근 본문) 가 같이 등장하는지 검증.
      // - 진태양시 → 라벨 자체가 "진태양시 보정" + desc 에 "태양이 실제 가장 높이
      //   뜨는" 친근 풀이 → desc 가 1줄 풀이.
      // - 자시 → 라벨 "자시 학파 (밤 11시~새벽 1시)" + desc "밤 11시부터 새벽 1시
      //   사이를 자시(子時)" 1줄 풀이.
      // - 절기 / 음력 / 출생지 → desc 가 1줄 풀이.
      // 본 test 는 각 도메인 키워드가 등장하면, 그 영역 desc 가 비어있지 않고
      // 25자 이상 친근 풀이 본문임을 검증.
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      const pairs = <List<String>>[
        ['infoCalcBasisTrueSunLabel', 'infoCalcBasisTrueSunDesc'],
        ['infoCalcBasisJasiLabel', 'infoCalcBasisJasiDesc'],
        ['infoCalcBasisSolarTermLabel', 'infoCalcBasisSolarTermDesc'],
        ['infoCalcBasisLunarLabel', 'infoCalcBasisLunarDesc'],
        ['infoCalcBasisCityLabel', 'infoCalcBasisCityDesc'],
      ];
      for (final pair in pairs) {
        final label = (ko[pair[0]] as String?) ?? '';
        final desc = (ko[pair[1]] as String?) ?? '';
        expect(label.isNotEmpty, isTrue, reason: '${pair[0]} 빈 라벨');
        expect(desc.length >= 25, isTrue,
            reason: '${pair[1]} 친근 1줄 풀이 길이 부족 (25자 미만): "$desc"');
      }
    });

    // ── 행동 5 — 신규 arb key 가 ko + en 둘 다 존재 ──

    test('행동5.B5 — 신규 arb key 가 app_ko.arb + app_en.arb 둘 다 존재', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      for (final k in newArbKeys) {
        expect(ko.containsKey(k), isTrue, reason: 'app_ko.arb 에 key "$k" 누락');
        expect(en.containsKey(k), isTrue, reason: 'app_en.arb 에 key "$k" 누락');
        expect((ko[k] as String).isNotEmpty, isTrue,
            reason: 'app_ko.arb["$k"] 빈 값');
        expect((en[k] as String).isNotEmpty, isTrue,
            reason: 'app_en.arb["$k"] 빈 값');
      }
    });

    test('행동5.B5b — generated app_localizations.dart 에 신규 getter 존재', () {
      final src = File('lib/l10n/app_localizations.dart').readAsStringSync();
      for (final k in newArbKeys) {
        expect(src.contains('String get $k'), isTrue,
            reason: 'app_localizations.dart 에 getter $k 누락 (gen-l10n 실행 필요)');
      }
    });
  });
}
