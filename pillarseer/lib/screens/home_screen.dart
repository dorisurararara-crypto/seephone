// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../models/daily_fortune.dart';
import '../services/daily_service.dart';
import '../services/hourly_service.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';

/// Home (Today's Energy). 사용자 사주 + 오늘 일진 → 종합 점수 + 4 카테고리 + Lucky.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 매일 첫 진입 시 streak tick
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider.notifier).tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saju = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final birth = ref.watch(userBirthInfoProvider);
    final fortune = DailyService().calculate(saju);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            children: [
              // 1. Greeting + streak (single block)
              _Header(name: birth?.name, dayMasterName: saju.dayMasterName),
              const _StreakChip(),
              // 2. 오늘 날짜
              const SizedBox(height: 6),
              _Date(date: fortune.date),
              // 3. 오늘의 점수 + 한 줄 (가장 큰 시각 임팩트)
              const SizedBox(height: 8),
              _ScoreCircle(score: fortune.totalScore),
              _ScoreExplanation(score: fortune.totalScore),
              _Quote(quoteEn: fortune.quoteEn, quoteKo: fortune.quoteKo),
              // 4. 오늘의 일진 한 줄 pill
              _TodayPillarRow(
                dayPillar: fortune.dayPillar,
                localizedLabel:
                    _localizedGanjiLabel(context, fortune.dayPillar),
              ),
              // 5. 시간대별 흐름 (지금/다음/저녁)
              const SizedBox(height: 4),
              _HourlyFlowCard(saju: saju),
              // 6. 카테고리 4종 점수 + 가이드 한 줄씩
              _CategoryGrid(fortune: fortune),
              _CategoryGuidesCard(fortune: fortune),
              // 7. 행운 (색·숫자·방향)
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

  /// 60갑자 텍스트 → locale 라벨 (예: 丙午 → "Fire Horse" / "화 말").
  String _localizedGanjiLabel(BuildContext context, String ganji) {
    if (ganji.length != 2) return '';
    final p = Pillar(chunGan: ganji[0], jiJi: ganji[1]);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return useKo ? p.pairKoreanMeaning : p.pairEnglish;
  }
}

