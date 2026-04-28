import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';

const _kPrefKey = 'ads_removed';

/// 광고 제거 IAP (com.ganziman.pupil.remove_ads, ₩1,500 / $0.99) 보유 상태.
///
/// 베타 빌드에선 SharedPreferences 토글만으로 활성화.
/// 정식 출시 시 in_app_purchase 패키지 + ASC IAP product 로 wire.
class AdsRemovedNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kPrefKey) ?? false;
    if (saved != state) {
      state = saved;
      AdService().setAdsRemoved(saved);
    }
  }

  Future<void> set(bool value) async {
    state = value;
    AdService().setAdsRemoved(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefKey, value);
  }

  Future<void> unlockAdRemoval() => set(true);

  Future<void> toggleForDev() => set(!state);
}

final adsRemovedProvider =
    NotifierProvider<AdsRemovedNotifier, bool>(AdsRemovedNotifier.new);
