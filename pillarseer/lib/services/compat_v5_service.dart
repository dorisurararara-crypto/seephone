// Pillar Seer — Round 106 (P4a rewrite) — 궁합 카피 v5 voice 전면 재작성기.
//
// R106 design doc §2 / §3 / §9 ground truth:
//  - 궁합(일반·최애)도 v5 톤으로 전환한다: 자연어 + 단정 금지 + 심리.
//  - v5 궁합 voice = 「두 사주의 관계가 무엇인지(합·충·삼합·형·상생·상극·비화·중립)
//    + 그게 관계에서 어떻게 작동하기 쉬운지(경향) + 어떻게 다루면 좋은지(조언)」.
//  - 절대 금지: 관계 결과·미래 단정 / 상대·나의 변화 단정 / 자녀·결혼 결과 단정 /
//    운명 voice / 사주·chart 메타. (codex 검수 위반유형 A~E)
//  - 허용: 실제 관계 anchor 사실, 경향(헷지: ~기 쉬운 자리), 조건(만약 ~하면), 조언.
//  - QA 기준: 두 사람 관계가 그날·앞으로 어떻든 틀린 문장이 0.
//
// 본 service 는 presentation layer only — 궁합 계산 엔진(합·충·오행·십신 anchor)의
// 산출물을 1 bit 도 건드리지 않는다. 두 궁합 screen 의 모든 궁합 카피 본문
// (compatibility_screen `_analyze`, kpop_compat `_composeVerdict`)이 합성 마지막
// 단계에서 전부 이 normalizer 를 통과한다 — 즉 모든 fragment 가 출력 시점에 v5
// voice 로 재작성된다. 두 사주의 실제 관계 anchor(합·충·오행·일주)는 보존되고,
// 관계 결과·미래를 단정하던 표현만 경향(헷지)·구조·조언형으로 전환된다.
//
// 거짓말 0: 정규화는 단정 → 경향/조건형 치환만 한다. 없는 anchor 를 만들지 않는다.
// 멱등: 이미 v5 voice 인 본문은 변형되지 않는다.
//
// 회귀: r106_compat_v5_test 가 출력 본문에 위반유형 A~E 0 을 lock 한다. R100
// compat_repetition / R101 celeb_compat_uses_analyze 가드는 정규화가 anchor
// 어휘(합·충·오행·일주)와 element-relation 변별 구조를 보존하므로 회귀 0.

/// 궁합 v5 voice 정규화기.
///
/// `soften` 은 KO/EN 궁합 본문을 받아 v5 룰 위반 표현(관계 결과·미래 단정, 변화
/// 단정, 운명 voice, 메타)을 경향·구조·조언형으로 전환한 본문을 돌려준다.
/// 순수 함수 — 같은 입력은 항상 같은 출력. 외부 상태·랜덤 없음.
class CompatV5Service {
  CompatV5Service._();

