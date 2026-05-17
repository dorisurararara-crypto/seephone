// Pillar Seer — Result screen (Aesop Luxury redesign).
// 텍스트 위주 magazine editorial. emoji 제거. letter-spacing UPPERCASE 라벨.
// ignore_for_file: unused_element, unused_element_parameter

// Round 70 mandate: 자미두수 별 이름·궁 이름 UI 노출 0.
// _CrossmatchSection 은 "DEEP POINT" 라벨로 우회 노출 (우리 차별점 — 사주↔자미두수 교차 일치).
// 별 이름·궁 이름은 BASE/DEEP evidence 본문에만 등장 (Round 70 9.95 PASS 선례).
// Sprint 1 (Round 73): 영문 모드 한글 leak 0 — useKo 분기 추가만.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/gong_mang_service.dart';
import '../services/gyeokguk_service.dart';
import '../services/hapchung_service.dart';
import '../services/life_stage_service.dart';
import '../services/palace_helper_anchor_service.dart';
import '../services/personalization_engine.dart';
import '../services/additional_life_service.dart';
import '../services/saju_context.dart';
import '../services/career_recommend_service.dart';
import '../services/sipsin_persona_service.dart';
import '../services/wealth_strategy_service.dart';
import '../services/shinsa_service.dart';
import '../services/strength_service.dart';
import '../services/twelve_unsung_service.dart';
import '../services/yongsin_service.dart';
import '../services/ziwei_crossmatch_service.dart';
import '../services/ziwei_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/saju_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';
import '../widgets/saju_required_empty.dart';

/// Round 70 mandate 명시: 자미두수 별 이름/궁 이름 UI 노출 0.
/// `_CrossmatchSection` 은 "DEEP POINT" 우회 라벨로 노출 유지 (우리 차별점).
/// `_ZiweiPalaceGroup` 도 "12가지 결 풀이" 우회 라벨 유지 (Round 70 9.95 PASS 선례).
/// Sprint 1 (Round 73): UI 토글 변경 X — useKo 분기 추가만.
const bool kIsZiweiUiHidden = true;

// Round 82 sprint 2 — 오늘 사건 카드 widget 및 anchor key/scroll logic 제거.
// 사용자 mandate "내 사주 = 평생사주만". 알림 deep-link 는 `lib/router.dart` 의
// redirect rule (R79 sprint 7) 로 `/today` 로 처리.

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    // Round 77 sprint 8 — SajuResult.dummy() fallback 제거. 사주 null 시 empty state CTA.
    final resultOrNull = ref.watch(sajuResultProvider);
    if (resultOrNull == null) {
      return const SajuRequiredEmpty();
    }
    final result = resultOrNull;
    final isPro = ref.watch(devUnlockProvider);
    final overrideLocale = ref.watch(localeProvider);
    final systemLocale = Localizations.maybeLocaleOf(context);
    final lang = (overrideLocale?.languageCode ?? systemLocale?.languageCode ?? 'en');
    final useKo = lang == 'ko';
    final reading = useKo ? result.deepKo : result.deepEn;

    // 깊은 풀이 레이어 — 사용자 입력 있을 때만 계산. 없으면 null 처리.
    // R83 sprint 5 (P1-E) — 외부 reviewer P0 #4 mandate:
    //   "시간 모름 = 임의 12시로 계산 금지." 자미두수는 시지 (時支) 가 12궁 배치의
    //   핵심 입력 — 시간 모름 시 노출하면 거짓 정보. 따라서 unknownTime=true 시
    //   ziwei=null + crossmatches=빈 list 로 차단 (정직성 우선).
    final birth = ref.watch(userBirthInfoProvider);
    final ZiweiResult? ziwei = (birth != null && !birth.unknownTime)
        ? ZiweiService.calculate(
            year: birth.birthDate.year,
            month: birth.birthDate.month,
            day: birth.birthDate.day,
            hour: birth.birthHour,
            minute: birth.birthMinute,
            isMale: birth.isMale,
          )
        : null;
    final crossmatches = ziwei != null
        ? ZiweiCrossmatchService.find(result, ziwei)
        : const <CrossMatch>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        title: Text(
          'P I L L A R    S E E R',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 5,
            color: AppColors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: _AesopChip(label: l.resultPrecisionBadge),
            ),
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Round 82 sprint 7 — first-fold 핵심 4 섹션 만 펼침. 나머지 14+ 섹션은
            // `_CollapsibleSection` wrapper 로 접힘 (사용자 mandate "한눈에 안 들어옴").
            // 정보 손실 0: 기존 widget 그대로 child 로 mount, R71~R80 시그니처 보존.
            //
            // 펼침 4 (codex 9.9+ 우선순위):
            //   1) 일주 한 줄 (_DayMasterHero — R71 _OracleHero)
            //   2) 5행 분포 (_FiveElementsSection — 1995-10-27 男 17시 16/21/17/41/4 골든)
            //   3) 8글자 십신 (_SipsinPersonaSection — R73 sprint 3)
            //   4) 오늘 한 줄 (_ForYouTodaySection — R71 personalization)

            // ===== first-fold 펼침 (4 섹션) =====
            // 1. Hero — 일주 한 줄
            _DayMasterHero(result: result, reading: reading, useKo: useKo),
            // 2. FIVE ELEMENTS — 5행 분포 (골든)
            _FiveElementsSection(
                result: result, reading: reading, useKo: useKo),
            // 3. SIPSIN PERSONA — 8글자 십신 (R73 sprint 3)
            // R83 sprint 5 (P1-E) — unknownTime=true 시 헤더 아래 보조 라벨 mount.
            _SipsinPersonaSection(
              result: result,
              useKo: useKo,
              unknownTime: birth?.unknownTime ?? false,
            ),
            // 4. FOR YOU TODAY — 오늘 한 줄 (R71 personalization)
            _ForYouTodaySection(result: result, useKo: useKo),

            // ===== 접힘 collapsed (헤더 라벨 + tap 펼침, 정보 손실 0) =====
            // 친구 자랑 CTA — 첫 fold 4 다음.
            _CollapsibleSection(
              label: useKo ? '친구한테 자랑하기' : 'SHARE',
              preview: useKo
                  ? '내 사주 카드를 친구한테 보내볼까요.'
                  : 'Send your saju card to a friend.',
              background: AppColors.bg,
              child: _ShareHeroBar(
                onTap: () => _shareChart(context, result, useKo),
              ),
            ),
            // 2.5 TWIN-LENS — 두 번 봐도 같이 잡힌 강점 (차별점)
            if (crossmatches.isNotEmpty)
              _CollapsibleSection(
                label: useKo ? '두 번 봐도 같이 잡힌 강점' : 'DEEP POINT · 深 點',
                preview: useKo
                    ? '깊게 봐도 똑같이 잡힌 사주의 단단한 부분이에요.'
                    : 'Strengths that hold up even when read twice.',
                background: AppColors.paper,
                child: _CrossmatchSection(matches: crossmatches, useKo: useKo),
              ),
            // 2.6 LIFE STAGE — 초년/중년/말년 (Round 73 sprint 2)
            _CollapsibleSection(
              label: useKo ? '시기별 풀이 (초년·중년·말년)' : 'LIFE STAGE',
              preview: useKo
                  ? '초년·중년·말년 시기별로 사주를 풀어드려요.'
                  : 'Read by life stage.',
              background: AppColors.bg,
              child: _LifeStageSection(
                result: result,
                useKo: useKo,
                isMale: birth?.isMale ?? true,
                userAge: birth != null
                    ? (DateTime.now().year - birth.birthDate.year)
                    : null,
                // R83 sprint 5 (P1-E) — 시간 모름 시 정확도 안내 라벨.
                unknownTime: birth?.unknownTime ?? false,
              ),
            ),
            // 2.8 CAREER — 직업 추천 (Round 73 sprint 6)
            _CollapsibleSection(
              label: useKo ? '나한테 맞는 일 방향' : 'CAREER',
              preview: useKo
                  ? '사주에 맞는 일 방향을 추천해드려요.'
                  : 'Work directions that fit your chart.',
              background: AppColors.paper,
              child: _CareerSection(result: result, useKo: useKo),
            ),
            // 2.8 WEALTH — 재테크 3 phase (Round 73 sprint 6)
            _CollapsibleSection(
              label: useKo ? '돈 들어오는 방식' : 'WEALTH',
              preview: useKo
                  ? '돈이 어떻게 들어오고 나가는지 봐드려요.'
                  : 'How money moves in your chart.',
              background: AppColors.bg,
              child: _WealthStrategySection(result: result, useKo: useKo),
            ),
            // 2.9 ADDITIONAL 6 — 건강/체질/사회 등 (Round 73 sprint 4)
            _CollapsibleSection(
              label: useKo ? '6가지 추가 풀이' : 'ADDITIONAL',
              preview: useKo
                  ? '건강·체질·사회성 등 여섯 가지 영역을 추가로 봐요.'
                  : 'Health, body, social, and three more.',
              background: AppColors.paper,
              child: _AdditionalLifeSection(result: result, useKo: useKo),
            ),
            // 3. CHART ATTRIBUTES — 2x2 grid
            _CollapsibleSection(
              label: useKo ? '사주 핵심 4가지' : 'CHART ATTRIBUTES',
              preview: useKo
                  ? '사주 유형·필요한 보충·세기·비어있는 자리 한눈에.'
                  : 'Format, needed element, strength, void.',
              background: AppColors.bg,
              child: _ChartAttributesSection(result: result, useKo: useKo),
            ),
            // 4. FOUR PILLARS — 4-column hairline
            _CollapsibleSection(
              label: useKo ? '네 기둥 한눈에' : 'FOUR PILLARS',
              preview: useKo
                  ? '연주·월주·일주·시주 네 기둥을 카드로 보여드려요.'
                  : 'Year, Month, Day, Hour pillars.',
              background: AppColors.paper,
              // R83 sprint 5 (P1-E) — 시간 모름 시 HOUR 영역 흐림 + disclaimer.
              child: _FourPillarsSection(
                result: result,
                useKo: useKo,
                unknownTime: birth?.unknownTime ?? false,
              ),
            ),
            // 5. THREE STROKES — magazine 3-hit
            _CollapsibleSection(
              label: useKo ? '핵심 세 줄 매거진 풀이' : 'THREE STROKES',
              preview: useKo
                  ? '사주 핵심을 매거진 세 줄로 정리해드려요.'
                  : 'Your chart in three magazine strokes.',
              background: AppColors.bg,
              child: _ThreeStrokesSection(
                  result: result, reading: reading, useKo: useKo),
            ),
            // A READING — 사주 5초 요약 (paper bg) — first-fold 에서 collapsed 로 이동.
            // 사용자 mandate first-fold = 일주/5행/십신/오늘. 본 섹션은 보조 magazine body.
            _CollapsibleSection(
              label: useKo ? '내 사주 한눈에 매거진 풀이' : 'A READING',
              preview: useKo
                  ? '사주 한 줄 요약을 매거진 본문으로 풀어드려요.'
                  : 'Magazine summary of your chart.',
              background: AppColors.paper,
              child:
                  _ReadingSection(result: result, reading: reading, useKo: useKo),
            ),
            // 7.5 인생 12 영역 풀이 (R70 자미두수 hidden, 라벨 우회 유지).
            // `_ZiweiPalaceGroup` 자체가 _GroupSection + 12 _AccordionRow 접힘.
            // 추가 wrap 없이 그대로 mount — 12 row 가 모두 접힌 상태로 시작.
            if (ziwei != null && kIsZiweiUiHidden)
              _ZiweiPalaceGroup(
                ziwei: ziwei,
                useKo: useKo,
                sajuResult: result,
              ),
            // 8. CORE READING accordion group — 자체 5 _AccordionRow 접힘.
            // 그룹 자체도 추가 collapse 적용 → 첫 fold 깔끔.
            _CollapsibleSection(
              label: useKo ? '기본 풀이 (십신·테마·10년·올해·행운)' : 'CORE READING',
              preview: useKo
                  ? '십신·테마·10년 운·올해 운·행운 다섯 가지를 봐드려요.'
                  : 'Ten gods, themes, 10-year, this year, lucky.',
              background: AppColors.paper,
              child: _GroupSection(
                groupLabel: useKo ? '기본 풀이 · CORE READING' : 'CORE READING',
                background: AppColors.paper,
                children: [
                  _AccordionRow(
                    title: l.resultTenGodsTitle.toUpperCase(),
                    hint: l.resultTenGodsTermHint,
                    locked: !isPro,
                    note: reading?.tenGodsNote,
                    child: _TenGodsTable(rows: result.tenGods, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: l.resultLifeThemesTitle.toUpperCase(),
                    locked: false,
                    child: _LifeThemesBlock(reading: reading, isPro: isPro),
                  ),
                  _AccordionRow(
                    title: l.resultTenYearLuckTitle.toUpperCase(),
                    hint: l.resultTenYearLuckTermHint,
                    locked: !isPro,
                    child: _LongText(text: reading?.tenYearLuck ?? ''),
                  ),
                  _AccordionRow(
                    title: l.resultThisYearTitle.toUpperCase(),
                    hint: l.resultThisYearTermHint,
                    locked: !isPro,
                    child: _LongText(text: reading?.thisYear ?? ''),
                  ),
                  _AccordionRow(
                    title: l.resultLuckyTitle.toUpperCase(),
                    locked: !isPro,
                    child: _LuckyBlock(reading: reading, useKo: useKo),
                  ),
                ],
              ),
            ),
            // 9. DEEP MYEONGLI accordion group — 자체 7 _AccordionRow 접힘.
            // R87 sprint 4 — 사용자 용신 spoiler. 사용자가 collapsed 상태에서도
            // 자기 용신을 1초 안에 확인 가능하게 preview 에 미리 노출. 사용자가
            // "용신이 뭐야" 묻는 경우 (UI 발견 실패) 방지.
            Builder(builder: (context) {
              final previewEl = result.elements;
              final previewDm = result.dayPillar.chunGanElement;
              final previewStrength = StrengthService.judge(
                dayMasterElement: previewDm,
                monthJi: result.monthPillar.jiJi,
                wood: previewEl.wood,
                fire: previewEl.fire,
                earth: previewEl.earth,
                metal: previewEl.metal,
                water: previewEl.water,
                dayMaster: result.dayPillar.chunGan,
                yearJi: result.yearPillar.jiJi,
                dayJi: result.dayPillar.jiJi,
                hourJi: result.hourPillar?.jiJi,
              );
              final previewYongsin = YongsinService.judge(
                dayMasterElement: previewDm,
                strengthLabel: previewStrength.label,
                wood: previewEl.wood,
                fire: previewEl.fire,
                earth: previewEl.earth,
                metal: previewEl.metal,
                water: previewEl.water,
                monthBranch: result.monthPillar.jiJi,
              );
              final userYs = previewYongsin.yongsin;
              return _CollapsibleSection(
              label: useKo
                  ? '깊은 사주 풀이 (격국·용신·강약·공망·신살·12운성·합충)'
                  : 'DEEP MYEONGLI',
              preview: useKo
                  ? '내 용신 = $userYs · 격국·강약·공망·신살·12운성·합충 일곱 가지 풀이.'
                  : 'Your yongsin = $userYs · format, strength, void, shinsa, life cycle, relations.',
              background: AppColors.bg,
              child: _GroupSection(
                groupLabel:
                    useKo ? '깊은 명리학 · DEEP MYEONGLI' : 'DEEP MYEONGLI',
                background: AppColors.bg,
                children: [
                  _AccordionRow(
                    title:
                        useKo ? '격국 · CHART FORMAT' : 'GYEOKGUK · CHART FORMAT',
                    locked: false,
                    child: _GyeokgukBlock(result: result, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: useKo
                        ? '용신 · NEEDED ELEMENT'
                        : 'YONGSIN · NEEDED ELEMENT',
                    locked: false,
                    child: _YongsinBlock(result: result, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: useKo ? '강약 · STRENGTH' : 'STRENGTH',
                    locked: false,
                    child: _StrengthBlock(result: result, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: useKo ? '공망 · VOID' : 'VOID BRANCHES',
                    locked: false,
                    child: _GongMangBlock(result: result, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: useKo ? '신살 · SHINSA' : 'SHINSA',
                    locked: false,
                    child: _ShinsaBlock(result: result, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: useKo
                        ? '12 운성 · LIFE CYCLE'
                        : '12 UNSUNG · LIFE CYCLE',
                    locked: false,
                    child: _TwelveUnsungBlock(result: result, useKo: useKo),
                  ),
                  _AccordionRow(
                    title: useKo
                        ? '합·충 · RELATIONS'
                        : 'HAP & CHUNG · RELATIONS',
                    locked: false,
                    child: _HapchungBlock(result: result, useKo: useKo),
                  ),
                ],
              ),
            );
            }),
            // 10. VERIFICATION — 자체 1 _AccordionRow 접힘.
            _CollapsibleSection(
              label: useKo ? '계산 기준 확인' : 'VERIFICATION',
              preview: useKo
                  ? '사주 계산 기준과 산식 근거를 확인할 수 있어요.'
                  : 'How the calculation was done.',
              background: AppColors.paper,
              child: _GroupSection(
                groupLabel: useKo ? '검증 · VERIFICATION' : 'VERIFICATION',
                background: AppColors.paper,
                children: [
                  _AccordionRow(
                    title: l.resultBasisTitle.toUpperCase(),
                    locked: false,
                    child:
                        _CalculationBasisBody(result: result, useKo: useKo),
                  ),
                ],
              ),
            ),
            // 11. PRO HOOKS (only free) — bg
            if (!isPro) ...[
              _ProHooksSection(),
            ],
            // 12. CTA stack — ink (full-width)
            _CtaStack(
              isPro: isPro,
              onShare: () => _shareChart(context, result, useKo),
            ),
            // 13. Footer — KASI source
            _AesopFooter(),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 1),
    );
  }
}

// ──────────── small primitives ────────────

class _AesopChip extends StatelessWidget {
  final String label;
  final Color? color;
  const _AesopChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.inkLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          letterSpacing: 3,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  final Color background;
  final String? meta;
  final Widget child;
  final EdgeInsets padding;
  final bool topBorder;
  final bool bottomBorder;
  const _SectionFrame({
    required this.background,
    required this.child,
    this.meta,
    this.padding = const EdgeInsets.fromLTRB(24, 36, 24, 36),
    this.topBorder = false,
    this.bottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: topBorder
              ? const BorderSide(color: AppColors.line, width: 1)
              : BorderSide.none,
          bottom: bottomBorder
              ? const BorderSide(color: AppColors.line, width: 1)
              : BorderSide.none,
        ),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta != null) ...[
            Text(
              meta!.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 22),
          ],
          child,
        ],
      ),
    );
  }
}

