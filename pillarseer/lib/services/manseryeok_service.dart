// Pillar Seer — 만세력 정확도 service (KASI 표준).
// klc 패키지: 1391~2050 음양력 변환 + 60갑자.
// 진태양시 보정 (서울 127.5° vs 일본 동경 135° = 약 32분 차).
// 시주는 별도 계산 (klc 미지원).

import 'dart:math';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:klc/klc.dart' as klc;
import '../models/saju_result.dart';
import 'solar_term_service.dart';
import 'thong_geun_service.dart';

class _DstRange {
  final DateTime start;
  final DateTime end;
  const _DstRange(this.start, this.end);
}

class ManseryeokService {
  /// 월령 가중 배수 — 정통 세력 판단을 UX 퍼센트로 옮기는 휴리스틱.
  /// 월지(月支)의 지장간 점수에 곱하여 계절 세력을 반영한다.
  static const double monthBranchBoost = 3.0;

  /// 오행 퍼센트용 휴리스틱 가중치.
  /// 국내 사주 앱들이 공개하지 않는 5행 % 공식을 제품 안에서 일관되게 재현하기
  /// 위한 세력 점수이며, 고전의 표준 산식이라는 뜻은 아니다.
  static const double stemWeight = 1.4;
  static const double dayStemSelfBonus = 1.2;
  static const double rootMainBonus = 1.6;
  // Round 79 sprint 5: 학파 표준 swap (rootMiddle 0.3 ↔ rootTrace 0.6) 시도 결과
  // 1995-10-27 男 17시 5행 골든 16/21/17/41/4 깨짐 — 채택 X (revert).
  // 학파 표준 정합은 Round 80 deferred. 현재 가중치 (본기 > 중기 > 여기) 유지.
  static const double rootMiddleBonus = 0.6;
  static const double rootTraceBonus = 0.3;
  static const double monthRootMultiplier = 1.5;
  static const double exactLuBonus = 0.8;
  static const List<double> pillarWeights = [0.8, 1.4, 1.6, 1.1];

  /// 진태양시 longitude 보정 (분 단위) — 서울 기준 -32분 (KST UTC+9 시기).
  /// 동경 135° (KST) → 서울 126.98° 적용 시 표준시보다 32분 늦게 떠/짐.
  /// 사주 명리학에서 절대시간(진태양시) 채택이 정통.
  /// 균시차 (equation of time) 별도 추가 — ±16분 시즌별 변동.
  static const int seoulLongitudeOffsetMinutes = -32;

  /// 1954-03-21 ~ 1961-08-09 한국 표준시는 UTC+8:30 (127.5°).
  /// 이 시기 입력 시각은 이미 거의 한국 longitude 기준이므로 longitude 보정 거의 0.
  static const int seoulLongitudeOffsetMinutesKst830 = -2;

