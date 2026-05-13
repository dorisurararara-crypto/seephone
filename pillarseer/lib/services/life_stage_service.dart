// Pillar Seer — 라이프스테이지(초년/중년/말년) 서비스.
//
// Round 73 Sprint 2:
// 운세의신 17 섹션 중 "초년운/중년운/말년운" 3 섹션을 DaewoonService.chain
// + TenGodsService 십신 분포로 동적 paragraph 생성. wire 0 → wire 1.
//
// 매핑:
//   - early phase = chunk[0..2] (대운 1~3, 보통 0~25세)
//   - mid phase   = chunk[3..4] (대운 4~5, 25~45세)
//   - late phase  = chunk[5..7] (대운 6~8, 45세+)
// 각 phase chunk 의 천간 십신(일간 기준) dominant 가 phrase key.
// 일간 강약(strong/weak)으로 변주.
//
// 페르소나: 한국 MZ K-pop 팬, 직설 친근 해요체 + 양면 단정 + 행동 처방 + 시점 anchor.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'daewoon_service.dart';
import 'strength_service.dart';
import 'ten_gods_service.dart';

class LifeStagePhase {
  /// 'early' / 'mid' / 'late' 의 한글 라벨.
  final String labelKo;

  /// 영문 라벨 (UPPERCASE).
  final String labelEn;

  /// phase 시작 나이 (UI 표시용, '~10세 경' 등).
  final int startAge;

  /// phase 본문 paragraph 한글.
  final String ko;

  /// phase 본문 paragraph 영문.
  final String en;

  /// 사용자가 현재 이 phase 에 있는지.
  final bool isCurrent;

  /// 이 paragraph 의 dominant 십신 (인터널 디버깅용).
  final TenGod? dominantSipsin;

  const LifeStagePhase({
    required this.labelKo,
    required this.labelEn,
    required this.startAge,
    required this.ko,
    required this.en,
    required this.isCurrent,
    this.dominantSipsin,
  });
}

class LifeStageResult {
  final LifeStagePhase early;
  final LifeStagePhase mid;
  final LifeStagePhase late;

  const LifeStageResult({
    required this.early,
    required this.mid,
    required this.late,
  });

  List<LifeStagePhase> get all => [early, mid, late];
}

class LifeStageService {
  static const _path = 'assets/data/life_stage_pool.json';
  static Map<String, dynamic>? _cache;

