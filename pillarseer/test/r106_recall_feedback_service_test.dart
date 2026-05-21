// Round 106 (P1) — RecallFeedbackService 검증.
//
// design doc §4-D / §4-E / §4-F / §10:
//  - 점수 맞았어요 +1 / 애매해요 -1 / 아니에요 -3.
//  - shownCount >= 3 && score < 0 → 14일 cooldown suppress.
//  - cooldown 지나면 다시 eligible.
//  - 추적 신호 2주 윈도우 prune.
//  - resetPersonalization 이 로컬 기록 삭제.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/recall_feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  const topic = 'mental_emotion';
  final base = DateTime(2026, 5, 20);

  group('점수표 (design doc §4-D)', () {
    test('맞았어요 +1 / 애매해요 -1 / 아니에요 -3', () {
      expect(RecallVerdict.correct.scoreDelta, 1);
      expect(RecallVerdict.unsure.scoreDelta, -1);
      expect(RecallVerdict.wrong.scoreDelta, -3);
    });

    test('recordFeedback 가 점수를 누적한다', () async {
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.correct,
          date: base);
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.wrong,
          date: base);
      final s = await RecallFeedbackService.stateOf(topic);
      expect(s.score, 1 - 3); // -2
    });
  });

  group('노출 기록', () {
    test('recordShown 이 shownCount 를 올린다', () async {
      await RecallFeedbackService.recordShown(topic, base);
      await RecallFeedbackService.recordShown(
          topic, base.add(const Duration(days: 1)));
      final s = await RecallFeedbackService.stateOf(topic);
      expect(s.shownCount, 2);
    });

    test('같은 날 중복 recordShown 은 1회로 본다', () async {
      await RecallFeedbackService.recordShown(topic, base);
      await RecallFeedbackService.recordShown(topic, base);
      final s = await RecallFeedbackService.stateOf(topic);
      expect(s.shownCount, 1);
    });
  });

  group('cooldown suppress (테스트 요구 4)', () {
    test('shownCount>=3 && score<0 → 14일 cooldown suppress', () async {
      // 노출 3회.
      for (var i = 0; i < 3; i++) {
        await RecallFeedbackService.recordShown(
            topic, base.add(Duration(days: i)));
      }
      // 아니에요 -3 → score < 0.
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.wrong,
          date: base.add(const Duration(days: 3)));

      final s = await RecallFeedbackService.stateOf(topic);
      expect(s.cooldownUntil, isNotNull);
      // 다음 날은 여전히 suppress.
      final stillSuppressed = await RecallFeedbackService.isSuppressed(
          topic, base.add(const Duration(days: 4)));
      expect(stillSuppressed, isTrue);
    });

    test('shownCount<3 이면 score<0 이라도 suppress 안 함', () async {
      await RecallFeedbackService.recordShown(topic, base);
      await RecallFeedbackService.recordShown(
          topic, base.add(const Duration(days: 1)));
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.wrong,
          date: base.add(const Duration(days: 2)));
      final suppressed = await RecallFeedbackService.isSuppressed(
          topic, base.add(const Duration(days: 3)));
      expect(suppressed, isFalse);
    });
  });

  group('cooldown 만료 후 다시 eligible (테스트 요구 5)', () {
    test('14일 경과하면 다시 eligible', () async {
      for (var i = 0; i < 3; i++) {
        await RecallFeedbackService.recordShown(
            topic, base.add(Duration(days: i)));
      }
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.wrong,
          date: base.add(const Duration(days: 3)));

      final feedbackDay = base.add(const Duration(days: 3));
      // 14일 전 — suppress.
      expect(
        await RecallFeedbackService.isSuppressed(
            topic, feedbackDay.add(const Duration(days: 13))),
        isTrue,
      );
      // 정확히 14일 후 — eligible.
      expect(
        await RecallFeedbackService.isSuppressed(
            topic, feedbackDay.add(const Duration(days: 14))),
        isFalse,
      );
      // 그 후도 eligible.
      expect(
        await RecallFeedbackService.isSuppressed(
            topic, feedbackDay.add(const Duration(days: 20))),
        isFalse,
      );
    });

    test('cooldown 상수는 14일 — threshold 보존', () {
      expect(RecallFeedbackService.cooldownDays, 14);
      expect(RecallFeedbackService.suppressMinShown, 3);
    });
  });

  group('userPref', () {
    test('기록 없으면 중립 0.5', () async {
      final pref = await RecallFeedbackService.userPref('communication');
      expect(pref, 0.5);
    });

    test('양수 점수 → 0.5 초과, 음수 점수 → 0.5 미만', () async {
      expect(RecallFeedbackService.userPrefFromScore(0), 0.5);
      expect(RecallFeedbackService.userPrefFromScore(9), 1.0);
      expect(RecallFeedbackService.userPrefFromScore(-9), 0.0);
      expect(RecallFeedbackService.userPrefFromScore(20), 1.0); // clamp
      expect(RecallFeedbackService.userPrefFromScore(-20), 0.0); // clamp
      expect(RecallFeedbackService.userPrefFromScore(5) > 0.5, isTrue);
      expect(RecallFeedbackService.userPrefFromScore(-5) < 0.5, isTrue);
    });
  });

  group('추적 신호 2주 윈도우 (design doc §4-F)', () {
    test('윈도우 안 신호는 남고 밖 신호는 prune', () async {
      final now = DateTime(2026, 5, 20, 12);
      // 20일 전 — 윈도우 밖.
      await RecallFeedbackService.recordTrackingSignal(
        TrackingSignalKind.notificationTap,
        at: now.subtract(const Duration(days: 20)),
      );
      // 5일 전 — 윈도우 안.
      await RecallFeedbackService.recordTrackingSignal(
        TrackingSignalKind.menuOpen,
        value: 'compatibility',
        at: now.subtract(const Duration(days: 5)),
      );
      final signals = await RecallFeedbackService.trackingSignals(now: now);
      expect(signals.length, 1);
      expect(signals.first.kind, TrackingSignalKind.menuOpen);
      expect(signals.first.value, 'compatibility');
    });

    test('윈도우 상수는 14일', () {
      expect(RecallFeedbackService.trackingWindowDays, 14);
    });
  });

  group('resetPersonalization (테스트 요구 9)', () {
    test('점수/노출/cooldown/추적 기록 전부 삭제', () async {
      // 데이터 적재.
      for (var i = 0; i < 3; i++) {
        await RecallFeedbackService.recordShown(
            topic, base.add(Duration(days: i)));
      }
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.wrong,
          date: base.add(const Duration(days: 3)));
      await RecallFeedbackService.recordTrackingSignal(
        TrackingSignalKind.appOpenHour,
        value: '21',
        at: base,
      );

      // 적재 확인.
      var s = await RecallFeedbackService.stateOf(topic);
      expect(s.score != 0 || s.shownCount != 0, isTrue);

      // 초기화.
      await RecallFeedbackService.resetPersonalization();

      s = await RecallFeedbackService.stateOf(topic);
      expect(s.score, 0);
      expect(s.shownCount, 0);
      expect(s.lastShown, isNull);
      expect(s.cooldownUntil, isNull);
      final signals = await RecallFeedbackService.trackingSignals(now: base);
      expect(signals, isEmpty);
    });

    test('reset 은 무관한 다른 SharedPreferences 키는 건드리지 않는다', () async {
      SharedPreferences.setMockInitialValues({'app.streak.current': 7});
      await RecallFeedbackService.recordFeedback(topic, RecallVerdict.correct,
          date: base);
      await RecallFeedbackService.resetPersonalization();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app.streak.current'), 7);
    });
  });

  group('forbidden copy guard (테스트 요구 10)', () {
    test('R106 신규 service 소스에 단정 금지 패턴 0 (design doc §2)', () {
      // 이번 sprint 는 core service only — user-facing 카피가 없어야 한다.
      // design doc §2 단정 금지 / §3 v5 금지 표현이 신규 파일에 0 인지 스캔.
      const forbidden = [
        '오늘 당신은',
        '예민해지기 쉬운',
        '들뜨기 쉬운',
        '우울',
        '병원',
        '반드시',
        '무조건',
        '100%',
      ];
      const r106Files = [
        'lib/services/topic_selector_service.dart',
        'lib/services/recall_feedback_service.dart',
      ];
      for (final path in r106Files) {
        final src = File(path).readAsStringSync();
        for (final bad in forbidden) {
          expect(src.contains(bad), isFalse,
              reason: '$path 에 단정 금지 패턴 "$bad" 발견');
        }
      }
    });
  });
}
