// Pillar Seer — Round 106 (P2a) — 오늘의 사주 v5.
//
// R106 design doc §2 / §3 / §4 ground truth:
//  - 오늘의 사주를 P1 `TopicSelectorService` 가 고른 "오늘의 주제" 중심으로 재설계.
//  - 구조: 헤드라인 + 「구조 / 발동조건 / 행동」 + 근거 3칩 + 자기검증.
//  - 톤 = 친구 같은 용한 점쟁이. 단정 금지(§2): 감정·사건 단정 0, "~하는 날이에요"
//    헤드라인체 0. 발동조건은 무조건 조건형. 행동은 기분 좋든 나쁘든 유효.
//  - selector 가 selected=null (오늘 신호 없음) 이면 fallback (총평형 + 주제 surface X).
//
// 본 service 는 presentation layer only — 계산 엔진 (DailyService / TenGods /
// Gyeokguk / Yongsin / Shinsa / Hapchung / TodayEventService / TopicSelector) 의
// 산출물을 읽어 v5 카피로 조립만 한다. 점수·임계값·분기 1 bit 도 건드리지 않는다.
//
// fragment pool = assets/data/today_v5_pool.json — 단정 표현이 pool 에 절대 들어가지
// 않게 작성했고, content_integrity / r106 forbidden copy guard 가 회귀 감시한다.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'today_event_service.dart';
import 'topic_selector_service.dart';

/// 근거 칩 1개 — "왜 이 주제인지" 를 사용자 언어로 풀어쓴 한 줄.
class TodayV5EvidenceChip {
  /// 짧은 라벨 (칩 위 작은 글씨, 예: '오늘 일진 글자').
  final String label;

  /// 사용자 언어 설명 — 한자 즉시 풀이. 단정 표현 0.
  final String text;

  const TodayV5EvidenceChip({required this.label, required this.text});
}

/// 오늘의 사주 v5 reading.
class TodayV5Reading {
  /// 오늘 선택된 주제. 신호 없으면 null (fallback 모드).
  final DailyTopic? topic;

  /// 주제 라벨 (사용자 노출용 한국어, 예: '마음·감정'). topic null 이면 '오늘 총평'.
  final String topicLabel;

  /// 근거 3칩 — fallback 모드에서는 빈 list.
  final List<TodayV5EvidenceChip> evidenceChips;

  /// 헤드라인 — plain 한 사람 말 조언. 헤드라인체 아님.
  final String headline;

  /// 본문 「구조 / 발동조건 / 행동」 — '/' 구분 3단락.
  final String structureLine;
  final String triggerLine;
  final String actionLine;

  /// selector 신호가 없어 총평형 fallback 으로 생성됐는가.
  final bool isFallback;

  /// 자기검증에 쓰는 topic id (RecallFeedbackService 연결용). fallback 시 null.
  final String? topicId;

  const TodayV5Reading({
    required this.topic,
    required this.topicLabel,
    required this.evidenceChips,
    required this.headline,
    required this.structureLine,
    required this.triggerLine,
    required this.actionLine,
    required this.isFallback,
    required this.topicId,
  });

  /// 본문 전체 (구조 + 발동조건 + 행동) 를 한 문단으로.
  String get bodyJoined =>
      [structureLine, triggerLine, actionLine].where((p) => p.isNotEmpty).join(' ');
}

class TodayV5Service {
  // ── 자기검증 카피 — design doc §7 verbatim. 절대 변경 금지. ──
  static const String recallTitleKo = '어제 풀이, 직접 체크해볼까요?';
  static const String recallDescKo =
      '맞았는지 가볍게 눌러두면 다음에 당신이 어떤 관심분야를 더 보고 싶어 하는지 '
      '앱이 더 잘 맞춰요. 틀렸다 싶은 날도 중요한 힌트예요.';
  static const String recallCorrectKo = '맞았어요';
  static const String recallUnsureKo = '애매해요';
  static const String recallWrongKo = '아니에요';

  // ── fragment pool ──
  static Map<String, dynamic>? _poolCache;
  static bool _poolLoaded = false;

