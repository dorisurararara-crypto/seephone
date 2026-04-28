import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToRitual() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    context.push('/ritual?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      body: Container(
        decoration: theme.buildScreenBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          theme.buildBrand(context),
                          theme.buildTagline(context),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: Icon(
                        Icons.settings,
                        color: theme.statusBarBrightness == Brightness.light
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                theme.buildInputLabel('— 고민을 적으시오 —'),
                const SizedBox(height: 12),
                theme.buildInputBox(
                  controller: _controller,
                  hint: '예: 전 남친한테 카톡할까?',
                ),
                const Spacer(),
                theme.buildCta(
                  label: '폰을 흔들어 점치기',
                  onPressed: _goToRitual,
                ),
                const SizedBox(height: 10),
                theme.buildShakeHint('위아래로 3번 흔드시오'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
