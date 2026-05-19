// R101 Sprint 5 — 전생 시나리오 화면 smoke test.
//
// 검증 (test 환경 rootBundle 한계 회피):
//   1) Source string grep — hero / 라벨 / route / RepaintBoundary / "다시 뽑기" /
//      userName 기본값 "당신" / KO 안내 문구.
//   2) Widget test — me==null → NeedSaju CTA. me!=null → appBar/bottom nav 마운트.
//   3) PastLifeService 단위 — userName="당신" 정상 inject / 다른 seed → 다른 시나리오.
//   4) reports_home 메뉴 최종 순서: past-life(hero) / music-pharmacy / kpop-compat /
//      compatibility / new-year-2026 / dream.
//
// `r101_past_life_keyword_test.dart` 가 PastLifeService 본문 KO leak / seed determinism
// / keyword extraction 의 전면 가드를 이미 수행. 본 smoke 는 화면 layer 만 다룬다.

import 'dart:convert';
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
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // ────────────────── 1. source string grep ──────────────────

  group('past_life_screen.dart — source string grep', () {
    final src =
        File('lib/screens/reports/past_life_screen.dart').readAsStringSync();

    test('hero eyebrow / title / subtitle KO 노출', () {
      expect(src.contains('팬심 1순위 · 전생 인연'), isTrue,
          reason: 'hero eyebrow 누락');
      expect(src.contains('전생의 악연 혹은 인연'), isTrue,
          reason: 'hero title 누락');
      expect(src.contains('합·충·원진살'), isTrue,
          reason: 'hero subtitle 누락');
    });

    test('userName 빈 칸 → "당신" inject helper + 안내 문구', () {
      expect(src.contains(r"raw.isEmpty ? '당신' : raw"), isTrue,
          reason: '빈 이름 → "당신" 기본값 helper 누락');
      expect(src.contains('“당신”'), isTrue, reason: '안내 문구 누락');
    });

    test('다시 뽑기 버튼 + reroll seed 회전 진입점', () {
      expect(src.contains("'다시 뽑기'"), isTrue, reason: '다시 뽑기 라벨 누락');
      expect(src.contains('past_life_reroll_button'), isTrue,
          reason: 'reroll 버튼 key 누락');
      expect(src.contains('reroll: true'), isTrue,
          reason: '_compose(reroll: true) 진입점 누락');
    });

    test('RepaintBoundary 로 결과 카드 감쌈 (sprint 7 공유 대비)', () {
      expect(src.contains('RepaintBoundary'), isTrue,
          reason: 'RepaintBoundary 누락 — 공유 기능 대비 깨짐');
      expect(src.contains('past_life_repaint_boundary'), isTrue,
          reason: 'RepaintBoundary key 누락');
    });

    test('영어 텍스트 leak 0 (화면 라벨)', () {
      // 화면이 한국어 only. 단, dart:convert / try/catch 등 영문 코드는 무관.
      // 사용자 노출 영문 문구 (라벨 / 안내) 가 0 이어야 함.
      const forbiddenInScreen = [
        "'Past Life Scenario'",
        "'reroll'",
      ];
      for (final f in forbiddenInScreen) {
        expect(src.contains(f), isFalse,
            reason: 'screen 라벨에 "$f" 영문 leak');
      }
    });

    test('필수 import / 서비스 호출', () {
      expect(src.contains("PastLifeService.primeCache"), isTrue);
      expect(src.contains("PastLifeService.generate"), isTrue);
      expect(src.contains('sajuResultProvider'), isTrue);
    });

    test('필수 key — name field / search / result body / picker row', () {
      expect(src.contains('past_life_name_field'), isTrue);
      expect(src.contains('past_life_search_field'), isTrue);
      expect(src.contains('past_life_result_body'), isTrue);
      expect(src.contains('past_life_result_card'), isTrue);
      expect(src.contains('past_life_star_row_'), isTrue);
    });
  });

  // ────────────────── 2. reports_home 메뉴 순서 ──────────────────

  group('reports_home_screen.dart — 메뉴 최종 순서', () {
    final src = File('lib/screens/reports/reports_home_screen.dart')
        .readAsStringSync();

    test('순서: past-life → music-pharmacy → kpop-compat → compatibility → new-year-2026 → dream',
        () {
      final idxPast = src.indexOf('/reports/past-life');
      final idxMusic = src.indexOf('/reports/music-pharmacy');
      final idxKpop = src.indexOf('/reports/kpop-compat');
      final idxCompat = src.indexOf('/reports/compatibility');
      final idxNy = src.indexOf('/reports/new-year-2026');
      final idxDream = src.indexOf('/reports/dream');
      for (final pair in [
        ('past-life', idxPast),
        ('music-pharmacy', idxMusic),
        ('kpop-compat', idxKpop),
        ('compatibility', idxCompat),
        ('new-year-2026', idxNy),
        ('dream', idxDream),
      ]) {
        expect(pair.$2 > 0, isTrue,
            reason: '${pair.$1} route 가 reports_home 에 없음');
      }
      expect(idxPast < idxMusic, isTrue,
          reason: '순서 위반: past-life >= music-pharmacy');
      expect(idxMusic < idxKpop, isTrue,
          reason: '순서 위반: music-pharmacy >= kpop-compat');
      expect(idxKpop < idxCompat, isTrue,
          reason: '순서 위반: kpop-compat >= compatibility');
      expect(idxCompat < idxNy, isTrue,
          reason: '순서 위반: compatibility >= new-year-2026');
      expect(idxNy < idxDream, isTrue,
          reason: '순서 위반: new-year-2026 >= dream');
    });

    test('eyebrow 1순위 / 2순위 / 3순위 라벨', () {
      expect(src.contains('팬심 1순위 · 전생 인연'), isTrue,
          reason: '1순위 eyebrow 누락');
      expect(src.contains('팬심 2순위 · 기운 처방'), isTrue,
          reason: '2순위 eyebrow 누락');
      expect(src.contains('팬심 3순위 · 최애 궁합'), isTrue,
          reason: '3순위 eyebrow 누락');
    });

    test('hero badge 가 1순위 (past-life) 라벨', () {
      expect(src.contains("'팬심 1순위 · 전생 인연' : 'FAN PICK · Past Life'"),
          isTrue,
          reason: 'hero badge 가 sprint 5 라벨이 아님');
    });
  });

  // ────────────────── 3. router 진입점 ──────────────────

  group('router.dart — 신규 route 등록', () {
    final src = File('lib/router.dart').readAsStringSync();

    test('past-life + music-pharmacy route + PastLifeScreen 진입점', () {
      expect(src.contains("'/reports/past-life'"), isTrue);
      expect(src.contains("'/reports/music-pharmacy'"), isTrue);
      expect(src.contains('PastLifeScreen()'), isTrue,
          reason: 'PastLifeScreen 진입점 누락');
    });
  });

  // ────────────────── 4. widget test — 사주 없음 / 사주 있음 표면 ──────────────────

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

  group('PastLifeScreen — widget smoke', () {
    testWidgets('사주 없으면 NeedSaju + 사주 입력 CTA', (tester) async {
      await tester.pumpWidget(hostWith());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('사주를 입력'), findsOneWidget);
      expect(find.text('사주 입력하기'), findsOneWidget);
    });

    testWidgets('사주 있으면 appBar / bottom nav 마운트', (tester) async {
      await tester.pumpWidget(hostWith(me: _makeSaju()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // appBar title.
      expect(find.text('전생 · 緣'), findsOneWidget);
      // bottom nav 가 mount.
      expect(find.text('더 보기'), findsOneWidget);
      // me 가 있을 때 NeedSaju 는 노출되면 안 됨.
      expect(find.textContaining('사주를 입력'), findsNothing);
    });
  });

  // ────────────────── 5. PastLifeService — "당신" inject ──────────────────

  group('PastLifeService — userName="당신" inject', () {
    late Map<String, dynamic> pool;

    setUpAll(() async {
      pool = json.decode(
              await File('assets/data/past_life_pool.json').readAsString())
          as Map<String, dynamic>;
    });

    setUp(() {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);
    });

    tearDown(() {
      PastLifeService.resetCacheForTest();
    });

    test('userName="당신" → 본문에 "당신" 포함 + placeholder 잔존 0', () {
      final scenario = PastLifeService.generateScenario(
        user: _makeSaju(),
        celeb: _makeCelebSaju(),
        celebName: '솔라',
        userName: '당신',
        seed: 1,
      );
      expect(scenario.contains('당신'), isTrue,
          reason: '"당신" inject 실패: $scenario');
      expect(scenario.contains(r'$userName'), isFalse);
      expect(scenario.contains(r'$celebName'), isFalse);
      expect(scenario.contains(r'$userRole'), isFalse);
      expect(scenario.contains(r'$celebRole'), isFalse);
    });

    test('다른 seed → 다른 시나리오 (variance 가드)', () {
      final base = PastLifeService.generateScenario(
        user: _makeSaju(),
        celeb: _makeCelebSaju(),
        celebName: '솔라',
        userName: '당신',
        seed: 0,
      );
      var diff = 0;
      for (var s = 1; s <= 10; s++) {
        final other = PastLifeService.generateScenario(
          user: _makeSaju(),
          celeb: _makeCelebSaju(),
          celebName: '솔라',
          userName: '당신',
          seed: s,
        );
        if (other != base) diff++;
      }
      expect(diff, greaterThanOrEqualTo(5),
          reason: 'seed variance 부족: $diff/10');
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

SajuResult _makeCelebSaju() {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '乙', jiJi: '巳'),
    monthPillar: const Pillar(chunGan: '丁', jiJi: '酉'),
    dayPillar: const Pillar(chunGan: '己', jiJi: '未'),
    hourPillar: null,
    elements: const FiveElements(
      wood: 10,
      fire: 10,
      earth: 60,
      metal: 10,
      water: 10,
    ),
    dayMaster: '己',
    dayMasterName: 'Earth Goat',
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