  /// 한국 주요 도시 경도 (degrees east).
  /// codex Round 22/24 권고: 출생지별 진태양시. 사용자 입력 도시 substring 매칭.
  /// fallback: 서울 (126.98°).
  static const Map<String, double> _cityLongitudes = {
    'seoul': 126.98,
    '서울': 126.98,
    'incheon': 126.71,
    '인천': 126.71,
    'busan': 129.07,
    '부산': 129.07,
    'daegu': 128.60,
    '대구': 128.60,
    'daejeon': 127.39,
    '대전': 127.39,
    'gwangju': 126.85,
    '광주': 126.85,
    'ulsan': 129.32,
    '울산': 129.32,
    'suwon': 127.03,
    '수원': 127.03,
    'changwon': 128.68,
    '창원': 128.68,
    'jeju': 126.50,
    '제주': 126.50,
    'gangneung': 128.88,
    '강릉': 128.88,
    'jeonju': 127.15,
    '전주': 127.15,
    'cheongju': 127.49,
    '청주': 127.49,
    'pohang': 129.36,
    '포항': 129.36,
    'mokpo': 126.39,
    '목포': 126.39,
    'andong': 128.73,
    '안동': 128.73,
    'chuncheon': 127.73,
    '춘천': 127.73,
    'sokcho': 128.59,
    '속초': 128.59,
    'wonju': 127.95,
    '원주': 127.95,
    // 천안시(天安市, 충남 67만): cheongan→cheonan / 청안(괴산 면, 1만) 제거.
    'cheonan': 127.15,
    '천안': 127.15,
    'iksan': 126.94,
    '익산': 126.94,
    'sunchang': 127.13,
    '순창': 127.13,
    'yeosu': 127.66,
    '여수': 127.66,
    'sangju': 128.16,
    '상주': 128.16,
    'gimhae': 128.89,
    '김해': 128.89,
    'jinju': 128.10,
    '진주': 128.10,
    'gunsan': 126.74,
    '군산': 126.74,
    'asan': 127.00,
    '아산': 127.00,
    'gimcheon': 128.11,
    '김천': 128.11,
    'seogwipo': 126.56,
    '서귀포': 126.56,
    'songdo': 126.65,
    '송도': 126.65,
    'tongyeong': 128.43,
    '통영': 128.43,
    'goyang': 126.83,
    '고양': 126.83,
    'seongnam': 127.13,
    '성남': 127.13,
    'bucheon': 126.79,
    '부천': 126.79,
    'ansan': 126.83,
    '안산': 126.83,
    'siheung': 126.80,
    '시흥': 126.80,
    'gwacheon': 126.99,
    '과천': 126.99,
  };

  /// 도시 이름에서 경도 추정 (substring 매칭, fallback 서울).
  static double longitudeForCity(String? city) {
    if (city == null || city.trim().isEmpty) return 126.98; // Seoul default
    final lower = city.trim().toLowerCase();
    // exact match
    if (_cityLongitudes.containsKey(lower)) return _cityLongitudes[lower]!;
    // substring match (e.g., "서울특별시", "Seoul, Korea")
    for (final entry in _cityLongitudes.entries) {
      if (lower.contains(entry.key) ||
          city.trim().contains(entry.key)) {
        return entry.value;
      }
    }
    return 126.98; // fallback: Seoul
  }

  /// 도시·시대 기반 longitude offset (분).
  /// KST UTC+9 시기: longitude - 135° → 4분/도.
  /// KST UTC+8:30 시기 (1954-1961): longitude - 127.5° → 4분/도.
  static int longitudeOffsetMinutes(DateTime dt, String? city) {
    final lon = longitudeForCity(city);
    final kst830Start = DateTime(1954, 3, 21);
    final kst830End = DateTime(1961, 8, 10);
    final meridian =
        (!dt.isBefore(kst830Start) && dt.isBefore(kst830End)) ? 127.5 : 135.0;
    return ((lon - meridian) * 4).round();
  }

  /// (deprecated) 균시차 미포함 단순 longitude offset.
  /// 외부 코드 호환을 위해 유지.
  @Deprecated('Use seoulLongitudeOffsetMinutes; equation of time is now applied automatically.')
  static const int seoulTrueSunOffsetMinutes = -32;

  /// 균시차 (Equation of Time, EoT) — 분 단위.
  /// Spencer (1971) 근사식, ±0.5분 정확도.
  /// [dayOfYear] 1~365 (윤년 무시 OK, 오차 1분 미만).
  /// 반환값: 음수 = 평균태양시 보다 빠름 (2월), 양수 = 느림 (11월).
  static double equationOfTimeMinutes(int dayOfYear) {
    final b = 2 * pi * (dayOfYear - 1) / 365.0;
    return 229.18 *
        (0.000075 +
            0.001868 * cos(b) -
            0.032077 * sin(b) -
            0.014615 * cos(2 * b) -
            0.040849 * sin(2 * b));
  }

  /// 서울 기준 진태양시 총 보정 (분) = longitude offset + EoT.
  /// (도시 정보 없을 때 사용. 도시 있으면 [trueSunOffsetForCityDate] 사용.)
  static int seoulTrueSunOffsetForDate(DateTime dt) =>
      trueSunOffsetForCityDate(dt, null);

