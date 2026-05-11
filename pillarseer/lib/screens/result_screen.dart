import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../providers/saju_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final result = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _PillarGrid(result: result),
            const SizedBox(height: 32),
            _DayMasterCard(result: result),
            const SizedBox(height: 24),
            _ElementsBar(result: result),
            const SizedBox(height: 24),
            _CategoryGrid(result: result),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => showComingSoonModal(context),
              icon: const Icon(Icons.lock_open),
              label: Text(l.resultUnlockFull),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.celestialGold,
                foregroundColor: AppColors.midnightPurple,
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_forward, color: AppColors.celestialGold),
              label: Text(
                l.resultContinueDaily,
                style: const TextStyle(color: AppColors.ghostlyWhite, letterSpacing: 1.0),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: AppColors.celestialGold.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => showComingSoonModal(context),
              icon: const Icon(Icons.share, color: AppColors.moonlightGray),
              label: Text(l.resultShare,
                  style: const TextStyle(color: AppColors.moonlightGray)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 1),
    );
  }
}

class _PillarGrid extends StatelessWidget {
  final SajuResult result;
  const _PillarGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PillarItem(label: l.resultPillarYear, pillar: result.yearPillar),
            _PillarItem(label: l.resultPillarMonth, pillar: result.monthPillar),
            _PillarItem(
                label: l.resultPillarDay,
                pillar: result.dayPillar,
                highlight: true),
            _PillarItem(label: l.resultPillarHour, pillar: result.hourPillar),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }
}

class _PillarItem extends StatelessWidget {
  final String label;
  final Pillar? pillar;
  final bool highlight;

  const _PillarItem({required this.label, required this.pillar, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final isNull = pillar == null;
    final borderColor = highlight
        ? AppColors.celestialGold
        : AppColors.celestialGold.withValues(alpha: 0.3);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.moonlightGray,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.midnightPurple.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: highlight ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(
                isNull ? '?' : pillar!.chunGan,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.celestialGold),
              ),
              const SizedBox(height: 2),
              Text(
                isNull ? '?' : pillar!.jiJi,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ghostlyWhite),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 68,
          child: Text(
            isNull ? '—' : pillar!.pairEnglish,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.moonlightGray,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayMasterCard extends StatelessWidget {
  final SajuResult result;
  const _DayMasterCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.celestialGold.withValues(alpha: 0.15),
            AppColors.spiritIndigo.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.celestialGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            l.resultDayMaster.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: AppColors.moonlightGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${result.dayMasterName} (${result.day60ji})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.celestialGold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.ghostlyWhite,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 500.ms, duration: 500.ms);
  }
}

class _ElementsBar extends StatelessWidget {
  final SajuResult result;
  const _ElementsBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final el = result.elements;
    final dom = el.dominant;
    final def = el.deficit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.resultFiveElements.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2.0,
              color: AppColors.moonlightGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _row('Wood', '木', el.wood, dom, def),
        _row('Fire', '火', el.fire, dom, def),
        _row('Earth', '土', el.earth, dom, def),
        _row('Metal', '金', el.metal, dom, def),
        _row('Water', '水', el.water, dom, def),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _row(String name, String han, int pct, String dom, String def) {
    final color = AppColors.forElement(han);
    final isDom = han == dom;
    final isDef = han == def;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Text(
              han,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Text(name,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.moonlightGray)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                backgroundColor: AppColors.spiritIndigo.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.ghostlyWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isDom)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.star, size: 11, color: AppColors.celestialGold),
                  )
                else if (isDef)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 11, color: AppColors.fadedSilver),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final SajuResult result;
  const _CategoryGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final cats = <_Cat>[
      _Cat(icon: Icons.bolt, title: l.resultStrength, key: 'personality', locked: false),
      _Cat(icon: Icons.favorite, title: l.resultLove, key: 'love', locked: false),
      _Cat(icon: Icons.work_outline, title: l.resultCareer, key: 'career', locked: true),
      _Cat(icon: Icons.savings_outlined, title: l.resultWealth, key: 'money', locked: true),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: cats.map((c) {
        final reading = result.categoryReadings[c.key] ?? '';
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.spiritIndigo
                    .withValues(alpha: c.locked ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.celestialGold
                        .withValues(alpha: c.locked ? 0.1 : 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c.icon,
                      size: 22,
                      color: c.locked
                          ? AppColors.celestialGold.withValues(alpha: 0.5)
                          : AppColors.celestialGold),
                  const SizedBox(height: 4),
                  Text(
                    c.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: c.locked
                          ? AppColors.ghostlyWhite.withValues(alpha: 0.5)
                          : AppColors.ghostlyWhite,
                    ),
                  ),
                  if (!c.locked) ...[
                    const SizedBox(height: 6),
                    Text(
                      reading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.moonlightGray,
                          height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            if (c.locked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppColors.celestialGold.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 10, color: AppColors.celestialGold),
                      SizedBox(width: 3),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.8,
                          color: AppColors.celestialGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    ).animate().fadeIn(delay: 1.seconds);
  }
}

class _Cat {
  final IconData icon;
  final String title;
  final String key;
  final bool locked;
  const _Cat({
    required this.icon,
    required this.title,
    required this.key,
    required this.locked,
  });
}
