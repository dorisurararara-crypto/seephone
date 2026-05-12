// Pillar Seer — 설정 화면. 언어 / 테마 / 알림 / About.
// Version 라벨 5탭 hidden gate → ganzinam95/12 dev unlock dialog.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/saju_settings_provider.dart';
import '../providers/streak_provider.dart';
import '../services/notification_service.dart';
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
            color: AppColors.cardBorderStrong,
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
                      color: AppColors.cardBorder,
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
          _NotifToggleTile(),
          const SizedBox(height: 24),
          _sectionHeader(context, l.settingsSajuOptions),
          _TrueSunTimeTile(),
          const SizedBox(height: 6),
          _LateNightZasiTile(),
          const SizedBox(height: 24),
          _sectionHeader(context, l.settingsTrust),
          _TrustTile(
            icon: Icons.verified_outlined,
            title: l.settingsTrustHowCalculated,
            subtitle: l.settingsTrustHowCalculatedDesc,
            onTap: null,
          ),
          _TrustTile(
            icon: Icons.smartphone_outlined,
            title: l.settingsTrustDataLocal,
            subtitle: l.settingsTrustDataLocalDesc,
            onTap: null,
          ),
          _TrustTile(
            icon: Icons.cloud_off_outlined,
            title: l.settingsTrustOffline,
            subtitle: l.settingsTrustOfflineDesc,
            onTap: null,
          ),
          _TrustTile(
            icon: Icons.delete_outline,
            title: l.settingsTrustDeleteAll,
            subtitle: l.settingsTrustDeleteAllDesc,
            destructive: true,
            onTap: () => _confirmDeleteAll(context, ref, l),
          ),
          if (isPro) ...[
            const SizedBox(height: 24),
            _sectionHeader(context, 'STATUS'),
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                color: AppColors.cardBorderStrong,
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
          _LinkTile(
            label: l.settingsPrivacy,
            value: 'github.io/pillarseer/privacy',
            url: 'https://dorisurararara-crypto.github.io/pillarseer/privacy.html',
          ),
          _LinkTile(
            label: l.settingsTerms,
            value: 'github.io/pillarseer/terms',
            url: 'https://dorisurararara-crypto.github.io/pillarseer/terms.html',
          ),
          _LinkTile(
            label: l.settingsContact,
            value: 'dorisurararara@gmail.com',
            url: 'mailto:dorisurararara@gmail.com',
          ),
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
          color: AppColors.moonlightGray,
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
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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

  Future<void> _confirmDeleteAll(
      BuildContext context, WidgetRef ref, AppL10n l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cosmicBlack,
        title: Text(l.settingsTrustDeleteAll,
            style: const TextStyle(color: AppColors.ghostlyWhite)),
        content: Text(l.settingsTrustDeleteAllDesc,
            style: const TextStyle(color: AppColors.moonlightGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.modalNotNow,
                style:
                    const TextStyle(color: AppColors.moonlightGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade200,
              foregroundColor: AppColors.cosmicBlack,
            ),
            child: Text(l.settingsTrustDeleteAll),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await NotificationService.cancelDaily();
    if (!context.mounted) return;
    ref.read(sajuResultProvider.notifier).clear();
    ref.read(userBirthInfoProvider.notifier).clear();
    // streak/notif provider 상태도 초기화
    ref.invalidate(streakProvider);
    ref.invalidate(notificationProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.settingsDeletedSnack),
        backgroundColor: AppColors.celestialGold,
        behavior: SnackBarBehavior.floating,
      ));
    context.go('/input');
  }

  Widget _aboutTile(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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

class _TrueSunTimeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final opts = ref.watch(sajuSettingsProvider);
    final on = opts.applyTrueSunTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: on ? AppColors.cardBorderStrong : AppColors.cardBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: on ? AppColors.celestialGold : AppColors.fadedSilver,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsApplyTrueSunTime,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ghostlyWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsApplyTrueSunTimeDesc,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.moonlightGray,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              activeThumbColor: AppColors.celestialGold,
              activeTrackColor:
                  AppColors.celestialGold.withValues(alpha: 0.35),
              onChanged: (v) async {
                await ref
                    .read(sajuSettingsProvider.notifier)
                    .setApplyTrueSunTime(v);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.spiritIndigo,
                    content: Text(
                      v
                          ? l.settingsApplyTrueSunTimeSnackOn
                          : l.settingsApplyTrueSunTimeSnackOff,
                      style: const TextStyle(
                        color: AppColors.ghostlyWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LateNightZasiTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final opts = ref.watch(sajuSettingsProvider);
    final on = opts.useLateNightZasi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: on ? AppColors.cardBorderStrong : AppColors.cardBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 18,
              color: on ? AppColors.mysticViolet : AppColors.fadedSilver,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsLateNightZasi,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ghostlyWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.settingsLateNightZasiDesc,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.moonlightGray,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              activeThumbColor: AppColors.mysticViolet,
              activeTrackColor:
                  AppColors.mysticViolet.withValues(alpha: 0.35),
              onChanged: (v) async {
                await ref
                    .read(sajuSettingsProvider.notifier)
                    .setUseLateNightZasi(v);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.spiritIndigo,
                    content: Text(
                      v
                          ? l.settingsLateNightZasiSnackOn
                          : l.settingsLateNightZasiSnackOff,
                      style: const TextStyle(
                        color: AppColors.ghostlyWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final toggle = ref.watch(notificationProvider);
    final on = toggle.enabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: on ? AppColors.cardBorderStrong : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              on
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              size: 18,
              color: on ? AppColors.mysticViolet : AppColors.fadedSilver,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.homeNotifTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ghostlyWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    on ? l.homeNotifOn : l.homeNotifSubtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: on
                          ? AppColors.moonlightGray
                          : AppColors.moonlightGray,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: on,
              activeThumbColor: AppColors.mysticViolet,
              activeTrackColor:
                  AppColors.mysticViolet.withValues(alpha: 0.35),
              onChanged: (v) async {
                final notifier = ref.read(notificationProvider.notifier);
                final messenger = ScaffoldMessenger.of(context);
                if (v) {
                  final saju = ref.read(sajuResultProvider);
                  final useKo = (Localizations.maybeLocaleOf(context)
                              ?.languageCode ??
                          'en') ==
                      'ko';
                  final ok = await notifier.enable(
                    pushTitle: l.homeNotifSampleTitle,
                    pushBody: l.homeNotifSampleBody,
                    day60ji: saju?.day60ji,
                    useKo: useKo,
                  );
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ok
                          ? AppColors.spiritIndigo
                          : Colors.redAccent.shade200,
                      content: Text(
                        ok
                            ? l.homeNotifEnabledSnack
                            : l.homeNotifPermissionDenied,
                        style: const TextStyle(
                          color: AppColors.ghostlyWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ));
                } else {
                  await notifier.disable();
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.spiritIndigo,
                      content: Text(l.homeNotifDisabledSnack),
                    ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final String value;
  final String url;
  const _LinkTile({required this.label, required this.value, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final uri = Uri.parse(url);
            try {
              final ok = await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
              if (!ok) throw Exception('launch returned false');
            } catch (_) {
              // codex Round 9 fix: silent catch 대신 사용자 fallback (clipboard copy + snackbar)
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              final useKo = (Localizations.maybeLocaleOf(context)
                          ?.languageCode ??
                      'en') ==
                  'ko';
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(useKo
                      ? '주소를 복사했어요: $value'
                      : 'URL copied: $value'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.spiritIndigo,
                  duration: const Duration(seconds: 3),
                ));
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.cardBorder,
              ),
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
                    fontSize: 11.5,
                    color: AppColors.moonlightGray,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.fadedSilver,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.open_in_new,
                    size: 12, color: AppColors.fadedSilver),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  const _TrustTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? Colors.redAccent.shade200
        : AppColors.mysticViolet;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: destructive
                    ? accent.withValues(alpha: 0.35)
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: destructive
                              ? Colors.redAccent.shade200
                              : AppColors.ghostlyWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.moonlightGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      color: AppColors.fadedSilver, size: 18),
                ],
              ],
            ),
          ),
        ),
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
                ? AppColors.mysticViolet.withValues(alpha: 0.22)
                : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.cardBorderStrong
                  : AppColors.cardBorder,
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
                        ? AppColors.ghostlyWhite
                        : AppColors.ghostlyWhite,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check,
                    size: 18, color: AppColors.mysticViolet),
            ],
          ),
        ),
      ),
    );
  }
}
