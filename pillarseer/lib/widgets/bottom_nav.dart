import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 4탭 Bottom Nav — codex Round 13 권고로 5탭 → 4탭 단순화.
/// 오늘 (Home) / 내 사주 (Result) / 리포트 / 프로필
/// Discover (셀럽 비교) 는 Reports home 안 카드로 흡수.
class PillarBottomNav extends StatelessWidget {
  final int activeIdx;

  const PillarBottomNav({super.key, required this.activeIdx});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = <_NavItem>[
      _NavItem(icon: Icons.wb_sunny_outlined, label: l.navHome, route: '/home'),
      _NavItem(
          icon: Icons.view_column_outlined,
          label: l.navReading,
          route: '/result'),
      _NavItem(
          icon: Icons.menu_book_outlined,
          label: l.navReports,
          route: '/reports'),
      _NavItem(
          icon: Icons.person_outline,
          label: l.navProfile,
          route: '/profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cosmicBlack.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
              color: AppColors.celestialGold.withValues(alpha: 0.12)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = i == activeIdx;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: item.label,
                  child: InkWell(
                    onTap: () {
                      if (i == activeIdx) return;
                      context.go(item.route);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: isActive
                              ? AppColors.celestialGold
                              : AppColors.moonlightGray,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? AppColors.celestialGold
                                : AppColors.moonlightGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(
      {required this.icon, required this.label, required this.route});
}
