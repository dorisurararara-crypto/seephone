// Pillar Seer — R88 sprint 4 LifeParagraphService.
//
// 운세의신 17 카테고리 인생 분류 paragraph lookup. LifeCategory enum 17 entry =
//   13 일반 카테고리 (string) + 3 성별 분기 카테고리 (sub-object {M, F}) + 1 conclusion_self.
// 일주 1 종당 paragraph 총량 = 13 + 3 × 2 + 1 = 20 paragraph string.
//
// 갑자 fixture seed = 20 paragraph (sprint 5~7 에서 일주 60 + 성별 분기 batch 확장).
//
// 저장소: assets/data/life_paragraphs.json
//   schema:
//     {
//       "갑자": {
//         "early_life": "초년운 paragraph (해요체, 80~400자)",
//         "mid_life": "...",
//         ...
//         "innate_character": { "M": "...", "F": "..." },
//         "love_fate":        { "M": "...", "F": "..." },
//         "affection":        { "M": "...", "F": "..." },
//         "conclusion_self": "..."
//       },
//       "을축": { ... },
//       ...
//     }
//
// Sprint 4 fixture seed = 갑자 1 종 (sprint 5~7 에서 일주 60 + 성별 분기 batch 확장).
// gender null fallback = M paragraph 우선 (단순 결정, spec 2.2.b 채택).

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// R88 sprint 4 — 17 카테고리 + conclusion_self enum.
/// 카테고리 ordinal 은 운세의신 인생 분류 구조 + 사용자 mandate 의 화면 순서를 따름.
enum LifeCategory {
  earlyLife,
  midLife,
  lateLife,
  health,
  constitution,
  social,
  socialPersonality,
  personality,
  innateTendency,
  innateCharacter, // 성별 분기
  loveFate, // 성별 분기
  affection, // 성별 분기
  wealth,
  wealthGather,
  wealthLossPrevent,
  wealthInvest,
  conclusionSelf,
}

/// LifeCategory → JSON key 매핑.
String lifeCategoryKey(LifeCategory cat) {
  switch (cat) {
    case LifeCategory.earlyLife:
      return 'early_life';
    case LifeCategory.midLife:
      return 'mid_life';
    case LifeCategory.lateLife:
      return 'late_life';
    case LifeCategory.health:
      return 'health';
    case LifeCategory.constitution:
      return 'constitution';
    case LifeCategory.social:
      return 'social';
    case LifeCategory.socialPersonality:
      return 'social_personality';
    case LifeCategory.personality:
      return 'personality';
    case LifeCategory.innateTendency:
      return 'innate_tendency';
    case LifeCategory.innateCharacter:
      return 'innate_character';
    case LifeCategory.loveFate:
      return 'love_fate';
    case LifeCategory.affection:
      return 'affection';
    case LifeCategory.wealth:
      return 'wealth';
    case LifeCategory.wealthGather:
      return 'wealth_gather';
    case LifeCategory.wealthLossPrevent:
      return 'wealth_loss_prevent';
    case LifeCategory.wealthInvest:
      return 'wealth_invest';
    case LifeCategory.conclusionSelf:
      return 'conclusion_self';
  }
}

/// 성별 분기 카테고리 set — JSON 안에서 {M, F} sub-object 로 저장.
const Set<LifeCategory> kGenderSplitCategories = {
  LifeCategory.innateCharacter,
  LifeCategory.loveFate,
  LifeCategory.affection,
};

class LifeParagraphService {
  static const _path = 'assets/data/life_paragraphs.json';
  static Map<String, dynamic>? _cache;

  /// 사용자 mandate (R88 spec sprint 4 verbatim) 호환 — `LifeParagraphService().paragraph(...)`.
  /// 인스턴스 method 와 static method 둘 다 동일 동작.
  const LifeParagraphService();

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

  /// 캐시 reset — test 격리 용.
  static void resetCache() {
    _cache = null;
  }

  /// 일주 + 카테고리 + 성별 → paragraph (instance method — spec mandate signature).
  ///
  /// [dayPillar] = '갑자' / '을축' / ... / '계해' (60 일주 한국어).
  /// [category] = LifeCategory enum (17 + conclusion_self).
  /// [gender] = 'M' or 'F' or null. 성별 분기 카테고리에서만 사용.
  ///   - null + 성별 분기 카테고리 = M paragraph fallback (spec 2.2.b 채택).
  ///   - 성별 분기 X 카테고리 + gender 전달 = gender 무시.
  ///
  /// 일주 없음 → ''. 카테고리 없음 → ''.
  Future<String> paragraph({
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) =>
      paragraphStatic(
          dayPillar: dayPillar, category: category, gender: gender);

  /// Static 변형 — 합성 service (LifeOverviewService / SelfConclusionService) 가
  /// 자체 lookup 시 instance 인자 없이 호출 가능.
  static Future<String> paragraphStatic({
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) async {
    final pool = await _pool();
    return lookup(pool,
        dayPillar: dayPillar, category: category, gender: gender);
  }

  /// 동기 lookup — pool map 을 직접 인자로 받음 (LifeOverviewService / SelfConclusionService 합성 용).
  ///
  /// R88 sprint 5 fallback chain:
  ///   1. 일주 60 정확 매칭 (예: '갑자') → paragraph 반환.
  ///   2. 일주 매칭 없음 + 일주 첫 글자 (일간) base 매칭 (예: '갑') → 일간 base paragraph 반환.
  ///   3. 둘 다 없음 → ''.
  /// 일간 fallback 은 sprint 5 의 핵심 — 일주 60 batch (sprint 6) 완성 전에도 service 작동 보장.
  static String lookup(
    Map<String, dynamic> pool, {
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) {
    final key = lifeCategoryKey(category);
    // 1. 일주 60 정확 매칭.
    final exact = pool[dayPillar];
    if (exact is Map) {
      final raw = exact[key];
      if (raw != null) {
        return _extract(raw, category: category, gender: gender);
      }
    }
    // 2. 일간 fallback — 일주 첫 글자 (예: '갑자' → '갑').
    if (dayPillar.isNotEmpty) {
      final stem = dayPillar.substring(0, 1);
      final stemEntry = pool[stem];
      if (stemEntry is Map) {
        final raw = stemEntry[key];
        if (raw != null) {
          return _extract(raw, category: category, gender: gender);
        }
      }
    }
    // 3. 매칭 없음.
    return '';
  }

  /// raw value 에서 gender 분기 적용 후 string 반환.
  /// raw 가 String 또는 Map {M, F} 둘 다 대응.
  static String _extract(
    Object raw, {
    required LifeCategory category,
    String? gender,
  }) {
    if (raw is String) return raw;
    if (raw is! Map) return raw.toString();
    // raw is Map — 성별 분기 sub-object {M, F} 가정.
    if (gender == 'F' && raw.containsKey('F')) {
      return (raw['F'] ?? '').toString();
    }
    // gender null / 'M' / 다른 값 → M fallback (spec 2.2.b).
    if (raw.containsKey('M')) return (raw['M'] ?? '').toString();
    return '';
  }

  /// 일주가 DB 에 있는지.
  static Future<bool> hasDayPillar(String dayPillar) async {
    final pool = await _pool();
    return pool.containsKey(dayPillar);
  }

  /// DB 에 있는 모든 일주 list.
  static Future<List<String>> availableDayPillars() async {
    final pool = await _pool();
    return pool.keys.toList();
  }
}
