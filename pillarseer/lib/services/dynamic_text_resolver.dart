// Pillar Seer — Round 78 sprint 3.
//
// DynamicTextResolver: key → ctx-aware text 4단계 priority chain.
//
// 입력: (key, SajuContext, locale [ko|en], staticFallback [없을 때만])
// 출력: 비어있지 않은 String (null 미반환 — chain 끝 staticFallback 보장).
//
// chain 단계:
//   1. 정확 매칭 (key + ctx subset 정확 일치 — pool entry 직접)
//   2. ctx subset 매칭 (key + 부분 subset — 격국+십신 / 용신만 / 5행만)
//   3. ctx-aware suffix (staticFallback + 용신·격국 derive suffix 1문장 합성)
//   4. staticFallback (R77 기존 정적 ment 그대로 — 회귀 가드)
//
// deterministic seed: SajuContext.chartSeed × keyHash. 같은 (key, ctx) → 같은 결과.

import 'saju_context.dart';

/// Pool entry — 정확/부분 매칭용.
class DynamicPoolEntry {
  /// Namespace key — resolver 의 [resolve.key] 와 정확히 일치하는 entry 만 매칭 후보.
  /// 예: 'oracle_hero.restDay.辛'.
  final String key;

  /// Locale 키 (ko / en) → 본문.
  final Map<String, String> bodies;

  /// 매칭 ctx subset — 비어있으면 wildcard (key 매칭만 됐을 때 가장 약한 후보).
  /// 가능 key: 'dayMaster' / 'dayElement' / 'gyeokgukShort' / 'yongsin' / 'dominantElement' /
  /// 'season' / 'strengthLabel' / 'todayPillar'.
  final Map<String, String> requires;

  const DynamicPoolEntry({
    required this.key,
    required this.bodies,
    this.requires = const {},
  });
}

class DynamicTextResolver {
  /// 허용된 ctx field whitelist — typo / unknown key 거부.
  static const supportedRequireKeys = {
    'dayMaster',
    'dayElement',
    'season',
    'gyeokgukShort',
    'yongsin',
    'dominantElement',
    'strengthLabel',
    'todayPillar',
  };

  /// 메인 진입점.
  ///
  /// [key]: namespace (예: 'oracle.restDay').
  /// [ctx]: SajuContext.
  /// [locale]: 'ko' | 'en'.
  /// [staticFallback]: 반드시 비어있지 않은 정적 본문 (R77 ment 등) — chain 끝 보장.
  /// [entries]: 매칭 후보 pool (정확/부분 매칭 시도).
  ///
  /// requires 의 모든 key 는 [supportedRequireKeys] 안에 있어야 함 — 위반 시 assert.
  static String resolve({
    required String key,
    required SajuContext ctx,
    required String locale,
    required String staticFallback,
    List<DynamicPoolEntry> entries = const [],
  }) {
    assert(staticFallback.isNotEmpty, 'staticFallback 비어있으면 안 됨');
    assert(locale == 'ko' || locale == 'en');

    // key namespace 필터 — 같은 key 의 entry 만 매칭 후보.
    final candidates = entries.where((e) => e.key == key).toList();

    // requires whitelist 가드 — typo 키는 release 환경에서도 ArgumentError throw.
    // matching 시 unknown key 는 _ctxField null 반환하여 자연 스럽게 skip 되지만,
    // intent unclear 한 typo 는 contract 위반 — release 에서도 즉시 발견.
    for (final e in candidates) {
      for (final k in e.requires.keys) {
        if (!supportedRequireKeys.contains(k)) {
          throw ArgumentError(
              'DynamicTextResolver: unsupported require key "$k" for entry key="${e.key}". '
              'Supported: $supportedRequireKeys');
        }
      }
    }

    // 1. 정확 매칭 — requires 비어있지 않고 모든 key 가 ctx 와 일치 + 가장 strict.
    // 다중 정확 일치 시 requires field 수 많은 쪽 우선 (가장 specific).
    final exactMatches = candidates
        .where((e) =>
            e.requires.isNotEmpty &&
            _matches(e.requires, ctx, exact: true))
        .toList()
      ..sort((a, b) => b.requires.length.compareTo(a.requires.length));
    if (exactMatches.isNotEmpty) {
      // 가장 strict 한 매칭 (requires field 수 최대) 선택. 동률이면 seed 로 분기.
      final maxFields = exactMatches.first.requires.length;
      final topMatches =
          exactMatches.where((e) => e.requires.length == maxFields).toList();
      final pick = topMatches[_seedIndex(ctx, key) % topMatches.length];
      final body = pick.bodies[locale];
      if (body != null && body.isNotEmpty) return body;
    }

    // 2. 부분 매칭 — requires field 수 ≥2 중 일부만 일치 (정확 매칭 X, 충돌 0).
    //    수 1 짜리 requires 는 사실상 exact 와 동치라 본 단계는 다중 field 의
    //    "subset 매칭" 검증용. matchCount > 0 + 비매칭 field 0 보장.
    final partialMatches = candidates
        .where((e) =>
            e.requires.length >= 2 &&
            !_matches(e.requires, ctx, exact: true) && // 정확 매칭은 단계 1
            _matches(e.requires, ctx, exact: false) &&
            _matchCount(e.requires, ctx) > 0)
        .toList()
      ..sort((a, b) => _matchCount(b.requires, ctx)
          .compareTo(_matchCount(a.requires, ctx)));
    if (partialMatches.isNotEmpty) {
      // 가장 높은 matchCount 후보만 추려서 seed 분기 — tie-break 안정성.
      final topCount = _matchCount(partialMatches.first.requires, ctx);
      final topPartial = partialMatches
          .where((e) => _matchCount(e.requires, ctx) == topCount)
          .toList();
      final pick = topPartial[_seedIndex(ctx, key) % topPartial.length];
      final body = pick.bodies[locale];
      if (body != null && body.isNotEmpty) return body;
    }

    // 3. ctx-aware suffix — staticFallback + 격국 prefix + 용신 5행 derive 1줄 suffix.
    //    같은 천간 + 같은 용신 이어도 격국 다르면 prefix 가 달라 phrase 차이 ≥1.
    final yPart = yongsinSuffix(ctx, locale: locale);
    final gPart = gyeokgukAnchor(ctx, locale: locale);
    final combo = [gPart, yPart].where((p) => p.isNotEmpty).join(' ');
    if (combo.isNotEmpty) {
      return '$staticFallback\n$combo';
    }

    // 4. staticFallback (회귀 가드).
    return staticFallback;
  }

