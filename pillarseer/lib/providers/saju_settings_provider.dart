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

  /// 진태양시 보정 적용 여부.
  /// true (기본) = 서울/도시별 longitude + 균시차 보정 적용 (정통 명리학).
  /// false = 표준시(KST) 그대로 사용 (단순 학파).
  final bool applyTrueSunTime;

  const SajuSettings({
    this.useLateNightZasi = false,
    this.applyTrueSunTime = true,
  });

  SajuSettings copyWith({bool? useLateNightZasi, bool? applyTrueSunTime}) =>
      SajuSettings(
        useLateNightZasi: useLateNightZasi ?? this.useLateNightZasi,
        applyTrueSunTime: applyTrueSunTime ?? this.applyTrueSunTime,
      );
}

class SajuSettingsNotifier extends Notifier<SajuSettings> {
  static const _kUseLateNightZasi = 'sajuSettings.useLateNightZasi';
  static const _kApplyTrueSunTime = 'sajuSettings.applyTrueSunTime';

  @override
  SajuSettings build() {
    _load();
    return const SajuSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lateNight = prefs.getBool(_kUseLateNightZasi) ?? false;
    final tst = prefs.getBool(_kApplyTrueSunTime) ?? true;
    state = SajuSettings(
        useLateNightZasi: lateNight, applyTrueSunTime: tst);
  }

  Future<void> setUseLateNightZasi(bool value) async {
    state = state.copyWith(useLateNightZasi: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseLateNightZasi, value);
  }

  Future<void> setApplyTrueSunTime(bool value) async {
    state = state.copyWith(applyTrueSunTime: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kApplyTrueSunTime, value);
  }
}

final sajuSettingsProvider =
    NotifierProvider<SajuSettingsNotifier, SajuSettings>(
        SajuSettingsNotifier.new);
