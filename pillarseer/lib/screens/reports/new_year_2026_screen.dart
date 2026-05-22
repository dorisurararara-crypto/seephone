// Pillar Seer — 2026 신년운세 (병오년).
import 'package:go_router/go_router.dart';
//
// 사주 원국 + 2026 세운 → 12달 흐름 + 12 영역 풀이.
// 정통 명리학: yearGanji (丙午) + 일간 기준 십신 매핑 + 월별 60갑자 조합.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
import '../../services/dynamic_text_resolver.dart';
import '../../services/jol_calendar_2026.dart';
import '../../services/natural_prose_joiner.dart';
import '../../services/saju_context.dart';
import '../../services/seun_service.dart';
import '../../services/strength_service.dart';
import '../../services/yongsin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/saju_required_empty.dart';

/// 2026 신년운세 screen — 사주 원국과 병오년 세운을 매칭하여 1년 운기 풀이.
class NewYear2026Screen extends ConsumerWidget {
  const NewYear2026Screen({super.key});

  static const int year = 2026;

  /// Round 78 sprint 7 — public test API.
  /// 사용자 SajuContext 기반 i번째 절기 mood 합성 (격국 anchor + 용신 suffix).
  /// 위임: _MonthlyFlow.moodFor.
  static String moodFor({
    required SajuContext ctx,
    required int index,
    required bool useKo,
  }) => _MonthlyFlow.moodFor(ctx: ctx, index: index, useKo: useKo);

  /// R107 #6 — public test API.
  /// 재성(정재·편재) 십신 빈도 → 돈 흐름 분기 라벨.
  /// 위임: _AnnualSummary.wealthShape.
  /// 반환: 'jeong' / 'pyeon' / 'balanced' / 'light' / 'none'.
  static String wealthShapeForTest(SajuContext ctx) =>
      _AnnualSummary.wealthShape(ctx);

  /// R107 #6 — public test API.
  /// 십신 빈도 map 직접 받아 돈 흐름 분기 라벨 (deterministic 검증용).
  static String wealthShapeFromFreqForTest(Map<TenGod, int> freq) =>
      _AnnualSummary.wealthShapeFromFreq(freq);

  /// R107 #6 — public test API.
  /// 신년 총평 [6] 돈 흐름 문단 (KO) — ctx 의 재성 구조 기반.
  static String wealthFlowKoForTest(SajuContext ctx) {
    final s = _AnnualSummary(saju: SajuResult.dummy(), yongsin: '火', useKo: true);
    return s._wealthFlowKo(ctx);
  }

  /// R107 #6 — public test API.
  /// _AnnualSummary 본문 전체 — 재성 구조 회귀 검증용.
  static String annualSummaryBodyForTest({
    required SajuResult saju,
    required bool useKo,
  }) {
    return _AnnualSummary.bodyText(saju: saju, useKo: useKo);
  }

