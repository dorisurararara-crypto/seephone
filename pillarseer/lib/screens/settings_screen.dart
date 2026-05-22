// Pillar Seer — 설정 (Aesop Luxury tone). 5탭 hidden gate → dev unlock.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/saju_settings_provider.dart';
import '../providers/streak_provider.dart';
import '../services/app_version_service.dart';
import '../services/notification_pool_service.dart';
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
      barrierColor: AppColors.ink.withValues(alpha: 0.36),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.line, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.devGateTitle.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.of(ctx).pop(v),
                style: GoogleFonts.notoSerifKr(color: AppColors.ink),
                cursorColor: AppColors.ink,
                decoration: InputDecoration(
                  hintText: l.devGateHint,
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.taupe,
                    fontSize: 12,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.ink),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.line),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.taupe,
                        minimumSize: const Size(0, 48),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        l.devGateCancel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.taupe,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 48, color: AppColors.line),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(controller.text),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size(0, 48),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        l.devGateApply.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
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
    switch (result) {
      case DevCodeResult.unlocked:
        msg = l2.devGateUnlocked;
        break;
      case DevCodeResult.locked:
        msg = l2.devGateLocked;
        break;
      case DevCodeResult.invalid:
        msg = l2.devGateInvalid;
        break;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.ink,
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          l.settingsTitle.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 5,
            color: AppColors.ink,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SettingsGroup(label: l.settingsLanguage, children: [
            _LanguageRow(
              label: l.settingsLanguageSystem,
              selected: currentLocale == null,
              onTap: () => ref.read(localeProvider.notifier).setLocale(null),
            ),
            _LanguageRow(
              label: l.settingsLanguageEnglish,
              selected: currentLocale?.languageCode == 'en',
              onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
            ),
            _LanguageRow(
              label: l.settingsLanguageKorean,
              selected: currentLocale?.languageCode == 'ko',
              onTap: () => ref.read(localeProvider.notifier).setLocale('ko'),
            ),
          ]),
          _SettingsGroup(label: l.settingsTheme, children: [
            _DisabledRow(label: l.settingsThemeDark),
          ]),
          _SettingsGroup(label: l.settingsNotifications, children: [
            _NotifSwitch(),
            // R108 ④ — 아침/오후/저녁 3 슬롯 시간대 섹션 (R76 단일 picker 대체).
            _NotifSlotsSection(),
            // Round 77 sprint 7 — 알림 톤 (어른 / 중고생) toggle.
            _NotifToneToggle(),
          ]),
          _SettingsGroup(label: l.settingsSajuOptions, children: [
            _TrueSunSwitch(),
            _LateNightZasiSwitch(),
          ]),
          _SettingsGroup(label: l.settingsTrust, children: [
            // R88 sprint 2 — 사용자 mandate "원래 우리 앱에 있던 나머지 것들은 전부
            // 없애줘". 신뢰 그룹의 상단 두 안내 row (계산 기준 / 풀이 방식) 제거.
            // arb 키와 관련 widget 파일은 dead code 로 보존 (sprint 10 baseline
            // 재설정 때 정리). 진입점만 제거.
            _InfoRow(
              title: l.settingsTrustDataLocal,
              subtitle: l.settingsTrustDataLocalDesc,
            ),
            _InfoRow(
              title: l.settingsTrustOffline,
              subtitle: l.settingsTrustOfflineDesc,
            ),
            _InfoRow(
              title: l.settingsTrustDeleteAll,
              subtitle: l.settingsTrustDeleteAllDesc,
              destructive: true,
              onTap: () => _confirmDeleteAll(context, ref, l),
            ),
          ]),
          if (isPro)
            _SettingsGroup(label: 'STATUS', children: [
              _InfoRow(
                title: 'PRO unlocked',
                subtitle: 'All chapters open.',
                accent: true,
              ),
            ]),
          _SettingsGroup(label: l.settingsAbout, children: [
            // Round 82 sprint 12 — pubspec 의 version+build 를 package_info_plus
            // 로 비동기 로드. 첫 frame 은 placeholder 값을 보여주고, info 가 도착
            // 하면 "버전 X.Y.Z · 빌드 N" (ko) / "Version X.Y.Z (build N)" (en).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onVersionTap,
              child: FutureBuilder<PackageInfo>(
                future: AppVersionService.load(),
                builder: (ctx, snap) {
                  final useKo =
                      Localizations.maybeLocaleOf(ctx)?.languageCode == 'ko';
                  final value = snap.hasData
                      ? AppVersionService.formatLabel(snap.data!, useKo: useKo)
                      : (useKo ? '버전 …' : 'Version …');
                  return _ValueRow(label: l.settingsVersion, value: value);
                },
              ),
            ),
            _LinkRow(
              label: l.settingsPrivacy,
              value: 'github.io/pillarseer/privacy',
              url:
                  'https://dorisurararara-crypto.github.io/pillarseer/privacy.html',
            ),
            _LinkRow(
              label: l.settingsTerms,
              value: 'github.io/pillarseer/terms',
              url:
                  'https://dorisurararara-crypto.github.io/pillarseer/terms.html',
            ),
            _LinkRow(
              label: l.settingsContact,
              value: 'dorisurararara@gmail.com',
              url: 'mailto:dorisurararara@gmail.com',
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(
      BuildContext context, WidgetRef ref, AppL10n l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.line, width: 1),
        ),
        title: Text(
          l.settingsTrustDeleteAll.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l.settingsTrustDeleteAllDesc,
          style: GoogleFonts.notoSansKr(
            color: AppColors.inkLight,
            fontSize: 13,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l.modalNotNow.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.taupe,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.settingsTrustDeleteAll.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.fireRed,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await NotificationService.cancelAll();
    if (!context.mounted) return;
    ref.read(sajuResultProvider.notifier).clear();
    ref.read(userBirthInfoProvider.notifier).clear();
    ref.invalidate(streakProvider);
    ref.invalidate(notificationProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.settingsDeletedSnack),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ));
    context.go('/input');
  }
}

