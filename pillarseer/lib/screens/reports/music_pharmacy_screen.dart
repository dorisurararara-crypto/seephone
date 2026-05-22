// Pillar Seer — 디지털 기운 처방전 화면 (R101 sprint 6, 팬심 2순위).
//
// 진입: /reports/music-pharmacy
// 디자인:
//   - 베이지 종이 질감 (apothecary cream + 부드러운 paper 톤 + 미세 dash 테두리).
//   - 처방전 카드 구조: 머리(타이틀/처방 번호) → 환자(사용자) → 처방 항목(셀럽+곡)
//     → 효능 / 부작용 / 복용법.
//   - "다시 처방 받기" 버튼 — seed 변경 → 다른 셀럽/곡/효능/부작용/복용법 조합.
//
// 공유 — Sprint 6 범위에서는 RepaintBoundary + boundary.toImage() + ShareXFile 시도.
//   Failure path 는 텍스트 공유 (Share.share) 로 graceful fallback. 막혀도 route 가
//   깨지지 않도록 button 항상 노출, 실패 시 SnackBar.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show File;

import '../../models/saju_result.dart';
import '../../providers/saju_provider.dart';
import '../../services/music_pharmacy_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav.dart';

class MusicPharmacyScreen extends ConsumerStatefulWidget {
  const MusicPharmacyScreen({super.key});

  @override
  ConsumerState<MusicPharmacyScreen> createState() =>
      _MusicPharmacyScreenState();
}

class _MusicPharmacyScreenState extends ConsumerState<MusicPharmacyScreen> {
  MusicPrescription? _prescription;
  bool _loading = true;
  int _seedTick = 0; // 다시 처방 받기 — seed 회전용.
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final user = ref.read(sajuResultProvider);
    if (user == null) {
      setState(() {
        _loading = false;
        _prescription = null;
      });
      return;
    }
    final info = ref.read(userBirthInfoProvider);
    final userName = info?.name;
    await MusicPharmacyService.primeCache();
    final seed = _seedTick == 0 ? null : _composeSeed(user, _seedTick);
    final p = await MusicPharmacyService.prescribe(
      user: user,
      userName: userName,
      seed: seed,
    );
    if (!mounted) return;
    setState(() {
      _prescription = p;
      _loading = false;
    });
  }

  int _composeSeed(SajuResult u, int tick) {
    final s = '${u.dayPillar.text}|${u.yearPillar.text}|tick:$tick';
    var h = 0x811c9dc5;
    for (final r in s.runes) {
      h ^= r & 0xff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  Future<void> _share() async {
    final p = _prescription;
    if (p == null) return;
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final shareText = useKo ? p.prescriptionText : p.prescriptionTextEn;
    final subject = useKo
        ? '디지털 기운 처방전'
        : 'Digital Energy Prescription';
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData?.buffer.asUint8List();
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/pillarseer_prescription.png');
          await file.writeAsBytes(bytes);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: shareText,
              subject: subject,
            ),
          );
          return;
        }
      }
      // 이미지 path 실패 → 텍스트 공유.
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: subject),
      );
    } catch (_) {
      // 마지막 fallback — 클립보드 복사 + SnackBar.
      await Clipboard.setData(ClipboardData(text: shareText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(useKo
              ? '처방전 텍스트가 복사됐어요.'
              : 'Prescription text copied.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sajuResultProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const PillarBottomNavStatic(activeIdx: 2),
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/reports'),
        ),
        title: Text(
          useKo ? '디지털 기운 처방전 · 藥' : 'ENERGY PRESCRIPTION · 藥',
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
      body: SafeArea(
        top: false,
        child: me == null
            ? _emptyState(context, useKo)
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _prescription == null
                    ? Center(
                        child: Text(useKo
                            ? '처방전을 만들지 못했어요. 다시 시도해 주세요.'
                            : "Couldn't build a prescription. Please try again."),
                      )
                    : _body(_prescription!, useKo),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool useKo) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            useKo
                ? '내 사주를 먼저 입력해 주세요.'
                : 'Enter your birth details first.',
            style: GoogleFonts.notoSerifKr(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/input'),
            child: Text(useKo ? '내 사주 입력하기' : 'Enter birth details'),
          ),
        ],
      ),
    );
  }

  Widget _body(MusicPrescription p, bool useKo) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: _PrescriptionCard(p: p, useKo: useKo),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('music_pharmacy_reroll_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _seedTick += 1;
                  });
                  _generate();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  useKo ? '다시 처방 받기' : 'Get another',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('music_pharmacy_share_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                onPressed: _share,
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(
                  useKo ? '공유' : 'Share',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final MusicPrescription p;
  final bool useKo;
  const _PrescriptionCard({required this.p, required this.useKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('music_pharmacy_card'),
      decoration: BoxDecoration(
        // 베이지 종이 톤 — apothecary cream 보다 더 따뜻한 노트지.
        color: const Color(0xFFF8F1E5),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.line, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PILLARSEER  ·  PHARMACY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  useKo
                      ? '처방 No. ${_shortHash(p)}'
                      : 'Rx No. ${_shortHash(p)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.taupe,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            useKo ? '디지털 기운 처방전' : 'Digital Energy Prescription',
            style: GoogleFonts.notoSerifKr(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            useKo
                ? '오늘 부족한 ${p.elementKo} 기운을 채워줄 곡'
                : 'A track to top up the ${p.elementEn} energy running light today',
            style: GoogleFonts.notoSerifKr(
              fontSize: 13,
              color: AppColors.taupe,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),

          _Section(
            label: useKo ? '처방 항목' : 'PRESCRIBED',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  useKo
                      ? '${p.celebNameKo}  —  ${p.songTitleKo}'
                      : '${p.celebNameEn}  —  ${p.songTitleEn}',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  useKo
                      ? '아티스트 · ${p.songArtistKo}'
                      : 'Artist · ${p.songArtistEn}',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),

          _Section(
            label: useKo ? '효능' : 'EFFECT',
            child: Text(
              useKo ? p.effectKo : p.effectEn,
              key: const Key('music_pharmacy_effect'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),

          _Section(
            label: useKo ? '부작용' : 'SIDE EFFECT',
            child: Text(
              useKo ? p.sideEffectKo : p.sideEffectEn,
              key: const Key('music_pharmacy_side'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),

          _Section(
            label: useKo ? '복용법' : 'DOSAGE',
            child: Text(
              useKo ? p.dosageKo : p.dosageEn,
              key: const Key('music_pharmacy_dosage'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.line, width: 1),
              ),
            ),
            child: Text(
              useKo ? p.prescriptionText : p.prescriptionTextEn,
              key: const Key('music_pharmacy_body'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortHash(MusicPrescription p) {
    final src = '${p.celebId}-${p.songTitleKo}-${p.element}';
    var h = 0x811c9dc5;
    for (final r in src.runes) {
      h ^= r & 0xff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return ((h & 0xffff)).toRadixString(16).padLeft(4, '0').toUpperCase();
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// Keep Uint8List import alive even if unused in widget tree — used by toImage
// path in _share() above and may be referenced by tests in the future.
// ignore: unused_element
typedef _KeepBytesAlive = Uint8List;