  /// R93 sprint 6 — public test API.
  /// 12 area dynamic readings (CAREER ~ LEGACY) — 사주 anchor 반영.
  /// 위임: _TwelveAreas._buildAreaReadings.
  static List<(String, String)> areaReadingsFor({
    required SajuResult saju,
    required ({String themeKo, String themeEn, dynamic godGan, dynamic godJi})
    theme,
    required bool useKo,
  }) {
    final ctx = SajuContext.from(saju, today: DateTime(year, 1, 1));
    return _TwelveAreas(
      theme: theme,
      saju: saju,
      useKo: useKo,
    )._buildAreaReadings(theme: theme, saju: saju, ctx: ctx, useKo: useKo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Round 77 sprint 8 — SajuResult.dummy() fallback 제거.
    final sajuOrNull = ref.watch(sajuResultProvider);
    if (sajuOrNull == null) {
      return const SajuRequiredEmpty();
    }
    final saju = sajuOrNull;
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

    final yearGanji = SeunService.yearGanji(year); // 丙午
    final theme = SeunService.annualTheme(
      dayMaster: saju.dayPillar.chunGan,
      solarYear: year,
    );

    final el = saju.elements;
    final strength = StrengthService.judge(
      dayMasterElement: saju.dayPillar.chunGanElement,
      monthJi: saju.monthPillar.jiJi,
      wood: el.wood,
      fire: el.fire,
      earth: el.earth,
      metal: el.metal,
      water: el.water,
      dayMaster: saju.dayPillar.chunGan,
      yearJi: saju.yearPillar.jiJi,
      dayJi: saju.dayPillar.jiJi,
      hourJi: saju.hourPillar?.jiJi,
    );
    final yongsin = YongsinService.judge(
      dayMasterElement: saju.dayPillar.chunGanElement,
      strengthLabel: strength.label,
      wood: el.wood,
      fire: el.fire,
      earth: el.earth,
      metal: el.metal,
      water: el.water,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const PillarBottomNavStatic(activeIdx: 2),
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/reports'),
        ),
        title: Text(
          useKo ? '2026 신년운세 · 歲 運' : 'NEW YEAR 2026 · 歲 運',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 5,
            color: AppColors.ink,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(yearGanji: yearGanji, useKo: useKo),
            _AnnualThemeSection(
              themeText: useKo ? theme.themeKo : theme.themeEn,
              yongsin: yongsin.yongsin,
              useKo: useKo,
            ),
            // R93 sprint 5 — 사용자 mandate verbatim: "한해 어떨지 쭉 매우 길게 총평이
            // 있어야지 너무 짧아". 사주 anchor (일간 5행 vs 2026 화 / 격국 / 용신
            // / 십신 / 신강·신약) 기반 1000~1500자 총평 새 섹션.
            // R110 Sprint 2 — 연간 총평은 무료(playbook ④ "연간 총평 + 3개월").
            _AnnualSummary(saju: saju, yongsin: yongsin.yongsin, useKo: useKo),
            // R110 Sprint 2 REWORK — playbook ④: 무료 = "연간 총평 + 3개월".
            // 입춘 이후 첫 3개월(寅·卯·辰 절기)만 compact 로 무료 노출. 새 데이터
            // 없이 _MonthlyFlow.moodFor + JolCalendar2026.displayOrder 재사용.
            _FreeMonthlyPreview(saju: saju, year: year, useKo: useKo),
            // R110 Sprint 2 REWORK — 프리미엄 = "12개월 전체 + 12영역 상세".
            // unlocked child 안에 _MonthlyFlow(12개월 전체) + _TwelveAreas(12영역)
            // 를 함께 둔다. locked 는 섹션 묶음 단위 placeholder (본문 truncate/blur X).
            PremiumGate(
              feature: PremiumFeature.newYearAreas,
              label: useKo
                  ? '2026 신년운세 · 12개월 흐름과 열두 영역'
                  : 'New Year 2026 · Full Monthly Flow & Twelve Areas',
              unlocked: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthlyFlow(saju: saju, year: year, useKo: useKo),
                  _TwelveAreas(theme: theme, saju: saju, useKo: useKo),
                ],
              ),
              locked: (_) => PremiumLockedSection(
                feature: PremiumFeature.newYearAreas,
                title: useKo
                    ? '4월 이후 월별 흐름 · 열두 영역 상세'
                    : 'Monthly Flow After April · Twelve Areas',
                description: useKo
                    ? '입하부터 대설까지 남은 아홉 달의 월별 흐름과, 연애·일·재물 등 열두 영역을 테마별로 짚어주는 상세 풀이는 프리미엄팩에서 열려요.'
                    : 'The remaining nine months of monthly flow and theme-by-theme '
                        'readings across twelve areas open with the Premium Pack.',
              ),
            ),
            _Counsel(useKo: useKo),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String yearGanji;
  final bool useKo;
  const _Hero({required this.yearGanji, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YEAR  2026 · 歲 運',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                yearGanji,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                  height: 1.0,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  useKo ? '병오년 · 火 馬' : 'Year of Fire Horse',
                  style: useKo
                      ? GoogleFonts.notoSerifKr(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: AppColors.ink,
                          letterSpacing: 0.3,
                        )
                      : GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            useKo
                ? '병오(丙午)는 한낮의 태양이 말처럼 달리는 해. 2026년은 자유로움과 추진력, 주목의 기운이 강하게 도는 해예요. 다만 화기(火氣)가 강한 만큼, 절제와 호흡 조절이 한 해 풍요의 열쇠가 됩니다.'
                : 'Bing Wu (丙午) — midday sun riding a horse. 2026 runs strong on freedom, forward thrust, and the pull of the spotlight. Yet the fire is intense; pacing and breath tend to decide what the year leaves you.',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnualThemeSection extends StatelessWidget {
  final String themeText;
  final String yongsin;
  final bool useKo;
  const _AnnualThemeSection({
    required this.themeText,
    required this.yongsin,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    String elKo(String e) =>
        {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'}[e] ?? e;
    final yongIn2026 = yongsin == '火';
    final advice = useKo
        ? (yongIn2026
              ? '용신이 ${elKo(yongsin)} — 병오년의 火 기운이 당신 용신과 같은 결이에요. 큰 결정을 꺼내보기 좋은 자리.'
              : '용신은 ${elKo(yongsin)}. 병오년 화기에 휘둘리지 않도록 ${elKo(yongsin)}을 의식적으로 보충하세요.')
        : (yongIn2026
              ? "Your yongsin is $yongsin — 2026's fire runs with it. A good window for the big decisions."
              : 'Your yongsin is $yongsin. Replenish it deliberately so the year\'s fire does not deplete you.');

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
          Text(
            useKo ? 'YOUR  ANNUAL  THEME · 主 題' : 'YOUR  ANNUAL  THEME · 主 題',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            themeText.isEmpty
                ? (useKo ? '비화 — 동등한 결' : 'Peer — equal vibe')
                : themeText,
            style: GoogleFonts.notoSerifKr(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          Text(
            advice,
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    height: 1.75,
                    letterSpacing: 0.3,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent,
                    height: 1.75,
                  ),
          ),
        ],
      ),
    );
  }
}

/// R93 sprint 5 — 신년운세 사용자 맞춤 매우 긴 총평 (1000~1500자).
///
/// 사용자 mandate verbatim: "한해 어떨지 쭉 매우 길게 총평이 있어야지 너무 짧아
/// 다른 사이트이나 앱은 어떻게 했나 봐봐"
///
/// unsin / 점신 / 한경운세 벤치마크:
///   - 총평 long-form 800~1500자 (한경 무료 대비 2~3배)
///   - 사주 anchor 기반 personalize (일간 5행 vs 세운 5행 + 격국 + 용신)
///   - 5~7 문단 구조 (큰 흐름 / 격국 / 용신 / 십신 / 길흉 시기 / 조언)
class _AnnualSummary extends StatelessWidget {
  final SajuResult saju;
  final String yongsin;
  final bool useKo;
  const _AnnualSummary({
    required this.saju,
    required this.yongsin,
    required this.useKo,
  });

  static const Map<String, String> _elKoMap = {
    '木': '나무',
    '火': '불',
    '土': '흙',
    '金': '쇠',
    '水': '물',
  };

  String _elKo(String e) => _elKoMap[e] ?? e;

  /// 2026 = 丙午 (병오년) = 火 강왕. 사용자 일간 5행 vs 火 관계 매핑.
  String _yearRelation(String myEl) {
    const generates = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    const overcomes = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
    if (myEl == '火') return 'same';
    if (generates[myEl] == '火') return 'iGenerate'; // 木 → 火
    if (generates['火'] == myEl) return 'theyGenerate'; // 火 → 土
    if (overcomes[myEl] == '火') return 'iOvercome'; // 水 → 火
    if (overcomes['火'] == myEl) return 'theyOvercome'; // 火 → 金
    return 'neutral';
  }

  /// R93 sprint 6 — 사용자 mandate: "중복된 패턴 다 수정해".
  /// 일간 5행만으로 분기하면 같은 5행 사용자 모두 동일 본문. 일지 vs 2026 午
  /// (병오년 본기 지지) 관계 한 줄을 추가해 같은 일간이라도 일지가 다르면
  /// 다른 본문이 나오게 함.
  /// returns: 'sameWu' (午午 복음) / 'clash' (子午충) / 'hap6' (午未 육합) /
  ///          'samhap' (寅午戌 삼합 火국) / 'neutral'.
  String _yearBranchRelationToWu(String myJi) {
    if (myJi == '午') return 'sameWu';
    if (myJi == '子') return 'clash'; // 子午 충
    if (myJi == '未') return 'hap6'; // 午未 육합
    if (myJi == '寅' || myJi == '戌') return 'samhap'; // 寅午戌 삼합 火국
    return 'neutral';
  }

  /// Part A — 일지 vs 午 관계 한 줄 (KO).
  String _branchMicroKo(String rel, String myJi) {
    switch (rel) {
      case 'sameWu':
        return ' 게다가 본인 일지(午)가 병오년 지지와 그대로 겹쳐서(복음·伏吟) 한 해의 화기가 본인 자리에 직격으로 들어와요 — 같은 火 일간이어도 본인이 한 해의 흐름을 가장 가까이서 느끼는 구조예요.';
      case 'clash':
        return ' 다만 본인 일지(子)와 병오년 지지(午)가 정면충돌(子午 충)하는 구도라, 한 해의 흐름이 본인 자리를 흔든다 느껴지는 순간이 한 번씩 올 수 있어요 — 같은 일간이어도 일지가 子라면 환경 변화·이동·관계 재편 쪽 결정이 평소보다 자주 떠오르기 쉬워요.';
      case 'hap6':
        return ' 그리고 본인 일지(未)가 병오년 지지(午)와 육합(午未合)으로 묶여서, 한 해 동안 본인 자리가 한 해의 본기와 자연스럽게 손을 잡는 결이에요 — 같은 일간이어도 협력·동행·파트너십 자리에 무게를 두면 결과가 더 잘 따라오기 쉬워요.';
      case 'samhap':
        final mine = myJi == '寅' ? '寅' : '戌';
        return ' 더해서 본인 일지($mine)가 병오년 지지(午)와 삼합(寅午戌 火국)으로 묶여서, 한 해 동안 화기가 본인 자리를 함께 끌어올려 주는 구도예요 — 같은 일간이어도 무대·표현·인지도 자리에 공들이면 한 단계 올라서기 좋은 흐름이에요.';
      default:
        return ' 본인 일지($myJi)는 병오년 지지(午)와 직접 합·충 관계가 없어서, 같은 일간이어도 일지에 따라 한 해의 체감 속도가 달라요 — 본인 자리는 비교적 안정적인 거리감으로 한 해 흐름을 받게 돼요.';
    }
  }

  /// Part A — 일지 vs 午 관계 한 줄 (EN).
  String _branchMicroEn(String rel, String myJi) {
    switch (rel) {
      case 'sameWu':
        return ' Your day branch (午) directly overlaps the year branch — a fu-yin doubling that pulls the year\'s fire straight onto your seat.';
      case 'clash':
        return ' Your day branch (子) clashes with the year branch (午) — a 子午 chung, so moves and reshuffles tend to surface around your position more than usual.';
      case 'hap6':
        return ' Your day branch (未) forms the 午未 six-harmony with the year — partnerships and co-work tend to pay extra when you lean on them.';
      case 'samhap':
        return ' Your day branch ($myJi) joins the 寅午戌 fire triad with the year — visibility and stage roles tend to get a lift when you lean into them.';
      default:
        return ' Your day branch ($myJi) has no direct hap/chung with the year branch (午) — a steadier distance from the year\'s tempo.';
    }
  }

  /// R107 #6 — public test API.
  /// 신년 총평 본문 전체를 widget 렌더 없이 합성. 재성 분기 회귀 검증용.
  static String bodyText({required SajuResult saju, required bool useKo}) {
    return _AnnualSummary(
      saju: saju,
      yongsin: '火',
      useKo: useKo,
    )._buildBody();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? 'ANNUAL  SUMMARY · 總 評' : 'ANNUAL  SUMMARY · 總 評',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _buildBody(),
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.95,
            ),
          ),
        ],
      ),
    );
  }

  /// R93 sprint 5 / R107 #6 — 신년 총평 7 문단 본문 합성.
  /// build() 와 bodyText() (test API) 가 공유.
  String _buildBody() {
    final ctx = SajuContext.from(saju, today: DateTime(2026, 1, 1));
    final myEl = saju.dayPillar.chunGanElement;
    final myJi = saju.dayPillar.jiJi;
    final rel = _yearRelation(myEl);
    final branchRel = _yearBranchRelationToWu(myJi);
    final branchMicro = useKo
        ? _branchMicroKo(branchRel, myJi)
        : _branchMicroEn(branchRel, myJi);

    // 7 문단 구조: 큰 흐름 / 격국 / 용신/희신/기신 / 십신 강세 / 길흉 시기 /
    // 사람·관계·돈 큰 그림 / 마무리 조언 — 평균 200~300자 × 7 = 1400~2100자 (헷지: 길게).
    final body = StringBuffer();

    if (useKo) {
      // R96 — 사용자 mandate "...에요로 계속 끝나니까 툭툭 끊기는 느낌 ... ai같아".
      // 7 문단 각각을 NaturalProseJoiner.polish() 로 통과시켜 paragraph 내부
      // 문장 사이에 connector + 어미 다양화 주입. 7 문단 구조 (writeln('') 빈 줄)
      // 는 그대로 보존 — 마지막 join 단계만 utility swap.
      void writePara(String text) =>
          body.writeln(NaturalProseJoiner.polish(text));

      // [1] 큰 흐름 (오행 관계 base + R93 sprint 6 일지 vs 午 micro) — 300자+α
      switch (rel) {
        case 'same':
          writePara(
            '올해 병오년의 본기는 火 — 당신 일간과 같은 오행이에요(비화). 한 해의 기운이 당신 본성과 같은 결이라, 평소 망설이던 표현·창작·무대형 결정을 꺼낼 때 평소보다 자연스럽게 풀리기 쉬운 자리예요. 다만 같은 오행이 강하게 겹치는 자리라, 한 박자만 잘못 밟으면 과열로 가기 쉬워요 — 한여름 어딘가에 의식적인 휴식 한 주를 미리 박아두면 한 해 페이스를 지키는 데 도움이 됩니다. 오행이 같다는 건 끌어주는 도움이 적다는 뜻이기도 해서, 큰 결정 앞에서는 객관적인 의견을 한 번 더 들어보는 습관이 도움이 돼요.$branchMicro',
          );
          break;
        case 'iGenerate':
          writePara(
            '올해는 당신의 일간(${_elKo(myEl)})이 병오년 본기(火)를 직접 살리는 상생(相生) 자리에 놓여요. 당신이 손대는 일·관계·창작에 공들이는 만큼 결과물이 자라기 좋은 결이라, 주는 쪽에 서는 한 해예요. 다만 주는 자리는 자기 페이스를 잃기 쉬워서, 한 달에 한 번은 자기를 위한 작은 회복 의식을 두면 좋아요. 상생은 시간이 지난 뒤 결실이 보이는 구조라, 5월~7월에 들인 노력이 가을·겨울에 돌아오기 쉬워요 — 그때까지 페이스를 잃지 않는 게 핵심이에요.$branchMicro',
          );
          break;
        case 'theyGenerate':
          writePara(
            '올해는 병오년 본기(火)가 당신의 일간(${_elKo(myEl)})을 살려주는 상생(相生) 자리예요. 한 해의 기운이 당신을 자라게 돕는 쪽이라, 평소 부족하다 느끼던 자리 — 표현·인지도·기회 — 가 채워질 기회가 평소보다 자주 오기 쉬워요. 흐름이 들어올 때 받는 만큼 표현하는 습관을 같이 챙기면, 관계가 한 해 동안 더 두텁게 자리잡기 좋아요. 만나는 사람 한 명 한 명에게 작은 표현을 자주 해두면, 그 인연이 오래 남는 자리가 됩니다.$branchMicro',
          );
          break;
        case 'iOvercome':
          writePara(
            '올해는 당신의 일간(${_elKo(myEl)})이 병오년 본기(火)를 제어하는 상극(相剋) 자리에 놓여요. 한 해의 강한 화기에 휩쓸리기보다 자기 페이스로 결정을 내리기 좋은 위치예요. 다만 제어하는 자리는 외로워지기 쉬워서, 큰 결정 앞에서 의지할 사람이 없다 느껴지는 순간이 오면 — 그때마다 객관적인 데이터(가계부·일정·만난 사람 목록)를 들여다보는 습관이 도움이 됩니다. 한 해의 본기가 강한데 그 위에 서 있는 자리라, 잘 쓰면 한 번에 큰 도약을 만들 수 있는 발판이 되기도 해요.$branchMicro',
          );
          break;
        case 'theyOvercome':
          writePara(
            '올해는 병오년 본기(火)가 당신의 일간(${_elKo(myEl)})을 제어하는 상극(相剋) 자리예요. 한 해의 강한 화기가 당신을 누르는 쪽이라, 평소보다 페이스를 잃기 쉽고 결정·관계·돈 흐름에서 휘둘린다 느끼는 순간이 올 수 있어요. 다만 상극 자리는 그 압박을 잘 견디면 한 단계 단단해지는 구조라, "올해는 무리하지 말자"는 한 줄을 한 해 내내 자기에게 자주 되뇌어주면 도움이 됩니다. 한여름(5~7월) 화기 정점에는 의식적으로 차분한 시기를 만들어두고, 가을 이후를 진짜 성장의 자리로 잡아두면 좋아요.$branchMicro',
          );
          break;
        default:
          writePara(
            '올해는 당신의 일간(${_elKo(myEl)})과 병오년 본기(火) 사이에 직접 생극 관계가 없는 중립 자리예요. 한 해의 색이 본인 색과 직접 겹치지도, 맞부딪치지도 않아서, 자기 색을 그대로 유지하면서 한 해를 보내기 좋은 구조예요. 다만 강한 끌림도 강한 자극도 적은 자리라, 가만히 흘러가다 보면 한 해가 빨리 지나간 느낌이 들 수 있어요. 작은 도전 한 가지, 새로운 만남 한 명, 새 루틴 한 가지를 의식적으로 만들어두면 그만큼 한 해가 또렷하게 남기 쉬워요.$branchMicro',
          );
      }

      // [2] 격국 — 200~300자
      body.writeln('');
      final gyeokguk = ctx.gyeokgukShort.isEmpty ? '비전형' : ctx.gyeokgukShort;
      writePara(
        '본인 본격(格局)은 "$gyeokguk"입니다. 격국은 한 사람의 본업·천명 자리를 가리키는 큰 그림인데, 병오년 동안 이 본격이 어떻게 자극받는지가 한 해 결정의 바탕이 돼요. 격국의 본질을 잊지 않고 그 결 위에서 결정을 내리면, 1년이 끝났을 때 자기 자리에 더 가까운 모습으로 도착하기 쉬워요. 반대로 본격을 거스르는 일·관계·돈 결정은 한 해 동안 한 번씩 피곤하게 되돌아오기 쉬우니, 결정 전에 한 번 더 짚어보면 좋아요.',
      );

      // [3] 용신/희신/기신 — 250~400자
      body.writeln('');
      writePara(
        '한 해 동안 가장 의식적으로 챙겨야 할 5행은 용신(用神) "${_elKo(ctx.yongsin)}"입니다. 용신은 사주의 균형을 잡아주는 핵심 5행으로, 한 해의 결정·만남·환경 선택에서 이 5행을 늘 가까이 두면 자연스럽게 흐름이 풀립니다. 희신은 "${_elKo(ctx.huisin)}" — 용신을 돕는 보조 5행이라 같이 의식하면 좋고, 반대로 기신 "${_elKo(ctx.gisin)}"은 가까이 두면 한 해 페이스가 흔들리는 5행이라 의도적으로 거리를 두는 게 좋아요. 색깔·음식·공간·만나는 사람 결까지 — 이 세 5행의 균형이 한 해의 운기를 좌우합니다.${ctx.yongsin == '火'
            ? ' 특히 용신이 火 → 병오년이 직접 당신을 살리는 해라서 큰 결정에 가장 적합한 한 해예요.'
            : ctx.gisin == '火'
            ? ' 다만 기신이 火 → 병오년 화기가 한 해 동안 가장 큰 부담이 되니, 의식적으로 수기(水)·금기(金) 자리를 가까이 두는 게 핵심입니다.'
            : ''}',
      );

      // [4] 십신 강세 — 200자
      body.writeln('');
      final topGod = _topTenGod(ctx);
      if (topGod != null) {
        writePara(
          '본인 사주에서 가장 강한 십신은 "$topGod"입니다. 이 십신이 강하다는 건 한 해 동안 이 영역에서 흐름이 가장 많이 일어난다는 뜻이에요. ${_godHint(topGod)} 병오년이 이 영역을 자극해서 한 해 동안 가장 큰 변화가 이 자리에서 일어날 가능성이 높으니, 미리 마음의 준비를 해두면 좋아요.',
        );
      }

      // [5] 길흉 시기 — 250~350자
      body.writeln('');
      writePara(
        '월별 큰 흐름은 절기 기준으로 이렇게 잡아두면 좋아요. 2~4월(봄 절기 입춘·경칩·청명)은 한 해의 씨앗을 심는 시기 — 새 결정·새 관계·새 루틴을 시작하기 좋아요. 5~7월(여름 절기 입하·망종·소서)은 병오년 화기 정점 — 무대·표현·인지도 자리에서 공들인 일이 가장 크게 드러나기 쉽지만, 의식적인 휴식을 한 번씩 두지 않으면 과열로 가기 쉬워요. 8~10월(가을 절기 입추·백로·한로)은 결실의 시기 — 봄·여름에 들인 노력이 돌아오기 쉬운 자리예요. 11~12월(겨울 절기 입동·대설)은 다음 해를 위한 저장의 시기 — 큰 결정보다 정리와 비축에 시간을 두면 좋습니다.',
      );

      // [6] 사람·관계·돈 — 250~350자
      // R107 #6 — 돈 흐름 문단을 사용자 실제 재성(정재·편재) 구조로 분기.
      // 기존: "정재보다 편재 성격" 고정 → 재성 구조 무관하게 모든 사용자가 동일 문장.
      body.writeln('');
      writePara(
        '관계 영역은 봄에 정리, 여름에 확장, 가을에 정착으로 리듬을 잡아두면 좋아요. 오래된 친구·연인과의 거리감을 봄에 한 번 들여다보기 좋고, 여름 무대에서 새 인연이 가까워질 자리가 열리기 쉬워요. 가을 이후에 두텁게 자리잡는 인연이 있다면 한 해의 가장 큰 선물이 될 수 있어요. ${_wealthFlowKo(ctx)} 큰 돈이 흘러올 때 바로 쓰지 않고 한 박자 보관하는 습관을 들이면 가을·겨울 안정에 도움이 됩니다.',
      );

      // [7] 마무리 조언 — 200자
      body.writeln('');
      writePara(
        '한 해의 한 줄 조언은 — "${_oneLineCounsel(rel)}" — 이 한 줄을 한 해 내내 자기에게 되뇌어주세요. 병오년은 빛이 강한 만큼 그림자도 함께 자라기 쉬운 결이에요. 자기 색을 잃지 않으면서 한 해의 흐름을 타려면, 매달 한 번 자기 페이스를 점검하는 작은 의식 한 가지를 두는 게 가장 큰 보약이에요. 12월 31일 밤에 한 해를 한 줄로 적어두면, 그 한 줄이 2027년의 첫 결정으로 이어지기 쉬워요.',
      );
    } else {
      // English — condensed (Korean is primary mandate; English keeps length similar but shorter).
      body.writeln(
        '2026 (Bing Wu / Fire Horse) places your day master ($myEl) in a ${rel == 'same'
            ? 'matching'
            : rel == 'iGenerate'
            ? 'generating (you → year)'
            : rel == 'theyGenerate'
            ? 'generating (year → you)'
            : rel == 'iOvercome'
            ? 'controlling (you → year)'
            : rel == 'theyOvercome'
            ? 'controlling (year → you)'
            : 'neutral'} relation with the year stem.$branchMicro',
      );
      body.writeln(
        'Your gyeokguk is "${ctx.gyeokgukShort.isEmpty ? 'unconventional' : ctx.gyeokgukShort}". The year activates this core structure — decisions aligned with it tend to leave you closer to your true position by year-end.',
      );
      body.writeln(
        'Yongsin: ${ctx.yongsin}. Huisin: ${ctx.huisin}. Gisin: ${ctx.gisin}. Keep yongsin and huisin close (colors, food, spaces, the people around you); deliberately distance the gisin.',
      );
      body.writeln(
        'Spring (Feb–Apr): plant new seeds. Summer (May–Jul): fire peaks — visibility but burnout risk. Autumn (Aug–Oct): harvest. Winter (Nov–Dec): store and prepare for 2027.',
      );
      body.writeln(
        'Relationships: spring is for sorting old ties, summer for opening new ones, autumn for settling depth. ${_wealthFlowEn(ctx)}',
      );
      body.writeln('One-line counsel: ${_oneLineCounsel(rel)}');
    }

    return body.toString().trim();
  }

  /// 십신 빈도 최강 1개 라벨 (KR).
  String? _topTenGod(SajuContext ctx) {
    if (ctx.tenGodFrequency.isEmpty) return null;
    final sorted = ctx.tenGodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value == 0) return null;
    const labels = {
      TenGod.bigyeon: '비견',
      TenGod.geopjae: '겁재',
      TenGod.siksin: '식신',
      TenGod.sanggwan: '상관',
      TenGod.pyeonjae: '편재',
      TenGod.jeongjae: '정재',
      TenGod.pyeongwan: '편관',
      TenGod.jeonggwan: '정관',
      TenGod.pyeonin: '편인',
      TenGod.jeongin: '정인',
    };
    return labels[top.key];
  }

  String _godHint(String label) {
    switch (label) {
      case '비견':
      case '겁재':
        return '동료·친구·경쟁자 자리가 한 해 흐름의 중심이 되기 쉬워요. 공동작업·창업·팀 결정 자리에 큰 흐름이 지나갈 수 있으니 미리 챙겨두면 좋아요.';
      case '식신':
      case '상관':
        return '표현·창작·아이디어 자리가 한 해 흐름의 중심이 되기 쉬워요. 글·콘텐츠·강의·SNS 등 외부로 표현하는 활동이 한 해의 자원이 되기 좋아요.';
      case '편재':
      case '정재':
        return '돈·자산·재산 자리가 한 해 흐름의 중심이 되기 쉬워요. 큰 결정 한 번이 재산 그림을 바꿀 자리가 열리기 쉬우니, 그 자리를 신중하게 다루면 좋아요.';
      case '편관':
      case '정관':
        return '직장·권위·책임 자리가 한 해 흐름의 중심이 되기 쉬워요. 승진·이직·자격증 등 공식적인 결정 자리가 한 해의 큰 흐름을 여는 실마리가 되기 쉬워요.';
      case '편인':
      case '정인':
        return '학습·공부·자기 안 들여다보는 시간 자리가 한 해 흐름의 중심이 되기 쉬워요. 책·강의·자격증·명상 등 안으로 들어가는 활동이 한 해의 자원이 되기 좋아요.';
      default:
        return '본인 본업 자리가 한 해 흐름의 중심이 되기 쉬워요.';
    }
  }

  String _oneLineCounsel(String rel) {
    switch (rel) {
      case 'same':
        return '같은 색의 해 — 무리하지 말고, 한 번 더 자기에게 묻고 결정';
      case 'iGenerate':
        return '주는 해 — 페이스를 잃지 않으면서 끝까지';
      case 'theyGenerate':
        return '받는 해 — 받는 만큼 표현으로 돌려주기';
      case 'iOvercome':
        return '제어하는 해 — 큰 도약 자리, 데이터로 결정';
      case 'theyOvercome':
        return '눌리는 해 — 무리 금지, 가을 이후 진짜 성장';
      default:
        return '중립의 해 — 작은 도전 한 가지로 의미를 만들기';
    }
  }

  /// R107 #6 — 사용자 실제 재성(정재·편재 십신 개수) 구조로 돈 흐름 문단 분기.
  ///
  /// 기존 총평 [6] 문단은 재성 구조와 무관하게 "정재보다 편재" 가 고정 삽입돼
  /// 많은 사용자가 같은 문장을 봤다. ctx.tenGodFrequency 의 정재·편재 카운트를
  /// 읽어 4 분기 — 정재 우세 / 편재 우세 / 정·편재 균형 / 재성 약함.
  /// v5 voice: 단정 금지·발동 조건형 ("쉬워요" / "기울어요" / "도움이 돼요").
  ///
  /// 분기 5 종 (public test 검증):
  ///   wealthShape ∈ { jeong, pyeon, balanced, light, none }.
  static String wealthShape(SajuContext ctx) =>
      wealthShapeFromFreq(ctx.tenGodFrequency);

  /// 십신 빈도 map 직접 받는 형 — deterministic 검증용.
  static String wealthShapeFromFreq(Map<TenGod, int> freq) {
    final jeong = freq[TenGod.jeongjae] ?? 0;
    final pyeon = freq[TenGod.pyeonjae] ?? 0;
    final total = jeong + pyeon;
    if (total == 0) return 'none';
    if (total == 1) return 'light';
    if (jeong > pyeon) return 'jeong';
    if (pyeon > jeong) return 'pyeon';
    return 'balanced';
  }

  String _wealthFlowKo(SajuContext ctx) {
    switch (wealthShape(ctx)) {
      case 'jeong':
        return '본인 사주는 재성 중 정재(고정 수입·꾸준한 결실) 쪽이 더 두텁게 자리해요. 한 해의 돈 흐름도 큰 한 방보다 매달 쌓이는 결을 챙길 때 더 안정되기 쉬우니, 정기적인 수입·저축 루틴을 봄에 한 번 정비해두면 좋아요.';
      case 'pyeon':
        return '본인 사주는 재성 중 편재(기회·투자·유동 수입) 쪽이 더 두텁게 자리해요. 한 해의 돈 흐름도 큰 흐름 한 번이 지나갈 때를 대비해두는 게 잘 맞으니, 1~3월 정보 수집과 4~5월 결정 모드를 미리 챙겨두면 그 자리를 놓치지 않기 쉬워요.';
      case 'balanced':
        return '본인 사주는 정재(고정 수입)와 편재(기회·투자)가 비슷한 무게로 자리해요. 한 해의 돈 흐름도 꾸준한 결실과 큰 기회를 둘 다 열어둘 때 균형이 잡히기 쉬우니, 안정 루틴 하나와 기회 대비 하나를 같이 챙겨두면 좋아요.';
      case 'light':
        return '본인 사주는 재성이 한 자리만 있어서, 한 해의 돈 흐름은 큰 변동보다 한두 번의 또렷한 결정 자리를 중심으로 움직이기 쉬워요. 그 한 자리를 신중하게 다루면 한 해 재정이 한결 또렷해지기 쉬워요.';
      default: // none
        return '본인 사주는 재성이 거의 없는 결이라, 한 해의 돈 흐름은 고정 수입보다 인연·기회 쪽 우회 경로로 들어오기 쉬워요. 사람과의 관계를 잘 챙기는 것이 그대로 재정의 길이 되기 쉬운 한 해예요.';
    }
  }

  String _wealthFlowEn(SajuContext ctx) {
    switch (wealthShape(ctx)) {
      case 'jeong':
        return 'Money: your chart leans toward jeongjae (steady, recurring income) among the wealth stars, so the flow tends to settle when you tend a regular savings rhythm rather than chasing one big hit.';
      case 'pyeon':
        return 'Money: your chart leans toward pyeonjae (opportunity and fluid income) among the wealth stars, so a big flow tends to pass once — collecting info Jan–Mar and deciding Apr–May tends to help you catch it.';
      case 'balanced':
        return 'Money: jeongjae (fixed income) and pyeonjae (opportunity) sit at similar weight in your chart, so the flow tends to balance when you keep both a steady routine and a readiness for the big window.';
      case 'light':
        return 'Money: a single wealth star sits in your chart, so the year tends to move around one or two clear decision points rather than wide swings — handling that one spot with care tends to keep the year steadier.';
      default: // none
        return 'Money: wealth stars are scarce in your chart, so the flow tends to arrive through people and opportunity more than fixed income — tending your relationships tends to double as tending your finances.';
    }
  }
}