class _SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _SettingsGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.line, width: 1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.paper : AppColors.bg,
          border: const Border(
            bottom: BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 15,
                  fontWeight:
                      selected ? FontWeight.w400 : FontWeight.w300,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (selected)
              Text(
                'SELECTED',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DisabledRow extends StatelessWidget {
  final String label;
  const _DisabledRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                color: AppColors.taupe,
              ),
            ),
          ),
          Text(
            'LOCKED',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool accent;
  const _InfoRow({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = destructive
        ? AppColors.fireRed
        : (accent ? AppColors.accent : AppColors.ink);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12.5,
                      color: AppColors.taupe,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  '→',
                  style: TextStyle(
                      color: destructive ? AppColors.fireRed : AppColors.taupe),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSerifKr(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String value;
  final String url;
  const _LinkRow(
      {required this.label, required this.value, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final uri = Uri.parse(url);
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) throw Exception('launch returned false');
        } catch (_) {
          await Clipboard.setData(ClipboardData(text: url));
          if (!context.mounted) return;
          final useKo = (Localizations.maybeLocaleOf(context)?.languageCode ??
                  'en') ==
              'ko';
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(useKo ? '주소를 복사했어요: $value' : 'URL copied: $value'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.ink,
              duration: const Duration(seconds: 3),
            ));
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.inkLight,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.taupe,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('↗', style: TextStyle(color: AppColors.taupe)),
          ],
        ),
      ),
    );
  }
}

class _TrueSunSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final opts = ref.watch(sajuSettingsProvider);
    return _AesopSwitch(
      title: l.settingsApplyTrueSunTime,
      subtitle: l.settingsApplyTrueSunTimeDesc,
      value: opts.applyTrueSunTime,
      onChanged: (v) async {
        await ref
            .read(sajuSettingsProvider.notifier)
            .setApplyTrueSunTime(v);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.ink,
            content: Text(v
                ? l.settingsApplyTrueSunTimeSnackOn
                : l.settingsApplyTrueSunTimeSnackOff),
          ));
      },
    );
  }
}

