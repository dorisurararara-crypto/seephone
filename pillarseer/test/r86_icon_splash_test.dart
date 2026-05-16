// R86 sprint 3 — Mock B 비비드 아이콘 + 스플래시 자산 회귀 가드.
//
// 사용자 mandate verbatim:
//   "이번엔 앱 아이콘이랑 스플래쉬 화면을 바꿔볼까? ... 2번으로 하는데 좀 비비드하게 해줘
//    생성하고 테스트플라이트 반영해"
//
// 검증:
//   B1 — iOS AppIcon.appiconset 의 15 PNG 파일 모두 존재 (Contents.json 기준)
//   B2 — LaunchImage.imageset 의 3 scale PNG 모두 존재
//   B3 — macOS AppIcon.appiconset 의 7 PNG 파일 모두 존재
//   B4 — source assets/icon/app_icon_1024.png 존재
//   B5 — LaunchScreen.storyboard backgroundColor 가 paper (R86 sprint 3 color)
//   B6 — LaunchScreen.storyboard 의 LaunchImage natural size 가 정사각 (320×320)

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R86 sprint 3 — icon / splash 자산', () {
    const iosIcons = [
      'Icon-App-20x20@1x.png', 'Icon-App-20x20@2x.png', 'Icon-App-20x20@3x.png',
      'Icon-App-29x29@1x.png', 'Icon-App-29x29@2x.png', 'Icon-App-29x29@3x.png',
      'Icon-App-40x40@1x.png', 'Icon-App-40x40@2x.png', 'Icon-App-40x40@3x.png',
      'Icon-App-60x60@2x.png', 'Icon-App-60x60@3x.png',
      'Icon-App-76x76@1x.png', 'Icon-App-76x76@2x.png',
      'Icon-App-83.5x83.5@2x.png',
      'Icon-App-1024x1024@1x.png',
    ];

    test('B1 — iOS AppIcon 15 PNG 모두 존재 (Mock B 비비드)', () {
      for (final name in iosIcons) {
        final f = File('ios/Runner/Assets.xcassets/AppIcon.appiconset/$name');
        expect(f.existsSync(), isTrue,
            reason: 'iOS icon "$name" 누락');
        expect(f.lengthSync() > 100, isTrue,
            reason: 'iOS icon "$name" 0 byte placeholder 잔존');
      }
    });

    test('B2 — LaunchImage 3 scale 모두 존재', () {
      for (final name in [
        'LaunchImage.png',
        'LaunchImage@2x.png',
        'LaunchImage@3x.png',
      ]) {
        final f = File('ios/Runner/Assets.xcassets/LaunchImage.imageset/$name');
        expect(f.existsSync(), isTrue, reason: 'LaunchImage "$name" 누락');
        expect(f.lengthSync() > 100, isTrue,
            reason: 'LaunchImage "$name" 0 byte placeholder');
      }
    });

    test('B3 — macOS AppIcon 7 sizes 모두 존재', () {
      for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
        final f =
            File('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$s.png');
        expect(f.existsSync(), isTrue,
            reason: 'macOS app_icon_$s.png 누락');
      }
    });

    test('B4 — source assets/icon/app_icon_1024.png 존재 (회귀 재생성 기준)', () {
      final f = File('assets/icon/app_icon_1024.png');
      expect(f.existsSync(), isTrue,
          reason: 'icon source 1024 누락 — 재생성 불가');
      expect(f.lengthSync() > 5000, isTrue,
          reason: 'icon source PNG 가 너무 작음 (생성 실패 의심)');
    });

    test('B5 — LaunchScreen.storyboard backgroundColor 가 paper 톤', () {
      final src = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
          .readAsStringSync();
      // R86 sprint 3 — backgroundColor red=0.937 green=0.902 blue=0.824 (#efe6d2 paper).
      // 기존 white (red=1 green=1 blue=1) 잔존 0.
      expect(
        src.contains(
            'red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"'),
        isFalse,
        reason: 'LaunchScreen backgroundColor 가 여전히 white — R86 sprint 3 갱신 X',
      );
      expect(src.contains('red="0.93725490196"'), isTrue,
          reason: 'LaunchScreen backgroundColor 가 paper (#efe6d2) 가 아님');
    });

    test('B6 — LaunchImage natural size 정사각 (320×320)', () {
      final src = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
          .readAsStringSync();
      expect(src.contains('<image name="LaunchImage" width="320" height="320"/>'),
          isTrue,
          reason: 'LaunchImage natural size 가 정사각 320 이 아님');
    });
  });
}
