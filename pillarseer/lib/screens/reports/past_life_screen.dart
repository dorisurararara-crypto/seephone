// Pillar Seer — 전생의 악연/인연 시나리오 (R101 Sprint 5, 팬심 1순위).
//
// 사용자 mandate verbatim:
//   "새로운 메뉴를 만들거야 이 메뉴야 이걸 팬심 1순위로 해주고 ... 이번 생에서도
//    솔라에게 돈 뺏기지만 행복할 운명".
//
// 화면 구조:
//   1) 셀럽 picker — celebrities.json 의 _StarLite list. 검색 + 일주 한자 표시.
//   2) userName TextField — 빈 값이면 "당신" 으로 inject (사용자 mandate verbatim).
//   3) 결과 카드 — PastLifeScenario.scenarioKo 본문 + keyword chip. RepaintBoundary
//      로 감싸서 Sprint 7 공유 기능 대비.
//   4) "다시 뽑기" 버튼 — seed 회전 → 같은 사주짝이라도 시대/관계/결말이 달라짐.
//
// 의존:
//   - PastLifeService.primeCache / generate — Sprint 4 에서 신규 작성.
//   - kpop_compat_screen.dart 의 _Star 패턴은 private 이라 import 불가 → 최소
//     복제 (_StarLite) + _starLiteToSajuResult adapter.
//
// 금지:
//   - 영어 단어 / K-POP 그룹명 영문 head leak. Sprint 4 가드 가 본문을 정제하지만
//     화면 텍스트 (안내 / 라벨 / 버튼) 도 한국어만.
//   - main 사주 입력 화면 우회 — me == null 이면 /input 으로 이동 안내.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
import '../../services/past_life_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class PastLifeScreen extends ConsumerStatefulWidget {
  const PastLifeScreen({super.key});

  @override
  ConsumerState<PastLifeScreen> createState() => _PastLifeScreenState();
}

class _PastLifeScreenState extends ConsumerState<PastLifeScreen> {
  List<_StarLite> _stars = const [];
  bool _loaded = false;
  _StarLite? _selected;
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

  int _seed = 1;
  PastLifeScenario? _scenario;
  bool _composing = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // 셀럽 풀 + past_life_pool 동시 준비.
      final raw = await rootBundle.loadString('assets/data/celebrities.json');
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      final stars = list
          .map(_StarLite.fromJson)
          .where((s) => s.dayPillar.length >= 2)
          .toList();
      // 아이돌 우선 정렬 → 일반 사용자 픽 확률 높이기.
      stars.sort((a, b) {
        final aw = a.kind == 'idol' ? 0 : 1;
        final bw = b.kind == 'idol' ? 0 : 1;
        if (aw != bw) return aw.compareTo(bw);
        return a.nameKo.compareTo(b.nameKo);
      });
      await PastLifeService.primeCache();
      if (!mounted) return;
      setState(() {
        _stars = stars;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  String _effectiveUserName() {
    final raw = _nameCtl.text.trim();
    return raw.isEmpty ? '당신' : raw;
  }

  Future<void> _compose({bool reroll = false}) async {
    final me = ref.read(sajuResultProvider);
    final star = _selected;
    if (me == null || star == null) return;
    setState(() {
      _composing = true;
      if (reroll) _seed = (_seed + 1) & 0x7fffffff;
    });
    final celeb = _starLiteToSajuResult(star);
    try {
      final scenario = await PastLifeService.generate(
        user: me,
        celeb: celeb,
        celebName: _starShortName(star),
        userName: _effectiveUserName(),
        seed: _seed,
      );
      if (!mounted) return;
      setState(() {
        _scenario = scenario;
        _composing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _composing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sajuResultProvider);
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
          '전생 · 緣',
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
            ? _NeedSajuState()
            : !_loaded
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _buildBody(context),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(),
        _NameField(controller: _nameCtl),
        _SearchBar(
          controller: _searchCtl,
          onChanged: (q) => setState(() => _query = q),
        ),
        _StarPickerList(
          stars: _filteredStars(),
          selectedId: _selected?.id,
          onPick: (s) {
            setState(() {
              _selected = s;
              _scenario = null;
            });
            _compose();
          },
        ),
        if (_selected != null) ...[
          const SizedBox(height: 8),
          if (_composing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_scenario != null)
            _ResultCard(
              key: const Key('past_life_result_card'),
              scenario: _scenario!,
              celebName: _starShortName(_selected!),
              userName: _effectiveUserName(),
              onReroll: () => _compose(reroll: true),
            ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }

  List<_StarLite> _filteredStars() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _stars;
    return _stars.where((s) {
      return s.nameKo.toLowerCase().contains(q) ||
          s.nameEn.toLowerCase().contains(q);
    }).toList();
  }
}

// ───────────────── widgets ─────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '팬심 1순위 · 전생 인연',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '전생의 악연 혹은 인연',
            style: GoogleFonts.notoSerifKr(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '나와 최애가 어떤 시대에 만나 어떤 관계였는지, 사주의 합·충·원진살로 풀어드립니다.',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: AppColors.inkLight,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 이름 (빈 칸이면 “당신”)',
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.taupe,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('past_life_name_field'),
            controller: controller,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: '예) 승현',
              hintStyle: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.taupe,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: AppColors.paper,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.line, width: 1),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.line, width: 1),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.accent, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: TextField(
        key: const Key('past_life_search_field'),
        controller: controller,
        style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.ink),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '최애 이름으로 검색',
          hintStyle:
              GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.taupe),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.taupe, size: 18),
          filled: true,
          fillColor: AppColors.bg,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.line, width: 1),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.line, width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.accent, width: 1),
          ),
        ),
      ),
    );
  }
}

