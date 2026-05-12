// Pillar Seer — Discover (Aesop Luxury). 유명인 사주 + 한자 hero, 일주별 비교.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/saju_result.dart';
import '../providers/locale_provider.dart';
import '../providers/saju_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _filter = 'all';
  List<_Celebrity> _all = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/celebrities.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      setState(() {
        _all = list.map(_Celebrity.fromJson).toList();
        _loaded = true;
      });
    } catch (_) {
      setState(() {
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final localeOverride = ref.watch(localeProvider);
    final systemLocale = Localizations.maybeLocaleOf(context);
    final useKo = (localeOverride?.languageCode ??
            systemLocale?.languageCode ??
            'en') ==
        'ko';
    final mySaju = ref.watch(sajuResultProvider);

    final filters = <_F>[
      _F('all', l.discoverFilterAll),
      _F('idol', l.discoverFilterIdol),
      _F('actor', l.discoverFilterActor),
      _F('athlete', l.discoverFilterAthlete),
      _F('icon', l.discoverFilterIcon),
    ];
    final filtered =
        _all.where((c) => _filter == 'all' || c.kind == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
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
                    'DISCOVER · 譜',
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
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CELEBRITY CHARTS · 名 譜',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.discoverTitle,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.discoverSubtitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.accent,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filters.length,
                  itemBuilder: (ctx, i) {
                    final f = filters[i];
                    final selected = f.id == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: selected
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          f.label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.ink
                                : AppColors.taupe,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: !_loaded
                  ? const Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: AppColors.ink, strokeWidth: 1.5)),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, color: AppColors.line, thickness: 1),
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final isMatch = mySaju?.day60ji == c.dayPillar;
                        return _CelebRow(
                          celeb: c,
                          useKo: useKo,
                          isMatch: isMatch,
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
}

class _F {
  final String id;
  final String label;
  const _F(this.id, this.label);
}

class _Celebrity {
  final String id;
  final String nameEn;
  final String nameKo;
  final String kind;
  final String birth;
  final String dayPillar;
  final String dayPillarName;
  final String blurbEn;
  final String blurbKo;
  final String emoji;
  const _Celebrity({
    required this.id,
    required this.nameEn,
    required this.nameKo,
    required this.kind,
    required this.birth,
    required this.dayPillar,
    required this.dayPillarName,
    required this.blurbEn,
    required this.blurbKo,
    required this.emoji,
  });

  factory _Celebrity.fromJson(Map<String, dynamic> j) {
    return _Celebrity(
      id: j['id'] as String? ?? '',
      nameEn: j['nameEn'] as String? ?? '',
      nameKo: j['nameKo'] as String? ?? '',
      kind: j['kind'] as String? ?? 'icon',
      birth: j['birth'] as String? ?? '',
      dayPillar: j['dayPillar'] as String? ?? '',
      dayPillarName: j['dayPillarName'] as String? ?? '',
      blurbEn: j['blurbEn'] as String? ?? '',
      blurbKo: j['blurbKo'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '✦',
    );
  }

  String localizedDayPillarName(bool useKo) {
    if (!useKo) return dayPillarName;
    if (dayPillar.length < 2) return dayPillarName;
    const ganKo = {
      '甲': '갑', '乙': '을', '丙': '병', '丁': '정', '戊': '무',
      '己': '기', '庚': '경', '辛': '신', '壬': '임', '癸': '계',
    };
    const jiKo = {
      '子': '자', '丑': '축', '寅': '인', '卯': '묘',
      '辰': '진', '巳': '사', '午': '오', '未': '미',
      '申': '신', '酉': '유', '戌': '술', '亥': '해',
    };
    const elementKo = {
      '甲': '목', '乙': '목', '丙': '화', '丁': '화',
      '戊': '토', '己': '토', '庚': '금', '辛': '금',
      '壬': '수', '癸': '수',
    };
    const animalKo = {
      '子': '쥐', '丑': '소', '寅': '호랑이', '卯': '토끼',
      '辰': '용', '巳': '뱀', '午': '말', '未': '양',
      '申': '원숭이', '酉': '닭', '戌': '개', '亥': '돼지',
    };
    final g = dayPillar[0];
    final j = dayPillar[1];
    final paired = '${ganKo[g] ?? "?"}${jiKo[j] ?? "?"}';
    final meaning = '${elementKo[g] ?? "?"} ${animalKo[j] ?? "?"}';
    return '$paired · $meaning';
  }
}

class _CelebRow extends ConsumerWidget {
  final _Celebrity celeb;
  final bool useKo;
  final bool isMatch;
  const _CelebRow({
    required this.celeb,
    required this.useKo,
    required this.isMatch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final mySaju = ref.watch(sajuResultProvider);
    return InkWell(
      onTap: () => _showCompare(context, l, mySaju, useKo),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        color: isMatch ? AppColors.paper : AppColors.bg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    celeb.dayPillar.isNotEmpty ? celeb.dayPillar[0] : '?',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: AppColors.accent,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    celeb.dayPillar.length >= 2 ? celeb.dayPillar[1] : '?',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: AppColors.ink,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    useKo ? celeb.nameKo : celeb.nameEn,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    celeb.localizedDayPillarName(useKo).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    useKo ? celeb.blurbKo : celeb.blurbEn,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.inkLight,
                      height: 1.7,
                    ),
                  ),
                  if (isMatch) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 1),
                      ),
                      child: Text(
                        useKo ? 'YOUR PILLAR · 同' : 'YOUR PILLAR · 同',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompare(
      BuildContext context, AppL10n l, SajuResult? me, bool useKo) {
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
                Text(
                  useKo ? celeb.nameKo : celeb.nameEn,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  celeb.localizedDayPillarName(useKo),
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 22),
                if (me != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.paper,
                    width: double.infinity,
                    child: Text(
                      me.day60ji == celeb.dayPillar
                          ? l.discoverCompareSame(
                              celeb.localizedDayPillarName(useKo))
                          : l.discoverCompareDifferent(
                              useKo
                                  ? me.dayPillar.pairKoreanMeaning
                                  : me.dayMasterName,
                              celeb.localizedDayPillarName(useKo)),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.5,
                        color: AppColors.ink,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _compareRow(
                      l.discoverCompareSimilar, _similarities(me, useKo)),
                  const SizedBox(height: 16),
                  _compareRow(
                      l.discoverCompareContrast, _contrasts(me, useKo)),
                  const SizedBox(height: 22),
                ],
                Text(
                  useKo ? celeb.blurbKo : celeb.blurbEn,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.75,
                  ),
                ),
                const SizedBox(height: 22),
                Container(height: 1, color: AppColors.line),
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
                          l.discoverCompareClose.toUpperCase(),
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
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          GoRouter.of(context).go('/reports/compatibility');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size(0, 52),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          l.discoverCompareSeeChart.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 4,
                            color: AppColors.ink,
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

  String _similarities(SajuResult me, bool useKo) {
    final myEl = me.dayPillar.chunGanElement;
    final celebEl = _celebElement();
    final sameElement = myEl == celebEl;
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    final sameJi = celeb.dayPillar.length >= 2 &&
        me.dayPillar.jiJi == celeb.dayPillar[1];
    if (sameElement && sameJi) {
      return useKo
          ? '같은 일주 — 결의 속도와 표현이 모두 비슷합니다.'
          : 'Same day pillar — both pace and expression align.';
    }
    if (sameElement) {
      return useKo
          ? '같은 오행 기운 — 추진력 결이 비슷하고, 동기 부여 방식이 닮았어요.'
          : 'Same elemental base — similar momentum and motivation grain.';
    }
    if (generates[myEl] == celebEl) {
      return useKo
          ? '당신이 키워주는 결 — 셀럽의 흐름을 자연스럽게 받쳐 줍니다.'
          : "You nourish their grain — your energy naturally supports their flow.";
    }
    if (generates[celebEl] == myEl) {
      return useKo
          ? '당신을 키워주는 결 — 셀럽의 결이 당신을 살려주는 관계 구조.'
          : 'They nourish yours — their grain feeds your direction.';
    }
    return useKo
        ? '다른 오행 — 보완 관계로 서로의 결핍을 채울 가능성이 큽니다.'
        : "Different elements but complementary — high potential to fill each other's gaps.";
  }

  String _contrasts(SajuResult me, bool useKo) {
    final myEl = me.dayPillar.chunGanElement;
    final celebEl = _celebElement();
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    final sameJi = celeb.dayPillar.length >= 2 &&
        me.dayPillar.jiJi == celeb.dayPillar[1];
    if (overcomes[myEl] == celebEl) {
      return useKo
          ? '당신이 누르는 결 — 충고가 통제처럼 느껴질 수 있어 표현 톤이 중요합니다.'
          : 'You control their grain — your advice can read as pressure; mind the tone.';
    }
    if (overcomes[celebEl] == myEl) {
      return useKo
          ? '셀럽이 당신을 누르는 결 — 자극이 되지만 페이스를 빼앗기지 마세요.'
          : 'Their grain pressures yours — stimulating, but guard your pace.';
    }
    if (sameJi && myEl != celebEl) {
      return useKo
          ? '비슷한 베이스지만 표현 방식이 다름 — 같은 무대에서 다른 색을 냅니다.'
          : 'Similar base, different expression — same stage, different colors.';
    }
    return useKo
        ? '리듬·페이스가 다름 — 한쪽이 빠를 때 다른 쪽이 느리게, 의식적 동기화 필요.'
        : 'Different rhythms — one pushes while the other paces; conscious sync helps.';
  }

  String _celebElement() {
    const map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    if (celeb.dayPillar.isEmpty) return '';
    return map[celeb.dayPillar[0]] ?? '';
  }

  Widget _compareRow(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.notoSansKr(
            fontSize: 13.5,
            color: AppColors.ink,
            height: 1.75,
          ),
        ),
      ],
    );
  }
}
