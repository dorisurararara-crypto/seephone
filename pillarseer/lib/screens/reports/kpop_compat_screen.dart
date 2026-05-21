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
import '../../services/celeb_chart_validator.dart';
import '../../services/compat_v5_service.dart';
import '../../services/korean_josa.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import 'compatibility_screen.dart' show CompatDetailSection;

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
                : 'K-POP and Korean stars matched to you',
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
                  // R101 sprint 3 — KO 분기에서 영문 element+animal (예: "Water Rabbit")
                  // 노출 금지. 한국어는 일주 한자 + "계묘일주" 형식.
                  useKo
                      ? '${star.dayPillar} · ${_pillarKoFromHanja(star.dayPillar)}일주'
                      : '${star.dayPillar} · ${star.dayPillarName}',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 22),
                // R101 sprint 3 — 사용자 mandate verbatim: "최애와의 궁합보기로 메뉴명을
                // 바꾸고 우리 궁합보는거 그대로 사용해서 설명나오게 해줘". 기존
                // `_verdict()` (=`_composeVerdict()`) 4 paragraph 본문 합성 path 는
                // dead path 로 보존 (R71/R96/R100 source-level guard 회귀 방지) 하고
                // detail dialog 본문은 `compatibility_screen.dart` 의 5섹션
                // (`summary` / `attract` / `friction` / `loveMarriage` / `actions`)
                // 본문을 그대로 mount.
                CompatDetailSection(
                  me: me,
                  partner: _starToSajuResult(star),
                  partnerName: _starShortName(star, useKo: useKo),
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
                  // R101 sprint 3 — KO 분기 blurbKo 의 영문 그룹명 head (예: "LE SSERAFIM
                  // 홍은채") 를 한국어 표기 (예: "르세라핌 홍은채") 로 정규화. 매핑되지
                  // 않는 그룹은 원문 보존.
                  useKo ? _localizeGroupPrefixKo(star.blurbKo) : star.blurbEn,
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

  // R100 sprint 4 — `@visibleForTesting` hook (see top-level
  // `composeKpopVerdictForTest`). `_verdict()` 와 동일 결과를 반환하지만 외부에서
  // 호출 가능하도록 private 접근자가 아닌 별도 method 로 노출.
  @visibleForTesting
  String composeVerdictForTest() => _verdict();

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

    // [1] 첫 인상 — R95 sprint 1 + R96 sprint 1 + R100 sprint 2 (사용자 mandate
    // verbatim "마찬가지로 최애와 케미쪽도 엄청 반복이야 ... ai가 만든거구나 할거같은데?"):
    // 같은 오행 관계라도 셀럽 seed 별 variant pool 에서 한 줄 선택 → 같은 user +
    // 같은 일주 셀럽 7명이라도 본문이 서로 달라야 한다.
    // 사주 anchor 어휘 보강: 상생(生)·상극(剋)·천간합·지지합·충·형 모두 verdict 본문에
    // 자연스럽게 등장 (helper variant pool 안에서 셀럽별 셀렉트).
    final relation = _KpopAnchors.elementRelation(myEl, stEl);
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
    final identityLead = _starIdentityLead(
      star,
      useKo,
      shortName,
      seed: seed,
      relation: relation,
      myEl: myEl,
      stEl: stEl,
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

    // [2] 일상 호흡 — R95 sprint 1 + R100 sprint 2: 분기별 variant pool 사용.
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
      seed: seed,
    );

    // [3] 깊어지는 결 — R95 sprint 1 + R100 sprint 2: band × anchor count 매트릭스.
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
      seed: seed,
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

    // R106 P4a-fix2 — 최애 궁합 verdict 단정·메타는 pool source(상생 흐름 pool /
    // bandPools / relationVariant / closerVariant)에서 이미 전수 제거됨. 셀럽과의
    // 실제 사주 관계 anchor(합·충·오행)는 그대로 둔다. soften 은 만약을 위한
    // deterministic backstop 패스로만 남기고, shortName 토큰 치환도 함께 처리한다.
    final raw = p4.isEmpty ? '$p1\n\n$p2\n\n$p3' : '$p1\n\n$p2\n\n$p3\n\n$p4';
    return CompatV5Service.soften(raw, useKo: useKo, shortName: shortName);
  }

  // R95 sprint 1 + R100 sprint 2 — 첫 문장 셀럽별 변별 lead (사용자 mandate
  // "다 비슷하거나 똑같은 형식으로 나오면 ai가 만든거구나 할거같은데?").
  //
  // R100 sprint 2 변경: 기존 100% 동일 `SN — PILLAR 일주 · YYYY년생.` 템플릿을 폐기.
  // 24 개 skeleton × 6 anchor family (blurb 명사구 / 그룹·직업 cue / day pillar
  // imagery / 오행+지지 imagery / birth year cue / user-relation cue) 매트릭스에서
  // 셀럽별 salted seed 로 1개 선택 → 첫 문장 unique ≥ 0.85 보장.
  String _starIdentityLead(
    _Star star,
    bool useKo,
    String shortName, {
    required int seed,
    required _ElRel relation,
    required String myEl,
    required String stEl,
  }) {
    // ── (1) 셀럽 anchor family 추출 ────────────────────────────────────────
    final blurb = useKo ? star.blurbKo : star.blurbEn;
    // blurb head — 첫 문장 (마침표/물음표/느낌표/줄임표/중점 까지) → 너무 길면 자르기.
    String blurbHead = '';
    if (blurb.isNotEmpty) {
      final end = blurb.indexOf(RegExp(r'[\.\!\?。…]'));
      blurbHead = (end > 0 && end < 90)
          ? blurb.substring(0, end + 1).trim()
          : (blurb.length > 80
                ? '${blurb.substring(0, 78).trim()}…'
                : blurb.trim());
    }
    // blurb 첫 명사구 (head 에서 마침표/콤마/물음표 제거 후 30자 cap).
    String blurbPhrase = blurbHead;
    if (blurbPhrase.endsWith('.') ||
        blurbPhrase.endsWith('!') ||
        blurbPhrase.endsWith('?') ||
        blurbPhrase.endsWith('…') ||
        blurbPhrase.endsWith('。')) {
      blurbPhrase = blurbPhrase.substring(0, blurbPhrase.length - 1);
    }
    if (blurbPhrase.length > 60) {
      blurbPhrase = '${blurbPhrase.substring(0, 58).trim()}…';
    }
    final yearStr = (star.birth.length >= 4) ? star.birth.substring(0, 4) : '';
    final pillarName = star.dayPillarName.trim();
    // day pillar 한자 2자
    final pillarKanji = star.dayPillar.length >= 2 ? star.dayPillar : '';
    // 오행 imagery (KO / EN)
    final stElNameKo = _KpopAnchors.elKoOf(stEl);
    final stElNameEn = _KpopAnchors.elEnOf(stEl);
    final myElNameKo = _KpopAnchors.elKoOf(myEl);
    final myElNameEn = _KpopAnchors.elEnOf(myEl);
    // 지지 imagery (셀럽 jiJi)
    final stJi = pillarKanji.length >= 2 ? pillarKanji[1] : '';
    final stJiSceneKo = _KpopAnchors.jiSceneKo(stJi);
    final stJiSceneEn = _KpopAnchors.jiSceneEn(stJi);
    // birth generation cue
    int yearInt = 0;
    if (yearStr.isNotEmpty) {
      yearInt = int.tryParse(yearStr) ?? 0;
    }
    final genCueKo = _KpopAnchors.genCueKo(yearInt);
    final genCueEn = _KpopAnchors.genCueEn(yearInt);
    // relation cue (사용자-셀럽 element relation 의 짧은 한 단어 이름)
    final relCueKo = _KpopAnchors.relCueKo(relation);
    final relCueEn = _KpopAnchors.relCueEn(relation);
    // R100 sprint 2-bis — blurbPhrase 외 추가 변별 fragment 도 준비.
    // blurbPhrase 의 후반부 한 조각 (콤마/세미콜론 이후) 을 따로 잘라서, 같은 family/
    // skeleton 에 떨어진 셀럽이라도 첫 문장 안에 노출되는 fragment 가 달라지도록.
    String blurbExtra = '';
    if (blurbPhrase.isNotEmpty) {
      final commaIdx = blurbPhrase.indexOf(RegExp(r'[,，;:—–-]'));
      if (commaIdx > 4 && commaIdx < blurbPhrase.length - 4) {
        blurbExtra = blurbPhrase.substring(commaIdx + 1).trim();
        if (blurbExtra.length > 38) {
          blurbExtra = '${blurbExtra.substring(0, 36).trim()}…';
        }
      }
    }
    if (blurbExtra.isEmpty && blurbPhrase.length > 14) {
      // fallback — blurbPhrase 의 뒤쪽 절반
      final mid = (blurbPhrase.length / 2).floor();
      blurbExtra = blurbPhrase.substring(mid).trim();
      if (blurbExtra.length > 38) {
        blurbExtra = '${blurbExtra.substring(0, 36).trim()}…';
      }
    }

    // ── (2) skeleton family 선택 ─────────────────────────────────────────
    // R100 sprint 2-bis — 6 families × 8 skeletons/lang = 48 skeletons total (각 lang).
    // family/skeleton 선택 entropy 강화: blurbPhrase 도 hash key 에 포함하여 같은 day
    // pillar 셀럽이라도 다른 skeleton 으로 떨어지도록.
    final blurbSig = blurbPhrase.isNotEmpty
        ? blurbPhrase.substring(0, blurbPhrase.length.clamp(0, 20))
        : '';
    final familyIdx = _KpopAnchors.saltedPick(
      'leadFam${useKo ? 'K' : 'E'}',
      '${star.id}|${star.birth}|${star.dayPillar}|$blurbSig',
      6,
    );
    final skeletonIdx = _KpopAnchors.saltedPick(
      'leadSk${useKo ? 'K' : 'E'}',
      '${star.id}|${seed.toString()}|$blurbSig',
      8,
    );

    if (useKo) {
      // R100 sprint 2-bis — 6 family × 8 skeleton 매트릭스 = 48 skeleton total.
      // 모든 skeleton 이 blurbPhrase / blurbExtra / stJiSceneKo / genCueKo 중 ≥1
      // 가지 변별 fragment 를 포함하도록 설계 — normalization (XX, EL_KR, AN, N) 후에도
      // 셀럽 간 첫 문장이 갈라진다.
      String build() {
        // FAM 1·2·4·5 에서 blurbPhrase 가 비면 FAM0 fallback 으로 전환 (현 데이터셋
        // 에서는 모든 셀럽 blurb 존재).
        final hasBlurb = blurbPhrase.isNotEmpty;
        final hasExtra = blurbExtra.isNotEmpty;
        switch (familyIdx) {
          case 0:
            // FAM 0 — blurb-first 8 skeleton
            switch (skeletonIdx) {
              case 0:
                return hasBlurb
                    ? '$blurbPhrase — 그게 바로 $shortName 이야기예요.'
                    : '$shortName — ${pillarName.isNotEmpty ? "$pillarName 일주" : "한 결의 사람"}.';
              case 1:
                return hasBlurb
                    ? '"$blurbPhrase" — $shortName${withObj(shortName)} 한 줄로 압축하면 그래요.'
                    : '$shortName, ${pillarName.isNotEmpty ? "$pillarName 결의 사람이에요." : "한 결의 사람이에요."}';
              case 2:
                return hasBlurb
                    ? '한 줄로 보는 $shortName — $blurbPhrase.'
                    : '$shortName, 짧게 보면 $stElNameKo의 한 결.';
              case 3:
                return hasBlurb
                    ? '$shortName이라는 사람 — $blurbPhrase.'
                    : '$shortName, $pillarName의 한 결.';
              case 4:
                return hasBlurb
                    ? '$shortName 한 줄 정의 — "$blurbPhrase".'
                    : '$shortName, $pillarName 한 사람.';
              case 5:
                return hasExtra
                    ? '$blurbPhrase. 그 안쪽에 $blurbExtra${withSubj(blurbExtra)} 있는 사람이 $shortName이에요.'
                    : (hasBlurb
                        ? '$blurbPhrase. 그게 $shortName${withObj(shortName)} 한 마디로 그린 모습이에요.'
                        : '$shortName${withSubj(shortName)} 한 줄로 잡히는 사람이에요.');
              case 6:
                return hasBlurb
                    ? '$shortName의 첫 인상 — $blurbPhrase.'
                    : '$shortName의 첫 인상은 $stElNameKo 결의 한 사람.';
              default:
                return hasBlurb
                    ? '"$blurbPhrase" 이 한 줄이 $shortName${withObj(shortName)} 절반쯤 설명해요.'
                    : '$shortName${withObj(shortName)} 한 줄로 적으면 $stElNameKo 결의 사람.';
            }
          case 1:
            // FAM 1 — 그룹/직업/활동 맥락 + blurbPhrase / blurbExtra 결합
            final kindLabel = (star.kind == 'idol')
                ? 'K-POP 무대 사람'
                : (star.kind == 'actor')
                    ? '카메라 안 사람'
                    : (star.kind == 'athlete')
                        ? '경기장의 사람'
                        : '한 결의 사람';
            switch (skeletonIdx) {
              case 0:
                return '$kindLabel $shortName — $blurbPhrase.';
              case 1:
                return hasExtra
                    ? '$shortName, $kindLabel이자 $blurbExtra.'
                    : '$shortName, $kindLabel 안의 $blurbPhrase.';
              case 2:
                return hasExtra
                    ? '$kindLabel의 한 결 — $shortName, $blurbExtra.'
                    : '$kindLabel의 한 결 — $shortName, $blurbPhrase.';
              case 3:
                return '$shortName${withSubj(shortName)} 자리잡은 곳은 $kindLabel — $blurbPhrase.';
              case 4:
                return hasExtra
                    ? '$kindLabel으로 보면 $shortName — $blurbExtra.'
                    : '$kindLabel으로 보면 $shortName — $blurbPhrase.';
              case 5:
                return hasExtra
                    ? '$shortName, 한 줄 정의는 "$blurbExtra" — $kindLabel.'
                    : '$shortName, 한 줄 정의는 "$blurbPhrase" — $kindLabel.';
              case 6:
                return '$shortName의 위치 — $kindLabel 안에서 $blurbPhrase.';
              default:
                return hasExtra
                    ? '$kindLabel 가운데 $shortName이 가진 결은 $blurbExtra.'
                    : '$kindLabel 가운데 $shortName이 가진 결은 $blurbPhrase.';
            }
          case 2:
            // FAM 2 — day pillar imagery (한자 + Korean) + blurbPhrase 결합
            final pillarTag = pillarKanji.isNotEmpty
                ? pillarKanji
                : (pillarName.isNotEmpty ? pillarName : '한 결');
            final pillarKoName = pillarName.isNotEmpty ? pillarName : '한 결';
            switch (skeletonIdx) {
              case 0:
                return '$pillarTag 일주의 $shortName — $blurbPhrase.';
              case 1:
                return hasExtra
                    ? '$shortName, $pillarTag 일주가 그린 $blurbExtra.'
                    : '$shortName, $pillarTag 일주가 그린 $blurbPhrase.';
              case 2:
                return '일주로 보면 $pillarTag — $shortName${withSubj(shortName)} 거기 서서 $blurbPhrase.';
              case 3:
                return '$pillarTag 일주 위에서 $shortName이 가진 결 — $blurbPhrase.';
              case 4:
                return hasExtra
                    ? '$pillarKoName 결의 사람 $shortName — $blurbExtra.'
                    : '$pillarKoName 결의 사람 $shortName — $blurbPhrase.';
              case 5:
                return hasExtra
                    ? '$shortName${withSubj(shortName)} $pillarKoName 일주가 그린 $blurbExtra.'
                    : '$shortName${withSubj(shortName)} $pillarKoName 일주가 그린 $blurbPhrase.';
              case 6:
                return hasExtra
                    ? '$pillarTag 일주, $pillarKoName 한 결 — $shortName${withSubj(shortName)} 거기서 $blurbExtra.'
                    : '$pillarTag 일주, $pillarKoName 한 결 — $shortName${withSubj(shortName)} 거기서 $blurbPhrase.';
              default:
                return hasExtra
                    ? '$shortName: $pillarTag 일주 사람이 보여 주는 모습은 $blurbExtra.'
                    : '$shortName: $pillarTag 일주 사람이 보여 주는 모습은 $blurbPhrase.';
            }
          case 3:
            // FAM 3 — 오행 + 지지 imagery (jiScene 12 variants + blurbPhrase)
            switch (skeletonIdx) {
              case 0:
                return stJiSceneKo.isNotEmpty
                    ? '$stElNameKo 결의 $shortName — $stJiSceneKo${withSubj(stJiSceneKo)} 어울리는 사람이에요. $blurbPhrase.'
                    : '$stElNameKo 결의 $shortName — $blurbPhrase.';
              case 1:
                return stJiSceneKo.isNotEmpty
                    ? '$shortName의 자리는 $stJiSceneKo — $stElNameKo 결 사람의 본 모습이에요. $blurbPhrase.'
                    : '$shortName, $stElNameKo 결의 한 사람. $blurbPhrase.';
              case 2:
                return stJiSceneKo.isNotEmpty
                    ? '$shortName${withSubj(shortName)} 가장 자연스러운 자리, $stJiSceneKo. $blurbPhrase.'
                    : '$shortName, $stElNameKo 결의 안쪽. $blurbPhrase.';
              case 3:
                return '$stElNameKo 결과 $stJiSceneKo${withSubj(stJiSceneKo)} 겹친 자리에 $shortName${withSubj(shortName)} 있어요. $blurbPhrase.';
              case 4:
                return stJiSceneKo.isNotEmpty
                    ? '$stJiSceneKo${withObj(stJiSceneKo)} 떠올리면 $shortName${withSubj(shortName)} 자연스러워요. $blurbPhrase.'
                    : '$shortName${withSubj(shortName)} $stElNameKo 결의 한 자락이에요. $blurbPhrase.';
              case 5:
                return stJiSceneKo.isNotEmpty
                    ? '$shortName, $stJiSceneKo 같은 장면이 어울려요 — $stElNameKo 결의 사람이거든요. $blurbPhrase.'
                    : '$shortName, $stElNameKo 결로 정리되는 사람. $blurbPhrase.';
              case 6:
                return hasExtra
                    ? '$stElNameKo 결 + $stJiSceneKo — $shortName${withSubj(shortName)} 거기서 $blurbExtra.'
                    : '$stElNameKo 결 + $stJiSceneKo — $shortName${withSubj(shortName)} 거기서 $blurbPhrase.';
              default:
                return stJiSceneKo.isNotEmpty
                    ? '$shortName${withObj(shortName)} 그릴 장면 하나, $stJiSceneKo — 그게 $stElNameKo 결이에요. $blurbPhrase.'
                    : '$shortName${withObj(shortName)} 그릴 장면 하나는 $stElNameKo 결의 한 컷이에요. $blurbPhrase.';
            }
          case 4:
            // FAM 4 — birth year / generation cue (10 cue + blurbPhrase)
            if (genCueKo.isEmpty) {
              return hasBlurb
                  ? '$shortName 이야기 한 줄 — $blurbPhrase.'
                  : '$shortName — $pillarName의 한 결.';
            }
            switch (skeletonIdx) {
              case 0:
                return '$genCueKo $shortName — $blurbPhrase.';
              case 1:
                return '$shortName${withSubj(shortName)} 자란 시대는 $genCueKo. $blurbPhrase.';
              case 2:
                return '$genCueKo${withSubj(genCueKo)} 만들어 낸 한 결, $shortName — $blurbPhrase.';
              case 3:
                return '$shortName — $genCueKo의 한 페이지에 있는 사람. $blurbPhrase.';
              case 4:
                return hasExtra
                    ? '$genCueKo $shortName, 한 마디로 적으면 $blurbExtra.'
                    : '$genCueKo $shortName, 한 마디로 적으면 $blurbPhrase.';
              case 5:
                return '$shortName, $genCueKo 색을 짙게 가진 사람 — $blurbPhrase.';
              case 6:
                return '$genCueKo 한가운데 $shortName${withSubj(shortName)} 서 있어요. $blurbPhrase.';
              default:
                return hasExtra
                    ? '$genCueKo의 한 줄로 $shortName${withObj(shortName)} 적으면 $blurbExtra.'
                    : '$genCueKo의 한 줄로 $shortName${withObj(shortName)} 적으면 $blurbPhrase.';
            }
          default:
            // FAM 5 — 사용자와의 관계 cue + jiScene/blurb 결합
            switch (skeletonIdx) {
              case 0:
                return stJiSceneKo.isNotEmpty
                    ? '너의 $myElNameKo 결과 $stElNameKo 결의 만남, $shortName — $stJiSceneKo 같은 자리예요. $blurbPhrase.'
                    : '너의 $myElNameKo 결과 $stElNameKo 결의 만남, $shortName. $blurbPhrase.';
              case 1:
                return hasExtra
                    ? '$shortName — 너에겐 $relCueKo 자리, $blurbExtra.'
                    : '$shortName — 너에겐 $relCueKo 자리, $blurbPhrase.';
              case 2:
                return stJiSceneKo.isNotEmpty
                    ? '너의 결과 $stElNameKo 결이 만나는 자리, $shortName — $stJiSceneKo. $blurbPhrase.'
                    : '너의 결과 $stElNameKo 결이 만나는 자리, $shortName. $blurbPhrase.';
              case 3:
                return hasExtra
                    ? '$shortName, 너와는 $relCueKo 흐름의 짝 — $blurbExtra.'
                    : '$shortName, 너와는 $relCueKo 흐름의 짝 — $blurbPhrase.';
              case 4:
                return hasExtra
                    ? '당신에게 $shortName${withSubj(shortName)} $relCueKo 자리에 서요 — $blurbExtra.'
                    : '당신에게 $shortName${withSubj(shortName)} $relCueKo 자리에 서요 — $blurbPhrase.';
              case 5:
                return stJiSceneKo.isNotEmpty
                    ? '$relCueKo 자리의 $shortName — $stJiSceneKo 같은 결로 다가와요. $blurbPhrase.'
                    : '$relCueKo 자리의 $shortName — $stElNameKo 결로 다가와요. $blurbPhrase.';
              case 6:
                return hasExtra
                    ? '$shortName${withSubj(shortName)} 당신에게 보여 주는 면 — $relCueKo 흐름 위의 $blurbExtra.'
                    : '$shortName${withSubj(shortName)} 당신에게 보여 주는 면 — $relCueKo 흐름 위의 $blurbPhrase.';
              default:
                return '너의 $myElNameKo 결 위로 $shortName이 가져오는 결은 $stElNameKo${withSubj(stElNameKo)} — $blurbPhrase.';
            }
        }
      }

      return build();
    } else {
      // R100 sprint 2-bis — EN 6 family × 8 skeleton = 48 skeleton total.
      // R106 P4a — grain 남용 청소 + 메타 노출 제거 (v5 자연 구어 톤).
      String build() {
        final hasBlurb = blurbPhrase.isNotEmpty;
        final hasExtra = blurbExtra.isNotEmpty;
        switch (familyIdx) {
          case 0:
            // FAM 0 — blurb-first 8 skeleton
            switch (skeletonIdx) {
              case 0:
                return hasBlurb
                    ? '$blurbPhrase — that, in one line, is $shortName.'
                    : '$shortName — ${pillarName.isNotEmpty ? "a $pillarName day pillar" : "a person you can read in a single line"}.';
              case 1:
                return hasBlurb
                    ? '"$blurbPhrase" — that is the compressed version of $shortName.'
                    : '$shortName${pillarName.isNotEmpty ? ", a $pillarName day pillar." : ", in one clear line."}';
              case 2:
                return hasBlurb
                    ? 'A one-line $shortName — $blurbPhrase.'
                    : '$shortName, briefly — a $stElNameEn-element type.';
              case 3:
                return hasBlurb
                    ? '$shortName, the person — $blurbPhrase.'
                    : '$shortName, ${pillarName.isNotEmpty ? "a $pillarName day pillar" : "in one clear line"}.';
              case 4:
                return hasBlurb
                    ? "$shortName's one-line tag: \"$blurbPhrase\"."
                    : "$shortName's one-line tag: $stElNameEn at the core.";
              case 5:
                return hasExtra
                    ? '$blurbPhrase. Underneath that lives the part of $shortName that $blurbExtra.'
                    : (hasBlurb
                        ? '$blurbPhrase. That is what $shortName looks like in shorthand.'
                        : '$shortName, a person you can capture in one line.');
              case 6:
                return hasBlurb
                    ? 'First impression of $shortName — $blurbPhrase.'
                    : 'First impression of $shortName — a $stElNameEn read.';
              default:
                return hasBlurb
                    ? '"$blurbPhrase" — that single line says a lot about $shortName.'
                    : 'A single line for $shortName — $stElNameEn at the core.';
            }
          case 1:
            // FAM 1 — group/kind context + blurb fragment
            final kindLabel = (star.kind == 'idol')
                ? 'K-pop stage figure'
                : (star.kind == 'actor')
                    ? 'a face inside the camera'
                    : (star.kind == 'athlete')
                        ? 'an arena figure'
                        : 'a one-of-one figure';
            switch (skeletonIdx) {
              case 0:
                return '$kindLabel $shortName — $blurbPhrase.';
              case 1:
                return hasExtra
                    ? '$shortName, a $kindLabel and $blurbExtra.'
                    : '$shortName, a $kindLabel inside which lives $blurbPhrase.';
              case 2:
                return hasExtra
                    ? "A $kindLabel's signature — $shortName, $blurbExtra."
                    : "A $kindLabel's signature — $shortName, $blurbPhrase.";
              case 3:
                return 'Where $shortName sits is the $kindLabel space — $blurbPhrase.';
              case 4:
                return hasExtra
                    ? 'Read as a $kindLabel, $shortName comes out as $blurbExtra.'
                    : 'Read as a $kindLabel, $shortName comes out as $blurbPhrase.';
              case 5:
                return hasExtra
                    ? "$shortName's one-line tag is \"$blurbExtra\" — a $kindLabel."
                    : "$shortName's one-line tag is \"$blurbPhrase\" — a $kindLabel.";
              case 6:
                return 'Inside a $kindLabel frame, $shortName carries $blurbPhrase.';
              default:
                return hasExtra
                    ? 'Among $kindLabel figures, $shortName holds $blurbExtra.'
                    : 'Among $kindLabel figures, $shortName holds $blurbPhrase.';
            }
          case 2:
            // FAM 2 — day pillar imagery (pillarName has "Water Dog" form)
            final pillarTag = pillarName.isNotEmpty
                ? pillarName
                : (pillarKanji.isNotEmpty ? pillarKanji : 'a quiet single line');
            final pillarKanjiTag = pillarKanji.isNotEmpty ? pillarKanji : pillarTag;
            switch (skeletonIdx) {
              case 0:
                return '$shortName, a $pillarTag pillar — $blurbPhrase.';
              case 1:
                return hasExtra
                    ? '$shortName, the person a $pillarTag pillar makes into $blurbExtra.'
                    : '$shortName, the person a $pillarTag pillar shapes into $blurbPhrase.';
              case 2:
                return 'Read as a pillar, $pillarTag — $shortName stands there with $blurbPhrase.';
              case 3:
                return 'On top of $pillarTag, what $shortName carries is $blurbPhrase.';
              case 4:
                return hasExtra
                    ? 'A $pillarTag pillar in person, $shortName — $blurbExtra.'
                    : 'A $pillarTag pillar in person, $shortName — $blurbPhrase.';
              case 5:
                return hasExtra
                    ? '$shortName, the person a $pillarTag pillar paints as $blurbExtra.'
                    : '$shortName, the person a $pillarTag pillar paints as $blurbPhrase.';
              case 6:
                return hasExtra
                    ? '$pillarKanjiTag pillar, the $pillarTag type — $shortName starts from $blurbExtra.'
                    : '$pillarKanjiTag pillar, the $pillarTag type — $shortName starts from $blurbPhrase.';
              default:
                return hasExtra
                    ? "$shortName: what a $pillarTag pillar shows is $blurbExtra."
                    : "$shortName: what a $pillarTag pillar shows is $blurbPhrase.";
            }
          case 3:
            // FAM 3 — element + jiScene imagery
            switch (skeletonIdx) {
              case 0:
                return stJiSceneEn.isNotEmpty
                    ? '$shortName, a $stElNameEn-element person, fits $stJiSceneEn. $blurbPhrase.'
                    : '$shortName, a $stElNameEn-element person. $blurbPhrase.';
              case 1:
                return stJiSceneEn.isNotEmpty
                    ? "$shortName's seat is $stJiSceneEn — the natural face of $stElNameEn. $blurbPhrase."
                    : '$shortName, a $stElNameEn-element person through and through. $blurbPhrase.';
              case 2:
                return stJiSceneEn.isNotEmpty
                    ? '$shortName at their most natural: $stJiSceneEn. $blurbPhrase.'
                    : '$shortName, $stElNameEn seen from the inside. $blurbPhrase.';
              case 3:
                return 'Where $stElNameEn meets $stJiSceneEn, that is where $shortName stands. $blurbPhrase.';
              case 4:
                return stJiSceneEn.isNotEmpty
                    ? 'Picture $stJiSceneEn — that is where $shortName lives. $blurbPhrase.'
                    : '$shortName lives close to the $stElNameEn element. $blurbPhrase.';
              case 5:
                return stJiSceneEn.isNotEmpty
                    ? '$shortName, the kind of person who suits $stJiSceneEn — a $stElNameEn read. $blurbPhrase.'
                    : '$shortName, the kind of person a $stElNameEn read fits. $blurbPhrase.';
              case 6:
                return hasExtra
                    ? '$stElNameEn + $stJiSceneEn — that is where $shortName carries $blurbExtra.'
                    : '$stElNameEn + $stJiSceneEn — that is where $shortName carries $blurbPhrase.';
              default:
                return stJiSceneEn.isNotEmpty
                    ? 'One scene to draw $shortName by: $stJiSceneEn — $stElNameEn at its clearest. $blurbPhrase.'
                    : 'One scene to draw $shortName by: a frame of the $stElNameEn element. $blurbPhrase.';
            }
          case 4:
            // FAM 4 — generation cue + blurb
            if (genCueEn.isEmpty) {
              return hasBlurb
                  ? '$shortName in one line — $blurbPhrase.'
                  : '$shortName — a person you can read in a single line.';
            }
            switch (skeletonIdx) {
              case 0:
                return 'A $genCueEn figure, $shortName — $blurbPhrase.';
              case 1:
                return "The era $shortName grew in was $genCueEn. $blurbPhrase.";
              case 2:
                return 'One figure $genCueEn produced, $shortName — $blurbPhrase.';
              case 3:
                return '$shortName — a name written on a $genCueEn page. $blurbPhrase.';
              case 4:
                return hasExtra
                    ? 'A $genCueEn figure, $shortName, in one line: $blurbExtra.'
                    : 'A $genCueEn figure, $shortName, in one line: $blurbPhrase.';
              case 5:
                return '$shortName, a person who carries the $genCueEn color in dense form — $blurbPhrase.';
              case 6:
                return 'Right in the middle of $genCueEn stands $shortName. $blurbPhrase.';
              default:
                return hasExtra
                    ? 'A $genCueEn one-liner for $shortName — $blurbExtra.'
                    : 'A $genCueEn one-liner for $shortName — $blurbPhrase.';
            }
          default:
            // FAM 5 — user-relation cue + jiScene/blurb
            switch (skeletonIdx) {
              case 0:
                return stJiSceneEn.isNotEmpty
                    ? 'Where your $myElNameEn element meets $stElNameEn stands $shortName — a $stJiSceneEn kind of seat. $blurbPhrase.'
                    : 'Where your $myElNameEn element meets $stElNameEn stands $shortName. $blurbPhrase.';
              case 1:
                return hasExtra
                    ? '$shortName — for you, the figure of a $relCueEn seat carrying $blurbExtra.'
                    : '$shortName — for you, the figure of a $relCueEn seat carrying $blurbPhrase.';
              case 2:
                return stJiSceneEn.isNotEmpty
                    ? 'Where your element meets $stElNameEn, that is $shortName — $stJiSceneEn. $blurbPhrase.'
                    : 'Where your element meets $stElNameEn, that is $shortName. $blurbPhrase.';
              case 3:
                return hasExtra
                    ? '$shortName, your partner in a $relCueEn flow — $blurbExtra.'
                    : '$shortName, your partner in a $relCueEn flow — $blurbPhrase.';
              case 4:
                return hasExtra
                    ? 'To you, $shortName stands in a $relCueEn seat — $blurbExtra.'
                    : 'To you, $shortName stands in a $relCueEn seat — $blurbPhrase.';
              case 5:
                return stJiSceneEn.isNotEmpty
                    ? '$shortName, the $relCueEn seat figure — arriving like $stJiSceneEn. $blurbPhrase.'
                    : '$shortName, the $relCueEn seat figure — arriving like a $stElNameEn read. $blurbPhrase.';
              case 6:
                return hasExtra
                    ? 'The face $shortName shows you — a $relCueEn flow carrying $blurbExtra.'
                    : 'The face $shortName shows you — a $relCueEn flow carrying $blurbPhrase.';
              default:
                return 'Onto your $myElNameEn element, what $shortName brings is $stElNameEn — $blurbPhrase.';
            }
        }
      }

      return build();
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
    required int seed,
  }) {
    // R100 sprint 2 — branch 별 variant pool 도입. NONE branch 만 32+ variant 보장.
    final mySceneKo = _KpopAnchors.jiSceneKo(myJi).isNotEmpty
        ? _KpopAnchors.jiSceneKo(myJi)
        : '둘만 아는 시간대';
    final stSceneKo = _KpopAnchors.jiSceneKo(stJi).isNotEmpty
        ? _KpopAnchors.jiSceneKo(stJi)
        : '둘만 아는 시간대';
    final mySceneEn = _KpopAnchors.jiSceneEn(myJi).isNotEmpty
        ? _KpopAnchors.jiSceneEn(myJi)
        : 'a time only you two know';
    final stSceneEn = _KpopAnchors.jiSceneEn(stJi).isNotEmpty
        ? _KpopAnchors.jiSceneEn(stJi)
        : 'a time only you two know';

    String pick(String slot, List<String> pool) {
      if (pool.isEmpty) return '';
      // R100 sprint 4 — key 에 shortName 까지 포함해 FNV-1a + xorshift+mix mod
      // bias 를 추가로 해소. 같은 seed band 안에서도 셀럽 이름이 다르면 다른 slot.
      final idx =
          _KpopAnchors.saltedPick(slot, '$seed|$shortName', pool.length);
      return pool[idx];
    }

    final parts = <String>[];
    if (useKo) {
      if (sameDay) {
        // R100 sprint 4 — 4 → 16 variants. baseline 의 4-variant slot collision
        // (FNV-1a + 같은 일주 셀럽 다수 → top-1 ≥ 11) 해소.
        final pool = [
          '둘 다 ${me.day60ji} 일주라 거울 보는 자리예요. $shortName${withSubj(shortName)} 깨달은 건 너도 곧 깨닫고, 너의 변화도 $shortName한테 빠르게 비쳐요.',
          '같은 ${me.day60ji} 일주끼리라 한 명의 변화가 곧 다른 한 명의 변화처럼 보여요. $shortName과 너는 거울처럼 서로의 모드를 빠르게 흡수해요.',
          '${me.day60ji} 일주 쌍이라 결정의 톤·말투까지 거의 겹쳐요. 같이 흔들리지 않게, 큰 결정 앞에서는 둘 중 한 명이 한 박자 늦추는 룰을 정해두세요.',
          '같은 ${me.day60ji} 일주 — 같은 약점·같은 강점이 동시에 살아 있어요. $shortName과 너 둘 다 회복 시기엔 함께 호흡을 늦추는 게 자연스러워요.',
          '${me.day60ji} 일주 두 사람 — 좋아하는 향, 좋아하는 소리, 결정의 속도까지 거울처럼 닿아요. 가끔 누군가 일부러 다른 페이스를 잡아주는 게 균형이에요.',
          '같은 ${me.day60ji} 일주라 컨디션 그래프가 비슷한 모양으로 움직여요. $shortName이 떨어지는 날엔 너도 자연스럽게 무거워지니, 한 명은 미리 회복 루틴을 약속해두세요.',
          '${me.day60ji} 일주 짝이라 첫 만남이 마치 오래 본 사람 같아요. 너무 닮은 만큼 작은 차이가 더 크게 보이니, 다른 점을 비난 대신 신호로 받아주는 약속이 필요해요.',
          '같은 ${me.day60ji} 일주끼리는 대화 한 줄에서도 같은 결을 잡아요. $shortName이 말 줄인 부분을 너는 자동 번역하니까, 한 번씩은 일부러 풀어 말해주는 자리도 만들어 두세요.',
          '${me.day60ji} 일주 거울 짝 — 약점은 같이 약해지는 자리예요. 한 명이 균형을 잃으면 다른 한 명이라도 외부 자원(친구·운동·산책)을 의식적으로 켜주세요.',
          '같은 ${me.day60ji} 일주 두 명 — 둘 다 한 번씩 큰 결정 앞에서 멈춰요. 한 명이 결단을 미루면 다른 한 명이라도 작은 결정부터 시작하는 룰이 도움돼요.',
          '${me.day60ji} 일주 한 짝 — 좋아하는 자리·시간·음식까지 비슷한 도화선이에요. 새 자극이 부족할 수 있으니 한 달에 한 번 낯선 장소를 같이 가는 약속이 색깔이 돼요.',
          '같은 ${me.day60ji} 일주 — 강점이 겹치는 만큼 같은 일에 같이 빠지면 회복이 늦어요. 큰 일은 한 명이 한 발 물러나는 룰을 정해두는 게 안전망이에요.',
          '${me.day60ji} 일주 쌍이라 갈등도 사과도 짧고 빠르게 끝나는 자리예요. 너무 빠르게 푸는 게 익숙해서 깊이까지 못 가기도 하니, 한 번씩은 천천히 풀어보는 시간을 두세요.',
          '같은 ${me.day60ji} 일주끼리 — 둘 다 한 사람에게 자기 색을 잘 안 내주는 성격이라, 누가 먼저 말을 꺼낼지 자연스레 미루는 자리예요. 처음 입을 떼는 사람의 역할을 번갈아 정해두세요.',
          '${me.day60ji} 일주 두 사람 — 자기만의 페이스를 같이 가진 짝이라 결정의 속도가 어긋날 일이 적어요. 너희 둘만의 결정 박자를 외부 압력보다 우선으로 두세요.',
          '같은 ${me.day60ji} 일주 — 닮아서 좋은 자리, 닮아서 막히는 자리예요. 다름을 일부러 만드는 작은 의식(서로 다른 책 추천·다른 카페 선택)이 관계의 산소가 돼요.',
        ];
        parts.add(pick('dailySD_K', pool));
      } else if (sameBranch) {
        final pool = [
          '같은 일지($myJi)를 공유해서 인생 리듬·계절감·체질이 비슷해요. 너의 $mySceneKo${withSubj(mySceneKo)} $shortName한테도 자연스럽게 닿아요.',
          '$myJi 일지를 함께 가진 짝이라 계절·시간대·식습관까지 비슷한 자리예요. $shortName과 너의 평일 동선이 자연스레 겹쳐요.',
          '일지 ($myJi) 공유 — 생활 리듬이 거의 같은 톤이라 약속을 잡을 때 시간 합이 잘 맞아요. $shortName과 너의 휴식 패턴도 비슷하게 흘러요.',
          '같은 일지($myJi)라 둘 다 비슷한 시즌에 컨디션이 올라요. $shortName과 너의 페이스가 어느새 한 음정으로 정렬돼요.',
          '$myJi 일지를 함께 가진 자리 — 둘 다 컨디션 회복하는 방법이 비슷해서 쉬는 자리 추천이 거의 같아요. $shortName과 너의 회복 루틴이 자연스럽게 합쳐져요.',
          '일지 ($myJi) 공유 — 좋아하는 시간대·소음·온도가 닮아 있어요. 같이 있을 때 굳이 묻지 않아도 분위기 조절이 자연스러워요.',
          '같은 일지($myJi) 짝 — 한 달 안에 컨디션 좋은 주가 비슷하게 흐르고, 비 오는 날 더 차분해지는 결도 같이 가요. $shortName과 너의 침묵 톤이 같은 음이에요.',
          '$myJi 일지 공유 — 좋아하는 향·음악·식감이 자주 겹쳐요. 작은 선물 고를 때 큰 고민 없이 통하는 자리예요.',
          '같은 일지($myJi)라 잠드는 시간·일어나는 시간이 비슷하게 정렬돼요. 같이 살거나 같이 일하면 일정 충돌이 적은 짝이에요.',
          '일지 ($myJi) 공유 — 좋아하는 카페·좋아하는 코스가 같은 결로 흘러요. $shortName과 너의 평일 산책이 자연스럽게 같은 방향이에요.',
          '같은 일지($myJi)라 갈등 후 회복하는 방식도 비슷해요. 한 명이 거리를 두면 다른 한 명도 무리하지 않는 게 자연스러운 자리예요.',
          '$myJi 일지 짝 — 둘 다 약속에서 시간 안 맞추는 사람을 비슷하게 어려워해요. 그래서 서로의 시간 약속만은 자연스럽게 정확해요.',
          '같은 일지($myJi)라 좋아하는 자리에서 같은 결로 호흡해요. 외향·내향이 같은 시간대에 켜지는 짝이라 같이 있는 자리가 편해요.',
          '일지 ($myJi) 공유 — 일상 작은 결정(밥집·메뉴·산책 코스)에서 빠르게 합의되는 자리예요. 큰 결정은 일부러 한 박자 늦추는 습관이 균형이에요.',
          '같은 일지($myJi) 짝 — 비슷한 시즌에 같이 지치고 같이 회복돼요. 그 결이 매력이지만, 둘 다 흔들리는 시즌엔 외부 친구 한 명을 의식적으로 합류시키세요.',
          '$myJi 일지를 같이 가진 자리 — 좋아하는 잠자리 온도·좋아하는 침묵 길이가 비슷해서 같은 공간에 있는 게 자연스러워요. 너희만의 침묵 룰이 곧 관계의 색이에요.',
        ];
        parts.add(pick('dailySB_K', pool));
      }
      if (ganHap) {
        final pool = [
          '천간 오합 ($myGan-$stGan)이 정확히 맺힌 사이예요. 처음 본 순간부터 자석처럼 끌리는데, 합이 강한 만큼 한쪽이 자기 색을 잃기 쉬워서 각자 페이스를 지키는 약속이 필요해요.',
          '천간 오합 ($myGan-$stGan) — 첫 순간부터 끌림이 강한 자리예요. 끌림이 큰 만큼 자기 색을 묻혀버릴 위험도 같이 커지니까, 너의 페이스를 의식적으로 지키세요.',
          '천간 오합 ($myGan-$stGan)이 정렬된 사이 — 한 번 만나면 인상이 깊게 박혀요. 그 인상에 휘말리지 않도록 너만의 결정 기준을 미리 정해두는 게 안전해요.',
          '천간 합 ($myGan-$stGan) — 둘 사이엔 자연 화학반응이 평균 두 배 자리예요. 두 배 끌리는 만큼 두 배 신중함이 필요한 자리예요.',
          '천간 오합 ($myGan-$stGan) — 짧은 대화에서도 평균 이상의 끌림이 만들어지는 자리예요. 사소한 약속 한 줄을 잘 지키는 게 신뢰의 단위가 돼요.',
          '천간 합 ($myGan-$stGan) — 첫 인상이 깊게 새겨지는 결이라, 시작 단계에서 너의 기준을 또렷이 정해두면 나중에 흔들릴 일이 줄어요.',
          '천간 오합 ($myGan-$stGan)이 걸린 짝 — 분위기에 휘말려 큰 결정을 빠르게 내리기 쉬워요. 24시간 룰(큰 결정은 하루 묵힌다)을 둘만의 약속으로 정해두세요.',
          '천간 합 ($myGan-$stGan) — $shortName 앞에서 평소보다 큰 결심이 더 가볍게 나와요. 가볍게 나온 결심을 가볍게 깨지 않도록 한 번 더 적어보는 습관이 보호예요.',
          '천간 오합 ($myGan-$stGan)이 정렬 — 둘이 같이 있을 때 다른 사람들이 분위기를 먼저 느낄 정도로 호흡이 큰 자리예요. 그 분위기에 둘이 도취되지 않도록 셋 자리(친구 한 명 포함)도 자주 만드세요.',
          '천간 합 ($myGan-$stGan) — 사주 신호 중 가장 직관적인 끌림이라 첫 단계가 빨라요. 빠르게 시작한 만큼 천천히 가는 단계도 일부러 만들어 균형을 잡아두세요.',
          '천간 오합 ($myGan-$stGan)이 걸린 자리 — 한 번 끝낸 결정을 다시 들추고 싶어지기 쉬운 자리예요. 큰 결정은 한 번 정하면 적어도 6개월은 묵혀보는 둘만의 룰을 두면 흔들림이 줄어요.',
          '천간 합 ($myGan-$stGan) — 표현이 적은 자리에서도 의미가 깊게 통하는 자리예요. 다만 같은 침묵이 다른 의미일 때가 있으니, 정기적으로 말로 확인하는 시간을 잡아두세요.',
          '천간 오합 ($myGan-$stGan) — 둘 사이 정서적 점화가 빠른 자리예요. $shortName과 너의 감정 강도가 외부 친구들 보기엔 평균 이상이라, 친구 말 한 마디로 흔들리지 않는 합의가 필요해요.',
          '천간 합 ($myGan-$stGan)이 정렬된 짝 — 한 사람의 변화가 다른 한 사람한테 즉시 전달되는 자리예요. 좋은 변화는 즉시 칭찬으로, 어려운 변화는 한 박자 뒤에 말로 풀어보세요.',
          '천간 오합 ($myGan-$stGan) — 자연 화학반응이 큰 만큼, 함께 보내는 시간이 평균보다 빠르게 흘러요. 시간 감각을 잃지 않게 정기적으로 일정을 기록해두는 게 도움돼요.',
          '천간 합 ($myGan-$stGan) — 둘 사이 끌림이 평균 이상이라 자기 결정권을 잃기 쉬워요. 일주일에 한 번은 혼자만의 결정 시간을 비워두는 약속이 자기 색을 지켜줘요.',
        ];
        parts.add(pick('dailyGH_K', pool));
      }
      if (jiHap6) {
        final pool = [
          '지지 육합 ($myJi-$stJi)이 있어 일상 호흡이 자연스럽게 맞아요. 너의 $mySceneKo${withWith(mySceneKo)} $shortName의 $stSceneKo${withSubj(stSceneKo)} 어느새 한 시간대로 흘러요.',
          '지지 육합 ($myJi-$stJi) — 평일 동선이 자연스레 겹치는 자리예요. $mySceneKo와 $stSceneKo가 같은 페이지 안으로 부드럽게 들어와요.',
          '육합 ($myJi-$stJi)이 걸린 짝이라 시간대·약속·기분이 큰 노력 없이 맞아 들어가요. 둘만의 루틴이 자연스럽게 만들어져요.',
          '지지 육합 ($myJi-$stJi) — 너의 $mySceneKo가 $shortName의 $stSceneKo와 같은 리듬으로 흘러요. 일상의 합이 가장 자연스러운 분기예요.',
          '육합 ($myJi-$stJi) — 둘 다 약속 시간 정확한 편이라 만나는 게 어렵지 않아요. $mySceneKo와 $stSceneKo 사이에 자연스러운 다리가 놓여 있어요.',
          '지지 육합 ($myJi-$stJi) — 같이 있는 자리에서 굳이 분위기 만들 노력이 필요 없는 짝이에요. 침묵도 어색하지 않은 게 이 자리의 특기예요.',
          '육합 ($myJi-$stJi)이 걸린 자리 — 갑작스러운 변경에도 합의가 빨라요. 일정 어긋남이 다툼으로 잘 안 가는 결의 짝이에요.',
          '지지 육합 ($myJi-$stJi) — 식사 시간·잠자는 시간·산책 코스가 자연스럽게 합쳐져요. 같이 살거나 같이 일하기 좋은 일상 짝이에요.',
          '육합 ($myJi-$stJi) — 같이 있을 때 호흡이 짧은 한숨 단위로도 맞아요. 큰 합이 아니라 작은 합이 매일 일어나는 자리예요.',
          '지지 육합 ($myJi-$stJi)이 정렬된 짝 — 둘이 합의 보는 데 평균보다 시간이 적게 걸려요. 그 시간 절약을 깊은 대화에 쓰는 게 자산이에요.',
          '육합 ($myJi-$stJi) — 작은 일상 결정에서 합이 빠른 만큼 큰 결정도 같이 보는 게 자연스러운 자리예요. 정기적으로 큰 그림을 같이 그리는 시간을 잡아두세요.',
          '지지 육합 ($myJi-$stJi) — 둘 다 자기 시간을 정중히 다루는 결이라 거리 조절도 자연스러워요. 너무 가까이 가지 않는 것도 합의 한 형태예요.',
          '육합 ($myJi-$stJi)이 있는 짝 — 갈등 후 회복 곡선이 짧아요. 작은 사과 한 줄이 한 마디로 통하는 자리예요.',
          '지지 육합 ($myJi-$stJi) — 같이 있을 때 자기 모습을 자연스럽게 꺼내는 자리예요. $shortName 앞에서 너도 평소보다 솔직해지기 쉬워요.',
          '육합 ($myJi-$stJi) — 만나는 횟수보다 만나는 깊이가 중요한 자리예요. $shortName과 너의 짧은 만남도 충분히 의미를 만들어요.',
          '지지 육합 ($myJi-$stJi)이 걸린 자리 — 두 사람 사이 일상 합의가 자연스러운 만큼, 큰 자리(여행·이사·이직)도 같이 보면 더 매끄럽게 진행돼요.',
        ];
        parts.add(pick('dailyJH6_K', pool));
      } else if (jiSamhap) {
        final pool = [
          '지지 삼합 일부 ($myJi-$stJi)가 맺혀 같은 목표를 향해 움직일 때 시너지가 가장 큰 흐름이에요. $mySceneKo + $stSceneKo = 같이 프로젝트 하나 만들어 가는 자리에 잘 맞아요.',
          '지지 삼합 일부 ($myJi-$stJi) — 함께 만든 목표 앞에서 시너지가 평균 이상으로 올라와요. 일상 친구보다 공동 작업 파트너에 더 어울리는 짝이에요.',
          '삼합 일부 ($myJi-$stJi)가 걸려 있어 큰 목표 앞에서 호흡이 척척 맞아요. $mySceneKo와 $stSceneKo가 만나는 자리에서 새 프로젝트가 자라요.',
          '지지 삼합 일부 ($myJi-$stJi) — 둘이 함께 그리는 큰 그림 앞에서 가장 자연스럽게 손발이 맞아요. 작업·여행·도전 같은 공동 프로젝트에 적합한 짝이에요.',
          '삼합 일부 ($myJi-$stJi) — 같은 방향을 잡았을 때 추진력이 평균보다 큰 자리예요. 처음부터 큰 목표를 같이 정리해두는 게 효율이에요.',
          '지지 삼합 일부 ($myJi-$stJi) — 작업 자리에서 손발이 빠르게 맞아 들어가요. 일상 관계보다 무언가 같이 만드는 자리에서 진가가 나와요.',
          '삼합 일부 ($myJi-$stJi)가 걸린 짝 — 둘이 같이 가는 길에서 호흡이 한 박자 안에 맞아요. 단, 방향이 갈리면 추진력도 같이 멈춰요.',
          '지지 삼합 일부 ($myJi-$stJi) — 공동 목표가 있는 자리에서 가장 빛나는 합이에요. 데이트보다 프로젝트, 친목보다 협업이 자연스러워요.',
          '삼합 일부 ($myJi-$stJi) — 짧은 시간에 큰 결과를 내는 짝이에요. 단기 도전·시즌제 작업·여행 계획 같은 자리에서 합이 잘 살아나요.',
          '지지 삼합 일부 ($myJi-$stJi) — 같은 방향만 잡으면 외부 자원도 같이 끌어들이는 자리예요. 외부 친구·외부 자리·외부 의견을 합류시킬 때 자연스럽게 협력해요.',
          '삼합 일부 ($myJi-$stJi)가 걸린 자리 — 둘이 함께 정한 약속을 외부 흔들림 없이 지켜내는 결의 짝이에요. 가볍게 시작한 약속이 큰 결과로 자라요.',
          '지지 삼합 일부 ($myJi-$stJi) — 작업 자리에서 한 사람의 빈자리를 다른 한 사람이 자연스럽게 채워요. 역할 분담 없이도 흐름이 만들어지는 짝이에요.',
          '삼합 일부 ($myJi-$stJi) — 공동 자리(작업·운동·여행)에서 시너지가 평균 이상이라 일상보다 이벤트 자리에서 빛나는 결이에요.',
          '지지 삼합 일부 ($myJi-$stJi) — 둘 다 결과 중심의 결이라 큰 목표 앞에서 합이 빠르게 일어나요. 일정·예산 같은 항목은 처음부터 같이 적어두세요.',
          '삼합 일부 ($myJi-$stJi)가 걸려 있는 짝 — 큰 그림을 잡으면 작은 디테일이 자연스럽게 따라와요. 그래서 처음 그림이 가장 중요한 자리예요.',
          '지지 삼합 일부 ($myJi-$stJi) — 같은 방향 잡았을 때 둘이 만들어내는 결과물이 평균보다 한 단계 위 자리예요. 같이 도전하는 시간을 정기적으로 만드세요.',
        ];
        parts.add(pick('dailyJSH_K', pool));
      }
      if (jiClash) {
        final pool = [
          '지지 충 ($myJi-$stJi)이 걸려 큰 결정·이사·여행·돈 자리에서 의견이 엇갈리기 쉬워요. 너의 $mySceneKo${withWith(mySceneKo)} $shortName의 $stSceneKo${withSubj(stSceneKo)} 정반대 시간대라, 미리 말로 룰을 정해두면 부딪힘이 줄어요.',
          '지지 충 ($myJi-$stJi) — 큰 결정 자리에서 서로의 입장이 정반대로 자주 나와요. 결정 전에 둘만의 룰 한 줄을 미리 정해두는 게 가장 효과적이에요.',
          '충 ($myJi-$stJi)이 걸린 짝 — 일상 톤은 괜찮은데 큰 자리(여행·이사·돈·진로)에서 의견이 갈려요. 갈등 시점에 침묵 대신 말로 풀어내는 룰이 핵심이에요.',
          '지지 충 ($myJi-$stJi) — 너의 $mySceneKo와 $shortName의 $stSceneKo가 같은 자리에서 정반대로 흐를 수 있어요. 일정·예산 같은 구체적 항목은 미리 합의해두세요.',
          '충 ($myJi-$stJi) — 가까이 있을수록 작은 차이가 크게 보이는 자리예요. 정기적으로 거리 두는 시간을 두는 게 오히려 관계 안정에 도움돼요.',
          '지지 충 ($myJi-$stJi) — 둘 다 자기 결이 또렷한 짝이라 같은 자리에서 다른 답을 내기 쉬워요. 그 답을 둘 다 인정하는 합의 한 줄이 안전망이에요.',
          '충 ($myJi-$stJi)이 걸린 자리 — 큰 자리에서 의견이 정반대로 갈리는 만큼, 결정 책임을 사전에 나눠두면 갈등이 평이해져요.',
          '지지 충 ($myJi-$stJi) — 일상 자잘한 차이는 신선한 자극이지만, 큰 자리에서는 부담이 돼요. 큰 자리는 외부 조언 한 명을 같이 듣는 게 도움돼요.',
          '충 ($myJi-$stJi) — 같이 있을 때 활발해지는 결의 짝이라 자극은 풍부해요. 자극이 갈등으로 안 가도록 갈등 후 24시간 안에 정리하는 루틴을 두세요.',
          '지지 충 ($myJi-$stJi) — 둘 다 큰 결정 앞에서 자기 결로 가는 결이에요. 그래서 큰 결정은 시간 두고 한 번 더 살펴보는 약속이 핵심이에요.',
          '충 ($myJi-$stJi)이 걸린 짝 — 갈등의 폭이 크지만 회복의 폭도 같이 큰 자리예요. 갈등 후 작은 호의 한 줄이 평균보다 큰 의미를 가져요.',
          '지지 충 ($myJi-$stJi) — 둘 사이에 자극이 풍부한 만큼 그 자극을 즐기는 자리가 어울려요. 새로운 자리·새로운 활동을 같이 가는 게 갈등 예방이에요.',
          '충 ($myJi-$stJi) — 큰 자리에서 의견이 갈리는 만큼, 작은 자리에서 의견 맞춰가는 연습이 평균보다 중요한 짝이에요.',
          '지지 충 ($myJi-$stJi)이 걸린 자리 — 같은 자리에서 다른 결을 내는 만큼 둘이 같이 가야 보이는 것도 많아요. 다른 결을 위협이 아닌 자원으로 보는 시야가 핵심이에요.',
          '충 ($myJi-$stJi) — 둘 사이 자극이 크기 때문에 한 명이라도 휴식이 부족하면 갈등 위험이 올라가요. 회복 시간을 합의해두는 게 보호장치예요.',
          '지지 충 ($myJi-$stJi) — 큰 자리에서 부딪힘이 잦은 만큼 결정 항목을 사전에 글로 적어두는 습관이 자산이에요. 적어두면 큰 갈등이 작은 조정으로 줄어들어요.',
        ];
        parts.add(pick('dailyJC_K', pool));
      }
      if (jiHyeong) {
        final pool = [
          '지지 형 ($myJi-$stJi)이 걸려 있어 한 번씩 강한 한 마디가 오갈 수 있어요. 평소에 작은 인정·칭찬을 자주 챙겨주면 큰 다툼으로 안 가요.',
          '지지 형 ($myJi-$stJi) — 가끔 한 마디가 평소보다 날카롭게 들리는 자리예요. 평소 인정·고마움 표현을 두 배로 늘려두면 그 한 마디가 무뎌져요.',
          '형 ($myJi-$stJi)이 걸린 짝 — 작은 불씨가 큰 불로 번질 위험이 살짝 있어요. 갈등 직후 24시간 안에 한 번 사과·정리하는 루틴이 보호장치예요.',
          '지지 형 ($myJi-$stJi) — 평소엔 좋은데 가끔 톤이 갈리는 자리예요. 둘 다 컨디션이 낮은 날엔 큰 대화를 미루는 합의가 도움돼요.',
          '형 ($myJi-$stJi) — 가끔 한 마디가 평균 이상 무게로 들리는 자리예요. 무게가 부담이 되기 전에 가볍게 표현하는 작은 어휘들을 한 줌 비축해두세요.',
          '지지 형 ($myJi-$stJi) — 둘 다 무딘 표현보다 또렷한 표현을 선호하는 결이라, 그 또렷함이 가끔 상대에게는 날카롭게 닿아요. 한 단계 부드러운 어휘를 의식적으로 챙겨두세요.',
          '형 ($myJi-$stJi)이 걸린 자리 — 갈등 후 회복은 평균보다 시간이 필요한 자리예요. 사과는 즉시, 화해는 천천히, 그게 자연스러운 순서예요.',
          '지지 형 ($myJi-$stJi) — 작은 어휘 차이가 큰 신호로 읽히는 결이에요. 같은 의미라도 다정한 어휘 한 줄이 자산이에요.',
          '형 ($myJi-$stJi) — 둘 다 자기 자리에 대한 감각이 또렷한 결이라 경계가 살짝 부딪혀요. 자기 자리에 대한 존중을 말로 자주 표현해주세요.',
          '지지 형 ($myJi-$stJi)이 있는 짝 — 가까이 있을수록 작은 충돌이 누적되기 쉬워요. 정기적인 거리 두기(혼자 시간·외부 친구 자리)가 관계 청정제예요.',
          '형 ($myJi-$stJi) — 갈등 발화점이 좀 낮은 자리예요. 평소 표현을 다정하게 비축해두면 발화점이 올라가서 큰 갈등이 잘 안 일어나요.',
          '지지 형 ($myJi-$stJi) — 둘 다 자기 의견을 또렷히 가지는 결이라, 의견 차이가 갈등이 되지 않게 처음부터 다양성을 인정하는 합의가 필요해요.',
          '형 ($myJi-$stJi)이 걸린 자리 — 가끔 짧은 마찰이 있지만 큰 사고는 적은 결이에요. 짧은 마찰을 그날 안에 푸는 습관이 누적 자산이에요.',
          '지지 형 ($myJi-$stJi) — 같이 있는 자리에서 자기 색이 또렷이 나오는 만큼 다른 색을 위협이 아닌 신선함으로 받는 시야가 핵심이에요.',
          '형 ($myJi-$stJi) — 둘 사이 작은 갈등이 정기적으로 일어나는 자리예요. 정기성을 그래프로 보는 시야(한 달 단위 점검)가 안정에 도움돼요.',
          '지지 형 ($myJi-$stJi)이 걸린 짝 — 둘 다 자기 결을 분명히 가진 결이라, 그 결을 합치는 노력보다 그 결을 같이 인정하는 자세가 자연스러워요.',
        ];
        parts.add(pick('dailyJHY_K', pool));
      }
      if (parts.isEmpty) {
        // R100 sprint 2 — NONE branch 32+ variants (baseline 의 44% 점유 분기).
        final pool = [
          '천간합·지지합·충·형이 직접 걸려 있지 않아요. 너의 $mySceneKo${withWith(mySceneKo)} $shortName의 $stSceneKo${withSubj(stSceneKo)} 자연스럽게 겹치는 순간이 와야 깊어지는 관계라, 시간이 일하는 인연이에요.',
          '직접적인 합·충·형 신호가 없는 짝이라 자연 발화는 천천히 와요. $shortName과 너 사이의 깊이는 사건이 아니라 시간이 만들어줘요.',
          '큰 합도 큰 충도 없어서 첫 만남부터 평온해요. 평온한 자리는 큰 폭발도 큰 회복도 없으니, 작은 약속·작은 메모가 관계의 진폭이 돼요.',
          '천간·지지 사이에 직접 걸린 자리가 없어요. 그래서 저절로 끌리기보다, 의도적으로 챙기는 만남이 깊이를 만들어가기 쉬운 자리예요.',
          '직접 합·충 자리가 없는 짝이라 일상 톤은 잔잔해요. 잔잔함이 권태로 빠지지 않도록 새로운 자극(여행·취미·새 사람)을 정기적으로 합류시키세요.',
          '합·충·형 신호가 직접 걸리지 않은 자리 — $shortName과 너 사이엔 의도적 누적이 가장 큰 자산이에요. 작은 약속을 자주 지켜주는 게 깊이의 단위예요.',
          '직접 anchor 가 없는 짝이라 둘 다 게을러지면 관계가 그대로 멈춰요. 한 명이라도 다음 약속을 잡는 노동을 멈추지 않으면, 그 노동이 관계의 진폭이 돼요.',
          '합·충 없는 자리에선 큰 사건보다 누적이 결정적이에요. $shortName과 너 사이엔 작은 메시지 한 줄·작은 만남 한 번이 평균보다 더 크게 작용해요.',
          '천간·지지 직접 신호가 약한 만큼, 둘 사이엔 강한 끌림도 강한 마찰도 없어요. 그 무게 없음을 자유로 해석하면 어느 친구보다 가볍게 오래 갈 수 있는 관계예요.',
          '합·충 anchor 없는 짝이라 자연 발화는 어렵지만, 인공 발화에 익숙해지면 자연 관계보다 더 정교한 관계로 키울 수 있어요. 의도가 자산인 자리예요.',
          '직접 걸린 자리가 없어서, 둘 다 자기 일에 빠지면 거리가 그대로 벌어지기 쉬워요. 너의 안부 한 줄이 평균보다 더 크게 작용하는 자리예요.',
          '합·충·형 직접 anchor 가 없는 자리 — $shortName과 너 사이엔 작은 의식(약속·기념일·연락)이 관계의 뼈대를 만들어요.',
          '천간·지지 사이의 직접 신호가 약해서 첫 만남부터 자극이 크지 않아요. 그 잔잔함이 매력이라 인정해주면 오래 가는 친구·파트너 후보예요.',
          '직접 anchor 0 — 직접 걸린 끌림 신호가 비어 있는 자리예요. 저절로 흘러가게 두기보다 너의 선택으로 만들어 가는 관계라고 보면 잘 맞아요.',
          '합·충 anchor 없이 평행선처럼 흐르는 자리라, 깊이는 시간이 천천히 쌓아가기 쉬워요. 1년 2년 단위로 길게 점검하는 시야가 잘 맞아요.',
          '직접 걸린 사주 신호가 약한 짝이라 큰 사건이 거의 없어요. 그래서 너희만의 작은 이벤트(이름 같은 카페·정기적인 산책)를 일부러 만드는 게 관계의 색이 돼요.',
          '천간·지지 직접 합·충이 없는 자리 — $shortName과 너 사이는 외부 사건이 관계의 색을 칠하기 쉬운 결이에요. 같이 다양한 자리에 가보세요.',
          '합·충 신호 없는 짝이라 강한 끌림은 적지만, 그만큼 안전한 자리예요. 친구·동료·신뢰 관계 자산으로 활용하기에 최적이에요.',
          '직접 anchor 가 없는 자리 — $shortName과 너 사이는 자연 발화보다 의도적 점화가 어울려요. 둘만의 정기 약속을 캘린더에 표시해두세요.',
          '천간·지지 합·충 직접 신호 없는 자리, 자연스러운 만남보다 의식적 만남이 자산이에요. $shortName과 너 사이엔 약속을 잡는 사람의 노동이 곧 관계의 자산이에요.',
          '합·충 anchor 0 — 자극이 적은 자리라 친구·동료로는 좋고 연애·동업처럼 거리가 가까워지는 자리는 의도적 관리가 필요해요.',
          '직접 걸린 자리 없이 잔잔한 짝 — 크게 부딪힐 일이 적은 결이라 크게 풀어줄 계기도 잘 안 와요. 작은 응어리를 그날 안에 푸는 룰이 보호장치예요.',
          '천간합·지지합·충·형 직접 anchor 없음 — $shortName과 너 사이의 색은 외부 자극(여행·새 친구·이벤트)이 칠해주기 쉬운 결이에요.',
          '직접 신호 없는 짝이라 한 사람이라도 거리를 좁히는 의지가 있는 시기에 관계가 자라요. 그 의지를 가진 사람이 관계의 엔진이에요.',
          '합·충 anchor 없는 자리는 크게 터질 일이 적은 결이에요. 그 안정감을 자기 자리로 끌어들이는 사람만이 이 관계의 깊이를 만들 수 있어요.',
          '직접 anchor 가 없는 만큼 저절로 생기는 끌림은 약해요. 대신 너희 둘이 의식적으로 만든 추억이 둘 사이를 잡아주기 쉬운 자리예요.',
          '천간·지지 직접 신호 약함 — 큰 변화(이사·진로 같은 외부 사건)가 겹치는 시기엔 둘 사이 거리가 벌어지기 쉬워요. 그런 시기일수록 평소보다 자주 안부를 챙기면 거리가 안 벌어져요.',
          '합·충 anchor 0 — 잔잔한 자리라 흥미는 외부에서 끌어와야 해요. 같이 새 사람·새 장소·새 활동을 시도하는 빈도가 관계의 신선도예요.',
          '직접 사주 신호 없이 평행하게 흐르는 자리 — $shortName과 너의 관계는 1년 단위로 봐야 진가가 보여요. 짧게 보지 말고 길게 가세요.',
          '천간·지지 합·충 직접 anchor 부재 — 자연 화학반응은 약하지만 의도적 신뢰 관계는 평균보다 단단하게 자랄 수 있어요.',
          '합·충 anchor 없는 짝이라 사건이 적어요. 사건이 적은 자리에선 누적이 결정적이니까, 작은 약속을 자주 지키는 게 관계 신용 점수예요.',
          '직접 anchor 없는 자리에서 $shortName과 너는 의도적 관계의 모범 사례가 될 수 있어요. 저절로 흘러가게 두지 말고 너희 선택으로 만들어 가는 관계로 봐주세요.',
          // R100 sprint 4 — 32 → 48. NONE pool top-1 collision (FNV-1a bias) 추가 해소.
          '큰 합·충 없는 짝이라 첫 만남부터 잔잔한 결이에요. 잔잔함을 즐기는 두 사람이라면 길게 갈 자리예요.',
          '직접 anchor 없는 자리 — $shortName과 너 사이엔 깊이가 만들어지는 자리가 따로 있어요. 같이 시간을 보내는 그 자리가 곧 깊이의 단위예요.',
          '큰 자극 없는 자리라 일정 협의가 평이해요. 평이함을 잘 다듬으면 안정적인 친구·파트너로 길게 자리잡아요.',
          '직접 신호 약한 만큼, 둘이 함께 보낸 시간의 길이가 평균보다 더 의미를 가져요. 짧게 자주 보는 게 핵심이에요.',
          '합·충·형 직접 anchor 없는 짝 — 저절로 끌리는 힘은 약하고, 의도적으로 챙기는 힘은 강한 결이에요. $shortName과 너의 약속 한 줄이 깊이를 쌓아가기 쉬워요.',
          '큰 anchor 없는 결이라 평소엔 잔잔하지만 큰 자리(여행·이사·진로)에서 합 보는 노력이 자산이에요.',
          '직접 신호 부재 — 둘 다 손을 놓으면 거리가 그대로 벌어지기 쉬워요. 한 명이라도 안부를 챙기는 결이 관계의 엔진이에요.',
          '큰 합·충 없는 자리에선 한 번의 큰 사건보다 매주 한 번의 작은 정성이 큰 의미를 가져요.',
          '직접 anchor 없는 결이라 첫 인상이 평범할 수 있어요. 평범함을 자유로 해석하면 어느 친구보다 가볍게 오래 가요.',
          '신호 없는 자리에서 $shortName과 너는 자연 화학반응보다 의도적 누적이 자산이에요. 약속 한 줄 한 줄이 관계 신용 점수가 돼요.',
          '큰 anchor 부재 — 자극은 외부에서 끌어와야 해요. 새 자리·새 사람·새 활동을 같이 가는 빈도가 관계의 신선도예요.',
          '직접 신호 없는 자리라 둘 사이 깊이는 사주가 정하지 않고 너희가 정해요. 둘만의 정기 약속이 관계의 색이에요.',
          '큰 합·충 부재 — 자연 끌림 약함, 의도 신뢰 강함. 저절로 흘러가게 두지 말고 너희 선택으로 길게 만들어 가기 좋은 결이에요.',
          '직접 anchor 없는 결 — 외부 사건(이사·진로 같은 변화)이 겹치면 $shortName과 너 사이 거리가 벌어지기 쉬워요. 그런 시기일수록 평소보다 자주 안부를 챙기면 거리가 안 벌어져요.',
          '큰 자극 없는 자리에선 작은 디테일이 결의 색을 만들어요. 너희만의 작은 습관(이름 같은 카페·정기 산책)이 자산이에요.',
          '합·충·형 직접 anchor 없는 짝 — 자연 발화가 약한 만큼 인공 발화에 능숙해지면 자연 관계보다 단단한 자리로 키울 수 있어요.',
        ];
        parts.add(pick('dailyNONE_K', pool));
      }
    } else {
      if (sameDay) {
        // R100 sprint 4 — 4 → 16 variants. baseline 의 4-variant slot collision
        // (FNV-1a + 같은 일주 셀럽 다수 → top-1 ≥ 11) 해소.
        final pool = [
          "Both ${me.day60ji} day pillar — a mirror seat. What $shortName picks up tends to surface in you before long, and your shifts tend to read back fast.",
          "Same ${me.day60ji} day pillar pair — one person's shift tends to look like the other's here. $shortName and you tend to pick up each other's modes fast.",
          "Twin ${me.day60ji} pillars means decision tone and word choice tend to overlap closely. To avoid wobbling together, agree to slow one of you on the biggest calls.",
          "Same ${me.day60ji} pillar — strengths and weak spots tend to sit in sync. Recovery seasons tend to go better paced together than pushed against.",
          "Mirror pair on ${me.day60ji} — preferred scent, preferred sound, decision speed all tend to touch the same line. Sometimes one of you taking a different pace becomes the balance.",
          "${me.day60ji} day pillar twin — your ups and downs tend to move in similar shapes. On the days $shortName dips, the load can land heavier on you, so promise a recovery routine in advance.",
          "Same ${me.day60ji} pair — a first meeting can read like seeing someone you've known a long time. Small differences can read bigger because you are this similar, so take the differences as signal, not blame.",
          "Twin ${me.day60ji} — in a single line of conversation you both tend to catch the same meaning. The parts $shortName trims short, you tend to fill in on your own — so build a habit of speaking the trimmed part out loud once in a while.",
          "${me.day60ji} mirror pair — weak spots tend to soften together. If one of you loses balance, the other turning on outside resources (a friend, a workout, a walk) is the steadying move.",
          "Same ${me.day60ji} day pillar — both of you tend to stall in front of large decisions. If one freezes, the other starting with a small decision is the recovery rule.",
          "${me.day60ji} day pillar twin — preferred seats, preferred hours, preferred meals all tend to sit near the same axis. New stimulus runs thin, so once a month go to an unfamiliar place together.",
          "Same ${me.day60ji} pillar — strengths overlap, so getting absorbed in the same task tends to slow recovery. On big work, agree that one of you steps back half a pace.",
          "${me.day60ji} pair — conflict and apology both tend to end fast here. Quick repair is your habit, so once in a while linger in the resolution to reach deeper ground.",
          "Twin ${me.day60ji} — neither of you offers your inner color to others easily, so first words tend to get postponed. Rotate who opens the line each time.",
          "${me.day60ji} pair — two people each with your own pace, so decision speed rarely clashes. Keep your shared decision tempo above outside pressure.",
          "Same ${me.day60ji} day pillar — alike enough to feel easy, alike enough that it can feel stuck. A small daily ritual of difference (different book picks, different cafe choice) becomes the air this pair breathes.",
        ];
        parts.add(pick('dailySD_E', pool));
      } else if (sameBranch) {
        final pool = [
          "Shared day branch ($myJi) — life rhythm, season, and pace tend to align. Your $mySceneEn reaches $shortName naturally.",
          "$myJi branch shared — season, time-of-day, even eating habits tend to match. Weekday paths between $shortName and you cross naturally.",
          "Branch ($myJi) shared — life rhythm runs at the same tempo, so scheduling is easy. Rest patterns between $shortName and you also flow alike.",
          "Same branch ($myJi) means condition spikes hit in the same season. $shortName's pace and yours align in one pitch over time.",
          "Shared $myJi branch — recovery method aligns too, so resting-place suggestions tend to overlap. $shortName and you blend recovery routines effortlessly.",
          "Branch ($myJi) shared — preferred hours, noise levels, room temperature all tend to sit near the same axis. The room tone tends to settle on its own when you two are in it.",
          "Same $myJi branch pair — good weeks in a month run similar; quiet rain settles you both at once. The silence between $shortName and you is in the same key.",
          "Shared $myJi branch — preferred scents, preferred sounds, preferred textures overlap often. Picking small gifts becomes nearly thoughtless here.",
          "Same branch ($myJi) — sleep times and wake times naturally align. Living or working together keeps schedule conflicts low.",
          "Branch ($myJi) shared — preferred cafes and preferred routes tend to run on the same wavelength. Weekday walks between $shortName and you head the same direction naturally.",
          "Same $myJi branch — recovery styles after conflict line up. If one of you needs distance, the other not pushing it is the natural move.",
          "$myJi branch pair — both of you find lateness similarly hard, so time agreements between you stay precise on their own.",
          "Same $myJi branch — preferred company-time settings breathe at the same pitch. Introvert mode and extrovert mode flip on at the same hour for the two of you.",
          "Branch ($myJi) shared — small daily choices (where to eat, what route to walk) settle fast. Slow the bigger choices by a deliberate beat for balance.",
          "Same $myJi branch pair — you tend to tire in the same season and recover in the same season. That shared rhythm is the charm, but plant one outside friend into the schedule during shared low seasons.",
          "Shared $myJi branch — preferred bedroom temperature and preferred silence-length both align, so sharing space feels natural. The silence-rule between you becomes the color of the bond.",
        ];
        parts.add(pick('dailySB_E', pool));
      }
      if (ganHap) {
        final pool = [
          "Heavenly stem union ($myGan-$stGan) — a pull that tends to read magnetic early. It is strong enough that one of you can lose their own color, so an agreed pace matters.",
          "Stem union ($myGan-$stGan) — pull is strong from the first beat. With strong pull comes the risk of erasing your own color; protect your pace consciously.",
          "Heavenly stem ($myGan-$stGan) aligned — first impression sticks deep. To avoid being swept by that impression, set your own decision criteria in advance.",
          "Stem alignment ($myGan-$stGan) — natural chemistry tends to run high here. A strong pull asks for steady care.",
          "Stem union ($myGan-$stGan) — even short exchanges generate above-average pull. Keeping small promises becomes the unit of trust here.",
          "Heavenly stem ($myGan-$stGan) bond — first impressions etch deep, and so do their afterimages once distance comes. Hold your standards visible at the very beginning.",
          "Stem union ($myGan-$stGan) — atmosphere can carry both of you into fast decisions. Set a private 24-hour rule (sleep on the big calls).",
          "Heavenly stem ($myGan-$stGan) — in front of $shortName, larger choices come out lighter than usual. Re-read those choices the next morning before acting.",
          "Stem union ($myGan-$stGan) aligned — the room can feel the breath between you. Build in third-seat moments (one friend in the room) so the pull does not isolate.",
          "Stem union ($myGan-$stGan) — one of the most intuitive pulls a pairing can carry. Pair fast-start moments with deliberately slow stretches to keep balance.",
          "Heavenly stem ($myGan-$stGan) bond — a pull this strong can be easy to fall back into. After any ending, sitting with it at least six months is a steadying private rule.",
          "Stem union ($myGan-$stGan) — meaning travels deeper than words. Same silences can mean different things, so schedule regular voice-checks.",
          "Heavenly stem ($myGan-$stGan) — emotional ignition tends to run faster than average. The bond can read strong from the outside too, so plant a shared rule against being shaken by one friend's comment.",
          "Stem union ($myGan-$stGan) — shifts tend to travel between you fast. Praise the good ones on the spot; voice the harder ones after one beat of pause.",
          "Heavenly stem ($myGan-$stGan) — shared time passes faster than measured time. Keep a calendar log so the days stay anchored.",
          "Stem union ($myGan-$stGan) — pull is high enough to dilute self-decision. Reserve one solo decision-window a week to keep your own color.",
        ];
        parts.add(pick('dailyGH_E', pool));
      }
      if (jiHap6) {
        final pool = [
          "Six harmony ($myJi-$stJi) — daily breath syncs. Your $mySceneEn and $shortName's $stSceneEn drift into one timeline.",
          "Six harmony ($myJi-$stJi) — weekday paths cross effortlessly. Your $mySceneEn and $stSceneEn fold into the same page.",
          "Hap6 ($myJi-$stJi) pair — time slots, plans, moods align with almost no effort. A two-person routine forms naturally.",
          "Six harmony ($myJi-$stJi) — your $mySceneEn tends to flow in the same rhythm as $shortName's $stSceneEn. A smooth-running daily branch pairing.",
          "Hap6 ($myJi-$stJi) — both of you keep time well, so meeting up rarely takes effort. A quiet bridge sits between $mySceneEn and $stSceneEn.",
          "Six harmony ($myJi-$stJi) — being together does not ask either of you to manufacture mood. Silence is not uncomfortable here.",
          "Hap6 ($myJi-$stJi) bond — sudden schedule changes settle quickly. Mismatched plans rarely become arguments in this pair.",
          "Six harmony ($myJi-$stJi) — meal times, sleep times, walking routes tend to drift together. Living together or working together suits this daily rhythm.",
          "Hap6 ($myJi-$stJi) — small breaths align even in a single sigh. The wins here are tiny daily harmonies more than one big union.",
          "Six harmony ($myJi-$stJi) aligned — reaching agreement takes less time than average. Spend the saved time on deeper conversation, not on filler.",
          "Hap6 ($myJi-$stJi) — small daily agreements come easily, so big agreements feel natural too. Schedule periodic time to draw the bigger picture together.",
          "Six harmony ($myJi-$stJi) — both of you respect your own time, so distance gets handled naturally. Not stepping too close is itself a form of harmony.",
          "Hap6 ($myJi-$stJi) pair — recovery from conflict has a short arc. One line of apology can carry the meaning of a long one.",
          "Six harmony ($myJi-$stJi) — being together invites your truer face out. In front of $shortName, you become more candid more easily.",
          "Hap6 ($myJi-$stJi) — the depth of meeting matters more than the frequency. Short visits between $shortName and you carry full weight.",
          "Six harmony ($myJi-$stJi) bond — daily agreement is natural, so big moves (travel, relocation, job changes) flow smoother when planned together.",
        ];
        parts.add(pick('dailyJH6_E', pool));
      } else if (jiSamhap) {
        final pool = [
          "Triad partial ($myJi-$stJi) — synergy peaks around shared goals. Your $mySceneEn plus $stSceneEn fits building one project together.",
          "Triad partial ($myJi-$stJi) — in front of a shared target, synergy tends to rise above average. It tends to suit a collaborator bond even more than a friendship-only one.",
          "Triad partial ($myJi-$stJi) — coordination flows when there's a big-picture goal. $mySceneEn and $stSceneEn meet inside a new project.",
          "Triad partial ($myJi-$stJi) — your hands and feet sync best in front of a shared big-picture goal. Travel, work, challenge projects all suit this pair.",
          "Triad partial ($myJi-$stJi) — once direction lines up, drive runs above average. Define the larger goal early for efficiency.",
          "Triad partial ($myJi-$stJi) — hands and feet sync at work. Where you really shine is making something together, more than daily catching up.",
          "Triad partial ($myJi-$stJi) bond — once aimed the same way, breath aligns within a single beat. If aim diverges, drive falls together.",
          "Triad partial ($myJi-$stJi) — the brightest harmony with a shared goal. Project mode beats dating mode; cooperation beats socializing.",
          "Triad partial ($myJi-$stJi) — short windows yield big outputs. Short challenges, seasonal projects, travel plans bring out the union.",
          "Triad partial ($myJi-$stJi) — when direction is shared, outside resources tend to gather toward the pair — friends, venues, and advice can come in more easily.",
          "Triad partial ($myJi-$stJi) bond — pacts you make hold against outside shaking. Casual commitments here can grow into outsized results.",
          "Triad partial ($myJi-$stJi) — one partner's gap is filled by the other without role-talk. Flow forms even without explicit role-splitting.",
          "Triad partial ($myJi-$stJi) — co-events (working, training, traveling) outshine daily routines for this pair. Event-time is the natural habitat.",
          "Triad partial ($myJi-$stJi) — both of you are result-leaning, so big goals lock harmony fast. Write the schedule and budget down from day one.",
          "Triad partial ($myJi-$stJi) bond — settle the big picture first, and the details follow on their own. The opening sketch matters most.",
          "Triad partial ($myJi-$stJi) — pointed in the same direction, the pair output sits a notch above average. Plant regular shared challenges into the calendar.",
        ];
        parts.add(pick('dailyJSH_E', pool));
      }
      if (jiClash) {
        final pool = [
          "Branch clash ($myJi-$stJi) — friction in big decisions, moves, money. Your $mySceneEn versus $shortName's $stSceneEn run on opposite clocks; pre-agree rules.",
          "Branch clash ($myJi-$stJi) — opposite sides surface in big calls. A pre-set rule between the two of you handles it most effectively.",
          "Clash ($myJi-$stJi) — daily tone is fine but big seats (travel, money, career) split opinions. Talk it out instead of going silent.",
          "Branch clash ($myJi-$stJi) — your $mySceneEn and $shortName's $stSceneEn can flow in opposite directions on the same square. Pre-agree concrete items (schedule, budget).",
          "Clash ($myJi-$stJi) — closer distance makes small differences feel larger. Building regular distance is paradoxically what stabilizes this bond.",
          "Branch clash ($myJi-$stJi) — both of you carry a clear shape, so the same seat can produce opposite answers. A short pact to honor both is the safety net.",
          "Clash ($myJi-$stJi) — big calls split opposite, so dividing responsibility ahead of time flattens the friction.",
          "Branch clash ($myJi-$stJi) — small everyday differences read as fresh stimulus, but the same shape becomes load in big seats. Bring one outside voice to share the big calls.",
          "Clash ($myJi-$stJi) — being together energizes the pair, so stimulus is plentiful. Keep the stimulus from sliding into conflict with a 24-hour repair routine.",
          "Branch clash ($myJi-$stJi) — both of you tend to lean toward your own read in big calls. The protective rule is sleeping on the call one more night.",
          "Clash ($myJi-$stJi) bond — conflict swings wide, but so does recovery. Small kindness after a clash carries above-average meaning.",
          "Branch clash ($myJi-$stJi) — plentiful stimulus suits adventurous settings. New places, new activities, new groups together is the preventive form of harmony.",
          "Clash ($myJi-$stJi) — disagreement in big calls is high, so practicing agreement in small calls is the disproportionate asset here.",
          "Branch clash ($myJi-$stJi) — the same seat tends to produce different reads, so what you see together is wider than what either of you sees alone. Frame the other read as a resource, not a threat.",
          "Clash ($myJi-$stJi) — stimulus is high, so if either of you under-rests, conflict risk rises. Negotiating recovery time is the protective rule.",
          "Branch clash ($myJi-$stJi) — friction in big seats softens when you write the decision items down. Written items turn large clashes into small adjustments.",
        ];
        parts.add(pick('dailyJC_E', pool));
      }
      if (jiHyeong) {
        final pool = [
          "Branch punishment ($myJi-$stJi) — sharp words can surface. A short 'thanks' or 'good job' every day keeps the big blow-up away.",
          "Branch punishment ($myJi-$stJi) — one line occasionally lands sharper than usual. Doubling everyday gratitude blunts that line.",
          "Hyeong ($myJi-$stJi) pair — a small spark can spread. A within-24h apology-and-repair routine right after conflict is the safety net.",
          "Branch punishment ($myJi-$stJi) — usually good, occasionally tone splits. On low-condition days, postpone heavy conversation by mutual agreement.",
          "Hyeong ($myJi-$stJi) — one word can carry above-average weight. Before the weight becomes pressure, keep a handful of light phrasings ready.",
          "Branch punishment ($myJi-$stJi) — both of you prefer clear phrasing over hedged phrasing, and the clarity sometimes lands as sharpness. Stock one rung of softer vocabulary deliberately.",
          "Hyeong ($myJi-$stJi) bond — recovery from conflict tends to take longer than average. Apology fast, reconciliation slow — that tends to be the natural order.",
          "Branch punishment ($myJi-$stJi) — small wording differences read as large signals here. A kinder phrasing of the same meaning is wealth.",
          "Hyeong ($myJi-$stJi) — both of you sense your own space with clarity, so boundaries can bump. Voice respect for each other's space often.",
          "Branch punishment ($myJi-$stJi) — closer distance accumulates micro-collisions. Periodic distance (solo time, outside friends) is the cleanser.",
          "Hyeong ($myJi-$stJi) — small sparks can catch a little more easily here. Stocking warm everyday phrasing tends to keep small sparks from growing into big ones.",
          "Branch punishment ($myJi-$stJi) — both of you hold opinions with clarity, so let diversity be the opening rule, not the result of a fight.",
          "Hyeong ($myJi-$stJi) bond — short rubs appear regularly, but big incidents are rare. Solving small rubs within the day is the cumulative asset.",
          "Branch punishment ($myJi-$stJi) — your color stands out together, so the protective view is reading other colors as freshness, not threat.",
          "Hyeong ($myJi-$stJi) — small conflicts arrive on a steady cycle. Reading that cycle on a monthly graph helps the bond stay even.",
          "Branch punishment ($myJi-$stJi) bond — both of you carry your own shape plainly, so the natural posture is recognizing both shapes rather than merging them.",
        ];
        parts.add(pick('dailyJHY_E', pool));
      }
      if (parts.isEmpty) {
        final pool = [
          "No direct stem-branch union or clash. Depth here tends to build as your $mySceneEn and $shortName's $stSceneEn overlap over time — time does the work.",
          "No direct union/clash signal here, so natural ignition arrives slowly. Depth between $shortName and you is built by time, not by events.",
          "Neither big union nor big clash — first impressions stay calm. Calm seats have no big eruption and no big recovery; small kept promises become amplitude.",
          "No direct anchor between heavenly stems or earthly branches. Intentional meeting tends to shape depth more than natural chemistry here.",
          "No direct union/clash present — daily tone stays mellow. Keep mellowness from sliding into boredom by adding regular outside stimulus (travel, hobbies, new faces).",
          "Union/clash/punishment signals don't connect directly — the asset here is deliberate accumulation. Small promises kept often become depth units.",
          "Without direct anchors, mutual laziness freezes the bond. Either of you booking the next plan is itself the amplitude of this relationship.",
          "In no-anchor seats accumulation outranks events. Between $shortName and you, one line in a small message carries more weight than average.",
          "Direct stem-branch signal is faint, so there's neither strong pull nor heavy friction here. Read the lack of weight as freedom — a bond that can run long when you tend it.",
          "Without union/clash anchors, natural ignition is rare; but once you both adapt to intentional ignition, the bond can become more precise than natural pairs.",
          "Direct anchor missing, so the bond pauses if both sink into solo work. One check-in line from you carries more weight than usual.",
          "No direct union/clash/punishment anchor — small rituals (meetings, anniversaries, replies) form the skeleton between $shortName and you.",
          "Direct signal between stem and branch is weak; first impressions don't carry strong stimulus. Acknowledging that calm as charm produces a long-haul friend or partner.",
          "Zero direct anchors — no direct pull signals here. Rather than leaving it to drift, treat this as a bond grown by your choices.",
          "Union/clash anchors absent, energies parallel — depth is on the clock. Annual reviews of the bond's depth are the right lens.",
          "Direct anchor signal is faint between $shortName and you, so big events are rare. Crafting your own tiny events (a named café, a regular walk) becomes the bond's color.",
          "No direct union/clash between stems and branches — outside events decide the color of the bond between $shortName and you. Visit different settings together.",
          "Without union/clash signals strong pull is rare, but so is risk. Optimal as a friend, colleague, trust-relationship asset.",
          "Direct anchor missing — intentional ignition fits this seat better than spontaneous combustion. Mark a recurring date on the shared calendar.",
          "No direct stem/branch union/clash — intentional meetings outperform spontaneous ones. Whoever books plans builds the bond's amplitude.",
          "Zero union/clash anchors — low stimulus seat. Great for friendship, careful management needed for romance or partnership.",
          "Mellow pair with no direct anchor — major fights are rare and so are major repairs. Tiny knots resolved same-day prevent bigger knots.",
          "Heavenly stem/branch union/clash/punishment all absent — outside stimulus (travel, new friends, events) defines the color between $shortName and you.",
          "Direct signal absent — the bond grows in seasons when at least one person actively closes the distance. That person is the engine of the relationship.",
          "Without union/clash anchors, big eruptions are rare. Only the person who claims the calm as their seat builds depth in this kind of bond.",
          "No direct anchor means the spontaneous pull is weak. The memories the two of you build deliberately step in and help hold the bond instead.",
          "Direct stem/branch signal weak — when big outside changes (moves, career shifts) overlap, the bond is easy to shake. Checking in more often through those stretches keeps the distance from widening.",
          "Zero union/clash anchors — calm seat with little curiosity. Pull curiosity in from outside; frequency of new people, new places, new activities defines freshness.",
          "No direct anchor between the two of you, parallel flow — the real value of $shortName and you tends to show on a year-plus arc. Play long.",
          "Stem/branch direct anchor absent — natural chemistry is weak, but intentional trust can grow steadier than average pairs.",
          "Union/clash anchors absent — events are rare. In rare-event seats accumulation decides, so kept small promises become long-term credit.",
          "No direct anchor seat — $shortName and you could be the textbook case of an intentional bond. Don't lean on fate; treat this as a bond grown by choice.",
          // R100 sprint 4 — 32 → 48. Top-1 collision (FNV-1a bias) 추가 해소.
          "Without big union or clash, first meeting reads calm. Two people who can enjoy calm sustain the bond long.",
          "No direct anchor — between $shortName and you, the seat where depth forms is separate. Time together in that seat is itself the unit of depth.",
          "Without big stimulus, scheduling stays plain. Polished plainness becomes a steady friend or partner role over the long arc.",
          "Direct signal faint, so the length of time spent together carries above-average meaning. Short and frequent visits hold the key.",
          "Union, clash, and punishment anchors all absent — natural chemistry quiet, intentional chemistry strong. A single promise line between $shortName and you tends to shape the depth.",
          "Without a big anchor, daily tone stays mellow, but pre-aligning for big seats (travel, relocation, career) becomes the real asset.",
          "Direct signal absent — if both of you go lazy, the bond drifts toward dormancy. One person keeping check-ins is the engine.",
          "Without big union or clash, one small consistent care weekly outweighs one big rare event.",
          "Direct anchor absent — first impression may read ordinary. Reading ordinariness as freedom lets this bond run long when you tend it.",
          "In no-signal seats, $shortName and you rely on intentional accumulation more than natural chemistry. Each promise line becomes credit on the relationship.",
          "Big anchor missing — stimulus must be pulled in from outside. Frequency of new seats, new people, new activities defines this bond's freshness.",
          "Direct signal absent — depth between you is not fixed in advance; it takes shape from how the two of you show up. Regular shared rituals become the bond's color.",
          "Big union/clash absent — natural pull weak, deliberate trust strong. Don't lean on fate; the bond grows long by your choices.",
          "Direct anchor missing — time between $shortName and you is easy to shake when big outside changes (moves, career shifts) overlap. Checking in more often through those stretches protects the bond.",
          "Without big stimulus, small details define the color. Your own tiny habits (a named café, a regular walk) become the asset.",
          "Union, clash, and punishment all absent — natural ignition weak, so getting fluent in intentional ignition turns the bond into something stronger than natural pairs.",
        ];
        parts.add(pick('dailyNONE_E', pool));
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
    required int seed,
  }) {
    final strong = [
      sameDay,
      ganHap,
      jiHap6,
      jiSamhap,
      sameBranch,
    ].where((b) => b).length;
    final weak = [jiClash, jiHyeong].where((b) => b).length;
    // R100 sprint 2 — band 5 × 16+ variants (70-85 band 32 variants).
    // band prefix 자체를 variant 풀에서 picking 하여 5 fixed prefix 가 60+ 명에게
    // 똑같이 노출되던 baseline 을 깨트림.
    int bandIdx;
    if (score >= 85) {
      bandIdx = 0;
    } else if (score >= 70) {
      bandIdx = 1;
    } else if (score >= 55) {
      bandIdx = 2;
    } else if (score >= 40) {
      bandIdx = 3;
    } else {
      bandIdx = 4;
    }

    if (useKo) {
      const bandPoolsKo = <List<String>>[
        // 85+
        [
          '두 사주가 강하게 끌리는 인연 — ',
          '두 사주의 합 신호가 적극적으로 밀어주는 자리 — ',
          '천간·지지 anchor 가 함께 받쳐주는 합 — ',
          '강한 끌림 신호가 정확히 모인 자리 — ',
          '두 사주가 가깝게 묶이는 인연 — ',
          '복합 anchor 가 같이 걸린 진한 흐름 — ',
          '강한 끌림 신호가 다중으로 정렬된 자리 — ',
          '두 사주 신호가 한 방향으로 정돈된 진한 자리 — ',
          '여러 합 신호가 한 페이지에 모인 흐름 — ',
          '강한 anchor 가 줄지어 자리잡은 자리 — ',
          '복수의 끌림 신호가 같은 톤으로 정렬된 자리 — ',
          '두 사주가 크게 묶이는 인연 — ',
          '천간 합과 지지 신호가 동시에 받쳐주는 진한 자리 — ',
          '강하게 묶인 anchor 가 한 자리에 모인 흐름 — ',
          '두 사주가 신뢰로 깊이 묶이는 자리 — ',
          '강한 합 신호가 합쳐서 한 페이지를 만든 자리 — ',
        ],
        // 70-84 (32 variants — 가장 흔한 band)
        [
          '두 사주가 비교적 우호적으로 만나는 흐름 — ',
          '두 사주 신호가 부드럽게 우호적인 자리 — ',
          '안정 anchor 가 한 줄 받쳐주는 흐름 — ',
          '두 사주 사이에 잔잔한 호의가 깔린 자리 — ',
          '천간·지지 신호가 잔잔하게 호의적인 자리 — ',
          '두 사주가 안정 합으로 만나는 자리 — ',
          '큰 신호 없이 부드러운 호의가 깔린 자리 — ',
          '안정 anchor 가 한 줄 자리잡은 진한 자리 — ',
          '두 사주가 무난하게 잘 맞는 자리 — ',
          '잔잔한 호의 신호가 한 톤 안에 모인 자리 — ',
          '천간·지지 anchor 가 부드러운 톤으로 정렬된 자리 — ',
          '안정 anchor 한 줄이 받쳐주는 자리 — ',
          '편안한 anchor 가 한 자리에 자리잡은 흐름 — ',
          '큰 합·충 없이 부드러운 친화가 깔린 자리 — ',
          '두 사주가 호의로 만나는 자리 — ',
          '안정 anchor 가 자연스럽게 받쳐주는 자리 — ',
          '두 사주 신호가 한쪽으로 살짝 기울어 호의적인 자리 — ',
          '부드러운 호감 신호가 줄지어 정돈된 자리 — ',
          '천간 합·지지 신호가 잔잔히 정렬된 자리 — ',
          '두 사주가 무리 없이 잘 맞는 자리 — ',
          '안정 anchor 가 일상 톤을 받쳐주는 자리 — ',
          '편안한 합 신호가 자리잡은 자리 — ',
          '큰 자극 없이 호의가 정돈된 자리 — ',
          '두 사주가 가볍게 끌리는 흐름 — ',
          '잔잔한 호의 anchor 가 자리잡은 흐름 — ',
          '천간·지지 신호가 한 톤 부드럽게 정렬된 자리 — ',
          '편안한 anchor 한 줄이 받쳐주는 자리 — ',
          '큰 합 없이도 자연스러운 호의가 깔린 자리 — ',
          '두 사주 사이에 호의가 깔린 자리 — ',
          '안정 anchor 가 일상 톤으로 자리잡은 흐름 — ',
          '천간·지지 신호가 호의 쪽으로 살짝 기운 자리 — ',
          '부드러운 친화 anchor 가 자리잡은 자리 — ',
        ],
        // 55-69
        [
          '강한 끌림도 강한 마찰도 없는 흐름 — ',
          '두 사주가 중립적으로 만나는 자리 — ',
          '신호가 한쪽으로 강하게 기울지 않은 자리 — ',
          '천간·지지 anchor 가 평행하게 흐르는 자리 — ',
          '한 줄로 정리하기 어려운 균형 자리 — ',
          '큰 호의도 큰 마찰도 없는 잔잔한 자리 — ',
          '결이 너희 선택에 더 달려 있는 자리 — ',
          '천간·지지 신호가 한쪽으로 치우치지 않은 자리 — ',
          '안정도 자극도 어느 한쪽이 강하지 않은 자리 — ',
          '두 사람의 노력이 무게를 더 가지는 자리 — ',
          '신호가 균형 잡힌 가운데 자리 — ',
          '한 쪽으로 답이 안 기우는 균형 자리 — ',
          '천간·지지 anchor 가 양 끝을 잡는 자리 — ',
          '큰 끌림도 큰 거부도 없는 잔잔한 자리 — ',
          '두 사람의 의도가 무게를 더 가지는 자리 — ',
          '신호 균형 자리 — ',
        ],
        // 40-54
        [
          '한 박자 조심해서 다루면 좋은 흐름 — ',
          '신호가 살짝 조심할 자리를 비추는 흐름 — ',
          '천간·지지 anchor 가 한쪽에 작은 자극을 두는 자리 — ',
          '한 박자 늦춰서 다루면 좋은 자리 — ',
          '잔잔한 마찰 anchor 가 한 줄 보이는 자리 — ',
          '신중함이 자산이 되기 쉬운 자리 — ',
          '천간·지지 신호가 살짝 어긋난 자리 — ',
          '의식적인 절제가 도움 되는 자리 — ',
          '큰 충돌은 없지만 마찰 자리가 한 줄 보이는 자리 — ',
          '두 사람의 인내가 무게를 가지는 자리 — ',
          '천간·지지 anchor 가 살짝 갈라진 자리 — ',
          '한 박자 조심해서 다루면 좋은 자리 — ',
          '잔잔한 자극 anchor 가 자리잡은 자리 — ',
          '신호가 살짝 어긋난 채로 흐르는 자리 — ',
          '큰 합은 없지만 작은 자극이 살아 있는 자리 — ',
          '의식적인 거리감이 도움 되는 자리 — ',
        ],
        // <40
        [
          '깊이 가까이 갈수록 조심해서 다루면 좋은 흐름 — ',
          '천간·지지 anchor 가 큰 자극을 두는 자리 — ',
          '강하게 조심해서 다루면 좋은 자리 — ',
          '큰 충돌 anchor 가 자리잡은 흐름 — ',
          '깊은 거리감이 도움 되는 자리 — ',
          '신호가 강한 자극 쪽으로 정렬된 자리 — ',
          '강한 신중함이 자산이 되기 쉬운 자리 — ',
          '천간·지지 신호가 정반대로 정렬된 자리 — ',
          '깊은 절제와 거리두기가 도움 되는 자리 — ',
          '큰 자극 anchor 가 한 줄에 모인 자리 — ',
          '직선적인 끌림이 잘 안 일어나는 자리 — ',
          '천간·지지 anchor 가 강하게 갈라진 자리 — ',
          '신호가 마찰 쪽으로 정돈된 자리 — ',
          '큰 마찰 anchor 가 줄지어 자리잡은 자리 — ',
          '한 박자 깊은 거리두기가 도움 되는 자리 — ',
          '천간·지지 신호가 강한 거리 쪽으로 정렬된 자리 — ',
        ],
      ];
      final pool = bandPoolsKo[bandIdx];
      final idx = _KpopAnchors.saltedPick('bandK_$bandIdx', '$seed', pool.length);
      final band = pool[idx];

      // anchor line — 16+ variants 매트릭스. strong+weak count 별 분기.
      String anchorLine;
      if (strong + weak == 0) {
        // R100 sprint 4 — 16 → 32 variants. NONE branch (95+ 셀럽 hit) 의 anchor
        // line top-1 collision 해소.
        const noAnchorPool = [
          '직접 걸린 큰 자극 없이 무게가 옅은 자리라 너의 시간은 의식적으로 깊이를 만들 때만 자라요.',
          '직접 anchor 가 없는 만큼 저절로 가까워지는 힘은 약해도, 둘이 의도적으로 챙기는 만큼 깊이가 쌓이기 쉬워요.',
          '큰 자극 없는 자리라 작은 약속의 누적이 가장 큰 자산이에요.',
          '직접 신호 없는 자리에서는 의도적 만남이 곧 깊이의 단위가 돼요.',
          '직접 anchor 가 없는 만큼 인공 화학반응(이벤트·여행·새 자리)이 관계의 색이 돼요.',
          '큰 anchor 없이 잔잔한 자리라, 한 명이 먼저 약속을 잡는 만큼 관계가 더 살아나기 쉬워요.',
          '직접 걸린 자리 0 — 자연 발화 약함, 의도 발화 강함. 둘의 결정이 곧 관계의 깊이예요.',
          '신호 없는 자리에서는 누적이 결정적이에요. 작은 한 줄·한 메모가 평균보다 두 배 작용해요.',
          '큰 자극 없는 자리라 저절로 흘러가게 두지 말고 너희 선택으로 관계를 가꿔보세요.',
          '직접 anchor 0 — 자유로운 자리. 어느 친구보다 가볍게 오래 갈 수 있는 자리예요.',
          '신호가 약한 만큼 사건보다 누적이 결정적이에요. 작은 메시지가 자산이 돼요.',
          '큰 자극 없는 자리, 의도 관계의 모범 사례가 될 수 있는 자리예요.',
          '직접 anchor 없는 자리에서는 한 사람의 의지가 곧 엔진이 돼요.',
          '큰 합·충 없는 자리라 잔잔한 친구·파트너로 길게 자리잡을 수 있어요.',
          '신호 없는 만큼 새 자극(여행·새 사람·새 활동)을 자주 들이면 관계가 더 신선해지기 쉬워요.',
          '직접 자극 없는 자리는 1년·2년 단위로 봐야 진가가 드러나요.',
          '큰 합·충 없는 짝이라 첫 만남부터 잔잔한 결이에요. 잔잔함을 즐길 줄 아는 두 사람이면 길게 가는 자리예요.',
          '직접 신호 약한 자리라 정기적인 안부 한 줄을 챙기면 관계의 색이 또렷해지기 쉬워요.',
          '큰 anchor 부재 — 자연 화학반응 약함, 단 의도 화학반응은 평균보다 단단해요.',
          '신호 없는 만큼 외부 자극(공통 관심사·새 활동·새 사람)이 관계의 산소가 돼요.',
          '직접 자극 없는 자리는 처음엔 평이하지만 누적이 큰 결을 만드는 자리예요.',
          '큰 합·충 없는 결이라, 한 사람이 거리를 좁히려 움직이는 만큼 관계가 더 살아나기 쉬워요.',
          '직접 anchor 0 — 자연 발화 약함, 그래서 한 명이라도 정기 약속을 챙기는 결이 자산이에요.',
          '신호 없는 자리라 큰 사건이 적은 만큼 작은 일상 디테일이 관계의 색이 돼요.',
          '큰 자극 없는 자리에선 사건보다 시간이 깊이를 쌓아가기 쉬워요. 1년 단위로 길게 보세요.',
          '직접 anchor 부재 — 자연 발화 약함, 의도 발화 강함, 그래서 관계는 너희 선택으로 자라요.',
          '큰 합·충 없는 결이라 자기 색을 잃을 위험이 적어요. 안정적인 친구·파트너 자리예요.',
          '신호 없는 자리에선 한 사람의 정성이 관계 깊이의 단위가 돼요. 작은 정성을 챙기세요.',
          '직접 자극 약한 자리라 큰 다툼이 적은 만큼 큰 회복도 어려워요. 작은 응어리는 그날 안에 풀어보세요.',
          '큰 anchor 없는 자리 — 너의 시간은 평이하지만 길게 흐르는 자리예요.',
          '직접 신호 없는 만큼 사건이 적고, 그래서 한 약속 한 약속이 평균보다 무게를 가져요.',
          '큰 합·충 부재 — 자연 끌림은 약하지만 의도적 신뢰는 평균보다 단단하게 자랄 수 있는 결이에요.',
        ];
        final idx2 = _KpopAnchors.saltedPick('bandKAnch0', '$seed', noAnchorPool.length);
        anchorLine = noAnchorPool[idx2];
      } else {
        final partsList = <String>[];
        if (strong > 0) partsList.add('강하게 끌어주는 자리 $strong개');
        if (weak > 0) partsList.add('조심해야 할 자리 $weak개');
        final anchorSummary = partsList.join(' / ');
        const anchorTailsKo = [
          '함께 있어서 너의 시간이 단순한 호감이 아니라 사주 흐름으로 새겨져요.',
          '자리잡혀 있어서 너의 시간이 평균보다 진하게 기록돼요.',
          '깔려 있어서 둘 사이의 의미가 한 단계 진하게 자리잡아요.',
          '등록되어 있어서 너의 일상에 평균보다 더 진한 줄로 남아요.',
          '같이 걸려 있어서 둘의 추억이 평균보다 길게 남아요.',
          '한 페이지에 모여 있어서 너의 시간이 평소보다 더 정돈되게 새겨져요.',
          '자리잡혀 있어서 관계의 무게가 사주 신호로도 단단해요.',
          '함께 있어서 둘의 일상이 사주 신호로도 잔잔하게 받쳐져요.',
          '한 자리에 모여 있어서 두 사람의 시간이 평균 이상으로 진하게 흘러요.',
          '줄지어 자리잡혀 있어서 둘 사이가 사주 신호로도 또렷해요.',
          '한 페이지에 정돈되어 있어서 관계의 깊이가 평소보다 한 단계 진해요.',
          '함께 자리잡혀 있어서 너의 시간이 평균보다 더 진하게 기록돼요.',
          '겹쳐 있어서 둘의 일상이 평균 이상으로 정돈돼요.',
          '받쳐 주고 있어서 너의 시간이 사주 톤으로도 단단하게 새겨져요.',
          '한 톤 안에 모여 있어서 너의 일상이 평소보다 한 단계 진해요.',
          '줄지어 자리잡혀 있어서 둘 사이가 평소보다 진하게 흘러요.',
        ];
        final idxA = _KpopAnchors.saltedPick('bandKAnchN', '$seed', anchorTailsKo.length);
        anchorLine = '$anchorSummary${withSubj(anchorSummary)} ${anchorTailsKo[idxA]}';
      }
      return '$band$anchorLine';
    } else {
      const bandPoolsEn = <List<String>>[
        // 85+
        [
          'A bond the two of you lean toward — ',
          'A seat you both point at — ',
          'Stems and branches both underwrite the union — ',
          'Strong pull signals align in one spot — ',
          'A seat where stem-union and branch anchors line up — ',
          'A dense flow with multiple anchors aligned — ',
          'Pull anchors multiply-aligned — ',
          'Anchor signals tidy into one direction — ',
          'Multiple union signals on one page — ',
          'Strong anchors lined up here — ',
          'Pull signals aligned in one tone — ',
          'A seat where deep-affinity anchors gather — ',
          'Stem union and branch signals reinforce each other — ',
          'Strong anchors gathered in one seat — ',
          'A seat where trust-leaning anchors stack up — ',
          'Stacked union signals form a single page — ',
        ],
        // 70-84 — 32 variants
        [
          'A broadly favorable meeting between the two of you — ',
          'Both of you lean gently favorable — ',
          'A steady anchor underwrites the seat — ',
          'A gently favorable seat between the two of you — ',
          'Stems and branches tilt mildly in favor — ',
          'The two of you meet on a stable union — ',
          'No big signal, but soft favor flows underneath — ',
          'A steady anchor sits in one row, deep in the seat — ',
          'An easy, well-matched seat between the two of you — ',
          'Soft favor signals tone within one band — ',
          'Stems and branches align in a softer tone — ',
          'A steady anchor noted in one line — ',
          'A comfortable anchor sits in one seat — ',
          'Soft affinity flows without big union or clash — ',
          'The two of you meet with quiet goodwill — ',
          'A steady anchor underwrites naturally — ',
          'Both of you tilt mildly toward favor — ',
          'Soft affinity signals line up in order — ',
          'Stem union and branch signals settle softly — ',
          'A good, frictionless seat between the two of you — ',
          'A steady anchor holds up the everyday tone — ',
          'A comfortable union signal sits here — ',
          'Goodwill settled with no big spike — ',
          'A flow the two of you lean toward — ',
          'A soft favor anchor settled underneath — ',
          'Stem-branch signal aligns one shade softly — ',
          'A comfortable anchor row underwrites — ',
          'Natural goodwill flows without big union — ',
          'A favorable seat between the two of you — ',
          'A steady anchor in the everyday tone — ',
          'Both of you lean one shade toward favor — ',
          'A soft affinity anchor settles here — ',
        ],
        // 55-69
        [
          'No strong pull and no strong friction either — ',
          'A neutral meeting between the two of you — ',
          'Signals neither tilt strongly one way nor another — ',
          'Stems and branches run parallel here — ',
          'A balanced seat that resists single-line summary — ',
          'No big favor and no big friction — ',
          'A seat that rests more on your choices — ',
          'Stem-branch signal doesn\'t lean strongly — ',
          'Stability and stimulus neither dominate — ',
          'A seat where your effort carries more of the weight — ',
          'A balanced middle seat — ',
          'A balanced seat with no single answer baked in — ',
          'Stems and branches hold both ends — ',
          'No big pull, no big rejection — ',
          'A seat where your intent carries more of the weight — ',
          'A signal-balanced seat — ',
        ],
        // 40-54
        [
          'A seat that rewards a little care — ',
          'A soft caution shows in the signal — ',
          'Stem-branch anchor places small stimulus on one side — ',
          'A seat that rewards a slower beat — ',
          'A mild friction anchor sits in one row — ',
          'A seat where prudence tends to be the asset — ',
          'Stem-branch signal tilts slightly off — ',
          'A seat where conscious restraint helps — ',
          'No big collision, but one friction row shows — ',
          'A seat where your patience carries weight — ',
          'Stem-branch anchor slightly split — ',
          'A seat that rewards one beat of caution — ',
          'A mild stimulus anchor sits in place — ',
          'The signal flows slightly off-axis — ',
          'No big union, but small stimulus stays alive — ',
          'A seat where conscious distance helps — ',
        ],
        // <40
        [
          'A seat that rewards care around deep closeness — ',
          'Stem-branch anchor places strong stimulus here — ',
          'A seat that rewards strong caution — ',
          'A big clash anchor sits in this flow — ',
          'A seat where deep distance helps — ',
          'Signals align toward strong stimulus — ',
          'A seat where heavy prudence tends to be the asset — ',
          'Stems and branches align in opposite directions — ',
          'A seat where deep restraint and distance help — ',
          'Big stimulus anchors gathered in one row — ',
          'A seat where straight-line pull rarely happens — ',
          'Stem-branch anchor strongly split — ',
          'The signal tidies toward friction — ',
          'Big friction anchors lined up — ',
          'A seat that rewards one beat of deep distancing — ',
          'Stem-branch signal aligns toward strong distance — ',
        ],
      ];
      final pool = bandPoolsEn[bandIdx];
      final idx = _KpopAnchors.saltedPick('bandE_$bandIdx', '$seed', pool.length);
      final band = pool[idx];

      String anchorLine;
      if (strong + weak == 0) {
        // R100 sprint 4 — 16 → 32 variants. NONE branch top-1 collision 해소.
        final noAnchorPool = [
          'no direct anchor holds the weight, so time with $shortName tends to deepen as you build depth on purpose.',
          'no direct anchor means natural ignition is quiet, but the intent of the two of you tends to shape the depth most.',
          'in a no-anchor seat, accumulated small promises become the biggest asset.',
          'where direct signals are absent, intentional meetings themselves are the depth unit.',
          "no direct anchor means artificial chemistry (events, travel, new tables) becomes the bond's color.",
          "with no big anchor, the labor of booking the next plan is itself the bond's amplitude.",
          'zero direct anchors — natural ignition quiet, intentional ignition strong; your choices tend to shape the depth.',
          'in no-signal seats accumulation rules; one small line or note tends to carry real weight.',
          "without big stimulus, don't lean on fate — let your choices grow this bond.",
          'zero direct anchors mean a free seat — a bond that can run long when you tend it.',
          'weak signal means accumulation outranks events; tiny messages become the real asset.',
          'no big stimulus here — a textbook case of an intentional bond.',
          "in no-anchor seats, one person's will becomes the engine of the bond.",
          'without big union or clash, a calm friend or partner role fits long-term.',
          "with no signal, outside stimulus (travel, new faces, new activity) defines the bond's freshness.",
          'no direct stimulus means the real value only shows on a 1-2 year arc.',
          'no big union or clash here, so the first meeting reads calm. Two people who can enjoy calm sustain the bond long.',
          'weak direct signal means a steady check-in line itself colors the bond more than chance does.',
          'no big anchor — natural chemistry is thin, but intentional chemistry can build sturdier than average.',
          "no signal here means outside stimulus (shared hobbies, new activities, new circles) becomes the bond's oxygen.",
          'no direct stimulus here, so it starts plain, but small things added up tend to build the deeper bond over time.',
          "no big union or clash means one person's will to close the distance carries most of the amplitude.",
          'zero direct anchors — natural ignition weak, so anyone keeping the next plan steady is the asset here.',
          'no signal seat means rare big events, so daily details design the bond color instead.',
          'no big stimulus seat — depth here tends to come from time more than from events. Read this on a yearly scale.',
          'absent direct anchor — natural ignition weak, deliberate ignition strong; your choices grow this bond.',
          'no big union or clash means losing your own color is unlikely; a steady friend or partner seat.',
          "in no-signal seats, one person's small care becomes the unit of bond depth.",
          'weak direct stimulus means rare big fights and rare big recoveries; small frictions are best cleared the same day.',
          "no big anchor — time with $shortName flows plain but extends long.",
          'no direct signal seat — events are rare, so each promise carries above-average weight.',
          'no big union or clash present — natural pull is weak, but deliberate trust can grow sturdier than average.',
        ];
        final idx2 = _KpopAnchors.saltedPick('bandEAnch0', '$seed', noAnchorPool.length);
        anchorLine = noAnchorPool[idx2];
      } else {
        final partsList = <String>[];
        if (strong > 0) partsList.add('$strong strong');
        if (weak > 0) partsList.add('$weak weak');
        final anchorSummary = partsList.join(' / ');
        final anchorTailsEn = [
          'anchors sit together, so time with $shortName tends to register, not just by feeling.',
          'anchors stand in place, so the meaning between you tends to read sharper than average.',
          'anchors lay underneath, so the bond tends to settle one shade deeper than usual.',
          'anchors are logged here, so your everyday tends to hold a deeper line than average.',
          'anchors hang together, so the memory between you tends to last longer than average.',
          'anchors are gathered on one page, so your time together tends to register more tidied than average.',
          'anchors are pinned in place, so the weight of the bond tends to firm up here too.',
          'anchors sit together, so your shared everyday tends to read steadier here too.',
          'anchors are gathered in one seat, so your time together tends to run deeper than average.',
          'anchors line up in a row, so the bond tends to read sharper here too.',
          'anchors are tidied onto one page, so the depth tends to lift one rank over usual.',
          'anchors stand together, so your time together tends to register deeper than average.',
          'anchors overlap, so your everyday tends to tidy above the average.',
          'anchors underwrite the seat, so your time together tends to register firm here.',
          'anchors gather in one tone, so your everyday tends to rise one rank from usual.',
          'anchors line up in a row, so the bond tends to flow deeper than usual.',
        ];
        final idxA = _KpopAnchors.saltedPick('bandEAnchN', '$seed', anchorTailsEn.length);
        anchorLine = '$anchorSummary ${anchorTailsEn[idxA]}';
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

  // R100 sprint 2 — _starIdentityLead 가 사용하는 anchor family lookup 헬퍼.
  // 6 family × 4 skeleton × 셀럽 birth/group/element 결합으로 144 realized variants.
  static String elKoOf(String el) => _elKo[el] ?? '오행';
  static String elEnOf(String el) => _elEn[el] ?? 'element';

  static String jiSceneKo(String ji) {
    const map = {
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
    return map[ji] ?? '';
  }

  static String jiSceneEn(String ji) {
    const map = {
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
    return map[ji] ?? '';
  }

  static String genCueKo(int year) {
    if (year <= 0) return '';
    if (year < 1970) return '60년대생';
    if (year < 1980) return '70년대생';
    if (year < 1985) return '80년대 초반';
    if (year < 1990) return '80년대 후반';
    if (year < 1995) return '90년대 초반';
    if (year < 2000) return '90년대 후반';
    if (year < 2005) return 'Y2K 즈음';
    if (year < 2010) return '00년대 후반';
    if (year < 2015) return '10년대 초반';
    return '디지털 네이티브';
  }

  static String genCueEn(int year) {
    if (year <= 0) return '';
    if (year < 1970) return '60s-born';
    if (year < 1980) return '70s-born';
    if (year < 1985) return 'early-80s';
    if (year < 1990) return 'late-80s';
    if (year < 1995) return 'early-90s';
    if (year < 2000) return 'late-90s';
    if (year < 2005) return 'Y2K-era';
    if (year < 2010) return 'late-00s';
    if (year < 2015) return 'early-10s';
    return 'digital-native';
  }

  static String relCueKo(_ElRel rel) {
    switch (rel) {
      case _ElRel.same:
        return '닮은 결';
      case _ElRel.iGenerate:
        return '네가 살리는';
      case _ElRel.theyGenerate:
        return '너를 살리는';
      case _ElRel.iOvercome:
        return '네가 다듬는';
      case _ElRel.theyOvercome:
        return '너를 흔드는';
      case _ElRel.neutral:
        return '평행한 결';
    }
  }

  static String relCueEn(_ElRel rel) {
    switch (rel) {
      case _ElRel.same:
        return 'same-element';
      case _ElRel.iGenerate:
        return 'you-produce';
      case _ElRel.theyGenerate:
        return 'they-produce-you';
      case _ElRel.iOvercome:
        return 'you-refine';
      case _ElRel.theyOvercome:
        return 'they-shake-you';
      case _ElRel.neutral:
        return 'parallel-element';
    }
  }

  // R100 sprint 2 — 각 enum 당 32 항목으로 확장 (KO/EN 각 192 라인).
  // 사용자 mandate verbatim "마찬가지로 최애와 케미쪽도 엄청 반복이야 1위만 보는게아니라
  // 여러사람 볼텐데 다 비슷하거나 똑같은 형식으로 나오면 ai가 만든거구나 할거같은데?"
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
      r'쌍둥이 오행이라 사소한 농담의 박자도 자연스럽게 맞아요. 일상 단어 선택까지 닮아가는 자리니까, 한 명이 부정적 모드에 들어가면 다른 한 명이 짧게 환기해주는 약속이 보호막이에요.',
      r'한 오행을 나란히 걷는 짝이라 음식 취향·휴식 방식까지 겹치기 쉬워요. 닮음이 편함의 자산이지만, 새 친구·새 책·새 동선 같은 외부 자극을 정기적으로 끼워 넣으면 관계가 더 길게 신선해져요.',
      r'기운이 일치하니까 둘이 결정하는 속도가 비슷하게 빨라요. 다만 같은 약점에 같은 시점에 빠질 수 있어서, 큰 선택은 한 박자 늦춰서 다시 검토해 보는 룰을 미리 잡아두면 안전해요.',
      r'같은 오행 위에서 만나는 사이라 음악 취향·SNS 알고리즘까지 비슷하게 흘러요. $shortName이 좋아하는 자리에 네가 자연스럽게 발맞춰지는 만큼, 가끔은 의도적으로 다른 결의 자리를 같이 시도해 보는 게 환기예요.',
      r'기본 결이 같다 보니 처음부터 같이 일하기 좋은 호흡이에요. 둘이 똑같이 신나거나 똑같이 지치니까, 회복 일정을 미리 엇갈리게 잡아두면 관계 전체의 체력이 길어져요.',
      r'같은 오행끼리 서서 시야가 자연스럽게 좁아지는 자리예요. 너희끼리 결론을 너무 빨리 내지 말고, 다른 결의 친구 한 명에게 의견을 묻는 단계를 한 번씩 추가하면 큰 실수가 줄어요.',
      r'같이 살아가는 오행이라 침묵도 같은 톤으로 흘러요. 그 편안함이 너무 익숙해지면 서로의 변화가 안 보이니까, $shortName이 새롭게 시도한 게 뭔지 한 번씩 묻는 습관이 약이에요.',
      r'동질감이 빠르게 자리잡는 만큼, 너희만의 안쪽 농담·은어가 빠르게 늘어나요. 외부에서 보면 둘만의 세계 같아 보이는데, 가끔은 외부 사람도 함께하는 자리로 너희 세계를 환기시키세요.',
      r'같은 오행이라 한 명의 컨디션이 다른 한 명한테 빠르게 전염돼요. 회의 전·약속 전에 서로의 상태를 한 줄 공유하는 사소한 룰만 지켜도 부딪힘 빈도가 절반 이하로 줄어요.',
      r'동일 오행 그룹이라 서로의 약점도 동시에 노출돼요. 그 약점을 메우는 외부 자원(전문가·친구·시스템)을 미리 한두 개 정해두면, 둘 다 동시에 지치는 시기를 무난히 지나가요.',
      r'기운이 한 색이라 평생 친구 후보로는 1순위에 가까워요. 다만 연애·동업처럼 거리가 가까워지는 자리는, 너희가 너무 비슷한 만큼 의식적으로 역할을 나눠두는 게 관계 수명을 늘려요.',
      r'$shortName과 같은 오행이라 시즌별 컨디션 곡선도 비슷해요. 둘 다 가라앉는 시기엔 무언가 큰 결정을 하지 않는다는 룰만 지키면, 그 외 90%의 시간은 어느 친구보다 자연스럽게 흘러요.',
      r'같은 오행끼리 만나는 자리는 마치 거울 두 개가 마주 보는 모양이에요. 거울이 너무 가까워지면 외부가 안 보이니, 정기적으로 다른 결의 자극을 넣어주는 게 관계의 산소예요.',
      r'한 오행을 공유한다는 건 같은 약점을 공유한다는 뜻이기도 해요. $shortName과 너 둘 다 가라앉을 때를 대비해, 너희를 일으켜 줄 외부 사람·루틴을 미리 정해두면 큰 위기를 미연에 막아요.',
      r'기본 결이 동일하니까 첫 만남부터 깊은 대화가 가능해요. 다만 깊이만 추구하다 보면 일상의 가벼움이 사라질 수 있어서, 의도적으로 시시콜콜한 농담 자리를 자주 만들어주세요.',
      r'$shortName이 가는 길이 곧 네가 가는 길처럼 느껴지는 자리예요. 그 동조가 자산이지만, 너만의 분기점도 한두 개는 분명히 잡아두는 게 관계가 한쪽으로 종속되지 않는 비결이에요.',
      r'같은 오행이라 디테일 하나하나가 다 비슷하게 느껴져요. 그 비슷함을 당연시하지 말고, 너만 보이는 $shortName의 미세한 변화를 짚어주는 사람이 되어주면 깊이가 한 단계 더 자라요.',
      r'기운이 같으니 둘 다 같은 트렌드·같은 사람·같은 컨텐츠에 끌려요. 그 합류 지점에서 둘만 아는 자리가 빨리 생기는 대신, 서로의 단독 취향을 보존하는 의식적인 시간을 따로 둬야 해요.',
      r'동질 오행 사이에선 위로의 언어도 거의 일치해요. $shortName이 위로받고 싶을 때 너의 한 마디가 가장 정확하게 닿으니, 그 정확함을 일상적으로 자주 꺼내 쓰는 게 관계의 가장 큰 자양분이에요.',
      r'같은 오행 짝은 갈등 회피 패턴도 비슷해요. 둘 다 같은 방식으로 자리를 피하면 문제가 그대로 쌓이니까, 한 명이 먼저 "잠시 멈추고 이야기하자" 신호를 정해두는 게 처방이에요.',
      r'쌍둥이 오행이라 둘이 결정한 건 셋이 결정한 것보다 더 빠르게 추진돼요. 추진력이 강한 만큼, 결정 전에 일부러 한 박자 늦춰서 외부 시각을 한 번 점검하는 루틴이 권장돼요.',
      r'같은 결끼리 부딪히면 마찰이 크지 않지만 회복도 비슷한 속도로 와요. $shortName과 너의 다툼은 짧고 정리도 빠른 편이라, 그 사이클을 의식하면 큰 다툼으로 번지지 않아요.',
      r'한 오행을 함께 쓰는 자리에선 의리·신뢰가 빠르게 형성돼요. 그 신뢰가 너무 빠른 만큼, 작은 약속이라도 지키는 디테일이 관계의 장기 신용 점수가 돼요.',
      r'같은 오행이라 너희가 같이 있을 때 분위기가 한 톤으로 통일돼요. 그 통일감이 매력의 핵심이지만, 외부에서 합류하는 사람 입장에선 진입장벽일 수 있으니 새 사람 들어올 자리는 의식적으로 열어두세요.',
    ],
    _ElRel.iGenerate: [
      r'너의 기운이 상대를 살리는 상생 흐름이라, 너의 한 마디·한 행동이 $shortName한테 깊게 닿아요. 상대가 자라는 모습을 보면서 네가 더 단단해지는 관계예요.',
      r'네가 상대에게 흘려보내는 쪽이라, 평소에는 네가 더 많이 주는 듯해도 시간이 쌓일수록 단단해지기 좋은 자리예요. 천천히 가는 게 잘 맞는 자리예요.',
      r'너의 색이 상대를 키우는 위치라, $shortName이 너 앞에서는 평소보다 더 솔직해져요. 받는 쪽에 익숙해질 때쯤 한 번씩 페이스를 점검하면 균형이 오래 가요.',
      r'상생 방향이 너 → 상대로 흐르는 흐름이에요. 네가 별생각 없이 한 말도 $shortName한테는 오래 남기 쉬우니, 그 무게를 의식하면 관계를 건강하게 끌고 가는 데 도움돼요.',
      r'너의 에너지가 $shortName의 약한 자리를 자연스럽게 데워주는 상생 흐름이에요. 네가 채워주는 만큼 상대가 자기 색을 찾아가니까, 결과가 곧 안 보여도 조급하지 말고 계절 단위로 관계를 봐주세요.',
      r'네가 먼저 빛을 보내는 위치라 $shortName이 너 앞에서 평소보다 더 자신감 있게 행동해요. 다만 네가 지치면 둘 다 같이 가라앉을 수 있어서, 너 자신을 충전하는 시간을 따로 비워두는 게 관계의 기본 체력이에요.',
      r'네가 길을 먼저 닦는 입장이라 $shortName이 따라오는 그림이 자연스러워요. 다만 네 페이스만 보고 가다 보면 상대가 자기 호흡을 잃기 쉬우니까, 가끔은 의도적으로 뒤따라가 보는 연습도 관계에 좋은 균형이 돼요.',
      r'너의 흐름이 상대를 키우는 상생 자리예요. $shortName이 너 앞에서 한 단계씩 성장하는 모습을 보면서, 그 결과만 칭찬하지 말고 과정의 작은 변화도 알아봐 주면 관계가 훨씬 단단해져요.',
      r'네가 영양분을 흘려보내는 쪽이라, 옆에 있는 시간만큼 $shortName의 색이 또렷해져요. 주고 있다는 자각보다 자라는 모습을 즐기는 마음일 때 관계가 가장 자연스럽게 깊어져요.',
      r'네 손길이 닿은 자리마다 $shortName이 한 뼘씩 자라는 게 보일 거예요. 그 변화의 속도에 조급해하지 말고, 1년 단위로 다시 들여다보는 시야가 두 사람한테 잘 맞아요.',
      r'네가 주는 입장이라 $shortName이 가끔 너한테 의존하는 그림이 만들어져요. 의존 자체는 자연스러운 신호니까 무서워하지 말고, 다만 너만의 회복 루틴은 절대 양보하지 마세요.',
      r'상대를 키우는 자리에 서 있는 만큼, 칭찬도 지적도 너의 말이 가장 빠르게 닿아요. 짧은 인정 한 줄을 일상에 자주 끼워 넣으면 $shortName의 자기 색이 훨씬 빨리 자리잡아요.',
      r'상생의 방향이 너 → $shortName 라는 건, 네가 만든 작은 환경 변화가 상대한테는 큰 도약점이라는 뜻이에요. 너에겐 별일 아닌 일이 그쪽엔 결정적이라는 걸 늘 의식하세요.',
      r'네 시간이 곧 $shortName의 영양분이 되는 자리예요. 너무 많이 쓰면 너의 영양분이 모자라니까, 함께 있는 시간만큼 혼자 충전하는 시간도 같은 비율로 챙기세요.',
      r'너의 결정이 $shortName의 다음 챕터를 여는 키가 되는 경우가 많아요. 그 권한의 무게를 느낀다면 무리해서 결정하지 말고, "지금은 당신에게 맡길게" 라고 넘기는 카드도 자주 써주세요.',
      r'네가 빛을 먼저 보내는 자리라, $shortName 앞에서 너의 무드 한 톤이 둘의 분위기 전체를 만들어요. 자기 컨디션을 솔직하게 공유하는 게 매너이자 관계 기본기예요.',
      r'$shortName한테 영양분을 흘려보내는 위치라, 네가 단순히 옆에 있는 것만으로도 상대의 회복 속도가 빨라져요. 그 무형의 효능을 너 스스로 인정하는 게, 주는 사람의 번아웃을 막아요.',
      r'네가 풍부할수록 $shortName이 풍부해지는 흐름이에요. 그래서 자기 계발·취미·인간관계 같은 너 자신의 풍요로움을 일부러 챙기는 게, 결과적으로 두 사람 다 자라게 만드는 길이에요.',
      r'상생 자리의 능동적 위치라, 갈등 상황에서도 네가 먼저 한 발 물러서는 그림이 만들어지기 쉬워요. 다만 늘 양보만 하면 너도 닳으니까, 너만의 비양보 영역을 두 개쯤은 정해두세요.',
      r'네 페이스에 $shortName의 성장 속도가 따라오기 쉬워요. 빠르게 끌고 가면 빨리 자라지만 부작용도 같이 오고, 천천히 가면 깊게 자라요. 둘이 미리 합의한 속도가 맞는 속도예요.',
      r'네 칭찬은 $shortName한테 누구의 칭찬보다 강하게 박혀요. 그래서 평소엔 칭찬을 아끼지 말고, 정말 짚어야 할 지적은 짧고 따뜻한 톤으로 한 번만 던지는 게 효과적이에요.',
      r'너의 작은 호의가 $shortName 입장에선 큰 사건처럼 기록돼요. 부담스러운 게 아니라, 그 만큼 너의 일상이 상대한테 중요하다는 뜻이니까 사소한 표현을 줄이지 마세요.',
      r'네가 영양분을 흘려보내는 만큼, 한 번씩은 $shortName의 회로가 너한테 어떤 색깔의 결과를 돌려주는지 확인해보세요. 그 피드백이 너의 다음 투자 방향을 잡아줘요.',
      r'상생의 흐름이 너 → $shortName 쪽으로 흐르는 자리라, 네 컨디션이 곧 $shortName 자리로도 이어지기 쉬워요. 그러니 둘 사이를 위해서라도 너 자신을 먼저 챙기는 게 좋은 출발점이에요.',
      r'$shortName이 너 앞에서 한 단계씩 단단해지는 모습은, 사실 너의 어떤 면이 비춰진 거울이기도 해요. 너의 미덕이 자라는 만큼 둘 사이가 자라요.',
      r'네가 길잡이 역할로 자연스럽게 자리잡는 위치라, 한 번씩은 의도적으로 모르는 척 따라가 보는 시간이 필요해요. 그 역할 교대가 관계의 입체감을 만들어요.',
      r'주는 쪽인 당신에게 가끔은 $shortName이 작게라도 되돌려주는 순간이 와요. 그 한 줌의 환원을 가볍게 넘기지 말고 분명히 인정해주면, 상대가 받는 사람 모드에서 벗어나는 데 도움이 돼요.',
      r'너의 결이 상대를 일으키는 자리라, 너의 무기력은 둘 모두의 무기력이 돼요. 너 혼자만의 시간·운동·휴식 같은 회복 루틴을 어떤 약속보다 우선해서 챙기는 게 결국 관계 보호예요.',
      r'네가 자라는 자리에 $shortName이 한 발 옆에 서 있는 그림이에요. 너의 성장 자체가 상대의 환경이 되니까, 자기 일을 잘 하는 것 자체가 가장 큰 사랑 표현이 되는 자리예요.',
      r'상생 방향이 너 쪽에서 흘러나가는 자리, $shortName한테 무엇이 가장 필요한지 한 번씩 직접 묻는 게 효과적이에요. 짐작으로 주기보다 정확히 묻고 주는 게 에너지 낭비를 줄여요.',
      r'네가 자양분 역할인 만큼 $shortName의 자기 색이 옅어지는 시기가 한 번씩 와요. 그럴 땐 한 발 물러서서 빈자리를 만들어주는 것이, 다음 단계에 상대가 자기 색을 다시 잡는 자리가 돼요.',
      r'너의 영향이 상대 일상 곳곳에 스며드는 자리라, 작은 농담조차 $shortName한테 오래 남아요. 자기 영향력을 정확히 인지하는 사람만이 이 상생 자리를 균형 있게 끌고 갈 수 있어요.',
    ],
    _ElRel.theyGenerate: [
      r'상대가 너의 부족한 자리를 자연스럽게 채워주기 좋은 상생 흐름이에요. 가까이 있을수록 네가 편해지기 쉽고, 받는 쪽이라 한 번씩 고마움을 말로 전해두면 관계가 받는 쪽으로만 기우는 자리를 줄이기 좋아요.',
      r'너 쪽으로 흘러 들어오는 방향이라 $shortName 옆에 있을 때 너의 에너지가 회복돼요. 받기만 한다는 죄책감 대신, 너만 할 수 있는 방식으로 되돌려주는 연습이 필요해요.',
      r'상대의 기운이 너를 살리는 위치라 어려운 시기에 가장 먼저 찾게 되는 사람이에요. 너무 의존하면 상대가 지칠 수 있어서 받는 쪽에서도 페이스 조절이 필요해요.',
      r'상생 방향이 상대 → 너로 흐르는 흐름이에요. $shortName의 안정감이 너의 흔들림을 잡아주니까, 너도 너만의 방식으로 상대의 약한 자리를 챙겨주는 균형이 답이에요.',
      r'$shortName의 색이 너의 빈자리를 데워주는 자리라, 같이 있는 시간만큼 너의 회복 속도가 빨라져요. 다만 받는 쪽도 의식적으로 상대의 일상을 들여다보는 습관을 들여야 관계가 한쪽으로 기울지 않아요.',
      r'상대의 흐름이 너 쪽으로 영양분처럼 흘러오는 위치예요. $shortName이 별생각 없이 건넨 말이 너한테는 큰 힘이 되는 경우가 많으니까, 그게 당연한 게 아니라는 걸 기억하고 작은 표현이라도 자주 돌려주세요.',
      r'$shortName의 기운이 너의 부족한 자리를 자연스럽게 채워주는 흐름이라, 큰 약속이 없어도 옆에 있는 것만으로 마음이 가벼워져요. 받는 쪽일수록 작은 인정·고마움을 자주 표현하는 게 관계의 가장 큰 자양분이에요.',
      r'너 쪽으로 흐르는 상생 방향이라, $shortName 앞에서는 평소보다 솔직한 너의 모습이 더 잘 나와요. 의지하는 게 자연스러운 만큼, 너만의 영역(취미·일·친구)을 함께 잘 챙겨야 받는 무게가 부담으로 안 변해요.',
      r'$shortName이 너의 약점을 자연스럽게 비춰주는 빛 같은 자리예요. 그 빛이 부담스럽지 않으려면, 너 스스로의 부족함을 부끄러워하지 않는 연습이 먼저 필요해요.',
      r'네가 빈 자리에 $shortName이 자기 색을 흘려보내는 그림이에요. 흘려 받는 게 자연스러운 만큼, "왜 이걸 나한테 줘?" 라는 자기 의심은 의식적으로 끊어내는 게 관계의 시작이에요.',
      r'$shortName 옆에 있으면 너의 결이 또렷해지는 자리예요. 그 또렷함은 상대가 준 환경의 결과니까, 결과만 자기 공으로 돌리지 말고 환경 제공자에게 자주 감사 표현을 돌려주세요.',
      r'상대가 너의 성장에 영양분 역할을 하는 자리라, $shortName과의 시간은 너의 다음 단계 발판이 되기 쉬워요. 그 발판을 당연시하지 말고, 한 번씩은 상대의 다음 단계를 위한 디딤돌이 되어주세요.',
      r'$shortName의 안정이 너의 흔들림을 잡아주는 자리예요. 너의 흔들림 자체를 죄책감으로 받지 말고, 흔들리는 시기엔 솔직히 도움을 청하는 게 이 관계에 맞는 사용법이에요.',
      r'네가 흡수하는 입장이라, $shortName이 보내준 단어·습관·태도가 어느새 너의 일부가 되어 있을 거예요. 그 변화의 출처를 잊지 말고 한 번씩 짚어주면 상대의 자존감이 든든해져요.',
      r'상대의 결이 너의 결을 보완해주는 자리라, 결정의 순간엔 $shortName의 의견을 먼저 묻는 게 자연스러워요. 다만 결정 책임까지 넘기지는 말고, 마지막 결정 한 줄은 네가 가져가세요.',
      r'$shortName 앞에서 네가 더 편안한 모습으로 변하는 자리예요. 그 편안함이 신호니까, 받는 쪽이라는 자격지심 대신 "잘 받기" 자체를 능력으로 봐주세요.',
      r'상대가 자기 색을 줄 때 자연스럽게 너의 색이 살아나는 자리라, 작은 위로·격려가 너한테 평균보다 큰 효능을 가져요. 그러니 $shortName의 사소한 메시지에도 충분히 반응해주는 게 관계의 예의예요.',
      r'너의 빈자리에 $shortName의 톤이 채워지는 그림이에요. 그 톤이 익숙해지면 너만의 색이 흐려질 위험이 있으니, 혼자만의 정체성 작업(독서·여행·일기 같은 단독 활동)을 일정량 유지해 주세요.',
      r'$shortName의 한 마디가 너의 하루 무게를 바꾸는 자리예요. 그래서 부정적인 한 마디도 평균보다 깊게 박히니까, 한 번씩은 상대에게 "그 말은 좀 더 부드럽게 해줄래?" 라고 솔직하게 부탁할 수 있어야 해요.',
      r'$shortName의 결이 너를 살리는 자리라, 어려운 시기일수록 상대를 먼저 찾게 돼요. 너무 매달리지 않으려고 거리두지 말고, 솔직하게 도움을 청하되 회복되면 그만큼 돌려준다는 마음을 늘 가져가세요.',
      r'상대의 자원이 너의 다음 챕터를 만들어주는 자리라, $shortName과 함께한 시기엔 너의 큰 발전이 이뤄지기 쉬워요. 그 결과를 너의 능력으로만 돌리지 말고, 그 시기에 곁에 있어준 상대를 늘 인정하세요.',
      r'네가 부족함을 솔직하게 인정할수록 $shortName이 더 정확하게 도와줄 수 있는 자리예요. 약점을 숨기는 습관이 가장 큰 손해니까, 이 관계 안에서는 평소보다 더 투명하게 살아도 안전해요.',
      r'$shortName 옆에 있는 시간만큼 너의 회복 속도가 빨라지기 쉬워요. 그래서 의도적으로 옆에 있는 시간을 만드는 것 자체가 자기 관리의 핵심 행동이 돼요.',
      r'상생 방향이 너 쪽으로 흘러오는 자리지만, 영구적이라고 가정하면 안 돼요. 받는 만큼 너의 회복 속도가 빨라진다는 걸 느낀 시점에서, 정확히 같은 양은 아니라도 너만의 방식으로 흘려보내는 연습을 시작해주세요.',
      r'$shortName의 따뜻함이 너의 추위를 녹여주는 자리예요. 그 따뜻함을 데이터처럼 측정하지 말고, 한 번씩 큰 소리로 인정해주는 표현이 가장 강한 보답이에요.',
      r'네가 받는 입장이라, $shortName이 자기 색을 너무 많이 내어주다가 자기 자신이 옅어질 위험이 있어요. 너의 변화를 짚어주는 사람이 너이듯, 상대의 변화를 짚어주는 사람도 너여야 한다는 걸 잊지 마세요.',
      r'$shortName의 자원이 당신에게 흘러오는 자리라, 큰 일에 앞서 상대에게 솔직히 상황을 공유하는 게 의외로 가장 큰 효과를 가져요. 비밀 없이 가는 게 이 관계의 전제예요.',
      r'네가 받는 쪽이라 상대의 작은 변화에 더 예민하게 반응할 필요가 있어요. $shortName이 평소와 다른 톤이면, 모르는 척 넘기지 말고 한 번이라도 짧게 물어봐 주세요.',
      r'상대가 너를 살리는 자리에 있다는 건, 네가 무너지면 둘의 관계 무게가 한쪽으로 쏠린다는 뜻이에요. 그래서 너의 회복 자체가 관계에 대한 책임이고, 그 회복은 죄책감 없이 진행되어야 해요.',
      r'$shortName이 흘려보내는 자원에는 시기·계절·총량이 있어요. 한 번에 다 받기보다 천천히 흡수하는 페이스가 둘 다 오래 가는 비결이에요.',
      r'네가 받는 입장이라 $shortName이 평균보다 더 많이 너의 자리에 신경 써요. 그 마음을 무겁게 받지 말고, "고마워" 한 마디를 그날 안에 정확히 돌려주는 작은 약속만 지켜주세요.',
      r'상생 흐름이 너 쪽으로 들어오는 만큼, $shortName이 지칠 때 가장 먼저 알아채는 사람이 너여야 해요. 받는 자리의 의무는 더 잘 받는 게 아니라, 더 잘 알아채는 거예요.',
    ],
    _ElRel.iOvercome: [
      r'너의 기운이 상대를 누르는 상극 흐름이라, 처음엔 네가 주도하고 상대 약점을 정확히 짚어내는 코치 같은 관계예요. 톤이 한 단계만 올라가도 통제처럼 느껴질 수 있으니 의도와 표현의 거리를 늘 의식해야 해요.',
      r'네가 상대를 누르는 방향이라 짧은 한 마디가 깊게 박혀요. $shortName이 너 앞에서는 평소보다 위축될 수도 있어서, 의식적으로 한 박자 부드럽게 가는 연습이 필요해요.',
      r'주도권이 너 쪽으로 자연스럽게 흐르는 흐름이에요. 잘 쓰면 든든한 멘토 관계지만, 잘못 쓰면 일방적인 지시 관계가 돼버려서 상대가 자기 색을 낼 공간을 늘 비워둬야 해요.',
      r'너의 기운이 상대를 다듬는 위치라 $shortName의 단점이 너 앞에서 더 잘 보여요. 그걸 어떻게 짚느냐에 따라 관계 결이 크게 달라지기 쉬워요 — 비판보다는 질문 형식이 잘 통해요.',
      r'네가 $shortName의 흐름을 조이는 위치라, 네가 의식하지 않은 평범한 말 한 줄도 상대한테는 평가처럼 들릴 수 있어요. 칭찬을 의도적으로 두 배 늘리고 지적은 사석에서만 하는 룰만 지켜도 관계 무게가 완전히 달라져요.',
      r'주도권이 자연스럽게 너 쪽으로 모이는 상극 흐름이에요. 네가 끌고 가는 게 편한 만큼 $shortName이 자기 의견을 꺼낼 타이밍을 잃기 쉬우니까, 결정 전에 "어떻게 생각해?" 한 마디를 의식적으로 끼워 넣어주면 좋아요.',
      r'너의 기운이 $shortName을 정돈하는 위치라, 평소엔 든든한 형/언니 같은 존재예요. 다만 상대가 너 한 명한테 맞추는 게 익숙해지면 자기 색이 옅어지니까, 가끔은 $shortName의 결정에 그냥 따라가 보는 시간이 필요해요.',
      r'네가 상대를 다듬는 자리에 서 있으니, 너의 정확함이 $shortName한테는 자극이자 부담이 될 수 있어요. 정답을 알려주기 전에 상대가 스스로 도달할 시간을 주는 게, 멘토 관계와 통제 관계를 가르는 결정적 차이예요.',
      r'$shortName 앞에서 너의 단호함은 평소의 두 배로 들려요. 그래서 너의 평소 톤보다 한 단계 부드럽게 발음하는 룰만 지켜도, 같은 말이 코치와 평가자로 정반대로 들릴 수 있어요.',
      r'네가 누르는 자리라 $shortName이 무의식적으로 너의 기준을 자기 기준으로 들여놔요. 너의 의견이 상대 일상에 그대로 박힐 수 있다는 걸 늘 무게로 인식하세요.',
      r'$shortName의 약점을 빠르게 캐치하는 능력이 너의 무기이자 위험이에요. 캐치 후엔 곧장 지적하지 말고, 상대가 스스로 발견할 자리까지 한 박자 기다리는 훈련이 필요해요.',
      r'네가 주도하는 그림이 편안한 만큼, $shortName이 자기 의견을 꺼내는 데 평균보다 더 큰 용기를 써야 하는 자리예요. 의견을 꺼내준 순간 그 가치를 평가가 아니라 환영으로 받아주세요.',
      r'$shortName의 행동 패턴이 당신에게는 빨리 분석돼요. 그 분석을 평가로 전달하지 말고, 상대가 그 안에서 자기 색을 발견할 수 있도록 질문형 언어로 풀어주세요.',
      r'네가 코치 자리에 자연스럽게 자리잡는 만큼, $shortName의 자기 결정권은 의식적으로 늘려줘야 해요. 사소한 결정(메뉴·동선·시간)부터 일부러 상대에게 넘겨주는 연습이 효과적이에요.',
      r'$shortName이 너 앞에서 자기 검열이 강해지는 자리예요. 그 자기 검열을 풀어주려면, 네가 먼저 자기 부족함을 솔직히 보여주는 게 가장 효과적인 처방이에요.',
      r'너의 기준이 상대의 기준이 되어버리는 위치라, $shortName이 너의 색에 자기 색을 양보하지 않게 보호해주는 게 너의 책임이에요. "그건 네 식대로 가도 좋아" 라는 말을 일상 어휘에 추가해주세요.',
      r'상극 방향이 너 → 상대로 가는 자리라, 작은 농담조차 $shortName한테는 평가처럼 들릴 수 있어요. 농담 직후엔 항상 "농담이야, 너의 그 자체로 충분해" 같은 안전 멘트를 한 줄 붙여주세요.',
      r'네가 다듬는 자리라, $shortName의 변화 속도가 너의 기대보다 느릴 때가 자주 와요. 그 속도 차를 인내가 아니라 "다른 시간을 사는 사람" 으로 인정해주는 게 가장 큰 호의예요.',
      r'네가 상대의 흐름을 조이는 자리에 있다는 건, $shortName이 너 옆에서는 자기 표현을 절제하는 습관이 생긴다는 뜻이기도 해요. 절제가 미덕으로 보이지 않게, 표현해도 안전한 자리라는 신호를 자주 보내주세요.',
      r'상극 자리에서 너의 정확함은 양날의 검이에요. 그 검을 휘두르지 말고 도구함에 잘 정리해두면, $shortName한테는 평생 안 사라질 멘토가 될 수 있어요.',
      r'$shortName의 부족함이 너 앞에서 평소보다 더 보이는 자리예요. 그게 너의 안목이지 상대의 결함은 아니에요. 같은 사람이 다른 친구 앞에서는 그 부족함을 안 드러낼 수도 있다는 걸 늘 기억하세요.',
      r'네가 누르는 자리라, $shortName의 자기 색이 너의 색 밑에서 자라기까지 시간이 더 걸려요. 결과만 빨리 보려고 하지 말고, 상대의 1년 단위 변화를 기록해두는 습관이 도움돼요.',
      r'상극 흐름의 능동 위치라, 갈등 시작점은 거의 너의 한 마디예요. 그 한 마디 전에 호흡 세 번을 의식적으로 끼워 넣는 룰만 지켜도 큰 다툼 빈도가 절반 이하로 줄어요.',
      r'네가 다듬는 입장이라 $shortName의 발전이 너의 만족이 돼요. 다만 상대의 발전을 자기 공으로 돌리는 순간 관계가 단숨에 무너지니까, 발전은 늘 상대의 공으로 명확히 표시해주세요.',
      r'$shortName이 너 앞에서 평소보다 작아 보이는 자리예요. 그 작아짐을 매력으로 즐기지 말고, "내가 너를 작게 만들고 있나?" 라고 의식적으로 자기 점검하는 시간을 정기적으로 가지세요.',
      r'네가 멘토 자리라, $shortName의 성장이 너의 평가지가 되기 쉬워요. 성장을 평가하지 말고 그저 함께 시간을 보내는 친구로 머무는 시간을 의식적으로 따로 마련해주세요.',
      r'상극 흐름에선 침묵도 무기예요. $shortName한테 침묵으로 불만을 표현하는 습관은 가장 위험한 패턴이니까, 불만은 같은 날 안에 짧게 말로 풀어주는 룰을 정해두세요.',
      r'네 정확함이 너무 빠른 자리라, $shortName이 따라잡기 어려운 순간이 자주 와요. 그럴 땐 너의 정확함을 쉬게 두는 시간도 필요해요. "지금은 그냥 같이 있는 시간" 같은 카드도 적극적으로 쓰세요.',
      r'$shortName의 미숙함을 빠르게 짚는 능력이 코치로 환영받을 수도, 통제자로 거부될 수도 있는 자리예요. 그 차이는 짚는 빈도가 아니라, 짚기 전에 상대의 자기 발견 시간을 얼마나 줬는가에서 갈려요.',
      r'네가 누르는 자리라, 큰 결정 앞에서는 의식적으로 너의 의견을 마지막에 꺼내는 룰이 잘 통해요. 너의 의견이 먼저 나오면 $shortName의 의견은 잘 안 나오기 쉬워요.',
      r'상극 자리의 너는, 잘 쓰면 $shortName의 평생 코치이지만 잘못 쓰면 평생 콤플렉스의 출처가 돼요. 그 사이의 갈림길은 너의 어조 하나, 너의 인내심 한 박자에 달려 있어요.',
      r'네 결이 상대를 다듬는 자리라, $shortName의 사적 시간(취미·우정·가족)에는 의식적으로 손대지 마세요. 그 영역에서만큼은 너의 평가가 들어가지 않는 안전지대가 있어야 관계 전체가 살아요.',
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
      r'네가 흔들리는 위치라 $shortName 앞에서는 평소의 결정 속도가 안 나와요. 그 답답함을 자기 단점으로 받지 말고, 상대 앞에서는 결정을 천천히 하는 게 안전 모드로 보세요.',
      r'$shortName의 한 마디가 너의 일상에 평균보다 더 큰 파장을 일으키는 자리예요. 파장을 줄이는 건 상대가 아니라 너의 흡수력 조절이에요. 흡수가 너무 빠른 시기엔 의식적으로 거리를 늘리세요.',
      r'상대가 너를 흔들 때, 너의 가장 큰 무기는 침착함이 아니라 평소의 너의 루틴이에요. 흔들림 속에서도 변하지 않는 일상 두세 가지가 너를 잡아주는 닻이 돼요.',
      r'$shortName이 당신에게 자극이 되는 자리라, 가끔은 일부러 그 자극을 피해 거리를 두는 시간도 필요해요. 거리두기가 도망이 아니라 회복이라는 걸 자기한테 분명히 설명해두세요.',
      r'네가 받는 자극이 너의 성장 신호이기도 해요. 자극이 클수록 너의 다음 챕터 진입 속도가 빠르지만, 그만큼 너의 회복 시간이 길어진다는 트레이드오프를 늘 의식하세요.',
      r'$shortName의 결이 너의 약점을 정확히 짚는 자리라, 상대 앞에서 너의 약점이 더 또렷하게 보여요. 그 또렷함을 상대 탓이 아니라 거울 효과로 받아들이는 순간 관계가 살아나요.',
      r'네가 흔들리는 입장이라 결정의 시점에서 $shortName 앞에서는 평소의 판단력이 잘 안 나와요. 그래서 큰 결정은 상대와 멀리 떨어진 자리에서 일부러 단독으로 진행하는 게 안전해요.',
      r'$shortName이 너의 페이스를 흔드는 자리라, 평소의 너의 속도를 지키는 게 무엇보다 중요해요. 상대 페이스에 끌려가지 말고, "지금 내 페이스가 어땠지?" 라고 자기 점검하는 시간을 정기적으로 두세요.',
      r'네가 받는 자극이 큰 만큼, $shortName의 말을 받아들이기 전에 24시간 정도 묵혀두는 습관이 도움돼요. 즉답 대신 묵혀둔 답이 너의 진짜 답에 더 가까워요.',
      r'상대의 결이 너의 결을 다듬는 자리라, 가까울수록 너의 디테일이 향상돼요. 다만 디테일이 향상되는 만큼 자기 검열도 함께 자라니까, 자기 검열은 한 단계 풀어두는 의식이 필요해요.',
      r'$shortName 앞에서 네가 평소보다 작아지는 시기엔, 그 작아짐을 정상화로 받지 말고 한 번씩 외부 친구·환경에서 너의 실물 크기를 다시 확인하세요. 외부 거울이 이 관계의 보호 장치예요.',
      r'네가 흔들리는 자리, 상대의 사소한 표정 변화에 평균보다 더 크게 반응할 수 있어요. 그 과반응을 자기 약점으로 보지 말고, 너의 감수성 시그널로 인정하면서 한 박자 늦게 반응하는 룰을 만드세요.',
      r'상대가 너를 다듬는 자리라, $shortName의 직설이 코치의 한 마디로 들리느냐 비난으로 들리느냐는 그날의 너의 컨디션에 달려 있어요. 컨디션이 낮은 날엔 그 직설을 미루는 약속이 둘에게 도움이 돼요.',
      r'$shortName이 너의 흐름을 조이는 위치라, 너의 자율 시간(혼자만의 산책·취미·운동)이 평소보다 더 신성한 자원이에요. 그 시간을 양보하기 시작하는 순간 균형이 무너져요.',
      r'네가 흔들림 받는 입장이라 갈등 직후 회복 시간이 평균보다 길어요. 그 시간을 자기 약점으로 보지 말고, 당신에게 맞는 회복 속도라고 정확히 자기한테 설명해주세요.',
      r'상극 자리의 수동 위치라, $shortName의 한 마디 무게가 평소의 두 배예요. 그래서 상대가 의식 없이 던진 농담이 너한텐 큰 사건이 될 수 있다는 걸 솔직하게 공유하는 게 보호예요.',
      r'네가 받는 자극이 너의 단단함을 만드는 자리라, 그 자극을 거부하지 않고 받아들이면서도 휩쓸리지 않는 균형이 핵심이에요. 균형의 첫 단추는 너만의 일상 루틴 보존이에요.',
      r'$shortName의 정확함이 당신에게는 자극이자 부담이에요. 그 부담을 줄이려면, "내가 너의 정확함을 100% 다 따라가지는 않아도 돼" 라는 자기 허용이 먼저 필요해요.',
      r'상대 결이 너를 다듬는 자리라, 너의 성장 속도가 평소보다 빨라져요. 그 속도가 너의 호흡을 추월하는 순간이 위험 신호니까, 한 달에 한 번은 너의 컨디션을 단독으로 점검하세요.',
      r'$shortName이 너의 약점을 정확히 비추는 자리라, 그 약점을 인정하는 연습은 평생 자산이 돼요. 다만 인정이 자기 학대로 변하지 않게, 인정 뒤에는 늘 "그래도 잘 살고 있다" 는 자기 위로를 붙여주세요.',
      r'네가 흔들리는 입장이라 결정·갈등·실수가 평균보다 자주 일어나요. 그 빈도를 자기 실패로 보지 말고, 이 관계 안에서의 학습 비용으로 회계 처리하면 마음이 가벼워져요.',
      r'$shortName 앞에서 너의 자기 색이 옅어지는 시기엔, 너의 친구·가족·일터처럼 너의 색이 또렷하게 살아 있는 자리에서 너를 다시 충전하세요. 충전한 너로 돌아오는 게 관계 보호예요.',
      r'상대가 너를 흔드는 자리라, 한 번씩은 의도적으로 $shortName한테 너의 한계를 솔직히 말해주세요. 한계를 숨기는 게 강함이 아니라, 한계를 정확히 공유하는 게 이 관계의 진짜 강함이에요.',
      r'네가 받는 자극이 다양한 자리라, 자극을 분류하는 습관이 도움돼요. 성장 자극·소음 자극·일시적 감정 자극을 구분하는 능력 자체가 이 관계에서의 너의 가장 큰 무기가 돼요.',
    ],
    _ElRel.neutral: [
      '오행상 자극도 충돌도 크지 않아 첫인상은 잔잔하고 편안해요. 누군가 적극적으로 신호를 보내지 않으면 자연스럽게 거리가 벌어질 수 있어서, 의식적으로 무게를 만들 때 비로소 깊이가 생기는 관계예요.',
      '서로 직접 살리지도 누르지도 않는 자리라, 저절로 묶이는 결이라기보다 같이 만들어가는 인연에 가까워요. 약속·만남·연락 같은 작은 의식이 관계의 뼈대가 돼요.',
      '안정적이지만 자극은 적은 흐름이라, "있으면 좋고 없어도 그럭저럭" 으로 끝날 수도 있어요. 한 사람이 먼저 두 발 다가가는 순간 관계가 비로소 자라요.',
      '서로의 기운이 평행선처럼 흘러서 큰 충돌 없이 오래 가기 좋은 사이예요. 다만 평행선이라 깊이는 시간이 천천히 쌓아주는 거니까, 짧게 보지 말고 길게 같이 가면 좋아요.',
      r'$shortName과 너 사이엔 큰 끌림도 큰 마찰도 없어서 첫 인상이 잔잔하게 지나갈 수 있어요. 평범한 자리에 작은 추억·반복되는 약속을 한 켜씩 쌓아갈 때 비로소 둘만의 무게가 생기는 관계예요.',
      r'오행상 직접 신호가 약한 자리라 자연스레 스쳐 지나가기 쉬운 흐름이에요. 누구 한 명이 먼저 "다음에 또 보자" 를 명확히 약속하지 않으면 인연이 옅어지니까, 의식적인 한 박자가 관계의 시작 신호예요.',
      '저절로 생기는 끌림보다 "선택해서 만들어 가는" 색이 강한 자리예요. 약속·연락·기념일 같은 작은 의식이 둘만의 뼈대를 만드니까, 자연스럽게 흘러가게 두기보다 의식적으로 한 박자씩 깊이를 더해주세요.',
      '큰 자극이 없는 만큼 가까워지는 속도가 천천히이고, 한 번 자리잡으면 오래 가는 흐름이에요. 짧은 시간 안에 결과를 보려 하지 말고, 1년·2년 단위로 관계의 두께를 늘려가는 시야가 답이에요.',
      r'$shortName의 결과 너의 결이 직접 만나지 않고 비껴 가는 자리라, 둘 다 손을 놓으면 거리가 그대로 벌어지기 쉬워요. 의식적인 만남 약속 하나가 관계 전체를 받쳐주는 자리예요.',
      r'서로의 기운이 평행선이라 갈등은 적지만 깊이를 만들 동력도 적어요. 깊이를 원한다면, 너희 둘 다 외부에 의지하지 말고 둘만 갈 수 있는 자리(여행·취미·프로젝트)를 의도적으로 만드세요.',
      r'중립 자리는 처음엔 편하지만, 시간이 지나면 권태로 빠지기 쉬워요. 권태를 풀어주는 가장 좋은 방법은 새로운 공동 목표 하나를 매년 추가하는 습관이에요.',
      r'직접 살리지도 누르지도 않는 자리라, 둘 사이엔 자연 화학반응보다 인공 화학반응이 필요해요. 이벤트·여행·새 친구 합류 같은 외부 자극이 둘만의 화학을 만드는 촉매가 돼요.',
      r'$shortName 옆에 있으면 마음이 편하지만 가슴이 두근거리지는 않는 자리예요. 그 편안함을 부정하지 말고 친구·동료·신뢰 관계의 기본 자산으로 활용하면 좋아요.',
      r'오행상 직접 신호가 없는 자리라, 둘 다 게을러지면 관계가 그대로 멈춰요. 한 사람이라도 약속을 잡고 다리를 놓는 노동을 멈추지 않으면, 그 노동량 자체가 관계의 진폭이 돼요.',
      r'중립 흐름은 첫 만남부터 강한 인상보다는 잔잔한 분위기가 더 많아요. 그 잔잔함을 매력으로 발전시키려면, 함께한 작은 순간을 의도적으로 기록·기념하는 습관이 도움돼요.',
      r'$shortName과 너 사이는 외부에서 보기엔 호흡이 좋아 보이지만, 안쪽에선 둘 다 큰 자극이 없다고 느끼기도 해요. 그 외부 평가에 안주하지 말고, 너희만의 비밀스러운 즐거움을 따로 키우세요.',
      r'기운이 비껴가는 자리라 큰 사건 없이 시간이 흘러요. 사건이 없는 게 관계의 단점일 수 있는데, 그 단점을 메우는 건 둘이 의도적으로 사건을 만드는 행동이에요.',
      r'중립 자리에선 갈등은 적지만, 한 번 갈등이 생기면 풀 동력도 부족해요. 그래서 갈등이 생기기 전에 작은 응어리를 자주 풀어두는 습관이 갈등 예방의 핵심이에요.',
      r'서로 직접 영향을 주지 않는 자리라, 너의 큰 일이 $shortName한테 자동 전달되지 않아요. 큰 일은 의식적으로 공유하는 게, 이 관계의 무게를 키우는 가장 효율적인 방법이에요.',
      r'직접적인 사주 신호가 없는 자리라 자연 발화가 어려운 관계예요. 다만 인공 발화에 익숙해지면, 자연 관계보다 더 정교하고 의도적인 관계로 키울 수 있어요.',
      r'$shortName과 너 사이엔 폭발도 침묵도 적어서, 외부에서 보면 "오래 가는 친구" 모양으로 보여요. 그 모양을 내부의 깊이로 채우려면, 의도적인 깊은 대화 시간을 한 달에 한 번이라도 잡으세요.',
      r'평행선 자리라 너희 둘만의 색은 외부 사건이 칠해주기 쉬워요. 같이 새로운 사람을 만나고 같이 새로운 자리를 가는 빈도가 늘수록 관계 색이 또렷해져요.',
      r'중립 흐름은 시간을 길게 잡고 보아야 진가가 드러나는 자리예요. 1년 단위로 너희 사이의 깊이가 어떻게 변했는지 점검하는 습관이 관계 보존의 비결이에요.',
      r'$shortName과 너의 관계는 자연 화학반응이 약한 만큼, "의도" 가 가장 큰 자산이에요. 의도적으로 약속하고, 의도적으로 기념하고, 의도적으로 표현하는 자리예요.',
      r'서로의 결이 다른 결을 직접 자극하지 않는 자리라, 둘 다 자기 일에 빠지면 거리가 슬슬 벌어지기 쉬워요. 정기적인 안부 한 줄이 관계의 가장 큰 의무이자 보호장치예요.',
      r'중립 자리에선 큰 사건보다 누적이 결정적이에요. 작은 약속·작은 메모·작은 선물 같은 누적이 시간이 지나면 큰 의미로 환산돼요.',
      r'기운이 평행선이라 서로한테 큰 영향이 안 미친다는 건, 너의 큰 변화를 $shortName이 모를 수도 있다는 뜻이에요. 너의 큰 변화는 적극적으로 알리는 게 이 관계의 정직 룰이에요.',
      r'$shortName과 너 사이는 크게 부딪힐 일이 적은 결이라, 그만큼 크게 풀어줄 계기도 잘 안 와요. 그래서 작은 응어리도 그날 안에 푸는 룰이 큰 응어리를 막는 첫 단추예요.',
      r'중립 흐름은 비행기로 치면 안전 운항 모드 같은 상태예요. 안전한 만큼 흥미는 적으니까, 흥미는 외부 컨텐츠·새 장소·새 활동으로 의식적으로 끌어오세요.',
      r'$shortName과 너 사이엔 강한 끌림이 없는 만큼 강한 부담도 없어요. 그 부담 없음을 자유로 해석하면, 어느 친구보다 길게 갈 수 있는 자유로운 관계가 만들어져요.',
      r'중립 자리에선 한 사람이 의식적으로 거리를 좁히지 않으면 둘 다 자기 자리로 돌아가요. 그래서 한 명이라도 "이 사람을 내 사람으로 만들겠다" 는 의지가 있는 시기에 관계가 비로소 자라요.',
      r'기운이 평행선이라 외부 변화가 겹치면 거리가 벌어지기 쉬운 자리예요. 큰 변화(이사·진로 같은 외부 사건)가 겹치는 시기엔 서로의 자리가 멀어지기 쉬우니까, 그런 시기일수록 평소보다 자주 안부를 챙기면 거리가 안 벌어져요.',
    ],
  };

  // R100 sprint 2 — EN expanded to 32 lines per enum (192 total).
  static const _relPoolEn = {
    _ElRel.same: [
      r"Same element overall — taste, tone, decision speed align without explaining. The flip side: shared weak spots, so when one dips, the other dips together.",
      r"Matching energy, so the first conversation already feels familiar. Comfort is high, novelty is low; it helps to surface new sides of each other on purpose.",
      r"Similar pattern underneath — silence isn't awkward. Because your weak spots overlap too, big decisions benefit from one outside opinion before you commit.",
      r"Standing on the same element — even the things that annoy you tend to be the same. Small differences can feel larger; naming them keeps the bond healthy.",
      r"Same element base — you read $shortName's mood without asking. The mirror effect runs both ways though, so when one of you wobbles, the other tilts with it. A small recovery ritual helps.",
      r"Same energy line, so the relationship moves at one tempo. Familiar fast, novel rarely — schedule new contexts (travel, hobbies, strangers' tables) on purpose so the bond doesn't go static.",
      r"Sharing the same element means you run similar decision circuits. When $shortName wavers, you tend to waver in the same direction — when your opinions line up exactly, take one more look from a different angle as a safety net.",
      r"Same energy, so daily conversation tones lock in naturally. Because your paces tie together so easily, scheduling regular solo time for each of you is the secret to a bond that lasts.",
      r"Twin elements means the cadence of small jokes locks in fast. Picks of food, rest mode, even sleep timing tend to match — refresh the loop with outside friends so the routine doesn't go flat.",
      r"You walk one element side by side, so tastes converge over time. Familiarity is the asset; budget for novelty (new book, new route, new face) on a calendar so the bond keeps breathing.",
      r"Same energy, same decision speed — the two of you tend to reach the same call quickly. Because you can also fall into the same blind spot at the same moment, slow the biggest choices by one full day before committing.",
      r"Standing on one element, everyday tastes and weekend rhythms tend to overlap. Once a season, choose a context $shortName has never tried — that's how same-element pairs stay interesting.",
      r"Twin pattern means starting a project together tends to feel obvious. Just remember both of you can hit the same wall at the same time; pre-plan staggered breaks so the whole project doesn't stall.",
      r"With the same element your field of view tends to narrow together. Run any big decision past one outsider before locking it in — that shared blind spot tends to be the main thing to watch in this bond.",
      r"Silence flows at the same tone when elements match. That comfort can hide change; once a month, ask $shortName what's new in their head — assumptions age fast in matched pairs.",
      r"Same-element pairs tend to build inside jokes fast. Keep one window open for outside language too — invite a third person into your loop occasionally so the world you share doesn't seal shut.",
      r"With one element, one mood spreads from you to $shortName fast. A one-line status check before meetings or plans is the cheapest insurance against unnecessary friction.",
      r"Twin elements means twin weak spots exposed at the same time. Identify two external supports (a friend, a habit, a system) in advance — that's how you weather the shared low seasons.",
      r"Same energy is gold for friendship rank one, but in romance or business the closeness needs structure. Pre-assign roles so being too similar doesn't blur both your colors.",
      r"You and $shortName tend to share a seasonal energy curve. Add one rule — no major decisions when both of you are in a dip — and the rest of the time the bond tends to run smooth.",
      r"Same element bonds are two mirrors facing each other. Mirrors that get too close stop reflecting the world; schedule deliberate outside stimuli to keep the bond ventilated.",
      r"Sharing one element means sharing one set of weak spots. Pre-decide which outside person or routine you'll lean on when both of you wobble — that's how to avoid a synchronized collapse.",
      r"Twin patterns enable deep first conversations. Don't only chase depth — protect daily small talk too, because matched pairs lose the everyday lightness fastest.",
      r"$shortName's path can feel like your own path here. That harmony is wealth, but keep one or two fork-points clearly yours so the bond stays a pair, not a merge.",
      r"Same element means details tend to land the same way for both. Don't take that for granted — being the one who names $shortName's micro-changes that only you would notice tends to be how a shared-element bond grows.",
      r"Identical energy means you're drawn to the same trends, the same people, the same content. The shared lane fills quickly — protect each of your solo lanes too.",
      r"Comfort languages tend to match between same-element pairs. Your one sentence can land as unusually precise comfort for $shortName — use that precision often, not just in crises.",
      r"Conflict-avoidance patterns also match, which means problems can stack quietly. Pre-agree on a 'pause and talk' signal so both of you don't dodge in the same direction.",
      r"Twin elements decide things faster as a pair than as a trio. The risk is haste; deliberately slow your biggest calls and ask one outside view before locking in.",
      r"When same-element pairs clash, the friction is short and recovery is mirrored. Knowing that cycle prevents short fights from inflating into long ones.",
      r"Trust tends to build fast on shared elements. That fast trust tends to earn interest from small kept promises, so treating tiny commitments as the bond's long-term credit score helps.",
      r"Same element means the room tone unifies the moment you two arrive. That unified vibe is your strength, but it can read as a closed circle to outsiders — leave a deliberate seat open for new people.",
    ],
    _ElRel.iGenerate: [
      r"A generating (相生) line runs from you toward $shortName. What you say tends to land deep, and watching $shortName step forward tends to steady you in return.",
      r"You tend to be the giving side here. Day to day it can feel uneven, but a generating line tends to hold steady when you tend it — slow tends to be the right pace.",
      r"Your element tends to quietly feed $shortName's, so honesty around you tends to come easier for them. Once you settle into giving, checking your own pace helps.",
      r"The generating arrow tends to run from you to them. Words you toss off can stay with $shortName a long time — owning that weight keeps the line healthy.",
      r"You tend to warm $shortName's weak spots quietly. The shift isn't visible day to day, so reading this line in seasons rather than weeks fits it best.",
      r"You tend to give light first, so confidence near you can come easier for $shortName. Saving real recharge time for yourself matters — your battery tends to be the line's baseline.",
      r"You tend to pave the road first, so $shortName following can feel natural. Watching only your own pace can cost them their breath, so letting them lead sometimes keeps it balanced.",
      r"You feed their growth in a clear generating (相生) flow. As $shortName steps up around you, naming the small process shifts — not just the results — tends to keep the line honest.",
      r"You tend to be the nutrient channel here. Leading from joy in their growth, rather than from awareness of giving, tends to let the line breathe naturally.",
      r"Wherever your hand touches, $shortName tends to move forward by an inch. Revisiting the change at the year mark fits this line better than rushing the speed.",
      r"As the giver here, you may occasionally see $shortName lean. A lean isn't danger — but never trading away your own recovery routine keeps the line steady.",
      r"In a generating line, both praise and correction from you tend to land with extra weight. Dropping short affirmations into the small moments of the day tends to help.",
      r"You → $shortName tends to be the direction. Small environment changes you make can be large pivot points for them — assuming something minor for you is minor for them tends to miss the mark.",
      r"Your hours tend to be $shortName's nutrient. Spend too many and you starve yourself — equal time alone tends to be non-negotiable in this line.",
      r"Your decisions often open $shortName's next chapter. If the weight feels heavy, handing back the call sometimes — 'I'll let you take this one' — is a real card to play.",
      r"You tend to light first, so your mood one notch can set the room two notches. Honest sharing of your real condition tends to be both manners and infrastructure here.",
      r"As the channel, you tend to give $shortName recovery just by being nearby. Knowing that intangible service helps you avoid burning out from over-effort.",
      r"Your own growth tends to feed this line. Pursuing your own enrichment — books, friends, hobbies — is, paradoxically, one of the most relational acts available to you.",
      r"In a generating flow, you may step back first in conflicts almost by default. Marking two areas where you never compromise keeps the giving from eroding you.",
      r"Your pace tends to set $shortName's growth rate. Fast pull tends to bring fast growth with side effects; slow pull tends to bring deeper growth — the pre-agreed pace tends to be the right pace.",
      r"Your praise tends to land harder on $shortName than most. So don't ration praise, and reserving sharp critique for one short, warm sentence at most helps.",
      r"Small favors from you tend to register as major events on their side. Not a burden — a signal that your daily life matters to them, so don't shrink the small expressions.",
      r"As you feed, occasionally check what color of result $shortName sends back. That feedback tends to guide your next round of investment.",
      r"You → $shortName means your steadiness tends to carry over to them. So caring for your own condition first isn't selfish — it tends to be the most strategic act for both.",
      r"$shortName tightening up beside you tends to be partly a mirror of your own intensity showing through. As you grow, the line tends to grow with you.",
      r"You tend to end up as the path-setter — but practising the follower role a few times tends to give the relationship depth instead of flatness.",
      r"As the giver, watch for the small moments when $shortName tries to return something. Naming them clearly tends to help them step out of pure-receiver mode.",
      r"Your element is the one that tends to lift the other, so your fatigue tends to be the line's fatigue too. Solo recovery (exercise, rest, no-call hours) tends to outweigh any meeting.",
      r"Your own growth tends to be the line's environment. Doing your own work well tends to become the largest expression of care available to you here.",
      r"In a generating flow, asking $shortName directly what they need now tends to beat guessing. Targeted help tends to save energy on both sides.",
      r"As nutrient, you may watch $shortName's color thin out at times. That tends to be when stepping back makes the space for them to rebuild their own color.",
      r"Your influence tends to permeate their everyday here — even casual jokes can echo for a while. Recognizing that scale tends to be what keeps a generating line balanced.",
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
      r"$shortName mirrors your weak spots like light hitting glass — visible, not painful. Practice not being ashamed of your gaps; in this bond they're meant to be seen.",
      r"Your empty seats are filled by $shortName's flow. Don't second-guess why they give; receiving well is a skill, and this bond starts with that skill.",
      r"Beside $shortName your edges sharpen. That sharpness is partly their gift, so credit doesn't stop with you — return the credit out loud once in a while.",
      r"Their pattern serves as nutrient for your next chapter. Don't take that step up as solo achievement; pay it forward by being someone else's step in turn.",
      r"$shortName's calm steadies your wobble. Don't make your wobble shameful; in this bond, asking openly for help is the correct usage.",
      r"You absorb a lot here — words, habits, attitudes from $shortName quietly become yours. Trace and credit the source once in a while; it pays interest on their self-esteem.",
      r"Their pattern complements yours, so asking $shortName's opinion first feels natural. Just don't hand off the final call — that last sentence is still yours.",
      r"You're more at ease in their presence than in most places. That ease is the signal — treat 'receiving well' as a competence, not a deficiency.",
      r"As they offer color, your color quietly comes online. So even small messages from $shortName carry oversized weight — match that by replying with full attention.",
      r"Their tone fills the empty seat in yours. If you let it overwrite you entirely, your own color fades; keep solo identity work (a journal, a hobby, a solo trip) in steady rotation.",
      r"$shortName's one sentence can change the weight of your day. That means a careless sentence lands deep too — it's fair to ask, plainly, for a gentler tone in hard weeks.",
      r"Their pattern revives you, so in hard seasons you'll call them first. Don't ration the call out of pride; ask openly, and once recovered, give back in your own way.",
      r"Time with $shortName tends to coincide with your major leaps. Don't credit only your own effort — name the person who was beside you during that season.",
      r"The more honestly you admit your gaps, the more precisely $shortName can help. Hiding weakness is the biggest loss here; you can afford more transparency in this bond.",
      r"Time near $shortName accelerates your recovery. Designing time to be near them is itself a self-care action.",
      r"The producing flow toward you isn't permanent; once you feel the lift, start designing your own way of giving back, in your own currency.",
      r"$shortName's warmth thaws your cold. Don't measure the warmth like data — name it out loud occasionally; that recognition is the strongest return.",
      r"As the receiver, you risk $shortName giving until they thin out themselves. Just as you name your own changes, name theirs too — that's a receiver's real duty.",
      r"Resources flow your way here. Before big events, share the situation honestly with $shortName; transparency multiplies their help.",
      r"As receiver, train yourself to notice $shortName's small changes more sharply than usual. If their tone is off, don't skip — ask briefly the same day.",
      r"They're in the position of lifting you, which means if you collapse, the bond skews. Your own recovery is, in fact, a duty to the bond — pursue it without guilt.",
      r"$shortName's flow has timing, season, total volume. Don't try to absorb in one gulp; slow intake is what makes this bond last on both sides.",
      r"As receiver, $shortName invests more attention in you than average. Don't carry that as weight — return one accurate 'thanks' in the same day, every time.",
      r"The producing arrow toward you means you should be the first to notice $shortName's fatigue. The duty of receiving isn't to receive more — it's to notice more.",
    ],
    _ElRel.iOvercome: [
      r"An overcoming (相剋) line runs from you toward $shortName. You tend to lead naturally and read their weak spots like a coach — a notch sharper, though, can read as control, so intent and delivery have to match.",
      r"You overcome them, so short words tend to land hard. $shortName may hold back around you without meaning to; building in a softer beat keeps it healthy.",
      r"Leadership drifts to your side naturally. Used well it's a mentor bond; used badly it becomes one-way instruction. Leaving room for their own color is what keeps it the first kind.",
      r"You refine them, so $shortName's flaws show clearly when you're close. How you point them out matters most — questions land better than verdicts.",
      r"You compress $shortName's flow without meaning to, so even a flat-toned sentence can read as a verdict. Double your visible praise and keep corrections private — that one rule reshapes the whole weight of the bond.",
      r'''Leadership lands on your side by default. It's easier to drive than to wait, but $shortName loses chances to speak first; build a deliberate "what do you think?" beat in before every decision.''',
      r"You keep $shortName tidied up, so on most days you read as the steady older one. But when they keep adjusting to you, their own color fades — practice just following their lead from time to time.",
      r"You're the one refining them, so your precision can land as both fuel and pressure on $shortName. Letting them reach the answer themselves, instead of handing it over, is the line between mentor and controller.",
      r"In front of you, $shortName tends to hear your firmness louder than you mean it. One notch softer than your default is the calibration that turns the same words from coach into critic.",
      r"As the one in pressing position, your standards quietly become $shortName's standards. Treat that as weight, not power — your opinion ends up etched into their daily life.",
      r"Catching $shortName's weak spots fast is both your strength and your risk. Don't point it out the instant you see it; wait one beat so they spot it themselves first.",
      r"Driving the rhythm here feels easy to you, while $shortName spends more courage to voice an opinion. When they do, receive it as a welcome, never as a review.",
      r"Their action patterns analyze quickly for you. Don't deliver the analysis as judgment; reframe as a question so they discover their own color inside it.",
      r"Coaching seat is your natural fit, which means $shortName's self-determination needs deliberate room. Hand over small choices (menu, route, time) on purpose.",
      r"$shortName self-edits more around you. To loosen that self-edit, you go first — show your own imperfections honestly; that's the most effective unlock.",
      r"Your bar becomes their bar here. Protect $shortName from over-aligning with your color; add 'your way is also fine' to your everyday vocabulary.",
      r"In overcoming flow your way, even jokes risk landing as appraisals. Pair each joke with a quick safety line — 'just kidding, you're enough as you are.'",
      r"As refiner, $shortName's growth pace will often feel slow to you. Reframe that gap not as patience, but as 'someone living on a different clock' — that's the real generosity.",
      r"$shortName trims their expression beside you. To keep restraint from looking like virtue, send constant signals that full expression is safe in your space.",
      r"Your precision is double-edged in this seat. Don't swing it; kept in its case, it tends to make you the kind of mentor $shortName keeps for a long time.",
      r"You see $shortName's gaps more clearly than others do. That's your eye, not their flaw — they might not show those gaps in front of a different friend.",
      r"You press, so $shortName's color takes longer to grow beneath yours. Don't only chase fast results; log their annual changes to read the bond accurately.",
      r"As the active end of overcoming flow, conflict often starts with your sentence. Three deliberate breaths before that sentence tend to cut the friction sharply.",
      r"As refiner, their progress easily becomes your satisfaction. Don't claim that progress as yours — keep credit clearly on $shortName's name plate.",
      r"$shortName can come across smaller next to you than on their own. Rather than sit with that contrast, schedule recurring self-check moments asking 'am I leaving them room?'",
      r"In mentor seat, $shortName's growth tempts you into evaluator mode. Schedule deliberate just-hanging-out time with no growth agenda attached.",
      r"In overcoming flow, silence can do real damage. Using silence as protest tends to be the costliest pattern here; resolve discontent in words on the same day.",
      r"Your speed of precision is too fast for $shortName at times. Rest the precision deliberately; cards like 'we're just hanging out right now' are valid.",
      r"Catching $shortName's immaturity fast can read as coaching or as control. The line isn't the frequency of catches — it's how much self-discovery time you grant before catching.",
      r"In pressing position, voice your opinion last in big decisions on purpose. When you speak first, $shortName's own voice tends to get crowded out.",
      r"At this seat, the same input can land on $shortName as steady coaching or as a weight that sticks. The fork lies in one tone, one extra beat of patience.",
      r"As refiner, deliberately keep your hands off $shortName's private circles (hobbies, friendships, family). That untouched zone keeps the whole bond breathable.",
    ],
    _ElRel.theyOvercome: [
      r"Their energy shifts your pace (overcoming flow toward you). The closer you get, the more it helps to hold your own color. Handled well, this kind of bond tends to leave both sides steadier.",
      r"They overcome you, so a single sentence from $shortName can spike you. Read that as a sign of how much they matter — not as a weakness in you.",
      r"Leadership drifts toward them. Don't just match; hold one or two non-negotiables so the relationship lasts past the early pull.",
      r"They challenge you by default. Facing that discomfort instead of dodging it is where your weak spot turns into strength — a growth-style bond.",
      r'''$shortName's tone tilts your normal pace, so the closer you get the more often a "this is shaking me" beat can surface. Honor that signal with short rest and brief distance — friction turns into growth once it's named.''',
      r'''Their seat mirrors your weak spots with precision. Defense rises first, but practicing honest "yes, that's me" responses around $shortName forges your next-level self — a quietly grateful bond.''',
      r"$shortName nudges your speed without meaning to. Don't get swept along — anchor one or two daily basics (morning, exercise, sleep) and their pressure converts into your new energy.",
      r"They shake you a little, but it's also the kind of jolt that surfaces your weak spots the way a coach would. The moment you receive $shortName's bluntness as a mirror rather than a verdict, this bond tends to become one of your fastest ways to grow.",
      r"In their seat your usual decision speed can dip. Don't take that lag as a flaw; treat slower decisions in $shortName's presence as your safe mode.",
      r"One sentence from $shortName creates oversized ripples in your day. The ripple control is yours, not theirs — when absorption runs too hot, stretch the distance deliberately.",
      r"When they shake you, your strongest tool isn't composure — it's your own routine. Two or three daily anchors are the keel that keeps you upright through their pressure.",
      r"$shortName is stimulating in this position, so deliberately stepping away from the stimulus is part of the rhythm. Naming distance as recovery, not avoidance, is important here.",
      r"The stimulus you absorb is also a growth signal. The bigger the spike, the faster the next chapter — and the longer the recovery; budget both sides of the trade.",
      r"Their pattern reads your weak spots accurately, so you see your own gaps sharper here. Treat that sharpness as a mirror effect, not as their fault — that flip resets the bond.",
      r"At decision points your usual judgment dims around $shortName. Deliberately take big decisions away from their presence; that physical distance protects your call.",
      r"$shortName shifts your pace; protecting your default tempo matters above all. Run regular check-ins: 'is this still my speed?' is a question worth asking weekly.",
      r"With the absorption running this high, sit with $shortName's words for 24 hours before responding. Slow replies tend to be your truer replies in this bond.",
      r"Their element refines yours, so closeness sharpens your details. As detail sharpens, self-censorship grows too; deliberately loosen one notch to keep self-expression alive.",
      r"In seasons you feel less like yourself beside $shortName, don't let that settle in as normal. Check in with an outside mirror — friends, work, family — that's this bond's safety net.",
      r"In shaken position, small expression changes can hit you harder than expected. Don't treat that as weakness — name it as your sensitivity signal and install a one-beat delay rule before reacting.",
      r"As they refine you, $shortName's directness reads as coaching or as insult depending on your condition. On low days, postpone the directness by mutual agreement.",
      r"$shortName presses your flow, so your autonomous time (a solo walk, a hobby, a workout) is even more sacred. The moment you start giving it up, balance starts breaking.",
      r"As receiver of shaking, recovery time after conflict tends to run long for you. Don't read that as a flaw; explain it to yourself as your own recovery cadence.",
      r"In the passive seat of overcoming flow, one sentence from $shortName tends to carry extra weight. Their unintentional joke can be a big event for you — sharing that openly is the protection.",
      r"What you absorb here is what builds your toughness. Receive without dodging, but never get swept — the balance starts with preserving your own daily routine.",
      r"$shortName's precision is both stimulus and burden. Reduce the burden by giving yourself permission: 'I don't have to mirror your precision 100%.'",
      r"Their element refines yours, and that tends to speed your growth. The moment your growth outruns your breath is the warning sign — solo check-in once a month, no exceptions.",
      r"$shortName reflects your weak spots clearly, and getting practised at acknowledgment tends to pay off for a long time. Just don't let acknowledgment turn into self-blame; pair it with 'still, I'm doing well.'",
      r"In shaken position, decisions, conflicts, and missteps occur more often. Don't book those as failures; accounting-wise, write them as learning cost inside this bond.",
      r"In seasons your color thins beside $shortName, recharge in places where your color is loud (friends, family, work). Returning recharged is, in itself, bond protection.",
      r"As receiver of shaking, occasionally state your limits to $shortName plainly. Hiding limits isn't strength here; precise sharing of limits is.",
      r"As receiver of varied stimulus, classifying the stimulus is half the skill. The ability to sort 'growth stimulus' from 'noise' is your sharpest tool in this bond.",
    ],
    _ElRel.neutral: [
      r"A neutral line with yours — no spark, no clash. This kind of bond tends to drift unless someone deliberately builds weight into it.",
      r"Neither generating nor overcoming directly, so this tends to be less a spontaneous draw and more a built one. Small rituals — meetings, replies, plans — tend to become the skeleton of the bond.",
      r"Stable but low-stimulation, so it can settle at 'nice to have, fine without.' Depth here tends to show up after one of you takes the first two steps in.",
      r"Parallel elements — easy to run long without big clashes. But parallel tends to mean depth is on the clock, so the long game fits this line better than the short one.",
      r"Between you and $shortName there's neither strong pull nor heavy friction, so first impressions tend to pass softly. Stacking small memories and repeated promises one layer at a time tends to be how weight forms.",
      r'''A direct elemental signal is weak here, so this bond tends to drift off if no one names the next step. A clear "let's meet again on X" from one side tends to turn this from passing into staying.''',
      r"More chosen than spontaneous, this tends to be a relationship you build with intention. Small rituals — promises, replies, anniversaries — tend to form the skeleton, so deliberately adding a beat of depth helps.",
      r"With no big stimulus, closeness here tends to come slowly — but once it sets, it tends to hold. Widening the lens to a year or two fits this bond better than reading it in weeks.",
      r"$shortName's element and yours cross sideways, so mutual indifference tends to thin the bond fast. One deliberate meeting per quarter tends to be enough to keep it alive.",
      r"Parallel elements, so conflicts tend to stay low but so does momentum. Building trips, hobbies, and projects only the two of you share tends to make outside stimulus the catalyst for depth.",
      r"Neutral seats tend to feel easy at first and slide toward boredom. Adding one new shared goal per year, deliberately, tends to be the best antidote.",
      r"With neither generating nor overcoming, this bond tends to run on built chemistry rather than natural. Events, travel, and new mutual friends tend to be the catalysts here.",
      r"Near $shortName your heart tends to settle rather than race. Filing that calm as the asset of a friend, colleague, or trust relationship — and using it as such — tends to help.",
      r"With no direct elemental signal, mutual laziness tends to freeze the bond as is. As long as one of you keeps booking the next plan, that labor itself tends to be the amplitude of the bond.",
      r"A neutral line leans more on quiet first impressions than strong sparks. Deliberately documenting and commemorating small moments tends to turn that calm into something warmer.",
      r"Between you and $shortName, outsiders tend to see a smooth pair, while inside both of you may feel low stimulation. Cultivating private joys only the two of you know tends to help more than settling for the outside reading.",
      r"The two elements cross sideways, so time tends to pass without major events. The lack of events can be a weak spot — making deliberate events together tends to counter it.",
      r"In neutral seats conflicts tend to be rare, but so is the energy to resolve them. Routinely clearing tiny grievances before they accumulate tends to pre-empt that.",
      r"Direct influence is weak, so your big news doesn't tend to auto-relay to $shortName. Sharing big news deliberately tends to be the most efficient way to add weight to this bond.",
      r"With no direct anchor between the two of you, a spontaneous spark tends to be rare. But once you both get used to deliberate ignition, an intentional bond can run as carefully as effortless pairs.",
      r"Between you and $shortName there's neither explosion nor silence, so outside eyes tend to see a 'long-time friend' shape. Booking one real, longer talk per month tends to match that shape with internal depth.",
      r"On a parallel line, the bond's color tends to come from outside events. The more often you meet new people and visit new places together, the more vivid the hue tends to get.",
      r"A neutral line tends to reveal its real value over a long arc. Making annual reviews of the bond a habit tends to be the way neutral pairs hold.",
      r"With $shortName, natural chemistry is weak, so 'intention' tends to be the largest asset here. Intentional meetings, intentional anniversaries, intentional expressions — all of it.",
      r"Neither element stimulates the other directly, so this bond tends to drift if both of you sink into your own work. A regular check-in line tends to be the biggest obligation and protection here.",
      r"In neutral seats accumulation tends to matter more than events. Small promises, small notes, small gifts tend to compound into large meaning over time.",
      r"Parallel elements mean your major shifts can pass under $shortName's radar. Announcing your big shifts actively tends to be the honesty rule of this bond.",
      r"Between you and $shortName fights tend to be rare, but so is deep repair. Resolving tiny knots on the same day tends to be the first button against bigger knots.",
      r"A neutral line tends to be a kind of safe-cruise mode. Safe but bland — bringing excitement in deliberately through outside content, new places, and new activities tends to help.",
      r"With no strong pull there tends to be no heavy burden either between you and $shortName. Reading the lack of burden as freedom — a free-flowing bond can run long when you tend it.",
      r"In neutral seats, unless one person deliberately closes distance, both tend to default back to their own lanes. This bond tends to grow in the seasons one person commits to truly showing up for it.",
      r"Parallel elements tend to be weak against outside shock. When big life changes (moves, career shifts) overlap, the bond stretches easily — checking in more often through those stretches helps.",
    ],
  };

  // R100 sprint 2 — closer pool 5 → 64 (KO/EN 각각). 사용자 mandate "엄청 반복".
  static const _closerPoolKo = [
    r'$shortName — $blurbTail 이 성향이 너의 일상에 한 자락 더해질 때, 두 사람만의 호흡이 생겨요.',
    r'$shortName의 한 줄 — $blurbTail 이 흐름이 너의 일주와 맞닿는 지점이 바로 너희만의 관계 색이에요.',
    r'$shortName — $blurbTail 이 분위기가 너의 페이스에 섞일 때, 평범한 하루가 좀 다르게 느껴져요.',
    r'$shortName의 색 — $blurbTail 너의 일주가 이 색을 어떻게 받아들이느냐에 따라 둘 사이 결이 달라지기 쉬워요.',
    r'$shortName — $blurbTail 너의 일상에 이 한 조각이 더해지는 순간, 둘만의 톤이 만들어져요.',
    r'$shortName 한눈에 — $blurbTail 이 결을 한 번 마주한 사람은 다음 약속을 자연스럽게 잡고 싶어져요.',
    r'$shortName, 결국 한 단어 — $blurbTail 그 단어가 너의 일주와 만나면 둘의 시즌이 시작돼요.',
    r'$shortName 노트 — $blurbTail 너의 일주가 이 결을 평소보다 한 톤 진하게 만들어줘요.',
    r'$shortName이라는 사람 — $blurbTail 너의 시간이 더해지면 이 사람의 색이 두 배로 짙어져요.',
    r'$shortName 메모 — $blurbTail 너의 일주가 가까이 있을 때 이 톤이 가장 자연스럽게 빛나요.',
    r'$shortName의 분위기 — $blurbTail 같이 있을 때 이 결이 더 또렷하게 살아나는 시즌이에요.',
    r'$shortName 한 줄 요약 — $blurbTail 이 결이 너희 둘만의 사적인 톤으로 번지는 자리예요.',
    r'$shortName 정리 — $blurbTail 그 결을 너의 일상이 받아주는 방식이 둘 사이의 깊이가 돼요.',
    r'$shortName이 가진 색 — $blurbTail 너의 일주와 만나면 이 색이 한 번 더 정돈돼서 보여요.',
    r'$shortName의 결 — $blurbTail 너의 자리가 옆에 있을 때 이 결의 잔향이 길게 남아요.',
    r'$shortName 첫 인상 — $blurbTail 그 인상이 너의 결과 만나는 자리가 둘의 시작점이에요.',
    r'$shortName의 페이스 — $blurbTail 너의 일주가 이 페이스를 부담 없이 따라가요.',
    r'$shortName이라는 사람의 한 단면 — $blurbTail 너의 일상 안에선 그 단면이 정면으로 보여요.',
    r'$shortName의 한 호흡 — $blurbTail 그 호흡에 너의 호흡이 자연스레 겹쳐지는 시점이 와요.',
    r'$shortName 한 컷 — $blurbTail 너의 일주가 옆에 있으면 이 한 컷이 영화의 도입처럼 풀려요.',
    r'$shortName의 톤 — $blurbTail 너의 결이 받아주는 방식에 따라 이 톤이 둘만의 사운드가 돼요.',
    r'$shortName, 짧게 정리 — $blurbTail 너의 일상 안에 들어왔을 때 이 결이 가장 단정하게 자리잡아요.',
    r'$shortName의 흐름 — $blurbTail 너의 시간이 흐를수록 이 흐름의 깊이가 자연스럽게 두 배가 돼요.',
    r'$shortName 본질 — $blurbTail 너의 일주가 그 본질을 가장 정확히 알아보는 자리에 서 있어요.',
    r'$shortName 한 컷 더 — $blurbTail 너의 결이 옆에 있으면 그 한 컷에 디테일이 한 겹 더해져요.',
    r'$shortName 스타일 — $blurbTail 너의 일주가 이 스타일을 입히는 방식이 둘만의 분위기가 돼요.',
    r'$shortName의 잔잔한 면 — $blurbTail 너의 일상 한쪽에 이 잔잔함이 자리잡으면 호흡이 한결 차분해지기 쉬워요.',
    r'$shortName 본 모습 — $blurbTail 너의 결이 가까이 있을 때 이 본 모습이 자연스럽게 풀려요.',
    r'$shortName 핵심 — $blurbTail 그 핵심이 너의 일주와 부딪힘 없이 자리잡는 자리예요.',
    r'$shortName 한 줄 — $blurbTail 너의 일주가 받쳐주면 이 한 줄이 둘만의 슬로건처럼 자리잡아요.',
    r'$shortName 가장 진한 톤 — $blurbTail 너의 시간이 옆에 있을 때 그 톤이 가장 길게 남아요.',
    r'$shortName의 자리 — $blurbTail 너의 일상 안 한 칸을 이 자리가 채우는 시즌이에요.',
    r'$shortName 한 모서리 — $blurbTail 너의 결과 만나면 그 모서리가 부드럽게 다듬어져서 보여요.',
    r'$shortName의 평소 — $blurbTail 너의 일주가 가까울 때 그 평소가 평소보다 한 단계 정돈돼요.',
    r'$shortName 컨셉 — $blurbTail 너의 일상 톤이 이 컨셉을 한 번 더 또렷하게 만들어줘요.',
    r'$shortName 한 면 — $blurbTail 너의 결이 옆에 있을 때 그 한 면이 정확히 카메라 정면으로 와요.',
    r'$shortName 무드 — $blurbTail 너의 일주가 이 무드를 일상 톤으로 자연스레 변환해줘요.',
    r'$shortName 정수 — $blurbTail 너의 시간이 옆에 흐를수록 그 정수가 평균보다 빠르게 드러나요.',
    r'$shortName 짧게 — $blurbTail 너의 일주가 만나면 그 짧음이 오래 가는 인상으로 자리잡아요.',
    r'$shortName의 결과 — $blurbTail 너의 일상 안에서 그 결과가 한 톤 부드럽게 마무리돼요.',
    r'$shortName이라는 신호 — $blurbTail 너의 결이 이 신호를 받는 자리에 정확히 서 있어요.',
    r'$shortName 본문 — $blurbTail 너의 일주와 만나는 부분이 그 본문의 가장 진한 줄이에요.',
    r'$shortName 단 한 줄 — $blurbTail 너의 결이 옆에 있으면 그 한 줄이 둘만의 시그니처가 돼요.',
    r'$shortName이라는 이름 — $blurbTail 너의 일상 안에 이 이름이 한 번 등장한 뒤로 톤이 바뀌어요.',
    r'$shortName의 평균 — $blurbTail 너의 일주가 옆에 있을 때 이 평균이 한 단계 위로 올라가요.',
    r'$shortName의 디테일 — $blurbTail 너의 결이 받아주면 이 디테일이 평균보다 길게 살아남아요.',
    r'$shortName 핵 — $blurbTail 너의 일주가 가까울 때 그 핵이 평균 두 배 빠르게 보여요.',
    r'$shortName 한 음 — $blurbTail 너의 일상 안에 그 한 음이 들어오면 분위기 전체가 살짝 달라져요.',
    r'$shortName 한 톤의 정리 — $blurbTail 너의 일주가 옆에서 그 톤의 안정을 한 번 더 받쳐줘요.',
    r'$shortName의 안쪽 — $blurbTail 너의 결이 가까이 있을 때 그 안쪽이 정확한 각도로 보여요.',
    r'$shortName이라는 분위기 — $blurbTail 너의 일상 안에 들어오면 그 분위기가 더 정직하게 풀려요.',
    r'$shortName의 결 한 줄 — $blurbTail 너의 일주가 받쳐주면 그 결이 일상 어디서나 살아 있어요.',
    r'$shortName, 정리하자면 — $blurbTail 너의 결과 만나면 그 정리가 둘만의 페이지가 돼요.',
    r'$shortName 한 음정 — $blurbTail 너의 일주가 그 음정에 화음을 더해주는 자리예요.',
    r'$shortName 본바탕 — $blurbTail 너의 일상 톤이 그 본바탕을 일상 어디서나 자연스럽게 만들어요.',
    r'$shortName 한 박자 — $blurbTail 너의 결이 그 박자를 따라줄 때 둘만의 리듬이 만들어져요.',
    r'$shortName 본인의 색 — $blurbTail 너의 일주가 만나면 그 색이 평균보다 한 단계 또렷해요.',
    r'$shortName의 자기다움 — $blurbTail 너의 일상 안에서 그 자기다움이 가장 편하게 풀려요.',
    r'$shortName 본문 한 줄 — $blurbTail 너의 결과 만나면 그 줄이 둘의 일상에 안착해요.',
    r'$shortName 한 자 — $blurbTail 너의 일주가 옆에 있을 때 그 한 자가 둘의 키워드가 돼요.',
    r'$shortName 한 결 — $blurbTail 너의 결이 그 결을 받아주는 방식이 둘 사이 깊이의 단위예요.',
    r'$shortName의 컬러 — $blurbTail 너의 일주가 옆에 있을 때 그 컬러가 일상 톤으로 정착해요.',
    r'$shortName 한 곡 — $blurbTail 너의 결과 만나면 그 한 곡이 둘의 단골 트랙처럼 자리잡아요.',
    r'$shortName이 보내는 신호 — $blurbTail 너의 일주가 그 신호를 받는 안테나처럼 작동해요.',
    r'$shortName의 본 톤 — $blurbTail 너의 일상이 옆에 있을 때 그 본 톤이 평소보다 한 결 더 짙어져요.',
    // R100 sprint 2-bis — pool 65 → 96 추가 변별 (+31).
    r'$shortName의 한 마디 — $blurbTail 너의 일주가 그 한 마디를 받아 보내는 자리에 앉아 있어요.',
    r'$shortName 본 박자 — $blurbTail 너의 결이 옆에 있으면 그 박자가 일상 박자로 자리 잡아요.',
    r'$shortName의 한 면 더 — $blurbTail 너의 일주와 만난 뒤에 그 면이 한 번 더 또렷이 떠올라요.',
    r'$shortName 한 뼘 — $blurbTail 너의 결이 받쳐주면 그 한 뼘이 둘만의 영역으로 굳어요.',
    r'$shortName이라는 톤 — $blurbTail 너의 일상이 옆에 있을 때 그 톤이 평소보다 두 톤 짙어 보여요.',
    r'$shortName의 코어 — $blurbTail 너의 일주가 옆에 있을 때 그 코어가 평소보다 한 박자 빠르게 비쳐요.',
    r'$shortName 한 결의 정의 — $blurbTail 너의 결과 만나면 그 정의가 둘만의 단어로 굳어요.',
    r'$shortName 첫 자 — $blurbTail 너의 일주가 옆에 있을 때 그 첫 자가 둘의 시작 신호처럼 들려요.',
    r'$shortName 한 음의 깊이 — $blurbTail 너의 결이 받쳐주면 그 깊이가 평균 두 배로 살아남아요.',
    r'$shortName 한 행 — $blurbTail 너의 일주와 만나면 그 한 행이 둘만의 책 한 페이지가 돼요.',
    r'$shortName의 자기 색 — $blurbTail 너의 일상 톤이 그 색을 자연스럽게 받아 주는 자리예요.',
    r'$shortName 결의 안쪽 — $blurbTail 너의 결이 가까이 있을 때 그 안쪽이 별도의 조명 없이 살아 있어요.',
    r'$shortName 한 줄의 표면 — $blurbTail 너의 일주가 만나면 그 표면 아래에서 한 결 더 보여요.',
    r'$shortName의 잔향 — $blurbTail 너의 일상 안에 그 잔향이 들어오면 톤이 한 박자 길어져요.',
    r'$shortName이라는 한 결 — $blurbTail 너의 결과 만나면 그 한 결이 둘만의 표준 톤이 돼요.',
    r'$shortName의 첫 줄 — $blurbTail 너의 일주가 옆에 있으면 그 첫 줄이 둘만의 인트로처럼 풀려요.',
    r'$shortName 한 가닥 — $blurbTail 너의 결이 옆에 있을 때 그 한 가닥이 일상 톤으로 자연스럽게 짜여요.',
    r'$shortName의 거리감 — $blurbTail 너의 일상 안에 들어오면 그 거리감이 둘만의 안전선처럼 자리잡아요.',
    r'$shortName의 한 시즌 — $blurbTail 너의 일주가 만나면 그 시즌이 두 사람의 시간으로 기록돼요.',
    r'$shortName 첫 페이지 — $blurbTail 너의 결이 옆에 있을 때 그 첫 페이지가 둘만의 책으로 이어져요.',
    r'$shortName의 표면 톤 — $blurbTail 너의 일주가 가까울 때 그 표면 톤이 평소보다 한 결 진해 보여요.',
    r'$shortName의 평소 결 — $blurbTail 너의 일상이 옆에 있을 때 그 평소 결이 두 사람의 기본 단위가 돼요.',
    r'$shortName의 한 박 — $blurbTail 너의 결과 만나면 그 한 박이 둘만의 메트로놈처럼 자리잡아요.',
    r'$shortName 본 색 — $blurbTail 너의 일주가 옆에 있을 때 그 본 색이 평균 한 단계 진해 보여요.',
    r'$shortName 한 마디 더 — $blurbTail 너의 결이 받쳐주면 그 한 마디가 둘만의 약속어가 돼요.',
    r'$shortName의 자기 박자 — $blurbTail 너의 일상 안에서 그 박자가 자연스러운 톤으로 안착해요.',
    r'$shortName의 한 면 — $blurbTail 너의 일주가 가까울 때 그 한 면이 평균보다 한 결 정확히 보여요.',
    r'$shortName이라는 모양 — $blurbTail 너의 일상이 옆에 있을 때 그 모양이 평소보다 한 톤 또렷이 떠올라요.',
    r'$shortName 한 음정의 색 — $blurbTail 너의 결과 만나면 그 색이 둘만의 단조처럼 자리잡아요.',
    r'$shortName 첫 뉘앙스 — $blurbTail 너의 일주가 만나면 그 뉘앙스가 두 사람만의 신호로 굳어요.',
    r'$shortName 결과 의도 — $blurbTail 너의 일상이 받쳐주면 그 의도가 둘만의 약속으로 자리 잡아요.',
    r'$shortName 첫 안쪽 — $blurbTail 너의 결이 옆에 있을 때 그 안쪽이 한 박자 더 정직하게 풀려요.',
    r'$shortName의 한 줄짜리 — $blurbTail 너의 일주가 가까울 때 그 한 줄이 둘의 표지처럼 자리잡아요.',
    r'$shortName 한 톤의 진폭 — $blurbTail 너의 결이 만나면 그 진폭이 두 사람의 일상 위에서 평탄해져요.',
    r'$shortName의 마디 — $blurbTail 너의 일주가 옆에 있을 때 그 마디가 둘만의 박자기처럼 작동해요.',
  ];

  static const _closerPoolEn = [
    r"$shortName — $blurbTail When this pattern layers into your daily rhythm, a beat of your own tends to form.",
    r"$shortName, in one line — $blurbTail Where this rhythm meets your day pillar tends to be where a shared color shows up.",
    r"$shortName — $blurbTail When this mood mixes into your pace, ordinary days tend to feel a little different.",
    r"$shortName's color — $blurbTail How your day pillar receives it tends to shape what kind of bond the two of you build.",
    r"$shortName — $blurbTail Add this single piece to your daily flow and a tone of your own tends to start forming.",
    r"$shortName at a glance — $blurbTail A spark like this tends to make people want the next conversation.",
    r"$shortName in one word — $blurbTail When that word meets your day pillar, a shared season tends to open.",
    r"$shortName, a note — $blurbTail Beside your day pillar, this tone tends to read one shade richer.",
    r"$shortName, the person — $blurbTail With your time alongside, this color tends to read deeper.",
    r"$shortName, a memo — $blurbTail Close to your day pillar, this tone tends to read at its most natural.",
    r"$shortName's atmosphere — $blurbTail Together, this side tends to read at its clearest.",
    r"$shortName, a one-line summary — $blurbTail This note tends to spread into a private tone of your own.",
    r"$shortName, a tidy version — $blurbTail How your everyday receives this note tends to set the depth between you.",
    r"$shortName's color — $blurbTail Meeting your day pillar, this color tends to come back framed.",
    r"$shortName's nature — $blurbTail When your seat is next to theirs, the after-tone of it tends to linger.",
    r"$shortName's first impression — $blurbTail Where that impression meets your day pillar tends to be the starting point.",
    r"$shortName's pace — $blurbTail Your day pillar tends to follow this pace without strain.",
    r"$shortName, a single facet — $blurbTail Inside your daily life, that facet tends to face forward.",
    r"$shortName's one breath — $blurbTail There tends to come a point where your breath overlaps with theirs.",
    r"$shortName in one cut — $blurbTail Beside your day pillar, that cut tends to unspool like the opening of a film.",
    r"$shortName's tone — $blurbTail The way your day pillar receives it tends to turn the tone into a sound of your own.",
    r"$shortName, briefly — $blurbTail Once it enters your everyday, this note tends to find its tidiest position.",
    r"$shortName's flow — $blurbTail As your time runs alongside, the depth of this flow tends to build.",
    r"$shortName's essence — $blurbTail Your day pillar tends to read that essence more accurately than most.",
    r"$shortName, one more frame — $blurbTail Beside your day pillar, the frame tends to gain one more layer of detail.",
    r"$shortName's style — $blurbTail The way your day pillar drapes this style tends to set the room tone between you.",
    r"$shortName's quieter side — $blurbTail In a corner of your everyday, this quiet tends to steady the breath of the bond.",
    r"$shortName's true face — $blurbTail Close to your day pillar, that true face tends to unfold naturally.",
    r"$shortName's core — $blurbTail The core tends to settle into your day pillar without friction.",
    r"$shortName, one line — $blurbTail With your day pillar behind it, this line tends to read like a slogan of your own.",
    r"$shortName's deepest tone — $blurbTail With your time at their side, that tone tends to linger.",
    r"$shortName's seat — $blurbTail Inside your everyday, this seat tends to fill one open square.",
    r"$shortName, an edge — $blurbTail Meeting your day pillar, that edge tends to come back gently smoothed.",
    r"$shortName's everyday — $blurbTail Close to your day pillar, the everyday tends to read one shade more composed.",
    r"$shortName's concept — $blurbTail Your day tone tends to sharpen this concept by one click.",
    r"$shortName, one face — $blurbTail Beside your day pillar, that face tends to land squarely in front of the lens.",
    r"$shortName's mood — $blurbTail Your day pillar tends to translate this mood into an everyday tone.",
    r"$shortName's essence, briefly — $blurbTail As your time flows beside it, the essence tends to emerge faster than average.",
    r"$shortName, in short — $blurbTail Meeting your day pillar, the brevity tends to last as a long impression.",
    r"$shortName's outcome — $blurbTail Inside your everyday, that outcome tends to close one shade softer.",
    r"$shortName as a signal — $blurbTail Your day pillar tends to stand exactly where a signal needs receiving.",
    r"$shortName's main text — $blurbTail Where your day pillar enters tends to be the boldest line in that text.",
    r"$shortName, a single line — $blurbTail Beside your day pillar, that line tends to read like a shared signature.",
    r"$shortName, the name — $blurbTail Once this name appears in your everyday, the room tone tends to shift.",
    r"$shortName's average — $blurbTail Next to your day pillar, that average tends to read one rank higher.",
    r"$shortName's detail work — $blurbTail Received by your day pillar, the detail tends to survive longer than average.",
    r"$shortName's nucleus — $blurbTail Close to your day pillar, the nucleus tends to surface faster than usual.",
    r"$shortName, one note — $blurbTail When that note enters your everyday, the whole room tone tends to bend slightly.",
    r"$shortName, a tonal tidy — $blurbTail Beside your day pillar, that tidy tends to hold one more beat of stability.",
    r"$shortName's interior — $blurbTail Close to your day pillar, the interior tends to show at the right angle.",
    r"$shortName as a mood — $blurbTail Inside your everyday, that mood tends to unspool more honestly.",
    r"$shortName, one note — $blurbTail Carried by your day pillar, the note tends to stay alive in every corner of the day.",
    r"$shortName, summed up — $blurbTail Meeting your day pillar, that summary tends to read like a page of your own.",
    r"$shortName, one pitch — $blurbTail Your day pillar tends to add a harmony on top of that pitch.",
    r"$shortName's groundwork — $blurbTail Your everyday tone tends to carry that groundwork into every corner of the day.",
    r"$shortName, one beat — $blurbTail When your day pillar follows that beat, a rhythm of the pair tends to start.",
    r"$shortName's own color — $blurbTail Meeting your day pillar, the color tends to read one rank sharper.",
    r"$shortName's selfness — $blurbTail Inside your everyday, that selfness tends to loosen into its easiest form.",
    r"$shortName, one paragraph — $blurbTail Meeting your day pillar, the paragraph tends to settle into your daily life.",
    r"$shortName, one character — $blurbTail Beside your day pillar, that single character tends to read like the keyword of the pair.",
    r"$shortName, one note answered — $blurbTail How your day pillar meets it tends to be the unit of depth between you.",
    r"$shortName's palette — $blurbTail Beside your day pillar, that palette tends to settle into a daily tone.",
    r"$shortName, one track — $blurbTail Meeting your day pillar, that track tends to read like a shared regular play.",
    r"$shortName as a signal sent — $blurbTail Your day pillar tends to function like the antenna that receives it.",
    r"$shortName's home tone — $blurbTail Alongside your everyday, that home tone tends to read one shade richer.",
    // R100 sprint 2-bis — pool 65 → 96 with semantically distinct frames (+31).
    r"$shortName's one remark — $blurbTail Your day pillar tends to sit exactly where that remark needs receiving.",
    r"$shortName's base beat — $blurbTail Near your day pillar, that beat tends to fit into your daily rhythm.",
    r"$shortName, one more side — $blurbTail Meeting your day pillar, that side tends to resurface a touch clearer.",
    r"$shortName, a hand's width — $blurbTail Backed by your day pillar, that width tends to read like your shared space.",
    r"$shortName as a tone — $blurbTail Alongside your everyday, that tone tends to read two shades deeper than usual.",
    r"$shortName's core — $blurbTail Near your day pillar, the core tends to surface faster than expected.",
    r"$shortName, one trait's definition — $blurbTail Meeting your day pillar, that definition tends to crystallize into a shared word.",
    r"$shortName's first letter — $blurbTail Next to your day pillar, that letter tends to sound like a start signal of the pair.",
    r"$shortName, one note's depth — $blurbTail When your day pillar supports it, the depth tends to last longer than usual.",
    r"$shortName, one row — $blurbTail Meeting your day pillar, that row tends to read like a page in a shared book.",
    r"$shortName's own color — $blurbTail Your daily tone tends to receive this color without effort, letting it settle.",
    r"$shortName's interior tone — $blurbTail Close to your day pillar, the interior tends to glow without extra lighting.",
    r"$shortName's one-line surface — $blurbTail Meeting your day pillar, one more layer tends to become visible beneath the surface.",
    r"$shortName's afterglow — $blurbTail Inside your everyday, that afterglow tends to stretch the tone by one beat.",
    r"$shortName, one note — $blurbTail Meeting your day pillar, this note tends to read like a shared standard tone.",
    r"$shortName's opening line — $blurbTail Next to your day pillar, that opening line tends to play like a duo's intro.",
    r"$shortName, one strand — $blurbTail Beside your day pillar, that strand tends to weave into your daily tone.",
    r"$shortName's distance — $blurbTail Inside your everyday, that distance tends to settle like a safety line for the pair.",
    r"$shortName's one season — $blurbTail Meeting your day pillar, the season tends to get logged as shared time.",
    r"$shortName's first page — $blurbTail When your day pillar is near, the first page tends to extend into a shared book.",
    r"$shortName's surface tone — $blurbTail Close to your day pillar, the surface tone tends to read one shade richer than usual.",
    r"$shortName's everyday note — $blurbTail Alongside your everyday, that note tends to read like the basic unit between you.",
    r"$shortName, one beat — $blurbTail Meeting your day pillar, that beat tends to act like a metronome of your own.",
    r"$shortName's true color — $blurbTail Next to your day pillar, the true color tends to come through a step deeper than average.",
    r"$shortName, one more sentence — $blurbTail When your day pillar backs it, the sentence tends to read like a shared shorthand.",
    r"$shortName's own tempo — $blurbTail Inside your everyday, that tempo tends to find its natural settling tone.",
    r"$shortName, one facet — $blurbTail Near your day pillar, the facet tends to show one shade more accurately than usual.",
    r"$shortName as a shape — $blurbTail Alongside your everyday, that shape tends to read a tone clearer than expected.",
    r"$shortName, one pitch of color — $blurbTail Meeting your day pillar, the color tends to settle into a shared minor key.",
    r"$shortName's first nuance — $blurbTail Meeting your day pillar, the nuance tends to firm into a signal of your own.",
    r"$shortName's result-and-intent — $blurbTail When your daily life supports it, the intent tends to settle into a shared promise.",
    r"$shortName's first interior — $blurbTail Close to your day pillar, the interior tends to unspool one beat more honestly.",
    r"$shortName's one-liner — $blurbTail Near your day pillar, that one-liner tends to read like a shared cover line.",
    r"$shortName's amplitude — $blurbTail Meeting your day pillar, the amplitude tends to smooth out over your shared daily life.",
    r"$shortName's segments — $blurbTail Beside your day pillar, those segments tend to tick like a shared metronome.",
  ];

  // R100 sprint 2 — salted independent FNV-1a per slot. 기존 `seed % pool.length`
  // 단일 seed 가 lead/relation/closer/daily/score 4 slot 모두에 똑같이 영향을 줘서
  // collision rate 가 편향되었음. 각 slot 별 salt 를 prefix 로 다시 hash 하면 pool
  // 인덱스가 거의 독립적으로 분포된다.
  static int saltedPick(String salt, String key, int poolLen) {
    if (poolLen <= 0) return 0;
    // R100 sprint 4 — FNV-1a + 2-pass xorshift32 + multiplicative mix.
    // pure FNV-1a + 단일 xorshift 의 small-mod bias (예: NONE pool 32 slot 에
    // 95 셀럽 분포 시 top-1 = 10) 추가 해소.
    int h = 0x811c9dc5;
    final src = '$salt|$key';
    for (var i = 0; i < src.length; i++) {
      h ^= src.codeUnitAt(i);
      h = (h * 0x01000193) & 0xffffffff;
    }
    // Pass 1: xorshift32.
    h ^= (h << 13) & 0xffffffff;
    h ^= (h >> 17);
    h ^= (h << 5) & 0xffffffff;
    // Pass 2: SplitMix64-inspired multiplicative mix (32-bit truncated).
    h = (h ^ (h >> 16)) & 0xffffffff;
    h = (h * 0x85ebca6b) & 0xffffffff;
    h = (h ^ (h >> 13)) & 0xffffffff;
    h = (h * 0xc2b2ae35) & 0xffffffff;
    h = (h ^ (h >> 16)) & 0xffffffff;
    return (h & 0x7fffffff) % poolLen;
  }

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
    // R100 sprint 2 — 'rel' salt 로 seed 를 다시 hash 하여 relation pool 안에서의
    // index 분포를 closer/daily/score 와 독립적으로 만든다. seed 는 이미 셀럽 unique
    // (star.id / starDayPillar / starBirth / myGan myJi / stGan stJi / relation idx /
    // strong/weak count). salt 가 다르면 같은 셀럽 두 사람도 다른 슬롯을 받음.
    final idx = saltedPick('rel${useKo ? 'K' : 'E'}_${relation.index}', '$seed', pool.length);
    var line = pool[idx];
    line = _injectShortName(line, shortName);
    // 강·약 anchor 갯수에 따른 1 절 micro-tail (같은 pool index 라도 anchor 조합이
    // 다르면 마지막 한 절이 달라져 본문이 더 갈라진다).
    final myElName =
        (useKo ? _elKo[myEl] : _elEn[myEl]) ?? (useKo ? '오행' : 'element');
    final stElName =
        (useKo ? _elKo[stEl] : _elEn[stEl]) ?? (useKo ? '오행' : 'element');
    // R100 sprint 2-bis — tail 4 → 16 variant per case. 동일 element-pair 셀럽이
    // 16 슬롯으로 흩어져 8어절 이상 반복 clause top-1 을 ≤ 5 로 낮춤. 추가 variant 는
    // 의미적으로 구분되는 문장 frame 위주 (synonym swap X). EN 도 동일.
    // KO 의 `$myElName과` 형식은 myEl 종성 유무에 따라 `과`/`와` 가 갈리므로
    // 한국어 helper 로 보정한 `$myElWithParticle` 를 사용한다 (예: 나무·쇠 = 와, 불·
    // 흙·물 = 과). 영어 측은 placeholder 가 필요 없다.
    final myElWith = useKo ? '$myElName${withWith(myElName)}' : myElName;
    String tail;
    final tailSalt = 'relTail${useKo ? "K" : "E"}_${strongCount}_$weakCount';
    if (useKo) {
      List<String> pool;
      if (strongCount >= 2) {
        pool = [
          ' 강하게 끌어주는 자리가 $strongCount개 겹쳐 $myElName↔$stElName 사이의 끌림이 평균보다 또렷해요.',
          ' $myElName↔$stElName 사이에 강한 anchor 가 $strongCount개 자리잡혀 있어 평균 이상의 끌림이 흐르는 자리예요.',
          ' 진한 anchor $strongCount개가 같이 받쳐주고 있어 $myElName↔$stElName 사이의 자석 끌림이 또렷해요.',
          ' $strongCount개의 진한 anchor 가 $myElName↔$stElName 자리에 정렬돼 있어 끌림이 평균 두 배 정돈돼 보여요.',
          ' $myElWith $stElName 사이를 $strongCount개의 큰 anchor 가 묶어 평소보다 끌림 신호가 진하게 흘러요.',
          ' anchor $strongCount개가 같은 방향으로 정렬돼 $myElName↔$stElName 자리의 자기장이 평균보다 짙어요.',
          ' $strongCount줄의 끌어주는 anchor 가 $myElName↔$stElName 결을 가로질러 들어가 끌림 신호가 또박또박 들려요.',
          ' $myElName↔$stElName 자리 위로 $strongCount개의 진한 신호가 겹쳐 끌림이 한 단계 위로 정돈돼 있어요.',
          ' 큰 anchor 가 $strongCount개나 동시에 있어 $myElName↔$stElName 흐름이 끌림 쪽으로 길게 기울어져요.',
          ' $strongCount개의 anchor 가 자리 잡힌 $myElName↔$stElName 결은 평소 톤보다 한 톤 진하게 다가와요.',
          ' $myElName↔$stElName 흐름이 $strongCount개의 강한 anchor 위에 놓여 있어 끌림이 또박또박 정렬돼요.',
          ' $myElWith $stElName 사이에 anchor 가 $strongCount줄 깔려, 자석처럼 가까워지는 시간이 잦은 자리예요.',
          ' anchor $strongCount줄이 $myElName↔$stElName 결의 양 끝을 잡아당겨 평균 두 배 또렷한 자기장이 흘러요.',
          ' $strongCount개의 anchor 가 같이 굳어 $myElName↔$stElName 사이의 끌림이 평소보다 길게 이어져요.',
          ' $myElName↔$stElName 결 위로 $strongCount줄의 강한 신호가 겹친 자리라 끌림이 한 박자 빠르게 도착해요.',
          ' $strongCount개의 anchor 가 한 묶음으로 $myElName↔$stElName 자리를 정돈해 끌림 신호가 또렷이 떠 있어요.',
        ];
      } else if (weakCount >= 1) {
        pool = [
          ' 조심해야 할 자리가 $weakCount개 걸려 있어 같은 흐름 안에서도 부딪힘 자리가 살짝 보여요.',
          ' $weakCount개의 마찰 anchor 가 자리에 있어 평소 좋은 톤 사이에서도 갈리는 지점이 살짝 보여요.',
          ' 작은 자극 anchor 가 $weakCount개 걸려 있어 같은 흐름 안에서도 한 박자 조심할 자리가 보여요.',
          ' $myElName↔$stElName 흐름 위에 마찰 anchor $weakCount개가 자리잡혀 잔잔한 사이에도 작은 갈림이 보여요.',
          ' $weakCount개의 자극 anchor 가 $myElName↔$stElName 결 사이에 끼어 한 박자 더 신중함이 필요한 자리예요.',
          ' anchor $weakCount줄이 $myElName↔$stElName 흐름의 한쪽을 살짝 흔들어 잔잔한 톤 안에서도 작은 균열이 드러나요.',
          ' $myElWith $stElName 사이에 $weakCount줄의 마찰 신호가 끼어 좋은 분위기 사이에도 한 박자 끊김이 와요.',
          ' $weakCount개의 마찰 anchor 가 $myElName↔$stElName 결 위에 자리 잡아 평소 톤이 한 박자 더 흔들려요.',
          ' anchor $weakCount줄이 $myElName↔$stElName 사이를 살짝 비틀어 잔잔한 자리에서도 작은 갈림이 드러나요.',
          ' $weakCount개의 자극 anchor 가 $myElName↔$stElName 결 위에 깔려 좋은 흐름 안쪽에도 작은 매듭이 보여요.',
          ' $myElName↔$stElName 자리 위로 $weakCount줄의 마찰 신호가 흘러 부드러운 톤 사이에서도 한 박자 조심이 필요해요.',
          ' $weakCount개의 작은 anchor 가 $myElWith $stElName 사이를 흔들어 같은 결 안에도 작은 단층이 생겨요.',
          ' anchor $weakCount줄이 $myElName↔$stElName 흐름의 한 부분을 끊어 두 사람 사이에 한 박자 더 정리가 필요해요.',
          ' $weakCount개의 마찰 신호가 $myElName↔$stElName 결 위에 자리 잡혀 좋은 톤 끝자락에 작은 갈림이 보여요.',
          ' $myElName↔$stElName 결 사이로 $weakCount줄의 자극 anchor 가 새어들어 평소 안정 톤도 한 박자 흔들려요.',
          ' $weakCount개의 마찰 anchor 가 $myElName↔$stElName 자리 한쪽을 누르고 있어 한 박자 더 의식적인 조율이 필요해요.',
        ];
      } else if (strongCount == 1) {
        pool = [
          ' 끌어주는 자리 한 줄이 받쳐주고 있어 $myElName↔$stElName 흐름이 자연스럽게 잡혀요.',
          ' 안정 anchor 한 줄이 자리잡혀 $myElName↔$stElName 흐름이 부드럽게 정돈돼요.',
          ' 한 줄의 든든한 anchor 가 받쳐주고 있어 $myElName↔$stElName 사이가 잔잔하게 정렬돼요.',
          ' $myElName↔$stElName 자리에 진한 anchor 한 줄이 깔려 있어 흐름이 평균 이상으로 정돈돼요.',
          ' anchor 한 줄이 $myElName↔$stElName 결 위에 가만히 깔려 있어 한쪽으로 기울지 않고 흐름이 또박또박 잡혀요.',
          ' $myElWith $stElName 사이에 한 줄의 안정 신호가 흘러 잔잔한 일상 톤이 길게 유지돼요.',
          ' 한 줄의 안정 anchor 가 $myElName↔$stElName 결 양 끝을 가볍게 잡아 흐름이 차분하게 가라앉아요.',
          ' $myElName↔$stElName 사이로 한 줄의 끌어주는 신호가 지나가 평소 톤보다 한 단계 안정된 자리예요.',
          ' anchor 한 줄이 $myElName↔$stElName 흐름을 부드럽게 묶어 두 사람 사이의 페이스가 한 박자 정돈돼요.',
          ' $myElName↔$stElName 결 위로 든든한 한 줄이 깔려 있어 흐름이 비대칭 없이 또박또박 흘러요.',
          ' 한 줄의 진한 anchor 가 $myElName↔$stElName 자리에 자리 잡아 평소보다 한 톤 안정된 결이 흘러요.',
          ' anchor 한 줄이 $myElName↔$stElName 사이의 거리감을 자연스럽게 좁혀 한 박자 가까운 톤이 자주 잡혀요.',
          ' $myElWith $stElName 사이에 진한 한 줄의 신호가 흘러 흐름이 부드러운 톤으로 길게 이어져요.',
          ' anchor 한 줄이 $myElName↔$stElName 결 한가운데에 자리 잡아 양쪽 톤이 자연스럽게 맞아 들어가요.',
          ' $myElName↔$stElName 자리 위에 차분한 anchor 한 줄이 정렬돼 평균보다 안정된 결이 흘러요.',
          ' 한 줄의 안정 신호가 $myElName↔$stElName 흐름을 받쳐 두 사람 사이의 톤이 잔잔하게 떠 있어요.',
          ' 한 줄의 anchor 가 $myElName↔$stElName 결을 비대칭 없이 받쳐주는 자리, 그래서 톤이 일정한 박자로 유지돼요.',
          ' $myElName↔$stElName 흐름 한가운데에 단정한 anchor 가 한 줄 박혀 있어 톤이 길게 흘러가요.',
          ' 안정 anchor 한 줄이 $myElName↔$stElName 결 위를 가로질러 평균 톤보다 한 박자 잔잔히 떠 있어요.',
          ' $myElWith $stElName 사이에 단단한 한 줄이 깔려 있어 톤이 한쪽으로 무너지지 않고 떠 있어요.',
          ' 한 줄의 받쳐 줌이 $myElName↔$stElName 결 위에 자리 잡아 둘 사이 페이스가 한 박자 평탄해져요.',
          ' anchor 한 줄이 $myElName↔$stElName 결 사이의 균형을 조용히 잡고 있어 결이 흔들리지 않고 흘러요.',
          ' $myElName↔$stElName 흐름 위로 침착한 anchor 한 줄이 흘러 일상 톤이 평균 위에서 안착해 있어요.',
          ' 한 줄의 진한 신호가 $myElName↔$stElName 결 한쪽 끝에서 다른 끝까지 일정한 톤으로 흘러요.',
          ' anchor 한 줄이 $myElName↔$stElName 자리 위에 차분히 깔려 톤이 평소보다 한 단계 정리돼 보여요.',
          ' $myElName↔$stElName 결 위로 안정 anchor 한 줄이 자리 잡아 둘만의 페이스가 부드럽게 떠 있어요.',
          ' 한 줄의 받쳐 줌이 $myElName↔$stElName 사이를 안정적인 박자로 묶어 톤이 길게 살아 있어요.',
          ' $myElWith $stElName 사이를 가만히 묶어 주는 anchor 한 줄이 있어 흐름이 평소 톤 위에 정착해요.',
          ' anchor 한 줄이 $myElName↔$stElName 결의 호흡을 맞춰 두 사람 사이 페이스가 일정한 박자로 흘러요.',
          ' 한 줄의 안정 신호가 $myElName↔$stElName 흐름의 가운데 자리를 차지해 톤이 비대칭 없이 흘러요.',
          ' $myElName↔$stElName 사이의 거리가 한 줄의 차분한 anchor 로 좁혀져 톤이 평균 위로 한 박자 떠 있어요.',
          ' 안정 anchor 한 줄이 $myElName↔$stElName 결 위에 정렬돼 한 박자 위 톤으로 결이 유지돼요.',
        ];
      } else {
        pool = [
          ' 직접 걸린 큰 자극 없이 $myElName↔$stElName 자체의 거리감이 그대로 드러나요.',
          ' 진한 anchor 없이 $myElName↔$stElName 자체의 거리감이 본 모습대로 드러나요.',
          ' 큰 anchor 가 깔려 있지 않아서 $myElName↔$stElName 사이의 본래 거리가 그대로 보여요.',
          ' 자극 anchor 없는 자리라 $myElName↔$stElName 자체의 결이 정직하게 드러나요.',
          ' anchor 한 줄도 깔리지 않아 $myElName↔$stElName 사이의 본 모습이 화장 없이 드러나요.',
          ' $myElWith $stElName 사이를 묶는 신호가 없어 둘의 본래 페이스가 그대로 흐르는 자리예요.',
          ' 큰 신호 없이 $myElName↔$stElName 결의 거리감이 표면 그대로 보여요.',
          ' anchor 가 잡히지 않은 자리라 $myElName↔$stElName 흐름이 자기 모양으로 흘러가요.',
          ' $myElName↔$stElName 사이에 강한 신호가 없어 둘의 결이 한쪽으로 기울지 않은 채 보여요.',
          ' 자극도 안정도 없는 자리라 $myElName↔$stElName 본래 거리가 그대로 측정돼요.',
          ' 진한 신호가 비어 있어 $myElName↔$stElName 결의 본 색이 한 톤도 안 가려지고 드러나요.',
          ' anchor 없이 $myElName↔$stElName 사이의 거리감이 둘의 노력 정도에 따라서만 바뀌는 자리예요.',
          ' $myElWith $stElName 결의 본 모습이 anchor 보정 없이 그대로 마주 보고 있어요.',
          ' 큰 신호가 비어 있어 $myElName↔$stElName 사이의 톤이 둘의 의식적 선택으로만 정해져요.',
          ' $myElName↔$stElName 자리에 받쳐 줄 anchor 가 없어 흐름이 자연 그대로의 거리로 흘러요.',
          ' anchor 부재한 결이라 $myElName↔$stElName 사이의 톤이 화장 없는 본 모습으로 비쳐요.',
          ' 어떤 anchor 도 잡히지 않은 결이라 $myElName↔$stElName 사이의 거리감이 손대지 않은 채 흘러요.',
          ' 진한 신호 한 줄도 없어 $myElName↔$stElName 사이의 본래 박자가 양쪽에서 그대로 부딪쳐요.',
          ' $myElName↔$stElName 결 위에 자극 anchor 가 없어 두 사람 사이 톤이 보정 없는 그대로 보여요.',
          ' anchor 보정이 빠진 자리라 $myElName↔$stElName 본래 결의 두께가 그대로 노출돼요.',
          ' $myElWith $stElName 사이에 신호가 비어 있어 톤은 둘이 의식적으로 만드는 만큼만 떠 있어요.',
          ' 큰 anchor 자리가 비어서 $myElName↔$stElName 결의 본 거리가 한 톤도 줄지 않은 채 드러나요.',
          ' 자극 신호가 없는 결이라 $myElName↔$stElName 사이의 톤은 그날의 노력 변동에 따라 움직여요.',
          ' anchor 가 부재한 결이라 $myElName↔$stElName 사이의 거리가 만남 빈도 그대로 거울처럼 비쳐요.',
          ' $myElName↔$stElName 결 위에 받쳐 줄 신호가 없어 톤은 두 사람이 만든 약속만큼만 떠 있어요.',
          ' 어떤 anchor 도 흐르지 않아 $myElName↔$stElName 사이의 본 결이 매번 새로 측정되는 자리예요.',
          ' anchor 빈 자리라 $myElName↔$stElName 결의 거리감이 둘의 의도된 노력에만 반응해요.',
          ' $myElWith $stElName 결의 본 모습이 신호 보정 없이 매번 그대로 다시 그려져요.',
          ' 큰 anchor 신호가 없는 결이라 $myElName↔$stElName 사이의 톤이 둘의 매일 행동에만 응답해요.',
          ' anchor 없는 자리라 $myElName↔$stElName 결의 본 거리가 두 사람의 선택에 따라서만 좁혀져요.',
          ' $myElName↔$stElName 사이에 신호 anchor 가 비어 있어 톤은 둘이 의식한 만큼만 가까워져요.',
          ' anchor 가 깔리지 않은 자리라 $myElName↔$stElName 본래 박자가 두 사람 사이에 그대로 흘러요.',
          ' 받쳐 줄 신호가 비어 있어 $myElName↔$stElName 사이의 톤이 두 사람의 약속만큼만 잔잔히 떠 있어요.',
          ' anchor 없는 결이라 $myElName↔$stElName 사이의 거리가 두 사람의 연락 횟수 그대로 보여요.',
          ' $myElName↔$stElName 결 위에 신호 자리가 비어 있어 톤이 매번 두 사람이 새로 합의해야 떠올라요.',
          ' 큰 anchor 없는 결이라 $myElName↔$stElName 사이의 본 박자가 매일 새로 측정돼요.',
          ' anchor 비어 있는 자리라 $myElName↔$stElName 결의 본 깊이가 매번 약속 빈도에 비례해 보여요.',
          ' $myElWith $stElName 사이에 받쳐 줄 신호가 없어, 톤은 두 사람이 의도적으로 합의한 만큼만 잔잔하게 떠 있어요.',
          ' 신호 없는 결이라 $myElName↔$stElName 본래 거리가 두 사람의 매일 결정으로만 좁혀져요.',
          ' anchor 가 없는 자리라 $myElName↔$stElName 결의 본 모양이 두 사람의 약속 빈도에 정직하게 비례해요.',
          ' $myElName↔$stElName 사이에 신호 anchor 가 비어 있어 톤은 두 사람의 의도된 시간만큼만 살아 있어요.',
          ' 받쳐 줄 anchor 가 비어 있어 $myElName↔$stElName 본래 결이 두 사람의 의도된 행동으로만 변형돼요.',
          ' $myElWith $stElName 결 위에 받쳐 줄 신호가 빠져 있어 톤이 두 사람의 약속만큼만 떠 있어요.',
          ' anchor 없는 결이라 $myElName↔$stElName 결의 본 박자가 두 사람의 일정 그대로 흐르는 자리예요.',
          ' $myElName↔$stElName 자리에 자극 anchor 가 빠져 있어 톤은 두 사람의 의도된 합의로만 모양이 잡혀요.',
          ' 큰 anchor 자리가 빈 결이라 $myElName↔$stElName 결의 본 거리가 두 사람의 약속 횟수 그대로 비쳐요.',
          ' anchor 가 비어 있는 자리라 $myElName↔$stElName 사이의 본 결이 매번 두 사람의 새 의도로만 다시 떠올라요.',
        ];
      }
      final tIdx = saltedPick(tailSalt, '$seed', pool.length);
      tail = pool[tIdx];
    } else {
      List<String> pool;
      if (strongCount >= 2) {
        pool = [
          ' $strongCount strong anchors stack here, so the $myElName↔$stElName pull reads sharper than average.',
          ' With $strongCount strong anchors in the seat, the $myElName↔$stElName attraction lands above average clarity.',
          ' $strongCount anchors of pull line up, sharpening the $myElName↔$stElName magnetism by a clear margin.',
          ' The $myElName↔$stElName flow runs through $strongCount strong anchors, so the pull reads tidier than usual.',
          ' $strongCount dense anchors bind the $myElName↔$stElName seat, drawing the two of you in by a sharper margin.',
          ' Across the $myElName↔$stElName line, $strongCount strong signals layer together so the pull reads two shades clearer.',
          ' $strongCount anchors lock the $myElName↔$stElName line in place, letting the attraction settle above the room average.',
          ' On top of the $myElName↔$stElName flow rest $strongCount big anchors, so the pull lands with extra weight.',
          ' $strongCount strong anchors gather over the $myElName↔$stElName seat, sharpening the magnetism beyond the usual tone.',
          ' The $myElName and $stElName elements are pulled toward each other by $strongCount anchors, so closeness arrives fast.',
          ' With $strongCount anchors lined up, the $myElName↔$stElName attraction reads a full step above average clarity.',
          ' $strongCount aligned anchors run through the $myElName↔$stElName seat, so the pull builds in a steady, visible curve.',
          ' $strongCount big signals reinforce the $myElName↔$stElName pairing, holding the attraction in a tight, readable line.',
          ' The $myElName↔$stElName seat carries $strongCount strong anchors at once, so closeness arrives without much effort.',
          ' Stacked in $strongCount rows, the anchors on the $myElName↔$stElName seat read like a magnetic pull above the median.',
          ' $strongCount anchors layered into the $myElName↔$stElName flow push the pull a clear notch above neutral attraction.',
        ];
      } else if (weakCount >= 1) {
        pool = [
          ' $weakCount weak anchor sits in the mix, so even inside one rhythm there are visible friction points.',
          ' $weakCount friction anchor stays in the seat, so a soft tone still shows a couple of split points.',
          ' A small stimulus anchor ($weakCount) is present, so even between calm beats one notch of caution surfaces.',
          ' On top of the $myElName↔$stElName flow, $weakCount friction anchor surfaces a small split inside a calm seat.',
          ' $weakCount friction anchor lodges between the $myElName and $stElName elements, asking for one extra beat of care.',
          ' Across the $myElName↔$stElName seat, $weakCount stimulus signal slips in and tilts the rhythm off-axis by a hair.',
          ' $weakCount weak anchor leans on the $myElName↔$stElName line, so the calm tone still cracks for a beat now and then.',
          ' A friction signal ($weakCount) cuts across the $myElName↔$stElName line, surfacing a small split mid-flow.',
          ' $weakCount stimulus anchor settles into the $myElName↔$stElName seat, asking for a touch more conscious alignment.',
          ' On the $myElName↔$stElName flow, $weakCount weak anchor sits low and the rhythm picks up a quiet hitch.',
          ' $weakCount friction signal lands across the $myElName and $stElName elements, leaving a fine line in an otherwise soft seat.',
          ' A small anchor of caution ($weakCount) holds part of the $myElName↔$stElName flow, so one beat of restraint is wise.',
          ' $weakCount weak anchor presses one side of the $myElName↔$stElName seat, so one shade of patience reads tidier.',
          ' Through the $myElName↔$stElName line runs $weakCount friction signal, so a soft tone shows a thin fracture if you look close.',
          ' $weakCount stimulus anchor is layered into the $myElName↔$stElName pairing, so the rhythm needs one beat of deliberate handling.',
          ' A subtle friction signal ($weakCount) crosses the $myElName↔$stElName seat, so a calm pace still snags once in a while.',
        ];
      } else if (strongCount == 1) {
        pool = [
          ' One anchor underwrites it, keeping the $myElName↔$stElName flow naturally settled.',
          ' A single steady anchor sits in the seat, tidying the $myElName↔$stElName flow into a calm tone.',
          ' One firm anchor underneath holds the $myElName↔$stElName flow in a quietly aligned rhythm.',
          ' A dense single anchor lies through the $myElName↔$stElName seat, so the flow settles above average tidy.',
          ' A lone steady anchor crosses the $myElName↔$stElName line, holding the flow without tilting either way.',
          ' One quiet anchor sits over the $myElName↔$stElName seat, keeping the pace softly aligned through the day.',
          ' Across the $myElName↔$stElName line, one anchor underwrites the rhythm and the tone stays one step above neutral.',
          ' A single firm signal binds the $myElName and $stElName elements, so the everyday rhythm sits a half-step calmer.',
          ' One anchor laid into the $myElName↔$stElName seat tidies the flow into a steady, unstrained tone.',
          ' The $myElName↔$stElName flow rests on one steady anchor, so daily pacing reads tidier than the average pairing.',
          ' One anchor underneath the $myElName↔$stElName seat keeps both elements aligned without either pushing the other.',
          ' A solid single signal threads the $myElName↔$stElName line, holding the flow at a quiet, average-plus setting.',
          ' A lone anchor lies across the $myElName and $stElName elements, so the rhythm reads one shade cleaner than usual.',
          ' One stabilizing anchor sits across the $myElName↔$stElName seat, so the pacing keeps a soft, sustained baseline.',
          ' A single firm anchor underwrites the $myElName↔$stElName line, so closeness builds without strain or rush.',
          ' One anchor of trust crosses the $myElName↔$stElName seat, letting the rhythm settle into a steady, low-friction tone.',
          ' A single quiet thread of an anchor runs through the $myElName↔$stElName seat, so the room reads calm without effort.',
          ' One settled anchor underwrites the $myElName↔$stElName line, keeping the daily tone half a step above the room average.',
          ' A solitary firm anchor crosses the $myElName and $stElName elements, so a steady tone stays in the air across the week.',
          ' One steady signal beneath the $myElName↔$stElName flow keeps both ends aligned without either side pressing the other.',
          ' A lone underwriting anchor on the $myElName↔$stElName seat holds the rhythm at a softly elevated baseline.',
          ' A single grounding anchor rests across the $myElName↔$stElName line, so closeness comes by inches rather than spikes.',
          ' One anchor of patience binds the $myElName↔$stElName seat, so the tone takes the long route into clarity.',
          ' A lone anchor runs underneath the $myElName↔$stElName flow, so the conversation cadence stays tidy without effort.',
          ' One firm note threads through the $myElName↔$stElName pairing, keeping the room temperature one notch above neutral.',
          ' A single supporting anchor on the $myElName↔$stElName seat tilts the tone gently toward favor without overplay.',
          ' One anchor sits low across the $myElName↔$stElName line, so the cadence holds even when the topic shifts.',
          ' A lone steady underwriter on the $myElName and $stElName seat keeps the conversation tone in a clean low gear.',
          ' One quiet anchor underwrites the $myElName↔$stElName flow, so the day-to-day stays mended without dramatic strokes.',
          ' A single settled anchor crosses the $myElName↔$stElName flow, so the bond builds in even, almost invisible layers.',
          ' One trust-shaped anchor sits beneath the $myElName↔$stElName line, so the closeness stays unstrained on slow days.',
          ' A lone calming anchor binds the $myElName↔$stElName seat, so neither side has to overcorrect to keep tempo.',
        ];
      } else {
        pool = [
          ' No direct anchor — the raw distance between $myElName and $stElName shows through.',
          ' No dense anchor here — the natural distance between $myElName and $stElName shows in its bare form.',
          ' With no big anchor laid in, the original distance between $myElName and $stElName comes through as is.',
          ' A no-stimulus seat — the $myElName and $stElName elements show their honest distance.',
          ' Nothing binds the seat, so the bare distance between $myElName and $stElName surfaces without correction.',
          ' Without a single anchor on the line, the $myElName and $stElName elements face each other in their natural form.',
          ' No signal layers in, so the distance between $myElName and $stElName reads exactly as it is.',
          ' An anchor-free seat — the $myElName and $stElName flow keeps to its own original spacing.',
          ' Without anchors, the $myElName↔$stElName flow runs at its uncorrected pace from both ends.',
          ' No reinforcing signal — the $myElName↔$stElName line stands at its honest, native distance.',
          ' Empty of dense anchors, the $myElName↔$stElName seat lets each side show its bare outline back.',
          ' No anchor lies between $myElName and $stElName, so the rhythm depends entirely on how you both choose to lean.',
          ' Across the $myElName↔$stElName line nothing locks in, so the distance reads as your conscious effort decides.',
          ' With the seat blank of anchors, the $myElName↔$stElName flow plays back without dampening or amplification.',
          ' No anchor on the $myElName↔$stElName line — closeness here tends to be a choice rather than something that happens on its own.',
          ' The $myElName↔$stElName seat carries no signal, so what shows up between you is built, not given.',
          ' An empty anchor seat lets the $myElName and $stElName elements stand at the size they were before they met.',
          ' Without one binding signal, the $myElName↔$stElName line reads as its untouched starting distance.',
          ' No layered anchors mean the $myElName↔$stElName flow stays its own native length on both sides.',
          ' A vacant anchor field across the $myElName and $stElName seat lets the bond rely solely on intent.',
          ' Lacking direct anchors, the $myElName↔$stElName flow holds its natural length until effort is added.',
          ' The $myElName↔$stElName line sits unmoored, so the tone changes only when one of you moves it on purpose.',
          ' No anchor reinforces the $myElName↔$stElName seat, so consistency depends on how you both keep showing up.',
          ' An empty signal line between $myElName and $stElName means the bond grows by deliberate action only.',
          ' The $myElName↔$stElName seat has no native pull, so depth here is built layer by layer rather than given.',
          ' Without any binding anchors, the $myElName↔$stElName line measures itself purely by your routines.',
          ' No stabilizing signal underwrites the $myElName↔$stElName pairing, so both sides keep their original size.',
          ' Free of anchors, the $myElName↔$stElName flow follows whatever rhythm you both consciously hand it.',
          ' The $myElName↔$stElName seat sits without any built-in scaffolding, so the bond tends to be whatever you keep making.',
          ' With no anchor laid into the $myElName↔$stElName line, the tone is the exact sum of your weekly meetings.',
          ' Nothing pre-binds the $myElName↔$stElName line here, so the bond reads as a slow, deliberate construction.',
          ' The $myElName↔$stElName seat has zero pre-set pull, so closeness becomes a deliberate practice rather than a given.',
          ' No bridging anchor lies in the $myElName↔$stElName seat, so the bond inherits whatever pace you both keep.',
          ' Across an empty signal field, the $myElName and $stElName elements keep their original outline intact.',
          ' Without dense anchors, the $myElName↔$stElName line plays at the volume you both deliberately set.',
          ' No native pull threads the $myElName↔$stElName flow, so the closeness reads as constructed, not inherited.',
          ' The $myElName↔$stElName seat lacks any built-in reinforcement, so the bond tends to run on practice alone.',
          ' Empty of any signal, the $myElName↔$stElName line shows its raw spacing every time you meet.',
          ' Without binding lines, the $myElName↔$stElName flow reads exactly as wide as your weekly contact keeps it.',
          ' An anchor-empty seat lets the $myElName and $stElName elements keep their native outline through every meeting.',
          ' The $myElName↔$stElName flow rests on no scaffolding here, so depth is the precise sum of your shown-up days.',
          ' Without underpinning anchors, the $myElName↔$stElName line records itself purely from your active choices.',
          ' No structure underwrites the $myElName↔$stElName seat, so the bond stays whatever rhythm you both keep current.',
          ' An empty signal seat across the $myElName↔$stElName line leaves the closeness to your own routine cadence.',
          ' Free of any built-in pull, the $myElName↔$stElName line tends to gather whatever shape your shared time gives it.',
          ' Without anchor reinforcement, the $myElName↔$stElName pairing holds at exactly your conscious bond-building rate.',
          ' The $myElName↔$stElName line carries no inherent pull, so what builds here is exactly what you both invest.',
        ];
      }
      final tIdx = saltedPick(tailSalt, '$seed', pool.length);
      tail = pool[tIdx];
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
    // R100 sprint 2 — independent salted pick. closer pool 안에서의 idx 가
    // relation/daily/score 와 collision 되지 않도록 'closer' salt 사용.
    final idx = saltedPick('closer${useKo ? 'K' : 'E'}', '$seed', pool.length);
    var line = pool[idx];
    line = _injectShortName(line, shortName);
    line = line.replaceAll(r'$blurbTail', blurbTail);
    // R100 sprint 2-bis — 8 element-pair fragment 으로 closer 2 문장 collision 해소.
    // 같은 pool slot 셀럽 ~7명도 fragment 슬롯 8개 × 5 element pair 분포로 흩어져
    // 8어절 이상 동일 clause top-1 이 ≤ 5 로 떨어진다.
    final myElName = (useKo ? _elKo[myEl] : _elEn[myEl]) ??
        (useKo ? '오행' : 'element');
    final stElName = (useKo ? _elKo[stEl] : _elEn[stEl]) ??
        (useKo ? '오행' : 'element');
    final fragSalt = 'closerFrag${useKo ? 'K' : 'E'}';
    final fragPool = useKo
        ? [
            ' ($myElName↔$stElName 결 한 갈피)',
            ' ($myElName↔$stElName 흐름 위에서)',
            ' ($myElName↔$stElName 사이 한 박)',
            ' ($myElName↔$stElName 톤의 한 결)',
            ' ($myElName↔$stElName 자리 안쪽)',
            ' ($myElName↔$stElName 결 모서리)',
            ' ($myElName↔$stElName 한 호흡)',
            ' ($myElName↔$stElName 박자 위)',
          ]
        : [
            ' ($myElName↔$stElName element note)',
            ' (on the $myElName↔$stElName flow)',
            ' (one beat across $myElName↔$stElName)',
            ' (a $myElName↔$stElName tone aside)',
            ' (inside the $myElName↔$stElName seat)',
            ' (at the $myElName↔$stElName edge)',
            ' (one $myElName↔$stElName breath)',
            ' (along the $myElName↔$stElName beat)',
          ];
    final fragIdx = saltedPick(fragSalt, '$seed', fragPool.length);
    // 마지막 마침표 직전에 fragment 를 끼워 한 문장으로 자연스럽게 결합.
    final frag = fragPool[fragIdx];
    if (line.endsWith('.') || line.endsWith('。') || line.endsWith('…')) {
      final last = line.substring(line.length - 1);
      line = '${line.substring(0, line.length - 1)}$frag$last';
    } else {
      line = '$line$frag';
    }
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

/// R100 sprint 4 — regression guard testing hook.
///
/// Wraps `_StarRow._verdict()` so that the regression test
/// (`test/r100_compat_repetition_guard_test.dart`) can exercise the actual
/// Dart composition path (identityLead + relationVariant + dailyBreath +
/// scoreBand + closerVariant) without rendering widgets or running
/// `flutter_test` 의 widget pump.
///
/// 사용처: 테스트 한정. production 코드는 호출하지 않는다.
@visibleForTesting
String composeKpopVerdictForTest({
  required SajuResult me,
  required Map<String, dynamic> starJson,
  required int score,
  required int rank,
  required bool useKo,
}) {
  final star = _Star.fromJson(starJson);
  return _StarRow(
    me: me,
    star: star,
    score: score,
    rank: rank,
    useKo: useKo,
  ).composeVerdictForTest();
}

/// R101 sprint 3 — 셀럽 일주 한자(예: `癸卯`) → 한국어 음(예: `계묘`).
///
/// `compatibility_screen.dart` 의 `Pillar.pairKorean` 헬퍼와 동일한 매핑이지만,
/// `_Star.dayPillar` 가 string field (한자 2자) 라 별도 inline helper 로 둔다.
/// KO 분기 detail header 와 `_starToSajuResult` adapter 모두에서 재사용.
String _pillarKoFromHanja(String dayPillar) {
  if (dayPillar.length < 2) return '';
  const ganKo = {
    '甲': '갑', '乙': '을', '丙': '병', '丁': '정', '戊': '무',
    '己': '기', '庚': '경', '辛': '신', '壬': '임', '癸': '계',
  };
  const jiKo = {
    '子': '자', '丑': '축', '寅': '인', '卯': '묘',
    '辰': '진', '巳': '사', '午': '오', '未': '미',
    '申': '신', '酉': '유', '戌': '술', '亥': '해',
  };
  final g = ganKo[dayPillar[0]] ?? '';
  final j = jiKo[dayPillar[1]] ?? '';
  return '$g$j';
}

/// R101 sprint 3 — 셀럽 한 명의 K-POP 그룹명 영문 prefix 를 한국어 표기로 정규화.
///
/// 사용자 mandate verbatim: "왜 한국어에 영어가 들어와". celebrities.json 의
/// `blurbKo` 가 "LE SSERAFIM 홍은채. 기본 성향은..." 같이 영문 그룹명으로 시작하는
/// 케이스가 62/223 (28%). KO 분기에서 본문을 그대로 보여주면 한국어 사용자에게
/// 영문 그룹명이 leak. 한국 미디어 표준 표기로 매핑.
///
/// 매핑되지 않은 그룹명은 원문 보존 (예: `BTS`, `BLACKPINK` 처럼 한국 미디어에서도
/// 영문 그대로 통용되는 케이스는 의도적으로 매핑하지 않거나 사용자 추가 mandate 시
/// 확장 가능).
@visibleForTesting
String localizeGroupPrefixKoForTest(String input) => _localizeGroupPrefixKo(input);

String _localizeGroupPrefixKo(String input) {
  if (input.isEmpty) return input;
  // longest-first 매핑 — "NCT DREAM" 처럼 공백 포함 prefix 가 "NCT" 보다 먼저
  // 매칭되도록.
  const groupMap = <String, String>{
    'LE SSERAFIM': '르세라핌',
    'NCT DREAM': '엔시티 드림',
    'NCT WISH': '엔시티 위시',
    'NCT 127': '엔시티 127',
    'NewJeans': '뉴진스',
    'BLACKPINK': '블랙핑크',
    'SEVENTEEN': '세븐틴',
    'ENHYPEN': '엔하이픈',
    'BABYMONSTER': '베이비몬스터',
    'ZEROBASEONE': '제로베이스원',
    'BOYNEXTDOOR': '보이넥스트도어',
    'Stray Kids': '스트레이키즈',
    'KISS OF LIFE': '키스오브라이프',
    'MAMAMOO': '마마무',
    'tripleS': '트리플에스',
    'fromis_9': '프로미스나인',
    'BTS': '방탄소년단',
    'TWICE': '트와이스',
    'ATEEZ': '에이티즈',
    'RIIZE': '라이즈',
    'ITZY': '있지',
    'IVE': '아이브',
    'aespa': '에스파',
    'TXT': '투모로우바이투게더',
    'TWS': '투어스',
    'XG': '엑스지',
    'ILLIT': '아일릿',
    'NCT': '엔시티',
    'EXO': '엑소',
    'SHINee': '샤이니',
    'MEOVV': '미야오',
    'VIVIZ': '비비지',
    'STAYC': '스테이씨',
    'fromis': '프로미스나인',
    'fifty fifty': '피프티피프티',
    '2PM': '투피엠',
  };
  // longest-first 정렬.
  final keys = groupMap.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final k in keys) {
    if (input.startsWith('$k ') || input.startsWith('$k.')) {
      return groupMap[k]! + input.substring(k.length);
    }
  }
  return input;
}

/// R101 sprint 3 — 셀럽 표시 이름 단축형 (괄호 제거 + trim).
///
/// celebrities.json 의 `nameKo` 는 `"홍은채 (LE SSERAFIM)"` 같은 괄호 표기가 일부
/// 포함됨. partnerName 으로 inject 할 때 본문 첫머리에 영문 그룹명이 노출되지
/// 않도록 short form 만 사용.
String _starShortName(_Star star, {required bool useKo}) {
  final raw = (useKo ? star.nameKo : star.nameEn).trim();
  if (raw.isEmpty) return raw;
  final cut = raw.contains('(') ? raw.split('(').first.trim() : raw;
  return cut;
}

/// R101 sprint 3 / R107 #2 — `_Star` → `SajuResult` adapter.
///
/// 셀럽 데이터(`celebrities.json`)는 `birth` (YYYY-MM-DD) + `dayPillar` (일주
/// 한자 2자) 를 가진다. 출생 시(時)는 공개되지 않았다.
///
/// R107 #2 거짓말 0 mandate — 이전(R101)에는 year/month pillar 자리를 `dayPillar`
/// 로 임시(가짜) 복사했다. "셀럽 전체 사주 궁합" 이라 보이지만 실제로는 일주만
/// 진짜이고 年柱·月柱가 가짜 = 거짓. 본 adapter 는 이제 `CelebChartValidator`
/// (= `ManseryeokService` 엔진, `unknownTime=true`) 로 셀럽 출생일에서 **실제
/// 年柱·月柱·日柱 3주**를 계산한다.
///
/// - `yearPillar` / `monthPillar` / `dayPillar` — 출생일에서 엔진이 계산한 실제 값.
///   (年/月은 절기 경계로 흔들릴 수 있으나 동일 출생일이면 엔진 결정값이 일관됨.)
/// - `hourPillar` — 항상 `null`. 셀럽 출생 시 미상 (R83 sprint P1-E mandate).
///   時柱는 절대 생성·암시하지 않는다.
/// - `elements` — `compatibility_screen._score`/`._analyze` 의 complementary 분기
///   (`me.elements.deficit == partner.elements.dominant` 또는 그 역) 의 회귀 0 을
///   위해 R101 과 동일하게 **일간(日干) 천간 5행** 가중치만 부여한다. (3주 전체
///   분포로 바꾸면 dominant/deficit 이 달라져 R100/R101 점수가 흔들리므로 의도적
///   보존.) 셀럽 5행은 본문 케미용 보조 신호일 뿐 만세력 정밀 분포가 아니다.
///
/// 일관성: `CelebChartValidator` 가 계산한 日柱는 `celebrities.json` 의
/// `dayPillar` 와 동일해야 한다 (R105 `celeb_chart_validator` 회귀 가드 검증).
/// 엔진 계산이 실패(날짜 파싱 불가 등)하면 가짜로 채우지 않고 기록된 `dayPillar`
/// 만 진짜로 두고 年/月은 일주로 폴백 — 이 경우만 부분 데이터이며, 실데이터
/// 223 entry 는 모두 정상 birth 를 가져 폴백 경로를 타지 않는다.
@visibleForTesting
SajuResult starToSajuResultForTest(Map<String, dynamic> starJson) =>
    _starToSajuResult(_Star.fromJson(starJson));

SajuResult _starToSajuResult(_Star star) {
  // dayPillar 한자 2자 보강 (실제 데이터 entry 223개 모두 2자 보장).
  final dp = star.dayPillar.length >= 2 ? star.dayPillar : '甲子';
  final dayGan = dp[0];
  final dayJi = dp[1];

  // 셀럽 출생일 → 실제 年柱·月柱·日柱 3주 계산.
  Pillar dayPillar = Pillar(chunGan: dayGan, jiJi: dayJi);
  Pillar yearPillar = dayPillar;   // 폴백 (날짜 파싱 실패 시에만 일주로).
  Pillar monthPillar = dayPillar;  // 폴백.
  final chart = star.birth.isNotEmpty
      ? CelebChartValidator.computeChart(
          celebId: star.id,
          birth: star.birth,
          isMale: star.gender != 'F',
        )
      : null;
  if (chart != null) {
    // 엔진 계산 성공 — 가짜 copy 없이 실제 3주 사용.
    if (chart.yearPillar.length >= 2) {
      yearPillar = Pillar(chunGan: chart.yearPillar[0], jiJi: chart.yearPillar[1]);
    }
    if (chart.monthPillar.length >= 2) {
      monthPillar = Pillar(chunGan: chart.monthPillar[0], jiJi: chart.monthPillar[1]);
    }
    // 日柱는 celebrities.json 기록값과 엔진 계산값이 일치해야 한다.
    // 엔진 계산값을 우선 — 만세력 진실값.
    if (chart.dayPillar.length >= 2) {
      dayPillar = Pillar(chunGan: chart.dayPillar[0], jiJi: chart.dayPillar[1]);
    }
  }

  // 5행 분포 — 일간 천간 5행 가중치 (R100/R101 회귀 0 보존, 위 doc 참조).
  const elMap = {
    '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
    '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
  };
  final ganEl = elMap[dayPillar.chunGan] ?? '木';
  int v(String k) => ganEl == k ? 60 : 10;
  final fe = FiveElements(
    wood: v('木'),
    fire: v('火'),
    earth: v('土'),
    metal: v('金'),
    water: v('水'),
  );
  DateTime? birthDt;
  try {
    if (star.birth.isNotEmpty) {
      birthDt = DateTime.parse(star.birth);
    }
  } catch (_) {
    birthDt = null;
  }
  return SajuResult(
    yearPillar: yearPillar,
    monthPillar: monthPillar,
    dayPillar: dayPillar,
    hourPillar: null,       // 시간 모름 — R83 sprint P1-E 와 동일.
    elements: fe,
    dayMaster: dayPillar.chunGan,
    dayMasterName: star.dayPillarName,
    summary: '',
    categoryReadings: const {},
    birthDateTime: birthDt,
  );
}
