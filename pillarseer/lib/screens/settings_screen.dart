// Pillar Seer — 설정 화면. 언어 / 테마 / 알림 / About.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _sectionHeader(context, l.settingsLanguage),
          _LanguageTile(
            label: l.settingsLanguageSystem,
            selected: currentLocale == null,
            onTap: () => ref.read(localeProvider.notifier).setLocale(null),
          ),
          _LanguageTile(
            label: l.settingsLanguageEnglish,
            selected: currentLocale?.languageCode == 'en',
            onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
          ),
          _LanguageTile(
            label: l.settingsLanguageKorean,
            selected: currentLocale?.languageCode == 'ko',
            onTap: () => ref.read(localeProvider.notifier).setLocale('ko'),
          ),
          const SizedBox(height: 24),
          _sectionHeader(context, l.settingsTheme),
          _disabledTile(context, l.settingsThemeDark),
          const SizedBox(height: 24),
          _sectionHeader(context, l.settingsNotifications),
          _disabledTile(context, l.settingsNotificationsDesc),
          const SizedBox(height: 24),
          _sectionHeader(context, l.settingsAbout),
          _aboutTile(context, l.settingsVersion, '1.0.0'),
          _aboutTile(context, l.settingsPrivacy, 'dorisurararara-crypto.github.io'),
          _aboutTile(context, l.settingsTerms, 'dorisurararara-crypto.github.io'),
          _aboutTile(context, l.settingsContact, 'dorisurararara@gmail.com'),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          color: AppColors.celestialGold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _disabledTile(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.fadedSilver,
              ),
            ),
          ),
          const Icon(Icons.lock_outline,
              size: 14, color: AppColors.fadedSilver),
        ],
      ),
    );
  }

  Widget _aboutTile(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.ghostlyWhite,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.moonlightGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.celestialGold.withValues(alpha: 0.15)
                : AppColors.spiritIndigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.celestialGold.withValues(alpha: 0.6)
                  : AppColors.celestialGold.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected
                        ? AppColors.celestialGold
                        : AppColors.ghostlyWhite,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check,
                    size: 18, color: AppColors.celestialGold),
            ],
          ),
        ),
      ),
    );
  }
}
