// Pillar Seer — K-POP Compatibility Lab.
import 'package:go_router/go_router.dart';
// 20+ K-POP 스타와 내 사주 궁합을 비교 → 일주 케미 + 오행 공명 점수 + 매니지먼트 인사이트.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final me = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final filtered = _stars
        .where((s) => _filter == 'all' || s.kind == _filter)
        .toList()
      ..sort((a, b) => _score(me, b).compareTo(_score(me, a)));

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
        child: !_loaded
            ? const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.ink, strokeWidth: 1.5)),
              )
            : Column(
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
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, color: AppColors.line, thickness: 1),
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
              ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
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
                ? '오행 상생 · 일주 합 · 천간 五合 · 지지 六合·三合·沖·刑 종합 계산.'
                : 'Elemental resonance · day-pillar combinations · stem 五合 · branch 六合/三合/沖/刑.',
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

  String _verdict() {
    if (score >= 88) {
      return useKo
          ? '자력처럼 끌리는 결합 — 오행이 서로를 살리는 사이클. 함께 무대를 만든다면 시너지가 강하게 작동합니다.'
          : 'Magnetic alignment — your elements feed each other. Together, you build stages well.';
    } else if (score >= 70) {
      return useKo
          ? '안정된 케미 — 무대 위에서나 일상에서나 호흡이 자연스럽게 맞습니다. 큰 충돌 없이 흐릅니다.'
          : 'Steady chemistry — your rhythms align without effort. Few collisions, much flow.';
    } else if (score >= 55) {
      return useKo
          ? '서로 다듬는 결 — 다른 결이 만나 마찰을 만들지만, 그 마찰이 두 사람을 더 정확하게 깎아냅니다.'
          : 'Friction polish — different grains create rub, but the rub sharpens both of you.';
    } else {
      return useKo
          ? '강한 중력의 인연 — 자석처럼 끌리지만 페이스가 다릅니다. 의식적인 동기화가 관계의 빛을 결정합니다.'
          : 'Heavy-gravity pull — magnetic but mismatched pace. Conscious sync decides the light.';
    }
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
                ? '점수는 일간 오행 상생/비화/상극, 같은 일주·일지, 천간 합(五合), 지지 육합(六合)·삼합 부분 일치, 12지 충(沖)·형(刑)을 계산합니다. 스타의 출생일은 공개 자료 기반이며 출생 시간을 알 수 없어 일주(日柱) 기준 비교입니다. 시주(時柱)까지 알면 더 정밀합니다.'
                : 'Score uses day-master element resonance (生/比/剋), same day-pillar/branch, stem combinations (五合), branch combinations (六合, 三合 partial), and 12-branch clash/punishment (沖·刑). Stars\' birth times are not public, so comparison is by day pillar only; including hour pillars would refine the score.',
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
      );
}
