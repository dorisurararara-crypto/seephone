// Pillar Seer — 일일 운세 알림. flutter_local_notifications + timezone.
// 오전 8시 매일 반복 푸시. 사용자 토글 ON/OFF.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'notification_pool_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _kPrefsEnabled = 'app.notif.daily8am.enabled';
  static const int _kDailyId = 8888;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(iOS: ios, android: android);
    await _plugin.initialize(settings: init);
    _initialized = true;
  }

  /// iOS / Android 13+ 알림 권한 요청. true 반환 = 허용.
  static Future<bool> requestPermission() async {
    await ensureInitialized();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  /// 30일 × 매일 오전 8시 알림 등록 — 각 알림마다 NotificationPool 에서 다른 문구 선택.
  /// codex Round 7 fix: matchDateTimeComponents.time 으로 무한반복 시 첫 문구가 계속 반복되는 문제 해결.
  /// day60ji null 시 fallback fixed body 사용.
  static Future<void> scheduleDaily8am({
    required String title,
    required String body,
    String? day60ji,
    bool useKo = false,
    int daysAhead = 30,
  }) async {
    await ensureInitialized();
    // 기존 모든 daily 알림 cancel
    for (var i = 0; i < 64; i++) {
      try {
        await _plugin.cancel(id: _kDailyId + i);
      } catch (_) {}
    }
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < daysAhead; i++) {
      final target = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, 8, 0, 0)
          .add(Duration(days: i));
      if (target.isBefore(now)) continue;
      String pickedBody = body;
      if (day60ji != null && day60ji.isNotEmpty) {
        final picked = NotificationPoolService.pickFor(
          DateTime(target.year, target.month, target.day),
          day60ji,
        );
        pickedBody = useKo ? picked.ko : picked.en;
      }
      try {
        await _plugin.zonedSchedule(
          id: _kDailyId + i,
          title: title,
          body: pickedBody,
          scheduledDate: target,
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
            android: AndroidNotificationDetails(
              'daily_fortune',
              'Daily Fortune',
              channelDescription: '매일 아침 8시 오늘의 사주 운세',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        if (kDebugMode) print('schedule[$i] failed: $e');
        break;
      }
    }
  }

  static Future<void> cancelDaily() async {
    await ensureInitialized();
    for (var i = 0; i < 64; i++) {
      try {
        await _plugin.cancel(id: _kDailyId + i);
      } catch (_) {}
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrefsEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsEnabled, value);
  }
}
