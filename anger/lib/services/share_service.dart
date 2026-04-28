import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ShareService {
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
          name: 'anger_${DateTime.now().millisecondsSinceEpoch}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결과 저장됨')),
        );
      }
    } catch (_) {}
  }

  static Future<void> shareResult({
    required ScreenshotController controller,
    required double watts,
  }) async {
    try {
      final bytes = await controller.capture(pixelRatio: 3);
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/anger_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '내 분노 ${watts.toStringAsFixed(0)}W — 분노발전소',
      );
    } catch (_) {}
  }
}
