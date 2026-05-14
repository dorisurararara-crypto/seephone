// Pillar Seer — Date Picking (擇日) Report. Aesop Luxury tone.
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saju_result.dart';
import '../../providers/locale_provider.dart';
import '../../providers/saju_provider.dart';
import '../../services/saju_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/saju_required_empty.dart';

class DatePickingScreen extends ConsumerWidget {
  const DatePickingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    // Round 77 sprint 8 — SajuResult.dummy() fallback 제거.
    final sajuOrNull = ref.watch(sajuResultProvider);
    if (sajuOrNull == null) {
      return const SajuRequiredEmpty();
    }
    final saju = sajuOrNull;
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
          useKo ? '택일 · 擇 日' : 'DATE PICKING · 擇 日',
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
            _HeroSection(subtitle: l.datePickSubtitle),
            _Summary(good: good.length, neutral: neutral.length, avoid: avoid.length, useKo: useKo),
            _Group(
              meta: l.datePickGoodDays,
              days: good,
              useKo: useKo,
              background: AppColors.bg,
              accent: true,
            ),
            _Group(
              meta: l.datePickAvoidDays,
              days: avoid,
              useKo: useKo,
              background: AppColors.paper,
            ),
            _Group(
              meta: l.datePickNeutral,
              days: neutral,
              useKo: useKo,
              background: AppColors.bg,
            ),
            const SizedBox(height: 24),
          ],
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
        reasonKo = '오늘이 당신을 살림 — 받고, 결정하고, 약속을 잡으세요.';
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
        animalKo: _jiKoreanAnimal(pillar.jiJi),
        kind: kind,
        reasonEn: reasonEn,
        reasonKo: reasonKo,
      ));
    }
    return results;
  }

  String _jiKoreanAnimal(String ji) {
    const map = {
      '子': '쥐', '丑': '소', '寅': '호랑이', '卯': '토끼',
      '辰': '용', '巳': '뱀', '午': '말', '未': '양',
      '申': '원숭이', '酉': '닭', '戌': '개', '亥': '돼지',
    };
    return map[ji] ?? ji;
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
  final String animalKo;
  final _DayKind kind;
  final String reasonEn;
  final String reasonKo;
  const _DateDay({
    required this.date,
    required this.pillar,
    required this.animal,
    required this.animalKo,
    required this.kind,
    required this.reasonEn,
    required this.reasonKo,
  });
}

class _HeroSection extends StatelessWidget {
  final String subtitle;
  const _HeroSection({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
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
            'NEXT  30  DAYS · 三 旬',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 17,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    height: 1.6,
                    letterSpacing: 0.3,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent,
                    height: 1.6,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int good;
  final int neutral;
  final int avoid;
  final bool useKo;
  const _Summary({
    required this.good,
    required this.neutral,
    required this.avoid,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final cells = [
      (l.datePickGoodDays, good, '吉'),
      (l.datePickNeutral, neutral, '平'),
      (l.datePickAvoidDays, avoid, '凶'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.line),
            left: BorderSide(color: AppColors.line),
          ),
        ),
        child: Row(
          children: cells.map((c) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.line),
                    bottom: BorderSide(color: AppColors.line),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      c.$3,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        color: AppColors.accent,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${c.$2}',
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: AppColors.ink,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.$1.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                        color: AppColors.taupe,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String meta;
  final List<_DateDay> days;
  final bool useKo;
  final Color background;
  final bool accent;
  const _Group({
    required this.meta,
    required this.days,
    required this.useKo,
    required this.background,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: background,
        border: const Border(
            bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meta.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              children: days.take(12).map((d) => _row(d)).toList(),
            ),
          ),
          if (days.length > 12) ...[
            const SizedBox(height: 12),
            Text(
              '+ ${days.length - 12} more days',
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.taupe,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(_DateDay d) {
    final dateStr = DateFormat('MMM d').format(d.date);
    final wd = DateFormat('EEE').format(d.date).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wd,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: AppColors.taupe,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              d.pillar,
              style: GoogleFonts.notoSerifKr(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: AppColors.accent,
                letterSpacing: 1,
                height: 1.1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              useKo ? d.reasonKo : d.reasonEn,
              style: GoogleFonts.notoSansKr(
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
