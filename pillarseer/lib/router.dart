import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'models/saju_result.dart';

final router = GoRouter(
  initialLocation: '/',
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
      builder: (context, state) {
        final result = state.extra as SajuResult?;
        return ResultScreen(result: result ?? SajuResult.dummy());
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final result = state.extra as SajuResult?;
        return HomeScreen(userSaju: result ?? SajuResult.dummy());
      },
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const PlaceholderScreen(
        title: 'Reports',
        description: 'Premium reports — Compatibility, Tojeongbigyeol, Date Picking, Dream Interpretation. Coming soon.',
        icon: '📜',
        activeNavIdx: 2,
      ),
    ),
    GoRoute(
      path: '/discover',
      builder: (context, state) => const PlaceholderScreen(
        title: 'Discover',
        description: 'K-pop saju, K-drama mysticism, and Korean fortune-telling stories. Coming soon.',
        icon: '🌙',
        activeNavIdx: 3,
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const PlaceholderScreen(
        title: 'Profile',
        description: 'Your birth chart archive, multi-profile management, and subscription. Coming soon.',
        icon: '○',
        activeNavIdx: 4,
      ),
    ),
  ],
);
