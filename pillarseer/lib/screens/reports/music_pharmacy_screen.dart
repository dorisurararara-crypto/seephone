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
              text: p.prescriptionText,
              subject: '디지털 기운 처방전',
            ),
          );
          return;
        }
      }
      // 이미지 path 실패 → 텍스트 공유.
      await SharePlus.instance.share(
        ShareParams(text: p.prescriptionText, subject: '디지털 기운 처방전'),
      );
    } catch (_) {
      // 마지막 fallback — 클립보드 복사 + SnackBar.
      await Clipboard.setData(ClipboardData(text: p.prescriptionText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처방전 텍스트가 복사됐어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sajuResultProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/reports'),
        ),
        title: Text(
          '디지털 기운 처방전 · 藥',
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
            ? _emptyState(context)
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _prescription == null
                    ? const Center(child: Text('처방전을 만들지 못했어요. 다시 시도해 주세요.'))
                    : _body(_prescription!),
      ),
      bottomNavigationBar: const PillarBottomNav(activeIdx: 2),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '내 사주를 먼저 입력해 주세요.',
            style: GoogleFonts.notoSerifKr(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/input'),
            child: const Text('내 사주 입력하기'),
          ),
        ],
      ),
    );
  }

  Widget _body(MusicPrescription p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: _PrescriptionCard(p: p),
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
                  '다시 처방 받기',
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
                  '공유',
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
  const _PrescriptionCard({required this.p});

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
                  '처방 No. ${_shortHash(p)}',
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
            '디지털 기운 처방전',
            style: GoogleFonts.notoSerifKr(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘 부족한 ${p.elementKo} 기운을 채워줄 곡',
            style: GoogleFonts.notoSerifKr(
              fontSize: 13,
              color: AppColors.taupe,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),

          _Section(
            label: '처방 항목',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.celebNameKo}  —  ${p.songTitleKo}',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '아티스트 · ${p.songArtistKo}',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),

          _Section(
            label: '효능',
            child: Text(
              p.effectKo,
              key: const Key('music_pharmacy_effect'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),

          _Section(
            label: '부작용',
            child: Text(
              p.sideEffectKo,
              key: const Key('music_pharmacy_side'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),

          _Section(
            label: '복용법',
            child: Text(
              p.dosageKo,
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
              p.prescriptionText,
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
