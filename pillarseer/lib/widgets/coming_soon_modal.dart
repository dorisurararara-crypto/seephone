// Pillar Seer — Coming Soon 모달.
// Promo / Premium / Share 등 Phase 2 기능 클릭 시 노출.
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

Future<void> showComingSoonModal(BuildContext context) {
  final l = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.cosmicBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: AppColors.celestialGold.withValues(alpha: 0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.celestialGold.withValues(alpha: 0.2),
                    AppColors.spiritIndigo.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 36, color: AppColors.celestialGold),
            ),
            const SizedBox(height: 16),
            Text(
              l.modalComingSoonTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.celestialGold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.modalComingSoonDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.ghostlyWhite,
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
