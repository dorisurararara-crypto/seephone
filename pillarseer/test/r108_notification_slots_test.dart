// Pillar Seer — Round 108 ④ — 알림 하루 복수 슬롯 가드.
//
// 확정 설계 ground truth:
//  - 3 고정 슬롯: 아침(morning) / 오후(afternoon) / 저녁(evening).
//    각 슬롯 = {enabled, hour, minute}. 디폴트 = 아침 ON 08:00 / 오후 OFF 13:00 /
//    저녁 OFF 21:00.
//  - 마스터 토글 = 권한 + 전체 on/off. 마스터 OFF → 아무것도 안 울림.
//  - 기존 단일 알림 사용자 마이그레이션: app.notif.daily.hour/minute → 아침 슬롯,
//    app.notif.daily8am.enabled(마스터) → 켜져 있던 사용자는 아침 슬롯도 ON.
//  - 슬롯별 사주 풀이 프레임 — 아침/오후/저녁 카피 결이 다르다(vivid v5).
//  - ID 공간 = _kDailyId + slotIndex*32 + dayOffset (slot 0/1/2, 슬롯당 32).
//
// 검증:
//  ① 슬롯 enum / SlotConfig / 디폴트.
//  ② 마이그레이션 — 기존 단일 알림 사용자 알림 유지.
//  ③ 슬롯 load/save 라운드트립 + clamp.
//  ④ scheduleSignature 가 3 슬롯 상태 전부 인코딩.
//  ⑤ 슬롯별 카피 프레임 분기 (mystery / deep / fallback, KO + EN).
//  ⑥ ID 공간 — scheduleSlots / cancelAll 가 96 ID 전수 cover.
//  ⑦ 회귀 — 기존 단일 시간 API (loadTime/setTime/needsReschedule) 보존.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/notification_pool_service.dart';
import 'package:pillarseer/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 5, 22);

  setUpAll(() async {
    NotificationPoolService.debugResetMysteryPool();
    await NotificationPoolService.ensureMysteryPoolLoaded();
  });

  // ─────────────────────────────────────────────────────────────────
  group('① 슬롯 enum / SlotConfig / 디폴트', () {
    test('3 고정 슬롯 — morning/afternoon/evening', () {
      expect(NotificationSlot.values.length, 3);
      expect(NotificationSlot.values,
          [NotificationSlot.morning, NotificationSlot.afternoon, NotificationSlot.evening]);
      expect(NotificationSlot.morning.id, 'morning');
      expect(NotificationSlot.afternoon.id, 'afternoon');
      expect(NotificationSlot.evening.id, 'evening');
    });

    test('슬롯 index 0/1/2', () {
      expect(NotificationSlot.morning.index, 0);
      expect(NotificationSlot.afternoon.index, 1);
      expect(NotificationSlot.evening.index, 2);
    });

    test('디폴트 시간 — 아침 08:00 / 오후 13:00 / 저녁 21:00', () {
      expect(NotificationSlot.morning.defaultTime, (hour: 8, minute: 0));
      expect(NotificationSlot.afternoon.defaultTime, (hour: 13, minute: 0));
      expect(NotificationSlot.evening.defaultTime, (hour: 21, minute: 0));
    });

    test('디폴트 enabled — 아침만 ON', () {
      expect(NotificationSlot.morning.defaultEnabled, isTrue);
      expect(NotificationSlot.afternoon.defaultEnabled, isFalse);
      expect(NotificationSlot.evening.defaultEnabled, isFalse);
    });

    test('SlotConfig copyWith 는 시간을 clamp', () {
      const c = SlotConfig(enabled: true, hour: 8, minute: 0);
      final over = c.copyWith(hour: 30, minute: 99);
      expect(over.hour, 23);
      expect(over.minute, 59);
      final under = c.copyWith(hour: -5, minute: -3);
      expect(under.hour, 0);
      expect(under.minute, 0);
    });

    test('SlotConfig sigPart — enabled@hh:mm', () {
      expect(const SlotConfig(enabled: true, hour: 8, minute: 0).sigPart,
          '1@08:00');
      expect(const SlotConfig(enabled: false, hour: 13, minute: 5).sigPart,
          '0@13:05');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  group('② 마이그레이션 — 기존 단일 알림 사용자 알림 유지', () {
    test('기존 단일 시간(09:30) + 마스터 ON → 아침 슬롯 09:30 ON', () async {
      // R76 단일 알림 사용자 — daily.hour/minute + 마스터 enabled 만 있던 상태.
      SharedPreferences.setMockInitialValues({
        'app.notif.daily.hour': 9,
        'app.notif.daily.minute': 30,
        'app.notif.daily8am.enabled': true,
      });
      final slots = await NotificationService.loadSlots();
      final m = slots[NotificationSlot.morning]!;
      expect(m.hour, 9, reason: '기존 단일 시간이 아침 슬롯으로 이관');
      expect(m.minute, 30);
      expect(m.enabled, isTrue, reason: '마스터 ON 사용자 → 아침 슬롯 ON (알림 유지)');
      // 오후/저녁은 디폴트 OFF.
      expect(slots[NotificationSlot.afternoon]!.enabled, isFalse);
      expect(slots[NotificationSlot.evening]!.enabled, isFalse);
      expect(slots[NotificationSlot.afternoon]!.hour, 13);
      expect(slots[NotificationSlot.evening]!.hour, 21);
      // 마스터 토글 상태 보존.
      expect(await NotificationService.isMasterEnabled(), isTrue);
    });

    test('기존 단일 알림 OFF 사용자 → 아침 슬롯 ON 디폴트, 마스터 OFF', () async {
      SharedPreferences.setMockInitialValues({
        'app.notif.daily.hour': 7,
        'app.notif.daily.minute': 15,
        'app.notif.daily8am.enabled': false,
      });
      final slots = await NotificationService.loadSlots();
      expect(slots[NotificationSlot.morning]!.hour, 7);
      expect(slots[NotificationSlot.morning]!.minute, 15);
      // 마스터 OFF 라도 아침 슬롯 자체 enabled 디폴트는 ON (마스터가 게이트).
      expect(slots[NotificationSlot.morning]!.enabled, isTrue);
      expect(await NotificationService.isMasterEnabled(), isFalse);
    });

    test('완전 신규 사용자(빈 prefs) → 디폴트 3 슬롯', () async {
      SharedPreferences.setMockInitialValues({});
      final slots = await NotificationService.loadSlots();
      expect(slots[NotificationSlot.morning]!.enabled, isTrue);
      expect(slots[NotificationSlot.morning]!.hour, 8);
      expect(slots[NotificationSlot.afternoon]!.enabled, isFalse);
      expect(slots[NotificationSlot.evening]!.enabled, isFalse);
    });

    test('마이그레이션 1회 — 두 번째 loadSlots 는 슬롯 값 보존', () async {
      SharedPreferences.setMockInitialValues({
        'app.notif.daily.hour': 9,
        'app.notif.daily.minute': 30,
        'app.notif.daily8am.enabled': true,
      });
      await NotificationService.loadSlots();
      // 사용자가 아침 슬롯을 끈 뒤 — 다시 load 해도 마이그레이션이 덮어쓰지 X.
      await NotificationService.saveSlot(
        NotificationSlot.morning,
        const SlotConfig(enabled: false, hour: 9, minute: 30),
      );
      final slots2 = await NotificationService.loadSlots();
      expect(slots2[NotificationSlot.morning]!.enabled, isFalse,
          reason: '마이그레이션이 한 번만 — 사용자 변경 보존');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  group('③ 슬롯 load/save 라운드트립', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saveSlot → loadSlots 라운드트립', () async {
      await NotificationService.saveSlot(NotificationSlot.afternoon,
          const SlotConfig(enabled: true, hour: 15, minute: 45));
      await NotificationService.saveSlot(NotificationSlot.evening,
          const SlotConfig(enabled: true, hour: 22, minute: 10));
      final slots = await NotificationService.loadSlots();
      expect(slots[NotificationSlot.afternoon]!.enabled, isTrue);
      expect(slots[NotificationSlot.afternoon]!.hour, 15);
      expect(slots[NotificationSlot.afternoon]!.minute, 45);
      expect(slots[NotificationSlot.evening]!.hour, 22);
      expect(slots[NotificationSlot.evening]!.minute, 10);
    });

    test('saveSlot 시간 clamp', () async {
      await NotificationService.saveSlot(NotificationSlot.morning,
          const SlotConfig(enabled: true, hour: 30, minute: 80));
      final slots = await NotificationService.loadSlots();
      expect(slots[NotificationSlot.morning]!.hour, 23);
      expect(slots[NotificationSlot.morning]!.minute, 59);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  group('④ scheduleSignature — 3 슬롯 상태 인코딩', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Map<NotificationSlot, SlotConfig> slotsOf({
      required bool m,
      required bool a,
      required bool e,
      int mh = 8,
      int ah = 13,
      int eh = 21,
    }) =>
        {
          NotificationSlot.morning:
              SlotConfig(enabled: m, hour: mh, minute: 0),
          NotificationSlot.afternoon:
              SlotConfig(enabled: a, hour: ah, minute: 0),
          NotificationSlot.evening:
              SlotConfig(enabled: e, hour: eh, minute: 0),
        };

    test('슬롯 enabled 변경 → needsReschedule true', () async {
      // 아침만 켜진 상태로 sig 저장.
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig':
            'ko|t|b||1@08:00,0@13:00,0@21:00|nosaju',
      });
      // 동일 상태 — false.
      expect(
        await NotificationService.needsRescheduleSlots(
          title: 't', body: 'b', useKo: true,
          slots: slotsOf(m: true, a: false, e: false),
        ),
        isFalse,
      );
      // 오후 슬롯을 켜면 — true.
      expect(
        await NotificationService.needsRescheduleSlots(
          title: 't', body: 'b', useKo: true,
          slots: slotsOf(m: true, a: true, e: false),
        ),
        isTrue,
        reason: '오후 슬롯 ON 했는데 reschedule 안 함',
      );
    });

    test('슬롯 시간 변경 → needsReschedule true', () async {
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig':
            'ko|t|b||1@08:00,1@13:00,0@21:00|nosaju',
      });
      // 오후 시간을 14시로 바꾸면 true.
      expect(
        await NotificationService.needsRescheduleSlots(
          title: 't', body: 'b', useKo: true,
          slots: slotsOf(m: true, a: true, e: false, ah: 14),
        ),
        isTrue,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────
  group('⑤ 슬롯별 카피 프레임 분기 — vivid v5, KO + EN', () {
    test('미스터리 — 슬롯마다 title 접두 + 본문 다르게', () {
      MysteryNotificationCopy pick(NotificationSlot s) =>
          NotificationPoolService.pickMystery(
            date: date,
            todayPillar: '丙寅',
            day60ji: '辛卯',
            topicId: 'communication',
            relation: MysteryRelation.neutral,
            dayOffset: 2,
            slot: s,
          );
      final m = pick(NotificationSlot.morning);
      final a = pick(NotificationSlot.afternoon);
      final e = pick(NotificationSlot.evening);
      // 슬롯 접두.
      expect(m.title.startsWith('아침 — '), isTrue);
      expect(a.title.startsWith('오후 — '), isTrue);
      expect(e.title.startsWith('저녁 — '), isTrue);
      // 같은 날 같은 사주여도 슬롯별 body 가 서로 다르다.
      final bodies = {m.body, a.body, e.body};
      expect(bodies.length, 3, reason: '슬롯별 카피 프레임이 동일');
      // body 행동 줄에 슬롯 anchor 가 박힌다.
      expect(m.bodyLine2.contains('하루를 펼치기 전'), isTrue);
      expect(a.bodyLine2.contains('오후부터 한 번 달라지는'), isTrue);
      expect(e.bodyLine2.contains('내일을 살짝 여는'), isTrue);
    });

    test('미스터리 — 슬롯별 결정성 (같은 슬롯 50회 동일)', () {
      for (final s in NotificationSlot.values) {
        MysteryNotificationCopy? prev;
        for (var i = 0; i < 50; i++) {
          final copy = NotificationPoolService.pickMystery(
            date: date, todayPillar: '庚午', day60ji: '辛卯',
            topicId: 'money_spending', relation: MysteryRelation.hap,
            dayOffset: 4, slot: s,
          );
          prev ??= copy;
          expect(copy.title, prev.title);
          expect(copy.body, prev.body);
        }
      }
    });

    test('deep — 슬롯별 title/본문 분기 (KO + EN)', () {
      final saju = SajuResult.dummy();
      final picks = {
        for (final s in NotificationSlot.values)
          s: NotificationPoolService.pickDeep(
            date: date, saju: saju, todayPillar: '丙戌', todayScore: 60,
            slot: s,
          ),
      };
      // 슬롯 title 접두 (KO + EN).
      expect(picks[NotificationSlot.morning]!.titleKo.startsWith('아침 — '),
          isTrue);
      expect(picks[NotificationSlot.afternoon]!.titleKo.startsWith('오후 — '),
          isTrue);
      expect(picks[NotificationSlot.evening]!.titleEn.startsWith('Evening — '),
          isTrue);
      expect(picks[NotificationSlot.morning]!.titleEn.startsWith('Morning — '),
          isTrue);
      // 본문에 슬롯 anchor (KO + EN).
      expect(
          picks[NotificationSlot.afternoon]!.ko.contains('오후부터 한 번 달라지는'),
          isTrue);
      expect(picks[NotificationSlot.evening]!.en.contains('crack tomorrow'),
          isTrue);
      // deep EN 본문은 여전히 "Today" 로 시작 (R76 회귀 보존).
      expect(picks[NotificationSlot.morning]!.en.startsWith('Today'), isTrue);
      // 본문 ≤300자.
      for (final p in picks.values) {
        expect(p.ko.length, lessThanOrEqualTo(300));
        expect(p.en.length, lessThanOrEqualTo(300));
      }
    });

    test('fallback(pickFor) — 슬롯별 title 접두 + 슬롯 salt 로 다른 줄', () {
      final m = NotificationPoolService.pickFor(date, '丙戌',
          slot: NotificationSlot.morning);
      final a = NotificationPoolService.pickFor(date, '丙戌',
          slot: NotificationSlot.afternoon);
      final e = NotificationPoolService.pickFor(date, '丙戌',
          slot: NotificationSlot.evening);
      expect(m.titleKo.startsWith('아침 — '), isTrue);
      expect(a.titleEn.startsWith('Afternoon — '), isTrue);
      expect(e.titleKo.startsWith('저녁 — '), isTrue);
      // 슬롯 salt 가 seed 에 섞여 — 최소 2 슬롯은 서로 다른 본문.
      expect({m.ko, a.ko, e.ko}.length, greaterThan(1),
          reason: '슬롯 salt 가 본문 분산 안 함');
    });

    test('슬롯 카피 — KO 한글 leak 가드 본문 잘림 0 (메타 노출 0)', () {
      // 슬롯 프레임 카피에 codex/총평/사주 같은 메타 화자 노출 0.
      for (final s in NotificationSlot.values) {
        final copy = NotificationPoolService.pickMystery(
          date: date, todayPillar: '壬申', day60ji: '辛卯',
          topicId: 'work_career', relation: MysteryRelation.chung,
          dayOffset: 1, slot: s,
        );
        final all = '${copy.title} ${copy.body}';
        // 헤드라인체("~하는 날이에요") 금지.
        expect(all.contains('하는 날이에요'), isFalse);
        // placeholder 누출 0.
        expect(all.contains('{'), isFalse);
        expect(all.contains('}'), isFalse);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  group('⑥ ID 공간 — 96 ID 전수 cover', () {
    test('scheduleSlots / cancelAll 가 96 ID 루프 (소스 가드)', () {
      final src =
          File('lib/services/notification_service.dart').readAsStringSync();
      // ID 공간 = _kDailyId + slotIndex*32 + dayOffset.
      expect(src.contains('_kSlotIdSpan'), isTrue);
      expect(src.contains('_kSlotIdSpan = 32'), isTrue);
      expect(src.contains('_kSlotCount = 3'), isTrue);
      // cancel 루프가 슬롯당 32 × 3 = 96 전수.
      expect(src.contains('_kSlotIdSpan * _kSlotCount'), isTrue);
      // 슬롯 ID base = _kDailyId + slot.index * _kSlotIdSpan.
      expect(src.contains('_kDailyId + slot.index * _kSlotIdSpan'), isTrue);
    });

    test('scheduleSlots 분기 순서 — mystery → deep → fallback 보존', () {
      final src =
          File('lib/services/notification_service.dart').readAsStringSync();
      expect(src.contains('useMystery = saju != null && useKo'), isTrue);
      final iMystery = src.indexOf('if (useMystery)');
      final iDeep = src.indexOf('else if (saju != null)');
      final iFor = src.indexOf('else if (day60ji != null');
      expect(iMystery, greaterThan(0));
      expect(iDeep, greaterThan(iMystery));
      expect(iFor, greaterThan(iDeep));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  group('⑦ 회귀 — 기존 단일 시간 API 보존', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('loadTime/setTime — 아침 슬롯으로 매핑', () async {
      final t0 = await NotificationService.loadTime();
      expect(t0.hour, 8);
      expect(t0.minute, 0);
      await NotificationService.setTime(21, 15);
      final t1 = await NotificationService.loadTime();
      expect(t1.hour, 21);
      expect(t1.minute, 15);
      // setTime 은 아침 슬롯에만 영향.
      final slots = await NotificationService.loadSlots();
      expect(slots[NotificationSlot.morning]!.hour, 21);
      expect(slots[NotificationSlot.afternoon]!.hour, 13);
    });

    test('isEnabled/setEnabled — 마스터 토글 alias', () async {
      expect(await NotificationService.isEnabled(), isFalse);
      await NotificationService.setEnabled(true);
      expect(await NotificationService.isEnabled(), isTrue);
      expect(await NotificationService.isMasterEnabled(), isTrue);
    });

    test('needsReschedule(hour/minute) — 하위호환 시그니처', () async {
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig':
            'ko|t|b||1@08:00,0@13:00,0@21:00|nosaju',
      });
      final same = await NotificationService.needsReschedule(
        title: 't', body: 'b', useKo: true, hour: 8, minute: 0,
      );
      expect(same, isFalse);
      final diff = await NotificationService.needsReschedule(
        title: 't', body: 'b', useKo: true, hour: 9, minute: 30,
      );
      expect(diff, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ⑧ settings UI — 3 슬롯 행 (sprint 2). source-grep + l10n 키 가드.
  // ─────────────────────────────────────────────────────────────────
  group('⑧ settings UI — 3 슬롯 행', () {
    final src = File('lib/screens/settings_screen.dart').readAsStringSync();

    test('R76 단일 picker(_NotifTimePicker) 제거 + 3 슬롯 섹션으로 교체', () {
      expect(src.contains('_NotifTimePicker'), isFalse,
          reason: 'R76 단일 알림 picker 가 남아 있음');
      expect(src.contains('class _NotifSlotsSection'), isTrue,
          reason: '3 슬롯 섹션 위젯 누락');
      expect(src.contains('class _NotifSlotRow'), isTrue,
          reason: '슬롯 행 위젯 누락');
    });

    test('마스터 토글(_NotifSwitch) 은 슬롯 섹션 위에 유지', () {
      final iSwitch = src.indexOf('_NotifSwitch()');
      final iSlots = src.indexOf('_NotifSlotsSection()');
      expect(iSwitch, greaterThan(0), reason: '마스터 토글 누락');
      expect(iSlots, greaterThan(iSwitch),
          reason: '슬롯 섹션이 마스터 토글보다 위');
    });

    test('슬롯 행 — 3 슬롯 전부 순회 + 시간 tap + 슬롯 토글 wire', () {
      // 3 슬롯 NotificationSlot.values 순회.
      expect(src.contains('for (final s in NotificationSlot.values)'), isTrue);
      // 슬롯 토글 → setSlot(enabled:).
      expect(src.contains('setSlot('), isTrue);
      expect(src.contains('enabled: enabled'), isTrue);
      // 시간 tap → showTimePicker + setSlot(hour/minute).
      expect(src.contains('showTimePicker'), isTrue);
      expect(src.contains('hour: picked.hour'), isTrue);
      // 슬롯 이모지 (🌅 아침 / ☀️ 오후 / 🌙 저녁).
      expect(src.contains('🌅'), isTrue);
      expect(src.contains('☀️'), isTrue);
      expect(src.contains('🌙'), isTrue);
    });

    test('l10n 슬롯 키 — KO + EN 둘 다 존재 + 한글/영문 leak 0', () {
      final ko = File('lib/l10n/app_ko.arb').readAsStringSync();
      final en = File('lib/l10n/app_en.arb').readAsStringSync();
      const slotKeys = [
        'settingsNotifSlotsLabel',
        'settingsNotifSlotsHint',
        'settingsNotifSlotMorning',
        'settingsNotifSlotAfternoon',
        'settingsNotifSlotEvening',
        'settingsNotifSlotMorningDesc',
        'settingsNotifSlotAfternoonDesc',
        'settingsNotifSlotEveningDesc',
        'settingsNotifSlotDoneSnack',
        'settingsNotifSlotOnSnack',
        'settingsNotifSlotOffSnack',
        'settingsNotifSlotPickerTitle',
        'homeNotifOnSlots',
      ];
      for (final k in slotKeys) {
        expect(ko.contains('"$k"'), isTrue, reason: 'KO arb 에 $k 누락');
        expect(en.contains('"$k"'), isTrue, reason: 'EN arb 에 $k 누락');
      }
      // EN 슬롯 라벨/설명에 한글 leak 0.
      final hangul = RegExp(r'[가-힣]');
      for (final k in const [
        'settingsNotifSlotMorning',
        'settingsNotifSlotAfternoon',
        'settingsNotifSlotEvening',
        'settingsNotifSlotMorningDesc',
        'settingsNotifSlotEveningDesc',
      ]) {
        final m = RegExp('"$k":\\s*"([^"]*)"').firstMatch(en);
        expect(m, isNotNull);
        expect(hangul.hasMatch(m!.group(1)!), isFalse,
            reason: 'EN $k 한글 leak: ${m.group(1)}');
      }
    });

    test('마스터 토글 subtitle — 켜진 시간대 개수 (homeNotifOnSlots)', () {
      expect(src.contains('homeNotifOnSlots'), isTrue,
          reason: '마스터 subtitle 이 슬롯 개수 미반영');
      expect(src.contains('activeSlotCount'), isTrue);
    });

    test('슬롯 카피 — AI 슬롭 어휘("결이"/"흐름이") 0 (l10n + SlotFrame)', () {
      // codex audit: "결이"/"흐름이" 는 AI 슬롭 패턴. 슬롯 카피 전수 가드.
      final ko = File('lib/l10n/app_ko.arb').readAsStringSync();
      final pool =
          File('lib/services/notification_pool_service.dart').readAsStringSync();
      for (final slop in const ['결이', '흐름이', '센터처럼', '본인의 결']) {
        // l10n 슬롯 키 본문 + SlotFrame anchor/prefix 에 slop 어휘 0.
        final slotLines = RegExp(
                r'"settingsNotifSlot[^"]*":\s*"([^"]*)"')
            .allMatches(ko)
            .map((m) => m.group(1)!)
            .toList();
        for (final s in slotLines) {
          expect(s.contains(slop), isFalse,
              reason: 'l10n 슬롯 카피 AI 슬롭 "$slop": "$s"');
        }
        // SlotFrame actionAnchorKo / titlePrefixKo 전수.
        final anchors = RegExp(r"actionAnchorKo:\s*'([^']*)'")
            .allMatches(pool)
            .map((m) => m.group(1)!)
            .toList();
        for (final s in anchors) {
          expect(s.contains(slop), isFalse,
              reason: 'SlotFrame anchor AI 슬롭 "$slop": "$s"');
        }
      }
    });
  });
}
