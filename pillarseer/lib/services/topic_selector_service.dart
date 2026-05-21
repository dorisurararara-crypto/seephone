// Pillar Seer — Round 106 (P1) — 오늘의 주제 selector.
//
// R106 design doc §4 ground truth:
//  - 10 주제 string 안정 매핑.
//  - 매일 "오늘 실제 발동한 주제"만 candidate.
//    candidate 조건 = evidence 2개 이상 OR strong single signal.
//  - 신호 없는 주제는 userPref 가 아무리 높아도 surface 금지 (§1-3 창작 금지).
//  - finalScore = signalStrength*0.55 + userPref*0.30 + freshness*0.10 + exploration*0.05.
//  - threshold 낮추지 않는다. 불확실하면 no-selection (null) 허용.
//
// keying (§5): 오행 비율만으로 keying 금지. full chart key =
//   일주 60갑자 + 십신 구성 + 합충형 + 격국/용신 + 신살 + todayFingerprint
//   (오늘 일진·오늘 십신·오늘 지지관계). 오행 비율은 보조 근거만.
//
// 본 sprint 는 core service + tests 만. UI / 알림 / 오늘의사주 화면·문구 변경 0.
// 계산 엔진 (DailyService / TenGods / Gyeokguk / Yongsin / Shinsa / Hapchung) 의
// 점수·임계값·분기는 1 bit 도 건드리지 않는다 — selector 는 그 산출물을 읽기만 한다.

import '../models/saju_result.dart';
import 'hapchung_service.dart';
import 'saju_context.dart';
import 'today_event_service.dart';

/// R106 10 주제. id 는 design doc §4-A string 과 1:1 안정 매핑.
enum DailyTopic {
  communication,
  moneySpending,
  workCareer,
  loveConnection,
  familyHome,
  healthCondition,
  mentalEmotion,
  relationshipConflict,
  challengeOpportunity,
  restRecovery,
}

extension DailyTopicId on DailyTopic {
  /// design doc §4-A 의 string id — 안정 매핑. 절대 변경 금지.
  String get id {
    switch (this) {
      case DailyTopic.communication:
        return 'communication';
      case DailyTopic.moneySpending:
        return 'money_spending';
      case DailyTopic.workCareer:
        return 'work_career';
      case DailyTopic.loveConnection:
        return 'love_connection';
      case DailyTopic.familyHome:
        return 'family_home';
      case DailyTopic.healthCondition:
        return 'health_condition';
      case DailyTopic.mentalEmotion:
        return 'mental_emotion';
      case DailyTopic.relationshipConflict:
        return 'relationship_conflict';
      case DailyTopic.challengeOpportunity:
        return 'challenge_opportunity';
      case DailyTopic.restRecovery:
        return 'rest_recovery';
    }
  }
}

/// string id → DailyTopic 역매핑. 미스 시 null.
DailyTopic? dailyTopicFromId(String id) {
  for (final t in DailyTopic.values) {
    if (t.id == id) return t;
  }
  return null;
}

/// 근거 출처 — 어떤 엔진 산출물이 신호를 만들었는지.
enum EvidenceSource {
  todayEventDominantCategory,
  todayEventSubCategory,
  activeShinsa,
  hapChung,
  todayGod,
  yongsin,
  gyeokguk,
  tenGodFrequency,
  fiveElementBalance, // 보조 근거 only (§5 — 오행은 보조).
}

/// 한 주제에 붙는 근거 한 건 (디버그 가능 구조).
///
/// user-facing 예언문이 아니다 — debug label 은 톤 규칙 대상 아님.
/// 다만 §3 v5 / §2 단정 금지 위반 단어를 넣지 않는다 (forbidden copy guard 대상).
class TopicEvidence {
  final DailyTopic topic;
  final EvidenceSource source;

  /// 0.0~1.0 신호 강도.
  final double strength;

  /// 디버그 라벨 — 어떤 글자/관계가 근거인지. 사용자 노출용 카피 아님.
  final String debugLabel;

  /// 오행 비율 등 보조 근거는 candidate 자격(evidence count)에 절반만 기여.
  /// §5 — 오행 비율만으로 keying 금지.
  final bool auxiliary;

  const TopicEvidence({
    required this.topic,
    required this.source,
    required this.strength,
    required this.debugLabel,
    this.auxiliary = false,
  });
}

