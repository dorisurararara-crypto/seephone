// Pillar Seer — Discover (유명인 사주). K-pop/배우/스포츠 인물.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final filtered = _all
        .where((c) => _filter == 'all' || c.kind == _filter)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.discoverTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.celestialGold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.discoverSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.moonlightGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemCount: filters.length,
                itemBuilder: (ctx, i) {
                  final f = filters[i];
                  final selected = f.id == _filter;
                  return ChoiceChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f.id),
                    selectedColor:
                        AppColors.celestialGold.withValues(alpha: 0.25),
                    backgroundColor:
                        AppColors.spiritIndigo.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.celestialGold
                          : AppColors.moonlightGray,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: AppColors.celestialGold
                            .withValues(alpha: selected ? 0.6 : 0.2),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: !_loaded
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.celestialGold))
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final isMatch = mySaju?.day60ji == c.dayPillar;
                        return _CelebTile(
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
      bottomNavigationBar: const PillarBottomNav(activeIdx: 3),
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
}

class _CelebTile extends ConsumerWidget {
  final _Celebrity celeb;
  final bool useKo;
  final bool isMatch;
  const _CelebTile({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.spiritIndigo.withValues(alpha: 0.2),
              AppColors.midnightPurple.withValues(alpha: 0.45),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMatch
                ? AppColors.celestialGold
                : AppColors.celestialGold.withValues(alpha: 0.3),
            width: isMatch ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.celestialGold.withValues(alpha: 0.5),
                    ),
                  ),
                  child:
                      Text(celeb.emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        useKo ? celeb.nameKo : celeb.nameEn,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ghostlyWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${celeb.dayPillarName} · ${celeb.dayPillar}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.celestialGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        celeb.birth,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.fadedSilver,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.celestialGold.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.celestialGold.withValues(alpha: 0.75),
                      ),
                    ),
                    child: Text(
                      useKo ? '내 일주!' : 'YOUR PILLAR!',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.celestialGold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              useKo ? celeb.blurbKo : celeb.blurbEn,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.moonlightGray,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 14,
                    color: AppColors.celestialGold.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  l.discoverShareCompare,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.celestialGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cosmicBlack,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: AppColors.celestialGold.withValues(alpha: 0.55)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(celeb.emoji,
                        style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l.discoverCompareTitle}${useKo ? celeb.nameKo : celeb.nameEn}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ghostlyWhite,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${celeb.dayPillarName} · ${celeb.dayPillar}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.celestialGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (me != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          AppColors.celestialGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.celestialGold
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      me.day60ji == celeb.dayPillar
                          ? l.discoverCompareSame(celeb.dayPillarName)
                          : l.discoverCompareDifferent(
                              me.dayMasterName, celeb.dayPillarName),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.celestialGold,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _compareRow(l.discoverCompareSimilar,
                      _similarities(me, useKo)),
                  const SizedBox(height: 10),
                  _compareRow(
                      l.discoverCompareContrast, _contrasts(me, useKo)),
                  const SizedBox(height: 16),
                ],
                Text(
                  useKo ? celeb.blurbKo : celeb.blurbEn,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.moonlightGray,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.moonlightGray),
                        label: Text(
                          l.discoverCompareClose,
                          style: const TextStyle(
                            color: AppColors.moonlightGray,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.celestialGold
                                .withValues(alpha: 0.3),
                          ),
                          minimumSize: const Size(0, 46),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          GoRouter.of(context).go('/reports/compatibility');
                        },
                        icon: const Icon(Icons.favorite, size: 16),
                        label: Text(
                          l.discoverCompareSeeChart,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.celestialGold,
                          foregroundColor: AppColors.cosmicBlack,
                          minimumSize: const Size(0, 46),
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
    final sameElement = me.dayPillar.chunGanElement == _celebElement();
    if (sameElement) {
      return useKo
          ? '같은 오행 기운 · 비슷한 추진력 결'
          : 'Same elemental base · similar momentum signature';
    }
    return useKo
        ? '다른 오행이지만 보완 관계 · 서로의 결핍을 채울 수 있음'
        : "Different elements, complementary roles · you fill each other's gaps";
  }

  String _contrasts(SajuResult me, bool useKo) {
    if (celeb.dayPillar.length >= 2 &&
        me.dayPillar.jiJi == celeb.dayPillar[1]) {
      return useKo
          ? '비슷한 베이스지만 표현 방식이 다름'
          : 'Similar base, different expression style';
    }
    return useKo
        ? '리듬·페이스가 다름 — 한쪽이 빠를 때 다른 쪽은 느리게'
        : 'Different rhythms — one pushes, the other paces';
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.spiritIndigo.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.celestialGold,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ghostlyWhite,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
