// Pillar Seer — Dream (解夢) Report. 검색 + 카테고리 필터.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class DreamScreen extends ConsumerStatefulWidget {
  const DreamScreen({super.key});

  @override
  ConsumerState<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends ConsumerState<DreamScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  List<_Dream> _all = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/dreams.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      setState(() {
        _all = list.map(_Dream.fromJson).toList();
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
    final filters = <_FilterChip>[
      _FilterChip('all', l.dreamCategoryAll),
      _FilterChip('auspicious', l.dreamCategoryAuspicious),
      _FilterChip('wealth', l.dreamCategoryWealth),
      _FilterChip('love', l.dreamCategoryLove),
      _FilterChip('warning', l.dreamCategoryWarning),
      _FilterChip('health', l.dreamCategoryHealth),
    ];
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _all.where((d) {
      final inFilter = _filter == 'all' ||
          d.cat == _filter ||
          (_filter == 'auspicious' && d.auspicious);
      if (!inFilter) return false;
      if (query.isEmpty) return true;
      return d.en.toLowerCase().contains(query) ||
          d.ko.contains(query) ||
          d.cat.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.dreamTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.ghostlyWhite),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.celestialGold),
                  hintText: l.dreamSearchHint,
                  hintStyle: const TextStyle(
                    color: AppColors.fadedSilver,
                    fontSize: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.celestialGold.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.celestialGold),
                  ),
                ),
              ),
            ),
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
                        AppColors.cardBorder,
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
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            useKo ? '검색 결과 없음' : 'No matches',
                            style: const TextStyle(
                                color: AppColors.fadedSilver, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) =>
                              _DreamTile(dream: filtered[i], useKo: useKo),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }
}

class _Dream {
  final String en;
  final String ko;
  final String cat;
  final bool auspicious;
  final String meaningEn;
  final String meaningKo;
  const _Dream({
    required this.en,
    required this.ko,
    required this.cat,
    required this.auspicious,
    required this.meaningEn,
    required this.meaningKo,
  });

  factory _Dream.fromJson(Map<String, dynamic> j) {
    return _Dream(
      en: j['en'] as String? ?? '',
      ko: j['ko'] as String? ?? '',
      cat: j['cat'] as String? ?? 'other',
      auspicious: j['auspicious'] as bool? ?? false,
      meaningEn: j['meaningEn'] as String? ?? '',
      meaningKo: j['meaningKo'] as String? ?? '',
    );
  }
}

class _FilterChip {
  final String id;
  final String label;
  const _FilterChip(this.id, this.label);
}

class _DreamTile extends StatelessWidget {
  final _Dream dream;
  final bool useKo;
  const _DreamTile({required this.dream, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final accent = dream.auspicious
        ? AppColors.celestialGold
        : Colors.redAccent.shade200;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                dream.auspicious
                    ? Icons.auto_awesome
                    : Icons.warning_amber_rounded,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  useKo
                      ? '${dream.ko}  ·  ${dream.en}'
                      : '${dream.en}  ·  ${dream.ko}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ghostlyWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
                child: Text(
                  dream.cat.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: accent,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            useKo ? dream.meaningKo : dream.meaningEn,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.moonlightGray,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
