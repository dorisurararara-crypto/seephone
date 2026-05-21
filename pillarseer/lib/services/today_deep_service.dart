// ignore_for_file: unused_field
// Pillar Seer — 오늘 운세 깊이 풀이 서비스 (Round 11+ / R108 ③-3 v5 톤).
//
// 사용자 사주 + 오늘 일진 → 5-7문장 narrative + 행동 추천 + 조심 + 시간대.
// 중학생도 5초 안에 이해할 톤. 명리 jargon은 괄호 안에만.
//
// R108 ③-3 — 본문 풀·fragment 를 my_saju_v5 메타포 톤으로 전면 재작성.
//   - headline 의 "총평"(메타)·"~날"(헤드라인체) 제거 → 조언형 한 줄.
//   - body fragment 의 "오늘은 ~한 날이에요" 헤드라인체 0 → 발동조건형.
//   - "균형/본인 페이스/자기 결대로" boilerplate 제거.
//   - 사용자 일간 비유 anchor (辛=잘 벼려진 칼·보석 등 10천간) 를 body 에 1회 묶음.
//   계산 로직·임계값·DayEnergyKind 분기·hash 는 1 bit 도 건드리지 않는다 — 텍스트만.
//
// 입력:
//   - userSaju.dayPillar.chunGan (사용자 일간)
//   - userSaju.dayPillar.jiJi (사용자 일지)
//   - userSaju.monthPillar.jiJi (사용자 월지 — 계절 보정)
//   - userSaju.elements.dominant / deficit (5행 균형)
//   - 오늘 일진 (60갑자) — DailyService 로부터
//
// 출력 (TodayDeepReading):
//   - headlineKo / headlineEn: 일간 비유에 묶은 조언형 한 줄 (메타·헤드라인체 0)
//   - bodyKo / bodyEn: 4-6 문장 narrative
//   - actionsKo[] / actionsEn[]: 추천 행동 2-3개 (구체적)
//   - cautionKo / cautionEn: 조심할 일 한 줄
//   - bestTimeKo / bestTimeEn: 시간대 추천 (예: "오전 9-11시")
//
// 알고리즘:
//   1) 오늘 천간 × 사용자 일간 → 십신 (TenGodsService)
//   2) 오늘 지지 vs 사용자 일지 → 합/충/형/파
//   3) 5행 강약 변화 (오늘 element가 사용자 dominant/deficit과 어떤 관계)
//   4) 시간대 = 오늘 지지 가 활성화되는 12시진 매핑

import '../models/saju_result.dart';
import 'daily_service.dart' show DayEnergyKind, classifyDayEnergy;
import 'dynamic_text_resolver.dart';
import 'natural_prose_joiner.dart';
import 'saju_context.dart';
import 'ten_gods_service.dart';
import 'yongsin_service.dart';

class TodayDeepReading {
  final String headlineKo;
  final String headlineEn;
  final String bodyKo;
  final String bodyEn;
  final List<String> actionsKo;
  final List<String> actionsEn;
  final String cautionKo;
  final String cautionEn;
  final String bestTimeKo;
  final String bestTimeEn;
  final String moodTagKo; // 한 단어 — 화면 chip
  final String moodTagEn;

  const TodayDeepReading({
    required this.headlineKo,
    required this.headlineEn,
    required this.bodyKo,
    required this.bodyEn,
    required this.actionsKo,
    required this.actionsEn,
    required this.cautionKo,
    required this.cautionEn,
    required this.bestTimeKo,
    required this.bestTimeEn,
    required this.moodTagKo,
    required this.moodTagEn,
  });
}