  // ── 한국어 regex 치환 규칙 ────────────────────────────────────────────────
  //
  // 각 항목: [패턴(RegExp), 치환문]. 단정/메타 표현을 v5 경향·조건·조언형으로
  // 바꾼다. 두 사주의 실제 관계(합·충·오행)는 그대로 두고, "관계가 그렇게 된다"는
  // 단정 voice 만 "그렇게 작동하기 쉬운 자리다 / 그렇게 다루면 좋다" 로 전환한다.
  // 긴 패턴이 먼저 와야 안전한 곳은 리스트 앞쪽에 둔다.
  static final List<List<dynamic>> _koRules = <List<dynamic>>[
    // ───── 위반유형 D — 운명 voice ─────
    [RegExp(r'운명 같은 끌림이지만'), '끌림이 강한 결이지만'],
    [RegExp(r'운명 같은 끌림'), '강하게 끌리기 쉬운 결'],
    [RegExp(r'운명 같지만'), '깊게 통하기 쉬운 자리지만'],
    [RegExp(r"처음엔 '운명' 같지만"), '처음엔 깊게 통하기 쉽지만'],
    [RegExp(r'운명적인 끌림 신호가 비어 있는'), '직접 걸린 끌림 anchor 가 비어 있는'],
    [RegExp(r'운명적인 끌림보다'), '저절로 끌리는 힘보다'],
    [RegExp(r'운명에 기대기보다'), '저절로 흘러가게 두기보다'],
    [RegExp(r'운명에 기대지'), '저절로 흘러가게 두지'],
    [RegExp(r'운명적이라기보다'), '저절로 묶이는 결이라기보다'],
    [RegExp(r'운명적 끌림'), '저절로 생기는 끌림'],
    [RegExp(r'운명을 대신해서'), '둘 사이를 대신해서'],
    [RegExp(r'운명 같은'), '깊게 통하기 쉬운'],

    // ───── 위반유형 A — 관계 결과·미래 단정 ─────
    // "헤어졌을 때의 잔상" 류 (이별 미래 단정, §3-7).
    [
      RegExp(r'첫 인상이 깊게 새겨지는 만큼 헤어졌을 때의 잔상도 길어요\. 그래서 시작 단계에서 너의 기준을 또렷이 가지고 가는 게 안전망이에요\.'),
      '첫 인상이 깊게 새겨지기 쉬운 결이라, 시작 단계에서 너의 기준을 또렷이 정해두면 나중에 흔들릴 일이 줄어요.',
    ],
    [
      RegExp(r'헤어졌다가 다시 만나는 사이클이 평균보다 잘 일어나요\. 한 번 끝낸 결정은 적어도 6개월은 묵히는 둘만의 룰이 도움돼요\.'),
      '한 번 정한 걸 다시 뒤집고 싶어지기 쉬워요. 큰 결정은 한 번 정하면 적어도 6개월은 묵혀보는 둘만의 룰을 두면 흔들림이 줄어요.',
    ],
    [
      RegExp(r'외부 충격\(이별·이사·진로 변화\) 앞에서는 관계가 흔들리기 쉬워요\. 그런 시즌엔 평소보다 두 배 자주 안부를 묻는 게 보호예요\.'),
      '큰 변화(이사·진로 같은 외부 사건)가 겹치는 시기엔 둘 사이 거리가 벌어지기 쉬워요. 그런 시기일수록 평소보다 자주 안부를 챙기면 거리가 안 벌어져요.',
    ],
    [
      RegExp(r'큰 사건\(이별·이사·진로 변화\) 앞에서는 서로의 자리가 멀어지기 쉬우니'),
      '큰 변화(이사·진로 같은 외부 사건)가 겹치는 시기엔 서로의 자리가 멀어지기 쉬우니까',
    ],
    // "행복할수록 상대도 행복" 류 (행복 미래 단정).
    [
      RegExp(r'네가 행복할수록 상대도 행복해진다는 신호예요\. 그러니 둘의 행복을 위해서라도 너 자신의 행복을 최우선에 두는 게 정답이에요\.'),
      '네 컨디션이 곧 상대 자리로도 이어지기 쉬워요. 그러니 둘 사이를 위해서라도 너 자신을 먼저 챙기는 게 좋은 출발점이에요.',
    ],

    // ── 관계가 "된다"는 단정 → 경향(~기 쉬운 자리/~하기 좋은 자리) ──
    // "시간이 지날수록 점점 진해진다" / "갈수록 ~해진다" 류.
    [RegExp(r'시간이 지날수록 점점 진해진다는 점이에요'), '시간을 들이면 결이 진해지기 좋은 자리예요'],
    [RegExp(r'시간이 갈수록 단단해지는 결이에요'), '시간을 들이면 단단해지기 좋은 결이에요'],
    [RegExp(r'시간이 갈수록 단단해지는 결'), '시간을 들이면 단단해지기 좋은 결'],
    [RegExp(r'시간이 갈수록 깊어지는 사이'), '시간을 들이면 깊어지기 좋은 사이'],
    [RegExp(r'시간이 갈수록 그 결이 더 또렷해져요'), '시간을 들이면 그 결이 또렷해지기 좋아요'],
    [RegExp(r'시간이 흐를수록 깊이가 쌓이는 결이에요'), '시간을 들이면 깊이가 쌓이기 좋은 결이에요'],
    [RegExp(r'시간이 흐를수록 잔잔한 깊이가 쌓여요'), '시간을 들이면 잔잔한 깊이가 쌓이기 좋아요'],
    [RegExp(r'시간이 쌓일수록 천천히 깊어지는 결'), '시간을 들이면 천천히 깊어지기 좋은 결'],
    [RegExp(r'시간이 쌓이면 누구도 못 깨는 결이 되지만'), '시간을 들이면 단단해지기 좋은 결이지만'],
    [RegExp(r'누구도 못 깨는 인연으로 굳어요'), '단단한 인연으로 자리잡기 좋아요'],
    [RegExp(r'누구도 못 깨는'), '단단한'],
    [RegExp(r'시간이 갈수록 점점 진해져요'), '시간을 들이면 진해지기 좋아요'],
    [RegExp(r'시간이 갈수록 진해지는 사랑'), '시간을 들이면 진해지기 좋은 사랑'],
    [RegExp(r'시간이 흐를수록 깊어지는 자리'), '시간을 들이면 깊어지기 좋은 자리'],
    [RegExp(r'시간이 쌓일수록 천천히 깊어지는'), '시간을 들이면 천천히 깊어지기 좋은'],
    [RegExp(r'천천히 깊어지는 결이라'), '천천히 깊어지기 좋은 결이라'],

    // "단단해져요 / 깊어져요 / 자라요" 단순 종결 단정.
    [RegExp(r'관계가 훨씬 단단해져요'), '관계를 단단하게 가져가는 데 도움돼요'],
    [RegExp(r'관계가 한 단계 더 자라요'), '관계가 한 단계 자라는 데 도움돼요'],
    [RegExp(r'관계가 더 단단해져요'), '관계를 단단하게 가져가는 데 도움돼요'],
    [RegExp(r'결이 훨씬 단단해져요'), '결을 단단하게 가져가는 데 도움돼요'],
    [RegExp(r'결이 더 단단해져요'), '결을 단단하게 가져가는 데 도움돼요'],
    [RegExp(r'관계가 한 단계 깊어져요'), '관계를 한 단계 깊게 가져가는 데 도움돼요'],
    [RegExp(r'더 건강하게 자라요'), '건강하게 가져가는 데 도움돼요'],
    [RegExp(r'관계가 자연스레 멀어져요'), '둘 사이 거리가 벌어지기 쉬워요'],
    [RegExp(r'관계가 자연스럽게 멀어져요'), '둘 사이 거리가 벌어지기 쉬워요'],
    [RegExp(r'자연스럽게 거리가 벌어져요'), '거리가 벌어지기 쉬워요'],
    [RegExp(r'거리가 그대로 벌어져요'), '거리가 벌어지기 쉬워요'],
    [RegExp(r'관계가 그대로 멈춰요'), '관계가 그대로 멈추기 쉬워요'],
    [RegExp(r'결혼 생활이 훨씬 안정돼요'), '결혼 생활을 안정되게 가져가는 데 도움돼요'],
    [RegExp(r'결혼이 단단해져요'), '결혼을 단단하게 가져가는 데 도움돼요'],

    // 다툼·갈등 결과 단정.
    [RegExp(r'충돌 빈도가 절반으로 줄어요'), '충돌이 큰 다툼으로 잘 안 번지게 하는 데 도움돼요'],
    [RegExp(r'큰 다툼 빈도가 절반 이하로 줄어요'), '큰 다툼으로 잘 안 번지게 하는 데 도움돼요'],
    [RegExp(r'부딪힘 빈도가 절반 이하로 줄어요'), '부딪힘이 잘 안 번지게 하는 데 도움돼요'],
    [RegExp(r'갈등이 줄어요'), '갈등을 줄이는 데 도움돼요'],
    [RegExp(r'갈등이 평이해져요'), '갈등을 평이하게 가져가는 데 도움돼요'],
    [RegExp(r'다툼이 안 와요'), '다툼이 잘 안 번져요'],
    [RegExp(r'다툼이 거의 사라져요'), '다툼이 잘 안 번지는 데 도움돼요'],
    [RegExp(r'작은 다툼은 거의 사라져요'), '작은 다툼이 잘 안 번지는 데 도움돼요'],
    [RegExp(r'큰 다툼으로 안 가요'), '큰 다툼으로 잘 안 번지는 데 도움돼요'],
    [RegExp(r'큰 다툼으로 잘 안 번져요'), '큰 다툼으로 잘 안 번지는 데 도움돼요'],
    [RegExp(r'큰 갈등으로 잘 안 번져요'), '큰 갈등으로 잘 안 번지는 데 도움돼요'],
    [RegExp(r'큰 충돌로 잘 안 번져요'), '큰 충돌로 잘 안 번지는 데 도움돼요'],
    [RegExp(r'큰 단절로 안 갑니다'), '큰 단절로 잘 안 가는 데 도움돼요'],
    [RegExp(r'큰 단절을 막아요'), '큰 단절을 막는 데 도움돼요'],
    [RegExp(r'큰 충돌을 막아요'), '큰 충돌을 막는 데 도움돼요'],
    [RegExp(r'큰 파열은 거의 사라져요'), '큰 파열이 잘 안 오는 데 도움돼요'],
    [RegExp(r'큰 위기를 미연에 막아요'), '큰 위기를 줄이는 데 도움돼요'],
    [RegExp(r'갈등 빈도가 올라가요'), '갈등 위험이 올라가기 쉬워요'],
    [RegExp(r'한 번에 폭발해요'), '한 번에 터지기 쉬워요'],
    [RegExp(r'갑자기 폭발하는 결이라'), '갑자기 한 번에 터지기 쉬워서'],
    [RegExp(r'큰 한 마디가 폭발해요'), '큰 한 마디가 터지기 쉬워요'],
    [RegExp(r'한 번씩 큰 한 마디가 터지기 쉬워요'), '한 번씩 큰 한 마디가 터지기 쉬워요'],
    [RegExp(r'의견이 자주 엇갈려요'), '의견이 엇갈리기 쉬워요'],

    // "오래 가요 / 길게 가요" 미래 단정.
    [RegExp(r'오래 가기 좋은 자리예요'), '오래 가기 좋게 다룰 수 있는 자리예요'],
    [RegExp(r'오래 가기 좋은 사랑'), '오래 가기 좋게 다룰 수 있는 사랑'],
    [RegExp(r'오래 단단하게 가기 좋아요'), '오래 단단하게 가져가기 좋아요'],
    [RegExp(r'관계가 유지돼요'), '관계를 이어가는 데 도움돼요'],
    [RegExp(r'관계 자연 소멸'), '둘 사이 거리'],
    [RegExp(r'자연 소멸돼요'), '거리가 벌어지기 쉬워요'],
    [RegExp(r'자연 소멸'), '거리가 벌어지기 쉬운 자리'],

    // ───── 위반유형 B — 상대·나의 변화 단정 ─────
    [RegExp(r'상대가 자라는 모습을 보면서 내가 더 단단해져요'), '상대가 한 걸음씩 가는 모습을 보면서 나도 든든해지기 쉬워요'],
    [RegExp(r'상대가 자라는 모습을 보면서 네가 더 단단해지는 관계예요'),
        '상대가 한 걸음씩 가는 모습을 보면서 너도 든든해지기 쉬운 관계예요'],
    [RegExp(r'네가 더 단단해지는 관계예요'), '너도 든든해지기 쉬운 관계예요'],
    [RegExp(r'상대가 자라는 모습'), '상대가 한 걸음씩 가는 모습'],
    [RegExp(r'자라는 모습을 보면서 내가 더 단단해져요'), '곁에 있는 모습을 보면서 나도 든든해지기 쉬워요'],
    [RegExp(r'한 단계씩 성장하는 모습을 보면서'), '한 걸음씩 가는 모습을 보면서'],
    [RegExp(r'한 단계씩 단단해지는 모습은'), '한 걸음씩 가는 모습은'],
    [RegExp(r'한 뼘씩 자라는 게 보일 거예요'), '한 뼘씩 가는 모습이 보이기 쉬워요'],
    [RegExp(r'상대가 자기 색을 찾아가니까'), '상대가 자기 색을 잡아가기 좋으니까'],
    [RegExp(r'네가 자라는 자리에'), '네가 한 걸음씩 가는 자리에'],
    [RegExp(r'결과물이 살아나요'), '결과물이 살아나기 좋아요'],
    // bare '자라는 모습' — 어떤 prefix 든 변화 단정 → 동행 묘사. 마지막에 둔다.
    [RegExp(r'자라는 모습'), '한 걸음씩 가는 모습'],
    [RegExp(r'내 결정이 정해져요'), '내 결정이 잡히기 좋아요'],
    [RegExp(r'능력을 펴요'), '능력을 펴기 좋아요'],

    // ───── 위반유형 C — 자녀·결혼 결과 단정 ─────
    [RegExp(r'자녀가 자기 결을 또렷이 가지는 결'), '자녀가 자기 결을 또렷이 잡아가기 좋은 자리'],
    [RegExp(r'자녀가 부모 두 사람의 결을 모두 흡수해서 단단한 자기 색을 가져요'),
        '자녀가 부모 두 사람의 결을 흡수해서 자기 색을 잡아가기 좋아요'],
    [RegExp(r"자녀가 '양쪽 모두에게 사랑받는 안정감' 을 자연스럽게 가져요"),
        "자녀가 '양쪽 모두에게 사랑받는 안정감' 을 갖기 좋은 자리예요"],
    [RegExp(r'자녀 두 사람 결을 자기 안에서 통합해 더 단단해져요'),
        '자녀가 부모 두 사람 결을 자기 안에서 통합해 가기 좋아요'],
    [RegExp(r'더 단단해져요'), '단단하게 가져가는 데 도움돼요'],

    // ───── 위반유형 E — 메타 (사주가/사주적으로) ─────
    [RegExp(r'사주가 가장 강하게 권하는 연애 결'), '두 사주가 가장 강하게 묶이는 연애 결'],
    [RegExp(r'사주적으로 결혼 잘 어울리는 결'), '결혼으로 가면 시간을 들여 단단해지기 좋은 결'],
    [RegExp(r'사주가 권하는 결혼 결'), '결혼으로 가면 잘 풀리기 좋은 결'],
    [RegExp(r"사주적으로 가장 강한 '동기' 결"), "둘이 가장 비슷한 '동기(同氣)' 결"],
    [RegExp(r'사주적으로 가장 안정적인 결'), '가장 안정적인 결'],
    [RegExp(r'사주적으로 자녀 운은'), '자녀 결은'],
    [RegExp(r'사주적으로'), '두 사람 결로 보면'],
    [RegExp(r'사주가 권하'), '두 사람 결이 권하'],

    // ── '정답' 단정 어휘 ──
    [RegExp(r'는 게 정답이에요\.'), '는 게 좋은 출발점이에요.'],
    [RegExp(r'룰이 정답이에요'), '룰이 도움돼요'],
    [RegExp(r'활용하는 게 정답이에요'), '활용하는 게 도움돼요'],
    [RegExp(r'정답인 만남'), '잘 다룰 수 있는 만남'],

    // ───── 일반 catch-all — 단정 verb 종결 → 경향·조언형 ─────
    // 위 구체 규칙이 먼저 흡수하고 남은 잔여 패턴을 generic 으로 마저 잡는다.
    // 핵심 단정 verb 종결 자체를 prefix 무관하게 경향형으로 전환한다.
    // 멱등: 치환문은 다시 매칭되지 않는 형태('~기 좋아요')로 둔다.
    [RegExp(r'관계가 비로소 자라요'), '관계가 한 걸음 나아가기 좋아요'],
    [RegExp(r'시기에 관계가 자라요'), '시기에 관계가 한 걸음 나아가기 좋아요'],
    [RegExp(r'둘 사이가 자라요'), '둘 사이가 한 걸음 나아가기 좋아요'],
    [RegExp(r'깊이가 한 단계 더 자라요'), '깊이를 한 단계 더 쌓아가는 데 도움돼요'],
    [RegExp(r'깊이가 커져요'), '깊이를 쌓아가기 좋아요'],
    [RegExp(r'시너지가 폭발해요'), '시너지가 크게 살아나기 쉬워요'],
    [RegExp(r'한쪽이 사라져요'), '한쪽이 자기 색을 잃기 쉬워요'],
    [RegExp(r'한쪽 색이 묻혀요'), '한쪽 색이 묻히기 쉬워요'],
    [RegExp(r'점점 작아져요'), '점점 움츠러들기 쉬워요'],
    [RegExp(r'점점 작아지기 쉬워요'), '점점 움츠러들기 쉬워요'],
    // bare verb 종결 — 어떤 prefix 뒤에 와도 경향형으로. 마지막에 둔다.
    [RegExp(r'단단해져요'), '단단하게 가기 좋아요'],
    [RegExp(r'깊어져요'), '깊어지기 좋아요'],
    [RegExp(r'진해져요'), '진해지기 좋아요'],
    [RegExp(r'또렷해져요'), '또렷해지기 좋아요'],
  ];

