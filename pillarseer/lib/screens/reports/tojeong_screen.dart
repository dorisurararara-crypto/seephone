// Pillar Seer — Tojeong-bigyeol (土亭祕訣) Report.
import 'package:go_router/go_router.dart';
// 사용자 생년월일 → 144 hexagram 중 1개 매핑 + 월별 흐름.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saju_result.dart';
import '../../providers/locale_provider.dart';
import '../../providers/saju_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class TojeongScreen extends ConsumerWidget {
  const TojeongScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final saju = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final birth = ref.watch(userBirthInfoProvider);
    final localeOverride = ref.watch(localeProvider);
    final systemLocale = Localizations.maybeLocaleOf(context);
    final useKo = (localeOverride?.languageCode ??
            systemLocale?.languageCode ??
            'en') ==
        'ko';
    final hex = _hexagramFor(saju, birth);
    final year = DateTime.now().year;
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
          useKo ? '토정비결 · 土 亭' : 'TOJEONG · 土 亭',
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
            _Section(
              background: AppColors.bg,
              meta: '$year · ${l.tojeongSubtitle}'.toUpperCase(),
              child: _HexagramHero(hex: hex, useKo: useKo),
            ),
            _Section(
              background: AppColors.paper,
              meta: l.tojeongYearOverview,
              child: Text(
                useKo ? hex.yearOverviewKo : hex.yearOverviewEn,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.ink,
                  height: 1.85,
                ),
              ),
            ),
            _Section(
              background: AppColors.bg,
              meta: l.tojeongMonthlyHeader,
              child: _MonthlyList(
                texts: _monthlyTexts(hex, useKo),
                useKo: useKo,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  List<String> _monthlyTexts(Hexagram hex, bool useKo) {
    return useKo ? hex.monthlyKo : hex.monthlyEn;
  }

  /// 1-144 hexagram 결정 (간단 매핑: 생년월일 → seed).
  Hexagram _hexagramFor(SajuResult saju, UserBirthInfo? birth) {
    final d = birth?.birthDate ?? DateTime(1990);
    final seed = (d.year + d.month * 11 + d.day * 31 +
            saju.day60ji.codeUnits.fold<int>(0, (a, b) => a + b)) %
        144;
    return _hexagramData[seed];
  }
}

class _Section extends StatelessWidget {
  final Color background;
  final String meta;
  final Widget child;
  const _Section({
    required this.background,
    required this.meta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: background,
        border: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meta,
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _HexagramHero extends StatelessWidget {
  final Hexagram hex;
  final bool useKo;
  const _HexagramHero({required this.hex, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No. ${hex.number.toString().padLeft(3, '0')} / 144',
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              hex.symbol,
              style: GoogleFonts.notoSerifKr(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: AppColors.accent,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                useKo ? hex.nameKo : hex.nameEn,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          useKo ? hex.taglineKo : hex.taglineEn,
          style: useKo
              ? GoogleFonts.notoSerifKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent,
                  height: 1.6,
                  letterSpacing: 0.3,
                )
              : GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: AppColors.accent,
                  height: 1.6,
                ),
        ),
      ],
    );
  }
}

class _MonthlyList extends StatelessWidget {
  final List<String> texts;
  final bool useKo;
  const _MonthlyList({required this.texts, required this.useKo});

  static const _monthsEn = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  static const _monthsKo = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: texts.asMap().entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.line, width: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    useKo ? _monthsKo[e.key] : _monthsEn[e.key],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class Hexagram {
  final int number;
  final String symbol;
  final String nameEn;
  final String nameKo;
  final String taglineEn;
  final String taglineKo;
  final String yearOverviewEn;
  final String yearOverviewKo;
  final List<String> monthlyEn;
  final List<String> monthlyKo;

  const Hexagram({
    required this.number,
    required this.symbol,
    required this.nameEn,
    required this.nameKo,
    required this.taglineEn,
    required this.taglineKo,
    required this.yearOverviewEn,
    required this.yearOverviewKo,
    required this.monthlyEn,
    required this.monthlyKo,
  });
}

/// 144 hexagram — 8 archetype × 18 사이클. 간단 procedural 생성.
final List<Hexagram> _hexagramData = List.generate(144, (i) {
  const archetypes = [
    ['乾', 'Heaven Rises', '하늘이 열린다', 'Authority returns to your hand.', '권위가 손에 돌아옵니다.'],
    ['坤', 'Earth Holds', '대지가 품는다', 'Patience cultivates harvest.', '인내가 수확을 키웁니다.'],
    ['震', 'Thunder Wakes', '벼락이 깬다', 'A startling event clarifies direction.', '예상 밖 사건이 방향을 정리합니다.'],
    ['巽', 'Wind Drifts', '바람이 머문다', 'Subtle influence shapes momentum.', '미세한 영향이 흐름을 만듭니다.'],
    ['坎', 'Water Deepens', '물이 깊어진다', 'A test of nerve precedes flow.', '담력의 시험이 흐름보다 먼저 옵니다.'],
    ['離', 'Fire Reveals', '불이 드러낸다', 'Visibility brings a tested choice.', '드러남이 시험된 선택을 부릅니다.'],
    ['艮', 'Mountain Holds', '산이 멈춘다', 'Stillness saves more than action.', '멈춤이 행동보다 더 많은 것을 살립니다.'],
    ['兌', 'Lake Speaks', '호수가 말한다', 'Communication unlocks a closed door.', '대화가 닫힌 문을 엽니다.'],
  ];
  final arch = archetypes[i % 8];
  final cycle = (i ~/ 8) + 1;
  final archIdx = i % 8;
  // 8 archetype 별 yearOverview 변형 (codex Round 30 권고 — 144 동일 템플릿 X).
  const yearOverviewKoByArch = [
    // 0 乾 Heaven — 권위
    '의 흐름으로 권위가 손에 돌아옵니다. 윗선과 정면으로 만나는 달이 한 해를 정합니다. 자필 한 줄이 가장 큰 무게를 가지고, 받지 않은 책임을 받게 됩니다.',
    // 1 坤 Earth — 인내
    '의 흐름으로 인내가 수확이 됩니다. 빠른 길은 결국 짧은 가지로 끝나고, 매일의 작은 루틴이 가장 큰 차이를 만듭니다. 봄에 심은 것이 가을에 보입니다.',
    // 2 震 Thunder — 충격
    '의 흐름으로 예상 밖 사건이 한 해를 다시 그립니다. 한 번의 결정이 4년의 방향을 바꿉니다. 충격을 피하지 말고 글로 받아 적으세요.',
    // 3 巽 Wind — 영향
    '의 흐름으로 미세한 흐름이 큰 결과를 만듭니다. 정면이 아닌 곁가지의 추천이 가장 큰 문을 엽니다. 말의 톤을 단계적으로 다듬으세요.',
    // 4 坎 Water — 시험
    '의 흐름으로 담력이 단련됩니다. 시험은 깊지만 짧고, 통과 후 새로운 흐름이 깊은 곳에서 옵니다. 무리하지 말 것.',
    // 5 離 Fire — 드러남
    '의 흐름으로 드러나는 한 해. 빛 아래 어떤 모습을 보일지가 곧 정체성이 됩니다. 옷을 고른 뒤 무대로 가세요.',
    // 6 艮 Mountain — 멈춤
    '의 흐름으로 멈춤이 가장 큰 행동이 됩니다. 한 산을 옮기려면 한 번 더 멈추세요. 결정 보류가 가장 큰 결정.',
    // 7 兌 Lake — 대화
    '의 흐름으로 말이 문을 엽니다. 닫혀 있던 대화를 노크하는 달이 옵니다. 듣는 시간을 말하는 시간보다 두 배 두세요.',
  ];
  const yearOverviewEnByArch = [
    ' opens authority into your hand. Direct meetings with leadership define the year — your signature carries weight; you receive responsibility you did not accept.',
    ' rewards patience as harvest. Fast paths end in short branches. Daily routines make the biggest difference; what you plant in spring appears in autumn.',
    ' redraws the year via an unexpected event. One decision reshapes four years. Do not flee the quake — write it down as grain.',
    ' moves big results through subtle currents. The biggest doors open sideways, not head-on. Tune your tone in stages.',
    ' tempers the nerve. The test runs deep yet short; new currents arrive from depth after the trial. Do not overreach.',
    ' reveals you on a stage. What you show under light becomes identity. Pick your robe before entering.',
    ' makes stillness the biggest action. To move a mountain, pause once more. Holding a decision is the biggest decision.',
    ' opens doors through words. The conversation that was closed knocks again. Listen twice as long as you speak.',
  ];
  final yearOverviewKo =
      '18사이클 중 ${cycle.toString().padLeft(2, '0')} — ${arch[2]}'
      '${yearOverviewKoByArch[archIdx]}';
  final yearOverviewEn =
      'Cycle ${cycle.toString().padLeft(2, '0')} of 18 — ${arch[1]}'
      '${yearOverviewEnByArch[archIdx]}';
  // 8 archetype × 12 month = 96 변형. (각 괘의 결에 맞춘 톤)
  const monthlyByArchetypeKo = [
    // 0 乾 Heaven Rises — 권위·결단
    [
      '권위 회복기 — 작년 미해결을 한 줄씩 처리하세요.',
      '결정권자와의 짧은 만남이 결정적입니다.',
      '주목도 상승 — 메시지를 다듬은 뒤 무대로.',
      '윗선과 정면으로 만나는 달. 직접 말하세요.',
      '명확한 거절이 오히려 권위를 만듭니다.',
      '연중 전환 — 한 권위를 내려놓아야 다른 것이 옵니다.',
      '약속·도장의 달. 자필 한 줄이 무게를 가져요.',
      '인정의 정점 — 다음 사이클을 미리 그리세요.',
      '오랜 멘토와 다시 만나 좌표를 확인.',
      '핵심 거래 마무리 — 미루지 마세요.',
      '회복기 — 휴식이 다음 권위를 만듭니다.',
      '내년의 한 줄을 적고, 연말에 다시 읽어보세요.',
    ],
    // 1 坤 Earth Holds — 인내·축적
    [
      '느린 시작 — 토대를 한 칸씩 다지세요.',
      '겉으로 보이지 않는 축적이 가장 큽니다.',
      '주변의 부드러운 신호가 큰 흐름을 알려요.',
      '큰 결정보다 일상의 루틴이 결과를 가릅니다.',
      '인내가 무르익는 달 — 빠른 길에 휘둘리지 마세요.',
      '중반의 작은 회복이 후반의 큰 결실을 만듭니다.',
      '재정 점검의 달 — 숫자를 직접 보세요.',
      '인정은 조용히 옵니다 — 받는 자세를 연습.',
      '오랜 관계가 깊은 곳에서 다시 흔들립니다.',
      '수확의 창 — 미리 약속된 결실을 마무리.',
      '회복 — 다음 씨앗을 위해 비우는 시기.',
      '내년에 키울 하나를 정해 글로 적으세요.',
    ],
    // 2 震 Thunder Wakes — 충격·전환
    [
      '예상 밖 사건이 한 해의 결을 잡습니다.',
      '숨은 전환이 시작 — 작은 신호도 진지하게.',
      '큰 변화 후 메시지 정리가 핵심.',
      '문이 열리지만 빠르게 닫혀요. 결단하세요.',
      '시험은 짧고 강합니다 — 흔들리지 말 것.',
      '연중 가장 큰 전환점 — 한 선택이 4년을 바꿉니다.',
      '돈 흐름이 한 번 끊겼다가 다시 — 침착.',
      '인정이 큰 파동으로 옵니다 — 균형 잡기.',
      '오랜 인연이 다시 등장해 충격을 정리.',
      '수확은 빠르게 — 미루면 다음 사이클로.',
      '회복기 — 다음 충격에 대비한 쿠션 쌓기.',
      '내년의 폭발을 준비하는 침묵의 달.',
    ],
    // 3 巽 Wind Drifts — 영향·전파
    [
      '미세한 영향이 시작 — 작은 메시지 다듬기.',
      '숨은 추천이 큰 기회로 변합니다.',
      '주목도 상승 — 톤을 조심.',
      '문은 옆에서 열립니다 — 정면이 아닌 곁가지로.',
      '인내가 흐름을 만듭니다 — 빠르게 가지 말 것.',
      '연중 전환 — 한 채널을 줄여 한 채널을 키워요.',
      '협상의 달 — 부드럽게 그러나 분명히.',
      '인정은 우회로로 와요 — 직접 요구하지 말 것.',
      '오랜 인연의 추천이 새 문을 엽니다.',
      '수확 — 흐름을 타고 마무리하세요.',
      '회복 — 결을 다시 가다듬는 시기.',
      '내년의 흐름을 미리 그려보세요.',
    ],
    // 4 坎 Water Deepens — 시험·깊이
    [
      '담력의 시험이 시작 — 첫 달 핵심.',
      '숨은 시험은 더 큽니다 — 흔들리지 말 것.',
      '드러나기 전에 깊이를 더 다지세요.',
      '문이 열리지만 좁고 깊어요. 진심으로.',
      '인내의 시험 — 가장 느린 길이 정답.',
      '연중 전환 — 한 시험을 통과해야 다음 단계로.',
      '돈 흐름의 시험 — 정직이 길게 갑니다.',
      '인정은 의외의 곳에서 — 자만 X.',
      '오랜 시험이 끝나고 새로운 깊이가 옵니다.',
      '수확은 깊이만큼 옵니다 — 무리하지 말 것.',
      '회복 — 다음 시험을 위한 쿠션.',
      '내년의 깊이를 위한 침잠의 달.',
    ],
    // 5 離 Fire Reveals — 드러남·선택
    [
      '드러나는 시작 — 어떤 모습을 보일지 정하세요.',
      '숨은 카드가 드러나는 달 — 미리 준비.',
      '주목도 정점 — 메시지의 톤이 결정적.',
      '문이 환하게 열려요 — 들어가기 전에 옷을 고르세요.',
      '시험된 선택의 달 — 망설이지 말 것.',
      '연중 전환 — 한 빛을 꺼야 다른 빛이 켜집니다.',
      '돈 흐름이 보이는 곳에 — 숫자 점검.',
      '인정의 정점 — 다음 사이클을 미리 그리세요.',
      '오랜 인연이 마지막 무대를 청합니다.',
      '수확 — 보이는 거래를 마무리하세요.',
      '회복 — 빛을 잠시 끄는 시기.',
      '내년의 무대를 미리 디자인하세요.',
    ],
    // 6 艮 Mountain Holds — 멈춤·고요
    [
      '멈춤이 시작 — 작년 정리에 시간을 더 주세요.',
      '숨은 멈춤이 더 큰 도약을 만듭니다.',
      '드러내기 전에 한 박자 더 멈추세요.',
      '문이 열려도 발 한 짝만 들이미세요.',
      '인내의 정점 — 그대로가 정답.',
      '연중 전환 — 한 멈춤이 다음 산을 옮깁니다.',
      '돈 흐름은 멈춰서 보세요 — 결정 보류.',
      '인정은 멈춤 속에 옵니다 — 받는 자세 연습.',
      '오랜 산이 잠깐 흔들렸다가 다시 자리.',
      '수확은 천천히 — 한 번에 다 하지 말 것.',
      '회복 — 다음 산을 위한 가장 깊은 멈춤.',
      '내년의 한 산을 정해 글로 적으세요.',
    ],
    // 7 兌 Lake Speaks — 대화·교류
    [
      '대화의 시작 — 닫혀 있던 문을 노크하세요.',
      '숨은 대화가 큰 기회를 엽니다.',
      '주목도 상승 — 말의 톤이 핵심.',
      '문이 말로 열려요 — 진심을 한 번 더.',
      '인내의 시험은 침묵으로 — 말을 줄이세요.',
      '연중 전환 — 한 대화를 정리해야 다음으로.',
      '돈 흐름은 대화로 — 협상의 달.',
      '인정의 정점 — 받은 말을 글로 남기세요.',
      '오랜 인연이 다시 한 번 대화를 청합니다.',
      '수확 — 약속된 거래를 말로 닫으세요.',
      '회복 — 말을 줄이고 듣는 시기.',
      '내년의 첫 대화를 미리 그려보세요.',
    ],
  ];
  const monthlyByArchetypeEn = [
    // 0 乾 Heaven Rises
    [
      'Authority returns — close last year\'s threads, one line each.',
      'A short meeting with a decision-maker decides the year.',
      'Visibility rises — refine the message, then take the stage.',
      'A direct confrontation with leadership clarifies — speak plainly.',
      'A clear no builds authority better than a soft yes.',
      'Mid-year pivot — releasing one role makes space for another.',
      'Contracts and signatures — your handwriting carries weight.',
      'Peak recognition — sketch the next cycle while standing tall.',
      'A long-time mentor returns to recalibrate your axis.',
      'Close the core deal — do not postpone.',
      'Recovery — rest builds the next throne.',
      'Write one line for next year; reread it at year\'s end.',
    ],
    // 1 坤
    [
      'Slow start — build the base one tile at a time.',
      'The unseen accumulation matters most.',
      'Soft signals around you reveal the big tide.',
      'Daily routines decide outcomes more than big calls.',
      'Patience ripens — do not chase fast lanes.',
      'A small mid-year recovery seeds a large autumn harvest.',
      'Money review — look at the numbers yourself.',
      'Recognition arrives quietly — rehearse receiving.',
      'An old relationship trembles in the deep.',
      'Harvest window — close what was already promised.',
      'Recovery — empty so the next seed can hold.',
      'Pick one thing to grow next year; write it down.',
    ],
    // 2 震
    [
      'An unexpected event sets the year\'s grain.',
      'Hidden shifts begin — take small signals seriously.',
      'After a quake, message hygiene is everything.',
      'A door opens and closes quickly — decide.',
      'The test is short and strong — do not waver.',
      'The biggest pivot of the year — one choice reshapes four years.',
      'Cash flow stops then resumes — stay calm.',
      'Recognition arrives as a wave — keep balance.',
      'An old tie returns to sort the shock.',
      'Harvest fast — delay slides it to the next cycle.',
      'Recovery — build cushion before the next jolt.',
      'A quiet month to prep next year\'s eruption.',
    ],
    // 3 巽
    [
      'Subtle influence begins — polish small messages.',
      'A hidden referral becomes a major opportunity.',
      'Visibility rises — watch the tone.',
      'The door opens sideways, not head-on.',
      'Patience makes the flow — do not rush.',
      'Mid-year pivot — shrink one channel, grow another.',
      'Negotiation month — soft but unambiguous.',
      'Recognition comes by detour — do not demand it.',
      'An old contact\'s referral opens a new door.',
      'Harvest — close while the wind is at your back.',
      'Recovery — re-tune the grain.',
      'Sketch next year\'s current in advance.',
    ],
    // 4 坎
    [
      'A nerve test begins — January is decisive.',
      'The hidden test is larger — do not flinch.',
      'Build depth before you show.',
      'A narrow but deep door opens — enter with sincerity.',
      'Patience test — the slowest path is the right one.',
      'Mid-year pivot — pass one trial to unlock the next.',
      'Cash flow trial — honesty wears longest.',
      'Recognition from an unlikely place — stay humble.',
      'An old test ends, new depth begins.',
      'Harvest scales with depth — do not overreach.',
      'Recovery — cushion for the next trial.',
      'A month of sinking deep for next year.',
    ],
    // 5 離
    [
      'A revealing start — decide which grain to show.',
      'Hidden cards surface — be ready.',
      'Peak visibility — your tone decides everything.',
      'The door opens brightly — pick your robe before entering.',
      'A tested choice month — do not waver.',
      'Mid-year pivot — one light dims for another to lit.',
      'Cash flow becomes visible — check the numbers.',
      'Peak recognition — sketch the next cycle.',
      'An old bond asks for a final stage.',
      'Harvest — close visible deals.',
      'Recovery — briefly dim the flame.',
      'Design next year\'s stage in advance.',
    ],
    // 6 艮
    [
      'A pause begins — give last year more time.',
      'A hidden stop seeds a larger leap.',
      'Pause one beat longer before you show.',
      'Even when the door opens, step in with one foot.',
      'Peak patience — staying still is the answer.',
      'Mid-year pivot — one stop moves the next mountain.',
      'Cash flow — pause to look. Hold decisions.',
      'Recognition lives inside the pause — rehearse receiving.',
      'An old peak trembles briefly, then settles.',
      'Harvest slowly — not all at once.',
      'Recovery — the deepest stop for the next mountain.',
      'Pick one mountain for next year; name it on paper.',
    ],
    // 7 兌
    [
      'Dialogue begins — knock on doors that were closed.',
      'A hidden conversation opens a big opportunity.',
      'Visibility rises — tone of voice is key.',
      'A door opens through words — sincerity once more.',
      'The patience test is silence — speak less.',
      'Mid-year pivot — sort one dialogue for the next.',
      'Cash flow through conversation — negotiation month.',
      'Peak recognition — write down what was said.',
      'An old tie asks for another exchange.',
      'Harvest — close promised deals with words.',
      'Recovery — speak less, listen.',
      'Sketch next year\'s first conversation in advance.',
    ],
  ];
  final monthlyKo = monthlyByArchetypeKo[archIdx];
  final monthlyEn = monthlyByArchetypeEn[archIdx];
  return Hexagram(
    number: i + 1,
    symbol: arch[0],
    nameEn: arch[1],
    nameKo: arch[2],
    taglineEn: arch[3],
    taglineKo: arch[4],
    yearOverviewEn: yearOverviewEn,
    yearOverviewKo: yearOverviewKo,
    monthlyEn: monthlyEn,
    monthlyKo: monthlyKo,
  );
});