/// finalScore 4 component (디버그 가능 — 각 0.0~1.0 double).
class TopicScoreBreakdown {
  final double signalStrength;
  final double userPref;
  final double freshness;
  final double exploration;
  final double finalScore;

  const TopicScoreBreakdown({
    required this.signalStrength,
    required this.userPref,
    required this.freshness,
    required this.exploration,
    required this.finalScore,
  });
}

/// 한 주제의 candidate 평가 결과.
class TopicCandidate {
  final DailyTopic topic;
  final List<TopicEvidence> evidence;
  final TopicScoreBreakdown breakdown;

  /// strong single signal 로 candidate 자격을 얻었는가.
  final bool byStrongSingle;

  const TopicCandidate({
    required this.topic,
    required this.evidence,
    required this.breakdown,
    required this.byStrongSingle,
  });

  /// candidate 자격 evidence count — 보조(auxiliary) 근거는 0.5 로 계산.
  double get weightedEvidenceCount {
    double c = 0;
    for (final e in evidence) {
      c += e.auxiliary ? 0.5 : 1.0;
    }
    return c;
  }
}

/// selector 출력 — selected topic + 전체 candidate + full chart key.
class TopicSelection {
  /// 오늘 선택된 주제. 신호 없으면 null (억지 선택 금지).
  final DailyTopic? selected;

  /// candidate 자격을 통과한 모든 주제 (finalScore 내림차순).
  /// cooldown(suppressed) 된 주제도 포함하므로 — UI 노출엔 [eligibleCandidates]
  /// 를 써야 cooldown 누수가 없다.
  final List<TopicCandidate> candidates;

  /// 신호는 잡혔으나 candidate 자격(evidence 2+ / strong single)에 못 미친 주제들.
  final List<TopicCandidate> belowThreshold;

  /// §5 full chart key — 충돌 방지 keying 재료. 같은 chart/date → 같은 key.
  final String chartKey;

  /// 14일 cooldown 으로 suppress 된 candidate 들 (finalScore 내림차순).
  /// candidate 자격은 있지만 §4-D cooldown 중이라 노출 금지.
  final List<TopicCandidate> suppressedCandidates;

  const TopicSelection({
    required this.selected,
    required this.candidates,
    required this.belowThreshold,
    required this.chartKey,
    this.suppressedCandidates = const [],
  });

  /// P2+ UI 가 노출해도 되는 candidate — candidate 자격을 통과하고 cooldown 도
  /// 아닌 주제. cooldown 된 주제가 새어나가지 않게 selector 가 미리 걸러둔다.
  List<TopicCandidate> get eligibleCandidates {
    if (suppressedCandidates.isEmpty) return candidates;
    final suppressed = suppressedCandidates.map((c) => c.topic).toSet();
    return candidates.where((c) => !suppressed.contains(c.topic)).toList();
  }

  TopicCandidate? get selectedCandidate {
    if (selected == null) return null;
    for (final c in candidates) {
      if (c.topic == selected) return c;
    }
    return null;
  }
}

class TopicSelectorService {
  // ── finalScore 가중치 — design doc §4-C. 절대 변경 금지. ──
  static const double wSignal = 0.55;
  static const double wUserPref = 0.30;
  static const double wFreshness = 0.10;
  static const double wExploration = 0.05;

  /// candidate 자격: 가중 evidence count 가 이 값 이상.
  /// 보조 근거 0.5 환산이므로, 일반 근거 2개 OR (일반 1 + 보조 2) = 2.0.
  static const double candidateEvidenceThreshold = 2.0;

  /// strong single signal 기준 — 단일 근거 strength 가 이 값 이상이면
  /// evidence count 가 1개여도 candidate 자격. design doc §4-B "강한 단일 신호".
  static const double strongSingleThreshold = 0.80;

  /// 신호 강도 정규화 상한 — 한 주제 raw 신호 합이 이 값이면 signalStrength=1.0.
  static const double _signalNormCap = 1.6;

  /// freshness 회복 기간(일) — 마지막 노출 후 이 일수가 지나면 freshness=1.0.
  static const int freshnessRecoveryDays = 14;

