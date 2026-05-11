import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

/// 다른 탭의 placeholder. Phase 2에서 각 탭 풀 화면으로 교체.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final int activeNavIdx; // 0=Home 1=Reading 2=Reports 3=Discover 4=Profile

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.activeNavIdx,
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
                Icon(iconData, size: 56, color: AppColors.celestialGold),
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
                    border: Border.all(
                        color: AppColors.celestialGold.withValues(alpha: 0.3)),
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
      bottomNavigationBar: PillarBottomNav(activeIdx: activeNavIdx),
    );
  }
}
