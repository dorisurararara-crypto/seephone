// Round 82 sprint 10 — 외부 reviewer P0 #7 fix
// 사용자 mandate (R82 spec §3 sprint 10):
//   사용자가 5행 카드 라벨/툴팁에서 정통 사주 비율 표시가 아닌 앱 기준 세력 분포
//   점수 + 숨은 글자/태어난 달/뿌리 힘을 같이 본 1줄 평이 풀이를 본다.
//
// 본 test 는 source-level assertion + 한국어 본문 audit. 시뮬레이터 / 에뮬레이터
// 새 부팅 X (M3 mandate).
//
// 검증 축:
//   1. arb ko resultFiveElements 헤더 = "세력 분포 점수 (앱 기준)".
//   2. arb ko resultFiveElementsHelper 신규 추가 + 평이 풀이 4 어휘 동시 보유.
//   3. arb en resultFiveElements + helper 평행 갱신 ("app-calibrated" / hidden stems
//      / birth month / root strength 명시).
//   4. result_screen 의 _FiveElementsSection 이 l10n getter 를 사용 (하드코딩 X).
//   5. 금지 문자열 (외부 reviewer 권고 "오행 …%식 표현") 0 — result_screen
//      사용자 노출 영역 + arb ko 신규 키.
//   6. 한자 jargon (지장간 / 월령 / 통근) 사용자 노출 영역 (arb) 0.
//   7. 5행 raw 산출 값 (1995-10-27 男 17시 16/21/17/41/4) wire 보존 — 산식 변경 X.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/manseryeok_service.dart';

