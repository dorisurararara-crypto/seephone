// Pillar Seer — 설정 화면. 언어 / 테마 / 알림 / About.
// Version 라벨 5탭 hidden gate → ganzinam95/12 dev unlock dialog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;
  DateTime? _lastTapAt;

  void _onVersionTap() {
    final now = DateTime.now();
    if (_lastTapAt != null && now.difference(_lastTapAt!).inSeconds > 2) {
      _versionTapCount = 0;
    }
    _lastTapAt = now;
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      _showDevDialog();
    }
  }

  Future<void> _showDevDialog() async {
    final controller = TextEditingController();
    final l = AppL10n.of(context);
    final code = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cosmicBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.celestialGold.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key_outlined,
                  color: AppColors.celestialGold, size: 30),
              const SizedBox(height: 10),
              Text(
                l.devGateTitle,
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.4,
                  color: AppColors.celestialGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.of(ctx).pop(v),
                style: const TextStyle(color: AppColors.ghostlyWhite),
                decoration: InputDecoration(
                  hintText: l.devGateHint,
                  hintStyle: const TextStyle(
                    color: AppColors.fadedSilver,
                    fontSize: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.celestialGold.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.celestialGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.moonlightGray,
                        minimumSize: const Size(0, 42),
                      ),
                      child: Text(l.devGateCancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.celestialGold,
                        foregroundColor: AppColors.cosmicBlack,
                        minimumSize: const Size(0, 42),
                      ),
                      child: Text(l.devGateApply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (code == null || code.isEmpty) return;

    final result = await ref.read(devUnlockProvider.notifier).apply(code);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l2 = AppL10n.of(context);
    String msg;
    Color bg;
    switch (result) {
      case DevCodeResult.unlocked:
        msg = l2.devGateUnlocked;
        bg = AppColors.celestialGold;
        break;
      case DevCodeResult.locked:
        msg = l2.devGateLocked;
        bg = AppColors.spiritIndigo;
        break;
      case DevCodeResult.invalid:
        msg = l2.devGateInvalid;
        bg = Colors.redAccent.shade200;
        break;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final currentLocale = ref.watch(localeProvider);
    final isPro = ref.watch(devUnlockProvider);

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
          if (isPro) ...[
            const SizedBox(height: 24),
            _sectionHeader(context, 'STATUS'),
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.celestialGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.celestialGold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.workspace_premium,
                      color: AppColors.celestialGold, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'PRO unlocked',
                    style: TextStyle(
                      color: AppColors.celestialGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _sectionHeader(context, l.settingsAbout),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onVersionTap,
            child: _aboutTile(context, l.settingsVersion, '1.0.0'),
          ),
          _aboutTile(context, l.settingsPrivacy,
              'dorisurararara-crypto.github.io'),
          _aboutTile(context, l.settingsTerms,
              'dorisurararara-crypto.github.io'),
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
