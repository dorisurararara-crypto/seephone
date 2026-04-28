import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/message_repo.dart';
import '../theme/theme_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String question;
  const ResultScreen({super.key, required this.question});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final Message _message;

  @override
  void initState() {
    super.initState();
    _message = ref.read(messageRepoProvider).pickFor(widget.question);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      body: Container(
        decoration: theme.buildScreenBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                Expanded(
                  child: Center(child: theme.buildTalisman(_message.text)),
                ),
                const SizedBox(height: 16),
                theme.buildActionButtons(
                  onSave: () {
                    // TODO: gal.putImage() — screenshot 패키지로 부적 영역 캡처 후 저장.
                  },
                  onShare: () {
                    // TODO: SharePlus.instance.share() with talisman PNG.
                  },
                ),
                theme.buildWatermark(),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    '처음으로',
                    style: TextStyle(
                      color: theme.statusBarBrightness == Brightness.light
                          ? Colors.white60
                          : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
