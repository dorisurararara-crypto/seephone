// 다음 빌드 신뢰도용 critical 회귀.
// 명리학 services 통합 + Service 간 일관성 + edge cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/gong_mang_service.dart';
import 'package:pillarseer/services/shinsa_service.dart';
import 'package:pillarseer/services/strength_service.dart';
import 'package:pillarseer/services/hapchung_service.dart';
import 'package:pillarseer/services/twelve_unsung_service.dart';
import 'package:pillarseer/services/manseryeok_service.dart';

void main() {
  group('Service 간 일관성 — 같은 사주 다중 호출 같은 결과', () {
    test('두 번 호출 시 결과 동일 (deterministic)', () async {
      final svc = SajuService();
      final r1 = await svc.calculateSaju(
        year: 1993, month: 5, day: 16,
        hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      final r2 = await svc.calculateSaju(
        year: 1993, month: 5, day: 16,
        hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      expect(r1.yearPillar.text, r2.yearPillar.text);
      expect(r1.monthPillar.text, r2.monthPillar.text);
      expect(r1.dayPillar.text, r2.dayPillar.text);
    });
  });

  group('Edge case — 자정 출생', () {
    test('00:00 출생 — hour pillar 子', () async {
      final r = await SajuService().calculateSaju(
        year: 2000, month: 6, day: 15,
        hour: 0, minute: 0,
        isLunar: false, isMale: true,
      );
      expect(r.hourPillar, isNotNull);
      expect(r.hourPillar!.jiJi, '子');
    });

    test('23:30 출생 — 야자시 학파 OFF (default) → 다음날 일주', () async {
      final off = await SajuService().calculateSaju(
        year: 2000, month: 6, day: 15,
        hour: 23, minute: 30,
        isLunar: false, isMale: true,
        applyTrueSunTime: false,
      );
      final on = await SajuService().calculateSaju(
        year: 2000, month: 6, day: 15,
        hour: 23, minute: 30,
        isLunar: false, isMale: true,
        applyTrueSunTime: false,
        useLateNightZasi: true,
      );
      expect(off.dayPillar.text, isNot(equals(on.dayPillar.text)));
    });
  });

  group('Edge case — DST 적용일 출생', () {
    test('1988-08-15 14:30 — DST 적용 자동', () async {
      final r = await SajuService().calculateSaju(
        year: 1988, month: 8, day: 15,
        hour: 14, minute: 30,
        isLunar: false, isMale: true,
        applyTrueSunTime: false,
      );
      expect(r.hourPillar, isNotNull);
      // DST -1h 적용으로 13:30 처리됨. 13:30 = 未시.
      expect(r.hourPillar!.jiJi, '未');
    });
  });

  group('명리학 services — 빈 입력 graceful 처리', () {
    test('GongMangService.forDayPillar 빈 문자열 → empty', () {
      expect(GongMangService.forDayPillar(''), isEmpty);
    });
    test('ShinsaService.yokmaFor 잘못된 입력 → empty', () {
      expect(ShinsaService.yokmaFor(''), '');
      expect(ShinsaService.yokmaFor('X'), '');
    });
    test('TwelveUnsungService.stageIndex 잘못된 입력 → -1', () {
      expect(TwelveUnsungService.stageIndex('X', '子'), -1);
      expect(TwelveUnsungService.stageIndex('甲', 'X'), -1);
    });
    test('HapchungService.isCheonganHap 빈 입력 → false', () {
      expect(HapchungService.isCheonganHap('', '甲'), isFalse);
      expect(HapchungService.isCheonganHap('甲', ''), isFalse);
    });
  });

  group('도시 substring 매칭 — 다양한 입력 패턴', () {
    test('소문자/대문자/한국어/공백 → 모두 매칭', () {
      final dt = DateTime(2000, 6, 15);
      // 모두 서울로 매칭되어야.
      final variants = ['Seoul', 'seoul', 'SEOUL', '서울', '서울특별시', 'Seoul, Korea'];
      final base =
          ManseryeokService.trueSunOffsetForCityDate(dt, '서울');
      for (final v in variants) {
        expect(
          ManseryeokService.trueSunOffsetForCityDate(dt, v),
          equals(base),
          reason: '"$v" 가 서울 매칭 실패',
        );
      }
    });
  });

  group('1900-2050 전체 deterministic — 5년 단위 입춘', () {
    test('1900~2050, 5년 단위 → 모두 정상 calculation (no exceptions)', () async {
      final svc = SajuService();
      for (int y = 1900; y <= 2050; y += 5) {
        final r = await svc.calculateSaju(
          year: y, month: 6, day: 15,
          hour: 12, minute: 0,
          isLunar: false, isMale: true, unknownTime: true,
        );
        expect(r.dayPillar.text.length, 2, reason: '$y day pillar 형식 X');
        expect(r.yearPillar.text.length, 2);
      }
    });
  });

  group('명리학 강약 — 모든 일간 5종 grid 정상', () {
    test('5 일간 (甲丙戊庚壬) + 5 월령 (寅巳辰申子) = 25 combination 정상', () {
      const dms = ['木', '火', '土', '金', '水'];
      const jis = ['寅', '巳', '辰', '申', '子'];
      for (final dm in dms) {
        for (final ji in jis) {
          final r = StrengthService.judge(
            dayMasterElement: dm,
            monthJi: ji,
            wood: 20, fire: 20, earth: 20, metal: 20, water: 20,
          );
          expect(r.score, greaterThanOrEqualTo(0));
          expect(r.score, lessThanOrEqualTo(100));
          expect(r.label, isNotEmpty);
        }
      }
    });
  });
}