  /// 오늘의 주제를 선택한다. pure — 같은 입력이면 항상 같은 출력 (deterministic).
  ///
  /// [event] 는 `TodayEventService.build(...)` 산출물, [ctx] 는 `SajuContext.from`
  /// 산출물. [userPrefById] / [shownDaysAgoById] / [suppressedIds] 는
  /// `RecallFeedbackService` 에서 미리 읽어와 주입한다 (selector 는 prefs 비의존).
  ///
  /// [userPrefById]      : topic.id → 0.0~1.0 사용자 선호.
  /// [shownDaysAgoById]  : topic.id → 마지막 노출 며칠 전 (없으면 키 부재).
  /// [suppressedIds]     : 14일 cooldown 중인 topic.id set — selected 후보 제외.
  static TopicSelection select({
    required SajuResult saju,
    required SajuContext ctx,
    required TodayEventReading event,
    required DateTime date,
    Map<String, double> userPrefById = const {},
    Map<String, int> shownDaysAgoById = const {},
    Set<String> suppressedIds = const {},
  }) {
    final chartKey = buildChartKey(saju: saju, ctx: ctx, event: event, date: date);

    // 1. 주제별 근거 수집.
    final evidenceByTopic = _collectEvidence(ctx: ctx, event: event);

    // 2. 주제별 candidate 평가.
    final candidates = <TopicCandidate>[];
    final belowThreshold = <TopicCandidate>[];
    final explorationSeed = _explorationSeed(chartKey);

    for (final topic in DailyTopic.values) {
      final ev = evidenceByTopic[topic] ?? const <TopicEvidence>[];
      if (ev.isEmpty) {
        // 신호 0 — userPref 가 높아도 candidate/selected 절대 금지 (§4-B).
        continue;
      }
      final breakdown = _scoreTopic(
        topic: topic,
        evidence: ev,
        userPref: userPrefById[topic.id] ?? 0.5,
        shownDaysAgo: shownDaysAgoById[topic.id],
        explorationSeed: explorationSeed,
        date: date,
      );

      // candidate 자격 판정.
      double weighted = 0;
      double maxSingle = 0;
      for (final e in ev) {
        weighted += e.auxiliary ? 0.5 : 1.0;
        if (e.strength > maxSingle) maxSingle = e.strength;
      }
      final byCount = weighted >= candidateEvidenceThreshold;
      final byStrong = maxSingle >= strongSingleThreshold;

      final cand = TopicCandidate(
        topic: topic,
        evidence: ev,
        breakdown: breakdown,
        byStrongSingle: !byCount && byStrong,
      );
      if (byCount || byStrong) {
        candidates.add(cand);
      } else {
        belowThreshold.add(cand);
      }
    }

    // 3. finalScore 내림차순 정렬 (동점 시 topic enum 순서 — 안정 deterministic).
    candidates.sort((a, b) {
      final c = b.breakdown.finalScore.compareTo(a.breakdown.finalScore);
      if (c != 0) return c;
      return a.topic.index.compareTo(b.topic.index);
    });
    belowThreshold.sort((a, b) {
      final c = b.breakdown.finalScore.compareTo(a.breakdown.finalScore);
      if (c != 0) return c;
      return a.topic.index.compareTo(b.topic.index);
    });

    // 4. selected — candidate 중 suppress 되지 않은 최상위. 없으면 null.
    //    동시에 suppressed candidate 를 분리해 UI 노출용 리스트를 깨끗하게 만든다.
    DailyTopic? selected;
    final suppressedCandidates = <TopicCandidate>[];
    for (final c in candidates) {
      if (suppressedIds.contains(c.topic.id)) {
        suppressedCandidates.add(c);
        continue;
      }
      selected ??= c.topic;
    }

    return TopicSelection(
      selected: selected,
      candidates: candidates,
      belowThreshold: belowThreshold,
      chartKey: chartKey,
      suppressedCandidates: suppressedCandidates,
    );
  }

