// Round 83 sprint 2 — "사주 계산 기준 안내" 페이지 (P1-G).
//
// 사용자 신뢰도 transparency = 이 앱이 사주를 어떻게 계산하는지 한국 MZ 친근한
// 한국어 1줄씩 보여줘요. 5 영역:
//   1) 진태양시 보정
//   2) 자시 학파 (밤 11시~새벽 1시)
//   3) 절기 기준 월주
//   4) 음력 · 양력 입력
//   5) 출생지 경도 보정
//
// route = `/settings/saju-calc-basis` (router.dart 에서 등록).
// 진입점 = Settings 화면 "신뢰 & 데이터" 그룹 안.
//
// M4 (5행 골든 보존) — 본 페이지는 readonly 정보 페이지. manseryeok 계산 로직 변경 0.
// R70 (자미두수 hidden) — 자미두수 별 이름 nameKo 본 페이지 노출 0.
// M5 (한국 MZ 페르소나) — 사주 도메인 어휘 화이트리스트 ("진태양시 / 자시 / 절기 /
//   음력 / 양력 / 도시 경도 / 사주 / 일주") 만 사용, 옆에 1줄 친근 풀이 wire 필수.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class InfoSajuCalcScreen extends StatelessWidget {
  const InfoSajuCalcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
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
          l.infoCalcBasisTitle.toUpperCase(),
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Text(
              l.infoCalcBasisIntro,
              style: GoogleFonts.notoSansKr(
                fontSize: 13.5,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CalcBasisSection(
            index: 1,
            label: l.infoCalcBasisTrueSunLabel,
            description: l.infoCalcBasisTrueSunDesc,
          ),
          _CalcBasisSection(
            index: 2,
            label: l.infoCalcBasisJasiLabel,
            description: l.infoCalcBasisJasiDesc,
          ),
          _CalcBasisSection(
            index: 3,
            label: l.infoCalcBasisSolarTermLabel,
            description: l.infoCalcBasisSolarTermDesc,
          ),
          _CalcBasisSection(
            index: 4,
            label: l.infoCalcBasisLunarLabel,
            description: l.infoCalcBasisLunarDesc,
          ),
          _CalcBasisSection(
            index: 5,
            label: l.infoCalcBasisCityLabel,
            description: l.infoCalcBasisCityDesc,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Text(
              l.infoCalcBasisFooter,
              style: GoogleFonts.notoSansKr(
                fontSize: 12.5,
                color: AppColors.taupe,
                height: 1.65,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5 영역 각각: 인덱스 (01~05) + 도메인 라벨 + 1줄 친근 풀이.
class _CalcBasisSection extends StatelessWidget {
  final int index;
  final String label;
  final String description;
  const _CalcBasisSection({
    required this.index,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final indexLabel = index.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측 index — Aesop luxury 톤 (단순 숫자, letterSpacing 강조).
          SizedBox(
            width: 36,
            child: Text(
              indexLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
                color: AppColors.taupe,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.7,
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
