// Pillar Seer — Round 76/77 — 오늘 사건 가능성 엔진.
//
// 입력: 사용자 일간/일지/월지 + 오늘 60갑자 + 오늘 score (Round 71 DayEnergyKind).
// 출력: 6 카테고리 (relationship/money/work/love/health/luck) 점수 + dominant/sub
//        + 별점 4 (love/money/work/health) + 활성 신살 + 합충형파해 + 사주 근거 단락.
//
// 톤 mandate: "오늘 ~ 생기기 쉬워요 / 흐름이 강해요 / 가능성이 있어요" 가능성 헷지.
// 단정 예언 (오늘 반드시 ~, 사고가 ~, 큰돈을 잃, 병원) 금지.
// 사용자 verbatim 매핑: 재성→돈, 관성→일, 인성→건강, 식상→일/관계, 비겁→관계.
//
// Round 77 sprint 2 — today_event_pool.json (90 entries / 30 key) wire 완료.
// `composeBodyKo` 가 pool entry 우선 + fallback 6분기. home/result/notification 3 호출처 사용.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'daily_service.dart' show DayEnergyKind, classifyDayEnergy;
import 'hapchung_service.dart';
import 'shinsa_service.dart';
import 'ten_gods_service.dart';

/// 6 카테고리. 사용자 verbatim 우선 매핑.
enum EventCategory {
  relationship, // 인간관계
  money, // 돈/소비
  work, // 일/공부
  love, // 연애/호감
  health, // 건강/컨디션
  luck, // 기회/행운
}

/// 5 십성 그룹.
enum TenGodGroup {
  bigyeop, // 비겁 (비견+겁재)
  siksang, // 식상 (식신+상관)
  jaeseong, // 재성 (편재+정재)
  gwanseong, // 관성 (편관+정관)
  inseong, // 인성 (편인+정인)
}

/// today_event_pool.json key prefix 와 일치 (한국어 십신 그룹).
/// pool key 형식: `{ko}_{EventCategory.key}` (예: `비겁_relationship`).
extension TenGodGroupKo on TenGodGroup {
  String get ko {
    switch (this) {
      case TenGodGroup.bigyeop:
        return '비겁';
      case TenGodGroup.siksang:
        return '식상';
      case TenGodGroup.jaeseong:
        return '재성';
      case TenGodGroup.gwanseong:
        return '관성';
      case TenGodGroup.inseong:
        return '인성';
    }
  }
}

extension EventCategoryKo on EventCategory {
  String get ko {
    switch (this) {
      case EventCategory.relationship:
        return '인간관계';
      case EventCategory.money:
        return '돈/소비';
      case EventCategory.work:
        return '일/공부';
      case EventCategory.love:
        return '연애/호감';
      case EventCategory.health:
        return '건강/컨디션';
      case EventCategory.luck:
        return '기회/행운';
    }
  }

  /// today_event_pool.json key suffix 와 일치 (영문 카테고리 alias).
  /// pool key 형식: `{한국어 십신}_{영문 카테고리}` 예: `관성_health`.
  String get key {
    switch (this) {
      case EventCategory.relationship:
        return 'relationship';
      case EventCategory.money:
        return 'money';
      case EventCategory.work:
        return 'work';
      case EventCategory.love:
        return 'love';
      case EventCategory.health:
        return 'health';
      case EventCategory.luck:
        return 'luck';
    }
  }
}

/// 오늘 사건 가능성 reading model.
class TodayEventReading {
  final EventCategory categoryDominant;
  final EventCategory categorySub;
  final TenGodGroup tenGodGroup;
  final List<String> activeShinsa; // 도화 / 역마 / 문창귀인 / 천을귀인 / 양인 / 백호 / 괴강 / 화개
  final String hapChungType; // 합 / 충 / 형 / 파 / 해 / 없음
  final int starsLove; // 1-5
  final int starsMoney; // 1-5
  final int starsWork; // 1-5
  final int starsHealth; // 1-5
  final String sourceReason; // 2-3 문장 사주 근거 (한국어)
  final String sourceReasonEn; // 2-3 sentence reasoning (English)
  final DayEnergyKind energy;
  final Map<EventCategory, int> rawScores; // 디버그 / 정렬용

