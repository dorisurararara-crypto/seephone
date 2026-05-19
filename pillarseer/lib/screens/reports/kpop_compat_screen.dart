// Pillar Seer — K-POP Compatibility Lab.
import 'package:go_router/go_router.dart';
// 20+ K-POP 스타와 내 사주 궁합을 비교 → 일주 케미 + 오행 공명 점수 + 매니지먼트 인사이트.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
import '../../services/korean_josa.dart';
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
  // R94 sprint 2 — 사용자 mandate verbatim "여자아이돌팬이여서 여자랑 궁합보고
  // 싶을수도있잖아" — gender 자동 reverse 필터 → 사용자 manual selection.
  // null = 사용자 default (반대 성별 — 기존 R82 sprint 9 로직 유지)
  // 'all' = 전체 / 'M' = 남자 / 'F' = 여자
  String? _genderFilterOverride;
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
    BuildContext context,
    SajuResult me,
    dynamic userInfo,
    bool useKo,
  ) {
    // R94 sprint 2 — _genderFilterOverride 가 null 이면 사용자 default (반대 성별
    // — R82 sprint 9 로직 유지), 'all' 이면 모든 셀럽, 'M'/'F' 면 해당 성별만.
    String? effectiveGender;
    if (_genderFilterOverride == 'all') {
      effectiveGender = null; // no filter
    } else if (_genderFilterOverride == 'M' || _genderFilterOverride == 'F') {
      effectiveGender = _genderFilterOverride;
    } else if (userInfo != null) {
      // default = 반대 성별 (R82 sprint 9 외부 review P0 #6 fix 보존).
      final UserGender userOriginalGender = (userInfo is UserBirthInfo)
          ? userInfo.gender
          : UserGender.male;
      if (userOriginalGender == UserGender.male) {
        effectiveGender = 'F';
      } else if (userOriginalGender == UserGender.female) {
        effectiveGender = 'M';
      } else if (userOriginalGender == UserGender.other) {
        // UserGender.other → silent 필터 끔 (사용자 의도 존중, R82 sprint 9 mandate).
        effectiveGender = null;
      }
    }
    // R86 — 사용자 mandate: 이름/그룹명 substring 검색 + 화면 전체 스크롤.
    final query = _query.trim().toLowerCase();
    final filtered =
        _stars
            .where((s) => _filter == 'all' || s.kind == _filter)
            .where(
              (s) =>
                  effectiveGender == null ||
                  s.gender.isEmpty ||
                  s.gender == effectiveGender,
            )
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
        // R94 sprint 2 — gender 필터 chip row (전체/남자/여자).
        SliverToBoxAdapter(
          child: _GenderFilterRow(
            current: _genderFilterOverride ?? '__default__',
            onChanged: (id) => setState(() {
              _genderFilterOverride = id == '__default__' ? null : id;
            }),
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
                  const Divider(height: 1, color: AppColors.line, thickness: 1),
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
            delegate: SliverChildBuilderDelegate((ctx, i) {
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
                  const Divider(height: 1, color: AppColors.line, thickness: 1),
                ],
              );
            }, childCount: filtered.length + 1),
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
    const generates = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    const overcomes = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
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
      '甲': '己',
      '己': '甲',
      '乙': '庚',
      '庚': '乙',
      '丙': '辛',
      '辛': '丙',
      '丁': '壬',
      '壬': '丁',
      '戊': '癸',
      '癸': '戊',
    };
    if (ganHap[myGan] == stGan) base += 6;
    // 지지 육합 (六合)
    const jiHap6 = {
      '子': '丑',
      '丑': '子',
      '寅': '亥',
      '亥': '寅',
      '卯': '戌',
      '戌': '卯',
      '辰': '酉',
      '酉': '辰',
      '巳': '申',
      '申': '巳',
      '午': '未',
      '未': '午',
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
      '子': '午',
      '丑': '未',
      '寅': '申',
      '卯': '酉',
      '辰': '戌',
      '巳': '亥',
      '午': '子',
      '未': '丑',
      '申': '寅',
      '酉': '卯',
      '戌': '辰',
      '亥': '巳',
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
    // R94 sprint 1 — 같은 일주 셀럽이라도 birth year 별 미세 변별
    // (사용자 불만: 같은 일주 7명 모두 92점 동일).
    // birth year ganji 의 연간 (year stem) 와 사용자 일주 천간 사이
    // 5합/극 관계로 ±2~5 점 미세 변동.
    base += _yearMicroAdjust(myGan, star.birth);
    return base.clamp(18, 99);
  }

  /// R94 sprint 1 — birth year stem → 사용자 일주 천간 사이 미세 anchor.
  /// 같은 일주 셀럽 7명이라도 birth year 가 다르면 ±2~5 차이.
  int _yearMicroAdjust(String myGan, String birth) {
    if (birth.length < 4) return 0;
    final year = int.tryParse(birth.substring(0, 4));
    if (year == null) return 0;
    // year ganji: (year - 4) % 10 = stem index (甲=0, 乙=1, ... 癸=9)
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    final stemIdx = (year - 4) % 10;
    if (stemIdx < 0 || stemIdx >= 10) return 0;
    final yearStem = stems[stemIdx];
    int adj = 0;
    // 천간합 (5합) = +3
    const ganHap5 = {
      '甲': '己',
      '己': '甲',
      '乙': '庚',
      '庚': '乙',
      '丙': '辛',
      '辛': '丙',
      '丁': '壬',
      '壬': '丁',
      '戊': '癸',
      '癸': '戊',
    };
    if (ganHap5[myGan] == yearStem) adj += 3;
    // 천간 같음 (비견) = +2
    if (myGan == yearStem) adj += 2;
    // 천간 극 (剋) = -2
    const ganOvercomes = {
      '甲': '戊',
      '乙': '己',
      '丙': '庚',
      '丁': '辛',
      '戊': '壬',
      '己': '癸',
      '庚': '甲',
      '辛': '乙',
      '壬': '丙',
      '癸': '丁',
    };
    if (ganOvercomes[myGan] == yearStem || ganOvercomes[yearStem] == myGan) {
      adj -= 2;
    }
    // birth month (1-12) seed → ±1 미세 마무리
    if (birth.length >= 7) {
      final m = int.tryParse(birth.substring(5, 7)) ?? 0;
      adj += (m % 3) - 1; // -1, 0, +1
    }
    return adj.clamp(-4, 5);
  }

  static String _elementOf(String stem) {
    const map = {
      '甲': '木',
      '乙': '木',
      '丙': '火',
      '丁': '火',
      '戊': '土',
      '己': '土',
      '庚': '金',
      '辛': '金',
      '壬': '水',
      '癸': '水',
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
    final shortName = name.contains('(') ? name.split('(').first.trim() : name;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
        ? const [
            ('all', '전체'),
            ('idol', '아이돌'),
            ('actor', '배우'),
            ('athlete', '운동선수'),
          ]
        : const [
            ('all', 'ALL'),
            ('idol', 'IDOL'),
            ('actor', 'ACTOR'),
            ('athlete', 'ATHLETE'),
          ];
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

// R94 sprint 2 — gender 필터 chip row (사용자 mandate: 전체/남자/여자 manual selection).
class _GenderFilterRow extends StatelessWidget {
  final String current; // '__default__' / 'all' / 'M' / 'F'
  final ValueChanged<String> onChanged;
  final bool useKo;
  const _GenderFilterRow({
    required this.current,
    required this.onChanged,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final items = useKo
        ? const [
            ('__default__', '내 기준'),
            ('all', '전체'),
            ('M', '남자'),
            ('F', '여자'),
          ]
        : const [
            ('__default__', 'MY DEFAULT'),
            ('all', 'ALL'),
            ('M', 'MALE'),
            ('F', 'FEMALE'),
          ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SizedBox(
        height: 42,
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
                margin: const EdgeInsets.only(right: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.accent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  item.$2,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.accent : AppColors.taupe,
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
// R94 sprint 4 — 사용자 mandate verbatim "카리나를 검색하려고 하니 ㅋ 만 치니까
// 검색이 되버리네 커서를 유지하고 있어야지". 한글 IME 자모 조합 중에 매 keystroke
// onChanged 가 발화되어 필터가 즉시 작동 → list 가 reflow 되며 커서가 깨짐.
// 해결: 280ms debounce — 사용자가 타이핑을 잠시 멈춰야 필터 발화.
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool useKo;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.useKo,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      widget.onChanged(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final useKo = widget.useKo;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: TextField(
        controller: controller,
        onChanged: _onTextChanged,
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
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppColors.taupe,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: const Icon(Icons.close, color: AppColors.taupe),
                  onPressed: () {
                    controller.clear();
                    _debounce?.cancel();
                    widget.onChanged('');
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
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
    final shortName = name.contains('(') ? name.split('(').first.trim() : name;
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
                        Icon(Icons.ios_share, size: 11, color: AppColors.taupe),
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
                            borderRadius: BorderRadius.zero,
                          ),
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
                            borderRadius: BorderRadius.zero,
                          ),
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
    final jiSamhap = (_KpopAnchors.jiSamhapPairs[myJi] ?? const []).contains(
      stJi,
    );
    final jiClash = _KpopAnchors.ji12clash[myJi] == stJi;
    final jiHyeong = (_KpopAnchors.jiHyeong[myJi] ?? const []).contains(stJi);
    final shortName = (useKo ? star.nameKo : star.nameEn).contains('(')
        ? (useKo ? star.nameKo : star.nameEn).split('(').first.trim()
        : (useKo ? star.nameKo : star.nameEn);

    // [1] 첫 인상 — R95 sprint 1 + R96 sprint 1 (사용자 mandate verbatim
    // "최애와의 케미가 아직도 다 복사 붙여넣기네 그냥 이름만 다르고 ?"):
    // 같은 오행 관계라도 셀럽 seed 별 variant pool 에서 한 줄 선택 → 같은 user +
    // 같은 일주 셀럽 7명이라도 본문이 서로 달라야 한다.
    final relation = _KpopAnchors.elementRelation(myEl, stEl);
    final identityLead = _starIdentityLead(star, useKo, shortName);
    final strongCount = [
      sameDay,
      ganHap,
      jiHap6,
      jiSamhap,
      sameBranch,
    ].where((b) => b).length;
    final weakCount = [jiClash, jiHyeong].where((b) => b).length;
    final seed = _verdictSeed(
      starId: star.id,
      starDayPillar: star.dayPillar,
      starBirth: star.birth,
      myGan: myGan,
      myJi: myJi,
      stGan: stGan,
      stJi: stJi,
      relation: relation,
      strongCount: strongCount,
      weakCount: weakCount,
    );
    final relationLine = _KpopAnchors.relationVariant(
      relation: relation,
      useKo: useKo,
      seed: seed,
      shortName: shortName,
      myEl: myEl,
      stEl: stEl,
      strongCount: strongCount,
      weakCount: weakCount,
    );
    final p1 = '$identityLead $relationLine';

    // [2] 일상 호흡 — R95 sprint 1: 정확한 천간/지지 쌍 + 셀럽 lead 로 분기별 본문 변별.
    final p2 = _composeDailyBreathDetail(
      myGan: myGan,
      stGan: stGan,
      myJi: myJi,
      stJi: stJi,
      sameDay: sameDay,
      sameBranch: sameBranch,
      ganHap: ganHap,
      jiHap6: jiHap6,
      jiSamhap: jiSamhap,
      jiClash: jiClash,
      jiHyeong: jiHyeong,
      shortName: shortName,
      useKo: useKo,
    );

    // [3] 깊어지는 결 — R95 sprint 1 (사용자 mandate "점수로 매칭하지 말라"):
    // 점수 anchor 를 사주 anchor 강·약 갯수 + band 톤으로 풀어 1 문장 합성.
    final p3 = _composeScoreBandTexture(
      score: score,
      ganHap: ganHap,
      jiHap6: jiHap6,
      jiSamhap: jiSamhap,
      jiClash: jiClash,
      jiHyeong: jiHyeong,
      sameDay: sameDay,
      sameBranch: sameBranch,
      shortName: shortName,
      useKo: useKo,
    );

    // [4] 셀럽 개성 anchor — R96 sprint 1: blurb 본문 + 셀럽 seed 기반 closer
    // variant pool 로 fixed 마무리 한 줄을 폐기 (이전 KO/EN 고정 closer 잔존 0).
    String p4;
    final blurb = useKo ? star.blurbKo : star.blurbEn;
    if (blurb.isNotEmpty) {
      final blurbTail = blurb.length > 120
          ? '${blurb.substring(0, 117)}...'
          : blurb;
      p4 = _KpopAnchors.closerVariant(
        useKo: useKo,
        seed: seed,
        shortName: shortName,
        blurbTail: blurbTail,
        myEl: myEl,
        stEl: stEl,
        strongCount: strongCount,
        weakCount: weakCount,
      );
    } else {
      p4 = '';
    }

    return p4.isEmpty ? '$p1\n\n$p2\n\n$p3' : '$p1\n\n$p2\n\n$p3\n\n$p4';
  }

  // R95 sprint 1 — 첫 문장 셀럽별 변별 lead (사용자 mandate "맨 첫문장이 다 똑같아").
  // shortName + star.dayPillarName + star.birth + star.blurb 의 첫 한 조각으로
  // 1~2 문장 lead 합성. 같은 element-relation 셀럽 7명이라도 lead 가 모두 다르게 됨.
  String _starIdentityLead(_Star star, bool useKo, String shortName) {
    final blurb = useKo ? star.blurbKo : star.blurbEn;
    // blurb 첫 조각 = 첫 문장 (마침표/물음표/느낌표/줄임표/중점 까지) — 너무 길면 자르기.
    String blurbHead = '';
    if (blurb.isNotEmpty) {
      final end = blurb.indexOf(RegExp(r'[\.\!\?。…]'));
      blurbHead = (end > 0 && end < 90)
          ? blurb.substring(0, end + 1).trim()
          : (blurb.length > 80
                ? '${blurb.substring(0, 78).trim()}…'
                : blurb.trim());
    }
    // 생년 4자리 (birth='1991-01-01' 형식).
    final yearStr = (star.birth.length >= 4) ? star.birth.substring(0, 4) : '';
    final pillarName = star.dayPillarName.trim();
    if (useKo) {
      final birthFrag = yearStr.isNotEmpty ? '$yearStr년생' : '';
      final pillarFrag = pillarName.isNotEmpty ? '$pillarName 일주' : '';
      final headFrag = <String>[
        if (pillarFrag.isNotEmpty) pillarFrag,
        if (birthFrag.isNotEmpty) birthFrag,
      ].join(' · ');
      final lead1 = headFrag.isNotEmpty
          ? '$shortName — $headFrag.'
          : '$shortName.';
      final lead2 = blurbHead.isNotEmpty ? ' $blurbHead' : '';
      return '$lead1$lead2';
    } else {
      final birthFrag = yearStr.isNotEmpty ? 'born $yearStr' : '';
      final pillarFrag = pillarName.isNotEmpty ? '$pillarName day pillar' : '';
      final headFrag = <String>[
        if (pillarFrag.isNotEmpty) pillarFrag,
        if (birthFrag.isNotEmpty) birthFrag,
      ].join(' · ');
      final lead1 = headFrag.isNotEmpty
          ? '$shortName — $headFrag.'
          : '$shortName.';
      final lead2 = blurbHead.isNotEmpty ? ' $blurbHead' : '';
      return '$lead1$lead2';
    }
  }

  // R95 sprint 1 — 일상 호흡 본문 helper. 정확한 myGan/stGan, myJi/stJi 쌍과 flag
  // 조합으로 셀럽별 본문 분기 (같은 jiHap6 자축 vs 인해 다른 장면 묘사).
  String _composeDailyBreathDetail({
    required String myGan,
    required String stGan,
    required String myJi,
    required String stJi,
    required bool sameDay,
    required bool sameBranch,
    required bool ganHap,
    required bool jiHap6,
    required bool jiSamhap,
    required bool jiClash,
    required bool jiHyeong,
    required String shortName,
    required bool useKo,
  }) {
    // 지지별 일상 장면 (육합·삼합·충·형 모두 같은 사전 쓰지만 분기별 톤 달라짐).
    const jiSceneKo = {
      '子': '늦은 밤 같이 깨어 있는 자리',
      '丑': '느린 아침과 정리된 책상',
      '寅': '새로 시작하는 첫 발걸음',
      '卯': '봄빛 들어오는 창가의 대화',
      '辰': '큰 그림을 같이 그리는 자리',
      '巳': '뜨거운 한낮의 결정',
      '午': '환한 정오의 약속',
      '未': '오후의 차 한 잔과 정원',
      '申': '동선이 짧은 도시 산책',
      '酉': '저녁 빛 아래 정돈된 자리',
      '戌': '문 닫고 같이 지키는 공간',
      '亥': '밤바다 같은 깊은 대화',
    };
    const jiSceneEn = {
      '子': 'late-night hours awake together',
      '丑': 'slow mornings and tidy desks',
      '寅': 'first steps of something new',
      '卯': 'spring-light window talks',
      '辰': 'mapping the big picture together',
      '巳': 'midday decisions under heat',
      '午': 'bright noon promises',
      '未': 'afternoon tea and gardens',
      '申': 'short-route city walks',
      '酉': 'tidied evenings under amber light',
      '戌': 'a door closed, a space kept together',
      '亥': 'deep night-sea conversations',
    };
    final mySceneKo = jiSceneKo[myJi] ?? '둘만 아는 시간대';
    final stSceneKo = jiSceneKo[stJi] ?? '둘만 아는 시간대';
    final mySceneEn = jiSceneEn[myJi] ?? 'a time only you two know';
    final stSceneEn = jiSceneEn[stJi] ?? 'a time only you two know';
    final parts = <String>[];
    if (useKo) {
      if (sameDay) {
        parts.add(
          '둘 다 ${me.day60ji} 일주라 거울 보는 자리예요. $shortName${withSubj(shortName)} 깨달은 건 너도 곧 깨닫고, 너의 변화도 $shortName한테 빠르게 비쳐요.',
        );
      } else if (sameBranch) {
        parts.add(
          '같은 일지($myJi)를 공유해서 인생 리듬·계절감·체질이 비슷해요. 너의 $mySceneKo${withSubj(mySceneKo)} $shortName한테도 자연스럽게 닿아요.',
        );
      }
      if (ganHap) {
        parts.add(
          '천간 오합 ($myGan-$stGan)이 정확히 맺힌 사이예요. 처음 본 순간부터 자석처럼 끌리는데, 합이 강한 만큼 한쪽이 자기 색을 잃기 쉬워서 각자 페이스를 지키는 약속이 필요해요.',
        );
      }
      if (jiHap6) {
        parts.add(
          '지지 육합 ($myJi-$stJi)이 있어 일상 호흡이 자연스럽게 맞아요. 너의 $mySceneKo${withWith(mySceneKo)} $shortName의 $stSceneKo${withSubj(stSceneKo)} 어느새 한 시간대로 흘러요.',
        );
      } else if (jiSamhap) {
        parts.add(
          '지지 삼합 일부 ($myJi-$stJi)가 맺혀 같은 목표를 향해 움직일 때 시너지가 가장 큰 흐름이에요. $mySceneKo + $stSceneKo = 같이 프로젝트 하나 만들어 가는 자리에 잘 맞아요.',
        );
      }
      if (jiClash) {
        parts.add(
          '지지 충 ($myJi-$stJi)이 걸려 큰 결정·이사·여행·돈 자리에서 의견이 자주 엇갈려요. 너의 $mySceneKo${withWith(mySceneKo)} $shortName의 $stSceneKo${withSubj(stSceneKo)} 정반대 시간대라, 미리 말로 룰을 정해두면 부딪힘이 줄어요.',
        );
      }
      if (jiHyeong) {
        parts.add(
          '지지 형 ($myJi-$stJi)이 걸려 있어 한 번씩 강한 한 마디가 오갈 수 있어요. 평소에 작은 인정·칭찬을 자주 챙겨주면 큰 다툼으로 안 가요.',
        );
      }
      if (parts.isEmpty) {
        parts.add(
          '천간합·지지합·충·형이 직접 걸려 있지 않아요. 너의 $mySceneKo${withWith(mySceneKo)} $shortName의 $stSceneKo${withSubj(stSceneKo)} 자연스럽게 겹치는 순간이 와야 깊어지는 관계라, 시간이 일하는 인연이에요.',
        );
      }
    } else {
      if (sameDay) {
        parts.add(
          "Both ${me.day60ji} day pillar — a mirror seat. What $shortName learns surfaces in you soon, and your changes reflect back fast.",
        );
      } else if (sameBranch) {
        parts.add(
          "Shared day branch ($myJi) — life rhythm, season, constitution all align. Your $mySceneEn reaches $shortName naturally.",
        );
      }
      if (ganHap) {
        parts.add(
          "Heavenly stem union ($myGan-$stGan) — magnetic from first sight. The pull is strong enough that one can lose their own color; an agreed pace matters.",
        );
      }
      if (jiHap6) {
        parts.add(
          "Six harmony ($myJi-$stJi) — daily breath syncs. Your $mySceneEn and $shortName's $stSceneEn drift into one timeline.",
        );
      } else if (jiSamhap) {
        parts.add(
          "Triad partial ($myJi-$stJi) — synergy peaks around shared goals. Your $mySceneEn plus $stSceneEn fits building one project together.",
        );
      }
      if (jiClash) {
        parts.add(
          "Branch clash ($myJi-$stJi) — friction in big decisions, moves, money. Your $mySceneEn versus $shortName's $stSceneEn run on opposite clocks; pre-agree rules.",
        );
      }
      if (jiHyeong) {
        parts.add(
          "Branch punishment ($myJi-$stJi) — sharp words can surface. A short 'thanks' or 'good job' every day keeps the big blow-up away.",
        );
      }
      if (parts.isEmpty) {
        parts.add(
          "No direct stem-branch union or clash. Depth comes only when your $mySceneEn and $shortName's $stSceneEn naturally overlap — time does the work.",
        );
      }
    }
    return parts.join(' ');
  }

  // R95 sprint 1 — 점수 band 텍스처 helper (사용자 mandate "점수로 매칭하지 말라").
  // band base + exact score + anchor 강/약 개수 1 sentence. "점수 N점 —" 시작 금지.
  String _composeScoreBandTexture({
    required int score,
    required bool ganHap,
    required bool jiHap6,
    required bool jiSamhap,
    required bool jiClash,
    required bool jiHyeong,
    required bool sameDay,
    required bool sameBranch,
    required String shortName,
    required bool useKo,
  }) {
    final strong = [
      sameDay,
      ganHap,
      jiHap6,
      jiSamhap,
      sameBranch,
    ].where((b) => b).length;
    final weak = [jiClash, jiHyeong].where((b) => b).length;
    String band;
    if (useKo) {
      if (score >= 85) {
        band = '사주가 권하는 인연 — ';
      } else if (score >= 70) {
        band = '사주가 비교적 우호적으로 보는 흐름 — ';
      } else if (score >= 55) {
        band = '사주가 강하게 권하지도 막지도 않는 흐름 — ';
      } else if (score >= 40) {
        band = '사주가 조심을 권하는 흐름 — ';
      } else {
        band = '사주가 깊이 가까이 가는 걸 조심스럽게 보는 흐름 — ';
      }
      final String anchorLine;
      if (strong + weak == 0) {
        anchorLine =
            '직접 걸린 큰 자극 없이 무게가 옅은 자리라 $shortName${withWith(shortName)}의 시간은 의식적으로 깊이를 만들 때만 자라요.';
      } else {
        final parts = <String>[];
        if (strong > 0) parts.add('강하게 끌어주는 자리 $strong개');
        if (weak > 0) parts.add('조심해야 할 자리 $weak개');
        final anchorSummary = parts.join(' / ');
        anchorLine =
            '$anchorSummary${withSubj(anchorSummary)} 함께 있어서 $shortName${withWith(shortName)}의 시간은 단순한 호감이 아니라 사주 흐름으로 새겨져요.';
      }
      return '$band$anchorLine';
    } else {
      if (score >= 85) {
        band = 'A bond saju recommends — ';
      } else if (score >= 70) {
        band = 'Broadly favorable in the chart — ';
      } else if (score >= 55) {
        band = 'Neither pushed nor blocked by the chart — ';
      } else if (score >= 40) {
        band = 'The chart asks for care here — ';
      } else {
        band = 'The chart is cautious about deep closeness — ';
      }
      final String anchorLine;
      if (strong + weak == 0) {
        anchorLine =
            'no direct anchor holds the weight, so time with $shortName grows only when you build depth on purpose.';
      } else {
        final parts = <String>[];
        if (strong > 0) parts.add('$strong strong');
        if (weak > 0) parts.add('$weak weak');
        final anchorSummary = parts.join(' / ');
        anchorLine =
            '$anchorSummary anchors sit together, so time with $shortName etches in by the chart, not just by feeling.';
      }
      return '$band$anchorLine';
    }
  }

  // Round 77 sprint 7 — discover 모달 prefill query 생성 (compat 화면 prefill).

  /// R96 sprint 1 — verdict variation seed.
  /// 사용자 mandate verbatim: "최애와의 케미가 아직도 다 복사 붙여넣기네 그냥 이름만
  /// 다르고 ?" → 같은 user + 같은 일주 + 같은 relation 셀럽 7명이라도 본문이 서로
  /// 달라야 한다. star.id / dayPillar / birth / 본인 천간·지지 / 셀럽 천간·지지 /
  /// relation index / 강·약 anchor 갯수를 모두 섞어 deterministic 32bit hash 산출.
  int _verdictSeed({
    required String starId,
    required String starDayPillar,
    required String starBirth,
    required String myGan,
    required String myJi,
    required String stGan,
    required String stJi,
    required _ElRel relation,
    required int strongCount,
    required int weakCount,
  }) {
    final src =
        '$starId|$starDayPillar|$starBirth|$myGan$myJi|$stGan$stJi|${relation.index}|$strongCount|$weakCount';
    int h = 0x811c9dc5; // FNV-1a 32bit basis.
    for (var i = 0; i < src.length; i++) {
      h ^= src.codeUnitAt(i);
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}

/// R93 sprint 2 — _verdict() 합성용 사주 anchor 상수 + 오행 관계 enum.
enum _ElRel { same, iGenerate, theyGenerate, iOvercome, theyOvercome, neutral }

class _KpopAnchors {
  static const ganHap = {
    '甲': '己',
    '己': '甲',
    '乙': '庚',
    '庚': '乙',
    '丙': '辛',
    '辛': '丙',
    '丁': '壬',
    '壬': '丁',
    '戊': '癸',
    '癸': '戊',
  };
  static const jiHap6 = {
    '子': '丑',
    '丑': '子',
    '寅': '亥',
    '亥': '寅',
    '卯': '戌',
    '戌': '卯',
    '辰': '酉',
    '酉': '辰',
    '巳': '申',
    '申': '巳',
    '午': '未',
    '未': '午',
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
    '子': '午',
    '丑': '未',
    '寅': '申',
    '卯': '酉',
    '辰': '戌',
    '巳': '亥',
    '午': '子',
    '未': '丑',
    '申': '寅',
    '酉': '卯',
    '戌': '辰',
    '亥': '巳',
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
      '甲': '木',
      '乙': '木',
      '丙': '火',
      '丁': '火',
      '戊': '土',
      '己': '土',
      '庚': '金',
      '辛': '金',
      '壬': '水',
      '癸': '水',
    };
    return map[stem] ?? '木';
  }

  static _ElRel elementRelation(String myEl, String stEl) {
    if (myEl == stEl) return _ElRel.same;
    const generates = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    const overcomes = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
    if (generates[myEl] == stEl) return _ElRel.iGenerate;
    if (generates[stEl] == myEl) return _ElRel.theyGenerate;
    if (overcomes[myEl] == stEl) return _ElRel.iOvercome;
    if (overcomes[stEl] == myEl) return _ElRel.theyOvercome;
    return _ElRel.neutral;
  }

  // R96 sprint 1 — relation variant pool (사용자 mandate verbatim
  // "최애와의 케미가 아직도 다 복사 붙여넣기네 그냥 이름만 다르고 ?").
  // 같은 user + 같은 일주 셀럽 7명이라도 seed (star.id 기반) 가 다르면
  // pool 의 다른 한 줄이 선택돼 본문이 모두 달라진다.
  // 사용자-가시 jargon 정리: '결'/'grain' 사용 X → '성향/흐름/관계' / 'pattern/rhythm/pull'.
  static const _elKo = {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'};
  static const _elEn = {
    '木': 'Wood',
    '火': 'Fire',
    '土': 'Earth',
    '金': 'Metal',
    '水': 'Water',
  };

  static const _relPoolKo = {
    _ElRel.same: [
      '같은 오행끼리라 별 설명 없이 호흡이 닿고, 좋아하는 음악·말투·결정 속도가 비슷해서 빠르게 편해지는 사이예요. 다만 약점도 같이 겹쳐서 한 명이 가라앉으면 같이 가라앉기 쉬워요.',
      '같은 기운이라 첫 만남부터 "어 나랑 비슷하네" 가 먼저 떠올라요. 편한 만큼 새 자극은 적어서, 의식적으로 서로의 새로운 면을 발견하는 시간이 필요해요.',
      '비슷한 성향이 깔려 있어서 침묵이 어색하지 않은 사이예요. 다만 둘 다 약한 자리가 같아서 어려운 결정은 서로한테만 의지하지 말고 바깥 의견을 한 번 더 들이는 게 좋아요.',
      '같은 오행 위에 서 있어서 취향·페이스·심지어 짜증 포인트까지 닮아 있어요. 너무 닮은 만큼 작은 차이가 크게 느껴질 때도 있고, 그걸 인정하는 순간 관계가 한 칸 더 깊어져요.',
      r'같은 오행을 깔고 있어 굳이 설명 안 해도 서로의 모드를 읽어요. $shortName과 너의 컨디션이 같이 오르고 같이 내려가는 거울 같은 사이라, 한 명이 회복 중일 때 다른 한 명이 잠깐 페이스를 잡아주는 약속이 도움돼요.',
      r'기운이 닮아 있어서 처음부터 "낯설지 않다" 가 느껴져요. 익숙함이 빨리 자리잡는 만큼, $shortName이 너 모르는 새 면을 가져올 수 있도록 새로운 자극(여행·취미·낯선 자리)을 같이 시도하는 게 관계의 산소가 돼요.',
      r'같은 오행을 공유하는 위치라 둘 다 비슷한 결정 회로를 돌려요. 그래서 $shortName이 흔들릴 때 너도 같은 방향으로 흔들리기 쉬우니까, 의견이 정확히 같은 순간엔 한 번 더 다른 각도에서 들여다보는 습관이 보호장치가 돼요.',
      r'기운이 같으니 일상 대화 톤이 자연스럽게 맞아 들어가요. $shortName과 너의 페이스가 너무 자연스럽게 묶이는 만큼, 각자 혼자만의 시간을 정기적으로 비워두는 게 오래 가는 관계의 비밀이에요.',
    ],
    _ElRel.iGenerate: [
      r'너의 기운이 상대를 살리는 상생 흐름이라, 너의 한 마디·한 행동이 $shortName한테 깊게 닿아요. 상대가 자라는 모습을 보면서 네가 더 단단해지는 관계예요.',
      r'네가 상대에게 흘려보내는 쪽이라, 평소에는 네가 더 많이 주는 듯해도 시간이 쌓이면 누구도 못 깨는 인연으로 굳어요. 천천히 가는 게 정답인 만남이에요.',
      r'너의 색이 상대를 키우는 위치라, $shortName이 너 앞에서는 평소보다 더 솔직해져요. 받는 쪽에 익숙해질 때쯤 한 번씩 페이스를 점검하면 균형이 오래 가요.',
      r'상생 방향이 너 → 상대로 흐르는 흐름이에요. 네가 별생각 없이 한 말도 $shortName한테는 오래 남고, 그 무게를 의식할 때 관계가 더 건강하게 자라요.',
      r'너의 에너지가 $shortName의 약한 자리를 자연스럽게 데워주는 상생 흐름이에요. 네가 채워주는 만큼 상대가 자기 색을 찾아가니까, 결과가 곧 안 보여도 조급하지 말고 계절 단위로 관계를 봐주세요.',
      r'네가 먼저 빛을 보내는 위치라 $shortName이 너 앞에서 평소보다 더 자신감 있게 행동해요. 다만 네가 지치면 둘 다 같이 가라앉을 수 있어서, 너 자신을 충전하는 시간을 따로 비워두는 게 관계의 기본 체력이에요.',
      r'네가 길을 먼저 닦는 입장이라 $shortName이 따라오는 그림이 자연스러워요. 다만 네 페이스만 보고 가다 보면 상대가 자기 호흡을 잃기 쉬우니까, 가끔은 의도적으로 뒤따라가 보는 연습도 관계에 좋은 균형이 돼요.',
      r'너의 흐름이 상대를 키우는 상생 자리예요. $shortName이 너 앞에서 한 단계씩 성장하는 모습을 보면서, 그 결과만 칭찬하지 말고 과정의 작은 변화도 알아봐 주면 관계가 훨씬 단단해져요.',
    ],
    _ElRel.theyGenerate: [
      r'상대가 너의 부족한 자리를 자연스럽게 채워주는 상생 흐름이에요. 가까이 있을수록 네가 편해지고, 받는 쪽이라 한 번씩 고마움을 말로 전하면 관계가 한 단계 깊어져요.',
      r'너 쪽으로 흘러 들어오는 방향이라 $shortName 옆에 있을 때 너의 에너지가 회복돼요. 받기만 한다는 죄책감 대신, 너만 할 수 있는 방식으로 되돌려주는 연습이 필요해요.',
      r'상대의 기운이 너를 살리는 위치라 어려운 시기에 가장 먼저 찾게 되는 사람이에요. 너무 의존하면 상대가 지칠 수 있어서 받는 쪽에서도 페이스 조절이 필요해요.',
      r'상생 방향이 상대 → 너로 흐르는 흐름이에요. $shortName의 안정감이 너의 흔들림을 잡아주니까, 너도 너만의 방식으로 상대의 약한 자리를 챙겨주는 균형이 답이에요.',
      r'$shortName의 색이 너의 빈자리를 데워주는 자리라, 같이 있는 시간만큼 너의 회복 속도가 빨라져요. 다만 받는 쪽도 의식적으로 상대의 일상을 들여다보는 습관을 들여야 관계가 한쪽으로 기울지 않아요.',
      r'상대의 흐름이 너 쪽으로 영양분처럼 흘러오는 위치예요. $shortName이 별생각 없이 건넨 말이 너한테는 큰 힘이 되는 경우가 많으니까, 그게 당연한 게 아니라는 걸 기억하고 작은 표현이라도 자주 돌려주세요.',
      r'$shortName의 기운이 너의 부족한 자리를 자연스럽게 채워주는 흐름이라, 큰 약속이 없어도 옆에 있는 것만으로 마음이 가벼워져요. 받는 쪽일수록 작은 인정·고마움을 자주 표현하는 게 관계의 가장 큰 자양분이에요.',
      r'너 쪽으로 흐르는 상생 방향이라, $shortName 앞에서는 평소보다 솔직한 너의 모습이 더 잘 나와요. 의지하는 게 자연스러운 만큼, 너만의 영역(취미·일·친구)을 함께 잘 챙겨야 받는 무게가 부담으로 안 변해요.',
    ],
    _ElRel.iOvercome: [
      r'너의 기운이 상대를 누르는 상극 흐름이라, 처음엔 네가 주도하고 상대 약점을 정확히 짚어내는 코치 같은 관계예요. 톤이 한 단계만 올라가도 통제처럼 느껴질 수 있으니 의도와 표현의 거리를 늘 의식해야 해요.',
      r'네가 상대를 누르는 방향이라 짧은 한 마디가 깊게 박혀요. $shortName이 너 앞에서는 평소보다 위축될 수도 있어서, 의식적으로 한 박자 부드럽게 가는 연습이 필요해요.',
      r'주도권이 너 쪽으로 자연스럽게 흐르는 흐름이에요. 잘 쓰면 든든한 멘토 관계지만, 잘못 쓰면 일방적인 지시 관계가 돼버려서 상대가 자기 색을 낼 공간을 늘 비워둬야 해요.',
      r'너의 기운이 상대를 다듬는 위치라 $shortName의 단점이 너 앞에서 더 잘 보여요. 그걸 어떻게 짚느냐가 관계의 미래를 결정해요 — 비판보다는 질문 형식이 잘 통해요.',
      r'네가 $shortName의 흐름을 조이는 위치라, 네가 의식하지 않은 평범한 말 한 줄도 상대한테는 평가처럼 들릴 수 있어요. 칭찬을 의도적으로 두 배 늘리고 지적은 사석에서만 하는 룰만 지켜도 관계 무게가 완전히 달라져요.',
      r'주도권이 자연스럽게 너 쪽으로 모이는 상극 흐름이에요. 네가 끌고 가는 게 편한 만큼 $shortName이 자기 의견을 꺼낼 타이밍을 잃기 쉬우니까, 결정 전에 "어떻게 생각해?" 한 마디를 의식적으로 끼워 넣어주는 게 정답이에요.',
      r'너의 기운이 $shortName을 정돈하는 위치라, 평소엔 든든한 형/언니 같은 존재예요. 다만 상대가 너 한 명한테 맞추는 게 익숙해지면 자기 색이 옅어지니까, 가끔은 $shortName의 결정에 그냥 따라가 보는 시간이 필요해요.',
      r'네가 상대를 다듬는 자리에 서 있으니, 너의 정확함이 $shortName한테는 자극이자 부담이 될 수 있어요. 정답을 알려주기 전에 상대가 스스로 도달할 시간을 주는 게, 멘토 관계와 통제 관계를 가르는 결정적 차이예요.',
    ],
    _ElRel.theyOvercome: [
      r'오히려 상대가 너의 페이스를 흔드는 상극 흐름이에요. 가까워질수록 네가 자기 색을 지키는 연습이 필요한 관계라, 잘 다루면 둘 다 단단해지지만 그 전에 서로의 톤 차이를 인정하는 게 먼저예요.',
      r'상대의 기운이 너를 흔드는 방향이라 $shortName 말 한 마디에 평소보다 크게 반응할 수 있어요. 그게 약점이 아니라 상대가 너의 일상에서 그만큼 큰 자리를 차지한다는 신호로 읽으면 다루기 쉬워져요.',
      r'주도권이 상대 쪽으로 자연스럽게 기우는 흐름이에요. 무조건 맞춰주기보다, 네가 흔들리지 않는 한두 가지 기준을 분명히 가져가야 관계가 오래 가요.',
      r'너 쪽에 자극을 주는 위치라 처음엔 불편할 수 있어요. 그 불편을 회피하지 않고 마주할 때 너의 약한 자리가 단단해지는, 성장형 관계예요.',
      r'$shortName의 톤이 너의 평소 속도를 살짝 흔드는 위치라, 가까워질수록 "내가 흔들리고 있다" 는 자각이 자주 와요. 그 자각을 무시하지 말고 작은 휴식·거리두기로 풀어주면 자극이 성장으로 바뀌어요.',
      r'상대의 자리가 너의 약점을 정확히 비추는 흐름이에요. 처음엔 방어가 먼저 올라오지만, $shortName 앞에서 약점을 인정하는 연습을 거치면 너의 한 단계 다음 버전이 만들어지는, 묘하게 고마운 관계가 돼요.',
      r'$shortName이 너의 속도를 의도치 않게 흔들어 놓는 자리예요. 그 흔들림에 휘둘리지 말고, 너만의 루틴(아침·운동·수면 같은 기본) 한두 개를 단단히 잡고 가면 상대의 자극이 너의 새 에너지로 바뀌어요.',
      r'상대가 너를 약하게 흔드는 위치이지만, 그게 너의 약점을 잡아주는 코치 같은 자극이기도 해요. $shortName의 직설을 비판이 아니라 거울로 받아들이는 순간, 가장 빠르게 성장하는 관계가 돼요.',
    ],
    _ElRel.neutral: [
      '오행상 자극도 충돌도 크지 않아 첫인상은 잔잔하고 편안해요. 누군가 적극적으로 신호를 보내지 않으면 자연스럽게 거리가 벌어질 수 있어서, 의식적으로 무게를 만들 때 비로소 깊이가 생기는 관계예요.',
      '서로 직접 살리지도 누르지도 않는 자리라, 운명적이라기보다 같이 만들어가는 인연에 가까워요. 약속·만남·연락 같은 작은 의식이 관계의 뼈대가 돼요.',
      '안정적이지만 자극은 적은 흐름이라, "있으면 좋고 없어도 그럭저럭" 으로 끝날 수도 있어요. 한 사람이 먼저 두 발 다가가는 순간 관계가 비로소 자라요.',
      '서로의 기운이 평행선처럼 흘러서 큰 충돌 없이 오래 갈 수 있는 사이예요. 다만 평행선이라 깊이는 시간이 만들어주는 거니까, 짧게 보지 말고 길게 같이 가는 게 정답이에요.',
      r'$shortName과 너 사이엔 큰 끌림도 큰 마찰도 없어서 첫 인상이 잔잔하게 지나갈 수 있어요. 평범한 자리에 작은 추억·반복되는 약속을 한 켜씩 쌓아갈 때 비로소 둘만의 무게가 생기는 관계예요.',
      r'오행상 직접 신호가 약한 자리라 자연스레 스쳐 지나가기 쉬운 흐름이에요. 누구 한 명이 먼저 "다음에 또 보자" 를 명확히 약속하지 않으면 인연이 옅어지니까, 의식적인 한 박자가 관계의 시작 신호예요.',
      '운명적인 끌림보다 "선택해서 만들어 가는" 색이 강한 자리예요. 약속·연락·기념일 같은 작은 의식이 둘만의 뼈대를 만드니까, 자연스럽게 흘러가게 두기보다 의식적으로 한 박자씩 깊이를 더해주세요.',
      '큰 자극이 없는 만큼 가까워지는 속도가 천천히이고, 한 번 자리잡으면 오래 가는 흐름이에요. 짧은 시간 안에 결과를 보려 하지 말고, 1년·2년 단위로 관계의 두께를 늘려가는 시야가 답이에요.',
    ],
  };

  static const _relPoolEn = {
    _ElRel.same: [
      r"Same element overall — taste, tone, decision speed align without explaining. The flip side: shared weak spots, so when one dips, the other dips together.",
      r"Matching energy, so the first conversation already feels familiar. Comfort is high, novelty is low; you'll need to surface new sides of each other on purpose.",
      r"Similar pattern underneath — silence isn't awkward. Because your weak spots overlap too, big decisions benefit from one outside opinion before you commit.",
      r"Standing on the same element — even the things that annoy you tend to be the same. Small differences can feel larger; naming them keeps the bond healthy.",
      r"Same element base — you read $shortName's mood without asking. The mirror effect runs both ways though, so when one of you wobbles, the other tilts with it. A small recovery ritual helps.",
      r"Same energy line, so the relationship moves at one tempo. Familiar fast, novel rarely — schedule new contexts (travel, hobbies, strangers' tables) on purpose so the bond doesn't go static.",
      r"Sharing the same element means you run similar decision circuits. When $shortName wavers, you tend to waver in the same direction — when your opinions line up exactly, take one more look from a different angle as a safety net.",
      r"Same energy, so daily conversation tones lock in naturally. Because your paces tie together so easily, scheduling regular solo time for each of you is the secret to a bond that lasts.",
    ],
    _ElRel.iGenerate: [
      r"You feed them (producing flow). What you say lands deep with $shortName, and watching them grow steadies you in return.",
      r"You're the giving side here. Day to day it can feel uneven, but the bond hardens over time into something hard to break. Slow is the right pace.",
      r"Your color quietly grows theirs, so $shortName tends to be more honest around you than around most people. Once you settle into giving, check your own pace.",
      r"The producing arrow runs from you to them. Words you toss off stay with $shortName a long time — own that weight and the bond grows healthier.",
      r"You quietly warm $shortName's weak spots. The change isn't visible day to day; read this bond in seasons, not weeks, and keep going even when the shift looks slow.",
      r"You give light first, so $shortName carries more confidence near you than alone. Save real recharge time for yourself — your battery is the bond's baseline.",
      r"You pave the road first, so $shortName following naturally feels right. Watching only your own pace, though, costs them their breath; practicing the reverse — letting them lead sometimes — keeps it balanced.",
      r"You feed their growth in a clear producing flow. As $shortName steps up around you, name not just the results but the small process shifts — that's where the bond hardens.",
    ],
    _ElRel.theyGenerate: [
      r"They fill the gaps in yours without effort (producing flow toward you). You receive more than you give, so naming the gratitude out loud deepens the bond.",
      r"Energy flows toward you here — being near $shortName restores yours. Instead of feeling guilty about receiving, return it in your own way.",
      r"Their pattern lifts you, so they're the first person you call when things get hard. Don't lean so far that they tire out; pace the receiving too.",
      r"The producing arrow runs from them to you. $shortName's steadiness holds your wobble — balance it by quietly covering one of their weak spots.",
      r"$shortName's color warms the empty seats in yours, so recovery speeds up just by being near. Get into the habit of checking on their day too — the bond stays level only if you watch the giver as well.",
      r"Their current flows toward you like nutrients. Casual words from $shortName often land as fuel for you, so remember it isn't given for free and send small returns back often.",
      r"$shortName's energy fills the gaps in yours so easily that just being near lightens your mind, even without big plans. The receiving side has to over-express small thanks — that's the richest fuel for this kind of bond.",
      r"A producing arrow runs your way, so your honest self shows up more easily around $shortName. Leaning is natural, but keeping your own ground (hobby, work, friends) makes sure the receiving never turns into a burden.",
    ],
    _ElRel.iOvercome: [
      r"You control them (overcoming flow). You lead naturally and read their weak spots like a coach. One notch sharper reads as control — intent and delivery must match.",
      r"You overcome them, so short words land hard. $shortName may shrink around you without meaning to; building in a softer beat keeps it healthy.",
      r"Leadership drifts to your side naturally. Used well it's a mentor bond; used badly it becomes one-way instruction. Always leave room for their own color.",
      r"You refine them, so $shortName's flaws show clearly when you're close. How you point them out decides everything — questions land better than verdicts.",
      r"You compress $shortName's flow without meaning to, so even a flat-toned sentence can read as a verdict. Double your visible praise and keep corrections private — that one rule reshapes the whole weight of the bond.",
      r'''Leadership lands on your side by default. It's easier to drive than to wait, but $shortName loses chances to speak first; build a deliberate "what do you think?" beat in before every decision.''',
      r"You keep $shortName tidied up, so on most days you read as the steady older one. But when they keep adjusting to you, their own color fades — practice just following their lead from time to time.",
      r"You're the one refining them, so your precision can land as both fuel and pressure on $shortName. Letting them reach the answer themselves, instead of handing it over, is the line between mentor and controller.",
    ],
    _ElRel.theyOvercome: [
      r"Their energy shifts your pace (overcoming flow toward you). The closer you get, the more you must hold your own color. Handle it well and both grow tougher.",
      r"They overcome you, so a single sentence from $shortName can spike you. Read that as a sign of how much they matter — not as a weakness in you.",
      r"Leadership drifts toward them. Don't just match; hold one or two non-negotiables so the relationship lasts past the early pull.",
      r"They challenge you by default. Facing that discomfort instead of dodging it is where your weak spot turns into strength — a growth-style bond.",
      r'''$shortName's tone tilts your normal pace, so the closer you get the more often you'll notice "I'm being shaken." Honor that signal with short rest and brief distance — friction turns into growth once it's named.''',
      r'''Their seat mirrors your weak spots with precision. Defense rises first, but practicing honest "yes, that's me" responses around $shortName forges your next-level self — a quietly grateful bond.''',
      r"$shortName nudges your speed without meaning to. Don't get swept along — anchor one or two daily basics (morning, exercise, sleep) and their pressure converts into your new energy.",
      r"They shake you a little, but it's also the kind of jolt that exposes your weak spots like a coach would. The moment you receive $shortName's bluntness as a mirror rather than a verdict, the relationship becomes your fastest growth engine.",
    ],
    _ElRel.neutral: [
      r"Mild interaction with yours — no spark, no clash. The bond drifts unless someone deliberately builds weight into it.",
      r"Neither producing nor overcoming directly, so this is less fated and more built. Small rituals — meetings, replies, plans — become the skeleton of the bond.",
      r"Stable but low-stimulation, so it can settle at 'nice to have, fine without.' Depth shows up only after one of you takes the first two steps in.",
      r"Energies run parallel — easy to last a long time without big clashes. But parallel means depth is on the clock; play the long game, not the short one.",
      r"Between you and $shortName there's neither strong pull nor heavy friction, so first impressions pass softly. Stack small memories and repeated promises one layer at a time — that's how weight forms.",
      r'''Direct elemental signal is weak here, so the bond drifts off if no one names the next step. A clear "let's meet again on X" from one side is what turns this from passing into staying.''',
      r"More chosen than fated, this is a relationship you build with intention. Small rituals — promises, replies, anniversaries — form the skeleton, so deliberately add a beat of depth instead of letting it drift on its own.",
      r"With no big stimulus, closeness comes slowly here — but once it sets, it lasts. Don't try to read the result in weeks; widen the lens to a year or two, and the bond steadily thickens.",
    ],
  };

  static const _closerPoolKo = [
    r'$shortName — $blurbTail 이 성향이 너의 일상에 한 자락 더해질 때, 두 사람만의 호흡이 생겨요.',
    r'$shortName의 한 줄 — $blurbTail 이 흐름이 너의 일주와 맞닿는 지점이 바로 너희만의 관계 색이에요.',
    r'$shortName — $blurbTail 이 분위기가 너의 페이스에 섞일 때, 평범한 하루가 좀 다르게 느껴져요.',
    r'$shortName의 색 — $blurbTail 너의 일주가 이 색을 어떻게 받아들이느냐가 둘 사이를 결정해요.',
    r'$shortName — $blurbTail 너의 일상에 이 한 조각이 더해지는 순간, 둘만의 톤이 만들어져요.',
  ];

  static const _closerPoolEn = [
    r"$shortName — $blurbTail When this pattern layers into your daily rhythm, the two of you find your own beat.",
    r"$shortName, in one line — $blurbTail Where this rhythm meets your chart is where your shared color shows up.",
    r"$shortName — $blurbTail When this mood mixes into your pace, ordinary days start to feel a little different.",
    r"$shortName's color — $blurbTail How your chart receives it decides what the two of you become.",
    r"$shortName — $blurbTail Add this single piece to your daily flow and a tone only the two of you have starts forming.",
  ];

  static String relationVariant({
    required _ElRel relation,
    required bool useKo,
    required int seed,
    required String shortName,
    required String myEl,
    required String stEl,
    required int strongCount,
    required int weakCount,
  }) {
    final pool = (useKo ? _relPoolKo : _relPoolEn)[relation] ?? const [];
    if (pool.isEmpty) return '';
    // R97 codex rework 3 — pool 6→8 확장 (사용자 mandate "같은 일주 6 셀럽 모두 unique").
    // 8 항목으로 늘려 collision rate 가 큰 폭으로 감소. 동일 일주 셀럽이 8 명을 넘어가는
    // 극단 케이스에서도 p1 의 _starIdentityLead (star.id / dayPillarName / birth 기반)
    // + p2/p3/p4 의 셀럽별 변별이 본문 unique 성을 끝까지 보장한다.
    final idx = seed % pool.length;
    var line = pool[idx];
    line = _injectShortName(line, shortName);
    // 강·약 anchor 갯수에 따른 1 절 micro-tail (같은 pool index 라도 anchor 조합이
    // 다르면 마지막 한 절이 달라져 본문이 더 갈라진다).
    final myElName =
        (useKo ? _elKo[myEl] : _elEn[myEl]) ?? (useKo ? '오행' : 'element');
    final stElName =
        (useKo ? _elKo[stEl] : _elEn[stEl]) ?? (useKo ? '오행' : 'element');
    String tail;
    if (useKo) {
      if (strongCount >= 2) {
        tail =
            ' 강하게 끌어주는 자리가 $strongCount개 겹쳐 $myElName↔$stElName 사이의 끌림이 평균보다 또렷해요.';
      } else if (weakCount >= 1) {
        tail = ' 조심해야 할 자리가 $weakCount개 걸려 있어 같은 흐름 안에서도 부딪힘 자리가 살짝 보여요.';
      } else if (strongCount == 1) {
        tail = ' 끌어주는 자리 한 줄이 받쳐주고 있어 $myElName↔$stElName 흐름이 자연스럽게 잡혀요.';
      } else {
        tail = ' 직접 걸린 큰 자극 없이 $myElName↔$stElName 자체의 거리감이 그대로 드러나요.';
      }
    } else {
      if (strongCount >= 2) {
        tail =
            ' $strongCount strong anchors stack here, so the $myElName↔$stElName pull reads sharper than average.';
      } else if (weakCount >= 1) {
        tail =
            ' $weakCount weak anchor sits in the mix, so even inside one rhythm there are visible friction points.';
      } else if (strongCount == 1) {
        tail =
            ' One anchor underwrites it, keeping the $myElName↔$stElName flow naturally settled.';
      } else {
        tail =
            ' No direct anchor — the raw distance between $myElName and $stElName shows through.';
      }
    }
    return '$line$tail';
  }

  static String closerVariant({
    required bool useKo,
    required int seed,
    required String shortName,
    required String blurbTail,
    required String myEl,
    required String stEl,
    required int strongCount,
    required int weakCount,
  }) {
    final pool = useKo ? _closerPoolKo : _closerPoolEn;
    // seed shift — relation pool 과 같은 index 가 나오지 않도록 13 회전.
    final idx = ((seed >> 5) + 13) % pool.length;
    var line = pool[idx];
    line = _injectShortName(line, shortName);
    line = line.replaceAll(r'$blurbTail', blurbTail);
    return line;
  }

  // R98 sprint 1 — shortName placeholder + 인접 조사 한 번에 보정.
  // raw string pool 안의 `$shortName과 / $shortName이 / $shortName을 / $shortName은`
  // 등이 받침 없는 셀럽 이름(예: 미나)일 때 `미나과` 어색 발생 — withWith/withSubj/
  // withObj/withTop helper 로 보정해서 placeholder 치환과 동시에 조사가 자연스럽게
  // 붙도록 한다. 영어 raw pool 도 동일 패턴을 가지지만 영어에서는 조사 보정 불필요라
  // 단순 치환만 수행한다.
  static String _injectShortName(String line, String shortName) {
    // 1) 한국어 조사 결합 placeholder 4 쌍 우선 매칭 (먼저 처리해야 일반 치환과
    //    충돌 안 함).
    final particleMap = <String, String Function(String)>{
      r'$shortName과': withWith, // 과/와
      r'$shortName와': withWith,
      r'$shortName이': withSubj, // 이/가
      r'$shortName가': withSubj,
      r'$shortName은': withTop, // 은/는
      r'$shortName는': withTop,
      r'$shortName을': withObj, // 을/를
      r'$shortName를': withObj,
    };
    var result = line;
    particleMap.forEach((placeholder, picker) {
      if (result.contains(placeholder)) {
        result = result.replaceAll(placeholder, '$shortName${picker(shortName)}');
      }
    });
    // 2) 남은 일반 placeholder (조사 없는 형태) 단순 치환.
    result = result.replaceAll(r'$shortName', shortName);
    return result;
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
      '甲': _wood,
      '乙': _wood,
      '丙': _fire,
      '丁': _fire,
      '戊': _earth,
      '己': _earth,
      '庚': _metal,
      '辛': _metal,
      '壬': _water,
      '癸': _water,
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
    Widget bar({double width = 60, double height = 12}) =>
        Container(width: width, height: height, color: _grey);
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
                ? '점수는 다섯 가지 기운(나무·불·흙·쇠·물)이 서로 살리는지, 같은 성향인지, 잘 어울리는 띠인지, 부딪히는 띠인지를 종합해서 계산해요. 셀럽의 정확한 태어난 시간은 알 수 없어서 태어난 날짜 기준으로만 비교하는데, 시간까지 알면 점수가 더 정확해집니다.'
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