  // ── 영어 regex 치환 규칙 ──────────────────────────────────────────────────
  //
  // §8: 영어도 같은 v5 voice — 관계 결과·미래 단정 / 변화 단정 / 운명 voice /
  // chart·saju 메타 금지. 단정 verb 를 경향(tends to / is easy to)·조건·조언형으로.
  static final List<List<dynamic>> _enRules = <List<dynamic>>[
    // ───── 위반유형 D — fated / destined voice ─────
    [RegExp(r'the kind of pull that reads as fated'), 'a pull strong enough to feel sudden'],
    [RegExp(r'the kind of pull that feels fated'), 'a pull strong enough to feel sudden'],
    [RegExp(r'reads like a fated pull'), 'reads like a strong, fast pull'],
    [RegExp(r'a bond that can outlast many fated pairs'),
        'a bond that can run long when you tend it'],
    [RegExp(r"a free-flowing bond can outlast many more 'fated' ones"),
        'a free-flowing bond can run long when you tend it'],
    [RegExp(r'the bond outlasts many fated ones'),
        'the bond can run long when you tend it'],
    [RegExp(r'lets this bond outlast many fated ones'),
        'lets this bond run long when you tend it'],
    [RegExp(r'and the bond outlasts loud pairings simply because'),
        'and the bond can run long when you tend it, simply because'],
    [RegExp(r"reads as 'destined' more in year ten than year one"),
        "tends to feel steadier in year ten than year one"],
    [RegExp(r"reads as 'destined'"), 'reads as steady'],
    [RegExp(r"don't lean on fate"), "don't leave it to drift"],
    [RegExp(r"Don't lean on fate"), "Don't leave it to drift"],
    [RegExp(r'the chart throws fated-pull signals'), 'the chart carries direct pull anchors'],
    [RegExp(r"doesn't throw fated-pull signals"), 'carries no direct pull anchors'],
    [RegExp(r'step in for the chart and hold the bond'), 'step in and help hold the bond'],
    [RegExp(r'fated'), 'strongly drawn'],
    [RegExp(r'destined'), 'steady'],

    // ───── 위반유형 E — chart / saju 메타 (R106 P4a EN 재작성 backstop) ─────
    // EN 궁합 카피 corpus 는 from-scratch v5 voice 로 재작성됐다. 아래 backstop 은
    // 만약을 위한 최후 방어막 — source 에 위반이 한 줄도 없어야 정상.
    [RegExp(r'no anchor in the chart'), 'no direct stem-branch anchor between you'],
    [RegExp(r'No anchor in the chart'), 'No direct stem-branch anchor between you'],
    [RegExp(r'sits in a quiet zone of your chart'),
        'sits in a quiet zone relative to your day pillar'],
    [RegExp(r'as the third voice in the room'),
        'as a neutral third reference in the room'],
    [RegExp(r'How your chart receives it decides what the two of you become'),
        'How your day pillar receives it tends to shape what kind of bond the two of you build'],
    [RegExp(r'How your chart receives it'), 'How your day pillar receives it'],
    [RegExp(r'meets your chart'), 'meets your day pillar'],
    [RegExp(r'\byour chart\b'), 'your day pillar'],
    [RegExp(r'chart-side scaffolding'), 'built-in scaffolding'],
    [RegExp(r'chart-side reinforcement'), 'built-in reinforcement'],
    [RegExp(r'chart-side'), 'built-in'],
    [RegExp(r'a chart event'), 'something that happens on its own'],
    [RegExp(r'chart event'), 'something that happens on its own'],
    [RegExp(r'Free from any chart pull'), 'Free of any built-in pull'],
    [RegExp(r'free from any chart pull'), 'free of any built-in pull'],
    [RegExp(r'\bchart pull\b'), 'built-in pull'],
    [RegExp(r'firms up by chart signal too'), 'firms up here too'],
    [RegExp(r'reads steadier here too'), 'reads steadier here too'],
    [RegExp(r'stabilizes by chart tone too'), 'reads steadier here too'],
    // ───── 위반유형 A — EN 관계 결과·미래 단정 backstop ─────
    [RegExp(r'your influence will be visible in [^.]*? choices'),
        'your influence tends to show in their choices'],
    [RegExp(r'will be visible in'), 'tends to show in'],
    [RegExp(r'almost unbreakable once a few years pass'),
        'tends to firm up the more years you tend it'],
    [RegExp(r'almost unbreakable'), 'durable when you tend it'],
    [RegExp(r'a low mood lifts faster than it would alone'),
        'a low mood is often easier to lift than it would be alone'],
    [RegExp(r'lifts faster than it would alone'),
        'is often easier to lift than it would be alone'],
    [RegExp(r'mood lifts faster'), 'mood is often easier to lift'],
    [RegExp(r'grows fastest beside you'), 'tends to grow beside you'],
    [RegExp(r'grows fastest'), 'tends to grow'],
    [RegExp(r'The love grows only by choice'),
        'A neutral love tends to grow by choice'],
    [RegExp(r'the love grows only by choice'),
        'a neutral love tends to grow by choice'],
    [RegExp(r'closeness grows only by choice'),
        'closeness tends to grow by choice'],
    [RegExp(r'grows only by choice'), 'tends to grow by choice'],
    [RegExp(r'keep beside you for life'), 'keep close for a long time'],
    [RegExp(r'\bfor life\b'), 'for a long time'],
    [RegExp(r'closeness grows the more time you share'),
        'closeness tends to build the more time you share'],
    [RegExp(r'Distance dilutes it; presence concentrates it'),
        'presence tends to concentrate it; distance tends to dilute it'],
    [RegExp(r'\bdecides what the two of you become'),
        'tends to shape what kind of bond the two of you build'],
    [RegExp(r'decides what .{0,40}? become'),
        'tends to shape what kind of bond forms'],
    [RegExp(r'\$n stops voicing opinions'), 'the other person tends to hold opinions back'],
    [RegExp(r'stops voicing opinions'), 'tends to hold opinions back'],
    // ───── 위반유형 C — EN 자녀 결과 단정 backstop ─────
    [RegExp(r'Children absorb the parental harmony[^.]*\.'),
        'A steady parental tone tends to give children a calm relationship climate to grow around.'],
    [RegExp(r'children inherit that ease'),
        'a steady tone tends to give children a calm room to grow in'],
    [RegExp(r'Children thrive when'), 'A home tends to feel steady to children when'],
    [RegExp(r'Children sense parental friction'),
        'Children tend to sense parental friction'],
    [RegExp(r'children grow their own grain'),
        'children tend to find their own grain'],
    [RegExp(r'Children get a quiet floor to stand on'),
        'A companion-style tone tends to give children a quiet floor to stand on'],
    [RegExp(r'children absorb'), 'children tend to take in'],
    [RegExp(r'children inherit'), 'children tend to take in'],
    [RegExp(r'\bChildren absorb\b'), 'Children tend to take in'],
    [RegExp(r'\bChildren inherit\b'), 'Children tend to take in'],
    [RegExp(r'saju strongly recommends this love'),
        'this is one of the strongest love bonds between the two charts'],
    [RegExp(r'Saju recommends this marriage\.'),
        'As a marriage, this bond tends to get steadier with years.'],
    [RegExp(r'Saju-favorable for marriage with'),
        'A marriage that tends to deepen over years with'],
    [RegExp(r'Saju calls this one of the strongest unions\.'),
        'This is one of the strongest unions between the two charts.'],
    [RegExp(r'A bond saju recommends — '), 'A bond the two charts lean toward — '],
    [RegExp(r'Saju calls '), ''],
    [RegExp(r'\bin saju\b'), 'in the pair'],
    [RegExp(r'time with [^.]*? etches in by the chart, not just by feeling'),
        'time together tends to register, not just by feeling'],
    [RegExp(r'etches in by the chart'), 'tends to register'],
    [RegExp(r'sharper by chart signal too'), 'sharper here too'],
    [RegExp(r'by chart signal too'), 'here too'],
    [RegExp(r'firms up by chart signal'), 'firms up here'],
    [RegExp(r'by chart tone too'), 'here too'],
    [RegExp(r'by chart tone'), 'here'],
    [RegExp(r'records sharper than average'), 'tends to register clearly'],
    [RegExp(r'the chart bookmarks'), 'the pair leans toward'],
    [RegExp(r'the chart rates'), 'the pair reads as'],
    [RegExp(r'the chart stamps'), 'the pair leans toward'],
    [RegExp(r'the chart etches'), 'the pair leans toward'],
    [RegExp(r'the chart asks for'), 'this seat rewards'],
    [RegExp(r'the chart recommends'), 'this seat rewards'],
    // 'is not decided by saju' 는 'decided by saju' 보다 먼저 — 부분 매칭 순서 버그 방지.
    [RegExp(r'is not decided by saju'), 'is not fixed in advance'],
    [RegExp(r'decided by saju'), 'shaped by the two of you'],
    [RegExp(r'Direct saju signal'), 'Direct anchor signal'],
    [RegExp(r'\bSaju triad\b'), 'Branch triad'],
    // fate voice — capital 형은 lowercase 규칙(line 240)이 못 잡으므로 명시.
    [RegExp(r'Fated-pull'), 'Strong-pull'],
    [RegExp(r'\bFated\b'), 'Strongly drawn'],

    // ───── 위반유형 A — 관계 결과·미래 단정 ─────
    [
      RegExp(r'outside shocks \(break-ups, moves, career shifts\) destabilize the bond\. '
          r'In those seasons, double your check-in frequency\.'),
      'when big outside changes (moves, career shifts) overlap, the bond is '
          'easy to shake. Checking in more often through those stretches keeps '
          'the distance from widening.',
    ],
    [
      RegExp(r'easy to shake by outside events \(break-ups, moves, career shifts\)\. '
          r'Double-check-in seasons protect the bond\.'),
      'easy to shake when big outside changes (moves, career shifts) overlap. '
          'Checking in more often through those stretches protects the bond.',
    ],
    [
      RegExp(r'In big life events \(break-ups, moves, career shifts\) the bond stretches '
          r'easily — double the check-in frequency in those seasons\.'),
      'When big life changes (moves, career shifts) overlap, the bond stretches '
          'easily — checking in more often through those stretches helps.',
    ],
    [RegExp(r'break-ups, moves, career shifts'), 'moves, career shifts'],
    [RegExp(r'break-up, moves'), 'moves'],

    // "deepens / grows deeper / lasts long" 미래 단정 → 경향.
    [RegExp(r'Depth compounds with time\.'), 'Depth tends to compound when you tend it.'],
    [RegExp(r'the bond hardens over time into something hard to break'),
        'the bond tends to harden when you tend it'],
    [RegExp(r'the bond outlasts loud pairings'), 'the bond tends to run longer than loud pairings'],
    [RegExp(r'[Tt]he marriage gets better in year five than year one'),
        'The marriage tends to read steadier in year five than year one'],
    [RegExp(r'[Tt]he bond gets better in year five than year one'),
        'The bond tends to read steadier in year five than year one'],
    [RegExp(r'gets better in year five'), 'tends to read steadier in year five'],
    [RegExp(r'gets better in year ten'), 'tends to read steadier in year ten'],
    [RegExp(r'the bond reads as easy from day one'), 'the bond can read as easy from day one'],
    [RegExp(r'tends to get steadier with years'), 'tends to get steadier with years'],
    [RegExp(r'gets steadier with years'), 'tends to get steadier with years'],
    [RegExp(r'the love lasts'), 'the love can run long'],
    [RegExp(r'the bond lasts'), 'the bond can run long'],
    [RegExp(r'closeness compounds through small repetition'),
        'closeness can build through small repetition'],
    [RegExp(r'closeness builds in quiet repetition'),
        'closeness tends to build in quiet repetition'],
    [RegExp(r'the depth grows by attention'), 'depth tends to grow with attention'],
    [RegExp(r'depth compounds with time'), 'depth tends to compound when you tend it'],
    [RegExp(r'and the bond locks in'), 'and the bond tends to settle'],
    [RegExp(r'the bond locks in'), 'the bond tends to settle'],
    [RegExp(r'distance grows by default'), 'distance tends to grow without small signals'],
    [RegExp(r'Distance grows by default'), 'Distance tends to grow without small signals'],
    [RegExp(r'the gap can widen without small signals'),
        'the gap can widen without small signals'],
    [RegExp(r'halve clash frequency'), 'help keep clashes from escalating'],
    [RegExp(r'Domain rules halve clash frequency'),
        'Domain rules help keep clashes from escalating'],
    [RegExp(r'shrinks 80% of the explosions'), 'helps keep most explosions from building'],
    [RegExp(r'kills most of the small fights'), 'helps defuse most small fights'],
    [RegExp(r'kills half of the small fights'), 'helps defuse half the small fights'],
    [RegExp(r'prevents most explosions'), 'helps prevent most explosions'],
    [RegExp(r'prevents most big fights'), 'helps prevent most big fights'],
    [RegExp(r'Small fights stop becoming silences'),
        'Small fights are less likely to become silences'],
    [RegExp(r'small bumps stop turning into fights'),
        'small bumps are less likely to turn into fights'],
    [RegExp(r'the love survives the friction'),
        'the love is easier to carry through the friction'],
    [RegExp(r'the bond often deepens after one honest collision'),
        'the bond often eases after one honest collision'],
    [RegExp(r'The smallest ritual deepens the bond\.'),
        'The smallest ritual helps the bond stay close.'],
    [RegExp(r'Honesty after collisions deepens the bond more than calm could\.'),
        'Honesty after collisions tends to ease the bond more than calm could.'],
    [RegExp(r"that's how shared elements deepen"),
        "that's how shared elements tend to grow"],
    [RegExp(r'naming the gratitude out loud deepens the bond'),
        'naming the gratitude out loud helps the bond stay close'],
    [RegExp(r'Your day pillar deepens this tone by one shade'),
        'Your day pillar reads this tone one shade richer'],
    [RegExp(r'that home tone deepens by one grain'),
        'that home tone reads one grain richer'],
    // 잔여 bare 'deepens' — 경향형으로. 마지막에 둔다.
    [RegExp(r'\bdeepens\b'), 'tends to deepen'],
    [RegExp(r'both grow tougher'), 'both tend to toughen'],
    [RegExp(r'both toughen'), 'both tend to toughen'],
    [RegExp(r'you grow tougher'), 'you tend to toughen'],

    // ───── 위반유형 B — 상대·나의 변화 단정 ─────
    [RegExp(r'watching them grow steadies you in return'),
        'watching them step forward tends to steady you in return'],
    [RegExp(r'watching $n grow steadies you in return'),
        'watching them step forward tends to steady you in return'],
    [RegExp(r'\$n catches up to themselves beside you'),
        'the other person tends to find their footing beside you'],
    [RegExp(r'catches up to themselves beside you'),
        'tends to find their footing beside you'],
    [RegExp(r'starts saying things they could not say before'),
        'tends to say things they held back before'],
    [RegExp(r'becomes their best self beside you'),
        'tends to show their steadier side beside you'],
  ];

