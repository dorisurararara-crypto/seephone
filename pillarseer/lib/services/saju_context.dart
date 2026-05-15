// Pillar Seer — Round 78 sprint 1.
//
// SajuContext: 사주 1차 source-of-truth (immutable record).
//
// 목적: Round 71-77 누적된 동적 본문 서비스 (today_deep / today_event / home_screen /
// notification_pool / personalization_engine 등) 가 같은 사주 컨텍스트를 받아 분기.
// 기존 service signature 절대 손대지 않고 **위에 합성** — 이미 wire 된 service 호출만 모아둠.
//
// Round 78 Task A 진입점: hotspot H1~H10 동적화 시 ctx.dayMaster / ctx.gyeokguk /
// ctx.yongsin / ctx.tenGodFrequency 등을 priority chain 키로 사용.
//
// 5행 % 는 ManseryeokService 가 이미 산출한 값 그대로 — 본 ctx 는 추가 계산 0.
// 1995-10-27 男 골든 16/21/17/41/4 보존 mandate 자동 통과.

import '../models/saju_result.dart';
import 'daewoon_service.dart';
import 'gong_mang_service.dart';
import 'gyeokguk_service.dart';
import 'hapchung_service.dart';
import 'shinsa_service.dart';
import 'strength_service.dart';
import 'ten_gods_service.dart';
import 'yongsin_service.dart';

/// 사주 contextual snapshot — DynamicTextResolver 입력.
class SajuContext {
  /// 일간 천간 (甲乙丙丁戊己庚辛壬癸).
  final String dayMaster;

  /// 일간 5행 (木火土金水).
  final String dayElement;

  /// 일간 음양 (true=양, false=음).
  final bool dayYang;

  /// 월지 (월령).
  final String monthBranch;

  /// 양력 계절 라벨 — 봄/여름/가을/겨울.
  final String season;

  /// 5행 % — wood/fire/earth/metal/water (R75 calibration 그대로).
  final int wood;
  final int fire;
  final int earth;
  final int metal;
  final int water;

  /// dominant / deficit 5행 (5행 % 기반 동치).
  final String dominantElement;
  final String deficitElement;

  /// 십신 빈도 — 비견/겁재/식신/상관/편재/정재/편관/정관/편인/정인.
  final Map<TenGod, int> tenGodFrequency;

  /// 신강/신약 라벨 (StrengthService.judge) — '신강' / '신왕' / '중화' / '신약' / '신쇠'.
  final String strengthLabel;

  /// 격국 짧은 이름 (예: '정관격').
  /// 본 field 는 **label dictionary** — body 본문 노출 시 추가 한자 redact 가드는 resolver 책임.
  final String gyeokgukShort;

  /// 격국 full 한자 (예: '정관격 (正官格)') — 격국 카드 / 결과 화면 jargon 한정 사용.
  /// MZ 톤 본문 (today_deep body / home _pool) 에는 [gyeokgukShort] 만 권장.
  final String gyeokgukFull;

  /// 용신 5행.
  final String yongsin;

  /// 희신 5행.
  final String huisin;

  /// 기신 (용신 극 5행 — gisin = overcomes[yongsin]).
  final String gisin;

  /// 활성화된 신살 set — '역마', '도화', '화개', '천을귀인', '문창귀인', '양인', '괴강', '백호'.
  final Set<String> activeShinsa;

  /// 공망 활성 영역 — 'year' / 'month' / 'hour' (일주 자기제외).
  final List<String> gongMangAreas;

  /// 현재 사용자 대운 chunk (age boundary + ganji + element) — null 가능 (사용자 나이 미입력).
  final ({int age, String ganji, String element})? currentDaewoon;

  /// 현재 대운 천간 → 일간 기준 십신 (예: 정인). null 가능.
  final TenGod? currentDaewoonGod;

  /// 오늘 일진 ganji (예: '甲子'). null 가능 (today_event 진입 시 set).
  final String? todayPillar;

  /// 오늘 일진 → 일간 기준 십신.
  final TenGod? todayGod;

  /// 오늘 일진과 일주 사이 직접 관계 발동 list.
  /// 본 ctx 는 명시적으로 **천간합 / 지지합 / 지지충 3종만** wire — HapchungService 의
  /// 단일 pair API 가 cover 하는 범위. 형(刑)/파(破)/해(害) 는 별도 신살 서비스
  /// (today_event / shinsa) 가 보유하므로 본 field 에는 포함 X — Sprint 6 에서
  /// today_event_pool 측면으로 anchor.
  final List<String> todayRelations;

  /// 결정적 분기 seed — (dayPillar code × YYYYMMDD) 형태 정수. resolver 가 풀 회전 seed 로 사용.
  final int chartSeed;

  /// 사용자 만 나이 (null 가능).
  final int? userAge;