  /// 도시·시대·EoT 기반 진태양시 총 보정 (분).
  /// [city] null/empty 면 서울 기본.
  static int trueSunOffsetForCityDate(DateTime dt, String? city) {
    final dayOfYear = dt.difference(DateTime(dt.year, 1, 1)).inDays + 1;
    final eot = equationOfTimeMinutes(dayOfYear);
    final lonOffset = longitudeOffsetMinutes(dt, city);
    return (lonOffset + eot).round();
  }

  /// 한국 서머타임 (DST) 적용 기간 — 출처: timeanddate.com 한국 DST 이력 (12개 시행).
  /// 출생일이 이 기간 내면 시계가 1시간 빨라져 있으므로 실제 사주 시간은 -1h.
  /// 자동 적용 (사용자에게 안 묻고).
  /// 1987-1988: 정확한 시각 (start 02:00 / end 03:00) 까지 반영.
  /// Returns true if [dt] (KST clock time, naive DateTime) falls within DST.
  static bool isKoreanDst(DateTime dt) {
    // 각 기간: 시작 datetime ~ 종료 datetime (exclusive 종료, half-open).
    // 자료 출처: https://www.timeanddate.com/time/zone/south-korea/seoul
    final ranges = <_DstRange>[
      _DstRange(DateTime(1948, 6, 1), DateTime(1948, 9, 13)),
      _DstRange(DateTime(1949, 4, 3), DateTime(1949, 9, 11)),
      _DstRange(DateTime(1950, 4, 1), DateTime(1950, 9, 10)),
      _DstRange(DateTime(1951, 5, 6), DateTime(1951, 9, 9)),
      _DstRange(DateTime(1955, 5, 5), DateTime(1955, 9, 9)),
      _DstRange(DateTime(1956, 5, 20), DateTime(1956, 9, 30)),
      _DstRange(DateTime(1957, 5, 5), DateTime(1957, 9, 22)),
      _DstRange(DateTime(1958, 5, 4), DateTime(1958, 9, 21)),
      _DstRange(DateTime(1959, 5, 3), DateTime(1959, 9, 20)),
      _DstRange(DateTime(1960, 5, 1), DateTime(1960, 9, 18)),
      // 1987/1988: 시간 정밀 (start 02:00 / end 03:00, half-open)
      _DstRange(DateTime(1987, 5, 10, 2, 0), DateTime(1987, 10, 11, 3, 0)),
      _DstRange(DateTime(1988, 5, 8, 2, 0), DateTime(1988, 10, 9, 3, 0)),
    ];
    for (final r in ranges) {
      if (!dt.isBefore(r.start) && dt.isBefore(r.end)) return true;
    }
    return false;
  }