class _NotifToggleCard extends ConsumerWidget {
  const _NotifToggleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final toggle = ref.watch(notificationProvider);
    final on = toggle.enabled;
    final saju = ref.watch(sajuResultProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    if (on) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationProvider.notifier).reconcileSchedule(
              pushTitle: l.homeNotifSampleTitle,
              pushBody: l.homeNotifSampleBody,
              day60ji: saju?.day60ji,
              useKo: useKo,
            );
      });
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.celestialGold.withValues(alpha: on ? 0.25 : 0.12),
              AppColors.spiritIndigo.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.celestialGold
                .withValues(alpha: on ? 0.7 : 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                color: AppColors.celestialGold, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.homeNotifTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ghostlyWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    on ? l.homeNotifOn : l.homeNotifSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: on
                          ? AppColors.celestialGold
                          : AppColors.moonlightGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: on,
              activeThumbColor: AppColors.celestialGold,
              activeTrackColor:
                  AppColors.celestialGold.withValues(alpha: 0.4),
              onChanged: (v) async {
                final notifier = ref.read(notificationProvider.notifier);
                final messenger = ScaffoldMessenger.of(context);
                if (v) {
                  final ok = await notifier.enable(
                    pushTitle: l.homeNotifSampleTitle,
                    pushBody: l.homeNotifSampleBody,
                    day60ji: saju?.day60ji,
                    useKo: useKo,
                  );
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ok
                          ? AppColors.celestialGold
                          : Colors.redAccent.shade200,
                      content: Text(
                        ok
                            ? l.homeNotifEnabledSnack
                            : l.homeNotifPermissionDenied,
                        style: const TextStyle(
                          color: AppColors.cosmicBlack,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ));
                } else {
                  await notifier.disable();
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.spiritIndigo,
                      content: Text(l.homeNotifDisabledSnack),
                    ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends ConsumerWidget {
  const _StreakChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final streak = ref.watch(streakProvider);
    if (streak.current <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.fireRed.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.fireRed.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  l.homeStreakDays(streak.current),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.fireRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (streak.celebrate) ...[
            const SizedBox(width: 8),
            Text(
              l.homeStreakNewDay,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.celestialGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const Spacer(),
          if (streak.longest > streak.current)
            Text(
              l.homeStreakLongest(streak.longest),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.fadedSilver,
              ),
            ),
        ],
      ),
    );
  }
}

class _HourlyFlowCard extends ConsumerWidget {
  final SajuResult saju;
  const _HourlyFlowCard({required this.saju});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final localeCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final useKo = localeCode == 'ko';
    final slots = HourlyService.twelveSlots(saju);
    // 현재 + 다음 2 슬롯 (3개) — codex 권고
    final currentIdx = slots.indexWhere((s) => s.isCurrent);
    final base = currentIdx >= 0 ? currentIdx : 0;
    final picks = [
      slots[base % 12],
      slots[(base + 1) % 12],
      slots[(base + 2) % 12],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.spiritIndigo.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.homeHourlyTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.celestialGold,
                    ),
                  ),
                ),
                Text(
                  l.homeHourlySubtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.moonlightGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _HourlySlotTile(
                        slot: picks[0],
                        labelOverride: l.homeHourlyNow,
                        accent: true,
                        useKo: useKo)),
                const SizedBox(width: 8),
                Expanded(
                    child: _HourlySlotTile(
                        slot: picks[1],
                        labelOverride: l.homeHourlyNext,
                        useKo: useKo)),
                const SizedBox(width: 8),
                Expanded(
                    child: _HourlySlotTile(
                        slot: picks[2],
                        labelOverride: l.homeHourlyLater,
                        useKo: useKo)),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showAll(context, l, slots, useKo),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: AppColors.celestialGold),
                    const SizedBox(width: 6),
                    Text(
                      l.homeHourlySeeAll,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.celestialGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.celestialGold),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAll(
      BuildContext context, AppL10n l, List<HourlySlot> slots, bool useKo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cosmicBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx2, scroll) => Container(
          decoration: BoxDecoration(
            color: AppColors.cosmicBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: AppColors.celestialGold.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.celestialGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Text(
                  l.homeHourlyFullTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.celestialGold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: slots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx3, i) {
                    final s = slots[i];
                    return _HourlySlotRow(slot: s, useKo: useKo);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourlySlotTile extends StatelessWidget {
  final HourlySlot slot;
  final String labelOverride;
  final bool accent;
  final bool useKo;
  const _HourlySlotTile({
    required this.slot,
    required this.labelOverride,
    this.accent = false,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final moodColor = _moodColor(slot.mood);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.celestialGold.withValues(alpha: 0.15)
            : AppColors.midnightPurple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent
              ? AppColors.celestialGold
              : AppColors.celestialGold.withValues(alpha: 0.25),
          width: accent ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelOverride.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.0,
              color: accent
                  ? AppColors.celestialGold
                  : AppColors.moonlightGray,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: moodColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${slot.score}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ghostlyWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            slot.label(useKo),
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.fadedSilver,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'peak':
        return AppColors.celestialGold;
      case 'good':
        return AppColors.woodJade;
      case 'neutral':
        return AppColors.fadedSilver;
      case 'avoid':
        return AppColors.fireRed.withValues(alpha: 0.8);
      default:
        return AppColors.moonlightGray;
    }
  }
}

class _HourlySlotRow extends StatelessWidget {
  final HourlySlot slot;
  final bool useKo;
  const _HourlySlotRow({required this.slot, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final moodColor = _moodColor(slot.mood);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: slot.isCurrent
            ? AppColors.celestialGold.withValues(alpha: 0.12)
            : AppColors.spiritIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slot.isCurrent
              ? AppColors.celestialGold
              : AppColors.celestialGold.withValues(alpha: 0.2),
          width: slot.isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            alignment: Alignment.center,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.midnightPurple.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: moodColor.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              children: [
                Text(
                  slot.jiJi,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: moodColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot.score}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ghostlyWhite,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label(useKo),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.celestialGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  useKo ? slot.guideKo : slot.guideEn,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ghostlyWhite,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'peak':
        return AppColors.celestialGold;
      case 'good':
        return AppColors.woodJade;
      case 'neutral':
        return AppColors.fadedSilver;
      case 'avoid':
        return AppColors.fireRed.withValues(alpha: 0.8);
      default:
        return AppColors.moonlightGray;
    }
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
    final locale = Localizations.maybeLocaleOf(context);
    final useKo = locale?.languageCode == 'ko';
    final text = useKo
        ? '${date.year}년 ${date.month}월 ${date.day}일 ${_weekdayKo(date.weekday)}요일'
        : DateFormat('EEE · MMM d, y', locale?.toString()).format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          color: AppColors.moonlightGray,
          letterSpacing: useKo ? 0 : 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _weekdayKo(int w) {
    const map = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    return map[w] ?? '';
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
    return Semantics(
      label: 'Today\'s energy score: $score out of 100',
      excludeSemantics: true,
      child: Container(
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
      ).animate().scale(duration: 600.ms).fadeIn(),
    );
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
  final String quoteEn;
  final String quoteKo;
  const _Quote({required this.quoteEn, required this.quoteKo});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final text = useKo ? (quoteKo.isEmpty ? quoteEn : quoteKo) : quoteEn;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 14),
      child: Text(
        '"$text"',
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
  final String localizedLabel;
  const _TodayPillarRow({
    required this.dayPillar,
    required this.localizedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final hasLabel = localizedLabel.isNotEmpty;
    final text = hasLabel
        ? '${l.homeTodaysPillar} · $localizedLabel ($dayPillar)'
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

class _CategoryGuidesCard extends StatelessWidget {
  final DailyFortune fortune;
  const _CategoryGuidesCard({required this.fortune});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final entries = [
      (icon: Icons.favorite, label: l.homeCategoryLove, emoji: '💞',
          text: useKo ? fortune.loveGuideKo : fortune.loveGuideEn),
      (icon: Icons.work_outline, label: l.homeCategoryWork, emoji: '💼',
          text: useKo ? fortune.workGuideKo : fortune.workGuideEn),
      (icon: Icons.savings_outlined, label: l.homeCategoryWealth, emoji: '💰',
          text: useKo ? fortune.wealthGuideKo : fortune.wealthGuideEn),
      (icon: Icons.bolt, label: l.homeCategoryEnergy, emoji: '⚡',
          text: useKo ? fortune.energyGuideKo : fortune.energyGuideEn),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: entries.where((e) => e.text.isNotEmpty).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(
                      e.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                        color: AppColors.celestialGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ghostlyWhite,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
      ),
    );
  }
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
