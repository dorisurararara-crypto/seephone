// Round 82 sprint 12 — package_info_plus 동적 로드 wrapper.
//
// 외부 reviewer P1 #8 (verbatim):
//   "Settings 에는 version 이 1.0.0 으로 하드코딩, pubspec 은 1.0.0+39.
//    package_info_plus 로 실제 버전/빌드 번호를 읽어야 함."
//
// 본 service 는 PackageInfo.fromPlatform() 를 한 번만 호출하여 캐싱하고,
// "버전 X.Y.Z · 빌드 N" 형식의 ko 표시 문자열을 반환한다. 외부 호출자
// (settings_screen 의 FutureBuilder) 는 future getter 또는 동기 formatted
// helper 를 사용. test 측은 PackageInfo.setMockInitialValues() 로 mock 한 뒤
// formatLabel 검증.

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// PackageInfo 를 한 번만 로드하여 캐싱하는 단일 인스턴스 wrapper.
///
/// Hot-restart 시 캐시 reset 을 위해 [resetForTest] 노출. 일반 앱 lifecycle 에선
/// PackageInfo 가 변하지 않으므로 single-flight cache 로 충분.
class AppVersionService {
  AppVersionService._();

  static Future<PackageInfo>? _cached;

  /// PackageInfo 를 (필요하면 한 번만) 로드한다.
  static Future<PackageInfo> load() {
    return _cached ??= PackageInfo.fromPlatform();
  }

  /// "버전 X.Y.Z · 빌드 N" (ko) / "Version X.Y.Z (build N)" (en) 형식 라벨.
  ///
  /// build 가 비어 있거나 0 이면 빌드 토큰 생략. 한자/영문 슬롭 회피, 친근 해요체.
  static String formatLabel(
    PackageInfo info, {
    required bool useKo,
  }) {
    final version = info.version.trim();
    final build = info.buildNumber.trim();
    final hasBuild = build.isNotEmpty && build != '0';
    if (useKo) {
      return hasBuild ? '버전 $version · 빌드 $build' : '버전 $version';
    }
    return hasBuild ? 'Version $version (build $build)' : 'Version $version';
  }

  /// future + locale 결합 helper. test 외에는 settings_screen 의 FutureBuilder
  /// 에서 직접 [load] + [formatLabel] 을 조합해 사용한다.
  static Future<String> loadLabel({required bool useKo}) async {
    final info = await load();
    return formatLabel(info, useKo: useKo);
  }

  /// test 격리용 — cache reset. 운영 코드에선 호출 X.
  @visibleForTesting
  static void resetForTest() {
    _cached = null;
  }
}
