// Pillar Seer — 개인화 콘텐츠 조합 엔진 (codex Round 6 #1 ROI).
// PillarProfile + InsightAtom 테이블 → 일주+오행+십신+오늘 조합 문장.
// deterministic seed (chart hash + date) → 같은 사용자 같은 날 동일 결과.

import '../models/saju_result.dart';

/// 사주 정규화 프로파일
class PillarProfile {
  final String dayMaster;          // 일간 천간
  final String dayMasterElement;   // 木火土金水
  final bool dayMasterYang;
  final String monthBranch;        // 월지
  final String season;             // spring/summer/autumn/winter/transition
  final String dominantEl;
  final String deficitEl;
  final bool isStrong;             // 일간 강약 (dominant == dayMasterElement 면 강함)

  const PillarProfile({
    required this.dayMaster,
    required this.dayMasterElement,
    required this.dayMasterYang,
    required this.monthBranch,
    required this.season,
    required this.dominantEl,
    required this.deficitEl,
    required this.isStrong,
  });

  factory PillarProfile.from(SajuResult saju) {
    final dm = saju.dayPillar;
    const ganYang = {
      '甲': true, '乙': false, '丙': true, '丁': false, '戊': true,
      '己': false, '庚': true, '辛': false, '壬': true, '癸': false,
    };
    final monthBranch = saju.monthPillar.jiJi;
    String season = 'transition';
    if (['寅', '卯', '辰'].contains(monthBranch)) season = 'spring';
    if (['巳', '午', '未'].contains(monthBranch)) season = 'summer';
    if (['申', '酉', '戌'].contains(monthBranch)) season = 'autumn';
    if (['亥', '子', '丑'].contains(monthBranch)) season = 'winter';
    return PillarProfile(
      dayMaster: dm.chunGan,
      dayMasterElement: dm.chunGanElement,
      dayMasterYang: ganYang[dm.chunGan] ?? true,
      monthBranch: monthBranch,
      season: season,
      dominantEl: saju.elements.dominant,
      deficitEl: saju.elements.deficit,
      isStrong: saju.elements.dominant == dm.chunGanElement,
    );
  }
}

/// 한 줄 문장 atom (condition → 1줄 텍스트)
class InsightAtom {
  final String topic;             // 'identity' / 'today' / 'action' / 'caution'
  final String koTpl;
  final String enTpl;
  final int priority;             // higher = more important
  final bool Function(PillarProfile p, DateTime now) condition;

  const InsightAtom({
    required this.topic,
    required this.koTpl,
    required this.enTpl,
    required this.priority,
    required this.condition,
  });
}

/// Today's personalized 4-line bundle
class PersonalReading {
  final String headlineKo;
  final String headlineEn;
  final String bodyKo;
  final String bodyEn;
  final String actionKo;
  final String actionEn;
  final String cautionKo;
  final String cautionEn;

  const PersonalReading({
    required this.headlineKo,
    required this.headlineEn,
    required this.bodyKo,
    required this.bodyEn,
    required this.actionKo,
    required this.actionEn,
    required this.cautionKo,
    required this.cautionEn,
  });
}

