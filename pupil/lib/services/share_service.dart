import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ShareService {
  static const _appStoreUrl = 'https://apps.apple.com/app/id6764363706';

  static Future<void> saveResult({
    required ScreenshotController controller,
    required BuildContext context,
  }) async {
    try {
      final bytes = await controller.capture(pixelRatio: 3);
      if (bytes == null) return;
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) return;
      }
      await Gal.putImageBytes(bytes,
          name: 'pupil_${DateTime.now().millisecondsSinceEpoch}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결과 저장됨')),
        );
      }
    } catch (_) {}
  }

  static Future<void> shareResult({
    required ScreenshotController controller,
    required String question,
    required double score,
  }) async {
    try {
      final bytes = await controller.capture(pixelRatio: 3);
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/pupil_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '동공 지진 진도 ${score.toStringAsFixed(1)} — "$question"\n\n'
            '— 카메라로 거짓말 탐지 —\n'
            '$_appStoreUrl',
      );
    } catch (_) {}
  }
}