  const TodayEventReading({
    required this.categoryDominant,
    required this.categorySub,
    required this.tenGodGroup,
    required this.activeShinsa,
    required this.hapChungType,
    required this.starsLove,
    required this.starsMoney,
    required this.starsWork,
    required this.starsHealth,
    required this.sourceReason,
    this.sourceReasonEn = '',
    required this.energy,
    required this.rawScores,
  });
}

class TodayEventService {
  /// 오늘 사건 가능성 build. 같은 입력 → 같은 출력 (pure).
  static TodayEventReading build({
    required String userDayStem, // 사용자 일간 (천간)
    required String userDayBranch, // 사용자 일지
    required String userMonthBranch, // 월지 — 계절 보정 (현재 미사용, future hook)
    required String todayPillar, // 오늘 60갑자
    required int todayScore, // 0-100
  }) {
    final stem = todayPillar.isNotEmpty ? todayPillar[0] : '甲';
    final branch = todayPillar.length >= 2 ? todayPillar[1] : '子';

    // 1. 오늘 천간 → 사용자 일간 기준 십성 → 그룹.
    final god = TenGodsService.godFor(userDayStem, stem);
    final group = _groupOf(god);

    // 2. 신살 — 오늘 지지 가 사용자 일간/일지 기준 신살에 해당하면 활성.
    final active = _activeShinsa(userDayStem: userDayStem, userDayBranch: userDayBranch, todayBranch: branch);

    // 3. 합/충/형/파/해 — 오늘 지지 vs 사용자 일지.
    final relation = _branchRelation(userDayBranch, branch);

    // 4. 카테고리 점수 계산.
    final scores = _scoreCategories(
      group: group,
      activeShinsa: active,
      relation: relation,
      energy: classifyDayEnergy(todayScore),
    );

    // 5. dominant/sub 선정 — 점수 1, 2위. 동점 시 enum 순서 (안정).
    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.index.compareTo(b.key.index);
      });
    final dominant = ranked.first.key;
    final sub = ranked.length > 1 ? ranked[1].key : dominant;

    // 6. 별점 4 — love/money/work/health 의 카테고리 점수 매핑.
    int star(EventCategory c) => _scoreToStar(scores[c] ?? 0);

    // 7. 사주 근거 단락 — 한자 jargon 노출 0 (groupTone 자연어로만).
    final sourceReason = _composeSourceReasonKo(
      group: group,
      god: god,
      activeShinsa: active,
      relation: relation,
      dominant: dominant,
    );
    final sourceReasonEn = _composeSourceReasonEn(
      group: group,
      activeShinsa: active,
      relation: relation,
      dominant: dominant,
    );

    return TodayEventReading(
      categoryDominant: dominant,
      categorySub: sub,
      tenGodGroup: group,
      activeShinsa: active,
      hapChungType: relation,
      starsLove: star(EventCategory.love),
      starsMoney: star(EventCategory.money),
      starsWork: star(EventCategory.work),
      starsHealth: star(EventCategory.health),
      sourceReason: sourceReason,
      sourceReasonEn: sourceReasonEn,
      energy: classifyDayEnergy(todayScore),
      rawScores: scores,
    );
  }

  /// 알림 본문 1줄 (가능성 + 행동 조언). 본 sprint 는 fallback — Sprint 6 에서
  /// today_event_pool.json wire 시 pool body 로 대체.
  /// 모든 분기는 verbatim 헷지 ("생기기 쉬워요" / "흐름이 강해요" / "흔들릴 수 있어요") 중 하나 포함.
  static String composeNotificationLine(TodayEventReading r) {
    final cat = r.categoryDominant;
    String body;
    switch (cat) {
      case EventCategory.relationship:
        body = '오늘은 누군가의 말에 신경이 쓰일 일이 생기기 쉬워요. 바로 반응하기보다 조금 늦게 답하는 게 좋아요.';
        break;
      case EventCategory.money:
        body = '오늘은 예상 밖의 지출이나 사고 싶은 게 생기기 쉬워요. 장바구니에만 담아두세요.';
        break;
      case EventCategory.work:
        body = '오늘은 집중이 흩어지는 흐름이 강해요. 큰 결정 말고 정리부터 하면 좋아요.';
        break;
      case EventCategory.love:
        body = '오늘은 연락이나 말투 하나에 기분이 크게 흔들릴 수 있어요. 상대 반응을 너무 확대해석하지 마세요.';
        break;
      case EventCategory.health:
        body = '오늘은 피로가 쌓이기 쉬워요. 자극적인 음식이나 늦은 수면은 피하는 게 좋아요.';
        break;
      case EventCategory.luck:
        body = '오늘은 도움이나 정보가 들어오는 흐름이 강해요. 사람들과 가볍게 소통해보세요.';
        break;
    }
    return body.length > 300 ? '${body.substring(0, 297)}...' : body;
  }

  // ─────────────── Round 77 sprint 2 — today_event_pool.json wire ───────────────
  //
  // pool 90 entries (30 key × 3 entry) 1회 로드 + 캐시. 호출 측은 부팅 시
  // `ensurePoolLoaded()` 1회 await. 이후 `composeBodyKo` / `composeCautionKo`
  // / `composeRecommendKo` 가 deterministic 선택 (날짜+사주 seed). 캐시 미적재
  // 또는 키 미스 시 6분기 fallback 으로 graceful.

  static Map<String, List<_TodayEventPoolEntry>>? _poolCache;
  static bool _poolLoaded = false;

  /// today_event_pool.json 1회 로드 + 캐시. 실패해도 silent (빈 map).
  /// 호출 측은 부팅 시 1회 await — 이후 동기 호출 OK.
  static Future<void> ensurePoolLoaded() async {
    if (_poolLoaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/today_event_pool.json');
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final events = (root['events'] as Map).cast<String, dynamic>();
      final out = <String, List<_TodayEventPoolEntry>>{};
      events.forEach((key, value) {
        final list = (value as List)
            .map((e) =>
                _TodayEventPoolEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        out[key] = list;
      });
      _poolCache = out;
    } catch (_) {
      _poolCache = <String, List<_TodayEventPoolEntry>>{};
    }
    _poolLoaded = true;
  }

  /// 테스트 전용 — 캐시 리셋 (다른 테스트 사이 hygiene).
  static void debugResetPool() {
    _poolCache = null;
    _poolLoaded = false;
  }

  /// pool 미로드 / 키 미스 시 null. 내부 helper — public composeBodyKo 등에서만 사용.
  static _TodayEventPoolEntry? _pickPoolEntry({
    required TodayEventReading reading,
    required DateTime date,
    required String day60ji,
  }) {
    final cache = _poolCache;
    if (cache == null || cache.isEmpty) return null;
    final groupKo = reading.tenGodGroup.ko;
    final catKey = reading.categoryDominant.key;
    final key = '${groupKo}_$catKey';
    final list = cache[key];
    if (list == null || list.isEmpty) return null;
    final seed = (date.year * 366 + date.month * 31 + date.day) ^
        day60ji.codeUnits.fold<int>(0, (a, b) => a + b) ^
        reading.tenGodGroup.index ^
        reading.categoryDominant.index;
    final idx = (seed % list.length).abs();
    return list[idx];
  }

  /// 테스트 전용 — pool entry 존재 여부 (private entry 노출 X).
  static bool debugHasPoolEntry({
    required TodayEventReading reading,
    required DateTime date,
    required String day60ji,
  }) =>
      _pickPoolEntry(reading: reading, date: date, day60ji: day60ji) != null;

  /// 한국어 본문 1줄. pool entry 우선, 미스 시 composeNotificationLine fallback.
  /// 결과는 항상 ≤300자.
  static String composeBodyKo({
    required TodayEventReading reading,
    required DateTime date,
    required String day60ji,
  }) {
    final entry = _pickPoolEntry(reading: reading, date: date, day60ji: day60ji);
    final body = entry?.body ?? composeNotificationLine(reading);
    return body.length > 300 ? '${body.substring(0, 297)}...' : body;
  }

  /// pool entry 의 caution. 미스 시 null.
  static String? composeCautionKo({
    required TodayEventReading reading,
    required DateTime date,
    required String day60ji,
  }) =>
      _pickPoolEntry(reading: reading, date: date, day60ji: day60ji)?.caution;

  /// pool entry 의 recommend. 미스 시 null.
  static String? composeRecommendKo({
    required TodayEventReading reading,
    required DateTime date,
    required String day60ji,
  }) =>
      _pickPoolEntry(reading: reading, date: date, day60ji: day60ji)?.recommend;

  // ─────────────── 내부 helper ───────────────

  static TenGodGroup _groupOf(TenGod? god) {
    if (god == null) return TenGodGroup.bigyeop;
    switch (god) {
      case TenGod.bigyeon:
      case TenGod.geopjae:
        return TenGodGroup.bigyeop;
      case TenGod.siksin:
      case TenGod.sanggwan:
        return TenGodGroup.siksang;
      case TenGod.pyeonjae:
      case TenGod.jeongjae:
        return TenGodGroup.jaeseong;
      case TenGod.pyeongwan:
      case TenGod.jeonggwan:
        return TenGodGroup.gwanseong;
      case TenGod.pyeonin:
      case TenGod.jeongin:
        return TenGodGroup.inseong;
    }
  }

  /// 오늘 지지 가 사용자 사주 신살 매칭 시 활성. ShinsaService 의 매핑 재사용.
  static List<String> _activeShinsa({
    required String userDayStem,
    required String userDayBranch,
    required String todayBranch,
  }) {
    final out = <String>[];
    if (ShinsaService.yokmaFor(userDayBranch) == todayBranch) out.add('역마');
    if (ShinsaService.dohwaFor(userDayBranch) == todayBranch) out.add('도화');
    if (ShinsaService.hwagaeFor(userDayBranch) == todayBranch) out.add('화개');
    if (ShinsaService.cheonEulGwiInFor(userDayStem).contains(todayBranch)) {
      out.add('천을귀인');
    }
    if (ShinsaService.munchangFor(userDayStem) == todayBranch) out.add('문창귀인');
    final yangIn = ShinsaService.yangInFor(userDayStem);
    if (yangIn.isNotEmpty && yangIn == todayBranch) out.add('양인');
    // 백호/괴강 은 오늘 일주 자체 기준 — today_event 에서는 활성 X (NON-GOAL).
    return out;
  }

  static String _branchRelation(String userBranch, String todayBranch) {
    if (userBranch == todayBranch) {
      // 자형(自刑) 4쌍 — 辰辰/午午/酉酉/亥亥 는 같은 지지 만남도 '형' 으로 잡힌다.
      const selfHyung = {'辰', '午', '酉', '亥'};
      return selfHyung.contains(userBranch) ? '형' : '없음';
    }
    if (HapchungService.isJijiHap(userBranch, todayBranch)) return '합';
    if (HapchungService.isJijiChung(userBranch, todayBranch)) return '충';
    if (HapchungService.isJijiPa(userBranch, todayBranch)) return '파';
    if (HapchungService.isJijiHae(userBranch, todayBranch)) return '해';
    // 형 — 子卯 / 寅巳 / 巳申 / 寅申 / 丑戌 / 戌未 / 丑未 등 (단순 2쌍 검사).
    if (_isJijiHyung(userBranch, todayBranch)) return '형';
    return '없음';
  }

  static bool _isJijiHyung(String a, String b) {
    // 무례지형 子卯, 三刑 寅巳申 / 丑戌未 의 2쌍 부분. 자형(辰辰·午午·酉酉·亥亥) 은
    // 위 _branchRelation 에서 userBranch==todayBranch 분기로 처리.
    const pairs = <Set<String>>[
      {'子', '卯'}, // 무례지형
      {'寅', '巳'}, {'巳', '申'}, {'寅', '申'}, // 三刑 寅巳申
      {'丑', '戌'}, {'戌', '未'}, {'丑', '未'}, // 三刑 丑戌未
    ];
    for (final p in pairs) {
      if (p.contains(a) && p.contains(b)) return true;
    }
    return false;
  }

  /// 6 카테고리 점수 합산. 각 카테고리 base 1점 (별점 0 방지) + 가중.
  static Map<EventCategory, int> _scoreCategories({
    required TenGodGroup group,
    required List<String> activeShinsa,
    required String relation,
    required DayEnergyKind energy,
  }) {
    final s = <EventCategory, int>{
      for (final c in EventCategory.values) c: 1,
    };

    void add(EventCategory c, int v) => s[c] = (s[c] ?? 0) + v;

    // 십성 그룹 → 카테고리 base (verbatim 매핑).
    switch (group) {
      case TenGodGroup.bigyeop:
        // 비겁 → 관계 주, 일 보조.
        add(EventCategory.relationship, 4);
        add(EventCategory.work, 2);
        break;
      case TenGodGroup.siksang:
        // 식상 → 일/표현 주, 관계 보조.
        add(EventCategory.work, 4);
        add(EventCategory.relationship, 2);
        break;
      case TenGodGroup.jaeseong:
        // 재성 → 돈 주, 연애 보조.
        add(EventCategory.money, 4);
        add(EventCategory.love, 2);
        break;
      case TenGodGroup.gwanseong:
        // 관성 → 일 주.
        add(EventCategory.work, 4);
        add(EventCategory.relationship, 1);
        break;
      case TenGodGroup.inseong:
        // 인성 → 건강/휴식 주, 일 보조.
        add(EventCategory.health, 4);
        add(EventCategory.work, 2);
        break;
    }

    // 신살 가중.
    for (final shin in activeShinsa) {
      switch (shin) {
        case '도화':
          add(EventCategory.love, 3);
          break;
        case '역마':
          add(EventCategory.luck, 3);
          break;
        case '문창귀인':
          add(EventCategory.work, 3);
          break;
        case '천을귀인':
          add(EventCategory.luck, 2);
          add(EventCategory.relationship, 1);
          break;
        case '양인':
          add(EventCategory.relationship, 2);
          break;
        case '화개':
          add(EventCategory.health, 1);
          add(EventCategory.work, 1);
          break;
      }
    }

    // 합/충/형/파/해 가중.
    switch (relation) {
      case '합':
        add(EventCategory.relationship, 1);
        add(EventCategory.love, 1);
        break;
      case '충':
        add(EventCategory.health, 1);
        add(EventCategory.luck, 1);
        // 충 → work 가능성 -1 (단 baseline 1 미만 X).
        s[EventCategory.work] = math.max(1, (s[EventCategory.work] ?? 1) - 1);
        break;
      case '형':
      case '파':
      case '해':
        add(EventCategory.work, 1);
        s[EventCategory.health] =
            math.max(1, (s[EventCategory.health] ?? 1) - 1);
        break;
    }

    // DayEnergyKind restDay → 건강/관계 +1 (조심 톤),
    // actionDay → luck/work +1 (추천 톤). mixedDay → 변화 X.
    switch (energy) {
      case DayEnergyKind.restDay:
        add(EventCategory.health, 1);
        add(EventCategory.relationship, 1);
        break;
      case DayEnergyKind.mixedDay:
        break;
      case DayEnergyKind.actionDay:
        add(EventCategory.luck, 1);
        add(EventCategory.work, 1);
        break;
    }

    return s;
  }

  /// 카테고리 점수 → 1-5 별점. 점수 1=★, 3=★★, 5=★★★, 7=★★★★, 9+=★★★★★.
  static int _scoreToStar(int score) {
    if (score >= 9) return 5;
    if (score >= 7) return 4;
    if (score >= 5) return 3;
    if (score >= 3) return 2;
    return 1;
  }

  static String _composeSourceReasonKo({
    required TenGodGroup group,
    required TenGod? god,
    required List<String> activeShinsa,
    required String relation,
    required EventCategory dominant,
  }) {
    // 자연어 톤: 십신 한자는 () 안에만, jargon "결/일간/지지" 단어 노출 X.
    final groupTone = _groupToneKo(group);
    final catKo = dominant.ko;
    final shinPart = activeShinsa.isEmpty
        ? ''
        : " 거기에 '${activeShinsa.first}' 분위기까지 들어와서"
            "${activeShinsa.length > 1 ? " '${activeShinsa[1]}' 까지" : ''}"
            ' $catKo 가능성이 더 커지기 쉬워요.';
    String relPart;
    switch (relation) {
      case '합':
        relPart = ' 오늘은 사람과 연결되기 좋은 분위기도 같이 흐르고 있어요.';
        break;
      case '충':
        relPart = ' 오늘은 컨디션이 들쭉날쭉 흔들릴 수 있는 분위기예요.';
        break;
      case '형':
        relPart = ' 작은 마찰이 살짝 생기기 쉬운 분위기도 같이 있어요.';
        break;
      case '파':
      case '해':
        relPart = ' 톤이 살짝 어긋날 수 있는 분위기도 같이 있어요.';
        break;
      default:
        relPart = '';
    }
    // FIX: 한자 jargon 노출 0 — god.ko 의 한자 () suffix 사용 X.
    return '오늘은 당신의 사주가 $groupTone 분위기를 만나서 $catKo 가능성이 강해요.'
        '$shinPart'
        '$relPart';
  }

  static String _composeSourceReasonEn({
    required TenGodGroup group,
    required List<String> activeShinsa,
    required String relation,
    required EventCategory dominant,
  }) {
    final groupTone = _groupToneEn(group);
    final catEn = dominant.key;
    final shinPart = activeShinsa.isEmpty
        ? ''
        : " A '${activeShinsa.first}' vibe is also showing up,"
            "${activeShinsa.length > 1 ? " plus '${activeShinsa[1]}'," : ''}"
            ' nudging the $catEn track stronger.';
    String relPart;
    switch (relation) {
      case '합':
        relPart = ' Today also leans toward people clicking and connecting.';
        break;
      case '충':
        relPart = " Energy can swing today, so watch the body's signals.";
        break;
      case '형':
        relPart = ' Small frictions can pop up on the side.';
        break;
      case '파':
      case '해':
        relPart = ' The tone can slip a notch from yesterday.';
        break;
      default:
        relPart = '';
    }
    // FIX r3 #3: 항상 2문장 이상 — 신살/관계 비어도 두 번째 문장 ("watch the small signals").
    final twoSent = shinPart.isEmpty && relPart.isEmpty
        ? ' Keep an eye on small signals on this track today.'
        : '$shinPart$relPart';
    return 'Today, your chart leans into $groupTone vibes — the $catEn track is more likely.$twoSent';
  }

  /// 영문 fallback notification line — 6 카테고리 분기 (composeNotificationLine 영문 짝).
  static String composeNotificationLineEn(TodayEventReading r) {
    switch (r.categoryDominant) {
      case EventCategory.relationship:
        return "Today, small words from someone may catch you off guard. Answer a beat later.";
      case EventCategory.money:
        return "Today, an unplanned urge to spend is likely. Add to cart and sleep on it.";
      case EventCategory.work:
        return "Today, focus can scatter. Stick to cleanup, not big decisions.";
      case EventCategory.love:
        return "Today, one message can shake your mood more than usual. Don't over-read it.";
      case EventCategory.health:
        return "Today, fatigue stacks easily. Skip the late-night feed and rest a bit earlier.";
      case EventCategory.luck:
        return "Today, small leads or info can drop in. Reply to one casual chat.";
    }
  }

  static String _groupToneKo(TenGodGroup group) {
    switch (group) {
      case TenGodGroup.bigyeop:
        return '친구·또래';
      case TenGodGroup.siksang:
        return '표현·말';
      case TenGodGroup.jaeseong:
        return '돈·소비';
      case TenGodGroup.gwanseong:
        return '책임·평가';
      case TenGodGroup.inseong:
        return '쉼·공부';
    }
  }

  static String _groupToneEn(TenGodGroup group) {
    switch (group) {
      case TenGodGroup.bigyeop:
        return 'peers and friends';
      case TenGodGroup.siksang:
        return 'expression and talk';
      case TenGodGroup.jaeseong:
        return 'money and spending';
      case TenGodGroup.gwanseong:
        return 'duty and evaluation';
      case TenGodGroup.inseong:
        return 'rest and study';
    }
  }
}

/// Round 77 sprint 2 — today_event_pool.json entry 모델 (private).
/// schema: `{body, caution, recommend}` — 한국어 톤 mandate verbatim.
class _TodayEventPoolEntry {
  final String body;
  final String caution;
  final String recommend;
  const _TodayEventPoolEntry({
    required this.body,
    required this.caution,
    required this.recommend,
  });

  factory _TodayEventPoolEntry.fromJson(Map<String, dynamic> j) {
    return _TodayEventPoolEntry(
      body: (j['body'] as String?) ?? '',
      caution: (j['caution'] as String?) ?? '',
      recommend: (j['recommend'] as String?) ?? '',
    );
  }
}
