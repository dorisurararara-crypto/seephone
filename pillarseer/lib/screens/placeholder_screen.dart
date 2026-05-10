import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';

/// 다른 탭의 placeholder. Phase 2에서 각 탭 풀 화면으로 교체.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final int activeNavIdx; // 0=Home 1=Reading 2=Reports 3=Discover 4=Profile
  final SajuResult? userSaju;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.activeNavIdx,
    this.userSaju,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 24),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.celestialGold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.moonlightGray,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.spiritIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.celestialGold.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      color: AppColors.celestialGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      {'icon': '✦', 'name': 'Home', 'route': '/home'},
      {'icon': '柱', 'name': 'Reading', 'route': '/result'},
      {'icon': '📜', 'name': 'Reports', 'route': '/reports'},
      {'icon': '🌙', 'name': 'Discover', 'route': '/discover'},
      {'icon': '○', 'name': 'Profile', 'route': '/profile'},
    ];
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.cosmicBlack.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.celestialGold.withValues(alpha: 0.15))),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isActive = i == activeNavIdx;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (i == activeNavIdx) return;
                final route = item['route'] as String;
                if (route == '/home' || route == '/result') {
                  context.go(route, extra: userSaju);
                } else {
                  context.go(route);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['icon'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      color: isActive ? AppColors.celestialGold : AppColors.moonlightGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (item['name'] as String).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.celestialGold : AppColors.moonlightGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
