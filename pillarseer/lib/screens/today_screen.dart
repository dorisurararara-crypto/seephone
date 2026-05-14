// Pillar Seer Round 79 Sprint 7 — 신규 /today route.
//
// 사용자 mandate: "내 사주 = 평생사주만 나오게".
// result_screen 의 today_event detail 섹션을 별 페이지로 분리.
//
// 본 sprint 7 의 minimal 화면 분리:
// - 신규 `/today` route 진입 시 TodayEventDetailSection (result_screen public 노출) 렌더.
// - result_screen 의 평생사주 영역 안 mount 는 backward compat (anchor scroll) 으로 유지.
// - home_screen `_TodayEventCard` push target → `/today` (사용자 새 진입 경로).
// - 알림 deep-link `/result?anchor=today_event` → `/today` redirect (router rule).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/saju_provider.dart';
import '../services/daily_service.dart';
import '../services/today_deep_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart' show TodayDeepReadingSection;
import 'result_screen.dart' show TodayEventDetailSection;

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
              TodayEventDetailSection(
                result: result,
                useKo: useKo,
              ),
              const SizedBox(height: 24),
              TodayDeepReadingSection(
                reading: TodayDeepService.build(
                  userDayStem: result.dayPillar.chunGan,
                  userDayBranch: result.dayPillar.jiJi,
                  userMonthBranch: result.monthPillar.jiJi,
                  userDominantEl: result.elements.dominant,
                  userDeficitEl: result.elements.deficit,
                  todayPillar: DailyService().calculate(result).dayPillar,
                  todayScore: DailyService().calculate(result).totalScore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