class PersonalizationEngine {
  /// Generate today's personalized reading for [saju].
  static PersonalReading buildFor(SajuResult saju, {DateTime? now}) {
    final profile = PillarProfile.from(saju);
    final t = now ?? DateTime.now();

    // deterministic seed — full chart hash + date (codex Round 7 fix)
    // 4기둥 + 5행 분포 + 나이 → 같은 일주여도 다른 사용자는 다른 결과
    final chartHash = _chartHash(saju);
    final seed = (chartHash * 1009 +
            t.year * 366 + t.month * 31 + t.day) &
        0x7fffffff;

    // Pick atoms by topic priority
    final picked = <String, InsightAtom>{};
    for (final topic in ['identity', 'today', 'action', 'caution']) {
      final candidates = _atoms
          .where((a) => a.topic == topic && a.condition(profile, t))
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      if (candidates.isEmpty) continue;
      // pick by deterministic seed
      final idx = (seed + topic.length) % candidates.length;
      picked[topic] = candidates[idx];
    }

    String render(String tpl) => tpl
        .replaceAll('{dm}', _gnameKo(profile.dayMaster))
        .replaceAll('{dmEn}', _gnameEn(profile.dayMaster))
        .replaceAll('{dom}', _elNameKo(profile.dominantEl))
        .replaceAll('{domEn}', _elNameEn(profile.dominantEl))
        .replaceAll('{def}', _elNameKo(profile.deficitEl))
        .replaceAll('{defEn}', _elNameEn(profile.deficitEl))
        .replaceAll('{compKo}', _compensationKo(profile.deficitEl))
        .replaceAll('{compEn}', _compensationEn(profile.deficitEl))
        .replaceAll('{season}', _seasonKo(profile.season))
        .replaceAll('{seasonEn}', _seasonEn(profile.season));

    final identity = picked['identity'];
    final today = picked['today'];
    final action = picked['action'];
    final caution = picked['caution'];
    return PersonalReading(
      headlineKo: identity != null ? render(identity.koTpl) : _fallbackHeadKo(profile),
      headlineEn: identity != null ? render(identity.enTpl) : _fallbackHeadEn(profile),
      bodyKo: today != null ? render(today.koTpl) : _fallbackBodyKo(profile),
      bodyEn: today != null ? render(today.enTpl) : _fallbackBodyEn(profile),
      actionKo: action != null ? render(action.koTpl) : _fallbackActionKo(profile),
      actionEn: action != null ? render(action.enTpl) : _fallbackActionEn(profile),
      cautionKo: caution != null ? render(caution.koTpl) : _fallbackCautionKo(profile),
      cautionEn: caution != null ? render(caution.enTpl) : _fallbackCautionEn(profile),
    );
  }

  // ──────── Helpers (label maps)

  static String _gnameKo(String g) => {
        '甲': '큰 나무 같은 사람', '乙': '잘 휘는 풀 같은 사람',
        '丙': '환한 햇빛 같은 사람', '丁': '따뜻한 촛불 같은 사람',
        '戊': '든든한 산 같은 사람', '己': '기름진 흙 같은 사람',
        '庚': '단단한 쇠 같은 사람', '辛': '예리한 보석 같은 사람',
        '壬': '깊은 바다 같은 사람', '癸': '잔잔한 이슬비 같은 사람',
      }[g] ??
      g;

  static String _gnameEn(String g) => {
        '甲': 'a tall-tree type', '乙': 'a bending-grass type',
        '丙': 'a sunlight type', '丁': 'a candle-warmth type',
        '戊': 'a solid-mountain type', '己': 'a fertile-soil type',
        '庚': 'a forged-metal type', '辛': 'a jewel-edge type',
        '壬': 'a deep-ocean type', '癸': 'a drizzle type',
      }[g] ??
      g;

  static String _elNameKo(String e) => {
        '木': '나무', '火': '불', '土': '흙',
        '金': '쇠', '水': '물',
      }[e] ??
      e;

  static String _elNameEn(String e) => {
        '木': 'wood', '火': 'fire', '土': 'earth', '金': 'metal', '水': 'water',
      }[e] ??
      e;

  static String _seasonKo(String s) => {
        'spring': '봄', 'summer': '여름', 'autumn': '가을', 'winter': '겨울',
        'transition': '환절기',
      }[s] ??
      s;

  static String _seasonEn(String s) => {
        'spring': 'spring', 'summer': 'summer', 'autumn': 'autumn',
        'winter': 'winter', 'transition': 'transition',
      }[s] ??
      s;

  // ──────── Fallbacks (atom 매치 실패 시)

  static String _fallbackHeadKo(PillarProfile p) =>
      '당신은 {dm}이에요. 오늘은 {dom} 쪽이 강한 날이에요.'.replaceAll('{dm}', _gnameKo(p.dayMaster))
          .replaceAll('{dom}', _elNameKo(p.dominantEl));