  const SajuContext({
    required this.dayMaster,
    required this.dayElement,
    required this.dayYang,
    required this.monthBranch,
    required this.season,
    required this.wood,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
    required this.dominantElement,
    required this.deficitElement,
    required this.tenGodFrequency,
    required this.strengthLabel,
    required this.gyeokgukShort,
    required this.gyeokgukFull,
    required this.yongsin,
    required this.huisin,
    required this.gisin,
    required this.activeShinsa,
    required this.gongMangAreas,
    required this.currentDaewoon,
    required this.currentDaewoonGod,
    required this.todayPillar,
    required this.todayGod,
    required this.todayRelations,
    required this.chartSeed,
    required this.userAge,
  });

  /// SajuResult + 선택적 today datetime → SajuContext.
  ///
  /// [today] null 이면 오늘 일진 관련 필드 (todayPillar / todayGod / todayRelations) 는
  /// null/empty 로 둔다. resolver 가 fallback chain 으로 보충.
  factory SajuContext.from(
    SajuResult saju, {
    DateTime? today,
  }) {
    final dm = saju.dayMaster;
    final dmEl = _ganElementOf(dm);
    final dayYang = _isGanYang(dm);

    // 5행 분포 (이미 R75 calibration 적용된 값).
    final el = saju.elements;
    final dom = el.dominant; // 한자 (木/火/土/金/水)
    final def = el.deficit;

    // 십신 빈도 (year/month/day/hour 천간 + 지지 본기).
    final tenGodRows = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final r in tenGodRows) {
      if (r.chunGanGod != null) {
        freq[r.chunGanGod as TenGod] = (freq[r.chunGanGod as TenGod] ?? 0) + 1;
      }
      if (r.jiJiGod != null) {
        freq[r.jiJiGod as TenGod] = (freq[r.jiJiGod as TenGod] ?? 0) + 1;
      }
    }

    // 신강/신약.
    final strength = StrengthService.judge(
      dayMasterElement: dmEl,
      monthJi: saju.monthPillar.jiJi,
      wood: el.wood,
      fire: el.fire,
      earth: el.earth,
      metal: el.metal,
      water: el.water,
      dayMaster: dm,
      yearJi: saju.yearPillar.jiJi,
      dayJi: saju.dayPillar.jiJi,
      hourJi: saju.hourPillar?.jiJi,
    );

    // 격국.
    final gy = GyeokgukService.judge(
      dayMaster: dm,
      monthJi: saju.monthPillar.jiJi,
    );

    // 용신.
    // R84 — monthBranch 전달로 R83 조후/계절 보정 reason 흡수. yongsin/huisin
    // 자체는 변하지 않으나 (R80 sprint 6 mandate / R83 회귀 가드) result_screen
    // 의 YongsinService.judge 호출과 signature parity 확보.
    final ys = YongsinService.judge(
      dayMasterElement: dmEl,
      strengthLabel: strength.label,
      wood: el.wood,
      fire: el.fire,
      earth: el.earth,
      metal: el.metal,
      water: el.water,
      monthBranch: saju.monthPillar.jiJi,
    );

    // 기신 — 용신을 극하는 오행 (5행 상극).
    const overcomeBy = {
      '木': '金', '火': '水', '土': '木', '金': '火', '水': '土',
    };
    final gisin = overcomeBy[ys.yongsin] ?? '';

    // 신살.
    final shinsa = ShinsaService.analyzeChart(
      yearJi: saju.yearPillar.jiJi,
      monthJi: saju.monthPillar.jiJi,
      dayChunGan: dm,
      dayJi: saju.dayPillar.jiJi,
      hourJi: saju.hourPillar?.jiJi,
    );

    // 공망 영역.
    final gongMang = GongMangService.affectedAreas(
      dayPillar: saju.dayPillar.text,
      yearJi: saju.yearPillar.jiJi,
      monthJi: saju.monthPillar.jiJi,
      hourJi: saju.hourPillar?.jiJi,
    );

    // 현재 대운.
    ({int age, String ganji, String element})? currentDw;
    TenGod? currentDwGod;
    if (saju.userAge != null && saju.isMale != null) {
      final chain = DaewoonService.chain(
        monthPillar: saju.monthPillar.text,
        yearChunGan: saju.yearPillar.chunGan,
        isMale: saju.isMale!,
        birthDateTime: saju.birthDateTime,
      );
      currentDw = DaewoonService.currentChunk(
        chain: chain,
        userAge: saju.userAge!,
      );
      if (currentDw != null && currentDw.ganji.length == 2) {
        currentDwGod = TenGodsService.godFor(dm, currentDw.ganji[0]);
      }
    }

