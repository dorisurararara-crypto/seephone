// Pillar Seer — 일일 운세 알림. flutter_local_notifications + timezone.
// 오전 8시 매일 반복 푸시. 사용자 토글 ON/OFF.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'notification_pool_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _kPrefsEnabled = 'app.notif.daily8am.enabled';
  static const _kPrefsScheduleSig = 'app.notif.daily8am.scheduleSig';
  // Round 76 — 사용자 설정 시간 영속 (디폴트 8:00 — 기존 호환).
  static const _kPrefsHour = 'app.notif.daily.hour';
  static const _kPrefsMinute = 'app.notif.daily.minute';
  static const int _kDailyId = 8888;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // codex Round 8 fix: tz.local 을 디바이스 실제 timezone 으로 설정.
    // 안하면 tz.local 이 UTC fallback 가능 → 8AM 알림이 한국 시간 17AM (UTC) 으로 보내짐.
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (e) {
      if (kDebugMode) print('timezone init failed: $e');
    }
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

  /// 30일 × 매일 사용자 설정 시간 알림 등록.
  /// Round 76 — hour/minute 사용자 설정 가능. 디폴트 8:00 (기존 호환).
  /// codex Round 7 fix: 각 일자별 explicit schedule (matchDateTimeComponents.time 미사용)
  /// — 사용자가 시간 변경 시 OS 캐싱 패턴이 안 깨지는 이슈 회피.
  /// day60ji null 시 fallback fixed body 사용.
  static Future<void> scheduleDaily({
    required String title,
    required String body,
    String? day60ji,
    bool useKo = false,
    int daysAhead = 30,
    required int hour,
    required int minute,
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
          tz.local, now.year, now.month, now.day, hour, minute, 0)
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
              channelDescription: '매일 사용자 지정 시간 오늘의 사주 운세',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsScheduleSig, _scheduleSignature(
      title: title,
      body: body,
      day60ji: day60ji,
      useKo: useKo,
      hour: hour,
      minute: minute,
    ));
    await prefs.setInt(_kPrefsHour, hour);
    await prefs.setInt(_kPrefsMinute, minute);
  }

  /// 기존 호환 — 8AM 고정 wrapper. 신규 코드는 scheduleDaily 직접 사용 권장.
  static Future<void> scheduleDaily8am({
    required String title,
    required String body,
    String? day60ji,
    bool useKo = false,
    int daysAhead = 30,
  }) =>
      scheduleDaily(
        title: title,
        body: body,
        day60ji: day60ji,
        useKo: useKo,
        daysAhead: daysAhead,
        hour: 8,
        minute: 0,
      );

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

  static Future<bool> needsReschedule({
    required String title,
    required String body,
    String? day60ji,
    required bool useKo,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrefsScheduleSig) != _scheduleSignature(
      title: title,
      body: body,
      day60ji: day60ji,
      useKo: useKo,
      hour: hour,
      minute: minute,
    );
  }

  /// Round 76 — 사용자 저장 알림 시간 (디폴트 8:00).
  static Future<({int hour, int minute})> loadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_kPrefsHour) ?? 8;
    final m = prefs.getInt(_kPrefsMinute) ?? 0;
    return (hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  static Future<void> setTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefsHour, hour.clamp(0, 23));
    await prefs.setInt(_kPrefsMinute, minute.clamp(0, 59));
  }

  static String _scheduleSignature({
    required String title,
    required String body,
    String? day60ji,
    required bool useKo,
    required int hour,
    required int minute,
  }) =>
      '${useKo ? 'ko' : 'en'}|$title|$body|${day60ji ?? ''}|'
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
