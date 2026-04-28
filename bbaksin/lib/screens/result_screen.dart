import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/share_service.dart';
import '../services/sound_service.dart';
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
  final _sfx = SoundService();
  Message? _message;
  bool _played = false;

  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final repoAsync = ref.watch(messageRepoProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: theme.buildScreenBackground()),
          // 굿판 ambient (V5 미스틱·V1 클래식 톤에서 잘 어울림). 다른 테마에서도 은은하게.
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/effects/v5_fx_smoke.png',
                fit: BoxFit.cover,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms, curve: Curves.easeOut),
          Positioned.fill(
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
              if (!_played) {
                _played = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _sfx.play(BbaksinSfx.reveal);
                });
              }
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
                      onSave: () {
                        _sfx.play(BbaksinSfx.success);
                        ShareService.saveTalisman(
                          controller: _shotController,
                          context: context,
                        );
                      },
                      onShare: () {
                        _sfx.play(BbaksinSfx.share);
                        ShareService.shareTalisman(
                          controller: _shotController,
                          question: widget.question,
                        );
                      },
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
        ],
      ),
    );
  }
}
