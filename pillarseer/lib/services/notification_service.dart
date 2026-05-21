// Pillar Seer — 일일 운세 알림. flutter_local_notifications + timezone.
// 오전 8시 매일 반복 푸시. 사용자 토글 ON/OFF.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/saju_result.dart';
import 'daily_service.dart';
import 'notification_pool_service.dart';
import 'recall_feedback_service.dart';
import 'saju_context.dart';
import 'today_event_service.dart';
import 'topic_selector_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _kPrefsEnabled = 'app.notif.daily8am.enabled';
  static const _kPrefsScheduleSig = 'app.notif.daily8am.scheduleSig';
  // Round 76 — 사용자 설정 시간 영속 (디폴트 8:00 — 기존 호환).
  static const _kPrefsHour = 'app.notif.daily.hour';
  static const _kPrefsMinute = 'app.notif.daily.minute';
  static const int _kDailyId = 8888;

  /// R106 P2b-fix — 미스터리 알림 알고리즘/풀 버전 마커.
  /// scheduleSignature 에 박혀, 이 값이 바뀌면 기존 enabled 사용자도
  /// needsReschedule==true 가 되어 새 미스터리 알림으로 자동 재스케줄된다.
  /// 미스터리 카피 알고리즘·풀 스키마가 바뀔 때마다 이 문자열을 올린다.
  ///   v1 = R106 P2b 초판 (static per-topic interactions).
  ///   v2 = R106 P2b-fix (relation-aware interactions — 거짓말 0).
  static const String _kMysteryAlgoVersion = 'mystery_v2';

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
    SajuResult? saju, // Round 76 sprint 6 — 있으면 today_event_service deep pick.
    // Round 77 sprint 7 — 알림 톤 (adult/mz). fallback pickFor 경로에서 풀 선택.
    NotificationTone tone = NotificationTone.adult,
  }) async {
    await ensureInitialized();
    // 기존 모든 daily 알림 cancel
    for (var i = 0; i < 64; i++) {
      try {
        await _plugin.cancel(id: _kDailyId + i);
      } catch (_) {}
    }
    final daily = DailyService();
    final now = tz.TZDateTime.now(tz.local);

    // Round 106 P2b — 사주 미스터리형 알림 (design doc §6).
    // saju + useKo(한국어) 둘 다일 때만 미스터리형. 영어는 후속 phase.
    // 미스터리 카피 풀 1회 로드 + topic-aware 를 위한 RecallFeedback pref 선읽기.
    final useMystery = saju != null && useKo;
    Map<String, double> userPrefById = const {};
    Map<String, int> shownDaysAgoById = const {};
    Set<String> suppressedIds = const {};
    if (useMystery) {
      await NotificationPoolService.ensureMysteryPoolLoaded();
      await TodayEventService.ensurePoolLoaded();
      final today0 = DateTime(now.year, now.month, now.day);
      final prefs = <String, double>{};
      final shown = <String, int>{};
      final suppressed = <String>{};
      for (final t in DailyTopic.values) {
        final st = await RecallFeedbackService.stateOf(t.id);
        prefs[t.id] = RecallFeedbackService.userPrefFromScore(st.score);
        if (st.lastShown != null) {
          shown[t.id] = today0.difference(st.lastShown!).inDays;
        }
        if (await RecallFeedbackService.isSuppressed(t.id, today0)) {
          suppressed.add(t.id);
        }
      }
      userPrefById = prefs;
      shownDaysAgoById = shown;
      suppressedIds = suppressed;
    }

    for (var i = 0; i < daysAhead; i++) {
      final target = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute, 0)
          .add(Duration(days: i));
      if (target.isBefore(now)) continue;
      String pickedTitle = title;
      String pickedBody = body;
      if (useMystery) {
        // Round 106 P2b — 매일 다른 일진 글자를 신비하게 던지는 미스터리형.
        // title 도 매일 다른 글자/주제 반영해 per-day 로 바뀐다.
        final dayDate = DateTime(target.year, target.month, target.day);
        final fortune = daily.calculate(saju, today: dayDate);
        final ctx = SajuContext.from(saju, today: dayDate);
        final event = TodayEventService.build(
          userDayStem: saju.dayPillar.chunGan,
          userDayBranch: saju.dayPillar.jiJi,
          userMonthBranch: saju.monthPillar.jiJi,
          todayPillar: fortune.dayPillar,
          todayScore: fortune.totalScore,
        );
        final selection = TopicSelectorService.select(
          saju: saju,
          ctx: ctx,
          event: event,
          date: dayDate,
          userPrefById: userPrefById,
          shownDaysAgoById: shownDaysAgoById,
          suppressedIds: suppressedIds,
        );
        // R106 P2b-fix — 거짓말 0: 그날 실제 계산된 일진 지지↔일지 관계
        // (event.hapChungType — TodayEventService 가 HapchungService 로 산출)를
        // pickMystery 로 넘긴다. body line1 의 차트 관계 표현이 실제 관계에
        // 강제 일치 — 실제 충일 때만 "부딪치는", 없으면 관계-중립 표현만.
        final relation =
            MysteryRelationKey.fromHapChungType(event.hapChungType);
        final copy = NotificationPoolService.pickMystery(
          date: dayDate,
          todayPillar: fortune.dayPillar,
          day60ji: saju.dayPillar.text,
          topicId: selection.selected?.id,
          relation: relation,
          dayOffset: i,
        );
        pickedTitle = copy.title;
        pickedBody = copy.body;
      } else if (saju != null) {
        // Round 76 sprint 6 — 매일 다른 일진 → 사주 기반 매일 다른 본문 (영어 등).
        final dayDate = DateTime(target.year, target.month, target.day);
        final fortune = daily.calculate(saju, today: dayDate);
        final picked = NotificationPoolService.pickDeep(
          date: dayDate,
          saju: saju,
          todayPillar: fortune.dayPillar,
          todayScore: fortune.totalScore,
        );
        pickedBody = useKo ? picked.ko : picked.en;
      } else if (day60ji != null && day60ji.isNotEmpty) {
        // R107 #3 — last-resort fallback. saju == null (사주 미상) 일 때만
        // 도달한다. 사주가 있으면 위 두 분기(미스터리/deep)가 항상 먼저
        // 잡으므로 계산 기반 알림이 기본 경로. 이 풀은 v5 voice(조건형 —
        // 사건/결과 단정 0)라 사주 미상에서도 거짓말 0.
        final picked = NotificationPoolService.pickFor(
          DateTime(target.year, target.month, target.day),
          day60ji,
          tone: tone,
        );
        pickedBody = useKo ? picked.ko : picked.en;
      }
      try {
        await _plugin.zonedSchedule(
          id: _kDailyId + i,
          title: pickedTitle,
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
      saju: saju,
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
    SajuResult? saju,
  }) =>
      scheduleDaily(
        title: title,
        body: body,
        day60ji: day60ji,
        useKo: useKo,
        daysAhead: daysAhead,
        hour: 8,
        minute: 0,
        saju: saju,
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
    SajuResult? saju,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrefsScheduleSig) != _scheduleSignature(
      title: title,
      body: body,
      day60ji: day60ji,
      useKo: useKo,
      hour: hour,
      minute: minute,
      saju: saju,
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
    SajuResult? saju,
  }) {
    // Round 76 sprint 6 — saju 의 derived key (dayPillar + monthBranch + dayMaster) 포함.
    // fallback↔deep 전환 시 signature mismatch → reschedule 보장.
    final sajuKey = saju == null
        ? 'nosaju'
        : 'deep:${saju.dayPillar.text}:${saju.monthPillar.jiJi}:${saju.dayMaster}';
    // R106 P2b-fix — 미스터리 알고리즘 버전 마커. 미스터리형으로 스케줄되는
    // 케이스(saju!=null && useKo)에만 박아, 알고리즘이 바뀌면 기존 enabled
    // 사용자의 needsReschedule 가 true 가 되어 새 미스터리 알림으로 갱신된다.
    final mysteryKey =
        (saju != null && useKo) ? '|$_kMysteryAlgoVersion' : '';
    return '${useKo ? 'ko' : 'en'}|$title|$body|${day60ji ?? ''}|'
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}|'
        '$sajuKey$mysteryKey';
  }
}