  /// §5 full chart key — 충돌 방지 keying. 일주 60갑자 + 십신 구성 + 합충형 +
  /// 격국/용신 + 신살 + todayFingerprint(오늘 일진·오늘 십신·오늘 지지관계).
  /// 오행 비율은 보조로만 꼬리에 붙인다.
  ///
  /// `hapchung=` 는 **원국(natal 4기둥) 합충** 이다 — design doc §5 요구. 오늘
  /// 일진×일주 관계(`ctx.todayRelations`)는 원국 합충이 아니므로 todayFingerprint
  /// (`fp=`) 쪽에만 둔다.
  static String buildChartKey({
    required SajuResult saju,
    required SajuContext ctx,
    required TodayEventReading event,
    required DateTime date,
  }) {
    // 십신 구성 — TenGod enum index:count 를 안정 정렬해 직렬화.
    final tg = ctx.tenGodFrequency.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    final tgPart = tg.map((e) => '${e.key.index}:${e.value}').join(',');

    // 합충형 — 원국 4기둥(년/월/일/시) 합충. HapchungService 는 호출만 (계산 로직 미수정).
    final natalHapchung = _natalHapchungKey(saju);

    // 신살 — 정적 활성 신살 set (안정 정렬).
    final shinsa = ctx.activeShinsa.toList()..sort();

    // todayFingerprint — 오늘 일진 + 오늘 십신 + 오늘 지지관계(일진×일주).
    final todayGodIdx = ctx.todayGod?.index ?? -1;
    final eventShinsa = event.activeShinsa.toList()..sort();
    final todayRel = ctx.todayRelations.toList()..sort();
    final fingerprint = [
      'tp=${ctx.todayPillar ?? saju.dayPillar.text}',
      'tg=$todayGodIdx',
      'trel=${event.hapChungType}',
      'tnatalrel=${todayRel.join("/")}', // 오늘 일진×일주 관계 — 원국 합충 아님.
      'tcat=${event.categoryDominant.index}.${event.categorySub.index}',
      'tshin=${eventShinsa.join("/")}',
      'd=${date.year}-${date.month}-${date.day}',
    ].join(';');

    final parts = [
      'ilju=${saju.dayPillar.text}', // 일주 60갑자
      'tengod=$tgPart', // 십신 구성
      'hapchung=$natalHapchung', // 합충형 (원국 4기둥)
      'gyeok=${ctx.gyeokgukShort}', // 격국
      'yongsin=${ctx.yongsin}', // 용신
      'huisin=${ctx.huisin}',
      'shinsa=${shinsa.join("/")}', // 신살
      'fp=$fingerprint', // todayFingerprint
      // 오행 비율 — 보조 근거 only (§5).
      'aux5=${ctx.wood}/${ctx.fire}/${ctx.earth}/${ctx.metal}/${ctx.water}',
    ];
    return parts.join('|');
  }

  /// 원국 4기둥 합·충 → 안정 직렬화 string. HapchungService.analyzeChart 산출물
  /// (천간5합·지지6합·지지6충)을 area-pair 단위로 정렬해 deterministic 하게 펼친다.
  /// HapchungService 는 호출만 — 계산 로직은 1 bit 도 건드리지 않는다.
  static String _natalHapchungKey(SajuResult saju) {
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
    final hapParts = analysis.hap
        .map((h) => 'H:${h.area1}-${h.area2}:${h.element}')
        .toList()
      ..sort();
    final chungParts =
        analysis.chung.map((c) => 'C:${c.area1}-${c.area2}').toList()..sort();
    return [...hapParts, ...chungParts].join(',');
  }

  // ── 내부 — 근거 수집 ──

  /// 엔진 산출물 → 주제별 근거 list. 신호 없는 주제는 키 자체가 없다.
  static Map<DailyTopic, List<TopicEvidence>> _collectEvidence({
    required SajuContext ctx,
    required TodayEventReading event,
  }) {
    final out = <DailyTopic, List<TopicEvidence>>{};
    void add(TopicEvidence e) =>
        (out[e.topic] ??= <TopicEvidence>[]).add(e);

    // 1. 오늘 사건 dominant/sub 카테고리 → 주제.
    add(TopicEvidence(
      topic: _topicForEventCategory(event.categoryDominant),
      source: EvidenceSource.todayEventDominantCategory,
      strength: _starToStrength(_dominantStar(event)),
      debugLabel: 'eventDominant=${event.categoryDominant.name}',
    ));
    if (event.categorySub != event.categoryDominant) {
      add(TopicEvidence(
        topic: _topicForEventCategory(event.categorySub),
        source: EvidenceSource.todayEventSubCategory,
        strength: 0.45,
        debugLabel: 'eventSub=${event.categorySub.name}',
      ));
    }

    // 2. 오늘 활성 신살 → 주제.
    for (final shin in event.activeShinsa) {
      final mapped = _topicForShinsa(shin);
      if (mapped == null) continue;
      add(TopicEvidence(
        topic: mapped.$1,
        source: EvidenceSource.activeShinsa,
        strength: mapped.$2,
        debugLabel: 'shinsa=$shin',
      ));
    }

    // 3. 오늘 합/충/형/파/해 → 주제.
    final relTopic = _topicForRelation(event.hapChungType);
    if (relTopic != null) {
      add(TopicEvidence(
        topic: relTopic.$1,
        source: EvidenceSource.hapChung,
        strength: relTopic.$2,
        debugLabel: 'relation=${event.hapChungType}',
      ));
    }

    // 4. 오늘 십신 (일진→일간) → 주제.
    if (ctx.todayGod != null) {
      add(TopicEvidence(
        topic: _topicForTenGod(ctx.todayGod as TenGod),
        source: EvidenceSource.todayGod,
        strength: 0.55,
        debugLabel: 'todayGod=${ctx.todayGod!.name}',
      ));
    }

    // 5. 격국 → 주제 (정적 — 보조 성격, auxiliary).
    final gyeokTopic = _topicForGyeokguk(ctx.gyeokgukShort);
    if (gyeokTopic != null) {
      add(TopicEvidence(
        topic: gyeokTopic,
        source: EvidenceSource.gyeokguk,
        strength: 0.35,
        debugLabel: 'gyeokguk=${ctx.gyeokgukShort}',
        auxiliary: true,
      ));
    }

    // 6. 오행 비율 dominant/deficit → 보조 근거 only (§5 — keying 금지).
    final domTopic = _topicForElement(ctx.dominantElement);
    if (domTopic != null) {
      add(TopicEvidence(
        topic: domTopic,
        source: EvidenceSource.fiveElementBalance,
        strength: 0.20,
        debugLabel: 'dominantElement=${ctx.dominantElement}',
        auxiliary: true,
      ));
    }

    return out;
  }

