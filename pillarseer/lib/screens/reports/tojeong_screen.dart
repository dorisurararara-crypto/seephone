// Pillar Seer — Tojeong-bigyeol (土亭祕訣) Report.
// 사용자 생년월일 → 144 hexagram 중 1개 매핑 + 월별 흐름.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: Text(l.tojeongTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$year · ${l.tojeongSubtitle}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.moonlightGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              _HexagramCard(hex: hex, useKo: useKo),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tojeongYearOverview.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.moonlightGray,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      useKo ? hex.yearOverviewKo : hex.yearOverviewEn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ghostlyWhite,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tojeongMonthlyHeader.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.moonlightGray,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._monthlyTexts(hex, useKo).asMap().entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 38,
                                child: Text(
                                  useKo
                                      ? '${e.key + 1}월'
                                      : _monthEn(e.key),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mysticViolet,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ghostlyWhite,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  String _monthEn(int idx) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[idx % 12];
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

class _HexagramCard extends StatelessWidget {
  final Hexagram hex;
  final bool useKo;
  const _HexagramCard({required this.hex, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStrong),
      ),
      child: Column(
        children: [
          Text(
            'No. ${hex.number}',
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: AppColors.moonlightGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hex.symbol,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.celestialGold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            useKo ? hex.nameKo : hex.nameEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ghostlyWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useKo ? hex.taglineKo : hex.taglineEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.moonlightGray,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
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
  final yearOverviewEn =
      'Cycle ${cycle.toString().padLeft(2, '0')} of 18 — ${arch[1]}. '
      'The year asks for ${arch[3].toLowerCase()} '
      'When the gate of ${arch[1]} opens around mid-year, your patience '
      'compounds into authority. Avoid forcing what is still ripening, '
      'and avoid hesitating once timing arrives. The pillar of this hexagram '
      'rewards specificity — name what you want, in writing, before summer.';
  final yearOverviewKo =
      '18사이클 중 ${cycle.toString().padLeft(2, '0')} — ${arch[2]}. '
      '${arch[4]} '
      '${arch[2]}의 문이 중반에 열릴 때, 인내가 권위로 돌아옵니다. '
      '익지 않은 것을 억지로 끌어내지 말고, 타이밍이 왔을 때 망설이지 마세요. '
      '이 괘는 구체성을 보상합니다 — 여름이 오기 전 원하는 바를 문장으로 적으세요.';
  final monthlyEn = List<String>.generate(12, (m) {
    const moods = [
      'Steady start — close last year\'s loose loops.',
      'Hidden moves bear fruit; quiet meetings matter.',
      'Visibility rises; refine narrative before scale.',
      'A door opens; choose the longer ladder.',
      'Tested patience; the slow path is the right one.',
      'Mid-year pivot; reduce one commitment to grow another.',
      'Cash flow demands attention; renegotiate gracefully.',
      'Recognition arrives; be careful not to overspend energy.',
      'Old relationships return for one final dance.',
      'Harvest window; close deals already in motion.',
      'Restoration phase; recover before launching new.',
      'Reflection and seeding for next year\'s direction.',
    ];
    return moods[m];
  });
  final monthlyKo = List<String>.generate(12, (m) {
    const moods = [
      '안정된 시작 — 작년의 미결을 정리하세요.',
      '숨은 움직임이 결실을 맺습니다. 조용한 미팅이 중요.',
      '주목도 상승 — 확장 전에 메시지를 다듬으세요.',
      '문이 열립니다. 더 긴 사다리를 고르세요.',
      '인내의 시험 — 느린 길이 옳은 길입니다.',
      '연중 전환점 — 하나를 줄여 다른 하나를 키우세요.',
      '현금 흐름 주의 — 우아하게 재조정하세요.',
      '인정이 옵니다 — 에너지를 과소비하지 마세요.',
      '오랜 인연이 마지막 춤을 청합니다.',
      '수확의 창 — 이미 진행 중인 거래를 마무리하세요.',
      '복원의 시기 — 새 출발 전에 회복하세요.',
      '내년 방향을 위한 성찰과 씨앗 뿌리기.',
    ];
    return moods[m];
  });
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
