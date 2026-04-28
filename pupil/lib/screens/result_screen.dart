import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/lie_detector.dart';
import '../services/share_service.dart';
import '../services/sound_service.dart';

class ResultScreen extends StatefulWidget {
  final String question;
  final double score;
  const ResultScreen({super.key, required this.question, required this.score});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _shotController = ScreenshotController();
  final _sfx = SoundService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sfx.play(widget.score >= 5 ? PupilSfx.lieDetected : PupilSfx.truthConfirmed);
      AdService().maybeShowResultInterstitial();
    });
  }

  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ls = LieDetector.compute(
      blinkCount: (widget.score * 0.6).round(),
      headRotationDelta: widget.score * 3,
      smileProbabilityAvg: widget.score / 10,
      questionHash: widget.question.hashCode,
    );
    final color = widget.score >= 7.5
        ? const Color(0xFFFF3D5A)
        : widget.score >= 5.0
            ? Colors.orange
            : widget.score >= 2.5
                ? Colors.yellow
                : Colors.greenAccent;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Screenshot(
                controller: _shotController,
                child: Container(
                  color: const Color(0xFF0A0A0A),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        l.questionLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.question,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l.magnitudeLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            letterSpacing: 4,
                            color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ls.magnitude.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.magnitudeUnit(ls.magnitude.toStringAsFixed(1)),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                            color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
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
                      child: Text(l.save),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => ShareService.shareResult(
                        controller: _shotController,
                        question: widget.question,
                        score: ls.magnitude,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3D5A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l.share),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l.scanAgain,
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
