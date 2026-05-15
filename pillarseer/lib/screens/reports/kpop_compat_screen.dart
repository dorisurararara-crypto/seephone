// Pillar Seer — K-POP Compatibility Lab.
import 'package:go_router/go_router.dart';
// 20+ K-POP 스타와 내 사주 궁합을 비교 → 일주 케미 + 오행 공명 점수 + 매니지먼트 인사이트.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class KpopCompatScreen extends ConsumerStatefulWidget {
  const KpopCompatScreen({super.key});

  @override
  ConsumerState<KpopCompatScreen> createState() => _KpopCompatScreenState();
}

class _KpopCompatScreenState extends ConsumerState<KpopCompatScreen> {
  List<_Star> _stars = [];
  bool _loaded = false;
  String _filter = 'idol'; // K-POP 팬 page → 아이돌이 기본. all/idol/actor/athlete.

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/celebrities.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final stars = list.map(_Star.fromJson).toList();
      setState(() {
        _stars = stars;
        _loaded = true;
      });
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Round 77 sprint 7 — dummy fallback 제거. 사주 null 시 empty state CTA.
    final me = ref.watch(sajuResultProvider);
    final userInfo = ref.watch(userBirthInfoProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

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
          useKo ? 'K-POP 궁합 · 緣' : 'K-POP COMPATIBILITY · 緣',
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
      body: SafeArea(
        top: false,
        child: me == null
            ? _KpopEmptyState(useKo: useKo)
            : _buildLoadedBody(context, me, userInfo, useKo),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  Widget _buildLoadedBody(
      BuildContext context, SajuResult me, dynamic userInfo, bool useKo) {
    // Round 82 sprint 9 — Gender.other 사용자 silent 필터링 fix (외부 review P0 #6).
    // 원본 성별이 UserGender.other 면 반대 성별 셀럽 필터를 끔 — 사용자 의도 존중.
    // 사용자 정보 없거나 other 면 전체 노출.
    String? preferredGender;
    if (userInfo != null) {
      final UserGender userOriginalGender =
          (userInfo is UserBirthInfo) ? userInfo.gender : UserGender.male;
      if (userOriginalGender == UserGender.male) {
        preferredGender = 'F';
      } else if (userOriginalGender == UserGender.female) {
        preferredGender = 'M';
      } else {
        // UserGender.other — 반대 성별 필터 끔, 모든 셀럽 노출.
        preferredGender = null;
      }
    }
    final filtered = _stars
        .where((s) => _filter == 'all' || s.kind == _filter)
        .where((s) =>
            preferredGender == null ||
            s.gender.isEmpty ||
            s.gender == preferredGender)
        .toList()
      ..sort((a, b) => _score(me, b).compareTo(_score(me, a)));

    // Round 77 sprint 7 — 로딩 시 skeleton row 3개 (빈 화면 방지).
    if (!_loaded) {
      return Column(
        children: [
          _Hero(useKo: useKo),
          _FilterRow(
            current: _filter,
            onChanged: (id) => setState(() => _filter = id),
            useKo: useKo,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: 3,
              separatorBuilder: (_, _) => const Divider(
                  height: 1, color: AppColors.line, thickness: 1),
              itemBuilder: (_, _) => const _SkeletonRow(),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _Hero(useKo: useKo),
        // 최상위 매치 — "친구에게 캡처해서 보낼 한 줄" (Round 12 codex P0)
        if (filtered.isNotEmpty)
          _TopMatchCard(
            star: filtered.first,
            score: _score(me, filtered.first),
            useKo: useKo,
          ),
        _FilterRow(
          current: _filter,
          onChanged: (id) => setState(() => _filter = id),
          useKo: useKo,
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: filtered.length + 1,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.line, thickness: 1),
            itemBuilder: (ctx, i) {
              if (i == filtered.length) {
                return _Methodology(useKo: useKo);
              }
              final s = filtered[i];
              final score = _score(me, s);
              return _StarRow(
                me: me,
                star: s,
                score: score,
                rank: i + 1,
                useKo: useKo,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 정통 명리학 궁합 점수:
  /// - 일간 오행 상생/비화/상극 base
  /// - 같은 일주 / 같은 지지 bonus
  /// - 천간 합 (甲己·乙庚·丙辛·丁壬·戊癸) +6
  /// - 지지 육합 (子丑·寅亥·卯戌·辰酉·巳申·午未) +6
  /// - 삼합 partial (子辰·寅午·巳酉·亥卯) +4
  /// - 12지 충 -12, 형(刑) -4
  int _score(SajuResult me, _Star star) {
    if (star.dayPillar.length < 2) return 50;
    final myGan = me.dayPillar.chunGan;
    final myJi = me.dayPillar.jiJi;
    final stGan = star.dayPillar[0];
    final stJi = star.dayPillar[1];
    final myEl = me.dayPillar.chunGanElement;
    final stEl = _elementOf(stGan);
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    int base;
    if (myEl == stEl) {
      base = 74;
    } else if (generates[myEl] == stEl || generates[stEl] == myEl) {
      base = 86;
    } else if (overcomes[myEl] == stEl || overcomes[stEl] == myEl) {
      base = 52;
    } else {
      base = 66;
    }
    // Same day pillar (일주 동일)
    if (me.day60ji == star.dayPillar) base += 8;
    // Same branch only (일지 동일)
    if (myJi == stJi) base += 4;
    // 천간 합 (五合)
    const ganHap = {
      '甲': '己', '己': '甲', '乙': '庚', '庚': '乙', '丙': '辛',
      '辛': '丙', '丁': '壬', '壬': '丁', '戊': '癸', '癸': '戊',
    };
    if (ganHap[myGan] == stGan) base += 6;
    // 지지 육합 (六合)
    const jiHap6 = {
      '子': '丑', '丑': '子', '寅': '亥', '亥': '寅', '卯': '戌',
      '戌': '卯', '辰': '酉', '酉': '辰', '巳': '申', '申': '巳',
      '午': '未', '未': '午',
    };
    if (jiHap6[myJi] == stJi) base += 6;
    // 삼합 partial pair (子辰水, 寅午火, 巳酉金, 亥卯木 — 2개 결합)
    const jiSamhapPairs = {
      '子': ['辰', '申'],
      '辰': ['子', '申'],
      '申': ['子', '辰'],
      '寅': ['午', '戌'],
      '午': ['寅', '戌'],
      '戌': ['寅', '午'],
      '巳': ['酉', '丑'],
      '酉': ['巳', '丑'],
      '丑': ['巳', '酉'],
      '亥': ['卯', '未'],
      '卯': ['亥', '未'],
      '未': ['亥', '卯'],
    };
    if ((jiSamhapPairs[myJi] ?? const []).contains(stJi)) base += 4;
    // 충 (沖)
    const ji12clash = {
      '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
      '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
    };
    if (ji12clash[myJi] == stJi) base -= 12;
    // 형 (刑) — 寅巳申 / 丑戌未 / 子卯 자형
    const jiHyeong = {
      '寅': ['巳', '申'],
      '巳': ['寅', '申'],
      '申': ['寅', '巳'],
      '丑': ['戌', '未'],
      '戌': ['丑', '未'],
      '未': ['丑', '戌'],
      '子': ['卯'],
      '卯': ['子'],
    };
    if ((jiHyeong[myJi] ?? const []).contains(stJi)) base -= 4;
    return base.clamp(18, 99);
  }

  static String _elementOf(String stem) {
    const map = {
      '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
      '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
    };
    return map[stem] ?? '木';
  }
}

// 최상위 매치 카드 — 친구에게 캡처해서 보낼 한 줄 (Round 12 codex P0).
class _TopMatchCard extends StatelessWidget {
  final _Star star;
  final int score;
  final bool useKo;
  const _TopMatchCard({
    required this.star,
    required this.score,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final name = useKo ? star.nameKo : star.nameEn;
    // 그룹명 괄호 제거 — 한 줄 밈 압축 ('뷔 (방탄소년단)' → '뷔')
    final shortName = name.contains('(')
        ? name.split('(').first.trim()
        : name;
    // Round 14 codex P0: 진짜 한 줄 밈처럼 박히게.
    final memeKo = '내 케미픽: $shortName · $score점';
    final memeEn = 'My pick: $shortName · $score';
    final fullKo = '나랑 제일 케미 터지는 K-POP 스타 — $name ($score점).';
    final fullEn = 'My strongest K-POP chemistry — $name ($score).';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: meta label + share button — Row overflow 방지 위해 Flexible
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  useKo ? '오늘의 케미 1위 · TOP MATCH' : "Today's top match",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final text = useKo ? memeKo : memeEn;
                  try {
                    await SharePlus.instance.share(ShareParams(text: text));
                  } catch (_) {
                    await Clipboard.setData(ClipboardData(text: text));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.ink, width: 1),
                  ),
                  child: Text(
                    useKo ? '공유' : 'SHARE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 캡쳐용 초단문 한 줄 — 밈처럼 박힘 (maxLines 1, ellipsis safety)
          Text(
            useKo ? memeKo : memeEn,
            style: GoogleFonts.notoSerifKr(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.3,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // 보조 — 풀 문장
          Text(
            useKo ? fullKo : fullEn,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.accent,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            useKo ? star.blurbKo : star.blurbEn,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              color: AppColors.inkLight,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool useKo;
  const _Hero({required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'K-POP  COMPATIBILITY · 韓 流 緣',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            useKo
                ? '내 사주와 가장 잘 맞는 K-POP·한국 셀럽'
                : 'K-POP and Korean stars matched to your chart',
            style: GoogleFonts.notoSerifKr(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useKo
                ? '나와 잘 맞는 다섯 가지 에너지, 같은 중심 성향, 잘 어울리는 관계, 부딪히는 관계까지 한 번에 계산했어요.'
                : 'Combines five-element resonance, matching day-pillar, harmonious pairings, and conflict points — all at once.',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.inkLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  final bool useKo;
  const _FilterRow({
    required this.current,
    required this.onChanged,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final items = useKo
        ? const [('all', '전체'), ('idol', '아이돌'), ('actor', '배우'), ('athlete', '운동선수')]
        : const [('all', 'ALL'), ('idol', 'IDOL'), ('actor', 'ACTOR'), ('athlete', 'ATHLETE')];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SizedBox(
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            final selected = current == item.$1;
            return GestureDetector(
              onTap: () => onChanged(item.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.ink : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  item.$2.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.ink : AppColors.taupe,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final SajuResult me;
  final _Star star;
  final int score;
  final int rank;
  final bool useKo;
  const _StarRow({
    required this.me,
    required this.star,
    required this.score,
    required this.rank,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    return InkWell(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        color: isTop ? AppColors.paper : AppColors.bg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rank.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                  color: isTop ? AppColors.accent : AppColors.taupe,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Round 77 sprint 7 — 셀럽 thumbnail chip (56×56, 오행 5색 + 이니셜).
            _CelebChip(star: star, useKo: useKo),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              child: Text(
                star.dayPillar,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    useKo ? star.nameKo : star.nameEn,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${star.dayPillarName.toUpperCase()} · ${star.kind.toUpperCase()}',
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
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/100',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 1,
                    color: AppColors.taupe,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.36),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.line, width: 1),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPATIBILITY · 緣',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: AppColors.accent,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '/100',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.taupe,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  useKo ? star.nameKo : star.nameEn,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${star.dayPillar} · ${star.dayPillarName}',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.paper,
                  width: double.infinity,
                  child: Text(
                    _verdict(),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13.5,
                      color: AppColors.ink,
                      height: 1.85,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  useKo ? '풀이 ·  INSIGHT' : 'INSIGHT',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  useKo ? star.blurbKo : star.blurbEn,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.85,
                  ),
                ),
                const SizedBox(height: 22),
                Container(height: 1, color: AppColors.line),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(double.infinity, 52),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Round 77 sprint 7 — 아이돌·배우·스포츠 모두 팬-셀럽 시너지 톤 (무대/컴백/직캠/굿즈/팬싸/명대사/명장면/시즌).
  // 망상 1:1 로맨스 시나리오 제거 — kind='idol' / 'athlete' / 'actor' 분기로 어휘만 차별.
  String _verdict() {
    final isIdol = star.kind == 'idol';
    if (isIdol) {
      return _verdictIdol();
    }
    return _verdictRomance();
  }

  // 아이돌 4 band — 팬-아티스트 시너지 (무대/컴백/카메라/굿즈/직캠/팬싸).
  // 어휘 mandate: 무대/컴백/직캠/굿즈/팬싸 ≥3개. 망상 톤 0회.
  String _verdictIdol() {
    if (score >= 88) {
      return useKo
          ? '이 아이돌의 무대가 너의 흐름을 살리는 케미예요. 컴백 곡 첫 소절에 네 기분이 풀려요. 직캠 한 영상으로 하루가 다시 시작되는 타입. 팬싸 줄 서면 너 차례에 분위기가 풀려요. 굿즈 한 장이 일주일을 가게 해줘요.'
          : "This idol's stage lifts your flow. The first line of a comeback track resets your mood. One fancam can restart your day. In a fansign queue, the room loosens up on your turn. One photocard carries you through a week.";
    } else if (score >= 70) {
      return useKo
          ? '이 아이돌의 컴백 무대 하나가 너의 페이스를 잡아주는 케미예요. 새 앨범 발매일에 너 컨디션이 같이 올라가요. 직캠 영상에서 너랑 결이 닿는 멤버가 보여요. 콘서트 직관 한 번이 분기 전체를 바꿔주는 시너지. 굿즈 한 장도 책상 위에 두면 페이스가 잡혀요.'
          : "One of this idol's comeback stages tunes your pace. On a new album release your condition rises with theirs. One fancam reveals the member whose grain matches yours. One in-person concert reshapes the whole quarter. Even one photocard on your desk keeps the pace.";
    } else if (score >= 55) {
      return useKo
          ? '이 아이돌의 컴백 주기에 너 흐름이 가끔 닿는 케미예요. 모든 무대가 맞진 않지만 한 직캠은 너의 시그니처가 돼요. 굿즈는 한두 장 정도면 충분한 거리감. 팬싸 줄 까지는 안 가도 좋아요.'
          : "Your flow touches this idol's comeback cycle once in a while. Not every stage lands, but one fancam becomes your signature. One or two photocards is the right merch distance. No fansign queue needed.";
    } else {
      return useKo
          ? '이 아이돌의 무대 톤이 너의 페이스랑 다른 케미예요. 컴백 직캠 한 번 보면 알아요. 굿즈 살 정도는 아닌 거리감. 한 곡 정도 플레이리스트 끝에 둘 만큼만.'
          : "This idol's stage tone runs a different pace from yours. One comeback fancam tells you. Not a merch-buying distance. About one track sits well at the bottom of your playlist.";
    }
  }

  // Round 77 sprint 7 — 배우/스포츠 셀럽도 팬-셀럽 시너지 톤으로 통일.
  // 망상 1:1 시나리오 X. 작품/경기/인터뷰/필모/명장면 어휘로 톤 차별화.
  String _verdictRomance() {
    final isAthlete = star.kind == 'athlete';
    if (score >= 88) {
      if (isAthlete) {
        return useKo
            ? '이 선수의 경기 흐름이 너의 페이스를 살리는 케미예요. 명장면 한 컷이 너의 하루를 다시 켜요. 우승 인터뷰 한 줄이 너 안에 박혀요. 시즌 첫 경기 직관 한 번이 분기를 바꿔줘요. 응원하는 팀 굿즈 한 장이 일주일을 가게 해줘요.'
            : "This athlete's match flow lifts your pace. One highlight clip restarts your day. One line from a victory interview lands in you. One in-person opening game reshapes the quarter. One team merch piece carries you a week.";
      }
      return useKo
          ? '이 배우의 필모가 너의 흐름을 살리는 케미예요. 명대사 한 줄에 너 기분이 풀려요. 인터뷰 영상 하나로 하루가 다시 시작되는 타입. 신작 첫 회 직관 한 번이 분기 전체를 바꿔줘요. 작품 OST 한 곡이 일주일 BGM이 돼요.'
          : "This actor's filmography lifts your flow. One signature line resets your mood. One interview clip can restart your day. One opening-episode in real time reshapes the whole quarter. One OST track carries your week as BGM.";
    } else if (score >= 70) {
      if (isAthlete) {
        return useKo
            ? '이 선수의 시즌 컨디션이 너의 페이스를 잡아주는 케미예요. 큰 경기 결과에 너 컨디션이 같이 올라가요. 인터뷰 영상에서 너랑 결이 닿는 한 마디가 와요. 시즌 한 번 직관이 분기를 바꿔줘요.'
            : "This athlete's season condition tunes your pace. On a big-game result your condition rises with theirs. One line from their interview touches your grain. One in-person season visit reshapes the quarter.";
      }
      return useKo
          ? '이 배우의 새 작품 사이클에 너의 페이스가 같이 가는 케미예요. 공개일에 너 컨디션이 같이 올라가요. 인터뷰 한 컷에서 너랑 결이 닿는 멤버. 시즌 한 번 정주행이 분기 전체를 바꿔줘요.'
          : "Your pace runs along this actor's new-project cycle. On a release date your condition rises with theirs. One interview frame touches your grain. One season binge reshapes the whole quarter.";
    } else if (score >= 55) {
      if (isAthlete) {
        return useKo
            ? '이 선수의 컨디션 사이클에 너의 흐름이 가끔 닿는 케미예요. 모든 경기가 닿진 않지만 한 경기는 너의 시그니처 게임이 돼요. 직캠보다 인터뷰 한 컷이 더 닿는 타입.'
            : "Your flow touches this athlete's condition cycle once in a while. Not every game lands, but one becomes your signature match. Their interview clip reaches you more than the highlight reel.";
      }
      return useKo
          ? '이 배우의 작품 사이클에 너의 흐름이 가끔 닿는 케미예요. 모든 작품이 맞진 않지만 한 작품은 너의 인생작이 돼요. 명대사보다 인터뷰 영상이 더 닿는 타입.'
          : "Your flow touches this actor's project cycle once in a while. Not every project lands, but one becomes your life-show. Their interview reaches you more than the famous quote.";
    } else {
      if (isAthlete) {
        return useKo
            ? '이 선수의 경기 톤이 너의 페이스랑 다른 케미예요. 플레이는 좋지만 너의 일상 페이스 자리에는 잘 안 맞아요. 한 경기 정도 하이라이트로만 둘 만한 거리감.'
            : "This athlete's game tone runs a different pace from yours. The play is good but doesn't fit your daily rhythm. About one match sits well at the bottom of your highlights.";
      }
      return useKo
          ? '이 배우의 작품 톤이 너의 페이스랑 다른 케미예요. 작품은 좋지만 너의 일상 BGM 자리에는 잘 안 맞아요. 한 작품 정도 정주행 목록 끝에 둘 만한 거리감.'
          : "This actor's project tone runs a different pace from yours. The shows are good but don't fit your daily BGM slot. About one project sits well at the bottom of your watch list.";
    }
  }

  // Round 77 sprint 7 — discover 모달 prefill query 생성 (compat 화면 prefill).
}

/// Round 77 sprint 7 — 셀럽 thumbnail chip (56×56, 오행 5색 + 이니셜).
/// 실사진 X (저작권 안전), 컬러+모노그램 만. 모서리 사각 Aesop 톤.
class _CelebChip extends StatelessWidget {
  final _Star star;
  final bool useKo;
  const _CelebChip({required this.star, required this.useKo});

  static const _wood = Color(0xFF8FA86E); // 木 sage green
  static const _fire = Color(0xFFE5947B); // 火 살구
  static const _earth = Color(0xFFC9A66B); // 土 토피
  static const _metal = Color(0xFFB8B5B0); // 金 라이트 그레이
  static const _water = Color(0xFF6E7D8E); // 水 잉크 블루

  static Color _colorFor(String stem) {
    const elMap = {
      '甲': _wood, '乙': _wood,
      '丙': _fire, '丁': _fire,
      '戊': _earth, '己': _earth,
      '庚': _metal, '辛': _metal,
      '壬': _water, '癸': _water,
    };
    return elMap[stem] ?? _earth;
  }

  @override
  Widget build(BuildContext context) {
    final stem = star.dayPillar.isNotEmpty ? star.dayPillar[0] : '甲';
    final bg = _colorFor(stem);
    // 한국어 모드 = 한국어 이니셜, 영문 = 영문 이니셜. 빈 문자열 fallback '·'.
    String initial;
    final name = useKo ? star.nameKo : star.nameEn;
    if (name.isEmpty) {
      initial = '·';
    } else {
      // 한국어: 첫 한 글자. 영문: 첫 공백 분리 후 각 단어 첫 글자 1-2.
      if (useKo) {
        initial = name[0];
      } else {
        final parts = name.split(RegExp(r'\s+'));
        initial = parts.first.isNotEmpty ? parts.first[0] : '·';
      }
    }
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      color: bg,
      child: Text(
        initial,
        style: GoogleFonts.notoSerifKr(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: AppColors.bg,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Round 77 sprint 7 — 로딩 시 skeleton row (회색 placeholder).
/// chip / rank / 일주 / 이름 / 점수 자리 모두 회색 막대.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  static const _grey = Color(0xFFD7D1C2); // line 보다 살짝 진하게.

  @override
  Widget build(BuildContext context) {
    Widget bar({double width = 60, double height = 12}) => Container(
          width: width,
          height: height,
          color: _grey,
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      color: AppColors.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 28, child: bar(width: 18, height: 10)),
          const SizedBox(width: 8),
          Container(width: 56, height: 56, color: _grey),
          const SizedBox(width: 12),
          SizedBox(width: 44, child: bar(width: 36, height: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width: 120, height: 14),
                const SizedBox(height: 6),
                bar(width: 80, height: 9),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bar(width: 42, height: 24),
              const SizedBox(height: 4),
              bar(width: 22, height: 9),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round 77 sprint 7 — saju null 시 empty state CTA.
/// dummy() fallback 제거 — "내 생일을 먼저 넣어야 케미가 보여요" + 입력 화면 이동.
class _KpopEmptyState extends StatelessWidget {
  final bool useKo;
  const _KpopEmptyState({required this.useKo});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.kpopEmptySub,
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.kpopEmptyTitle,
              style: GoogleFonts.notoSerifKr(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.kpopEmptyBody,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 28),
            InkWell(
              onTap: () => context.go('/input'),
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                color: AppColors.ink,
                child: Text(
                  '${l.kpopEmptyCta}  →',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.bg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Methodology extends StatelessWidget {
  final bool useKo;
  const _Methodology({required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      color: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? 'METHODOLOGY · 計 算' : 'METHODOLOGY · 計 算',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            useKo
                ? '점수는 다섯 가지 기운(나무·불·흙·쇠·물)이 서로 살리는지, 같은 결인지, 잘 어울리는 띠인지, 부딪히는 띠인지를 종합해서 계산해요. 셀럽의 정확한 태어난 시간은 알 수 없어서 태어난 날짜 기준으로만 비교하는데, 시간까지 알면 점수가 더 정확해집니다.'
                : 'The score blends five-element resonance (Wood, Fire, Earth, Metal, Water), shared core nature, harmonious zodiac pairings, and clashing zodiac points. We don\'t know the celebrity\'s exact birth time, so the comparison uses birth date only — adding birth time would refine the score further.',
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              color: AppColors.inkLight,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            useKo
                ? '본 콘텐츠는 정통 명리학(KASI 절기력) 기반 학습·엔터테인먼트 풀이입니다. 실제 인생 결정의 절대 기준은 아닙니다.'
                : 'This is myeongli-based entertainment scoring (KASI solar terms). Not an absolute basis for life decisions.',
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    color: AppColors.taupe,
                    height: 1.65,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.taupe,
                    height: 1.6,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final String id;
  final String nameEn;
  final String nameKo;
  final String kind;
  final String birth;
  final String dayPillar;
  final String dayPillarName;
  final String blurbEn;
  final String blurbKo;
  /// 'M' (남성) / 'F' (여성) / '' (미지정)
  final String gender;
  const _Star({
    required this.id,
    required this.nameEn,
    required this.nameKo,
    required this.kind,
    required this.birth,
    required this.dayPillar,
    required this.dayPillarName,
    required this.blurbEn,
    required this.blurbKo,
    this.gender = '',
  });

  factory _Star.fromJson(Map<String, dynamic> j) => _Star(
        id: j['id'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        nameKo: j['nameKo'] as String? ?? '',
        kind: j['kind'] as String? ?? 'icon',
        birth: j['birth'] as String? ?? '',
        dayPillar: j['dayPillar'] as String? ?? '',
        dayPillarName: j['dayPillarName'] as String? ?? '',
        blurbEn: j['blurbEn'] as String? ?? '',
        blurbKo: j['blurbKo'] as String? ?? '',
        gender: j['gender'] as String? ?? '',
      );
}
