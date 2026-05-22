// Pillar Seer — 일일 운세 알림. flutter_local_notifications + timezone.
// R108 ④ — 하루 1회 → 3 고정 슬롯(아침/오후/저녁)으로 확장.
//   각 슬롯 = {enabled, hour, minute}. 마스터 토글이 권한 + 전체 on/off.
//   마스터 ON 일 때 enabled 인 슬롯만 매일 울린다.
//   기존 단일 알림 사용자는 마이그레이션으로 아침 슬롯에 그대로 이관 (알림 유지).

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

/// R108 ④ — 하루 알림 슬롯. 3 고정: 아침 / 오후 / 저녁.
/// 슬롯마다 다른 사주 풀이 프레임(아침 = 하루 미리보기, 오후 = 결이 바뀜,
/// 저녁 = 하루 마무리 + 내일 살짝)으로 같은 날도 카피가 다르게 나간다.
enum NotificationSlot { morning, afternoon, evening }

extension NotificationSlotMeta on NotificationSlot {
  /// SharedPreferences key prefix + signature 식별자.
  String get id {
    switch (this) {
      case NotificationSlot.morning:
        return 'morning';
      case NotificationSlot.afternoon:
        return 'afternoon';
      case NotificationSlot.evening:
        return 'evening';
    }
  }

  /// ID 공간 / cancel loop / signature 순서용 인덱스 (0/1/2).
  int get index => NotificationSlot.values.indexOf(this);

  /// 디폴트 시간 — 아침 08:00 / 오후 13:00 / 저녁 21:00.
  ({int hour, int minute}) get defaultTime {
    switch (this) {
      case NotificationSlot.morning:
        return (hour: 8, minute: 0);
      case NotificationSlot.afternoon:
        return (hour: 13, minute: 0);
      case NotificationSlot.evening:
        return (hour: 21, minute: 0);
    }
  }

  /// 디폴트 enabled — 아침만 ON.
  bool get defaultEnabled => this == NotificationSlot.morning;
}

/// 한 슬롯의 설정 — enabled + 시간. immutable.
class SlotConfig {
  final bool enabled;
  final int hour;
  final int minute;
  const SlotConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  SlotConfig copyWith({bool? enabled, int? hour, int? minute}) => SlotConfig(
        enabled: enabled ?? this.enabled,
        hour: (hour ?? this.hour).clamp(0, 23),
        minute: (minute ?? this.minute).clamp(0, 59),
      );

  /// signature 조각 — "{enabled}@{hh}:{mm}".
  String get sigPart =>
      '${enabled ? '1' : '0'}@${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 마스터 토글 — 권한 + 전체 on/off. (기존 키 재사용 — 마이그레이션 호환.)
  static const _kPrefsMaster = 'app.notif.daily8am.enabled';
  static const _kPrefsScheduleSig = 'app.notif.daily8am.scheduleSig';

  /// R76 단일 슬롯 시절 키 — 마이그레이션 source 로만 읽는다.
  static const _kLegacyHour = 'app.notif.daily.hour';
  static const _kLegacyMinute = 'app.notif.daily.minute';

  /// R108 — 슬롯별 키. `{prefix}.{slotId}.enabled/.hour/.minute`.
  static const _kSlotPrefix = 'app.notif.slot';

  /// 마이그레이션 1회 완료 마커.
  static const _kMigrated = 'app.notif.r108.migrated';

  /// 슬롯당 ID 예산 32 (30일 + 여유). 3 슬롯 = 96 ID (8888~8983).
  static const int _kDailyId = 8888;
  static const int _kSlotIdSpan = 32;
  static const int _kSlotCount = 3;

  /// R106 P2b-fix — 미스터리 알림 알고리즘/풀 버전 마커.
  /// scheduleSignature 에 박혀, 이 값이 바뀌면 기존 enabled 사용자도
  /// needsReschedule==true 가 되어 새 미스터리 알림으로 자동 재스케줄된다.
  ///   v1 = R106 P2b 초판 (static per-topic interactions).
  ///   v2 = R106 P2b-fix (relation-aware interactions — 거짓말 0).
  ///   v3 = R108 ④ 슬롯별 사주 풀이 프레임 (아침/오후/저녁).
  static const String _kMysteryAlgoVersion = 'mystery_v3';

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

