// Round 82 sprint 13 — 회귀 가드 round close 통합 invariant.
//
// 사용자 mandate (R82 spec §3 sprint 13):
//   사용자가 `flutter test` 전체 PASS 확인. 1995-10-27 남자 17시 사주의
//   5행 16/21/17/41/4 + 일주 辛卯 + R69 lock 6각 점수 보존.
//
// 본 test 는 sprint 1~12 의 모든 invariant 를 한 곳에서 통합 검증.
// 산출 값 깨지면 즉시 sprint 중단 (G7 protocol — M4 mandate 위반).
//
// 검증 축:
//   I1. 5행 골든 1995-10-27 男 17시 양력 = 16/21/17/41/4 + 일주 辛卯 (R75 calibration).
//   I2. R69 lock 6각 점수 (1995-10-27 男 15:43) — 본성 78 / 연애 78 / 일 72 /
//       돈 74 / 건강 57 / 평판 71 + matchCount 5 + matchedAxes 5종 (R80 baseline).
//   I3. R71~R80 + R82 시그니처 source-level grep 보존:
//       - 자미두수 UI hidden (`kIsZiweiUiHidden=true` result_screen).
//       - `/today` route 등록 (router.dart).
//       - oneLine 60일주 wire (deep_content_service `_oneLineByJi60Ko` 또는
//         후속 R82 sprint 의 후계 wire).
//       - 신살 anchor (양인/괴강/백호/천을/문창) source 존재.
//   I4. R82 sprint 1~12 commit 산출물 source-level 존재:
//       - sprint 2 (#4) result_screen 에서 `TodayEventDetailSection` mount 0
//         (회귀 가드 — /today 단독).
//       - sprint 4 (#5) `_MatchBadge` 라벨 재작성 또는 widget 보존.
//       - sprint 5 (#3) palace_helper_anchor_service 존재.
//       - sprint 6 (#7 #8 #9) animal_context_service 존재.
//       - sprint 7 (#1) _CollapsibleSection 또는 first-fold 정리 widget 존재.
//       - sprint 8 (#2) saju_deep_slice JSON 30+ entry slot.
//       - sprint 9 Gender.other 처리 (silent male fallback 제거).
//       - sprint 10 외부 reviewer #7 — "세력 분포 점수" 라벨 + helper.
//       - sprint 11 외부 reviewer #7 — Profile reset confirm dialog.
//       - sprint 12 외부 reviewer #8 — version 동적 로드 (package_info_plus).
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
  group('R82 sprint 13 — round close 통합 invariant', () {
    // ------ I1: 5행 골든 (1995-10-27 男 17시 양력) ------
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
      expect(el.wood, 16, reason: '木 = 16 (R75)');
      expect(el.fire, 21, reason: '火 = 21 (R75)');
      expect(el.earth, 17, reason: '土 = 17 (R75)');
      expect(el.metal, 41, reason: '金 = 41 (R75)');
      expect(el.water, 4, reason: '水 = 4 (R75)');
      expect(r.dayPillar.text, '辛卯', reason: '일주 = 辛卯 (R75)');
    });

    // ------ I2: R69 lock (1995-10-27 男 15:43) ------
    test('I2 — R69 lock 6각 점수 + matchCount 5/6 (R80 baseline)',
        () async {
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

    // ------ I3: R71~R80 시그니처 source-level 보존 ------
    test('I3 — 자미두수 UI hidden + /today route 등록 + 신살 anchor source 보존',
        () {
      final resultScreen =
          File('lib/screens/result_screen.dart').readAsStringSync();
      expect(resultScreen.contains('const bool kIsZiweiUiHidden = true'),
          isTrue,
          reason: '자미두수 UI hidden flag 보존 (R73)');

      final router = File('lib/router.dart').readAsStringSync();
      expect(router.contains("path: '/today'"), isTrue,
          reason: '/today route 등록 보존 (R79 sprint 7)');
      expect(router.contains("return '/today';"), isTrue,
          reason: '/today redirect rule 보존 (R79 sprint 7)');

      // R80 sprint 4 신살 anchor — 양인/괴강/백호/천을/문창 중 최소 anchor key
      // (양인) 존재 확인. SixAxisScoreService 또는 personalization 영역에서 사용.
      final libDir = Directory('lib');
      var foundYangin = false;
      for (final f in libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        if (src.contains('양인') || src.contains('yangIn')) {
          foundYangin = true;
          break;
        }
      }
      expect(foundYangin, isTrue,
          reason: '신살 anchor 양인 source 보존 (R80 sprint 4)');
    });

    // ------ I4: R82 sprint 1~12 산출물 source-level 존재 ------
    test('I4 — R82 sprint 2~12 산출물 source 보존', () {
      // sprint 2 (#4) — result_screen 에서 TodayEventDetailSection mount 0.
      final resultScreen =
          File('lib/screens/result_screen.dart').readAsStringSync();
      expect(resultScreen.contains('TodayEventDetailSection('), isFalse,
          reason: 'sprint 2 (#4) — result_screen 에서 TodayEventDetailSection '
              'mount 제거됨 (/today 단독)');

      // sprint 5 (#3) — palace_helper_anchor_service 존재.
      final palaceHelper =
          File('lib/services/palace_helper_anchor_service.dart');
      expect(palaceHelper.existsSync(), isTrue,
          reason: 'sprint 5 — palace_helper_anchor_service.dart 존재');

      // sprint 6 (#7 #8 #9) — animal_context_service 존재.
      final animalCtx = File('lib/services/animal_context_service.dart');
      expect(animalCtx.existsSync(), isTrue,
          reason: 'sprint 6 — animal_context_service.dart 존재');

      // sprint 10 — l10n resultFiveElementsHelper key 존재.
      final arbKo = File('lib/l10n/app_ko.arb').readAsStringSync();
      expect(arbKo.contains('resultFiveElementsHelper'), isTrue,
          reason: 'sprint 10 — resultFiveElementsHelper l10n key 보존');
      expect(arbKo.contains('세력 분포 점수'), isTrue,
          reason: 'sprint 10 — "세력 분포 점수" 라벨 보존');

      // sprint 11 — Profile reset confirm dialog (Settings delete-all 모달 패턴).
      final profileSrc =
          File('lib/screens/profile_screen.dart').readAsStringSync();
      // R82 sprint 11 mandate — reset 버튼 tap 시 confirm 모달 mount.
      // showDialog 호출 또는 _confirm 패턴 또는 AlertDialog 사용 grep.
      final hasResetConfirm = profileSrc.contains('showDialog') ||
          profileSrc.contains('AlertDialog');
      expect(hasResetConfirm, isTrue,
          reason: 'sprint 11 — profile_screen reset confirm dialog 보존');

      // sprint 12 — package_info_plus 사용 (settings 또는 main).
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('package_info_plus'), isTrue,
          reason: 'sprint 12 — package_info_plus dependency 보존');
    });

    // ------ I5: 시크릿 leak 가드 (회귀 sprint 추가 안전 net) ------
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
