// Pillar Seer — Profile (Aesop Luxury tone).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/saju_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final saju = ref.watch(sajuResultProvider);
    final info = ref.watch(userBirthInfoProvider);
    final isPro = ref.watch(devUnlockProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

    final displayName = (info?.name.trim().isNotEmpty ?? false)
        ? info!.name.trim()
        : (saju != null
            ? (useKo
                ? saju.dayPillar.pairKoreanMeaning
                : saju.dayMasterName)
            : '—');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'P I L L A R    S E E R',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 5,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    useKo ? '프로필 · 我' : 'PROFILE · 我',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR  CHART · 命 譜',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    displayName,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  if (saju != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      useKo
                          ? '${saju.dayPillar.pairKorean} · ${saju.dayPillar.pairKoreanMeaning} · ${saju.day60ji}'
                          : '${saju.dayMasterName} · ${saju.day60ji}',
                      style: useKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: AppColors.accent,
                              letterSpacing: 0.3,
                            )
                          : GoogleFonts.cormorantGaramond(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accent,
                            ),
                    ),
                  ],
                  if (isPro) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.accent, width: 1),
                      ),
                      child: Text(
                        'PRO  MEMBER',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _MenuRow(
              label: l.settingsTitle,
              onTap: () => context.push('/settings'),
            ),
            _MenuRow(
              label: l.profileReset,
              destructive: true,
              onTap: () {
                ref.read(sajuResultProvider.notifier).clear();
                ref.read(userBirthInfoProvider.notifier).clear();
                context.go('/input');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 3),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _MenuRow({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
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
                  color: destructive ? AppColors.fireRed : AppColors.ink,
                ),
              ),
            ),
            Text(
              '→',
              style: TextStyle(
                  color: destructive ? AppColors.fireRed : AppColors.taupe,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
