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
      builder: (context, state) {
        final question = state.uri.queryParameters['q'] ?? '';
        return ScanScreen(question: question);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final question = state.uri.queryParameters['q'] ?? '';
        final score = double.tryParse(
              state.uri.queryParameters['score'] ?? '0',
            ) ??
            0.0;
        return ResultScreen(question: question, score: score);
      },
    ),
  ],
);
