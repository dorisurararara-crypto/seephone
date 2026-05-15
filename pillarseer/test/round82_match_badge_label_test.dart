// Round 82 sprint 4 회귀 가드 — `_MatchBadge` 라벨 + `_CrossmatchSection` headline
// 재작성 검증.
//
// 사용자 verbatim (2026-05-15):
//   "깊게봐도 다시 잡힌 핵심 이것도 부자연스럽고"
//
// → six_axis_radar.dart 의 `_MatchBadge` 라벨 + result_screen.dart 의 `_CrossmatchSection`
//   headline / intro 일관 재작성 (한국 MZ 중학생 친근 어휘).
//   widget tree 미변경 + R69 lock (matchCount 5 / matchedAxes / combinedScores) 보존.
//
// ── Sprint 계약 = testable 3 행동 ──
//   행동 1 (B1 / B1b / B1c / B1d 검사군) = "깊게 봐도 다시 잡힌" 부자연 phrase 가
//     six_axis_radar.dart + result_screen.dart 양쪽에서 모두 제거되고, 신규 라벨
//     ("두 번 봐도 같이 잡힌 강점") 가 두 곳 모두에 노출, 한자 jargon blacklist 0.
//   행동 2 (B2 검사군) = R69 lock (1995-10-27 15:43 男 — combinedScores 6 + matchCount 5
//     + matchedAxes) + 5행 raw 골든 (1995-10-27 17:00 男 — 16/21/17/41/4) 두 sample
//     모두 보존. 두 시간 sample 은 spec 의 M4 mandate (5행 골든 17:00) 와 R69 lock
//     baseline (15:43) 둘을 동시에 검증하기 위해 분리. _MatchBadge 라벨 변경은
//     algorithmic 미접촉 → 둘 다 보존 mandate.
//   행동 3 (B3 / B3b 검사군) = widget tree 시그니처 (_MatchBadge class /
//     showMatchBadge param / mount call) 보존 + 자미두수 hidden mandate (nameKo
//     사용자 노출 0 — `_CrossmatchSection` 영역에 별 이름 leak X).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/six_axis_score_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  group('R82 sprint 4 — _MatchBadge 라벨 재작성 회귀 가드', () {
    final radarSrc =
        File('lib/widgets/six_axis_radar.dart').readAsStringSync();
    final resultSrc =
        File('lib/screens/result_screen.dart').readAsStringSync();

    // ───────── 행동 1 — 라벨 재작성 (string grep) ─────────

    test('행동1.B1 — six_axis_radar.dart 안에 "깊게 봐도 다시 잡힌" 문자열 0', () {
      // _MatchBadge 라벨 영역 (line 71 부근).
      expect(radarSrc.contains('깊게 봐도 다시 잡힌'), isFalse,
          reason: 'six_axis_radar _MatchBadge 라벨에 부자연 phrase 잔존');
    });

    test('행동1.B1b — result_screen.dart 안에 "깊게 봐도 다시 잡힌" 문자열 0', () {
      // _CrossmatchSection headline 영역 (line 2710 부근).
      expect(resultSrc.contains('깊게 봐도 다시 잡힌'), isFalse,
          reason: 'result_screen _CrossmatchSection headline 에 부자연 phrase 잔존');
    });

    test('행동1.B1c — 신규 라벨 "두 번 봐도 같이 잡힌 강점" 두 곳 모두 노출', () {
      // 사용자 친근 어휘 — 한국 MZ 중학생 K-POP 팬 페르소나 (한자 jargon X / 영문 약어 X).
      expect(radarSrc.contains('두 번 봐도 같이 잡힌 강점'), isTrue,
          reason: 'six_axis_radar _MatchBadge 신규 라벨 미반영');
      expect(resultSrc.contains('두 번 봐도 같이 잡힌 강점'), isTrue,
          reason: 'result_screen _CrossmatchSection headline 신규 라벨 미반영');
    });

    test('행동1.B1d — 라벨 영역에 한자 jargon noun blacklist 0 (페르소나 M5 mandate)', () {
      // "정수" / "본질" / "벼린 칼" / "도검의 끝" / "결을 다듬는" — 한국 MZ 중학생이 의미
      // 잘 모르는 한자 jargon. _MatchBadge 영역 전수 검사.
      const jargon = ['정수', '본질', '벼린 칼', '도검의 끝', '결을 다듬는'];
      for (final term in jargon) {
        expect(radarSrc.contains(term), isFalse,
            reason: 'six_axis_radar 에 한자 jargon "$term" 노출');
      }
      // 단, result_screen 은 다른 영역에 별도 단어가 있을 수 있어 본 sprint 영역만
      // ground truth 보존. blacklist 전수 검사는 sprint 3 / sprint 8 위임.
    });

    // ───────── 행동 2 — R69 lock + 5행 raw 골든 두 sample 모두 보존 ─────────

    test(
        '행동2.B2 — R69 lock 보존 (1995-10-27 15:43 男 / 신묘 일주, R80 sprint 4 baseline)',
        () async {
      // R69 lock 의 사용자 sample = 1995-10-27 *15:43* 남자.
      // (test/round69_regression_test.dart line 21 의 baseline 값과 동일.)
      // _MatchBadge 라벨 변경은 algorithmic 미접촉 → lock 완전 보존 mandate.
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ziwei = ZiweiService.calculate(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isMale: true,
      );
      final score = SixAxisScoreService.compute(saju, ziwei);
      expect(score.matchCount, 5, reason: 'R69 lock matchCount 5 보존');
      expect(score.matchedAxes, ['연애', '일', '돈', '건강', '평판'],
          reason: 'R69 lock matchedAxes 보존');
      expect(score.combinedScores['본성'], 78, reason: 'R69 lock 본성 78 보존');
      expect(score.combinedScores['연애'], 78, reason: 'R69 lock 연애 78 보존');
      expect(score.combinedScores['일'], 72, reason: 'R69 lock 일 72 보존');
      expect(score.combinedScores['돈'], 74, reason: 'R69 lock 돈 74 보존');
      expect(score.combinedScores['건강'], 57, reason: 'R69 lock 건강 57 보존');
      expect(score.combinedScores['평판'], 71, reason: 'R69 lock 평판 71 보존');
    });

    test(
        '행동2.B2b — 5행 raw 골든 보존 (1995-10-27 17:00 男 — 16/21/17/41/4, R75 calibration spec G3)',
        () async {
      // spec M4 mandate 의 5행 raw 골든 = 1995-10-27 *17:00* 남자 (정시).
      // 시간 다르므로 R69 lock sample (15:43) 과 별도 검증.
      // _MatchBadge 라벨 변경은 algorithmic 미접촉 → 5행 raw 보존 mandate.
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      // R75 calibration: 木 16 / 火 21 / 土 17 / 金 41 / 水 4 + 일주 辛卯.
      expect(saju.elements.wood, 16, reason: 'R75 골든 木 16 보존');
      expect(saju.elements.fire, 21, reason: 'R75 골든 火 21 보존');
      expect(saju.elements.earth, 17, reason: 'R75 골든 土 17 보존');
      expect(saju.elements.metal, 41, reason: 'R75 골든 金 41 보존');
      expect(saju.elements.water, 4, reason: 'R75 골든 水 4 보존');
      expect(saju.dayPillar.chunGan, '辛', reason: 'R75 골든 일간 辛 보존');
      expect(saju.dayPillar.jiJi, '卯', reason: 'R75 골든 일지 卯 보존');
    });

    // ───────── 행동 3 — widget tree 시그니처 + 자미두수 hidden mandate 보존 ─────────

    test('행동3.B3 — widget tree 시그니처 보존 (_MatchBadge class + showMatchBadge param)',
        () {
      // 옵션 A (라벨 재작성) 선택 — widget tree 미변경 mandate.
      expect(radarSrc.contains('class _MatchBadge extends StatelessWidget'),
          isTrue,
          reason: '_MatchBadge class 정의 보존 (옵션 B badge 제거 X)');
      expect(radarSrc.contains('final bool showMatchBadge'), isTrue,
          reason: 'showMatchBadge param 보존');
      expect(
          radarSrc.contains(
              '_MatchBadge(matchCount: score.matchCount, useKo: useKo)'),
          isTrue,
          reason: '_MatchBadge mount 시그니처 보존');
    });

    test(
        '행동3.B3b — 자미두수 hidden mandate 보존 (별 이름 nameKo 사용자 노출 0 — _CrossmatchSection 영역)',
        () {
      // R70 마케팅 차별점 보호: 자미두수 12궁 별 이름 (자미성·천기성·태양성·천부성 등) 사용자
      // 노출 0. _CrossmatchSection 영역에 별 이름 string literal leak 0 검사.
      const ziweiStarNames = [
        '자미성', '천기성', '태양성', '무곡성', '천동성', '염정성',
        '천부성', '태음성', '탐랑성', '거문성', '천상성', '천량성',
        '칠살성', '파군성',
      ];
      // _CrossmatchSection 영역 (line 2700 ~ 2900 부근) 만 추출해서 검사.
      final crossSectionStart =
          resultSrc.indexOf('class _CrossmatchSection extends StatelessWidget');
      expect(crossSectionStart, greaterThan(0),
          reason: '_CrossmatchSection class 정의 보존');
      // 다음 class 정의 또는 2000 char 까지 (방어적 cap).
      var crossSectionEnd =
          resultSrc.indexOf('\nclass ', crossSectionStart + 1);
      if (crossSectionEnd < 0) crossSectionEnd = resultSrc.length;
      // cap 2000 char 적용해서 인접 class 도 못 보게.
      final scanEnd =
          (crossSectionStart + 2000) < crossSectionEnd
              ? (crossSectionStart + 2000)
              : crossSectionEnd;
      final crossSection = resultSrc.substring(crossSectionStart, scanEnd);
      for (final star in ziweiStarNames) {
        expect(crossSection.contains(star), isFalse,
            reason: '_CrossmatchSection 에 자미두수 별 이름 "$star" leak');
      }
    });
  });
}