class TodayDeepService {
  /// 메인: 사용자 사주 + 오늘 일진 → 깊은 풀이.
  ///
  /// Round 78 sprint 4 — [ctx] (SajuContext) 가 주어지면 격국 anchor 와 용신 5축
  /// suffix 가 body 끝에 derive 되어 같은 십신·dayEnergy 라도 격국·용신 다르면
  /// 본문 phrase 차이 ≥1 보장. ctx null 시 R77 기존 형태 그대로 (회귀 가드).
  static TodayDeepReading build({
    required String userDayStem, // 사용자 일간 (천간)
    required String userDayBranch, // 사용자 일지
    required String userMonthBranch, // 사용자 월지
    required String userDominantEl, // 사용자 5행 강함
    required String userDeficitEl, // 사용자 5행 약함
    required String todayPillar, // 오늘 60갑자 (예: '丙戌')
    required int todayScore, // 0-100
    SajuContext? ctx, // Round 78 sprint 4 — 격국·용신 derive
  }) {
    final todayStem = todayPillar.isNotEmpty ? todayPillar[0] : '甲';
    final todayBranch = todayPillar.length >= 2 ? todayPillar[1] : '子';

    // 1. 십신 — 오늘 천간이 사용자 일간 기준 무엇인가
    final god = TenGodsService.godFor(userDayStem, todayStem);

    // 2. 사용자 vs 오늘 지지 관계
    final branchRelation = _branchRelation(userDayBranch, todayBranch);

    // 3. 5행 풀이
    final todayEl = _elementOfStem(todayStem);
    final elementMood = _elementMood(userDominantEl, userDeficitEl, todayEl);

    // 4. 12시진 best time
    final bestTime = _bestTimeFor(todayBranch);

    // Round 71 — `DayEnergyKind` 단일 source-of-truth. body / headline 도 같은 분기.
    final dayEnergy = classifyDayEnergy(todayScore);

    // R98 — 반복 sentence 분산용 deterministic seed (사용자 사주 anchor).
    // 같은 사주 + 같은 오늘 = 항상 같은 sentence (consistency 보장),
    // 다른 사주끼리는 다른 sentence 가 픽되도록 spread.
    final branchPickSeed = _phraseSeed('$userDayBranch$todayBranch');
    final godPickSeed = _phraseSeed('$userDayStem$todayStem$userDayBranch');

    // narrative 조합 — godPhrase 와 hook 모두 dayEnergy 기반.
    final godKo = god == null ? '' : _godPhraseKoByEnergy(god, dayEnergy, godPickSeed);
    final godEn = god == null ? '' : _godPhraseEnByEnergy(god, dayEnergy);
    final brKo = _branchRelationKo(branchRelation, branchPickSeed);
    final brEn = _branchRelationEn(branchRelation);

    final hooks = _hooksByEnergy(dayEnergy);

    // R108 ③-3 — headline 은 메타("총평")·헤드라인체("~날") 0. 일간 비유에
    // 묶은 조언형 한 줄. 같은 일간 + dayEnergy = 같은 headline (deterministic).
    final headlineKo = _headlineKo(userDayStem, dayEnergy);
    final headlineEn = _headlineEn(userDayStem, dayEnergy);

    // R97 — mixedDay opening 변형 pool deterministic pick anchor.
    // 사용자 사주 (일간 + 일지) + 오늘 일지 만으로 결정 (같은 사주 = 같은 sentence).
    // R98 — seed mix 강화 (FNV-1a 변형) 으로 5 pool 골고루 분산.
    final mixedSeed = _mixedOpeningSeed(
      userDayStem: userDayStem,
      userDayBranch: userDayBranch,
      todayBranch: todayBranch,
    );

    // R98 — mixedDay moodHook 변형 pool seed (mixedSeed 와 분리해 더 spread).
    final moodHookSeed = _phraseSeed('$userDayStem$userDayBranch$todayStem$todayBranch');

    // R98 — mixedDay 일 때 moodHook 3-pool deterministic pick (sample 5 반복 fix).
    final resolvedMoodHookKo = dayEnergy == DayEnergyKind.mixedDay
        ? _mixedDayMoodHookPool[moodHookSeed % _mixedDayMoodHookPool.length]
        : hooks.bodyHookKo;

    var bodyKo = _composeBodyKo(
      userDayStem: userDayStem,
      godKo: godKo,
      branchKo: brKo,
      elementKo: elementMood.ko,
      moodHookKo: resolvedMoodHookKo,
      energy: dayEnergy,
      mixedOpeningSeed: mixedSeed,
    );
    var bodyEn = _composeBodyEn(
      userDayStem: userDayStem,
      godEn: godEn,
      branchEn: brEn,
      elementEn: elementMood.en,
      moodHookEn: hooks.bodyHookEn,
      energy: dayEnergy,
    );

    // Round 78 sprint 4/7 — ctx 주입 시 격국 anchor + 용신 5축 derive suffix +
    // 현재 대운 십신 anchor (sprint 7) 합성.
    // 같은 십신·dayEnergy 라도 격국·용신·대운 다르면 본문 phrase 차이 ≥1.
    if (ctx != null) {
      final gAnchorKo = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'ko');
      final ySuffixKo = DynamicTextResolver.yongsinSuffix(ctx, locale: 'ko');
      final dwAnchorKo = _daewoonAnchor(ctx, locale: 'ko');
      final extraKo = [
        dwAnchorKo,
        gAnchorKo,
        ySuffixKo,
      ].where((p) => p.isNotEmpty).join(' ');
      if (extraKo.isNotEmpty) {
        bodyKo = NaturalProseJoiner.append(bodyKo, [extraKo]);
      }
      final gAnchorEn = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'en');
      final ySuffixEn = DynamicTextResolver.yongsinSuffix(ctx, locale: 'en');
      final dwAnchorEn = _daewoonAnchor(ctx, locale: 'en');
      final extraEn = [
        dwAnchorEn,
        gAnchorEn,
        ySuffixEn,
      ].where((p) => p.isNotEmpty).join(' ');
      if (extraEn.isNotEmpty) {
        bodyEn = '$bodyEn $extraEn';
      }
    }

    final actionsKo = _actionsKo(god, branchRelation, todayScore);
    final actionsEn = _actionsEn(god, branchRelation, todayScore);

    // Round 78 sprint 5 — ctx 주입 시 용신 5축 1줄 actions 끝에 join.
    if (ctx != null && ctx.yongsin.isNotEmpty) {
      final axisKo = YongsinService.oneAxisLineKo(ctx.yongsin, ctx.chartSeed);
      final axisEn = YongsinService.oneAxisLineEn(ctx.yongsin, ctx.chartSeed);
      if (axisKo.isNotEmpty) {
        actionsKo.add('오늘 한 가지: $axisKo.');
      }
      if (axisEn.isNotEmpty) {
        actionsEn.add('One small move: $axisEn.');
      }
    }

    var cautionKo = _cautionKo(god, branchRelation, todayScore);
    var cautionEn = _cautionEn(god, branchRelation, todayScore);

    // Round 78 sprint 6 — 공망 발동 시 caution 끝에 anchor join.
    // R108 ③-3 — "공망" jargon 노출 제거, 작용만 plain 하게 묘사.
    if (ctx != null && ctx.gongMangAreas.isNotEmpty) {
      cautionKo = '$cautionKo 오늘은 결정 하나가 괜히 헛돌 수 있는 자리라, '
          '큰돈·계약 같은 건 한 번 더 확인하고 움직여요.';
      cautionEn = '$cautionEn Today, a decision can spin without landing, '
          'so double-check big money or contract calls before you move.';
    }

    return TodayDeepReading(
      headlineKo: headlineKo,
      headlineEn: headlineEn,
      bodyKo: bodyKo,
      bodyEn: bodyEn,
      actionsKo: actionsKo,
      actionsEn: actionsEn,
      cautionKo: cautionKo,
      cautionEn: cautionEn,
      bestTimeKo: bestTime.ko,
      bestTimeEn: bestTime.en,
      moodTagKo: hooks.moodKo,
      moodTagEn: hooks.moodEn,
    );
  }

  // ───────── helpers ─────────

  /// Round 78 sprint 7 — 현재 대운 십신 anchor 1구.
  /// userAge 미공급 / currentDaewoon null / currentDaewoonGod null 시 빈 string.
  static String _daewoonAnchor(SajuContext ctx, {required String locale}) {
    if (ctx.currentDaewoon == null) return '';
    final dwGod = ctx.currentDaewoonGod;
    if (dwGod == null) return '';
    if (locale == 'ko') {
      final ko = dwGod.ko.split(' ').first; // '정관 (正官)' → '정관'
      // R86 sprint 4 — 사용자 mandate: 십신 jargon ("식신/겁재/정관" 등) 본문 노출 0.
      // "대운" 단어 자체는 R78 sprint 7 anchor wire 시그니처 유지 위해 보존.
      const map = {
        '비견': '지금 대운에서는 또래·동료와의 비교 신호가 평소보다 진하게 도는 시기예요.',
        '겁재': '지금 대운에서는 경쟁심·승부 욕구가 평소보다 한 박자 빨라지는 시기예요.',
        '식신': '지금 대운에서는 표현·창작이 잘 풀리는 시기예요.',
        '상관': '지금 대운에서는 한 발 빠른 감각이 잘 드러나는 시기예요.',
        '편재': '지금 대운에서는 새로운 거래·기회가 자주 찾아오는 시기예요.',
        '정재': '지금 대운에서는 차곡차곡 쌓이는 안정감이 강해지는 시기예요.',
        '편관': '지금 대운에서는 도전·승부 신호가 평소보다 한 겹 더해지는 시기예요.',
        '정관': '지금 대운에서는 직장·조직 안에서 자리 잡는 안내가 잘 받쳐주는 시기예요.',
        '편인': '지금 대운에서는 직관이 평소보다 또렷해지는 시기예요.',
        '정인': '지금 대운에서는 배우는 시간이 평소보다 단단하게 쌓이는 시기예요.',
      };
      return map[ko] ?? '';
    } else {
      final ko = dwGod.ko.split(' ').first;
      // R108 ③-3 — sipsin-style jargon labels ("Peer/Output cycle" 등) 제거.
      // 한국어 map 과 동일하게 plain 하게 풀어쓴다.
      const map = {
        '비견': 'In this stretch of your life, the pull of comparing yourself '
            'with peers tends to run thicker than usual.',
        '겁재': 'In this stretch of your life, a competitive, want-to-win '
            'streak tends to run a beat quicker.',
        '식신': 'In this stretch of your life, expressing and creating tends '
            'to flow more easily.',
        '상관': 'In this stretch of your life, a quick, sharp read of things '
            'tends to come through clearly.',
        '편재': 'In this stretch of your life, fresh deals and chances tend '
            'to come around more often.',
        '정재': 'In this stretch of your life, a steady, layered sense of '
            'stability tends to grow stronger.',
        '편관': 'In this stretch of your life, signals of challenge and '
            'pressure tend to stack one layer thicker.',
        '정관': 'In this stretch of your life, settling into a role within a '
            'job or group tends to be well backed.',
        '편인': 'In this stretch of your life, your intuition tends to read '
            'clearer than usual.',
        '정인': 'In this stretch of your life, the time you spend learning '
            'tends to stack up more solidly.',
      };
      return map[ko] ?? '';
    }
  }

  static String _elementOfStem(String stem) {
    const map = {
      '甲': '木',
      '乙': '木',
      '丙': '火',
      '丁': '火',
      '戊': '土',
      '己': '土',
      '庚': '金',
      '辛': '金',
      '壬': '水',
      '癸': '水',
    };
    return map[stem] ?? '木';
  }

  // ───────── R108 ③-3 — 일간 비유 anchor (my_saju_v5 _stemPersona 톤) ─────────

  /// 일간 천간 → 짧은 비유 명사구 (body 첫 문장 anchor 용).
  /// my_saju_v5_pool day_master.ko / life_overview _stemPersona 와 같은 비유.
  static const Map<String, String> _stemMetaphorKo = {
    '甲': '곧게 위로 자라는 큰 나무 같은 당신',
    '乙': '어디에 놓여도 길을 찾아 자라는 풀 같은 당신',
    '丙': '한낮의 해처럼 환한 당신',
    '丁': '어두운 데를 비추는 촛불 같은 당신',
    '戊': '자리를 묵직하게 잡은 큰 산 같은 당신',
    '己': '무엇이든 길러내는 밭흙 같은 당신',
    '庚': '아직 다듬지 않은 무쇠 같은 당신',
    '辛': '잘 벼려진 칼이나 보석 같은 당신',
    '壬': '넓게 흐르는 큰 강 같은 당신',
    '癸': '땅속으로 조용히 스며드는 옹달샘 같은 당신',
  };

  /// 일간 천간 → 영어 비유 명사구.
  static const Map<String, String> _stemMetaphorEn = {
    '甲': 'you, with a tall-tree kind of energy',
    '乙': 'you, with a vine-finding-its-way kind of energy',
    '丙': 'you, with a midday-sun kind of energy',
    '丁': 'you, with a candle-lighting-a-dark-corner kind of energy',
    '戊': 'you, with a wide-mountain kind of energy',
    '己': 'you, with a rich-garden-soil kind of energy',
    '庚': 'you, with a raw-iron kind of energy',
    '辛': 'you, with a well-honed-blade kind of energy',
    '壬': 'you, with a wide-river kind of energy',
    '癸': 'you, with a quiet-spring kind of energy',
  };

  static String _stemMetaphorKoOf(String stem) =>
      _stemMetaphorKo[stem] ?? '본인 색이 또렷한 당신';

  static String _stemMetaphorEnOf(String stem) =>
      _stemMetaphorEn[stem] ?? 'you, with a colour all your own';

  /// R108 ③-3 — headline (한국어). 메타·헤드라인체 0. 일간 비유 + dayEnergy
  /// 조언형 한 줄. 같은 일간 + dayEnergy → 같은 문장.
  static String _headlineKo(String userDayStem, DayEnergyKind energy) {
    final who = _stemMetaphorKoOf(userDayStem);
    switch (energy) {
      case DayEnergyKind.actionDay:
        return '$who, 오늘은 미뤄둔 한 가지를 손에 들어도 좋아요.';
      case DayEnergyKind.mixedDay:
        return '$who, 오늘은 한 발씩 정리하는 쪽이 잘 맞아요.';
      case DayEnergyKind.restDay:
        return '$who, 오늘은 새로 벌리기보다 한 박자 쉬어가요.';
    }
  }

  /// R108 ③-3 — headline (영어). r99 forbidden 35 phrase 회피.
  static String _headlineEn(String userDayStem, DayEnergyKind energy) {
    final who = _stemMetaphorEnOf(userDayStem);
    switch (energy) {
      case DayEnergyKind.actionDay:
        return 'For $who, today is fine for picking up one thing you have '
            'been putting off.';
      case DayEnergyKind.mixedDay:
        return 'For $who, a step-by-step sort-out works best today.';
      case DayEnergyKind.restDay:
        return 'For $who, today leans toward a pause rather than a new start.';
    }
  }

  // Round 71 — restDay 일 때 "승진/공식 자리/도전" 류 단어가 bodyKo 에 등장하면
  // 사용자 불만 #3 (모순) 재발. dayEnergy 별 godPhrase 변주로 차단.
  // Round 74 — '분위기' 5회 반복 분산. 일상 평서.
  // R98 — geopjae sample 5/10 반복 fix. seed 기반 3-pool deterministic pick.
  static String _godPhraseKoByEnergy(TenGod g, DayEnergyKind energy, [int seed = 0]) {
    if (energy == DayEnergyKind.restDay) {
      switch (g) {
        case TenGod.jeonggwan:
          return '오늘은 자리 관련 얘기를 무리해서 끌어올리지 않아도 돼요';
        case TenGod.pyeongwan:
          return '새 일 얘기가 들어와도 오늘은 떠맡기보다 한 박자 두는 쪽이 잘 맞아요';
        case TenGod.sanggwan:
          return '표현하고 싶은 마음이 올라와도 오늘은 한 톤 가라앉혀 두는 쪽이 편해요';
        case TenGod.pyeonjae:
          return '큰돈 얘기가 나와도 오늘은 한 발 멀리 두고 보는 쪽이 편해요';
        case TenGod.geopjae:
          return '승부욕이 올라와도 오늘은 한 박자 늦추는 쪽이 잘 맞아요';
        case TenGod.bigyeon:
        case TenGod.siksin:
        case TenGod.jeongjae:
        case TenGod.pyeonin:
        case TenGod.jeongin:
          return _godPhraseKo(g);
      }
    }
    // R98 — geopjae 변형 pool (non-restDay 기본 톤 분산).
    if (g == TenGod.geopjae) {
      return _geopjaeNonRestPool[seed % _geopjaeNonRestPool.length];
    }
    return _godPhraseKo(g);
  }

  /// R98 — geopjae (non-restDay) 본문 godPhrase 3-pool.
  /// 동일 사용자 (dayStem+dayBranch) + 오늘 stem hash 로 deterministic pick.
  /// R108 ③-3 — 헤드라인체("~날이에요") 0. 발동조건형으로.
  static const List<String> _geopjaeNonRestPool = [
    '오늘은 또래나 가까운 사람과 비교가 한 번씩 떠오르면, 그건 그냥 지나가는 신호니까 너무 붙들지 않아도 돼요',
    '오늘은 누가 한 발 앞서 보이면 평소보다 신경이 그쪽으로 갈 수 있으니, 그럴 땐 내 한 가지에만 손을 둬요',
    '오늘은 가까운 사람 한 명이 자꾸 눈에 들어오면, 비교 대신 가벼운 안부 한 줄로 풀어봐요',
  ];

  /// R98 — mixedDay 일 때 본문 마지막 줄 (moodHook) 3-pool.
  /// 같은 사주는 항상 같은 sentence — 다른 사주 끼리는 spread.
  /// R108 ③-3 — 헤드라인체 0. 행동 권유형.
  static const List<String> _mixedDayMoodHookPool = [
    '큰 일은 잠시 두고 작은 마무리 하나에 시간을 모아보면 더 잘 풀려요',
    '급한 결정이 떠오르면 그 자리에서 정하지 말고 한 박자만 늦춰봐요',
    '오늘은 한 가지만 분명히 끝내도 충분하니, 나머지는 메모로만 남겨둬도 돼요',
  ];

  /// R98 — phrase pool deterministic pick 용 hash (FNV-1a + avalanche).
  /// 단순 DJBX33A 는 한자 codepoint base bit 가 비슷해 3-pool 에서 2 bucket
  /// 만 채워졌음 (sample 10 중 4/0/1). 자리별 salt + 두 단계 avalanche 추가.
  static int _phraseSeed(String key) {
    var h = 0x811c9dc5; // FNV offset basis
    for (var i = 0; i < key.length; i++) {
      final ch = key.codeUnitAt(i);
      h = (h ^ (ch + i * 0x9E3779B1)) & 0x7fffffff;
      h = (h * 16777619) & 0x7fffffff;
    }
    h ^= h >> 13;
    h = (h * 0x5bd1e995) & 0x7fffffff;
    h ^= h >> 15;
    return h & 0x7fffffff;
  }

  static String _godPhraseEnByEnergy(TenGod g, DayEnergyKind energy) {
    if (energy == DayEnergyKind.restDay) {
      switch (g) {
        case TenGod.jeonggwan:
          return 'there is no need to push position talk up today';
        case TenGod.pyeongwan:
          return 'if new work comes up, leaving it a beat rather than taking it on is the better move today';
        case TenGod.sanggwan:
          return 'if the urge to speak up rises, turning it down a notch tends to feel easier today';
        case TenGod.pyeonjae:
          return "if big-money talk comes up, keeping it at arm's length pays off today";
        case TenGod.geopjae:
          return 'if a competitive streak rises, easing it by a beat tends to help today';
        case TenGod.bigyeon:
        case TenGod.siksin:
        case TenGod.jeongjae:
        case TenGod.pyeonin:
        case TenGod.jeongin:
          return _godPhraseEn(g);
      }
    }
    return _godPhraseEn(g);
  }

  static String _godPhraseKo(TenGod g) {
    // R86 sprint 4 — 사용자 mandate verbatim:
    //   "사람이랑 부딪히는데 큰 충돌없이 지나간다니 앞뒤가 안맞아"
    // 강한 충돌 phrase ("부딪칠 일이 생겨요" 등) 약화 — branch neutral 의 "큰 충돌 없이"
    // 와 함께 합성돼도 모순 0 보장.
    // R108 ③-3 — 헤드라인체 0, jargon 0. 사건은 무조건 발동조건형("~하면 ~")으로 —
    // 그날 아무 일도 안 생겨도 틀리지 않게.
    switch (g) {
      case TenGod.bigyeon:
        return '친구나 동료처럼 비슷한 자리의 사람이 떠오르면, 오늘은 먼저 한 발 다가가도 잘 받아주는 편이에요';
      case TenGod.geopjae:
        return '누가 한 발 앞서 보여서 비교가 떠오르면, 오늘은 그 마음을 붙들지 말고 내 한 가지에만 손을 둬요';
      case TenGod.siksin:
        return '표현하고 싶은 게 있으면 오늘 꺼내봐요 — 말과 글이 평소보다 한결 가볍게 나가는 편이에요';
      case TenGod.sanggwan:
        return '재능을 보여줄 일이 생기면 오늘은 잘 드러나는 편이니, 윗사람한테는 톤만 한 단계 부드럽게 가요';
      case TenGod.pyeonjae:
        return '돈이나 기회 얘기가 나오면, 오늘은 바로 정하기보다 한 번 더 확인하고 가는 쪽이 잘 맞아요';
      case TenGod.jeongjae:
        return '수입이나 약속을 챙길 일이 있으면, 오늘은 차곡차곡 정리해두기 좋은 편이에요';
      case TenGod.pyeongwan:
        return '큰 책임이나 새 도전 얘기가 들어오면, 오늘은 그 자리에서 답하지 말고 한 박자 두고 봐요';
      case TenGod.jeonggwan:
        return '인정받을 일이나 자리 관련 얘기가 오가면, 오늘은 평소보다 한 단계만 갖춰서 가면 잘 받쳐줘요';
      case TenGod.pyeonin:
        return '혼자 깊게 파고들 일이 있으면 오늘 손대봐요 — 직관이 평소보다 한 칸 또렷한 편이에요';
      case TenGod.jeongin:
        return '배우거나 도움을 청할 일이 있으면, 오늘은 멘토·선생님 쪽으로 한 발 다가가기 좋은 편이에요';
    }
  }

  static String _godPhraseEn(TenGod g) {
    // R108 ③-3 — condition/trigger form, no verdict. The r99 English-quality
    // guard forbidden-phrase list is honored here (no AI-cliche carriers).
    // R108 ③-3 — condition form ("if ~"), no event verdict.
    switch (g) {
      case TenGod.bigyeon:
        return 'if a friend or coworker on your level comes to mind, '
            'stepping toward them first tends to land well';
      case TenGod.geopjae:
        return 'if a comparison comes up because someone seems a step '
            'ahead, keeping your hands on your one thing is the steadier move';
      case TenGod.siksin:
        return 'if you have something to express, putting it out today '
            'tends to come easier than usual';
      case TenGod.sanggwan:
        return 'if a chance to show your talent comes up, a softer tone '
            'around senior people tends to help';
      case TenGod.pyeonjae:
        return 'if money or a chance comes up, checking once more before '
            'you settle it pays off';
      case TenGod.jeongjae:
        return 'if there is income or a promise to look after, sorting it '
            'steadily works well today';
      case TenGod.pyeongwan:
        return 'if a bigger ask or a new challenge comes in, leaving it a '
            'beat rather than answering on the spot is the better move';
      case TenGod.jeonggwan:
        return 'if recognition or position talk passes back and forth, '
            'lifting your manner one notch tends to back you up';
      case TenGod.pyeonin:
        return 'if there is something to dig into alone, reaching for it '
            'today works well — your read runs a notch clearer';
      case TenGod.jeongin:
        return 'if there is something to learn or help to ask for, '
            'stepping toward a mentor tends to land well';
    }
  }

  static _BranchRelation _branchRelation(String userJi, String todayJi) {
    if (userJi == todayJi) return _BranchRelation.same;
    const hap6 = {
      '子': '丑',
      '丑': '子',
      '寅': '亥',
      '亥': '寅',
      '卯': '戌',
      '戌': '卯',
      '辰': '酉',
      '酉': '辰',
      '巳': '申',
      '申': '巳',
      '午': '未',
      '未': '午',
    };
    if (hap6[userJi] == todayJi) return _BranchRelation.hap;
    const chung = {
      '子': '午',
      '丑': '未',
      '寅': '申',
      '卯': '酉',
      '辰': '戌',
      '巳': '亥',
      '午': '子',
      '未': '丑',
      '申': '寅',
      '酉': '卯',
      '戌': '辰',
      '亥': '巳',
    };
    if (chung[userJi] == todayJi) return _BranchRelation.chung;
    return _BranchRelation.neutral;
  }

  static String _branchRelationKo(_BranchRelation r, [int seed = 0]) {
    // R86 sprint 4 — neutral phrase 의 "큰 충돌 없이" 표현이 godPhrase 와
    // 모순(예: 겁재 "부딪칠 일이 생겨요" + neutral "충돌 없이") 을 일으켜 사용자 직발.
    // 모순 가능성 없는 중립 톤으로 갱신.
    // R98 — neutral 7/10 반복 fix. seed 기반 5-pool deterministic pick.
    // R108 ③-3 — "오늘은 ~날이에요" 헤드라인체 0. jargon("일지") 노출 0.
    switch (r) {
      case _BranchRelation.same:
        return '오늘 기운이 당신과 같은 결로 들어와서, 평소 습관·말버릇이 한 칸 더 선명하게 비칠 수 있으니 말 한마디만 평소처럼 차분히 가요';
      case _BranchRelation.hap:
        return '오늘 기운이 당신과 잘 맞물리는 결이라, 미뤄둔 연락이나 사람 사이 일을 오늘 풀어보면 평소보다 매끄럽게 가요';
      case _BranchRelation.chung:
        return '오늘 기운이 당신과 살짝 어긋나는 결이라, 마음이 어디로 쏠리면 그 자리에서 큰 결정을 정하기보다 한 박자 두고 봐요';
      case _BranchRelation.neutral:
        return _branchNeutralPool[seed % _branchNeutralPool.length];
    }
  }

  /// R98 — branch neutral 본문 5-pool.
  /// 같은 사용자 + 오늘 hash 로 deterministic pick — 같은 사주는 항상 같은 sentence.
  /// "충돌/부딪" 단어 0 (R86 sprint 4 invariant 보존).
  /// R108 ③-3 — "본인 페이스/자기 결대로/분위기" boilerplate 제거, jargon("일지") 0.
  static const List<String> _branchNeutralPool = [
    '오늘 기운은 당신과 특별히 엮이지 않아서, 밖에 휘둘리기보다 하던 한 가지에 손을 두면 잘 풀려요',
    '오늘 기운은 당신과 큰 접점이 없어서, 새 신호를 찾기보다 하던 흐름을 이어가는 쪽이 잘 맞아요',
    '오늘 기운은 당신과 부딪치지도 맞물리지도 않아서, 욕심내지 말고 한 가지만 챙겨도 충분해요',
    '오늘 기운은 당신과 거리를 둔 결이라, 평소 챙기던 한 가지를 다시 잡아보면 좋아요',
    '오늘 기운은 당신과 따로 도는 결이라, 큰 결정을 서두르기보다 평소 페이스대로 가면 돼요',
  ];

  static String _branchRelationEn(_BranchRelation r) {
    // R108 ③-3 — condition form, no day verdict. No saju jargon carriers.
    switch (r) {
      case _BranchRelation.same:
        return "Today's current runs in the same groove as yours, so your "
            'usual habits can read a notch clearer — keep a remark as calm '
            'as usual';
      case _BranchRelation.hap:
        return "Today's current locks in well with yours, so working "
            'through a postponed message or a people matter today tends to '
            'go more smoothly';
      case _BranchRelation.chung:
        return "Today's current sits a little off from yours, so if your "
            'mind tilts somewhere, leaving a big call a beat is the safer move';
      case _BranchRelation.neutral:
        // R86 sprint 4 — drop "clash" wording (clashed with 겁재 godPhrase).
        return "Today's current barely meets yours, so rather than chasing "
            'a new signal, keeping your hands on one usual thing works best';
    }
  }

  static ({String ko, String en}) _elementMood(
    String dominant,
    String deficit,
    String todayEl,
  ) {
    const koEl = {'木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물'};
    const enEl = {
      '木': 'wood',
      '火': 'fire',
      '土': 'earth',
      '金': 'metal',
      '水': 'water',
    };
    // R108 ③-3 — "균형" 금지어 제거. "당신 사주/chart" meta 제거. 발동조건형.
    if (todayEl == dominant) {
      return (
        ko: '오늘은 ${koEl[dominant]} 기운이 들어와서, 당신이 평소에 강한 ${koEl[dominant]} 색이 한 칸 더 진하게 비칠 수 있어요',
        en: 'Today, an incoming ${enEl[todayEl]} current tends to bring out '
            'your already-strong ${enEl[todayEl]} side a touch more',
      );
    }
    if (todayEl == deficit) {
      return (
        ko: '오늘은 ${koEl[deficit]} 기운이 들어와서, 당신이 평소에 옅은 ${koEl[deficit]} 쪽이 살짝 보태질 수 있어요',
        en: 'Today, an incoming ${enEl[deficit]} current tends to lend a hand '
            'to your usually lighter ${enEl[deficit]} side',
      );
    }
    return (
      ko: '오늘은 ${koEl[todayEl]} 기운이 들어오는데, 당신과 따로 도는 결이라 한 번 의식해두면 그 색을 골라 쓰기 좋아요',
      en: 'Today, an incoming ${enEl[todayEl]} current runs apart from your '
          'usual mix, so noticing it once tends to make it easy to draw on',
    );
  }

  static ({String ko, String en}) _bestTimeFor(String todayJi) {
    const map = {
      '子': (ko: '밤 11시 ~ 새벽 1시', en: '11 PM – 1 AM'),
      '丑': (ko: '새벽 1시 ~ 3시', en: '1 AM – 3 AM'),
      '寅': (ko: '새벽 3시 ~ 5시', en: '3 AM – 5 AM'),
      '卯': (ko: '아침 5시 ~ 7시', en: '5 AM – 7 AM'),
      '辰': (ko: '아침 7시 ~ 9시', en: '7 AM – 9 AM'),
      '巳': (ko: '오전 9시 ~ 11시', en: '9 AM – 11 AM'),
      '午': (ko: '낮 11시 ~ 1시', en: '11 AM – 1 PM'),
      '未': (ko: '낮 1시 ~ 3시', en: '1 PM – 3 PM'),
      '申': (ko: '오후 3시 ~ 5시', en: '3 PM – 5 PM'),
      '酉': (ko: '저녁 5시 ~ 7시', en: '5 PM – 7 PM'),
      '戌': (ko: '저녁 7시 ~ 9시', en: '7 PM – 9 PM'),
      '亥': (ko: '밤 9시 ~ 11시', en: '9 PM – 11 PM'),
    };
    return map[todayJi] ?? (ko: '낮 11시 ~ 1시', en: '11 AM – 1 PM');
  }

  // Round 71 — `DayEnergyKind` 기반 hook 변주. actionDay 에 "쉬어가/아끼" 단어 0회,
  // restDay 에 "공식/도전/승진" 단어 0회 (사용자 불만 #3).
  static ({String moodKo, String moodEn, String bodyHookKo, String bodyHookEn})
  _hooksByEnergy(DayEnergyKind energy) {
    // R108 ③-3 — moodKo 는 chip 한 단어 (헤드라인체 X). bodyHookKo 는 body 마지막
    // 줄로 합성되니 행동 권유형.
    switch (energy) {
      case DayEnergyKind.actionDay:
        return (
          moodKo: '움직이기 좋은',
          moodEn: 'good for moving',
          bodyHookKo: '미뤄둔 일 하나는 오늘 손에 들어도 좋아요',
          bodyHookEn:
              'Picking up one thing you have been putting off can work well today',
        );
      case DayEnergyKind.mixedDay:
        return (
          moodKo: '차분히 다지는',
          moodEn: 'steady and measured',
          bodyHookKo: '큰 결정은 한 박자 두고, 확인이 필요한 일 하나만 끝내봐요',
          bodyHookEn:
              'Leave a big decision a beat and finish just one thing that needs a check',
        );
      case DayEnergyKind.restDay:
        return (
          moodKo: '쉬어가는',
          moodEn: 'quiet and restful',
          bodyHookKo: '새로 벌리기보다 몸과 마음을 한 칸 채우는 쪽으로 가봐요',
          bodyHookEn:
              'Leaning toward refilling your body and mind, rather than a new start, is the better call',
        );
    }
  }

  // R96 hotfix — 의미 무관한 5-sentence random paragraph 만들지 마.
  // opening + godKo + branchKo + moodHook (4 sentence) 만 유지.
  // middleHook (망설이던 일 / 새 판 / 억지로 밀어붙이면) + elementKo 라인은
  // godKo/branchKo 와 인과관계 없는 random atom 이라 제거.
  // ctx 주입 시 _daewoonAnchor + gyeokgukAnchor + yongsinSuffix 가 1 sentence
  // append 되므로 총 4~5 sentence.
  // R97 — mixedDay 5개 변형 pool. 사용자 사주 anchor (일간 + 일지 + 오늘 일지)
  // hash 로 deterministic pick — 같은 사주는 항상 같은 sentence.
  /// R108 ③-3 — "오늘은 ~날이에요" 헤드라인체 0. 행동 권유형으로.
  static const List<String> _mixedDayOpeningPool = [
    '오늘은 한 번에 멀리 가기보다 한 발씩 정리하는 쪽으로 가면 잘 풀려요.',
    '오늘은 끝내야 할 일 한 가지에 시간을 모아보면 흐름이 잡혀요.',
    '오늘은 결과를 서두르기보다 흐름을 먼저 잡아두는 쪽이 잘 맞아요.',
    '오늘은 큰 그림보다 그동안 미뤄둔 작은 것 한 가지를 매듭지어보면 좋아요.',
    '오늘은 새로 벌리기보다 하던 일에 한 박자 힘을 더 모아보면 단단해져요.',
  ];

  /// R97 → R98 — FNV-1a 변형 hash + rotational salt.
  /// 기존 `h * 131 + ch` 단순 polynomial 은 한자 codepoint (~0x4E00 base)가 비슷해
  /// 5-pool % 가 2-3 bucket 에 몰림 (sample 10 중 idx 0/2/3 만). FNV-1a + 위치별
  /// salt 로 한자 base bit 까지 흩뜨려 5 bucket 골고루 분산.
  static int _mixedOpeningSeed({
    required String userDayStem,
    required String userDayBranch,
    required String todayBranch,
  }) {
    var h = 0x811c9dc5; // FNV offset basis
    final key = '$userDayStem$userDayBranch$todayBranch';
    for (var i = 0; i < key.length; i++) {
      final ch = key.codeUnitAt(i);
      // 위치 salt 와 함께 mix — 같은 한자라도 자리 다르면 다른 영향.
      h = (h ^ (ch + i * 0x9E3779B1)) & 0x7fffffff;
      h = (h * 16777619) & 0x7fffffff;
    }
    // 추가 avalanche — 상위 bit 까지 5-pool 까지 잘 흘러내려가게.
    h ^= h >> 13;
    h = (h * 0x5bd1e995) & 0x7fffffff;
    h ^= h >> 15;
    return h & 0x7fffffff;
  }

  static String _composeBodyKo({
    required String userDayStem,
    required String godKo,
    required String branchKo,
    required String elementKo,
    required String moodHookKo,
    required DayEnergyKind energy,
    int mixedOpeningSeed = 0,
  }) {
    final parts = <String>[];
    // R108 ③-3 — opening 을 일간 비유에 anchor (my_saju_v5 톤). 헤드라인체 0.
    // 비유는 opening 한 문장 안에 녹여 sentence 수는 그대로 (opening+god+branch+
    // moodHook = 4, ctx 시 5 — R85 cap 보존).
    final who = _stemMetaphorKoOf(userDayStem);
    switch (energy) {
      case DayEnergyKind.actionDay:
        parts.add('$who한테, 오늘은 마음먹은 걸 한 발 밖으로 꺼내봐도 잘 받쳐주는 편이에요.');
      case DayEnergyKind.mixedDay:
        final idx = mixedOpeningSeed % _mixedDayOpeningPool.length;
        parts.add('$who한테, ${_mixedDayOpeningPool[idx]}');
      case DayEnergyKind.restDay:
        parts.add('$who한테, 오늘은 속도를 늦추고 안쪽을 정리하는 쪽이 잘 맞아요.');
    }
    if (godKo.isNotEmpty) parts.add('$godKo.');
    parts.add('$branchKo.');
    parts.add('$moodHookKo.');
    return NaturalProseJoiner.join(parts);
  }

  static String _composeBodyEn({
    required String userDayStem,
    required String godEn,
    required String branchEn,
    required String elementEn,
    required String moodHookEn,
    required DayEnergyKind energy,
  }) {
    final parts = <String>[];
    // R108 ③-3 — opening anchored to the day-stem metaphor.
    final who = _stemMetaphorEnOf(userDayStem);
    switch (energy) {
      case DayEnergyKind.actionDay:
        parts.add('For $who, putting something you have in mind a step out '
            'into the open tends to be well met today.');
      case DayEnergyKind.mixedDay:
        parts.add('For $who, sorting things out a step at a time tends to '
            'fit better than forcing a big move today.');
      case DayEnergyKind.restDay:
        parts.add('For $who, slowing down and clearing some space tends to '
            'fit best today.');
    }
    if (godEn.isNotEmpty) parts.add('Today, $godEn.');
    parts.add('$branchEn.');
    // R96 hotfix — drop random middleHook + elementEn line. Same intent as
    // _composeBodyKo: avoid stitching meaning-unrelated atoms.
    parts.add('$moodHookEn.');
    return parts.join(' ');
  }

  // Round 71 사용자 불만 #3 — `DayEnergyKind` 단일 source-of-truth.
  // restDay 일 때 jeonggwan/pyeongwan 의 "공식 자리·발표·승진" / "도전·승부" 출력 0.
  // actionDay 일 때 "쉬어가 / 아끼" 출력 0.
  static List<String> _actionsKo(TenGod? god, _BranchRelation rel, int score) {
    final out = <String>[];
    final dayEnergy = classifyDayEnergy(score);
    // 1) 십신 기반 — restDay 면 행동권유형 행동을 묵은 정리 / 회복으로 대체.
    if (god != null) {
      out.add(_actionForGodKoByEnergy(god, dayEnergy));
    }
    // 2) 지지 관계 기반 — 단정 톤 + restDay 보정.
    if (rel == _BranchRelation.hap) {
      out.add(
        dayEnergy == DayEnergyKind.restDay
            ? '오늘은 새 약속 잡지 마세요. 묵은 톡 하나 정리하면 끝이에요.'
            : '미뤘던 약속·연락을 오늘 정리해요.',
      );
    } else if (rel == _BranchRelation.chung) {
      out.add('중요한 통화·약속은 내일로 미뤄요.');
    } else if (rel == _BranchRelation.same) {
      out.add('평소 루틴(운동·정리·습관) 하나를 오늘 다시 잡아요.');
    } else {
      out.add('짧게 걷거나 책상 한 칸만 치워도 오늘 흐름이 잡혀요.');
    }
    // 3) 분류 기반 — actionDay 한정으로 적극 표현, restDay 한정으로 회복 표현.
    switch (dayEnergy) {
      case DayEnergyKind.actionDay:
        out.add('자기 분야의 한 사람에게 먼저 연락해요. 그 한 줄이 큰 인연이 돼요.');
      case DayEnergyKind.restDay:
        out.add('오늘 만든 결과보다 오늘 회복한 에너지가 내일을 정해요.');
      case DayEnergyKind.mixedDay:
        break;
    }
    return out;
  }

  static List<String> _actionsEn(TenGod? god, _BranchRelation rel, int score) {
    final out = <String>[];
    final dayEnergy = classifyDayEnergy(score);
    if (god != null) out.add(_actionForGodEnByEnergy(god, dayEnergy));
    if (rel == _BranchRelation.hap) {
      out.add(
        dayEnergy == DayEnergyKind.restDay
            ? "Don't book new plans. Tidy one postponed message — that's it."
            : 'Close postponed promises and calls today — they flow.',
      );
    } else if (rel == _BranchRelation.chung) {
      out.add('Defer big contracts and important calls to tomorrow.');
    } else if (rel == _BranchRelation.same) {
      out.add('Push your usual routine harder — workout, tidy, habit.');
    } else {
      out.add('A short walk or one tidy task sets the day right.');
    }
    switch (dayEnergy) {
      case DayEnergyKind.actionDay:
        out.add(
          'Reach out to one person in your field first — small signal, big result.',
        );
      case DayEnergyKind.restDay:
        out.add('Recovering today wins more than working today.');
      case DayEnergyKind.mixedDay:
        break;
    }
    return out;
  }

  /// restDay 보정 — jeonggwan / pyeongwan / sanggwan 처럼 공격적 행동을 권유하는
  /// 십신 멘트가 score<50 에서 나오면 모순이라 회복형으로 대체.
  static String _actionForGodKoByEnergy(TenGod god, DayEnergyKind energy) {
    if (energy == DayEnergyKind.restDay) {
      // 공식 자리·도전·발표 → 회복·정리·짧은 한 줄.
      switch (god) {
        case TenGod.jeonggwan:
          return '오늘은 격식 있는 자리 잡지 마세요. 자료 하나 다듬는 편이 좋아요.';
        case TenGod.pyeongwan:
          return '오늘은 새 일 떠맡지 마세요. 받기 전 한 박자 쉬어요.';
        case TenGod.sanggwan:
          return '오늘은 표현 줄여요. 한 박자 천천히 들으면 흐름이 잡혀요.';
        case TenGod.pyeonjae:
          return '큰 돈 결정 잡지 마세요. 정보 하나 정리하면 끝이에요.';
        case TenGod.geopjae:
          return '동업·돈 거래는 오늘 진행하지 마세요. 한 박자 더 쉬어요.';
        default:
          return _actionForGodKo(god);
      }
    }
    return _actionForGodKo(god);
  }

  static String _actionForGodEnByEnergy(TenGod god, DayEnergyKind energy) {
    if (energy == DayEnergyKind.restDay) {
      switch (god) {
        case TenGod.jeonggwan:
          return "Don't lock formal settings. Polish one doc and stop.";
        case TenGod.pyeongwan:
          return "Don't take on new asks. Pause one breath before any 'yes'.";
        case TenGod.sanggwan:
          return 'Speak less. One careful listen sets the room.';
        case TenGod.pyeonjae:
          return "Don't move big money. File one line of info and stop.";
        case TenGod.geopjae:
          return "Skip partnership and money talks. Rest one more beat.";
        default:
          return _actionForGodEn(god);
      }
    }
    return _actionForGodEn(god);
  }

  static String _actionForGodKo(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return '같은 팀·동료와 짧은 점심이나 차 한 잔 — 정보 한 줄이 답이 됩니다.';
      case TenGod.geopjae:
        return '비교 대신 협력으로 — 경쟁심 잠시 내려두면 양쪽 다 이깁니다.';
      case TenGod.siksin:
        return '글·SNS·강의 등 표현 한 가지를 오늘 만들어 보세요.';
      case TenGod.sanggwan:
        return '재능 보여주기 좋은 날 — 단, 윗사람에겐 톤 한 단계 부드럽게.';
      case TenGod.pyeonjae:
        return '큰 돈의 기회 신호 — 정보 듣고, 결정 전에 한 번 더 확인.';
      case TenGod.jeongjae:
        return '꾸준한 일·고정 수입 점검 — 작게 쌓는 결정이 빛납니다.';
      case TenGod.pyeongwan:
        return '도전·승부 받기 좋은 날 — 단, 끝까지 책임지세요.';
      case TenGod.jeonggwan:
        return '공식 자리·발표·승진 신청에 좋은 날 — 격식 한 단계 올리세요.';
      case TenGod.pyeonin:
        return '깊은 책·강의·명상 한 가지를 골라봐요 — 오늘 직관이 한 칸 또렷해지는 쪽이에요.';
      case TenGod.jeongin:
        return '오래된 멘토·선생님께 연락 한 통 — 답이 빠릅니다.';
    }
  }

  static String _actionForGodEn(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return 'A short lunch or coffee with a peer — one line of info is the answer.';
      case TenGod.geopjae:
        return 'Cooperate, do not compete — both sides win when ego rests.';
      case TenGod.siksin:
        return 'Write, post, or teach one thing today — expression flows.';
      case TenGod.sanggwan:
        return 'Showcase your talent — but soften your tone around authority figures.';
      case TenGod.pyeonjae:
        return 'A signal of bigger money — listen, then double-check before contract.';
      case TenGod.jeongjae:
        return 'Audit steady income and fixed work — small accumulations shine.';
      case TenGod.pyeongwan:
        return 'A day to accept the challenge — but follow through end-to-end.';
      case TenGod.jeonggwan:
        return 'Strong for formal settings, presentations, promotion asks.';
      case TenGod.pyeonin:
        return 'One deep book, lecture, or meditation — intuition deepens.';
      case TenGod.jeongin:
        return 'Reach out to an old mentor — replies come fast.';
    }
  }

  // Round 71 사용자 불만 #3 — `DayEnergyKind` 단일 분기로 모순 차단.
  // restDay 일 때 actionDay 톤 (도전/공식) 출력 X.
  static String _cautionKo(TenGod? god, _BranchRelation rel, int score) {
    final dayEnergy = classifyDayEnergy(score);
    if (rel == _BranchRelation.chung) {
      return '오늘은 큰 결정·약속·이별 같은 결단을 미뤄요.';
    }
    if (dayEnergy == DayEnergyKind.restDay) {
      return '오늘 에너지 다 쓰면 내일 회복이 오래 걸려요. 하나만 끝내요.';
    }
    if (god == TenGod.geopjae) {
      return '돈 거래·동업은 한 번 더 확인해요. 믿음만으로 진행하지 마세요.';
    }
    if (god == TenGod.sanggwan) {
      return '윗사람한테 말 한마디 던질 때 톤을 한 단계 부드럽게 해요.';
    }
    if (god == TenGod.pyeongwan) {
      return '갑작스러운 일 떠맡기 전 한 박자 쉬어요.';
    }
    return '말 톤을 한 단계 부드럽게 해요. 오늘은 짧은 한마디가 큰 차이를 만들어요.';
  }

  static String _cautionEn(TenGod? god, _BranchRelation rel, int score) {
    final dayEnergy = classifyDayEnergy(score);
    if (rel == _BranchRelation.chung) {
      return 'Defer big decisions, signatures, and breakups — clash day.';
    }
    if (dayEnergy == DayEnergyKind.restDay) {
      return 'Do not burn the whole battery — tomorrow gets harder to recover.';
    }
    if (god == TenGod.geopjae) {
      return 'Double-check money or partnership talks — trust alone is not enough.';
    }
    if (god == TenGod.sanggwan) {
      return 'A word with authority — soften your tone one notch.';
    }
    if (god == TenGod.pyeongwan) {
      return 'Avoid being swept into sudden responsibility — pause before accepting.';
    }
    return 'Soften the tone one notch — small expression makes the big difference.';
  }
}

enum _BranchRelation { same, hap, chung, neutral }