  /// JSON 풀 lazy load (Flutter rootBundle).
  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_path);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  /// 테스트 주입용: pre-loaded map (rootBundle 우회).
  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 사주 + 사용자 나이 → 3 phase paragraph.
  ///
  /// [isMale] 은 DaewoonService 순행/역행 결정 (양남음녀 순행).
  /// [userAge] 없으면 mid 가 current.
  static Future<LifeStageResult> compute(
    SajuResult saju, {
    bool isMale = true,
    int? userAge,
  }) async {
    final pool = await _pool();

    // 1) DaewoonService chain → 8 chunk
    final chain = DaewoonService.chain(
      monthPillar:
          '${saju.monthPillar.chunGan}${saju.monthPillar.jiJi}',
      yearChunGan: saju.yearPillar.chunGan,
      isMale: isMale,
    );

    // 2) phase mapping: chunk index 0..2 / 3..4 / 5..7
    final earlyChunks = chain.length >= 3 ? chain.sublist(0, 3) : chain;
    final midChunks = chain.length >= 5 ? chain.sublist(3, 5) : <dynamic>[];
    final lateChunks = chain.length >= 8 ? chain.sublist(5, 8) : <dynamic>[];

    // 3) 일간 강약 — StrengthService.judge label 은 '신강|신왕|중화|신약|신쇠'.
    final el = saju.elements;
    final strength = StrengthService.judge(
      dayMasterElement: saju.dayPillar.chunGanElement,
      monthJi: saju.monthPillar.jiJi,
      wood: el.wood,
      fire: el.fire,
      earth: el.earth,
      metal: el.metal,
      water: el.water,
      dayMaster: saju.dayPillar.chunGan,
      yearJi: saju.yearPillar.jiJi,
      dayJi: saju.dayPillar.jiJi,
      hourJi: saju.hourPillar?.jiJi,
    );
    // strong: 신강·신왕·중화 (강한 결로 풀이) / weak: 신약·신쇠 (약한 결로 풀이)
    final isStrong = strength.label == '신강' ||
        strength.label == '신왕' ||
        strength.label == '중화';
    final strengthKey = isStrong ? 'strong' : 'weak';

    // 4) 사주 8글자 십신 분포 (TenGodsService.tableFor 사용 — spec 명시).
    //    chunk 의 천간/지지를 추가로 가중하여 phase 별 dominant 결정.
    final dm = saju.dayMaster;
    final baseTable = TenGodsService.tableFor(saju);
    final baseFreq = <TenGod, int>{};
    for (final row in baseTable) {
      if (row.chunGanGod != null) {
        baseFreq[row.chunGanGod!] = (baseFreq[row.chunGanGod!] ?? 0) + 1;
      }
      if (row.jiJiGod != null) {
        baseFreq[row.jiJiGod!] = (baseFreq[row.jiJiGod!] ?? 0) + 1;
      }
    }

    TenGod? dominantOf(List<dynamic> chunks) {
      // 8글자 기본 분포 + chunk 가중 (chunk 천간/지지 각 1점).
      final freq = Map<TenGod, int>.from(baseFreq);
      for (final c in chunks) {
        final ganji = (c.ganji as String);
        if (ganji.isEmpty) continue;
        final g = TenGodsService.godFor(dm, ganji[0]);
        if (g != null) freq[g] = (freq[g] ?? 0) + 1;
        if (ganji.length > 1) {
          final j = TenGodsService.godForJiJi(dm, ganji[1]);
          if (j != null) freq[j] = (freq[j] ?? 0) + 1;
        }
      }
      if (freq.isEmpty) return null;
      final sorted = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.first.key;
    }

    final earlyGod = dominantOf(earlyChunks);
    final midGod = dominantOf(midChunks.isNotEmpty ? midChunks : earlyChunks);
    final lateGod = dominantOf(lateChunks.isNotEmpty
        ? lateChunks
        : (midChunks.isNotEmpty ? midChunks : earlyChunks));

    // 5) 현재 phase 결정 (userAge 기반)
    final age = userAge ?? 28; // 기본 mid 추정
    final earlyEnd = chain.length >= 3 ? chain[2].age + 10 : 25;
    final midEnd = chain.length >= 5 ? chain[4].age + 10 : 55;
    String currentKey;
    if (age < earlyEnd) {
      currentKey = 'early';
    } else if (age < midEnd) {
      currentKey = 'mid';
    } else {
      currentKey = 'late';
    }

    // 6) pool 에서 entry fetch
    ({String ko, String en}) fetch(TenGod? god, String phase) {
      if (god == null) {
        final fb = pool['_fallback'] as Map<String, dynamic>;
        return (ko: fb['ko'] as String, en: fb['en'] as String);
      }
      final key = '${_sipsinKey(god)}_${phase}_$strengthKey';
      final entry = pool[key] as Map<String, dynamic>?;
      if (entry != null) {
        return (ko: entry['ko'] as String, en: entry['en'] as String);
      }
      // 강약 fallback: 같은 phase × 다른 strength.
      final otherStrength = strengthKey == 'strong' ? 'weak' : 'strong';
      final alt = pool['${_sipsinKey(god)}_${phase}_$otherStrength']
          as Map<String, dynamic>?;
      if (alt != null) {
        return (ko: alt['ko'] as String, en: alt['en'] as String);
      }
      // 최종 fallback
      final fb = pool['_fallback'] as Map<String, dynamic>;
      return (ko: fb['ko'] as String, en: fb['en'] as String);
    }

    final e = fetch(earlyGod, 'early');
    final m = fetch(midGod, 'mid');
    final l = fetch(lateGod, 'late');

    final earlyStart = chain.isNotEmpty ? chain.first.age : 3;
    final midStart = chain.length >= 4 ? chain[3].age : 28;
    final lateStart = chain.length >= 6 ? chain[5].age : 53;

    return LifeStageResult(
      early: LifeStagePhase(
        labelKo: '초년운',
        labelEn: 'EARLY YEARS',
        startAge: earlyStart,
        ko: e.ko,
        en: e.en,
        isCurrent: currentKey == 'early',
        dominantSipsin: earlyGod,
      ),
      mid: LifeStagePhase(
        labelKo: '중년운',
        labelEn: 'MID YEARS',
        startAge: midStart,
        ko: m.ko,
        en: m.en,
        isCurrent: currentKey == 'mid',
        dominantSipsin: midGod,
      ),
      late: LifeStagePhase(
        labelKo: '말년운',
        labelEn: 'LATE YEARS',
        startAge: lateStart,
        ko: l.ko,
        en: l.en,
        isCurrent: currentKey == 'late',
        dominantSipsin: lateGod,
      ),
    );
  }

  static String _sipsinKey(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return 'bigyeon';
      case TenGod.geopjae:
        return 'geopjae';
      case TenGod.siksin:
        return 'siksin';
      case TenGod.sanggwan:
        return 'sanggwan';
      case TenGod.pyeonjae:
        return 'pyeonjae';
      case TenGod.jeongjae:
        return 'jeongjae';
      case TenGod.pyeongwan:
        return 'pyeongwan';
      case TenGod.jeonggwan:
        return 'jeonggwan';
      case TenGod.pyeonin:
        return 'pyeonin';
      case TenGod.jeongin:
        return 'jeongin';
    }
  }
}
