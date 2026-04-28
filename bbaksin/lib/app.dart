import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

class BbaksinApp extends ConsumerWidget {
  const BbaksinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '빡신',
      debugShowCheckedModeBanner: false,
      theme: BbaksinTheme.light(),
      routerConfig: appRouter,
    );
  }
}
