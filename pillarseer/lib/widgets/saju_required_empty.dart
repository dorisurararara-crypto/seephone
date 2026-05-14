// Round 77 sprint 8 — SajuResult.dummy() fallback 제거 후 공용 empty state.
// 사주 정보가 비어 있을 때 모든 사주 의존 화면에서 1회용 가짜 결과 누출 0.
// 5 화면 공용 (home / result / date_picking / new_year_2026 / tojeong).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 사주 정보가 아직 입력되지 않은 화면에서 보여주는 통일 empty state.
///
/// kpop_compat_screen 의 _KpopEmptyState 와 동일 톤이지만, 사주 입력 전용 메시지.
/// CTA → `/input`.
///
/// - [showAppBar] true 면 PILLAR SEER AppBar 포함 (result/reports 화면용).
/// - false 면 body 단독 (home_screen — BottomNav 컨테이너 안 body slot 만 차지).
class SajuRequiredEmpty extends StatelessWidget {
  final bool showAppBar;
  const SajuRequiredEmpty({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!showAppBar) {
      return body;
    }
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
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final l = AppL10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.emptyStateSajuRequiredSub,
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.emptyStateSajuRequiredTitle,
              style: GoogleFonts.notoSerifKr(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.emptyStateSajuRequiredBody,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 28),
            InkWell(
              onTap: () => context.go('/input'),
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                color: AppColors.ink,
                child: Text(
                  '${l.emptyStateSajuRequiredCta}  →',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.bg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
