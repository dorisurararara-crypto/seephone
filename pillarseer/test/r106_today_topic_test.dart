// Round 106 (P2a / P2a-fix) — 오늘의 사주 v5 검증.
//
// design doc §2 / §3 / §4 / §7:
//  ① selector 가 고른 오늘의 주제가 v5 reading 에 surface 된다.
//  ② 단정 금지 가드 — 생성 본문에 감정·사건 단정 0. "기분 좋았는데?" 반증 불가.
//  ③ 10 주제 전부 v5 본문 (헤드라인 + 구조/발동조건/행동) 생성.
//  ④ 자기검증 응답 → RecallFeedbackService 연결.
//  ⑤ selected=null (신호 없음) → 총평형 fallback (주제 surface X).
//
// R106 P2a-fix:
//  - Fix 3: 단정금지 가드를 today_v5_pool.json 의 *모든 fragment* 전수 + 패턴군
//    (정규식) 검사로 확장. trigger 의 조건형("만약~") 만 예외.
//  - Fix 4: score 루프가 실제 TodayEventReading 입력(todayScore)에 반영되게 수정.
//
// presentation layer only — 계산 엔진·selector·feedback 코어는 호출만.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/recall_feedback_service.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/today_event_service.dart';
import 'package:pillarseer/services/today_v5_service.dart';
import 'package:pillarseer/services/topic_selector_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1995-10-27 男 골든 케이스 기반 ctx + event helper.
  // [score] 는 TodayEventService.build 의 todayScore 로 실제 전달된다 (Fix 4).
  Future<({SajuResult saju, SajuContext ctx, TodayEventReading event})>
      goldenInputs({DateTime? date, int score = 50}) async {
    final d = date ?? DateTime(2026, 5, 20);
    final saju = await SajuService().calculateSaju(
      year: 1995, month: 10, day: 27,
      hour: 15, minute: 43,
      isLunar: false, isMale: true,
    );
    final ctx = SajuContext.from(saju, today: d);
    final event = TodayEventService.build(
      userDayStem: saju.dayPillar.chunGan,
      userDayBranch: saju.dayPillar.jiJi,
      userMonthBranch: saju.monthPillar.jiJi,
      todayPillar: ctx.todayPillar ?? '丙戌',
      todayScore: score,
    );
    return (saju: saju, ctx: ctx, event: event);
  }

  // ── 단정 금지 패턴군 — design doc §2 (Fix 3) ──
  //
  // 감정·상태·사건을 *예측* 하는 표현. 사용자가 그날 그렇지 않으면 "틀린 문장" 이
  // 되는 패턴을 정규식으로 잡는다. trigger 단락의 조건형("만약~") 은 별도 예외.
  final forbiddenPatterns = <RegExp>[
    // 감정·상태가 "올라온다/느껴진다" 류로 예측되는 패턴.
    RegExp(r'느껴지기\s*쉬'),
    RegExp(r'느껴질\s*수\s*있'),
    RegExp(r'신경\s*쓰이기\s*쉬'),
    RegExp(r'마음이.{0,8}흔들'),
    RegExp(r'컨디션이.{0,8}들쭉'),
    RegExp(r'마찰이.{0,6}생기'),
    RegExp(r'헷갈리기\s*쉬'),
    RegExp(r'(올라오기|움직이기|빨라지기|흘러가기)\s*쉬'),
    RegExp(r'(떠오를|올라올|생길)\s*수\s*있'),
    // 감정 단정 어휘.
    RegExp(r'예민'),
    RegExp(r'우울'),
    RegExp(r'들뜨'),
    RegExp(r'불안해'),
    RegExp(r'화가\s*나'),
    // 헤드라인체 / 메타 / 단정 어미.
    RegExp(r'하는\s*날이에요'),
    RegExp(r'되는\s*날이에요'),
    RegExp(r'(큰\s*)?변동\s*없이'),
    RegExp(r'무거워(?:지|져)'),
    RegExp(r'구조로\s*봅니다'),
    RegExp(r'사주적으로'),
    RegExp(r'본\s*리딩은'),
    // 사건 단정.
    RegExp(r'일이\s*일어'),
    RegExp(r'반드시'),
    RegExp(r'무조건'),
    RegExp(r'100%'),
  ];

  /// 임의 fragment 문자열을 패턴군으로 스캔. trigger 단락은 조건형 허용.
  void assertNoVerdictCopy(
    String text, {
    required String where,
    bool isTrigger = false,
  }) {
    for (final p in forbiddenPatterns) {
      // trigger 의 "만약 ~" 조건형은 감정·사건을 *조건* 으로만 언급하므로 예외.
      // 단 조건형이라도 헤드라인체·메타·사건 단정은 막는다.
      final triggerAllowed = isTrigger &&
          (p.pattern.contains('쉬') ||
              p.pattern.contains('수\\s*있') ||
              p.pattern == r'마음이.{0,8}흔들' ||
              p.pattern == r'컨디션이.{0,8}들쭉' ||
              p.pattern == r'마찰이.{0,6}생기');
      if (triggerAllowed) continue;
      expect(p.hasMatch(text), isFalse,
          reason: '$where 에 단정/금칙 패턴 /${p.pattern}/ 매치 — design doc §2 위반\n'
              '본문: "$text"');
    }
  }

  group('R106 P2a — 오늘의 사주 v5', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TodayV5Service.debugResetPool();
    });

    test('① selector 가 고른 주제가 v5 reading 에 surface 된다', () async {
      final i = await goldenInputs();
      final selection = TopicSelectorService.select(
        saju: i.saju,
        ctx: i.ctx,
        event: i.event,
        date: DateTime(2026, 5, 20),
      );
      final reading = TodayV5Service.build(
        saju: i.saju,
        selection: selection,
        event: i.event,
        chartSeed: i.ctx.chartSeed,
      );

      if (selection.selected != null) {
        expect(reading.topic, selection.selected,
            reason: 'selector 가 고른 주제가 그대로 v5 reading.topic');
        expect(reading.topicId, selection.selected!.id);
        expect(reading.isFallback, isFalse);
        expect(reading.topicLabel.isNotEmpty, isTrue);
        expect(reading.evidenceChips.length, 3, reason: '근거 칩은 항상 3개');
        for (final c in reading.evidenceChips) {
          expect(c.label.isNotEmpty, isTrue);
          expect(c.text.isNotEmpty, isTrue);
        }
      } else {
        expect(reading.isFallback, isTrue);
      }
    });

    test('② 단정 금지 — score 가 실제 event 에 반영된 채로 본문 검사 (Fix 4)', () async {
      // Fix 4: score 를 goldenInputs 에 넘겨 TodayEventService 입력에 반영.
      // actionDay/mixedDay/restDay 분류를 todayScore 로 실제 cover.
      for (final score in [15, 50, 85]) {
        final i = await goldenInputs(date: DateTime(2026, 5, 20), score: score);
        final selection = TopicSelectorService.select(
          saju: i.saju, ctx: i.ctx, event: i.event,
          date: DateTime(2026, 5, 20),
        );
        final reading = TodayV5Service.build(
          saju: i.saju, selection: selection, event: i.event,
          chartSeed: i.ctx.chartSeed,
        );
        assertNoVerdictCopy(reading.headline, where: 'score=$score 헤드라인');
        assertNoVerdictCopy(reading.structureLine,
            where: 'score=$score 구조');
        assertNoVerdictCopy(reading.triggerLine,
            where: 'score=$score 발동조건', isTrigger: true);
        assertNoVerdictCopy(reading.actionLine, where: 'score=$score 행동');
        for (final c in reading.evidenceChips) {
          assertNoVerdictCopy(c.text, where: 'score=$score 근거 칩');
        }
        expect(reading.triggerLine.contains('만약'), isTrue,
            reason: 'score=$score 발동조건 단락은 조건형이어야 함');
      }
    });

    test('③ 10 주제 전부 v5 본문 생성 (헤드라인 + 구조 + 발동조건 + 행동)', () async {
      await TodayV5Service.ensurePoolLoaded();
      final i = await goldenInputs();
      for (final topic in DailyTopic.values) {
        final forced = TopicSelection(
          selected: topic,
          candidates: [
            TopicCandidate(
              topic: topic,
              evidence: const [],
              breakdown: const TopicScoreBreakdown(
                signalStrength: 1, userPref: 0.5,
                freshness: 1, exploration: 0, finalScore: 1,
              ),
              byStrongSingle: true,
            ),
          ],
          belowThreshold: const [],
          chartKey: 'forced-${topic.id}',
        );
        final reading = TodayV5Service.build(
          saju: i.saju, selection: forced, event: i.event,
          chartSeed: i.ctx.chartSeed,
        );
        expect(reading.topic, topic);
        expect(reading.headline.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 헤드라인 비어있음');
        expect(reading.structureLine.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 구조 단락 비어있음');
        expect(reading.triggerLine.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 발동조건 단락 비어있음');
        expect(reading.actionLine.trim().isNotEmpty, isTrue,
            reason: '${topic.id} 행동 단락 비어있음');
        assertNoVerdictCopy(reading.headline, where: '${topic.id} 헤드라인');
        assertNoVerdictCopy(reading.structureLine, where: '${topic.id} 구조');
        assertNoVerdictCopy(reading.triggerLine,
            where: '${topic.id} 발동조건', isTrigger: true);
        assertNoVerdictCopy(reading.actionLine, where: '${topic.id} 행동');
        // 한자 jargon 단독 노출 0 (R86 보존).
        const rawGanji = '甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥';
        for (final ch in rawGanji.split('')) {
          expect(reading.bodyJoined.contains(ch), isFalse,
              reason: '${topic.id} 본문에 한자 jargon "$ch" 노출');
        }
      }
    });

    // ── Fix 3 — today_v5_pool.json 전 fragment 전수 단정금지 스캔 ──
    test('Fix3 — pool 의 모든 fragment 전수 패턴군 검사', () {
      final file = File('assets/data/today_v5_pool.json');
      expect(file.existsSync(), isTrue, reason: 'today_v5_pool.json 없음');
      final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      var scanned = 0;

      void scanList(dynamic raw, String where, {required bool isTrigger}) {
        expect(raw, isA<List>(), reason: '$where 가 list 가 아님');
        for (var idx = 0; idx < (raw as List).length; idx++) {
          final s = raw[idx];
          expect(s, isA<String>(), reason: '$where[$idx] 가 string 아님');
          assertNoVerdictCopy(s as String,
              where: '$where[$idx]', isTrigger: isTrigger);
          scanned++;
        }
      }

      void scanBucket(Map<String, dynamic> bucket, String where) {
        scanList(bucket['headline'], '$where.headline', isTrigger: false);
        scanList(bucket['structure'], '$where.structure', isTrigger: false);
        scanList(bucket['trigger'], '$where.trigger', isTrigger: true);
        scanList(bucket['action'], '$where.action', isTrigger: false);
      }

      // 10 주제 전수.
      final topics = root['topics'] as Map<String, dynamic>;
      expect(topics.length, 10, reason: '주제는 10개여야 함');
      for (final entry in topics.entries) {
        scanBucket(entry.value as Map<String, dynamic>, 'topics.${entry.key}');
      }
      // no_signal fallback 전수.
      scanBucket(
        root['no_signal_fallback'] as Map<String, dynamic>,
        'no_signal_fallback',
      );

      // R107 #4 — 변주 확장: 10 주제 × 4 슬롯 × 6 + fallback 4 슬롯 × 4
      //          = 240 + 16 = 256. (R106: 슬롯당 3 → R107: 슬롯당 6)
      expect(scanned, 256,
          reason: 'pool fragment 수 불일치 — 누락 없이 전수 스캔되어야 함');
      // 변주 확장 가드 — 각 주제 slot 변주 ≥ 6.
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          expect((bucket[slot] as List).length, greaterThanOrEqualTo(6),
              reason: 'topics.${entry.key}.$slot 변주가 6개 미만');
        }
      }
    });

    test('④ 자기검증 응답 → RecallFeedbackService.recordFeedback 연결', () async {
      const topicId = 'mental_emotion';
      final before = await RecallFeedbackService.stateOf(topicId);
      expect(before.score, 0);

      await RecallFeedbackService.recordFeedback(
          topicId, RecallVerdict.correct,
          date: DateTime(2026, 5, 20));
      final afterCorrect = await RecallFeedbackService.stateOf(topicId);
      expect(afterCorrect.score, 1, reason: '맞았어요 → +1');

      await RecallFeedbackService.recordFeedback(
          topicId, RecallVerdict.wrong,
          date: DateTime(2026, 5, 21));
      final afterWrong = await RecallFeedbackService.stateOf(topicId);
      expect(afterWrong.score, -2, reason: '아니에요 → -3 (누적 1-3)');

      expect(TodayV5Service.recallTitleKo, '어제 풀이, 직접 체크해볼까요?');
      expect(TodayV5Service.recallDescKo.contains('관심분야를 더'), isTrue);
      expect(TodayV5Service.recallDescKo.contains('틀렸다 싶은 날도'), isTrue);
      expect(TodayV5Service.recallCorrectKo, '맞았어요');
      expect(TodayV5Service.recallUnsureKo, '애매해요');
      expect(TodayV5Service.recallWrongKo, '아니에요');
    });

    // ── Fix 5 — 자기검증은 *어제 본 풀이* 에 기록 ──
    test('Fix5 — recordShown 이 "마지막 노출 풀이" 슬롯을 갱신, lastReading 으로 읽힘',
        () async {
      // 어제(5/19) communication 노출.
      await RecallFeedbackService.recordShown(
          'communication', DateTime(2026, 5, 19));
      final last = await RecallFeedbackService.lastReading();
      expect(last, isNotNull);
      expect(last!.topic, 'communication');
      expect(last.date, DateTime(2026, 5, 19));

      // 오늘(5/20) money_spending 노출 → 슬롯이 오늘 값으로 갱신.
      await RecallFeedbackService.recordShown(
          'money_spending', DateTime(2026, 5, 20));
      final last2 = await RecallFeedbackService.lastReading();
      expect(last2!.topic, 'money_spending');
      expect(last2.date, DateTime(2026, 5, 20));
    });

    test('Fix5 — 자기검증 feedback 은 어제 topic 에 기록된다', () async {
      // 어제 health_condition 노출 후, 자기검증에서 어제 topic 에 feedback.
      await RecallFeedbackService.recordShown(
          'health_condition', DateTime(2026, 5, 19));
      final last = await RecallFeedbackService.lastReading();
      expect(last!.topic, 'health_condition');

      // 자기검증 카드가 어제 topic 에 "맞았어요" 기록.
      await RecallFeedbackService.recordFeedback(
          last.topic, RecallVerdict.correct,
          date: last.date);
      final state = await RecallFeedbackService.stateOf('health_condition');
      expect(state.score, 1, reason: '어제 topic 점수에 +1 반영');

      // 오늘 본 topic(예: love_connection)에는 기록 안 됨.
      final loveState =
          await RecallFeedbackService.stateOf('love_connection');
      expect(loveState.score, 0,
          reason: '오늘 topic 에는 feedback 이 가지 않아야 함');
    });

    test('Fix5 — 어제 기록이 없으면 lastReading null (자기검증 카드 숨김 근거)',
        () async {
      final last = await RecallFeedbackService.lastReading();
      expect(last, isNull, reason: '첫 실행 — 어제 노출 풀이 없음');
    });

    test('Fix5 — resetPersonalization 이 lastReading 슬롯도 초기화', () async {
      await RecallFeedbackService.recordShown(
          'work_career', DateTime(2026, 5, 19));
      expect(await RecallFeedbackService.lastReading(), isNotNull);
      await RecallFeedbackService.resetPersonalization();
      expect(await RecallFeedbackService.lastReading(), isNull,
          reason: 'reset 후 어제 풀이 슬롯도 비워져야 함');
    });

    test('⑤ selected=null → 총평형 fallback (주제 surface X, 근거 칩 X)', () async {
      final i = await goldenInputs();
      const empty = TopicSelection(
        selected: null,
        candidates: [],
        belowThreshold: [],
        chartKey: 'no-signal',
      );
      final reading = TodayV5Service.build(
        saju: i.saju, selection: empty, event: i.event,
        chartSeed: i.ctx.chartSeed,
      );
      expect(reading.isFallback, isTrue);
      expect(reading.topic, isNull);
      expect(reading.topicId, isNull,
          reason: 'fallback 모드 — 자기검증 연결 topic 없음');
      expect(reading.evidenceChips, isEmpty,
          reason: 'fallback 모드 — 근거 칩 surface 금지 (창작 방지)');
      expect(reading.headline.trim().isNotEmpty, isTrue);
      expect(reading.structureLine.trim().isNotEmpty, isTrue);
      assertNoVerdictCopy(reading.headline, where: 'fallback 헤드라인');
      assertNoVerdictCopy(reading.structureLine, where: 'fallback 구조');
      assertNoVerdictCopy(reading.triggerLine,
          where: 'fallback 발동조건', isTrigger: true);
      assertNoVerdictCopy(reading.actionLine, where: 'fallback 행동');
    });

    test('deterministic — 같은 입력이면 v5 reading 동일', () async {
      final i = await goldenInputs();
      final sel = TopicSelectorService.select(
        saju: i.saju, ctx: i.ctx, event: i.event,
        date: DateTime(2026, 5, 20),
      );
      final a = TodayV5Service.build(
        saju: i.saju, selection: sel, event: i.event,
        chartSeed: i.ctx.chartSeed,
      );
      final b = TodayV5Service.build(
        saju: i.saju, selection: sel, event: i.event,
        chartSeed: i.ctx.chartSeed,
      );
      expect(a.headline, b.headline);
      expect(a.bodyJoined, b.bodyJoined);
    });

    test('pool 미적재 (debugResetPool) 여도 내장 fallback 으로 v5 본문 생성', () async {
      TodayV5Service.debugResetPool();
      final i = await goldenInputs();
      final forced = TopicSelection(
        selected: DailyTopic.moneySpending,
        candidates: [
          TopicCandidate(
            topic: DailyTopic.moneySpending,
            evidence: const [],
            breakdown: const TopicScoreBreakdown(
              signalStrength: 1, userPref: 0.5,
              freshness: 1, exploration: 0, finalScore: 1,
            ),
            byStrongSingle: true,
          ),
        ],
        belowThreshold: const [],
        chartKey: 'forced',
      );
      final reading = TodayV5Service.build(
        saju: i.saju, selection: forced, event: i.event,
        chartSeed: i.ctx.chartSeed,
      );
      expect(reading.headline.trim().isNotEmpty, isTrue);
      expect(reading.structureLine.trim().isNotEmpty, isTrue);
      assertNoVerdictCopy(reading.headline, where: 'pool 미적재 fallback 헤드라인');
      assertNoVerdictCopy(reading.structureLine,
          where: 'pool 미적재 fallback 구조');
      assertNoVerdictCopy(reading.triggerLine,
          where: 'pool 미적재 fallback 발동조건', isTrigger: true);
      assertNoVerdictCopy(reading.actionLine,
          where: 'pool 미적재 fallback 행동');
    });
  });
}
