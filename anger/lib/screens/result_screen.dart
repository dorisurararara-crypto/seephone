import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/anger_calc.dart';
import '../services/share_service.dart';
import '../services/sound_service.dart';

class ResultScreen extends StatefulWidget {
  final double watts;
  const ResultScreen({super.key, required this.watts});

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
      _sfx.play(AngerSfx.buzzer);
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
    final v = AngerCalc.verdict(widget.watts);
    final l = AppLocalizations.of(context);

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
                        l.yourAnger,
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
                        l.factory,
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
                      child: Text(l.save),
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
                      child: Text(l.share),
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
                  l.again,
                  style: GoogleFonts.blackHanSans(fontSize: 18),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  l.home,
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
