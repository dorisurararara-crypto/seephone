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
import 'screens/info_saju_calc_screen.dart';
import 'screens/reports/reports_home_screen.dart';
import 'screens/reports/compatibility_screen.dart';
import 'screens/reports/tojeong_screen.dart';
import 'screens/reports/date_picking_screen.dart';
import 'screens/reports/dream_screen.dart';
import 'screens/reports/new_year_2026_screen.dart';
import 'screens/reports/kpop_compat_screen.dart';
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
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/input',
        builder: (context, state) => const InputScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
      // Round 79 sprint 7 — 신규 `/today` route (사용자 mandate "내 사주 = 평생사주만").
      GoRoute(
        path: '/today',
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
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
      // Round 83 sprint 2 — "사주 계산 기준 안내" 페이지 (P1-G).
      // 진태양시 / 자시 학파 / 절기 / 음력 / 출생지 경도 5 영역 readonly 안내.
      GoRoute(
        path: '/settings/saju-calc-basis',
        builder: (context, state) => const InfoSajuCalcScreen(),
      ),
    ],
  );
}
