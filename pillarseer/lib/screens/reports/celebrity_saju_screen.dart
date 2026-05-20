// Pillar Seer — 최애의 사주 (R105 Sprint 4, 팬심 4순위).
//
// 사용자 mandate (R105):
//   DB 셀럽의 진짜 사주를 풀되, 위키 검증 사실을 티 안 나게 침투한다.
//   셀럽 출생 시(時)는 공개되지 않았으므로 사주는 年月日 세 기둥만 — 출생 시(時)
//   기준 네 번째 기둥은 절대 생성·암시하지 않는다.
//
// 화면 구조 (past_life_screen picker 패턴 차용):
//   1) 셀럽 미선택 — 검색 + picker 노출. picker 는 celeb_saju_readings.json 의
//      curated 셀럽(= sections 비어있지 않음)만. 빈 셀럽 / non-curated 는 숨긴다.
//   2) 셀럽 선택 후 — search / picker 는 mount 하지 않고 결과 영역만. 상단에
//      "선택한 최애: X" + "다른 최애 고르기" 버튼. 다시뽑기/랜덤 버튼 없음.
//   3) 결과 영역 — 셀럽 사주 차트(年月日 3기둥 + 일간/오행, 時 칸은 "—") +
//      7섹션 본문(opening … closing). 공유 영역은 RepaintBoundary 로 감싼다.
//
// 이 화면은 사용자 본인 사주(sajuResultProvider) 가 불필요하다 — 셀럽 데이터만
// 읽는다. me == null 이어도 접근 가능.
//
// Sprint 4 polish:
//   - 결과 카드: 7섹션을 한국어 섹션 라벨과 함께 표시 (라벨은 UI 코드 매핑,
//     데이터는 readings.json 그대로). 차트에 일간·오행 + 時 "—" 칸 추가.
//   - 공유 영역 RepaintBoundary 감싸기 + overflow 방지.
//   - loading / error / empty(준비중) state 분리.
//
// 금지:
//   - 출생 시(時) 기준 기둥 / "태어난 시간" 단정 표현. 時 칸은 항상 "—".
//   - 사용자 노출 영문 문구 (라벨 / 안내 / 버튼). 차트 한자는 증거 라벨이라 OK.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class CelebritySajuScreen extends ConsumerStatefulWidget {
  const CelebritySajuScreen({super.key});

  @override
  ConsumerState<CelebritySajuScreen> createState() =>
      _CelebritySajuScreenState();
}

/// bootstrap 의 3가지 종료 상태 — UI 분기용.
enum _LoadState { loading, ready, error }

