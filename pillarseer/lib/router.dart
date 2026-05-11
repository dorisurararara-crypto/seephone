import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/saju_provider.dart';

/// 전역 라우터. extra 의존 제거.
/// SajuResult 가 null 이면 /input 으로 redirect (Bottom Nav 탭 이동 후에도 안전).
GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final result = ref.read(sajuResultProvider);
      final loc = state.matchedLocation;
      const protected = ['/result', '/home', '/reports', '/discover', '/profile'];
      if (result == null && protected.contains(loc)) {
        return '/input';
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) =>
            const PlaceholderScreen(kind: PlaceholderKind.reports),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) =>
            const PlaceholderScreen(kind: PlaceholderKind.discover),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

