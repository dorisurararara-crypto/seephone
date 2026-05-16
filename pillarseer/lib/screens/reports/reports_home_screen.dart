// Pillar Seer — More home. Keep only high-signal extra readings.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

    // R85 — 메뉴 피로 정리. 토정비결/택일/셀럽 일주 탐색은 숨기고, 사용자가
    // 바로 이해할 수 있는 4개만 노출한다.
    final cards = <_Card>[
      _Card(
        eyebrow: useKo ? '연애 · 인간관계' : 'Love & people',
        title: useKo ? '궁합 보기' : 'Compatibility',
        subtitle: useKo
            ? '두 사람의 끌림, 잘 맞는 지점, 부딪히는 지점을 봐요.'
            : 'See where two people click, support each other, or clash.',
        route: '/reports/compatibility',
        size: _CardSize.large,
      ),
      _Card(
        eyebrow: useKo ? '올해 흐름' : 'Year ahead',
        title: useKo ? '2026 신년운세' : 'New Year 2026',
        subtitle: useKo
            ? '올해 전체 분위기와 달별로 조심할 포인트를 정리해요.'
            : 'A year overview with month-by-month points to watch.',
        route: '/reports/new-year-2026',
      ),
      _Card(
        eyebrow: useKo ? '가볍게 보기' : 'Light read',
        title: useKo ? '꿈 풀이' : 'Dream Reading',
        subtitle: useKo
            ? '기억나는 꿈이 신경 쓰일 때만 가볍게 찾아봐요.'
            : 'Look up a dream when it stays on your mind.',
        route: '/reports/dream',
      ),
      _Card(
        eyebrow: useKo ? '팬심 재미' : 'For fun',
        title: useKo ? '최애와 케미' : 'Bias Chemistry',
        subtitle: useKo
            ? 'K-POP·한국 셀럽과 내 사주의 케미를 비교해요.'
            : 'Compare your saju chemistry with K-pop and Korean celebrities.',
        route: '/reports/kpop-compat',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'P I L L A R    S E E R',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 5,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    useKo ? '더 보기' : 'MORE',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    useKo ? '필요할 때 보는 풀이' : 'EXTRA READINGS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.reportsHomeTitle,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.reportsHomeSubtitle,
                    style: useKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: AppColors.accent,
                            height: 1.55,
                            letterSpacing: 0.3,
                          )
                        : GoogleFonts.cormorantGaramond(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppColors.accent,
                            height: 1.5,
                          ),
                  ),
                ],
              ),
            ),
            ...cards.asMap().entries.map(
              (e) => _CardRow(card: e.value, highlight: e.key == 0),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }
}

enum _CardSize { normal, large }

class _Card {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String route;
  final _CardSize size;
  const _Card({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.route,
    this.size = _CardSize.normal,
  });
}

class _CardRow extends StatelessWidget {
  final _Card card;
  final bool highlight;
  const _CardRow({required this.card, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final isLarge = card.size == _CardSize.large;
    return InkWell(
      onTap: () => context.go(card.route),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          isLarge ? 28 : 22,
          24,
          isLarge ? 28 : 22,
        ),
        decoration: BoxDecoration(
          color: highlight ? AppColors.paper : AppColors.bg,
          border: const Border(
            top: BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.eyebrow,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.taupe,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.title,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: isLarge ? 22 : 17,
                            fontWeight: FontWeight.w400,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.subtitle,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.inkLight,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '→',
                style: GoogleFonts.inter(fontSize: 18, color: AppColors.taupe),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
