// Pillar Seer — 2026 신년운세 (병오년).
//
// 사주 원국 + 2026 세운 → 12달 흐름 + 12 영역 풀이.
// 정통 명리학: yearGanji (丙午) + 일간 기준 십신 매핑 + 월별 60갑자 조합.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          useKo ? 'NEW  YEAR  2026' : 'NEW  YEAR  2026',
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
                  style: GoogleFonts.cormorantGaramond(
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
                ? '병오(丙午)는 한낮의 태양이 말처럼 달리는 결. 2026년은 자유, 추진력, 무대 위의 해입니다. 다만 화기(火氣)가 강한 만큼, 절제와 호흡 조절이 풍요를 결정합니다.'
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
            style: GoogleFonts.cormorantGaramond(
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

  /// 절기 기준 월건 (간단형: solar month → 月支 매핑).
  static const _monthBranches = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];

  /// 월건 천간 — 년간 (병) 기준 五虎遁: 丙年 → 정월 庚寅.
  /// 丙·辛 년 → 庚寅 시작. 월간은 子月에 戊가 되는 순서.
  /// 간단 매핑 (월별): 寅=庚, 卯=辛, 辰=壬, 巳=癸, 午=甲, 未=乙, 申=丙, 酉=丁, 戌=戊, 亥=己, 子=庚, 丑=辛.
  static const _monthStems = ['庚', '辛', '壬', '癸', '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛'];

  static const _monthMoods = [
    ('JAN · 입춘', '겨울이 풀리는 신호. 새 그림을 그리되 서두르지 마세요.', 'Spring stirs. Sketch the new plan, but do not sprint.'),
    ('FEB · 경칩', '바람이 시작합니다. 사람과 인연이 다시 움직여요.', 'Wind picks up; old contacts re-emerge.'),
    ('MAR · 청명', '본격 봄. 기획은 가볍게, 실행은 두텁게.', 'Spring proper. Plan light, execute thick.'),
    ('APR · 입하', '뜨거워지기 직전 — 가장 비싼 결정을 내릴 시기.', 'Heat just before peak — most expensive decisions land well.'),
    ('MAY · 망종', '병오년 본기 가동. 무대·표현·이름이 커지는 달.', 'The year’s engine roars. Stage and reputation grow.'),
    ('JUN · 하지', '극지의 정점. 빛이 강한 만큼 그림자도 — 휴식 의식적.', 'Solar zenith. Where light is strong, intentionally rest.'),
    ('JUL · 입추', '가을 첫 신호. 수확을 의식하고 마무리 모드.', 'Autumn’s first signal. Switch to harvest mode.'),
    ('AUG · 백로', '결실의 달. 약속을 글로 남기세요.', 'The fruiting month. Put promises in writing.'),
    ('SEP · 한로', '냉기 진입. 정리·다이어트·재정 점검.', 'Coolness begins. Clear, lighten, audit finances.'),
    ('OCT · 입동', '겨울 입구. 사람을 가깝게, 계획을 깊게.', 'Winter\'s gate. Keep people close, plans deeper.'),
    ('NOV · 대설', '저장의 달. 자랑보다 축적.', 'The storing month. Accumulate, do not display.'),
    ('DEC · 동지', '한 해의 정산. 다음 해의 씨앗을 봉인.', 'Year-end reckoning. Seal the seeds of next year.'),
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
          const SizedBox(height: 22),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              children: List.generate(12, (i) {
                final ganji = '${_monthStems[i]}${_monthBranches[i]}';
                final mood = _monthMoods[i];
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
                              mood.$1,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w500,
                                color: AppColors.taupe,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              useKo ? mood.$2 : mood.$3,
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
                '병오년은 무대의 해. 실력보다 가시성이 보상되는 한 해. 단, 화기 강한 달(5·6월)은 갈등 조심.'),
            ('WEALTH · 財',
                '큰 흐름의 돈이 한 번은 지나갑니다. 정재(고정 수입)보다 편재(기회·투자)의 결.'),
            ('LOVE · 緣',
                '인연이 빠르게 시작·끝납니다. 깊이는 가을(9-10월) 진입 후에. 봄·여름엔 가벼움이 정답.'),
            ('HEALTH · 養生',
                '심장·혈압·눈 — 화기 항진 영역. 6월·7월 휴식 의식적. 수분·운동·수면의 균형.'),
            ('FAMILY · 家',
                '가족과의 거리감이 새로 정해지는 해. 명절·생일을 의식적으로 챙기면 그대로 잘 흘러갑니다.'),
            ('STUDY · 學',
                '학습은 폭주력보다 정밀도. 짧은 코스 ✓, 마라톤 X. 5월·11월 시험·자격 시도 좋음.'),
          ]
        : const [
            ('CAREER',
                'A year of the stage. Visibility is rewarded more than effort. Mind conflict in May–June.'),
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
            style: GoogleFonts.cormorantGaramond(
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
                ? '병오년은 추진과 가시성의 해입니다. 다만 명리학에서 화(火)가 한 해의 본기일 때 가장 비싼 결단은 ‘속도 줄이기’입니다. 5월·6월·7월 어딘가에 의식적인 휴식을 한 번 두세요. 그것이 가을의 결실을 결정합니다.'
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