class _LongText extends StatelessWidget {
  final String text;
  const _LongText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
        fontSize: 14.5,
        height: 1.85,
        color: AppColors.ink,
      ),
    );
  }
}

// ──────────── Hero ────────────

class _DayMasterHero extends StatelessWidget {
  final SajuResult result;
  final DeepReading? reading;
  final bool useKo;
  const _DayMasterHero({
    required this.result,
    required this.reading,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    // R86 — 사용자 mandate: "금 토끼의 결" 명사화 표현 제거. meaning 본문 노출 0.
    final element = result.dayPillar.chunGanElement;
    final elementKo = const {
      '木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물',
    }[element] ?? element;
    final subAccent = reading?.oneLineYouAre.trim() ?? '';
    // 한 줄 답 — 사용자가 5초 안에 이해할 문장.
    final oneLineAnswer = useKo
        ? (subAccent.isEmpty
            ? '$elementKo의 기운을 가진 사람이에요.'
            : '$subAccent 사람이에요.')
        : (subAccent.isEmpty
            ? 'A person carrying the spirit of $element.'
            : 'A $subAccent person.');

    return _SectionFrame(
      background: AppColors.bg,
      meta: useKo ? '나는 어떤 사람? · 日 柱' : 'Who am I? · 日 柱',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 답 먼저 — 5초 안에 이해되는 한 줄.
          Text(
            oneLineAnswer,
            style: GoogleFonts.notoSerifKr(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
              height: 1.35,
              color: AppColors.ink,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 18),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          // 보조 — '일주' 풀이 + 한자 sub-accent
          RichText(
            text: TextSpan(
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.7,
                letterSpacing: 0.2,
              ),
              children: [
                TextSpan(
                  // R86 — 사용자 mandate: "금 토끼의 결" 명사화 표현 제거.
                  // meaning ("금 토끼") + "의 결" 모두 노출 X. subtitle 만 유지.
                  text: useKo
                      ? '당신의 기본 성향\n(태어난 날 기준 — 정밀 모드에서 한자 표기 보기)'
                      : 'Your basic nature\n(based on birth day — toggle precision mode for hanja)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 작은 hint — 용어 풀이
          Text(
            useKo
                ? '※ 사주의 핵심 — 당신이 어떤 사람인지 가장 잘 보여주는 부분이에요.'
                : '※ The core of your saju — the part that shows who you really are.',
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: AppColors.taupe,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── A READING ────────────

class _ReadingSection extends StatelessWidget {
  final SajuResult result;
  final DeepReading? reading;
  final bool useKo;
  const _ReadingSection({
    required this.result,
    required this.reading,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final body = reading?.dayMasterDeep ??
        (useKo
            ? '당신의 기본 성향에 대한 자세한 풀이는 곧 갱신됩니다.'
            : result.summary);
    final lead = useKo ? '한 줄 요약 ' : 'In summary ';
    final accentPhrase = useKo
        ? '속도보다 깊이로 흐르는'
        : 'flowing in depth rather than speed';

    return _SectionFrame(
      background: AppColors.paper,
      meta: useKo ? '내 사주 한눈에 · A READING' : 'A READING',
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            height: 1.85,
            color: AppColors.ink,
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(text: lead),
            TextSpan(
              text: '— $accentPhrase ',
              style: useKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 15,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    )
                  : GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    ),
            ),
            TextSpan(text: useKo ? '사주.\n\n' : 'reading.\n\n'),
            TextSpan(text: body),
          ],
        ),
      ),
    );
  }
}

// ──────────── CHART ATTRIBUTES (2×2 grid) ────────────

class _ChartAttributesSection extends ConsumerWidget {
  final SajuResult result;
  final bool useKo;
  const _ChartAttributesSection({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final el = result.elements;
    final dm = result.dayPillar.chunGanElement;
    final strength = StrengthService.judge(
      dayMasterElement: dm,
      monthJi: result.monthPillar.jiJi,
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
      dayMaster: result.dayPillar.chunGan,
      yearJi: result.yearPillar.jiJi,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    final gmAreas = GongMangService.affectedAreas(
      dayPillar: result.day60ji,
      yearJi: result.yearPillar.jiJi,
      monthJi: result.monthPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    final gmBranches = GongMangService.forDayPillar(result.day60ji);
    final gyeokguk = GyeokgukService.judge(
      dayMaster: result.dayPillar.chunGan,
      monthJi: result.monthPillar.jiJi,
    );
    final yongsin = YongsinService.judge(
      dayMasterElement: dm,
      strengthLabel: strength.label,
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
    );
    String elKo(String e) =>
        {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'}[e] ?? e;
    String areaKo(String a) =>
        {'year': '년', 'month': '월', 'day': '일', 'hour': '시'}[a] ?? a;

    final hanForFormat = gyeokguk.name.split(' ').first;
    final koForFormat = gyeokguk.name.contains(' ')
        ? gyeokguk.name.split(' ').sublist(1).join(' ')
        : '';
    final hanForStrength = strength.label.contains('身')
        ? strength.label.split(' ').firstWhere((s) => s.contains('身'),
            orElse: () => strength.label)
        : strength.label;
    final voidValue = useKo
        ? (gmAreas.isEmpty
            ? (useKo ? '없음' : 'NONE')
            : gmBranches.join(' · '))
        : (gmAreas.isEmpty ? 'NONE' : gmBranches.join(' · '));
    final voidKo = useKo
        ? (gmAreas.isEmpty
            ? '균형'
            : gmAreas.map((a) => areaKo(a)).join('·'))
        : '';

    return _SectionFrame(
      background: AppColors.bg,
      meta: useKo ? '핵심 4가지 · CHART ATTRIBUTES' : 'CHART ATTRIBUTES',
      child: _AttributeGrid(rows: [
        [
          _Attribute(
            label: useKo ? '사주 유형' : 'FORMAT',
            subLabel: useKo ? '= 큰 그림' : '',
            han: hanForFormat,
            ko: useKo ? koForFormat : '',
            en: useKo ? '' : gyeokguk.nameEn,
          ),
          _Attribute(
            label: useKo ? '필요한 기운' : 'YONGSIN',
            subLabel: useKo ? '= 보충 추천' : '',
            han: yongsin.yongsin,
            ko: useKo ? elKo(yongsin.yongsin) : '',
            en: useKo ? '' : '',
          ),
        ],
        [
          _Attribute(
            label: useKo ? '기운 세기' : 'STRENGTH',
            subLabel: useKo ? '= 강함/약함' : '',
            han: hanForStrength.length > 4
                ? hanForStrength.substring(0, 2)
                : hanForStrength,
            ko: useKo
                ? (strength.label.contains(' ')
                    ? strength.label.split(' ').last
                    : '')
                : '',
            en: useKo ? '' : strength.labelEn,
          ),
          _Attribute(
            label: useKo ? '비어있는 곳' : 'VOID',
            subLabel: useKo ? '= 깊이의 자리' : '',
            han: voidValue,
            ko: voidKo,
            en: useKo ? '' : '',
            small: voidValue.length > 5,
          ),
        ],
      ]),
    );
  }
}

class _Attribute {
  final String label;
  final String subLabel;
  final String han;
  final String ko;
  final String en;
  final bool small;
  const _Attribute({
    required this.label,
    this.subLabel = '',
    required this.han,
    this.ko = '',
    this.en = '',
    this.small = false,
  });
}

class _AttributeGrid extends StatelessWidget {
  final List<List<_Attribute>> rows;
  const _AttributeGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.line),
          left: BorderSide(color: AppColors.line),
        ),
      ),
      child: Column(
        children: rows.map((r) {
          return IntrinsicHeight(
            child: Row(
              children: r.map((a) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 18),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.line),
                        bottom: BorderSide(color: AppColors.line),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.label,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            letterSpacing: 0.3,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                        if (a.subLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            a.subLabel,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 10,
                              color: AppColors.taupe,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 6,
                          children: [
                            Text(
                              a.han,
                              style: GoogleFonts.notoSerifKr(
                                fontSize: a.small ? 14 : 18,
                                fontWeight: FontWeight.w400,
                                color: AppColors.accent,
                                height: 1.2,
                              ),
                            ),
                            if (a.ko.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  a.ko,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.inkLight,
                                  ),
                                ),
                              ),
                            if (a.en.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  a.en,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.inkLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────── R83 SPRINT 5 — 시간 모름 안내 라벨 (P1-E) ────────────
//
// 시간 모름 사용자가 대운/성향 등 시간 영향 큰 섹션을 봤을 때, "왜 어떤 영역이 흐릿하게
// 느껴지는지" 1줄로 안내해주는 보조 라벨. 본문 widget 자체는 보존 — 라벨만 추가.
//
// 사용자 mandate M5 (한국 MZ 페르소나) + 친근 해요체 + 사주 도메인 어휘 화이트리스트.
class _TimeUnknownNote extends StatelessWidget {
  final String keyId;
  final bool useKo;
  final String text;
  const _TimeUnknownNote({
    required this.keyId,
    required this.useKo,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(keyId),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line, width: 0.5),
      ),
      child: Text(
        text,
        style: useKo
            ? GoogleFonts.notoSansKr(
                fontSize: 12,
                height: 1.5,
                color: AppColors.taupe,
              )
            : GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                color: AppColors.taupe,
              ),
      ),
    );
  }
}

// ──────────── FOUR PILLARS ────────────

class _FourPillarsSection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  // R83 sprint 5 (P1-E) — 시간 모름 처리.
  // true 면 HOUR _PillarCol 영역 Opacity 0.4 + 카드 하단 disclaimer 1줄 mount.
  // false 면 기존 동작 그대로 (5행 골든 1995-10-27 男 17시 sample 영향 0).
  final bool unknownTime;
  const _FourPillarsSection({
    required this.result,
    required this.useKo,
    this.unknownTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final pillars = [
      _PillarCol(label: 'YEAR', pillar: result.yearPillar),
      _PillarCol(label: 'MONTH', pillar: result.monthPillar),
      _PillarCol(label: 'DAY', pillar: result.dayPillar, isDay: true),
      // R83 sprint 5 (P1-E) — 시간 모름 시 HOUR 영역 흐림 처리 (opacity 0.4).
      _PillarCol(
        label: 'HOUR',
        pillar: result.hourPillar,
        dim: unknownTime,
      ),
    ];
    return _SectionFrame(
      background: AppColors.paper,
      meta: useKo ? '네 기둥 · 四 柱' : 'FOUR PILLARS · 四 柱',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: pillars.asMap().entries.map((e) {
              final isLast = e.key == pillars.length - 1;
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: isLast
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.line, width: 0.6),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: e.value,
                ),
              );
            }).toList(),
          ),
          // R83 sprint 5 (P1-E) — 시간 모름 시 시주 미포함 disclaimer + badge.
          if (unknownTime) ...[
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('hour-pillar-unknown-disclaimer'),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(color: AppColors.line, width: 0.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.hourPillarUnknownBadge,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.hourPillarUnknownDisclaimer,
                    style: useKo
                        ? GoogleFonts.notoSansKr(
                            fontSize: 13,
                            height: 1.55,
                            color: AppColors.ink,
                          )
                        : GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.55,
                            color: AppColors.ink,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillarCol extends StatelessWidget {
  final String label;
  final Pillar? pillar;
  final bool isDay;
  // R83 sprint 5 (P1-E) — 시간 모름 시 HOUR 영역 흐림 (opacity 0.4).
  // 데이터 자체 (pillar=null) 는 유지, UI 만 dim — disclaimer 본문에서 의도 설명.
  final bool dim;
  const _PillarCol({
    required this.label,
    required this.pillar,
    this.isDay = false,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNull = pillar == null;
    final color = isDay ? AppColors.accent : AppColors.ink;
    final weight = isDay ? FontWeight.w400 : FontWeight.w300;
    final col = Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isNull ? '—' : pillar!.chunGan,
          style: GoogleFonts.notoSerifKr(
            fontSize: 26,
            fontWeight: weight,
            height: 1.1,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isNull ? '—' : pillar!.jiJi,
          style: GoogleFonts.notoSerifKr(
            fontSize: 26,
            fontWeight: weight,
            height: 1.1,
            color: color,
          ),
        ),
      ],
    );
    // R83 sprint 5 (P1-E) — dim=true 시 Opacity wrapper.
    return dim
        ? Opacity(
            key: const ValueKey('pillar-col-hour-dim'),
            opacity: 0.4,
            child: col,
          )
        : col;
  }
}

// ──────────── THREE STROKES ────────────

class _ThreeStrokesSection extends StatelessWidget {
  final SajuResult result;
  final DeepReading? reading;
  final bool useKo;
  const _ThreeStrokesSection({
    required this.result,
    required this.reading,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = <_Stroke>[
      _Stroke(
        label: l.resultThreeHitPersonalityLabel,
        glyph: '性',
        text: reading?.personalityHook ?? '',
      ),
      _Stroke(
        label: l.resultThreeHitLoveLabel,
        glyph: '緣',
        text: reading?.loveHook ?? '',
      ),
      _Stroke(
        label: l.resultThreeHitTodayLabel,
        glyph: '今',
        text: reading?.todayHook ?? '',
      ),
    ];
    return _SectionFrame(
      background: AppColors.bg,
      meta: useKo ? '세 가지 핵심 · 三 筆' : 'THREE STROKES · 三 筆',
      child: Column(
        children: items.where((i) => i.text.isNotEmpty).map((i) {
          final isLast = i == items.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    i.glyph,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: AppColors.accent,
                      height: 1.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.label.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.taupe,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        i.text,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: AppColors.ink,
                          height: 1.75,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _Stroke {
  final String label;
  final String glyph;
  final String text;
  const _Stroke({required this.label, required this.glyph, required this.text});
}

// ──────────── FOR YOU TODAY ────────────

class _ForYouTodaySection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _ForYouTodaySection({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final p = PersonalizationEngine.buildFor(result);
    final head = useKo ? p.headlineKo : p.headlineEn;
    final body = useKo ? p.bodyKo : p.bodyEn;
    final action = useKo ? p.actionKo : p.actionEn;
    final caution = useKo ? p.cautionKo : p.cautionEn;
    final rows = <(String, String)>[
      (l.personalHeadlineLabel, head),
      (l.personalBodyLabel, body),
      (l.personalActionLabel, action),
      (l.personalCautionLabel, caution),
    ];
    return _SectionFrame(
      background: AppColors.paper,
      meta: l.personalCardTitle.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.line, width: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.value.$1.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.taupe,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.value.$2,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────── FIVE ELEMENTS ────────────

class _FiveElementsSection extends StatelessWidget {
  final SajuResult result;
  final DeepReading? reading;
  final bool useKo;
  const _FiveElementsSection({
    required this.result,
    required this.reading,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final el = result.elements;
    final dom = el.dominant;
    final def = el.deficit;
    final names = useKo
        ? const {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'}
        : const {
            '木': 'Wood', '火': 'Fire', '土': 'Earth', '金': 'Metal', '水': 'Water'
          };
    final rows = [
      ('木', el.wood),
      ('火', el.fire),
      ('土', el.earth),
      ('金', el.metal),
      ('水', el.water),
    ];
    // Round 82 sprint 10 — 외부 reviewer P0 #7 fix.
    // 라벨이 사주 고전 산식처럼 보이지 않도록 헤더 + helper 1줄을 평이 어휘로 갱신.
    // 5행 raw 산출 값 (1995-10-27 男 17시 16/21/17/41/4 등) 보존.
    // 한자 jargon (사용자가 의미 모를 명리학 명사) 사용자 노출 X — "숨은 글자 /
    // 태어난 달 / 뿌리 힘" 평이 풀이만.
    final l = AppL10n.of(context);
    final header = l.resultFiveElements;
    final helper = l.resultFiveElementsHelper;
    return _SectionFrame(
      background: AppColors.bg,
      meta: useKo ? '내 안의 5가지 기운' : 'FIVE ENERGIES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — 평이 한국어 라벨 (사용자 친근 어휘).
          Text(
            header,
            style: GoogleFonts.notoSerifKr(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          // 1줄 helper — "숨은 글자 / 태어난 달 / 뿌리 힘" 평이 풀이.
          Text(
            helper,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              height: 1.7,
              color: AppColors.inkLight,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          ...rows.map((r) => _ElementRow(
                han: r.$1,
                name: names[r.$1]!,
                pct: r.$2,
                isDom: r.$1 == dom,
                isDef: r.$1 == def,
              )),
          if (reading != null && reading!.elementsNote.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.line, width: 0.6)),
              ),
              child: Text(
                reading!.elementsNote,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.inkLight,
                  height: 1.75,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ElementRow extends StatelessWidget {
  final String han;
  final String name;
  final int pct;
  final bool isDom;
  final bool isDef;
  const _ElementRow({
    required this.han,
    required this.name,
    required this.pct,
    required this.isDom,
    required this.isDef,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forElement(han);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              han,
              style: GoogleFonts.notoSerifKr(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: color,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              name.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
                color: AppColors.inkLight,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(height: 2, color: AppColors.line),
                FractionallySizedBox(
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: Container(height: 2, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                if (isDom)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    // Round 77 sprint 7 — 별 텍스트 X. dominant 마커는 작은 사각 dot.
                    child: Container(
                      width: 6,
                      height: 6,
                      color: AppColors.accent,
                    ),
                  )
                else if (isDef)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '·',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.taupe,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Group + Accordion ────────────

class _GroupSection extends StatelessWidget {
  final String groupLabel;
  final Color background;
  final List<Widget> children;
  const _GroupSection({
    required this.groupLabel,
    required this.background,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
            child: Text(
              groupLabel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AccordionRow extends StatefulWidget {
  final String title;
  final String hint;
  final bool locked;
  final Widget child;
  final String? note;
  const _AccordionRow({
    required this.title,
    this.hint = '',
    required this.locked,
    required this.child,
    this.note,
  });

  @override
  State<_AccordionRow> createState() => _AccordionRowState();
}

class _AccordionRowState extends State<_AccordionRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                        if (widget.hint.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.hint,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 11,
                              color: AppColors.taupe,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.locked)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _AesopChip(label: l.resultProLocked),
                    ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        size: 18, color: AppColors.taupe),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.locked) _LockedPlaceholder() else widget.child,
                  if (!widget.locked &&
                      widget.note != null &&
                      widget.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColors.line, width: 0.6)),
                      ),
                      child: Text(
                        widget.note!,
                        style: useKo
                            ? GoogleFonts.notoSerifKr(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w300,
                                color: AppColors.accent,
                                height: 1.75,
                                letterSpacing: 0.2,
                              )
                            : GoogleFonts.cormorantGaramond(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.accent,
                                height: 1.7,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

// Round 82 sprint 7 — first-fold 정리용 collapsible wrapper.
// 사용자 mandate (R82 인수인계 line 14): "너무 뭐가 많아서 한눈에 들어오지도 않고"
// → 큰 섹션을 헤더만 노출된 접힘 상태로 mount, tap 시 child mount.
// 정보 손실 0: 기존 widget 그대로 child 로 mount, widget tree 자체 유지.
class _CollapsibleSection extends StatefulWidget {
  final String label; // 메인 라벨 — letter-spacing UPPERCASE
  final String preview; // 한 줄 미리보기 — 사용자 친근 해요체
  final Color background;
  final Widget child;
  final bool initiallyOpen;

  const _CollapsibleSection({
    required this.label,
    required this.preview,
    required this.background,
    required this.child,
    this.initiallyOpen = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.background,
        border: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.taupe,
                          ),
                        ),
                        if (widget.preview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.preview,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              color: AppColors.ink,
                              height: 1.55,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      size: 20,
                      color: AppColors.taupe,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: widget.child,
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _LockedPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: () => showComingSoonModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.line, width: 0.6),
            bottom: BorderSide(color: AppColors.line, width: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.resultUnlockHint,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.75,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.resultProLocked.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────── Gyeokguk / Yongsin / Strength / GongMang / Shinsa / 12 Unsung / Hapchung ────────────

class _GyeokgukBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _GyeokgukBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final g = GyeokgukService.judge(
      dayMaster: result.dayPillar.chunGan,
      monthJi: result.monthPillar.jiJi,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          useKo ? g.name : g.nameEn,
          style: GoogleFonts.notoSerifKr(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.accent,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          useKo ? g.desc : g.descEn,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        _FootnoteItalic(
          useKo
              ? '격국(格局) — 사주의 구조 분류. 월지(月支) 본기가 일간 기준 어떤 십신인지로 결정. 명리학의 가장 핵심 분석.'
              : 'Gyeokguk — chart structure classification. Determined by the month branch\'s core stem and its ten-god relation to day master.',
        ),
      ],
    );
  }
}

class _YongsinBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _YongsinBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final el = result.elements;
    final dm = result.dayPillar.chunGanElement;
    final s = StrengthService.judge(
      dayMasterElement: dm,
      monthJi: result.monthPillar.jiJi,
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
      dayMaster: result.dayPillar.chunGan,
      yearJi: result.yearPillar.jiJi,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    // Round 83 sprint 6 — monthBranch 도 전달해서 조후용신 같이 산출.
    final y = YongsinService.judge(
      dayMasterElement: dm,
      strengthLabel: s.label,
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
      monthBranch: result.monthPillar.jiJi,
    );
    // 격국용신 산출 (Round 83 sprint 6).
    final gyeokgukYs = YongsinService.gyeokgukYongsinFor(
      dayMaster: result.dayPillar.chunGan,
      dayMasterElement: dm,
      monthJi: result.monthPillar.jiJi,
    );
    // 3 종 신뢰도 분석.
    final conf = YongsinService.confidence(
      eokbu: y.yongsin,
      chowhu: y.chowhuYongsin,
      gyeokguk: gyeokgukYs,
    );
    final elKo = YongsinService.elementKo;
    final dash = '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1차 용신 헤더 (= 억부용신, 기존 시그니처 보존).
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              y.yongsin,
              style: GoogleFonts.notoSerifKr(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                color: AppColors.accent,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                useKo ? elKo(y.yongsin) : 'YONGSIN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: AppColors.inkLight,
                ),
              ),
            ),
            const Spacer(),
            _AesopChip(
              label: useKo ? '희신 ${elKo(y.huisin)}' : 'HUISIN ${y.huisin}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 신뢰도 라벨 chip.
        Align(
          alignment: Alignment.centerLeft,
          child: _AesopChip(
            label: useKo ? conf.labelKo : conf.labelEn,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          useKo ? conf.helperKo : conf.helperEn,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.inkLight,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 18),
        // ── 3 종 분리 표시 ──
        Text(
          useKo ? '세 기준의 용신 · THREE STREAMS' : 'THREE STREAMS',
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 12),
        _YongsinSplitRow(
          labelKo: '억부용신 (강약 기준)',
          labelEn: 'Eokbu (strength)',
          element: y.yongsin,
          helperKo: '일간 강약을 보고 모자란 쪽을 채우는 용신이에요.',
          helperEn: 'Fills what the day-master needs by strength.',
          useKo: useKo,
          dash: dash,
        ),
        const SizedBox(height: 10),
        _YongsinSplitRow(
          labelKo: '조후용신 (계절 기준)',
          labelEn: 'Johu (season)',
          element: y.chowhuYongsin,
          helperKo: '계절을 보고 추우면 따뜻하게, 더우면 식혀주는 용신이에요.',
          helperEn: 'Warms a cold chart, cools a hot one by season.',
          useKo: useKo,
          dash: dash,
        ),
        const SizedBox(height: 10),
        _YongsinSplitRow(
          labelKo: '격국용신 (격국 보좌 기준)',
          labelEn: 'Gyeokguk (format)',
          element: gyeokgukYs,
          helperKo: '사주 격국을 받쳐주는 보좌 오행이에요.',
          helperEn: 'Supports the chart format as backup.',
          useKo: useKo,
          dash: dash,
        ),
        const SizedBox(height: 18),
        // 기존 강약 reason (요약).
        Text(
          y.reason,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          useKo ? '실생활 보충 · DAILY-LIFE SUPPORT' : 'DAILY-LIFE SUPPORT',
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          YongsinService.compensationGuide(y.yongsin, ko: useKo),
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: AppColors.inkLight,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 14),
        _FootnoteItalic(useKo
            ? '용신(用神) — 사주에서 가장 필요한 오행. 일간 강약 + 5행 균형 기반. 억부 / 조후 / 격국 세 기준으로 같이 봐요.'
            : 'Yongsin — the most needed element. Based on day master strength and 5-element balance. Read by three streams: eokbu / johu / gyeokguk.'),
      ],
    );
  }
}

/// Round 83 sprint 6 — 용신 3 종 분리 row.
///
/// 한 라벨 + 한 오행 (없으면 dash) + 1줄 친근 풀이.
class _YongsinSplitRow extends StatelessWidget {
  final String labelKo;
  final String labelEn;
  final String? element;
  final String helperKo;
  final String helperEn;
  final bool useKo;
  final String dash;
  const _YongsinSplitRow({
    required this.labelKo,
    required this.labelEn,
    required this.element,
    required this.helperKo,
    required this.helperEn,
    required this.useKo,
    required this.dash,
  });

  @override
  Widget build(BuildContext context) {
    final el = element;
    final elKo = YongsinService.elementKo;
    final hasEl = el != null && el.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                useKo ? labelKo : labelEn,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              hasEl ? el : dash,
              style: GoogleFonts.notoSerifKr(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: hasEl ? AppColors.accent : AppColors.taupe,
                height: 1.0,
              ),
            ),
            if (hasEl && useKo) ...[
              const SizedBox(width: 8),
              Text(
                elKo(el),
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.inkLight,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hasEl
              ? (useKo ? helperKo : helperEn)
              : (useKo
                  ? '이 기준의 정보가 부족해요.'
                  : 'This stream lacks data.'),
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            color: AppColors.inkLight,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _StrengthBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _StrengthBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final dm = result.dayPillar.chunGanElement;
    final el = result.elements;
    final j = StrengthService.judge(
      dayMasterElement: dm,
      monthJi: result.monthPillar.jiJi,
      wood: el.wood, fire: el.fire, earth: el.earth,
      metal: el.metal, water: el.water,
      dayMaster: result.dayPillar.chunGan,
      yearJi: result.yearPillar.jiJi,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              useKo ? j.label : j.labelEn,
              style: GoogleFonts.notoSerifKr(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppColors.accent,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${j.score}/100',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: AppColors.inkLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          decoration: BoxDecoration(color: AppColors.line),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (j.score / 100).clamp(0.0, 1.0),
            child: Container(color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          StrengthService.guide(j.label, ko: useKo),
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        _FootnoteItalic(useKo
            ? '신왕/신약 — 일간(日干)이 사주 원국에서 강한지 약한지 판단. 인성·비겁이 강하면 신왕, 식상·재성·관성이 강하면 신약.'
            : 'Day-master strength balance. Resource + Peer = supports; Output + Wealth + Officer = drains.'),
      ],
    );
  }
}

class _GongMangBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _GongMangBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final gm = GongMangService.forDayPillar(result.day60ji);
    final areas = GongMangService.affectedAreas(
      dayPillar: result.day60ji,
      yearJi: result.yearPillar.jiJi,
      monthJi: result.monthPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    final interpretation = GongMangService.interpretation(areas, ko: useKo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gm.join(' · '),
          style: GoogleFonts.notoSerifKr(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: AppColors.accent,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          interpretation,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 14),
        _FootnoteItalic(useKo
            ? '공망(空亡) — 60갑자 한 순(旬, 10일)에서 천간 10개에 매칭되지 않는 지지 2개. 비어 보이는 결은 깊이로 전환됩니다.'
            : 'Void (空亡): 2 branches per 10-day cycle that don\'t pair with a stem. The felt absence becomes depth.'),
      ],
    );
  }
}

class _ShinsaBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _ShinsaBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final activations = ShinsaService.analyzeChart(
      yearJi: result.yearPillar.jiJi,
      monthJi: result.monthPillar.jiJi,
      dayChunGan: result.dayPillar.chunGan,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    if (activations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo
                ? '원국에 강한 신살 활성화 없음 — 사주 결이 균형 잡혀 있어 부수 요소에 휘둘리지 않습니다.'
                : 'No strong shinsa activation — your chart is balanced.',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.8,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activations.entries.toList().asMap().entries.map((idx) {
          final entry = idx.value;
          final isLast = idx.key == activations.length - 1;
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.line, width: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    entry.key,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    ShinsaService.interpretation(entry.key, entry.value,
                            ko: useKo)
                        .replaceFirst(RegExp(r'^[^—]*— '), ''),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        _FootnoteItalic(useKo
            ? '신살(神煞) — 사주 원국이 특정 패턴과 일치할 때 활성화되는 명리학 부수 요소.'
            : 'Shinsa: auxiliary myeongli markers activated when chart branches match certain stem/branch patterns.'),
      ],
    );
  }
}

class _TwelveUnsungBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _TwelveUnsungBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final stages = TwelveUnsungService.chartStages(
      dayChunGan: result.dayPillar.chunGan,
      yearJi: result.yearPillar.jiJi,
      monthJi: result.monthPillar.jiJi,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    String labelKo(String area) => {
          'year': '년주',
          'month': '월주',
          'day': '일주',
          'hour': '시주',
        }[area] ??
        area;
    String labelEn(String area) =>
        {'year': 'YEAR', 'month': 'MONTH', 'day': 'DAY', 'hour': 'HOUR'}[area] ??
        area;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...stages.entries.toList().asMap().entries.map((idx) {
          final entry = idx.value;
          final isLast = idx.key == stages.length - 1;
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.line, width: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    useKo ? labelKo(entry.key) : labelEn(entry.key),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    useKo
                        ? entry.value
                        : (TwelveUnsungService.stagesEn[
                            TwelveUnsungService.stages.indexOf(entry.value)]),
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    TwelveUnsungService.interpretation(entry.value, ko: useKo),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12.5,
                      color: AppColors.ink,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        _FootnoteItalic(useKo
            ? '12 운성(運星) — 일간이 12지지에 따라 가지는 일생 12 단계. 각 기둥 지지의 강약을 보여줍니다.'
            : '12 Unsung: life-cycle stages your day stem moves through across the 12 branches.'),
      ],
    );
  }
}

class _HapchungBlock extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _HapchungBlock({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final r = HapchungService.analyzeChart(
      yearGan: result.yearPillar.chunGan,
      yearJi: result.yearPillar.jiJi,
      monthGan: result.monthPillar.chunGan,
      monthJi: result.monthPillar.jiJi,
      dayGan: result.dayPillar.chunGan,
      dayJi: result.dayPillar.jiJi,
      hourGan: result.hourPillar?.chunGan,
      hourJi: result.hourPillar?.jiJi,
    );
    String areaKo(String a) =>
        {'year': '년주', 'month': '월주', 'day': '일주', 'hour': '시주'}[a] ?? a;
    String areaEn(String a) =>
        {'year': 'YEAR', 'month': 'MONTH', 'day': 'DAY', 'hour': 'HOUR'}[a] ??
        a;
    final samhap = HapchungService.findSamhap(
      yearJi: result.yearPillar.jiJi,
      monthJi: result.monthPillar.jiJi,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    final banghap = HapchungService.findBanghap(
      yearJi: result.yearPillar.jiJi,
      monthJi: result.monthPillar.jiJi,
      dayJi: result.dayPillar.jiJi,
      hourJi: result.hourPillar?.jiJi,
    );
    if (r.hap.isEmpty &&
        r.chung.isEmpty &&
        samhap.isEmpty &&
        banghap.isEmpty) {
      return Text(
        useKo
            ? '원국에 강한 합·충 관계 없음 — 사주 흐름이 직선적이고 안정적입니다.'
            : 'No strong hap (合) or chung (沖) — your chart flows linearly and steadily.',
        style: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: AppColors.ink,
          height: 1.8,
        ),
      );
    }
    Widget sub(String label, String? note, List<Widget> lines) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
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
            ...lines,
            if (note != null) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: useKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: AppColors.accent,
                        height: 1.7,
                        letterSpacing: 0.2,
                      )
                    : GoogleFonts.cormorantGaramond(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.accent,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.hap.isNotEmpty)
          sub(
            useKo ? '합(合) — 결합·조화' : 'HAP — ALLIANCE',
            HapchungService.hapInterpretation(ko: useKo),
            [
              for (final h in r.hap)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    useKo
                        ? '· ${areaKo(h.area1)} ↔ ${areaKo(h.area2)}${h.element.isEmpty ? "" : " (오행 화: ${h.element})"}'
                        : '· ${areaEn(h.area1)} ↔ ${areaEn(h.area2)}${h.element.isEmpty ? "" : " (element: ${h.element})"}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                ),
            ],
          ),
        if (samhap.isNotEmpty)
          sub(
            useKo ? '삼합(三合) — 3지지 결합' : 'SAMHAP — 3-BRANCH UNITY',
            useKo
                ? '삼합 — 3지지가 한 오행으로 강하게 결합. 가장 큰 합.'
                : 'Samhap — three branches lock into one element. The biggest combination.',
            [
              for (final s in samhap)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    useKo
                        ? '· ${s.areas.map((a) => areaKo(a)).join(" + ")} → ${s.element}'
                        : '· ${s.areas.map((a) => areaEn(a)).join(" + ")} → ${s.element}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                ),
            ],
          ),
        if (banghap.isNotEmpty)
          sub(
            useKo ? '방합(方合) — 계절 3지지' : 'BANGHAP — SEASONAL UNITY',
            useKo
                ? '방합 — 한 계절의 3지지가 한 오행으로 모임. 계절 기운이 강하게 작동.'
                : 'Banghap — three branches of one season unite into one element.',
            [
              for (final b in banghap)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    useKo
                        ? '· ${b.areas.map((a) => areaKo(a)).join(" + ")} → ${b.element}'
                        : '· ${b.areas.map((a) => areaEn(a)).join(" + ")} → ${b.element}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                ),
            ],
          ),
        if (r.chung.isNotEmpty)
          sub(
            useKo ? '충(沖) — 갈등·변동' : 'CHUNG — FRICTION',
            HapchungService.chungInterpretation(ko: useKo),
            [
              for (final c in r.chung)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    useKo
                        ? '· ${areaKo(c.area1)} ↔ ${areaKo(c.area2)}'
                        : '· ${areaEn(c.area1)} ↔ ${areaEn(c.area2)}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ──────────── Ten Gods table ────────────

class _TenGodsTable extends StatelessWidget {
  final List<TenGodRow> rows;
  final bool useKo;
  const _TenGodsTable({required this.rows, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.inter(
      fontSize: 9,
      letterSpacing: 3,
      fontWeight: FontWeight.w500,
      color: AppColors.taupe,
    );
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child:
                        Text(useKo ? 'PILLAR' : 'PILLAR', style: headerStyle)),
                Expanded(
                    flex: 3,
                    child:
                        Text(useKo ? 'STEM' : 'STEM', style: headerStyle)),
                Expanded(
                    flex: 3,
                    child:
                        Text(useKo ? 'BRANCH' : 'BRANCH', style: headerStyle)),
              ],
            ),
          ),
          ...rows.map((row) => Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.line, width: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _posLabel(row.position, useKo),
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 14,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.chunGanGod == null
                            ? '—'
                            : (useKo ? row.chunGanGod!.ko : row.chunGanGod!.en),
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.jiJiGod == null
                            ? '—'
                            : (useKo ? row.jiJiGod!.ko : row.jiJiGod!.en),
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _posLabel(String pos, bool ko) {
    if (ko) {
      switch (pos) {
        case 'year': return '년주';
        case 'month': return '월주';
        case 'day': return '일주';
        case 'hour': return '시주';
      }
    }
    switch (pos) {
      case 'year': return 'YEAR';
      case 'month': return 'MONTH';
      case 'day': return 'DAY';
      case 'hour': return 'HOUR';
    }
    return pos;
  }
}

// ──────────── Life Themes ────────────

class _LifeThemesBlock extends StatelessWidget {
  final DeepReading? reading;
  final bool isPro;
  const _LifeThemesBlock({required this.reading, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final themes = <_ThemeItem>[
      _ThemeItem(l.resultThemeCareer, 'CAREER', reading?.career ?? '', false),
      _ThemeItem(l.resultThemeWealth, 'WEALTH', reading?.wealth ?? '', false),
      _ThemeItem(l.resultThemeLove, 'LOVE', reading?.love ?? '', false),
      _ThemeItem(l.resultThemeHealth, 'HEALTH', reading?.health ?? '', !isPro),
      _ThemeItem(l.resultThemeFamily, 'FAMILY', reading?.family ?? '', !isPro),
      _ThemeItem(l.resultThemeFame, 'FAME', reading?.fame ?? '', !isPro),
    ];
    return Column(
      children: themes.asMap().entries.map((e) {
        final isLast = e.key == themes.length - 1;
        return _ThemeRow(item: e.value, isLast: isLast);
      }).toList(),
    );
  }
}

class _ThemeItem {
  final String titleLocalized;
  final String labelEn;
  final String text;
  final bool locked;
  const _ThemeItem(this.titleLocalized, this.labelEn, this.text, this.locked);
}

class _ThemeRow extends StatelessWidget {
  final _ThemeItem item;
  final bool isLast;
  const _ThemeRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.line, width: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.labelEn,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (item.locked)
                _AesopChip(label: l.resultProLocked),
            ],
          ),
          const SizedBox(height: 10),
          if (item.locked)
            InkWell(
              onTap: () => showComingSoonModal(context),
              child: Text(
                l.resultUnlockHint,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.taupe,
                  height: 1.7,
                ),
              ),
            )
          else
            Text(
              item.text,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.8,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────── Lucky ────────────

class _LuckyBlock extends StatelessWidget {
  final DeepReading? reading;
  final bool useKo;
  const _LuckyBlock({required this.reading, required this.useKo});

  @override
  Widget build(BuildContext context) {
    if (reading == null) return const SizedBox.shrink();
    final rows = [
      (useKo ? 'COLOR · 색' : 'COLOR', reading!.luckyColor),
      (useKo ? 'NUMBER · 숫자' : 'NUMBER', '${reading!.luckyNumber}'),
      (useKo ? 'DIRECTION · 방향' : 'DIRECTION', reading!.luckyDirection),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Column(
        children: rows.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.line, width: 0.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.$1,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                ),
                Text(
                  r.$2,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────── Calculation basis ────────────

class _CalculationBasisBody extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _CalculationBasisBody({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final rows = [
      (l.resultBasisManseryeok, l.resultBasisManseryeokVal),
      (l.resultBasisYearBoundary, l.resultBasisYearBoundaryVal),
      (l.resultBasisDayBoundary, l.resultBasisDayBoundaryVal),
      (l.resultBasisTrueSun, l.resultBasisTrueSunOn),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Column(
        children: rows.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.line, width: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    r.$1.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.$2,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12.5,
                      color: AppColors.ink,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────── Pro hooks ────────────

class _ProHooksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final hooks = <(String, String, String, VoidCallback)>[
      (
        l.resultProHookYearLoveTitle,
        l.resultProHookYearLoveTeaser,
        '愛',
        () => showComingSoonModal(context),
      ),
      (
        l.resultProHookCompatTitle,
        l.resultProHookCompatTeaser,
        '緣',
        () => context.go('/reports/compatibility'),
      ),
      (
        l.resultProHookDatesTitle,
        l.resultProHookDatesTeaser,
        '日',
        () => context.go('/reports/date-picking'),
      ),
    ];
    return _SectionFrame(
      background: AppColors.bg,
      meta: l.resultProHookHeader.toUpperCase(),
      child: Column(
        children: hooks.asMap().entries.map((e) {
          final isLast = e.key == hooks.length - 1;
          final h = e.value;
          return InkWell(
            onTap: h.$4,
            child: Container(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.line, width: 0.6),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      h.$3,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: AppColors.accent,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.$1,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          h.$2,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12.5,
                            color: AppColors.inkLight,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '→',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: AppColors.taupe,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────── CTAs ────────────

class _CtaStack extends StatelessWidget {
  final bool isPro;
  final VoidCallback onShare;
  const _CtaStack({required this.isPro, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Column(
      children: [
        if (!isPro)
          InkWell(
            onTap: () => showComingSoonModal(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26),
              alignment: Alignment.center,
              color: AppColors.ink,
              child: Text(
                l.resultUnlockFull.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bg,
                ),
              ),
            ),
          ),
        InkWell(
          onTap: () => context.go('/home'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border:
                  Border(bottom: BorderSide(color: AppColors.line, width: 1)),
            ),
            child: Text(
              l.resultContinueDaily.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        InkWell(
          onTap: onShare,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            alignment: Alignment.center,
            color: AppColors.bg,
            child: Text(
              // Round 77 sprint 7 — 상단 ShareHeroBar 가 1차 CTA 이므로 하단은 "다시 공유" 톤.
              l.resultShareAgain.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Round 77 sprint 7 — hero 직후 친구 공유 CTA (first-fold).
/// 좌측 한국어 라벨 + sub (한자 letter-spacing) / 우측 화살표.
class _ShareHeroBar extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareHeroBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.resultShareHeroLabel,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.resultShareHeroSub,
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
            Text(
              '→',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.taupe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────── Footer ────────────

class _AesopFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      alignment: Alignment.center,
      child: Text(
        'KASI · 입춘 · 12절 · 진태양시 · 균시차',
        style: GoogleFonts.inter(
          fontSize: 9,
          letterSpacing: 3,
          fontWeight: FontWeight.w400,
          color: AppColors.taupe,
        ),
      ),
    );
  }
}

// ──────────── Footnote italic helper ────────────

class _FootnoteItalic extends StatelessWidget {
  final String text;
  const _FootnoteItalic(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSansKr(
          fontSize: 11.5,
          color: AppColors.taupe,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ──────────── Share chart ────────────

Future<void> _shareChart(
    BuildContext context, SajuResult result, bool useKo) async {
  final reading = useKo ? result.deepKo : result.deepEn;
  final oneLine = reading?.oneLineYouAre ?? '';
  final personality = reading?.personalityHook ?? '';
  final today = reading?.todayHook ?? '';
  final text = useKo
      ? '''Pillar Seer — 내 사주

$oneLine 사람.
일주 ${result.dayPillar.pairKorean} · ${result.dayPillar.pairKoreanMeaning} · ${result.day60ji}

성격 — $personality
오늘 — $today

Pillar Seer 앱에서 정밀 풀이를 확인하세요.'''
      : '''Pillar Seer — My Saju

A $oneLine person.
Day Pillar: ${result.dayMasterName} · ${result.day60ji}

Personality — $personality
Today — $today

Open Pillar Seer for the full reading.''';
  try {
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final l = AppL10n.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.shareCardCopied),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ));
  }
}

// ──────────── 2.5 TWIN-LENS — 깊이 풀이에서도 같이 잡힌 결 (차별점) ────────────

class _CrossmatchSection extends StatelessWidget {
  final List<CrossMatch> matches;
  final bool useKo;
  const _CrossmatchSection({required this.matches, required this.useKo});

  @override
  Widget build(BuildContext context) {
    // Round 82 sprint 4 — 사용자 verbatim "깊게봐도 다시 잡힌 핵심 이것도 부자연스럽고"
    // 직발 → headline + intro 친근 어휘 재작성. widget tree 미변경 / 산식 미변경 / R69 lock 보존.
    final headline = useKo
        ? '두 번 봐도 같이 잡힌 강점'
        : 'WHAT THE DEEP READ CONFIRMS';
    final intro = useKo
        ? '사주를 한 번 더 들여다봐도 똑같이 잡힌 부분이에요.\n그래서 제일 단단하게 믿고 가도 되는 곳이에요.'
        : 'Even when read at a deeper layer, these points stay the same. '
            'The most trustworthy lines in your chart.';
    return _SectionFrame(
      background: AppColors.paper,
      meta: useKo ? '깊은 포인트 · DEEP POINT' : 'DEEP POINT · 深 點',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // accent star + headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _TwinStar(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  headline,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    letterSpacing: -0.2,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Text(
            intro,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              height: 1.75,
              color: AppColors.inkLight,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 22),
          // 각 매칭 항목
          for (var i = 0; i < matches.length; i++) ...[
            _CrossmatchTile(
              match: matches[i],
              useKo: useKo,
              index: i + 1,
            ),
            if (i < matches.length - 1)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 18),
                height: 1,
                color: AppColors.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _TwinStar extends StatelessWidget {
  const _TwinStar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent, width: 1),
        color: AppColors.bg,
      ),
      alignment: Alignment.center,
      child: Text(
        '✦',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 18,
          color: AppColors.accent,
          height: 1.0,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _CrossmatchTile extends StatelessWidget {
  final CrossMatch match;
  final bool useKo;
  final int index;
  const _CrossmatchTile({
    required this.match,
    required this.useKo,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주제 라벨 (작은 UPPERCASE) — Round 73: topicEn 사용 (한국어 topic 우회)
        Row(
          children: [
            Text(
              index.toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 14, height: 1, color: AppColors.line),
            const SizedBox(width: 10),
            Text(
              useKo ? match.topic : match.topicEn,
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    )
                  : GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 메인 결론 — Round 73: useKo 분기
        Text(
          match.combinedFor(useKo: useKo),
          style: useKo
              ? GoogleFonts.notoSerifKr(
                  fontSize: 16.5,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                  color: AppColors.ink,
                )
              : GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                  color: AppColors.ink,
                ),
        ),
        const SizedBox(height: 12),
        // 두 풀이 깊이 근거 — 2-row layout (Round 73: useKo 분기)
        _TwinEvidenceRow(
          labelKo: '기본 흐름',
          labelEn: 'BASE',
          body: match.sajuSideFor(useKo: useKo),
          useKo: useKo,
        ),
        const SizedBox(height: 6),
        _TwinEvidenceRow(
          labelKo: '깊은 흐름',
          labelEn: 'DEEP',
          body: match.ziweiSideFor(useKo: useKo),
          useKo: useKo,
        ),
      ],
    );
  }
}

class _TwinEvidenceRow extends StatelessWidget {
  final String labelKo;
  final String labelEn;
  final String body;
  final bool useKo;
  const _TwinEvidenceRow({
    required this.labelKo,
    required this.labelEn,
    required this.body,
    this.useKo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            labelEn,
            style: GoogleFonts.inter(
              fontSize: 8,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ),
        Expanded(
          child: Text(
            body,
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    height: 1.65,
                    color: AppColors.inkLight,
                  )
                : GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.inkLight,
                  ),
          ),
        ),
      ],
    );
  }
}

// ──────────── 7.5 인생 12 영역 풀이 그룹 (accordion) ────────────

class _ZiweiPalaceGroup extends StatelessWidget {
  final ZiweiResult ziwei;
  final bool useKo;
  // Round 82 sprint 5 — 12 결 풀이 카드의 "도와주는 흐름" / "살짝 걸리는 흐름"
  // 라벨 옆 helper (= 십신/용신/신살 anchor + 1줄 설명) wire 용 source.
  // 사용자 mandate (R82 인수인계 line 14): support/caution row 옆에 사주 근거가
  // 안 나오고 설명이 약하다는 사용자 지적.
  final SajuResult sajuResult;
  const _ZiweiPalaceGroup({
    required this.ziwei,
    required this.useKo,
    required this.sajuResult,
  });

  @override
  Widget build(BuildContext context) {
    // SajuContext 1차 source — R78 4단계 chain 보존 (재계산 0).
    final ctx = SajuContext.from(sajuResult);
    // gungKo (내부 키) → 사용자 노출용 우회 라벨.
    // 내부 키는 그대로 유지하되 화면에는 우회 표현만 노출.
    final labels = useKo
        ? const {
            '명궁': '나의 중심',
            '형제궁': '친구·동료',
            '부처궁': '연애·결혼',
            '자녀궁': '창작·후배',
            '재백궁': '돈 흐름',
            '질액궁': '건강·체질',
            '천이궁': '바깥 활동',
            '노복궁': '사람 네트워크',
            '관록궁': '일·진로',
            '전택궁': '사는 공간',
            '복덕궁': '마음·취향',
            '부모궁': '어른·윗사람',
          }
        : const {
            '명궁': 'Core nature',
            '형제궁': 'Friends & peers',
            '부처궁': 'Love & partner',
            '자녀궁': 'Creation & juniors',
            '재백궁': 'Money',
            '질액궁': 'Health & body',
            '천이궁': 'Outside world',
            '노복궁': 'Network',
            '관록궁': 'Work & purpose',
            '전택궁': 'Home space',
            '복덕궁': 'Inner peace',
            '부모궁': 'Elders & parents',
          };
    final subtitles = useKo
        ? const {
            '명궁': '나는 어떤 사람',
            '형제궁': '형제·친구·동료',
            '부처궁': '연애·결혼 인연',
            '자녀궁': '자녀·창작·후배',
            '재백궁': '돈 들어오는 방식',
            '질액궁': '건강·체질',
            '천이궁': '바깥 활동·이동·해외운',
            '노복궁': '주변 사람·인맥',
            '관록궁': '꿈·진로·하고 싶은 일',
            '전택궁': '집·내 방·사는 환경',
            '복덕궁': '마음·취향·힐링',
            '부모궁': '부모·윗사람',
          }
        : const {
            '명궁': 'Self · core nature',
            '형제궁': 'Siblings · peers',
            '부처궁': 'Marriage · love',
            '자녀궁': 'Children · creation',
            '재백궁': 'Wealth · money',
            '질액궁': 'Health · body',
            '천이궁': 'Travel · movement',
            '노복궁': 'Subordinates · network',
            '관록궁': 'Career · status',
            '전택궁': 'Home · property',
            '복덕궁': 'Inner life · pleasure',
            '부모궁': 'Parents · elders',
          };
    return _GroupSection(
      groupLabel: useKo
          ? '삶의 12가지 결 풀이'
          : 'LIFE AREAS',
      background: AppColors.paper,
      children: [
        // 헤더 — 중심 결 / 바깥 결 + 본성 자리 / 활동 자리
        _ZiweiHeader(ziwei: ziwei, useKo: useKo),
        for (final p in ziwei.by12Gung)
          _AccordionRow(
            title: useKo
                ? '${labels[p.gungKo] ?? ''} · ${subtitles[p.gungKo] ?? ''}'
                    .toUpperCase()
                : '${(labels[p.gungKo] ?? '').toUpperCase()} · ${subtitles[p.gungKo] ?? ''}',
            hint: useKo
                ? '${p.branchKo}(${p.branchAnimalKo}) 결'
                : '${p.branchEn.toUpperCase()} branch',
            locked: false,
            child: _ZiweiPalaceBlock(
              palace: p,
              useKo: useKo,
              sajuContext: ctx,
            ),
          ),
      ],
    );
  }
}

class _ZiweiHeader extends StatelessWidget {
  final ZiweiResult ziwei;
  final bool useKo;
  const _ZiweiHeader({required this.ziwei, required this.useKo});

  // 중심 흐름 / 바깥 흐름 — 별 이름 노출 X, 풀이 한 줄만.
  static const Map<String, String> _coreReadKo = {
    'lucun': '안정과 재물 기질',
    'tianji': '머리 빠른 분석 기질',
    'wenchang': '글·공부 재능 기질',
    'tianxiang': '균형 잡힌 중재 기질',
    'tianliang': '신중한 어른 기질',
    'ziwei': '리더십 카리스마 기질',
    'wuqu': '단단한 추진 기질',
    'pojun': '변화를 만드는 기질',
    'lianzhen': '원칙·정의감 기질',
    'taiyang': '환한 적극성 기질',
    'tanlang': '다재다능한 매력 기질',
    'jumen': '말로 끄는 힘 기질',
    'tianfu': '안정감 있는 든든 기질',
    'taiyin': '섬세한 감성 기질',
    'tiantong': '다정한 분위기 기질',
    'qisha': '결단력 강한 추진 기질',
  };

  static const Map<String, String> _coreReadEn = {
    'lucun': 'Stable & wealthy',
    'tianji': 'Sharp analyst',
    'wenchang': 'Words & study',
    'tianxiang': 'Balanced mediator',
    'tianliang': 'Wise elder',
    'ziwei': 'Leader presence',
    'wuqu': 'Solid drive',
    'pojun': 'Change maker',
    'lianzhen': 'Principled justice',
    'taiyang': 'Bright energy',
    'tanlang': 'Versatile charm',
    'jumen': 'Voice that moves',
    'tianfu': 'Steady & dependable',
    'taiyin': 'Gentle sensitivity',
    'tiantong': 'Warm presence',
    'qisha': 'Bold decisive drive',
  };

  String _coreOf(String key) =>
      (useKo ? _coreReadKo[key] : _coreReadEn[key]) ??
      (useKo ? '본인만의 결' : 'Unique signature');

  String _selfHeader(ZiweiPalace p) {
    // 외부 노출에서 "명궁"/"신궁" 흔적 제거 → 12지지(자/축/...) 결만.
    final selfLabel = useKo ? '결' : 'BRANCH';
    if (useKo) {
      return '${p.branchKo}(${p.branchAnimalKo}) $selfLabel';
    }
    return '${p.branchEn.toUpperCase()} $selfLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo
                ? '만세력과 태어난 시간을 같이 보고 풀어낸, 삶의 12가지 결이에요.'
                : 'A 12-area life reading drawn from the classical lunar almanac and hour pillar.',
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              height: 1.75,
              color: AppColors.inkLight,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeaderCell(
                  label: useKo ? '중심 기질' : 'CORE READ',
                  value: _coreOf(ziwei.mingZhuKey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderCell(
                  label: useKo ? '바깥 기질' : 'OUTER READ',
                  value: _coreOf(ziwei.shenZhuKey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeaderCell(
                  label: useKo ? '나의 중심' : 'SELF',
                  value: _selfHeader(ziwei.mingPalace),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderCell(
                  label: useKo ? '활동 결' : 'BODY',
                  value: _selfHeader(ziwei.shenPalace),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 8,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSerifKr(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.3,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZiweiPalaceBlock extends StatelessWidget {
  final ZiweiPalace palace;
  final bool useKo;
  // Round 82 sprint 5 — 사주 anchor (십신/용신/신살) 기반 1줄 helper wire.
  final SajuContext sajuContext;
  const _ZiweiPalaceBlock({
    required this.palace,
    required this.useKo,
    required this.sajuContext,
  });

  @override
  Widget build(BuildContext context) {
    // Round 82 sprint 5 — 영역별 사주 anchor 결정. palace.luckyStars/badStars 의
    // nameKo (자미두수 별 이름) 는 절대 노출 X — length 만 service 에 전달 (R70 mandate).
    final anchorPair = PalaceHelperAnchorService.resolve(
      gungKo: palace.gungKo,
      ctx: sajuContext,
      useKo: useKo,
      luckyCount: palace.luckyStars.length,
      badCount: palace.badStars.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 핵심 결 풀이 — 별 이름 노출 X, 풀이 한 줄만 나열.
        if (palace.majorStars.isNotEmpty) ...[
          for (final s in palace.majorStars)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 10),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.oneLineKo,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        height: 1.8,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              useKo
                  ? '이 자리는 직접 드러난 사주가 약해서, 연결된 자리까지 같이 봐요.'
                  : 'This area is open — read the opposing area as proxy.',
              style: GoogleFonts.notoSansKr(
                fontSize: 13.5,
                height: 1.8,
                color: AppColors.inkLight,
              ),
            ),
          ),
        // Round 82 sprint 5 — 도와주는 흐름 / 살짝 걸리는 흐름 라벨 옆 사주 anchor
        // (십신/용신/신살) + 1줄 helper. palace.luckyStars/badStars 의 length 만 사용.
        if (palace.luckyStars.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SupportSummaryRow(
            labelKo: '도와주는 흐름',
            labelEn: 'Support',
            countKo: '받쳐주는 단서 ${palace.luckyStars.length}가지',
            countEn:
                '${palace.luckyStars.length} supportive cue${palace.luckyStars.length == 1 ? '' : 's'}',
            anchorKo: anchorPair.support.anchorLabelKo,
            anchorEn: anchorPair.support.anchorLabelEn,
            helperKo: anchorPair.support.helperKo,
            helperEn: anchorPair.support.helperEn,
            color: AppColors.accent,
            useKo: useKo,
          ),
        ],
        if (palace.badStars.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SupportSummaryRow(
            labelKo: '살짝 걸리는 흐름',
            labelEn: 'Caution',
            countKo: '걸리는 단서 ${palace.badStars.length}가지',
            countEn:
                '${palace.badStars.length} tense cue${palace.badStars.length == 1 ? '' : 's'}',
            anchorKo: anchorPair.caution.anchorLabelKo,
            anchorEn: anchorPair.caution.anchorLabelEn,
            helperKo: anchorPair.caution.helperKo,
            helperEn: anchorPair.caution.helperEn,
            color: AppColors.taupe,
            useKo: useKo,
          ),
        ],
      ],
    );
  }
}

// Round 82 sprint 5 — 12 결 풀이 카드 "도와주는 흐름" / "살짝 걸리는 흐름" row.
// 변경점: anchor label (= 사주의 X 십신 / Y 용신 / Z 신살) + 1줄 helper text 추가.
// 사용자 mandate: support/caution row 옆에 사주 근거가 안 나오고 설명이 약하다는 지적.
class _SupportSummaryRow extends StatelessWidget {
  final String labelKo;
  final String labelEn;
  final String countKo;
  final String countEn;
  final String anchorKo;
  final String anchorEn;
  final String helperKo;
  final String helperEn;
  final Color color;
  final bool useKo;
  const _SupportSummaryRow({
    required this.labelKo,
    required this.labelEn,
    required this.countKo,
    required this.countEn,
    required this.anchorKo,
    required this.anchorEn,
    required this.helperKo,
    required this.helperEn,
    required this.color,
    required this.useKo,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 96,
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            useKo ? labelKo : labelEn,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1행 — 개수 요약 + anchor 라벨 ( = 사주의 X 십신 ).
              RichText(
                text: TextSpan(
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.ink,
                  ),
                  children: [
                    TextSpan(text: useKo ? countKo : countEn),
                    TextSpan(
                      text: ' ${useKo ? anchorKo : anchorEn}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        height: 1.55,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 2행 — 1줄 helper (친근 행동 처방).
              Text(
                useKo ? helperKo : helperEn,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12.5,
                  height: 1.7,
                  color: AppColors.inkLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// _StarChip / _StarRow 제거: 별 이름 노출하던 컴포넌트로, 필살기 보호 위해 삭제.
// 대체: _SupportSummaryRow (개수 풀이만 노출).

// ──────────── LIFE STAGE — Round 73 sprint 2 ────────────
// 초년/중년/말년 3 phase paragraph (DaewoonService.chain wire).
// 운세의신 17 섹션 중 "초년운/중년운/말년운" 매핑.

class _LifeStageSection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  final bool isMale;
  final int? userAge;
  // R83 sprint 5 (P1-E) — 대운 영역은 시주에서 파생되는 십신/대운 일부 영향을 받음.
  // unknownTime=true 시 헤더 아래 정확도 안내 라벨 1줄 mount.
  final bool unknownTime;
  const _LifeStageSection({
    required this.result,
    required this.useKo,
    required this.isMale,
    required this.userAge,
    this.unknownTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return FutureBuilder<LifeStageResult>(
      future: LifeStageService.compute(
        result,
        isMale: isMale,
        userAge: userAge,
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          // loading — empty placeholder (UI 깜빡임 방지).
          return const SizedBox(height: 0);
        }
        final r = snap.data!;
        return _SectionFrame(
          background: AppColors.bg,
          meta: useKo ? '인생 흐름 · LIFE STAGE' : 'LIFE STAGE',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                useKo
                    ? '초년 · 중년 · 말년 흐름'
                    : 'EARLY · MID · LATE FLOW',
                style: useKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      )
                    : GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
              ),
              const SizedBox(height: 12),
              Container(width: 36, height: 1, color: AppColors.line),
              // R83 sprint 5 (P1-E) — 시간 모름 시 정확도 안내 라벨.
              if (unknownTime) ...[
                const SizedBox(height: 12),
                _TimeUnknownNote(
                  keyId: 'life-stage-time-unknown',
                  useKo: useKo,
                  text: l.timeUnknownAffectsAccuracy,
                ),
              ],
              const SizedBox(height: 18),
              for (var i = 0; i < r.all.length; i++) ...[
                _LifeStageCard(phase: r.all[i], useKo: useKo),
                if (i < r.all.length - 1)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    height: 1,
                    color: AppColors.line,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LifeStageCard extends StatelessWidget {
  final LifeStagePhase phase;
  final bool useKo;
  const _LifeStageCard({required this.phase, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final accent = phase.isCurrent ? AppColors.accent : AppColors.taupe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              useKo ? phase.labelKo : phase.labelEn,
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 14, height: 1, color: AppColors.line),
            const SizedBox(width: 8),
            Text(
              useKo
                  ? '${phase.startAge}세~'
                  : 'AGE ${phase.startAge}+',
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            if (phase.isCurrent) ...[
              const SizedBox(width: 8),
              Text(
                useKo ? '· 지금' : '· NOW',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          useKo ? phase.ko : phase.en,
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 13.5,
                  height: 1.75,
                  color: AppColors.inkLight,
                  letterSpacing: 0.1,
                )
              : GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.65,
                  color: AppColors.inkLight,
                ),
        ),
      ],
    );
  }
}

// ──────────── SIPSIN PERSONA — Round 73 sprint 3 ────────────
// 8글자 십신 인격 풀이 — TenGodsService.tableFor 결과 위 4 카테고리 phrase.
// 8글자 십신 분포 기반 차별화 (같은 일주 다른 8글자 = phrase ≥30% 차별).

class _SipsinPersonaSection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  // R83 sprint 5 (P1-E) — 성향 영역은 시간(시주 천간/지지)에 영향을 일부 받음.
  // unknownTime=true 시 헤더 아래 정확도 안내 라벨 1줄 mount (큰 widget 변경 X).
  final bool unknownTime;
  const _SipsinPersonaSection({
    required this.result,
    required this.useKo,
    this.unknownTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return FutureBuilder<SipsinPersonaReading>(
      future: SipsinPersonaService.compute(result),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 0);
        final r = snap.data!;
        return _SectionFrame(
          background: AppColors.paper,
          meta: useKo ? '8글자 풀이 · EIGHT-CHARACTER READ' : 'EIGHT-CHARACTER READ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                useKo
                    ? '8글자 깊게 푼 풀이'
                    : 'A DEEPER EIGHT-CHARACTER READ',
                style: useKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      )
                    : GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
              ),
              const SizedBox(height: 12),
              Container(width: 36, height: 1, color: AppColors.line),
              // R83 sprint 5 (P1-E) — 시간 모름 시 정확도 안내 라벨.
              if (unknownTime) ...[
                const SizedBox(height: 12),
                _TimeUnknownNote(
                  keyId: 'sipsin-persona-time-unknown',
                  useKo: useKo,
                  text: l.timeUnknownAffectsAccuracy,
                ),
              ],
              const SizedBox(height: 18),
              for (var i = 0; i < SipsinPersonaService.categories.length; i++) ...[
                _SipsinPersonaRow(
                  category: SipsinPersonaService.categories[i],
                  reading: r,
                  useKo: useKo,
                ),
                if (i < SipsinPersonaService.categories.length - 1)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 1,
                    color: AppColors.line,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SipsinPersonaRow extends StatelessWidget {
  final String category;
  final SipsinPersonaReading reading;
  final bool useKo;
  const _SipsinPersonaRow({
    required this.category,
    required this.reading,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final body = useKo ? reading.ko[category]! : reading.en[category]!;
    final label = useKo
        ? SipsinPersonaService.labelKo[category]!
        : SipsinPersonaService.labelEn[category]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    )
                  : GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.line)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 13.5,
                  height: 1.75,
                  color: AppColors.inkLight,
                  letterSpacing: 0.1,
                )
              : GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.65,
                  color: AppColors.inkLight,
                ),
        ),
      ],
    );
  }
}

// ──────────── CAREER — Round 73 sprint 6 ────────────
// 8글자 십신 분포 → 직업 추천 (5-7) + 한 줄 설명.

class _CareerSection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _CareerSection({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CareerRecommendation>(
      future: CareerRecommendService.compute(result),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 0);
        final c = snap.data!;
        final careers = useKo ? c.careersKo : c.careersEn;
        return _SectionFrame(
          background: AppColors.bg,
          meta: useKo ? '재테크 비법 · CAREER PATH' : 'CAREER PATH',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                useKo
                    ? '본인에게 어울리는 직업'
                    : 'CAREERS THAT FIT YOU',
                style: useKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      )
                    : GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                useKo ? c.primaryKo : c.primaryEn,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              Container(width: 36, height: 1, color: AppColors.line),
              const SizedBox(height: 14),
              Text(
                useKo ? c.noteKo : c.noteEn,
                style: useKo
                    ? GoogleFonts.notoSansKr(
                        fontSize: 13.5,
                        height: 1.75,
                        color: AppColors.inkLight,
                        letterSpacing: 0.1,
                      )
                    : GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.65,
                        color: AppColors.inkLight,
                      ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final career in careers)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line, width: 1),
                        color: AppColors.paper,
                      ),
                      child: Text(
                        career,
                        style: useKo
                            ? GoogleFonts.notoSansKr(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              )
                            : GoogleFonts.inter(
                                fontSize: 11.5,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────── WEALTH — Round 73 sprint 6 ────────────
// 재성 분포 + 일간 강약 → 3 phase paragraph
// (모으는 법 / 손실 막는 법 / 재테크 비법).

class _WealthStrategySection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _WealthStrategySection({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WealthStrategy>(
      future: WealthStrategyService.compute(result),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 0);
        final w = snap.data!;
        return _SectionFrame(
          background: AppColors.paper,
          meta: useKo ? '재물 흐름 · WEALTH STRATEGY' : 'WEALTH STRATEGY',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                useKo
                    ? '재물 모으는 법 · 손실 막는 법 · 재테크 비법'
                    : 'BUILD · PROTECT · GROW',
                style: useKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      )
                    : GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
              ),
              const SizedBox(height: 12),
              Container(width: 36, height: 1, color: AppColors.line),
              const SizedBox(height: 18),
              _WealthPhaseRow(
                  labelKo: '재물 모으는 법',
                  labelEn: 'BUILD',
                  ko: w.accumKo,
                  en: w.accumEn,
                  useKo: useKo),
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 1,
                  color: AppColors.line),
              _WealthPhaseRow(
                  labelKo: '재물 손실 막는 법',
                  labelEn: 'PROTECT',
                  ko: w.lossKo,
                  en: w.lossEn,
                  useKo: useKo),
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 1,
                  color: AppColors.line),
              _WealthPhaseRow(
                  labelKo: '재테크 비법',
                  labelEn: 'GROW',
                  ko: w.techKo,
                  en: w.techEn,
                  useKo: useKo),
            ],
          ),
        );
      },
    );
  }
}

class _WealthPhaseRow extends StatelessWidget {
  final String labelKo;
  final String labelEn;
  final String ko;
  final String en;
  final bool useKo;
  const _WealthPhaseRow({
    required this.labelKo,
    required this.labelEn,
    required this.ko,
    required this.en,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              useKo ? labelKo : labelEn,
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    )
                  : GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.line)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          useKo ? ko : en,
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 13.5,
                  height: 1.75,
                  color: AppColors.inkLight,
                  letterSpacing: 0.1,
                )
              : GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.65,
                  color: AppColors.inkLight,
                ),
        ),
      ],
    );
  }
}

// ──────────── ADDITIONAL LIFE 6 — Round 73 sprint 4 ────────────
// 운세의신 17 섹션 중 미커버 6 섹션:
//   건강운 / 체질운 / 사회운 / 사회적성격 / 타고난성향 / 타고난인품
// 입력: 사주 5행 dominant → 6 paragraph (ko/en).

class _AdditionalLifeSection extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _AdditionalLifeSection({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdditionalLifeReading>(
      future: AdditionalLifeService.compute(result),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 0);
        final r = snap.data!;
        // 6 카테고리 정의 — 운세의신 17 섹션 라벨 매칭.
        final rows = useKo
            ? [
                ('건강운', r.healthKo),
                ('체질운', r.bodyKo),
                ('사회운', r.socialKo),
                ('사회적 성격', r.socialPersonaKo),
                ('타고난 성향', r.innateNatureKo),
                ('타고난 인품', r.innateCharacterKo),
              ]
            : [
                ('HEALTH', r.healthEn),
                ('CONSTITUTION', r.bodyEn),
                ('SOCIAL CIRCLE', r.socialEn),
                ('PUBLIC PERSONA', r.socialPersonaEn),
                ('INNATE NATURE', r.innateNatureEn),
                ('INNATE CHARACTER', r.innateCharacterEn),
              ];
        return _SectionFrame(
          background: AppColors.bg,
          meta: useKo ? '인생 6 결 · LIFE SIX' : 'LIFE SIX',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                useKo
                    ? '건강 · 체질 · 사회 · 성품'
                    : 'HEALTH · BODY · SOCIAL · CHARACTER',
                style: useKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      )
                    : GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
              ),
              const SizedBox(height: 12),
              Container(width: 36, height: 1, color: AppColors.line),
              const SizedBox(height: 18),
              for (var i = 0; i < rows.length; i++) ...[
                _AdditionalLifeRow(label: rows[i].$1, body: rows[i].$2, useKo: useKo),
                if (i < rows.length - 1)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 1,
                    color: AppColors.line,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AdditionalLifeRow extends StatelessWidget {
  final String label;
  final String body;
  final bool useKo;
  const _AdditionalLifeRow({
    required this.label,
    required this.body,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    )
                  : GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.line)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 13.5,
                  height: 1.75,
                  color: AppColors.inkLight,
                  letterSpacing: 0.1,
                )
              : GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.65,
                  color: AppColors.inkLight,
                ),
        ),
      ],
    );
  }
}

