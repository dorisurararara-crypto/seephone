// Pillar Seer — Result screen. MZ/K-pop 친근 톤 + 3-hit 요약 + 큰 글씨.
// 한자어는 모두 보조 subtitle 로만, 메인 헤더는 친근 라벨 + emoji.
// Free user 는 본성+5행+Life Themes 3/6 만 unlocked; Pro 면 모두 해제.
// ignore_for_file: unused_element, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../services/personalization_engine.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/saju_result.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/saju_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/coming_soon_modal.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final result = ref.watch(sajuResultProvider) ?? SajuResult.dummy();
    final isPro = ref.watch(devUnlockProvider);
    final overrideLocale = ref.watch(localeProvider);
    final systemLocale = Localizations.maybeLocaleOf(context);
    final lang = (overrideLocale?.languageCode ?? systemLocale?.languageCode ?? 'en');
    final useKo = lang == 'ko';
    final reading = useKo ? result.deepKo : result.deepEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorderStrong),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified,
                        size: 12, color: AppColors.celestialGold),
                    const SizedBox(width: 4),
                    Text(
                      useKo ? '정밀 모드' : 'Precision',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.celestialGold,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // codex Round 19 권고: "그래서 나는 누구인가" 가장 먼저.
            // 1. 한 줄 정체성 (3-hit card)
            _ThreeHitCard(result: result, reading: reading, useKo: useKo),
            const SizedBox(height: 14),
            // 2. 사주 4기둥 (가장 핵심 결과)
            _PillarGrid(result: result),
            const SizedBox(height: 12),
            // 3. 일간 상세 카드
            _DayMasterCard(result: result),
            const SizedBox(height: 14),
            // 4. 오늘 조언 (개인화)
            _PersonalForYouCard(result: result, useKo: useKo),
            const SizedBox(height: 12),
            // 5. 작은 신뢰 + 처음이세요? 보조 영역
            _TrustLine(),
            const SizedBox(height: 6),
            _EasyModeBanner(),
            const SizedBox(height: 22),
            _SectionHeader(
              title: l.resultDayMasterDeepTitle,
              hint: l.resultDayMasterTermHint,
            ),
            const SizedBox(height: 10),
            _Section(
              locked: false,
              whyLine: reading?.whyReason,
              child: _LongText(text: reading?.dayMasterDeep ?? result.summary),
            ),
            const SizedBox(height: 22),
            _SectionHeader(
              title: l.resultFiveElementsDetailTitle,
              hint: l.resultFiveElementsTermHint,
            ),
            const SizedBox(height: 10),
            _Section(
              locked: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ElementsBar(result: result),
                  if (reading != null && reading.elementsNote.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color:
                            AppColors.midnightPurple.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.celestialGold
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        reading.elementsNote,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.ghostlyWhite,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            // 이하 항목 accordion 으로 정리 (codex Round 14 권고 — 너무 길음).
            _AccordionSection(
              title: l.resultTenGodsTitle,
              hint: l.resultTenGodsTermHint,
              locked: !isPro,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TenGodsTable(rows: result.tenGods, useKo: useKo),
                  if (reading != null && reading.tenGodsNote.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: AppColors.celestialGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.celestialGold
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        reading.tenGodsNote,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.celestialGold,
                          fontWeight: FontWeight.w700,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _AccordionSection(
              title: l.resultLifeThemesTitle,
              locked: false,
              child: _LifeThemesBlock(reading: reading, isPro: isPro),
            ),
            _AccordionSection(
              title: l.resultTenYearLuckTitle,
              hint: l.resultTenYearLuckTermHint,
              locked: !isPro,
              child: _LongText(text: reading?.tenYearLuck ?? ''),
            ),
            _AccordionSection(
              title: l.resultThisYearTitle,
              hint: l.resultThisYearTermHint,
              locked: !isPro,
              child: _LongText(text: reading?.thisYear ?? ''),
            ),
            _AccordionSection(
              title: l.resultLuckyTitle,
              locked: !isPro,
              child: _LuckyBlock(reading: reading, useKo: useKo),
            ),
            _AccordionSection(
              title: l.resultBasisTitle,
              locked: false,
              child: _CalculationBasisBody(result: result, useKo: useKo),
            ),
            const SizedBox(height: 8),
            if (!isPro) _ProHooks(),
            const SizedBox(height: 18),
            if (!isPro)
              ElevatedButton.icon(
                onPressed: () => showComingSoonModal(context),
                icon: const Icon(Icons.lock_open),
                label: Text(l.resultUnlockFull),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.celestialGold,
                  foregroundColor: AppColors.midnightPurple,
                  minimumSize: const Size(double.infinity, 58),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            if (!isPro) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_forward,
                  color: AppColors.celestialGold),
              label: Text(
                l.resultContinueDaily,
                style: const TextStyle(
                    color: AppColors.ghostlyWhite,
                    fontSize: 15,
                    letterSpacing: 1.0),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(
                  color: AppColors.celestialGold.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _shareChart(context, result, useKo),
              icon: const Icon(Icons.share, color: AppColors.celestialGold),
              label: Text(
                l.resultShare,
                style: const TextStyle(
                    color: AppColors.celestialGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 1),
    );
  }
}

// ──────── Personalization Engine 카드 (codex Round 6 #1 ROI)

class _PersonalForYouCard extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _PersonalForYouCard({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final p = PersonalizationEngine.buildFor(result);
    final head = useKo ? p.headlineKo : p.headlineEn;
    final body = useKo ? p.bodyKo : p.bodyEn;
    final action = useKo ? p.actionKo : p.actionEn;
    final caution = useKo ? p.cautionKo : p.cautionEn;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.celestialGold),
              const SizedBox(width: 8),
              Text(
                l.personalCardTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.celestialGold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('🪨', l.personalHeadlineLabel, head),
          const SizedBox(height: 10),
          _row('🌊', l.personalBodyLabel, body),
          const SizedBox(height: 10),
          _row('✅', l.personalActionLabel, action),
          const SizedBox(height: 10),
          _row('⚠️', l.personalCautionLabel, caution),
        ],
      ),
    );
  }

  Widget _row(String emoji, String label, String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.midnightPurple.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: AppColors.celestialGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.ghostlyWhite,
                    height: 1.6,
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

// ──────── Share chart — copy + share via OS sheet

Future<void> _shareChart(BuildContext context, SajuResult result, bool useKo) async {
  final reading = useKo ? result.deepKo : result.deepEn;
  final oneLine = reading?.oneLineYouAre ?? '';
  final personality = reading?.personalityHook ?? '';
  final today = reading?.todayHook ?? '';
  final text = useKo
      ? '''✨ 내 사주 — Pillar Seer ✨

당신은 $oneLine 사람이에요.
일주: ${result.dayPillar.pairKorean} · ${result.dayPillar.pairKoreanMeaning} · ${result.day60ji}

🪨 성격: $personality
🎯 오늘: $today

🔗 Pillar Seer 앱에서 확인'''
      : '''✨ My Saju — Pillar Seer ✨

You are a $oneLine person.
Day Pillar: ${result.dayMasterName} · ${result.day60ji}

🪨 Personality: $personality
🎯 Today: $today

🔗 Open Pillar Seer to read yours''';
  try {
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (_) {
    // fallback: clipboard copy
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final l = AppL10n.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.shareCardCopied),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.celestialGold,
        duration: const Duration(seconds: 2),
      ));
  }
}

// ──────── Calculation Basis body (Round 14: accordion content)

class _CalculationBasisBody extends StatelessWidget {
  final SajuResult result;
  final bool useKo;
  const _CalculationBasisBody({required this.result, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final rows = [
      (label: l.resultBasisManseryeok, value: l.resultBasisManseryeokVal),
      (label: l.resultBasisYearBoundary, value: l.resultBasisYearBoundaryVal),
      (label: l.resultBasisDayBoundary, value: l.resultBasisDayBoundaryVal),
      (label: l.resultBasisTrueSun, value: l.resultBasisTrueSunOn),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        r.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.moonlightGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.ghostlyWhite,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ──────── Trust line (codex PM 권고 — 작은 신뢰 문구 1줄)

class _TrustLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined,
              size: 14, color: AppColors.celestialGold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l.resultTrustLine,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.fadedSilver,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Pro hooks — Result 중하단 3카드 (올해 연애 / 그 사람 / 중요 날짜)

class _ProHooks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final hooks = [
      _ProHook(
        emoji: '💞',
        title: l.resultProHookYearLoveTitle,
        teaser: l.resultProHookYearLoveTeaser,
        onTap: () => showComingSoonModal(context),
      ),
      _ProHook(
        emoji: '🤝',
        title: l.resultProHookCompatTitle,
        teaser: l.resultProHookCompatTeaser,
        onTap: () => context.go('/reports/compatibility'),
      ),
      _ProHook(
        emoji: '📅',
        title: l.resultProHookDatesTitle,
        teaser: l.resultProHookDatesTeaser,
        onTap: () => context.go('/reports/date-picking'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            l.resultProHookHeader,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.celestialGold,
            ),
          ),
        ),
        ...hooks.map((h) => _ProHookCard(hook: h)),
      ],
    );
  }
}

class _ProHook {
  final String emoji;
  final String title;
  final String teaser;
  final VoidCallback onTap;
  const _ProHook({
    required this.emoji,
    required this.title,
    required this.teaser,
    required this.onTap,
  });
}

class _ProHookCard extends StatelessWidget {
  final _ProHook hook;
  const _ProHookCard({required this.hook});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: hook.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.midnightPurple.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorderStrong),
              ),
              child: Text(hook.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hook.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ghostlyWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hook.teaser,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.moonlightGray,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.celestialGold.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.celestialGold.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open,
                      size: 11, color: AppColors.celestialGold),
                  const SizedBox(width: 4),
                  Text(
                    l.resultProHookCta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.celestialGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────── Easy mode banner — "처음이세요?"

class _EasyModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return InkWell(
      onTap: () => _showGuide(context, l),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.spiritIndigo.withValues(alpha: 0.3),
              AppColors.celestialGold.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.help_outline,
                size: 24, color: AppColors.celestialGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.resultEasyModeBannerTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.celestialGold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.resultEasyModeBannerDesc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.moonlightGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.fadedSilver),
          ],
        ),
      ),
    );
  }

  void _showGuide(BuildContext context, AppL10n l) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cosmicBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: AppColors.celestialGold.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined,
                  color: AppColors.celestialGold, size: 32),
              const SizedBox(height: 10),
              Text(
                l.resultGuideTitle,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.celestialGold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.resultGuideBody,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.ghostlyWhite,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.celestialGold,
                    foregroundColor: AppColors.cosmicBlack,
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(
                    l.resultGuideGotIt,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────── 3-hit summary — codex PM 권고: 성격 / 연애 / 오늘 한 방씩

class _ThreeHitCard extends StatelessWidget {
  final SajuResult result;
  final DeepReading? reading;
  final bool useKo;
  const _ThreeHitCard({
    required this.result,
    required this.reading,
    required this.useKo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final oneLine = reading?.oneLineYouAre ??
        (useKo ? '한결같은' : 'steady-energy');
    final whoYouAre = useKo
        ? '${l.resultIntroLeadIn} $oneLine ${l.resultIntroLeadOut}'
        : '${l.resultIntroLeadIn} a $oneLine ${l.resultIntroLeadOut}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.celestialGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                l.resultThreeHitHeader,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.moonlightGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            whoYouAre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ghostlyWhite,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            useKo
                ? '${result.dayPillar.pairKorean} · ${result.dayPillar.pairKoreanMeaning} · ${result.day60ji}'
                : '${result.dayMasterName} · ${result.day60ji}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.fadedSilver,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          _hit(l.resultThreeHitPersonalityLabel, '🪨',
              reading?.personalityHook ?? ''),
          const SizedBox(height: 10),
          _hit(l.resultThreeHitLoveLabel, '💞',
              reading?.loveHook ?? ''),
          const SizedBox(height: 10),
          _hit(l.resultThreeHitTodayLabel, '🎯',
              reading?.todayHook ?? ''),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _hit(String label, String emoji, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.midnightPurple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.celestialGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.ghostlyWhite,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Section header — friendly title + small hint

/// Accordion section — codex Round 14 권고.
/// Result 가 너무 길어서 핵심만 상단 고정, 나머지는 접힘.
class _AccordionSection extends StatelessWidget {
  final String title;
  final String hint;
  final bool locked;
  final bool initiallyExpanded;
  final Widget child;
  final String? whyLine;

  const _AccordionSection({
    required this.title,
    this.hint = '',
    required this.locked,
    this.initiallyExpanded = false,
    required this.child,
    this.whyLine,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: const ListTileThemeData(
            dense: true,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            iconColor: AppColors.moonlightGray,
            collapsedIconColor: AppColors.fadedSilver,
            title: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ghostlyWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.celestialGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.celestialGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      l.resultProLocked,
                      style: const TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        color: AppColors.celestialGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: hint.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 13, top: 3),
                    child: Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.fadedSilver,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
            children: [
              if (locked)
                _LockedPlaceholder()
              else ...[
                child,
                if (whyLine != null && whyLine!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.celestialGold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.celestialGold.withValues(alpha: 0.15),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.moonlightGray,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: '${l.resultWhyLabel} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.celestialGold,
                            ),
                          ),
                          TextSpan(text: whyLine),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String hint;
  const _SectionHeader({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.celestialGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ghostlyWhite,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.fadedSilver,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────── Section shell (Pro Lock 적용)

class _Section extends StatelessWidget {
  final bool locked;
  final Widget child;
  final String? whyLine;
  const _Section({
    required this.locked,
    required this.child,
    this.whyLine,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.spiritIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.celestialGold.withValues(alpha: locked ? 0.08 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (locked) ...[
            _LockedPlaceholder(),
          ] else ...[
            child,
            if (whyLine != null && whyLine!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.celestialGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.celestialGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology_outlined,
                        size: 14, color: AppColors.celestialGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.moonlightGray,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: '${l.resultWhyLabel} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.celestialGold,
                              ),
                            ),
                            TextSpan(text: whyLine),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.midnightPurple.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.celestialGold.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                color: AppColors.celestialGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.resultUnlockHint,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.fadedSilver,
                  height: 1.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.celestialGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.celestialGold.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                l.resultProLocked,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: AppColors.celestialGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────── Long body text — 15.5pt

class _LongText extends StatelessWidget {
  final String text;
  const _LongText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15.5,
        color: AppColors.ghostlyWhite,
        height: 1.75,
      ),
    );
  }
}

// ──────── 4 Pillars grid

class _PillarGrid extends StatelessWidget {
  final SajuResult result;
  const _PillarGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PillarItem(label: l.resultPillarYear, pillar: result.yearPillar),
          _PillarItem(label: l.resultPillarMonth, pillar: result.monthPillar),
          _PillarItem(
            label: l.resultPillarDay,
            pillar: result.dayPillar,
            highlight: true,
          ),
          _PillarItem(label: l.resultPillarHour, pillar: result.hourPillar),
        ],
      ),
    );
  }
}

class _PillarItem extends StatelessWidget {
  final String label;
  final Pillar? pillar;
  final bool highlight;
  const _PillarItem({
    required this.label,
    required this.pillar,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNull = pillar == null;
    final borderColor = highlight
        ? AppColors.celestialGold  // day pillar 만 gold 강조 (핵심)
        : AppColors.cardBorder;
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final localizedPillarLabel = isNull
        ? '—'
        : (useKo ? pillar!.pairKoreanMeaning : pillar!.pairEnglish);
    final semanticLabel = isNull
        ? '$label pillar: unknown'
        : '$label pillar: ${pillar!.text}, $localizedPillarLabel';
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.moonlightGray,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.midnightPurple.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: highlight ? 1.8 : 1),
          ),
          child: Column(
            children: [
              Text(
                isNull ? '?' : pillar!.chunGan,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  // day pillar 만 gold, 나머지는 white (codex Round 16 권고)
                  color: highlight
                      ? AppColors.celestialGold
                      : AppColors.ghostlyWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isNull ? '?' : pillar!.jiJi,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ghostlyWhite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
              localizedPillarLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.moonlightGray,
                height: 1.2,
              ),
            ),
        ),
      ],
    ),
    );
  }
}

// ──────── Day Master compact card

class _DayMasterCard extends StatelessWidget {
  final SajuResult result;
  const _DayMasterCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.midnightPurple.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderStrong),
            ),
            child: Text(
              result.day60ji,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ghostlyWhite,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  useKo ? result.dayPillar.pairKoreanMeaning : result.dayMasterName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ghostlyWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final useKo = (Localizations.maybeLocaleOf(context)
                              ?.languageCode ??
                          'en') ==
                      'ko';
                  // Korean 모드: deepKo.dayMasterDeep 첫 문장 또는 personality 첫 줄
                  // English: result.summary (asset 가 영어라서 자연스러움)
                  final reading = useKo ? result.deepKo : result.deepEn;
                  String text;
                  if (useKo && reading != null) {
                    final src = reading.personalityHook.isNotEmpty
                        ? reading.personalityHook
                        : (reading.dayMasterDeep.isNotEmpty
                            ? reading.dayMasterDeep.split('. ').first
                            : result.summary);
                    text = src;
                  } else {
                    text = result.summary;
                  }
                  return Text(
                    text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.moonlightGray,
                      height: 1.5,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Five Elements bar

class _ElementsBar extends StatelessWidget {
  final SajuResult result;
  const _ElementsBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final el = result.elements;
    final dom = el.dominant;
    final def = el.deficit;
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final names = useKo
        ? const {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'}
        : const {
            '木': 'Wood', '火': 'Fire', '土': 'Earth', '金': 'Metal', '水': 'Water',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(names['木']!, '木', el.wood, dom, def),
        _row(names['火']!, '火', el.fire, dom, def),
        _row(names['土']!, '土', el.earth, dom, def),
        _row(names['金']!, '金', el.metal, dom, def),
        _row(names['水']!, '水', el.water, dom, def),
      ],
    );
  }

  Widget _row(String name, String han, int pct, String dom, String def) {
    final color = AppColors.forElement(han);
    final isDom = han == dom;
    final isDef = han == def;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
            child: Text(
              han,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.moonlightGray,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: AppColors.spiritIndigo.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ghostlyWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isDom)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.star,
                        size: 14, color: AppColors.celestialGold),
                  )
                else if (isDef)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 13, color: AppColors.fadedSilver),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Ten Gods table

class _TenGodsTable extends StatelessWidget {
  final List<TenGodRow> rows;
  final bool useKo;
  const _TenGodsTable({required this.rows, required this.useKo});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 11.5,
      letterSpacing: 1.2,
      color: AppColors.moonlightGray,
      fontWeight: FontWeight.w800,
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(useKo ? '기둥' : 'PILLAR', style: headerStyle),
            ),
            Expanded(
              flex: 3,
              child: Text(useKo ? '천간' : 'HEAVENLY', style: headerStyle),
            ),
            Expanded(
              flex: 3,
              child: Text(useKo ? '지지' : 'EARTHLY', style: headerStyle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _posLabel(row.position, useKo),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ghostlyWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.chunGanGod == null
                          ? '—'
                          : (useKo ? row.chunGanGod!.ko : row.chunGanGod!.en),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.celestialGold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.jiJiGod == null
                          ? '—'
                          : (useKo ? row.jiJiGod!.ko : row.jiJiGod!.en),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.celestialGold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _posLabel(String pos, bool ko) {
    if (ko) {
      switch (pos) {
        case 'year':
          return '년주';
        case 'month':
          return '월주';
        case 'day':
          return '일주';
        case 'hour':
          return '시주';
      }
    }
    switch (pos) {
      case 'year':
        return 'Year';
      case 'month':
        return 'Month';
      case 'day':
        return 'Day';
      case 'hour':
        return 'Hour';
    }
    return pos;
  }
}

// ──────── Life themes block

class _LifeThemesBlock extends StatelessWidget {
  final DeepReading? reading;
  final bool isPro;
  const _LifeThemesBlock({required this.reading, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final themes = <_ThemeItem>[
      _ThemeItem(l.resultThemeCareer, '💼', reading?.career ?? '',
          locked: false),
      _ThemeItem(l.resultThemeWealth, '💰', reading?.wealth ?? '',
          locked: false),
      _ThemeItem(l.resultThemeLove, '💞', reading?.love ?? '', locked: false),
      _ThemeItem(l.resultThemeHealth, '🌿', reading?.health ?? '',
          locked: !isPro),
      _ThemeItem(l.resultThemeFamily, '🏠', reading?.family ?? '',
          locked: !isPro),
      _ThemeItem(l.resultThemeFame, '🌟', reading?.fame ?? '',
          locked: !isPro),
    ];
    return Column(
      children: themes.map((t) => _ThemeCard(item: t)).toList(),
    );
  }
}

class _ThemeItem {
  final String title;
  final String emoji;
  final String text;
  final bool locked;
  const _ThemeItem(this.title, this.emoji, this.text, {required this.locked});
}

class _ThemeCard extends StatelessWidget {
  final _ThemeItem item;
  const _ThemeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.midnightPurple.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.celestialGold
              .withValues(alpha: item.locked ? 0.1 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.4,
                    color: item.locked
                        ? AppColors.fadedSilver
                        : AppColors.ghostlyWhite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (item.locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.celestialGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.celestialGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 10, color: AppColors.celestialGold),
                      const SizedBox(width: 4),
                      Text(
                        l.resultProLocked,
                        style: const TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.8,
                          color: AppColors.celestialGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.locked)
            InkWell(
              onTap: () => showComingSoonModal(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l.resultUnlockHint,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.fadedSilver,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            Text(
              item.text,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.ghostlyWhite,
                height: 1.7,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────── Lucky block

class _LuckyBlock extends StatelessWidget {
  final DeepReading? reading;
  final bool useKo;
  const _LuckyBlock({required this.reading, required this.useKo});

  @override
  Widget build(BuildContext context) {
    if (reading == null) return const SizedBox.shrink();
    return Column(
      children: [
        _row(Icons.palette_outlined, useKo ? '행운의 색' : 'Lucky Color',
            reading!.luckyColor),
        _row(Icons.tag, useKo ? '행운의 숫자' : 'Lucky Number',
            '${reading!.luckyNumber}'),
        _row(Icons.explore_outlined, useKo ? '행운의 방향' : 'Lucky Direction',
            reading!.luckyDirection),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.moonlightGray),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.moonlightGray,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.celestialGold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
