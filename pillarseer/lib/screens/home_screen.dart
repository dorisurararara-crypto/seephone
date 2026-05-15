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
import '../services/animal_context_service.dart';
import '../services/daily_service.dart';
import '../services/dynamic_text_resolver.dart';
import '../services/five_day_trend_service.dart';
import '../services/hourly_service.dart';
import '../services/lucky_chips_service.dart';
import '../services/saju_context.dart';
import '../services/six_axis_score_service.dart';
import '../services/today_deep_service.dart';
import '../services/today_event_service.dart';
import '../services/ziwei_service.dart';
import '../providers/notification_provider.dart';
import '../providers/saju_provider.dart';
import '../providers/streak_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';
import '../widgets/five_day_trend_chart.dart';
import '../widgets/saju_required_empty.dart';
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
    // Round 77 sprint 8 — SajuResult.dummy() fallback 제거. 사주 null 시 empty state CTA.
    final sajuOrNull = ref.watch(sajuResultProvider);
    if (sajuOrNull == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SajuRequiredEmpty(showAppBar: false),
        bottomNavigationBar: PillarBottomNav(activeIdx: 0),
      );
    }
    final saju = sajuOrNull;
    final birth = ref.watch(userBirthInfoProvider);
    final fortune = DailyService().calculate(saju);
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
              // ── First-fold (Round 77 sprint 6 — MZ 페르소나 친밀도) ──
              // first-fold = OracleHero + TodayEvent 둘만. 닉네임 인사/차트 5종은 deep dive 강등.
              _OracleHero(
                dayPillarChunGan: saju.dayPillar.chunGan,
                dayEnergy: classifyDayEnergy(fortune.totalScore),
                ctx: SajuContext.from(saju, today: DateTime.now()),
              ),
              // Round 76 sprint 5 — 오늘 사건 가능성 카드. CTA → /result 의 상세 섹션.
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
              // ── Deep dive (collapsible) — 친구 인사 + 차트 5종 + 일진 + 4영역 + 행운 표 ──
              _DeepDiveSection(
                children: [
                  // Round 77 sprint 6 — 닉네임 / 일주 별명 / 친구 인사. Deep dive 첫 카드.
                  _FirstFoldGreeting(
                    name: birth?.name,
                    dayMasterKo: saju.dayPillar.pairKoreanMeaning,
                    dayMasterEn: saju.dayMasterName,
                    date: fortune.date,
                    // Round 82 sprint 6 — 한글 동물 단독 노출 fix (#7+#8 통합).
                    // headline ("조승현아 오늘은 금 토끼의 날이야") 아래 1줄 helper
                    // 추가 — "= 평소 본인 분위기. <12 동물별 1줄>".
                    dayChunGan: saju.dayPillar.chunGan,
                    dayJiJi: saju.dayPillar.jiJi,
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
                  if (chips != null) _LuckyChipsCard(chips: chips),
                  _StreakLine(),
                  _PillarOfTheDay(
                    dayPillar: fortune.dayPillar,
                    label: _localizedGanjiLabel(context, fortune.dayPillar),
                    // Round 82 sprint 6 — 일진 단독 노출 fix (#9).
                    // "오늘의 일진 화 개" 단독 노출 X — 사용자 일간과 관계 1줄 helper.
                    userDayChunGan: saju.dayPillar.chunGan,
                  ),
                  TodayDeepReadingSection(
                    reading: TodayDeepService.build(
                      userDayStem: saju.dayPillar.chunGan,
                      userDayBranch: saju.dayPillar.jiJi,
                      userMonthBranch: saju.monthPillar.jiJi,
                      userDominantEl: saju.elements.dominant,
                      userDeficitEl: saju.elements.deficit,
                      todayPillar: fortune.dayPillar,
                      todayScore: fortune.totalScore,
                      ctx: SajuContext.from(saju, today: DateTime.now()),
                    ),
                  ),
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
/// DayEnergyKind × 천간(10) 30 ment pool 에서 결정적 hash 로 한 줄 선택.
///
/// 톤 (Round 67/71): 단정 평서 한다체. "오늘 너는 ~ 한다 / 너는 ~ 다."
/// Sprint 3 사용자 불만 #3 invariant: restDay 에 "공식 자리·발표·승진·도전·승부" 0 / actionDay 에 "쉬어가·아끼" 0.
class _OracleHero extends StatelessWidget {
  final String dayPillarChunGan;
  final DayEnergyKind dayEnergy;
  // Round 78 sprint 3 — SajuContext 주입. 같은 천간·dayEnergy 라도 격국·용신 따라
  // body 1줄 suffix 가 derive 되어 사용자별 phrase 차이 ≥1 보장.
  final SajuContext? ctx;
  const _OracleHero({
    required this.dayPillarChunGan,
    required this.dayEnergy,
    this.ctx,
  });

  /// 천간 10 × dayEnergy 3 = 30 ment pool.
  /// restDay: "오늘 너는 한 번 멈춰야 한다 / 새로 시작하지 마라 / 묵은 정리 한 가지가 정답이다" 류.
  /// actionDay: "오늘 너는 한 명한테 먼저 연락한다 / 그 한 줄이 분기점이다" 류.
  /// mixedDay: "오늘 너는 큰 결정 한 번 미룬다 / 확인 한 가지로 분위기를 잡는다" 류.
  // Round 77 sprint 6 — 30 멘트 전수 재작성. MZ 중학생 K-POP 팬 친구 톤.
  // 형식 3종 분배 (천간 10 × 3 dayEnergy = 30):
  //   단정조 4 (해요체 / 친구 톤) — 甲乙丙丁
  //   질문조 3 (친구 호기심) — 戊己庚
  //   인용·밈 톤 3 (Co-Star 식 짧은 단정) — 辛壬癸
  // invariant: restDay 에 "공식 자리·발표·승진·도전·승부" 0 / actionDay 에 "쉬어가·아끼" 0.
  static const _pool = <DayEnergyKind, Map<String, String>>{
    DayEnergyKind.restDay: {
      // 단정조 — 해요체 친구 톤
      '甲': '오늘은 그냥 쉬는 게 진짜야.\n어제 펼친 일 한 가지만 매듭 짓고 끝.\n그 한 가지가 다야.',
      '乙': '한 박자 늦춰 봐.\n잠 한 시간이 단톡 다섯 개보다 커.\n무리한 약속은 그냥 패스.',
      '丙': '오늘 너 앞에 안 나서도 돼.\n묵은 톡 하나만 정리해 봐.\n그걸로 마음이 가벼워져.',
      '丁': '조용히 가는 날이야.\n친한 친구 한 명한테만 짧게 안부 보내 봐.\n그 한 줄이 오늘 다야.',
      // 질문조 — 친구 호기심 톤
      '戊': '오늘 큰 결정 굳이 해야 돼?\n한 박자 미뤄도 안 사라져.\n오늘 너 가만히 있는 게 정답.',
      '己': '오늘 남 일까지 떠맡고 있는 거 아니야?\n본인부터 챙길 차례야.\n친한 한 명한테만 신경 써 봐.',
      '庚': '오늘 바로 손절하려고 했어?\n그거 한 박자 더 보고 가.\n흔들릴 때 결정은 항상 후회야.',
      // 인용·밈 톤 — Co-Star 식 짧은 단정
      '辛': '오늘 너 = 안 부딪치는 사람.\n날 세우면 너만 다쳐.\n어제 상한 마음부터 풀어 줘.',
      '壬': '오늘 키워드 = 멈춤.\n새 방향 잡지 마. 묵은 일 한 가지만.\n그게 다야.',
      '癸': '오늘 너 = 안 끌려가는 사람.\n네 자리만 지키면 돼.\n그게 정답.',
    },
    DayEnergyKind.mixedDay: {
      // 단정조 — 해요체 친구 톤
      '甲': '큰 결정은 한 박자 미뤄.\n작은 확인 한 가지만 끝내면 오늘 분위기 잡혀.\n그게 답.',
      '乙': '한 박자 늦게 움직여 봐.\n작은 약속 한 가지 지키면 내일이 편해져.\n그 약속이 오늘 진짜야.',
      '丙': '오늘은 한 자리만 지켜.\n친한 한 명한테 짧게 톡 한 줄.\n그 한 줄이 오늘 분위기 다 정해.',
      '丁': '한 사람한테만 집중해.\n오래된 친구한테 안부 한 줄 보내 봐.\n다음 톡이 그 안부에서 풀려.',
      // 질문조 — 친구 호기심
      '戊': '오늘 자리 안 지키면 어떻게 될 거 같아?\n큰 결정은 한 박자 늦춰.\n안 움직인 게 오늘 답이야.',
      '己': '오늘 한 사람만 챙길 수 있어?\n묵은 약속 한 가지 끝내 봐.\n그 약속 끝내면 마음이 가벼워져.',
      '庚': '오늘 큰 결정 진짜 지금 해야 돼?\n작은 거 한 가지만 제대로 하면 돼.\n그게 너의 이미지를 만들어.',
      // 인용·밈 톤 — Co-Star 식
      '辛': '오늘 너 = 흔들리지 않는 사람.\n네 스타일만 지켜. 거기서 다음 할 일이 보여.\n그게 다야.',
      '壬': '오늘 키워드 = 흐름 읽기.\n다음 할 일 한 가지만 정해.\n그 한 가지로 다음이 편해져.',
      '癸': '오늘 너 = 비어 있는 자리 채우는 사람.\n오래 못 본 한 명한테 톡 보내 봐.\n그 톡으로 오늘 분위기 잡혀.',
    },
    DayEnergyKind.actionDay: {
      // 단정조 — 해요체 친구 톤
      '甲': '오늘 한 명한테 먼저 톡 보내 봐.\n그 톡이 오늘 분위기 다 정해.\n망설이면 타이밍 놓쳐.',
      '乙': '미뤘던 한 가지 진짜 오늘 끝내 봐.\n오늘은 너 편이야.\n그 한 발이 내일을 정해.',
      '丙': '앞에 나서서 분위기 잡아 봐.\n사람들이 너한테 모여.\n그 자리에서 다음이 편해져.',
      '丁': '한 명을 제대로 챙겨 봐.\n그 사람이 너 쉽게 못 잊어.\n먼저 손 내미는 쪽이 너야.',
      // 질문조 — 친구 호기심
      '戊': '오늘 미루던 한 가지 진짜 끝낼 수 있어?\n너 오늘 그 정도 텐션이야.\n결과는 딱 네 이름으로 남아.',
      '己': '오늘 한 사람 도와줄 수 있어?\n그 사람이 너한테 고맙다고 해.\n그 한마디로 네 자리가 잡혀.',
      '庚': '오늘 바로 정할 수 있어?\n그 한 번이 너의 이미지를 만들어.\n망설일 일 아니야.',
      // 인용·밈 톤 — Co-Star 식
      '辛': '오늘 너 = 본인 스타일로 가는 사람.\n사람들이 너 바로 기억해.\n그게 오늘 너의 장점.',
      '壬': '오늘 키워드 = 새 방향.\n다음 할 일이 너한테 먼저 보여.\n그게 다야.',
      '癸': '오늘 너 = 한 사람 기억에 박히는 사람.\n그 사람이 너 쉽게 못 잊어.\n그게 다음 기회야.',
    },
  };

  /// Round 78 sprint 3 — H1 ctx-aware pool entries.
  /// 한 chunGan/dayEnergy 셀 이 격국·용신 조합으로 정확/부분 매칭 가능하도록 작은 pool 제공.
  /// 본 entries 가 미매칭 시 R77 _pool 정적 ment fallback + ctx suffix 합성 (chain 2~4).
  static const _ctxEntries = <DynamicPoolEntry>[
    // 정관격 + 용신 木 + restDay 사용자 — 직장 안정 + 초록 활동 안내.
    DynamicPoolEntry(
      key: 'oracle_hero.restDay.辛',
      bodies: {
        'ko':
            '오늘은 정해진 룰 안에서 쉬는 게 정답.\n초록·산책 한 번 챙기면 컨디션이 받쳐줘요.\n무리한 약속은 다음 주로 넘겨.',
        'en':
            "Rest inside your usual lane today.\nA short green walk steadies your focus.\nPush bigger plans to next week.",
      },
      requires: {
        'gyeokgukShort': '정관격',
        'yongsin': '木',
      },
    ),
    // 정관격 + 용신 火 — 같은 정관격이어도 용신 다르면 안내 다름.
    // invariant: restDay 본문에 "도전·승부·발표·공식 자리·승진" 0.
    DynamicPoolEntry(
      key: 'oracle_hero.restDay.辛',
      bodies: {
        'ko':
            '오늘은 정해진 룰 안에서 쉬는 게 정답.\n햇볕 받는 동선이 자신감을 채워줘요.\n새 일정은 한 주 미뤄.',
        'en':
            "Rest inside your usual lane today.\nA bit of sunlight refills your spark.\nPush new plans to next week.",
      },
      requires: {
        'gyeokgukShort': '정관격',
        'yongsin': '火',
      },
    ),
  ];

  String _pickMent() {
    final m = _pool[dayEnergy]!;
    final base = m[dayPillarChunGan] ?? m['甲']!;
    // Round 78 sprint 3 — ctx 주입 시 DynamicTextResolver 가 용신 derive suffix 합성.
    final c = ctx;
    if (c == null) return base;
    return DynamicTextResolver.resolve(
      key: 'oracle_hero.${dayEnergy.name}.$dayPillarChunGan',
      ctx: c,
      locale: 'ko',
      staticFallback: base,
      entries: _ctxEntries,
    );
  }

  // Round 77 sprint 6 — 영문 fallback 친구 톤 native casual.
  // Plain English, no hedging (might/maybe/perhaps 0), no AI slop, no em dash.
  String _pickMentEn() {
    final base = switch (dayEnergy) {
      DayEnergyKind.actionDay =>
        "Drop a quick message. One will decide the vibe today.\nDon't wait. Send it now.\nThat one move makes the day.",
      DayEnergyKind.mixedDay =>
        "Push the big call to tomorrow.\nOne small move does the work today.\nThat small move sets your vibe.",
      DayEnergyKind.restDay =>
        "Don't push today.\nSkip new plans. Resting is the real win.\nOne hour of rest beats five group chats.",
    };
    final c = ctx;
    if (c == null) return base;
    return DynamicTextResolver.resolve(
      key: 'oracle_hero.${dayEnergy.name}.$dayPillarChunGan',
      ctx: c,
      locale: 'en',
      staticFallback: base,
      entries: _ctxEntries,
    );
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

// ──────────── First-fold greeting (Round 77 sprint 6) ────────────

/// MZ 친구 톤 한 줄 인사 — 닉네임 / 일주 별명 / 친구 호칭.
/// 예) "민수야, 오늘은 갑목의 날이야"
/// 영문: "Hey Minsoo, it's a Yang Wood day for you"
class _FirstFoldGreeting extends StatelessWidget {
  final String? name;
  final String dayMasterKo;
  final String dayMasterEn;
  final DateTime date;
  // Round 82 sprint 6 — 한글 동물 단독 노출 fix (#7+#8). dayChunGan + dayJiJi 주입 시
  // headline 아래 sub-line 1줄 helper ("= 평소 본인 분위기. <동물별 1줄>") 추가.
  final String? dayChunGan;
  final String? dayJiJi;
  const _FirstFoldGreeting({
    required this.name,
    required this.dayMasterKo,
    required this.dayMasterEn,
    required this.date,
    this.dayChunGan,
    this.dayJiJi,
  });

  /// 한국어 호칭 조사 — 받침 있으면 '아', 없으면 '야'.
  String _josa(String n) {
    if (n.isEmpty) return '';
    final last = n.runes.last;
    // 한글 가-힣 (0xAC00 ~ 0xD7A3) 음절 = (last - 0xAC00) % 28 != 0 → 받침 있음.
    if (last < 0xAC00 || last > 0xD7A3) return '아'; // 비한글 시 fallback
    final hasBatchim = ((last - 0xAC00) % 28) != 0;
    return hasBatchim ? '아' : '야';
  }

  String _dateText(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final useKo = locale?.languageCode == 'ko';
    if (useKo) {
      const wd = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
      return '${date.month}월 ${date.day}일 (${wd[date.weekday] ?? ''})';
    }
    return DateFormat('MMM d, EEE', locale?.toString()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final trimmed = (name ?? '').trim();
    final hasName = trimmed.isNotEmpty;
    String headline;
    if (useKo) {
      if (hasName) {
        headline = '$trimmed${_josa(trimmed)}, 오늘은 $dayMasterKo의 날이야';
      } else {
        headline = '오늘은 $dayMasterKo의 날이야';
      }
    } else {
      if (hasName) {
        headline = "Hey $trimmed, it's a $dayMasterEn day for you";
      } else {
        headline = "It's a $dayMasterEn day for you";
      }
    }
    // Round 82 sprint 6 — 한국어 단독 노출 영역 fix (#7+#8).
    // ko + dayChunGan + dayJiJi 셋 다 갖춰진 경우 headline 바로 아래 1줄 helper.
    // "조승현아, 오늘은 금 토끼의 날이야" → 그 아래 "= 평소 본인 분위기. 단단한데 다정한 사람.".
    final String? helperKo = (useKo &&
            dayChunGan != null &&
            dayJiJi != null &&
            (dayChunGan?.isNotEmpty ?? false) &&
            (dayJiJi?.isNotEmpty ?? false))
        ? AnimalContextService.selfPairHelperKo(
            dayChunGan: dayChunGan!,
            dayJiJi: dayJiJi!,
          )
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
          if (helperKo != null) ...[
            const SizedBox(height: 6),
            Text(
              helperKo,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w400,
                color: AppColors.taupe,
                letterSpacing: 0.1,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _dateText(context),
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: AppColors.taupe,
              letterSpacing: 0.2,
            ),
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
    final ({String label, String hint, Color accent}) status = switch (dayEnergy) {
      DayEnergyKind.actionDay => (
          label: useKo ? '오늘은 좋은 날' : 'A good day',
          hint: useKo
              ? '평소보다 분위기가 본인 편이에요. 미뤘던 일 한 가지를 오늘 시작해 봐요.'
              : 'Flow is on your side. Start what you delayed.',
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
  // Round 82 sprint 6 — 일진 단독 노출 fix (#9). userDayChunGan 주입 시 1줄 helper
  // ("= 당신을 잡아주는 분위기...") 추가.
  final String? userDayChunGan;
  const _PillarOfTheDay({
    required this.dayPillar,
    required this.label,
    this.userDayChunGan,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    // Round 82 sprint 6 — 일진 1줄 helper (사용자 일간과 오늘 일진 천간의 십신/천간합 관계).
    final String? pillarHelperKo = (useKo &&
            userDayChunGan != null &&
            (userDayChunGan?.isNotEmpty ?? false) &&
            dayPillar.length == 2)
        ? AnimalContextService.todayPillarHelperKo(
            userDayChunGan: userDayChunGan!,
            todayPillar: dayPillar,
          )
        : null;
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
          if (pillarHelperKo != null) ...[
            const SizedBox(height: 10),
            // Round 82 sprint 6 — "오늘의 일진" 단독 노출 fix (#9).
            // 사용자 일간 + 오늘 일진 천간 관계 1줄 helper (한자 jargon X).
            Text(
              pillarHelperKo,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                letterSpacing: 0.1,
              ),
            ),
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
                const Icon(Icons.arrow_forward,
                    size: 14, color: AppColors.ink),
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
            Expanded(child: _ScoreGauge(score: row.$2, isTop: i == topIdx)),
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
      cells.add(Expanded(
        child: Container(
          height: 8,
          color: isFilled ? activeColor : AppColors.line,
        ),
      ));
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
            useKo ? '오늘 추천' : 'Try today',
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              letterSpacing: 0.2,
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
        ref.read(notificationProvider.notifier).reconcileSchedule(
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
    final headline =
        useKo ? '성격·연애·공부·돈·체력·인기 한눈에' : 'You in Six Areas';
    final axesLine = useKo
        ? '성격 · 연애 · 공부 · 돈 · 체력 · 인기'
        : 'Nature · Love · Study · Money · Health · Fame';
    final matched = score.matchedAxesFor(useKo: useKo);
    final mainLine = matched.isEmpty
        ? (useKo
            ? '오늘 너는 한쪽으로 안 쏠려. 여러 방향이 다 열려 있어.'
            : "You don't lean hard one way today. Many directions stay open.")
        : useKo
            ? '✨ 너의 강점 ${score.matchCount}개: ${matched.join(" · ")}'
            : '✨ Your ${score.matchCount} strengths: ${matched.join(" · ")}';
    final subLine = score.matchCount >= 3
        ? (useKo
            ? '평소에 너도 느끼는 강점이야. 단톡·발표·시험 다 여기서 풀려.'
            : 'These are the strengths you already feel. Group chats, presentations, tests — all open up here.')
        : score.matchCount >= 1
            ? (useKo
                ? '이 ${score.matchCount}개가 너의 진짜 무기야. 오늘은 여기 위주로 가.'
                : 'These ${score.matchCount} are your real edge. Lean into them today.')
            : (useKo
                ? '오늘은 한쪽으로 안 쏠려. 여러 방향이 다 열려 있는 시기야.'
                : "You're in a phase of change today, not a single-direction push.");
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
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '하나 눌러 봐 — 왜 너한테 행운인지 알려줄게',
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
                .map((c) => _LuckyChipButton(chip: c))
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
    '흰색':   Color(0xFFF3EDE4), // paper 톤
    '검정색': Color(0xFF2A2A2A), // ink 톤
  }[value];
}

class _LuckyChipButton extends StatelessWidget {
  final LuckyChip chip;
  const _LuckyChipButton({required this.chip});

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
              '${chip.category} · ${chip.value}',
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
