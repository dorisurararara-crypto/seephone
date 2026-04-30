import 'package:go_router/go_router.dart';
import 'screens/intro_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const IntroScreen()),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final score = double.tryParse(
              state.uri.queryParameters['score'] ?? '0',
            ) ??
            0.0;
        return ResultScreen(score: score);
      },
    ),
  ],
);
