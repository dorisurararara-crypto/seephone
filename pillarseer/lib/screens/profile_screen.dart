// Pillar Seer — Profile (Aesop Luxury tone).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/saju_result.dart';
import '../providers/dev_unlock_provider.dart';
import '../providers/saju_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final saju = ref.watch(sajuResultProvider);
    final info = ref.watch(userBirthInfoProvider);
    final isPro = ref.watch(devUnlockProvider);
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

    final displayName = (info?.name.trim().isNotEmpty ?? false)
        ? info!.name.trim()
        : (saju != null
            ? (useKo
                ? saju.dayPillar.pairKoreanMeaning
                : saju.dayMasterName)
            : '—');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'P I L L A R    S E E R',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 5,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    useKo ? '프로필 · 我' : 'PROFILE · 我',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR  CHART · 命 譜',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.taupe,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    displayName,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (saju != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      useKo
                          ? '${saju.dayPillar.pairKorean} · ${saju.dayPillar.pairKoreanMeaning} · ${saju.day60ji}'
                          : '${saju.dayMasterName} · ${saju.day60ji}',
                      style: useKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: AppColors.accent,
                              letterSpacing: 0.3,
                            )
                          : GoogleFonts.cormorantGaramond(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accent,
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isPro) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.accent, width: 1),
                      ),
                      child: Text(
                        'PRO  MEMBER',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Round 77 sprint 7 — 정사각 PNG 공유 카드 export.
            if (saju != null)
              _MenuRow(
                label: l.profileShareCard,
                onTap: () => _shareSajuCard(
                  context,
                  saju: saju,
                  displayName: displayName,
                  useKo: useKo,
                ),
              ),
            _MenuRow(
              label: l.settingsTitle,
              onTap: () => context.push('/settings'),
            ),
            _MenuRow(
              label: l.profileReset,
              destructive: true,
              // R82 sprint 11 — 외부 reviewer P1 #7. 즉시 clear 가 아니라 confirm
              // dialog 1회. Settings 의 "내 데이터 모두 삭제" 모달 패턴과 일관.
              onTap: () => _confirmReset(context, ref, l),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round 82 sprint 11 — Profile reset 메뉴 row tap 시 confirm dialog 1회.
/// 외부 reviewer P1 #7 — Settings "내 데이터 모두 삭제" 와 동일 패턴 (AlertDialog +
/// BorderRadius.zero + line 1px + Inter letterSpacing 4 + fireRed accent).
/// "지우기" 분기에서만 기존 reset 동작 실행 (provider clear + `/input` 이동).
Future<void> _confirmReset(
  BuildContext context,
  WidgetRef ref,
  AppL10n l,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bg,
      surfaceTintColor: AppColors.bg,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.line, width: 1),
      ),
      title: Text(
        l.profileResetConfirmTitle,
        style: GoogleFonts.notoSerifKr(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          height: 1.5,
        ),
      ),
      content: Text(
        l.profileResetConfirmDesc,
        style: GoogleFonts.notoSansKr(
          color: AppColors.inkLight,
          fontSize: 13,
          height: 1.7,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            l.modalNotNow.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 4,
              color: AppColors.taupe,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            l.profileResetConfirmCta.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 4,
              color: AppColors.fireRed,
            ),
          ),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  ref.read(sajuResultProvider.notifier).clear();
  ref.read(userBirthInfoProvider.notifier).clear();
  context.go('/input');
}

/// Round 77 sprint 7 — 정사각 1080×1080 PNG 공유 카드 생성 + share_plus 호출.
/// 카드 내용: 일주 한자 (60pt) + 한국어 의미 + 닉네임 + 한 줄 verdict + 워터마크.
/// 톤: Aesop paper 배경 + ink 텍스트 + accent line. 실패 시 클립보드 fallback.
Future<void> _shareSajuCard(
  BuildContext context, {
  required SajuResult saju,
  required String displayName,
  required bool useKo,
}) async {
  final l = AppL10n.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final verdict = useKo
      ? (saju.deepKo?.oneLineYouAre ?? saju.dayPillar.pairKoreanMeaning)
      : (saju.deepEn?.oneLineYouAre ?? saju.dayMasterName);
  final shareText = useKo ? '내 사주 카드' : 'My Saju Card';
  // 정사각 1080×1080 — Instagram square / KakaoTalk share 안전.
  const size = 1080.0;
  try {
    final png = await _drawSajuCardPng(
      size: size,
      hanja: saju.day60ji,
      koreanMeaning: useKo
          ? saju.dayPillar.pairKoreanMeaning
          : saju.dayMasterName,
      name: displayName,
      verdict: verdict,
      useKo: useKo,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pillarseer_saju_card.png');
    await file.writeAsBytes(png);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  } catch (_) {
    // 폴백 — 클립보드에 한 줄 카드 텍스트 복사.
    final fallback = useKo
        ? '내 사주 카드 — ${saju.day60ji} · ${saju.dayPillar.pairKoreanMeaning}\n$displayName · $verdict\npillarseer.app'
        : 'My saju card — ${saju.day60ji} · ${saju.dayMasterName}\n$displayName · $verdict\npillarseer.app';
    try {
      await Clipboard.setData(ClipboardData(text: fallback));
    } catch (_) {/* silent */}
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(l.profileShareCardFallback),
      ));
  }
}

