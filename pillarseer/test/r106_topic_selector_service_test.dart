// Round 106 (P1) — TopicSelectorService 검증.
//
// design doc §4 / §5:
//  - 신호 0 topic 은 userPref 높아도 candidate/selected 금지.
//  - evidence 2+ topic 은 candidate.
//  - strong single signal topic 은 candidate.
//  - finalScore = signalStrength*0.55 + userPref*0.30 + freshness*0.10 + exploration*0.05.
//  - selector deterministic.
//  - full chart key 가 일주/십신/합충형/격국/용신/신살/todayPillar/todayRelation 포함.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/daily_service.dart' show DayEnergyKind;
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/today_event_service.dart';
import 'package:pillarseer/services/topic_selector_service.dart';

/// 테스트용 SajuContext build helper — 1995-10-27 辛卯 골든 케이스 기반 윤곽.
SajuContext buildCtx({
  String dayMaster = '辛',
  String dayElement = '金',
  Map<TenGod, int>? tenGodFreq,
  Set<String> activeShinsa = const {},
  List<String> todayRelations = const [],
  String gyeokgukShort = '정관격',
  String yongsin = '土',
  String huisin = '金',
  String dominantElement = '金',
  TenGod? todayGod,
  String? todayPillar,
  int chartSeed = 12345,
}) {
  return SajuContext(
    dayMaster: dayMaster,
    dayElement: dayElement,
    dayYang: false,
    monthBranch: '戌',
    season: '가을',
    wood: 16,
    fire: 21,
    earth: 17,
    metal: 41,
    water: 4,
    dominantElement: dominantElement,
    deficitElement: '水',
    tenGodFrequency: tenGodFreq ?? const {TenGod.jeonggwan: 2, TenGod.bigyeon: 1},
    strengthLabel: '신강',
    gyeokgukShort: gyeokgukShort,
    gyeokgukFull: '$gyeokgukShort (格)',
    yongsin: yongsin,
    huisin: huisin,
    gisin: '火',
    activeShinsa: activeShinsa,
    gongMangAreas: const [],
    currentDaewoon: null,
    currentDaewoonGod: null,
    todayPillar: todayPillar,
    todayGod: todayGod,
    todayRelations: todayRelations,
    chartSeed: chartSeed,
    userAge: 30,
  );
}

/// 테스트용 TodayEventReading build helper.
TodayEventReading buildEvent({
  EventCategory dominant = EventCategory.work,
  EventCategory sub = EventCategory.relationship,
  TenGodGroup group = TenGodGroup.gwanseong,
  List<String> activeShinsa = const [],
  String hapChung = '없음',
  int starsLove = 2,
  int starsMoney = 2,
  int starsWork = 3,
  int starsHealth = 2,
  Map<EventCategory, int>? rawScores,
}) {
  return TodayEventReading(
    categoryDominant: dominant,
    categorySub: sub,
    tenGodGroup: group,
    activeShinsa: activeShinsa,
    hapChungType: hapChung,
    starsLove: starsLove,
    starsMoney: starsMoney,
    starsWork: starsWork,
    starsHealth: starsHealth,
    sourceReason: '',
    energy: DayEnergyKind.mixedDay,
    rawScores: rawScores ??
        {for (final c in EventCategory.values) c: 5},
  );
}

SajuResult buildSaju() {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'),
    dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
    hourPillar: const Pillar(chunGan: '戊', jiJi: '子'),
    elements: const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
    dayMaster: '辛',
    dayMasterName: 'Yin Metal Rabbit',
    summary: '',
    categoryReadings: const {},
  );
}

