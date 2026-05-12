// Pillar Seer — K-POP Compatibility Lab.
// 20+ K-POP 스타와 내 사주 궁합을 비교 → 일주 케미 + 오행 공명 점수 + 매니지먼트 인사이트.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  String _filter = 'all'; // all / idol / actor

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'K  P O P  ·  緣',
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
                  _FilterRow(
                    current: _filter,
                    onChanged: (id) => setState(() => _filter = id),
                    useKo: useKo,
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, color: AppColors.line, thickness: 1),
                      itemBuilder: (ctx, i) {
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

  int _score(SajuResult me, _Star star) {
    final myEl = me.dayPillar.chunGanElement;
    final stEl = _elementOf(star.dayPillar.isEmpty ? '甲' : star.dayPillar[0]);
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    int base;
    if (myEl == stEl) {
      base = 76;
    } else if (generates[myEl] == stEl || generates[stEl] == myEl) {
      base = 88;
    } else if (overcomes[myEl] == stEl || overcomes[stEl] == myEl) {
      base = 54;
    } else {
      base = 68;
    }
    if (me.day60ji == star.dayPillar) base += 8;
    if (star.dayPillar.length >= 2 &&
        me.dayPillar.jiJi == star.dayPillar[1]) {
      base += 4;
    }
    const ji12clash = {
      '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
      '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
    };
    if (star.dayPillar.length >= 2 &&
        ji12clash[me.dayPillar.jiJi] == star.dayPillar[1]) {
      base -= 12;
    }
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
            useKo ? '내 사주와 가장 잘 맞는 K-POP 스타' : 'K-POP stars who match your chart',
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
                ? '오행 공명 + 일주 케미 + 12지 충/합 기준 정통 명리학 점수.'
                : 'Scored by elemental resonance, day-pillar chemistry, and 12-branch interactions.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.accent,
              height: 1.5,
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
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent,
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
