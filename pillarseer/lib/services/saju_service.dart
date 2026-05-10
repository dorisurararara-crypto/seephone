import '../models/saju_result.dart';

/// Pillar Seer — 사주(四柱) 계산 서비스
///
/// 60갑자(六十甲子) 시스템:
/// - 천간(天干) 10: 甲乙丙丁戊己庚辛壬癸
/// - 지지(地支) 12: 子丑寅卯辰巳午未申酉戌亥
/// - 60갑자 = 10×12의 최소공배수 (10×6=60, 12×5=60)
///
/// 정확도 노트:
/// - 일주(日柱): 1900-01-01 = 甲戌(60갑자 인덱스 10) 기준 누적 (Julian Day Number 사용)
/// - 년주(年柱): 입춘(立春, ~2/4) 기준. 입춘 전 출생은 전년도 처리 (현재 단순화: 양력 1/1 기준)
/// - 월주(月柱): 절기(節氣) 기준. 24절기 데이터 필요 (현재 단순화: 양력 월 기준)
/// - 시주(時柱): 일간 × 시진(時辰, 2시간 단위)
///
/// TODO (Phase 2):
/// - manseryeok-js 포팅으로 절기·음력 정확도 향상
/// - timezone 출생지 기반 보정
/// - 한국 KST 30분 진태양시 보정 (서울 127° vs 일본 동경 135°)
/// - 음력 입력 지원 (sajupy 데이터 기반)