  // ── 내부 — scoring ──

  static TopicScoreBreakdown _scoreTopic({
    required DailyTopic topic,
    required List<TopicEvidence> evidence,
    required double userPref,
    required int? shownDaysAgo,
    required double explorationSeed,
    required DateTime date,
  }) {
    // signalStrength — 근거 strength 합을 normalize cap 으로 0~1 clamp.
    double raw = 0;
    for (final e in evidence) {
      raw += e.strength;
    }
    final signalStrength = (raw / _signalNormCap).clamp(0.0, 1.0);

    // freshness — 최근 노출 적을수록 높음. 노출 기록 없으면 1.0.
    double freshness;
    if (shownDaysAgo == null) {
      freshness = 1.0;
    } else {
      freshness =
          (shownDaysAgo / freshnessRecoveryDays).clamp(0.0, 1.0).toDouble();
    }

    // exploration — topic 별 안정 소량 가중 (chartKey seed + topic index).
    final exploration = _explorationFor(topic, explorationSeed);

    final pref = userPref.clamp(0.0, 1.0);
    final finalScore = signalStrength * wSignal +
        pref * wUserPref +
        freshness * wFreshness +
        exploration * wExploration;

    return TopicScoreBreakdown(
      signalStrength: signalStrength,
      userPref: pref,
      freshness: freshness,
      exploration: exploration,
      finalScore: finalScore,
    );
  }

