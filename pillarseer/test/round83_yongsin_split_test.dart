// Round 83 sprint 6 — P1-D 용신 억부/조후/격국 분리 표시 + 신뢰도 라벨 회귀 가드.
//
// 사용자 스토리:
//   사용자가 result_screen 의 용신 카드에서 억부용신 / 조후용신 / 격국용신
//   3 종을 분리해서 보고, 세 결과가 일치하면 "강한 확신" 라벨, 다르면
//   "두 줄기가 함께 보이는 복합 사주" 같은 신뢰도 라벨을 본다.
//
// ── Sprint 계약 = testable 5 행동 ──
//   행동 1 = YongsinService.judge() 가 eokbu (= yongsin) / chowhu / huisin 산출,
//     gyeokgukYongsinFor() 가 격국용신 산출. 5행 골든 1995-10-27 男 17시 보존.
//   행동 2 = confidence() 헬퍼가 3 분기 (3 동일 / 2 동일 / 모두 다름) + ko/en 매핑.
//   행동 3 = result_screen.dart 안에 "억부용신" / "조후용신" / "격국용신" 라벨 +
//     1줄 풀이 string literal 존재.
//   행동 4 = 자미두수 별 이름 nameKo 0 노출 + 한자 jargon "기운/결/본질/정수/운기/운명" 0.
//   행동 5 = 5행 골든 raw 보존 + 일주 辛卯 보존 + yongsin 산출 backward compat.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/yongsin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R83 sprint 6 — 용신 3 종 분리 + 신뢰도 라벨', () {
    // 5행 골든 sample.
    late final dynamic golden;

    setUpAll(() async {
      golden = await SajuService().calculateSaju(
        year: 1995,
        month: 10,
        day: 27,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
      );
    });

    // ── 행동 1 — 3 종 산출 ──

    test('행동1.B1 — judge() chowhu 같이 산출 (1995-10-27 男, 戌월)', () {
      final el = golden.elements;
      final dm = golden.dayPillar.chunGanElement;
      final y = YongsinService.judge(
        dayMasterElement: dm,
        strengthLabel: '신강',
        wood: el.wood,
        fire: el.fire,
        earth: el.earth,
        metal: el.metal,
        water: el.water,
        monthBranch: golden.monthPillar.jiJi,
      );
      // 5행 element 중 하나.
      expect(['木', '火', '土', '金', '水'], contains(y.yongsin));
      expect(['木', '火', '土', '金', '水'], contains(y.huisin));
      expect(y.chowhuYongsin, isNotNull);
      expect(['木', '火', '土', '金', '水'], contains(y.chowhuYongsin));
    });

    test('행동1.B1b — gyeokgukYongsinFor() 1995-10-27 男 정인격 → 관성 (火)', () {
      // 일간 辛(金), 월지 戌 본기 = 戊(土), godForJiJi(辛, 戌) = 정인 (土 생 金).
      // → 정인격 → 격국용신 = 관성 (일간을 극하는 오행, 金 ← 火) = 火.
      final result = YongsinService.gyeokgukYongsinFor(
        dayMaster: '辛',
        dayMasterElement: '金',
        monthJi: '戌',
      );
      expect(result, '火');
    });

    test('행동1.B1c — gyeokgukYongsinFor() 모든 격국 → null 아님 또는 명시 매핑', () {
      // 12 지지 × 10 천간 일부 sample 만 — 모두 null 아닌 5행 반환 보장.
      const samples = [
        ('甲', '子'), // 木 / 子(癸 水) → 정인격
        ('乙', '寅'), // 木 / 寅(甲 木) → 겁재 (양인격)
        ('丙', '午'), // 火 / 午(丁 火) → 겁재
        ('庚', '申'), // 金 / 申(庚 金) → 비견 (건록격)
      ];
      for (final s in samples) {
        final r = YongsinService.gyeokgukYongsinFor(
          dayMaster: s.$1,
          dayMasterElement:
              {'甲': '木', '乙': '木', '丙': '火', '庚': '金'}[s.$1] ?? '?',
          monthJi: s.$2,
        );
        expect(r, isNotNull, reason: '${s.$1}/${s.$2} 격국용신 null');
        expect(['木', '火', '土', '金', '水'], contains(r));
      }
    });

    // ── 행동 2 — confidence() 3 분기 ──

    test('행동2.B2 — 3 종 동일 → "강한 확신"', () {
      final c = YongsinService.confidence(
        eokbu: '木',
        chowhu: '木',
        gyeokguk: '木',
      );
      expect(c.labelKo, '강한 확신');
      expect(c.labelEn, 'Strong consensus');
      expect(c.agreement, 3);
      expect(c.helperKo, isNotEmpty);
    });

    test('행동2.B2b — 2 종 동일 → "두 줄기가 함께 보이는 복합 사주"', () {
      final c = YongsinService.confidence(
        eokbu: '木',
        chowhu: '木',
        gyeokguk: '火',
      );
      expect(c.labelKo, '두 줄기가 함께 보이는 복합 사주');
      expect(c.labelEn, 'Two streams aligned');
      expect(c.agreement, 2);
    });

    test('행동2.B2c — 3 종 모두 다름 → "여러 방향이 같이 보이는 사주"', () {
      final c = YongsinService.confidence(
        eokbu: '木',
        chowhu: '火',
        gyeokguk: '水',
      );
      expect(c.labelKo, '여러 방향이 같이 보이는 사주');
      expect(c.labelEn, 'Three streams woven');
      expect(c.agreement, 1);
    });

    test('행동2.B2d — 1 종 이하 → "한 줄기 기준"', () {
      final c = YongsinService.confidence(
        eokbu: '木',
        chowhu: null,
        gyeokguk: null,
      );
      expect(c.labelKo, '한 줄기 기준');
      expect(c.labelEn, 'Single stream');
    });

    test('행동2.B2e — 1995-10-27 男 17시 sample 의 3 종 분기', () {
      final el = golden.elements;
      final dm = golden.dayPillar.chunGanElement;
      final s = YongsinService.judge(
        dayMasterElement: dm,
        strengthLabel: '신강',
        wood: el.wood,
        fire: el.fire,
        earth: el.earth,
        metal: el.metal,
        water: el.water,
        monthBranch: golden.monthPillar.jiJi,
      );
      final g = YongsinService.gyeokgukYongsinFor(
        dayMaster: golden.dayPillar.chunGan,
        dayMasterElement: dm,
        monthJi: golden.monthPillar.jiJi,
      );
      final c = YongsinService.confidence(
        eokbu: s.yongsin,
        chowhu: s.chowhuYongsin,
        gyeokguk: g,
      );
      // 분기 라벨 4 종 중 하나.
      const labels = <String>[
        '강한 확신',
        '두 줄기가 함께 보이는 복합 사주',
        '여러 방향이 같이 보이는 사주',
        '한 줄기 기준',
      ];
      expect(labels, contains(c.labelKo));
    });

    // ── 행동 3 — result_screen.dart 분리 라벨 + 풀이 mount ──

    test('행동3.B3 — result_screen.dart 안에 "억부용신" / "조후용신" / "격국용신" 라벨 존재', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      expect(src.contains('억부용신'), isTrue,
          reason: '"억부용신" 라벨 미존재');
      expect(src.contains('조후용신'), isTrue,
          reason: '"조후용신" 라벨 미존재');
      expect(src.contains('격국용신'), isTrue,
          reason: '"격국용신" 라벨 미존재');
    });

    test('행동3.B3b — result_screen.dart 안에 3 영역 1줄 풀이 string literal 존재', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // 억부 = 강약 / 조후 = 계절 / 격국 = 보좌 — 각 풀이 키워드 hit.
      expect(src.contains('강약'), isTrue, reason: '억부용신 풀이 "강약" 미존재');
      expect(src.contains('계절'), isTrue, reason: '조후용신 풀이 "계절" 미존재');
      expect(src.contains('보좌') || src.contains('받쳐'), isTrue,
          reason: '격국용신 풀이 "보좌/받쳐" 미존재');
    });

    test('행동3.B3c — result_screen.dart 안에 3 종 신뢰도 라벨 noun 1+ 존재', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // _YongsinBlock 안에 confidence helper 호출이 있고, label 자체 string
      // literal 은 service 안에 있으므로 src 안에는 `YongsinService.confidence` /
      // `conf.labelKo` 같은 호출 패턴이 보여야 함.
      expect(src.contains('YongsinService.confidence'), isTrue,
          reason: 'confidence() 호출 누락');
      expect(src.contains('YongsinService.gyeokgukYongsinFor'), isTrue,
          reason: 'gyeokgukYongsinFor() 호출 누락');
    });

    // ── 행동 4 — 한자 jargon / 자미두수 별 nameKo noLeak ──

    test('행동4.B4 — confidence() 결과 본문에 한자 jargon 0 (원문 단어 그대로)', () {
      // 사용자 mandate (M5) — "기운/결/본질/정수/운기/운명" 한자 jargon 0. 원문 단어
      // 그대로 검사해서 "같은 결" / "운명을" 등 다양한 활용형 매칭.
      const jargon = <String>['기운', '결', '본질', '정수', '운기', '운명', '벼린'];
      const inputs = [
        ['木', '木', '木'],
        ['木', '木', '火'],
        ['木', '火', '水'],
        ['木', null, null],
      ];
      for (final inp in inputs) {
        final c = YongsinService.confidence(
          eokbu: inp[0],
          chowhu: inp[1],
          gyeokguk: inp[2],
        );
        final all = '${c.labelKo} ${c.helperKo}';
        for (final j in jargon) {
          expect(all.contains(j), isFalse,
              reason:
                  'confidence ${inp.join(",")} 결과 본문에 jargon "$j" 노출: $all');
        }
      }
    });

    test('행동4.B4c — _YongsinBlock 영역 사용자 노출 string literal jargon 0', () {
      // codex round 1 권고 #1 — _YongsinBlock + _YongsinSplitRow region 전체에서
      // "기운/결/본질/정수/운기/운명" 한자 jargon 0 검사. 사용자 노출 본문 mandate.
      // 도메인 화이트리스트 (사주/용신/일주/대운/억부/조후/격국/강약/계절) 는 OK.
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      final blockStart = src.indexOf('class _YongsinBlock');
      // _YongsinSplitRow 도 같은 영역 — 다음 비-Yongsin class 까지.
      final blockEnd = src.indexOf('class _StrengthBlock', blockStart);
      expect(blockStart, greaterThan(0));
      expect(blockEnd, greaterThan(blockStart));
      final region = src.substring(blockStart, blockEnd);
      // 사용자 노출 string literal 만 추출 (작은따옴표 / 큰따옴표).
      final literals = RegExp(r'''('([^'\n]+)'|"([^"\n]+)")''')
          .allMatches(region)
          .map((m) => m.group(2) ?? m.group(3) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      // "결" 단독은 정상 한국어 단어 ("결정·결과·연결") 와 충돌 → 명리학 jargon
      // 활용형 ("결을·결의·같은 결·본인의 결") 만 검사. "결정 / 결실" 류 false positive 회피.
      const jargonExact = <String>['기운', '본질', '정수', '운기', '운명', '벼린'];
      const jargonPhrase = <String>['결을', '결의', '같은 결', '본인의 결'];
      for (final lit in literals) {
        for (final j in jargonExact) {
          expect(lit.contains(j), isFalse,
              reason:
                  '_YongsinBlock string literal "$lit" 에 jargon "$j" 노출 (M5 mandate 위반)');
        }
        for (final j in jargonPhrase) {
          expect(lit.contains(j), isFalse,
              reason:
                  '_YongsinBlock string literal "$lit" 에 명리학 jargon phrase "$j" 노출');
        }
      }
    });

    test('행동4.B4d — compensationGuide ko 본문에 "기운" 0 (M5 mandate)', () {
      // R83 sprint 6 — compensationGuide() ko 본문 친근화. "기운" 제거.
      const elements = ['木', '火', '土', '金', '水'];
      for (final el in elements) {
        final g = YongsinService.compensationGuide(el, ko: true);
        expect(g.contains('기운'), isFalse,
            reason: 'compensationGuide($el) 에 "기운" 노출: $g');
        expect(g.isNotEmpty, isTrue,
            reason: 'compensationGuide($el) 본문 비어있음');
      }
    });

    test('행동4.B4b — _YongsinBlock 영역에 자미두수 별 이름 nameKo 0 노출', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      final blockStart = src.indexOf('class _YongsinBlock');
      // _YongsinSplitRow 도 같은 영역 — 다음 class 까지.
      final blockEnd = src.indexOf('class _StrengthBlock', blockStart);
      expect(blockStart, greaterThan(0),
          reason: '_YongsinBlock 미발견');
      expect(blockEnd, greaterThan(blockStart),
          reason: '_YongsinBlock 다음 class 미발견');
      final region = src.substring(blockStart, blockEnd);
      const starNamesKo = <String>[
        '자미성', '천기성', '태양성', '무곡성', '천동성', '염정성',
        '천부성', '태음성', '탐랑성', '거문성', '천상성', '천량성',
        '칠살성', '파군성', '문창성', '문곡성', '천괴성',
        '천월성', '좌보성', '우필성', '녹존성', '천마성',
      ];
      for (final star in starNamesKo) {
        expect(region.contains(star), isFalse,
            reason:
                'R70 mandate 위반: _YongsinBlock 에 자미두수 별 이름 "$star" leak');
      }
    });

    // ── 행동 5 — 5행 골든 / 일주 / backward compat ──

    test('행동5.B5 — 5행 골든 raw 보존 (1995-10-27 男 17시 → 16/21/17/41/4)', () {
      final el = golden.elements;
      expect(el.wood, 16);
      expect(el.fire, 21);
      expect(el.earth, 17);
      expect(el.metal, 41);
      expect(el.water, 4);
    });

    test('행동5.B5b — 일주 辛卯 보존', () {
      expect(golden.dayPillar.text, '辛卯');
    });

    test('행동5.B5c — judge() backward compat (monthBranch 없이 호출 시 chowhu null)', () {
      final r = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16,
        fire: 21,
        earth: 17,
        metal: 41,
        water: 4,
      );
      expect(r.chowhuYongsin, isNull);
      expect(['木', '火', '土', '金', '水'], contains(r.yongsin));
    });

    test('행동5.B5d — yongsin 산출 값 monthBranch 유무 무관 동일 (R80 회귀)', () {
      final without = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16,
        fire: 21,
        earth: 17,
        metal: 41,
        water: 4,
      );
      final withMonth = YongsinService.judge(
        dayMasterElement: '金',
        strengthLabel: '신강',
        wood: 16,
        fire: 21,
        earth: 17,
        metal: 41,
        water: 4,
        monthBranch: '戌',
      );
      expect(without.yongsin, withMonth.yongsin);
      expect(without.huisin, withMonth.huisin);
    });
  });
}
