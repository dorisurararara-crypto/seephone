// Pillar Seer — Reports home (Aesop Luxury). 7 chapters in editorial layout.
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

    // 추천 1 — 가장 시즌성 강한 콘텐츠 (지금 시점 보너스)
    final recommended = <_Card>[
      _Card(
        symbol: '丙午',
        title: useKo ? '2026 신년운세' : 'New Year 2026',
        subtitle: useKo
            ? '병오년 1년 흐름 · 매달 분위기 · 12가지 생활 영역'
            : 'Year of Fire Horse · monthly flow · 12 life areas',
        route: '/reports/new-year-2026',
        badge: useKo ? '추천' : 'PICK',
        size: _CardSize.large,
      ),
    ];

    // 가볍게 보기 2 — 재미 + 빠른 소비
    final light = <_Card>[
      _Card(
        symbol: '韓 流',
        title: useKo ? 'K-POP 스타 궁합' : 'K-POP Star Compatibility',
        subtitle: useKo
            ? '20+ K-POP 스타와 나의 사주 일치율'
            : 'Saju matching with 20+ K-POP stars',
        route: '/reports/kpop-compat',
        badge: useKo ? 'NEW' : 'NEW',
      ),
      _Card(
        symbol: '解 夢',
        title: l.reportsCardDream,
        subtitle: useKo
            ? '꿈으로 보는 길흉 — 1,000+ 사전'
            : 'Dream omens — 1,000+ entries',
        route: '/reports/dream',
      ),
    ];

    // 깊게 보기 4 — 정통 명리 깊은 풀이
    final deep = <_Card>[
      _Card(
        symbol: '宮 合',
        title: l.reportsCardCompatibility,
        subtitle: useKo
            ? '두 사람의 사주 일치율 · 끌림과 갈등'
            : l.reportsCardCompatibilityDesc,
        route: '/reports/compatibility',
      ),
      _Card(
        symbol: '土 亭',
        title: l.reportsCardTojeong,
        subtitle: useKo
            ? '올해 한 줄 운세 · 12달 흐름'
            : l.reportsCardTojeongDesc,
        route: '/reports/tojeong',
      ),
      _Card(
        symbol: '擇 日',
        title: l.reportsCardDatePicking,
        subtitle: useKo
            ? '앞으로 30일 길일 · 평일 · 흉일'
            : l.reportsCardDatePickingDesc,
        route: '/reports/date-picking',
      ),
      _Card(
        symbol: '名 譜',
        title: l.discoverTitle,
        subtitle: useKo
            ? '유명인 사주 둘러보기 · 일주 비교'
            : l.discoverSubtitle,
        route: '/discover',
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
                    bottom: BorderSide(color: AppColors.line, width: 1)),
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
                    useKo ? '리포트 · 譜' : 'REPORTS · 譜',
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
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    useKo ? '심층 풀이 · 深 章' : 'DEEP CHAPTERS · 深 章',
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
            _GroupHeader(useKo ? '추천 · 지금 보세요' : 'PICK FOR YOU'),
            ...recommended.map((c) => _CardRow(card: c, highlight: true)),
            _GroupHeader(useKo ? '가볍게 보기' : 'QUICK READS'),
            ...light.map((c) => _CardRow(card: c)),
            _GroupHeader(useKo ? '깊게 보기' : 'DEEP READS'),
            ...deep.map((c) => _CardRow(card: c)),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          letterSpacing: 5,
          fontWeight: FontWeight.w500,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}

enum _CardSize { normal, large }

class _Card {
  final String symbol;
  final String title;
  final String subtitle;
  final String route;
  final String? badge;
  final _CardSize size;
  const _Card({
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.route,
    this.badge,
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
        padding: EdgeInsets.fromLTRB(24, isLarge ? 28 : 22, 24, isLarge ? 28 : 22),
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
                      if (card.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.accent, width: 1),
                          ),
                          child: Text(
                            card.badge!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 한자는 작은 sub-accent (장식)
                  Text(
                    card.symbol,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: AppColors.accent,
                    ),
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
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppColors.taupe,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
