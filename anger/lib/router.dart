import 'package:go_router/go_router.dart';
import 'screens/intro_screen.dart';
import 'screens/measure_screen.dart';
import 'screens/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const IntroScreen()),
    GoRoute(path: '/measure', builder: (context, state) => const MeasureScreen()),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final w = double.tryParse(
              state.uri.queryParameters['w'] ?? '0',
            ) ??
            0.0;
        return ResultScreen(watts: w);
      },
    ),
  ],
);
