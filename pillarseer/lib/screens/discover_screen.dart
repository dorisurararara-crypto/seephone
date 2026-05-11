// Pillar Seer — Discover (유명인 사주). K-pop/배우/스포츠 인물.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
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

class _CelebTile extends StatelessWidget {
  final _Celebrity celeb;
  final bool useKo;
  final bool isMatch;
  const _CelebTile({
    required this.celeb,
    required this.useKo,
    required this.isMatch,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.spiritIndigo.withValues(alpha: 0.18),
            AppColors.midnightPurple.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMatch
              ? AppColors.celestialGold
              : AppColors.celestialGold.withValues(alpha: 0.3),
          width: isMatch ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.celestialGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.celestialGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(celeb.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      useKo ? celeb.nameKo : celeb.nameEn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ghostlyWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${celeb.dayPillarName} (${celeb.dayPillar}) · ${celeb.birth}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.celestialGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMatch)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.celestialGold.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    useKo ? '내 일주!' : 'YOUR PILLAR!',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.celestialGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            useKo ? celeb.blurbKo : celeb.blurbEn,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.moonlightGray,
              height: 1.6,
            ),
          ),
          if (isMatch) ...[
            const SizedBox(height: 8),
            Text(
              l.discoverShareCompare,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.celestialGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
