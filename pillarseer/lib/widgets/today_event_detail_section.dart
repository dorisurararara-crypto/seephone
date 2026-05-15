// Pillar Seer Round 82 sprint 2 — TodayEventDetailSection 분리.
//
// 사용자 mandate: "내 사주" 탭 = 평생사주만. "오늘 당신에게 생길 수 있는 일" 카드는
// `/today` 탭 단독 노출. R79 sprint 7 가 partial 분리 (result_screen 의 mount 잔존) 였고
// R82 sprint 2 가 완전 분리 — result_screen 에서 본 widget mount / anchor key / scroll
// logic 모두 제거. router 의 `/result?anchor=today_event` → `/today` redirect 가
// 알림 deep-link 호환 처리 (R79 sprint 7 line 50~53 보존).
//
// 본 widget 의 본문·별점·시그니처는 R76 sprint 5 wire 그대로 (변경 0).
// 시각 동일성을 위해 result_screen 의 `_SectionFrame` 와 동일한 컨테이너를
// 본 file 안 inline private helper (`_TodayEventSectionFrame`) 로 복제.
//
// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/saju_result.dart';
import '../services/daily_service.dart' show DailyService;
import '../services/today_event_service.dart';
import '../theme/app_theme.dart';

/// `/today` 탭 단독 노출 — 오늘 사건 가능성 카드.
///
/// R76 sprint 5 wire (DailyService → TodayEventService.build → composeBodyKoWithAnchor
/// + composeCautionKo + composeRecommendKo + 4 row 별점 게이지) 보존.
class TodayEventDetailSection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const TodayEventDetailSection({
    super.key,
    required this.result,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    // DailyService 로 오늘 일진 + 점수 계산 후 TodayEventService.build 호출.
    final fortune = DailyService().calculate(result);
    final reading = TodayEventService.build(
      userDayStem: result.dayPillar.chunGan,
      userDayBranch: result.dayPillar.jiJi,
      userMonthBranch: result.monthPillar.jiJi,
      todayPillar: fortune.dayPillar,
      todayScore: fortune.totalScore,
    );
    // Round 78 sprint 6 — anchor (신살/합충/천간합) wire. ko 본문은 composeBodyKoWithAnchor.
    final day60ji = result.dayPillar.text;
    final now = DateTime.now();
    final body = useKo
        ? TodayEventService.composeBodyKoWithAnchor(
            reading: reading,
            date: now,
            day60ji: day60ji,
            userDayStem: result.dayPillar.chunGan,
            todayStem:
                fortune.dayPillar.isNotEmpty ? fortune.dayPillar[0] : null,
          )
        : TodayEventService.composeNotificationLineEn(reading);
    // sourceReason 도 ko/en 분기 (Round 76 sprint 5 r2 fix).
    final why = useKo ? reading.sourceReason : reading.sourceReasonEn;
    // 조심/추천 — pool entry 우선, 미스 시 카테고리별 inline.
    final caution = useKo
        ? (TodayEventService.composeCautionKo(
                reading: reading, date: now, day60ji: day60ji) ??
            _cautionKo(reading.categoryDominant))
        : _cautionEn(reading.categoryDominant);
    final recommend = useKo
        ? (TodayEventService.composeRecommendKo(
                reading: reading, date: now, day60ji: day60ji) ??
            _recommendKo(reading.categoryDominant))
        : _recommendEn(reading.categoryDominant);
    final stars = [
      (l.homeCategoryLove, reading.starsLove),
      (l.homeCategoryWealth, reading.starsMoney),
      (l.homeCategoryWork, reading.starsWork),
      (l.todayEventStarHealth, reading.starsHealth),
    ];

    return _TodayEventSectionFrame(
      background: AppColors.paper,
      meta: useKo ? '오늘 사건 가능성 · TODAY EVENT' : 'TODAY EVENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.todayEventCaption,
            style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              height: 1.65,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 26),
          _TodayDetailRow(label: l.todayEventWhy, body: why, useKo: useKo),
          const SizedBox(height: 16),
          _TodayDetailRow(
              label: l.todayEventCaution, body: caution, useKo: useKo),
          const SizedBox(height: 16),
          _TodayDetailRow(
              label: l.todayEventRecommend, body: recommend, useKo: useKo),
          const SizedBox(height: 24),
          // Round 77 sprint 7 — 별점 텍스트(★☆) → 가로 색 게이지 5칸. 4행 중 1위 accent 강조.
          ..._buildDetailStarRows(stars),
        ],
      ),
    );
  }

  // Round 77 sprint 7 — 4 row 게이지 빌더. 1위는 accent 색 강조.
  // 동률 시 Love → Wealth → Work → Health 순 (stars 리스트 인덱스 0→3 순).
  List<Widget> _buildDetailStarRows(List<(String, int)> stars) {
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                row.$1.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: AppColors.taupe,
                ),
              ),
            ),
            Expanded(
              child:
                  _TodayResultScoreGauge(score: row.$2, isTop: i == topIdx),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Round 76 sprint 5 — 카테고리별 조심/추천 자연어 inline.
  static String _cautionKo(EventCategory c) {
    switch (c) {
      case EventCategory.relationship:
        return '바로 반응하지 말고 한 박자 늦게 답하세요.';
      case EventCategory.money:
        return '할인이라는 말에 바로 결제하지 마세요.';
      case EventCategory.work:
        return '큰 결정 말고 정리부터 하면 좋아요.';
      case EventCategory.love:
        return '상대 반응을 너무 크게 해석하지 마세요.';
      case EventCategory.health:
        return '자극적인 음식이나 늦은 수면은 피하세요.';
      case EventCategory.luck:
        return '관심 분야 하나만 가볍게 검색해보세요.';
    }
  }

  static String _cautionEn(EventCategory c) {
    switch (c) {
      case EventCategory.relationship:
        return 'Hold the snap reply — answer a beat later.';
      case EventCategory.money:
        return "Don't tap pay just because it's on sale.";
      case EventCategory.work:
        return 'Skip big decisions today — cleanup first.';
      case EventCategory.love:
        return "Don't over-read the other person's reaction.";
      case EventCategory.health:
        return 'Avoid spicy food and late sleep.';
      case EventCategory.luck:
        return "Don't ignore a casual recommendation — note it before it fades.";
    }
  }

  static String _recommendKo(EventCategory c) {
    switch (c) {
      case EventCategory.relationship:
        return '먼저 가볍게 인사 한 줄 건네보세요.';
      case EventCategory.money:
        return '장바구니에만 담아두고 하루 자고 보세요.';
      case EventCategory.work:
        return '오늘 끝낼 한 가지만 정해 집중하세요.';
      case EventCategory.love:
        return '짧은 안부 한 줄로 가볍게 시작하세요.';
      case EventCategory.health:
        return '물 한 잔 마시고 30분 일찍 누워보세요.';
      case EventCategory.luck:
        return '들은 키워드 하나는 메모에 적어두세요.';
    }
  }

  static String _recommendEn(EventCategory c) {
    switch (c) {
      case EventCategory.relationship:
        return 'Send a light hello first.';
      case EventCategory.money:
        return 'Add to cart and sleep on it.';
      case EventCategory.work:
        return 'Pick one task to finish today and focus.';
      case EventCategory.love:
        return 'Open with a short, friendly hi.';
      case EventCategory.health:
        return 'Drink water and go to bed 30 min earlier.';
      case EventCategory.luck:
        return 'Note one keyword you heard today.';
    }
  }
}

