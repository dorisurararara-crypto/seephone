// Pillar Seer — 개발자 unlock provider.
// Settings → Version 라벨 5탭 → 키 입력 다이얼로그.
// 'ganzinam95' → isPro=true (모든 Pro 기능 해제)
// 'ganzinam12' → isPro=false (free 모드 복귀)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsProKey = 'app.dev.pro_unlocked';
const _kUnlockCode = 'ganzinam95';
const _kLockCode = 'ganzinam12';

class DevUnlockNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kPrefsProKey) ?? false;
  }

  /// 입력된 코드 검증 후 상태 변경. true 반환 = 코드 매치.
  Future<DevCodeResult> apply(String code) async {
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