class _StarPickerList extends StatelessWidget {
  final List<_StarLite> stars;
  final String? selectedId;
  final ValueChanged<_StarLite> onPick;
  const _StarPickerList({
    required this.stars,
    required this.selectedId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (stars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Text(
          '검색 결과가 없어요. 다른 이름으로 찾아보세요.',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.inkLight,
          ),
        ),
      );
    }
    // Picker 영역은 inline 화면 안에 들어가야 해서 maxHeight 제한.
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.line, width: 1),
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: stars.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.line,
        ),
        itemBuilder: (ctx, i) {
          final s = stars[i];
          final isSelected = s.id == selectedId;
          return InkWell(
            key: Key('past_life_star_row_${s.id}'),
            onTap: () => onPick(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : AppColors.bg,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _starShortName(s),
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.dayPillar} · ${_pillarKoFromHanja(s.dayPillar)}일주',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11.5,
                            color: AppColors.taupe,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, color: AppColors.accent, size: 18)
                  else
                    const Text(
                      '→',
                      style: TextStyle(color: AppColors.taupe, fontSize: 16),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PastLifeScenario scenario;
  final String celebName;
  final String userName;
  final VoidCallback onReroll;
  const _ResultCard({
    super.key,
    required this.scenario,
    required this.celebName,
    required this.userName,
    required this.onReroll,
  });

  @override
  Widget build(BuildContext context) {
    final keywords = scenario.keywords.map((k) => k.labelKo).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: RepaintBoundary(
        key: const Key('past_life_repaint_boundary'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.accent, width: 1.2),
          ),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '전생 · 緣',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                scenario.headlineKo,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final k in keywords)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        border: Border.all(color: AppColors.line, width: 1),
                      ),
                      child: Text(
                        k,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: AppColors.inkLight,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: AppColors.line),
              const SizedBox(height: 18),
              Text(
                scenario.scenarioKo,
                key: const Key('past_life_result_body'),
                style: GoogleFonts.notoSansKr(
                  fontSize: 14.5,
                  color: AppColors.ink,
                  height: 1.85,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('past_life_reroll_button'),
                      onPressed: onReroll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(
                            color: AppColors.accent, width: 1),
                        minimumSize: const Size(0, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        '다시 뽑기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
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
    );
  }
}

class _NeedSajuState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '먼저 내 사주를 입력해 주세요.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifKr(
                fontSize: 18,
                color: AppColors.ink,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '전생 시나리오는 사용자 사주와 최애의 일주를 바탕으로 합·충·원진살을 풀어드립니다.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton(
              onPressed: () => context.go('/input'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 1),
                minimumSize: const Size(0, 48),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                '사주 입력하기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── _StarLite + helpers ─────────────────

/// R101 sprint 5 — kpop_compat_screen.dart `_Star` 의 private 복제(최소 필드).
/// 사용 범위: 본 화면 picker / 어댑터에만 사용. 다른 화면은 기존 `_Star` 그대로.
class _StarLite {
  final String id;
  final String nameKo;
  final String nameEn;
  final String kind;
  final String birth;
  final String dayPillar;

  const _StarLite({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.kind,
    required this.birth,
    required this.dayPillar,
  });

  factory _StarLite.fromJson(Map<String, dynamic> j) => _StarLite(
        id: j['id'] as String? ?? '',
        nameKo: j['nameKo'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        kind: j['kind'] as String? ?? 'icon',
        birth: j['birth'] as String? ?? '',
        dayPillar: j['dayPillar'] as String? ?? '',
      );
}

/// `nameKo` 의 괄호 (예: "홍은채 (LE SSERAFIM)") 안 영문 그룹명을 잘라낸 짧은 표시명.
String _starShortName(_StarLite s) {
  final raw = s.nameKo.trim();
  if (raw.isEmpty) return s.nameEn.trim();
  final cut = raw.contains('(') ? raw.split('(').first.trim() : raw;
  return cut.isEmpty ? s.nameEn.trim() : cut;
}

/// 일주 한자 2자 → 한국어 음 (kpop_compat_screen.dart `_pillarKoFromHanja` 와 동일 매핑).
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

/// `_StarLite` → `SajuResult` light adapter.
/// kpop_compat_screen.dart `_starToSajuResult` 와 동일 패턴 (일주 한자 2자 + birth 만 보강).
SajuResult _starLiteToSajuResult(_StarLite s) {
  final dp = s.dayPillar.length >= 2 ? s.dayPillar : '甲子';
  final dayGan = dp[0];
  final dayJi = dp[1];
  const elMap = {
    '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
    '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
  };
  final ganEl = elMap[dayGan] ?? '木';
  int v(String k) => ganEl == k ? 60 : 10;
  final fe = FiveElements(
    wood: v('木'),
    fire: v('火'),
    earth: v('土'),
    metal: v('金'),
    water: v('水'),
  );
  final pillar = Pillar(chunGan: dayGan, jiJi: dayJi);
  DateTime? birthDt;
  try {
    if (s.birth.isNotEmpty) {
      birthDt = DateTime.parse(s.birth);
    }
  } catch (_) {
    birthDt = null;
  }
  return SajuResult(
    yearPillar: pillar,
    monthPillar: pillar,
    dayPillar: pillar,
    hourPillar: null,
    elements: fe,
    dayMaster: dayGan,
    dayMasterName: '',
    summary: '',
    categoryReadings: const {},
    birthDateTime: birthDt,
  );
}
