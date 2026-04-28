import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'theme_pack_owned';

/// 올테마팩 (com.ganziman.bbaksin.theme_pack_all) 보유 상태.
///
/// 베타 빌드에선 SharedPreferences 토글만으로 활성화.
/// 정식 출시 시 in_app_purchase 패키지 + ASC 등록된 IAP product
/// (`com.ganziman.bbaksin.theme_pack_all`, ₩2,900 / $1.99) 로 wire.
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

  /// 올테마팩 결제 / 베타 활성화 → 모든 테마 잠금 해제.
  Future<void> unlockThemePack() => setPro(true);

  /// 개발용 토글 (설정 화면 long-press 등).
  Future<void> toggleForDev() => setPro(!state);
}

final proStatusProvider =
    NotifierProvider<ProStatusNotifier, bool>(ProStatusNotifier.new);
