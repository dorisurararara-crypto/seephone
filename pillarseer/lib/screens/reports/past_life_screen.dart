// Pillar Seer — 전생의 악연/인연 시나리오 (R101 Sprint 5, 팬심 1순위).
//
// 사용자 mandate verbatim:
//   "새로운 메뉴를 만들거야 이 메뉴야 이걸 팬심 1순위로 해주고 ... 이번 생에서도
//    솔라에게 돈 뺏기지만 행복할 운명".
//
// 화면 구조 (R104 sprint 2 — reroll 제거 + 셀럽 선택 시 picker hide):
//   1) 셀럽 미선택 상태 — userName TextField + 검색 + picker 노출.
//      · userName TextField — 빈 값이면 "당신" 으로 inject (사용자 mandate verbatim).
//      · picker — celebrities.json 의 _StarLite list. 검색 + 일주 한자 표시.
//   2) 셀럽 선택 + 결과 생성 후 — name field / search / picker 는 mount 하지 않고
//      결과 카드만 노출. 상단에 "선택한 최애: X" 표시 + "다른 최애 고르기" 버튼.
//   3) 결과 카드 — PastLifeScenario.scenarioKo 본문 + keyword chip. RepaintBoundary
//      로 감싸서 Sprint 7 공유 기능 대비.
//   4) "다른 최애 고르기" 버튼 — _selected / _scenario 초기화 후 picker 화면으로 복귀.
//      (R104: 사용자 mandate 로 이전 seed 회전 reroll 기능은 완전 제거.)
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
import '../../providers/premium_provider.dart';
import '../../providers/saju_provider.dart';
import '../../services/past_life_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/premium_gate.dart';

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

  PastLifeScenario? _scenario;
  bool _composing = false;

  // R110 Sprint 2 — playbook ⑥: 첫 1편 전체 무료. "다른 최애 고르기"로
  // 추가 전생 생성은 프리미엄. 첫 시나리오가 완성되면 true.
  bool _viewedFreeStory = false;

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

  /// R106 P5 — 앱 언어 분기. compatibility_screen / kpop_compat_screen 의
  /// `final useKo = (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko'`
  /// 패턴과 동일.
  bool _useKo(BuildContext context) =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

  String _effectiveUserName(BuildContext context) {
    final raw = _nameCtl.text.trim();
    // R106 P5 — 빈 칸이면 언어별 기본 호칭. KO 경로는 R101 이래의 동작
    // `raw.isEmpty ? '당신' : raw` 그대로, EN 경로는 'you' 로 분기.
    if (!_useKo(context)) return raw.isEmpty ? 'you' : raw;
    return raw.isEmpty ? '당신' : raw;
  }

  Future<void> _compose(BuildContext context) async {
    final me = ref.read(sajuResultProvider);
    final star = _selected;
    if (me == null || star == null) return;
    // R106 P5 — 현재 앱 언어에 맞는 호칭/셀럽명으로 시나리오 생성.
    // 서비스는 KO/EN 본문을 모두 만들지만, 본문에 박히는 이름은 한 쌍이므로
    // 화면이 보는 언어에 맞춰 전달한다.
    final useKo = _useKo(context);
    setState(() {
      _composing = true;
    });
    final celeb = _starLiteToSajuResult(star);
    try {
      final scenario = await PastLifeService.generate(
        user: me,
        celeb: celeb,
        celebName: _starDisplayName(star, useKo),
        userName: _effectiveUserName(context),
        kind: star.kind,
      );
      if (!mounted) return;
      setState(() {
        _scenario = scenario;
        _composing = false;
        // 첫 전생 1편이 완성됨 — 이후 추가 생성은 프리미엄.
        _viewedFreeStory = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _composing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sajuResultProvider);
    final useKo = _useKo(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const PillarBottomNavStatic(activeIdx: 2),
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/reports'),
        ),
        title: Text(
          useKo ? '전생 · 緣' : 'PAST LIFE · 緣',
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
            ? _NeedSajuState(useKo: useKo)
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
            : _buildBody(context, useKo),
      ),
    );
  }

  /// R104 sprint 2 — "다른 최애 고르기" tap. 선택/시나리오를 초기화해
  /// picker / search / name input 화면으로 복귀한다. (검색어는 보존해
  /// 직전에 찾던 목록을 그대로 다시 보여준다.)
  void _chooseOtherStar() {
    setState(() {
      _selected = null;
      _scenario = null;
      _composing = false;
    });
  }

  Widget _buildBody(BuildContext context, bool useKo) {
    // R103 sprint 2 — page-level single primary scroll. picker 의 nested ListView
    // 가 NeverScrollable 로 설정되어 모든 vertical gesture 가 이 ListView 로 흐른다.
    //
    // R104 sprint 2 — 셀럽 선택 후 결과가 있으면 name field / search / picker 를
    // mount 하지 않고 결과 카드만 노출 (사용자 mandate: "선택하면 밑에 목록은
    // 사라지고 결과가 나와야지"). picker 복귀는 "다른 최애 고르기" 버튼으로만.
    final hasResult = _selected != null && _scenario != null;
    return ListView(
      key: const Key('past_life_primary_scroll'),
      padding: EdgeInsets.zero,
      children: [
        _Hero(useKo: useKo),
        if (!hasResult) ...[
          _NameField(controller: _nameCtl),
          _SearchBar(
            controller: _searchCtl,
            useKo: useKo,
            onChanged: (q) => setState(() => _query = q),
          ),
          _StarPickerList(
            stars: _filteredStars(),
            selectedId: _selected?.id,
            useKo: useKo,
            onPick: (s) {
              // R110 Sprint 2 — 첫 1편은 무료. 이미 한 편을 본 뒤의 추가
              // 전생 생성은 프리미엄(미보유 시 paywall hook 만 호출).
              final unlocked = ref.read(isPremiumUnlockedProvider);
              if (_viewedFreeStory && !unlocked) {
                onPremiumLockedTap(PremiumLockContext(
                  feature: PremiumFeature.pastLifeMore,
                  label: useKo ? '전생 이야기' : 'Past Life',
                  context: context,
                ));
                return;
              }
              setState(() {
                _selected = s;
                _scenario = null;
              });
              _compose(context);
            },
          ),
        ],
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
              celebName: _starDisplayName(_selected!, useKo),
              userName: _effectiveUserName(context),
              useKo: useKo,
              onChooseOther: _chooseOtherStar,
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
  final bool useKo;
  const _Hero({required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? '팬심 1순위 · 전생 인연' : 'FOR THE FANDOM · PAST-LIFE TIE',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            useKo ? '전생의 악연 혹은 인연' : 'A bond or a feud, lifetimes ago',
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                    height: 1.25,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            useKo
                ? '나와 최애가 어떤 시대에 만나 어떤 관계였는지, 사주의 합·충·원진살로 풀어드립니다.'
                : 'How you and your favorite might have met, and what you '
                      'might have been to each other — read through the '
                      'meeting, clashing, and love-hate threads of your day pillars.',
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.7,
                  )
                : GoogleFonts.inter(
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
    // R106 P5 — useKo 를 context 에서 직접 산출 (state 의 _useKo 와 동일 패턴).
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo ? '내 이름 (빈 칸이면 “당신”)' : 'Your name (blank becomes “you”)',
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: AppColors.taupe,
                    letterSpacing: 0.4,
                  )
                : GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.taupe,
                    letterSpacing: 0.4,
                  ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('past_life_name_field'),
            controller: controller,
            style: GoogleFonts.notoSansKr(fontSize: 15, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: useKo ? '예) 승현' : 'e.g. Alex',
              hintStyle: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.taupe,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
  final bool useKo;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.useKo,
  });

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
          hintText: useKo ? '최애 이름으로 검색' : 'Search by your favorite’s name',
          hintStyle: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.taupe,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.taupe,
            size: 18,
          ),
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
  final bool useKo;
  const _StarPickerList({
    required this.stars,
    required this.selectedId,
    required this.onPick,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    if (stars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Text(
          useKo
              ? '검색 결과가 없어요. 다른 이름으로 찾아보세요.'
              : 'No matches. Try another name.',
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.inkLight,
                )
              : GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkLight,
                ),
        ),
      );
    }
    // R103 sprint 2 — nested ListView + Container(height:260) 제거.
    //   부모 ListView (build _buildBody) 가 page 단일 primary scroll 을 가져가고,
    //   picker 는 그 자식으로 흐른다. lazy build 는 ListView.builder + shrinkWrap +
    //   NeverScrollableScrollPhysics 조합으로 보존 (시각 영역 밖 item 은 build 지연).
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.line, width: 1),
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: ListView.separated(
        key: const Key('past_life_star_picker_list'),
        padding: EdgeInsets.zero,
        // 부모 ListView 가 single primary scroll — picker 는 gesture 안 가져감.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stars.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, thickness: 1, color: AppColors.line),
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
                          _starDisplayName(s, useKo),
                          style: useKo
                              ? GoogleFonts.notoSerifKr(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: AppColors.ink,
                                )
                              : GoogleFonts.cormorantGaramond(
                                  fontSize: 18,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: AppColors.ink,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          useKo
                              ? '${s.dayPillar} · ${_pillarKoFromHanja(s.dayPillar)}일주'
                              : '${s.dayPillar} · ${_pillarRomanFromHanja(s.dayPillar)} day pillar',
                          style: useKo
                              ? GoogleFonts.notoSansKr(
                                  fontSize: 11.5,
                                  color: AppColors.taupe,
                                )
                              : GoogleFonts.inter(
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
  final bool useKo;

  /// R104 sprint 2 — "다른 최애 고르기" tap. picker 화면으로 복귀.
  final VoidCallback onChooseOther;
  const _ResultCard({
    super.key,
    required this.scenario,
    required this.celebName,
    required this.userName,
    required this.useKo,
    required this.onChooseOther,
  });

  @override
  Widget build(BuildContext context) {
    // R106 P5 — 언어별 keyword 라벨 / headline / body. EN scenarioEn 이 비면
    // (영어 풀 누락 등) 한국어 본문으로 fallback 해 앱이 깨지지 않게 한다.
    final keywords = scenario.keywords
        .map((k) => useKo ? k.labelKo : k.labelEn)
        .toList();
    // R108 ② Sprint 9 — 장편 메타는 언어별로 분기. 영어 모드 + EN longform 풀이
    // 있으면 EN 챕터/제목/메타, 아니면 KO longform 으로 fallback.
    final useEnLong = !useKo && scenario.isLongformEn;
    final showLongform = useKo
        ? (scenario.isLongform && scenario.chapters.isNotEmpty)
        : (useEnLong ? scenario.chaptersEn.isNotEmpty : false);
    final longTitle = useEnLong ? scenario.titleEn : scenario.title;
    final longGenre = useEnLong ? scenario.genreEn : scenario.genre;
    final longEra = useEnLong ? scenario.eraEn : scenario.era;
    final longLogline = useEnLong ? scenario.loglineEn : scenario.logline;
    final longEst = useEnLong
        ? scenario.estReadMinutesEn
        : scenario.estReadMinutes;
    final isLongformActive = useKo ? scenario.isLongform : useEnLong;
    // 작품 제목을 헤드라인으로, 아니면 기존 keyword 헤드라인.
    final headline = isLongformActive && longTitle.trim().isNotEmpty
        ? longTitle
        : (useKo
              ? scenario.headlineKo
              : (scenario.headlineEn.isNotEmpty
                    ? scenario.headlineEn
                    : scenario.headlineKo));
    final body = useKo
        ? scenario.scenarioKo
        : (scenario.scenarioEn.isNotEmpty
              ? scenario.scenarioEn
              : scenario.scenarioKo);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // R104 sprint 2 — 결과 카드 상단에 선택한 최애를 명시 + picker 복귀 경로.
          _SelectedStarBar(
            key: const Key('past_life_selected_star_bar'),
            celebName: celebName,
            useKo: useKo,
            onChooseOther: onChooseOther,
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
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
                    useKo ? '전생 · 緣' : 'PAST LIFE · 緣',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headline,
                    style: useKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                            color: AppColors.ink,
                            height: 1.35,
                          )
                        : GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                            height: 1.3,
                          ),
                  ),
                  // R108 ② — 장편이면 제목 아래 1줄 시놉시스.
                  if (isLongformActive && longLogline.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      longLogline,
                      style: useKo
                          ? GoogleFonts.notoSansKr(
                              fontSize: 12.5,
                              color: AppColors.inkLight,
                              height: 1.55,
                            )
                          : GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.inkLight,
                              height: 1.55,
                            ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // R108 ② — 장편이면 장르 / 시대 / 읽기 시간 메타칩을
                      // keyword 칩 앞에 노출 (인터넷소설 작품 메타 연출).
                      if (isLongformActive) ...[
                        if (longGenre.isNotEmpty)
                          _MetaChip(label: longGenre, accent: true),
                        if (longEra.isNotEmpty)
                          _MetaChip(label: longEra, accent: true),
                        if (longEst > 0)
                          _MetaChip(
                            label: useKo
                                ? '약 $longEst분 읽기'
                                : '~$longEst min read',
                            accent: true,
                          ),
                      ],
                      for (final k in keywords) _MetaChip(label: k),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: AppColors.line),
                  const SizedBox(height: 18),
                  // R108 ② — 장편이면 챕터 헤더 + 본문 + epilogue, 아니면 단일 본문.
                  if (showLongform)
                    _LongformBody(scenario: scenario, useKo: useKo)
                  else
                    Text(
                      body,
                      key: const Key('past_life_result_body'),
                      style: useKo
                          ? GoogleFonts.notoSansKr(
                              fontSize: 14.5,
                              color: AppColors.ink,
                              height: 1.85,
                            )
                          : GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.ink,
                              height: 1.8,
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// R108 ② — 결과 카드 메타칩 (장르 / 시대 / 읽기 시간 / keyword).
class _MetaChip extends StatelessWidget {
  final String label;
  final bool accent;
  const _MetaChip({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? AppColors.accent.withValues(alpha: 0.08) : AppColors.bg,
        border: Border.all(
          color: accent ? AppColors.accent : AppColors.line,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: useKo
            ? GoogleFonts.notoSansKr(
                fontSize: 11,
                color: accent ? AppColors.accent : AppColors.inkLight,
                letterSpacing: 0.2,
              )
            : GoogleFonts.inter(
                fontSize: 11,
                color: accent ? AppColors.accent : AppColors.inkLight,
                letterSpacing: 0.2,
              ),
      ),
    );
  }
}

/// R108 ② — 장편 본문: 챕터 소제목 + 단락 + epilogue 여운 연출.
/// 한 ListView 안의 연속 스크롤 — `past_life_result_body` 키는 첫 챕터 본문에
/// 부여해 기존 스모크 가드를 유지한다.
class _LongformBody extends StatelessWidget {
  final PastLifeScenario scenario;
  final bool useKo;
  const _LongformBody({required this.scenario, required this.useKo});

  @override
  Widget build(BuildContext context) {
    // R108 ② Sprint 9 — 영어 모드 + EN longform 풀이 있으면 EN 챕터,
    // 아니면 KO 챕터.
    final useEnLong = !useKo && scenario.isLongformEn;
    final chapters = useEnLong ? scenario.chaptersEn : scenario.chapters;
    final epilogue = useEnLong ? scenario.epilogueEn : scenario.epilogue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < chapters.length; i++) ...[
          if (i > 0) const SizedBox(height: 26),
          // 챕터 소제목 — 번호 + heading.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${chapters[i].no}',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapters[i].heading,
                  style: useKo
                      ? GoogleFonts.notoSerifKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        )
                      : GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            chapters[i].body,
            key: i == 0 ? const Key('past_life_result_body') : null,
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 14.5,
                    color: AppColors.ink,
                    height: 1.9,
                  )
                : GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.85,
                  ),
          ),
        ],
        if (epilogue.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 18),
          Text(
            useKo ? '그리고, 지금' : 'And now',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            epilogue,
            key: const Key('past_life_epilogue'),
            style: useKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 14.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.ink,
                    height: 1.9,
                  )
                : GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.ink,
                    height: 1.85,
                  ),
          ),
        ],
      ],
    );
  }
}