class _LateNightZasiSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final opts = ref.watch(sajuSettingsProvider);
    return _AesopSwitch(
      title: l.settingsLateNightZasi,
      subtitle: l.settingsLateNightZasiDesc,
      value: opts.useLateNightZasi,
      onChanged: (v) async {
        await ref
            .read(sajuSettingsProvider.notifier)
            .setUseLateNightZasi(v);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.ink,
            content: Text(v
                ? l.settingsLateNightZasiSnackOn
                : l.settingsLateNightZasiSnackOff),
          ));
      },
    );
  }
}

class _NotifSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final toggle = ref.watch(notificationProvider);
    // R108 ④ — 마스터 ON 이면 켜진 시간대 개수를 보여준다.
    final subtitle = toggle.enabled
        ? l.homeNotifOnSlots(toggle.activeSlotCount)
        : l.homeNotifSubtitle;
    return _AesopSwitch(
      title: l.homeNotifTitle,
      subtitle: subtitle,
      value: toggle.enabled,
      onChanged: (v) async {
        final notifier = ref.read(notificationProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);
        if (v) {
          final saju = ref.read(sajuResultProvider);
          final useKo = (Localizations.maybeLocaleOf(context)?.languageCode ??
                  'en') ==
              'ko';
          final ok = await notifier.enable(
            pushTitle: l.homeNotifSampleTitle,
            pushBody: l.homeNotifSampleBody,
            day60ji: saju?.day60ji,
            useKo: useKo,
            saju: saju,
          );
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.ink,
              content: Text(
                  ok ? l.homeNotifEnabledSnack : l.homeNotifPermissionDenied),
            ));
        } else {
          await notifier.disable();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.ink,
              content: Text(l.homeNotifDisabledSnack),
            ));
        }
      },
    );
  }
}

// R108 ④ — 알림 받을 시간대 (아침/오후/저녁) 3 슬롯 섹션.
// 섹션 헤더(라벨 + 힌트) 아래 3 슬롯 행. 각 행 = 이모지 + 슬롯 이름 + 한 줄
// 설명 + 시간(tap 변경) + 슬롯 토글. 마스터 토글 OFF 상태에서도 미리 설정 가능
// (영속만 — 다음 ON 때 반영). Round 76 단일 picker 를 대체.
class _NotifSlotsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.settingsNotifSlotsLabel.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.settingsNotifSlotsHint,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              color: AppColors.taupe,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          for (final s in NotificationSlot.values) _NotifSlotRow(slot: s),
        ],
      ),
    );
  }
}

/// 한 슬롯 행 — 이모지 + 이름 + 설명 + 시간(tap) + 슬롯 토글.
class _NotifSlotRow extends ConsumerWidget {
  final NotificationSlot slot;
  const _NotifSlotRow({required this.slot});

  String _emoji() {
    switch (slot) {
      case NotificationSlot.morning:
        return '🌅';
      case NotificationSlot.afternoon:
        return '☀️';
      case NotificationSlot.evening:
        return '🌙';
    }
  }

  String _name(AppL10n l) {
    switch (slot) {
      case NotificationSlot.morning:
        return l.settingsNotifSlotMorning;
      case NotificationSlot.afternoon:
        return l.settingsNotifSlotAfternoon;
      case NotificationSlot.evening:
        return l.settingsNotifSlotEvening;
    }
  }

