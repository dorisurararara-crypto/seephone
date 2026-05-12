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
        '甲': '갑목', '乙': '을목', '丙': '병화', '丁': '정화', '戊': '무토',
        '己': '기토', '庚': '경금', '辛': '신금', '壬': '임수', '癸': '계수',
      }[g] ??
      g;

  static String _gnameEn(String g) => {
        '甲': 'Yang Wood', '乙': 'Yin Wood', '丙': 'Yang Fire', '丁': 'Yin Fire',
        '戊': 'Yang Earth', '己': 'Yin Earth', '庚': 'Yang Metal', '辛': 'Yin Metal',
        '壬': 'Yang Water', '癸': 'Yin Water',
      }[g] ??
      g;

  static String _elNameKo(String e) => {
        '木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물',
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
      '{dm} 일간, {dom} 기운이 오늘의 흐름을 만들어요.'.replaceAll('{dm}', _gnameKo(p.dayMaster))
          .replaceAll('{dom}', _elNameKo(p.dominantEl));

  static String _fallbackHeadEn(PillarProfile p) =>
      'Your ${_gnameEn(p.dayMaster)} day master under ${_elNameEn(p.dominantEl)} dominance shapes today.';

  static String _fallbackBodyKo(PillarProfile p) =>
      '오늘은 한 가지에 집중하면 보상이 따라요. 당신은 출생 계절(${_seasonKo(p.season)}) 결을 가진 사람.';

  static String _fallbackBodyEn(PillarProfile p) =>
      'Today, focus on one thing — you carry ${_seasonEn(p.season)}-born momentum.';

  static String _fallbackActionKo(PillarProfile p) =>
      '오늘 ${_elNameKo(p.deficitEl)} 기운을 보태는 행동(${_compensationKo(p.deficitEl)})을 하나만 의식하세요.';

  static String _fallbackActionEn(PillarProfile p) =>
      'Add one ${_elNameEn(p.deficitEl)} touch today (${_compensationEn(p.deficitEl)}).';

  static String _fallbackCautionKo(PillarProfile p) => p.isStrong
      ? '강한 ${_elNameKo(p.dominantEl)} 기운 — 자기 주장이 과해지지 않게 한 박자 늦추세요.'
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
    // identity (headline)
    InsightAtom(
      topic: 'identity',
      priority: 90,
      koTpl: '{dm} — {dom} 기운이 강하게 작동하는 사주예요.',
      enTpl: 'Your {dmEn} runs on heavy {domEn} energy.',
      condition: (p, t) => p.isStrong,
    ),
    InsightAtom(
      topic: 'identity',
      priority: 80,
      koTpl: '{dm} — {def} 기운이 부족해 결을 조심스럽게 다듬는 타입이에요.',
      enTpl: 'Your {dmEn} runs light on {defEn} — you refine your grain carefully.',
      condition: (p, t) => !p.isStrong,
    ),
    InsightAtom(
      topic: 'identity',
      priority: 70,
      koTpl: '{season}생 {dm} — 출생 계절과 본성이 같은 방향이라 결이 자연스러워요.',
      enTpl: '{dmEn} born in {seasonEn} — your nature flows with the season you were born in.',
      condition: (p, t) => (p.season == 'spring' && p.dayMasterElement == '木') ||
          (p.season == 'summer' && p.dayMasterElement == '火') ||
          (p.season == 'autumn' && p.dayMasterElement == '金') ||
          (p.season == 'winter' && p.dayMasterElement == '水'),
    ),

    // today (body)
    InsightAtom(
      topic: 'today',
      priority: 85,
      koTpl: '오늘은 관계보다 정리에 힘이 실립니다. 한 번에 하나만.',
      enTpl: 'Today rewards finishing over starting. One thing at a time.',
      condition: (p, t) => t.weekday >= 4,
    ),
    InsightAtom(
      topic: 'today',
      priority: 75,
      koTpl: '오늘은 {dom} 기운이 강하게 발현되는 날. 자기 결을 의식하면 더 빛납니다.',
      enTpl: 'Today\'s {domEn} energy amplifies your nature — own your signature.',
      condition: (p, t) => true,
    ),
    InsightAtom(
      topic: 'today',
      priority: 70,
      koTpl: '오늘은 말의 온도를 한 번 낮추는 편이 좋아요.',
      enTpl: 'Cool your tone by one degree before you speak.',
      condition: (p, t) => p.dayMasterElement == '火',
    ),
    InsightAtom(
      topic: 'today',
      priority: 70,
      koTpl: '오늘은 결정을 미루지 마세요. 한 가지를 매듭짓는 데 의미가 있어요.',
      enTpl: "Don't postpone — closing one decision matters today.",
      condition: (p, t) => p.dayMasterElement == '土',
    ),

    // action
    InsightAtom(
      topic: 'action',
      priority: 80,
      koTpl: '오늘 {def} 기운({compKo})을 한 가지 보태면 흐름이 더 부드러워져요.',
      enTpl: 'Add one touch of {defEn} ({compEn}) — the day softens.',
      condition: (p, t) => true,
    ),
    InsightAtom(
      topic: 'action',
      priority: 70,
      koTpl: '오늘 첫 메시지는 오전 11시 이후가 좋아요.',
      enTpl: 'Send your first big message after 11 AM today.',
      condition: (p, t) => t.weekday <= 3,
    ),

    // caution
    InsightAtom(
      topic: 'caution',
      priority: 85,
      koTpl: '강한 {dom} — 한 박자 늦춰서 말의 폭이 좁아지지 않게 조심.',
      enTpl: 'Heavy {domEn} — slow by one beat so your tone stays wide.',
      condition: (p, t) => p.isStrong,
    ),
    InsightAtom(
      topic: 'caution',
      priority: 80,
      koTpl: '{def} 부족 — 충동 결정 미루기, 24시간 보류가 답.',
      enTpl: 'Low {defEn} — sit on big decisions 24 hours before you act.',
      condition: (p, t) => !p.isStrong,
    ),
    InsightAtom(
      topic: 'caution',
      priority: 65,
      koTpl: '주말 분위기 — 약속을 무리해서 잡지 마세요.',
      enTpl: 'Weekend energy — don\'t overschedule social bandwidth.',
      condition: (p, t) => t.weekday >= 6,
    ),
    // identity 추가
    InsightAtom(
      topic: 'identity',
      priority: 60,
      koTpl: '출생 계절 {season}의 {dm} — 환절기 결을 잘 읽는 타입이에요.',
      enTpl: '{dmEn} in {seasonEn} — you read transitional moments well.',
      condition: (p, t) => p.season == 'transition',
    ),
    // today 추가
    InsightAtom(
      topic: 'today',
      priority: 60,
      koTpl: '오늘은 약한 {def} 기운을 의도적으로 보태면 흐름이 풀립니다.',
      enTpl: 'Today, intentionally adding {defEn} unblocks the day.',
      condition: (p, t) => !p.isStrong,
    ),
    // action 추가
    InsightAtom(
      topic: 'action',
      priority: 60,
      koTpl: '오늘 한 번은 {compKo}을(를) 일정에 끼워 넣으세요.',
      enTpl: 'Slot one block of {compEn} into today\'s schedule.',
      condition: (p, t) => true,
    ),
    // identity 추가 (강한 일간 별)
    InsightAtom(
      topic: 'identity',
      priority: 75,
      koTpl: '{dm} — 흐름을 만들기보다 흐름의 결을 정확히 짚는 타입.',
      enTpl: 'Your {dmEn} reads the grain rather than makes the wave.',
      condition: (p, t) =>
          p.dayMasterElement == '土' || p.dayMasterElement == '金',
    ),
    InsightAtom(
      topic: 'identity',
      priority: 75,
      koTpl: '{dm} — 시작은 빠르고, 표현은 깊은 결의 사주예요.',
      enTpl: 'Your {dmEn} starts fast, expresses deep — a layered nature.',
      condition: (p, t) =>
          p.dayMasterElement == '木' || p.dayMasterElement == '火',
    ),
    InsightAtom(
      topic: 'identity',
      priority: 70,
      koTpl: '{dm} — 흐름을 직접 만들지 않아도 결국 가장 깊이 도달하는 결.',
      enTpl: 'Your {dmEn} reaches the deepest without forcing the current.',
      condition: (p, t) => p.dayMasterElement == '水',
    ),
    // today 추가 (오행 dominant 별)
    InsightAtom(
      topic: 'today',
      priority: 75,
      koTpl: '오늘은 {dom}이(가) 많은 날이라, 결정은 정리에 두세요.',
      enTpl: 'A {domEn}-heavy day — orient toward closing, not starting.',
      condition: (p, t) =>
          p.dominantEl == '土' || p.dominantEl == '金',
    ),
    InsightAtom(
      topic: 'today',
      priority: 75,
      koTpl: '오늘은 {dom} 기운이 짙어 표현을 늘리되 양은 줄이세요.',
      enTpl: '{domEn} energy runs thick — increase expression, reduce volume.',
      condition: (p, t) =>
          p.dominantEl == '木' || p.dominantEl == '火',
    ),
    // caution 추가 (요일 + 계절)
    InsightAtom(
      topic: 'caution',
      priority: 70,
      koTpl: '월요일 — 첫 메시지의 톤이 한 주 전체를 정합니다.',
      enTpl: 'Monday — the first message you send sets the week\'s tone.',
      condition: (p, t) => t.weekday == 1,
    ),
    InsightAtom(
      topic: 'caution',
      priority: 70,
      koTpl: '금요일 — 결정은 미루고 듣는 데 시간을 더 주세요.',
      enTpl: 'Friday — postpone decisions; spend the time listening.',
      condition: (p, t) => t.weekday == 5,
    ),
    // action 추가 (계절)
    InsightAtom(
      topic: 'action',
      priority: 65,
      koTpl: '겨울 — {def} 기운({compKo})을 따뜻한 색·음식으로 보태세요.',
      enTpl: 'Winter — bring {defEn} ({compEn}) via warm color or warming food.',
      condition: (p, t) => t.month >= 12 || t.month <= 2,
    ),
    InsightAtom(
      topic: 'action',
      priority: 65,
      koTpl: '여름 — {def}을(를) 자연 속에서 흡수 (산책·물·하늘).',
      enTpl: 'Summer — absorb {defEn} outdoors (walk, water, sky).',
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
