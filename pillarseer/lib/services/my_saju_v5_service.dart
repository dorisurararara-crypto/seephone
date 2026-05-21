// Pillar Seer — Round 106 (P3) — 내 사주(평생사주) v5.
//
// R106 design doc §3 / §5 / §9(내 사주) ground truth:
//  - 평생사주 화면 상단에 v5 cohesive 리딩을 새로 얹는다. 기존 17섹션 상세
//    풀이는 그 아래 detail 로 보존(삭제 X).
//  - 구조 = 증거띠(실제 차트 anchor 칩) + 헤드라인(강점+그림자) + 본문 + 오늘 CTA.
//  - 톤 = 친구 같은 용한 점쟁이. 한자 즉시 풀이. 메타·헤드라인체·codex 말투 금지.
//  - 내 사주는 평생 성향이라 falsifiability 제약은 약하나 — anchor 없는 막연한
//    칭찬 금지. 모든 진술이 일주/일간/십신/합/격국/용신 에 묶인다. 거짓말·창작 0.
//
// 본 service 는 presentation layer only — 계산 엔진 (TenGods / Gyeokguk /
// Yongsin / Shinsa / Hapchung / SajuContext) 의 산출물을 읽어 v5 카피로 조립만
// 한다. 점수·임계값·분기 1 bit 도 건드리지 않는다. 기존 17섹션 (LifeOverview /
// LifeParagraph / SelfConclusion) 의 생성 로직도 손대지 않는다.
//
// fragment pool = assets/data/my_saju_v5_pool.json — 한자/jargon 의 단독 노출이
// pool 에 절대 들어가지 않게 작성했고, r106 test guard 가 회귀 감시한다.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'hapchung_service.dart';
import 'saju_context.dart';
import 'ten_gods_service.dart';

/// 증거 칩 1개 — "내 풀이에 실제 반영된 것" 한 조각.
/// 사용자에게 "이 풀이는 이 계산에서 나왔어요" 신뢰를 주는 anchor 칩.
class MySajuV5EvidenceChip {
  /// 칩 위 작은 라벨 (예: '일주').
  final String label;

  /// 칩 본문 — 실제 차트 값을 사용자 언어로 (예: '辛卯 (신묘) 일주').
  final String value;

  const MySajuV5EvidenceChip({required this.label, required this.value});
}

/// 내 사주 v5 reading — 평생사주 화면 상단 cohesive 리딩.
class MySajuV5Reading {
  /// 증거 띠 — 실제 차트 anchor 칩들. 항상 일주/일간 포함, 신호 있으면 더 붙음.
  final List<MySajuV5EvidenceChip> evidenceChips;

  /// 헤드라인 — 한 사람을 한 줄로. 강점 + 그 그림자를 같이.
  final String headline;

  /// 본문 — v5 자연어. 일간→십신→합·용신→그림자 다루는 법→'바탕' 마무리.
  /// '/' 가 아닌 문단 list 로 보관 — UI 가 문단 간격을 줄 수 있게.
  final List<String> bodyParagraphs;

  /// 오늘 연결 CTA — "→ 오늘은 이 바탕이 어떻게 건드려질까요".
  final String todayCta;

  const MySajuV5Reading({
    required this.evidenceChips,
    required this.headline,
    required this.bodyParagraphs,
    required this.todayCta,
  });

  /// 본문 전체를 한 덩어리로 (테스트·검수용).
  String get bodyJoined => bodyParagraphs.join(' ');
}

class MySajuV5Service {
  // ── fragment pool ──
  static Map<String, dynamic>? _poolCache;
  static bool _poolLoaded = false;

  /// my_saju_v5_pool.json 1회 로드 + 캐시. 실패해도 silent (빈 map).
  /// pool 미적재 시 build 는 내장 fallback 카피로 graceful (앱이 죽지 않는다).
  static Future<void> ensurePoolLoaded() async {
    if (_poolLoaded) return;
    try {
      final raw =
          await rootBundle.loadString('assets/data/my_saju_v5_pool.json');
      _poolCache = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _poolCache = <String, dynamic>{};
    }
    _poolLoaded = true;
  }

  /// 테스트 전용 — 캐시 리셋.
  static void debugResetPool() {
    _poolCache = null;
    _poolLoaded = false;
  }

  /// 테스트 전용 — pool 직접 주입.
  static void debugSeedPool(Map<String, dynamic> pool) {
    _poolCache = pool;
    _poolLoaded = true;
  }

