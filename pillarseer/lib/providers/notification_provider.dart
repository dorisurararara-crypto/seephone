// Pillar Seer — 일일 알림 토글 상태 provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_pool_service.dart';
import '../services/notification_service.dart';

class NotificationToggle {
  final bool enabled;
  final bool permissionGranted;
  const NotificationToggle({
    required this.enabled,
    required this.permissionGranted,
  });

  NotificationToggle copyWith({bool? enabled, bool? permissionGranted}) {
    return NotificationToggle(
      enabled: enabled ?? this.enabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
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
    state = state.copyWith(enabled: enabled);
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
    // Pool 에서 다양한 body 선택 (오늘 기준 deterministic)
    String body = pushBody;
    if (day60ji != null && day60ji.isNotEmpty) {
      final picked =
          NotificationPoolService.pickFor(DateTime.now(), day60ji);
      body = useKo ? picked.ko : picked.en;
    }
    await NotificationService.scheduleDaily8am(
      title: pushTitle,
      body: body,
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
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationToggle>(
        NotificationNotifier.new);
