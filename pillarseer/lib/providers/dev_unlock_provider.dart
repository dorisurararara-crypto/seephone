// Pillar Seer — 개발자 unlock provider.
// Settings → Version 라벨 5탭 → 키 입력 다이얼로그.
// 'ganzinam95' → isPro=true (모든 Pro 기능 해제)
// 'ganzinam12' → isPro=false (free 모드 복귀)
//
// codex Round 8 fix: release build 에서는 dev gate 비활성 — App Review safety.
// kDebugMode 또는 dart-define DEV_GATE_ENABLED=true 일 때만 작동.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsProKey = 'app.dev.pro_unlocked';
const _kUnlockCode = 'ganzinam95';
const _kLockCode = 'ganzinam12';

/// Dev gate 활성 여부 — debug 빌드 OR explicit dart-define.
/// Release build (App Store production) 에서는 magic code 안 먹게.
const bool kDevGateEnabled =
    kDebugMode ||
    bool.fromEnvironment('DEV_GATE_ENABLED', defaultValue: false);

class DevUnlockNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  /// Release safety (codex Round 9 critical fix):
  /// release build 에서는 prefs 의 dev unlock 상태도 무시 + 삭제.
  /// 이전에 debug build 에서 unlock 한 사용자가 release update 받았을 때
  /// Pro 상태가 그대로 살아나는 보안 구멍 방지.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!kDevGateEnabled) {
      // 잔존 dev unlock 강제 제거
      if (prefs.getBool(_kPrefsProKey) == true) {
        await prefs.setBool(_kPrefsProKey, false);
      }
      state = false;
      return;
    }
    state = prefs.getBool(_kPrefsProKey) ?? false;
  }

  /// 입력된 코드 검증 후 상태 변경. true 반환 = 코드 매치.
  /// Release build 에서는 항상 invalid (kDevGateEnabled=false).
  Future<DevCodeResult> apply(String code) async {
    if (!kDevGateEnabled) return DevCodeResult.invalid;
    final trimmed = code.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed == _kUnlockCode) {
      await prefs.setBool(_kPrefsProKey, true);
      state = true;
      return DevCodeResult.unlocked;
    }
    if (trimmed == _kLockCode) {
      await prefs.setBool(_kPrefsProKey, false);
      state = false;
      return DevCodeResult.locked;
    }
    return DevCodeResult.invalid;
  }
}

enum DevCodeResult { unlocked, locked, invalid }

final devUnlockProvider =
    NotifierProvider<DevUnlockNotifier, bool>(DevUnlockNotifier.new);
