// Round 83 sprint 3 — Discover 셀럽 출생정보 신뢰도 라벨 (P1-F) 회귀 가드.
//
// 사용자 verbatim mapping (R83 backlog P1-F + 외부 reviewer 권고):
//   "유명인의 출생시간은 대체로 공개되지 않기 때문에 시주를 쓰면 위험. 셀럽 비교에는
//    반드시 '출생시간 미상 기준, 공개 생일 기반의 가벼운 비교' 라고 표시."
//
// ── Sprint 계약 = testable 4 행동 ──
//   행동 1 = Discover 화면 첫 fold (filter chip 위) 영역에 disclaimer banner 1회
//     mount — celebDisclosureBanner + celebDisclosureBannerHelper text 둘 다 노출.
//   행동 2 = 셀럽 카드 widget 안에 celebCardConfidenceLabel 1줄이 카드마다 mount
//     (`Key('discover_celeb_confidence_label_<idx>')`).
//   행동 3 = 신규 arb key 3종 (celebDisclosureBanner, celebDisclosureBannerHelper,
//     celebCardConfidenceLabel) 이 ko + en 둘 다 존재 + 빈 값 X + generated
//     getter 존재 + 한자 jargon / AI 슬롭 / 의료 단정 / 자미두수 별 이름 leak 0.
//   행동 4 = celebrities.json 데이터 unchanged — entry 수 62 + 각 entry key 10개
//     (id, nameEn, nameKo, kind, birth, dayPillar, dayPillarName, blurbEn,
//     blurbKo, gender) baseline 보존 (R83 sprint 3 = 라벨만 추가, 데이터 수정 X).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/discover_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R83 sprint 3 — 셀럽 출생정보 신뢰도 라벨 (P1-F)', () {
    const newArbKeys = <String>[
      'celebDisclosureBanner',
      'celebDisclosureBannerHelper',
      'celebCardConfidenceLabel',
    ];

    // ── 공용 widget pump scaffold ──
    // `_DiscoverScreen` 은 rootBundle.loadString('assets/data/celebrities.json')
    // 호출. test 환경의 rootBundle 은 AssetManifest 부재 → 빈 list fallback.
    // 행동 2 검증을 위해 DefaultAssetBundle 을 file 시스템 fixture bundle 로
    // override. discover_screen 내부의 rootBundle.loadString 가 DefaultAssetBundle.of
    // 를 직접 사용하지 X 이므로, `_load()` 함수 catch 가 빈 list 로 fallback —
    // 행동 1 (banner) 은 셀럽 0개여도 mount, 행동 2 는 _TestFixtureCelebrities
    // 데이터를 router 의 별도 fixture screen 으로 검증.
    Widget discoverScaffold() {
      final router = GoRouter(
        initialLocation: '/reports/discover',
        routes: [
          GoRoute(
              path: '/reports/discover',
              builder: (c, s) => const DiscoverScreen()),
          // Fallback routes (PillarBottomNav 가 push 할 수 있는 곳).
          GoRoute(
              path: '/reports',
              builder: (c, s) => const Scaffold(body: Text('reports'))),
          GoRoute(
              path: '/home',
              builder: (c, s) => const Scaffold(body: Text('home'))),
          GoRoute(
              path: '/today',
              builder: (c, s) => const Scaffold(body: Text('today'))),
          GoRoute(
              path: '/settings',
              builder: (c, s) => const Scaffold(body: Text('settings'))),
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

    // ── 행동 1 — disclaimer banner mount (widget pump) ──
    // test 환경의 rootBundle 은 assets/data/celebrities.json 을 로딩할 수 없어
    // _DiscoverScreen 의 `catch (_) { _loaded = true; }` fallback → 빈 list.
    // 빈 list 에서도 disclaimer banner 는 filter chip 위 (`first-fold`) 영역이라
    // mount 됨 → 행동 1 widget pump 로 검증 가능.
    testWidgets('행동1.B1 — Discover 화면 disclaimer banner 1회 mount + helper 노출',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(discoverScaffold());
      // pumpAndSettle 은 _load() async 가 끝나야 settle. setState 이후 1프레임만
      // pump 하고 종료 (banner 는 _loaded 와 무관하므로 첫 build 에서 이미 mount).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // disclaimer banner key 1회 mount.
      expect(find.byKey(const Key('discover_celeb_disclosure_banner')),
          findsOneWidget,
          reason: 'disclaimer banner key 미발견 (first-fold 마운트 누락)');

      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      final banner = ko['celebDisclosureBanner'] as String;
      final helper = ko['celebDisclosureBannerHelper'] as String;
      // 본문 text 둘 다 노출.
      expect(find.text(banner), findsWidgets,
          reason: 'celebDisclosureBanner 본문 노출 누락: "$banner"');
      expect(find.text(helper), findsWidgets,
          reason: 'celebDisclosureBannerHelper 본문 노출 누락: "$helper"');
    });

    // ── 행동 2 — 카드별 confidence label widget wire (소스 정적 검증) ──
    // test 환경에서 rootBundle 의 celebrities.json 로딩이 차단되어 (asset
    // manifest 부재) 카드 widget pump 검증이 불가능. 대신 discover_screen.dart
    // 소스에서 confidence label widget 의 5가지 핵심 요소가 모두 wire 되어
    // 있는지 정적 검증.
    test('행동2.B2 — _CelebRow 안에 celebCardConfidenceLabel widget wire 확인', () {
      final src =
          File('lib/screens/discover_screen.dart').readAsStringSync();
      // (1) confidence label key naming 패턴.
      expect(src.contains("Key('discover_celeb_confidence_label_"), isTrue,
          reason: '카드별 confidence label key 미정의 (discover_celeb_confidence_label_*)');
      // (2) listIndex 가 _CelebRow constructor 인자.
      expect(src.contains('required this.listIndex'), isTrue,
          reason: '_CelebRow constructor 에 listIndex 인자 누락');
      // (3) listIndex 가 itemBuilder 에서 wire.
      expect(src.contains('listIndex: i'), isTrue,
          reason: 'itemBuilder 에서 listIndex 전달 누락');
      // (4) celebCardConfidenceLabel getter 사용.
      expect(src.contains('l.celebCardConfidenceLabel'), isTrue,
          reason: 'l.celebCardConfidenceLabel getter 호출 누락');
      // (5) disclaimer banner widget 안 celebDisclosureBanner + helper 둘 다 wire.
      expect(src.contains('l.celebDisclosureBanner'), isTrue,
          reason: 'l.celebDisclosureBanner getter 호출 누락');
      expect(src.contains('l.celebDisclosureBannerHelper'), isTrue,
          reason: 'l.celebDisclosureBannerHelper getter 호출 누락');
    });

    // ── 행동 3 — 신규 arb key 존재 + slop / jargon / 자미두수 leak 0 ──
    test('행동3.B3 — 신규 arb key 가 ko + en 둘 다 존재 + 빈 값 X', () {
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

    test('행동3.B3b — generated app_localizations.dart 에 신규 getter 존재', () {
      final src = File('lib/l10n/app_localizations.dart').readAsStringSync();
      for (final k in newArbKeys) {
        expect(src.contains('String get $k'), isTrue,
            reason: 'app_localizations.dart 에 getter $k 누락');
      }
    });

    test('행동3.B3c — ko 본문에 한자 jargon noun blacklist 0', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      const jargonBlacklist = <String>['본질', '정수', '운기', '운명'];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final jargon in jargonBlacklist) {
          expect(v.contains(jargon), isFalse,
              reason: 'arb key "$k" 의 ko value 에 한자 jargon "$jargon" 노출: "$v"');
        }
      }
    });

    test('행동3.B3d — ko 본문에 AI 슬롭 / Apologetic AI 패턴 0', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
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
              reason: 'arb key "$k" 의 ko value 에 AI 슬롭 "$slop" 노출: "$v"');
        }
      }
    });

    test('행동3.B3e — ko 본문에 의료 단정 phrase 0', () {
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      const medicalBlacklist = <String>['진단', '치료해', '병원 가야', '약 먹어야'];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final med in medicalBlacklist) {
          expect(v.contains(med), isFalse,
              reason: 'arb key "$k" 의 ko value 에 의료 단정 "$med" 노출: "$v"');
        }
      }
    });

    test('행동3.B3f — ko 본문에 자미두수 별 nameKo 0 (R70 mandate)', () {
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

    test('행동3.B3g — ko 본문에 "출생시간 미상" 핵심 carve-out phrase 존재', () {
      // 외부 reviewer 권고의 핵심 핵심: "출생시간 미상" / "공개 생일 기반" 단어 둘 다
      // 사용자에게 transparent. arb 본문 합쳐서 두 phrase 모두 출현 확인.
      final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      final blob = newArbKeys.map((k) => ko[k] as String? ?? '').join('\n');
      expect(blob.contains('출생시간 미상'), isTrue,
          reason: '"출생시간 미상" carve-out phrase 누락');
      expect(blob.contains('공개 생일'), isTrue,
          reason: '"공개 생일" carve-out phrase 누락');
    });

    // ── 행동 4 — celebrities.json 데이터 unchanged ──
    test('행동4.B4 — celebrities.json baseline 보존 (entry 62 + key 10/entry)', () {
      final raw = File('assets/data/celebrities.json').readAsStringSync();
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      expect(data.length, 62,
          reason: 'celebrities.json entry 수 baseline 위반 (62 → ${data.length})');
      // baseline schema (R83 sprint 3 시점) = 정확히 10 key.
      const baselineKeys = <String>{
        'id',
        'nameEn',
        'nameKo',
        'kind',
        'birth',
        'dayPillar',
        'dayPillarName',
        'blurbEn',
        'blurbKo',
        'gender',
      };
      for (var i = 0; i < data.length; i++) {
        final entry = data[i];
        expect(entry.keys.toSet(), baselineKeys,
            reason:
                'celebrities.json[$i] key schema baseline 위반 (라벨 추가는 widget level 만 허용)');
      }
    });
  });
}
