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
import '../services/five_day_trend_service.dart';
import '../services/hourly_service.dart';
import '../services/lucky_chips_service.dart';
import '../services/six_axis_score_service.dart';
import '../services/today_deep_service.dart';
import '../services/ziwei_service.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';
import '../widgets/five_day_trend_chart.dart';
import '../widgets/six_axis_radar.dart';

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

    // 깊은 풀이 레이어 — birth info 있을 때만 계산. 없으면 dummy date.
    ZiweiResult? ziwei;
    try {
      final by = birth?.birthDate.year ?? 1995;
      final bm = birth?.birthDate.month ?? 10;
      final bd = birth?.birthDate.day ?? 27;
      final bh = birth?.birthHour ?? 15;
      final bmin = birth?.birthMinute ?? 43;
      final male = birth?.isMale ?? true;
      ziwei = ZiweiService.calculate(
        year: by, month: bm, day: bd,
        hour: bh, minute: bmin,
        isMale: male,
      );
    } catch (_) {
      ziwei = null;
    }

    final sixAxis = ziwei == null
        ? null
        : SixAxisScoreService.compute(saju, ziwei);
    final fiveDay = FiveDayTrendService.compute(saju);
    final chips = ziwei == null
        ? null
        : LuckyChipsService.compute(saju, ziwei);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppBarBlock(),
              // Round 71 사용자 불만 #8 — first-fold 도파민. _OracleHero 한 줄 단정
              // 예언 (font ≥24, 2~3 line) 이 화면 상단 첫 250px 안에 위치.
              _OracleHero(
                dayPillarChunGan: saju.dayPillar.chunGan,
                dayEnergy: classifyDayEnergy(fortune.totalScore),
              ),
              // ── 5초 파악 first-fold (codex 9.9+ 흡수 1등 앱 강점 4종) ──
              if (sixAxis != null) _SixAxisCard(score: sixAxis),
              _FiveDayTrendCard(points: fiveDay),
              _ScoreBlock(
                score: fortune.totalScore,
                quote: useKo
                    ? (fortune.quoteKo.isEmpty ? fortune.quoteEn : fortune.quoteKo)
                    : fortune.quoteEn,
              ),
              if (chips != null) _LuckyChipsCard(chips: chips),
              // ── 더 깊이 보기 (collapsible) ──
              // Round 71 — _HeroGreeting / _StreakLine 은 first-fold 도파민 트리거가
              // 아니라 정보 (인사·streak). _DeepDiveSection 안으로 이동.
              _DeepDiveSection(
                children: [
                  _HeroGreeting(
                    name: birth?.name,
                    dayMaster: useKo
                        ? saju.dayPillar.pairKoreanMeaning
                        : saju.dayMasterName,
                    date: fortune.date,
                  ),
                  _StreakLine(),
                  _PillarOfTheDay(
                    dayPillar: fortune.dayPillar,
                    label: _localizedGanjiLabel(context, fortune.dayPillar),
                  ),
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
                ],
              ),
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
            useKo ? '오늘' : 'TODAY',
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

// ──────────── Oracle hero (Round 71 first-fold 도파민) ────────────

/// 사용자 불만 #8 — home 진입 첫 5초 안에 화면 상단 ~250px 안에 박히는 단정 예언.
/// DayEnergyKind × 천간(10) 30 ment pool 에서 결정적 hash 로 한 줄 선택.
///
/// 톤 (Round 67/71): 단정 평서 한다체. "오늘 너는 ~ 한다 / 너는 ~ 다."
/// Sprint 3 사용자 불만 #3 invariant: restDay 에 "공식 자리·발표·승진·도전·승부" 0 / actionDay 에 "쉬어가·아끼" 0.
class _OracleHero extends StatelessWidget {
  final String dayPillarChunGan;
  final DayEnergyKind dayEnergy;
  const _OracleHero({
    required this.dayPillarChunGan,
    required this.dayEnergy,
  });

