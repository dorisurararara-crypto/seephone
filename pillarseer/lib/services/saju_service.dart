import '../models/saju_result.dart';
import 'deep_content_service.dart';
import 'manseryeok_service.dart';
import 'saju_content_service.dart';
import 'ten_gods_service.dart';

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
/// Round 20-42 이후 적용 완료:
/// - klc 패키지 + 자체 SolarTermService 로 절기·음력 정확도 ±20분
/// - 출생지 36개 도시 longitude 자동 보정 (ManseryeokService)
/// - 한국 KST 진태양시 보정 (서울 -32분 + 균시차 ±16분, 1954-1961 UTC+8:30 시기)
/// - 음력 입력 → 양력 변환 (klc) 정상 작동
/// - 한국 DST 12 기간 (1948-1988) 자동 보정
/// - 야자시/조자시 학파 toggle (Settings)
/// - 12 신살 / 12 운성 / 공망 / 합·충 / 신왕신약 (Result accordion)

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

  /// 메인 사주 계산 함수.
  /// [unknownTime]=true 면 시주(hourPillar) 미계산 → null 반환,
  /// 5행 분포도 3기둥(년/월/일)만으로 산출 (가짜 hour 값으로 차트가 오염되지 않게).
  Future<SajuResult> calculateSaju({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required bool isLunar,
    required bool isMale,
    bool unknownTime = false,
    bool useLateNightZasi = false,
    bool applyTrueSunTime = true,
    String? birthCity,
  }) async {
    // 만세력 (KASI 표준) + 진태양시 보정 + 음양력 변환을 통합 처리
    final mans = ManseryeokService.calculate(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      isLunar: isLunar,
      isMale: isMale,
      unknownTime: unknownTime,
      useLateNightZasi: useLateNightZasi,
      applyTrueSunTime: applyTrueSunTime,
      birthCity: birthCity,
    );
    final yearP = mans.yearPillar;
    final monthP = mans.monthPillar;
    final dayP = mans.dayPillar;
    final hourP = mans.hourPillar;
    final elements = mans.elements;
    final dayMaster = dayP.chunGan;
    final dayMasterName = mans.dayMasterName;

    // assets/data/saju_60ji.json 에서 60일주 콘텐츠 로드
    String summary;
    Map<String, String> readings;
    try {
      summary = await SajuContentService.summaryFor(dayP.text);
      readings = await SajuContentService.readingsFor(dayP.text);
    } catch (_) {
      // JSON 로드 실패 시 fallback (test 환경 등)
      summary = _summaryFor(dayP.text);
      readings = _readingsFor(dayP.text);
    }

    // 8섹션 deep content + 10신 table + 대운/세운 procedural
    final currentYearGanji = DeepContentService.currentYearGanji();
    final today = DateTime.now();
    final hasBirthdayPassed = today.month > month ||
        (today.month == month && today.day >= day);
    final age = today.year - year - (hasBirthdayPassed ? 0 : 1);
    DeepReading? deepEn;
    DeepReading? deepKo;
    try {
      final pair = await DeepContentService.buildFor(
        day60ji: dayP.text,
        dayMasterName: dayMasterName,
        currentYearGanji: currentYearGanji,
        userAge: age.clamp(1, 120),
        dominantElement: elements.dominant,
        deficitElement: elements.deficit,
        shortReadings: readings,
      );
      deepEn = pair.en;
      deepKo = pair.ko;
    } catch (_) {
      // deep content optional; result still works without it
    }

    final base = SajuResult(
      yearPillar: yearP,
      monthPillar: monthP,
      dayPillar: dayP,
      hourPillar: hourP,
      elements: elements,
      dayMaster: dayMaster,
      dayMasterName: dayMasterName,
      summary: summary,
      categoryReadings: readings,
      deepEn: deepEn,
      deepKo: deepKo,
      userAge: age.clamp(1, 120),
      currentYearGanji: currentYearGanji,
    );

    final tenGods = TenGodsService.tableFor(base);
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
      deepEn: deepEn,
      deepKo: deepKo,
      tenGods: tenGods,
      userAge: age.clamp(1, 120),
      currentYearGanji: currentYearGanji,
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
