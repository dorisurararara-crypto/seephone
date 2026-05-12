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
import '../../services/jol_calendar_2026.dart';
import '../../services/seun_service.dart';
import '../../services/strength_service.dart';
import '../../services/yongsin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

/// 2026 신년운세 screen — 사주 원국과 병오년 세운을 매칭하여 1년 운기 풀이.
class NewYear2026Screen extends ConsumerWidget {
  const NewYear2026Screen({super.key});

  static const int year = 2026;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saju = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
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
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
    );
    final yongsin = YongsinService.judge(
      dayMasterElement: saju.dayPillar.chunGanElement,
      strengthLabel: strength.label,
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/reports'),
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
            _MonthlyFlow(
              saju: saju,
              year: year,
              useKo: useKo,
            ),
            _TwelveAreas(theme: theme, saju: saju, useKo: useKo),
            _Counsel(useKo: useKo),
            _Footer(),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
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
                ? '병오(丙午)는 한낮의 태양이 말처럼 달리는 해. 2026년은 자유로움, 추진력, 그리고 주목 받는 한 해입니다. 다만 화기(火氣)가 강한 만큼 절제와 호흡 조절이 풍요를 결정합니다.'
                : 'Bing Wu (丙午) — midday sun riding a horse. 2026 favors freedom, forward thrust, and the spotlight. Yet the fire is intense; pacing and breath decide what the year leaves you.',
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
            ? '용신이 ${elKo(yongsin)} — 병오년이 당신을 직접 살려주는 해입니다. 큰 결정에 적합.'
            : '용신은 ${elKo(yongsin)}. 병오년 화기에 휘둘리지 않도록 ${elKo(yongsin)}을 의식적으로 보충하세요.')
        : (yongIn2026
            ? 'Your yongsin is $yongsin — 2026 directly nourishes your chart. A year for the big decisions.'
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
            themeText.isEmpty ? (useKo ? '비화 — 동등한 결' : 'Peer — equal grain') : themeText,
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
    '백로 — 이슬이 맺히는 달. 약속과 계약을 글로 남기세요.',
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

  @override
  Widget build(BuildContext context) {
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
                              useKo ? _moodsKo[i] : _moodsEn[i],
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
    final areas = useKo
        ? const [
            ('CAREER · 仕事',
                '병오년은 주목 받는 해. 실력보다 가시성이 먼저 보상됩니다. 화기 강한 5-7월은 갈등 조심.'),
            ('WEALTH · 財',
                '큰 흐름의 돈이 한 번은 지나갑니다. 정재(고정 수입)보다 편재(기회·투자) 성격.'),
            ('LOVE · 緣',
                '인연이 빠르게 시작·끝납니다. 깊이는 가을(9-10월) 이후. 봄·여름엔 가벼움이 정답.'),
            ('HEALTH · 養生',
                '심장·혈압·눈 — 화기 항진 영역. 6-7월 휴식 의식적. 수분·운동·수면의 균형이 핵심.'),
            ('FAMILY · 家',
                '가족과의 거리감이 새로 정해지는 해. 명절·생일을 의식적으로 챙기면 자연스럽게 흐릅니다.'),
            ('STUDY · 學',
                '학습은 폭주력보다 정밀도. 짧은 코스가 마라톤보다 답. 5월·11월 시험·자격 시도 좋음.'),
            ('FRIENDS · 友',
                '오랜 친구와의 거리감이 봄에 한 번 정리됩니다. 새 인연은 여름 무대에서. 가을엔 자연 정리.'),
            ('TRAVEL · 行',
                '봄·여름은 짧고 자주, 가을은 길고 의미 있게. 11월 이후 장기 이동은 보류가 좋아요.'),
            ('GROWTH · 進',
                '병오년 본기는 표현·창작. 글쓰기·강의·SNS 등 외부로 나가는 활동이 자원이 됩니다.'),
            ('LEGAL · 訟',
                '계약·서류 5-7월 화기 항진기 피하기. 봄(2-4월), 가을 후반(10-11월)이 가장 안정.'),
            ('SPIRIT · 心',
                '명상·기도·차분한 시간이 가장 큰 보약. 6-7월 의식적 침묵의 일주일을 한 번 꼭 두세요.'),
            ('LEGACY · 名',
                '연말 정산기에 한 해를 한 줄로 적으세요. 그 한 줄이 2027년의 첫 결정을 만듭니다.'),
          ]
        : const [
            ('CAREER',
                'A year of visibility. Attention is rewarded before effort. Mind conflict in May–July.'),
            ('WEALTH',
                'One large flow of money will pass through. Lean into windfall opportunities over fixed income.'),
            ('LOVE',
                'Connections start and end quickly. Depth arrives after September. Spring and summer reward lightness.'),
            ('HEALTH',
                'Heart, blood pressure, eyes — fire-overheat zones. Rest deliberately in June–July. Hydration, exercise, sleep.'),
            ('FAMILY',
                'A year that resets distances. Show up for birthdays and holidays — the rest flows by itself.'),
            ('STUDY',
                'Precision over volume. Short courses yes; marathons no. May and November are auspicious for exams.'),
            ('FRIENDS',
                'Old ties get sorted in spring. New connections arrive on the summer stage. Autumn does the natural pruning.'),
            ('TRAVEL',
                'Short and frequent in spring/summer; long and meaningful in autumn. Defer long-haul plans after November.'),
            ('GROWTH',
                'The year favors expression and creation. Writing, speaking, and external presence become your resource.'),
            ('LEGAL',
                'Avoid contracts during fire-peak May–July. Spring (Feb–Apr) and late autumn (Oct–Nov) are most stable.'),
            ('SPIRIT',
                'Meditation and quiet are the most expensive medicine. Place one silent week in June or July.'),
            ('LEGACY',
                "Write the year down in one line at the end. That single line will shape the first decision of 2027."),
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
                ? '병오년은 추진과 가시성의 해입니다. 명리학에서 화(火)가 한 해의 본기일 때 가장 중요한 결단은 ‘속도 줄이기’입니다. 5월·6월·7월 어딘가에 의식적인 휴식을 한 번 두세요. 그것이 가을의 결실을 좌우합니다.'
                : 'The Year of Bing Wu rewards thrust and visibility. Yet when fire is the year\'s engine, the most expensive decision is to slow down. Place a deliberate rest somewhere in May, June, or July. That single pause decides what autumn harvests.',
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
      decoration: const BoxDecoration(
        color: AppColors.bg,
      ),
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