  /// 천간 10 × dayEnergy 3 = 30 ment pool.
  /// restDay: "오늘 너는 한 번 멈춰야 한다 / 새로 시작하지 마라 / 묵은 정리 한 가지가 정답이다" 류.
  /// actionDay: "오늘 너는 한 명한테 먼저 연락한다 / 그 한 줄이 분기점이다" 류.
  /// mixedDay: "오늘 너는 큰 결정 한 번 미룬다 / 확인 한 가지로 분위기를 잡는다" 류.
  static const _pool = <DayEnergyKind, Map<String, String>>{
    DayEnergyKind.restDay: {
      '甲': '오늘은 새로 벌이지 않는 게 낫다.\n어제 시작한 일 하나만 매듭지으면 된다.\n그게 오늘 최선이다.',
      '乙': '한 박자 늦게 가는 게 맞다.\n새 약속은 안 잡는 게 낫다.\n잠 한 시간이 오늘 가장 큰 회복이다.',
      '丙': '앞에 나서지 않는 게 낫다.\n새 자리에 얼굴 비치지 않는 게 좋다.\n묵은 톡 하나만 정리하면 된다.',
      '丁': '오늘은 조용히 가는 게 낫다.\n새 사람 안 만나는 게 좋다.\n친한 친구한테 짧은 안부 하나면 충분하다.',
      '戊': '큰 결정은 한 박자 미루는 게 낫다.\n새 일은 안 떠맡는 게 좋다.\n오늘은 가만히 있는 게 낫다.',
      '己': '남 일에 끼지 않는 게 낫다.\n오늘은 너부터 챙긴다.\n친한 한 명만 신경 쓰면 된다.',
      '庚': '오늘은 바로 손절하지 않는 게 낫다.\n결정은 한 박자 미룬다.\n한 박자 더 보고 가는 게 낫다.',
      '辛': '오늘은 부딪치지 않는 게 낫다.\n날 세우고 싸우는 건 안 좋다.\n어제 상한 마음부터 풀어주면 된다.',
      '壬': '오늘은 가만히 있는 게 낫다.\n새 방향 잡는 건 안 좋다.\n묵은 일 하나만 정리하면 된다.',
      '癸': '끌려가지 않는 게 낫다.\n새 자리에 빠지지 않는 게 좋다.\n오늘은 네 자리만 지킨다.',
    },
    DayEnergyKind.mixedDay: {
      '甲': '큰 결정은 한 박자 미룬다.\n작은 확인 하나만 끝내면 된다.\n그게 오늘 답이다.',
      '乙': '한 박자 늦게 움직인다.\n작은 약속 하나 지키는 게 답이다.\n그 약속이 내일을 정한다.',
      '丙': '오늘은 한 자리만 지킨다.\n친한 한 명한테 짧게 톡 보낸다.\n그 말 한마디로 오늘 분위기가 잡힌다.',
      '丁': '한 사람한테만 집중한다.\n오래된 친구한테 안부 하나 보낸다.\n그 안부로 다음 톡이 쉬워진다.',
      '戊': '자리만 지킨다.\n큰 결정은 한 박자 늦춘다.\n안 움직인 게 오늘 답이다.',
      '己': '한 사람만 챙긴다.\n묵은 약속 하나 끝낸다.\n그 약속 끝내면 마음이 가벼워진다.',
      '庚': '큰 결정은 한 박자 미룬다.\n작게 하나만 제대로 하면 된다.\n그게 너의 이미지를 만든다.',
      '辛': '네 스타일만 지킨다.\n흔들리지 않는 게 맞다.\n거기서 다음 할 일이 보인다.',
      '壬': '오늘은 흐름만 읽는다.\n다음 할 일 하나만 정한다.\n그 한 가지로 다음이 편해진다.',
      '癸': '비어 있는 자리 하나만 챙긴다.\n오래 못 본 한 명한테 톡 보낸다.\n그 톡으로 오늘 분위기가 잡힌다.',
    },
    DayEnergyKind.actionDay: {
      '甲': '한 명한테 먼저 톡 보낸다.\n그 톡이 오늘 분위기를 정한다.\n망설이면 타이밍 놓친다.',
      '乙': '미뤘던 한 가지 시작한다.\n오늘은 네 편이다.\n그 한 발이 내일을 정한다.',
      '丙': '앞에 나서서 분위기 잡는다.\n사람들이 너한테 모인다.\n오늘 그 자리에서 다음이 편해진다.',
      '丁': '한 명을 제대로 챙긴다.\n그 사람이 너를 쉽게 못 잊는다.\n먼저 손 내미는 쪽이 너다.',
      '戊': '정한 건 끝까지 밀고 간다.\n결과가 딱 네 걸로 남는다.\n그게 네 이미지를 좋게 만든다.',
      '己': '한 사람을 도와준다.\n그 사람이 너한테 고맙다고 한다.\n그 한마디로 네 자리가 잡힌다.',
      '庚': '오늘은 바로 정한다.\n그 한 번이 네 이미지를 만든다.\n망설일 일 아니다.',
      '辛': '오늘은 네 스타일로 간다.\n사람들이 너를 바로 기억한다.\n그게 오늘 너의 장점이다.',
      '壬': '새 방향으로 움직인다.\n다음 할 일이 너한테 먼저 보인다.\n그게 너의 장점이다.',
      '癸': '한 사람 기억에 딱 남는다.\n그 사람이 너를 쉽게 못 잊는다.\n그게 다음 기회를 만든다.',
    },
  };

