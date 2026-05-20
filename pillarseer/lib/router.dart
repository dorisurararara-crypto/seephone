import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/today_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reports/reports_home_screen.dart';
import 'screens/reports/compatibility_screen.dart';
import 'screens/reports/tojeong_screen.dart';
import 'screens/reports/date_picking_screen.dart';
import 'screens/reports/dream_screen.dart';
import 'screens/reports/new_year_2026_screen.dart';
import 'screens/reports/kpop_compat_screen.dart';
import 'screens/reports/past_life_screen.dart';
import 'screens/reports/music_pharmacy_screen.dart';
import 'screens/reports/celebrity_saju_screen.dart';
import 'providers/saju_provider.dart';

/// 전역 라우터. extra 의존 제거.
/// SajuResult 가 null 이면 /input 으로 redirect.
GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final result = ref.read(sajuResultProvider);
      final loc = state.matchedLocation;
      const protected = [
        '/result',
        '/today',
        '/home',
        '/reports',
        '/reports/compatibility',
        '/reports/tojeong',
        '/reports/date-picking',
        '/reports/dream',
        '/reports/new-year-2026',
        '/reports/kpop-compat',
        '/reports/past-life',
        '/reports/music-pharmacy',
        // R105 주의: 최애의 사주 route 는 의도적으로 이 protected 목록에서 제외했다.
        // 그 화면은 셀럽 데이터만 읽고 사용자 본인 사주(sajuResult)가 불필요하므로,
        // result == null 이어도 /input redirect 없이 접근 가능해야 한다.
        '/discover',
        '/profile',
        '/settings',
      ];
      if (result == null && protected.contains(loc)) {
        return '/input';
      }
      // Round 79 sprint 7 — 알림 deep-link `/result?anchor=today_event` payload 를
      // 새 화면 `/today` 로 redirect (사용자 mandate "내 사주 = 평생사주만").
      // result_screen 의 backward compat (anchor scroll) 는 유지하되, 신규 진입은
      // /today 로만. notification_service 측 payload 도 sprint 7 안 `/today` 로 migration.
      if (loc == '/result' &&
          state.uri.queryParameters['anchor'] == 'today_event') {
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/input', builder: (context, state) => const InputScreen()),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
      // Round 79 sprint 7 — 신규 `/today` route (사용자 mandate "내 사주 = 평생사주만").
      GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsHomeScreen(),
      ),
      GoRoute(
        path: '/reports/compatibility',
        builder: (context, state) => const CompatibilityScreen(),
      ),
      GoRoute(
        path: '/reports/tojeong',
        builder: (context, state) => const TojeongScreen(),
      ),
      GoRoute(
        path: '/reports/date-picking',
        builder: (context, state) => const DatePickingScreen(),
      ),
      GoRoute(
        path: '/reports/dream',
        builder: (context, state) => const DreamScreen(),
      ),
      GoRoute(
        path: '/reports/new-year-2026',
        builder: (context, state) => const NewYear2026Screen(),
      ),
      GoRoute(
        path: '/reports/kpop-compat',
        builder: (context, state) => const KpopCompatScreen(),
      ),
      // R101 sprint 5 — 전생 시나리오 (팬심 1순위).
      GoRoute(
        path: '/reports/past-life',
        builder: (context, state) => const PastLifeScreen(),
      ),
      // R101 sprint 6 — 디지털 기운 처방전 (팬심 2순위) 본 화면 wire.
      GoRoute(
        path: '/reports/music-pharmacy',
        builder: (context, state) => const MusicPharmacyScreen(),
      ),
      // R105 — 최애의 사주 (팬심 4순위). 사용자 본인 사주 불필요 — 셀럽 데이터만.
      GoRoute(
        path: '/reports/celebrity-saju',
        builder: (context, state) => const CelebritySajuScreen(),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // R88 sprint 2 — 계산 기준 안내 route 제거. 사용자 mandate
      // ("원래 우리 앱에 있던 나머지 것들은 전부 없애줘"). 관련 widget
      // 파일은 dead code 로 보존 (sprint 10 baseline 재설정 때 정리).
    ],
  );
}

// R101 sprint 5 placeholder 는 sprint 6 가 MusicPharmacyScreen 으로 교체했어요.