/// result_screen 의 `_SectionFrame` 시각 동일 복제 (R82 sprint 2 분리 후 의존 끊기).
class _TodayEventSectionFrame extends StatelessWidget {
  final Color background;
  final String? meta;
  final Widget child;
  final EdgeInsets padding;
  final bool topBorder;
  final bool bottomBorder;
  const _TodayEventSectionFrame({
    required this.background,
    required this.child,
    this.meta,
    this.padding = const EdgeInsets.fromLTRB(24, 36, 24, 36),
    this.topBorder = false,
    this.bottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: topBorder
              ? const BorderSide(color: AppColors.line, width: 1)
              : BorderSide.none,
          bottom: bottomBorder
              ? const BorderSide(color: AppColors.line, width: 1)
              : BorderSide.none,
        ),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta != null) ...[
            Text(
              meta!.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 22),
          ],
          child,
        ],
      ),
    );
  }
}

class _TodayDetailRow extends StatelessWidget {
  final String label;
  final String body;
  final bool useKo;
  const _TodayDetailRow({
    required this.label,
    required this.body,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 13.5,
                  height: 1.65,
                  color: AppColors.inkLight,
                )
              : GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.6,
                  color: AppColors.inkLight,
                ),
        ),
      ],
    );
  }
}

/// Round 77 sprint 7 — 별점 텍스트 대체 가로 색 게이지 5칸 (today event).
/// 가득 찬 칸: isTop=true → accent (gold), false → ink. 빈 칸: line (회색).
class _TodayResultScoreGauge extends StatelessWidget {
  final int score;
  final bool isTop;
  const _TodayResultScoreGauge({required this.score, required this.isTop});

  @override
  Widget build(BuildContext context) {
    final filled = score.clamp(0, 5);
    final activeColor = isTop ? AppColors.accent : AppColors.ink;
    final cells = <Widget>[];
    for (var i = 0; i < 5; i++) {
      final isFilled = i < filled;
      cells.add(Expanded(
        child: Container(
          height: 9,
          color: isFilled ? activeColor : AppColors.line,
        ),
      ));
      if (i < 4) cells.add(const SizedBox(width: 4));
    }
    return Row(children: cells);
  }
}