  // ── 천간 한자 → 한글 ──
  static const Map<String, String> _stemKo = {
    '甲': '갑', '乙': '을', '丙': '병', '丁': '정', '戊': '무',
    '己': '기', '庚': '경', '辛': '신', '壬': '임', '癸': '계',
  };
  // ── 지지 한자 → 한글 ──
  static const Map<String, String> _branchKo = {
    '子': '자', '丑': '축', '寅': '인', '卯': '묘', '辰': '진', '巳': '사',
    '午': '오', '未': '미', '申': '신', '酉': '유', '戌': '술', '亥': '해',
  };
  // ── 5행 한자 → 한글 ──
  static const Map<String, String> _elKo = {
    '木': '목', '火': '화', '土': '토', '金': '금', '水': '수',
  };

  /// 일주 60갑자 한자 → 한글 (예: '辛卯' → '신묘'). 천간+지지.
  static String _ganjiKo(String ganji) {
    if (ganji.length != 2) return ganji;
    final g = _stemKo[ganji[0]] ?? ganji[0];
    final j = _branchKo[ganji[1]] ?? ganji[1];
    return '$g$j';
  }

  /// 천간합 2글자 한자 → 한글 (예: '丙辛' → '병신'). 두 글자 모두 천간.
  static String _stemPairKo(String pair) {
    if (pair.length != 2) return pair;
    final a = _stemKo[pair[0]] ?? pair[0];
    final b = _stemKo[pair[1]] ?? pair[1];
    return '$a$b';
  }

  /// TenGod → 한글 라벨.
  static const Map<TenGod, String> _tenGodKo = {
    TenGod.bigyeon: '비견',
    TenGod.geopjae: '겁재',
    TenGod.siksin: '식신',
    TenGod.sanggwan: '상관',
    TenGod.pyeonjae: '편재',
    TenGod.jeongjae: '정재',
    TenGod.pyeongwan: '편관',
    TenGod.jeonggwan: '정관',
    TenGod.pyeonin: '편인',
    TenGod.jeongin: '정인',
  };

  /// 내 사주 v5 build. pure — 같은 사주 → 항상 같은 출력 (deterministic).
  ///
  /// [saju]      = SajuResult.
  /// [topTopicId] = RecallFeedbackService.userPref 최고 주제 id (P1). null 이면
  ///                CTA 는 default. design doc §9 — 관심 주제 쪽 CTA 연결.
  static MySajuV5Reading build({
    required SajuResult saju,
    String? topTopicId,
  }) {
    final ctx = SajuContext.from(saju);

    // ── 핵심 십신: 사주 8글자 빈도 1위 ──
    final topGod = _topTenGod(saju);
    final topGodKo = _tenGodKo[topGod] ?? '비견';

    // ── 원국(natal) 합·충 ──
    final hapchung = _natalHapchung(saju);

    // ── 1. 증거 띠 ──
    final chips = _buildChips(
      saju: saju,
      ctx: ctx,
      topGodKo: topGodKo,
      hapchung: hapchung,
    );

    // ── 2. 헤드라인 — 강점 + 그림자 ──
    final headline = _buildHeadline(saju);

    // ── 3. 본문 ──
    final body = _buildBody(
      saju: saju,
      ctx: ctx,
      topGodKo: topGodKo,
      hapchung: hapchung,
    );

    // ── 4. 오늘 CTA ──
    final cta = _buildTodayCta(topTopicId);

    return MySajuV5Reading(
      evidenceChips: chips,
      headline: headline,
      bodyParagraphs: body,
      todayCta: cta,
    );
  }

  // ── 핵심 십신 (사주 8글자 빈도 1위) ──