  // ──────────────────── R108 슬롯 영속 (load / save) ────────────────────

  static String _slotKey(NotificationSlot s, String field) =>
      '$_kSlotPrefix.${s.id}.$field';

  /// R108 — 기존 단일 알림 사용자를 3 슬롯 모델로 1회 이관.
  /// 기존 `app.notif.daily.hour/minute` → 아침 슬롯 시간.
  /// 기존 마스터 enabled → 아침 슬롯도 enabled (업데이트 후 알림 유지).
  /// 마커가 이미 있으면 no-op.
  static Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_kMigrated) ?? false) return;

    // 슬롯 키가 이미 하나라도 있으면(신규 설치 후 이미 슬롯 사용) 마커만 찍는다.
    final alreadyHasSlots = prefs.containsKey(
      _slotKey(NotificationSlot.morning, 'hour'),
    );
    if (!alreadyHasSlots) {
      // 기존 단일 시간 — 없으면 아침 디폴트 08:00.
      final legacyHour =
          (prefs.getInt(_kLegacyHour) ?? NotificationSlot.morning.defaultTime.hour)
              .clamp(0, 23);
      final legacyMinute = (prefs.getInt(_kLegacyMinute) ??
              NotificationSlot.morning.defaultTime.minute)
          .clamp(0, 59);
      // 기존 마스터가 켜져 있던 사용자 → 아침 슬롯도 켠다 (알림 끊김 방지).
      final masterOn = prefs.getBool(_kPrefsMaster) ?? false;

      for (final s in NotificationSlot.values) {
        final isMorning = s == NotificationSlot.morning;
        final t = isMorning
            ? (hour: legacyHour, minute: legacyMinute)
            : s.defaultTime;
        // 아침: 기존 마스터 ON 이면 ON, 아니면 디폴트(ON). 오후/저녁: 디폴트 OFF.
        final enabled = isMorning ? (masterOn || s.defaultEnabled) : s.defaultEnabled;
        await prefs.setBool(_slotKey(s, 'enabled'), enabled);
        await prefs.setInt(_slotKey(s, 'hour'), t.hour);
        await prefs.setInt(_slotKey(s, 'minute'), t.minute);
      }
    }
    await prefs.setBool(_kMigrated, true);
  }

  /// 3 슬롯 설정 로드 (마이그레이션 포함). 항상 3 entry 반환.
  static Future<Map<NotificationSlot, SlotConfig>> loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded(prefs);
    final out = <NotificationSlot, SlotConfig>{};
    for (final s in NotificationSlot.values) {
      final d = s.defaultTime;
      out[s] = SlotConfig(
        enabled: prefs.getBool(_slotKey(s, 'enabled')) ?? s.defaultEnabled,
        hour: (prefs.getInt(_slotKey(s, 'hour')) ?? d.hour).clamp(0, 23),
        minute: (prefs.getInt(_slotKey(s, 'minute')) ?? d.minute).clamp(0, 59),
      );
    }
    return out;
  }

  /// 한 슬롯 설정 저장.
  static Future<void> saveSlot(NotificationSlot s, SlotConfig c) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded(prefs);
    await prefs.setBool(_slotKey(s, 'enabled'), c.enabled);
    await prefs.setInt(_slotKey(s, 'hour'), c.hour.clamp(0, 23));
    await prefs.setInt(_slotKey(s, 'minute'), c.minute.clamp(0, 59));
  }

  // ──────────────────── 스케줄링 (3 슬롯) ────────────────────

  /// 3 고정 슬롯 × 매일 알림 등록. 마스터 ON + enabled 인 슬롯만 울린다.
  /// codex R7 fix: 각 일자별 explicit schedule — 사용자가 시간 변경/슬롯 토글
  /// 시 OS 캐싱 패턴이 안 깨지게 per-day schedule 유지.
  /// day60ji null 시 fallback fixed body 사용.
  static Future<void> scheduleSlots({
    required String title,
    required String body,
    required Map<NotificationSlot, SlotConfig> slots,
    String? day60ji,
    bool useKo = false,
    int daysAhead = 30,
    SajuResult? saju, // 있으면 미스터리/deep 계산 본문.
  }) async {
    await ensureInitialized();
    // 전체 슬롯 ID 공간 전수 cancel (0..95) — 슬롯 OFF→ON / 시간 변경 모두 커버.
    for (var i = 0; i < _kSlotIdSpan * _kSlotCount; i++) {
      try {
        await _plugin.cancel(id: _kDailyId + i);
      } catch (_) {}
    }

    final daily = DailyService();
    final now = tz.TZDateTime.now(tz.local);

    // R106 P2b — 미스터리형: saju + useKo 둘 다일 때만. 영어는 deep 경로.
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

    for (final slot in NotificationSlot.values) {
      final cfg = slots[slot];
      if (cfg == null || !cfg.enabled) continue;
      await _scheduleOneSlot(
        slot: slot,
        cfg: cfg,
        title: title,
        body: body,
        day60ji: day60ji,
        useKo: useKo,
        daysAhead: daysAhead,
        saju: saju,
        useMystery: useMystery,
        daily: daily,
        now: now,
        userPrefById: userPrefById,
        shownDaysAgoById: shownDaysAgoById,
        suppressedIds: suppressedIds,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsScheduleSig,
      _scheduleSignature(
        title: title,
        body: body,
        day60ji: day60ji,
        useKo: useKo,
        slots: slots,
        saju: saju,
      ),
    );
  }

  /// 한 슬롯의 daysAhead 일분 explicit schedule.
  static Future<void> _scheduleOneSlot({
    required NotificationSlot slot,
    required SlotConfig cfg,
    required String title,
    required String body,
    required String? day60ji,
    required bool useKo,
    required int daysAhead,
    required SajuResult? saju,
    required bool useMystery,
    required DailyService daily,
    required tz.TZDateTime now,
    required Map<String, double> userPrefById,
    required Map<String, int> shownDaysAgoById,
    required Set<String> suppressedIds,
  }) async {
    final idBase = _kDailyId + slot.index * _kSlotIdSpan;
    for (var i = 0; i < daysAhead; i++) {
      final target = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        cfg.hour,
        cfg.minute,
        0,
      ).add(Duration(days: i));
      if (target.isBefore(now)) continue;

      String pickedTitle = title;
      String pickedBody = body;
      if (useMystery) {
        final dayDate = DateTime(target.year, target.month, target.day);
        final fortune = daily.calculate(saju!, today: dayDate);
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
        final relation =
            MysteryRelationKey.fromHapChungType(event.hapChungType);
        // R108 ④ — 슬롯별 풀이 프레임. 같은 날이라도 아침/오후/저녁 카피가 다르게.
        final copy = NotificationPoolService.pickMystery(
          date: dayDate,
          todayPillar: fortune.dayPillar,
          day60ji: saju.dayPillar.text,
          topicId: selection.selected?.id,
          relation: relation,
          dayOffset: i,
          slot: slot,
        );
        pickedTitle = copy.title;
        pickedBody = copy.body;
      } else if (saju != null) {
        final dayDate = DateTime(target.year, target.month, target.day);
        final fortune = daily.calculate(saju, today: dayDate);
        final picked = NotificationPoolService.pickDeep(
          date: dayDate,
          saju: saju,
          todayPillar: fortune.dayPillar,
          todayScore: fortune.totalScore,
          slot: slot,
        );
        pickedTitle = useKo ? picked.titleKo : picked.titleEn;
        pickedBody = useKo ? picked.ko : picked.en;
      } else if (day60ji != null && day60ji.isNotEmpty) {
        // last-resort fallback — saju 미상일 때만.
        final picked = NotificationPoolService.pickFor(
          DateTime(target.year, target.month, target.day),
          day60ji,
          slot: slot,
        );
        pickedTitle = useKo ? picked.titleKo : picked.titleEn;
        pickedBody = useKo ? picked.ko : picked.en;
      }

      try {
        await _plugin.zonedSchedule(
          id: idBase + i,
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
        if (kDebugMode) print('schedule[$slot/$i] failed: $e');
        break;
      }
    }
  }

  static Future<void> cancelAll() async {
    await ensureInitialized();
    for (var i = 0; i < _kSlotIdSpan * _kSlotCount; i++) {
      try {
        await _plugin.cancel(id: _kDailyId + i);
      } catch (_) {}
    }
  }

  static Future<bool> isMasterEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPrefsMaster) ?? false;
  }

  static Future<void> setMasterEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsMaster, value);
  }

  /// 마스터 토글 — 하위호환 alias (기존 호출부·테스트 보존).
  static Future<bool> isEnabled() => isMasterEnabled();
  static Future<void> setEnabled(bool value) => setMasterEnabled(value);

  /// 하위호환 — 단일 알림 시간 = 아침 슬롯 시간.
  /// R76 시절 키가 남아 있으면 그대로, 없으면 아침 슬롯에서 읽는다.
  static Future<({int hour, int minute})> loadTime() async {
    final slots = await loadSlots();
    final m = slots[NotificationSlot.morning]!;
    return (hour: m.hour.clamp(0, 23), minute: m.minute.clamp(0, 59));
  }

  /// 하위호환 — 단일 알림 시간 설정 = 아침 슬롯 시간 변경.
  static Future<void> setTime(int hour, int minute) async {
    final slots = await loadSlots();
    final m = slots[NotificationSlot.morning]!;
    await saveSlot(
      NotificationSlot.morning,
      m.copyWith(hour: hour, minute: minute),
    );
  }

  /// R108 — 3 슬롯 기반 needsReschedule.
  static Future<bool> needsRescheduleSlots({
    required String title,
    required String body,
    String? day60ji,
    required bool useKo,
    required Map<NotificationSlot, SlotConfig> slots,
    SajuResult? saju,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPrefsScheduleSig) !=
        _scheduleSignature(
          title: title,
          body: body,
          day60ji: day60ji,
          useKo: useKo,
          slots: slots,
          saju: saju,
        );
  }

  /// 하위호환 — 단일 hour/minute 시그니처. 아침 슬롯만 enabled 로 본 signature 와
  /// 비교한다 (R76 테스트·기존 호출부 보존). 신규 코드는 slots 버전을 쓴다.
  static Future<bool> needsReschedule({
    required String title,
    required String body,
    String? day60ji,
    required bool useKo,
    int? hour,
    int? minute,
    Map<NotificationSlot, SlotConfig>? slots,
    SajuResult? saju,
  }) async {
    final effective = slots ??
        {
          for (final s in NotificationSlot.values)
            s: s == NotificationSlot.morning
                ? SlotConfig(
                    enabled: true,
                    hour: hour ?? s.defaultTime.hour,
                    minute: minute ?? s.defaultTime.minute,
                  )
                : SlotConfig(
                    enabled: false,
                    hour: s.defaultTime.hour,
                    minute: s.defaultTime.minute,
                  ),
        };
    return needsRescheduleSlots(
      title: title,
      body: body,
      day60ji: day60ji,
      useKo: useKo,
      slots: effective,
      saju: saju,
    );
  }

  static String _scheduleSignature({
    required String title,
    required String body,
    String? day60ji,
    required bool useKo,
    required Map<NotificationSlot, SlotConfig> slots,
    SajuResult? saju,
  }) {
    // saju derived key (dayPillar + monthBranch + dayMaster) — fallback↔deep
    // 전환 시 signature mismatch → reschedule 보장.
    final sajuKey = saju == null
        ? 'nosaju'
        : 'deep:${saju.dayPillar.text}:${saju.monthPillar.jiJi}:${saju.dayMaster}';
    // R106 P2b-fix — 미스터리 알고리즘 버전 마커.
    final mysteryKey =
        (saju != null && useKo) ? '|$_kMysteryAlgoVersion' : '';
    // R108 — 3 슬롯 enabled/시간 전부 signature 에 포함 (슬롯 변경 시 reschedule).
    final slotKey = NotificationSlot.values
        .map((s) => slots[s]?.sigPart ?? '0@--:--')
        .join(',');
    return '${useKo ? 'ko' : 'en'}|$title|$body|${day60ji ?? ''}|'
        '$slotKey|$sajuKey$mysteryKey';
  }
}