class SajuService {
  // 60갑자 배열 (인덱스 0 = 甲子, 1 = 乙丑, ..., 59 = 癸亥)
  static const List<String> chunGan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];

  static const List<String> jiJi = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  /// 60갑자 인덱스 → Pillar
  Pillar pillarFromIndex(int index) {
    final i = index % 60;
    return Pillar(
      chunGan: chunGan[i % 10],
      jiJi: jiJi[i % 12],
    );
  }

  /// Julian Day Number (양력 yyyy-mm-dd → 정수 일수)
  int _julianDay(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return ((365.25 * (year + 4716)).floor() +
            (30.6001 * (month + 1)).floor() +
            day + b - 1524.5)
        .floor();
  }

  /// 일주 계산: 1900-01-01 = 甲戌 (60갑자 인덱스 10)
  /// JDN(1900-01-01) = 2415021
  int _dayPillarIndex(int year, int month, int day) {
    final jdn = _julianDay(year, month, day);
    final epoch = 2415021;
    final daysFromEpoch = jdn - epoch;
    return (10 + daysFromEpoch) % 60;
  }

  /// 년주: 1900년 = 庚子 (60갑자 인덱스 36)
  /// 입춘(2/4) 전이면 전년도 처리 (단순화)
  int _yearPillarIndex(int year, int month, int day) {
    int adjustedYear = year;
    if (month < 2 || (month == 2 && day < 4)) {
      adjustedYear -= 1;
    }
    return (36 + (adjustedYear - 1900)) % 60;
  }

  /// 월주: 년주 천간에 따라 정월(寅月) 천간 결정
  /// 갑/기년: 丙寅, 을/경년: 戊寅, 병/신년: 庚寅, 정/임년: 壬寅, 무/계년: 甲寅
  int _monthPillarIndex(int yearPillarIdx, int month, int day) {
    final yearChunGanIdx = yearPillarIdx % 10;
    // 정월(寅月) 천간 시작점
    const startMap = [2, 4, 6, 8, 0, 2, 4, 6, 8, 0]; // 갑=丙(2), 을=戊(4), ...
    final monthChunGanStart = startMap[yearChunGanIdx];

    // 절기 기준 단순화: 매월 6일 이후 = 해당 월
    int adjustedMonth = month;
    if (day < 6) adjustedMonth -= 1;
    if (adjustedMonth < 1) adjustedMonth += 12;

    // 정월(寅) = 1, 묘월 = 2, ..., 축월 = 12
    final lunarMonth = (adjustedMonth - 2 + 12) % 12; // 寅=0, 卯=1, ...
    final chunGanIdx = (monthChunGanStart + lunarMonth) % 10;
    final jiJiIdx = (lunarMonth + 2) % 12; // 寅=2

    // 60갑자 인덱스로 환산
    return _findGanjiIndex(chunGanIdx, jiJiIdx);
  }

  /// 시주: 일간 × 시진
  /// 갑/기일: 甲子시(자시), 을/경일: 丙子시, ...
  int _hourPillarIndex(int dayPillarIdx, int hour) {
    final dayChunGanIdx = dayPillarIdx % 10;
    // 자시(子) 천간 시작점
    const startMap = [0, 2, 4, 6, 8, 0, 2, 4, 6, 8]; // 갑=甲(0), 을=丙(2), ...
    final hourChunGanStart = startMap[dayChunGanIdx];

    // 시진 결정 (2시간 단위, 자시 = 23~01시)
    int hourJiJiIdx;
    if (hour == 23 || hour == 0) {
      hourJiJiIdx = 0; // 子
    } else {
      hourJiJiIdx = ((hour + 1) ~/ 2) % 12; // 1~2시 = 丑, 3~4시 = 寅, ...
    }

    final chunGanIdx = (hourChunGanStart + hourJiJiIdx) % 10;
    return _findGanjiIndex(chunGanIdx, hourJiJiIdx);
  }

  /// (천간 인덱스, 지지 인덱스) → 60갑자 인덱스
  int _findGanjiIndex(int chunGanIdx, int jiJiIdx) {
    for (int i = 0; i < 60; i++) {
      if (i % 10 == chunGanIdx && i % 12 == jiJiIdx) return i;
    }
    return 0; // fallback
  }

  /// 5행 분포 계산 (각 기둥의 천간/지지 5행 합계)
  FiveElements _calculateElements(List<Pillar> pillars) {
    int wood = 0, fire = 0, earth = 0, metal = 0, water = 0;
    for (final p in pillars) {
      final cg = p.chunGanElement;
      final jj = p.jiJiElement;
      for (final el in [cg, jj]) {
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
    if (total == 0) return const FiveElements(wood: 20, fire: 20, earth: 20, metal: 20, water: 20);
    return FiveElements(
      wood: (wood * 100 / total).round(),
      fire: (fire * 100 / total).round(),
      earth: (earth * 100 / total).round(),
      metal: (metal * 100 / total).round(),
      water: (water * 100 / total).round(),
    );
  }

  /// 일간 별칭 (영어, K-pop fan friendly)
  String _dayMasterEnglish(Pillar dayPillar) {
    const elementName = {'木': 'Wood', '火': 'Fire', '土': 'Earth', '金': 'Metal', '水': 'Water'};
    const animalName = {
      '子': 'Rat', '丑': 'Ox', '寅': 'Tiger', '卯': 'Rabbit',
      '辰': 'Dragon', '巳': 'Snake', '午': 'Horse', '未': 'Goat',
      '申': 'Monkey', '酉': 'Rooster', '戌': 'Dog', '亥': 'Pig',
    };
    final elem = elementName[dayPillar.chunGanElement] ?? '?';
    final anim = animalName[dayPillar.jiJi] ?? '?';
    return '$elem $anim';
  }

  /// 메인 사주 계산 함수
  Future<SajuResult> calculateSaju({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required bool isLunar,
    required bool isMale,
  }) async {
    // 음력 입력은 양력 변환 필요 (Phase 2: sajupy 데이터)
    // 현재는 양력 그대로 처리
    if (isLunar) {
      // TODO: 음력 → 양력 변환
    }

    final yearIdx = _yearPillarIndex(year, month, day);
    final monthIdx = _monthPillarIndex(yearIdx, month, day);
    final dayIdx = _dayPillarIndex(year, month, day);
    final hourIdx = _hourPillarIndex(dayIdx, hour);

    final yearP = pillarFromIndex(yearIdx);
    final monthP = pillarFromIndex(monthIdx);
    final dayP = pillarFromIndex(dayIdx);
    final hourP = pillarFromIndex(hourIdx);

    final elements = _calculateElements([yearP, monthP, dayP, hourP]);
    final dayMaster = dayP.chunGan;
    final dayMasterName = _dayMasterEnglish(dayP);

    // TODO: 실제 콘텐츠는 assets/data/saju_60ji.json 에서 로드
    final summary = _summaryFor(dayP.text);
    final readings = _readingsFor(dayP.text);

    return SajuResult(
      yearPillar: yearP,
      monthPillar: monthP,
      dayPillar: dayP,
      hourPillar: hourP,
      elements: elements,
      dayMaster: dayMaster,
      dayMasterName: dayMasterName,
      summary: summary,
      categoryReadings: readings,
    );
  }

  /// 일주 60갑자 → 한 줄 요약 (placeholder, JSON 데이터로 교체 예정)
  String _summaryFor(String day60ji) {
    // 60개 일주별 한 줄 요약 (Phase 2: assets/data/saju_60ji.json 로 이전)
    const map = {
      '甲子': 'You are a fresh sapling beside a deep stream — gentle, reflective, but rooted in cold clarity.',
      '戊寅': 'You are a mountain that shelters tigers — patient, ancient, quietly enormous.',
      '丙午': 'You are a noon flame on dry grass — bright, fast, magnetically warm.',
      '癸亥': 'You are deep water under a winter moon — silent, mysterious, holding everything.',
      '庚申': 'You are forged steel under starlight — sharp, cold, made for purpose.',
    };
    return map[day60ji] ?? 'Your destiny carries the rhythm of $day60ji — ancient, specific, yours alone.';
  }

  Map<String, String> _readingsFor(String day60ji) {
    return {
      'personality': 'Your $day60ji day pillar carries an ancient signature — strongest when you follow its native rhythm.',
      'love': 'Love arrives slowly for $day60ji — beginning in depth, growing in patience.',
      'money': 'Wealth flows toward $day60ji when you stay rooted in your essence, not chasing trends.',
      'career': '$day60ji thrives where your five-element balance can fully express itself.',
    };
  }
}
