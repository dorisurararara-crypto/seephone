// Pillar Seer — R90 sprint 2 LifeParagraphService (시그니처 확장).
//
// 운세의신 17 카테고리 인생 분류 paragraph lookup. LifeCategory enum 17 entry =
//   13 일반 카테고리 (string) + 3 성별 분기 카테고리 (sub-object {M, F}) + 1 conclusion_self.
// 일주 1 종당 paragraph 총량 = 13 + 3 × 2 + 1 = 20 paragraph string.
//
// R88 sprint 4 ~ R89 까지 = `paragraphStatic({dayPillar, category, gender})` 단일 signature.
//
// R89 결함 (사용자 verbatim):
//   "원래 사주는 일주로만 봐?? 내 사주가 곧 평생사주인데 왜 신묘일주만 말하지??"
//   → 같은 신묘 일주여도 다른 사주 anchor (월령/십성/격국/5행) 가 다르면 본문도 달라야 함.
//
// R90 sprint 2 새 signature (사용자 mandate):
//   `paragraph({saju: SajuResult, category, gender})` — SajuResult 전체 받음.
//   내부에서 base paragraph (sprint 1 prefix 제거된 60 일주 DB)
//     + fragment 1~2 (LifeCategoryFragmentService sprint 3) 결합.
//
// 호환성:
//   - 기존 `paragraphStatic({dayPillar, ...})` = deprecated 표시 + 그대로 작동 (base 만 반환).
//   - 모든 caller (LifeOverviewService / SelfConclusionService / result_screen) 는
//     sprint 5 sweep 에서 새 signature 로 마이그레이션.
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
// gender null fallback = M paragraph 우선 (단순 결정, spec 2.2.b 채택).

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'life_category_fragment_service.dart';
import 'natural_prose_joiner.dart';

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

  /// 일주 + 카테고리 + 성별 → paragraph (R88 호환 instance method).
  ///
  /// **R90 sprint 2**: 새 코드는 `paragraphForSaju(saju: ..., category: ...)`
  /// (사주 anchor 5축 fragment injection) 사용 권장.
  /// 이 method 는 R88/R89 test 호환성 유지를 위해 보존 — base lookup 만, fragment X.
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
      paragraphStatic(dayPillar: dayPillar, category: category, gender: gender);

  /// **R90 sprint 2 — 새 메인 method (사주 전체 + fragment injection)**.
  ///
  /// 사주 전체 + 카테고리 + 성별 → paragraph + anchor fragment 1~2 결합.
  ///
  /// 동작:
  ///   1. base paragraph = sprint 1 prefix 제거된 60 일주 DB lookup
  ///      (일주 정확 → 일간 fallback chain — 기존 R88 룰 보존).
  ///   2. fragment 1~2 = `LifeCategoryFragmentService.fragmentsFor(saju, category, gender)`
  ///      (사주 anchor 5축 — 5행압도/5행공허/월령/십성주력/격국 매트릭스).
  ///   3. 결합 = "$base $fragment1 $fragment2" (공백 1칸 join, 마침표 정합).
  ///
  /// 핵심: 같은 일주여도 사주 anchor 조합이 다르면 fragment 셋이 달라져 본문 차별화.
  ///
  /// 호출자 패턴 (sprint 5 sweep):
  /// - result_screen._CategorySectionCard → 이 method
  /// - LifeOverviewService.compose → anchor 6 직접 빌드 (이 method 미사용)
  /// - SelfConclusionService.conclude → 이 method 로 conclusion_self lookup
  Future<String> paragraphForSaju({
    required SajuResult saju,
    required LifeCategory category,
    String? gender,
  }) async {
    final dayPillarKo = _dayPillarKo(saju);
    final base = await paragraphStatic(
      dayPillar: dayPillarKo,
      category: category,
      gender: gender,
    );
    if (base.isEmpty) return '';
    final fragments = await LifeCategoryFragmentService.fragmentsFor(
      saju: saju,
      category: category,
      gender: gender,
    );
    return _mergeFragments(base, fragments);
  }

  /// `paragraphForSaju` 의 정적 alias — 헬퍼 service 가 인스턴스 없이 호출 가능.
  static Future<String> paragraphForSajuStatic({
    required SajuResult saju,
    required LifeCategory category,
    String? gender,
  }) => const LifeParagraphService().paragraphForSaju(
    saju: saju,
    category: category,
    gender: gender,
  );

  /// 기존 일주 단독 anchor signature (R88 호환).
  ///
  /// R90 사주 anchor 다층화 mandate 후로는 가능한 한 `paragraphForSajuStatic` 사용 권장.
  /// 이 method 는 LifeOverviewService 가 anchor 6 직접 빌드 시 base 본문 lookup 용으로
  /// 여전히 필요 (fragment 는 LifeOverviewService 가 별도 mount).
  static Future<String> paragraphStatic({
    required String dayPillar,
    required LifeCategory category,
    String? gender,
  }) async {
    final pool = await _pool();
    return lookup(
      pool,
      dayPillar: dayPillar,
      category: category,
      gender: gender,
    );
  }

  /// SajuResult → '신묘' 같은 한글 일주 key.
  static String _dayPillarKo(SajuResult saju) {
    const stemKo = {
      '甲': '갑',
      '乙': '을',
      '丙': '병',
      '丁': '정',
      '戊': '무',
      '己': '기',
      '庚': '경',
      '辛': '신',
      '壬': '임',
      '癸': '계',
    };
    const branchKo = {
      '子': '자',
      '丑': '축',
      '寅': '인',
      '卯': '묘',
      '辰': '진',
      '巳': '사',
      '午': '오',
      '未': '미',
      '申': '신',
      '酉': '유',
      '戌': '술',
      '亥': '해',
    };
    final s = stemKo[saju.dayPillar.chunGan] ?? saju.dayPillar.chunGan;
    final b = branchKo[saju.dayPillar.jiJi] ?? saju.dayPillar.jiJi;
    return '$s$b';
  }

  /// base paragraph 끝에 fragment 1~2 를 자연스럽게 결합.
  ///
  /// 결합 룰 (spec sprint 5):
  /// - base 가 '. ' 또는 '요.' 로 끝나면 그대로 한 칸 공백 후 fragment join.
  /// - fragment 가 마침표로 끝나지 않으면 '.' 보강.
  static String _mergeFragments(String base, List<String> fragments) {
    if (fragments.isEmpty) return base;
    return NaturalProseJoiner.append(base, fragments);
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
