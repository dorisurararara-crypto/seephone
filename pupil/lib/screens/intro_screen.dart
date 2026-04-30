import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../services/locale_service.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  HealthDeviceStatus? _health;
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    // 첫 진입 시 한 번만 probe — 권한 다이얼로그가 뜸
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHealth());
  }

  Future<void> _refreshHealth() async {
    if (_probing) return;
    setState(() => _probing = true);
    final status = await HealthService.instance.probe();
    if (!mounted) return;
    setState(() {
      _health = status;
      _probing = false;
    });
  }

  void _start() {
    context.push('/scan');
  }

  void _openSettings() {
    final l = AppLocalizations.of(context);
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  child: Text(l.close,
                      style: const TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${l.introTitleLine1}\n${l.introTitleLine2}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.introTagline,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // 워치/에어팟 연동 배지
                  _HealthBadge(
                    status: _health,
                    probing: _probing,
                    onTap: _refreshHealth,
                  ),
                  const SizedBox(height: 16),
                  // 작동 흐름 안내
                  _StepRow(num: '1', text: l.stepStart),
                  const SizedBox(height: 12),
                  _StepRow(num: '2', text: l.stepAsk),
                  const SizedBox(height: 12),
                  _StepRow(num: '3', text: l.stepAnalyze),
                  const Spacer(),
                  FilledButton(
                    onPressed: _start,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: const Color(0xFFFF3D5A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l.startButton,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.introInstruction,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: _openSettings,
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

class _StepRow extends StatelessWidget {
  final String num;
  final String text;
  const _StepRow({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF3D5A), width: 1.5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: GoogleFonts.inter(
              color: const Color(0xFFFF3D5A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansKr(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  final HealthDeviceStatus? status;
  final bool probing;
  final VoidCallback onTap;
  const _HealthBadge({
    required this.status,
    required this.probing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = status;
    final linked = s != null && s.authorized && s.bpm != null;

    final color = probing
        ? Colors.white24
        : linked
            ? const Color(0xFF00E0FF)
            : Colors.white24;
    final iconBg = probing
        ? Colors.white12
        : linked
            ? const Color(0xFF00E0FF).withValues(alpha: 0.15)
            : Colors.white10;

    final mainLabel = probing
        ? '디바이스 확인 중…'
        : (s?.label ?? '연동 안 됨');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              linked ? Icons.favorite : Icons.favorite_border,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainLabel,
                    style: GoogleFonts.notoSansKr(
                      color: linked ? Colors.white : Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (linked && s.bpm != null)
                    Text(
                      '최근 BPM ${s.bpm!.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00E0FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (!probing && (s == null || !s.authorized))
                    Text(
                      'Apple Watch · AirPods Pro 3 · Galaxy Watch',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (probing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Icon(
                linked ? Icons.check_circle : Icons.refresh,
                color: color,
                size: 18,
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
  const _LangTile({required this.label, required this.selected, required this.onTap});

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
              color: selected ? const Color(0xFFFF3D5A) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
