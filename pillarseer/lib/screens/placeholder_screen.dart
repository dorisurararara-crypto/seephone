import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

enum PlaceholderKind { reports, discover }

/// Reports / Discover placeholder (Phase 2 까지 임시).
class PlaceholderScreen extends StatelessWidget {
  final PlaceholderKind kind;

  const PlaceholderScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final String title;
    final String description;
    final IconData icon;
    final int navIdx;
    switch (kind) {
      case PlaceholderKind.reports:
        title = l.placeholderReportsTitle;
        description = l.placeholderReportsDesc;
        icon = Icons.menu_book_outlined;
        navIdx = 2;
        break;
      case PlaceholderKind.discover:
        title = l.placeholderDiscoverTitle;
        description = l.placeholderDiscoverDesc;
        icon = Icons.nightlight_round;
        navIdx = 3;
        break;
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 56, color: AppColors.celestialGold),
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
                  child: Text(
                    l.placeholderComingSoon,
                    style: const TextStyle(
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
      bottomNavigationBar: PillarBottomNav(activeIdx: navIdx),
    );
  }
}
