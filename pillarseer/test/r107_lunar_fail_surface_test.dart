// R107 — 음력 변환 실패 surface 검증.
//
// 문제: ManseryeokService.calculate 가 음력→양력 변환 실패 시
// lunarConversionFailed=true 를 반환하지만, 직전까지 SajuService.calculateSaju
// 가 이 flag 를 SajuResult 로 전달하지 않아 사용자가 변환 실패를 알 수 없었다.
//
// 본 테스트는:
//  1. 음력 변환 실패 케이스 → SajuResult.lunarConversionFailed == true
//  2. 정상 음력 입력 → SajuResult.lunarConversionFailed == false
//  3. 정상 양력 입력 → SajuResult.lunarConversionFailed == false
//  4. 5행 골든 (1995-10-27 男 17시 辛卯 16/21/17/41/4) 1 bit 불변
//  5. SajuResult 기본 생성자의 lunarConversionFailed 기본값 false

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  final svc = SajuService();

  group('R107 — 음력 변환 실패 flag surface', () {
    test('음력 변환 실패 (klc 범위 밖 연도) → lunarConversionFailed==true', () async {
      // klc 음양력 변환 범위는 1391~2050. 그 밖의 연도는 변환 불가.
      final r = await svc.calculateSaju(
        year: 1000, month: 5, day: 15,
        hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isTrue,
          reason: '범위 밖 음력 연도는 변환 실패로 surface 되어야 함');
    });

    test('음력 변환 실패 (없는 음력 월) → lunarConversionFailed==true', () async {
      final r = await svc.calculateSaju(
        year: 1995, month: 13, day: 1,
        hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isTrue,
          reason: '13월 같은 잘못된 음력 월은 변환 실패로 surface 되어야 함');
    });

    test('음력 변환 실패 (없는 음력 일) → lunarConversionFailed==true', () async {
      final r = await svc.calculateSaju(
        year: 1995, month: 2, day: 31,
        hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isTrue,
          reason: '2월 31일 같은 잘못된 음력 일은 변환 실패로 surface 되어야 함');
    });

    test('정상 음력 입력 → lunarConversionFailed==false', () async {
      final r = await svc.calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isFalse,
          reason: '유효한 음력 날짜는 정상 변환 — flag false');
    });

    test('정상 양력 입력 → lunarConversionFailed==false', () async {
      final r = await svc.calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      expect(r.lunarConversionFailed, isFalse,
          reason: '양력 입력은 음력 변환을 거치지 않음 — flag 항상 false');
    });

    test('SajuResult 기본 생성자 — lunarConversionFailed 기본값 false', () {
      final dummy = SajuResult.dummy();
      expect(dummy.lunarConversionFailed, isFalse,
          reason: 'flag 미지정 시 기본 false — 기존 호출자 회귀 0');
    });
  });

  group('R107 — 회귀 가드: 5행 골든 불변', () {
    test('1995-10-27 男 17:00 양력 → 辛卯 16/21/17/41/4 절대 보존', () async {
      final saju = await svc.calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      // R75~R107 골든 — flag 추가가 계산 출력을 1 bit 도 안 바꿈을 보장.
      expect(saju.dayPillar.text, '辛卯', reason: '골든 일주 辛卯');
      expect(saju.elements.wood, 16, reason: '골든 wood');
      expect(saju.elements.fire, 21, reason: '골든 fire');
      expect(saju.elements.earth, 17, reason: '골든 earth');
      expect(saju.elements.metal, 41, reason: '골든 metal');
      expect(saju.elements.water, 4, reason: '골든 water');
      expect(saju.lunarConversionFailed, isFalse,
          reason: '골든 양력 입력 — flag false');
    });

    test('변환 실패 케이스라도 4기둥·5행 출력 자체는 깨지지 않음', () async {
      // 변환 실패 시 입력값을 양력으로 fallback 계산 — 앱이 죽지 않아야 함.
      final r = await svc.calculateSaju(
        year: 1995, month: 13, day: 1,
        hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isTrue);
      expect(r.dayPillar.text.length, 2, reason: '일주 4기둥 정상 산출');
      final sum = r.elements.wood +
          r.elements.fire +
          r.elements.earth +
          r.elements.metal +
          r.elements.water;
      expect(sum, greaterThan(0), reason: '5행 분포 정상 산출');
    });
  });
}
