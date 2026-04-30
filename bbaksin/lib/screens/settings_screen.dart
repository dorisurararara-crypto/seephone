import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../theme/theme_provider.dart';
import '../theme/theme_registry.dart';
import '../theme/theme_style.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = ref.watch(currentThemeProvider);
    final currentId = ref.watch(themeIdProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: Container(
        decoration: theme.buildScreenBackground(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppBar(theme: theme, title: l.settings),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    _SectionLabel(theme: theme, label: l.themeLabel),
                    const SizedBox(height: 12),
                    ...kAllThemes.map((t) {
                      final isCurrent = t.id == currentId;
                      return _ThemeTile(
                        themeStyle: t,
                        isCurrent: isCurrent,
                        isLocked: false,
                        onTap: () {
                          ref
                              .read(themeIdProvider.notifier)
                              .setTheme(t.id);
                        },
                      );
                    }),
                    const SizedBox(height: 32),
                    _SectionLabel(theme: theme, label: l.language),
                    const SizedBox(height: 8),
                    _LangTile(
                      label: l.languageAuto,
                      selected: currentLocale == null,
                      accent: theme.previewColor,
                      onTap: () =>
                          ref.read(localeProvider.notifier).setLocale(null),
                    ),
                    _LangTile(
                      label: l.languageKorean,
                      selected: currentLocale?.languageCode == 'ko',
                      accent: theme.previewColor,
                      onTap: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('ko')),
                    ),
                    _LangTile(
                      label: l.languageEnglish,
                      selected: currentLocale?.languageCode == 'en',
                      accent: theme.previewColor,
                      onTap: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('en')),
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

class _LangTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _LangTile({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? accent : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final BbaksinThemeStyle theme;
  final String title;
  const _AppBar({required this.theme, required this.title});

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
          Text(
            title,
            style: const TextStyle(
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