  /// 만세력 기반 정확한 4기둥 계산.
  /// 반환은 SajuResult 의 부분 — 별도 deep content / 십신 / 대운은 호출자가 추가.
  ///
  /// [isLunar] true → 음력 입력 → 양력 변환 후 처리.
  /// [unknownTime] true → 시주 미계산.
  /// 진태양시 보정 적용 (옵션). false 시 표준시 기준.
  static ({
    Pillar yearPillar,
    Pillar monthPillar,
    Pillar dayPillar,
    Pillar? hourPillar,
    FiveElements elements,
    String dayMasterName,
    int solarYear,
    int solarMonth,
    int solarDay,
    DateTime adjustedBirth,
  }) calculate({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required bool isLunar,
    String? birthCity,
    required bool isMale,
    bool unknownTime = false,
    bool applyTrueSunTime = true,
    bool useLateNightZasi = false,
  }) {
    // 1. 음력 → 양력 (필요 시)
    int sYear = year;
    int sMonth = month;
    int sDay = day;
    if (isLunar) {
      try {
        klc.setLunarDate(year, month, day, false);
        sYear = klc.getSolarYear();
        sMonth = klc.getSolarMonth();
        sDay = klc.getSolarDay();
      } catch (_) {
        // out-of-range / invalid → fallback (solar 그대로)
      }
    }

    // 2. DST 보정 (한국 1948-1988 일부 기간) — 시계가 1h 빨랐으므로 실제 시각 -1h.
    int dstY = sYear;
    int dstM = sMonth;
    int dstD = sDay;
    int dstHour = hour;
    final bool wasDst =
        isKoreanDst(DateTime(sYear, sMonth, sDay, hour, minute));
    if (wasDst) {
      final corrected = DateTime(sYear, sMonth, sDay, hour, minute)
          .subtract(const Duration(hours: 1));
      dstY = corrected.year;
      dstM = corrected.month;
      dstD = corrected.day;
      dstHour = corrected.hour;
    }

    // 3. 진태양시 보정 — 시간 (& 자정 넘으면 day shift)
    // 정통 명리학: 모든 기둥에 진태양시 적용 (년·월 경계도 절기 ± 32분 오차 흡수).
    int adjHour = dstHour;
    int adjMin = minute;
    int adjY = dstY;
    int adjM = dstM;
    int adjD = dstD;
    if (applyTrueSunTime && !unknownTime) {
      final dt = DateTime(dstY, dstM, dstD, dstHour, minute);
      final offsetMin = trueSunOffsetForCityDate(dt, birthCity);
      final adj = dt.add(Duration(minutes: offsetMin));
      adjY = adj.year;
      adjM = adj.month;
      adjD = adj.day;
      adjHour = adj.hour;
      adjMin = adj.minute;
    }

    // 4. 일주 기준 날짜 결정 — 자시(23~01h) 의 23시대 처리.
    // 기본 (조자시 학파, useLateNightZasi=false): 23h 출생 → 다음 날 일주.
    // 야자시 학파 (useLateNightZasi=true): 23h 출생 → 같은 날 일주 유지.
    int dayPillarY = adjY;
    int dayPillarM = adjM;
    int dayPillarD = adjD;
    if (!unknownTime && adjHour == 23 && !useLateNightZasi) {
      final next = DateTime(adjY, adjM, adjD).add(const Duration(days: 1));
      dayPillarY = next.year;
      dayPillarM = next.month;
      dayPillarD = next.day;
    }

    // 4. klc 만세력으로 연·월·일 갑자 (한자 chars)
    Pillar yearP, monthP, dayP;
    try {
      klc.setSolarDate(dayPillarY, dayPillarM, dayPillarD);
      final gapja = klc.getChineseGapJaString();
      // format: "甲子年 乙丑月 丙寅日"
      final parts = gapja.split(' ');
      if (parts.length < 3 ||
          parts[0].length < 2 ||
          parts[1].length < 2 ||
          parts[2].length < 2) {
        throw Exception('Bad gapja: $gapja');
      }
      // 년주 — 사주 명리학은 입춘(立春) 절입 기준이므로 day pillar 의 연주는 부정확할 수 있음
      // 정확한 사주 년주: 입춘 절입시각 이전이면 전년도 사용.
      // 입춘 datetime 은 SolarTermService 로 ±5분 정확도.
      // 진태양시 보정된 datetime 으로 절기 경계 비교 (정통 명리학).
      yearP = _yearPillarSolarBased(adjY, adjM, adjD, adjHour, adjMin);
      monthP = _monthPillarSolarBased(adjY, adjM, adjD, adjHour, adjMin, yearP);
      dayP = Pillar(chunGan: parts[2][0], jiJi: parts[2][1]);
    } catch (_) {
      // fallback to legacy JDN 알고리즘
      final legacy = _legacyPillars(sYear, sMonth, sDay);
      yearP = legacy.year;
      monthP = legacy.month;
      dayP = legacy.day;
    }

    // 5. 시주 — 일간 × 시진 (klc 미지원, 자체 계산)
    Pillar? hourP;
    if (!unknownTime) {
      hourP = _hourPillar(dayP, adjHour);
    }

    // 6. 5행 분포 계산
    final pillars = <Pillar>[yearP, monthP, dayP];
    if (hourP != null) pillars.add(hourP);
    final elements = _calculateElements(pillars);

    // 7. 일간 영문 별칭
    const elementName = {'木': 'Wood', '火': 'Fire', '土': 'Earth', '金': 'Metal', '水': 'Water'};
    const animalName = {
      '子': 'Rat', '丑': 'Ox', '寅': 'Tiger', '卯': 'Rabbit',
      '辰': 'Dragon', '巳': 'Snake', '午': 'Horse', '未': 'Goat',
      '申': 'Monkey', '酉': 'Rooster', '戌': 'Dog', '亥': 'Pig',
    };
    final dayMasterName =
        '${elementName[dayP.chunGanElement] ?? "?"} ${animalName[dayP.jiJi] ?? "?"}';

    return (
      yearPillar: yearP,
      monthPillar: monthP,
      dayPillar: dayP,
      hourPillar: hourP,
      elements: elements,
      dayMasterName: dayMasterName,
      // 음력 입력의 양력 변환된 생년월일 — saju_service 의 나이 계산에서 사용.
      solarYear: sYear,
      solarMonth: sMonth,
      solarDay: sDay,
      // DST·진태양시 보정 모두 적용된 KST datetime — daewoon 절기 거리 계산에서 사용.
      adjustedBirth: DateTime(adjY, adjM, adjD, adjHour, adjMin),
    );
  }

