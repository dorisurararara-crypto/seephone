// Pillar Seer — Coming Soon 모달.
// Round 16: gold tone-down. CTA gold 1곳만 유지.
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

Future<void> showComingSoonModal(BuildContext context) {
  final l = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cardBorderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.midnightPurple.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorderStrong),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 32, color: AppColors.mysticViolet),
            ),
            const SizedBox(height: 16),
            Text(
              l.modalComingSoonTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ghostlyWhite,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.modalComingSoonDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.moonlightGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.moonlightGray,
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(l.modalNotNow),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text(l.modalNotifyConfirm),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.spiritIndigo,
                          duration: const Duration(seconds: 2),
                        ));
                    },
                    // CTA = gold (codex 권고: CTA + 핵심 숫자만 gold)
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.celestialGold,
                      foregroundColor: AppColors.cosmicBlack,
                      minimumSize: const Size(0, 44),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l.modalNotifyMe),
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
