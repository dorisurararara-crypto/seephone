// Pillar Seer — R110 Sprint 2: 무료/프리미엄 경계 정책 (단일 ground truth).
//
// monetization_playbook.md §"무료 / 프리미엄 경계 (9개 기능)" 를 코드로 옮긴
// 것. 게이트가 걸리는 곳은 모두 이 파일을 참조해, 경계가 한 곳에서만 정의된다.
//
// ── playbook 무료 핵심 5 vs legacy 17카테고리 매핑 (R110 Sprint 2 REWORK) ──
//
// playbook ① "무료 5" 는 한 카테고리 묶음이 아니라 "나는 어떤 사람인가" 라는
// 무료 체험의 *완결 묶음* 이다:
//   핵심 성향 · 오행 균형 · 십신 성향 · 강점/주의점 · 오늘 바로 써먹는 조언.
//
// 이 무료 핵심 5는 result_screen 상단 무료 모듈들이 *함께* 충족한다:
//   - 오행 균형      → `_FiveElementsSection` (PremiumGate 밖, 무료)
//   - 오행/강약/용신  → `_ChartAttributesSection` (PremiumGate 밖, 무료)
//   - 핵심 성향·강점/주의점·오늘 조언
//                    → `_MySajuV5Section` + `_ForYouTodaySection`
//                      (헤드라인/강점/주의/오늘 CTA, PremiumGate 밖, 무료)
// 즉 무료 핵심 5는 한 화면 상단에서 모듈 합으로 제공되며, 아래 legacy 키
// Set 와 1:1 로 동일하지 *않다*.
//
// 한편 result_screen 의 `kR88LifeCategories` 17 키는 R88 부터 쓰던 *인생 영역*
// 분류(초년/중년/말년/건강/체질/사회/성격/성향/이성/애정/재물 4종/결론)다.
// 이 legacy 17카테고리에도 playbook 비율(무료 5 / 프리미엄 12)을 적용해야
// 하는데, 명칭이 playbook 무료 5와 1:1 로 일치하지 않으므로 *의도* 기준으로
// 가른다:
//   playbook 무료 5 의도   = "나는 어떤 사람인가"(정체성·성향),
//   playbook 프리미엄 12 의도 = "내 인생 영역들"(시기·돈·관계 등 삶의 영역).
// 그 의도대로 legacy 키를 free/premium 으로 분류한다:
//   legacy 무료 5 (= 정체성/성향 카테고리. playbook 무료 5의 "성향" 결을
//                  legacy 카테고리 층위에서 대표하는 5개일 뿐, 위 무료
//                  핵심 5 모듈과 동일물이 아니다):
//            personality(성격운) · social_personality(사회적 성격) ·
//            innate_tendency(타고난 성향) · innate_character(타고난 인품) ·
//            social(사회운)
//   legacy 프리미엄 12 (= 인생 영역 카테고리):
//            early_life · mid_life · late_life · health · constitution ·
//            love_fate · affection · wealth · wealth_gather ·
//            wealth_loss_prevent · wealth_invest · conclusion_self
// `conclusion_self` 는 result_screen 에서 별도 `_SelfConclusionCard` 로
// 렌더되며 playbook 의 "깊은 종합 결론"(프리미엄) 에 해당한다.
//
// legacy 무료 5 + legacy 프리미엄 12 = 17 — playbook 비율(5/12)을 그대로
// 만족한다.

/// 내 사주 *legacy 17카테고리* 중 무료 공개 5개 categoryKey.
/// (result_screen.dart `kR88LifeCategories` 의 key 와 동일 문자열.)
/// 주의: 이 5개는 playbook "무료 핵심 5"(오행/십신/오늘 조언 등)와 동일물이
/// 아니라, legacy 카테고리 층위에서 "성향" 결을 대표하는 5개다. playbook
/// 무료 핵심 5는 화면 상단 무료 모듈(_FiveElements / _ChartAttributes /
/// _MySajuV5 / _ForYouToday)이 함께 충족한다.
const Set<String> kFreeMySajuCategoryKeys = {
  'personality', // 성격운
  'social_personality', // 사회적 성격
  'innate_tendency', // 타고난 성향
  'innate_character', // 타고난 인품
  'social', // 사회운
};

/// 주어진 내 사주 categoryKey 가 무료 공개 대상인지.
bool isFreeMySajuCategory(String categoryKey) =>
    kFreeMySajuCategoryKeys.contains(categoryKey);

/// 깊은 종합 결론(`_SelfConclusionCard`) 은 프리미엄 — playbook §① "깊은 종합 결론".
const bool kSelfConclusionIsPremium = true;