  String _pickMent() {
    final m = _pool[dayEnergy]!;
    return m[dayPillarChunGan] ?? m['甲']!;
  }

  // Round 74 — 영문 fallback 도 DayEnergyKind 단정 평서 3 분기.
  // Plain English, no hedging (might/maybe/perhaps 0), no AI slop, no em dash.
  String _pickMentEn() {
    switch (dayEnergy) {
      case DayEnergyKind.actionDay:
        return "Reach out first today.\nOne quick message changes the week.\nWaiting loses the timing.";
      case DayEnergyKind.mixedDay:
        return "Skip big choices today.\nDo one small thing instead.\nThat small thing sets your day.";
      case DayEnergyKind.restDay:
        return "Today is not a day to push.\nSkip new plans.\nRest is the real win today.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    // Round 74 — ko / en 양쪽 모두 DayEnergyKind 단정 평서.
    final ment = useKo ? _pickMent() : _pickMentEn();
    final accent = switch (dayEnergy) {
      DayEnergyKind.actionDay => AppColors.woodJade,
      DayEnergyKind.mixedDay => AppColors.accent,
      DayEnergyKind.restDay => AppColors.fireRed,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작은 라벨 — Round 70 톤 (한자 + 영문 letter-spacing).
          Text(
            useKo ? '오늘의 한 줄' : "TODAY'S ORACLE",
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          // Oracle 단정 예언 — font ≥24, 2~3 line.
          Text(
            ment,
            style: GoogleFonts.notoSerifKr(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: accent,
              height: 1.45,
              letterSpacing: -0.1,
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
    final dayEnergy = classifyDayEnergy(score);
    final explanation = switch (dayEnergy) {
      DayEnergyKind.restDay => l.homeExplanationLow,
      DayEnergyKind.mixedDay => l.homeExplanationMid,
      DayEnergyKind.actionDay => l.homeExplanationHigh,
    };
    // Round 71 사용자 불만 #3 — `DayEnergyKind` 단일 source-of-truth.
    // `_ScoreBlock` 라벨/hint 는 score 직접 분기 X, enum 분기만.
    // Round 67/71 톤: 단정 평서 (헷지 X / advice X / 보호자체 X).
    final ({String label, String hint, Color accent}) status = switch (dayEnergy) {
      DayEnergyKind.actionDay => (
          label: useKo ? '오늘은 좋은 날' : 'A good day',
          hint: useKo
              ? '평소보다 분위기가 너 편이다. 미뤘던 일 한 가지를 오늘 시작해라.'
              : 'Flow is on your side. Start what you delayed.',
          accent: AppColors.woodJade,
        ),
      DayEnergyKind.mixedDay => (
          label: useKo ? '오늘은 보통보다 조심' : 'Steady — proceed with care',
          hint: useKo
              ? '큰 결정은 미뤄라. 확인이 필요한 일 한 가지만 끝내라.'
              : 'Defer big calls. Handle the checklists.',
          accent: AppColors.accent,
        ),
      DayEnergyKind.restDay => (
          label: useKo ? '오늘은 쉬어가는 날' : 'A resting day',
          hint: useKo
              ? '오늘 너는 새로 시작하지 마라. 미뤄둔 정리 하나만 끝내라.'
              : 'Conserve energy. Today rewards tidying and rest.',
          accent: AppColors.fireRed,
        ),
    };
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            useKo ? '12 시간 흐름 · 十 二 時' : 'TWELVE  HOURS · 十 二 時',
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
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.ink),
                      tooltip: useKo ? '닫기' : 'Close',
                      onPressed: () => Navigator.of(ctx2).pop(),
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

// ──────────── 6 각 Radar 카드 (깊이 풀이에서 같이 잡힌 결 시그니처) ────────────

class _SixAxisCard extends StatelessWidget {
  final SixAxisScore score;
  const _SixAxisCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final headline = useKo ? '여섯 결로 본 오늘' : 'TODAY ON SIX AXES';
    final axesLine = useKo
        ? '본성 · 연애 · 일 · 돈 · 건강 · 평판'
        : 'NATURE · LOVE · WORK · MONEY · HEALTH · FAME';
    final matched = score.matchedAxesFor(useKo: useKo);
    final mainLine = matched.isEmpty
        ? (useKo
            ? '오늘은 흐름이 골고루 풀려요. 한쪽에 치우치지 않고 다양한 방향으로 풀려나갈 거예요.'
            : 'Today the flow is even. Nothing leans hard one way — many directions stay open.')
        : useKo
            ? '✨ 깊게 봐도 다시 잡힌 핵심: ${matched.join(" · ")} (${score.matchCount}/6)'
            : '✨ Confirmed at the deep layer: ${matched.join(" · ")} (${score.matchCount}/6)';
    final subLine = score.matchCount >= 3
        ? (useKo
            ? '한 번 더 봐도 같은 방향으로 잡힌 포인트라 그만큼 단단해요. 본인이 평소에도 자주 느끼는 강점이에요.'
            : 'These points stay the same when read again. That is the strength you already feel day to day.')
        : score.matchCount >= 1
            ? (useKo
                ? '깊게 봐도 다시 잡힌 ${score.matchCount}개 축이 본인 기질의 핵심이에요. 그 부분 위주로 풀어 가세요.'
                : 'The ${score.matchCount} axes confirmed at the deep layer are your real core. Lean into them.')
            : (useKo
                ? '오늘은 흐름이 골고루 풀려요. 한쪽 강점만 쓰는 게 아니라 변화가 많은 시기라는 뜻이에요.'
                : 'The flow is even today. You are in a phase of change, not single-axis push.');
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
            headline,
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 12,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  )
                : GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            axesLine,
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          SixAxisRadar(score: score, size: 240),
          const SizedBox(height: 14),
          Text(
            mainLine,
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                    height: 1.5,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                    height: 1.45,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            subLine,
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.6,
                  )
                : GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.inkLight,
                    height: 1.55,
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────── 5 일 trend 카드 ────────────

class _FiveDayTrendCard extends StatelessWidget {
  final List<FiveDayPoint> points;
  const _FiveDayTrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final today = points.firstWhere((p) => p.isToday);
    final tomorrow = points.length > 3 ? points[3] : today;
    final diff = tomorrow.score - today.score;
    final headline = useKo ? '5일 흐름' : 'FIVE-DAY FLOW';
    final axisLine = useKo
        ? '그제 · 어제 · 오늘 · 내일 · 모레'
        : '−2D · −1D · TODAY · +1D · +2D';
    final hint = diff > 5
        ? (useKo
            ? '내일은 오늘보다 더 풀려요. 오늘 미뤄둔 결정 한 가지가 내일 쉽게 풀릴 거예요.'
            : 'Tomorrow opens up more than today. A decision you have been putting off will go through easier then.')
        : diff < -5
            ? (useKo
                ? '내일은 살짝 가라앉아요. 오늘 끝낼 수 있는 건 오늘 마무리하는 게 편해요.'
                : 'Tomorrow dips a little. Close what you can today; it will be easier than waiting.')
            : (useKo
                ? '내일도 비슷한 결이에요. 오늘 흐름 그대로 이어가도 괜찮아요.'
                : 'Tomorrow runs in the same key as today. Keep the current flow going.');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 12,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  )
                : GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            axisLine,
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          FiveDayTrendChart(points: points),
          const SizedBox(height: 12),
          Text(
            hint,
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.6,
                  )
                : GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.inkLight,
                    height: 1.55,
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────── 행운 chip 6 개 + 탭 popup ────────────

class _LuckyChipsCard extends StatelessWidget {
  final List<LuckyChip> chips;
  const _LuckyChipsCard({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 행운',
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '하나 누르면 왜 행운인지 알려줘요',
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips
                .map((c) => _LuckyChipButton(chip: c))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _LuckyChipButton extends StatelessWidget {
  final LuckyChip chip;
  const _LuckyChipButton({required this.chip});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showReason(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chip.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '${chip.category} · ${chip.value}',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReason(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(chip.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      '${chip.category} · ${chip.value}',
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(width: 36, height: 1, color: AppColors.line),
                const SizedBox(height: 14),
                Text(
                  '이게 왜 행운이야?',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  chip.reasonKo,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                    ),
                    child: Text(
                      '닫기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────── 더 깊이 보기 — collapsible section ────────────

class _DeepDiveSection extends StatefulWidget {
  final List<Widget> children;
  const _DeepDiveSection({required this.children});

  @override
  State<_DeepDiveSection> createState() => _DeepDiveSectionState();
}

class _DeepDiveSectionState extends State<_DeepDiveSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(
                bottom: BorderSide(color: AppColors.line, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _expanded ? '간단히 보기' : '더 깊이 보기 — 사주 풀이',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  _expanded ? '▲' : '▼',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          ...widget.children,
          _FullSajuCTA(),
        ],
      ],
    );
  }
}

/// "내 사주 풀이 전체 보기" → /result 이동 CTA.
class _FullSajuCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/result'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          children: [
            Text(
              '내 사주 풀이 전체 보기',
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            Text(
              '→',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