  /// today_v5_pool.json 1회 로드 + 캐시. 실패해도 silent (빈 map).
  /// 호출 측은 부팅 시 1회 await — 이후 동기 호출 OK. pool 미적재 시 build 는
  /// 내장 fallback 카피로 graceful (앱이 죽지 않는다).
  static Future<void> ensurePoolLoaded() async {
    if (_poolLoaded) return;
    try {
      final raw =
          await rootBundle.loadString('assets/data/today_v5_pool.json');
      final root = jsonDecode(raw) as Map<String, dynamic>;
      _poolCache = root;
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

  /// 오늘의 사주 v5 build. pure — 같은 입력이면 항상 같은 출력 (deterministic).
  ///
  /// [selection] 은 `TopicSelectorService.select(...)` 산출물.
  /// [event] 는 `TodayEventService.build(...)` 산출물 (근거 칩 라벨용).
  /// [chartSeed] 는 `SajuContext.chartSeed` — fragment 변형 deterministic pick anchor.
  static TodayV5Reading build({
    required SajuResult saju,
    required TopicSelection selection,
    required TodayEventReading event,
    required int chartSeed,
  }) {
    final selected = selection.selected;
    if (selected == null) {
      return _buildFallback(chartSeed: chartSeed);
    }

    final topicId = selected.id;
    final topicLabel = topicLabelKo(selected);
    final pool = _topicPool(topicId);

    final headline = _pick(pool, 'headline', chartSeed, 0,
        fallback: _fallbackHeadline(selected));
    final structure = _pick(pool, 'structure', chartSeed, 1,
        fallback: _fallbackStructure(selected));
    final trigger = _pick(pool, 'trigger', chartSeed, 2,
        fallback: _fallbackTrigger(selected));
    final action = _pick(pool, 'action', chartSeed, 3,
        fallback: _fallbackAction(selected));

    final chips = _buildChips(
      saju: saju,
      selection: selection,
      event: event,
    );

    return TodayV5Reading(
      topic: selected,
      topicLabel: topicLabel,
      evidenceChips: chips,
      headline: headline,
      structureLine: structure,
      triggerLine: trigger,
      actionLine: action,
      isFallback: false,
      topicId: topicId,
    );
  }

  /// selector 신호 0 → 총평형 fallback. 주제 surface X, 근거 칩 X.
  static TodayV5Reading _buildFallback({required int chartSeed}) {
    final pool = _noSignalPool();
    return TodayV5Reading(
      topic: null,
      topicLabel: '오늘 총평',
      evidenceChips: const [],
      headline: _pick(pool, 'headline', chartSeed, 0,
          fallback: '오늘은 특별히 튀는 신호 없이 평소 페이스대로 가도 괜찮아요.'),
      structureLine: _pick(pool, 'structure', chartSeed, 1,
          fallback: '오늘은 어느 한 영역이 두드러지게 움직이지 않아요. '
              '새 신호를 찾기보다 평소 습관대로 가는 쪽으로 하루를 잡아요.'),
      triggerLine: _pick(pool, 'trigger', chartSeed, 2,
          fallback: '만약 그래도 마음이 어딘가로 쏠리면, 그건 외부 신호가 아니라 '
              '당신이 원래 신경 쓰던 쪽이라는 뜻이에요.'),
      actionLine: _pick(pool, 'action', chartSeed, 3,
          fallback: '평소 챙기던 루틴 하나를 오늘 다시 잡아보면 좋아요. '
              '운동, 정리, 습관 — 무엇이든 작게 한 가지면 충분해요.'),
      isFallback: true,
      topicId: null,
    );
  }

  // ── 근거 3칩 ──

  /// TopicSelection.selectedCandidate 의 evidence 에서 "왜 이 주제인지" 3개를
  /// 사용자 언어로 풀어쓴다. 한자는 즉시 풀이. 신호가 3개 미만이면 chartKey 의
  /// 일반 근거로 보충해 항상 3개를 채운다.
  static List<TodayV5EvidenceChip> _buildChips({
    required SajuResult saju,
    required TopicSelection selection,
    required TodayEventReading event,
  }) {
    final cand = selection.selectedCandidate;
    final chips = <TodayV5EvidenceChip>[];
    if (cand != null) {
      // evidence 를 strength 내림차순으로 — 강한 근거부터 칩으로.
      final ev = [...cand.evidence]
        ..sort((a, b) => b.strength.compareTo(a.strength));
      for (final e in ev) {
        final chip = _chipForEvidence(e, event);
        if (chip != null && !chips.any((c) => c.label == chip.label)) {
          chips.add(chip);
        }
        if (chips.length >= 3) break;
      }
    }
    // 부족하면 안정 보충 (오늘 일진 글자 + 내 일간 + 사건 카테고리).
    if (chips.length < 3) {
      final today = event;
      final extras = <TodayV5EvidenceChip>[
        TodayV5EvidenceChip(
          label: '오늘 일진 글자',
          text: '오늘 들어온 글자가 당신 사주와 만나는 자리를 봤어요.',
        ),
        TodayV5EvidenceChip(
          label: '내 일간과의 관계',
          text: '태어난 날의 기운(${_dayMasterPlain(saju.dayMaster)})과 오늘 글자가 '
              '어떻게 맞물리는지 봤어요.',
        ),
        TodayV5EvidenceChip(
          label: '오늘 사건 영역',
          text: "오늘 가장 두드러진 영역은 '${today.categoryDominant.ko}' 쪽이에요.",
        ),
      ];
      for (final e in extras) {
        if (chips.length >= 3) break;
        if (!chips.any((c) => c.label == e.label)) chips.add(e);
      }
    }
    return chips.take(3).toList();
  }

  /// 한 evidence → 사용자 언어 칩. 매핑 안 되면 null.
  static TodayV5EvidenceChip? _chipForEvidence(
    TopicEvidence e,
    TodayEventReading event,
  ) {
    switch (e.source) {
      case EvidenceSource.todayGod:
        return const TodayV5EvidenceChip(
          label: '오늘 일진 글자',
          text: '오늘 들어온 천간이 당신 일간과 만드는 관계가 또렷해요.',
        );
      case EvidenceSource.todayEventDominantCategory:
      case EvidenceSource.todayEventSubCategory:
        return TodayV5EvidenceChip(
          label: '오늘 사건 영역',
          text: "오늘 흐름이 '${event.categoryDominant.ko}' 쪽으로 모이고 있어요.",
        );
      case EvidenceSource.activeShinsa:
        final shin = _shinsaLabel(e.debugLabel);
        return TodayV5EvidenceChip(
          label: '오늘의 신살',
          text: "오늘 사주에 '$shin'(이)라는 작은 손님 글자가 들어왔어요.",
        );
      case EvidenceSource.hapChung:
        return const TodayV5EvidenceChip(
          label: '합·충 관계',
          text: '오늘 일진과 당신 일지가 서로 끌어당기거나 부딪치는 자리예요.',
        );
      case EvidenceSource.gyeokguk:
        return const TodayV5EvidenceChip(
          label: '내 사주 짜임새',
          text: '당신 사주가 원래 갖고 있는 큰 틀과 오늘 흐름이 맞물려요.',
        );
      case EvidenceSource.yongsin:
        return const TodayV5EvidenceChip(
          label: '내게 도움 되는 기운',
          text: '당신에게 힘이 되는 기운이 오늘 흐름과 닿아 있어요.',
        );
      case EvidenceSource.tenGodFrequency:
        return const TodayV5EvidenceChip(
          label: '내 사주 성향',
          text: '당신 사주가 평소 자주 쓰는 기운이 오늘 영역과 겹쳐요.',
        );
      case EvidenceSource.fiveElementBalance:
        return const TodayV5EvidenceChip(
          label: '오행 균형 (보조)',
          text: '당신 사주에서 강한 오행이 오늘 주제 쪽을 살짝 거들어요.',
        );
    }
  }

  /// debugLabel 'shinsa=도화' → '도화'.
  static String _shinsaLabel(String debugLabel) {
    final idx = debugLabel.indexOf('=');
    final raw = idx >= 0 ? debugLabel.substring(idx + 1) : debugLabel;
    return raw.isEmpty ? '특별한 글자' : raw;
  }

  /// 일간 천간 → 사용자 언어 풀이 (한자 단독 노출 0).
  static String _dayMasterPlain(String dayMaster) {
    const map = {
      '甲': '큰 나무 같은 기운',
      '乙': '풀·덩굴 같은 기운',
      '丙': '한낮의 햇빛 같은 기운',
      '丁': '촛불·등불 같은 기운',
      '戊': '넓은 땅 같은 기운',
      '己': '밭흙 같은 기운',
      '庚': '단단한 쇠 같은 기운',
      '辛': '잘 벼려진 보석 같은 기운',
      '壬': '큰 물 같은 기운',
      '癸': '이슬·빗물 같은 기운',
    };
    return map[dayMaster] ?? '당신 고유의 기운';
  }

  // ── 주제 라벨 (사용자 노출용 한국어) ──

  static String topicLabelKo(DailyTopic topic) {
    switch (topic) {
      case DailyTopic.communication:
        return '대화·표현';
      case DailyTopic.moneySpending:
        return '돈·소비';
      case DailyTopic.workCareer:
        return '일·커리어';
      case DailyTopic.loveConnection:
        return '연애·호감';
      case DailyTopic.familyHome:
        return '가족·집';
      case DailyTopic.healthCondition:
        return '건강·컨디션';
      case DailyTopic.mentalEmotion:
        return '마음·감정';
      case DailyTopic.relationshipConflict:
        return '사람 관계';
      case DailyTopic.challengeOpportunity:
        return '도전·기회';
      case DailyTopic.restRecovery:
        return '쉼·회복';
    }
  }

  // ── pool 접근 ──

  static Map<String, dynamic> _topicPool(String topicId) {
    final root = _poolCache;
    if (root == null) return const {};
    final topics = root['topics'];
    if (topics is! Map) return const {};
    final p = topics[topicId];
    return p is Map ? p.cast<String, dynamic>() : const {};
  }

  static Map<String, dynamic> _noSignalPool() {
    final root = _poolCache;
    if (root == null) return const {};
    final p = root['no_signal_fallback'];
    return p is Map ? p.cast<String, dynamic>() : const {};
  }

  /// pool[field] list 에서 chartSeed + salt 로 deterministic pick. 미스 시 fallback.
  static String _pick(
    Map<String, dynamic> pool,
    String field,
    int chartSeed,
    int salt, {
    required String fallback,
  }) {
    final raw = pool[field];
    if (raw is! List || raw.isEmpty) return fallback;
    final list = raw.whereType<String>().toList();
    if (list.isEmpty) return fallback;
    final idx = ((chartSeed ~/ 7 + salt * 31).abs()) % list.length;
    return list[idx];
  }

  // ── pool 미적재 시 내장 fallback (앱이 죽지 않게) — 모두 v5 톤 ──

  static String _fallbackHeadline(DailyTopic t) {
    return '오늘은 ${topicLabelKo(t)} 쪽에서 뭐든 한 박자만 늦추면 돼요.';
  }

  static String _fallbackStructure(DailyTopic t) {
    return '오늘은 ${topicLabelKo(t)} 쪽 결정을 바로 정하기보다 한 박자 두고 '
        '다루는 게 잘 맞아요. 언제, 어떻게 다룰지를 먼저 정하고 움직여요.';
  }

  static String _fallbackTrigger(DailyTopic t) {
    return '만약 이쪽에서 지금 당장 무언가 정하고 싶어지면 — '
        "그게 '한 박자 쉬고 가자'는 신호예요.";
  }

  static String _fallbackAction(DailyTopic t) {
    return '기분이 좋든 안 좋든, 큰 결정은 10분 뒤로 미뤄도 늦지 않아요. '
        '오늘은 작은 한 가지만 분명히 해두면 충분해요.';
  }
}