  /// 년주: 입춘(立春) 절입시각 기준.
  /// SolarTermService 가 KST minute 정확도 datetime 반환 → 출생시각과 비교.
  /// 입춘 이전이면 전년도 갑자 사용.
  static Pillar _yearPillarSolarBased(
      int sYear, int sMonth, int sDay, [int hour = 0, int minute = 0]) {
    int adjYear = sYear;
    // 빠른 경로: 입춘 와 무관한 달 (3~12월) 은 datetime 계산 생략.
    if (sMonth == 1) {
      adjYear -= 1;
    } else if (sMonth == 2) {
      final birth = DateTime(sYear, sMonth, sDay, hour, minute);
      final lipchun = SolarTermService.lipchun(sYear);
      if (birth.isBefore(lipchun)) {
        adjYear -= 1;
      }
    }
    // 1900년 = 庚子 (60갑자 인덱스 36)
    final idx = ((36 + (adjYear - 1900)) % 60 + 60) % 60;
    return _pillarFromIndex(idx);
  }

  /// 월주: 12절(節) 절입시각 기준.
  /// 사주 명리학은 음력 월 ≠ 사주 월. 입춘 후 寅월, 경칩 후 卯월 ... 패턴.
  /// 월간(천간) 은 오호둔법(五虎遁法) — 년간 % 5 으로 결정.
  static Pillar _monthPillarSolarBased(int sYear, int sMonth, int sDay,
      int hour, int minute, Pillar yearPillar) {
    final birth = DateTime(sYear, sMonth, sDay, hour, minute);
    // 효과적 년도 계산 — 년주의 effective year 와 동일.
    int effYear = sYear;
    if (sMonth == 1) {
      effYear -= 1;
    } else if (sMonth == 2) {
      final lipchun = SolarTermService.lipchun(sYear);
      if (birth.isBefore(lipchun)) effYear -= 1;
    }
    // effYear 의 12절: 입춘~대설 (effYear), 소한 (effYear+1).
    // birth 가 어느 절기 구간에 속하는지 → m=0..11 (寅...丑).
    final jols = <DateTime>[
      for (int i = 0; i < 11; i++) SolarTermService.jolDateTime(effYear, i),
      SolarTermService.jolDateTime(effYear + 1, 11), // 소한
    ];
    int m = 0;
    for (int i = 0; i < 12; i++) {
      if (!birth.isBefore(jols[i])) m = i;
    }
    // 월지 mapping: m=0→寅, m=1→卯, ..., m=10→子, m=11→丑.
    const jiJi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final jiJiIdx = (m + 2) % 12;
    final monthJiJi = jiJi[jiJiIdx];
    // 월간 (오호둔법): 寅월 시작 천간 = (년간 % 5 * 2 + 2) % 10. 이후 순차.
    const chunGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    final yearChunGanIdx = chunGan.indexOf(yearPillar.chunGan);
    final firstMonthChunGanIdx =
        yearChunGanIdx < 0 ? 2 : ((yearChunGanIdx % 5) * 2 + 2) % 10;
    final monthChunGanIdx = (firstMonthChunGanIdx + m) % 10;
    return Pillar(chunGan: chunGan[monthChunGanIdx], jiJi: monthJiJi);
  }

