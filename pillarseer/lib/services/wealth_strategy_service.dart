// Pillar Seer — 재테크 전략 서비스 (Round 73 Sprint 6).
//
// 재성 분포 (편재/정재/혼합/없음) × 일간 강약 → 3 phase paragraph
// (모으는 법 / 손실 막는 법 / 재테크 비법).
//
// 운세의신 17 섹션 중 "재물 모으는 법 / 재물 손실 막는 법 / 재테크 비법" 3 섹션 매핑.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'strength_service.dart';
import 'ten_gods_service.dart';

class WealthStrategy {
  /// 모으는 법 한글.
  final String accumKo;

  /// 모으는 법 영문.
  final String accumEn;

  /// 손실 막는 법 한글.
  final String lossKo;

  /// 손실 막는 법 영문.
  final String lossEn;

  /// 재테크 비법 한글.
  final String techKo;

  /// 재테크 비법 영문.
  final String techEn;

  /// 매핑 key (디버깅용 — 예: "pyeonjae_strong").
  final String matchKey;

  const WealthStrategy({
    required this.accumKo,
    required this.accumEn,
    required this.lossKo,
    required this.lossEn,
    required this.techKo,
    required this.techEn,
    required this.matchKey,
  });
}

class WealthStrategyService {
  static const _path = 'assets/data/wealth_detail.json';
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

  /// 사주 → 재테크 3 phase paragraph.
  static Future<WealthStrategy> compute(SajuResult saju) async {
    final pool = await _pool();

    // 1) 재성 (편재/정재) 빈도 계산
    final table = TenGodsService.tableFor(saju);
    int pyeonjaeCount = 0;
    int jeongjaeCount = 0;
    for (final row in table) {
      if (row.chunGanGod == TenGod.pyeonjae) pyeonjaeCount++;
      if (row.chunGanGod == TenGod.jeongjae) jeongjaeCount++;
      if (row.jiJiGod == TenGod.pyeonjae) pyeonjaeCount++;
      if (row.jiJiGod == TenGod.jeongjae) jeongjaeCount++;
    }

    // 2) wealthGod 분류
    String wealthGod;
    if (pyeonjaeCount > 0 && jeongjaeCount > 0) {
      wealthGod = 'mixed';
    } else if (pyeonjaeCount > 0) {
      wealthGod = 'pyeonjae';
    } else if (jeongjaeCount > 0) {
      wealthGod = 'jeongjae';
    } else {
      wealthGod = 'none';
    }

    // 3) 일간 강약 — StrengthService.judge
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
    final isStrong = strength.label == '신강' ||
        strength.label == '신왕' ||
        strength.label == '중화';
    final strengthKey = isStrong ? 'strong' : 'weak';

    final matchKey = '${wealthGod}_$strengthKey';
    final entry = (pool[matchKey] as Map<String, dynamic>?) ??
        (pool['none_$strengthKey'] as Map<String, dynamic>?) ??
        (pool['none_strong'] as Map<String, dynamic>);

    return WealthStrategy(
      accumKo: entry['accumKo'] as String,
      accumEn: entry['accumEn'] as String,
      lossKo: entry['lossKo'] as String,
      lossEn: entry['lossEn'] as String,
      techKo: entry['techKo'] as String,
      techEn: entry['techEn'] as String,
      matchKey: matchKey,
    );
  }
}
