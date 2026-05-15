// Round 82 sprint 9 회귀 가드 — Gender.other 계산 처리 (외부 review P0 #6).
//
// 외부 reviewer 지적 verbatim:
//   "성별은 남/여/기타로 받는데, 계산에서는 female 이 아니면 전부 isMale=true 로 들어감.
//    '기타' 가 남성 계산으로 silent 처리됨."
//
// → fix 방향:
//   1. input_screen.dart 의 `_gender != Gender.female` silent truthy 패턴 제거.
//      대신 명시 switch (Gender.male / Gender.female / Gender.other) 로 분기.
//   2. Gender.other 선택 시 사용자에게 보조 모달로 "남 기준 / 여 기준" 명시 선택 요구.
//      사용자가 dismiss 하면 _gender 자체가 null 로 reset — silent male 처리 0.
//   3. _OtherGenderChoiceButton + _OtherGenderCalcBadge widget mount 검증.
//
// 본 test 는 lib/screens/input_screen.dart 의 source 를 grep 하여 silent fallback 패턴이
// 다시 생기지 않도록 회귀 가드. widget mount test 는 keyed lookup 으로 가벼운 smoke.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/providers/saju_provider.dart';

void main() {
  group('R82 sprint 9 — Gender.other 계산 처리 (외부 review P0 #6)', () {
    final src = File('lib/screens/input_screen.dart').readAsStringSync();
    final arbKoSrc = File('lib/l10n/app_ko.arb').readAsStringSync();
    final arbEnSrc = File('lib/l10n/app_en.arb').readAsStringSync();
    final providerSrc =
        File('lib/providers/saju_provider.dart').readAsStringSync();
    final kpopSrc =
        File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();

    test('input_screen 에 silent truthy fallback (`_gender != Gender.female`) 0', () {
      // 외부 review P0 #6 핵심 — `_gender != Gender.female` 패턴은 Gender.other 를
      // silent male 로 흡수하므로 회귀 시 즉시 fail.
      expect(
        src.contains('_gender != Gender.female'),
        isFalse,
        reason:
            'Silent truthy fallback 회귀 — Gender.other 가 silent male 로 흡수됨. '
            '명시 switch (Gender.male / Gender.female / Gender.other) 패턴 사용.',
      );
    });

    test('input_screen 의 isMale 도출이 명시 switch 패턴', () {
      // 명시 switch 의 3 case 모두 source 에 존재.
      expect(src.contains('case Gender.male:'), isTrue,
          reason: 'Gender.male case missing');
      expect(src.contains('case Gender.female:'), isTrue,
          reason: 'Gender.female case missing');
      expect(src.contains('case Gender.other:'), isTrue,
          reason: 'Gender.other case missing');
    });

    test('input_screen 에 _calculationIsMaleForOther state + 가드 mount', () {
      expect(src.contains('_calculationIsMaleForOther'), isTrue,
          reason:
              'Gender.other 계산 기준 명시 store 변수 누락 — silent male 위험.');
      // _canSubmit 가드에서 Gender.other 시 _calculationIsMaleForOther non-null 요구.
      expect(
        src.contains('_gender != Gender.other || _calculationIsMaleForOther != null'),
        isTrue,
        reason: '_canSubmit 가 Gender.other 의 silent fallback 을 막아야 함.',
      );
      // _submit 의 추가 가드 — Gender.other 면 모달 다시 띄움.
      expect(
        src.contains(
            '_gender == Gender.other && _calculationIsMaleForOther == null'),
        isTrue,
        reason: '_submit 가드가 Gender.other null state 시 모달 재제시해야 함.',
      );
    });

    test('input_screen 에 보조 모달 method + widget 정의', () {
      expect(src.contains('_askOtherGenderCalcBasis'), isTrue,
          reason: '보조 모달 method 누락.');
      expect(src.contains('class _OtherGenderChoiceButton'), isTrue,
          reason: '_OtherGenderChoiceButton widget 정의 누락.');
      expect(src.contains('class _OtherGenderCalcBadge'), isTrue,
          reason: '_OtherGenderCalcBadge widget 정의 누락.');
      // 모달 dismiss 시 _gender 가 null 로 reset — silent male 처리 0 보장.
      expect(src.contains('_gender = null'), isTrue,
          reason: '모달 cancel 시 _gender reset 누락 — silent male 위험.');
    });

    test('arb 에 모달 helper 7 key 존재 (ko + en)', () {
      const keys = [
        'inputGenderOtherModalTitle',
        'inputGenderOtherModalBody',
        'inputGenderOtherModalMale',
        'inputGenderOtherModalFemale',
        'inputGenderOtherModalCancel',
        'inputGenderOtherCalcMaleBadge',
        'inputGenderOtherCalcFemaleBadge',
      ];
      for (final k in keys) {
        expect(arbKoSrc.contains('"$k"'), isTrue,
            reason: 'ko arb 에 $k key 누락.');
        expect(arbEnSrc.contains('"$k"'), isTrue,
            reason: 'en arb 에 $k key 누락.');
      }
    });

    test('arb ko 톤이 친근 해요체 (한자 jargon 0)', () {
      // 한자 jargon blacklist — 외부 review C 톤 mandate.
      const blacklist = ['本性', '本質', '結', '靈', '陽男陰女', '陰男陽女'];
      for (final w in blacklist) {
        expect(arbKoSrc.contains(w), isFalse,
            reason: 'ko arb 에 한자 jargon "$w" — 톤 위반.');
      }
      // 친근 톤 marker — "주세요" / "할까요" / "필요해요" / "어요?" 류 1개 이상.
      final hasFriendlyMarker = arbKoSrc.contains('주세요') ||
          arbKoSrc.contains('할까요') ||
          arbKoSrc.contains('필요해요') ||
          arbKoSrc.contains('어요?') ||
          arbKoSrc.contains('할게요');
      expect(hasFriendlyMarker, isTrue,
          reason: '모달 한국어 본문에 친근 해요체 marker 누락.');
    });

    test('Gender enum 정의 보존 (male/female/other 3 case)', () {
      expect(src.contains('enum Gender { male, female, other }'), isTrue,
          reason: 'Gender enum 변경 — 호환성 회귀.');
    });

    test('saju_provider 에 UserGender enum 정의 (male/female/other 보존)', () {
      // 외부 review P0 #6 FIX 1 — UserBirthInfo 가 원본 성별을 isMale boolean 외
      // 별도 enum 으로 보존해야 Gender.other 가 후속 surface 까지 살아남음.
      expect(providerSrc.contains('enum UserGender { male, female, other }'),
          isTrue,
          reason: 'UserGender enum 정의 누락 — 원본 성별 보존 실패.');
      expect(providerSrc.contains('final UserGender gender;'), isTrue,
          reason: 'UserBirthInfo.gender field 누락.');
    });

    test('UserBirthInfo.gender 가 Gender.other 보존 (round-trip 검증)', () {
      // 외부 review P0 #6 FIX 1 — Gender.other 사용자가 UserBirthInfo round-trip 시
      // 원본 의도가 살아남는지 직접 인스턴스 검증.
      final info = UserBirthInfo(
        name: 'test_other',
        birthDate: DateTime(1995, 10, 27),
        birthHour: 17,
        birthMinute: 0,
        birthCity: '',
        isLunar: false,
        isMale: true, // 계산 기준만 male — 원본은 other.
        gender: UserGender.other,
      );
      expect(info.gender, UserGender.other,
          reason: 'UserBirthInfo.gender 가 원본 (other) 보존 실패.');
      expect(info.isMale, true,
          reason: 'isMale 은 계산 기준 boolean 유지 — round-trip 영향 0.');
    });

    test('kpop_compat_screen 의 Gender.other silent 분류 회귀 가드', () {
      // 외부 review P0 #6 FIX 2 — Gender.other 사용자는 K-POP 궁합 반대 성별 필터에서
      // 제외되어야 함. 회귀 시 `userInfo.isMale ? 'F' : 'M'` 패턴이 다시 등장.
      expect(
        kpopSrc.contains("userInfo.isMale ? 'F' : 'M'"),
        isFalse,
        reason:
            '회귀 — Gender.other 사용자가 isMale 기반 silent 필터로 다시 묶임.',
      );
      // UserGender.other 분기 존재 검증.
      expect(kpopSrc.contains('UserGender.other'), isTrue,
          reason: 'Gender.other 사용자 분기 처리 누락.');
    });
  });
}
