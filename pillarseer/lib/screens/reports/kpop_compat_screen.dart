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
  // R86 — 사용자 mandate: 이름/그룹명 검색.
  String _query = '';
  final TextEditingController _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

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
    // R86 — 사용자 mandate: 이름/그룹명 substring 검색 + 화면 전체 스크롤.
    final query = _query.trim().toLowerCase();
    final filtered = _stars
        .where((s) => _filter == 'all' || s.kind == _filter)
        .where((s) =>
            preferredGender == null ||
            s.gender.isEmpty ||
            s.gender == preferredGender)
        .where((s) {
          if (query.isEmpty) return true;
          return s.nameKo.toLowerCase().contains(query) ||
              s.nameEn.toLowerCase().contains(query);
        })
        .toList()
      ..sort((a, b) => _score(me, b).compareTo(_score(me, a)));

    // R86 — 사용자 mandate: Column+Expanded(ListView) 구조 (내부만 스크롤) → CustomScrollView
    // 슬라이버로 통합해 Hero/TopMatch/Filter/Search/리스트가 한 번에 스크롤되도록 교체.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(useKo: useKo)),
        // 최상위 매치 — "친구에게 캡처해서 보낼 한 줄" (Round 12 codex P0)
        if (_loaded && filtered.isNotEmpty)
          SliverToBoxAdapter(
            child: _TopMatchCard(
              star: filtered.first,
              score: _score(me, filtered.first),
              useKo: useKo,
            ),
          ),
        SliverToBoxAdapter(
          child: _FilterRow(
            current: _filter,
            onChanged: (id) => setState(() => _filter = id),
            useKo: useKo,
          ),
        ),
        SliverToBoxAdapter(
          child: _SearchBar(
            controller: _queryCtrl,
            useKo: useKo,
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        // Round 77 sprint 7 — 로딩 시 skeleton row 3개 (빈 화면 방지).
        if (!_loaded)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Column(
                children: [
                  const _SkeletonRow(),
                  const Divider(
                      height: 1, color: AppColors.line, thickness: 1),
                ],
              ),
              childCount: 3,
            ),
          )
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: _EmptySearchResult(useKo: useKo, query: _query),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (i == filtered.length) {
                  return _Methodology(useKo: useKo);
                }
                final s = filtered[i];
                final score = _score(me, s);
                return Column(
                  children: [
                    _StarRow(
                      me: me,
                      star: s,
                      score: score,
                      rank: i + 1,
                      useKo: useKo,
                    ),
                    const Divider(
                        height: 1, color: AppColors.line, thickness: 1),
                  ],
                );
              },
              childCount: filtered.length + 1,
            ),
          ),
        // 하단 nav 와의 여유 공간.
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

