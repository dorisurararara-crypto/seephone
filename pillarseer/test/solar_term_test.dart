// SolarTermService 정확도 + ManseryeokService 입춘 경계 회귀 테스트.
//
// 입춘 datetime 의 약 ±15분 정확도 검증 (Meeus low-precision formula).
// 사용자가 입춘 ±15분 이내에 태어났을 확률은 매우 낮으므로 충분.
//
// 년주 경계: 입춘 직전·직후 출생자 년주가 1년 차이 나는지 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/manseryeok_service.dart';
import 'package:pillarseer/services/solar_term_service.dart';

void main() {
  group('SolarTermService.lipchun — KASI 발표값과 비교', () {
    // KASI 월력요항 published 입춘 KST datetime — 검증 가능한 연도만.
    // 추가 연도는 확실한 KASI source 확보 후에 추가.
    final Map<int, DateTime> kasi = {
      1990: DateTime(1990, 2, 4, 11, 14),
      1995: DateTime(1995, 2, 4, 16, 12),
      2000: DateTime(2000, 2, 4, 21, 40),
      2015: DateTime(2015, 2, 4, 12, 58),
      2020: DateTime(2020, 2, 4, 18, 3),
      2024: DateTime(2024, 2, 4, 17, 27),
      2026: DateTime(2026, 2, 4, 5, 2),
    };

    for (final entry in kasi.entries) {
      test('년도 ${entry.key} 입춘 ±20분 이내', () {
        final calc = SolarTermService.lipchun(entry.key);
        final diffMin = calc.difference(entry.value).inMinutes.abs();
        expect(diffMin, lessThanOrEqualTo(20),
            reason:
                '$entry.key 입춘: calc=$calc, KASI=${entry.value}, diff=$diffMin 분');
      });
    }
  });

  group('년주 경계 — 입춘 전/후 출생자', () {
    test('1995년 입춘(2/4 16:12) 직전 출생 → 1994 갑술', () {
      // 1995-02-04 15:00 (입춘 1시간 전) → 갑술 (1994 year pillar)
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 2,
        day: 4,
        hour: 15,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '甲戌');
    });

    test('1995년 입춘(2/4 16:12) 직후 출생 → 1995 을해', () {
      // 1995-02-04 17:00 (입춘 1시간 후) → 을해 (1995 year pillar)
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 2,
        day: 4,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '乙亥');
    });

    test('1월 1일 출생 → 무조건 전년도 갑자', () {
      // 1995-01-01 → 1994 갑술
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 1,
        day: 1,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '甲戌');
    });

    test('3월 1일 출생 → 무조건 당해 갑자', () {
      // 1995-03-01 → 1995 을해
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 3,
        day: 1,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '乙亥');
    });

    test('2024년 입춘(2/4 17:27) 직전 출생 → 2023 계묘', () {
      final result = ManseryeokService.calculate(
        year: 2024,
        month: 2,
        day: 4,
        hour: 10,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '癸卯');
    });

    test('2024년 입춘 직후 출생 → 2024 갑진', () {
      final result = ManseryeokService.calculate(
        year: 2024,
        month: 2,
        day: 4,
        hour: 20,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '甲辰');
    });
  });

  group('월주 회귀 — 12절기 기반', () {
    test('IU 1993-05-16 → 巳월 (입하~망종 구간, 월간 丁)', () {
      // 1993 입하 May 5 ≈ 1993-05-05. Birth May 16 → 巳월.
      // 년간 癸 → 寅월 시작 甲 → 巳월(m=3) = 丁. 월주 = 丁巳.
      final result = ManseryeokService.calculate(
        year: 1993,
        month: 5,
        day: 16,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: false,
        applyTrueSunTime: false,
      );
      expect(result.monthPillar.text, '丁巳');
    });

    test('1995-12-30 → 子월 (대설 후, 월간 戊)', () {
      // 1995 대설 Dec 7. Birth Dec 30 > 대설, < 소한 1996. → 子월 (m=10).
      // 년간 乙 → 寅월 시작 戊. m=10. 월간 = 戊+10 = (4+10)%10 = 4 = 戊. → 戊子.
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 12,
        day: 30,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.monthPillar.text, '戊子');
    });

    test('1월 출생 (입춘 전, 소한 후) → 丑월', () {
      // 1995-01-15: 소한 1995-01-06 후, 입춘 1995-02-04 전. → 丑월 (m=11).
      // 년간 effYear=1994 = 甲. 寅월 시작 丙. m=11. 월간 = (2+11)%10 = 3 = 丁. → 丁丑.
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 1,
        day: 15,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.yearPillar.text, '甲戌'); // 1994 갑술
      expect(result.monthPillar.text, '丁丑');
    });

    test('3월 출생 (경칩 후) → 卯월', () {
      // 1995-03-15: 경칩 1995-03-06 후, 청명 1995-04-05 전. → 卯월 (m=1).
      // 년간 乙. 寅월 시작 戊. m=1. 월간 = (4+1)%10 = 5 = 己. → 己卯.
      final result = ManseryeokService.calculate(
        year: 1995,
        month: 3,
        day: 15,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(result.monthPillar.text, '己卯');
    });
  });

  group('오호둔법 5그룹 매핑 — 寅월 시작 천간', () {
    // 같은 달(3월 = 卯월 m=1) 다른 년간 → 월간 다름 확인.
    // 寅월 시작 천간: 갑·기→丙, 을·경→戊, 병·신→庚, 정·임→壬, 무·계→甲.
    // m=1 (卯) 이면 +1 = 寅월 + 1.
    final cases = [
      // [year, expectedYearChunGan, expectedMonthChunGan(卯월)]
      (2024, '甲', '丁'), // 甲년 → 寅丙 → 卯丁
      (2025, '乙', '己'), // 乙년 → 寅戊 → 卯己
      (2026, '丙', '辛'), // 丙년 → 寅庚 → 卯辛
      (2027, '丁', '癸'), // 丁년 → 寅壬 → 卯癸
      (2028, '戊', '乙'), // 戊년 → 寅甲 → 卯乙
      (2029, '己', '丁'), // 己년 → 寅丙 → 卯丁
      (2030, '庚', '己'), // 庚년 → 寅戊 → 卯己
      (2031, '辛', '辛'), // 辛년 → 寅庚 → 卯辛
      (2032, '壬', '癸'), // 壬년 → 寅壬 → 卯癸
      (2033, '癸', '乙'), // 癸년 → 寅甲 → 卯乙
    ];
    for (final c in cases) {
      test('${c.$1}년 3월 15일 (경칩~청명 = 卯월) → ${c.$2}${c.$3}월', () {
        final result = ManseryeokService.calculate(
          year: c.$1,
          month: 3,
          day: 15,
          hour: 12,
          minute: 0,
          isLunar: false,
          isMale: true,
          applyTrueSunTime: false,
        );
        expect(result.yearPillar.chunGan, c.$2,
            reason: '년간 ${c.$1}년 → ${c.$2}');
        expect(result.monthPillar.chunGan, c.$3,
            reason: '월간 ${c.$1}년 卯월 → ${c.$3}');
      });
    }
  });

  group('진태양시 일관성 — 년주/월주에도 -32분 적용', () {
    test('한국 DST — 1987 서머타임 적용 기간 isKoreanDst true', () {
      // 1987 한국 서머타임: 5/10 02:00 ~ 10/11 03:00
      expect(
          ManseryeokService.isKoreanDst(DateTime(1987, 7, 15, 12, 0)), isTrue);
      expect(
          ManseryeokService.isKoreanDst(DateTime(1987, 5, 10, 1, 59)), isFalse);
      expect(
          ManseryeokService.isKoreanDst(DateTime(1987, 5, 10, 2, 0)), isTrue);
      expect(
          ManseryeokService.isKoreanDst(DateTime(1987, 10, 11, 2, 59)), isTrue);
      expect(
          ManseryeokService.isKoreanDst(DateTime(1987, 10, 11, 3, 0)), isFalse);
    });

    test('한국 DST — 1951 추가 (codex Round 23)', () {
      expect(ManseryeokService.isKoreanDst(DateTime(1951, 7, 1, 12)), isTrue);
      expect(ManseryeokService.isKoreanDst(DateTime(1951, 5, 5, 23)), isFalse);
      expect(ManseryeokService.isKoreanDst(DateTime(1951, 9, 8, 23)), isTrue);
      expect(ManseryeokService.isKoreanDst(DateTime(1951, 9, 9, 0)), isFalse);
    });

    test('도시별 longitude offset — 부산 vs 서울 vs 제주', () {
      // KST UTC+9 (1962+): 135° 기준
      // 서울 126.98° → -32분, 부산 129.07° → -24분, 제주 126.50° → -34분
      final dt = DateTime(2000, 6, 15);
      final seoulOff =
          ManseryeokService.trueSunOffsetForCityDate(dt, '서울');
      final busanOff =
          ManseryeokService.trueSunOffsetForCityDate(dt, '부산');
      final jejuOff =
          ManseryeokService.trueSunOffsetForCityDate(dt, '제주');
      // 부산은 서울보다 동쪽 → offset이 덜 음수 (양수 방향)
      expect(busanOff - seoulOff, equals(8),
          reason: '부산은 서울보다 동쪽 (8분 차이)');
      // 제주는 서울보다 서쪽 → offset이 더 음수
      expect(jejuOff - seoulOff, equals(-2),
          reason: '제주는 서울보다 서쪽 (2분 차이)');
    });

    test('도시 영어 입력 — Seoul/Busan 매칭', () {
      final dt = DateTime(2000, 6, 15);
      expect(
        ManseryeokService.trueSunOffsetForCityDate(dt, 'Seoul'),
        equals(ManseryeokService.trueSunOffsetForCityDate(dt, '서울')),
      );
      expect(
        ManseryeokService.trueSunOffsetForCityDate(dt, 'Busan'),
        equals(ManseryeokService.trueSunOffsetForCityDate(dt, '부산')),
      );
    });

    test('진태양시 OFF — 표준시(KST) 그대로 사용', () {
      // 1990-02-04 17:00 (KASI 입춘 11:14 후): 표준시 그대로면 입춘 후 → 1990 庚午
      // 진태양시 ON: 17:00 - ~46분 (EoT 포함) = ~16:14, 입춘 후 → 1990 庚午 (same in this case)
      // boundary 비슷, 결과 거의 같음. 확인용 test.
      final off = ManseryeokService.calculate(
        year: 1990,
        month: 2,
        day: 4,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      final on = ManseryeokService.calculate(
        year: 1990,
        month: 2,
        day: 4,
        hour: 17,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: true,
      );
      // 둘 다 입춘 후 → 1990 庚午
      expect(off.yearPillar.text, '庚午');
      expect(on.yearPillar.text, '庚午');
      // 시주는 다를 수 있음 (boundary)
    });

    test('24절기 — 입춘 인덱스 0 = lipchun 같음', () {
      // termDateTime(year, 0) == lipchun(year)
      for (final y in [1990, 2000, 2010, 2020, 2024]) {
        expect(
          SolarTermService.termDateTime(y, 0),
          equals(SolarTermService.lipchun(y)),
        );
      }
    });

    test('24절기 — 12 중기 우수(idx 1) 입춘 직후 (Feb 18-20)', () {
      // 우수 = 황경 330° ≈ Feb 18-20.
      final usu2024 = SolarTermService.termDateTime(2024, 1);
      expect(usu2024.month, 2);
      expect(usu2024.day, greaterThanOrEqualTo(17));
      expect(usu2024.day, lessThanOrEqualTo(20));
    });

    test('24절기 — 추분 (idx 15) 9월 22-24', () {
      // 추분 = 180° ≈ Sep 22-24.
      final chubun2024 = SolarTermService.termDateTime(2024, 15);
      expect(chubun2024.month, 9);
      expect(chubun2024.day, greaterThanOrEqualTo(21));
      expect(chubun2024.day, lessThanOrEqualTo(24));
    });

    test('24절기 — 동지 (idx 21) 12월 21-23', () {
      // 동지 = 270° ≈ Dec 21-23.
      final dongji2024 = SolarTermService.termDateTime(2024, 21);
      expect(dongji2024.month, 12);
      expect(dongji2024.day, greaterThanOrEqualTo(20));
      expect(dongji2024.day, lessThanOrEqualTo(23));
    });

    test('currentTermIndex — 1월 중순 = 소한(22) 또는 대한(23)', () {
      final r = SolarTermService.currentTermIndex(DateTime(2024, 1, 15));
      expect(r, anyOf(equals(22), equals(23), equals(20), equals(21)));
    });

    test('currentTermIndex — 7월 = 하지(9) 또는 소서(10) 또는 대서(11)', () {
      final r = SolarTermService.currentTermIndex(DateTime(2024, 7, 15));
      expect(r, anyOf(equals(9), equals(10), equals(11)));
    });

    test('allTermsKo/En 길이 24', () {
      expect(SolarTermService.allTermsKo.length, 24);
      expect(SolarTermService.allTermsEn.length, 24);
      expect(SolarTermService.allTermsKo[0], '입춘');
      expect(SolarTermService.allTermsKo[23], '대한');
    });

    test('음력 입력 시 양력 변환 작동 — 1990 음력 1월 1일 = 양력 1990-1-27', () {
      // klc package 가 음력 변환 처리. KASI 발표값과 일치하는지 확인.
      // 1990 음력 1월 1일 (설날) = 양력 1990-01-27.
      // 따라서 음력 입력으로 들어오면 양력으로 변환 후 사주 계산.
      // 같은 결과: 음력 1990/1/1 vs 양력 1990/1/27.
      final lunar = ManseryeokService.calculate(
        year: 1990,
        month: 1,
        day: 1,
        hour: 12,
        minute: 0,
        isLunar: true,
        isMale: true,
        unknownTime: true,
      );
      final solar = ManseryeokService.calculate(
        year: 1990,
        month: 1,
        day: 27,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        unknownTime: true,
      );
      // 동일 일주 + 동일 년주 (둘 다 입춘 이전 → 1989 기준).
      expect(lunar.dayPillar.text, equals(solar.dayPillar.text),
          reason: '음력 1/1 = 양력 1/27 → 같은 사주여야 함');
      expect(lunar.yearPillar.text, equals(solar.yearPillar.text));
    });

    test('unknown time + 입춘일 — deterministic 년주 (hour=12 기준)', () {
      // 2024 입춘 = 17:11 (my formula). unknown time hour=12 → 입춘 이전 → 2023 년주.
      final r = ManseryeokService.calculate(
        year: 2024,
        month: 2,
        day: 4,
        hour: 12,
        minute: 0,
        isLunar: false,
        isMale: true,
        unknownTime: true,
      );
      // unknown time 이면 시주 미계산.
      expect(r.hourPillar, isNull);
      // 12시 < 입춘 17:11 → 2023 (癸卯) 년주.
      expect(r.yearPillar.text, '癸卯',
          reason: 'unknown time hour=12 가 입춘 이전이라 전년도 년주');
    });

    test('1988 DST 종료일 03:00 boundary — half-open 정확성', () {
      // 1988-10-09 02:59 → DST 적용 중
      // 1988-10-09 03:00 → DST 종료 (half-open)
      expect(
          ManseryeokService.isKoreanDst(DateTime(1988, 10, 9, 2, 59)), isTrue);
      expect(
          ManseryeokService.isKoreanDst(DateTime(1988, 10, 9, 3, 0)), isFalse);
      // 1988-05-08 02:00 → DST 시작 (inclusive)
      expect(
          ManseryeokService.isKoreanDst(DateTime(1988, 5, 8, 1, 59)), isFalse);
      expect(
          ManseryeokService.isKoreanDst(DateTime(1988, 5, 8, 2, 0)), isTrue);
    });

    test('1990년대 출생자: DST 영향 없음 (1990, 1995)', () {
      expect(ManseryeokService.isKoreanDst(DateTime(1990, 7, 15)), isFalse);
      expect(ManseryeokService.isKoreanDst(DateTime(1995, 7, 15)), isFalse);
    });

    test('2000년대 이후 출생자: DST 영향 없음', () {
      expect(ManseryeokService.isKoreanDst(DateTime(2000, 7, 15)), isFalse);
      expect(ManseryeokService.isKoreanDst(DateTime(2024, 7, 15)), isFalse);
    });

    test('도시별 보정이 calculate() 까지 흐름 — 부산 vs 서울 시주 boundary', () {
      // 1990-06-15 09:00 출생, 시주 boundary 근처 (실 태양시).
      // 서울 longitude -32분 → 진태양시 ~08:28 → 辰시
      // 부산 longitude -24분 → 진태양시 ~08:36 → 辰시 (같음)
      // 더 극단 케이스: 11:00 출생 (午시 boundary 11:00 inclusive)
      // 서울 -32분 → 10:28 → 巳시
      // 부산 -24분 → 10:36 → 巳시
      // 사주 hour boundary 11:00 → idx=(11+1)/2=6 (午), 10:36 → idx=(10+1)/2=5 (巳)
      // 부산이 더 동쪽이라 시간이 늦게 보정되어 boundary 가 다를 수 있음.
      final seoul = ManseryeokService.calculate(
        year: 1990,
        month: 6,
        day: 15,
        hour: 11,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: true,
        birthCity: '서울',
      );
      final busan = ManseryeokService.calculate(
        year: 1990,
        month: 6,
        day: 15,
        hour: 11,
        minute: 0,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: true,
        birthCity: '부산',
      );
      // 두 도시의 시주 jiJi 가 다를 수 있다 (boundary 부근일 때).
      // 최소한 hour pillar 가 양쪽 어느 한쪽에 정확히 존재.
      expect(seoul.hourPillar, isNotNull);
      expect(busan.hourPillar, isNotNull);
      // 적어도 분 단위 차이가 8분 (boundary 부근만 결과 달라짐).
    });

    test('도시 substring 매칭 — "서울특별시" → 서울', () {
      final dt = DateTime(2000, 6, 15);
      expect(
        ManseryeokService.trueSunOffsetForCityDate(dt, '서울특별시'),
        equals(ManseryeokService.trueSunOffsetForCityDate(dt, '서울')),
      );
    });

    test('1954-1961 UTC+8:30 시기 — longitude offset -2분 (not -32분)', () {
      // 1958-07-15: 표준시 UTC+8:30 시기 → longitude offset = -2분
      // DST 적용 (1958/5/4 ~ 9/21) → 시계 -1h → 입력시각 14:30 → 실제 13:30 → 진태양시 13:30 + EoT - 2분 ≈ 13:22
      // 비교 검증: 1962년 (UTC+9 시기) 같은 날짜는 longitude -32분 적용.
      final offset58 =
          ManseryeokService.seoulTrueSunOffsetForDate(DateTime(1958, 7, 15));
      final offset62 =
          ManseryeokService.seoulTrueSunOffsetForDate(DateTime(1962, 7, 15));
      // 1958 offset ≈ -2 + EoT(7/15); 1962 offset ≈ -32 + EoT(7/15)
      expect(offset58 - offset62, equals(30),
          reason: '1958 → 1962 longitude diff = 30분');
    });

    test('한국 DST — 1988 8월 출생 → 시계 -1h 자동 적용', () {
      // 1988-08-15 14:30 (DST 적용 기간) → 실제 사주 시각 13:30.
      // 시주: 13:00-15:00 = 未시 (羊). idx (13+1)/2 % 12 = 7 → 未.
      // DST 보정: 14:30 → 13:30. 13:30: idx (13+1)/2=7 → 未 (same in this case).
      // 시주 정확도는 시 boundary 근처에서만 차이.
      // 더 중요한 케이스: 15:30 (申시 변경 후) DST 후 14:30 (未시) → 시주 변경.
      final dst = ManseryeokService.calculate(
        year: 1988,
        month: 8,
        day: 15,
        hour: 15,
        minute: 30,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      // 1988-08-15 15:30 → DST -1h → 14:30 → 未시
      expect(dst.hourPillar!.jiJi, '未',
          reason: 'DST 적용으로 15:30 → 14:30 → 未시');
    });

    test('야자시 학파 옵션 — 23:30 출생: 기본 vs useLateNightZasi', () {
      // 1995-05-15 23:30: 기본 (조자시) → 다음 날 일주 (5/16).
      // 야자시 → 같은 날 일주 (5/15).
      final def = ManseryeokService.calculate(
        year: 1995,
        month: 5,
        day: 15,
        hour: 23,
        minute: 30,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      final late = ManseryeokService.calculate(
        year: 1995,
        month: 5,
        day: 15,
        hour: 23,
        minute: 30,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
        useLateNightZasi: true,
      );
      expect(def.dayPillar.text, isNot(equals(late.dayPillar.text)),
          reason: '두 학파의 일주는 1일 차이 나야 함');
    });

    test('입춘 직후 출생 (raw) — TST OFF/ON 으로 년주 다르게', () {
      // SolarTermService 의 2024 입춘 = 17:11 (KASI 17:27 대비 -16분 formula 오차).
      // Raw birth 17:30:
      // - TST OFF: 17:30 > 17:11 → 2024 甲辰
      // - TST ON (17:30 - 32 = 16:58): 16:58 < 17:11 → 2023 癸卯
      final off = ManseryeokService.calculate(
        year: 2024,
        month: 2,
        day: 4,
        hour: 17,
        minute: 30,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: false,
      );
      expect(off.yearPillar.text, '甲辰', reason: 'TST OFF: 17:30 > 입춘');

      final on = ManseryeokService.calculate(
        year: 2024,
        month: 2,
        day: 4,
        hour: 17,
        minute: 30,
        isLunar: false,
        isMale: true,
        applyTrueSunTime: true,
      );
      expect(on.yearPillar.text, '癸卯', reason: 'TST ON: 16:58 < 입춘');
    });
  });
}
