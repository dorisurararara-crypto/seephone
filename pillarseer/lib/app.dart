import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PillarSeerApp extends StatelessWidget {
  const PillarSeerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _RouterHost());
  }
}

class _RouterHost extends ConsumerStatefulWidget {
  const _RouterHost();

  @override
  ConsumerState<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends ConsumerState<_RouterHost> {
  late final _router = buildRouter(ref);

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppL10n.of(ctx).appTitle,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
    );
  }
}
