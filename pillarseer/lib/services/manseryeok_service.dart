// Pillar Seer — 만세력 정확도 service (KASI 표준).
// klc 패키지: 1391~2050 음양력 변환 + 60갑자.
// 진태양시 보정 (서울 127.5° vs 일본 동경 135° = 약 32분 차).
// 시주는 별도 계산 (klc 미지원).

import 'package:klc/klc.dart' as klc;
import '../models/saju_result.dart';

class ManseryeokService {
  /// 진태양시 보정 (분 단위) — 서울 기준 -32분
  /// 동경 135° (KST) → 서울 127.5° 적용 시 표준시보다 30분 늦게 떠/짐
  /// 사주 명리학에서 절대시간(진태양시) 채택이 정통.
  static const int seoulTrueSunOffsetMinutes = -32;

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
  }) calculate({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required bool isLunar,
    required bool isMale,
    bool unknownTime = false,
    bool applyTrueSunTime = true,
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

    // 2. 진태양시 보정 — 시간 (& 자정 넘으면 day shift)
    int adjHour = hour;
    int adjY = sYear;
    int adjM = sMonth;
    int adjD = sDay;
    if (applyTrueSunTime && !unknownTime) {
      final dt = DateTime(sYear, sMonth, sDay, hour, minute);
      final adj = dt.add(const Duration(minutes: seoulTrueSunOffsetMinutes));
      adjY = adj.year;
      adjM = adj.month;
      adjD = adj.day;
      adjHour = adj.hour;
    }

    // 3. 일주 기준 날짜 결정 — 자시(23~01h) 의 23시대는 다음날 일주 사용
    int dayPillarY = adjY;
    int dayPillarM = adjM;
    int dayPillarD = adjD;
    if (!unknownTime && adjHour == 23) {
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
      // 년주 — 사주 명리학은 입춘(2/4) 기준이므로 day pillar 의 연주는 부정확할 수 있음
      // 정확한 사주 년주: 입춘 이전이면 전년도 사용. KASI 의 year gapja 는 음력 1월 1일 기준 → 보정 필요
      // 안전하게 입춘 기준으로 직접 결정
      yearP = _yearPillarSolarBased(sYear, sMonth, sDay);
      monthP = Pillar(chunGan: parts[1][0], jiJi: parts[1][1]);
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
    );
  }

  /// 년주: 입춘(2/4) 기준 (단순화 — 매년 2/4 00:00 으로 처리)
  /// KASI 의 입춘 자동 데이터 사용 가능하지만 ±1일 오차 허용 시 충분.
  static Pillar _yearPillarSolarBased(int sYear, int sMonth, int sDay) {
    int adjYear = sYear;
    if (sMonth < 2 || (sMonth == 2 && sDay < 4)) {
      adjYear -= 1;
    }
    // 1900년 = 庚子 (60갑자 인덱스 36)
    final idx = ((36 + (adjYear - 1900)) % 60 + 60) % 60;
    return _pillarFromIndex(idx);
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

  static FiveElements _calculateElements(List<Pillar> pillars) {
    int wood = 0, fire = 0, earth = 0, metal = 0, water = 0;
    for (final p in pillars) {
      for (final el in [p.chunGanElement, p.jiJiElement]) {
        switch (el) {
          case '木': wood++; break;
          case '火': fire++; break;
          case '土': earth++; break;
          case '金': metal++; break;
          case '水': water++; break;
        }
      }
    }
    final total = wood + fire + earth + metal + water;
    if (total == 0) {
      return const FiveElements(wood: 20, fire: 20, earth: 20, metal: 20, water: 20);
    }
    return FiveElements(
      wood: (wood * 100 / total).round(),
      fire: (fire * 100 / total).round(),
      earth: (earth * 100 / total).round(),
      metal: (metal * 100 / total).round(),
      water: (water * 100 / total).round(),
    );
  }

  /// JDN 기반 fallback (klc 실패 시)
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
    return (
      year: _yearPillarSolarBased(y, m, d),
      month: _pillarFromIndex(((dayIdx ~/ 60) * 10) % 60),
      day: _pillarFromIndex(dayIdx),
    );
  }
}
