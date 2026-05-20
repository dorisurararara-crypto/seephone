// Round 79 sprint 8 — 새 골든 test (G1~G7).
//
// Sprint 5-7 변경 영역 회귀 가드:
// - H3 본문 wire (PersonalizationEngine 격국·용신·신살 anchor)
// - H1 가중치 swap 시도 후 revert (5행 골든 보존)
// - Sprint 7 화면 분리 (/today route)
// - 5행 골든 1995-10-27 男 17시 16/21/17/41/4 절대 보존 mandate

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/personalization_engine.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  group('Round 79 골든 test (G1~G7)', () {
    test('G1 — 1995-10-27 男 17:00 양력 5행 16/21/17/41/4 절대 보존 (사용자 mandate)',
        () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      // 사용자 명시 5행 골든 baseline — 절대 보존 mandate.
      expect(saju.elements.wood, 16, reason: 'G1 wood');
      expect(saju.elements.fire, 21, reason: 'G1 fire');
      expect(saju.elements.earth, 17, reason: 'G1 earth');
      expect(saju.elements.metal, 41, reason: 'G1 metal');
      expect(saju.elements.water, 4, reason: 'G1 water');
      // 일주 보존 — 辛卯.
      expect(saju.dayPillar.text, '辛卯', reason: 'G1 dayPillar 辛卯');
    });

    test('G2 — 1988-07-15 男 10:15 양력 (sample #2 audit lock): 일주 辛未 + 5행 확정',
        () async {
      final saju = await SajuService().calculateSaju(
        year: 1988, month: 7, day: 15,
        hour: 10, minute: 15,
        isLunar: false, isMale: true,
      );
      // Round 79 Sprint 2 Playwright sim 결과 lock (회귀 가드).
      // Sprint 6 audit 결과: 우리 시뮬 辛未 / unsin 庚 추정 — Round 80 deferred fix.
      // 본 test 는 우리 앱 baseline lock — Round 80 fix 시 update.
      expect(saju.dayPillar.text, '辛未', reason: 'G2 dayPillar lock 辛未');
      expect(saju.elements.wood, 6, reason: 'G2 wood lock');
      expect(saju.elements.fire, 7, reason: 'G2 fire lock');
      expect(saju.elements.earth, 54, reason: 'G2 earth lock');
      expect(saju.elements.metal, 22, reason: 'G2 metal lock');
      expect(saju.elements.water, 11, reason: 'G2 water lock');
    });

    test('G3 — 2001-02-04 女 00:30 양력: 입춘 boundary + 戊戌 일주 일치 (sample #3)',
        () async {
      final saju = await SajuService().calculateSaju(
        year: 2001, month: 2, day: 4,
        hour: 0, minute: 30,
        isLunar: false, isMale: false,
      );
      // sample #3 unsin 결과 戊戌 일주 정합.
      expect(saju.dayPillar.text, '戊戌', reason: 'G3 dayPillar 戊戌');
    });

    test('G6 — 1995-10-27 男 17:00 PersonalReading: 4 line 본문 + bodyKo 격국 / actionKo 용신 / cautionKo 신살 anchor wire',
        () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      final reading = PersonalizationEngine.buildFor(
        saju,
        now: DateTime(2026, 5, 15),
      );
      // 4 line 모두 non-empty.
      expect(reading.headlineKo.isNotEmpty, isTrue, reason: 'headlineKo');
      expect(reading.bodyKo.isNotEmpty, isTrue, reason: 'bodyKo');
      expect(reading.actionKo.isNotEmpty, isTrue, reason: 'actionKo');
      expect(reading.cautionKo.isNotEmpty, isTrue, reason: 'cautionKo');
      // bodyKo — 격국 anchor 8개 중 하나 포함 (Round 79 sprint 5).
      // R86 — 사용자 mandate: 격국 jargon ("정인격" 등) 본문 노출 0 → 평어 phrase 매칭.
      // R104 sprint 6 — golden phrase 갱신: 정인격 anchor 는 R98(1.0.0+58,
      // commit eff85eb) 자연 한국어 정제에서 '배움이 잘 자리잡는 흐름이에요' →
      // '새로 익히는 게 머리에 잘 남는 날이에요' 로 의도적으로 교체됨.
      // golden 리스트가 R98 시점 갱신 누락 → stale. 현 anchor 로 동기화.
      const gPhrases = [
        '안정적인 일 흐름이 받쳐줘요',
        '추진력이 한 박자 강해지는 분위기예요',
        '새로 익히는 게 머리에 잘 남는 날이에요',
        '직관이 평소보다 또렷해지는 분위기예요',
        '차곡차곡 쌓이는 흐름이에요',
        '새 거래 신호가 자주 오는 분위기예요',
        '표현이 술술 풀리는 흐름이에요',
        '한 발 빠른 감이 살아나는 분위기예요',
      ];
      final hasGyeokguk = gPhrases.any((p) => reading.bodyKo.contains(p));
      expect(hasGyeokguk, isTrue,
          reason: 'G6 bodyKo 격국 anchor (R86 평어): ${reading.bodyKo}');
      // actionKo — 용신 5축 keyword 중 하나 포함 (Round 79 sprint 5 / DynamicTextResolver.yongsinSuffix).
      // R104 sprint 6 — 5행 水 anchor 는 R98(1.0.0+58, commit eff85eb) 자연
      // 한국어 정제에서 '충분한 수면 한 시간' → '잠을 조금만 더 챙겨도' 로
      // 의도적으로 교체됨. golden 리스트가 R98 시점 갱신 누락 → stale. 동기화.
      const ySoftMap = [
        '초록·산책', '햇볕 받는', '단맛 간식', '책상 정리', '잠을 조금만 더 챙겨도',
      ];
      final hasYongsin = ySoftMap.any((y) => reading.actionKo.contains(y));
      expect(hasYongsin, isTrue,
          reason: 'G6 actionKo 용신 anchor: ${reading.actionKo}');
      // cautionKo — non-empty (활성 신살 0 일 때는 base caution 만, anchor 0 가능).
      // 1995-10-27 男 17시 신묘 일주 → 활성 신살 빈 set (audit 확인).
      // 신살 anchor strict assert 는 G6b 의 다른 sample (활성 신살 있는) 에서 검증.
      expect(reading.cautionKo.length > 10, isTrue,
          reason: 'G6 cautionKo base 본문: ${reading.cautionKo}');
    });

    test('G6b — 활성 신살 있는 sample cautionKo: 신살 anchor 8개 중 하나 포함 (Round 79 sprint 6)',
        () async {
      // 활성 신살 있는 sample 탐색 — 1990-09-15 男 06:20 (월지 酉, 일지 卯 = 도화 가능).
      // 정확한 활성 신살 sample 발견 위해 여러 sample 시도, 본 test 에서는 base body 검증
      // + cautionKo 가 신살 anchor 합성 path 적어도 1 sample 통과 보장.
      bool foundAny = false;
      const sMap = ['귀인 신호', '공부·표현', '매력·표현', '이동·새 자리',
        '혼자 정리', '결단력이 강', '리더십', '큰 변화 신호'];
      // 활성 신살 후보 sample 들 — 다양한 birth date.
      final candidates = <(int, int, int, int, int, bool)>[
        (1990, 9, 15, 6, 20, true),
        (2010, 9, 15, 6, 20, true),
        (1995, 12, 30, 12, 0, false),
        (1998, 5, 5, 10, 0, true),
      ];
      for (final s in candidates) {
        final saju = await SajuService().calculateSaju(
          year: s.$1, month: s.$2, day: s.$3,
          hour: s.$4, minute: s.$5,
          isLunar: false, isMale: s.$6,
        );
        final reading = PersonalizationEngine.buildFor(
          saju,
          now: DateTime(2026, 5, 15),
        );
        if (sMap.any((m) => reading.cautionKo.contains(m))) {
          foundAny = true;
          break;
        }
      }
      // 활성 신살이 있는 sample 적어도 1개 — cautionKo 의 신살 anchor wire 회귀 가드.
      expect(foundAny, isTrue,
          reason: 'G6b 4 candidate sample 중 1개 이상 신살 anchor 합성 fail');
    });

    test('G8 — Round 79 톤 가드: 3 sample × 8 line (ko+en) × 폐기 phrase / 한자 / 의료금융 단정 0',
        () async {
      // DynamicTextResolver + PersonalizationEngine + (모든 anchor pool) 본문 톤 회귀 가드.
      // 3 sample (G1 골든 / G3 입춘 / G2 sample #2) — anchor pool 의 ko/en 풀 sweep.
      final samples = <(int, int, int, int, int, bool)>[
        (1995, 10, 27, 17, 0, true),
        (2001, 2, 4, 0, 30, false),
        (1988, 7, 15, 10, 15, true),
      ];
      // 한자 jargon 2글자 이상 — 본문 노출 X 가드 (R73 sprint 6 mandate).
      final kanjiJargon = RegExp(r'[一-鿿]{2,}');
      // 폐기 phrase (R73-R78 mandate + R77 Round 77 sprint 7).
      const banned = [
        '본인의 결', '센터처럼', 'K팝 센터처럼', '리텐션', '퍼포먼스', ' PT', 'pt 받는',
      ];
      // 의료·금융·사망 단정 X (양면 단정 톤).
      const medFin = ['이혼', '암 발병', '파산', '암 진단', '재정 파탄'];
      for (final s in samples) {
        final saju = await SajuService().calculateSaju(
          year: s.$1, month: s.$2, day: s.$3,
          hour: s.$4, minute: s.$5,
          isLunar: false, isMale: s.$6,
        );
        final reading = PersonalizationEngine.buildFor(
          saju,
          now: DateTime(2026, 5, 15),
        );
        final bodies = [
          reading.headlineKo,
          reading.bodyKo,
          reading.actionKo,
          reading.cautionKo,
          reading.headlineEn,
          reading.bodyEn,
          reading.actionEn,
          reading.cautionEn,
        ];
        for (final b in bodies) {
          expect(kanjiJargon.hasMatch(b), isFalse,
              reason: 'kanji jargon in sample ${s.$1}-${s.$2}-${s.$3}: $b');
          for (final ban in banned) {
            expect(b.contains(ban), isFalse,
                reason: '폐기 phrase $ban in sample ${s.$1}-${s.$2}-${s.$3}: $b');
          }
          for (final m in medFin) {
            expect(b.contains(m), isFalse,
                reason: '의료/금융 단정 $m in sample ${s.$1}-${s.$2}-${s.$3}: $b');
          }
        }
      }
    });

    test('G7 — /today route 등록 + redirect rule 확인 (router.dart grep 강화)', () {
      // Round 79 sprint 7 — 신규 /today route + 알림 deep-link redirect mandate.
      final routerSrc = File('lib/router.dart').readAsStringSync();
      // GoRoute 등록 (path 와 builder TodayScreen).
      expect(routerSrc.contains("path: '/today'"), isTrue,
          reason: '/today GoRoute path');
      expect(routerSrc.contains('TodayScreen'), isTrue,
          reason: '/today builder TodayScreen');
      // protected list 등록.
      expect(routerSrc.contains("'/today',"), isTrue,
          reason: '/today protected list');
      // redirect rule — anchor=today_event 시 /today 로.
      expect(routerSrc.contains("anchor"), isTrue, reason: 'anchor redirect rule');
      expect(routerSrc.contains("'today_event'"), isTrue,
          reason: 'anchor value today_event');
      expect(routerSrc.contains("return '/today'"), isTrue,
          reason: 'redirect target /today');
    });

    test('G7b — home_screen push target /today (사용자 mandate)', () {
      final homeSrc = File('lib/screens/home_screen.dart').readAsStringSync();
      // Sprint 7 — _TodayEventCard push target 변경.
      expect(homeSrc.contains("push('/today')"), isTrue,
          reason: 'home _TodayEventCard push /today');
    });

    test('G7c — today_screen.dart 신규 + TodayEventDetailSection + TodayDeepReadingSection mount',
        () {
      final todaySrc =
          File('lib/screens/today_screen.dart').readAsStringSync();
      expect(todaySrc.contains('TodayEventDetailSection'), isTrue,
          reason: 'today_screen TodayEventDetailSection');
      expect(todaySrc.contains('TodayDeepReadingSection'), isTrue,
          reason: 'today_screen TodayDeepReadingSection');
    });
  });
}
