// Pillar Seer — Result screen. 8섹션 deep reading + Pro Lock.
// Free user 는 Day Master + Five Elements + Life Themes(Career/Wealth/Love) 만 unlocked.
// devUnlockProvider true 면 모두 unlocked.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/saju_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final result = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final isPro = ref.watch(devUnlockProvider);
    final overrideLocale = ref.watch(localeProvider);
    final systemLocale = Localizations.maybeLocaleOf(context);
    final lang = (overrideLocale?.languageCode ?? systemLocale?.languageCode ?? 'en');
    final useKo = lang == 'ko';
    final reading = useKo ? result.deepKo : result.deepEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PillarGrid(result: result),
            const SizedBox(height: 28),
            _DayMasterCard(result: result),
            const SizedBox(height: 24),
            _SectionShell(
              title: l.resultDayMasterDeepTitle,
              locked: false,
              child: _LongText(text: reading?.dayMasterDeep ?? result.summary),
            ),
            const SizedBox(height: 18),
            _SectionShell(
              title: l.resultFiveElementsDetailTitle,
              locked: false,
              child: _ElementsBar(result: result),
            ),
            const SizedBox(height: 18),
            _SectionShell(
              title: l.resultTenGodsTitle,
              locked: !isPro,
              child: _TenGodsTable(rows: result.tenGods, useKo: useKo),
            ),
            const SizedBox(height: 18),
            _LifeThemesBlock(
              reading: reading,
              isPro: isPro,
            ),
            const SizedBox(height: 18),
            _SectionShell(
              title: l.resultTenYearLuckTitle,
              locked: !isPro,
              child: _LongText(
                text: reading?.tenYearLuck ?? '',
              ),
            ),
            const SizedBox(height: 18),
            _SectionShell(
              title: l.resultThisYearTitle,
              locked: !isPro,
              child: _LongText(
                text: reading?.thisYear ?? '',
              ),
            ),
            const SizedBox(height: 18),
            _SectionShell(
              title: l.resultLuckyTitle,
              locked: !isPro,
              child: _LuckyBlock(reading: reading, useKo: useKo),
            ),
            const SizedBox(height: 28),
            if (!isPro)
              ElevatedButton.icon(
                onPressed: () => showComingSoonModal(context),
                icon: const Icon(Icons.lock_open),
                label: Text(l.resultUnlockFull),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.celestialGold,
                  foregroundColor: AppColors.midnightPurple,
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            if (!isPro) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_forward,
                  color: AppColors.celestialGold),
              label: Text(
                l.resultContinueDaily,
                style: const TextStyle(
                    color: AppColors.ghostlyWhite, letterSpacing: 1.0),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(
                  color: AppColors.celestialGold.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => showComingSoonModal(context),
              icon: const Icon(Icons.share, color: AppColors.moonlightGray),
              label: Text(
                l.resultShare,
                style: const TextStyle(color: AppColors.moonlightGray),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 1),
    );
  }
}

// ──────── Pillar grid (4기둥)

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
          minWidth: MediaQuery.of(context).size.width - 40,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PillarItem(label: l.resultPillarYear, pillar: result.yearPillar),
            _PillarItem(label: l.resultPillarMonth, pillar: result.monthPillar),
            _PillarItem(
              label: l.resultPillarDay,
              pillar: result.dayPillar,
              highlight: true,
            ),
            _PillarItem(label: l.resultPillarHour, pillar: result.hourPillar),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.1, end: 0);
  }
}

class _PillarItem extends StatelessWidget {
  final String label;
  final Pillar? pillar;
  final bool highlight;
  const _PillarItem({
    required this.label,
    required this.pillar,
    this.highlight = false,
  });

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
                  color: AppColors.celestialGold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isNull ? '?' : pillar!.jiJi,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ghostlyWhite,
                ),
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

// ──────── Day Master quick card

class _DayMasterCard extends StatelessWidget {
  final SajuResult result;
  const _DayMasterCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.celestialGold.withValues(alpha: 0.18),
            AppColors.spiritIndigo.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: 0.55),
        ),
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
    ).animate().scale(delay: 400.ms, duration: 500.ms);
  }
}

// ──────── Section shell — title + Pro lock pill

class _SectionShell extends StatelessWidget {
  final String title;
  final bool locked;
  final Widget child;
  const _SectionShell({
    required this.title,
    required this.locked,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: locked ? 0.12 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    color: locked
                        ? AppColors.celestialGold.withValues(alpha: 0.55)
                        : AppColors.celestialGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.celestialGold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 10, color: AppColors.celestialGold),
                      const SizedBox(width: 4),
                      Text(
                        l.resultProLocked,
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: AppColors.celestialGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (locked)
            _LockedPlaceholder()
          else
            child,
        ],
      ),
    );
  }
}

class _LockedPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: () => showComingSoonModal(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.midnightPurple.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: AppColors.celestialGold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.resultUnlockHint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.fadedSilver,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────── Long text body

class _LongText extends StatelessWidget {
  final String text;
  const _LongText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        color: AppColors.ghostlyWhite,
        height: 1.7,
      ),
    );
  }
}

// ──────── Five elements bar

