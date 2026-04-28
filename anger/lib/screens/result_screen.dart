import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../services/anger_calc.dart';
import '../services/share_service.dart';

class ResultScreen extends StatefulWidget {
  final double watts;
  const ResultScreen({super.key, required this.watts});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _shotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final v = AngerCalc.verdict(widget.watts);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Screenshot(
                controller: _shotController,
                child: Container(
                  color: const Color(0xFF0F0F0F),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFB800)
                                .withValues(alpha: 0.4),
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
                      const SizedBox(height: 16),
                      Text(
                        '— 분노 발전소 —',
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white30,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ShareService.saveResult(
                        controller: _shotController,
                        context: context,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('저장'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => ShareService.shareResult(
                        controller: _shotController,
                        watts: widget.watts,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB800),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('공유'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/measure'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  '한 번 더',
                  style: GoogleFonts.blackHanSans(fontSize: 18),
                ),
              ),
              const SizedBox(height: 6),
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