/// R104 sprint 2 — 결과 카드 상단 바. 선택한 최애 이름을 명시하고,
/// "다른 최애 고르기" 로 picker 화면 복귀 경로를 제공한다.
class _SelectedStarBar extends StatelessWidget {
  final String celebName;
  final bool useKo;
  final VoidCallback onChooseOther;
  const _SelectedStarBar({
    super.key,
    required this.celebName,
    required this.useKo,
    required this.onChooseOther,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              useKo ? '선택한 최애: $celebName' : 'Your pick: $celebName',
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      letterSpacing: 0.2,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      letterSpacing: 0.2,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const Key('past_life_choose_other_star_button'),
            onPressed: onChooseOther,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 36),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              useKo ? '다른 최애 고르기' : 'Pick another',
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: AppColors.accent,
                    )
                  : GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: AppColors.accent,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedSajuState extends StatelessWidget {
  final bool useKo;
  const _NeedSajuState({required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              useKo
                  ? '먼저 내 사주를 입력해 주세요.'
                  : 'Enter your birth details first.',
              textAlign: TextAlign.center,
              style: useKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 18,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w400,
                    )
                  : GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              useKo
                  ? '전생 시나리오는 사용자 사주와 최애의 일주를 바탕으로 합·충·원진살을 풀어드립니다.'
                  : 'The past-life reading is drawn from your day pillar and '
                        'your favorite’s — through the meeting, clashing, and '
                        'love-hate threads between them.',
              textAlign: TextAlign.center,
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.inkLight,
                      height: 1.7,
                    )
                  : GoogleFonts.inter(
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
                useKo ? '사주 입력하기' : 'Enter birth details',
                style: useKo
                    ? GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      )
                    : GoogleFonts.inter(
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
  if (raw.isEmpty) return _stripParen(s.nameEn);
  final cut = raw.contains('(') ? raw.split('(').first.trim() : raw;
  return cut.isEmpty ? _stripParen(s.nameEn) : cut;
}

/// R106 P5 — `nameEn` 의 괄호 (예: "V (BTS)") 안 그룹명을 잘라낸 짧은 영문명.
String _stripParen(String name) {
  final raw = name.trim();
  if (raw.isEmpty) return raw;
  final cut = raw.contains('(') ? raw.split('(').first.trim() : raw;
  return cut.isEmpty ? raw : cut;
}

/// R106 P5 — 언어별 셀럽 표시명. KO → `_starShortName`, EN → `nameEn` 짧은 형.
/// 어느 쪽이든 비어 있으면 다른 언어 이름으로 fallback.
String _starDisplayName(_StarLite s, bool useKo) {
  if (useKo) {
    final ko = _starShortName(s);
    return ko.isNotEmpty ? ko : _stripParen(s.nameEn);
  }
  final en = _stripParen(s.nameEn);
  return en.isNotEmpty ? en : _starShortName(s);
}

/// 일주 한자 2자 → 한국어 음 (kpop_compat_screen.dart `_pillarKoFromHanja` 와 동일 매핑).
String _pillarKoFromHanja(String dayPillar) {
  if (dayPillar.length < 2) return '';
  const ganKo = {
    '甲': '갑',
    '乙': '을',
    '丙': '병',
    '丁': '정',
    '戊': '무',
    '己': '기',
    '庚': '경',
    '辛': '신',
    '壬': '임',
    '癸': '계',
  };
  const jiKo = {
    '子': '자',
    '丑': '축',
    '寅': '인',
    '卯': '묘',
    '辰': '진',
    '巳': '사',
    '午': '오',
    '未': '미',
    '申': '신',
    '酉': '유',
    '戌': '술',
    '亥': '해',
  };
  final g = ganKo[dayPillar[0]] ?? '';
  final j = jiKo[dayPillar[1]] ?? '';
  return '$g$j';
}

/// R106 P5 — 일주 한자 2자 → 로마자 음 (영어 모드 picker 부제목용).
/// 천간/지지 표준 로마자. 매핑 실패 시 빈 문자열.
String _pillarRomanFromHanja(String dayPillar) {
  if (dayPillar.length < 2) return '';
  const ganRoman = {
    '甲': 'Gap',
    '乙': 'Eul',
    '丙': 'Byeong',
    '丁': 'Jeong',
    '戊': 'Mu',
    '己': 'Gi',
    '庚': 'Gyeong',
    '辛': 'Sin',
    '壬': 'Im',
    '癸': 'Gye',
  };
  const jiRoman = {
    '子': 'Ja',
    '丑': 'Chuk',
    '寅': 'In',
    '卯': 'Myo',
    '辰': 'Jin',
    '巳': 'Sa',
    '午': 'O',
    '未': 'Mi',
    '申': 'Sin',
    '酉': 'Yu',
    '戌': 'Sul',
    '亥': 'Hae',
  };
  final g = ganRoman[dayPillar[0]] ?? '';
  final j = jiRoman[dayPillar[1]] ?? '';
  if (g.isEmpty || j.isEmpty) return '';
  return '$g$j';
}

/// `_StarLite` → `SajuResult` light adapter.
/// kpop_compat_screen.dart `_starToSajuResult` 와 동일 패턴 (일주 한자 2자 + birth 만 보강).
SajuResult _starLiteToSajuResult(_StarLite s) {
  final dp = s.dayPillar.length >= 2 ? s.dayPillar : '甲子';
  final dayGan = dp[0];
  final dayJi = dp[1];
  const elMap = {
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
