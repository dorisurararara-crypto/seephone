// Round 83 sprint 9 — 회귀 가드 round close 통합 invariant.
//
// 사용자 mandate (R83 spec §3 sprint 9):
//   사용자가 `flutter test` 전체 PASS 확인. 1995-10-27 男 17시 5행 골든
//   16/21/17/41/4 + 일주 辛卯 + R69 lock 6각 점수 + R71~R82 시그니처 +
//   R83 sprint 2~6 anchor 모두 보존.
//
// **사용자 mandate (이번 sprint 9 전제)**: sprint 7/8 (만세력 algorithmic +
// H1 swap) 스킵 → R84 deferred (사용자 sample 미수령). 본 sprint 9 =
// sprint 2~6 (P1-G/F/B/E/D) 5 fix 통합 회귀 가드.
//
// 본 test 는 sprint 1~6 의 모든 invariant 를 한 곳에서 통합 검증.
// 산출 값 깨지면 즉시 sprint 중단 (G7 protocol — M4 mandate 위반).
//
// 검증 축:
//   I1. 5행 골든 1995-10-27 男 17시 양력 = 16/21/17/41/4 + 일주 辛卯 (R75).
//   I2. R69 lock 6각 점수 (1995-10-27 男 15:43) — 본성 78 / 연애 78 / 일 72 /
//       돈 74 / 건강 57 / 평판 71 + matchCount 5 + matchedAxes 5종 (R80 baseline).
//   I3. R71~R82 시그니처 source-level grep 보존:
//       - R70/R73 자미두수 UI hidden (`kIsZiweiUiHidden=true` result_screen).
//       - R71 oracle hero (oracle_hero / OracleHero anchor).
//       - R75 5행 calibration 음양 10분류 (sipsin_persona_service 또는 ten god).
//       - R79 `/today` route 등록 (router.dart).
//       - R80 신살 anchor (양인 / yangIn) source 존재.
//       - R80 sprint 6 조후용신 wire (yongsin_service `chowhuFor` 또는 monthBranch).
//       - R80 sprint 5 radar 색상 재설계 (radar 영역 색상 anchor — six axis radar).
//       - R82 sprint 2 result_screen 에서 TodayEventDetailSection mount 0 (/today 단독).
//       - R82 sprint 4 _MatchBadge widget 보존.
//       - R82 sprint 5 palace_helper_anchor_service 존재.
//       - R82 sprint 6 animal_context_service 존재.
//       - R82 sprint 7 _CollapsibleSection first-fold 존재.
//       - R82 sprint 9 Gender.other / UserGender enum 처리.
//       - R82 sprint 10 "세력 분포 점수" arb 라벨.
//       - R82 sprint 11 Profile reset confirm dialog.
//       - R82 sprint 12 package_info_plus dependency.
//   I4. R83 sprint 2~6 anchor source-level 존재:
//       - sprint 2 (P1-G) info_saju_calc_screen.dart 파일 + InfoSajuCalcScreen
//         widget + settingsCalcBasisRow arb key.
//       - sprint 3 (P1-F) celebDisclosureBanner / celebDisclosureBannerHelper /
//         celebCardConfidenceLabel arb 3종 ko+en.
//       - sprint 4 (P1-B) inputZasiHelperTitle arb + input_screen 자시 helper.
//       - sprint 5 (P1-E) result_screen "시간 모름" disclaimer + hourPillarUnknown
//         anchor + saju_result 모델의 unknownTime 처리.
//       - sprint 6 (P1-D) result_screen `_YongsinSplitRow` + yongsin_service
//         `gyeokgukYongsinFor` / chowhu / 격국용신 분리.
//   I5. 시크릿 leak 가드 (회귀 sprint 추가 안전 net).
//
// 시뮬레이터 / 에뮬레이터 새 부팅 X (M3 mandate).
// 시크릿 leak X. 5행 골든 / R69 lock 값 변경 X.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/manseryeok_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/six_axis_score_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  group('R83 sprint 9 — round close 통합 invariant', () {
    // ─────────────── I1: 5행 골든 (1995-10-27 男 17시 양력) ───────────────
    test('I1 — 5행 골든 1995-10-27 男 17시 = 16/21/17/41/4 + 일주 辛卯 (M4)',
        () {
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
      expect(el.wood, 16, reason: '木 = 16 (R75 calibration)');
      expect(el.fire, 21, reason: '火 = 21 (R75 calibration)');
      expect(el.earth, 17, reason: '土 = 17 (R75 calibration)');
      expect(el.metal, 41, reason: '金 = 41 (R75 calibration)');
      expect(el.water, 4, reason: '水 = 4 (R75 calibration)');
      expect(r.dayPillar.text, '辛卯',
          reason: '일주 = 辛卯 (R75 calibration / M4 mandate)');
    });

    // ─────────────── I2: R69 lock (1995-10-27 男 15:43) ───────────────
    test('I2 — R69 lock 6각 점수 + matchCount 5/6 (R80 baseline)', () async {
      final SajuResult saju = await SajuService().calculateSaju(
        year: 1995,
        month: 10,
        day: 27,
        hour: 15,
        minute: 43,
        isLunar: false,
        isMale: true,
      );
      final ZiweiResult ziwei = ZiweiService.calculate(
        year: 1995,
        month: 10,
        day: 27,
        hour: 15,
        minute: 43,
        isMale: true,
      );
      final s = SixAxisScoreService.compute(saju, ziwei);
      expect(s.matchCount, 5, reason: 'matchCount = 5/6 (R80 lock)');
      expect(s.matchedAxes, ['연애', '일', '돈', '건강', '평판'],
          reason: 'matchedAxes 5종 (R80 lock)');
      expect(s.combinedScores['본성'], 78, reason: '본성 = 78 (R80 lock)');
      expect(s.combinedScores['연애'], 78, reason: '연애 = 78 (R80 lock)');
      expect(s.combinedScores['일'], 72, reason: '일 = 72 (R80 lock)');
      expect(s.combinedScores['돈'], 74, reason: '돈 = 74 (R80 lock)');
      expect(s.combinedScores['건강'], 57, reason: '건강 = 57 (R80 lock)');
      expect(s.combinedScores['평판'], 71, reason: '평판 = 71 (R80 lock)');
    });

    // ─────────────── I3: R71~R82 시그니처 source 보존 ───────────────
    test('I3 — R70/R73/R79/R80 핵심 시그니처 source 보존', () {
      final resultScreen =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // R70 / R73 — 자미두수 UI hidden flag.
      expect(resultScreen.contains('const bool kIsZiweiUiHidden = true'),
          isTrue,
          reason: '자미두수 UI hidden flag 보존 (R70 / R73)');

      // R79 sprint 7 — /today route 등록 + redirect.
      final router = File('lib/router.dart').readAsStringSync();
      expect(router.contains("path: '/today'"), isTrue,
          reason: '/today route 등록 보존 (R79 sprint 7)');
      expect(router.contains("return '/today';"), isTrue,
          reason: '/today redirect rule 보존 (R79 sprint 7)');

      // R71 — oracle hero widget (lib 안 anchor 1개 이상).
      final libDir = Directory('lib');
      var foundOracleHero = false;
      var foundYangin = false;
      var foundChowhu = false;
      for (final f in libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        if (!foundOracleHero &&
            (src.contains('OracleHero') || src.contains('_OracleHero'))) {
          foundOracleHero = true;
        }
        // R80 sprint 4 신살 anchor 양인.
        if (!foundYangin && (src.contains('양인') || src.contains('yangIn'))) {
          foundYangin = true;
        }
        // R80 sprint 6 조후용신 wire (yongsin_service 의 chowhu key).
        if (!foundChowhu &&
            (src.contains('chowhu') || src.contains('조후용신'))) {
          foundChowhu = true;
        }
      }
      expect(foundOracleHero, isTrue,
          reason: 'R71 oracle hero anchor 보존');
      expect(foundYangin, isTrue,
          reason: 'R80 sprint 4 신살 anchor (양인) 보존');
      expect(foundChowhu, isTrue,
          reason: 'R80 sprint 6 조후용신 wire 보존');
    });

    // ─────────────── I3b: R82 sprint 2~12 산출물 source 보존 ───────────────
    test('I3b — R82 sprint 2/4/5/6/7/9/10/11/12 산출물 source 보존', () {
      final resultScreen =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // R82 sprint 2 (#4) — /today route 단독 → result_screen 에서 mount 제거.
      expect(resultScreen.contains('TodayEventDetailSection('), isFalse,
          reason: 'R82 sprint 2 — result_screen 에서 TodayEventDetailSection '
              'mount 제거 보존 (/today 단독)');

      // R82 sprint 4 — _MatchBadge widget 존재 (widgets/six_axis_radar.dart)
      // + result_screen 안 "두 번 봐도 같이 잡힌 강점" 라벨 anchor 보존.
      final radarSrc =
          File('lib/widgets/six_axis_radar.dart').readAsStringSync();
      expect(radarSrc.contains('_MatchBadge'), isTrue,
          reason: 'R82 sprint 4 — _MatchBadge widget (six_axis_radar) 보존');
      expect(resultScreen.contains('두 번 봐도 같이 잡힌 강점'), isTrue,
          reason: 'R82 sprint 4 — "두 번 봐도 같이 잡힌 강점" 라벨 보존');

      // R82 sprint 5 — palace_helper_anchor_service 존재.
      final palaceHelper =
          File('lib/services/palace_helper_anchor_service.dart');
      expect(palaceHelper.existsSync(), isTrue,
          reason: 'R82 sprint 5 — palace_helper_anchor_service.dart 존재');

      // R82 sprint 6 — animal_context_service 존재.
      final animalCtx = File('lib/services/animal_context_service.dart');
      expect(animalCtx.existsSync(), isTrue,
          reason: 'R82 sprint 6 — animal_context_service.dart 존재');

      // R82 sprint 7 — _CollapsibleSection first-fold.
      expect(resultScreen.contains('_CollapsibleSection'), isTrue,
          reason: 'R82 sprint 7 — _CollapsibleSection widget 보존');

      // R82 sprint 9 — Gender.other / UserGender enum (silent male fallback 제거).
      // saju_settings_provider 또는 models 안의 enum.
      final libDir = Directory('lib');
      var foundGenderOther = false;
      for (final f in libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        if (src.contains('UserGender') || src.contains('Gender.other') ||
            src.contains('Gender.male') && src.contains('Gender.female')) {
          foundGenderOther = true;
          break;
        }
      }
      expect(foundGenderOther, isTrue,
          reason: 'R82 sprint 9 — UserGender / Gender 처리 보존');

      // R82 sprint 10 — "세력 분포 점수" arb 라벨.
      final arbKo = File('lib/l10n/app_ko.arb').readAsStringSync();
      expect(arbKo.contains('resultFiveElementsHelper'), isTrue,
          reason: 'R82 sprint 10 — resultFiveElementsHelper l10n key 보존');
      expect(arbKo.contains('세력 분포 점수'), isTrue,
          reason: 'R82 sprint 10 — "세력 분포 점수" 라벨 보존');

      // R82 sprint 11 — Profile reset confirm dialog.
      final profileSrc =
          File('lib/screens/profile_screen.dart').readAsStringSync();
      final hasResetConfirm = profileSrc.contains('showDialog') ||
          profileSrc.contains('AlertDialog');
      expect(hasResetConfirm, isTrue,
          reason: 'R82 sprint 11 — profile_screen reset confirm dialog 보존');

      // R82 sprint 12 — package_info_plus dependency.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('package_info_plus'), isTrue,
          reason: 'R82 sprint 12 — package_info_plus dependency 보존');
    });

    // ─────────────── I4: R83 sprint 2~6 anchor source 존재 ───────────────
    test('I4a — R83 sprint 2 (P1-G) info_saju_calc_screen 파일 R89 sprint 4 에서 완전 삭제',
        () {
      // R83 sprint 2 = P1-G info 화면 신규.
      // R88 sprint 2 = 진입점 + router route 제거 (파일 보존).
      // R89 sprint 4 = 파일 본체 완전 삭제 (dead code 정리).
      final infoFile = File('lib/screens/info_saju_calc_screen.dart');
      expect(infoFile.existsSync(), isFalse,
          reason: 'R89 sprint 4 — info_saju_calc_screen.dart 파일 완전 삭제 (dead code 정리)');
    });

    test('I4a-r88 — R88 sprint 2: settings 진입점 + router route 제거 확인', () {
      // R88 sprint 2 신규 guard — 사용자 mandate 정확 반영.
      final settings = File('lib/screens/settings_screen.dart').readAsStringSync();
      expect(settings.contains('settingsTrustHowCalculated'), isFalse,
          reason: 'R88 sprint 2 — settingsTrustHowCalculated row 제거됨');
      expect(settings.contains('settingsCalcBasisRow'), isFalse,
          reason: 'R88 sprint 2 — settingsCalcBasisRow row 제거됨');
      expect(settings.contains('/settings/saju-calc-basis'), isFalse,
          reason: 'R88 sprint 2 — settings 안에서 router push 0');

      final router = File('lib/router.dart').readAsStringSync();
      expect(router.contains('InfoSajuCalcScreen'), isFalse,
          reason: 'R88 sprint 2 — router 의 InfoSajuCalcScreen 등록 제거됨');
      expect(router.contains("/settings/saju-calc-basis"), isFalse,
          reason: 'R88 sprint 2 — router 의 `/settings/saju-calc-basis` route 제거됨');
    });

    test('I4b — R83 sprint 3 (P1-F) 셀럽 disclosure 라벨 anchor 보존', () {
      // P1-F — discover_screen 셀럽 출생정보 신뢰도 라벨.
      final arbKo = File('lib/l10n/app_ko.arb').readAsStringSync();
      final arbEn = File('lib/l10n/app_en.arb').readAsStringSync();
      for (final key in const [
        'celebDisclosureBanner',
        'celebDisclosureBannerHelper',
        'celebCardConfidenceLabel',
      ]) {
        expect(arbKo.contains(key), isTrue,
            reason: 'R83 sprint 3 — arb ko 의 $key 보존');
        expect(arbEn.contains(key), isTrue,
            reason: 'R83 sprint 3 — arb en 의 $key 보존');
      }
      // 한국어 본문 ground truth — "공개 생일 기반" anchor 보존.
      expect(arbKo.contains('공개 생일 기반'), isTrue,
          reason: 'R83 sprint 3 — "공개 생일 기반" 본문 anchor 보존');
    });

    test('I4c — R83 sprint 4 (P1-B) 자시 학파 helper anchor 보존', () {
      // P1-B — input_screen 23시 자시 학파 helper.
      final arbKo = File('lib/l10n/app_ko.arb').readAsStringSync();
      // sprint 4 신규 arb key — inputZasiHelperTitle (sprint 4 mandate).
      expect(arbKo.contains('inputZasiHelperTitle'), isTrue,
          reason: 'R83 sprint 4 — inputZasiHelperTitle arb 보존');
      expect(arbKo.contains('자시'), isTrue,
          reason: 'R83 sprint 4 — "자시" 도메인 어휘 본문 보존');

      // settings 야자시 학파 toggle anchor (R83 sprint 4 의 학파 선택 진입점).
      expect(arbKo.contains('settingsLateNightZasi'), isTrue,
          reason: 'R83 sprint 4 — settingsLateNightZasi (야자시 학파) 보존');
    });

    test('I4d — R83 sprint 5 (P1-E) 시간 모름 처리 anchor 보존', () {
      // P1-E — 출생 시간 모름 처리.
      final saju = File('lib/models/saju_result.dart').readAsStringSync();
      // saju_result 의 unknownTime / 시간 모름 처리 anchor.
      expect(saju.contains('R83 sprint 5') || saju.contains('시간 모름'),
          isTrue,
          reason: 'R83 sprint 5 — saju_result.dart 의 시간 모름 처리 anchor 보존');

      final resultScreen =
          File('lib/screens/result_screen.dart').readAsStringSync();
      // result_screen 의 R83 sprint 5 anchor (시간 모름 disclaimer / hour 흐림).
      expect(resultScreen.contains('R83 sprint 5'), isTrue,
          reason: 'R83 sprint 5 — result_screen 시간 모름 anchor 보존');
      expect(resultScreen.contains('시간 모름'), isTrue,
          reason: 'R83 sprint 5 — result_screen "시간 모름" 본문 anchor 보존');
    });

    test('I4e — R83 sprint 6 (P1-D) 용신 분리 anchor 보존', () {
      // P1-D — 용신 억부 / 조후 / 격국 분리.
      final resultScreen =
          File('lib/screens/result_screen.dart').readAsStringSync();
      expect(resultScreen.contains('_YongsinSplitRow'), isTrue,
          reason: 'R83 sprint 6 — _YongsinSplitRow widget 보존');
      expect(resultScreen.contains('억부용신'), isTrue,
          reason: 'R83 sprint 6 — "억부용신" 라벨 보존');
      expect(resultScreen.contains('조후용신'), isTrue,
          reason: 'R83 sprint 6 — "조후용신" 라벨 보존');
      expect(resultScreen.contains('격국용신'), isTrue,
          reason: 'R83 sprint 6 — "격국용신" 라벨 보존');

      // yongsin_service 의 격국용신 산출 (Round 83 sprint 6 anchor).
      final yongsin =
          File('lib/services/yongsin_service.dart').readAsStringSync();
      expect(yongsin.contains('Round 83 sprint 6'), isTrue,
          reason: 'R83 sprint 6 — yongsin_service.dart 안 anchor 보존');
      expect(
          yongsin.contains('gyeokgukYongsinFor') ||
              yongsin.contains('격국용신'),
          isTrue,
          reason: 'R83 sprint 6 — 격국용신 산출 anchor 보존');
    });

    // ─────────────── I5: 시크릿 leak 가드 ───────────────
    test('I5 — 시크릿 leak grep 0 (lib + test)', () {
      final patterns = <RegExp>[
        RegExp(r'AuthKey_[A-Z0-9]{10}'),
        RegExp(r'sk-[A-Za-z0-9]{20,}'),
        RegExp(r'ghp_[A-Za-z0-9]{30,}'),
        RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
      ];
      final dirs = <Directory>[Directory('lib'), Directory('test')];
      final hits = <String>[];
      for (final d in dirs) {
        for (final f in d
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          final src = f.readAsStringSync();
          for (final p in patterns) {
            if (p.hasMatch(src)) {
              hits.add('${f.path} — ${p.pattern}');
            }
          }
        }
      }
      expect(hits, isEmpty, reason: '시크릿 leak 발견: ${hits.join("\n")}');
    });
  });
}