  String _desc(AppL10n l) {
    switch (slot) {
      case NotificationSlot.morning:
        return l.settingsNotifSlotMorningDesc;
      case NotificationSlot.afternoon:
        return l.settingsNotifSlotAfternoonDesc;
      case NotificationSlot.evening:
        return l.settingsNotifSlotEveningDesc;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final toggle = ref.watch(notificationProvider);
    final slotCfg = toggle.slots[slot] ??
        SlotConfig(
          enabled: slot.defaultEnabled,
          hour: slot.defaultTime.hour,
          minute: slot.defaultTime.minute,
        );
    final hh = slotCfg.hour.toString().padLeft(2, '0');
    final mm = slotCfg.minute.toString().padLeft(2, '0');
    final on = slotCfg.enabled;
    // 슬롯 OFF 면 시간은 흐리게 — 토글로 켜야 활성 의미.
    final timeColor = on ? AppColors.ink : AppColors.taupe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(_emoji(), style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name(l),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _desc(l),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11.5,
                    color: AppColors.taupe,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 시간 — tap 으로 변경. 슬롯 OFF 여도 미리 설정 가능.
          InkWell(
            onTap: () => _pickTime(context, ref, slotCfg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '$hh:$mm',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: timeColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: on,
            activeThumbColor: AppColors.bg,
            activeTrackColor: AppColors.ink,
            inactiveThumbColor: AppColors.taupe,
            inactiveTrackColor: AppColors.line,
            trackOutlineColor: WidgetStatePropertyAll(AppColors.line),
            onChanged: (v) => _toggleSlot(context, ref, v),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSlot(
      BuildContext context, WidgetRef ref, bool enabled) async {
    final l = AppL10n.of(context);
    final saju = ref.read(sajuResultProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(notificationProvider.notifier).setSlot(
          slot: slot,
          enabled: enabled,
          pushTitle: l.homeNotifSampleTitle,
          pushBody: l.homeNotifSampleBody,
          day60ji: saju?.day60ji,
          useKo: useKo,
          saju: saju,
        );
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(enabled
            ? l.settingsNotifSlotOnSnack(_name(l))
            : l.settingsNotifSlotOffSnack(_name(l))),
      ));
  }

  Future<void> _pickTime(
      BuildContext context, WidgetRef ref, SlotConfig slotCfg) async {
    final l = AppL10n.of(context);
    final saju = ref.read(sajuResultProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slotCfg.hour, minute: slotCfg.minute),
      helpText: l.settingsNotifSlotPickerTitle(_name(l)),
    );
    if (picked == null || !context.mounted) return;
    await ref.read(notificationProvider.notifier).setSlot(
          slot: slot,
          hour: picked.hour,
          minute: picked.minute,
          pushTitle: l.homeNotifSampleTitle,
          pushBody: l.homeNotifSampleBody,
          day60ji: saju?.day60ji,
          useKo: useKo,
          saju: saju,
        );
    if (!context.mounted) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(l.settingsNotifSlotDoneSnack(_name(l), hh, mm)),
      ));
  }
}

/// Round 77 sprint 7 — 알림 톤 toggle (어른 / 중고생).
/// pickFor fallback 풀 선택에 영향. saju 있는 경우 today_event_pool 본문 우선.
class _NotifToneToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final toggle = ref.watch(notificationProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.settingsNotificationTone.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.settingsNotificationToneHint,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              color: AppColors.taupe,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ToneChip(
                label: l.settingsNotificationToneAdult,
                selected: toggle.tone == NotificationTone.adult,
                onTap: () => _set(context, ref, NotificationTone.adult),
              ),
              const SizedBox(width: 10),
              _ToneChip(
                label: l.settingsNotificationToneMz,
                selected: toggle.tone == NotificationTone.mz,
                onTap: () => _set(context, ref, NotificationTone.mz),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _set(
      BuildContext context, WidgetRef ref, NotificationTone tone) async {
    final l = AppL10n.of(context);
    final saju = ref.read(sajuResultProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    await ref.read(notificationProvider.notifier).setTone(
          tone: tone,
          pushTitle: l.homeNotifSampleTitle,
          pushBody: l.homeNotifSampleBody,
          day60ji: saju?.day60ji,
          useKo: useKo,
          saju: saju,
        );
  }
}

class _ToneChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.bg,
          border: Border.all(
              color: selected ? AppColors.ink : AppColors.line, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSerifKr(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: selected ? AppColors.bg : AppColors.ink,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _AesopSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AesopSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    color: AppColors.taupe,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.bg,
            activeTrackColor: AppColors.ink,
            inactiveThumbColor: AppColors.taupe,
            inactiveTrackColor: AppColors.line,
            trackOutlineColor:
                WidgetStatePropertyAll(AppColors.line),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
