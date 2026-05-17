// R89 sprint 4 회귀 가드 — info_saju_calc_screen.dart dead code 완전 삭제 검증.
//
// 사용자 스토리:
//   사용자가 router 의 모든 entry 를 순회해도 InfoSajuCalcScreen 진입 불가능.
//   binary 에서 해당 widget 코드 완전 제거.
//
// 검증:
//   B1 — lib/screens/info_saju_calc_screen.dart 파일 미존재
//   B2 — lib/ 전체 어디서도 InfoSajuCalcScreen 사용 안 함 (import 0 / class 등록 0)
//   B3 — l10n key infoCalcBasis* 미사용 (l10n arb 잔존은 별도 R88 sprint 2 baseline)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R89 sprint 4 — info_saju_calc dead code 완전 삭제', () {
    test('B1 — info_saju_calc_screen.dart 파일 완전 삭제', () {
      final file = File('lib/screens/info_saju_calc_screen.dart');
      expect(file.existsSync(), isFalse,
          reason: 'R89 sprint 4 mandate — 파일 삭제');
    });

    test('B2 — lib/ 전체에서 InfoSajuCalcScreen 0 hit', () {
      final libDir = Directory('lib');
      final dartFiles = <File>[];
      void walk(Directory d) {
        for (final entity in d.listSync()) {
          if (entity is File && entity.path.endsWith('.dart')) {
            dartFiles.add(entity);
          } else if (entity is Directory) {
            walk(entity);
          }
        }
      }
      walk(libDir);

      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        expect(src.contains('InfoSajuCalcScreen'), isFalse,
            reason: '${f.path} 에 InfoSajuCalcScreen 잔존');
        expect(src.contains('info_saju_calc_screen.dart'), isFalse,
            reason: '${f.path} 에 info_saju_calc_screen.dart import 잔존');
      }
    });

    test('B3 — router 의 /settings/saju-calc-basis route 0 hit', () {
      final routerSrc = File('lib/router.dart').readAsStringSync();
      expect(routerSrc.contains('/settings/saju-calc-basis'), isFalse,
          reason: 'router route 0 hit (R88 sprint 2 + R89 sprint 4 누적)');
    });
  });
}