  static String _fallbackHeadEn(PillarProfile p) =>
      'Your ${_gnameEn(p.dayMaster)} day master under ${_elNameEn(p.dominantEl)} dominance shapes today.';

  static String _fallbackBodyKo(PillarProfile p) =>
      '오늘은 한 가지에 집중하면 보상이 따라요. 당신은 ${_seasonKo(p.season)}에 태어난 사람이에요.';

  static String _fallbackBodyEn(PillarProfile p) =>
      'Today, focus on one thing — you carry ${_seasonEn(p.season)}-born momentum.';

  static String _fallbackActionKo(PillarProfile p) =>
      '오늘 ${_elNameKo(p.deficitEl)} 쪽을 보태는 행동(${_compensationKo(p.deficitEl)})을 하나만 의식하세요.';

  static String _fallbackActionEn(PillarProfile p) =>
      'Add one ${_elNameEn(p.deficitEl)} touch today (${_compensationEn(p.deficitEl)}).';

  static String _fallbackCautionKo(PillarProfile p) => p.isStrong
      ? '${_elNameKo(p.dominantEl)} 쪽이 강한 날 — 자기 주장이 과해지지 않게 한 박자 늦추세요.'
      : '약한 ${_elNameKo(p.deficitEl)} — 무리한 결정은 미루세요.';

  static String _fallbackCautionEn(PillarProfile p) => p.isStrong
      ? 'Strong ${_elNameEn(p.dominantEl)} — soften your stance by one beat.'
      : 'Light ${_elNameEn(p.deficitEl)} — defer big decisions a day.';

  static String _compensationKo(String el) => {
        '木': '식물·산책', '火': '햇빛·운동', '土': '정리·루틴',
        '金': '청소·결정', '水': '물·수면',
      }[el] ??
      '한 가지 균형';

  static String _compensationEn(String el) => {
        '木': 'plants, a walk', '火': 'sunlight, movement', '土': 'cleanup, routine',
        '金': 'declutter, decide', '水': 'hydration, rest',
      }[el] ??
      'one balance habit';

  // ──────── Atom 테이블 (priority 높을수록 먼저 picked)

