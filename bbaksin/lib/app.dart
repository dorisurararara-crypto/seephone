import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/theme_provider.dart';

class BbaksinApp extends ConsumerWidget {
  const BbaksinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.statusBarBrightness == Brightness.light
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: '빡신',
      debugShowCheckedModeBanner: false,
      theme: theme.buildMaterialTheme(),
      routerConfig: appRouter,
    );
  }
}
