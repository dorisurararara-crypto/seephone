// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../models/daily_fortune.dart';
import '../services/daily_service.dart';
import '../services/hourly_service.dart';
import '../services/today_deep_service.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';

/// Aesop Luxury home — 텍스트 위주 magazine editorial.
/// 그라데이션 X, 카드 그림자 X, 둥근 모서리 X. 모든 강조는 letter-spacing UPPERCASE + 한자 + italic accent.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider.notifier).tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saju = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final birth = ref.watch(userBirthInfoProvider);
    final fortune = DailyService().calculate(saju);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppBarBlock(),
              _HeroGreeting(
                name: birth?.name,
                dayMaster: useKo
                    ? saju.dayPillar.pairKoreanMeaning
                    : saju.dayMasterName,
                date: fortune.date,
              ),
              _StreakLine(),
              _ScoreBlock(
                score: fortune.totalScore,
                quote: useKo
                    ? (fortune.quoteKo.isEmpty ? fortune.quoteEn : fortune.quoteKo)
                    : fortune.quoteEn,
              ),
              _PillarOfTheDay(
                dayPillar: fortune.dayPillar,
                label: _localizedGanjiLabel(context, fortune.dayPillar),
              ),
              // 신규 — 사주 깊이 기반 오늘 풀이 (codex Round 11+)
              _TodayDeepReadingSection(
                reading: TodayDeepService.build(
                  userDayStem: saju.dayPillar.chunGan,
                  userDayBranch: saju.dayPillar.jiJi,
                  userMonthBranch: saju.monthPillar.jiJi,
                  userDominantEl: saju.elements.dominant,
                  userDeficitEl: saju.elements.deficit,
                  todayPillar: fortune.dayPillar,
                  todayScore: fortune.totalScore,
                ),
              ),
              _HourlyFlowSection(saju: saju),
              _CategorySection(fortune: fortune),
              _CategoryGuides(fortune: fortune),
              _LuckySection(fortune: fortune),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 0),
    );
  }

  String _localizedGanjiLabel(BuildContext context, String ganji) {
    if (ganji.length != 2) return '';
    final p = Pillar(chunGan: ganji[0], jiJi: ganji[1]);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return useKo ? p.pairKoreanMeaning : p.pairEnglish;
  }
}

// ──────────── App bar ────────────

