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

    // R87 sprint 1 — 사용자 mandate: K-POP 케미가 이 앱의 1순위 컨셉이라
    // 더보기 탭 최상위 + hero treatment (배지 + accent 강조 + 큰 사이즈).
    // 기존 '궁합 보기'/'신년운세'/'꿈 풀이'는 케미 아래로 강등.
    final cards = <_Card>[
      _Card(
        eyebrow: useKo ? '팬심 1순위 · FAN PICK' : 'FAN PICK · Top',
        title: useKo ? '최애와 케미' : 'Bias Chemistry',
        subtitle: useKo
            ? 'K-POP 아이돌과 내 사주의 케미를 점수로 보고 친구한테 자랑하세요.'
            : 'Score your K-POP idol chemistry and share it with friends.',
        route: '/reports/kpop-compat',
        size: _CardSize.hero,
      ),
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
              (e) => _CardRow(
                card: e.value,
                highlight: e.key == 0,
                useKo: useKo,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }
}

enum _CardSize { normal, large, hero }

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
  final bool useKo;
  const _CardRow({
    required this.card,
    this.highlight = false,
    this.useKo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isHero = card.size == _CardSize.hero;
    final isLarge = card.size == _CardSize.large;
    final padV = isHero ? 34.0 : (isLarge ? 28.0 : 22.0);
    final titleSize = isHero ? 26.0 : (isLarge ? 22.0 : 17.0);
    return InkWell(
      onTap: () => context.go(card.route),
      child: Container(
        key: Key('reports_home_card_${card.route}'),
        padding: EdgeInsets.fromLTRB(24, padV, 24, padV),
        decoration: BoxDecoration(
          color: isHero
              ? AppColors.accent.withValues(alpha: 0.06)
              : (highlight ? AppColors.paper : AppColors.bg),
          border: Border(
            top: BorderSide(
              color: isHero ? AppColors.accent : AppColors.line,
              width: isHero ? 1.5 : 1,
            ),
            bottom: isHero
                ? const BorderSide(color: AppColors.accent, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // R87 sprint 1 — hero 카드에만 "팬심 1순위" badge.
                  // 사용자 mandate: K-POP 케미가 앱의 1순위 컨셉이라
                  // 다른 카드들 위로 시각적으로 돋보여야 함.
                  if (isHero) ...[
                    Container(
                      key: const Key('reports_home_hero_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        useKo ? '팬심 1순위 · TOP PICK' : 'TOP PICK · 팬',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bg,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    card.eyebrow,
                    style: GoogleFonts.notoSansKr(
                      fontSize: isHero ? 11.5 : 11,
                      fontWeight: isHero ? FontWeight.w500 : FontWeight.w400,
                      color: isHero ? AppColors.accent : AppColors.taupe,
                      letterSpacing: isHero ? 0.4 : 0,
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
                            fontSize: titleSize,
                            fontWeight:
                                isHero ? FontWeight.w500 : FontWeight.w400,
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
                      fontSize: isHero ? 13.5 : 13,
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
                style: GoogleFonts.inter(
                  fontSize: isHero ? 22 : 18,
                  fontWeight: isHero ? FontWeight.w600 : FontWeight.w400,
                  color: isHero ? AppColors.accent : AppColors.taupe,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
