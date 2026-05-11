import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// 5탭 Bottom Nav. home/result/placeholder 공유.
/// 라우트 진입은 Riverpod 전역 상태(sajuResultProvider)로 보호되므로 extra 전달 불필요.
class PillarBottomNav extends StatelessWidget {
  final int activeIdx; // 0=Home 1=Reading 2=Reports 3=Discover 4=Profile

  const PillarBottomNav({super.key, required this.activeIdx});

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.auto_awesome, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.view_column_outlined, label: 'Reading', route: '/result'),
    _NavItem(icon: Icons.menu_book_outlined, label: 'Reports', route: '/reports'),
    _NavItem(icon: Icons.nightlight_round, label: 'Discover', route: '/discover'),
    _NavItem(icon: Icons.person_outline, label: 'Profile', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cosmicBlack.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.celestialGold.withValues(alpha: 0.15)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: _items.asMap().entries.map((entry) {
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
                            fontSize: 11,
                            letterSpacing: 0.3,
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
  const _NavItem({required this.icon, required this.label, required this.route});
}