  /// KO/EN 궁합 본문에 v5 voice 정규화를 적용한다.
  ///
  /// [text] 이미 조립된 궁합 풀이 본문. [useKo] true=한국어 규칙, false=영어 규칙.
  /// [shortName] 본문 안 `$shortName` / `$n` 치환 슬롯이 정규화 결과에도 유지되도록
  /// 받는 선택 인자. 규칙 패턴에 `$n` 가 들어간 경우 shortName 으로 풀어 매칭한다.
  static String soften(String text, {required bool useKo, String? shortName}) {
    if (text.isEmpty) return text;
    var out = text;
    final rules = useKo ? _koRules : _enRules;
    final sn = (shortName ?? '').trim();
    for (final rule in rules) {
      var pattern = rule[0] as RegExp;
      var to = rule[1] as String;
      if (sn.isNotEmpty) {
        // 규칙 패턴/치환문에 이름 슬롯이 들어 있으면 실제 이름으로 풀어준다.
        final ps = pattern.pattern;
        if (ps.contains(r'$n') || ps.contains(r'\$n')) {
          pattern = RegExp(
            ps.replaceAll(r'\$n', RegExp.escape(sn)).replaceAll(r'$n', RegExp.escape(sn)),
          );
        }
        to = to.replaceAll(r'$shortName', sn).replaceAll(r'$n', sn);
      }
      out = out.replaceAll(pattern, to);
    }
    return out;
  }
}
