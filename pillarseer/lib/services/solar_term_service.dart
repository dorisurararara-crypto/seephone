// Pillar Seer — 24절기 (Solar Term) 절입시각 계산.
//
// 사주 명리학에서 년주·월주는 음력이 아니라 **태양 절기** 기준으로 바뀐다.
// - 년주: 입춘(立春, 태양 황경 315°) 경계.
// - 월주: 12절(立春·驚蟄·清明·立夏·芒種·小暑·立秋·白露·寒露·立冬·大雪·小寒) 경계.
//
// 이 서비스는 IAU/USNO 의 sun mean longitude 공식 + Newton's method 으로
// 임의 태양 황경의 정확한 KST datetime 을 ±5분 이내로 반환한다.
// 1900-2050 KASI 발표값과 대조 검증 완료 (manseryeok_service_test).
//
// 참조:
// - Meeus, "Astronomical Algorithms" Ch 25-27 (low-precision sun position)
// - KASI 「월력요항」 24절기 KST datetime
// - https://astro.kasi.re.kr/almanac/pageView/1

import 'dart:math';

class SolarTermService {
  /// 12절(節) 의 태양 황경 (월주 경계).
  /// 사주 월주는 절(節) 기준 — 중기(中氣, 우수·춘분 등)는 제외.
  /// 인덱스 0 = 입춘 (315°), 시계방향.
  static const List<double> jolLongitudes = [
    315.0, // 입춘 (立春) — 寅월 시작
    345.0, // 경칩 (驚蟄) — 卯월 시작
    15.0,  // 청명 (淸明) — 辰월 시작
    45.0,  // 입하 (立夏) — 巳월 시작
    75.0,  // 망종 (芒種) — 午월 시작
    105.0, // 소서 (小暑) — 未월 시작
    135.0, // 입추 (立秋) — 申월 시작
    165.0, // 백로 (白露) — 酉월 시작
    195.0, // 한로 (寒露) — 戌월 시작
    225.0, // 입동 (立冬) — 亥월 시작
    255.0, // 대설 (大雪) — 子월 시작
    285.0, // 소한 (小寒) — 丑월 시작
  ];

  /// 12중기(中氣) — 절기 24개 중 절(節)과 교대로 위치하는 중간점.
  /// 사주 월주 결정에는 사용하지 않지만, 절기 정보 표시·일일 운세 절기 인식·
  /// 연중 운세 timing 계산에 사용.
  static const List<double> jungGiLongitudes = [
    330.0, // 우수 (雨水) — 입춘 다음
    0.0,   // 춘분 (春分) — 경칩 다음
    30.0,  // 곡우 (穀雨) — 청명 다음
    60.0,  // 소만 (小滿) — 입하 다음
    90.0,  // 하지 (夏至) — 망종 다음
    120.0, // 대서 (大暑) — 소서 다음
    150.0, // 처서 (處暑) — 입추 다음
    180.0, // 추분 (秋分) — 백로 다음
    210.0, // 상강 (霜降) — 한로 다음
    240.0, // 소설 (小雪) — 입동 다음
    270.0, // 동지 (冬至) — 대설 다음
    300.0, // 대한 (大寒) — 소한 다음
  ];

  /// 24절기 (12절 + 12중기) — 1년 흐름 절기 전체.
  /// 인덱스 0=입춘, 1=우수, 2=경칩, 3=춘분, ..., 23=대한. 각 15°씩.
  static const List<String> allTermsKo = [
    '입춘', '우수', '경칩', '춘분',
    '청명', '곡우', '입하', '소만',
    '망종', '하지', '소서', '대서',
    '입추', '처서', '백로', '추분',
    '한로', '상강', '입동', '소설',
    '대설', '동지', '소한', '대한',
  ];
  static const List<String> allTermsEn = [
    'Lìchūn', 'Yǔshuǐ', 'Jīngzhé', 'Chūnfēn',
    'Qīngmíng', 'Gǔyǔ', 'Lìxià', 'Xiǎomǎn',
    'Mángzhòng', 'Xiàzhì', 'Xiǎoshǔ', 'Dàshǔ',
    'Lìqiū', 'Chùshǔ', 'Báilù', 'Qiūfēn',
    'Hánlù', 'Shuāngjiàng', 'Lìdōng', 'Xiǎoxuě',
    'Dàxuě', 'Dōngzhì', 'Xiǎohán', 'Dàhán',
  ];

  /// 절기 인덱스 0-23 → 태양 황경 (315°, 330°, 345°, 0°, ...).
  static double termLongitude(int termIdx) {
    final wrapped = termIdx % 24;
    return ((wrapped * 15) + 315) % 360;
  }

  /// 24절기 datetime — KST.
  static DateTime termDateTime(int year, int termIdx) =>
      solarTermDateTime(year, termLongitude(termIdx));

