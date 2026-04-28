import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'services/locale_service.dart';
import 'theme/theme_provider.dart';

class BbaksinApp extends ConsumerWidget {
  const BbaksinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final locale = ref.watch(localeProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.statusBarBrightness == Brightness.light
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme.buildMaterialTheme(),
      routerConfig: appRouter,
    );
  }
}
