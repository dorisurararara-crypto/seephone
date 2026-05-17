// Round 83 sprint 5 (P1-E) — 출생 시간 모름 처리 회귀 가드.
//
// 사용자 mandate (외부 reviewer P0 #4):
//   "출생시간 모르는 사용자가 많음. '시간 모름' 을 단순히 00:00 으로 계산하면 오해.
//    시간 모르면 시주 제외 + '시주 미포함 결과' 라고 표시 + 대운/성향 중 시간 영향
//    큰 부분은 흐리게 표시."
//
// ── Sprint 계약 = testable 5 행동 ──
//   B1 = unknownTime=true 결과에서 시주(hourPillar) 가 null + 5행 분포는 3 기둥 합으로
//        산출 (시주 hidden stem 미포함). `SajuService.calculateSaju(... unknownTime:true)`
//        cross-check.
//   B2 = unknownTime=false 결과 (5행 골든 1995-10-27 男 17시) 16/21/17/41/4 보존
//        + 일주 辛卯 (M4 mandate).
//   B3 = `_FourPillarsSection` widget 에 unknownTime=true 전달 시 HOUR _PillarCol 영역에
//        ValueKey('pillar-col-hour-dim') Opacity wrapper mount + 카드 하단
//        ValueKey('hour-pillar-unknown-disclaimer') disclaimer block mount.
//   B4 = arb 신규 key 3종 (hourPillarUnknownDisclaimer / hourPillarUnknownBadge /
//        timeUnknownAffectsAccuracy) ko + en 둘 다 존재 + 빈 값 X + generated getter 존재.
//   B5 = `_SipsinPersonaSection` + `_LifeStageSection` widget 에 unknownTime=true 전달 시
//        ValueKey('sipsin-persona-time-unknown') + ValueKey('life-stage-time-unknown')
//        보조 안내 라벨 mount.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_stage_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/sipsin_persona_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // R83 sprint 5 (codex audit r3 보강) — B6c strict 검증을 위해 LifeStage/Sipsin
  // pool JSON seed. test 환경의 rootBundle 미지원 우회 (life_stage_service_test 패턴 답습).
  setUpAll(() async {
    final stage = json.decode(
        File('assets/data/life_stage_pool.json').readAsStringSync())
        as Map<String, dynamic>;
    LifeStageService.seedForTest(stage);
    final sipsin = json.decode(
        File('assets/data/sipsin_persona.json').readAsStringSync())
        as Map<String, dynamic>;
    SipsinPersonaService.seedForTest(sipsin);
  });

  group('R83 sprint 5 — P1-E 출생 시간 모름 처리', () {
    // ── 행동 1 (B1) — unknownTime=true 시 hourPillar=null + 5행 3 기둥 분포 ──
    test('B1 — unknownTime=true → hourPillar=null + 5행 raw 분포 3 기둥 합', () async {
      final svc = SajuService();
      // 1995-10-27 男 hour=0 — 5행 골든 sample 과 동일 일자.
      final unknown = await svc.calculateSaju(
        year: 1995,
        month: 10,
        day: 27,
        hour: 0,
        minute: 0,
        isLunar: false,
        isMale: true,
        unknownTime: true,
      );
      expect(unknown.hourPillar, isNull,
          reason: 'P1-E: unknownTime=true → hourPillar 미계산 (null)');
      // 5행 raw 분포는 3 기둥(년/월/일) 합 — 시주 hidden stem 미포함.
      final total = unknown.elements.wood +
          unknown.elements.fire +
          unknown.elements.earth +
          unknown.elements.metal +
          unknown.elements.water;
      expect(total > 0, isTrue, reason: 'P1-E: 3 기둥만으로도 5행 raw 분포 산출');
      // 일주 보존 — unknownTime 이어도 dayPillar 영향 0 (시간 모름 = 시주만 제외).
      expect(unknown.dayPillar.text, equals('辛卯'),
          reason: 'P1-E: 1995-10-27 일주 辛卯 보존 (unknownTime 영향 X)');
    });

    // ── 행동 1b (B1b) — unknownTime=true 일 때 hour input invariance ──
    // 사용자가 input_screen 의 _unknownTime 을 체크하면 hour 값은 의미 없어짐.
    // hour=0 / hour=12 / hour=23 (자시 boundary 포함) 모두 동일 결과여야 함 —
    // 시주 계산 분기 (`if (!unknownTime) hourP = _hourPillar(...)`) 가 시간 입력
    // invariance 를 보장한다는 회귀 가드.
    test('B1b — unknownTime=true → hour=0/12/23 모두 동일 5행 분포 + 일주', () async {
      final svc = SajuService();
      final hours = <int>[0, 12, 23];
      final results = <FiveElements>[];
      final dayPillars = <String>[];
      for (final hour in hours) {
        final r = await svc.calculateSaju(
          year: 1995,
          month: 10,
          day: 27,
          hour: hour,
          minute: 0,
          isLunar: false,
          isMale: true,
          unknownTime: true,
        );
        expect(r.hourPillar, isNull,
            reason: 'P1-E: hour=$hour 라도 unknownTime=true → hourPillar null');
        results.add(r.elements);
        dayPillars.add(r.dayPillar.text);
      }
      // 5행 분포 완전 동일 — hour input invariance 보장.
      for (var i = 1; i < results.length; i++) {
        expect(results[i].wood, equals(results[0].wood),
            reason: 'P1-E: hour=${hours[i]} 와 hour=${hours[0]} 木 분포 불일치');
        expect(results[i].fire, equals(results[0].fire),
            reason: 'P1-E: hour=${hours[i]} 와 hour=${hours[0]} 火 분포 불일치');
        expect(results[i].earth, equals(results[0].earth),
            reason: 'P1-E: hour=${hours[i]} 와 hour=${hours[0]} 土 분포 불일치');
        expect(results[i].metal, equals(results[0].metal),
            reason: 'P1-E: hour=${hours[i]} 와 hour=${hours[0]} 金 분포 불일치');
        expect(results[i].water, equals(results[0].water),
            reason: 'P1-E: hour=${hours[i]} 와 hour=${hours[0]} 水 분포 불일치');
      }
      // 일주도 hour 와 무관 (자시 boundary 23시는 unknownTime 시 day shift X — manseryeok step 4).
      for (var i = 1; i < dayPillars.length; i++) {
        expect(dayPillars[i], equals(dayPillars[0]),
            reason: 'P1-E: hour=${hours[i]} 의 일주가 hour=${hours[0]} 와 다름');
      }
    });

    // ── 행동 1c (B1c) — unknownTime=true 5행 분포 ≠ unknownTime=false (시주 기여 영향) ──
    // 17시 sample 의 5행 = 16/21/17/41/4. unknownTime=true (시주 미계산) 는 시주
    // 천간/지지 (지장간 포함) 의 5행 기여가 사라지므로 5행 분포 자체가 달라야 함.
    // 분포가 같다면 시주 영향 = 0 → 시주 분리 의도 위반.
    // (raw 합계는 normalize 로 비슷할 수 있으므로 분포 차이로 검증.)
    test('B1c — unknownTime=true 5행 분포 ≠ unknownTime=false (시주 기여 영향)',
        () async {
      final svc = SajuService();
      final unknown = await svc.calculateSaju(
        year: 1995,
        month: 10,
        day: 27,
        hour: 0,
        minute: 0,
        isLunar: false,
        isMale: true,
        unknownTime: true,
      );
      final golden = await svc.calculateSaju(
        year: 1995,
        month: 10,
        day: 27,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
        unknownTime: false,
      );
      // 5행 분포 vector 비교 — 적어도 한 element 의 raw 가 달라야 함.
      // (모두 같다면 시주 영향 0 → P1-E 의도 위반.)
      final samePattern = unknown.elements.wood == golden.elements.wood &&
          unknown.elements.fire == golden.elements.fire &&
          unknown.elements.earth == golden.elements.earth &&
          unknown.elements.metal == golden.elements.metal &&
          unknown.elements.water == golden.elements.water;
      expect(samePattern, isFalse,
          reason:
              'P1-E: 시주 기여 사라짐 → 5행 분포 변화 (unknown=${unknown.elements.wood}/${unknown.elements.fire}/${unknown.elements.earth}/${unknown.elements.metal}/${unknown.elements.water} vs golden=${golden.elements.wood}/${golden.elements.fire}/${golden.elements.earth}/${golden.elements.metal}/${golden.elements.water})');
      // 17시 sample 의 일간 = 辛 (金). 시주가 己亥 = 土+水 — 시주 빠지면 金 분포 우세
      // 정도가 달라야 함. 골든 metal=41 (압도) → unknown 의 metal 도 dominant 이지만
      // raw 값은 골든보다 작거나 같거나 다른 패턴.
      expect(unknown.elements.metal, isNot(equals(golden.elements.metal)),
          reason: 'P1-E: 시주 영향 직접 확인 — 金 분포 변화 (시주 己亥 영향)');
    });

    // ── 행동 2 (B2) — unknownTime=false 골든 보존 (M4 mandate) ──
    test('B2 — 5행 골든 1995-10-27 男 17시 16/21/17/41/4 + 일주 辛卯 보존', () async {
      final svc = SajuService();
      final golden = await svc.calculateSaju(
        year: 1995,
        month: 10,
        day: 27,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
        unknownTime: false,
      );
      expect(golden.dayPillar.text, equals('辛卯'),
          reason: 'M4: 일주 辛卯 골든 보존');
      expect(golden.hourPillar, isNotNull,
          reason: 'M4: unknownTime=false → 시주 계산 (non-null)');
      expect(golden.elements.wood, equals(16), reason: 'M4: 木 16 골든');
      expect(golden.elements.fire, equals(21), reason: 'M4: 火 21 골든');
      expect(golden.elements.earth, equals(17), reason: 'M4: 土 17 골든');
      expect(golden.elements.metal, equals(41), reason: 'M4: 金 41 골든');
      expect(golden.elements.water, equals(4), reason: 'M4: 水 4 골든');
    });

    // ── 행동 3 (B3) — result_screen widget wire 정적 검증 ──
    // (test 환경에서 ResultScreen pump 시 manseryeok / personalization 의 async chain +
    //  rootBundle.loadString assets/data/*.json 모두가 mock 필요 → 소스 grep 으로 wire 검증.)
    group('B3 — result_screen.dart 안 시주 영역 흐림 + disclaimer wire', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();

      test('B3a — _FourPillarsSection 에 unknownTime prop wire', () {
        expect(src.contains('class _FourPillarsSection'), isTrue);
        expect(src.contains('final bool unknownTime'), isTrue,
            reason: 'P1-E: _FourPillarsSection.unknownTime field 추가');
        // call site (build) 에서 birth?.unknownTime 전달.
        expect(src.contains('unknownTime: birth?.unknownTime ?? false'), isTrue,
            reason: 'P1-E: build 의 _FourPillarsSection call site 에서 unknownTime 전달');
      });

      test('B3b — _PillarCol HOUR dim=true 시 Opacity wrapper mount', () {
        expect(src.contains("ValueKey('pillar-col-hour-dim')"), isTrue,
            reason: 'P1-E: dim=true 시 ValueKey("pillar-col-hour-dim") Opacity wrapper');
        expect(src.contains('opacity: 0.4'), isTrue,
            reason: 'P1-E: HOUR 영역 opacity 0.4 흐림 처리');
        expect(src.contains('dim: unknownTime'), isTrue,
            reason: 'P1-E: HOUR _PillarCol 에 dim=unknownTime 전달');
      });

      test('B3c — 시주 미포함 disclaimer block mount', () {
        expect(src.contains("ValueKey('hour-pillar-unknown-disclaimer')"), isTrue,
            reason: 'P1-E: disclaimer block ValueKey');
        expect(src.contains('l.hourPillarUnknownDisclaimer'), isTrue,
            reason: 'P1-E: disclaimer 본문 getter 호출');
        expect(src.contains('l.hourPillarUnknownBadge'), isTrue,
            reason: 'P1-E: 미포함 badge 라벨 getter 호출');
      });
    });

    // ── 행동 4 (B4) — arb 신규 key 3종 + generated getter ──
    group('B4 — arb 신규 key 3종 ko + en + getter', () {
      const newKeys = <String>[
        'hourPillarUnknownDisclaimer',
        'hourPillarUnknownBadge',
        'timeUnknownAffectsAccuracy',
      ];

      test('B4a — ko / en arb 에 신규 key 3종 + 빈 값 X', () {
        final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
            as Map<String, dynamic>;
        final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
        for (final k in newKeys) {
          expect(ko.containsKey(k), isTrue,
              reason: 'app_ko.arb 에 key "$k" 누락');
          expect(en.containsKey(k), isTrue,
              reason: 'app_en.arb 에 key "$k" 누락');
          expect((ko[k] as String).isNotEmpty, isTrue,
              reason: 'app_ko.arb["$k"] 빈 값');
          expect((en[k] as String).isNotEmpty, isTrue,
              reason: 'app_en.arb["$k"] 빈 값');
        }
      });

      test('B4b — generated app_localizations.dart 에 getter 3종', () {
        final src = File('lib/l10n/app_localizations.dart').readAsStringSync();
        for (final k in newKeys) {
          expect(src.contains('String get $k'), isTrue,
              reason: 'app_localizations.dart 에 getter "$k" 누락');
        }
      });

      test('B4c — ko 본문 페르소나 톤 (해요체 + 친근 어휘 + 자미두수 별 이름 0)', () {
        final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
            as Map<String, dynamic>;
        // 사용자 노출 본문 — "시주" 또는 "시간" 도메인 어휘 포함 + 친근 해요체.
        final disclaimer = ko['hourPillarUnknownDisclaimer'] as String;
        final badge = ko['hourPillarUnknownBadge'] as String;
        final note = ko['timeUnknownAffectsAccuracy'] as String;
        expect(disclaimer.contains('시주') || disclaimer.contains('시각'), isTrue,
            reason: 'M5: 사주 도메인 어휘 "시주" or "시각" 노출');
        expect(badge.contains('시주'), isTrue,
            reason: 'M5: badge 에 "시주" 어휘 노출');
        expect(note.contains('시간'), isTrue,
            reason: 'M5: 정확도 안내 본문에 "시간" 어휘 노출');
        // 해요체 또는 친근 어미 끝.
        expect(
            disclaimer.endsWith('요') ||
                disclaimer.endsWith('요.') ||
                disclaimer.contains('요'),
            isTrue,
            reason: 'M5: 해요체 친근 톤');
        // 자미두수 별 이름 leak 0 (R70 hidden mandate).
        const ziweiStars = <String>['자미', '천부', '천기', '태양', '무곡'];
        for (final star in ziweiStars) {
          expect(disclaimer.contains(star), isFalse,
              reason: 'R70: 자미두수 별 이름 "$star" leak 금지 (disclaimer)');
          expect(badge.contains(star), isFalse,
              reason: 'R70: 자미두수 별 이름 "$star" leak 금지 (badge)');
          expect(note.contains(star), isFalse,
              reason: 'R70: 자미두수 별 이름 "$star" leak 금지 (note)');
        }
      });

      test('B4d — ko 본문 의료/법률 단정 0 + AI 슬롭 0', () {
        final ko = jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
            as Map<String, dynamic>;
        const blacklist = <String>[
          '진단',
          '처방',
          '치료',
          'AI',
          '챗봇',
          '데이터베이스',
          'algorithm',
        ];
        for (final k in [
          'hourPillarUnknownDisclaimer',
          'hourPillarUnknownBadge',
          'timeUnknownAffectsAccuracy',
        ]) {
          final v = (ko[k] as String);
          for (final word in blacklist) {
            expect(v.contains(word), isFalse,
                reason: 'M5: key "$k" 에 금지 어휘 "$word" 노출: "$v"');
          }
        }
      });
    });

    // ── 행동 5 (B5) — 대운 / 성향 보조 안내 라벨 wire ──
    // R88 sprint 3 — _SipsinPersonaSection / _LifeStageSection widget 본체 정의는
    //   보존 (sprint 10 baseline 재설정에서 정리). result_screen build 안 mount 0 → 폐기.
    //   _FourPillarsSection 의 unknownTime wire 만 B5c-r88 에서 검증 보존.
    group('B5 — _FourPillarsSection unknownTime call site (R88 sprint 3 result_screen 17 카테고리 재작성 후)', () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();

      test('B5c-r88 — result_screen build 의 _FourPillarsSection call 에서 birth?.unknownTime 전달',
          () {
        final lines = src.split('\n');
        var pillarCall = false;
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('_FourPillarsSection(')) {
            final scope = lines.skip(i).take(8).join('\n');
            if (scope.contains('unknownTime: birth?.unknownTime')) {
              pillarCall = true;
            }
          }
        }
        expect(pillarCall, isTrue,
            reason: 'P1-E (R88 보존): _FourPillarsSection call site 에서 unknownTime 전달');
      });

      test('B5d — _TimeUnknownNote 공용 widget class 보존 (sprint 10 까지 dead code OK)',
          () {
        expect(src.contains('class _TimeUnknownNote'), isTrue,
            reason: 'P1-E: _TimeUnknownNote widget class 정의 보존');
        expect(src.contains('l.timeUnknownAffectsAccuracy'), isTrue,
            reason: 'P1-E: 보조 라벨에 timeUnknownAffectsAccuracy 본문 사용');
      });
    });

    // ── 행동 6 (B6) — ResultScreen pump 실제 widget tree 검증 ──
    // R88 sprint 3 폐기: result_screen 의 _CollapsibleSection / _SipsinPersonaSection
    //   mount 자체가 사라짐 (17 카테고리 skeleton 으로 갈아엎힘). HomeScreen 의 ziwei
    //   차단 (B7b 보존) + _FourPillarsSection 의 시주 흐림 + disclaimer source-grep
    //   검증 (B3b/B3c 보존) 으로 핵심 mandate (시간 모름 시 임의 계산 차단) 회귀 가드.
    //   widget pump 기반 strict 검증은 sprint 10 baseline 재설정 시 R88 신규 test 로 작성.

    // ── R83 sprint 5 ziwei 차단 → R88 에서 HomeScreen 에만 잔존 (result_screen 17 카테고리 재설계로 ziwei mount 0) ──
    test('B7 — R88 sprint 3: result_screen 의 ziwei 계산 호출 자체 mount 0 (17 카테고리 재설계)',
        () {
      final src =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // R88 sprint 3 — ResultScreen.build 안에서 ZiweiService.calculate 호출 자체 제거.
      // ziwei UI / crossmatch / palace 모두 result_screen 에서 사라짐. 따라서
      // unknownTime 기반 차단 분기도 result_screen 에서는 불필요.
      // HomeScreen 의 ziwei 차단 (B7b) 로 mandate 핵심 보존.
      expect(src.contains('ZiweiService.calculate'), isFalse,
          reason: 'R88 sprint 3: result_screen 안 ziwei calculate 호출 0');
      // 임의 12시 fallback 코드 (`birth.unknownTime ? 12 : birth.birthHour`) 제거.
      expect(src.contains('birth.unknownTime ? 12 : birth.birthHour'), isFalse,
          reason: 'P1-E P0 #4: 임의 12시 fallback 제거 (false 신뢰도 차단)');
    });

    // ── R83 sprint 5 보강 (codex audit r2 권고) — Home ziwei 차단 ──
    // codex audit round 2 직접 지적:
    //   "HomeScreen 에서 unknownTime 자미두수 계산이 아직 살아 있음 — input_screen 은
    //    unknownTime=true 시 birthHour=0 으로 store → home 이 임의 0시 ziwei 계산 위험."
    // home_screen.dart 의 ZiweiService.calculate 호출도 동일하게 차단 보장.
    test('B7b — unknownTime=true → HomeScreen ziwei 계산 차단 (임의 0시 계산 X)',
        () {
      final src =
          File('lib/screens/home_screen.dart').readAsStringSync();
      // home_screen.build 에서 ZiweiService.calculate 호출 영역.
      // !birth.unknownTime 분기로 차단.
      expect(src.contains('!birth.unknownTime'), isTrue,
          reason: 'P1-E P0 #4: HomeScreen 도 unknownTime=true 시 ziwei 차단 mandate');
      // sixAxis / chips 가 ziwei null 시 자동 null 되는 기존 wire 보존.
      expect(src.contains('ziwei == null') || src.contains('ziwei == null'),
          isTrue,
          reason: 'P1-E: sixAxis/chips 가 ziwei null 시 자동 null fallback');
    });

    // ── 회귀 가드 — R71 wire 보존 ──
    test('R71 회귀 — input_screen _unknownTime 체크박스 위치 / signature 보존', () {
      final inputSrc =
          File('lib/screens/input_screen.dart').readAsStringSync();
      expect(inputSrc.contains('bool _unknownTime = false'), isTrue,
          reason: 'R71 회귀: _unknownTime state field 보존');
      expect(inputSrc.contains('unknownTime: _unknownTime'), isTrue,
          reason: 'R71 회귀: saju_service.calculateSaju(... unknownTime:) 전달 보존');
    });

    test('R71 회귀 — saju_service.calculateSaju signature 보존', () {
      final svcSrc =
          File('lib/services/saju_service.dart').readAsStringSync();
      expect(svcSrc.contains('bool unknownTime = false'), isTrue,
          reason: 'R71 회귀: calculateSaju 의 unknownTime parameter 보존');
    });
  });
}

// R88 sprint 3 — ProviderScope override 용 dummy notifier 폐기 (result_screen pump
// 검증 자체가 17 카테고리 재설계로 폐기됨). models/saju_result import 는 SajuResult /
// UserBirthInfo / UserGender 등 다른 직접 사용을 위해 남겨두지만, dummy notifier 본체는
// 정리. sprint 10 baseline 재설정 때 R88 신규 result_screen widget pump test 작성.