void main() {
  final date = DateTime(2026, 5, 20);

  group('근거 0 topic 은 surface 금지 (테스트 요구 1)', () {
    test('userPref 가 1.0 이라도 신호 없는 topic 은 candidate/selected 0', () {
      // 가족·집(family_home) 신호를 만들지 않는 입력.
      final ctx = buildCtx(
        activeShinsa: const {},
        todayRelations: const [],
        gyeokgukShort: '정관격', // → work_career
        dominantElement: '金', // → work_career
        todayGod: TenGod.jeonggwan, // → work_career
      );
      final event = buildEvent(
        dominant: EventCategory.work,
        sub: EventCategory.work, // sub == dominant → sub 근거 미생성
        activeShinsa: const [],
        hapChung: '없음',
      );
      final sel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
        // family_home / love_connection 등 모든 무신호 topic 에 최대 선호도.
        userPrefById: {
          for (final t in DailyTopic.values) t.id: 1.0,
        },
      );

      // family_home 은 어떤 근거도 없어야 한다.
      final familyInCand =
          sel.candidates.any((c) => c.topic == DailyTopic.familyHome);
      final familyInBelow =
          sel.belowThreshold.any((c) => c.topic == DailyTopic.familyHome);
      expect(familyInCand, isFalse);
      expect(familyInBelow, isFalse);
      // selected 도 신호 있는 topic 만.
      expect(sel.selected, isNot(DailyTopic.familyHome));
    });
  });

  group('evidence 2+ topic 은 candidate (테스트 요구 2)', () {
    test('일반 근거 2개 누적 topic 은 candidate', () {
      // work_career 에 todayGod(정관) + 격국(정관격) + dominant 카테고리 work
      // → 일반 근거 2+ 확보.
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        todayGod: TenGod.jeonggwan,
        activeShinsa: const {},
      );
      final event = buildEvent(
        dominant: EventCategory.work,
        sub: EventCategory.relationship,
      );
      final sel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      final work = sel.candidates
          .where((c) => c.topic == DailyTopic.workCareer)
          .toList();
      expect(work, isNotEmpty);
      expect(work.first.weightedEvidenceCount >= 2.0, isTrue);
    });

    test('보조 근거만으로는 candidate 자격 미달 — 0.5 환산', () {
      // 오직 오행 dominant(보조 0.5) + 격국(보조 0.5) 만 → 1.0 < 2.0.
      final ctx = buildCtx(
        gyeokgukShort: '인수격', // → rest_recovery (보조)
        dominantElement: '水', // → mental_emotion (보조)
        todayGod: null,
        activeShinsa: const {},
      );
      final event = buildEvent(
        dominant: EventCategory.work,
        sub: EventCategory.work,
      );
      final sel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      // mental_emotion 은 보조 근거 1개(0.5) 뿐 → candidate 아님.
      final mentalCand =
          sel.candidates.any((c) => c.topic == DailyTopic.mentalEmotion);
      expect(mentalCand, isFalse);
    });
  });

  group('strong single signal topic 은 candidate (테스트 요구 3)', () {
    test('도화 1개만 있어도 love_connection candidate', () {
      // 도화 strength 0.85 >= 0.80 → strong single.
      final ctx = buildCtx(activeShinsa: const {});
      final event = buildEvent(
        dominant: EventCategory.work, // love 와 무관
        sub: EventCategory.work,
        activeShinsa: const ['도화'],
      );
      final sel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      final love = sel.candidates
          .where((c) => c.topic == DailyTopic.loveConnection)
          .toList();
      expect(love, isNotEmpty);
      expect(love.first.byStrongSingle, isTrue);
      expect(love.first.evidence.length, 1); // 단일 근거
    });

    test('strong single threshold 는 0.80 — 보존', () {
      expect(TopicSelectorService.strongSingleThreshold, 0.80);
      expect(TopicSelectorService.candidateEvidenceThreshold, 2.0);
    });
  });

  group('finalScore 공식 (테스트 요구 6)', () {
    test('가중치 0.55/0.30/0.10/0.05', () {
      expect(TopicSelectorService.wSignal, 0.55);
      expect(TopicSelectorService.wUserPref, 0.30);
      expect(TopicSelectorService.wFreshness, 0.10);
      expect(TopicSelectorService.wExploration, 0.05);
      // 합 = 1.0.
      expect(
        TopicSelectorService.wSignal +
            TopicSelectorService.wUserPref +
            TopicSelectorService.wFreshness +
            TopicSelectorService.wExploration,
        1.0,
      );
    });

    test('breakdown 의 finalScore = 4 component 가중합', () {
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        todayGod: TenGod.jeonggwan,
      );
      final event = buildEvent(dominant: EventCategory.work);
      final sel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      for (final c in [...sel.candidates, ...sel.belowThreshold]) {
        final b = c.breakdown;
        final expected = b.signalStrength * TopicSelectorService.wSignal +
            b.userPref * TopicSelectorService.wUserPref +
            b.freshness * TopicSelectorService.wFreshness +
            b.exploration * TopicSelectorService.wExploration;
        expect((b.finalScore - expected).abs() < 1e-9, isTrue,
            reason: '${c.topic.id} finalScore != 가중합');
        // 모든 component 는 0~1 double.
        for (final v in [
          b.signalStrength,
          b.userPref,
          b.freshness,
          b.exploration,
        ]) {
          expect(v >= 0.0 && v <= 1.0, isTrue);
        }
      }
    });

    test('freshness — 최근 노출일수록 낮다', () {
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        todayGod: TenGod.jeonggwan,
      );
      final event = buildEvent(dominant: EventCategory.work);
      final fresh = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
        shownDaysAgoById: const {'work_career': 1},
      );
      final stale = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
        shownDaysAgoById: const {'work_career': 20},
      );
      double freshnessOf(TopicSelection s) => s.candidates
          .firstWhere((c) => c.topic == DailyTopic.workCareer)
          .breakdown
          .freshness;
      expect(freshnessOf(fresh) < freshnessOf(stale), isTrue);
    });
  });

  group('selector deterministic (테스트 요구 7)', () {
    test('같은 입력 → 같은 출력', () {
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        todayGod: TenGod.jeonggwan,
        activeShinsa: const {'도화'},
      );
      final event = buildEvent(
        dominant: EventCategory.work,
        activeShinsa: const ['도화', '문창귀인'],
        hapChung: '합',
      );
      final prefs = {
        for (final t in DailyTopic.values) t.id: 0.7,
      };
      TopicSelection run() => TopicSelectorService.select(
            saju: buildSaju(),
            ctx: ctx,
            event: event,
            date: date,
            userPrefById: prefs,
            shownDaysAgoById: const {'work_career': 3},
          );
      final a = run();
      final b = run();
      expect(a.selected, b.selected);
      expect(a.chartKey, b.chartKey);
      expect(a.candidates.length, b.candidates.length);
      for (var i = 0; i < a.candidates.length; i++) {
        expect(a.candidates[i].topic, b.candidates[i].topic);
        expect(
          a.candidates[i].breakdown.finalScore,
          b.candidates[i].breakdown.finalScore,
        );
      }
    });
  });

  group('full chart / todayFingerprint key (테스트 요구 8)', () {
    test('chartKey 가 일주/십신/합충형/격국/용신/신살/todayPillar/todayRelation 포함', () {
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        yongsin: '土',
        activeShinsa: const {'도화', '역마'},
        todayRelations: const ['지지충'],
        todayGod: TenGod.jeonggwan,
        todayPillar: '甲子',
      );
      final event = buildEvent(
        dominant: EventCategory.work,
        activeShinsa: const ['문창귀인'],
        hapChung: '충',
      );
      final key = TopicSelectorService.buildChartKey(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      // 일주 60갑자.
      expect(key.contains('ilju=辛卯'), isTrue);
      // 십신 구성.
      expect(key.contains('tengod='), isTrue);
      // 합충형 (정적 todayRelations).
      expect(key.contains('hapchung='), isTrue);
      expect(key.contains('지지충'), isTrue);
      // 격국.
      expect(key.contains('gyeok=정관격'), isTrue);
      // 용신.
      expect(key.contains('yongsin=土'), isTrue);
      // 신살.
      expect(key.contains('shinsa='), isTrue);
      expect(key.contains('도화'), isTrue);
      // todayFingerprint — todayPillar / todayRelation.
      expect(key.contains('tp=甲子'), isTrue);
      expect(key.contains('trel=충'), isTrue);
      expect(key.contains('tg='), isTrue); // 오늘 십신
    });

    test('오행 비율은 보조 — aux 접두로만 들어간다 (§5 keying 금지)', () {
      final ctx = buildCtx();
      final key = TopicSelectorService.buildChartKey(
        saju: buildSaju(),
        ctx: ctx,
        event: buildEvent(),
        date: date,
      );
      expect(key.contains('aux5='), isTrue);
    });

    test('원국 내부 합충이 다르면 chartKey 가 다르다 (Fix 1 — natal 합충 keying)', () {
      // 두 사주는 일주/십신/격국/용신/신살/오행/날짜 모두 동일하게 맞추고,
      // 오직 원국 4기둥 내부 합충만 달라지게 한다.
      //
      // sajuA: 년 甲子 / 월 戊辰 / 일 辛卯 / 시 庚寅
      //   - 천간 甲己/乙庚/丙辛/丁壬/戊癸 합 없음 (甲·戊·辛·庚 — 乙庚만? 乙 없음)
      //   - 지지 子辰卯寅 — 6합(子丑·辰酉·卯戌·寅亥) 없음, 6충 없음 → 원국 합충 0.
      final sajuA = SajuResult(
        yearPillar: const Pillar(chunGan: '甲', jiJi: '子'),
        monthPillar: const Pillar(chunGan: '戊', jiJi: '辰'),
        dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
        hourPillar: const Pillar(chunGan: '庚', jiJi: '寅'),
        elements:
            const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
        dayMaster: '辛',
        dayMasterName: 'Yin Metal Rabbit',
        summary: '',
        categoryReadings: const {},
      );
      // sajuB: 동일 일주(辛卯)·동일 십신용 윤곽이지만 원국 합충이 발생.
      //   년 丙午 / 월 辛丑 / 일 辛卯 / 시 庚子
      //   - 천간 丙辛 합(년-월) 발생.
      //   - 지지 午丑卯子 — 子丑 6합(시-월) 발생.
      final sajuB = SajuResult(
        yearPillar: const Pillar(chunGan: '丙', jiJi: '午'),
        monthPillar: const Pillar(chunGan: '辛', jiJi: '丑'),
        dayPillar: const Pillar(chunGan: '辛', jiJi: '卯'),
        hourPillar: const Pillar(chunGan: '庚', jiJi: '子'),
        elements:
            const FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
        dayMaster: '辛',
        dayMasterName: 'Yin Metal Rabbit',
        summary: '',
        categoryReadings: const {},
      );
      // ctx / event / date 는 완전히 동일하게 — 차이는 오직 원국 합충뿐.
      final ctx = buildCtx();
      final event = buildEvent();
      final keyA = TopicSelectorService.buildChartKey(
        saju: sajuA,
        ctx: ctx,
        event: event,
        date: date,
      );
      final keyB = TopicSelectorService.buildChartKey(
        saju: sajuB,
        ctx: ctx,
        event: event,
        date: date,
      );
      // 원국 합충이 다르므로 chartKey 가 달라야 한다.
      expect(keyA == keyB, isFalse,
          reason: '원국 합충이 다른데 chartKey 가 같으면 Barnum 복붙 위험');
      // sajuA 는 원국 합충 0 → hapchung= 비어있어야.
      expect(keyA.contains('hapchung=|'), isTrue,
          reason: 'sajuA 원국 합충 0 → hapchung= 빈 값');
      // sajuB 는 丙辛합 + 子丑합 → hapchung= 에 H: 항목 존재.
      expect(keyB.contains('hapchung=H:'), isTrue,
          reason: 'sajuB 원국 합 발생 → hapchung= 에 H: 직렬화');
    });

    test('todayRelations(오늘 일진×일주)는 hapchung= 가 아닌 fp= 쪽에만 (Fix 1)', () {
      final ctx = buildCtx(todayRelations: const ['지지충']);
      final key = TopicSelectorService.buildChartKey(
        saju: buildSaju(),
        ctx: ctx,
        event: buildEvent(),
        date: date,
      );
      // 오늘 일진×일주 관계는 todayFingerprint(tnatalrel=) 안에 있어야 한다.
      expect(key.contains('tnatalrel=지지충'), isTrue);
      // hapchung= 세그먼트(원국 합충) 자체에는 '지지충' 문자열이 들어가면 안 된다.
      final hapchungSeg = key
          .split('|')
          .firstWhere((s) => s.startsWith('hapchung='));
      expect(hapchungSeg.contains('지지충'), isFalse,
          reason: '오늘 일진×일주 관계는 원국 합충이 아니다');
    });

    test('일주가 다르면 chartKey 가 다르다', () {
      final key1 = TopicSelectorService.buildChartKey(
        saju: buildSaju(),
        ctx: buildCtx(),
        event: buildEvent(),
        date: date,
      );
      final saju2 = SajuResult(
        yearPillar: const Pillar(chunGan: '乙', jiJi: '亥'),
        monthPillar: const Pillar(chunGan: '丙', jiJi: '戌'),
        dayPillar: const Pillar(chunGan: '甲', jiJi: '子'),
        elements:
            const FiveElements(wood: 30, fire: 20, earth: 20, metal: 15, water: 15),
        dayMaster: '甲',
        dayMasterName: 'Yang Wood Rat',
        summary: '',
        categoryReadings: const {},
      );
      final key2 = TopicSelectorService.buildChartKey(
        saju: saju2,
        ctx: buildCtx(dayMaster: '甲', dayElement: '木'),
        event: buildEvent(),
        date: date,
      );
      expect(key1 == key2, isFalse);
    });
  });

  group('no-selection 허용 — 억지 선택 금지', () {
    test('selected candidate 가 suppress 되면 다음 후보로', () {
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        todayGod: TenGod.jeonggwan,
        activeShinsa: const {},
      );
      // work_career + relationship_conflict 양쪽 candidate 만들기.
      final event = buildEvent(
        dominant: EventCategory.work,
        sub: EventCategory.relationship,
        activeShinsa: const ['양인', '망신'], // → relationship_conflict 강화
        hapChung: '형', // → relationship_conflict
      );
      final normal = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      expect(normal.selected, isNotNull);
      // selected topic 을 suppress 하면 다른 candidate 가 선택돼야.
      final suppressedSel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
        suppressedIds: {normal.selected!.id},
      );
      if (suppressedSel.selected != null) {
        expect(suppressedSel.selected, isNot(normal.selected));
      }
      // 어떤 경우든 selected 는 신호 있는 candidate 거나 null.
      if (suppressedSel.selected != null) {
        expect(
          suppressedSel.candidates
              .any((c) => c.topic == suppressedSel.selected),
          isTrue,
        );
      }
    });

    test('suppressed topic 은 eligibleCandidates 에 안 들어간다 (Fix 3 — cooldown 누수 방지)', () {
      final ctx = buildCtx(
        gyeokgukShort: '정관격',
        todayGod: TenGod.jeonggwan,
        activeShinsa: const {},
      );
      // work_career + relationship_conflict 양쪽 candidate.
      final event = buildEvent(
        dominant: EventCategory.work,
        sub: EventCategory.relationship,
        activeShinsa: const ['양인', '망신'],
        hapChung: '형',
      );
      final normal = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
      );
      // suppress 없을 때 — eligibleCandidates == candidates, suppressed 비어있음.
      expect(normal.suppressedCandidates, isEmpty);
      expect(normal.eligibleCandidates.length, normal.candidates.length);
      expect(normal.selected, isNotNull);

      // selected topic 을 cooldown suppress.
      final suppressedId = normal.selected!.id;
      final sel = TopicSelectorService.select(
        saju: buildSaju(),
        ctx: ctx,
        event: event,
        date: date,
        suppressedIds: {suppressedId},
      );
      // suppressed topic 은 전체 candidates 에는 남아있되,
      // 노출용 eligibleCandidates / selected 에는 새어나가면 안 된다.
      expect(
        sel.candidates.any((c) => c.topic.id == suppressedId),
        isTrue,
        reason: 'candidates 전체에는 디버그용으로 남는다',
      );
      expect(
        sel.eligibleCandidates.any((c) => c.topic.id == suppressedId),
        isFalse,
        reason: 'cooldown 된 주제가 노출용 리스트로 새면 안 된다',
      );
      expect(
        sel.suppressedCandidates.any((c) => c.topic.id == suppressedId),
        isTrue,
        reason: 'suppressed candidate 는 별도 리스트에 분리',
      );
      // selected 도 suppressed topic 이면 안 된다.
      expect(sel.selected?.id, isNot(suppressedId));
      // eligibleCandidates + suppressedCandidates = candidates (누락·중복 0).
      expect(
        sel.eligibleCandidates.length + sel.suppressedCandidates.length,
        sel.candidates.length,
      );
    });
  });

  group('topic id 안정 매핑 (테스트 요구 10 — 10 주제 string)', () {
    test('10 주제 id 가 design doc §4-A 와 1:1', () {
      const expected = {
        DailyTopic.communication: 'communication',
        DailyTopic.moneySpending: 'money_spending',
        DailyTopic.workCareer: 'work_career',
        DailyTopic.loveConnection: 'love_connection',
        DailyTopic.familyHome: 'family_home',
        DailyTopic.healthCondition: 'health_condition',
        DailyTopic.mentalEmotion: 'mental_emotion',
        DailyTopic.relationshipConflict: 'relationship_conflict',
        DailyTopic.challengeOpportunity: 'challenge_opportunity',
        DailyTopic.restRecovery: 'rest_recovery',
      };
      expect(DailyTopic.values.length, 10);
      expected.forEach((topic, id) {
        expect(topic.id, id);
        expect(dailyTopicFromId(id), topic);
      });
      expect(dailyTopicFromId('nonsense'), isNull);
    });
  });
}