  /// 시주: 일간 천간에 따라 자시 천간 결정.
  /// 갑/기일: 甲子, 을/경일: 丙子, 병/신일: 戊子, 정/임일: 庚子, 무/계일: 壬子
  static Pillar _hourPillar(Pillar dayPillar, int hour) {
    // 시진 결정 (자시 23~01, 축시 01~03, ..., 해시 21~23)
    int hourJiJiIdx;
    if (hour == 23 || hour == 0) {
      hourJiJiIdx = 0; // 子
    } else {
      hourJiJiIdx = ((hour + 1) ~/ 2) % 12;
    }
    // 천간 시작점 (자시)
    const startMap = {
      '甲': 0, '己': 0, '乙': 2, '庚': 2, '丙': 4, '辛': 4,
      '丁': 6, '壬': 6, '戊': 8, '癸': 8,
    };
    final hourChunGanStart = startMap[dayPillar.chunGan] ?? 0;
    const chunGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const jiJi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final cgIdx = (hourChunGanStart + hourJiJiIdx) % 10;
    return Pillar(chunGan: chunGan[cgIdx], jiJi: jiJi[hourJiJiIdx]);
  }

  static Pillar _pillarFromIndex(int idx) {
    const chunGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const jiJi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final i = idx % 60;
    return Pillar(chunGan: chunGan[i % 10], jiJi: jiJi[i % 12]);
  }

