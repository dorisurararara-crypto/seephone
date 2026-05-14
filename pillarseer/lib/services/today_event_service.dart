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
/// today_event_pool.json key prefix 와 일치 (한국어 십신 그룹).
/// pool key 형식: `{한국어 십신}_{EventCategory.key}` (예: `비겁_relationship`).
/// Round 77 sprint 8 — `ko` getter 는 enum 내부 method 로 inline (extension 제거).
enum TenGodGroup {
  bigyeop, // 비겁 (비견+겁재)
  siksang, // 식상 (식신+상관)
  jaeseong, // 재성 (편재+정재)
  gwanseong, // 관성 (편관+정관)
  inseong; // 인성 (편인+정인)

  /// pool key prefix (한국어 십신 그룹명).
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
  /// Round 78 sprint 6 — 신살 16 key + 합/충/형/파/해 36 key 단일 line cache.
  static Map<String, String>? _shinsaCache;
  static Map<String, String>? _hapchungCache;
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
      // Round 78 sprint 6 — shinsa / hapchung 캐시.
      _shinsaCache = (root['shinsa'] as Map?)
              ?.cast<String, dynamic>()
              .map((k, v) => MapEntry(k, v as String)) ??
          <String, String>{};
      _hapchungCache = (root['hapchung'] as Map?)
              ?.cast<String, dynamic>()
              .map((k, v) => MapEntry(k, v as String)) ??
          <String, String>{};
    } catch (_) {
      _poolCache = <String, List<_TodayEventPoolEntry>>{};
      _shinsaCache = <String, String>{};
      _hapchungCache = <String, String>{};
    }
    _poolLoaded = true;
  }

  /// 테스트 전용 — 캐시 리셋 (다른 테스트 사이 hygiene).
  static void debugResetPool() {
    _poolCache = null;
    _shinsaCache = null;
    _hapchungCache = null;
    _poolLoaded = false;
  }

  /// Round 78 sprint 6 — 신살 key 직접 line 조회 (활성 신살 anchor 본문 join).
  /// pool 미로드 / key 미스 시 null. seed 미사용 (각 신살 1 line — 단일 verbatim).
  static String? shinsaLineKo(String shinsaKey) {
    final c = _shinsaCache;
    if (c == null || c.isEmpty) return null;
    return c[shinsaKey];
  }

  /// Round 78 sprint 6 — 합/충/형/파/해 + 카테고리 결합 line.
  /// [relationKey] = '천간합' / '지지합' / '지지충' / '지지형' / '지지파' / '지지해'.
  /// [categoryKey] = 'relationship' / 'money' / 'work' / 'love' / 'health' / 'luck'.
  /// 미스 시 null — fallback chain (today_event_pool body) 유지.
  static String? hapchungLineKo(String relationKey, String categoryKey) {
    final c = _hapchungCache;
    if (c == null || c.isEmpty) return null;
    return c['${relationKey}_$categoryKey'];
  }

  /// Round 78 sprint 6 — 활성 신살 set 중 우선순위 1개 → anchor line.
  /// 우선순위 (강한 신호 우선):
  ///   천을귀인 > 도화 > 역마 > 문창귀인 > 양인 > 괴강 > 백호 > 화개 > 공망 > 겁살 >
  ///   재살 > 월살 > 망신 > 천살 > 장성 > 반안 > 지살 > 육해 > 삼합 > 방합 > 삼재 >
  ///   암록 > 년살 > 화개살.
  /// 신규 12 신살 8개 (천살/지살/장성/반안/망신/육해/년살/화개살) 도 모두 활성 시 라인 반환.
  static String? primaryShinsaLine(Set<String> activeShinsa) {
    for (final p in shinsaPriority) {
      if (activeShinsa.contains(p)) {
        final line = shinsaLineKo(p);
        if (line != null) return line;
      }
    }
    return null;
  }

  /// 24 신살 우선순위 list — primaryShinsaLine + 향후 UI 표시 정렬 공용.
  static const shinsaPriority = [
    '천을귀인', '도화', '역마', '문창귀인', '양인', '괴강', '백호', '화개',
    '공망', '겁살', '재살', '월살', '망신', '천살', '장성', '반안', '지살',
    '육해', '삼합', '방합', '삼재', '암록', '년살', '화개살',
  ];

  /// composeBodyKoWithAnchor 단계 1 (신살 우선) 에서 사용할 핵심 신살 — 강한 신호 8개만.
  /// 12 신살 (천살/지살/장성/반안/망신/육해/겁살/재살/월살) 은 매 사주 거의 항상 활성
  /// (일지 삼합 그룹 기준 9 cell cover) 이므로 anchor 항상 hit 되어 천간합·지지 hapchung
  /// 우선순위가 뒤집힘. 따라서 anchor 단계 1 은 사용자 사주 고유 "강한" 신살만.
  static const _coreShinsaForAnchor = {
    '천을귀인', '도화', '역마', '문창귀인', '양인', '괴강', '백호', '화개', '공망',
  };

  /// composeBodyKoWithAnchor 가 사용하는 anchor 1차 — 핵심 신살만.
  static String? _coreShinsaAnchor(Set<String> activeShinsa) {
    for (final p in shinsaPriority) {
      if (!_coreShinsaForAnchor.contains(p)) continue;
      if (activeShinsa.contains(p)) {
        final line = shinsaLineKo(p);
        if (line != null) return line;
      }
    }
    return null;
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

  /// Round 78 sprint 6 — composeBodyKo + 신살·합충 anchor 1줄 prepend.
  /// 신살 활성 set + relation 둘 다 보유 시 신살 anchor 우선 (사용자 사주 고유 신호).
  /// [userDayStem] / [todayStem] 둘 다 제공 시 천간합 발동도 검사.
  static String composeBodyKoWithAnchor({
    required TodayEventReading reading,
    required DateTime date,
    required String day60ji,
    String? userDayStem,
    String? todayStem,
  }) {
    final body = composeBodyKo(reading: reading, date: date, day60ji: day60ji);
    // 1차: 활성 강한 신살 anchor (천을귀인·도화·역마·문창귀인·양인·괴강·백호·화개·공망).
    // 12 신살 (겁살·재살·월살·천살·지살·장성·반안·망신·육해) 는 항상 1 hit 이라
    // 천간합·지지 hapchung 우선순위가 뒤집히지 않게 1차 anchor 에서 제외.
    final shinsaLine = _coreShinsaAnchor(reading.activeShinsa.toSet());
    if (shinsaLine != null) {
      final combined = '$shinsaLine\n$body';
      return combined.length > 400 ? '${combined.substring(0, 397)}...' : combined;
    }
    // 2차: 천간합 anchor (userDayStem + todayStem 둘 다 제공 시).
    if (userDayStem != null && todayStem != null) {
      if (_isCheonganHap(userDayStem, todayStem)) {
        final catKey = reading.categoryDominant.key;
        final hapLine = hapchungLineKo('천간합', catKey);
        if (hapLine != null) {
          final combined = '$hapLine\n$body';
          return combined.length > 400 ? '${combined.substring(0, 397)}...' : combined;
        }
      }
    }
    // 3차: 지지 hapchung anchor (지지합/충/형/파/해).
    final relKey = _hapchungKeyOf(reading.hapChungType);
    if (relKey.isNotEmpty) {
      final catKey = reading.categoryDominant.key;
      final hapLine = hapchungLineKo(relKey, catKey);
      if (hapLine != null) {
        final combined = '$hapLine\n$body';
        return combined.length > 400 ? '${combined.substring(0, 397)}...' : combined;
      }
    }
    return body;
  }

  /// 천간 5합 (甲己 / 乙庚 / 丙辛 / 丁壬 / 戊癸).
  static bool _isCheonganHap(String a, String b) {
    const pairs = {'甲': '己', '乙': '庚', '丙': '辛', '丁': '壬', '戊': '癸'};
    if (pairs[a] == b) return true;
    if (pairs[b] == a) return true;
    return false;
  }

  static String _hapchungKeyOf(String rel) {
    switch (rel) {
      case '합':
        return '지지합';
      case '충':
        return '지지충';
      case '형':
        return '지지형';
      case '파':
        return '지지파';
      case '해':
        return '지지해';
    }
    return '';
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
    // Round 78 sprint 6 — 12 신살 확장 (일지 삼합 그룹 기준).
    final extra = _twelveShinsaFor(userDayBranch, todayBranch);
    out.addAll(extra);
    // 공망: 일주 기준 공망 지지에 오늘 지지가 매칭되면.
    final gongmang = _gongmangBranches(userDayStem, userDayBranch);
    if (gongmang.contains(todayBranch)) out.add('공망');
    return out;
  }

  /// 12 신살 — 일지 삼합 그룹 기준. 12 살 전부 emit.
  /// 삼합 4 그룹: 申子辰(水), 巳酉丑(金), 寅午戌(火), 亥卯未(木).
  /// 정통 표 (각 그룹별 12지 순환):
  ///   水: 겁=巳, 재=午, 천=未, 지=申, 년(도)=酉, 월=戌, 망=亥, 장=子, 반=丑, 역=寅, 육=卯, 화(개)=辰
  ///   金: 겁=寅, 재=卯, 천=辰, 지=巳, 년=午, 월=未, 망=申, 장=酉, 반=戌, 역=亥, 육=子, 화=丑
  ///   火: 겁=亥, 재=子, 천=丑, 지=寅, 년=卯, 월=辰, 망=巳, 장=午, 반=未, 역=申, 육=酉, 화=戌
  ///   木: 겁=申, 재=酉, 천=戌, 지=亥, 년=子, 월=丑, 망=寅, 장=卯, 반=辰, 역=巳, 육=午, 화=未
  /// 도화/역마/화개 는 12 신살 표의 년(도)/역/화(개) — 이미 별도 분기 emit 됨.
  /// 본 메서드는 그 외 9 살 (겁살·재살·천살·지살·월살·망신·장성·반안·육해) emit.
  static List<String> _twelveShinsaFor(String userBranch, String todayBranch) {
    const samhapGroup = {
      '申': '水', '子': '水', '辰': '水',
      '巳': '金', '酉': '金', '丑': '金',
      '寅': '火', '午': '火', '戌': '火',
      '亥': '木', '卯': '木', '未': '木',
    };
    const map = {
      '水': {
        '겁살': '巳', '재살': '午', '천살': '未', '지살': '申',
        '월살': '戌', '망신': '亥', '장성': '子', '반안': '丑', '육해': '卯',
      },
      '金': {
        '겁살': '寅', '재살': '卯', '천살': '辰', '지살': '巳',
        '월살': '未', '망신': '申', '장성': '酉', '반안': '戌', '육해': '子',
      },
      '火': {
        '겁살': '亥', '재살': '子', '천살': '丑', '지살': '寅',
        '월살': '辰', '망신': '巳', '장성': '午', '반안': '未', '육해': '酉',
      },
      '木': {
        '겁살': '申', '재살': '酉', '천살': '戌', '지살': '亥',
        '월살': '丑', '망신': '寅', '장성': '卯', '반안': '辰', '육해': '午',
      },
    };
    final group = samhapGroup[userBranch];
    if (group == null) return const [];
    final out = <String>[];
    final g = map[group]!;
    for (final entry in g.entries) {
      if (entry.value == todayBranch) out.add(entry.key);
    }
    return out;
  }

  /// 공망 — 일주 기준 2개 지지. saju_service 와 동일 식 GongMangService 위임 가능.
  /// 본 service 의존성 최소화를 위해 단순 lookup.
  static List<String> _gongmangBranches(String dayStem, String dayBranch) {
    // 60갑자 인덱스 idx → soon = idx ~/ 10. 6 순 × 2 지지 = 공망 list.
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final g = stems.indexOf(dayStem);
    final j = branches.indexOf(dayBranch);
    if (g < 0 || j < 0) return const [];
    int idx = -1;
    for (int i = 0; i < 60; i++) {
      if (i % 10 == g && i % 12 == j) { idx = i; break; }
    }
    if (idx < 0) return const [];
    final soon = idx ~/ 10;
    const gongMangBySoon = [
      ['戌', '亥'],
      ['申', '酉'],
      ['午', '未'],
      ['辰', '巳'],
      ['寅', '卯'],
      ['子', '丑'],
    ];
    return gongMangBySoon[soon];
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
