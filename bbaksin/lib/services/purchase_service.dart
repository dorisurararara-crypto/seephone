import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'is_pro';

/// Pro 구독 상태.
///
/// TODO: in_app_purchase 패키지 연동 (실제 IAP 영수증 검증).
/// 현재는 SharedPreferences 플래그 — 개발용 / 토글 가능.
class ProStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kPrefKey) ?? false;
    if (saved != state) state = saved;
  }

  Future<void> setPro(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefKey, value);
  }

  /// 개발용 토글 (설정 화면 long-press 등).
  Future<void> toggleForDev() => setPro(!state);
}

final proStatusProvider =
    NotifierProvider<ProStatusNotifier, bool>(ProStatusNotifier.new);
