// Pillar Seer — Date Picking (擇日) Report.
// 다음 30일 일진과 사용자 일간 5행 상호작용으로 길일/평일/흉일 분류.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saju_result.dart';
import '../../providers/locale_provider.dart';
import '../../providers/saju_provider.dart';
import '../../services/saju_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class DatePickingScreen extends ConsumerWidget {
  const DatePickingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final saju = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final localeOverride = ref.watch(localeProvider);
    final systemLocale = Localizations.maybeLocaleOf(context);
    final useKo = (localeOverride?.languageCode ??
            systemLocale?.languageCode ??
            'en') ==
        'ko';
    final days = _next30Days(saju);
    final good = days.where((d) => d.kind == _DayKind.good).toList();
    final avoid = days.where((d) => d.kind == _DayKind.avoid).toList();
    final neutral = days.where((d) => d.kind == _DayKind.neutral).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.datePickTitle),
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
                l.datePickSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.moonlightGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                good: good.length,
                neutral: neutral.length,
                avoid: avoid.length,
                useKo: useKo,
              ),
              const SizedBox(height: 18),
              _Section(
                title: l.datePickGoodDays,
                color: AppColors.celestialGold,
                days: good,
                useKo: useKo,
              ),
              const SizedBox(height: 14),
              _Section(
                title: l.datePickAvoidDays,
                color: Colors.redAccent.shade200,
                days: avoid,
                useKo: useKo,
              ),
              const SizedBox(height: 14),
              _Section(
                title: l.datePickNeutral,
                color: AppColors.fadedSilver,
                days: neutral,
                useKo: useKo,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  List<_DateDay> _next30Days(SajuResult me) {
    final svc = SajuService();
    final today = DateTime.now();
    final results = <_DateDay>[];
    final dm = me.dayPillar.chunGanElement;
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    for (var i = 0; i < 30; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      final idx = _dayPillarIndex(d.year, d.month, d.day);
      final pillar = svc.pillarFromIndex(idx);
      final el = pillar.chunGanElement;
      _DayKind kind;
      String reasonEn;
      String reasonKo;
      if (el == dm) {
        kind = _DayKind.good;
        reasonEn = 'Same element — your day master finds a peer.';
        reasonKo = '같은 오행 — 당신의 일간과 어깨를 나란히.';
      } else if (generates[el] == dm) {
        kind = _DayKind.good;
        reasonEn = 'Day nourishes you — receive, decide, sign.';
        reasonKo = '오늘이 당신을 살림 — 받고, 결정하고, 서명하세요.';
      } else if (generates[dm] == el) {
        kind = _DayKind.good;
        reasonEn = 'You nourish the day — pitch, present, launch.';
        reasonKo = '당신이 오늘을 살림 — 제안, 발표, 런칭에 좋습니다.';
      } else if (overcomes[el] == dm) {
        kind = _DayKind.avoid;
        reasonEn = 'Day overcomes you — defer big asks, protect energy.';
        reasonKo = '오늘이 당신을 극함 — 큰 요청은 미루고, 에너지를 보호하세요.';
      } else if (overcomes[dm] == el) {
        kind = _DayKind.neutral;
        reasonEn = 'You overcome the day — push only what is essential.';
        reasonKo = '당신이 오늘을 극함 — 필수만 밀어붙이세요.';
      } else {
        kind = _DayKind.neutral;
        reasonEn = 'A quiet day — steady actions yield best.';
        reasonKo = '잔잔한 날 — 꾸준한 행동이 최선.';
      }
      results.add(_DateDay(
        date: d,
        pillar: pillar.text,
        animal: pillar.jiJiEnglish,
        kind: kind,
        reasonEn: reasonEn,
        reasonKo: reasonKo,
      ));
    }
    return results;
  }

  int _dayPillarIndex(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jdn = ((365.25 * (y + 4716)).floor() +
            (30.6001 * (m + 1)).floor() +
            day +
            b -
            1524.5)
        .floor();
    const epoch = 2415021;
    return (10 + (jdn - epoch)) % 60;
  }
}

enum _DayKind { good, neutral, avoid }

class _DateDay {
  final DateTime date;
  final String pillar;
  final String animal;
  final _DayKind kind;
  final String reasonEn;
  final String reasonKo;
  const _DateDay({
    required this.date,
    required this.pillar,
    required this.animal,
    required this.kind,
    required this.reasonEn,
    required this.reasonKo,
  });
}

class _SummaryRow extends StatelessWidget {
  final int good;
  final int neutral;
  final int avoid;
  final bool useKo;
  const _SummaryRow({
    required this.good,
    required this.neutral,
    required this.avoid,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _chip(l.datePickGoodDays, good, AppColors.celestialGold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(l.datePickNeutral, neutral, AppColors.fadedSilver),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(l.datePickAvoidDays, avoid, Colors.redAccent.shade200),
        ),
      ],
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.moonlightGray,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<_DateDay> days;
  final bool useKo;
  const _Section({
    required this.title,
    required this.color,
    required this.days,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...days.take(12).map((d) => _row(d, useKo)),
          if (days.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+ ${days.length - 12} more',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.fadedSilver,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(_DateDay d, bool useKo) {
    final dateStr = DateFormat('MMM d (EEE)').format(d.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.celestialGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${d.pillar} · ${d.animal}',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.moonlightGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              useKo ? d.reasonKo : d.reasonEn,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.ghostlyWhite,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