  /// 격국 → 짧은 1구 anchor (예: "정관격 흐름이 받쳐줘요"). 한자 X.
  /// 같은 용신이어도 격국 다르면 prefix 가 달라 ctx-aware 분기 보장.
  static String gyeokgukAnchor(SajuContext ctx, {required String locale}) {
    final g = ctx.gyeokgukShort;
    if (g.isEmpty) return '';
    if (locale == 'ko') {
      const map = {
        '정관격': '정관격 흐름이 안정적으로 받쳐줘요.',
        '편관격': '편관격 추진력이 한 박자 강해져요.',
        '정인격': '정인격 학습 흐름이 단단해져요.',
        '편인격': '편인격 직관이 평소보다 또렷해져요.',
        '정재격': '정재격 차곡차곡 쌓이는 흐름이에요.',
        '편재격': '편재격 새 거래 신호가 자주 와요.',
        '식신격': '식신격 표현이 술술 풀려요.',
        '상관격': '상관격 한 발 빠른 감이 살아나요.',
      };
      return map[g] ?? '';
    } else {
      const map = {
        '정관격': 'Stable office vibe holds steady today.',
        '편관격': 'Bold drive sharpens a notch today.',
        '정인격': 'Study mode locks in firmer today.',
        '편인격': 'Intuition runs sharper than usual today.',
        '정재격': 'Steady stacking flow today.',
        '편재격': 'Fresh deal signals show up today.',
        '식신격': 'Expression flows easily today.',
        '상관격': 'Quick read on the room today.',
      };
      return map[g] ?? '';
    }
  }

  /// 용신 5행 → 짧은 행동 처방 1줄 (5축 일부 — sprint 5 에서 본격 5축 wire).
  /// 본 sprint 는 1축 (행동/맥락) 만 노출 — Round 77 톤 유지.
  static String yongsinSuffix(SajuContext ctx, {required String locale}) {
    final y = ctx.yongsin;
    if (y.isEmpty) return '';
    if (locale == 'ko') {
      const map = {
        '木': '오늘 초록·산책 한 번 챙기면 컨디션이 받쳐줘요.',
        '火': '오늘 햇볕 받는 동선 한 번 챙기면 자신감이 채워져요.',
        '土': '오늘 단맛 간식 한 입, 안정된 루틴 한 줄이 흐름을 잡아줘요.',
        '金': '오늘 책상 정리 한 번, 명료한 결정 한 번이 감을 살려요.',
        '水': '오늘 충분한 수면 한 시간이 다음 날 컨디션을 두 배로 만들어줘요.',
      };
      return map[y] ?? '';
    } else {
      const map = {
        '木': 'A short walk or a touch of green today keeps your focus steady.',
        '火': 'A bit of sunlight on your route today refills your confidence.',
        '土': 'One sweet bite and one steady routine line set today\'s rhythm.',
        '金': 'A quick desk reset and one clear decision sharpens today.',
        '水': 'An extra hour of sleep tonight doubles tomorrow\'s energy.',
      };
      return map[y] ?? '';
    }
  }

