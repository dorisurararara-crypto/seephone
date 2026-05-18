// Pillar Seer — R90 sprint 3 LifeCategoryFragmentService.
//
// R89 결함 (사용자 verbatim):
//   "원래 사주는 일주로만 봐?? 내 사주가 곧 평생사주인데 왜 신묘일주만 말하지??"
//
// 같은 신묘 일주여도 본인 사주 anchor (월령 / 십성 / 격국 / 5행) 가 다르면 본문이
// 달라지도록, paragraph 본문에 결합할 1~2 fragment 를 동적으로 골라 반환.
//
// 5축 anchor (운세의신 사상 정합 — 일간 30 + 월령 25 + 십성 20 + 5행 20 + 격국 5):
//   1. 5행압도 = saju.elements.dominant (5)
//   2. 5행공허 = saju.elements.deficit (5)
//   3. 월령 = monthPillar.jiJi → 봄/여름/가을/겨울 (4)
//   4. 십성주력 = TenGodsService.tableFor(saju) 빈도 1위 (10)
//   5. 격국 = GyeokgukService.judge(dayMaster, monthJi).name (8)
//
// 카테고리 × anchor 매트릭스 (spec 2.5 sprint 5):
//   각 LifeCategory 에 anchor 2개씩 — fragment 2 개 결합.
//
// idempotent: 같은 사주 → 같은 fragment 순서.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'gyeokguk_service.dart';
import 'life_paragraph_service.dart' show LifeCategory;
import 'ten_gods_service.dart';

class LifeCategoryFragmentService {
  static const _path = 'assets/data/life_fragments.json';
  static Map<String, dynamic>? _cache;

  /// 카테고리 × anchor 매트릭스 (spec sprint 5).
  /// 어떤 카테고리에 어떤 anchor 2 개를 결합할지.
  static const Map<LifeCategory, List<String>> _matrix = {
    LifeCategory.earlyLife: ['월령', '5행압도'],
    LifeCategory.midLife: ['십성주력', '격국'],
    LifeCategory.lateLife: ['5행공허', '월령'],
    LifeCategory.health: ['5행압도', '5행공허'],
    LifeCategory.constitution: ['5행압도', '월령'],
    LifeCategory.social: ['십성주력', '5행압도'],
    LifeCategory.socialPersonality: ['격국', '십성주력'],
    LifeCategory.personality: ['십성주력', '5행압도'],
    LifeCategory.innateTendency: ['5행압도', '월령'],
    LifeCategory.innateCharacter: ['십성주력', '격국'],
    LifeCategory.loveFate: ['십성주력', '5행압도'],
    LifeCategory.affection: ['격국', '십성주력'],
    LifeCategory.wealth: ['격국', '십성주력'],
    LifeCategory.wealthGather: ['5행압도', '격국'],
    LifeCategory.wealthLossPrevent: ['십성주력', '5행공허'],
    LifeCategory.wealthInvest: ['5행압도', '격국'],
    LifeCategory.conclusionSelf: [], // LifeOverviewService 가 anchor 6 직접 빌드.
  };

  /// 한자 지지 → 계절.
  static const Map<String, String> _branchToSeason = {
    '寅': '봄', '卯': '봄', '辰': '봄',
    '巳': '여름', '午': '여름', '未': '여름',
    '申': '가을', '酉': '가을', '戌': '가을',
    '亥': '겨울', '子': '겨울', '丑': '겨울',
  };

  /// 격국 name (예: '정관격 (正官格)') → fragment key (예: '정관격').
  static String _gyeokgukKey(String name) {
    // 첫 ' (' 또는 '(' 앞까지.
    final idx = name.indexOf('(');
    if (idx > 0) return name.substring(0, idx).trim();
    final idx2 = name.indexOf(' ');
    if (idx2 > 0) return name.substring(0, idx2).trim();
    return name.trim();
  }

  /// TenGod enum → fragment key (예: TenGod.jeonggwan → '정관').
  static const Map<TenGod, String> _sipsinKey = {
    TenGod.bigyeon: '비견',
    TenGod.geopjae: '겁재',
    TenGod.siksin: '식신',
    TenGod.sanggwan: '상관',
    TenGod.pyeonjae: '편재',
    TenGod.jeongjae: '정재',
    TenGod.pyeongwan: '편관',
    TenGod.jeonggwan: '정관',
    TenGod.pyeonin: '편인',
    TenGod.jeongin: '정인',
  };

  /// JSON 풀 lazy load.
  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_path);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  /// 테스트 주입.
  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 캐시 reset.
  static void resetCache() {
    _cache = null;
  }

  /// 사주 → 5축 anchor key 추출.
  static Map<String, String> anchorsFor(SajuResult saju) {
    // 1. 5행 dominant / deficit.
    final dom = saju.elements.dominant;
    final def = saju.elements.deficit;

    // 2. 월령 계절.
    final season = _branchToSeason[saju.monthPillar.jiJi] ?? '봄';

    // 3. 십성주력 = saju 8글자 (또는 6글자 hourPillar null) 의 십신 빈도 1위.
    final rows = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final r in rows) {
      if (r.chunGanGod != null) {
        freq[r.chunGanGod!] = (freq[r.chunGanGod!] ?? 0) + 1;
      }
      if (r.jiJiGod != null) {
        freq[r.jiJiGod!] = (freq[r.jiJiGod!] ?? 0) + 1;
      }
    }
    TenGod? topGod;
    int topCount = 0;
    // deterministic — TenGod enum 순서 tie-breaker (작은 ordinal 우선).
    for (final g in TenGod.values) {
      final c = freq[g] ?? 0;
      if (c > topCount) {
        topCount = c;
        topGod = g;
      }
    }
    final sipsin = topGod != null ? (_sipsinKey[topGod] ?? '비견') : '비견';

    // 4. 격국.
    final gye = GyeokgukService.judge(
      dayMaster: saju.dayMaster,
      monthJi: saju.monthPillar.jiJi,
    );
    final gyeKey = _gyeokgukKey(gye.name);

    return {
      '5행압도': dom,
      '5행공허': def,
      '월령': season,
      '십성주력': sipsin,
      '격국': gyeKey,
    };
  }

  /// 사주 + 카테고리 → fragment 1~2 list.
  ///
  /// idempotent — saju anchor 가 같으면 같은 fragment 순서.
  /// fragment variation pick = saju.pillarsText hash % len (deterministic).
  static Future<List<String>> fragmentsFor({
    required SajuResult saju,
    required LifeCategory category,
    String? gender,
  }) async {
    final axes = _matrix[category] ?? [];
    if (axes.isEmpty) return [];

    final pool = await _pool();
    final anchors = anchorsFor(saju);

    // hash seed — 같은 사주 동일 출력.
    final seed = saju.pillarsText.codeUnits
        .fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);

    final out = <String>[];
    for (int i = 0; i < axes.length; i++) {
      final axis = axes[i];
      final anchorKey = anchors[axis];
      if (anchorKey == null) continue;
      final axisMap = pool[axis];
      if (axisMap is! Map) continue;
      final variants = axisMap[anchorKey];
      if (variants is! List || variants.isEmpty) continue;
      // category 별 다른 variation 을 pick 하도록 i + seed mix.
      final idx = (seed + i * 7 + category.index * 13) % variants.length;
      final picked = variants[idx];
      if (picked is String && picked.trim().isNotEmpty) out.add(picked);
    }
    return out;
  }
}
