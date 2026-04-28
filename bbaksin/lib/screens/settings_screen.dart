import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/purchase_service.dart';
import '../theme/theme_provider.dart';
import '../theme/theme_registry.dart';
import '../theme/theme_style.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final currentId = ref.watch(themeIdProvider);
    final isPro = ref.watch(proStatusProvider);

    return Scaffold(
      body: Container(
        decoration: theme.buildScreenBackground(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppBar(theme: theme),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    _SectionLabel(theme: theme, label: '테마'),
                    const SizedBox(height: 12),
                    if (!isPro)
                      _ProBanner(
                        theme: theme,
                        onTap: () =>
                            _showProSheet(context, ref, theme.previewColor),
                      ),
                    const SizedBox(height: 8),
                    ...kAllThemes.map((t) {
                      final isCurrent = t.id == currentId;
                      final isLocked = !isPro && t.id != kDefaultThemeId;
                      return _ThemeTile(
                        themeStyle: t,
                        isCurrent: isCurrent,
                        isLocked: isLocked,
                        onTap: () {
                          if (isLocked) {
                            _showProSheet(
                                context, ref, theme.previewColor);
                            return;
                          }
                          ref
                              .read(themeIdProvider.notifier)
                              .setTheme(t.id);
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                    // 개발용 Pro 토글 — long press
                    GestureDetector(
                      onLongPress: () => ref
                          .read(proStatusProvider.notifier)
                          .toggleForDev(),
                      child: Text(
                        isPro
                            ? '✓ Pro 활성화됨 (장기누름: 해제)'
                            : '⚙ Pro 비활성 (장기누름: 개발용 토글)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showProSheet(BuildContext context, WidgetRef ref, Color accent) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '빡신 PRO',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '5가지 테마 자유 전환 · 광고 제거 · 부적 무제한',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: in_app_purchase 실제 구매 플로우.
              // 임시로 Pro 활성화.
              ref.read(proStatusProvider.notifier).setPro(true);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('월 2,900원으로 시작',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('나중에',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    ),
  );
}

class _AppBar extends StatelessWidget {
  final BbaksinThemeStyle theme;
  const _AppBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Text(
            '설정',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final BbaksinThemeStyle theme;
  final String label;
  const _SectionLabel({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final BbaksinThemeStyle themeStyle;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.themeStyle,
    required this.isCurrent,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? themeStyle.previewColor
                  : Colors.white.withValues(alpha: 0.12),
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeStyle.previewColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeStyle.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      themeStyle.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock, color: Colors.white38, size: 20),
              if (isCurrent && !isLocked)
                Icon(Icons.check_circle,
                    color: themeStyle.previewColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final BbaksinThemeStyle theme;
  final VoidCallback onTap;
  const _ProBanner({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.previewColor.withValues(alpha: 0.4),
              theme.previewColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.previewColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: theme.previewColor, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'PRO 구독으로 5개 테마 자유 전환',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }
}
