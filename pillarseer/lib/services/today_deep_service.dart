// ignore_for_file: unused_field
// Pillar Seer — 오늘 운세 깊이 풀이 서비스 (Round 11+).
//
// 사용자 사주 + 오늘 일진 → 5-7문장 narrative + 행동 추천 + 조심 + 시간대.
// 중학생도 5초 안에 이해할 톤. 명리 jargon은 괄호 안에만.
//
// 입력:
//   - userSaju.dayPillar.chunGan (사용자 일간)
//   - userSaju.dayPillar.jiJi (사용자 일지)
//   - userSaju.monthPillar.jiJi (사용자 월지 — 계절 보정)
//   - userSaju.elements.dominant / deficit (5행 균형)
//   - 오늘 일진 (60갑자) — DailyService 로부터
//
// 출력 (TodayDeepReading):
//   - headlineKo / headlineEn: 한 줄 분위기 (예: "오늘은 '깊은 물 같은 사람'에게 따스한 바람이 부는 날.")
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
  final String moodTagKo;  // 한 단어 — 화면 chip
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
    required String userDayStem,        // 사용자 일간 (천간)
    required String userDayBranch,      // 사용자 일지
    required String userMonthBranch,    // 사용자 월지
    required String userDominantEl,     // 사용자 5행 강함
    required String userDeficitEl,      // 사용자 5행 약함
    required String todayPillar,        // 오늘 60갑자 (예: '丙戌')
    required int todayScore,            // 0-100
    SajuContext? ctx,                   // Round 78 sprint 4 — 격국·용신 derive
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
    // narrative 조합 — godPhrase 와 hook 모두 dayEnergy 기반.
    final godKo = god == null ? '' : _godPhraseKoByEnergy(god, dayEnergy);
    final godEn = god == null ? '' : _godPhraseEnByEnergy(god, dayEnergy);
    final brKo = _branchRelationKo(branchRelation);
    final brEn = _branchRelationEn(branchRelation);

    final hooks = _hooksByEnergy(dayEnergy);

    final headlineKo = '오늘은 ${hooks.moodKo} 분위기의 하루.';
    final headlineEn = "Today's mood: ${hooks.moodEn}.";

    var bodyKo = _composeBodyKo(
      godKo: godKo,
      branchKo: brKo,
      elementKo: elementMood.ko,
      moodHookKo: hooks.bodyHookKo,
    );
    var bodyEn = _composeBodyEn(
      godEn: godEn,
      branchEn: brEn,
      elementEn: elementMood.en,
      moodHookEn: hooks.bodyHookEn,
    );

    // Round 78 sprint 4 — ctx 주입 시 격국 anchor + 용신 5축 derive suffix 합성.
    // 같은 십신·dayEnergy 라도 격국·용신 다르면 본문 phrase 차이 ≥1 보장.
    if (ctx != null) {
      final gAnchorKo = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'ko');
      final ySuffixKo = DynamicTextResolver.yongsinSuffix(ctx, locale: 'ko');
      final extraKo =
          [gAnchorKo, ySuffixKo].where((p) => p.isNotEmpty).join(' ');
      if (extraKo.isNotEmpty) {
        bodyKo = '$bodyKo $extraKo';
      }
      final gAnchorEn = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'en');
      final ySuffixEn = DynamicTextResolver.yongsinSuffix(ctx, locale: 'en');
      final extraEn =
          [gAnchorEn, ySuffixEn].where((p) => p.isNotEmpty).join(' ');
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

    final cautionKo = _cautionKo(god, branchRelation, todayScore);
    final cautionEn = _cautionEn(god, branchRelation, todayScore);

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

  static String _elementOfStem(String stem) {
    const map = {
      '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
      '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
    };
    return map[stem] ?? '木';
  }

  // Round 71 — restDay 일 때 "승진/공식 자리/도전" 류 단어가 bodyKo 에 등장하면
  // 사용자 불만 #3 (모순) 재발. dayEnergy 별 godPhrase 변주로 차단.
  // Round 74 — '분위기' 5회 반복 분산. 일상 평서.
  static String _godPhraseKoByEnergy(TenGod g, DayEnergyKind energy) {
    if (energy == DayEnergyKind.restDay) {
      switch (g) {
        case TenGod.jeonggwan:
          return '평소 자리 관련 얘기가 오늘은 잠잠하다';
        case TenGod.pyeongwan:
          return '오늘은 새 일 떠맡기에 어울리는 날이 아니에요';
        case TenGod.sanggwan:
          return '표현 욕구가 평소보다 조용해져요';
        case TenGod.pyeonjae:
          return '큰돈 얘기는 오늘 멀리 가요';
        case TenGod.geopjae:
          return '경쟁심이 평소보다 가라앉아요';
        case TenGod.bigyeon:
        case TenGod.siksin:
        case TenGod.jeongjae:
        case TenGod.pyeonin:
        case TenGod.jeongin:
          return _godPhraseKo(g);
      }
    }
    return _godPhraseKo(g);
  }

  static String _godPhraseEnByEnergy(TenGod g, DayEnergyKind energy) {
    if (energy == DayEnergyKind.restDay) {
      switch (g) {
        case TenGod.jeonggwan:
          return 'not your day for big formal moves';
        case TenGod.pyeongwan:
          return 'not a day to pick up new tasks';
        case TenGod.sanggwan:
          return 'the urge to speak up quiets down';
        case TenGod.pyeonjae:
          return "big money decisions don't fit";
        case TenGod.geopjae:
          return 'competition cools off';
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
    switch (g) {
      case TenGod.bigyeon:
        return '오늘은 친구나 동료처럼 당신과 같은 자리 사람이 가까워져요';
      case TenGod.geopjae:
        return '오늘은 비슷한 자리 사람이랑 부딪칠 일이 생겨요';
      case TenGod.siksin:
        return '오늘은 표현·창작이 잘 풀려서 말과 글이 가벼워져요';
      case TenGod.sanggwan:
        return '재능이 빛나는 날이에요. 윗사람한테 톤만 한 단계 부드럽게 가요';
      case TenGod.pyeonjae:
        return '뜻밖의 기회나 큰돈 얘기가 당신한테 와요';
      case TenGod.jeongjae:
        return '꾸준한 수입·약속이 자리 잡는 흐름이에요';
      case TenGod.pyeongwan:
        return '큰 책임이나 새 도전이 갑자기 당신한테 다가와요';
      case TenGod.jeonggwan:
        return '인정받을 일이나 자리 관련 얘기가 오늘 생겨요';
      case TenGod.pyeonin:
        return '오늘은 깊은 공부·직관이 당신한테 강해져요';
      case TenGod.jeongin:
        return '배움·멘토·도움이 당신한테 자연스럽게 와요';
    }
  }

  static String _godPhraseEn(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return 'peers come your way — friends or coworkers at your level';
      case TenGod.geopjae:
        return 'someone at your level pushes back. expect friction';
      case TenGod.siksin:
        return 'your words land light. expression flows easy';
      case TenGod.sanggwan:
        return 'your talent shines. just watch your tone with the boss';
      case TenGod.pyeonjae:
        return 'an unexpected money opening shows up';
      case TenGod.jeongjae:
        return 'steady income and promises lock in';
      case TenGod.pyeongwan:
        return 'a big ask or challenge lands fast';
      case TenGod.jeonggwan:
        return 'recognition, promotion, or formal moves come in';
      case TenGod.pyeonin:
        return 'deep study and intuition hit strong';
      case TenGod.jeongin:
        return 'learning, mentors, and help come naturally';
    }
  }

  static _BranchRelation _branchRelation(String userJi, String todayJi) {
    if (userJi == todayJi) return _BranchRelation.same;
    const hap6 = {
      '子': '丑', '丑': '子', '寅': '亥', '亥': '寅', '卯': '戌',
      '戌': '卯', '辰': '酉', '酉': '辰', '巳': '申', '申': '巳',
      '午': '未', '未': '午',
    };
    if (hap6[userJi] == todayJi) return _BranchRelation.hap;
    const chung = {
      '子': '午', '丑': '未', '寅': '申', '卯': '酉', '辰': '戌', '巳': '亥',
      '午': '子', '未': '丑', '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
    };
    if (chung[userJi] == todayJi) return _BranchRelation.chung;
    return _BranchRelation.neutral;
  }

  static String _branchRelationKo(_BranchRelation r) {
    switch (r) {
      case _BranchRelation.same:
        return '오늘 흐름이 당신 사주랑 같아서 평소 습관이 강하게 나와요';
      case _BranchRelation.hap:
        return '오늘 흐름이 당신 사주랑 잘 맞아서 인연이 자연스럽게 풀려요';
      case _BranchRelation.chung:
        return '오늘 흐름이 당신 사주랑 부딪쳐서 마음이 흔들리고 결정이 어려워요';
      case _BranchRelation.neutral:
        return '오늘 흐름은 당신 사주랑 크게 안 부딪치고 잔잔하게 가요';
    }
  }

  static String _branchRelationEn(_BranchRelation r) {
    switch (r) {
      case _BranchRelation.same:
        return 'today matches your chart, so your usual habits show up strong';
      case _BranchRelation.hap:
        return 'today fits your chart well, so connections come easy';
      case _BranchRelation.chung:
        return 'today clashes with your chart, so decisions feel shaky';
      case _BranchRelation.neutral:
        return "today doesn't clash with your chart. things move quietly";
    }
  }

  static ({String ko, String en}) _elementMood(String dominant, String deficit, String todayEl) {
    const koEl = {'木':'나무','火':'불','土':'흙','金':'쇠','水':'물'};
    const enEl = {'木':'wood','火':'fire','土':'earth','金':'metal','水':'water'};
    if (todayEl == dominant) {
      return (
        ko: '평소 강한 ${koEl[dominant]} 색이 오늘 더 짙어져요',
        en: 'your strong ${enEl[todayEl]} side gets even stronger today',
      );
    }
    if (todayEl == deficit) {
      return (
        ko: '평소 부족한 ${koEl[deficit]} 색이 오늘 채워져요',
        en: 'your weak ${enEl[deficit]} side gets a boost today',
      );
    }
    return (
      ko: '오늘은 ${koEl[todayEl]} 색이 강한 하루예요',
      en: '${enEl[todayEl]} sets the tone today',
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
    switch (energy) {
      case DayEnergyKind.actionDay:
        return (
          moodKo: '활짝 열린',
          moodEn: 'wide open',
          bodyHookKo: '평소 못 하던 일을 오늘 시작하면 흐름이 당신 편이에요',
          bodyHookEn: 'a good day to start what you usually delay',
        );
      case DayEnergyKind.mixedDay:
        return (
          moodKo: '잔잔한',
          moodEn: 'calm',
          bodyHookKo: '큰 결정은 미뤄요. 작은 확인 하나만 끝내면 돼요',
          bodyHookEn: 'skip big calls. just confirm one small thing',
        );
      case DayEnergyKind.restDay:
        return (
          moodKo: '쉬어가는',
          moodEn: 'restful',
          bodyHookKo: '오늘은 새로 시작하지 않는 게 나아요. 회복 하나가 정답이에요',
          bodyHookEn: 'not a day to start. recovery is the real win',
        );
    }
  }

  static String _composeBodyKo({
    required String godKo,
    required String branchKo,
    required String elementKo,
    required String moodHookKo,
  }) {
    final parts = <String>[];
    if (godKo.isNotEmpty) parts.add('$godKo.');
    parts.add('$branchKo.');
    parts.add('$elementKo.');
    parts.add('$moodHookKo.');
    return parts.join(' ');
  }

  static String _composeBodyEn({
    required String godEn,
    required String branchEn,
    required String elementEn,
    required String moodHookEn,
  }) {
    final parts = <String>[];
    if (godEn.isNotEmpty) parts.add('Today: $godEn.');
    parts.add('$branchEn.');
    parts.add('$elementEn.');
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
        out.add('Reach out to one person in your field first — small signal, big result.');
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
          return '오늘은 격식 있는 자리 잡지 마세요. 자료 하나 다듬는 게 정답이에요.';
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
        return '깊은 책·강의·명상 한 가지 — 직관이 가장 깊어지는 날.';
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
