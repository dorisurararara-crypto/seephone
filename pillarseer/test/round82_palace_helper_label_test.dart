// Round 82 sprint 5 회귀 가드 — 12 결 풀이 카드 (`_ZiweiPalaceBlock`) 의
// "도와주는 흐름" / "살짝 걸리는 흐름" 라벨 + 1줄 helper + 사주 anchor wire.
//
// 사용자 verbatim (R82 인수인계.md line 14):
//   "도와주는기운과 살짝걸리는기운이 나오는데 그게 뭔지도 안나오고 설명도 약하고"
//
// → 라벨 옆에 사주 근거 (= 사주의 X 십신 / Y 용신 / Z 신살) + 1줄 친근 helper text
//   추가. palace.luckyStars / palace.badStars 의 nameKo (자미두수 별 이름)
//   사용자 노출 0 (R70 mandate 보존).
//
// ── Sprint 계약 = testable 4 행동 ──
//   행동 1 = PalaceHelperAnchorService 가 anchor pair 를 항상 반환하고, label/helper
//     이 비어있지 않으며, 십신/용신/신살 anchor key 중 하나에 매칭.
//   행동 2 = 자미두수 별 이름 nameKo (자미성·천기성·태양성·태음성·천기성·...) 가 anchor
//     label/helper text 에 0 회 노출 (R70 mandate).
//   행동 3 = 한국어 helper 본문 audit — 한자 jargon blacklist (본질/정수/운기/기운/결) 0
//     + AI 슬롭 X + Apologetic AI 어조 X + 의료 단정 X.
//   행동 4 = result_screen.dart widget 변경 회귀 — _SupportSummaryRow 가 anchorKo /
//     helperKo 인자 사용, _ZiweiPalaceBlock 이 sajuContext 인자 사용.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/palace_helper_anchor_service.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R82 sprint 5 — 12 결 풀이 라벨 + 사주 anchor wire 가드', () {
    // 5행 골든 sample (1995-10-27 男 17시, 16/21/17/41/4 + 일주 辛卯).
    late final dynamic golden;
    late final SajuContext ctx;

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
      ctx = SajuContext.from(golden);
    });

    // 12 결 풀이 카드 전체 영역 — 모든 gungKo 에 대해 anchor pair 확보.
    const gungKoList = <String>[
      '명궁', '형제궁', '부처궁', '자녀궁', '재백궁', '질액궁',
      '천이궁', '노복궁', '관록궁', '전택궁', '복덕궁', '부모궁',
    ];

    // ── 행동 1 — anchor pair 항상 반환 + label/helper 비어있지 않음 ──

    test('행동1.B1 — 12 영역 모두 support/caution anchor pair 반환 + 텍스트 비어있지 않음', () {
      for (final gungKo in gungKoList) {
        final pair = PalaceHelperAnchorService.resolve(
          gungKo: gungKo,
          ctx: ctx,
          useKo: true,
          luckyCount: 3,
          badCount: 2,
        );
        expect(pair.support.anchorLabelKo, isNotEmpty,
            reason: '$gungKo support anchorLabelKo 비어있음');
        expect(pair.support.helperKo, isNotEmpty,
            reason: '$gungKo support helperKo 비어있음');
        expect(pair.caution.anchorLabelKo, isNotEmpty,
            reason: '$gungKo caution anchorLabelKo 비어있음');
        expect(pair.caution.helperKo, isNotEmpty,
            reason: '$gungKo caution helperKo 비어있음');
      }
    });

    test('행동1.B1b — anchor 라벨에 "사주의 ... 십신 / 용신 / 신살 / 자리" anchor 키워드 1+ 포함', () {
      // 5행 골든 사주는 십신 빈도 5+ 가 보장됨 → 십신 anchor 가 우선 hit.
      // 매 12영역마다 anchor label 에 'support' 인 경우 "십신" 또는 "용신",
      // 'caution' 인 경우 "신살" / "공망 자리" / "약한 자리" / "천천히" 중 하나 포함.
      for (final gungKo in gungKoList) {
        final pair = PalaceHelperAnchorService.resolve(
          gungKo: gungKo,
          ctx: ctx,
          useKo: true,
          luckyCount: 3,
          badCount: 2,
        );
        final sLabel = pair.support.anchorLabelKo;
        expect(
          sLabel.contains('십신') ||
              sLabel.contains('용신') ||
              sLabel.contains('받쳐주는'),
          isTrue,
          reason: '$gungKo support anchor 키워드 누락: "$sLabel"',
        );
        final cLabel = pair.caution.anchorLabelKo;
        expect(
          cLabel.contains('신살') ||
              cLabel.contains('공망') ||
              cLabel.contains('자리') ||
              cLabel.contains('천천히'),
          isTrue,
          reason: '$gungKo caution anchor 키워드 누락: "$cLabel"',
        );
      }
    });

    test('행동1.B1c — luckyCount/badCount == 0 도 friendly fallback 반환', () {
      final pair = PalaceHelperAnchorService.resolve(
        gungKo: '명궁',
        ctx: ctx,
        useKo: true,
        luckyCount: 0,
        badCount: 0,
      );
      expect(pair.support.anchorLabelKo, isNotEmpty);
      expect(pair.support.helperKo, isNotEmpty);
      expect(pair.caution.anchorLabelKo, isNotEmpty);
      expect(pair.caution.helperKo, isNotEmpty);
    });

    // ── 행동 2 — 자미두수 별 이름 nameKo noLeak 회귀 (R70 mandate) ──

    test('행동2.B2 — anchor label/helper 에 자미두수 별 이름 nameKo 0 노출', () {
      // 자미두수 16종 nameKo 풀 (ZiweiService 내부 star pool).
      const starNamesKo = <String>[
        '자미성', '천기성', '태양성', '무곡성', '천동성', '염정성',
        '천부성', '태음성', '탐랑성', '거문성', '천상성', '천량성',
        '칠살성', '파군성', '천량성', '문창성', '문곡성', '천괴성',
        '천월성', '좌보성', '우필성', '녹존성', '천마성',
      ];
      for (final gungKo in gungKoList) {
        for (final lucky in [0, 1, 3, 5]) {
          for (final bad in [0, 1, 3, 5]) {
            final pair = PalaceHelperAnchorService.resolve(
              gungKo: gungKo,
              ctx: ctx,
              useKo: true,
              luckyCount: lucky,
              badCount: bad,
            );
            final all = [
              pair.support.anchorLabelKo,
              pair.support.helperKo,
              pair.caution.anchorLabelKo,
              pair.caution.helperKo,
            ].join(' || ');
            for (final star in starNamesKo) {
              expect(all.contains(star), isFalse,
                  reason:
                      'R70 mandate 위반: $gungKo (lucky=$lucky bad=$bad) anchor 영역에 자미두수 별 이름 "$star" leak: $all');
            }
          }
        }
      }
    });

    test('행동2.B2b — result_screen.dart 의 _SupportSummaryRow 가 palace.luckyStars 의 이름 X', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // `_SupportSummaryRow` 영역에서 palace.luckyStars[ 같은 인덱싱 (이름 access) 0.
      // length 만 사용 OK. (정규식: luckyStars[ 또는 luckyStars.first/last/map 등 이름
      // 접근 패턴 검출 — 단 .length 는 허용)
      expect(src.contains('palace.luckyStars['), isFalse,
          reason: 'palace.luckyStars[] 인덱싱 발견 — 별 이름 leak 위험');
      expect(src.contains('palace.badStars['), isFalse,
          reason: 'palace.badStars[] 인덱싱 발견 — 별 이름 leak 위험');
    });

    // ── 행동 3 — 한국어 본문 audit ──

    test('행동3.B3 — helper text 에 한자 jargon noun blacklist 0', () {
      // 한자 jargon (사용자 노출 본문 금지). 단 "사주" / "십신" / "용신" / "신살" 같이
      // 자주 듣는 도메인 단어는 OK. 그 외 한자 추상 jargon (본질/정수/운기/운명) 0.
      const jargonBlacklist = <String>['본질', '정수', '운기', '운명'];
      for (final gungKo in gungKoList) {
        final pair = PalaceHelperAnchorService.resolve(
          gungKo: gungKo,
          ctx: ctx,
          useKo: true,
          luckyCount: 3,
          badCount: 2,
        );
        final allHelper = '${pair.support.helperKo} ${pair.caution.helperKo}';
        for (final jargon in jargonBlacklist) {
          expect(allHelper.contains(jargon), isFalse,
              reason: '$gungKo helper text 에 한자 jargon "$jargon" 노출: $allHelper');
        }
      }
    });

    test('행동3.B3b — helper text 에 AI 슬롭 / Apologetic AI 패턴 0 (강화)', () {
      // R82 sprint 3 oneline_jargon scanner 와 동일 blacklist + 사용자 verbatim
      // 직접 어휘 '기운' (사용자: "도와주는기운/살짝걸리는기운") helper 본문 0.
      const slopBlacklist = <String>[
        '죄송하지만',
        '단정 짓기 어렵',
        '말씀드리기 어렵',
        '센터처럼',
        '본인의 결은',
        '본인의 결',
        '흐름이',
        '흐름을',
        '흐름은',
        '기운이',
        '기운을',
        '기운은',
        '벼린',
      ];
      for (final gungKo in gungKoList) {
        for (final lucky in [0, 1, 3]) {
          for (final bad in [0, 1, 3]) {
            final pair = PalaceHelperAnchorService.resolve(
              gungKo: gungKo,
              ctx: ctx,
              useKo: true,
              luckyCount: lucky,
              badCount: bad,
            );
            final allHelper = [
              pair.support.helperKo,
              pair.caution.helperKo,
              pair.support.anchorLabelKo,
              pair.caution.anchorLabelKo,
            ].join(' || ');
            for (final slop in slopBlacklist) {
              expect(allHelper.contains(slop), isFalse,
                  reason:
                      '$gungKo (lucky=$lucky bad=$bad) helper/anchor 에 AI 슬롭 "$slop" 노출: $allHelper');
            }
          }
        }
      }
    });

    test('행동3.B3c — helper text 에 의료 단정 phrase 0', () {
      const medicalBlacklist = <String>['진단', '치료해', '병원 가야', '약 먹어야'];
      for (final gungKo in gungKoList) {
        final pair = PalaceHelperAnchorService.resolve(
          gungKo: gungKo,
          ctx: ctx,
          useKo: true,
          luckyCount: 3,
          badCount: 2,
        );
        final allHelper = '${pair.support.helperKo} ${pair.caution.helperKo}';
        for (final med in medicalBlacklist) {
          expect(allHelper.contains(med), isFalse,
              reason: '$gungKo helper text 에 의료 단정 "$med" 노출: $allHelper');
        }
      }
    });

    // ── 행동 4 — result_screen.dart widget 변경 회귀 ──

    test('행동4.B4 — _SupportSummaryRow 가 anchorKo + helperKo 인자 사용', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      expect(src.contains('anchorKo:'), isTrue,
          reason: '_SupportSummaryRow anchorKo 인자 누락');
      expect(src.contains('helperKo:'), isTrue,
          reason: '_SupportSummaryRow helperKo 인자 누락');
    });

    test('행동4.B4b — _ZiweiPalaceBlock 가 sajuContext 인자 사용', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      expect(src.contains('sajuContext: ctx'), isTrue,
          reason: '_ZiweiPalaceBlock sajuContext 인자 wire 누락');
      expect(src.contains('PalaceHelperAnchorService.resolve('), isTrue,
          reason: 'PalaceHelperAnchorService.resolve 호출 누락');
    });

    test('행동4.B4c — 5행 골든 raw 보존 (1995-10-27 男 17시 → 16/21/17/41/4)', () {
      // anchor service 가 5행 계산 자체에는 손대지 않았음 검증.
      final el = golden.elements;
      expect(el.wood, 16);
      expect(el.fire, 21);
      expect(el.earth, 17);
      expect(el.metal, 41);
      expect(el.water, 4);
    });

    test('행동4.B4d — 일주 辛卯 (1995-10-27) 보존', () {
      expect(golden.dayPillar.text, '辛卯');
    });

    // ── 행동 5 — result_screen.dart 의 R82 sprint 5 변경 영역 (12 결 풀이) 노출 본문 audit ──
    // codex round 3 의 D 보강 mandate — 카드 안의 사용자 노출 string literal 도 AI 슬롭 0.

    test('행동5.B5 — R82 sprint 5 변경 영역 노출 string literal 에 AI 슬롭 0', () {
      // _ZiweiPalaceBlock (line 3195~) + _SupportSummaryRow (line 3330~) 영역만 한정.
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // _ZiweiPalaceBlock 부터 _SectionFrame (다음 클래스) 전까지 추출.
      final blockStart = src.indexOf('class _ZiweiPalaceBlock');
      final blockEnd = src.indexOf('// _StarChip / _StarRow 제거', blockStart);
      expect(blockStart, greaterThan(0),
          reason: '_ZiweiPalaceBlock anchor 미발견');
      expect(blockEnd, greaterThan(blockStart),
          reason: '_ZiweiPalaceBlock 종료 anchor 미발견');
      final r82Region = src.substring(blockStart, blockEnd);

      // 사용자 노출 string literal 만 추출 (작은따옴표 / 큰따옴표 단순 매칭).
      final stringLiterals = RegExp(r"'([^'\n]+)'|" + r'"([^"\n]+)"')
          .allMatches(r82Region)
          .map((m) => m.group(1) ?? m.group(2) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      // R82 변경 영역의 user-visible blacklist.
      const slopBlacklist = <String>[
        '흐름이',
        '흐름을',
        '본인의 결은',
        '센터처럼',
      ];
      for (final lit in stringLiterals) {
        for (final slop in slopBlacklist) {
          expect(lit.contains(slop), isFalse,
              reason:
                  '_ZiweiPalaceBlock 영역 string literal "$lit" 에 AI 슬롭 "$slop" 노출');
        }
      }
    });

    test('행동5.B5b — R82 sprint 5 변경 영역에 사주 anchor 키워드 string literal 1+', () {
      // 사용자 노출 영역 (anchor service 호출 후 string interpolation 결과) 가
      // "= 사주의 X 십신" / "= 사주의 Y 용신" / "= 사주의 Z 신살" 패턴이려면, 라벨
      // template 의 "= 사주" prefix 가 service 안에 존재해야 함.
      final svcSrc =
          File('lib/services/palace_helper_anchor_service.dart')
              .readAsStringSync();
      expect(svcSrc.contains('= 사주의 '), isTrue,
          reason: 'anchor label template "= 사주의 " 누락');
      // 십신 / 용신 / 신살 키워드 중 2+ template 노출.
      var hits = 0;
      for (final k in ['십신', '용신', '신살', '공망']) {
        if (svcSrc.contains(k)) hits++;
      }
      expect(hits, greaterThanOrEqualTo(3),
          reason: '사주 anchor 키워드 (십신/용신/신살/공망) 3+ template 미발견');
    });

    test('행동5.B5c — R82 sprint 5 변경 영역 string literal 에 자미두수 별 nameKo 0', () {
      // R70 mandate — _ZiweiPalaceBlock 사용자 노출 영역에 자미두수 별 이름 직접 0.
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      final blockStart = src.indexOf('class _ZiweiPalaceBlock');
      final blockEnd = src.indexOf('// _StarChip / _StarRow 제거', blockStart);
      final r82Region = src.substring(blockStart, blockEnd);

      const starNamesKo = <String>[
        '자미성', '천기성', '태양성', '무곡성', '천동성', '염정성',
        '천부성', '태음성', '탐랑성', '거문성', '천상성', '천량성',
        '칠살성', '파군성', '문창성', '문곡성', '천괴성',
        '천월성', '좌보성', '우필성', '녹존성', '천마성',
      ];
      for (final star in starNamesKo) {
        expect(r82Region.contains(star), isFalse,
            reason:
                'R70 mandate 위반: _ZiweiPalaceBlock 영역에 자미두수 별 이름 "$star" leak');
      }
    });
  });
}