/// 정사각 PNG 직접 그리기 (ui.PictureRecorder + Canvas).
/// RepaintBoundary 없이 off-screen render → 텍스트는 ui.ParagraphBuilder 사용.
Future<Uint8List> _drawSajuCardPng({
  required double size,
  required String hanja,
  required String koreanMeaning,
  required String name,
  required String verdict,
  required bool useKo,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
      recorder, Rect.fromLTWH(0, 0, size, size));
  // 배경 — Aesop paper.
  final bgPaint = Paint()..color = AppColors.bg;
  canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);
  // 외곽 인너 라인 (paper accent).
  final linePaint = Paint()
    ..color = AppColors.line
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  canvas.drawRect(
      Rect.fromLTWH(60, 60, size - 120, size - 120), linePaint);

  // helper: paragraph 그리기.
  void drawText(
    String text, {
    required double left,
    required double top,
    required double maxWidth,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w400,
    String? fontFamily,
    double letterSpacing = 0,
    TextAlign align = TextAlign.left,
  }) {
    final pStyle = ui.ParagraphStyle(
      textAlign: align,
      fontWeight: weight,
      fontSize: fontSize,
      fontFamily: fontFamily,
      height: 1.25,
    );
    final builder = ui.ParagraphBuilder(pStyle)
      ..pushStyle(ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontFamily: fontFamily,
      ))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(left, top));
  }

  // Round 77 sprint 7 — 한국어 메인 + 한자는 sub (한자 letter-spacing 큰 메인 라벨 X).
  // 상단 sub label — 한국어 자연문.
  drawText(
    useKo ? '내 사주 카드' : 'My saju card',
    left: 120,
    top: 130,
    maxWidth: size - 240,
    fontSize: 28,
    color: AppColors.taupe,
    weight: FontWeight.w500,
  );

  // 일주 한국어 의미 — 메인 카드 hero.
  drawText(
    koreanMeaning,
    left: 120,
    top: 200,
    maxWidth: size - 240,
    fontSize: 96,
    color: AppColors.ink,
    weight: FontWeight.w300,
  );

  // 일주 한자 — sub-accent (작게).
  drawText(
    hanja,
    left: 120,
    top: 350,
    maxWidth: size - 240,
    fontSize: 56,
    color: AppColors.accent,
    weight: FontWeight.w300,
    letterSpacing: 2,
  );

  // accent line
  canvas.drawLine(Offset(120, 460), Offset(size - 120, 460),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = 1);

  // 닉네임 라벨 + 닉네임
  drawText(
    useKo ? '닉네임' : 'NAME',
    left: 120,
    top: 490,
    maxWidth: size - 240,
    fontSize: 22,
    color: AppColors.taupe,
    weight: FontWeight.w500,
  );
  drawText(
    name,
    left: 120,
    top: 530,
    maxWidth: size - 240,
    fontSize: 72,
    color: AppColors.ink,
    weight: FontWeight.w300,
  );

  // 한 줄 verdict
  drawText(
    verdict,
    left: 120,
    top: 720,
    maxWidth: size - 240,
    fontSize: 38,
    color: AppColors.inkLight,
    weight: FontWeight.w400,
  );

  // 하단 워터마크 — 한국어 메인.
  drawText(
    useKo ? 'pillarseer.app  ·  명조 카드' : 'pillarseer.app  ·  saju card',
    left: 120,
    top: size - 130,
    maxWidth: size - 240,
    fontSize: 22,
    color: AppColors.taupe,
    weight: FontWeight.w500,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('toByteData returned null');
  }
  return byteData.buffer.asUint8List();
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _MenuRow({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                  color: destructive ? AppColors.fireRed : AppColors.ink,
                ),
              ),
            ),
            Text(
              '→',
              style: TextStyle(
                  color: destructive ? AppColors.fireRed : AppColors.taupe,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
