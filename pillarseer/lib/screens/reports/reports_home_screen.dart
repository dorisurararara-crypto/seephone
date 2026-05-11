// Pillar Seer — Reports 메뉴 화면. 4 카드 grid 진입.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final cards = <_ReportCard>[
      _ReportCard(
        title: l.reportsCardCompatibility,
        desc: l.reportsCardCompatibilityDesc,
        icon: Icons.favorite,
        route: '/reports/compatibility',
        symbol: '宮合',
      ),
      _ReportCard(
        title: l.reportsCardTojeong,
        desc: l.reportsCardTojeongDesc,
        icon: Icons.menu_book_outlined,
        route: '/reports/tojeong',
        symbol: '土亭',
      ),
      _ReportCard(
        title: l.reportsCardDatePicking,
        desc: l.reportsCardDatePickingDesc,
        icon: Icons.event_available,
        route: '/reports/date-picking',
        symbol: '擇日',
      ),
      _ReportCard(
        title: l.reportsCardDream,
        desc: l.reportsCardDreamDesc,
        icon: Icons.nights_stay_outlined,
        route: '/reports/dream',
        symbol: '解夢',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                child: Text(
                  l.reportsHomeTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.celestialGold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  l.reportsHomeSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.moonlightGray,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
              ...cards.map((c) => _ReportTile(card: c)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }
}

class _ReportCard {
  final String title;
  final String desc;
  final IconData icon;
  final String route;
  final String symbol;
  const _ReportCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.route,
    required this.symbol,
  });
}

class _ReportTile extends StatelessWidget {
  final _ReportCard card;
  const _ReportTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go(card.route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.spiritIndigo.withValues(alpha: 0.15),
                AppColors.midnightPurple.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.celestialGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.celestialGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.celestialGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 6,
                      right: 8,
                      child: Text(
                        card.symbol,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.celestialGold
                              .withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(card.icon,
                        size: 26, color: AppColors.celestialGold),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ghostlyWhite,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.desc,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.moonlightGray,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.fadedSilver),
            ],
          ),
        ),
      ),
    );
  }
}