  static final List<InsightAtom> _atoms = [
    // identity (headline) — 본인이 어떤 사람인지 한 문장
    InsightAtom(
      topic: 'identity',
      priority: 90,
      koTpl: '당신은 {dm}이에요. 안에 든 {dom}이 강하게 작동해서, 결정한 일은 끝까지 밀어붙이는 추진력이 자연스럽게 살아 있어요.',
      enTpl: 'You are {dmEn}. The strong {domEn} inside drives your decisions hard — once you commit, you push it to the finish.',
      condition: (p, t) => p.isStrong,
    ),
    InsightAtom(
      topic: 'identity',
      priority: 80,
      koTpl: '당신은 {dm}이에요. {def}이 좀 부족해서, 결정 전에 한 번 더 생각하고 다듬는 신중한 면이 강해요.',
      enTpl: 'You are {dmEn}. With less {defEn} inside, you tend to think twice and refine before acting — a careful style.',
      condition: (p, t) => !p.isStrong,
    ),
    InsightAtom(
      topic: 'identity',
      priority: 70,
      koTpl: '당신은 {dm}, 그리고 {season}에 태어났어요. 타고난 성격과 계절 기운이 같은 방향이라 큰 갈등 없이 자기 길을 갈 수 있는 사주예요.',
      enTpl: 'You are {dmEn}, born in {seasonEn}. Your nature and your birth season pull the same way — you can walk your path without inner friction.',
      condition: (p, t) => (p.season == 'spring' && p.dayMasterElement == '木') ||
          (p.season == 'summer' && p.dayMasterElement == '火') ||
          (p.season == 'autumn' && p.dayMasterElement == '金') ||
          (p.season == 'winter' && p.dayMasterElement == '水'),
    ),

    // today (body) — 오늘의 흐름 풀이 2-3 문장
    InsightAtom(
      topic: 'today',
      priority: 85,
      koTpl: '오늘은 새로 시작하기보다 진행 중인 일을 매듭짓는 게 더 잘 풀려요. 한 번에 하나씩, 시작했던 작은 일부터 차근차근 끝내 보세요. 마무리한 하나가 오늘 가장 큰 성취가 돼요.',
      enTpl: 'Today rewards closing over opening. Go one thing at a time — finish a small task you started earlier. The single closed loop is today\'s biggest win.',
      condition: (p, t) => t.weekday >= 4,
    ),
    InsightAtom(
      topic: 'today',
      priority: 75,
      koTpl: '오늘은 {dom}이 강하게 흐르는 날이에요. 당신 본래의 색이 더 뚜렷하게 드러나는 흐름이라서, 평소보다 자기 의견을 분명하게 말해도 잘 받아들여져요.',
      enTpl: 'Today\'s {domEn} flows strong, and your natural color shows clearer than usual. Speaking your opinion more openly today actually lands well.',
      condition: (p, t) => true,
    ),
    InsightAtom(
      topic: 'today',
      priority: 70,
      koTpl: '오늘은 말의 온도를 한 단계 낮추는 게 도움이 돼요. 평소 잘 통하던 표현도 오늘은 살짝 강하게 들릴 수 있으니, 한 박자 늦춰서 부드럽게 전달하세요.',
      enTpl: 'Cool your tone one notch today. Words that usually land may feel a bit sharp — slow by a beat and soften.',
      condition: (p, t) => p.dayMasterElement == '火',
    ),
    InsightAtom(
      topic: 'today',
      priority: 70,
      koTpl: '오늘은 미뤄둔 결정을 마무리하기에 좋은 날이에요. 작은 결정 하나만 명확하게 끝내도 일주일 전체가 한결 가벼워져요.',
      enTpl: 'A good day to close a postponed decision. Finishing even one small choice lightens the whole week.',
      condition: (p, t) => p.dayMasterElement == '土',
    ),

    // action — 오늘 한 가지 실천
    InsightAtom(
      topic: 'action',
      priority: 80,
      koTpl: '당신에게 살짝 부족한 {def}을 의식적으로 보충해 보세요. {compKo} 같은 작은 행동 하나면 충분하고, 그 하나가 오늘 흐름을 부드럽게 풀어줘요.',
      enTpl: 'Add one conscious touch of {defEn} ({compEn}). One small action is enough — it softens the day visibly.',
      condition: (p, t) => true,
    ),
    InsightAtom(
      topic: 'action',
      priority: 70,
      koTpl: '오늘 중요한 메시지나 제안은 오전 11시 이후에 보내는 게 더 잘 받아들여져요. 이른 아침보다는 상대가 충분히 깨어 있을 때 닿게 보내세요.',
      enTpl: 'Send the important message after 11 AM today — better reception when the other side is fully awake.',
      condition: (p, t) => t.weekday <= 3,
    ),

    // caution — 주의할 점 2-3 문장
    InsightAtom(
      topic: 'caution',
      priority: 85,
      koTpl: '오늘은 당신 안의 {dom}이 평소보다 강해서, 말의 폭이 좁아질 수 있어요. 한 박자 늦춰서 상대 말이 끝난 뒤에 답하고, "다시 생각해보면…" 같은 한 문장만 끼워 넣어도 분위기가 부드러워져요.',
      enTpl: 'Your {domEn} runs heavy today and may narrow your tone. Slow one beat, let the other finish, and add one phrase like "thinking again..." — the room softens instantly.',
      condition: (p, t) => p.isStrong,
    ),
    InsightAtom(
      topic: 'caution',
      priority: 80,
      koTpl: '오늘은 {def}이 살짝 부족한 흐름이에요. 큰 결정은 24시간 보류하고, 한 번 자고 일어난 후에 결정해도 늦지 않아요.',
      enTpl: 'Your {defEn} runs light today. Hold big decisions for 24 hours — sleep on it, then decide.',
      condition: (p, t) => !p.isStrong,
    ),
    InsightAtom(
      topic: 'caution',
      priority: 65,
      koTpl: '주말 흐름이에요. 의무감으로 약속을 잡으면 다음 주까지 피로가 따라와요. 정말 보고 싶은 한 사람만 만나도 충분해요.',
      enTpl: 'Weekend energy. Booking from obligation drags fatigue into next week — meeting one person you really want to see is enough.',
      condition: (p, t) => t.weekday >= 6,
    ),
    // identity 추가
    InsightAtom(
      topic: 'identity',
      priority: 60,
      koTpl: '당신은 환절기({season})에 태어난 {dm}이에요. 분위기가 바뀌는 순간을 다른 사람보다 빠르게 알아채는 감각이 있어요.',
      enTpl: 'You are {dmEn} born in {seasonEn} transition. You read shifts in mood faster than most.',
      condition: (p, t) => p.season == 'transition',
    ),
    // today 추가
    InsightAtom(
      topic: 'today',
      priority: 60,
      koTpl: '오늘은 살짝 부족한 {def}을 의식적으로 보태면 흐름이 부드러워져요. 평소 잊기 쉬운 작은 습관 하나가 오늘의 열쇠가 돼요.',
      enTpl: 'Adding a conscious touch of {defEn} unblocks today. A small habit you usually forget becomes today\'s key.',
      condition: (p, t) => !p.isStrong,
    ),
    // action 추가
    InsightAtom(
      topic: 'action',
      priority: 60,
      koTpl: '오늘 일정 어딘가에 {compKo} 시간을 잠깐이라도 끼워 넣으세요. 길지 않아도 돼요, 의식적으로 한 번이면 충분해요.',
      enTpl: 'Slot a quick block of {compEn} somewhere in today\'s schedule. It doesn\'t have to be long — one conscious moment is enough.',
      condition: (p, t) => true,
    ),
    // identity 추가 (강한 일간 별)
    InsightAtom(
      topic: 'identity',
      priority: 75,
      koTpl: '당신은 {dm}이에요. 새 흐름을 직접 만들기보다 이미 흐르는 흐름을 정확히 읽어내는 쪽이 강점이에요. 변화를 주도하지 않아도, 잘 따라가서 결국 가장 깊이 도달하는 타입이에요.',
      enTpl: 'You are {dmEn}. You read existing currents better than you create new ones — and by riding the right one, you reach the deepest spot.',
      condition: (p, t) =>
          p.dayMasterElement == '土' || p.dayMasterElement == '金',
    ),
    InsightAtom(
      topic: 'identity',
      priority: 75,
      koTpl: '당신은 {dm}이에요. 시작은 빠른데, 진짜 마음은 천천히 표현하는 면이 있어서, 처음 본 사람과 오래 본 사람이 느끼는 당신이 꽤 달라요.',
      enTpl: 'You are {dmEn}. Quick to start, slow to reveal real feeling — first impressions and long-time impressions of you can differ noticeably.',
      condition: (p, t) =>
          p.dayMasterElement == '木' || p.dayMasterElement == '火',
    ),
    InsightAtom(
      topic: 'identity',
      priority: 70,
      koTpl: '당신은 {dm}이에요. 흐름을 직접 만들지 않아도, 결국 가장 깊은 곳까지 도달하는 힘이 있어요. 서두르지 않아도 자기 자리를 찾는 사람이에요.',
      enTpl: 'You are {dmEn}. You don\'t need to force the current — you reach the deepest place anyway. You find your place without rushing.',
      condition: (p, t) => p.dayMasterElement == '水',
    ),
    // today 추가 (오행 dominant 별)
    InsightAtom(
      topic: 'today',
      priority: 75,
      koTpl: '오늘은 {dom}이 강한 날이라 새로 시작하는 일보다 정리·마무리에 더 좋은 흐름이에요. 책상 위 한 칸만 정리해도 머리가 가벼워져요.',
      enTpl: 'A {domEn}-heavy day — better for tidying and closing than for starting. Even clearing one corner of your desk lifts your head.',
      condition: (p, t) =>
          p.dominantEl == '土' || p.dominantEl == '金',
    ),
    InsightAtom(
      topic: 'today',
      priority: 75,
      koTpl: '오늘은 {dom}이 풍부한 날이에요. 자기 표현을 늘려도 잘 받아들여지는 흐름이지만, 양을 너무 많이 풀면 듣는 사람이 지칠 수 있으니 핵심만.',
      enTpl: '{domEn} energy is abundant today. Expressing more is welcomed, but pouring out too much tires the listener — stay on the core.',
      condition: (p, t) =>
          p.dominantEl == '木' || p.dominantEl == '火',
    ),
    // caution 추가 (요일 + 계절)
    InsightAtom(
      topic: 'caution',
      priority: 70,
      koTpl: '오늘은 월요일이에요. 가장 먼저 보내는 한 통의 메시지나 첫 인사의 톤이 한 주 전체 분위기를 정해요. 평소보다 한 단계 더 정성스럽게 시작해 보세요.',
      enTpl: 'Monday. The first message you send sets the tone of the whole week — start with one extra notch of care.',
      condition: (p, t) => t.weekday == 1,
    ),
    InsightAtom(
      topic: 'caution',
      priority: 70,
      koTpl: '오늘은 금요일이에요. 중요한 결정은 주말을 보내고 월요일에 다시 보세요. 오늘은 결정보다 듣는 시간을 더 길게 가지면 답이 자연스럽게 와요.',
      enTpl: 'Friday. Hold key decisions until Monday — today, listen longer than you decide, and answers arrive naturally.',
      condition: (p, t) => t.weekday == 5,
    ),
    // action 추가 (계절)
    InsightAtom(
      topic: 'action',
      priority: 65,
      koTpl: '겨울 — 당신에게 부족한 {def}을 따뜻한 색과 음식({compKo})으로 보충하는 시기예요. 따뜻한 차 한 잔, 노란 조명, 따끈한 국 한 그릇이 효과가 커요.',
      enTpl: 'Winter — bring missing {defEn} via warm colors and food ({compEn}). A hot cup, yellow lighting, a warm soup do real work.',
      condition: (p, t) => t.month >= 12 || t.month <= 2,
    ),
    InsightAtom(
      topic: 'action',
      priority: 65,
      koTpl: '여름 — {def}을 자연 속에서 흡수하기 좋은 계절이에요. 짧은 산책, 물 한 잔, 잠깐 하늘 올려다보기만 해도 보충돼요.',
      enTpl: 'Summer — absorb {defEn} from nature. A short walk, a glass of water, looking up at the sky for a minute — that refills it.',
      condition: (p, t) => t.month >= 6 && t.month <= 8,
    ),
  ];

  /// Full chart hash — 4 pillars + 5 elements + age 조합
  static int _chartHash(SajuResult saju) {
    int h = 0;
    h = h * 31 + saju.yearPillar.text.codeUnits.fold<int>(0, (a, b) => a + b);
    h = h * 31 + saju.monthPillar.text.codeUnits.fold<int>(0, (a, b) => a + b);
    h = h * 31 + saju.dayPillar.text.codeUnits.fold<int>(0, (a, b) => a + b);
    if (saju.hourPillar != null) {
      h = h * 31 +
          saju.hourPillar!.text.codeUnits.fold<int>(0, (a, b) => a + b);
    }
    h = h * 31 + saju.elements.wood + saju.elements.fire * 7 +
        saju.elements.earth * 13 + saju.elements.metal * 17 +
        saju.elements.water * 19;
    h = h * 31 + (saju.userAge ?? 0);
    return h & 0x7fffffff;
  }

}
