// Pillar Seer — 일일 알림 토글 상태 provider.
// Round 76 — 사용자 알림 시간 (hour, minute) state + SharedPreferences 영속.
// R108 ④ — 하루 1회 → 3 고정 슬롯(아침/오후/저녁). 마스터 토글 + 슬롯별 설정.
//   notifyHour/notifyMinute 는 아침 슬롯 시간으로 derive (caller 하위호환).
// R109 — 알림 톤(어른/중·고생) state·setTone 제거 (死기능).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saju_result.dart';
import '../services/notification_service.dart';

class NotificationToggle {
  /// 마스터 토글 — 권한 + 전체 on/off. OFF 면 어떤 슬롯도 안 울린다.
  final bool enabled;
  final bool permissionGranted;

  /// R108 — 3 고정 슬롯 설정. 항상 3 entry (아침/오후/저녁).
  final Map<NotificationSlot, SlotConfig> slots;

  const NotificationToggle({
    required this.enabled,
    required this.permissionGranted,
    required this.slots,
  });

  /// 디폴트 — 마스터 OFF, 슬롯 디폴트(아침 ON 08:00 / 오후 OFF / 저녁 OFF).
  factory NotificationToggle.initial() => NotificationToggle(
        enabled: false,
        permissionGranted: false,
        slots: {
          for (final s in NotificationSlot.values)
            s: SlotConfig(
              enabled: s.defaultEnabled,
              hour: s.defaultTime.hour,
              minute: s.defaultTime.minute,
            ),
        },
      );

  /// 아침 슬롯 — caller(home_screen 등) 하위호환용 derive.
  SlotConfig get morning =>
      slots[NotificationSlot.morning] ??
      SlotConfig(
        enabled: NotificationSlot.morning.defaultEnabled,
        hour: NotificationSlot.morning.defaultTime.hour,
        minute: NotificationSlot.morning.defaultTime.minute,
      );

  /// 하위호환 — 기존 caller 가 읽던 단일 알림 시간 = 아침 슬롯 시간.
  int get notifyHour => morning.hour;
  int get notifyMinute => morning.minute;

  /// 켜져 있고 마스터 ON 인 슬롯 개수 (UI 요약용).
  int get activeSlotCount =>
      enabled ? slots.values.where((c) => c.enabled).length : 0;

  NotificationToggle copyWith({
    bool? enabled,
    bool? permissionGranted,
    Map<NotificationSlot, SlotConfig>? slots,
  }) {
    return NotificationToggle(
      enabled: enabled ?? this.enabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      slots: slots ?? this.slots,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationToggle> {
  @override
  NotificationToggle build() {
    _load();
    return NotificationToggle.initial();
  }

  Future<void> _load() async {
    await NotificationService.ensureInitialized();
    final enabled = await NotificationService.isMasterEnabled();
    // R108 — 슬롯 로드(내부에서 기존 단일 알림 사용자 1회 마이그레이션).
    final slots = await NotificationService.loadSlots();
    state = state.copyWith(enabled: enabled, slots: slots);
  }

  /// 마스터 토글 ON — 권한 요청 후 enabled 슬롯 전부 schedule.
  Future<bool> enable({
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
    SajuResult? saju,
  }) async {
    final granted = await NotificationService.requestPermission();
    if (!granted) {
      state = state.copyWith(enabled: false, permissionGranted: false);
      return false;
    }
    await NotificationService.scheduleSlots(
      title: pushTitle,
      body: pushBody,
      slots: state.slots,
      day60ji: day60ji,
      useKo: useKo,
      saju: saju,
    );
    await NotificationService.setMasterEnabled(true);
    state = state.copyWith(enabled: true, permissionGranted: true);
    return true;
  }

  /// 마스터 토글 OFF — 전 슬롯 cancel.
  Future<void> disable() async {
    await NotificationService.cancelAll();
    await NotificationService.setMasterEnabled(false);
    state = state.copyWith(enabled: false);
  }

  /// R108 ④ — 한 슬롯의 enabled / 시간 변경. 즉시 reschedule (마스터 ON 시).
  /// 마스터 OFF 면 prefs 만 저장 (다음 ON 때 반영).
  Future<void> setSlot({
    required NotificationSlot slot,
    bool? enabled,
    int? hour,
    int? minute,
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
    SajuResult? saju,
  }) async {
    final current = state.slots[slot] ??
        SlotConfig(
          enabled: slot.defaultEnabled,
          hour: slot.defaultTime.hour,
          minute: slot.defaultTime.minute,
        );
    final updated = current.copyWith(
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
    await NotificationService.saveSlot(slot, updated);
    final nextSlots = {
      ...state.slots,
      slot: updated,
    };
    state = state.copyWith(slots: nextSlots);
    if (state.enabled) {
      await NotificationService.scheduleSlots(
        title: pushTitle,
        body: pushBody,
        slots: nextSlots,
        day60ji: day60ji,
        useKo: useKo,
        saju: saju,
      );
    }
  }

  /// 하위호환 — 기존 caller 의 단일 알림 시간 변경 = 아침 슬롯 시간 변경.
  Future<void> setTime({
    required int hour,
    required int minute,
    required String pushTitle,
    required String pushBody,
    String? day60ji,
    bool useKo = false,
    SajuResult? saju,
  }) async {
    await setSlot(
      slot: NotificationSlot.morning,
      hour: hour,
      minute: minute,
      pushTitle: pushTitle,
      pushBody: pushBody,
      day60ji: day60ji,
      useKo: useKo,
      saju: saju,
    );
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
      slots: state.slots,
      saju: saju,
    );
    if (!needsReschedule) return;
    await NotificationService.scheduleSlots(
      title: pushTitle,
      body: pushBody,
      slots: state.slots,
      day60ji: day60ji,
      useKo: useKo,
      saju: saju,
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationToggle>(
        NotificationNotifier.new);
