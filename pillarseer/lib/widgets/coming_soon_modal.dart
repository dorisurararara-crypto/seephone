// Pillar Seer — Coming Soon 모달 (Aesop Luxury 톤).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

Future<void> showComingSoonModal(BuildContext context) {
  final l = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.36),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.bg,
      surfaceTintColor: AppColors.bg,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'COMING  SOON',
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 5,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 14),
            Container(width: 28, height: 1, color: AppColors.line),
            const SizedBox(height: 20),
            Text(
              l.modalComingSoonTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifKr(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.modalComingSoonDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.75,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 28),
            Container(height: 1, color: AppColors.line),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.taupe,
                      minimumSize: const Size(0, 52),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      l.modalNotNow.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.taupe,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 52, color: AppColors.line),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text(l.modalNotifyConfirm),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.ink,
                          duration: const Duration(seconds: 2),
                        ));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, 52),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      l.modalNotifyMe.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