  /// 5행 분포 계산 — 지장간·월령·일간·통근을 반영한 UX 휴리스틱.
  ///
  /// 한 기둥 가중:
  /// - 천간: [stemWeight] × 년월일시 위치 가중.
  /// - 지지 지장간: 본기/중기/여기 ratio × 년월일시 위치 가중.
  /// - 월령: 월지(月支) 지장간 점수에 ×monthBoost.
  /// - 일간: 자기 5행에 [dayStemSelfBonus] 추가.
  /// - 통근: 일간이 지지 지장간에 뿌리내리면 본기/중기/여기 별 보너스.
  ///
  /// [monthIdx]: pillars 중 월주 index (보통 `[year, month, day, hour]` 의 1).
  /// [monthBoost]: 월령 가중 배수 (기본 [monthBranchBoost] = 3.0).
  static FiveElements _calculateElements(
    List<Pillar> pillars, {
    int monthIdx = 1,
    double monthBoost = monthBranchBoost,
  }) {
    double wood = 0, fire = 0, earth = 0, metal = 0, water = 0;

    void add(String el, double w) {
      switch (el) {
        case '木': wood += w; break;
        case '火': fire += w; break;
        case '土': earth += w; break;
        case '金': metal += w; break;
        case '水': water += w; break;
      }
    }

    final dayMaster = pillars.length > 2 ? pillars[2].chunGan : '';
    final dayMasterElement = pillars.length > 2 ? pillars[2].chunGanElement : '';

    for (int i = 0; i < pillars.length; i++) {
      final p = pillars[i];
      final pillarWeight = i < pillarWeights.length ? pillarWeights[i] : 1.0;
      // 1. 천간 가중. 천간은 밖으로 드러난 기운이라 지지 원점보다 높게 둔다.
      add(p.chunGanElement, stemWeight * pillarWeight);
      // 2. 지지 지장간 비율 가중. 월지는 계절권이라 추가 boost.
      final ratios =
          ThongGeunService.jijangGanRatio[p.jiJi] ?? const <String, double>{};
      final boost = pillarWeight * ((i == monthIdx) ? monthBoost : 1.0);
      ratios.forEach((gan, r) {
        add(ThongGeunService.ganElement(gan), r * boost);
      });
    }

    // 3. 일간 자체와 통근 보너스. 5행 %가 "내 사주의 세력표"로 읽히므로
    // 일간의 뿌리는 별도 보정한다.
    if (dayMasterElement.isNotEmpty) {
      add(dayMasterElement, dayStemSelfBonus);
      for (int i = 0; i < pillars.length; i++) {
        final p = pillars[i];
        final rootStrength = ThongGeunService.thongGeunStrength(dayMaster, p.jiJi);
        if (rootStrength == 0) continue;
        final base = switch (rootStrength) {
          3 => rootMainBonus,
          2 => rootMiddleBonus,
          _ => rootTraceBonus,
        };
        add(dayMasterElement, base * (i == monthIdx ? monthRootMultiplier : 1.0));
      }
      if (_exactLuBranch[dayMaster] case final lu?) {
        if (pillars.any((p) => p.jiJi == lu)) {
          add(dayMasterElement, exactLuBonus);
        }
      }
    }

    final total = wood + fire + earth + metal + water;
    if (total == 0) {
      return const FiveElements(wood: 20, fire: 20, earth: 20, metal: 20, water: 20);
    }
    // 5행 % 산출 — 사용자 mandate calibration 우선.
    //
    // Round 77 Sprint 1 결정: 1995-10-27 男 5행 골든 16/21/17/41/4 (합 99) 은
    // 1등 만세력 사이트 비교 기반 사용자 mandate. 산술적으로 합 100 보장과
    // 정확한 골든 lock 은 양립 불가 (largest-remainder 시 火 22 로 변동) →
    // 골든 보존 우선, 종전 독립 round() 그대로 유지.
    //
    // 일반 케이스 acceptance: 합 99~101 허용 (round() 자체 한계). UI 게이지
    // 시각 mismatch 는 향후 sprint 에서 별도 dominant +1 / deficit -1 보정안으로
    // deferred. backlog HIGH #7.
    return FiveElements(
      wood: (wood * 100 / total).round(),
      fire: (fire * 100 / total).round(),
      earth: (earth * 100 / total).round(),
      metal: (metal * 100 / total).round(),
      water: (water * 100 / total).round(),
    );
  }

  static const Map<String, String> _exactLuBranch = {
    '甲': '寅', '乙': '卯',
    '丙': '巳', '丁': '午',
    '戊': '巳', '己': '午',
    '庚': '申', '辛': '酉',
    '壬': '亥', '癸': '子',
  };

  /// 테스트 전용 fallback 강제 호출 — `_legacyPillars` 회귀 검증용.
  @visibleForTesting
  static ({Pillar year, Pillar month, Pillar day}) debugLegacyPillars(
          int y, int m, int d) =>
      _legacyPillars(y, m, d);