  /// chartKey → 0.0~1.0 seed. deterministic.
  static double _explorationSeed(String chartKey) {
    int h = 0;
    for (final c in chartKey.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return (h % 1000) / 1000.0;
  }

  /// topic 별 exploration 가중 — seed + topic index 결합, 0~1.
  static double _explorationFor(DailyTopic topic, double seed) {
    final mixed = ((seed * 1000).round() + topic.index * 97) % 1000;
    return mixed / 1000.0;
  }

  static double _starToStrength(int star) {
    // 1~5 별 → 0.2~1.0.
    return (star.clamp(1, 5)) / 5.0;
  }

  static int _dominantStar(TodayEventReading event) {
    // dominant 카테고리에 해당하는 별점.
    switch (event.categoryDominant) {
      case EventCategory.love:
        return event.starsLove;
      case EventCategory.money:
        return event.starsMoney;
      case EventCategory.work:
        return event.starsWork;
      case EventCategory.health:
        return event.starsHealth;
      case EventCategory.relationship:
      case EventCategory.luck:
        // 별점 없는 카테고리 — rawScores 로 강도 추정.
        final raw = event.rawScores[event.categoryDominant] ?? 1;
        if (raw >= 9) return 5;
        if (raw >= 7) return 4;
        if (raw >= 5) return 3;
        if (raw >= 3) return 2;
        return 1;
    }
  }

  // ── 내부 — 매핑 (엔진 카테고리/근거 → R106 10 주제) ──

  static DailyTopic _topicForEventCategory(EventCategory c) {
    switch (c) {
      case EventCategory.relationship:
        return DailyTopic.relationshipConflict;
      case EventCategory.money:
        return DailyTopic.moneySpending;
      case EventCategory.work:
        return DailyTopic.workCareer;
      case EventCategory.love:
        return DailyTopic.loveConnection;
      case EventCategory.health:
        return DailyTopic.healthCondition;
      case EventCategory.luck:
        return DailyTopic.challengeOpportunity;
    }
  }

  /// 신살 → (주제, strength). 미스 시 null.
  static (DailyTopic, double)? _topicForShinsa(String shin) {
    switch (shin) {
      case '도화':
        return (DailyTopic.loveConnection, 0.85); // strong single
      case '역마':
        return (DailyTopic.challengeOpportunity, 0.82); // strong single
      case '문창귀인':
        return (DailyTopic.workCareer, 0.7);
      case '천을귀인':
        return (DailyTopic.challengeOpportunity, 0.6);
      case '양인':
        return (DailyTopic.relationshipConflict, 0.6);
      case '괴강':
        return (DailyTopic.workCareer, 0.55);
      case '백호':
        return (DailyTopic.healthCondition, 0.55);
      case '화개':
        return (DailyTopic.restRecovery, 0.5);
      case '공망':
        return (DailyTopic.mentalEmotion, 0.5);
      case '망신':
        return (DailyTopic.relationshipConflict, 0.45);
      case '겁살':
      case '재살':
        return (DailyTopic.moneySpending, 0.4);
      case '월살':
      case '천살':
        return (DailyTopic.restRecovery, 0.4);
      case '장성':
        return (DailyTopic.workCareer, 0.4);
      case '반안':
        return (DailyTopic.familyHome, 0.4);
      case '지살':
        return (DailyTopic.challengeOpportunity, 0.4);
      case '육해':
        return (DailyTopic.relationshipConflict, 0.4);
    }
    return null;
  }

  /// 합/충/형/파/해 → (주제, strength). '없음' 이면 null.
  static (DailyTopic, double)? _topicForRelation(String rel) {
    switch (rel) {
      case '합':
        return (DailyTopic.relationshipConflict, 0.55);
      case '충':
        return (DailyTopic.healthCondition, 0.6);
      case '형':
        return (DailyTopic.relationshipConflict, 0.6);
      case '파':
      case '해':
        return (DailyTopic.communication, 0.5);
    }
    return null;
  }

  static DailyTopic _topicForTenGod(TenGod god) {
    switch (god) {
      case TenGod.bigyeon:
      case TenGod.geopjae:
        return DailyTopic.relationshipConflict;
      case TenGod.siksin:
      case TenGod.sanggwan:
        return DailyTopic.communication;
      case TenGod.pyeonjae:
      case TenGod.jeongjae:
        return DailyTopic.moneySpending;
      case TenGod.pyeongwan:
      case TenGod.jeonggwan:
        return DailyTopic.workCareer;
      case TenGod.pyeonin:
      case TenGod.jeongin:
        return DailyTopic.restRecovery;
    }
  }

  /// 격국 short 이름 → 주제. 미스 시 null.
  static DailyTopic? _topicForGyeokguk(String gyeokShort) {
    if (gyeokShort.isEmpty) return null;
    if (gyeokShort.contains('재')) return DailyTopic.moneySpending;
    if (gyeokShort.contains('관') || gyeokShort.contains('살')) {
      return DailyTopic.workCareer;
    }
    if (gyeokShort.contains('인')) return DailyTopic.restRecovery;
    if (gyeokShort.contains('식') || gyeokShort.contains('상')) {
      return DailyTopic.communication;
    }
    if (gyeokShort.contains('비') || gyeokShort.contains('겁') ||
        gyeokShort.contains('록') || gyeokShort.contains('양')) {
      return DailyTopic.relationshipConflict;
    }
    return null;
  }

  /// 오행 dominant → 주제 (보조 근거 only).
  static DailyTopic? _topicForElement(String element) {
    switch (element) {
      case '木':
        return DailyTopic.challengeOpportunity;
      case '火':
        return DailyTopic.communication;
      case '土':
        return DailyTopic.familyHome;
      case '金':
        return DailyTopic.workCareer;
      case '水':
        return DailyTopic.mentalEmotion;
    }
    return null;
  }
}
