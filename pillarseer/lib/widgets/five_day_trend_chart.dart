// Pillar Seer — 5 일 trend line chart.
//
// Aesop Luxury 톤: accent line + 점 marker + 오늘 강조 박스.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/five_day_trend_service.dart';
import '../theme/app_theme.dart';

class FiveDayTrendChart extends StatelessWidget {
  final List<FiveDayPoint> points;
  final double height;

  const FiveDayTrendChart({
    super.key,
    required this.points,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return SizedBox(
      height: height + 38,
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, height),
                  painter: _TrendPainter(points: points),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: points
                .map((p) => Expanded(
                      child: Text(
                        p.labelFor(useKo: useKo),
                        textAlign: TextAlign.center,
                        style: useKo
                            ? GoogleFonts.notoSansKr(
                                fontSize: 11,
                                fontWeight: p.isToday
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: p.isToday
                                    ? AppColors.accent
                                    : AppColors.taupe,
                              )
                            : GoogleFonts.inter(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                fontWeight: p.isToday
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: p.isToday
                                    ? AppColors.accent
                                    : AppColors.taupe,
                              ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<FiveDayPoint> points;
  _TrendPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    // Y 범위 0~100 고정 (점수 비교 일관성).
    const minY = 0.0;
    const maxY = 100.0;
    final padY = 14.0;
    final padX = 20.0;

    double xFor(int i) =>
        padX + (size.width - 2 * padX) * (i / (points.length - 1));
    double yFor(double v) =>
        padY + (size.height - 2 * padY) * (1 - (v - minY) / (maxY - minY));

    // 1) 격자 (50점 reference line)
    final refPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padX, yFor(50)),
      Offset(size.width - padX, yFor(50)),
      refPaint,
    );

    // 2) 라인
    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xFor(i), yFor(points[i].score.toDouble()));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // 3) 점 marker + 점수 표시
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final center = Offset(xFor(i), yFor(p.score.toDouble()));
      // 오늘은 강조 (큰 점 + accent fill).
      final dotPaint = Paint()
        ..color = p.isToday ? AppColors.accent : AppColors.ink
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, p.isToday ? 5.0 : 3.5, dotPaint);
      if (p.isToday) {
        final ringPaint = Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 9, ringPaint);
      }
      // 점수 라벨
      final tp = TextPainter(
        text: TextSpan(
          text: '${p.score}',
          style: GoogleFonts.notoSerifKr(
            fontSize: p.isToday ? 13 : 11,
            fontWeight: p.isToday ? FontWeight.w600 : FontWeight.w400,
            color: p.isToday ? AppColors.accent : AppColors.inkLight,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // 점 위쪽에 표시.
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height - 8),
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points;
}