  /// 격국 (한자 jargon 제거) → 짧은 라벨 (resolver 호출처에서 사용 가능).
  /// 본문 body 에 한자 직접 노출 X 가드 — Sprint 1 SajuContext.gyeokgukShort docstring 일치.
  static String gyeokgukLabel(SajuContext ctx, {required String locale}) {
    if (locale == 'ko') {
      return ctx.gyeokgukShort;
    }
    // 영문: 한자 dictionary 제거, 영문 라벨만.
    const map = {
      '정관격': 'Stable Office',
      '편관격': 'Bold Drive',
      '정인격': 'Direct Resource',
      '편인격': 'Unconventional Resource',
      '정재격': 'Stable Wealth',
      '편재격': 'Windfall Wealth',
      '식신격': 'Output',
      '상관격': 'Sharp Output',
    };
    return map[ctx.gyeokgukShort] ?? ctx.gyeokgukShort;
  }

  /// 십신 그룹 — TenGod 10 → 5 그룹 (관성/식상/재성/인성/비겁).
  static String tenGodGroup(String? tenGodKo) {
    if (tenGodKo == null) return '';
    if (tenGodKo.startsWith('정관') || tenGodKo.startsWith('편관')) return '관성';
    if (tenGodKo.startsWith('식신') || tenGodKo.startsWith('상관')) return '식상';
    if (tenGodKo.startsWith('정재') || tenGodKo.startsWith('편재')) return '재성';
    if (tenGodKo.startsWith('정인') || tenGodKo.startsWith('편인')) return '인성';
    if (tenGodKo.startsWith('비견') || tenGodKo.startsWith('겁재')) return '비겁';
    return '';
  }

  // ── private ─────────────────────────────────────────────

  /// ctx field 추출 — requires key 가 ctx 의 어떤 field 와 매칭되는지.
  static String? _ctxField(String reqKey, SajuContext ctx) {
    switch (reqKey) {
      case 'dayMaster':
        return ctx.dayMaster;
      case 'dayElement':
        return ctx.dayElement;
      case 'season':
        return ctx.season;
      case 'gyeokgukShort':
        return ctx.gyeokgukShort;
      case 'yongsin':
        return ctx.yongsin;
      case 'dominantElement':
        return ctx.dominantElement;
      case 'strengthLabel':
        return ctx.strengthLabel;
      case 'todayPillar':
        return ctx.todayPillar;
      default:
        return null;
    }
  }

  static bool _matches(
      Map<String, String> requires, SajuContext ctx,
      {required bool exact}) {
    if (requires.isEmpty) return false; // wildcard 는 1·2 단계 매칭 X
    if (exact) {
      // 모든 field 가 ctx 와 정확 일치.
      for (final entry in requires.entries) {
        final v = _ctxField(entry.key, ctx);
        if (v != entry.value) return false;
      }
      return true;
    } else {
      // partial — 명시된 field 중 적어도 1 일치, 충돌 (명시 != ctx) 0.
      // ctx 가 해당 field 미보유 (null) → skip (충돌 X).
      bool anyMatch = false;
      for (final entry in requires.entries) {
        final v = _ctxField(entry.key, ctx);
        if (v == null) continue;
        if (v == entry.value) {
          anyMatch = true;
        } else {
          return false; // 명시된 field 가 ctx 와 충돌 — partial X
        }
      }
      return anyMatch;
    }
  }

  static int _matchCount(Map<String, String> requires, SajuContext ctx) {
    int count = 0;
    for (final entry in requires.entries) {
      final v = _ctxField(entry.key, ctx);
      if (v == entry.value) count++;
    }
    return count;
  }

  /// deterministic index — (chartSeed × keyHash) % len 형태로 사용.
  static int _seedIndex(SajuContext ctx, String key) {
    int h = key.hashCode;
    if (h < 0) h = -h;
    final mix = (ctx.chartSeed.abs() ~/ 7 + h) % 0x7FFFFFFF;
    return mix;
  }
}
