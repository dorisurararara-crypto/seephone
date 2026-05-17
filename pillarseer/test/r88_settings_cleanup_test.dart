// R88 sprint 2 회귀 가드 — 설정 탭 항목 2 개 제거.
//
// 사용자 mandate (R88 spec sprint 2 verbatim):
//   "사용자가 설정 탭에 들어가면 '이 풀이는 어떻게 계산되나요' / '사주 계산 기준 안내'
//   두 항목이 보이지 않는다. 다른 설정 항목(알림 / 테마 / 폰트 등)은 모두 그대로 있다."
//
// 검증:
//   B1 — settings_screen 안에서 두 l10n key 참조 0 + router push 호출 0
//   B2 — router 의 `/settings/saju-calc-basis` route + InfoSajuCalcScreen import 0
//   B3 — info_saju_calc_screen.dart 파일은 dead code 로 보존 (sprint 10 까지 유지)
//   B4 — 다른 설정 항목 변경 0 (_NotifSwitch / _NotifTimePicker / _NotifToneToggle /
//        _TrueSunSwitch / _LateNightZasiSwitch / _LinkRow / 약관 / 개인정보 / 연락 보존)
//   B5 — settingsTrust 그룹 안 _InfoRow 가 3 개 (Data / Offline / DeleteAll) 로 남음

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R88 sprint 2 — 설정 탭 항목 2 개 제거', () {
    final settings =
        File('lib/screens/settings_screen.dart').readAsStringSync();
    final router = File('lib/router.dart').readAsStringSync();

    test('B1 — settings_screen 에서 두 l10n key 참조 0 + router push 0', () {
      expect(settings.contains('settingsTrustHowCalculated'), isFalse,
          reason: '"이 풀이는 어떻게 계산되나요" row 제거됨');
      expect(settings.contains('settingsTrustHowCalculatedDesc'), isFalse,
          reason: 'settingsTrustHowCalculatedDesc 참조 제거됨');
      expect(settings.contains('settingsCalcBasisRow'), isFalse,
          reason: '"사주 계산 기준 안내" row 제거됨');
      expect(settings.contains('settingsCalcBasisRowDesc'), isFalse,
          reason: 'settingsCalcBasisRowDesc 참조 제거됨');
      expect(settings.contains('/settings/saju-calc-basis'), isFalse,
          reason: 'settings 안 router push 호출 제거됨');
    });

    test('B2 — router 의 `/settings/saju-calc-basis` route + import 제거', () {
      expect(router.contains('info_saju_calc_screen.dart'), isFalse,
          reason: 'router import 제거됨');
      expect(router.contains('InfoSajuCalcScreen'), isFalse,
          reason: 'router builder 의 InfoSajuCalcScreen 등록 제거됨');
      expect(router.contains('/settings/saju-calc-basis'), isFalse,
          reason: 'router 의 route path 제거됨');
    });

    test('B3 — info_saju_calc_screen.dart 파일 완전 삭제 (R89 sprint 4 mandate)', () {
      // R88 sprint 2 = router 만 제거, 파일 보존.
      // R89 sprint 4 = 파일 본체 dead code 정리 — 완전 삭제.
      final infoFile = File('lib/screens/info_saju_calc_screen.dart');
      expect(infoFile.existsSync(), isFalse,
          reason: 'R89 sprint 4 — info_saju_calc_screen.dart 파일 완전 삭제');
    });

    test('B4 — 다른 설정 항목 변경 0', () {
      // 알림 그룹 (_NotifSwitch / _NotifTimePicker / _NotifToneToggle).
      for (final widget in const [
        '_NotifSwitch',
        '_NotifTimePicker',
        '_NotifToneToggle',
      ]) {
        expect(settings.contains(widget), isTrue, reason: '$widget 보존');
      }
      // 사주 옵션 그룹 (R83 P1-B 자시 / 진태양시 switch).
      for (final widget in const [
        '_TrueSunSwitch',
        '_LateNightZasiSwitch',
      ]) {
        expect(settings.contains(widget), isTrue, reason: '$widget 보존');
      }
      // about 그룹 약관/개인정보/연락 l10n key.
      for (final key in const [
        'settingsPrivacy',
        'settingsTerms',
        'settingsContact',
        'settingsVersion',
      ]) {
        expect(settings.contains(key), isTrue, reason: '$key l10n key 보존');
      }
      // settingsTrust 그룹 안 다른 row 보존 (Data / Offline / DeleteAll).
      for (final key in const [
        'settingsTrustDataLocal',
        'settingsTrustOffline',
        'settingsTrustDeleteAll',
      ]) {
        expect(settings.contains(key), isTrue, reason: '$key l10n key 보존');
      }
    });

    test('B5 — settingsTrust 그룹 안 _InfoRow 가 3 개 (Data / Offline / DeleteAll) 만 남음',
        () {
      // settingsTrust group 시작 (`label: l.settingsTrust`) ~ 다음 group 시작 사이.
      final start = settings.indexOf('label: l.settingsTrust');
      expect(start, greaterThan(-1), reason: 'settingsTrust 그룹 시작 미발견');
      // 다음 `_SettingsGroup(label: ` 또는 group close 까지 슬라이스.
      var end = settings.indexOf('_SettingsGroup(label:', start + 10);
      if (end == -1) end = settings.length;
      final slice = settings.substring(start, end);
      // _InfoRow 호출 횟수 = 3.
      final infoRowMatches = '_InfoRow('.allMatches(slice).length;
      expect(infoRowMatches, equals(3),
          reason: 'settingsTrust 그룹의 _InfoRow 가 3 개 (DataLocal / Offline / DeleteAll)');
    });

    test('B6 — round83_info_saju_calc_test.dart 폐기 (R83 sprint 2 P1-G 진입점이 R88 spec 에서 사라짐)',
        () {
      final old = File('test/round83_info_saju_calc_test.dart');
      expect(old.existsSync(), isFalse,
          reason: 'R83 widget test 가 R88 spec sprint 10 baseline 재설정에 따라 폐기');
    });
  });
}