// R86 — 사용자 mandate: 이름/그룹 검색바. 가벼운 한 줄, 키보드 띄우면 자동 스크롤.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool useKo;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.notoSansKr(
          fontSize: 13,
          color: AppColors.ink,
          height: 1.4,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: useKo ? '이름 또는 그룹 검색' : 'Search by name or group',
          hintStyle: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.taupe,
            height: 1.4,
          ),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.taupe),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 28, minHeight: 28),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: const Icon(Icons.close, color: AppColors.taupe),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: AppColors.line, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: AppColors.line, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: AppColors.ink, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  final bool useKo;
  final String query;
  const _EmptySearchResult({required this.useKo, required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      child: Column(
        children: [
          Text(
            useKo
                ? (query.trim().isEmpty
                    ? '조건에 맞는 셀럽이 없어요.'
                    : '"$query" 검색 결과가 없어요.')
                : (query.trim().isEmpty
                    ? 'No celebrities match these filters.'
                    : 'No results for "$query".'),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.inkLight,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            useKo
                ? '필터를 ‘전체’로 바꾸거나 다른 이름으로 검색해 보세요.'
                : 'Try the “All” filter or another name.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: AppColors.taupe,
              height: 1.6,
            ),
          ),
        ],
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

  // R87 sprint 2 — 사용자 mandate: top 1 이 아닌 모든 카드도 공유 가능.
  // 단축 이름 (괄호 제거) + 점수 + 케미 한 줄. share 실패 시 clipboard fallback.
  String _shareText() {
    final name = useKo ? star.nameKo : star.nameEn;
    final shortName = name.contains('(')
        ? name.split('(').first.trim()
        : name;
    return useKo
        ? '내 케미픽: $shortName · $score점'
        : 'My pick: $shortName · $score';
  }

  Future<void> _share(BuildContext context) async {
    final text = _shareText();
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(useKo ? '복사됐어요' : 'Copied'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

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
                // R87 sprint 2 — row-level share button (모든 카드).
                // tap 시 row 전체 onTap (detail) 안 가게 따로 GestureDetector.
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _share(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    key: Key('kpop_row_share_rank_$rank'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.taupe, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ios_share,
                          size: 11,
                          color: AppColors.taupe,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          useKo ? '공유' : 'SHARE',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                            color: AppColors.taupe,
                          ),
                        ),
                      ],
                    ),
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
                // R87 sprint 2 — detail dialog 안에도 share. top 1 외 모든 카드.
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.taupe,
                          minimumSize: const Size(0, 52),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          useKo ? '닫기' : 'CLOSE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 4,
                            color: AppColors.taupe,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 52, color: AppColors.line),
                    Expanded(
                      child: TextButton(
                        key: Key('kpop_detail_share_${star.id}'),
                        onPressed: () => _share(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size(0, 52),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          useKo ? '공유하기' : 'SHARE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // R93 sprint 2 — 진짜 연인 사주 궁합 톤 (사용자 mandate: K-POP 어휘 X / 무대 X / 팬싸 X / 굿즈 X).
  // 본인 일주 vs 셀럽 일주 → 사주 9 anchor 기반 4 paragraph 합성 (300~600 char target).
  //   [1] 첫 인상 (오행 관계 base)
  //   [2] 일상 호흡 (천간합 / 지지합 / 지지충 / 지지형)
  //   [3] 깊어지는 결 (점수 band)
  //   [4] 핵심 한 줄
  String _verdict() {
    if (star.dayPillar.length < 2) return '';
    return _composeVerdict();
  }

  String _composeVerdict() {
    final myGan = me.dayPillar.chunGan;
    final myJi = me.dayPillar.jiJi;
    final stGan = star.dayPillar[0];
    final stJi = star.dayPillar[1];
    final myEl = me.dayPillar.chunGanElement;
    final stEl = _KpopAnchors.elementOf(stGan);
    final sameDay = me.day60ji == star.dayPillar;
    final sameBranch = myJi == stJi;
    final ganHap = _KpopAnchors.ganHap[myGan] == stGan;
    final jiHap6 = _KpopAnchors.jiHap6[myJi] == stJi;
    final jiSamhap =
        (_KpopAnchors.jiSamhapPairs[myJi] ?? const []).contains(stJi);
    final jiClash = _KpopAnchors.ji12clash[myJi] == stJi;
    final jiHyeong =
        (_KpopAnchors.jiHyeong[myJi] ?? const []).contains(stJi);
    final shortName = (useKo ? star.nameKo : star.nameEn).contains('(')
        ? (useKo ? star.nameKo : star.nameEn).split('(').first.trim()
        : (useKo ? star.nameKo : star.nameEn);

    // [1] 첫 인상 (오행 관계)
    final relation = _KpopAnchors.elementRelation(myEl, stEl);
    String p1;
    if (useKo) {
      switch (relation) {
        case _ElRel.same:
          p1 = '$shortName과 너는 같은 오행 결을 타고 났어요. 처음 만났을 때 별 설명 없이도 결이 닿고, 좋아하는 음악·말투·결정 속도가 비슷해서 빠르게 편해지는 사이예요. 단, 결이 같은 만큼 약한 자리도 겹쳐서 한 명이 가라앉으면 같이 가라앉기 쉬워요.';
          break;
        case _ElRel.iGenerate:
          p1 = '$shortName과 너는 너의 기운이 상대를 살리는 상생 관계예요. 너의 한 마디 한 행동이 $shortName한테 깊게 닿고, 상대가 자라는 모습을 보면서 네가 더 단단해지는 결이에요. 천천히 가도 시간이 쌓이면 누구도 못 깨는 인연으로 굳어요.';
          break;
        case _ElRel.theyGenerate:
          p1 = '$shortName이 너를 살리는 상생 관계예요. 상대의 결이 너의 부족한 자리를 자연스럽게 채워줘서 가까이 있을수록 네가 편해지는 사이예요. 너는 받는 쪽이라 표현을 자주 안 해도 상대는 알아주지만, 한 번씩 고마움을 말로 전하면 관계가 한 단계 깊어져요.';
          break;
        case _ElRel.iOvercome:
          p1 = '$shortName과 너는 너의 기운이 상대를 누르는 상극 관계예요. 처음엔 네가 주도하는 자리가 자연스럽고 상대 약점을 정확히 짚어내는 코치 같은 결이에요. 다만 톤이 한 단계만 올라가도 통제처럼 느껴질 수 있어서 의도와 표현의 거리를 늘 의식해야 해요.';
          break;
        case _ElRel.theyOvercome:
          p1 = '$shortName이 너를 누르는 상극 관계예요. 상대 한 마디가 너의 페이스를 흔드는 경우가 종종 있고, 가까워질수록 네가 자기 색을 지키는 연습이 필요한 결이에요. 잘 다루면 둘 다 단단해지지만 그 전에 서로의 톤 차이를 인정하는 게 먼저예요.';
          break;
        case _ElRel.neutral:
          p1 = '$shortName과 너는 자극도 충돌도 크지 않은 결이에요. 첫인상은 잔잔하고 편안하지만, 누군가 적극적으로 신호를 보내지 않으면 자연스럽게 거리가 벌어질 수 있어요. 의식적으로 무게를 만들 때 비로소 깊이가 생기는 인연이에요.';
          break;
      }
    } else {
      switch (relation) {
        case _ElRel.same:
          p1 = "You and $shortName share the same element grain. Comfort comes quickly — taste in music, tone, decision speed all align. The flip side: shared weak spots, so when one dips, the other dips together.";
          break;
        case _ElRel.iGenerate:
          p1 = "You feed $shortName — your energy quietly grows them. Their growth in turn makes you steadier. Slow but durable; the bond hardens over time.";
          break;
        case _ElRel.theyGenerate:
          p1 = "$shortName feeds you. Their grain fills your gaps without effort. You receive more than you give, so showing thanks out loud once in a while deepens the bond.";
          break;
        case _ElRel.iOvercome:
          p1 = "You overcome $shortName — you lead naturally and read their weak spots like a coach. Watch the tone: one notch sharper reads as control. Intent and delivery must match.";
          break;
        case _ElRel.theyOvercome:
          p1 = "$shortName overcomes you. Their one word can shift your pace. The closer you get, the more you must hold your own color. Handle it well and both grow tougher.";
          break;
        case _ElRel.neutral:
          p1 = "Mild interaction — no spark, no clash. The bond drifts unless someone deliberately builds weight into it.";
          break;
      }
    }

    // [2] 일상 호흡 (천간합·지지합·삼합·충·형 + sameDay/sameBranch)
    final p2parts = <String>[];
    if (useKo) {
      if (sameDay) {
        p2parts.add(
            '같은 일주($shortName도 ${me.day60ji})를 타고 났어요. 60갑자 중 같은 자리에서 시작한 사이라 거울 보듯 닮은 면이 많고, 한 사람이 깨달은 건 다른 사람도 곧 깨달아요.');
      } else if (sameBranch) {
        p2parts.add(
            '같은 일지(띠)를 공유해요. 띠가 같으면 인생 리듬·계절감·체질이 비슷해서 함께 있는 시간 자체가 안정적이에요.');
      }
      if (ganHap) {
        p2parts.add(
            '천간 오합($myGan·$stGan)이 맺어진 사이예요. 천간합은 사주에서 가장 강한 끌림 중 하나로, 처음 봤을 때부터 끌리는 자석 같은 결이에요. 다만 합이 강한 만큼 한쪽이 자기 색을 잃기 쉬우니 각자의 페이스를 잊지 않는 게 중요해요.');
      }
      if (jiHap6) {
        p2parts.add(
            '지지 육합($myJi·$stJi)이 있어서 가까워질수록 일상 호흡이 자연스럽게 맞아져요. 같이 살거나 같이 일하는 자리에 잘 어울리는 결이에요.');
      } else if (jiSamhap) {
        p2parts.add(
            '지지 삼합 일부($myJi·$stJi)가 맺어져 있어서 같은 목표를 향해 움직일 때 시너지가 가장 잘 나와요. 함께 프로젝트 하나 만들어가는 자리가 잘 맞아요.');
      }
      if (jiClash) {
        p2parts.add(
            '지지 충($myJi·$stJi)이 있어요. 큰 결정·이사·여행·돈 결정에서 의견이 자주 엇갈리니까 미리 말로 룰을 정해두면 부딪힘이 줄어요. 충이 있는 사이는 한 번 부딪히고 나면 오히려 깊어지는 경우도 많아요.');
      }
      if (jiHyeong) {
        p2parts.add(
            '지지 형($myJi·$stJi)이 걸려 있어요. 한 번씩 강한 한 마디가 오갈 수 있는 결이라, 평소에 작은 인정과 칭찬을 자주 챙겨주면 큰 다툼으로 안 가요.');
      }
      if (p2parts.isEmpty) {
        p2parts.add(
            '천간합·지지합·충·형이 직접 걸려 있지 않아요. 강한 끌림도 강한 부딪힘도 없는, 만남이 시간을 들여야 깊어지는 결이에요.');
      }
    } else {
      if (sameDay) {
        p2parts.add(
            "Same day pillar (${me.day60ji}) — a mirror bond. One person's lesson surfaces in the other soon after.");
      } else if (sameBranch) {
        p2parts.add(
            "Shared day branch (zodiac) — life rhythm, season, constitution all align.");
      }
      if (ganHap) {
        p2parts.add(
            "Heavenly stem union ($myGan·$stGan) — one of the strongest pulls in saju. Magnetic from first sight. Risk: one loses their own color in the union.");
      }
      if (jiHap6) {
        p2parts.add("Six harmony ($myJi·$stJi) — daily breath syncs up. Fits living or working together.");
      } else if (jiSamhap) {
        p2parts.add(
            "Triad partial ($myJi·$stJi) — synergy peaks around shared goals and projects.");
      }
      if (jiClash) {
        p2parts.add(
            "Branch clash ($myJi·$stJi) — friction in big decisions, moves, money. Pre-agree rules. Often deepens after one real clash.");
      }
      if (jiHyeong) {
        p2parts.add(
            "Branch punishment ($myJi·$stJi) — sharp words may surface. Small acknowledgments daily prevent the big blow-up.");
      }
      if (p2parts.isEmpty) {
        p2parts.add(
            "No direct stem-branch union or clash. No strong pull, no strong friction — depth requires time.");
      }
    }
    final p2 = p2parts.join(' ');

    // [3] 깊어지는 결 (점수 band)
    String p3;
    if (useKo) {
      if (score >= 85) {
        p3 = '점수 $score점 — 사주가 권하는 인연이에요. 평생 친구·연인·동료 어느 자리에 두어도 깊어지는 결이라, 만남이 생겼다면 무리하지 말고 천천히 시간을 쌓아도 돼요.';
      } else if (score >= 70) {
        p3 = '점수 $score점 — 사주가 비교적 우호적인 인연이에요. 한쪽이 적극적으로 다가가면 자연스럽게 가까워지고, 좋은 자리에 오래 두기 좋은 결이에요.';
      } else if (score >= 55) {
        p3 = '점수 $score점 — 사주가 강하게 권하지도 막지도 않는 결이에요. 적절한 거리에서 천천히 보다 보면 자기에게 맞는 자리가 자연스럽게 정해져요.';
      } else if (score >= 40) {
        p3 = '점수 $score점 — 사주는 둘 사이에 조심을 권해요. 가까이 두려면 의식적인 거리 조절과 표현이 필요한 결이라, 부담 없는 자리에서 시작하는 게 좋아요.';
      } else {
        p3 = '점수 $score점 — 사주가 깊이 가까이 가는 걸 조심스럽게 보는 결이에요. 가벼운 거리에서 잠깐씩 보는 자리에 잘 맞아요.';
      }
    } else {
      if (score >= 85) {
        p3 = "Score $score — saju recommends this bond. Friend, partner, colleague — it deepens wherever you place it. Take your time.";
      } else if (score >= 70) {
        p3 = "Score $score — saju is broadly favorable. One side moving toward the other closes the distance naturally.";
      } else if (score >= 55) {
        p3 = "Score $score — neither push nor block. Right distance shows itself over time.";
      } else if (score >= 40) {
        p3 = "Score $score — saju advises care. Tone and distance need conscious adjustment. Start light.";
      } else {
        p3 = "Score $score — saju is cautious. Best in light, brief contact.";
      }
    }

    return '$p1\n\n$p2\n\n$p3';
  }

  // Round 77 sprint 7 — discover 모달 prefill query 생성 (compat 화면 prefill).
}

/// R93 sprint 2 — _verdict() 합성용 사주 anchor 상수 + 오행 관계 enum.
enum _ElRel { same, iGenerate, theyGenerate, iOvercome, theyOvercome, neutral }

class _KpopAnchors {
  static const ganHap = {
    '甲': '己', '己': '甲', '乙': '庚', '庚': '乙', '丙': '辛',
    '辛': '丙', '丁': '壬', '壬': '丁', '戊': '癸', '癸': '戊',
  };
  static const jiHap6 = {
    '子': '丑', '丑': '子', '寅': '亥', '亥': '寅', '卯': '戌',
    '戌': '卯', '辰': '酉', '酉': '辰', '巳': '申', '申': '巳',
    '午': '未', '未': '午',
  };
  static const jiSamhapPairs = {
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
  static const ji12clash = {
    '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
    '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
  };
  static const jiHyeong = {
    '寅': ['巳', '申'],
    '巳': ['寅', '申'],
    '申': ['寅', '巳'],
    '丑': ['戌', '未'],
    '戌': ['丑', '未'],
    '未': ['丑', '戌'],
    '子': ['卯'],
    '卯': ['子'],
  };

  static String elementOf(String stem) {
    const map = {
      '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
      '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
    };
    return map[stem] ?? '木';
  }

  static _ElRel elementRelation(String myEl, String stEl) {
    if (myEl == stEl) return _ElRel.same;
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    if (generates[myEl] == stEl) return _ElRel.iGenerate;
    if (generates[stEl] == myEl) return _ElRel.theyGenerate;
    if (overcomes[myEl] == stEl) return _ElRel.iOvercome;
    if (overcomes[stEl] == myEl) return _ElRel.theyOvercome;
    return _ElRel.neutral;
  }
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
