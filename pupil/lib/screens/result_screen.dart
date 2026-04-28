import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lie_detector.dart';

class ResultScreen extends StatelessWidget {
  final String question;
  final double score; // 0.0 ~ 10.0 magnitude
  const ResultScreen({super.key, required this.question, required this.score});

  @override
  Widget build(BuildContext context) {
    final ls = LieDetector.compute(
      blinkCount: (score * 0.6).round(),
      headRotationDelta: score * 3,
      smileProbabilityAvg: score / 10,
      questionHash: question.hashCode,
    );
    final color = score >= 7.5
        ? const Color(0xFFFF3D5A)
        : score >= 5.0
            ? Colors.orange
            : score >= 2.5
                ? Colors.yellow
                : Colors.greenAccent;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'QUESTION',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'PUPIL TREMOR MAGNITUDE',
                style: GoogleFonts.inter(
                    fontSize: 11, letterSpacing: 4, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                ls.magnitude.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 140,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '진도 ${ls.magnitude.toStringAsFixed(1)} / 10.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                    color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(
                  ls.verdict,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  '다시 측정',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