class _CelebritySajuScreenState extends ConsumerState<CelebritySajuScreen> {
  List<_CelebReading> _readings = const [];
  _LoadState _state = _LoadState.loading;
  _CelebReading? _selected;
  final TextEditingController _searchCtl = TextEditingController();
  final ScrollController _scrollCtl = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  /// celebrities.json (이름) + celeb_saju_readings.json (curated reading) 을
  /// 합쳐, curated reading 이 있는 셀럽만 picker 에 노출한다.
  Future<void> _bootstrap() async {
    try {
      final celebRaw = await rootBundle.loadString(
        'assets/data/celebrities.json',
      );
      final celebList = (json.decode(celebRaw) as List)
          .cast<Map<String, dynamic>>();
      final nameById = <String, Map<String, dynamic>>{
        for (final c in celebList)
          if ((c['id'] as String?) != null) c['id'] as String: c,
      };

      final readingRaw = await rootBundle.loadString(
        'assets/data/celeb_saju_readings.json',
      );
      final readingMap = json.decode(readingRaw) as Map<String, dynamic>;

      final readings = <_CelebReading>[];
      readingMap.forEach((id, value) {
        if (id == '_meta') return;
        if (value is! Map<String, dynamic>) return;
        final reading = _CelebReading.tryParse(
          id: id,
          readingJson: value,
          celebJson: nameById[id],
        );
        // curated = sections 비어있지 않은 셀럽만 노출. 나머지(준비 중 / non-curated
        // / boundary_ambiguous reading)는 picker 에서 숨긴다.
        if (reading != null && reading.isCurated) {
          readings.add(reading);
        }
      });
      readings.sort((a, b) => a.nameKoShort.compareTo(b.nameKoShort));

      if (!mounted) return;
      setState(() {
        _readings = readings;
        _state = _LoadState.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  void _retry() {
    setState(() => _state = _LoadState.loading);
    _bootstrap();
  }

  void _selectStar(_CelebReading r) {
    setState(() {
      _selected = r;
      _query = '';
      _searchCtl.clear();
    });
    // 결과 카드가 검색 위치보다 위에서 시작하도록 스크롤을 맨 위로 되돌린다.
    if (_scrollCtl.hasClients) {
      _scrollCtl.jumpTo(0);
    }
  }

  void _chooseOtherStar() {
    setState(() => _selected = null);
    if (_scrollCtl.hasClients) {
      _scrollCtl.jumpTo(0);
    }
  }

  List<_CelebReading> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _readings;
    return _readings
        .where(
          (r) =>
              r.nameKoShort.toLowerCase().contains(q) ||
              r.nameEn.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
          '최애의 사주',
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
      body: SafeArea(top: false, child: _buildState(context)),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  Widget _buildState(BuildContext context) {
    switch (_state) {
      case _LoadState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        );
      case _LoadState.error:
        return _ErrorState(key: const Key('celebrity_saju_error'), onRetry: _retry);
      case _LoadState.ready:
        return _buildBody(context);
    }
  }

  Widget _buildBody(BuildContext context) {
    final hasSelection = _selected != null;
    final filtered = _filtered();
    return ListView(
      key: const Key('celebrity_saju_primary_scroll'),
      controller: _scrollCtl,
      padding: EdgeInsets.zero,
      children: [
        _Hero(),
        if (!hasSelection) ...[
          _SearchBar(
            controller: _searchCtl,
            onChanged: (q) => setState(() => _query = q),
          ),
          _CelebPickerList(
            readings: filtered,
            totalCurated: _readings.length,
            emptyCurated: _readings.isEmpty,
            onPick: _selectStar,
          ),
        ],
        if (hasSelection)
          _ResultCard(
            key: const Key('celebrity_saju_result_card'),
            reading: _selected!,
            onChooseOther: _chooseOtherStar,
          ),
        const SizedBox(height: 28),
      ],
    );
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
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '팬심 4순위 · 최애의 사주',
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '내 최애는 어떤 사주일까',
            style: GoogleFonts.notoSerifKr(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '최애의 공개된 생일로 풀어낸 사주 이야기예요. 출생 시간은 알려지지 않아 '
            '연·월·일 세 기둥만 봅니다.',
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: TextField(
        key: const Key('celebrity_saju_search_field'),
        controller: controller,
        style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.ink),
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '최애 이름으로 검색',
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

class _CelebPickerList extends StatelessWidget {
  final List<_CelebReading> readings;

  /// curated reading 전체 수 (검색 필터 적용 전). 안내 문구에 사용.
  final int totalCurated;

  /// curated reading 이 0개 — 준비 중 상태.
  final bool emptyCurated;
  final ValueChanged<_CelebReading> onPick;
  const _CelebPickerList({
    required this.readings,
    required this.totalCurated,
    required this.emptyCurated,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Text(
          emptyCurated
              ? '최애의 사주 풀이를 준비하고 있어요. 곧 만나요.'
              : '검색 결과가 없어요. 다른 이름으로 찾아보세요.',
          key: const Key('celebrity_saju_empty_hint'),
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.inkLight,
            height: 1.7,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Text(
            '풀이가 준비된 최애 $totalCurated명',
            key: const Key('celebrity_saju_curated_count'),
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.taupe,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            border: Border(
              top: BorderSide(color: AppColors.line, width: 1),
              bottom: BorderSide(color: AppColors.line, width: 1),
            ),
          ),
          child: ListView.separated(
            key: const Key('celebrity_saju_picker_list'),
            padding: EdgeInsets.zero,
            // 부모 ListView 가 page 단일 primary scroll — picker 는 gesture 안 가져감.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, thickness: 1, color: AppColors.line),
            itemBuilder: (ctx, i) {
              final r = readings[i];
              return InkWell(
                key: Key('celebrity_saju_row_${r.id}'),
                onTap: () => onPick(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  color: AppColors.bg,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.nameKoShort,
                              style: GoogleFonts.notoSerifKr(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.dayPillar} · '
                              '${_pillarKoFromHanja(r.dayPillar)}일주',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 11.5,
                                color: AppColors.taupe,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        ),
      ],
    );
  }
}

/// bootstrap 실패 시 — 다시 시도 CTA.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '최애의 사주를 불러오지 못했어요.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifKr(
                fontSize: 18,
                color: AppColors.ink,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '잠시 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton(
              key: const Key('celebrity_saju_retry_button'),
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 1),
                minimumSize: const Size(0, 48),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                '다시 시도',
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

class _ResultCard extends StatelessWidget {
  final _CelebReading reading;
  final VoidCallback onChooseOther;
  const _ResultCard({
    super.key,
    required this.reading,
    required this.onChooseOther,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedStarBar(
            celebName: reading.nameKoShort,
            onChooseOther: onChooseOther,
          ),
          const SizedBox(height: 12),
          // 공유 대비 — 결과 본문 전체를 RepaintBoundary 로 감싼다.
          RepaintBoundary(
            key: const Key('celebrity_saju_repaint_boundary'),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.accent, width: 1.2),
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최애의 사주',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reading.nameKoShort,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 사주 차트 — 年月日 3기둥 + 時 칸은 "—". 출생 시(時) 추정 금지.
                  _SajuChart(reading: reading),
                  const SizedBox(height: 18),
                  Container(height: 1, color: AppColors.line),
                  const SizedBox(height: 18),
                  _SectionBody(reading: reading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 셀럽 사주 차트 — 年月日 3기둥 한자 + 일간/오행 요약. 時 칸은 "—".
class _SajuChart extends StatelessWidget {
  final _CelebReading reading;
  const _SajuChart({required this.reading});

  @override
  Widget build(BuildContext context) {
    final dayMaster = reading.dayMasterKo;
    final element = reading.dayElementKo;
    return Column(
      key: const Key('celebrity_saju_chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4칸: 연·월·일 + 時(미상 "—"). 시각 추정 절대 금지.
        Row(
          children: [
            _PillarChip(label: '연주', pillar: reading.yearPillar),
            const SizedBox(width: 6),
            _PillarChip(label: '월주', pillar: reading.monthPillar),
            const SizedBox(width: 6),
            _PillarChip(label: '일주', pillar: reading.dayPillar),
            const SizedBox(width: 6),
            const _PillarChip(label: '시주', pillar: '—', dim: true),
          ],
        ),
        if (dayMaster.isNotEmpty || element.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            [
              if (dayMaster.isNotEmpty) '일간 $dayMaster',
              if (element.isNotEmpty) '오행 $element',
              '출생 시(時) 미상',
            ].join('  ·  '),
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.taupe,
              letterSpacing: 0.2,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _PillarChip extends StatelessWidget {
  final String label;
  final String pillar;

  /// 시주 미상 칸 — 흐리게 처리.
  final bool dim;
  const _PillarChip({
    required this.label,
    required this.pillar,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                color: AppColors.taupe,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pillar.isEmpty ? '—' : pillar,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: GoogleFonts.notoSerifKr(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: dim ? AppColors.taupe : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 결과 카드 본문 — 7섹션(opening … closing)을 한국어 섹션 라벨과 함께 표시.
class _SectionBody extends StatelessWidget {
  final _CelebReading reading;
  const _SectionBody({required this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading.sections.isEmpty) {
      // curated 만 picker 에 노출되므로 정상 흐름에선 도달하지 않는 방어 분기.
      return Text(
        '${reading.nameKoShort}의 사주 풀이를 정성껏 준비하고 있어요.',
        key: const Key('celebrity_saju_result_body'),
        style: GoogleFonts.notoSansKr(
          fontSize: 14.5,
          color: AppColors.ink,
          height: 1.85,
        ),
      );
    }
    return Column(
      key: const Key('celebrity_saju_result_body'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < reading.sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          Text(
            _sectionLabelKo(reading.sections[i].id),
            style: GoogleFonts.inter(
              fontSize: 9,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            reading.sections[i].bodyKo,
            style: GoogleFonts.notoSansKr(
              fontSize: 14.5,
              color: AppColors.ink,
              height: 1.85,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedStarBar extends StatelessWidget {
  final String celebName;
  final VoidCallback onChooseOther;
  const _SelectedStarBar({
    required this.celebName,
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
              '선택한 최애: $celebName',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const Key('celebrity_saju_choose_other_button'),
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
              '다른 최애 고르기',
              style: GoogleFonts.notoSansKr(
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

// ───────────────── model + helpers ─────────────────

/// celeb_saju_readings.json sections 의 한 섹션 (id + 한국어 본문).
class _CelebSection {
  final String id;
  final String bodyKo;
  const _CelebSection({required this.id, required this.bodyKo});
}

/// celeb_saju_readings.json 의 한 셀럽 항목 + celebrities.json 의 이름.
class _CelebReading {
  final String id;
  final String nameKoShort;
  final String nameEn;
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final List<_CelebSection> sections;

  const _CelebReading({
    required this.id,
    required this.nameKoShort,
    required this.nameEn,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.sections,
  });

  /// curated = 본문 sections 가 비어있지 않음. 빈 셀럽은 메뉴에서 숨긴다.
  bool get isCurated => sections.isNotEmpty;

  /// 일간(日干) 한국어 음 — 일주 한자 첫 글자.
  String get dayMasterKo =>
      dayPillar.isEmpty ? '' : (_ganKo[dayPillar[0]] ?? '');

  /// 일간 오행 한국어 — 일주 한자 첫 글자 기준.
  String get dayElementKo =>
      dayPillar.isEmpty ? '' : (_ganElementKo[dayPillar[0]] ?? '');

  static _CelebReading? tryParse({
    required String id,
    required Map<String, dynamic> readingJson,
    required Map<String, dynamic>? celebJson,
  }) {
    final chart = readingJson['chart'];
    if (chart is! Map<String, dynamic>) return null;
    final rawSections = readingJson['sections'];
    final sections = <_CelebSection>[];
    if (rawSections is List) {
      for (final s in rawSections) {
        if (s is Map<String, dynamic>) {
          final sid = (s['id'] as String?)?.trim() ?? '';
          final body = (s['bodyKo'] as String?)?.trim() ?? '';
          if (body.isNotEmpty) {
            sections.add(_CelebSection(id: sid, bodyKo: body));
          }
        }
      }
    }
    final nameKo = (celebJson?['nameKo'] as String?)?.trim() ?? '';
    final nameEn = (celebJson?['nameEn'] as String?)?.trim() ?? '';
    return _CelebReading(
      id: id,
      nameKoShort: _shortName(nameKo, nameEn),
      nameEn: nameEn,
      yearPillar: (chart['yearPillar'] as String?)?.trim() ?? '',
      monthPillar: (chart['monthPillar'] as String?)?.trim() ?? '',
      dayPillar: (chart['dayPillar'] as String?)?.trim() ?? '',
      sections: sections,
    );
  }
}

/// "홍은채 (LE SSERAFIM)" → "홍은채" (괄호 안 영문 그룹명 제거).
String _shortName(String nameKo, String nameEn) {
  final raw = nameKo.trim();
  if (raw.isEmpty) return nameEn.trim();
  final cut = raw.contains('(') ? raw.split('(').first.trim() : raw;
  return cut.isEmpty ? nameEn.trim() : cut;
}

/// 결과 카드 7섹션 id → 한국어 섹션 라벨. (라벨은 UI 매핑 — 데이터 변경 아님.)
/// 알 수 없는 id 는 빈 문자열 → 라벨 없이 본문만 표시.
String _sectionLabelKo(String sectionId) {
  const labels = {
    'opening': '첫인상',
    'day_core': '일주의 핵심',
    'month_year_frame': '월·연주의 틀',
    'ten_gods_flow': '십신의 흐름',
    'verified_trace': '사주에 남은 흔적',
    'fan_takeaway': '팬에게 한마디',
    'closing': '맺음말',
  };
  return labels[sectionId] ?? '';
}

/// 천간 한자 → 한국어 음.
const Map<String, String> _ganKo = {
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

/// 천간 한자 → 오행 한국어.
const Map<String, String> _ganElementKo = {
  '甲': '목(木)',
  '乙': '목(木)',
  '丙': '화(火)',
  '丁': '화(火)',
  '戊': '토(土)',
  '己': '토(土)',
  '庚': '금(金)',
  '辛': '금(金)',
  '壬': '수(水)',
  '癸': '수(水)',
};

/// 지지 한자 → 한국어 음.
const Map<String, String> _jiKo = {
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

/// 일주 한자 2자 → 한국어 음 (past_life_screen `_pillarKoFromHanja` 와 동일 매핑).
String _pillarKoFromHanja(String dayPillar) {
  if (dayPillar.length < 2) return '';
  final g = _ganKo[dayPillar[0]] ?? '';
  final j = _jiKo[dayPillar[1]] ?? '';
  return '$g$j';
}