/// R110 Sprint 2 REWORK — playbook ④ 무료 "3개월" 섹션.
///
/// 입춘 이후 첫 3개월(寅·卯·辰 절기) 흐름만 compact 로 무료 노출한다. 새
/// 데이터/문구를 만들지 않고 `_MonthlyFlow.moodFor` 의 절기 mood + 격국
/// anchor + 용신 suffix 합성과 `JolCalendar2026.displayOrder` 를 그대로
/// 재사용한다. 4월 이후 9개월·12영역은 PremiumGate 로 따로 잠긴다.
///
/// ⚠️ displayOrder[0] 은 소한(丑) — 입춘이 아니다. 무료 3개월은 명리학
/// 새해(입춘) 이후라야 하므로 displayOrder 를 `skip(1)` 해 寅·卯·辰 을 쓴다.
/// moodFor 의 index 도 displayOrder index(寅=1·卯=2·辰=3)를 그대로 넘겨
/// 절기 mood 가 슬롯과 어긋나지 않게 한다.
class _FreeMonthlyPreview extends StatelessWidget {
  final SajuResult saju;
  final int year;
  final bool useKo;
  const _FreeMonthlyPreview({
    required this.saju,
    required this.year,
    required this.useKo,
  });

  /// 무료 노출 개월 수 — playbook ④ "연간 총평 + 3개월".
  static const int freeMonths = 3;

