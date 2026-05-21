// Pillar Seer — Round 106 (P2a) — 오늘의 사주 v5 async 조립 로더.
//
// home/today 화면이 v5 섹션을 mount 할 때 selector wire 에 필요한 비동기 작업
// (RecallFeedbackService 에서 userPref / shownDaysAgo / suppressed 읽기) 을
// 한 곳에서 처리한다. selector·feedback·계산 엔진은 호출만 한다 (수정 0).
//
// 조립 순서:
//   1. DailyService.calculate → 오늘 일진·점수
//   2. SajuContext.from → full chart context
//   3. TodayEventService.build → 오늘 사건 reading (selector evidence + 칩 라벨)
//   4. RecallFeedbackService → 10 주제 userPref / shownDaysAgo / suppressed
//   5. TopicSelectorService.select → 오늘의 주제
//   6. TodayV5Service.build → v5 reading
//   7. TodayV5Section 렌더

import 'package:flutter/material.dart';

import '../models/saju_result.dart';
import '../services/daily_service.dart';
import '../services/recall_feedback_service.dart';
import '../services/saju_context.dart';
import '../services/today_event_service.dart';
import '../services/today_v5_service.dart';
import '../services/topic_selector_service.dart';
import 'today_v5_section.dart';

/// 오늘의 사주 v5 — 비동기 조립 + 렌더 wrapper.
class TodayV5Loader extends StatefulWidget {
  final SajuResult saju;

  /// 단일 source DateTime — home/today 가 fortune/ctx 와 동일하게 공유.
  final DateTime date;

  const TodayV5Loader({super.key, required this.saju, required this.date});

  @override
  State<TodayV5Loader> createState() => _TodayV5LoaderState();
}

class _TodayV5LoaderState extends State<TodayV5Loader> {
  late Future<TodayV5Reading> _future;

  @override
  void initState() {
    super.initState();
    _future = _assemble();
  }

  Future<TodayV5Reading> _assemble() async {
    final saju = widget.saju;
    final date = widget.date;

    // 1~3. 계산 엔진 산출물 (읽기만).
    final fortune = DailyService().calculate(saju, today: date);
    final ctx = SajuContext.from(saju, today: date);
    final event = TodayEventService.build(
      userDayStem: saju.dayPillar.chunGan,
      userDayBranch: saju.dayPillar.jiJi,
      userMonthBranch: saju.monthPillar.jiJi,
      todayPillar: fortune.dayPillar,
      todayScore: fortune.totalScore,
    );

    // 4. RecallFeedbackService — 10 주제 개인화 신호 읽기.
    final userPref = <String, double>{};
    final shownDaysAgo = <String, int>{};
    final suppressed = <String>{};
    for (final topic in DailyTopic.values) {
      final id = topic.id;
      final state = await RecallFeedbackService.stateOf(id);
      userPref[id] = RecallFeedbackService.userPrefFromScore(state.score);
      final last = state.lastShown;
      if (last != null) {
        final d = DateTime(date.year, date.month, date.day)
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;
        if (d >= 0) shownDaysAgo[id] = d;
      }
      if (await RecallFeedbackService.isSuppressed(id, date)) {
        suppressed.add(id);
      }
    }

    // 5. selector.
    final selection = TopicSelectorService.select(
      saju: saju,
      ctx: ctx,
      event: event,
      date: date,
      userPrefById: userPref,
      shownDaysAgoById: shownDaysAgo,
      suppressedIds: suppressed,
    );

    // 6. v5 reading.
    return TodayV5Service.build(
      saju: saju,
      selection: selection,
      event: event,
      chartSeed: ctx.chartSeed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TodayV5Reading>(
      future: _future,
      builder: (context, snap) {
        final reading = snap.data;
        if (reading == null) {
          // 로드 중 — 레이아웃 점프 최소화용 placeholder.
          return const SizedBox(height: 1);
        }
        return TodayV5Section(reading: reading, date: widget.date);
      },
    );
  }
}
