// Pillar Seer Round 79 Sprint 7 — 신규 /today route.
//
// 사용자 mandate: "내 사주 = 평생사주만 나오게".
// result_screen 의 today_event detail 섹션을 별 페이지로 분리.
//
// Round 82 sprint 2 — 분리 완료:
// - TodayEventDetailSection 이 `lib/widgets/today_event_detail_section.dart` 단독.
// - result_screen 의 mount + anchor key + scroll logic 전부 제거 (`#4` fix).
// - home_screen `_TodayEventCard` push target → `/today` (R79 sprint 7 wire 보존).
// - 알림 deep-link `/result?anchor=today_event` → `/today` redirect (router rule 보존).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/saju_provider.dart';
import '../services/daily_service.dart';
import '../services/saju_context.dart';
import '../services/today_deep_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_gate.dart';
import '../widgets/today_event_detail_section.dart';
import '../widgets/today_v5_loader.dart';
import 'home_screen.dart' show TodayDeepReadingSection;

/// /today 페이지 — today_event 상세 + (옵션) today_deep 본문 통합 노출.
/// result_screen 의 평생사주 영역과 분리 (사용자 mandate "내 사주 = 평생사주만").
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(sajuResultProvider);
    final useKo = Localizations.localeOf(context).languageCode == 'ko';

    if (result == null) {
      // 사주 결과 없으면 입력 진입.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/input');
      });
      return const SizedBox.shrink();
    }

    // R84 — 단일 source DateTime + 단일 fortune + ctx 주입 (home 와 parity).
    // 이전: TodayDeepService.build 가 ctx 없이 호출되어 today tab 본문이 home 대비
    // 격국/용신/대운 anchor 누락 + DailyService 가 2회 호출되며 SajuContext 의
    // todayPillar/seed 가 home 과 달라지는 위험. now/today/fortune 단일화로 고정.
    final now = DateTime.now();
    final fortune = DailyService().calculate(result, today: now);
    final ctx = SajuContext.from(result, today: now);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          useKo ? '오늘' : 'Today',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // R106 P2a — 오늘의 사주 v5 (오늘의 주제 중심 + 근거 3칩 + 자기검증)
              // 가 primary 섹션. TopicSelector 신호 0 시 v5 자체가 총평형 fallback.
              // R110 Sprint 2 — v5 핵심 요약/행동은 무료(playbook ②).
              TodayV5Loader(saju: result, date: now),
              const SizedBox(height: 24),
              // R110 Sprint 2 — 오늘 사주 총평(심층) + 오늘 사건 상세는 프리미엄.
              // TodayDeepService 기반 심층 본문·추가 확장은 PremiumGate 로 잠근다.
              PremiumGate(
                feature: PremiumFeature.todayDeep,
                label: useKo ? '오늘의 사주 심층' : "Today's Deep Reading",
                unlocked: (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 기존 오늘 사주 총평 (TodayDeepService) — 심층 deep reading.
                    TodayDeepReadingSection(
                      reading: TodayDeepService.build(
                        userDayStem: result.dayPillar.chunGan,
                        userDayBranch: result.dayPillar.jiJi,
                        userMonthBranch: result.monthPillar.jiJi,
                        userDominantEl: result.elements.dominant,
                        userDeficitEl: result.elements.deficit,
                        todayPillar: fortune.dayPillar,
                        todayScore: fortune.totalScore,
                        ctx: ctx,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TodayEventDetailSection(result: result, useKo: useKo),
                  ],
                ),
                locked: (_) => PremiumLockedSection(
                  feature: PremiumFeature.todayDeep,
                  title: useKo ? '오늘 사주 심층 해석' : "Today's Deep Reading",
                  description: useKo
                      ? '오늘 일진을 더 깊게 풀어낸 총평과 오늘 일어날 수 있는 일 상세는 프리미엄팩에서 열려요.'
                      : 'A deeper read of today and what may unfold opens with the Premium Pack.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
