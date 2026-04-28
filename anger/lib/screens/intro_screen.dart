import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../services/purchase_service.dart';

class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  void _openSettings(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final adsRemoved = ref.read(adsRemovedProvider);
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  adsRemoved ? l.adsRemovedLabel : l.removeAds,
                  style: GoogleFonts.blackHanSans(
                    color: const Color(0xFFFFB800),
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  adsRemoved ? l.removeAdsThanks : l.removeAdsDescription,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (!adsRemoved) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.betaFreeNotice,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(adsRemovedProvider.notifier).unlockAdRemoval();
                      Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l.activateRemoveAds,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  l.language.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _LangTile(
                  label: l.languageAuto,
                  selected: currentLocale == null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(null);
                    setSheetState(() {});
                  },
                ),
                _LangTile(
                  label: l.languageKorean,
                  selected: currentLocale?.languageCode == 'ko',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('ko'));
                    setSheetState(() {});
                  },
                ),
                _LangTile(
                  label: l.languageEnglish,
                  selected: currentLocale?.languageCode == 'en',
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en'));
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    adsRemoved ? l.close : l.later,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.introTitleLine1,
                    style: GoogleFonts.blackHanSans(
                      fontSize: 96,
                      color: const Color(0xFFFFB800),
                      height: 0.95,
                      letterSpacing: -3,
                    ),
                  ),
                  Text(
                    l.introTitleLine2,
                    style: GoogleFonts.blackHanSans(
                      fontSize: 96,
                      color: Colors.white,
                      height: 0.95,
                      letterSpacing: -3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.introTagline,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: Colors.white60,
                      height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.amber, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l.warningBody,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              color: Colors.amber.shade100,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/measure'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    child: Text(
                      l.startButton,
                      style: GoogleFonts.blackHanSans(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => _openSettings(context, ref),
                icon: const Icon(Icons.settings, color: Colors.white54),
                tooltip: l.settings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFFFFB800) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
