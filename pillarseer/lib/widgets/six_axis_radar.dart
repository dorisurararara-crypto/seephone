// Pillar Seer — 6 각 Radar Widget.
//
// 1등 운세 앱 시그니처 (6 축) + 우리 차별점 (깊이 풀이 ✨ 일치 배지).
// Aesop Luxury 톤: ink line · accent fill (반투명) · taupe axis · 6 축 라벨 ko.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/six_axis_score_service.dart';
import '../theme/app_theme.dart';

class SixAxisRadar extends StatelessWidget {
  final SixAxisScore score;

  /// radar 한 변 픽셀.
  final double size;

  /// true → "깊게 봐도 다시 잡힌 핵심: N/6 ✨" 작은 카드도 같이 보여줌.
  final bool showMatchBadge;

  const SixAxisRadar({
    super.key,
    required this.score,
    this.size = 220,
    this.showMatchBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMatchBadge)
          _MatchBadge(matchCount: score.matchCount, useKo: useKo),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadarPainter(score: score, useKo: useKo),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _AxisLegend(score: score, useKo: useKo),
      ],
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final int matchCount;
  final bool useKo;
  const _MatchBadge({required this.matchCount, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Text(
            useKo
                ? '깊게 봐도 다시 잡힌 핵심'
                : 'CONFIRMED AT THE DEEP LAYER',
            style: useKo
                ? GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkLight,
                  )
                : GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkLight,
                  ),
          ),
          const Spacer(),
          Text(
            '$matchCount/6',
            style: GoogleFonts.notoSerifKr(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '✨',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLegend extends StatelessWidget {
  final SixAxisScore score;
  final bool useKo;
  const _AxisLegend({required this.score, required this.useKo});

  @override
  Widget build(BuildContext context) {
    final keys = SixAxisScore.axes;
    final labels = SixAxisScore.axesFor(useKo: useKo);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: List.generate(keys.length, (i) {
        final key = keys[i];
        final label = labels[i];
        final s = score.combinedScores[key] ?? 0;
        final matched = score.crossMatches[key] ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: useKo
                  ? GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkLight,
                    )
                  : GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkLight,
                    ),
            ),
            const SizedBox(width: 4),
            Text(
              '$s',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            if (matched) ...[
              const SizedBox(width: 2),
              Text(
                '✨',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final SixAxisScore score;
  final bool useKo;
  _RadarPainter({required this.score, required this.useKo});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 라벨 영역 확보 위해 radius 는 size 의 35%.
    final radius = math.min(size.width, size.height) * 0.35;
    // axes = 내부 키 (Map 조회용, 한글), axisLabels = UI 노출용 (useKo 분기).
    final axes = SixAxisScore.axes;
    final axisLabels = SixAxisScore.axesFor(useKo: useKo);

    // 12시 방향에서 시작, 시계방향.
    final angles = List.generate(
      axes.length,
      (i) => -math.pi / 2 + i * (2 * math.pi / axes.length),
    );

    // 1) 동심 격자 (4 레벨) + 축선
    final gridPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var lvl = 1; lvl <= 4; lvl++) {
      final r = radius * lvl / 4;
      final path = Path();
      for (var i = 0; i < angles.length; i++) {
        final p = Offset(
          center.dx + r * math.cos(angles[i]),
          center.dy + r * math.sin(angles[i]),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    // 축선
    final axisPaint = Paint()
      ..color = AppColors.taupe.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (final a in angles) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(a),
          center.dy + radius * math.sin(a),
        ),
        axisPaint,
      );
    }

    // 2) 데이터 polygon (combinedScores)
    final dataPath = Path();
    for (var i = 0; i < axes.length; i++) {
      final v = (score.combinedScores[axes[i]] ?? 0) / 100.0;
      final r = radius * v;
      final p = Offset(
        center.dx + r * math.cos(angles[i]),
        center.dy + r * math.sin(angles[i]),
      );
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();
    final fillPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);
    final strokePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(dataPath, strokePaint);

    // 3) 데이터 점 — 일치(✨) 축은 강조.
    for (var i = 0; i < axes.length; i++) {
      final v = (score.combinedScores[axes[i]] ?? 0) / 100.0;
      final r = radius * v;
      final p = Offset(
        center.dx + r * math.cos(angles[i]),
        center.dy + r * math.sin(angles[i]),
      );
      final matched = score.crossMatches[axes[i]] ?? false;
      final dotPaint = Paint()
        ..color = matched ? AppColors.accent : AppColors.ink
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, matched ? 4.2 : 3.0, dotPaint);
      if (matched) {
        // ✨ 효과: outer ring
        final ringPaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(p, 7, ringPaint);
      }
    }

    // 4) 축 라벨 — useKo 분기 (Round 73)
    for (var i = 0; i < axes.length; i++) {
      final matched = score.crossMatches[axes[i]] ?? false;
      final labelOffset = Offset(
        center.dx + (radius + 18) * math.cos(angles[i]),
        center.dy + (radius + 18) * math.sin(angles[i]),
      );
      final baseLabel = axisLabels[i];
      final label = matched ? '$baseLabel ✨' : baseLabel;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: useKo
              ? GoogleFonts.notoSansKr(
                  fontSize: 11,
                  fontWeight: matched ? FontWeight.w600 : FontWeight.w500,
                  color: matched ? AppColors.accent : AppColors.ink,
                )
              : GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: matched ? FontWeight.w600 : FontWeight.w500,
                  color: matched ? AppColors.accent : AppColors.ink,
                ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          labelOffset.dx - tp.width / 2,
          labelOffset.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.score.combinedScores != score.combinedScores ||
      old.score.crossMatches != score.crossMatches ||
      old.useKo != useKo;
}