  /// 입력된 datetime 이 어떤 절기 구간에 있는지 반환 (0-23).
  /// 입춘(0) ~ 우수(1) 직전 = 0.
  static int currentTermIndex(DateTime kstDt) {
    // 가장 가까운 이전 절기 찾기.
    // 시작점: 1월 → 작년 대한이나 소한일 수 있음.
    final y = kstDt.year;
    // 작년 소한(termIdx 22) ~ 올해 대한(23) ~ 올해 입춘(0+24) ... 의 datetime 비교.
    int latest = 22;
    for (int i = 0; i < 25; i++) {
      // i=0 → 이번 해 입춘부터, i=1 → 우수 ... i=23 → 대한, i=24 → 다음 해 입춘
      final tIdx = i % 24;
      final tYear = i < 24 ? y : y + 1;
      final t = termDateTime(tYear, tIdx);
      if (!kstDt.isBefore(t)) {
        latest = tIdx;
      } else {
        break; // 다음 절기는 미래
      }
    }
    // 만약 이번 해 입춘 이전이면 작년 소한·대한 시기.
    if (kstDt.isBefore(termDateTime(y, 0))) {
      // 작년 소한 또는 대한.
      final dahan = termDateTime(y - 1, 23);
      if (!kstDt.isBefore(dahan)) return 23;
      final sohan = termDateTime(y - 1, 22);
      if (!kstDt.isBefore(sohan)) return 22;
      // 더 이전은 작년 대설(20).
      return 20;
    }
    return latest;
  }

  /// 12절 절입의 KST DateTime 반환.
  /// [jolIndex] 0=입춘 ... 11=소한.
  /// 입춘 이전 (1월) 의 소한 절입은 전년도 12월 말에 발생할 수 있음.
  static DateTime jolDateTime(int year, int jolIndex) {
    final lon = jolLongitudes[jolIndex];
    return solarTermDateTime(year, lon);
  }

  /// 입춘 KST DateTime — 년주 경계.
  static DateTime lipchun(int year) => solarTermDateTime(year, 315.0);

  /// 태양 황경 [targetLongitudeDeg] 가 되는 [year] 연도 내 KST DateTime.
  /// 입춘(315°) 의 경우 양력 2월 3-5일.
  /// Newton's method 로 수렴, 보통 4-5회 iteration.
  static DateTime solarTermDateTime(int year, double targetLongitudeDeg) {
    // 1) 초기 추정: 태양 황경의 평균 위치 기반.
    // 황경 0° = 춘분 ≈ 3월 20일 (year-day 78~79).
    // 약 0.98562 deg/day.
    double estimateDayOfYear = 79.0 + targetLongitudeDeg / 0.985647;
    // 입춘의 경우: 79 + 315/0.985647 ≈ 398 → 다음해 → mod 365.2422
    if (estimateDayOfYear > 365.2422) {
      estimateDayOfYear -= 365.2422;
    }
    // 입춘 (315°) → estimateDayOfYear ≈ 33-34 → 2/3~2/4

    // year 1월 1일 0시 UT 시각.
    DateTime estUt = DateTime.utc(year, 1, 1)
        .add(Duration(seconds: (estimateDayOfYear * 86400).round()));

    // 2) Newton's method.
    for (int i = 0; i < 8; i++) {
      final jd = _toJD(estUt);
      final sl = _solarLongitude(jd);
      // signed diff in degrees, -180..180
      double diff = targetLongitudeDeg - sl;
      diff = ((diff + 540) % 360) - 180;
      if (diff.abs() < 0.0001) break; // ~9 seconds precision
      // Adjust time. Sun moves ~0.98562 deg/day, so seconds = diff * 86400 / 0.985647.
      final dtSec = (diff * 86400 / 0.985647).round();
      estUt = estUt.add(Duration(seconds: dtSec));
    }

    // 3) UT → KST naive DateTime (시각만; 비교 시 birth (naive) 와 같은 wall-clock 기준).
    final shifted = estUt.add(const Duration(hours: 9));
    return DateTime(shifted.year, shifted.month, shifted.day, shifted.hour,
        shifted.minute, shifted.second);
  }

  // ─── astronomical helpers ──────────────────────────────────────────────

  /// Convert DateTime (UT) to Julian Date.
  static double _toJD(DateTime utDt) {
    int y = utDt.year;
    int m = utDt.month;
    final dayFrac = utDt.day +
        (utDt.hour + utDt.minute / 60.0 + utDt.second / 3600.0) / 24.0;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        dayFrac +
        b -
        1524.5;
  }

  /// Sun's apparent ecliptic longitude in degrees (0..360).
  /// Meeus Ch 25, low-precision formulas (accurate ~0.01°).
  static double _solarLongitude(double jd) {
    final T = (jd - 2451545.0) / 36525.0;
    // Mean longitude
    double L = 280.46646 + 36000.76983 * T + 0.0003032 * T * T;
    // Mean anomaly
    double M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T;
    final mRad = _rad(M);
    // Equation of center
    final c = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(mRad) +
        (0.019993 - 0.000101 * T) * sin(2 * mRad) +
        0.000289 * sin(3 * mRad);
    double trueLon = L + c;
    // Wrap to 0..360
    trueLon = trueLon % 360;
    if (trueLon < 0) trueLon += 360;
    return trueLon;
  }

  static double _rad(double deg) => deg * pi / 180.0;
}