  @override
  Widget build(BuildContext context) {
    final ctx = SajuContext.from(saju, today: DateTime(year, 1, 1));
    // displayOrder[0] = 소한(丑). 무료 3개월은 입춘 이후라야 하므로 첫 칸
    // (소한)을 건너뛰고 寅·卯·辰 세 칸을 쓴다. moodFor index 도 displayOrder
    // index(寅=1·卯=2·辰=3)와 맞춰야 절기 mood 가 어긋나지 않는다.
    const firstFreeOrderIndex = 1; // 입춘(寅) = displayOrder index 1.
    final slots = JolCalendar2026.displayOrder
        .skip(firstFreeOrderIndex)
        .take(freeMonths)
        .toList();
    return Container(
      key: const Key('new_year_free_monthly_preview'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? 'FIRST  THREE  MONTHS · 三 月' : 'FIRST  THREE  MONTHS · 三 月',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useKo
                ? '입춘으로 새해가 열린 뒤 첫 세 달의 흐름이에요. 절기 기준 월건이라 양력 달력과는 경계가 달라요.'
                : 'The flow of the first three months after Ipchun opens the year. '
                      'Months follow solar terms, not the Gregorian calendar.',
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    color: AppColors.inkLight,
                    height: 1.65,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.inkLight,
                    height: 1.6,
                  ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              children: List.generate(freeMonths, (i) {
                final slot = slots[i];
                // slots 는 이미 소한을 skip 한 寅·卯·辰. moodFor index 는
                // displayOrder index 라야 절기 mood 가 슬롯과 맞으므로
                // skip 한 만큼(firstFreeOrderIndex) 더한다.
                final moodIndex = i + firstFreeOrderIndex;
                final ganji = '${slot.monthStem}${slot.monthBranch}';
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.line, width: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          ganji,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: AppColors.accent,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              useKo ? slot.displayKo : slot.displayEn,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w500,
                                color: AppColors.taupe,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              NewYear2026Screen.moodFor(
                                ctx: ctx,
                                index: moodIndex,
                                useKo: useKo,
                              ),
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
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyFlow extends StatelessWidget {
  final SajuResult saju;
  final int year;
  final bool useKo;
  const _MonthlyFlow({
    required this.saju,
    required this.year,
    required this.useKo,
  });

  /// 2026 KASI 12절 source-of-truth.
  /// 데이터는 `JolCalendar2026` 에서 관리 (테스트도 동일 데이터 검증).
  static List<JolSlot> get _slots => JolCalendar2026.displayOrder;

  static const _moodsKo = <String>[
    '동지 직후 — 한 해의 씨앗이 땅속에 봉인된 시기. 큰 결정보다 정돈과 비축.',
    '입춘 — 새 해의 명리학 시작. 가벼운 시작과 약속의 한 줄.',
    '경칩 — 잠들었던 사람과 인연이 다시 움직이는 봄의 두 번째 마디.',
    '청명 — 흙이 풀리고 사람의 결도 풀립니다. 큰 청소·정리에 적합.',
    '입하 — 여름의 첫 신호. 화 기운이 본격 가동.',
    '망종 — 병오년 본기 가동. 무대·표현이 커지는 달.',
    '소서 — 화 기운 정점. 의식적인 휴식이 가을 결실을 결정.',
    '입추 — 가을의 첫 마디. 결실을 의식하고 마무리 모드.',
    '백로 — 이슬이 맺히는 달. 약속과 다짐을 글로 남기세요.',
    '한로 — 차가운 이슬. 재정·관계의 점검과 다이어트.',
    '입동 — 겨울의 시작. 사람을 가깝게, 계획은 깊게.',
    '대설 — 저장의 달. 다음 해를 위한 비축.',
  ];

  static const _moodsEn = <String>[
    'After winter solstice — last year\'s seed is sealed in the soil. Tidy, do not decide big.',
    'Ipchun — the myeongli new year starts here. A light beginning and one written promise.',
    'Gyeongchip — sleeping ties wake. The second beat of spring.',
    'Cheongmyeong — earth softens, so do people. Best for clearing and tidying.',
    'Ipha — first signal of summer. Fire engages.',
    'Mangjong — the engine of Bing Wu year roars. Stage and expression grow.',
    'Soseo — fire at its peak. A deliberate rest decides the autumn harvest.',
    'Ipchu — first beat of autumn. Switch to harvest mode.',
    'Baekro — month of dew. Put promises and contracts in writing.',
    'Hanro — cold dew. Audit finances and relationships; lighten the load.',
    'Ipdong — winter begins. Keep people close, plans deep.',
    'Daeseol — the storing month. Accumulate for next year.',
  ];

  /// Round 78 sprint 7 — 사용자 SajuContext 기반 i번째 절기 mood 합성.
  /// 기존 절기 라벨 (mood base) + 격국 anchor + 용신 5축 1줄 append.
  /// 격국 / 용신 모두 빈 ctx 시 base 그대로 (회귀 가드). [ctx] 는 required —
  /// null ctx 경로는 호출 측 (build) 에서 가드.
  /// 테스트에서 widget 렌더 없이 직접 검증 가능 — public static.
  static String moodFor({
    required SajuContext ctx,
    required int index,
    required bool useKo,
  }) {
    final base = useKo ? _moodsKo[index] : _moodsEn[index];
    final locale = useKo ? 'ko' : 'en';
    final gAnchor = DynamicTextResolver.gyeokgukAnchor(ctx, locale: locale);
    final ySuffix = DynamicTextResolver.yongsinSuffix(ctx, locale: locale);
    final parts = [gAnchor, ySuffix].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return base;
    if (useKo) return NaturalProseJoiner.append(base, parts);
    return '$base\n${parts.join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    // Round 78 sprint 7 — build 안에서 1회 합성. 12 절기 row 에 재사용 (12회 재합성 X).
    final newYearCtx = SajuContext.from(saju, today: DateTime(year, 1, 1));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? 'MONTHLY  FLOW · 月 運' : 'MONTHLY  FLOW · 月 運',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useKo
                ? '명리학 월건은 절기 기준입니다. 양력 달력이 아닌 입춘·경칩 등 절입일이 한 달의 경계입니다.'
                : 'Myeongli months follow solar terms — not the Gregorian calendar. Each month begins at its solar-term gate.',
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    color: AppColors.inkLight,
                    height: 1.65,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.inkLight,
                    height: 1.6,
                  ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              children: List.generate(12, (i) {
                final slot = _slots[i];
                final ganji = '${slot.monthStem}${slot.monthBranch}';
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.line, width: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          ganji,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: AppColors.accent,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              useKo ? slot.displayKo : slot.displayEn,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w500,
                                color: AppColors.taupe,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              NewYear2026Screen.moodFor(
                                ctx: newYearCtx,
                                index: i,
                                useKo: useKo,
                              ),
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
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwelveAreas extends StatelessWidget {
  final ({String themeKo, String themeEn, dynamic godGan, dynamic godJi}) theme;
  final SajuResult saju;
  final bool useKo;
  const _TwelveAreas({
    required this.theme,
    required this.saju,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final ctx = SajuContext.from(saju, today: DateTime(2026, 1, 1));
    final areas = _buildAreaReadings(
      theme: theme,
      saju: saju,
      ctx: ctx,
      useKo: useKo,
    );
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
          Text(
            useKo ? 'TWELVE  AREAS · 十 二 域' : 'TWELVE  AREAS · 十 二 域',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          ...areas.asMap().entries.map((e) {
            final isLast = e.key == areas.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Container(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
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
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.taupe,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      e.value.$2,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.5,
                        color: AppColors.ink,
                        height: 1.8,
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

  // ── R93 sprint 6 — 12 area dynamic builder ──────────────────────────────
  //
  // 사용자 mandate verbatim: "이와같이 중복된 패턴있으면 다 수정해".
  // 기존 const list 는 모든 사용자가 같은 12 area 본문을 봤음. 사주 anchor
  // (격국 / 강한 십신 / 용신/희신/기신 / 일지 vs 午 합·충 / 五行 강약) 를
  // 12 area 본문에 직접 반영해 사용자별 차별성 확보.
  //
  // 매핑:
  //   CAREER     ← gyeokguk + 강한 십신 (관/인/식상)
  //   WEALTH     ← 재성 (편재/정재) 빈도 + yongsin 가까움 여부
  //   LOVE       ← 일지 vs 午 합·충 (sameWu/clash/hap6/samhap/neutral)
  //   HEALTH     ← fire overload + gisin == 火 여부 + yongsin
  //   FAMILY     ← 비견/겁재 강약
  //   STUDY      ← 인성 (편인/정인) 빈도
  //   FRIENDS    ← 비견/겁재 강약 + 신살 (역마)
  //   TRAVEL     ← 일지 vs 午 충/합
  //   GROWTH     ← 식상 (식신/상관) 빈도 + theme
  //   LEGAL      ← 관성 + 신살 (괴강·양인)
  //   SPIRIT     ← yongsin + 인성
  //   LEGACY     ← gyeokguk + 60일주 hint
  List<(String, String)> _buildAreaReadings({
    required ({String themeKo, String themeEn, dynamic godGan, dynamic godJi})
    theme,
    required SajuResult saju,
    required SajuContext ctx,
    required bool useKo,
  }) {
    const elKo = {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'};
    String el(String e) => useKo ? (elKo[e] ?? e) : SajuContext.elementEn(e);

    final gFreq = ctx.tenGodFrequency;
    int sumOf(List<TenGod> keys) => keys.fold(0, (a, k) => a + (gFreq[k] ?? 0));
    final wealth = sumOf([TenGod.pyeonjae, TenGod.jeongjae]);
    final officer = sumOf([TenGod.pyeongwan, TenGod.jeonggwan]);
    final scholar = sumOf([TenGod.pyeonin, TenGod.jeongin]);
    final express = sumOf([TenGod.siksin, TenGod.sanggwan]);
    final peer = sumOf([TenGod.bigyeon, TenGod.geopjae]);

    final myJi = saju.dayPillar.jiJi;
    // 일지 vs 午 (병오년 본기 지지) — _AnnualSummary._yearBranchRelationToWu 와
    // 동일 매핑 (별 widget class 라 재선언).
    String branchRel;
    if (myJi == '午') {
      branchRel = 'sameWu';
    } else if (myJi == '子') {
      branchRel = 'clash';
    } else if (myJi == '未') {
      branchRel = 'hap6';
    } else if (myJi == '寅' || myJi == '戌') {
      branchRel = 'samhap';
    } else {
      branchRel = 'neutral';
    }

    final gShort = ctx.gyeokgukShort.isEmpty
        ? (useKo ? '비전형 격국' : 'unconventional')
        : ctx.gyeokgukShort;

    final yong = el(ctx.yongsin);
    final hui = el(ctx.huisin);

    final fireOverload = ctx.fire >= 30;
    final gisinIsFire = ctx.gisin == '火';
    final yongIsFire = ctx.yongsin == '火';

    final themeText = useKo ? theme.themeKo : theme.themeEn;
    final hasYeokma = ctx.activeShinsa.contains('역마');
    final hasGoegang = ctx.activeShinsa.contains('괴강');
    final hasYangin = ctx.activeShinsa.contains('양인');

    if (useKo) {
      (String, String) area(String label, String body) =>
          (label, NaturalProseJoiner.polish(body));

      final careerAnchor = officer >= 2
          ? '본인 사주에서 관성(편관·정관)이 두텁게 자리해서, 공식 라인·승진·자격 쪽 결정이 유리하게 작동하기 쉬워요.'
          : scholar >= 2
          ? '인성(편인·정인)이 강해서, 학습·자격·전문가 트랙에 공들이기 좋은 자리예요.'
          : express >= 2
          ? '식상(식신·상관)이 살아 있어서, 표현·창작·강연·콘텐츠 쪽이 본업의 자원이 되기 좋아요.'
          : '본업은 $gShort 결을 그대로 따라가는 게 한 해 동안 가장 잘 맞아요.';

      final wealthAnchor = wealth >= 3
          ? '재성이 두텁게 자리한 사주라, 큰 흐름 한 번에 자산 그림이 바뀔 자리가 열리기 쉬워요.'
          : wealth >= 1
          ? '재성이 한 자리 있어서, 한 해에 한 번쯤 큰 결정 자리가 떠오르기 쉬워요.'
          : '재성이 거의 없는 사주라, 한 해의 돈 흐름은 정재(고정 수입)보다 인연·기회 쪽 우회 경로로 들어오기 쉬워요.';
      final wealthYong = yongIsFire
          ? '용신이 火 — 병오년 火 기운이 용신과 같은 결이라 큰 결정을 꺼내보기 좋아요.'
          : '용신 $yong을 가까이 두면 돈 흐름이 한 박자 안정되기 쉬워요.';

      String loveAnchor;
      switch (branchRel) {
        case 'sameWu':
          loveAnchor = '본인 일지(午)가 병오년 지지와 그대로 겹쳐서(복음), 인연이 본인 자리 가까이로 들어오기 쉬운 결이에요.';
          break;
        case 'clash':
          loveAnchor = '본인 일지(子)와 병오년(午)이 충(子午 충)이라, 인연을 재편할 자리가 한 번 떠오르기 쉬워요.';
          break;
        case 'hap6':
          loveAnchor = '본인 일지(未)와 병오년(午)이 육합으로 묶여서, 파트너와의 결속에 공들이면 한 해 동안 더 단단해지기 좋은 결이에요.';
          break;
        case 'samhap':
          loveAnchor = '본인 일지($myJi)가 병오년(午)과 寅午戌 삼합으로 묶여서, 무대형 만남 자리에서 인연이 열리기 쉬워요.';
          break;
        default:
          loveAnchor = '본인 일지($myJi)와 병오년(午)이 직접 합·충 없이 안정적인 거리감을 유지하는 결이에요.';
      }

      final healthAnchor = fireOverload && gisinIsFire
          ? '본인 사주가 이미 火가 강한데 기신도 火 — 병오년 화기는 직접 부담이 큰 영역이에요.'
          : fireOverload
          ? '본인 사주가 火 비중이 높아서 한 해 화기에 더해지면 과열되기 쉬워요.'
          : gisinIsFire
          ? '기신이 火 — 병오년 한 해는 의식적인 수분·휴식이 필수.'
          : yongIsFire
          ? '용신이 火 — 병오년 화기는 오히려 회복의 자원이에요.'
          : '본인 사주 화 균형이 무난해서 평소 페이스를 지키면 무리 없는 한 해예요.';

      final familyAnchor = peer >= 3
          ? '비견·겁재가 두텁게 자리해서 형제·또래·동료와의 거리감이 한 해의 큰 흐름이에요.'
          : peer >= 1
          ? '비견·겁재가 한 자리 있어서 가족·또래 자리에서 한 번 정리 흐름이 와요.'
          : '비견·겁재가 거의 없는 사주라 가족·또래보다 한 박자 떨어진 자리에서 한 해를 보내요.';

      final studyAnchor = scholar >= 3
          ? '인성(편인·정인)이 두텁게 자리해서 학습·자격·전문가 트랙이 한 해의 큰 자원이에요.'
          : scholar >= 1
          ? '인성이 한 자리 있어서 짧은 코스·자격증 한 개가 한 해의 키예요.'
          : '인성이 거의 없는 사주라 학습은 폭주력보다 정밀도 — 짧고 굵게.';

      final friendsAnchor = peer >= 3
          ? '동료·또래 자리에서 한 해의 흐름이 가장 많이 일어나요.'
          : '오랜 친구와의 거리감이 봄에 한 번 정리되고, 새 인연은 여름 무대에서 들어와요.';

      String travelAnchor;
      switch (branchRel) {
        case 'clash':
          travelAnchor =
              '일지 子 vs 병오년 午 충이라 이동·환경 변화가 평소보다 자주 일어나요 — 봄·여름 단거리 위주, 가을엔 의미 있는 장거리.';
          break;
        case 'samhap':
          travelAnchor =
              '일지 $myJi 와 병오년 午가 삼합으로 묶여서, 여름 이동·출장 자리에서 큰 인연이 들어오기 좋아요.';
          break;
        case 'hap6':
          travelAnchor = '일지 未 vs 午 육합 — 동행 이동이 한 해의 결을 만들어요.';
          break;
        case 'sameWu':
          travelAnchor = '일지 午 복음 — 익숙한 공간에서 한 해 흐름이 정해져요. 멀리 안 가도 좋은 한 해.';
          break;
        default:
          travelAnchor = '본인 일지($myJi)는 병오년 午와 직접 관계가 약해서, 이동은 본인 호흡대로 자유롭게.';
      }

      final growthAnchor = express >= 3
          ? '식상이 두텁게 자리해서 표현·창작·콘텐츠가 한 해 자원의 본류예요.'
          : express >= 1
          ? '식상이 한 자리 있어서 한 가지 외부 활동을 꾸준히 끌고 가면 큰 결과로 돌아와요.'
          : '식상이 거의 없는 사주라 표현보다 내실 — 본인 본업 안에서 한 단계 깊어지는 한 해예요.';

      final legalAnchor = officer >= 2
          ? '관성이 두텁게 자리해서 공식 서류·계약 자리가 한 해의 큰 흐름이에요.'
          : '관성이 약한 사주라 큰 서류·계약은 한 박자 미루는 게 안전해요.';

      final spiritAnchor = scholar >= 2
          ? '인성이 살아 있어서 명상·기도·차분한 시간이 자연스러운 보약이에요.'
          : '평소 안 쪽 시간을 두지 않는 결의 사주 — 6-7월에 의식적인 침묵의 일주일 한 번이 큰 보약.';

      return [
        area(
          'CAREER · 仕事',
          '$gShort 본격 위에서 한 해가 움직여요. $careerAnchor 병오년 화기 정점인 5-7월은 노출이 커지는 만큼 갈등도 같이 올 수 있으니 조심.',
        ),
        area(
          'WEALTH · 財',
          '$wealthAnchor $wealthYong ${_wealthShapeLineKo(ctx)}',
        ),
        area('LOVE · 緣', '$loveAnchor 깊이는 가을(9-10월) 이후에 자리잡기 쉽고, 봄·여름엔 가볍게 가는 게 잘 맞아요.'),
        area(
          'HEALTH · 養生',
          '$healthAnchor 심장·혈압·눈 영역 6-7월 의식적 휴식. 용신 $yong / 희신 $hui을 가까이.',
        ),
        area('FAMILY · 家', '$familyAnchor 명절·생일을 의식적으로 챙기면 자연스럽게 흐릅니다.'),
        area('STUDY · 學', '$studyAnchor 5월·11월은 시험·자격 시도에 무게를 두기 좋은 자리예요.'),
        area(
          'FRIENDS · 友',
          '$friendsAnchor${hasYeokma ? ' 역마 활성 — 한 해 동안 새 만남이 평소보다 자주 와요.' : ''}',
        ),
        area('TRAVEL · 行', '$travelAnchor 11월 이후 장기 이동은 보류가 좋아요.'),
        area(
          'GROWTH · 進',
          '$growthAnchor 병오년 본기는 "$themeText" — 이 결과 본인 식상이 만나는 자리에서 결과가 나오기 쉬워요.',
        ),
        area(
          'LEGAL · 訟',
          '$legalAnchor 5-7월 화기 항진기 피하기, 봄(2-4월)·가을 후반(10-11월)이 안정.${hasGoegang || hasYangin ? ' 괴강·양인 활성 — 강한 결정 자리에서 한 번 더 검토.' : ''}',
        ),
        area(
          'SPIRIT · 心',
          '$spiritAnchor 용신 $yong / 희신 $hui을 가까이 두는 시간이 한 해의 회복력을 만들어요.',
        ),
        area(
          'LEGACY · 名',
          '$gShort 본격의 본질이 한 해의 결과물로 남기 쉬워요. 연말 정산기에 한 해를 한 줄로 적으면, 그 한 줄이 2027년의 첫 결정을 여는 실마리가 됩니다.',
        ),
      ];
    } else {
      final careerAnchor = officer >= 2
          ? 'Officer stars (gwan) are strong — formal lines, promotions, and credentials tend to work in your favor.'
          : scholar >= 2
          ? 'Scholar stars (in) are strong — learning, certification, and expert tracks are good places to lean.'
          : express >= 2
          ? 'Output stars (sik/sang) are strong — expression, writing, and content tend to become your resource.'
          : 'Your $gShort structure sets the year\'s baseline.';
      final wealthAnchor = wealth >= 3
          ? 'Wealth stars are dense — one big flow can reshape your asset picture.'
          : wealth >= 1
          ? 'Wealth stars present — a decisive money window tends to surface once in the year.'
          : 'No wealth star — money tends to arrive through people and opportunity rather than fixed income.';
      String loveAnchor;
      switch (branchRel) {
        case 'sameWu':
          loveAnchor =
              'Day branch 午 matches the year — connections tend to arrive close to your seat.';
          break;
        case 'clash':
          loveAnchor =
              'Day branch 子 clashes with 午 — a round of relational reshuffle tends to surface.';
          break;
        case 'hap6':
          loveAnchor =
              'Day branch 未 six-harmonies with 午 — partnership bonds tend to tighten when you tend them.';
          break;
        case 'samhap':
          loveAnchor =
              'Day branch $myJi joins the 寅午戌 fire triad — stage-style encounters tend to open up.';
          break;
        default:
          loveAnchor = 'Day branch $myJi keeps a steady distance from 午.';
      }
      final healthAnchor = fireOverload && gisinIsFire
          ? 'Your day master already runs hot and gisin is Fire — the year\'s fire tends to land heavy.'
          : fireOverload
          ? 'High fire baseline — pace yourself when the year piles more on.'
          : gisinIsFire
          ? 'Gisin is Fire — make hydration and rest a firm habit this year.'
          : yongIsFire
          ? 'Yongsin is Fire — the year\'s fire tends to read as restorative for you.'
          : 'Fire balance reads steady — keeping your usual pace tends to be enough.';
      final familyAnchor = peer >= 3
          ? 'Peer stars are dense — siblings, peers, and team dynamics tend to drive much of the year.'
          : peer >= 1
          ? 'One peer star — a round of family/peer reshuffle tends to surface.'
          : 'Peer stars are scarce — you tend to observe family from a step back.';
      final studyAnchor = scholar >= 3
          ? 'Scholar stars are dense — study and certification are your big resource.'
          : scholar >= 1
          ? 'One scholar star — a single short course unlocks the year.'
          : 'No scholar star — precision over volume; short and sharp.';
      final friendsAnchor = peer >= 3
          ? 'Peer/sibling axis drives the year\'s social flow.'
          : 'Old ties get sorted in spring; new ones arrive on the summer stage.';
      String travelAnchor;
      switch (branchRel) {
        case 'clash':
          travelAnchor =
              'Day branch 子 vs year 午 clash — movement comes often; long-haul saved for autumn.';
          break;
        case 'samhap':
          travelAnchor =
              'Day branch $myJi joins 寅午戌 with 午 — summer trips tend to bring big introductions.';
          break;
        case 'hap6':
          travelAnchor =
              'Day branch 未 + 午 six-harmony — travel with partners shapes the year.';
          break;
        case 'sameWu':
          travelAnchor =
              'Day branch 午 doubled — familiar ground defines the year. Stay close.';
          break;
        default:
          travelAnchor =
              'Day branch $myJi keeps a free distance from 午 — travel on your own rhythm.';
      }
      final growthAnchor = express >= 3
          ? 'Output stars are dense — creation and expression are your main current.'
          : express >= 1
          ? 'One output star — sustained outward activity returns big.'
          : 'No output star — depth over breadth; deepen your craft.';
      final legalAnchor = officer >= 2
          ? 'Officer stars strong — formal documents and contracts matter this year.'
          : 'Officer stars weak — defer large contracts when possible.';
      final spiritAnchor = scholar >= 2
          ? 'Scholar stars present — meditation and quiet come naturally.'
          : 'Inward time does not arrive by itself — schedule a deliberate silent week in June/July.';

      return [
        (
          'CAREER',
          '$gShort structure sets the year. $careerAnchor Watch conflict during the fire peak May–July.',
        ),
        (
          'WEALTH',
          '$wealthAnchor ${yongIsFire ? 'Yongsin Fire — the year directly nourishes you, ideal for big calls.' : 'Keep yongsin $yong close to steady the flow.'} ${_wealthShapeLineEn(ctx)}',
        ),
        (
          'LOVE',
          '$loveAnchor Depth tends to settle in after September; spring and summer reward lightness.',
        ),
        (
          'HEALTH',
          '$healthAnchor Heart, blood pressure, eyes — rest deliberately in June–July. Yongsin $yong / huisin $hui close.',
        ),
        (
          'FAMILY',
          '$familyAnchor Show up for birthdays and holidays — the rest flows by itself.',
        ),
        ('STUDY', '$studyAnchor May and November tend to be good windows to aim exams at.'),
        (
          'FRIENDS',
          '$friendsAnchor${hasYeokma ? ' Yeokma active — new encounters arrive more often.' : ''}',
        ),
        ('TRAVEL', '$travelAnchor Defer long-haul plans after November.'),
        (
          'GROWTH',
          '$growthAnchor The year\'s engine — "$themeText" — meets your output stars there.',
        ),
        (
          'LEGAL',
          '$legalAnchor Avoid contracts during fire-peak May–July; spring (Feb–Apr) and late autumn most stable.${hasGoegang || hasYangin ? ' Goegang/Yangin active — double-check strong decisions.' : ''}',
        ),
        (
          'SPIRIT',
          '$spiritAnchor Keep yongsin $yong and huisin $hui close to rebuild.',
        ),
        (
          'LEGACY',
          "Your $gShort structure leaves the year's mark. Write the year in one line at the end — that line shapes the first decision of 2027.",
        ),
      ];
    }
  }

  /// R107 #6 — WEALTH area 한 줄을 사용자 재성(정재·편재) 구조로 분기.
  /// 기존 "정재보다 편재 성격의 한 해" 고정 삽입 제거. v5 voice (발동 조건형).
  String _wealthShapeLineKo(SajuContext ctx) {
    switch (_AnnualSummary.wealthShape(ctx)) {
      case 'jeong':
        return '재성 중 정재(고정 수입) 쪽이 두터운 결 — 매달 쌓이는 흐름을 챙길 때 더 안정되기 쉬워요.';
      case 'pyeon':
        return '재성 중 편재(기회·투자) 쪽이 두터운 결 — 1-3월 정보 수집, 4-5월 결정 모드를 미리 챙겨두면 좋아요.';
      case 'balanced':
        return '정재(고정)와 편재(기회)가 비슷한 무게 — 안정 루틴 하나와 기회 대비 하나를 같이 챙겨두면 좋아요.';
      case 'light':
        return '재성이 한 자리 — 한두 번의 또렷한 결정 자리를 신중하게 다루는 게 한 해의 키예요.';
      default: // none
        return '재성이 약한 결 — 돈 흐름은 인연·기회 쪽 우회 경로로 들어오기 쉬워요.';
    }
  }

  /// R107 #6 — WEALTH area 영어 한 줄 (재성 구조 분기).
  String _wealthShapeLineEn(SajuContext ctx) {
    switch (_AnnualSummary.wealthShape(ctx)) {
      case 'jeong':
        return 'Wealth leans to jeongjae (steady income) — tending a recurring rhythm tends to keep it stable.';
      case 'pyeon':
        return 'Wealth leans to pyeonjae (opportunity) — collect info Jan–Mar, decide Apr–May.';
      case 'balanced':
        return 'Jeongjae and pyeonjae sit at similar weight — keep both a steady routine and a readiness for the window.';
      case 'light':
        return 'A single wealth star — handling one or two clear decision points with care is the year\'s key.';
      default: // none
        return 'Wealth stars are scarce — the flow tends to arrive through people and opportunity.';
    }
  }
}

class _Counsel extends StatelessWidget {
  final bool useKo;
  const _Counsel({required this.useKo});

  @override
  Widget build(BuildContext context) {
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
            useKo ? "MASTER'S  COUNSEL · 訓" : "MASTER'S  COUNSEL · 訓",
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            useKo
                ? '"빛이 강한 해는 그림자도 함께 자랍니다."'
                : '"In a year of strong light, the shadow grows alongside."',
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 19,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    height: 1.5,
                    letterSpacing: 0.3,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: AppColors.accent,
                    height: 1.5,
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            useKo
                ? '병오년은 추진과 가시성이 강하게 도는 해예요. 명리학에서 화(火)가 한 해의 본기일 때 가장 중요한 결단은 ‘속도 줄이기’예요. 5월·6월·7월 어딘가에 의식적인 휴식을 한 번 두세요 — 그 한 박자가 가을의 결실을 좌우하기 쉬워요.'
                : 'The Year of Bing Wu rewards thrust and visibility. Yet when fire is the year\'s engine, the most expensive decision is to slow down. Place a deliberate rest somewhere in May, June, or July. That single pause tends to shape what autumn harvests.',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Text(
        '입춘 2026.02.04 · KASI 절기력',
        style: GoogleFonts.inter(
          fontSize: 9,
          letterSpacing: 3,
          fontWeight: FontWeight.w400,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}
