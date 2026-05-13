// Pillar Seer — 직업 추천 서비스 (Round 73 Sprint 6).
//
// 8글자 십신 분포 (dominant + secondary) → 직업 list (5-7) + 한 줄 설명.
// 운세의신 17 섹션 중 "재테크 비법" 의 직업 추천 부분 흡수.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'ten_gods_service.dart';

class CareerRecommendation {
  /// 십신 조합 한글 라벨 (예: "정인 + 상관").
  final String primaryKo;

  /// 영문 라벨.
  final String primaryEn;

  /// 한 줄 설명 한글.
  final String noteKo;

  /// 한 줄 설명 영문.
  final String noteEn;

  /// 추천 직업 list 한글 (5-7).
  final List<String> careersKo;

  /// 추천 직업 list 영문.
  final List<String> careersEn;

  /// 매핑된 dominant 십신 (디버깅용).
  final TenGod? dominantSipsin;

  /// 매핑된 secondary 십신 (디버깅용).
  final TenGod? secondarySipsin;

  const CareerRecommendation({
    required this.primaryKo,
    required this.primaryEn,
    required this.noteKo,
    required this.noteEn,
    required this.careersKo,
    required this.careersEn,
    this.dominantSipsin,
    this.secondarySipsin,
  });
}

class CareerRecommendService {
  static const _path = 'assets/data/career_pool.json';
  static Map<String, dynamic>? _cache;

  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_path);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 사주 → 직업 추천.
  ///
  /// 입력: 8글자 십신 분포 (TenGodsService.tableFor) + 일간 5행 (saju.dayPillar.chunGanElement).
  /// 일간 5행은 priority pair 동률 일 때 동일 5행 십신 쪽으로 가중 (예: 木 일간 → 인성 우선).
  static Future<CareerRecommendation> compute(SajuResult saju) async {
    final pool = await _pool();

    final table = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final row in table) {
      if (row.chunGanGod != null) {
        freq[row.chunGanGod!] = (freq[row.chunGanGod!] ?? 0) + 1;
      }
      if (row.jiJiGod != null) {
        freq[row.jiJiGod!] = (freq[row.jiJiGod!] ?? 0) + 1;
      }
    }

    if (freq.isEmpty) {
      return _fallback(pool);
    }

    // 일간 5행 가중 — 인성 (정인+편인) freq 에 +0.5 추가 (5행 보호 강조).
    // 木·火 일간은 식상 +0.5, 金·水 일간은 관성 +0.5 (전형 패턴).
    final dayEl = saju.dayPillar.chunGanElement;
    final dayElBonus = <TenGod, double>{};
    if (dayEl == '木' || dayEl == '火') {
      dayElBonus[TenGod.siksin] = 0.5;
      dayElBonus[TenGod.sanggwan] = 0.5;
    } else if (dayEl == '金' || dayEl == '水') {
      dayElBonus[TenGod.jeonggwan] = 0.5;
      dayElBonus[TenGod.pyeongwan] = 0.5;
    } else if (dayEl == '土') {
      dayElBonus[TenGod.pyeonjae] = 0.5;
      dayElBonus[TenGod.jeongjae] = 0.5;
    }
    // dayElBonus 는 priority pair 동률 일 때 secondary 결정에만 사용 (정수 freq 우선).
    final weightedFreq = <TenGod, double>{};
    freq.forEach((g, c) {
      weightedFreq[g] = c.toDouble() + (dayElBonus[g] ?? 0);
    });

    // weightedFreq 로 sort (일간 5행 가중 반영).
    final sorted = weightedFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dom = sorted.first.key;
    final sec = sorted.length > 1 ? sorted[1].key : null;

    // 매칭 시도 순서:
    //   1) 의미 있는 페어 priority — 정인+상관 / 정관+정인 / 편관+상관 등.
    //      두 십신이 사주 안에 모두 등장하면 그 페어 entry 사용 (8글자 십신 매칭).
    //   2) dominant + secondary (정렬된 키)
    //   3) dominant + 다른 핵심 십신
    //   4) fallback
    Map<String, dynamic>? entry;

    // 1) priority 페어 — 운세의신 본문 매칭 비결.
    //    각 페어 = [요구되는 십신 2개, JSON key].
    const priorityPairs = <List<dynamic>>[
      [TenGod.jeongin, TenGod.sanggwan, 'jeongin_sanggwan'],
      [TenGod.pyeonin, TenGod.sanggwan, 'pyeonin_sanggwan'],
      [TenGod.jeonggwan, TenGod.jeongin, 'jeonggwan_jeongin'],
      [TenGod.jeonggwan, TenGod.sanggwan, 'jeonggwan_sanggwan'],
      [TenGod.pyeongwan, TenGod.sanggwan, 'pyeongwan_sanggwan'],
      [TenGod.siksin, TenGod.jeongin, 'siksin_jeongin'],
      [TenGod.siksin, TenGod.sanggwan, 'siksin_sanggwan'],
      [TenGod.siksin, TenGod.pyeonin, 'siksin_pyeonin'],
      [TenGod.jeongin, TenGod.pyeonjae, 'jeongin_pyeonjae'],
      [TenGod.siksin, TenGod.pyeonjae, 'siksin_pyeonjae'],
      [TenGod.sanggwan, TenGod.pyeonjae, 'sanggwan_pyeonjae'],
      [TenGod.sanggwan, TenGod.pyeonin, 'sanggwan_pyeonin'],
      [TenGod.jeonggwan, TenGod.pyeonjae, 'jeonggwan_pyeonjae'],
      [TenGod.jeonggwan, TenGod.jeongjae, 'jeonggwan_jeongjae'],
      [TenGod.pyeongwan, TenGod.pyeonjae, 'pyeongwan_pyeonjae'],
      [TenGod.pyeongwan, TenGod.jeongin, 'pyeongwan_jeongin'],
      [TenGod.pyeonjae, TenGod.jeongjae, 'pyeonjae_jeongjae'],
      [TenGod.pyeonjae, TenGod.pyeonin, 'pyeonjae_pyeonin'],
      [TenGod.pyeonjae, TenGod.jeongin, 'pyeonjae_jeongin'],
      [TenGod.siksin, TenGod.jeongjae, 'siksin_jeongjae'],
      [TenGod.bigyeon, TenGod.jeongjae, 'bigyeon_jeongjae'],
      [TenGod.bigyeon, TenGod.sanggwan, 'bigyeon_sanggwan'],
      [TenGod.bigyeon, TenGod.pyeongwan, 'bigyeon_pyeongwan'],
      [TenGod.geopjae, TenGod.pyeongwan, 'geopjae_pyeongwan'],
      [TenGod.geopjae, TenGod.jeongjae, 'geopjae_jeongjae'],
      [TenGod.geopjae, TenGod.siksin, 'geopjae_siksin'],
      [TenGod.geopjae, TenGod.jeongin, 'geopjae_jeongin'],
      [TenGod.pyeonin, TenGod.jeongin, 'pyeonin_jeongin'],
    ];
    for (final pair in priorityPairs) {
      final a = pair[0] as TenGod;
      final b = pair[1] as TenGod;
      if ((freq[a] ?? 0) >= 1 && (freq[b] ?? 0) >= 1) {
        // 둘 중 한 명은 dominant 이거나 weighted score 높아야 우선.
        // weighted score = freq[a] + freq[b]
        final pairCount = (freq[a] ?? 0) + (freq[b] ?? 0);
        if (pairCount >= 2) {
          entry = pool[pair[2] as String] as Map<String, dynamic>?;
          if (entry != null) break;
        }
      }
    }

    // 2) dominant + secondary fallback
    if (entry == null && sec != null) {
      final domKey = _sipsinKey(dom);
      final secKey = _sipsinKey(sec);
      entry = (pool['${domKey}_$secKey'] as Map<String, dynamic>?) ??
          (pool['${secKey}_$domKey'] as Map<String, dynamic>?);
    }

    // 3) dominant 위주 fallback
    if (entry == null) {
      const groups = [
        TenGod.jeonggwan,
        TenGod.pyeongwan,
        TenGod.sanggwan,
        TenGod.siksin,
        TenGod.pyeonjae,
        TenGod.jeongjae,
        TenGod.jeongin,
        TenGod.pyeonin,
        TenGod.bigyeon,
        TenGod.geopjae,
      ];
      final domKey = _sipsinKey(dom);
      for (final g in groups) {
        if (g == dom) continue;
        if ((freq[g] ?? 0) < 1) continue;
        final gKey = _sipsinKey(g);
        entry = (pool['${domKey}_$gKey'] as Map<String, dynamic>?) ??
            (pool['${gKey}_$domKey'] as Map<String, dynamic>?);
        if (entry != null) break;
      }
    }

    entry ??= pool['_fallback'] as Map<String, dynamic>;
    return CareerRecommendation(
      primaryKo: entry['primaryKo'] as String,
      primaryEn: entry['primaryEn'] as String,
      noteKo: entry['noteKo'] as String,
      noteEn: entry['noteEn'] as String,
      careersKo: List<String>.from(entry['careersKo'] as List),
      careersEn: List<String>.from(entry['careersEn'] as List),
      dominantSipsin: dom,
      secondarySipsin: sec,
    );
  }

  static CareerRecommendation _fallback(Map<String, dynamic> pool) {
    final entry = pool['_fallback'] as Map<String, dynamic>;
    return CareerRecommendation(
      primaryKo: entry['primaryKo'] as String,
      primaryEn: entry['primaryEn'] as String,
      noteKo: entry['noteKo'] as String,
      noteEn: entry['noteEn'] as String,
      careersKo: List<String>.from(entry['careersKo'] as List),
      careersEn: List<String>.from(entry['careersEn'] as List),
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