    // 오늘 일진.
    String? todayPillar;
    TenGod? todayGod;
    final relations = <String>[];
    if (today != null) {
      todayPillar = _todayGanjiFor(today);
      if (todayPillar.length == 2) {
        todayGod = TenGodsService.godFor(dm, todayPillar[0]);
        // 오늘 vs 일주 관계 — hapchung_service 의 단일 pair 분석.
        final tGan = todayPillar[0];
        final tJi = todayPillar[1];
        if (HapchungService.isCheonganHap(tGan, saju.dayPillar.chunGan)) {
          relations.add('천간합');
        }
        if (HapchungService.isJijiHap(tJi, saju.dayPillar.jiJi)) {
          relations.add('지지합');
        }
        if (HapchungService.isJijiChung(tJi, saju.dayPillar.jiJi)) {
          relations.add('지지충');
        }
      }
    }

    // 결정적 seed: (60갑자 인덱스 × yyyymmdd) — today 미공급 시 birthDateTime 사용.
    final dayIdx = _ganjiIndex(saju.dayPillar.text);
    final dateBase = (today ?? saju.birthDateTime ?? DateTime(2026, 1, 1));
    final dateKey = dateBase.year * 10000 + dateBase.month * 100 + dateBase.day;
    final chartSeed = (dayIdx + 1) * 1000000 + dateKey;

    return SajuContext(
      dayMaster: dm,
      dayElement: dmEl,
      dayYang: dayYang,
      monthBranch: saju.monthPillar.jiJi,
      season: _seasonOf(saju.monthPillar.jiJi),
      wood: el.wood,
      fire: el.fire,
      earth: el.earth,
      metal: el.metal,
      water: el.water,
      dominantElement: dom,
      deficitElement: def,
      tenGodFrequency: Map.unmodifiable(freq),
      strengthLabel: strength.label,
      gyeokgukShort: _shortGyeokguk(gy.name),
      gyeokgukFull: gy.name,
      yongsin: ys.yongsin,
      huisin: ys.huisin,
      gisin: gisin,
      activeShinsa: Set.unmodifiable(shinsa.keys.toSet()),
      gongMangAreas: List.unmodifiable(gongMang),
      currentDaewoon: currentDw,
      currentDaewoonGod: currentDwGod,
      todayPillar: todayPillar,
      todayGod: todayGod,
      todayRelations: List.unmodifiable(relations),
      chartSeed: chartSeed,
      userAge: saju.userAge,
    );
  }

  /// 한국어 5행 라벨 (목/화/토/금/수). dominantElement 등 한자 → 한글.
  static String elementKo(String hanja) {
    const m = {'木': '목', '火': '화', '土': '토', '金': '금', '水': '수'};
    return m[hanja] ?? hanja;
  }

  /// 영문 5행 라벨.
  static String elementEn(String hanja) {
    const m = {
      '木': 'Wood',
      '火': 'Fire',
      '土': 'Earth',
      '金': 'Metal',
      '水': 'Water',
    };
    return m[hanja] ?? hanja;
  }

  // ── private helpers ─────────────────────────────────────────

  static const Map<String, String> _ganElement = {
    '甲': '木', '乙': '木',
    '丙': '火', '丁': '火',
    '戊': '土', '己': '土',
    '庚': '金', '辛': '金',
    '壬': '水', '癸': '水',
  };

  static const Set<String> _yangGans = {'甲', '丙', '戊', '庚', '壬'};

  static String _ganElementOf(String gan) => _ganElement[gan] ?? '?';

  static bool _isGanYang(String gan) => _yangGans.contains(gan);

  static String _seasonOf(String monthJi) {
    // 명리 절기 기준: 寅卯辰=봄 / 巳午未=여름 / 申酉戌=가을 / 亥子丑=겨울.
    const m = {
      '寅': '봄', '卯': '봄', '辰': '봄',
      '巳': '여름', '午': '여름', '未': '여름',
      '申': '가을', '酉': '가을', '戌': '가을',
      '亥': '겨울', '子': '겨울', '丑': '겨울',
    };
    return m[monthJi] ?? '?';
  }

  static String _shortGyeokguk(String full) {
    // '정관격 (正官格)' → '정관격'.
    final idx = full.indexOf(' ');
    return idx > 0 ? full.substring(0, idx) : full;
  }

  static const List<String> _gan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];
  static const List<String> _ji = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  static int _ganjiIndex(String ganji) {
    if (ganji.length != 2) return 0;
    final g = _gan.indexOf(ganji[0]);
    final j = _ji.indexOf(ganji[1]);
    if (g < 0 || j < 0) return 0;
    for (int i = 0; i < 60; i++) {
      if (i % 10 == g && i % 12 == j) return i;
    }
    return 0;
  }

  /// 1900-01-01 = 甲戌(60갑자 인덱스 10) 기준 → 오늘 일진 ganji.
  /// SajuService 일주 산출 로직과 동일 식 — 단, 외부 새 import 없이 자체 계산.
  static String _todayGanjiFor(DateTime today) {
    final base = DateTime.utc(1900, 1, 1);
    final t = DateTime.utc(today.year, today.month, today.day);
    final diff = t.difference(base).inDays;
    final idx = ((10 + diff) % 60 + 60) % 60;
    return '${_gan[idx % 10]}${_ji[idx % 12]}';
  }
}
