// R105 Sprint 1 + Sprint 4 — 최애의 사주 화면 / route / 메뉴 가드 + UX polish.
//
// 검증:
//   1) router 에 /reports/celebrity-saju route + CelebritySajuScreen 진입점.
//   2) /reports/celebrity-saju 는 protected 목록 밖 (사용자 사주 불필요).
//   3) reports_home 에 팬심 4순위 카드가 kpop-compat 카드 바로 아래.
//   4) 화면 source — hero / 검색 / picker / "다른 최애 고르기" / reroll 없음 /
//      영문 라벨 leak 0.
//   5) widget smoke — 사주 없어도 접근 가능 (NeedSaju 없음), appBar mount.
//   6) Sprint 4 — 결과 카드 7섹션 라벨 / 사주 차트(時 칸 "—") / RepaintBoundary /
//      loading·error·empty state / curated-only.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/reports/celebrity_saju_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('router.dart — celebrity-saju route', () {
    final src = File('lib/router.dart').readAsStringSync();

    test('/reports/celebrity-saju route + CelebritySajuScreen 진입점', () {
      expect(src.contains("'/reports/celebrity-saju'"), isTrue);
      expect(
        src.contains('CelebritySajuScreen()'),
        isTrue,
        reason: 'CelebritySajuScreen 진입점 누락',
      );
    });

    test('celebrity-saju 는 protected 목록 밖 (사용자 사주 불필요)', () {
      // protected 배열 안에 celebrity-saju 가 들어가면 안 된다.
      final protectedStart = src.indexOf('const protected = [');
      final protectedEnd = src.indexOf('];', protectedStart);
      expect(protectedStart, greaterThan(0));
      final block = src.substring(protectedStart, protectedEnd);
      expect(
        block.contains("'/reports/celebrity-saju'"),
        isFalse,
        reason: 'celebrity-saju 가 protected 에 들어감 — 사주 없이도 접근 가능해야 함',
      );
    });
  });

  group('reports_home_screen.dart — 팬심 4순위 카드', () {
    final src = File(
      'lib/screens/reports/reports_home_screen.dart',
    ).readAsStringSync();

    test('팬심 4순위 카드 + route 존재', () {
      expect(src.contains('팬심 4순위 · 최애의 사주'), isTrue, reason: '4순위 eyebrow 누락');
      expect(
        src.contains('/reports/celebrity-saju'),
        isTrue,
        reason: 'route 누락',
      );
    });

    test('카드 순서 — celebrity-saju 가 kpop-compat 바로 아래', () {
      final idxKpop = src.indexOf('/reports/kpop-compat');
      final idxCeleb = src.indexOf('/reports/celebrity-saju');
      final idxCompat = src.indexOf('/reports/compatibility');
      expect(idxKpop, greaterThan(0));
      expect(idxCeleb, greaterThan(0));
      expect(idxCompat, greaterThan(0));
      expect(
        idxKpop < idxCeleb,
        isTrue,
        reason: '순서 위반: kpop-compat >= celebrity-saju',
      );
      expect(
        idxCeleb < idxCompat,
        isTrue,
        reason: '순서 위반: celebrity-saju >= compatibility',
      );
    });
  });

  group('celebrity_saju_screen.dart — source skeleton', () {
    final src = File(
      'lib/screens/reports/celebrity_saju_screen.dart',
    ).readAsStringSync();

    test('hero / 검색 / picker / 결과 key', () {
      expect(
        src.contains('팬심 4순위 · 최애의 사주'),
        isTrue,
        reason: 'hero eyebrow 누락',
      );
      expect(src.contains('내 최애는 어떤 사주일까'), isTrue, reason: 'hero title 누락');
      expect(src.contains('celebrity_saju_search_field'), isTrue);
      expect(src.contains('celebrity_saju_picker_list'), isTrue);
      expect(src.contains('celebrity_saju_result_card'), isTrue);
      expect(src.contains('celebrity_saju_result_body'), isTrue);
      expect(src.contains('celebrity_saju_row_'), isTrue);
    });

    test('past_life picker 패턴 — 다른 최애 고르기 + reroll/random 없음', () {
      expect(
        src.contains('celebrity_saju_choose_other_button'),
        isTrue,
        reason: '다른 최애 고르기 버튼 key 누락',
      );
      expect(src.contains('다른 최애 고르기'), isTrue, reason: '다른 최애 고르기 라벨 누락');
      // reroll / 다시 뽑기 / random 진입점이 없어야 한다.
      expect(src.contains('다시 뽑기'), isFalse, reason: 'reroll 라벨 잔존');
      expect(src.contains('reroll'), isFalse, reason: 'reroll 진입점 잔존');
      expect(src.contains('Random()'), isFalse, reason: 'random 셀럽 진입점 잔존');
    });

    test('영문 라벨 leak 0 (사용자 노출 문구)', () {
      const forbidden = ["'Bias Saju'", "'My Bias", "Text('Past Life"];
      // R110 Sprint 2 — `useKo ? '한글' : '영문'` 처럼 로케일 분기된 줄은 leak
      // 이 아니다(KO 모드에서 영문이 노출되지 않음). 분기 안 된 영문만 잡는다.
      final lines = src
          .split('\n')
          .where((l) => !l.contains('useKo ?') && !l.contains('useKo?'))
          .join('\n');
      for (final f in forbidden) {
        expect(lines.contains(f), isFalse, reason: '화면 라벨에 "$f" 영문 leak');
      }
    });

    test('Sprint 4 — 결과 카드 7섹션 라벨 매핑', () {
      // _sectionLabelKo 가 7개 section id 를 한국어 라벨로 매핑한다.
      for (final id in const [
        'opening',
        'day_core',
        'month_year_frame',
        'ten_gods_flow',
        'verified_trace',
        'fan_takeaway',
        'closing',
      ]) {
        expect(src.contains("'$id'"), isTrue, reason: '섹션 라벨 매핑에 $id 누락');
      }
      // _CelebSection 모델이 id + bodyKo 를 보존.
      expect(src.contains('class _CelebSection'), isTrue);
      expect(src.contains('_sectionLabelKo'), isTrue);
    });

    test('Sprint 4 — 사주 차트 + 時 칸 "—" (시각 추정 금지)', () {
      expect(src.contains('celebrity_saju_chart'), isTrue, reason: '차트 key 누락');
      // 4번째 칸은 시주 — 항상 "—". 출생 시각 추정 표현 없음.
      expect(
        src.contains("_PillarChip(label: '시주', pillar: '—'"),
        isTrue,
        reason: '시주 칸이 "—" 고정이 아님',
      );
      // 일간 / 오행 요약 라벨.
      expect(src.contains('일간'), isTrue);
      expect(src.contains('출생 시(時) 미상'), isTrue);
    });

    test('Sprint 4 — 공유 영역 RepaintBoundary', () {
      expect(
        src.contains('celebrity_saju_repaint_boundary'),
        isTrue,
        reason: 'RepaintBoundary key 누락',
      );
      expect(src.contains('RepaintBoundary('), isTrue);
    });

    test('Sprint 4 — loading / error / empty state 분기', () {
      expect(src.contains('enum _LoadState'), isTrue, reason: 'state enum 누락');
      expect(src.contains('_LoadState.loading'), isTrue);
      expect(src.contains('_LoadState.error'), isTrue);
      expect(src.contains('_LoadState.ready'), isTrue);
      // 에러 상태 재시도 CTA.
      expect(src.contains('celebrity_saju_error'), isTrue);
      expect(src.contains('celebrity_saju_retry_button'), isTrue);
      expect(src.contains('다시 시도'), isTrue);
    });

    test('Sprint 4 — curated 수 안내 + 선택 시 검색어 reset', () {
      expect(src.contains('celebrity_saju_curated_count'), isTrue);
      expect(src.contains('풀이가 준비된 최애'), isTrue);
      // 선택 시 검색어/필드 초기화 → 다시 picker 진입 시 전체 목록.
      expect(src.contains('_searchCtl.clear()'), isTrue);
    });
  });

  // ── widget smoke — 사주 없이도 접근 가능 ──
  Widget host() {
    final router = GoRouter(
      initialLocation: '/reports/celebrity-saju',
      routes: [
        GoRoute(
          path: '/reports/celebrity-saju',
          builder: (c, s) => const CelebritySajuScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (c, s) => const Scaffold(body: Text('reports-home')),
        ),
        GoRoute(
          path: '/home',
          builder: (c, s) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/today',
          builder: (c, s) => const Scaffold(body: Text('today')),
        ),
        GoRoute(
          path: '/settings',
          builder: (c, s) => const Scaffold(body: Text('settings')),
        ),
      ],
    );
    // sajuResultProvider override 없음 — 사용자 사주 null 상태.
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('ko'),
      ),
    );
  }

  group('CelebritySajuScreen — widget smoke', () {
    testWidgets('사주 없어도 appBar mount + NeedSaju 없음', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // appBar title.
      expect(find.text('최애의 사주'), findsWidgets);
      // R109 후속 — 리포트 상세는 push full-screen 이지만 정적 하단 탭
      // (PillarBottomNavStatic) 을 단다. '더 보기'(리포트 탭 라벨) 노출.
      expect(find.text('더 보기'), findsOneWidget);
      // 사주 입력 강제 CTA 가 없어야 한다 (사용자 사주 불필요).
      expect(find.textContaining('사주를 입력'), findsNothing);
    });

    testWidgets('로딩 중에는 spinner — bootstrap 비동기 IO 진입', (tester) async {
      // _bootstrap 의 rootBundle.loadString 는 실제 비동기 IO — flutter_test
      // 의 frame pump 만으로는 완료되지 않는다 (runAsync 필요). 따라서 여기서는
      // 첫 frame 에 로딩 spinner 가 뜨고 화면이 깨지지 않음만 확인한다.
      // curated 0개 → 준비중 hint 노출 로직은 아래 source skeleton 그룹에서 가드.
      await tester.pumpWidget(host());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 사용자 사주 없이도 NeedSaju CTA 가 강제되지 않는다.
      expect(find.textContaining('사주를 입력'), findsNothing);
    });
  });

  // ── curated-only 노출 로직 source 가드 ──
  // (rootBundle 비동기 IO 가 flutter_test frame 만으로 안 풀려 widget 검증 대신
  //  source 로 가드. 실제 hint mount 는 실기기 / runAsync 통합 테스트에서 확인.)
  group('celebrity_saju_screen.dart — curated-only hint 로직', () {
    final src = File(
      'lib/screens/reports/celebrity_saju_screen.dart',
    ).readAsStringSync();

    test('emptyCurated → 준비중 안내 hint key + copy', () {
      expect(src.contains('celebrity_saju_empty_hint'), isTrue);
      expect(
        src.contains('최애의 사주 풀이를 준비하고 있어요'),
        isTrue,
        reason: 'curated 0개 안내 copy 누락',
      );
      // _CelebPickerList 가 emptyCurated 분기를 가짐.
      expect(src.contains('emptyCurated'), isTrue);
    });
  });
}
