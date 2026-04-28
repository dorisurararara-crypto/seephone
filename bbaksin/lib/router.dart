import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/ritual_screen.dart';
import 'screens/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/ritual',
      builder: (context, state) {
        final question = state.uri.queryParameters['q'] ?? '';
        return RitualScreen(question: question);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final question = state.uri.queryParameters['q'] ?? '';
        return ResultScreen(question: question);
      },
    ),
  ],
);
