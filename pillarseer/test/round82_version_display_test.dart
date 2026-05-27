// Round 82 sprint 12 — version 하드코딩 제거 + package_info_plus 동적 로드 가드.
//
// 외부 reviewer P1 #8 (verbatim, docs/round82_spec.md §3 sprint 12):
//   "Settings 에는 version 이 1.0.0 으로 하드코딩, pubspec 은 1.0.0+40.
//    package_info_plus 로 실제 버전/빌드 번호를 읽어야 함."
// (R82 baseline lock; R85 에서 1.0.0+42 로 build 번호 lock 갱신 — sprint 시그니처 동일.)
//
// → settings_screen.dart 의 `_ValueRow(label: l.settingsVersion, value: '1.0.0')`
//   하드코딩 string 을 FutureBuilder<PackageInfo> + AppVersionService.formatLabel
//   조합으로 교체. PackageInfo.fromPlatform() 결과는 AppVersionService 가
//   single-flight cache 로 관리.
//
// 본 test 의 testable 행동 (S1+S2+B1+B2):
//   S1 — settings_screen.dart 에 `'1.0.0'` literal grep 0 (label value 분리).
//   S2 — package_info_plus import + AppVersionService.load 호출 wire 잔존.
//   B1 — AppVersionService.formatLabel(ko=true, build=45)  = "버전 1.0.0 · 빌드 45".
//   B2 — Settings widget mount + mock PackageInfo 도착 후 동적 label 표시.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/settings_screen.dart';
import 'package:pillarseer/services/app_version_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R82 sprint 12 — version 하드코딩 제거 + package_info_plus 회귀 가드', () {
    final settingsSrc =
        File('lib/screens/settings_screen.dart').readAsStringSync();
    final pubspecSrc = File('pubspec.yaml').readAsStringSync();

    test('S1 — settings_screen.dart 전체에 `1.0.0` 하드코딩 literal 잔존 0',
        () {
      // 기존 패턴 `_ValueRow(label: l.settingsVersion, value: '1.0.0')`
      // 잔존 0. value 는 동적 로드 (snap.data + formatLabel) 로 와야 함.
      expect(
        settingsSrc.contains("value: '1.0.0'"),
        isFalse,
        reason: 'value 영역에 `1.0.0` 하드코딩 잔존 — package_info_plus 미 wire',
      );
      // settingsVersion row 자체는 유지 (deletion 회피).
      expect(
        settingsSrc.contains('l.settingsVersion'),
        isTrue,
        reason: 'settingsVersion l10n key 사용 누락',
      );
      // codex round 1 reviewer 추가 mandate — file 전체 grep "1.0.0" literal 0
      // (주석/문자열 어디에도 잔존 X). 운영 시 pubspec version 가 바뀌어도 코드
      // 변경 0 보장.
      expect(
        settingsSrc.contains('1.0.0'),
        isFalse,
        reason: 'settings_screen.dart 어디에도 `1.0.0` literal 잔존 0 — '
            '주석 예시도 일반 표현 (X.Y.Z) 으로 교체 필요',
      );
    });

    test('S2 — package_info_plus import + AppVersionService.load 호출 wire', () {
      expect(
        settingsSrc.contains(
            "import 'package:package_info_plus/package_info_plus.dart'"),
        isTrue,
        reason: 'package_info_plus import 누락',
      );
      expect(
        settingsSrc.contains("import '../services/app_version_service.dart'"),
        isTrue,
        reason: 'AppVersionService import 누락',
      );
      expect(
        settingsSrc.contains('FutureBuilder<PackageInfo>'),
        isTrue,
        reason: 'FutureBuilder<PackageInfo> wire 누락',
      );
      expect(
        settingsSrc.contains('AppVersionService.load()'),
        isTrue,
        reason: 'AppVersionService.load() 호출 누락',
      );
      expect(
        settingsSrc.contains('AppVersionService.formatLabel'),
        isTrue,
        reason: 'AppVersionService.formatLabel 호출 누락',
      );
      // pubspec dependency 도 staged 되어야 함.
      expect(
        pubspecSrc.contains('package_info_plus:'),
        isTrue,
        reason: 'pubspec dependency 누락',
      );
      // pubspec version 자체 — ship target. ⚠️ 매 ship 마다 갱신 필요한 핀(트랩).
      // R96 '1.0.0+57' → ... → R108 '1.0.0+73' → R110 '1.0.0+75' → R110 +76 → R111 +77 Apple 4.3a appeal resubmit.
      expect(
        pubspecSrc.contains('version: 1.0.0+77'),
        isTrue,
        reason: 'pubspec version (1.0.0+77) 자체 변경 — R111 Apple 4.3a appeal resubmit 불일치',
      );
    });

    test('B1 — formatLabel(ko, version=1.0.0, build=45) = "버전 1.0.0 · 빌드 45"',
        () {
      // PackageInfo 직접 생성. (constructor public — package_info_plus 4.x+)
      final info = PackageInfo(
        appName: 'pillarseer',
        packageName: 'com.ganziman.pillarseer',
        version: '1.0.0',
        buildNumber: '45',
      );
      expect(
        AppVersionService.formatLabel(info, useKo: true),
        '버전 1.0.0 · 빌드 45',
      );
      expect(
        AppVersionService.formatLabel(info, useKo: false),
        'Version 1.0.0 (build 45)',
      );
    });

    test('B1b — formatLabel build 비어 있으면 build 토큰 생략', () {
      final infoNoBuild = PackageInfo(
        appName: 'pillarseer',
        packageName: 'com.ganziman.pillarseer',
        version: '1.0.0',
        buildNumber: '',
      );
      expect(
        AppVersionService.formatLabel(infoNoBuild, useKo: true),
        '버전 1.0.0',
      );
      expect(
        AppVersionService.formatLabel(infoNoBuild, useKo: false),
        'Version 1.0.0',
      );
    });

    testWidgets(
        'B2 — Settings widget mount + mock PackageInfo 도착 후 "버전 1.0.0 · 빌드 45" 표시',
        (tester) async {
      // R82 baseline — Settings ListView 는 393 폭에서 letter-spacing 5 영향
      // _SettingsGroup 라벨이 overflow 가능. 본 test 는 version row 라벨만 검증
      // → 600 폭으로 회피.
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // PackageInfo mock — pubspec 의 1.0.0+45 매칭 (R86 sprint 4 lock 갱신).
      PackageInfo.setMockInitialValues(
        appName: 'pillarseer',
        packageName: 'com.ganziman.pillarseer',
        version: '1.0.0',
        buildNumber: '45',
        buildSignature: '',
        installerStore: null,
      );
      AppVersionService.resetForTest();
      addTearDown(AppVersionService.resetForTest);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (c, s) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (c, s) => const _StubScreen(),
          ),
          GoRoute(
            path: '/input',
            builder: (c, s) => const _StubScreen(),
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
      // mount + future microtask 처리.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Settings ListView 의 ABOUT (정보) group 은 list 끝 영역. lazy mount 회피
      // 위해 scrollUntilVisible 로 version row 까지 스크롤.
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget,
          reason: 'Settings ListView mount 누락');
      final versionLabelFinder = find.text('버전');
      await tester.scrollUntilVisible(
        versionLabelFinder,
        200,
        scrollable: find.descendant(
          of: listFinder,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 동적 value — "버전 1.0.0 · 빌드 45" mount.
      expect(
        find.text('버전 1.0.0 · 빌드 45'),
        findsOneWidget,
        reason: 'PackageInfo mock 도착 후 동적 label 미 표시',
      );
      // 하드코딩 "1.0.0" 단독 텍스트 잔존 0 (value Text widget).
      expect(
        find.text('1.0.0'),
        findsNothing,
        reason: '하드코딩 "1.0.0" Text 잔존',
      );
    });
  });
}

class _StubScreen extends StatelessWidget {
  const _StubScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('STUB')));
}
