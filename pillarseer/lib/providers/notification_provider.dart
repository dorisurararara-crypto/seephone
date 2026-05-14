// Pillar Seer — 일일 알림 토글 상태 provider.
// Round 76 — 사용자 알림 시간 (hour, minute) state + SharedPreferences 영속 추가.
// Round 77 sprint 7 — 알림 톤 (adult/mz) state + SharedPreferences 영속 추가.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saju_result.dart';
import '../services/notification_pool_service.dart';
import '../services/notification_service.dart';

const _kPrefsTone = 'app.notif.tone';

class NotificationToggle {
  final bool enabled;
  final bool permissionGranted;
  final int notifyHour;
  final int notifyMinute;
  final NotificationTone tone;
  const NotificationToggle({
    required this.enabled,
    required this.permissionGranted,
    this.notifyHour = 8,
    this.notifyMinute = 0,
    this.tone = NotificationTone.adult,
  });

  NotificationToggle copyWith({
    bool? enabled,
    bool? permissionGranted,
    int? notifyHour,
    int? notifyMinute,
    NotificationTone? tone,
  }) {
    return NotificationToggle(
      enabled: enabled ?? this.enabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      tone: tone ?? this.tone,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationToggle> {
  @override
  NotificationToggle build() {
    _load();
    return const NotificationToggle(enabled: false, permissionGranted: false);
  }

  Future<void> _load() async {
    await NotificationService.ensureInitialized();
    final enabled = await NotificationService.isEnabled();
    final time = await NotificationService.loadTime();
    // Round 77 sprint 7 — 알림 톤 영속 로드.
    final prefs = await SharedPreferences.getInstance();
    final toneRaw = prefs.getString(_kPrefsTone) ?? 'adult';
    final tone =
        toneRaw == 'mz' ? NotificationTone.mz : NotificationTone.adult;
    state = state.copyWith(
      enabled: enabled,
      notifyHour: time.hour,
      notifyMinute: time.minute,
      tone: tone,
    );
  }

  /// Round 77 sprint 7 — 알림 톤 설정 (adult/mz). 즉시 reschedule (enabled 시).
  Future<void> setTone({
    required NotificationTone tone,
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
    SajuResult? saju,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsTone, tone == NotificationTone.mz ? 'mz' : 'adult');
    state = state.copyWith(tone: tone);
    if (state.enabled) {
      await NotificationService.scheduleDaily(
        title: pushTitle,
        body: pushBody,
        day60ji: day60ji,
        useKo: useKo,
        hour: state.notifyHour,
        minute: state.notifyMinute,
        saju: saju,
        tone: tone,
      );
    }
  }

  Future<bool> enable({
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
    SajuResult? saju, // Round 76 sprint 6 — 있으면 today_event 기반 본문.
  }) async {
    final granted = await NotificationService.requestPermission();
    if (!granted) {
      state = state.copyWith(enabled: false, permissionGranted: false);
      return false;
    }
    // NotificationService 가 30일 × 매일 다른 문구 자동 schedule
    await NotificationService.scheduleDaily(
      title: pushTitle,
      body: pushBody,
      day60ji: day60ji,
      useKo: useKo,
      hour: state.notifyHour,
      minute: state.notifyMinute,
      saju: saju,
      tone: state.tone,
    );
    await NotificationService.setEnabled(true);
    state = state.copyWith(enabled: true, permissionGranted: true);
    return true;
  }

  Future<void> disable() async {
    await NotificationService.cancelDaily();
    await NotificationService.setEnabled(false);
    state = state.copyWith(enabled: false);
  }

  /// Round 76 — 사용자가 시간 picker 로 변경 시. 즉시 reschedule.
  /// enabled 가 true 인 경우에만 reschedule, 아니면 prefs 만 저장.
  Future<void> setTime({
    required int hour,
    required int minute,
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
    SajuResult? saju,
  }) async {
    final h = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    await NotificationService.setTime(h, m);
    state = state.copyWith(notifyHour: h, notifyMinute: m);
    if (state.enabled) {
      await NotificationService.scheduleDaily(
        title: pushTitle,
        body: pushBody,
        day60ji: day60ji,
        useKo: useKo,
        hour: h,
        minute: m,
        saju: saju,
        tone: state.tone,
      );
    }
  }

  Future<void> reconcileSchedule({
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    required bool useKo,
    SajuResult? saju,
  }) async {
    if (!state.enabled) return;
    final needsReschedule = await NotificationService.needsReschedule(
      title: pushTitle,
      body: pushBody,
      day60ji: day60ji,
      useKo: useKo,
      hour: state.notifyHour,
      minute: state.notifyMinute,
      saju: saju,
    );
    if (!needsReschedule) return;
    await NotificationService.scheduleDaily(
      title: pushTitle,
      body: pushBody,
      day60ji: day60ji,
      useKo: useKo,
      hour: state.notifyHour,
      minute: state.notifyMinute,
      saju: saju,
      tone: state.tone,
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationToggle>(
        NotificationNotifier.new);