void main() {
  group('R82 sprint 10 — 세력 분포 점수 라벨 + 평이 helper', () {
    late String resultScreenSrc;
    late Map<String, dynamic> arbKo;
    late Map<String, dynamic> arbEn;

    // Build forbidden phrases at runtime via list-join so the test source itself
    // remains grep-clean per 외부 reviewer 권고 (codex audit r1). 사용자 노출
    // 영역 (lib/, arb) 에 정통 사주 비율 표기가 없는 것을 검증하는 게 목적이며,
    // test 자체가 해당 표기를 grep hit 시키지 않도록 한다.
    String join(List<String> parts) => parts.join(' ');

    setUpAll(() {
      resultScreenSrc =
          File('lib/screens/result_screen.dart').readAsStringSync();
      arbKo = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
          as Map<String, dynamic>;
      arbEn = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
    });

    test('arb ko — resultFiveElements 헤더 = 세력 분포 점수 (앱 기준)', () {
      expect(arbKo['resultFiveElements'], '세력 분포 점수 (앱 기준)',
          reason: '외부 reviewer P0 #7 — 정통 산식 오해 방지 라벨 갱신');
    });

    test('arb ko — resultFiveElementsHelper 신규 추가 + 평이 풀이 4 어휘 동시 보유', () {
      final helper = (arbKo['resultFiveElementsHelper'] ?? '') as String;
      expect(helper.isNotEmpty, isTrue,
          reason: 'helper key 누락 — "숨은 글자 / 태어난 달 / 뿌리 힘" 평이 풀이 wire 필요');
      expect(helper.contains('숨은 글자'), isTrue,
          reason: 'spec §3 sprint 10 — "숨은 글자" 평이 풀이 (지장간 jargon 대체)');
      expect(helper.contains('태어난 달'), isTrue,
          reason: 'spec §3 sprint 10 — "태어난 달" 평이 풀이 (월령 jargon 대체)');
      expect(helper.contains('뿌리 힘'), isTrue,
          reason: 'spec §3 sprint 10 — "뿌리 힘" 평이 풀이 (통근 jargon 대체)');
      expect(helper.contains('앱 기준'), isTrue,
          reason: '"앱 기준" 명시 — 정통 산식 오해 방지');
    });

    test('arb en — resultFiveElements + helper 평행 갱신', () {
      expect(
        arbEn['resultFiveElements'],
        'Element strength score (app-calibrated)',
        reason: 'en label 도 "app-calibrated" 명시',
      );
      final helperEn = (arbEn['resultFiveElementsHelper'] ?? '') as String;
      expect(helperEn.toLowerCase().contains('app-calibrated'), isTrue);
      expect(helperEn.toLowerCase().contains('hidden stems'), isTrue);
      expect(helperEn.toLowerCase().contains('birth month'), isTrue);
      expect(helperEn.toLowerCase().contains('root strength'), isTrue);
    });

    test(
        'result_screen — _FiveElementsSection 이 l10n getter 사용 (하드코딩 X)',
        () {
      // _FiveElementsSection 영역에 새 getter wire 확인.
      expect(resultScreenSrc.contains('l.resultFiveElements'), isTrue,
          reason:
              '_FiveElementsSection 의 헤더가 l10n getter resultFiveElements 를 사용해야 함 (하드코딩 X)');
      expect(resultScreenSrc.contains('l.resultFiveElementsHelper'), isTrue,
          reason:
              '_FiveElementsSection 의 helper 1줄이 l10n getter resultFiveElementsHelper 를 사용해야 함');
    });

    test('금지 문자열 — 정통 사주 비율 표기 사용자 노출 영역 0', () {
      final forbidden = [
        join(['오행', '퍼센트']),
        join(['정확한', '오행', '비율']),
        join(['오행', '비율']),
      ];
      // result_screen 사용자 노출 영역 grep.
      for (final phrase in forbidden) {
        expect(resultScreenSrc.contains(phrase), isFalse,
            reason:
                'result_screen.dart 사용자 노출 영역에 잔존 — 외부 reviewer P0 #7 위반');
      }
      // arb ko 신규 키도 사용자 노출 — forbidden 0 보장.
      final koLabel = (arbKo['resultFiveElements'] ?? '') as String;
      final koHelper = (arbKo['resultFiveElementsHelper'] ?? '') as String;
      for (final phrase in forbidden) {
        expect(koLabel.contains(phrase), isFalse,
            reason: 'arb resultFiveElements 에 정통 사주 비율 표기 잔존');
        expect(koHelper.contains(phrase), isFalse,
            reason: 'arb resultFiveElementsHelper 에 정통 사주 비율 표기 잔존');
      }
    });

    test('한자 jargon (지장간 / 월령 / 통근) 사용자 노출 영역 0', () {
      const jargon = ['지장간', '월령', '통근'];
      final koLabel = (arbKo['resultFiveElements'] ?? '') as String;
      final koHelper = (arbKo['resultFiveElementsHelper'] ?? '') as String;
      for (final word in jargon) {
        expect(koLabel.contains(word), isFalse,
            reason:
                'arb resultFiveElements 에 한자 jargon "$word" 잔존 — M5 페르소나 위반');
        expect(koHelper.contains(word), isFalse,
            reason:
                'arb resultFiveElementsHelper 에 한자 jargon "$word" 잔존 — M5 페르소나 위반');
      }
    });

    test('5행 raw 산출 값 보존 — 1995-10-27 男 17시 16/21/17/41/4 (M4 mandate)',
        () {
      // ManseryeokService 실행해서 5행 raw 값 자체 변경 0 확인.
      final r = ManseryeokService.calculate(
        year: 1995,
        month: 10,
        day: 27,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
      );
      final el = r.elements;
      expect(el.wood, 16, reason: '5행 골든 木 = 16 (R75 calibration)');
      expect(el.fire, 21, reason: '5행 골든 火 = 21 (R75 calibration)');
      expect(el.earth, 17, reason: '5행 골든 土 = 17 (R75 calibration)');
      expect(el.metal, 41, reason: '5행 골든 金 = 41 (R75 calibration)');
      expect(el.water, 4, reason: '5행 골든 水 = 4 (R75 calibration)');
      // dayPillar.text = chunGan + jiJi = 辛卯.
      expect(r.dayPillar.text, '辛卯', reason: '일주 골든 = 辛卯 (R75)');
    });
  });
}
