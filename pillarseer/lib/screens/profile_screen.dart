// Pillar Seer — Profile 화면 (Phase 1 간단 구현).
// 사용자 사주 요약 + Settings 진입 + Reset.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            // 사용자 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.celestialGold.withValues(alpha: 0.15),
                    AppColors.spiritIndigo.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.celestialGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_outline,
                      size: 48, color: AppColors.celestialGold),
                  const SizedBox(height: 12),
                  Text(
                    info?.name.isNotEmpty == true ? info!.name : '—',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ghostlyWhite,
                    ),
                  ),
                  if (saju != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${saju.dayMasterName} (${saju.day60ji})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.celestialGold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _row(
              context,
              icon: Icons.settings_outlined,
              label: l.settingsTitle,
              onTap: () => context.push('/settings'),
            ),
            _row(
              context,
              icon: Icons.refresh,
              label: 'Reset',
              onTap: () {
                ref.read(sajuResultProvider.notifier).clear();
                ref.read(userBirthInfoProvider.notifier).clear();
                context.go('/input');
              },
            ),
            const SizedBox(height: 24),
            Text(
              l.placeholderProfileDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.fadedSilver,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 4),
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.spiritIndigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.celestialGold.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.celestialGold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.ghostlyWhite,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.moonlightGray),
            ],
          ),
        ),
      ),
    );
  }
}
