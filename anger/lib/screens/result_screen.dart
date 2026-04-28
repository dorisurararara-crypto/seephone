import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/anger_calc.dart';

class ResultScreen extends StatelessWidget {
  final double watts;
  const ResultScreen({super.key, required this.watts});

  @override
  Widget build(BuildContext context) {
    final v = AngerCalc.verdict(watts);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'YOUR ANGER',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                v.headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.blackHanSans(
                  fontSize: 120,
                  color: const Color(0xFFFFB800),
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '≈ ${v.comparison}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      v.mockery,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/measure'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  '한 번 더',
                  style: GoogleFonts.blackHanSans(fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  '홈으로',
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
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
