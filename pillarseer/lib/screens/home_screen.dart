// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../services/notification_pool_service.dart' show MysteryRelation, MysteryRelationKey;
import '../services/saju_context.dart';
import '../services/six_axis_score_service.dart';
import '../services/today_deep_service.dart';
import '../services/today_event_service.dart';
import '../services/ziwei_service.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/coming_soon_modal.dart';
import '../widgets/five_day_trend_chart.dart';
import '../widgets/saju_required_empty.dart';
import '../widgets/six_axis_radar.dart';
import '../widgets/today_v5_loader.dart';

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
    // Round 77 sprint 8 — SajuResult.dummy() fallback 제거. 사주 null 시 empty state CTA.
    final sajuOrNull = ref.watch(sajuResultProvider);
    if (sajuOrNull == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SajuRequiredEmpty(showAppBar: false),
      );
    }
    final saju = sajuOrNull;
    final birth = ref.watch(userBirthInfoProvider);
    // R106 P2a-fix #6 — now() 를 한 곳에서 잡아 v5/deep/hero/fortune 에 동일 주입.
    // midnight edge 에서 위젯별 now() 가 서로 다른 날을 가리키지 않게 한다 (R84 스타일).
    final now = DateTime.now();
    final fortune = DailyService().calculate(saju, today: now);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

    // Round 77 sprint 6 — birth null 시 ziwei skip. 자동 isMale 가드 X.
    // 깊은 풀이 레이어는 birth info (성별 포함) 가 있을 때만 계산.
    //
    // R83 sprint 5 (P1-E) — 외부 reviewer P0 #4 mandate:
    //   "시간 모름 = 임의 시간으로 계산 금지." input_screen 은 unknownTime=true 시
    //   birthHour=0, birthMinute=0 로 store → home 의 ziwei 가 임의 0시 계산 위험.
    //   `!birth.unknownTime` 분기로 차단 → sixAxis / chips 등 ziwei-derived 콘텐츠
    //   자동 hide (false precision 방지).
    ZiweiResult? ziwei;
    if (birth != null && !birth.unknownTime) {
      try {
        ziwei = ZiweiService.calculate(
          year: birth.birthDate.year,
          month: birth.birthDate.month,
          day: birth.birthDate.day,
          hour: birth.birthHour,
          minute: birth.birthMinute,
          isMale: birth.isMale,
        );
      } catch (_) {
        ziwei = null;
      }
    }

    final sixAxis = ziwei == null
        ? null
        : SixAxisScoreService.compute(saju, ziwei);
    final fiveDay = FiveDayTrendService.compute(saju);
    final chips = ziwei == null ? null : LuckyChipsService.compute(saju, ziwei);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppBarBlock(),
              // ── First-fold (R88 sprint 1 — 사용자 mandate 순서 재배치) ──
              // 1. 오늘 한 줄 (_OracleHero) — 진입 첫 5초 결정적 한 줄.
              // 2. 오늘 사주 총평 (TodayDeepReadingSection) — 6줄 가량 본문 + actions.
              // 3. 오늘 이렇게 해 봐 (_CategoryGuides) — 4영역 가이드.
              _OracleHero(
                todayPillar: fortune.dayPillar,
                userDayStem: saju.dayPillar.chunGan,
                userDayBranch: saju.dayPillar.jiJi,
                userMonthBranch: saju.monthPillar.jiJi,
                todayScore: fortune.totalScore,
                dayEnergy: classifyDayEnergy(fortune.totalScore),
              ),
              // R106 P2a — 오늘의 사주 v5 (오늘의 주제 + 근거 3칩 + 자기검증).
              // 첫 fold 의 primary 오늘 풀이. selector 신호 0 시 v5 가 총평형 fallback.
              TodayV5Loader(saju: saju, date: now),
              TodayDeepReadingSection(
                reading: TodayDeepService.build(
                  userDayStem: saju.dayPillar.chunGan,
                  userDayBranch: saju.dayPillar.jiJi,
                  userMonthBranch: saju.monthPillar.jiJi,
                  userDominantEl: saju.elements.dominant,
                  userDeficitEl: saju.elements.deficit,
                  todayPillar: fortune.dayPillar,
                  todayScore: fortune.totalScore,
                  ctx: SajuContext.from(saju, today: now),
                ),
              ),
              _CategoryGuides(fortune: fortune),
              // ── Deep dive (collapsible) — 친구 인사 + 차트 5종 + 일진 + 4영역 + 행운 표 ──
              // R88 sprint 1: 오늘 사건 가능성 카드 + 4영역 한눈에 + 행운 표 등 기존 위젯
              // 순서는 그대로 보존. TodayDeepReading 과 CategoryGuides 만 first-fold 로 승격.
              _DeepDiveSection(
                children: [
                  // R76 sprint 5 — 오늘 사건 가능성 카드 (deep dive 로 강등 in R88 S1).
                  _TodayEventCard(
                    reading: TodayEventService.build(
                      userDayStem: saju.dayPillar.chunGan,
                      userDayBranch: saju.dayPillar.jiJi,
                      userMonthBranch: saju.monthPillar.jiJi,
                      todayPillar: fortune.dayPillar,
                      todayScore: fortune.totalScore,
                    ),
                    day60ji: saju.dayPillar.text,
                    userDayStem: saju.dayPillar.chunGan,
                    todayPillar: fortune.dayPillar,
                  ),
                  if (sixAxis != null) _SixAxisCard(score: sixAxis),
                  _FiveDayTrendCard(points: fiveDay),
                  _HourlyFlowSection(saju: saju),
                  _ScoreBlock(
                    score: fortune.totalScore,
                    quote: useKo
                        ? (fortune.quoteKo.isEmpty
                              ? fortune.quoteEn
                              : fortune.quoteKo)
                        : fortune.quoteEn,
                  ),
                  if (chips != null)
                    _LuckyChipsCard(chips: chips, useKo: useKo),
                  _StreakLine(),
                  _CategorySection(fortune: fortune),
                  _LuckySection(fortune: fortune),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────── App bar ────────────

class _AppBarBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final now = DateTime.now();
    String dateLabel;
    if (useKo) {
      const wd = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
      dateLabel = '${now.month}월 ${now.day}일 (${wd[now.weekday] ?? ''})';
    } else {
      dateLabel = DateFormat('MMM d (EEE)').format(now);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 한국어 메인 라벨 — notoSerifKr 18pt.
              Text(
                useKo ? '오늘 내 운세' : "Today's Reading",
                style: GoogleFonts.notoSerifKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: AppColors.ink,
                ),
              ),
              // 영문 sub-line — 9pt 회색 (메인은 한국어 "오늘 내 운세").
              Text(
                'PILLAR SEER',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: AppColors.taupe.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          // 우측 = 날짜 short (M월 D일 (요일) / MMM d (EEE)).
          Text(
            dateLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
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
/// R106 — '오늘의 한 줄' 미스터리형 전환.
///
/// 알림(R106 P2b)과 톤 통일: 오늘 들어온 일진 지지 한 글자를 신비하게 던져
/// "아래 풀이" 로의 호기심을 유발한다. 사용자 감정·사건·미래를 사실 단정하지 않고,
/// 차트 관계(충/합/형·파·해/없음)만 사실로 진술한다 — 거짓말·창작 0.
///
/// relation 산출 = `TodayEventService.build(...).hapChungType` →
/// `MysteryRelationKey.fromHapChungType` (충/합/형·파·해/없음 → chung/hap/friction/neutral)
/// 만 사용. 충·합이 없으면 neutral 로 접힌다 (관계 단정 금지).
///
/// `dayEnergy` 는 accent 색상에만 사용. ment 산출엔 미사용.
class _OracleHero extends StatelessWidget {
  /// 오늘 60갑자 (예: '丁卯'). 둘째 글자가 오늘 일진 지지.
  final String todayPillar;
  final String userDayStem;
  final String userDayBranch;
  final String userMonthBranch;
  final int todayScore;
  final DayEnergyKind dayEnergy;
  const _OracleHero({
    required this.todayPillar,
    required this.userDayStem,
    required this.userDayBranch,
    required this.userMonthBranch,
    required this.todayScore,
    required this.dayEnergy,
  });

  /// 지지 한자 → 한글음 gloss. 본문 {B} 슬롯에 '$지지($한글음)' 형태로 주입.
  static const _branchKo = <String, String>{
    '子': '자', '丑': '축', '寅': '인', '卯': '묘', '辰': '진', '巳': '사',
    '午': '오', '未': '미', '申': '신', '酉': '유', '戌': '술', '亥': '해',
  };

  /// relation 별 미스터리형 ment pool — KO 5 × 4 relation = 20.
  /// {B} = 오늘 일진 지지 글자 슬롯 (예: '卯(묘)').
  static const _poolKo = <MysteryRelation, List<String>>{
    MysteryRelation.chung: [
      '오늘 당신 자리에 {B} 한 글자가 들어왔어요.\n당신 일주와 정면으로 마주 보는 글자예요.\n맞서기 전에 한 박자 — 자세한 건 아래 풀이에 있어요.',
      '오늘 들어온 글자는 {B}.\n당신 일주와 똑바로 부딪치는 자리에 섰어요.\n세게 막지 말고 비껴서는 법, 아래 풀이에서 봐요.',
      '{B}. 오늘 당신 일주 맞은편에 선 글자예요.\n맞부딪치면 시끄럽고, 한 박자 늦추면 조용해져요.\n어느 쪽일지는 아래 풀이가 정해줘요.',
      '오늘은 {B} 글자가 당신 일주를 똑바로 건드려요.\n피하라는 게 아니라, 속도만 줄이면 되는 자리예요.\n그 속도 조절법, 아래 풀이에 적어놨어요.',
      '오늘 당신한테 {B} 한 글자가 마주 걸어왔어요.\n당신 일주와 정면으로 만나는 자리예요.\n잘 넘기는 법은 아래 풀이를 봐요.',
    ],
    MysteryRelation.hap: [
      '오늘 당신 자리에 {B} 한 글자가 들어왔어요.\n당신 일주와 살며시 손을 맞잡는 글자예요.\n이 손을 어떻게 쓰는지는 아래 풀이에 있어요.',
      '오늘 들어온 글자는 {B}.\n당신 일주와 부드럽게 맞물리는 자리에 섰어요.\n맞물린 김에 뭘 하면 좋은지, 아래 풀이에서 봐요.',
      '{B}. 오늘 당신 일주와 한편이 되는 글자예요.\n막혀 있던 게 있다면 오늘 슬쩍 밀어보기 좋은 자리예요.\n그 한 가지가 뭔지는 아래 풀이에.',
      '오늘은 {B} 글자가 당신 일주에 살그머니 붙어요.\n밀어내지 말고 곁에 두면 하루가 한결 부드러워요.\n쓰는 법은 아래 풀이에 적어놨어요.',
      '오늘 당신한테 {B} 한 글자가 손 내밀며 왔어요.\n맞잡으면 오늘 일이 한 칸 수월해지는 자리예요.\n어떻게 잡는지는 아래 풀이를 봐요.',
    ],
    MysteryRelation.friction: [
      '오늘 당신 자리에 {B} 한 글자가 들어왔어요.\n당신 일주를 한 끗 비껴 스치는 글자예요.\n그 한 끗 다루는 법은 아래 풀이에 있어요.',
      '오늘 들어온 글자는 {B}.\n당신 일주와 살짝 어긋난 자리에 섰어요.\n어긋난 한 칸을 메우는 법, 아래 풀이에서 봐요.',
      '{B}. 오늘 당신 일주를 한 끗 엇갈려 지나는 글자예요.\n크게 부딪치진 않아도 작게 엇갈리는 자리예요.\n그 결을 푸는 법은 아래 풀이에.',
      '오늘은 {B} 글자가 당신 일주를 비스듬히 스쳐요.\n정면도 아니고 합도 아닌, 한 끗 어긋난 자리예요.\n그 한 끗을 어떻게 넘기는지는 아래 풀이를 봐요.',
      '오늘 당신한테 {B} 한 글자가 슬쩍 어긋나게 왔어요.\n작은 엇박을 미리 알면 오늘 덜 걸려 넘어져요.\n자세한 건 아래 풀이에 적어놨어요.',
    ],
    MysteryRelation.neutral: [
      '오늘 당신 자리에 {B} 한 글자가 들어왔어요.\n당신 곁을 가만히 지나가는 글자예요.\n오늘 이 글자를 어떻게 맞이하는지는 아래 풀이에.',
      '오늘 들어온 글자는 {B}.\n당신 일주와 직접 얽히지 않고 곁을 지나는 자리예요.\n조용한 날을 어떻게 쓰는지, 아래 풀이에서 봐요.',
      '{B}. 오늘 당신 일주 옆을 스쳐 지나는 글자예요.\n크게 건드리지 않으니 흔들릴 일도 적은 자리.\n이 잔잔함을 쓰는 법은 아래 풀이에.',
      '오늘은 {B} 글자가 당신 곁을 슬쩍 지나가요.\n부딪침도 끌림도 옅어서 오늘은 본인 페이스대로 가도 돼요.\n자세한 건 아래 풀이를 봐요.',
      '오늘 당신한테 {B} 한 글자가 가볍게 다녀가요.\n직접 걸리는 자리가 없어 오늘은 잔잔한 날이에요.\n이 잔잔한 하루 쓰는 법, 아래 풀이에 적어놨어요.',
    ],
  };

  /// relation 별 미스터리형 ment pool — EN 5 × 4 relation = 20.
  static const _poolEn = <MysteryRelation, List<String>>{
    MysteryRelation.chung: [
      'A new character stepped onto your day: {B}.\nIt stands face to face with your day pillar.\nHow to pass it well is in the reading below.',
      "Today's character is {B}, squared up against your day pillar.\nDon't block it hard; step half a beat aside.\nThe how is in the reading below.",
      '{B}. Today it stands directly across from your day pillar.\nMeet it head-on and it\'s loud; slow a beat and it quiets.\nWhich way it goes is in the reading below.',
      'Today {B} touches your day pillar straight on.\nNot a sign to hide, just a sign to ease your pace.\nThe pacing is in the reading below.',
      'A character walked up to face you today: {B}.\nIt meets your day pillar straight on.\nHow to take it well is in the reading below.',
    ],
    MysteryRelation.hap: [
      'A new character stepped onto your day: {B}.\nIt links quietly arm in arm with your day pillar.\nWhat to do with that link is in the reading below.',
      "Today's character is {B}, clasping gently with your day pillar.\nWhile it's clasped, there's a good move to make.\nIt's in the reading below.",
      "{B}. Today it takes your day pillar's side.\nIf something's been stuck, today's a good day to nudge it.\nWhat that something is is in the reading below.",
      'Today {B} settles softly against your day pillar.\nKeep it close rather than pushing it off, and the day runs smoother.\nThe how is in the reading below.',
      'A character reached a hand out to you today: {B}.\nClasp it and one thing today gets a notch easier.\nHow to clasp it is in the reading below.',
    ],
    MysteryRelation.friction: [
      "A new character stepped onto your day: {B}.\nIt grazes your day pillar by a hair.\nHandling that hair's width is in the reading below.",
      "Today's character is {B}, set a touch off from your day pillar.\nThere's a small gap to close.\nThe how is in the reading below.",
      '{B}. Today it crosses your day pillar a hair out of line.\nNo big collision, just a small snag.\nSmoothing it is in the reading below.',
      'Today {B} brushes your day pillar at a slant.\nNot a clash, not a link, a hair out of line.\nHow to pass it is in the reading below.',
      'A character came in slightly off-beat today: {B}.\nKnow the small off-beat early and you trip on it less.\nThe detail is in the reading below.',
    ],
    MysteryRelation.neutral: [
      'A new character stepped onto your day: {B}.\nIt simply passes by your side.\nHow to meet a quiet day is in the reading below.',
      "Today's character is {B}, passing by without tangling with your day pillar.\nThere's a way to use a calm day.\nIt's in the reading below.",
      '{B}. Today it slips past the side of your day pillar.\nNothing pulls hard, so little shakes loose.\nUsing that stillness is in the reading below.',
      'Today {B} drifts quietly past you.\nLittle clash, little pull, a day to keep your own pace.\nThe detail is in the reading below.',
      'A character passed through lightly today: {B}.\nNothing catches directly, so it\'s a still day.\nHow to use a still day is in the reading below.',
    ],
  };

  /// 오늘 일진 지지 글자 (한자) — todayPillar 둘째 글자.
  String get _todayBranch =>
      todayPillar.length >= 2 ? todayPillar[1] : '子';

  /// {B} 슬롯 값 — '$지지($한글음)' (예: '卯(묘)').
  String get _branchSlot {
    final b = _todayBranch;
    final ko = _branchKo[b];
    return ko == null ? b : '$b($ko)';
  }

  /// 오늘 차트 관계 — TodayEventService 산출값만 사용 (거짓말 0).
  MysteryRelation get _relation {
    final reading = TodayEventService.build(
      userDayStem: userDayStem,
      userDayBranch: userDayBranch,
      userMonthBranch: userMonthBranch,
      todayPillar: todayPillar,
      todayScore: todayScore,
    );
    return MysteryRelationKey.fromHapChungType(reading.hapChungType);
  }

  /// 날짜 + 오늘 일진 기반 결정적 seed — 같은 날 같은 사용자 = 같은 ment.
  int _seed(DateTime date) {
    final dayKey = date.year * 366 + date.month * 31 + date.day;
    final pillarKey =
        todayPillar.codeUnits.fold<int>(0, (a, c) => a ^ c);
    return (dayKey ^ pillarKey ^ userDayStem.codeUnits.fold<int>(0, (a, c) => a + c))
        .abs();
  }

  /// relation pool 에서 결정적으로 1개 pick 후 {B} 슬롯 주입.
  String _pickMent(bool useKo) {
    final rel = _relation;
    final pool = (useKo ? _poolKo : _poolEn)[rel]!;
    final idx = _seed(DateTime.now()) % pool.length;
    return pool[idx].replaceAll('{B}', _branchSlot);
  }

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final ment = _pickMent(useKo);
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
          // Round 77 sprint 6 — 한국어 메인 sub label. letter-spacing 4 → 0.3.
          Text(
            useKo ? '오늘의 한 줄' : "Today's Oracle",
            style: GoogleFonts.notoSerifKr(
              fontSize: 11,
              letterSpacing: 0.3,
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
              letterSpacing: 0,
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
            _dateText(context),
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 0.2,
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
              letterSpacing: 0,
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
          // Round 77 sprint 6 — 한국어 자연문 streak. UPPERCASE + letterSpacing 4 제거.
          Text(
            l.homeStreakDays(streak.current),
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
          if (streak.celebrate) ...[
            const SizedBox(width: 12),
            Text(
              l.homeStreakNewDay,
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                letterSpacing: 0.2,
                color: AppColors.inkLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Spacer(),
          if (streak.longest > streak.current)
            Text(
              l.homeStreakLongest(streak.longest),
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                letterSpacing: 0.2,
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
    final ({String label, String hint, Color accent}) status =
        switch (dayEnergy) {
          DayEnergyKind.actionDay => (
            label: useKo ? '오늘은 좋은 날' : 'A good day',
            hint: useKo
                ? '평소보다 한 발 내딛기 좋은 자리예요. 미뤄둔 일 하나, 오늘 시작해 봐요.'
                : 'A good day to take the step. Start the thing you delayed.',
            accent: AppColors.woodJade,
          ),
          DayEnergyKind.mixedDay => (
            label: useKo ? '오늘은 평소보다 신중하게' : 'Steady — proceed with care',
            hint: useKo
                ? '큰 결정은 미뤄요. 확인이 필요한 일 한 가지만 끝내요.'
                : 'Defer big calls. Handle the checklists.',
            accent: AppColors.accent,
          ),
          DayEnergyKind.restDay => (
            label: useKo ? '오늘은 쉬어가는 날' : 'A resting day',
            hint: useKo
                ? '오늘은 새로 시작하지 말고, 미뤄둔 정리 하나만 끝내요.'
                : 'Conserve energy. A day that suits tidying and rest.',
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
                useKo ? '$score점' : '$score',
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
          // 한국어 메인 라벨 — notoSerifKr 15pt.
          Text(
            l.homeHourlyTitle,
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          // 영문 sub-line — letter-spacing 2, 9pt 회색.
          Text(
            useKo ? 'NEXT 12 HOURS · 十二時' : 'NEXT 12 HOURS · 十二時',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
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
                  l.homeHourlySeeAll,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('→', style: TextStyle(color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAll(
    BuildContext context,
    AppL10n l,
    List<HourlySlot> slots,
    bool useKo,
  ) {
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
                child: Container(width: 36, height: 1, color: AppColors.line),
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
                          // 한국어 메인 라벨 — notoSerifKr 26pt.
                          Text(
                            l.homeHourlyFullTitle,
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // 영문/한자 sub-line — letter-spacing 2, 9pt 회색.
                          Text(
                            '12 HOURS · 十二時',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w400,
                              color: AppColors.taupe.withValues(alpha: 0.7),
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
                    height: 1,
                    color: AppColors.line,
                    thickness: 0.6,
                  ),
                  itemBuilder: (ctx3, i) =>
                      _HourlyRow(slot: slots[i], useKo: useKo),
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
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              letterSpacing: 0.2,
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
                  slot.label(useKo),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    letterSpacing: 0.2,
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
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
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
          // 한국어 메인 라벨 — notoSerifKr 15pt.
          Text(
            useKo ? '네 영역으로 본 오늘' : 'Four Areas Today',
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          // 영문/한자 sub-line — letter-spacing 2, 9pt 회색.
          Text(
            'FOUR AREAS · 四域',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
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
                      .map(
                        (r) => Expanded(
                          child: _CategoryCell(
                            name: r.$1,
                            glyph: r.$2,
                            score: r.$3,
                          ),
                        ),
                      )
                      .toList(),
                ),
                Row(
                  children: rows
                      .sublist(2, 4)
                      .map(
                        (r) => Expanded(
                          child: _CategoryCell(
                            name: r.$1,
                            glyph: r.$2,
                            score: r.$3,
                          ),
                        ),
                      )
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
                name,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.2,
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
      (
        l.homeCategoryWealth,
        useKo ? fortune.wealthGuideKo : fortune.wealthGuideEn,
      ),
      (
        l.homeCategoryEnergy,
        useKo ? fortune.energyGuideKo : fortune.energyGuideEn,
      ),
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
          // 한국어 메인 라벨 — notoSerifKr 15pt.
          Text(
            useKo ? '오늘 이렇게 해 봐' : 'How to Move Today',
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          // 영문 sub-line — letter-spacing 2, 9pt 회색.
          Text(
            "TODAY'S GUIDANCE",
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
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
                      e.value.$1,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        letterSpacing: 0.2,
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
        ? (fortune.luckyColorKo.isEmpty
              ? fortune.luckyColor
              : fortune.luckyColorKo)
        : (fortune.luckyColorEn.isEmpty
              ? fortune.luckyColor
              : fortune.luckyColorEn);
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
          // 한국어 메인 라벨 — notoSerifKr 15pt.
          Text(
            useKo ? '오늘의 행운 카드' : "Today's Luck",
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          // 영문/한자 sub-line — letter-spacing 2, 9pt 회색.
          Text(
            'AUSPICIOUS · 吉',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.line, width: 0.6),
              ),
            ),
            child: Column(
              children: rows.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.line, width: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.$1,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            letterSpacing: 0.2,
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

// ──────────── Round 76 sprint 5 — Today Event Card (오늘 사건 가능성) ────────────
//
// home_screen first-fold 카드. 사용자 verbatim mandate: "오늘 당신에게 생길 수 있는 일".
// dominant 카테고리 본문 1줄 + 별점 4 row + "자세히 보기 →" CTA.

class _TodayEventCard extends StatelessWidget {
  final TodayEventReading reading;
  final String day60ji;
  // Round 78 sprint 6 — anchor wire 용 stems.
  final String? userDayStem;
  final String? todayPillar;
  const _TodayEventCard({
    required this.reading,
    required this.day60ji,
    this.userDayStem,
    this.todayPillar,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    // Round 78 sprint 6 — anchor (신살/합충/천간합) wire. ko 본문은 composeBodyKoWithAnchor.
    final body = useKo
        ? TodayEventService.composeBodyKoWithAnchor(
            reading: reading,
            date: DateTime.now(),
            day60ji: day60ji,
            userDayStem: userDayStem,
            todayStem: (todayPillar != null && todayPillar!.isNotEmpty)
                ? todayPillar![0]
                : null,
          )
        : TodayEventService.composeNotificationLineEn(reading);
    final stars = [
      (l.homeCategoryLove, reading.starsLove),
      (l.homeCategoryWealth, reading.starsMoney),
      (l.homeCategoryWork, reading.starsWork),
      (l.todayEventStarHealth, reading.starsHealth),
    ];
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
          // Round 77 sprint 6 — 한국어 자연문 sub-label. UPPERCASE / letterSpacing 4 제거.
          Text(
            l.todayEventCaption,
            style: GoogleFonts.notoSerifKr(
              fontSize: 12,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              height: 1.55,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          // Round 77 sprint 7 — 별점 텍스트(★☆) → 가로 색 게이지 5칸.
          // 4 카테고리 중 max 점수 1위는 accent 강조 (동률 시 Love → Wealth → Work → Health 순).
          ..._buildStarRows(stars),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () =>
                // Round 79 sprint 7 — 사용자 mandate "내 사주 = 평생사주만".
                // 신규 진입 = /today route (result 의 today section 은 backward compat 유지).
                GoRouter.of(context).push('/today'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l.todayEventCtaDetail,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.ink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Round 77 sprint 7 — 4 row 게이지 빌더. 1위는 accent 색 강조.
  // 동률 시 Love → Wealth → Work → Health 순 (stars 리스트 인덱스 0→3 순).
  List<Widget> _buildStarRows(List<(String, int)> stars) {
    int topIdx = 0;
    int topScore = -1;
    for (var i = 0; i < stars.length; i++) {
      if (stars[i].$2 > topScore) {
        topScore = stars[i].$2;
        topIdx = i;
      }
    }
    return stars.asMap().entries.map((e) {
      final i = e.key;
      final row = e.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                row.$1,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
            ),
            Expanded(
              child: _ScoreGauge(score: row.$2, isTop: i == topIdx),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Round 77 sprint 7 — 별점 텍스트 대체 가로 색 게이지 5칸.
/// 가득 찬 칸: isTop=true → accent (gold), false → ink. 빈 칸: line (회색).
/// 모서리 사각 (Aesop 톤). 칸 사이 4pt separator.
class _ScoreGauge extends StatelessWidget {
  final int score;
  final bool isTop;
  const _ScoreGauge({required this.score, required this.isTop});

  @override
  Widget build(BuildContext context) {
    final filled = score.clamp(0, 5);
    final activeColor = isTop ? AppColors.accent : AppColors.ink;
    final cells = <Widget>[];
    for (var i = 0; i < 5; i++) {
      final isFilled = i < filled;
      cells.add(
        Expanded(
          child: Container(
            height: 8,
            color: isFilled ? activeColor : AppColors.line,
          ),
        ),
      );
      if (i < 4) cells.add(const SizedBox(width: 4));
    }
    return Row(children: cells);
  }
}

// ──────────── Today Deep Reading (사주 깊이 오늘 풀이) ────────────

/// Round 79 sprint 7 — today_screen 에서 재사용 위해 public visibility 노출.
/// home_screen 의 deep dive 영역 안 mount 는 기존대로 유지.
class TodayDeepReadingSection extends StatelessWidget {
  final TodayDeepReading reading;
  const TodayDeepReadingSection({super.key, required this.reading});

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
                useKo ? '오늘 사주 총평' : "Today's Saju Summary",
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 1),
                ),
                child: Text(
                  moodTag,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    letterSpacing: 0.2,
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
            useKo ? '오늘 살릴 부분' : 'Use this today',
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 10),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      color: AppColors.accent,
                    ),
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
            ),
          ),
          const SizedBox(height: 18),
          // caution
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.line, width: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  useKo ? '조심할 점' : 'Watch out',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    letterSpacing: 0.2,
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
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.2,
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
              l.homePromoLimited,
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 0.4,
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
                  '더 읽어 봐',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    letterSpacing: 0.3,
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
        ref
            .read(notificationProvider.notifier)
            .reconcileSchedule(
              pushTitle: l.homeNotifSampleTitle,
              pushBody: l.homeNotifSampleBody,
              day60ji: saju?.day60ji,
              useKo: useKo,
              saju: saju,
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
                  l.homeNotifTitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  on
                      ? l.homeNotifOnAt(
                          toggle.notifyHour.toString().padLeft(2, '0'),
                          toggle.notifyMinute.toString().padLeft(2, '0'),
                        )
                      : l.homeNotifSubtitle,
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
                  saju: saju,
                );
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.ink,
                      content: Text(
                        ok
                            ? l.homeNotifEnabledSnack
                            : l.homeNotifPermissionDenied,
                        style: const TextStyle(color: AppColors.bg),
                      ),
                    ),
                  );
              } else {
                await notifier.disable();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.ink,
                      content: Text(l.homeNotifDisabledSnack),
                    ),
                  );
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
    final headline = useKo ? '성격·연애·공부·돈·체력·인기 한눈에' : 'You in Six Areas';
    final axesLine = useKo
        ? '성격 · 연애 · 공부 · 돈 · 체력 · 인기'
        : 'Nature · Love · Study · Money · Health · Fame';
    final matched = score.matchedAxesFor(useKo: useKo);
    final mainLine = matched.isEmpty
        ? (useKo
              ? '오늘 너는 한쪽으로 안 쏠려. 여러 방향이 다 열려 있어.'
              : "You don't lean hard one way today. Many directions stay open.")
        : useKo
        ? '✨ ${matched.join(" · ")} — 안팎에서 같이 보인 강점'
        : '✨ ${matched.join(" · ")} — confirmed on the deeper read';
    final subLine = matched.isEmpty
        ? (useKo
              ? '오늘은 한쪽으로 안 쏠려. 여러 방향이 다 열려 있는 시기야.'
              : "You're in a phase of change today, not a single-direction push.")
        : score.matchCount >= 3
        ? (useKo
              ? '${matched.join(" · ")} 쪽은 평소에도 느끼는 강점이야. 단톡·발표·시험 다 여기서 풀려.'
              : 'You already feel ${matched.join(" · ")} in daily life — chats, presentations, tests open up here.')
        : (useKo
              ? '${matched.join(" · ")} 쪽으로 가면 오늘이 풀려. 이 강점 위주로 움직여 봐.'
              : 'Lean into ${matched.join(" · ")} today — your day opens up there.');
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
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
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
    // Round 77 sprint 6 — 친구 톤 + 구체 점수 차 노출. "결이에요/가라앉아요" 어른 단어 제거.
    final hint = diff > 5
        ? (useKo
              ? '내일은 오늘보다 $diff점 더 풀려. 미뤘던 거 내일 처리해 봐.'
              : "Tomorrow opens up by $diff. Handle what you've put off then.")
        : diff < -5
        ? (useKo
              ? '내일은 오늘보다 ${-diff}점 살짝 내려가. 오늘 끝낼 수 있는 건 오늘 끝내.'
              : 'Tomorrow dips by ${-diff}. Finish today what you can today.')
        : (useKo
              ? '내일도 오늘이랑 거의 같아. 이 흐름 그대로 가도 돼.'
              : 'Tomorrow tracks today. Keep the current flow going.');
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
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
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
  final bool useKo;
  const _LuckyChipsCard({required this.chips, required this.useKo});

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
            useKo ? '오늘의 행운' : "Today's Lucky Picks",
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            useKo
                ? '하나 눌러 봐 — 왜 너한테 행운인지 알려줄게'
                : "Tap one — I'll tell you why it's lucky for you",
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.taupe.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips
                .map((c) => _LuckyChipButton(chip: c, useKo: useKo))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

/// Round 77 sprint 6 — '색' 카테고리 chip 배경을 실제 lucky 색상으로 칠하기.
/// value (한국어 색 이름) → Color 매핑. AppColors 팔레트 톤 매칭.
Color? _luckyColorBg(String value) {
  return const <String, Color>{
    '초록색': Color(0xFF7FAE7C), // woodJade 톤
    '빨강색': Color(0xFFB85A4A), // fireRed 톤
    '황금색': Color(0xFFD4A857), // accent 톤
    '흰색': Color(0xFFF3EDE4), // paper 톤
    '검정색': Color(0xFF2A2A2A), // ink 톤
  }[value];
}

class _LuckyChipButton extends StatelessWidget {
  final LuckyChip chip;
  final bool useKo;
  const _LuckyChipButton({required this.chip, required this.useKo});

  String get _label => useKo
      ? '${chip.category} · ${chip.value}'
      : '${chip.categoryEn} · ${chip.valueEn}';

  @override
  Widget build(BuildContext context) {
    final isColorChip = chip.category == '색';
    final bg = isColorChip ? _luckyColorBg(chip.value) : null;
    final hasColorBg = bg != null;
    // 배경 luminance 기준으로 텍스트 색 결정 — 밝으면 ink, 어두우면 white.
    final textColor = hasColorBg
        ? (bg.computeLuminance() > 0.6 ? AppColors.ink : Colors.white)
        : AppColors.ink;
    final iconOpacity = hasColorBg ? 1.0 : 1.0;
    return InkWell(
      onTap: () => _showReason(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasColorBg ? bg : AppColors.paper,
          border: Border.all(
            color: hasColorBg
                ? bg.computeLuminance() > 0.85
                      ? AppColors.line
                      : Colors.transparent
                : AppColors.line,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: iconOpacity,
              child: Text(chip.icon, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 6),
            Text(
              _label,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
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
                      _label,
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
                  useKo ? '이게 왜 행운이야?' : 'Why is this lucky?',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  useKo ? chip.reasonKo : chip.reasonEn,
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
                    style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                    child: Text(
                      useKo ? '닫기' : 'Close',
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
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
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
                  _expanded
                      ? (useKo ? '간단히 보기' : 'Show less')
                      : (useKo
                          ? '더 깊이 보기 — 사주 풀이'
                          : 'Go deeper — full reading'),
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
                  style: const TextStyle(color: AppColors.accent, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[...widget.children, _FullSajuCTA()],
      ],
    );
  }
}

/// "내 사주 풀이 전체 보기" → /result 탭 이동 CTA.
class _FullSajuCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return InkWell(
      // R109 FIX 2 — /result 는 shell branch. go 로 해당 탭으로 전환
      // (IndexedStack 이라 홈 탭 State 는 살아 있어 보존된다).
      onTap: () => context.go('/result'),
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
              useKo ? '내 사주 풀이 전체 보기' : 'See your full reading',
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