  static TenGod _topTenGod(SajuResult saju) {
    final rows = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final r in rows) {
      if (r.chunGanGod != null) {
        freq[r.chunGanGod!] = (freq[r.chunGanGod!] ?? 0) + 1;
      }
      if (r.jiJiGod != null) {
        freq[r.jiJiGod!] = (freq[r.jiJiGod!] ?? 0) + 1;
      }
    }
    TenGod top = TenGod.bigyeon;
    int topCount = -1;
    // TenGod.values 순서 = 안정 deterministic tie-break.
    for (final g in TenGod.values) {
      final c = freq[g] ?? 0;
      if (c > topCount) {
        topCount = c;
        top = g;
      }
    }
    return top;
  }

  // ── 원국 합·충 ──

  /// 원국 4기둥 합·충. 일주(日柱)가 끼는 천간합·지지합·충을 우선 추려 v5 anchor 로.
  static ({String? cheonganHapPair, bool hasJijiHap, bool hasChung})
      _natalHapchung(SajuResult saju) {
    final analysis = HapchungService.analyzeChart(
      yearGan: saju.yearPillar.chunGan,
      yearJi: saju.yearPillar.jiJi,
      monthGan: saju.monthPillar.chunGan,
      monthJi: saju.monthPillar.jiJi,
      dayGan: saju.dayPillar.chunGan,
      dayJi: saju.dayPillar.jiJi,
      hourGan: saju.hourPillar?.chunGan,
      hourJi: saju.hourPillar?.jiJi,
    );

    // 천간합 — 일간이 끼는 합 우선 (없으면 첫 천간합). 화 오행이 있는 것 = 천간5합.
    String? cheonganHapPair;
    for (final h in analysis.hap) {
      if (h.element.isEmpty) continue; // 지지6합은 element 비어있게 들어옴.
      final involvesDay = h.area1 == 'day' || h.area2 == 'day';
      final gan = _ganForArea(saju, h.area1);
      final gan2 = _ganForArea(saju, h.area2);
      if (gan == null || gan2 == null) continue;
      if (!HapchungService.isCheonganHap(gan, gan2)) continue;
      final pair = _canonHapKey(gan, gan2);
      if (involvesDay) {
        cheonganHapPair = pair;
        break;
      }
      cheonganHapPair ??= pair;
    }

    // 지지합 존재 여부 (천간합과 별개로 사주 안쪽 엮임 묘사).
    bool hasJijiHap = false;
    for (final h in analysis.hap) {
      if (h.element.isNotEmpty) continue;
      final j1 = _jiForArea(saju, h.area1);
      final j2 = _jiForArea(saju, h.area2);
      if (j1 != null && j2 != null && HapchungService.isJijiHap(j1, j2)) {
        hasJijiHap = true;
        break;
      }
    }

    final hasChung = analysis.chung.isNotEmpty;
    return (
      cheonganHapPair: cheonganHapPair,
      hasJijiHap: hasJijiHap,
      hasChung: hasChung,
    );
  }

  static String? _ganForArea(SajuResult saju, String area) {
    switch (area) {
      case 'year':
        return saju.yearPillar.chunGan;
      case 'month':
        return saju.monthPillar.chunGan;
      case 'day':
        return saju.dayPillar.chunGan;
      case 'hour':
        return saju.hourPillar?.chunGan;
    }
    return null;
  }

  static String? _jiForArea(SajuResult saju, String area) {
    switch (area) {
      case 'year':
        return saju.yearPillar.jiJi;
      case 'month':
        return saju.monthPillar.jiJi;
      case 'day':
        return saju.dayPillar.jiJi;
      case 'hour':
        return saju.hourPillar?.jiJi;
    }
    return null;
  }

  /// 천간합 2글자를 pool key 의 canonical 순서로 (甲己 / 乙庚 / 丙辛 / 丁壬 / 戊癸).
  static String _canonHapKey(String a, String b) {
    const order = {
      '甲己': '甲己', '己甲': '甲己',
      '乙庚': '乙庚', '庚乙': '乙庚',
      '丙辛': '丙辛', '辛丙': '丙辛',
      '丁壬': '丁壬', '壬丁': '丁壬',
      '戊癸': '戊癸', '癸戊': '戊癸',
    };
    return order['$a$b'] ?? '$a$b';
  }

  // ── 1. 증거 띠 ──

  static List<MySajuV5EvidenceChip> _buildChips({
    required SajuResult saju,
    required SajuContext ctx,
    required String topGodKo,
    required ({String? cheonganHapPair, bool hasJijiHap, bool hasChung})
        hapchung,
  }) {
    final chips = <MySajuV5EvidenceChip>[];

    // 항상 — 일주 60갑자.
    final iljuHan = saju.dayPillar.text;
    chips.add(MySajuV5EvidenceChip(
      label: '일주',
      value: '$iljuHan (${_ganjiKo(iljuHan)}) 일주',
    ));

    // 항상 — 일간.
    final dm = saju.dayMaster;
    final dmKo = _stemKo[dm] ?? dm;
    final dmPool = _dayMasterPool(dm);
    final dmShape = (dmPool['ko'] as String?) ?? '';
    chips.add(MySajuV5EvidenceChip(
      label: '일간',
      value: dmShape.isEmpty
          ? '$dm ($dmKo)'
          : '$dm ($dmKo) · $dmShape',
    ));

    // 핵심 십신.
    chips.add(MySajuV5EvidenceChip(
      label: '핵심 십신',
      value: topGodKo,
    ));

    // 천간합 (있으면).
    final hap = hapchung.cheonganHapPair;
    if (hap != null && hap.length == 2) {
      chips.add(MySajuV5EvidenceChip(
        label: '천간합',
        value: '$hap (${_stemPairKo(hap)})합',
      ));
    }

    // 격국.
    if (ctx.gyeokgukShort.isNotEmpty) {
      chips.add(MySajuV5EvidenceChip(
        label: '격국',
        value: ctx.gyeokgukShort,
      ));
    }

    // 용신.
    if (ctx.yongsin.isNotEmpty) {
      final ysKo = _elKo[ctx.yongsin] ?? ctx.yongsin;
      chips.add(MySajuV5EvidenceChip(
        label: '용신',
        value: '${ctx.yongsin} ($ysKo)',
      ));
    }

    // 신살 (있으면 첫 1개).
    if (ctx.activeShinsa.isNotEmpty) {
      final shin = (ctx.activeShinsa.toList()..sort()).first;
      chips.add(MySajuV5EvidenceChip(
        label: '신살',
        value: shin,
      ));
    }

    return chips;
  }

  // ── 2. 헤드라인 (강점 + 그림자) ──

  static String _buildHeadline(SajuResult saju) {
    final dmPool = _dayMasterPool(saju.dayMaster);
    final strength = (dmPool['headline_strength'] as String?) ?? '';
    final shadow = (dmPool['headline_shadow'] as String?) ?? '';
    if (strength.isEmpty) {
      return '쉽게 흔들리지 않는 사람이에요. 대신 혼자 너무 오래 끌어안고 가요.';
    }
    // 강점 문장 — 종결어미로 끝나면 마침표를 붙여 그림자 문장과 분리한다.
    final s = _endSentence(strength);
    if (shadow.isEmpty) return s;
    final sh = _endSentence(shadow);
    return '$s $sh';
  }

  /// 문장 끝에 마침표가 없으면 붙인다 (이미 .!? 면 그대로).
  static String _endSentence(String text) {
    final t = text.trimRight();
    if (t.isEmpty) return t;
    final last = t[t.length - 1];
    if (last == '.' || last == '!' || last == '?') return t;
    return '$t.';
  }

  // ── 3. 본문 ──

  static List<String> _buildBody({
    required SajuResult saju,
    required SajuContext ctx,
    required String topGodKo,
    required ({String? cheonganHapPair, bool hasJijiHap, bool hasChung})
        hapchung,
  }) {
    final paras = <String>[];

    // 문단 1 — 일간 형용 + dominant 오행 + 일지(日支) 내면 자리.
    // 일지 fragment 는 같은 일간이라도 일주 60갑자 수준으로 본문이 갈리도록
    // 박는 anchor — 일지(본인 내면 자리)라는 실제 차트 요소에 묶인다.
    final dmPool = _dayMasterPool(saju.dayMaster);
    final dmBody = (dmPool['body'] as String?) ?? '';
    final domEl = ctx.dominantElement;
    final domLine = _strMap('dominant_element')[domEl] ?? '';
    final dayBranch = saju.dayPillar.jiJi;
    final branchLine = _strMap('day_branch')[dayBranch] ?? '';
    final p1 = [dmBody, domLine, branchLine].where((s) => s.isNotEmpty).join(' ');
    if (p1.isNotEmpty) {
      paras.add(p1);
    } else {
      paras.add('당신은 어지간한 압력에 잘 흔들리지 않는 사람이에요. '
          '기준이 또렷하고, 자기 색이 분명해요.');
    }

    // 문단 2 — 핵심 십신.
    final sipsinPool = _strMapMap('sipsin')[topGodKo];
    final sipsinBody = sipsinPool == null
        ? ''
        : (sipsinPool['body'] as String?) ?? '';
    if (sipsinBody.isNotEmpty) paras.add(sipsinBody);

    // 문단 3 — 원국 합·충 + 용신.
    final hapKey = hapchung.cheonganHapPair;
    final hapLine = (hapKey != null)
        ? (_strMap('natal_hap')[hapKey] ?? '')
        : '';
    final jijiHapLine = hapchung.hasJijiHap
        ? (_strMap('natal_hap_jiji')['any'] ?? '')
        : '';
    final chungLine = hapchung.hasChung
        ? (_strMap('natal_chung')['any'] ?? '')
        : '';
    final yongsinLine = _strMap('yongsin')[ctx.yongsin] ?? '';
    final p3 = [hapLine, jijiHapLine, chungLine, yongsinLine]
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (p3.isNotEmpty) paras.add(p3);

    // 문단 4 — 그림자 다루는 법 (일간 5행 기준) + '바탕' 마무리.
    final dayEl = ctx.dayElement;
    final shadowLine = _strMap('shadow_handling')[dayEl] ?? '';
    final closing = (_poolRoot()['closing'] as String?) ??
        "이건 오늘 하루 운세가 아니라, 평생 잘 안 바뀌는 당신의 '바탕'이에요.";
    final p4 = [shadowLine, closing].where((s) => s.isNotEmpty).join(' ');
    paras.add(p4);

    return paras;
  }

  // ── 4. 오늘 CTA ──

  static String _buildTodayCta(String? topTopicId) {
    final ctaMap = _strMap('today_cta');
    if (topTopicId != null && ctaMap.containsKey(topTopicId)) {
      return ctaMap[topTopicId]!;
    }
    return ctaMap['default'] ??
        "→ 그럼 오늘은 이 바탕이 어떻게 건드려질까요? '오늘의 사주'에서 확인해봐요.";
  }

  // ── pool 접근 헬퍼 ──

  static Map<String, dynamic> _poolRoot() {
    return _poolCache ?? const {};
  }

  static Map<String, dynamic> _dayMasterPool(String stem) {
    final dm = _poolRoot()['day_master'];
    if (dm is! Map) return _builtinDayMaster(stem);
    final p = dm[stem];
    if (p is Map) return p.cast<String, dynamic>();
    return _builtinDayMaster(stem);
  }

  /// root[field] 가 {string: string} map 이면 cast, 아니면 빈 map.
  static Map<String, String> _strMap(String field) {
    final raw = _poolRoot()[field];
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (k is String && v is String) out[k] = v;
    });
    return out;
  }

  /// root[field] 가 {string: {string: string}} map 이면 cast.
  static Map<String, Map<String, dynamic>> _strMapMap(String field) {
    final raw = _poolRoot()[field];
    if (raw is! Map) return const {};
    final out = <String, Map<String, dynamic>>{};
    raw.forEach((k, v) {
      if (k is String && v is Map) out[k] = v.cast<String, dynamic>();
    });
    return out;
  }

  // ── pool 미적재 시 내장 fallback (앱이 죽지 않게) — 모두 v5 톤 ──

  static Map<String, dynamic> _builtinDayMaster(String stem) {
    const builtin = {
      '甲': {
        'ko': '큰 나무',
        'headline_strength': '한번 마음먹으면 위로 쭉 뻗어가는 사람이에요',
        'headline_shadow': '대신 한번 정한 방향은 잘 못 꺾어요',
        'body': '당신을 한 글자로 보면 甲木(갑목) — 곧게 위로 자라는 큰 나무 '
            '같은 기운이에요. 시작하는 힘이 좋고, 한번 정하면 그쪽으로 쭉 밀고 가요. '
            '단점도 같이 와요 — 방향을 한번 정하면 중간에 꺾기가 어려워요.',
      },
      '辛': {
        'ko': '잘 벼려진 보석',
        'headline_strength': '쉽게 안 휘는 사람이에요',
        'headline_shadow': '대신 혼자 너무 오래 버텨요',
        'body': '당신을 한 글자로 보면 辛金(신금) — 잘 벼려진 칼이나 보석 같은 '
            '금속이에요. 기준이 뚜렷하고 어지간한 압력엔 잘 안 휘어요. 단점도 같이 '
            '와요 — 힘들어도 티를 안 내고 혼자 너무 오래 버텨요.',
      },
    };
    final p = builtin[stem];
    if (p != null) return p;
    return const {
      'ko': '',
      'headline_strength': '쉽게 흔들리지 않는 사람이에요',
      'headline_shadow': '대신 혼자 너무 오래 끌어안고 가요',
      'body': '당신은 어지간한 압력에 잘 흔들리지 않는 사람이에요. '
          '기준이 또렷하고, 자기 색이 분명해요. 단점도 같이 와요 — 힘들 때도 '
          '티를 잘 안 내고 혼자 끌어안고 가는 편이에요.',
    };
  }
}
