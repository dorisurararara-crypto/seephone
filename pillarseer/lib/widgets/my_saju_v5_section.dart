// Pillar Seer — Round 106 (P3) — 내 사주(평생사주) v5 섹션 위젯.
//
// design doc §3/§5/§9(내 사주) — 평생사주 화면 상단 cohesive 리딩.
// 구조 = 증거 띠 + 헤드라인(강점+그림자) + 본문 문단 + 오늘 연결 CTA.
// 기존 17섹션 상세 풀이는 이 섹션 아래에 그대로 보존된다 (본 위젯은 추가만).
//
// 계산 엔진·service 코어는 호출만 — 표현 layer only.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/my_saju_v5_service.dart';
import '../theme/app_theme.dart';

/// 내 사주 v5 — 평생사주 화면 상단 primary 섹션.
class MySajuV5Section extends StatelessWidget {
  final MySajuV5Reading reading;

  const MySajuV5Section({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final r = reading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── section meta ──
          Row(
            children: [
              Text(
                '내 사주',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 1),
                ),
                child: Text(
                  '평생 안 바뀌는 바탕',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    letterSpacing: 0.2,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ── 헤드라인 (강점 + 그림자) ──
          Text(
            r.headline,
            style: GoogleFonts.notoSerifKr(
              fontSize: 21,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          // ── 증거 띠 — "내 풀이에 실제 반영된 것" ──
          if (r.evidenceChips.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              '내 풀이에 실제 반영된 것',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: r.evidenceChips.map(_buildEvidenceChip).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          // ── 본문 문단 ──
          for (int i = 0; i < r.bodyParagraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Text(
              r.bodyParagraphs[i],
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.85,
              ),
            ),
          ],
          // ── 오늘 연결 CTA ──
          const SizedBox(height: 22),
          _buildTodayCta(context, r.todayCta),
        ],
      ),
    );
  }

  Widget _buildEvidenceChip(MySajuV5EvidenceChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chip.label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            chip.value,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCta(BuildContext context, String cta) {
    return InkWell(
      onTap: () => context.go('/today'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.accent, width: 1),
        ),
        child: Text(
          cta,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.accent,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
