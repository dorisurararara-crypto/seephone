import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/share_service.dart';
import '../state/message_repo.dart';
import '../theme/theme_provider.dart';
import 'package:screenshot/screenshot.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String question;
  const ResultScreen({super.key, required this.question});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _shotController = ScreenshotController();
  Message? _message;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final repoAsync = ref.watch(messageRepoProvider);

    return Scaffold(
      body: Container(
        decoration: theme.buildScreenBackground(),
        child: SafeArea(
          child: repoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                '데이터 로드 실패: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (repo) {
              _message ??= repo.pickFor(widget.question);
              final msg = _message!;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Screenshot(
                          controller: _shotController,
                          child: theme.buildTalisman(msg.text),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    theme.buildActionButtons(
                      onSave: () => ShareService.saveTalisman(
                        controller: _shotController,
                        context: context,
                      ),
                      onShare: () => ShareService.shareTalisman(
                        controller: _shotController,
                        question: widget.question,
                      ),
                    ),
                    theme.buildWatermark(),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(
                        '처음으로',
                        style: TextStyle(
                          color:
                              theme.statusBarBrightness == Brightness.light
                                  ? Colors.white60
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