class _ElementsBar extends StatelessWidget {
  final SajuResult result;
  const _ElementsBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final el = result.elements;
    final dom = el.dominant;
    final def = el.deficit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Wood', '木', el.wood, dom, def),
        _row('Fire', '火', el.fire, dom, def),
        _row('Earth', '土', el.earth, dom, def),
        _row('Metal', '金', el.metal, dom, def),
        _row('Water', '水', el.water, dom, def),
      ],
    );
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
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.moonlightGray,
              ),
            ),
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
            width: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.ghostlyWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isDom)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.star,
                        size: 11, color: AppColors.celestialGold),
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

// ──────── Ten Gods table

class _TenGodsTable extends StatelessWidget {
  final List<TenGodRow> rows;
  final bool useKo;
  const _TenGodsTable({required this.rows, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final headerStyle = const TextStyle(
      fontSize: 10,
      letterSpacing: 1.2,
      color: AppColors.moonlightGray,
      fontWeight: FontWeight.w700,
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(useKo ? '기둥' : 'PILLAR', style: headerStyle),
            ),
            Expanded(
              flex: 3,
              child: Text(useKo ? '천간' : 'HEAVENLY', style: headerStyle),
            ),
            Expanded(
              flex: 3,
              child: Text(useKo ? '지지' : 'EARTHLY', style: headerStyle),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _posLabel(row.position, useKo),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ghostlyWhite,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.chunGanGod == null
                          ? '—'
                          : (useKo ? row.chunGanGod!.ko : row.chunGanGod!.en),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.celestialGold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.jiJiGod == null
                          ? '—'
                          : (useKo ? row.jiJiGod!.ko : row.jiJiGod!.en),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.celestialGold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _posLabel(String pos, bool ko) {
    if (ko) {
      switch (pos) {
        case 'year':
          return '년주';
        case 'month':
          return '월주';
        case 'day':
          return '일주';
        case 'hour':
          return '시주';
      }
    }
    switch (pos) {
      case 'year':
        return 'Year';
      case 'month':
        return 'Month';
      case 'day':
        return 'Day';
      case 'hour':
        return 'Hour';
    }
    return pos;
  }
}

// ──────── Life themes — 6 cards (Career/Wealth/Love/Health/Family/Fame)

class _LifeThemesBlock extends StatelessWidget {
  final DeepReading? reading;
  final bool isPro;
  const _LifeThemesBlock({required this.reading, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final themes = <_ThemeItem>[
      _ThemeItem(l.resultThemeCareer, Icons.work_outline,
          reading?.career ?? '', locked: false),
      _ThemeItem(l.resultThemeWealth, Icons.savings_outlined,
          reading?.wealth ?? '', locked: false),
      _ThemeItem(l.resultThemeLove, Icons.favorite_border,
          reading?.love ?? '', locked: false),
      _ThemeItem(l.resultThemeHealth, Icons.spa_outlined,
          reading?.health ?? '', locked: !isPro),
      _ThemeItem(l.resultThemeFamily, Icons.diversity_3,
          reading?.family ?? '', locked: !isPro),
      _ThemeItem(l.resultThemeFame, Icons.auto_awesome,
          reading?.fame ?? '', locked: !isPro),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.resultLifeThemesTitle.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              color: AppColors.celestialGold,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...themes.map((t) => _ThemeCard(item: t)),
        ],
      ),
    );
  }
}

class _ThemeItem {
  final String title;
  final IconData icon;
  final String text;
  final bool locked;
  const _ThemeItem(this.title, this.icon, this.text, {required this.locked});
}

class _ThemeCard extends StatelessWidget {
  final _ThemeItem item;
  const _ThemeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.midnightPurple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.celestialGold
              .withValues(alpha: item.locked ? 0.08 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 16,
                color: item.locked
                    ? AppColors.celestialGold.withValues(alpha: 0.5)
                    : AppColors.celestialGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: item.locked
                        ? AppColors.fadedSilver
                        : AppColors.ghostlyWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.celestialGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 9, color: AppColors.celestialGold),
                      const SizedBox(width: 3),
                      Text(
                        l.resultProLocked,
                        style: const TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.8,
                          color: AppColors.celestialGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.locked)
            InkWell(
              onTap: () => showComingSoonModal(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l.resultUnlockHint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.fadedSilver,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            Text(
              item.text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.ghostlyWhite,
                height: 1.7,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────── Lucky alignments

class _LuckyBlock extends StatelessWidget {
  final DeepReading? reading;
  final bool useKo;
  const _LuckyBlock({required this.reading, required this.useKo});

  @override
  Widget build(BuildContext context) {
    if (reading == null) return const SizedBox.shrink();
    return Column(
      children: [
        _row(Icons.palette_outlined, useKo ? '행운의 색' : 'Lucky Color',
            reading!.luckyColor),
        _row(Icons.tag, useKo ? '행운의 숫자' : 'Lucky Number',
            '${reading!.luckyNumber}'),
        _row(Icons.explore_outlined, useKo ? '행운의 방향' : 'Lucky Direction',
            reading!.luckyDirection),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.moonlightGray),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.moonlightGray,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.celestialGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
