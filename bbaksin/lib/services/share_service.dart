import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 부적 이미지 캡처 → 갤러리 저장 / 공유.
class ShareService {
  /// App Store 다운로드 링크 (친구가 이 링크 누르면 빡신 다운로드 페이지).
  static const _appStoreUrl = 'https://apps.apple.com/app/id6764363757';
  // TODO: 안드로이드 출시 후 추가
  // static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.ganziman.bbaksin';
  static Future<void> saveTalisman({
    required ScreenshotController controller,
    required BuildContext context,
  }) async {
    try {
      final bytes = await controller.capture(pixelRatio: 3);
      if (bytes == null) return;
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (context.mounted) {
            _toast(context, '갤러리 권한이 필요합니다');
          }
          return;
        }
      }
      await Gal.putImageBytes(bytes, name: 'bbaksin_${DateTime.now().millisecondsSinceEpoch}');
      if (context.mounted) {
        _toast(context, '부적 저장됨');
      }
    } catch (e) {
      if (context.mounted) {
        _toast(context, '저장 실패: $e');
      }
    }
  }

  static Future<void> shareTalisman({
    required ScreenshotController controller,
    required String question,
  }) async {
    try {
      final bytes = await controller.capture(pixelRatio: 3);
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/bbaksin_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '빡신이 내려주신 부적: $question\n\n'
            '— 욕쟁이 무당이 폭폭 날리는 디지털 점집 —\n'
            '$_appStoreUrl',
      );
    } catch (e) {
      // 공유 취소 등은 그냥 무시.
    }
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
