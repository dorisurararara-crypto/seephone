// Round 107 today_v5_en — 오늘의 사주 v5 영어 모드 갭 일소 검증.
//
// 문제 (영어 모드 갭):
//  - today_v5(R106 P2a) 가 한국어 전용. today_v5_pool.json 의 10주제 × 4슬롯
//    (headline/structure/trigger/action) 변주가 전부 한국어.
//  - today_v5_service / today_v5_section / today_v5_loader 에 useKo 분기 0개.
//  → 영어 모드에서 today_v5 가 한국어로 새거나 안 뜬다.
//
// today_v5_en fix:
//  - today_v5_pool.json 각 주제·슬롯에 *En 영어 변주 6종 추가 (한국어 키 불변).
//  - TodayV5Service.build(useKo: false) → *En slot / 영어 라벨 / 영어 fallback.
//  - TodayV5Section / TodayV5Loader 가 Localizations 로 useKo 분기.
//
// 검증:
//  E1 — pool: 10 주제 × 4 슬롯 모두 *En 변주 ≥ 6, 변주끼리 중복 0.
//  E2 — pool: no_signal_fallback 도 *En 변주 ≥ 4.
//  E3 — 영어 변주 안 한글 누출 0 (전 변주).
//  E4 — 영어 변주 안 한자 jargon 단독 노출 0.
//  E5 — v5 voice: 영어 단정 금지어(will/always/definitely/guarantee 등) 0.
//  E6 — 영어 trigger 변주는 전부 조건형("If").
//  E7 — build(useKo:false) → 영어 reading, 한글 leak 0, 10 주제 전부.
//  E8 — build(useKo:false) fallback → 영어, 한글 leak 0.
//  E9 — 한국어 키 불변 (회귀) — 기존 ko slot 변주 ≥ 6 그대로.
//  E10 — build(useKo:true) 회귀 — 한국어 reading 그대로 (DayEnergy/today 무관).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/today_event_service.dart';
import 'package:pillarseer/services/today_v5_service.dart';
import 'package:pillarseer/services/topic_selector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hangul = RegExp(r'[가-힣]');
  const rawGanji = '甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥';

  // ── 영어 단정 금지 패턴군 — v5 voice (단정 0, 메타 0). ──
  // trigger 는 조건형이므로 'If' 절 안에서는 'will' 류 미허용은 동일하게 적용.
  final forbiddenEn = <RegExp>[
    RegExp(r'\bwill\b', caseSensitive: false),
    RegExp(r'\balways\b', caseSensitive: false),
    RegExp(r'\bnever\b', caseSensitive: false),
    RegExp(r'\bdefinitely\b', caseSensitive: false),
    RegExp(r'\bcertainly\b', caseSensitive: false),
    RegExp(r'\bguarantee', caseSensitive: false),
    RegExp(r'\bmust\s+happen', caseSensitive: false),
    RegExp(r'\byou\s+are\s+going\s+to\b', caseSensitive: false),
    RegExp(r'100%'),
    // 메타 금지 — 카피가 자기 자신/장르를 가리키는 표현.
    RegExp(r'\bfortune-?telling\b', caseSensitive: false),
    RegExp(r'\bthis\s+reading\b', caseSensitive: false),
  ];

  void assertNoVerdictEn(String text, {required String where}) {
    for (final p in forbiddenEn) {
      expect(p.hasMatch(text), isFalse,
          reason: '$where 에 영어 단정/금칙 /${p.pattern}/ 매치\n본문: "$text"');
    }
  }

  group('today_v5_en — pool 영어 변주', () {
    late Map<String, dynamic> pool;

    setUpAll(() {
      final file = File('assets/data/today_v5_pool.json');
      expect(file.existsSync(), isTrue, reason: 'today_v5_pool.json 없음');
      pool = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('E1 — 10 주제 × 4 슬롯 모두 *En 변주 ≥ 6 + 중복 0', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      expect(topics.length, 10, reason: '주제는 10개');
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          final enSlot = '${slot}En';
          expect(bucket.containsKey(enSlot), isTrue,
              reason: 'topics.${entry.key}.$enSlot 없음');
          final list = bucket[enSlot] as List;
          expect(list.length, greaterThanOrEqualTo(6),
              reason: 'topics.${entry.key}.$enSlot 변주 ${list.length}개 (<6)');
          final set = list.map((e) => e as String).toSet();
          expect(set.length, list.length,
              reason: 'topics.${entry.key}.$enSlot 에 중복 변주 존재');
        }
      }
    });

    test('E2 — no_signal_fallback 도 *En 변주 ≥ 4', () {
      final fb = pool['no_signal_fallback'] as Map<String, dynamic>;
      for (final slot in ['headline', 'structure', 'trigger', 'action']) {
        final list = fb['${slot}En'] as List;
        expect(list.length, greaterThanOrEqualTo(4),
            reason: 'no_signal_fallback.${slot}En 변주 ${list.length}개 (<4)');
      }
    });

    test('E3 — 영어 변주 안 한글 누출 0 (전 변주)', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          for (final s in (bucket['${slot}En'] as List)) {
            expect(hangul.hasMatch(s as String), isFalse,
                reason: 'topics.${entry.key}.${slot}En 에 한글 leak: $s');
          }
        }
      }
      final fb = pool['no_signal_fallback'] as Map<String, dynamic>;
      for (final slot in ['headline', 'structure', 'trigger', 'action']) {
        for (final s in (fb['${slot}En'] as List)) {
          expect(hangul.hasMatch(s as String), isFalse,
              reason: 'no_signal_fallback.${slot}En 에 한글 leak: $s');
        }
      }
    });

    test('E4 — 영어 변주 안 한자 jargon 단독 노출 0', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          for (final s in (bucket['${slot}En'] as List)) {
            for (final ch in rawGanji.split('')) {
              expect((s as String).contains(ch), isFalse,
                  reason: 'topics.${entry.key}.${slot}En 에 한자 "$ch" 노출');
            }
          }
        }
      }
    });

    test('E5 — 영어 변주 전수 단정/메타 금지어 0', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          final list = bucket['${slot}En'] as List;
          for (var i = 0; i < list.length; i++) {
            assertNoVerdictEn(list[i] as String,
                where: 'topics.${entry.key}.${slot}En[$i]');
          }
        }
      }
      final fb = pool['no_signal_fallback'] as Map<String, dynamic>;
      for (final slot in ['headline', 'structure', 'trigger', 'action']) {
        final list = fb['${slot}En'] as List;
        for (var i = 0; i < list.length; i++) {
          assertNoVerdictEn(list[i] as String,
              where: 'no_signal_fallback.${slot}En[$i]');
        }
      }
    });

    test('E6 — 영어 trigger 변주는 전부 조건형("If")', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final list = (entry.value as Map<String, dynamic>)['triggerEn'] as List;
        for (var i = 0; i < list.length; i++) {
          expect((list[i] as String).trimLeft().startsWith('If '), isTrue,
              reason: 'topics.${entry.key}.triggerEn[$i] 조건형(If) 아님');
        }
      }
      final fbTrig =
          (pool['no_signal_fallback'] as Map<String, dynamic>)['triggerEn']
              as List;
      for (var i = 0; i < fbTrig.length; i++) {
        expect((fbTrig[i] as String).trimLeft().startsWith('If '), isTrue,
            reason: 'no_signal_fallback.triggerEn[$i] 조건형(If) 아님');
      }
    });

    test('E9 — 한국어 키 불변 회귀 — 기존 ko slot 변주 ≥ 6 그대로', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          final list = bucket[slot] as List;
          expect(list.length, greaterThanOrEqualTo(6),
              reason: 'topics.${entry.key}.$slot (ko) 변주 회귀: ${list.length}');
          // 한국어 변주는 한글을 포함해야 (영어로 바뀌지 않았음 확인).
          expect(hangul.hasMatch(list.first as String), isTrue,
              reason: 'topics.${entry.key}.$slot (ko) 가 영어로 오염됨');
        }
      }
    });
  });

  group('today_v5_en — build(useKo:false) 영어 산출', () {
    setUp(() {
      TodayV5Service.debugResetPool();
    });

    SajuResult makeSaju() => SajuResult(
          yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
          monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'),
          dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
          hourPillar: const Pillar(chunGan: '丁', jiJi: '酉'),
          elements:
              const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
          dayMaster: '辛',
          dayMasterName: 'Test',
          summary: '',
          categoryReadings: const {},
        );

    TopicSelection forced(DailyTopic topic) => TopicSelection(
          selected: topic,
          candidates: [
            TopicCandidate(
              topic: topic,
              evidence: const [],
              breakdown: const TopicScoreBreakdown(
                signalStrength: 1,
                userPref: 0.5,
                freshness: 1,
                exploration: 0,
                finalScore: 1,
              ),
              byStrongSingle: true,
            ),
          ],
          belowThreshold: const [],
          chartKey: 'forced',
        );

    test('E7 — 10 주제 전부 영어 reading, 한글 leak 0', () async {
      await TodayV5Service.ensurePoolLoaded();
      final saju = makeSaju();
      final event = TodayEventService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      for (final topic in DailyTopic.values) {
        final reading = TodayV5Service.build(
          saju: saju,
          selection: forced(topic),
          event: event,
          chartSeed: 12345,
          useKo: false,
        );
        expect(reading.topic, topic);
        // 4 슬롯 모두 비어있지 않음.
        expect(reading.headline.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 영어 헤드라인 비어있음');
        expect(reading.structureLine.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 영어 구조 비어있음');
        expect(reading.triggerLine.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 영어 발동조건 비어있음');
        expect(reading.actionLine.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 영어 행동 비어있음');
        // 한글 leak 0 — 헤드라인/본문/주제라벨/근거칩 전부.
        final all = [
          reading.headline,
          reading.structureLine,
          reading.triggerLine,
          reading.actionLine,
          reading.topicLabel,
          for (final c in reading.evidenceChips) ...[c.label, c.text],
        ];
        for (final t in all) {
          expect(hangul.hasMatch(t), isFalse,
              reason: '${topic.id} 영어 reading 한글 leak: $t');
          for (final ch in rawGanji.split('')) {
            expect(t.contains(ch), isFalse,
                reason: '${topic.id} 영어 reading 한자 leak "$ch": $t');
          }
        }
        // v5 voice — 단정/메타 금지어 0.
        assertNoVerdictEn(reading.headline, where: '${topic.id} 영어 헤드라인');
        assertNoVerdictEn(reading.structureLine, where: '${topic.id} 영어 구조');
        assertNoVerdictEn(reading.actionLine, where: '${topic.id} 영어 행동');
        // 주제 라벨이 영어.
        expect(reading.topicLabel, TodayV5Service.topicLabelEn(topic));
        // 근거 칩은 항상 3개.
        expect(reading.evidenceChips.length, 3,
            reason: '${topic.id} 근거 칩 3개 아님');
      }
    });

    test('E7b — 영어 변주가 한국어 변주와 다르다 (실제 영어판)', () async {
      await TodayV5Service.ensurePoolLoaded();
      final saju = makeSaju();
      final event = TodayEventService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      for (final topic in DailyTopic.values) {
        final ko = TodayV5Service.build(
          saju: saju,
          selection: forced(topic),
          event: event,
          chartSeed: 12345,
          useKo: true,
        );
        final en = TodayV5Service.build(
          saju: saju,
          selection: forced(topic),
          event: event,
          chartSeed: 12345,
          useKo: false,
        );
        expect(en.headline == ko.headline, isFalse,
            reason: '${topic.id} 영어 헤드라인이 한국어와 동일');
        expect(en.structureLine == ko.structureLine, isFalse,
            reason: '${topic.id} 영어 구조가 한국어와 동일');
      }
    });

    test('E8 — fallback (selected=null) 영어, 한글 leak 0', () async {
      await TodayV5Service.ensurePoolLoaded();
      const empty = TopicSelection(
        selected: null,
        candidates: [],
        belowThreshold: [],
        chartKey: 'none',
      );
      final saju = makeSaju();
      final event = TodayEventService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      final en = TodayV5Service.build(
        saju: saju,
        selection: empty,
        event: event,
        chartSeed: 999,
        useKo: false,
      );
      expect(en.isFallback, isTrue);
      expect(en.topic, isNull);
      expect(en.evidenceChips, isEmpty);
      expect(en.topicLabel, TodayV5Service.fallbackTopicLabelEn);
      for (final t in [
        en.headline,
        en.structureLine,
        en.triggerLine,
        en.actionLine,
        en.topicLabel,
      ]) {
        expect(t.trim().isNotEmpty, isTrue, reason: '영어 fallback 슬롯 비어있음');
        expect(hangul.hasMatch(t), isFalse,
            reason: '영어 fallback 한글 leak: $t');
        assertNoVerdictEn(t, where: '영어 fallback');
      }
    });

    test('E8b — pool 미적재 시 영어 내장 fallback 으로 graceful', () {
      TodayV5Service.debugResetPool(); // ensurePoolLoaded 호출 안 함.
      final saju = makeSaju();
      final event = TodayEventService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      // pool 미적재 + 영어 모드 → 내장 영어 fallback. 한글 leak 0.
      final en = TodayV5Service.build(
        saju: saju,
        selection: forced(DailyTopic.workCareer),
        event: event,
        chartSeed: 7,
        useKo: false,
      );
      for (final t in [
        en.headline,
        en.structureLine,
        en.triggerLine,
        en.actionLine,
      ]) {
        expect(t.trim().isNotEmpty, isTrue);
        expect(hangul.hasMatch(t), isFalse,
            reason: 'pool 미적재 영어 fallback 한글 leak: $t');
      }
    });

    test('E10 — build(useKo:true) 회귀 — 한국어 reading 그대로', () async {
      await TodayV5Service.ensurePoolLoaded();
      final saju = makeSaju();
      final event = TodayEventService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      for (final topic in DailyTopic.values) {
        final ko = TodayV5Service.build(
          saju: saju,
          selection: forced(topic),
          event: event,
          chartSeed: 12345,
          useKo: true,
        );
        // 한국어 모드는 한글을 포함해야 (영어 분기가 ko 를 오염시키지 않음).
        expect(hangul.hasMatch(ko.headline), isTrue,
            reason: '${topic.id} 한국어 헤드라인 회귀');
        expect(ko.topicLabel, TodayV5Service.topicLabelKo(topic));
      }
      // default 인자(useKo 생략)도 한국어 — 회귀 가드.
      final def = TodayV5Service.build(
        saju: saju,
        selection: forced(DailyTopic.mentalEmotion),
        event: event,
        chartSeed: 12345,
      );
      expect(hangul.hasMatch(def.headline), isTrue,
          reason: 'useKo 기본값이 한국어가 아님 — 회귀');
    });

    test('E10b — build 는 deterministic (영어 모드)', () async {
      await TodayV5Service.ensurePoolLoaded();
      final saju = makeSaju();
      final event = TodayEventService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      final a = TodayV5Service.build(
        saju: saju,
        selection: forced(DailyTopic.loveConnection),
        event: event,
        chartSeed: 555,
        useKo: false,
      );
      final b = TodayV5Service.build(
        saju: saju,
        selection: forced(DailyTopic.loveConnection),
        event: event,
        chartSeed: 555,
        useKo: false,
      );
      expect(a.headline, b.headline);
      expect(a.structureLine, b.structureLine);
      expect(a.triggerLine, b.triggerLine);
      expect(a.actionLine, b.actionLine);
    });
  });
}