  /// JDN 기반 fallback (klc 실패 시).
  /// 월주는 SolarTermService(절기) + 오호둔법(五虎遁法) 으로 정상 산출.
  /// 종전 `((dayIdx ~/ 60) * 10) % 60` 은 dayIdx 가 0~59 라 항상 0 → 월주가 영원히 甲子 였다.
  static ({Pillar year, Pillar month, Pillar day}) _legacyPillars(
      int y, int m, int d) {
    int yy = y;
    int mm = m;
    if (mm <= 2) {
      yy -= 1;
      mm += 12;
    }
    final a = (yy / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jdn = ((365.25 * (yy + 4716)).floor() +
            (30.6001 * (mm + 1)).floor() +
            d + b - 1524.5)
        .floor();
    const epoch = 2415021;
    final dayIdx = ((10 + (jdn - epoch)) % 60 + 60) % 60;
    final yearP = _yearPillarSolarBased(y, m, d, 0, 0);
    final monthP = _legacyMonthPillar(y, m, d, yearP);
    return (
      year: yearP,
      month: monthP,
      day: _pillarFromIndex(dayIdx),
    );
  }

  /// fallback 월주 — SolarTermService 우선, 실패 시 절입 평균일 표 fallback.
  /// 월지(月支) = 12절 인덱스 매핑, 월간(月干) = 오호둔법(년간 % 5 기반).
  static Pillar _legacyMonthPillar(int y, int m, int d, Pillar yearPillar) {
    int monthJiIdx; // 0=寅 ~ 11=丑
    try {
      // SolarTermService 사용 가능: birth 가 어느 12절 구간인지 판정.
      final birth = DateTime(y, m, d);
      final jols = <DateTime>[
        for (int i = 0; i < 11; i++) SolarTermService.jolDateTime(y, i),
        SolarTermService.jolDateTime(y + 1, 11), // 다음해 소한
      ];
      int idx = -1;
      for (int i = 0; i < 12; i++) {
        if (!birth.isBefore(jols[i])) idx = i;
      }
      if (idx < 0) {
        // 입춘 이전 (1월) — 전년 소한 이후 = 丑월(11).
        idx = 11;
      }
      monthJiIdx = idx;
    } catch (_) {
      // 절기 데이터 실패 → 절입 평균일 표 fallback.
      // 입춘 2/4, 경칩 3/6, 청명 4/5, 입하 5/6, 망종 6/6, 소서 7/7,
      // 입추 8/8, 백로 9/8, 한로 10/8, 입동 11/7, 대설 12/7, 소한 1/6.
      const cutoff = <List<int>>[
        [2, 4],  // 寅 (입춘~)
        [3, 6],  // 卯 (경칩~)
        [4, 5],  // 辰 (청명~)
        [5, 6],  // 巳 (입하~)
        [6, 6],  // 午 (망종~)
        [7, 7],  // 未 (소서~)
        [8, 8],  // 申 (입추~)
        [9, 8],  // 酉 (백로~)
        [10, 8], // 戌 (한로~)
        [11, 7], // 亥 (입동~)
        [12, 7], // 子 (대설~)
        [1, 6],  // 丑 (소한~)
      ];
      int idx = 11; // default: 丑 (입춘 직전)
      for (int i = 11; i >= 0; i--) {
        final cm = cutoff[i][0];
        final cd = cutoff[i][1];
        // 같은 해 시퀀스로 비교: 입춘(寅) 이전은 전년 丑월.
        if (i == 11) {
          // 丑월: (소한 1/6 ~ 입춘 2/4) 또는 (전년 소한 1/6 ~ 올해 입춘 직전).
          if ((m == 1 && d >= cd) ||
              (m == 2 && d < 4)) {
            idx = 11;
            break;
          }
          continue;
        }
        if (m > cm || (m == cm && d >= cd)) {
          idx = i;
          break;
        }
      }
      monthJiIdx = idx;
    }
    // 월간(오호둔법): 寅월 시작 천간 = (년간 % 5 * 2 + 2) % 10. 이후 순차.
    const chunGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const jiJi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final yearChunGanIdx = chunGan.indexOf(yearPillar.chunGan);
    final firstMonthChunGanIdx =
        yearChunGanIdx < 0 ? 2 : ((yearChunGanIdx % 5) * 2 + 2) % 10;
    final monthChunGanIdx = (firstMonthChunGanIdx + monthJiIdx) % 10;
    // monthJiIdx 0=寅 → jiJi[(0+2)%12]=寅, 1=卯, ..., 11=丑.
    final monthJiJi = jiJi[(monthJiIdx + 2) % 12];
    return Pillar(chunGan: chunGan[monthChunGanIdx], jiJi: monthJiJi);
  }
}
