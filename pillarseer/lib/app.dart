import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/premium_provider.dart';
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
    // R110 — 앱 시작 시 프리미엄 entitlement 부팅(캐시 반영 + StoreKit
    // 조용한 자동 복원). provider 를 watch 만 해도 build()→_boot() 가 1회 실행됨.
    ref.watch(premiumProvider);
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
