// Pillar Seer — 일일 알림 토글 상태 provider.
// Round 76 — 사용자 알림 시간 (hour, minute) state + SharedPreferences 영속 추가.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

class NotificationToggle {
  final bool enabled;
  final bool permissionGranted;
  final int notifyHour;
  final int notifyMinute;
  const NotificationToggle({
    required this.enabled,
    required this.permissionGranted,
    this.notifyHour = 8,
    this.notifyMinute = 0,
  });

  NotificationToggle copyWith({
    bool? enabled,
    bool? permissionGranted,
    int? notifyHour,
    int? notifyMinute,
  }) {
    return NotificationToggle(
      enabled: enabled ?? this.enabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
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
    state = state.copyWith(
      enabled: enabled,
      notifyHour: time.hour,
      notifyMinute: time.minute,
    );
  }

  Future<bool> enable({
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
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
      );
    }
  }

  Future<void> reconcileSchedule({
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    required bool useKo,
  }) async {
    if (!state.enabled) return;
    final needsReschedule = await NotificationService.needsReschedule(
      title: pushTitle,
      body: pushBody,
      day60ji: day60ji,
      useKo: useKo,
      hour: state.notifyHour,
      minute: state.notifyMinute,
    );
    if (!needsReschedule) return;
    await NotificationService.scheduleDaily(
      title: pushTitle,
      body: pushBody,
      day60ji: day60ji,
      useKo: useKo,
      hour: state.notifyHour,
      minute: state.notifyMinute,
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationToggle>(
        NotificationNotifier.new);
