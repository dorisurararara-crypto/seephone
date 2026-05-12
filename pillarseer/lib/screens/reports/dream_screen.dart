// Pillar Seer — Dream (解夢) Report. Aesop Luxury tone.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      setState(() => _loaded = true);
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
    final filters = <_F>[
      _F('all', l.dreamCategoryAll),
      _F('auspicious', l.dreamCategoryAuspicious),
      _F('wealth', l.dreamCategoryWealth),
      _F('love', l.dreamCategoryLove),
      _F('family', l.dreamCategoryFamily),
      _F('warning', l.dreamCategoryWarning),
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
          'DREAM · 解 夢',
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.notoSerifKr(
                  fontSize: 16,
                  color: AppColors.ink,
                ),
                cursorColor: AppColors.ink,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.dreamSearchHint,
                  hintStyle: GoogleFonts.notoSerifKr(
                    fontSize: 16,
                    color: AppColors.taupe.withValues(alpha: 0.6),
                  ),
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.taupe, size: 18),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.line)),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.line)),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.ink, width: 1.2)),
                ),
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
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            useKo ? '검색 결과 없음' : 'No matches',
                            style: useKo
                                ? GoogleFonts.notoSerifKr(
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.taupe,
                                    fontSize: 14,
                                  )
                                : GoogleFonts.cormorantGaramond(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.taupe,
                                    fontSize: 14,
                                  ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: AppColors.line,
                              thickness: 1),
                          itemBuilder: (ctx, i) =>
                              _DreamRow(dream: filtered[i], useKo: useKo),
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

class _F {
  final String id;
  final String label;
  const _F(this.id, this.label);
}

class _DreamRow extends StatelessWidget {
  final _Dream dream;
  final bool useKo;
  const _DreamRow({required this.dream, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      color: dream.auspicious ? AppColors.bg : AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  useKo ? dream.ko : dream.en,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: dream.auspicious
                          ? AppColors.accent
                          : AppColors.taupe,
                      width: 1),
                ),
                child: Text(
                  dream.cat.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                    color: dream.auspicious
                        ? AppColors.accent
                        : AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            useKo ? dream.en : dream.ko,
            // useKo → secondary text is English → Cormorant italic OK
            // !useKo → secondary text is Korean → Noto Serif KR weight 300
            style: useKo
                ? GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.inkLight,
                  )
                : GoogleFonts.notoSerifKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: AppColors.inkLight,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            useKo ? dream.meaningKo : dream.meaningEn,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.ink,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}