class _AppBarBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'P I L L A R    S E E R',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 5,
              color: AppColors.ink,
            ),
          ),
          Text(
            useKo ? '오늘 · 今 日' : 'TODAY · 今 日',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
              color: AppColors.inkLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Hero greeting ────────────

class _HeroGreeting extends StatelessWidget {
  final String? name;
  final String dayMaster;
  final DateTime date;
  const _HeroGreeting({
    required this.name,
    required this.dayMaster,
    required this.date,
  });

  String _greeting(AppL10n l) {
    final h = DateTime.now().hour;
    if (h < 5) return l.homeGreetingNight;
    if (h < 12) return l.homeGreetingMorning;
    if (h < 18) return l.homeGreetingAfternoon;
    return l.homeGreetingEvening;
  }

  String _dateText(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final useKo = locale?.languageCode == 'ko';
    if (useKo) {
      const wd = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
      return '${date.year}년 ${date.month}월 ${date.day}일 ${wd[date.weekday] ?? ''}요일';
    }
    return DateFormat('EEEE · MMMM d, y', locale?.toString()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final displayName = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : dayMaster;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateText(context).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_greeting(l)},',
            style: GoogleFonts.notoSerifKr(
              fontSize: 17,
              fontWeight: FontWeight.w300,
              color: AppColors.inkLight,
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayName,
            style: GoogleFonts.notoSerifKr(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
              height: 1.2,
              color: AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ──────────── Streak line ────────────

class _StreakLine extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final streak = ref.watch(streakProvider);
    if (streak.current <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            l.homeStreakDays(streak.current).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
          if (streak.celebrate) ...[
            const SizedBox(width: 12),
            Text(
              l.homeStreakNewDay.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 3,
                color: AppColors.inkLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Spacer(),
          if (streak.longest > streak.current)
            Text(
              l.homeStreakLongest(streak.longest).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 3,
                color: AppColors.taupe,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────── Score block ────────────

class _ScoreBlock extends StatelessWidget {
  final int score;
  final String quote;
  const _ScoreBlock({required this.score, required this.quote});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final explanation = score < 50
        ? l.homeExplanationLow
        : (score < 75 ? l.homeExplanationMid : l.homeExplanationHigh);
    final ({String label, String hint, Color accent}) status;
    if (score >= 75) {
      status = (
        label: useKo ? '오늘은 좋은 날' : 'A good day',
        hint: useKo
            ? '평소보다 흐름이 잘 풀립니다. 미뤘던 일을 시작해보세요.'
            : 'Flow is on your side. Start what you delayed.',
        accent: AppColors.woodJade,
      );
    } else if (score >= 50) {
      status = (
        label: useKo ? '오늘은 보통보다 조심' : 'Steady — proceed with care',
        hint: useKo
            ? '큰 결정은 미루고, 확인이 필요한 일을 처리하기 좋아요.'
            : 'Defer big calls. Handle the checklists.',
        accent: AppColors.accent,
      );
    } else {
      status = (
        label: useKo ? '오늘은 쉬어가는 날' : 'A resting day',
        hint: useKo
            ? '에너지를 아끼세요. 새 시작보다 정리·휴식이 더 도움됩니다.'
            : 'Conserve energy. Today rewards tidying and rest.',
        accent: AppColors.fireRed,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 한국어 메인 라벨
          Text(
            useKo ? '오늘의 기운 점수' : "Today's energy score",
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 4),
          // 영문 + 한자는 작은 sub
          Text(
            "Today's energy · 日 氣",
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          // 상태명 — 사용자가 즉시 이해
          Text(
            status.label,
            style: GoogleFonts.notoSerifKr(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: status.accent,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 10),
          // 행동 hint — 무엇을 해야 하는지
          Text(
            status.hint,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          // 점수 — 작게 sub (참고용). 한 행에 점수 + / 100 만 (overflow 방지).
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score점',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ 100',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
          // 점수 풀이 — 다음 줄에 (overflow 안 나도록)
          const SizedBox(height: 6),
          Text(
            explanation,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: AppColors.inkLight,
              height: 1.6,
            ),
          ),
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '"$quote"',
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.accent,
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ],
      ),
    );
  }
}

// ──────────── Pillar of the day ────────────

class _PillarOfTheDay extends StatelessWidget {
  final String dayPillar;
  final String label;
  const _PillarOfTheDay({required this.dayPillar, required this.label});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 한국어 메인 라벨
          Text(
            l.homeTodaysPillar,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          // 한국어 의미 메인 (예: '화 개' = fire dog)
          if (label.isNotEmpty)
            Text(
              label,
              style: GoogleFonts.notoSerifKr(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                letterSpacing: 0.3,
              ),
            ),
          const SizedBox(height: 6),
          // 한자 60갑자는 작은 sub-accent
          Text(
            useKo ? '$dayPillar · 오늘의 60갑자' : '$dayPillar · today\'s ganji',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w400,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Hourly flow ────────────

class _HourlyFlowSection extends ConsumerWidget {
  final SajuResult saju;
  const _HourlyFlowSection({required this.saju});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final slots = HourlyService.twelveSlots(saju);
    final currentIdx = slots.indexWhere((s) => s.isCurrent);
    final base = currentIdx >= 0 ? currentIdx : 0;
    final picks = [
      slots[base % 12],
      slots[(base + 1) % 12],
      slots[(base + 2) % 12],
    ];
    final labels = [l.homeHourlyNow, l.homeHourlyNext, l.homeHourlyLater];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.homeHourlyTitle.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.line),
                left: BorderSide(color: AppColors.line),
              ),
            ),
            child: Row(
              children: picks.asMap().entries.map((e) {
                return Expanded(
                  child: _HourlyCell(
                    slot: e.value,
                    label: labels[e.key],
                    useKo: useKo,
                    isFirst: e.key == 0,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => _showAll(context, l, slots, useKo),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.homeHourlySeeAll.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '→',
                  style: TextStyle(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAll(
      BuildContext context, AppL10n l, List<HourlySlot> slots, bool useKo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.94,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx2, scroll) => Container(
          color: AppColors.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 1,
                  color: AppColors.line,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TWELVE  HOURS · 十 二 時',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.taupe,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.homeHourlyFullTitle,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: ListView.separated(
                  controller: scroll,
                  padding: EdgeInsets.zero,
                  itemCount: slots.length,
                  separatorBuilder: (_, _) => const Divider(
                      height: 1, color: AppColors.line, thickness: 0.6),
                  itemBuilder: (ctx3, i) => _HourlyRow(slot: slots[i], useKo: useKo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourlyCell extends StatelessWidget {
  final HourlySlot slot;
  final String label;
  final bool useKo;
  final bool isFirst;
  const _HourlyCell({
    required this.slot,
    required this.label,
    required this.useKo,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final isPeak = slot.mood == 'peak';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 8.5,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${slot.score}',
            style: GoogleFonts.notoSerifKr(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: isPeak ? AppColors.accent : AppColors.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            slot.label(useKo),
            style: GoogleFonts.notoSansKr(
              fontSize: 10.5,
              color: AppColors.inkLight,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HourlyRow extends StatelessWidget {
  final HourlySlot slot;
  final bool useKo;
  const _HourlyRow({required this.slot, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: slot.isCurrent ? AppColors.paper : AppColors.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.jiJi,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: slot.isCurrent ? AppColors.accent : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${slot.score}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label(useKo).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  useKo ? slot.guideKo : slot.guideEn,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Category 4종 ────────────

class _CategorySection extends StatelessWidget {
  final DailyFortune fortune;
  const _CategorySection({required this.fortune});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final rows = [
      (l.homeCategoryLove, '愛', fortune.loveScore),
      (l.homeCategoryWork, '事', fortune.workScore),
      (l.homeCategoryWealth, '財', fortune.wealthScore),
      (l.homeCategoryEnergy, '氣', fortune.energyScore),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOUR  AREAS · 四 域',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.line),
                left: BorderSide(color: AppColors.line),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: rows
                      .sublist(0, 2)
                      .map((r) => Expanded(
                          child: _CategoryCell(
                              name: r.$1, glyph: r.$2, score: r.$3)))
                      .toList(),
                ),
                Row(
                  children: rows
                      .sublist(2, 4)
                      .map((r) => Expanded(
                          child: _CategoryCell(
                              name: r.$1, glyph: r.$2, score: r.$3)))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final String name;
  final String glyph;
  final int score;
  const _CategoryCell({
    required this.name,
    required this.glyph,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.line),
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                glyph,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$score',
            style: GoogleFonts.notoSerifKr(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: AppColors.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 24, height: 1, color: AppColors.line),
        ],
      ),
    );
  }
}

// ──────────── Category guides ────────────

class _CategoryGuides extends StatelessWidget {
  final DailyFortune fortune;
  const _CategoryGuides({required this.fortune});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final rows = [
      (l.homeCategoryLove, useKo ? fortune.loveGuideKo : fortune.loveGuideEn),
      (l.homeCategoryWork, useKo ? fortune.workGuideKo : fortune.workGuideEn),
      (l.homeCategoryWealth, useKo ? fortune.wealthGuideKo : fortune.wealthGuideEn),
      (l.homeCategoryEnergy, useKo ? fortune.energyGuideKo : fortune.energyGuideEn),
    ].where((r) => r.$2.isNotEmpty).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S  GUIDANCE",
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isLast
                        ? BorderSide.none
                        : const BorderSide(color: AppColors.line, width: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.value.$1.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.taupe,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.value.$2,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.75,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ──────────── Lucky ────────────

class _LuckySection extends StatelessWidget {
  final DailyFortune fortune;
  const _LuckySection({required this.fortune});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final color = useKo
        ? (fortune.luckyColorKo.isEmpty ? fortune.luckyColor : fortune.luckyColorKo)
        : (fortune.luckyColorEn.isEmpty ? fortune.luckyColor : fortune.luckyColorEn);
    final direction = useKo
        ? (fortune.luckyDirectionKo.isEmpty
            ? fortune.luckyDirection
            : fortune.luckyDirectionKo)
        : (fortune.luckyDirectionEn.isEmpty
            ? fortune.luckyDirection
            : fortune.luckyDirectionEn);
    final rows = [
      (l.homeLuckyColor, color),
      (l.homeLuckyNumber, '${fortune.luckyNumber}'),
      (l.homeLuckyDirection, direction),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY  AUSPICIOUS · 吉',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
            ),
            child: Column(
              children: rows.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: AppColors.line, width: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.$1.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                            color: AppColors.taupe,
                          ),
                        ),
                      ),
                      Text(
                        r.$2,
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Today Deep Reading (사주 깊이 오늘 풀이) ────────────

class _TodayDeepReadingSection extends StatelessWidget {
  final TodayDeepReading reading;
  const _TodayDeepReadingSection({required this.reading});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final headline = useKo ? reading.headlineKo : reading.headlineEn;
    final body = useKo ? reading.bodyKo : reading.bodyEn;
    final actions = useKo ? reading.actionsKo : reading.actionsEn;
    final caution = useKo ? reading.cautionKo : reading.cautionEn;
    final bestTime = useKo ? reading.bestTimeKo : reading.bestTimeEn;
    final moodTag = useKo ? reading.moodTagKo : reading.moodTagEn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section meta
          Row(
            children: [
              Text(
                useKo ? '오늘 내 사주 풀이' : "Today's deep reading",
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration:
                    BoxDecoration(border: Border.all(color: AppColors.accent, width: 1)),
                child: Text(
                  moodTag.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    letterSpacing: 2,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // headline — 한국어 메인
          Text(
            headline,
            style: GoogleFonts.notoSerifKr(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          // body — 4-6 sentences
          Text(
            body,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
          const SizedBox(height: 22),
          // recommended actions
          Text(
            useKo ? '오늘 추천 · 行' : 'Try today · 行',
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 10),
          ...actions.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 10),
                      child: Container(
                          width: 4, height: 4, color: AppColors.accent),
                    ),
                    Expanded(
                      child: Text(
                        a,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13.5,
                          color: AppColors.ink,
                          height: 1.75,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          // caution
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  useKo ? '조심할 점 · 戒' : 'Watch out · 戒',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  caution,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13.5,
                    color: AppColors.ink,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // best time row
          Row(
            children: [
              Text(
                useKo ? '운 좋은 시간' : 'Best time',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
              const Spacer(),
              Text(
                bestTime,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────── Promo card (deprecated — kept for ref) ────────────

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: () => showComingSoonModal(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.homePromoLimited.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.homePromoTitle,
              style: GoogleFonts.notoSerifKr(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.homePromoDesc,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'READ  MORE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('→', style: TextStyle(color: AppColors.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────── Notification toggle (legacy retained for future) ────────────

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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.homeNotifTitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  on ? l.homeNotifOn : l.homeNotifSubtitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    color: AppColors.taupe,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: on,
            activeThumbColor: AppColors.ink,
            activeTrackColor: AppColors.ink.withValues(alpha: 0.35),
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
                    backgroundColor: AppColors.ink,
                    content: Text(
                      ok
                          ? l.homeNotifEnabledSnack
                          : l.homeNotifPermissionDenied,
                      style: const TextStyle(color: AppColors.bg),
                    ),
                  ));
              } else {
                await notifier.disable();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.ink,
                    content: Text(l.homeNotifDisabledSnack),
                  ));
              }
            },
          ),
        ],
      ),
    );
  }
}
