// Pillar Seer — 사주 계산 옵션 (학파 호환성).
// 야자시 옵션: 23:00-23:59 출생자의 일주 결정 학파 차이.
//   기본 (false, 조자시 학파): 23h → 다음 날 일주 (한국 mainstream)
//   true (야자시 학파): 23h → 같은 날 일주

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SajuSettings {
  /// 야자시 학파 사용 여부.
  /// false (기본) = 23h 출생은 다음 날 일주 (조자시 학파, 한국 mainstream).
  /// true = 23h 출생은 같은 날 일주 (야자시 학파).
  final bool useLateNightZasi;

  const SajuSettings({this.useLateNightZasi = false});

  SajuSettings copyWith({bool? useLateNightZasi}) => SajuSettings(
        useLateNightZasi: useLateNightZasi ?? this.useLateNightZasi,
      );
}

class SajuSettingsNotifier extends Notifier<SajuSettings> {
  static const _kUseLateNightZasi = 'sajuSettings.useLateNightZasi';

  @override
  SajuSettings build() {
    _load();
    return const SajuSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lateNight = prefs.getBool(_kUseLateNightZasi) ?? false;
    state = SajuSettings(useLateNightZasi: lateNight);
  }

  Future<void> setUseLateNightZasi(bool value) async {
    state = state.copyWith(useLateNightZasi: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseLateNightZasi, value);
  }
}

final sajuSettingsProvider =
    NotifierProvider<SajuSettingsNotifier, SajuSettings>(
        SajuSettingsNotifier.new);
