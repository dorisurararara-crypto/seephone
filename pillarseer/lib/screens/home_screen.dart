import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../models/daily_fortune.dart';
import '../services/daily_service.dart';
import '../providers/saju_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';

/// Home (Today's Energy). 사용자 사주 + 오늘 일진 → 종합 점수 + 4 카테고리 + Lucky.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saju = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final birth = ref.watch(userBirthInfoProvider);
    final fortune = DailyService().calculate(saju);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            children: [
              _Header(name: birth?.name, dayMasterName: saju.dayMasterName),
              _Date(date: fortune.date),
              const SizedBox(height: 12),
              const _MoonDeco(),
              _ScoreCircle(score: fortune.totalScore),
              _ScoreExplanation(score: fortune.totalScore),
              _Quote(quote: fortune.quote),
              _TodayPillarRow(
                dayPillar: fortune.dayPillar,
                englishLabel: _englishForGanji(fortune.dayPillar),
              ),
              _CategoryGrid(fortune: fortune),
              _LuckyCard(fortune: fortune),
              const _PromoCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 0),
    );
  }

  /// 60갑자 텍스트 → 영문 일주 이름 (예: 丙午 → "Fire Horse").
  /// dummy fallback 이거나 길이가 다르면 원문 그대로 반환.
  String _englishForGanji(String ganji) {
    if (ganji.length != 2) return '';
    final p = Pillar(chunGan: ganji[0], jiJi: ganji[1]);
    return p.pairEnglish;
  }
}

class _Header extends StatelessWidget {
  final String? name;
  final String dayMasterName;
  const _Header({required this.name, required this.dayMasterName});

  String _greeting(AppL10n l) {
    final h = DateTime.now().hour;
    if (h < 5) return '${l.homeGreetingNight},';
    if (h < 12) return '${l.homeGreetingMorning},';
    if (h < 18) return '${l.homeGreetingAfternoon},';
    return '${l.homeGreetingEvening},';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final displayName = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : dayMasterName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(l),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.moonlightGray,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 2),
                Text(
                  '$displayName  ✦',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ghostlyWhite,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none,
                  size: 22, color: AppColors.moonlightGray),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.celestialGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Date extends StatelessWidget {
  final DateTime date;
  const _Date({required this.date});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.toString();
    final fmt = DateFormat('EEE · MMM d, y', locale);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        fmt.format(date).toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.moonlightGray,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MoonDeco extends StatelessWidget {
  const _MoonDeco();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '✦  ✦  ✦',
        style: TextStyle(
            fontSize: 12, color: AppColors.celestialGold, letterSpacing: 8),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int score;
  const _ScoreCircle({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.celestialGold.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7],
        ),
        border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.celestialGold.withValues(alpha: 0.2),
            blurRadius: 30,
          ),
        ],
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: '$score',
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: AppColors.celestialGold,
              height: 1,
            ),
            children: const [
              TextSpan(
                text: '\n/100',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.moonlightGray,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms).fadeIn();
  }
}

class _ScoreExplanation extends StatelessWidget {
  final int score;
  const _ScoreExplanation({required this.score});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final String msg;
    if (score < 50) {
      msg = l.homeExplanationLow;
    } else if (score < 75) {
      msg = l.homeExplanationMid;
    } else {
      msg = l.homeExplanationHigh;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.moonlightGray,
          height: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _Quote extends StatelessWidget {
  final String quote;
  const _Quote({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 14),
      child: Text(
        '"$quote"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.ghostlyWhite,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _TodayPillarRow extends StatelessWidget {
  final String dayPillar;
  final String englishLabel;
  const _TodayPillarRow({required this.dayPillar, required this.englishLabel});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final hasEnglish = englishLabel.isNotEmpty;
    final text = hasEnglish
        ? '${l.homeTodaysPillar} · $englishLabel ($dayPillar)'
        : '${l.homeTodaysPillar} · $dayPillar';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.spiritIndigo.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: AppColors.celestialGold.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.celestialGold,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final DailyFortune fortune;
  const _CategoryGrid({required this.fortune});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final cats = [
      _CatItem(icon: Icons.favorite, name: l.homeCategoryLove, score: fortune.loveScore),
      _CatItem(icon: Icons.work_outline, name: l.homeCategoryWork, score: fortune.workScore),
      _CatItem(
          icon: Icons.savings_outlined,
          name: l.homeCategoryWealth,
          score: fortune.wealthScore),
      _CatItem(icon: Icons.bolt, name: l.homeCategoryEnergy, score: fortune.energyScore),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: cats.map((c) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.spiritIndigo.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.celestialGold.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(c.icon, size: 18, color: AppColors.celestialGold),
                  const SizedBox(height: 4),
                  Text(
                    '${c.score}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.celestialGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.moonlightGray,
                      letterSpacing: 0.6,
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

class _CatItem {
  final IconData icon;
  final String name;
  final int score;
  const _CatItem({required this.icon, required this.name, required this.score});
}

class _LuckyCard extends StatelessWidget {
  final DailyFortune fortune;
  const _LuckyCard({required this.fortune});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        border:
            Border.all(color: AppColors.celestialGold.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Builder(builder: (context) {
        final l = AppL10n.of(context);
        return Column(
          children: [
            _row(Icons.palette_outlined, l.homeLuckyColor, fortune.luckyColor),
            _row(Icons.tag, l.homeLuckyNumber, '${fortune.luckyNumber}'),
            _row(Icons.explore_outlined, l.homeLuckyDirection,
                fortune.luckyDirection),
          ],
        );
      }),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.moonlightGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.moonlightGray)),
          ),
          Text(value,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.celestialGold,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: () => showComingSoonModal(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.celestialGold.withValues(alpha: 0.15),
              AppColors.spiritIndigo.withValues(alpha: 0.15),
            ],
          ),
          border:
              Border.all(color: AppColors.celestialGold.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.homePromoLimited,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.celestialGold,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.homePromoTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ghostlyWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.homePromoDesc,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.moonlightGray,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
