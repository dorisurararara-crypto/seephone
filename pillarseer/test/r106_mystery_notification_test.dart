// Pillar Seer — Round 106 (P2b + P2b-fix) — 사주 미스터리형 알림 검증.
//
// design doc §6 ground truth:
//  - title = 오늘 일진 글자를 신비하게 던지는 호기심 훅.
//  - body 2줄 = (글자 × 사용자 차트 실제 관계) + (바로 할 행동 1개).
//  - topic-aware — P1 TopicSelector 가 고른 주제 반영.
//  - 7회 중 1회 기능 발견 훅.
//  - 단정 금지(§2) — 사용자 감정·사건 단정 0. "오늘 기분 좋았는데?" 에도 틀린 문장 0.
//
// P2b-fix (거짓말 0 — 최우선):
//  - body line1 의 차트 관계 표현은 그날 실제 계산된 일진 지지↔사용자 일지
//    관계(MysteryRelation)로만 선택된다. 실제 충일 때만 "부딪/맞서", 실제 합일
//    때만 "맞물/끌어당", 실제 형/파/해일 때만 "엇갈", 셋 다 없으면 관계-중립만.
//
// 검증:
//  ① title 이 오늘 일진 글자/관계 호기심 훅 (관계-중립).
//  ② body 2줄 (글자×차트 관계 + 행동).
//  ③ 단정 금지 가드 — 생성 알림에 감정·반응·상태 예측 0.
//  ④ topic-aware — selector 주제 반영.
//  ⑤ 기능 발견 훅 rotate (7회 중 1회 근방).
//  ⑥ 결정성 + 기존 토글·시간설정·pickDeep·pickFor 회귀.
//  ⑦ raw 풀(JSON) 전수 스캔 — titles/interactions/actions/feature_hooks 금지어 0.
//  ⑧ P2b-fix 거짓말 0 — relation 별 카피가 실제 관계에만 매칭.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/daily_service.dart';
import 'package:pillarseer/services/notification_pool_service.dart';
import 'package:pillarseer/services/notification_service.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/today_event_service.dart';
import 'package:pillarseer/services/topic_selector_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 미스터리 풀 asset 을 실제로 로드 (rootBundle mock).
  setUpAll(() async {
    NotificationPoolService.debugResetMysteryPool();
    await NotificationPoolService.ensureMysteryPoolLoaded();
  });

  final date = DateTime(2026, 5, 21);
  // 오늘 일진 60갑자 표본 — 12 지지 전부 cover.
  const todayPillars = [
    '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳',
    '庚午', '辛未', '壬申', '癸酉', '甲戌', '乙亥',
  ];
  const topicIds = [
    'communication',
    'money_spending',
    'work_career',
    'love_connection',
    'family_home',
    'health_condition',
    'mental_emotion',
    'relationship_conflict',
    'challenge_opportunity',
    'rest_recovery',
  ];
  const relations = MysteryRelation.values;

  // design doc §2 — 감정·사건 단정 + 상태·반응 예측 + 헤드라인체. 생성 알림 0.
  // P2b-fix: codex 가 짚은 "설레게/쏠리기 쉬운/흔들리기 쉬운/페이스가 흔들/말로
  // 먼저 반응/검토에 강해지는" 등 상태·반응 *예측* 어구를 정규식군으로 확장.
  final forbiddenAssertion = RegExp(
    // 감정·사건 단정.
    '오늘 (당신은 )?(예민|우울|들뜨|불안|화가|기분이 (좋|나쁘|안 좋))'
    '|예민해지기 쉬운|들뜨기 쉬운'
    '|오늘 .*(일어난다|생긴다|만난다|벌어진다)'
    '|반드시|큰일|위험|사고|운명|대박|100%|무조건'
    // 상태·반응 예측 (P2b-fix 확장).
    '|설레게'
    '|쏠리기 쉬'
    '|흔들리기 쉬'
    '|페이스가.{0,6}흔들'
    '|말로 먼저 반응'
    '|검토에 강해지(는|기)'
    '|(페이스|속도)가.{0,12}(잡히|어긋나)'
    '|마음이.{0,12}어긋나'
    '|사람과.{0,12}(부딪|끌어당|어긋나)'
    // 헤드라인체.
    '|하는 날이에요'
    '|오늘의 .{0,4}운'
    // 감정 단정어.
    '|마음이 쏠리기'
    '|설렘'
    '|두근',
  );

  group('① title — 오늘 일진 글자 호기심 훅', () {
    test('모든 일진 글자 × 모든 주제 × 모든 관계 — title 이 호기심 훅 형태', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (final rel in relations) {
            final copy = NotificationPoolService.pickMystery(
              date: date,
              todayPillar: tp,
              day60ji: '辛卯',
              topicId: tid,
              relation: rel,
            );
            expect(copy.title.isNotEmpty, isTrue);
            // 헤드라인체("오늘의 ○○운") 금지.
            expect(copy.title.contains('운세') && copy.title.contains('오늘의'),
                isFalse,
                reason: '헤드라인체 금지: ${copy.title}');
            // 글자/자리/사주/일주 호기심 어휘 중 하나 포함.
            final hook = RegExp('글자|자리|손님|사주|일주|일지');
            expect(hook.hasMatch(copy.title), isTrue,
                reason: 'no curiosity hook: ${copy.title}');
          }
        }
      }
    });
  });

  group('② body — 2줄 (글자×차트 관계 + 행동)', () {
    test('bodyLine1 = 글자×차트 관계, bodyLine2 = 행동', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (final rel in relations) {
            for (var off = 0; off < 7; off++) {
              final copy = NotificationPoolService.pickMystery(
                date: date,
                todayPillar: tp,
                day60ji: '戊寅',
                topicId: tid,
                relation: rel,
                dayOffset: off,
              );
              expect(copy.bodyLine1.isNotEmpty, isTrue);
              expect(copy.bodyLine2.isNotEmpty, isTrue);
              // body = 2줄 줄바꿈 결합.
              expect(copy.body, '${copy.bodyLine1}\n${copy.bodyLine2}');
              if (copy.isFeatureHook) continue; // 기능 훅은 ⑤ 에서 검증.
              // line1 — 글자 × 차트(일주/일지/사주) 관계 언급.
              final relWord = RegExp('일주|일지|사주|차트|자리');
              expect(relWord.hasMatch(copy.bodyLine1), isTrue,
                  reason: 'line1 no chart relation: ${copy.bodyLine1}');
              // line2 — 행동/안내 어휘 (앱 열면 자세히).
              final act = RegExp('안에|확인|넘기는|적어');
              expect(act.hasMatch(copy.bodyLine2), isTrue,
                  reason: 'line2 no action: ${copy.bodyLine2}');
            }
          }
        }
      }
    });

    test('오늘 일진 지지 한자가 본문에 노출되고 즉시 한글로 풀이됨', () {
      for (final rel in relations) {
        final copy = NotificationPoolService.pickMystery(
          date: date,
          todayPillar: '丙子', // 지지 子 = 자.
          day60ji: '辛卯',
          topicId: 'mental_emotion',
          relation: rel,
        );
        expect(copy.bodyLine1.contains('子'), isTrue,
            reason: '글자 미노출: ${copy.bodyLine1}');
        expect(copy.bodyLine1.contains('자'), isTrue,
            reason: '한자 풀이 누락: ${copy.bodyLine1}');
      }
    });

    test('body 길이 — 알림 한도(≤300자 각 줄)', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (final rel in relations) {
            final copy = NotificationPoolService.pickMystery(
              date: date,
              todayPillar: tp,
              day60ji: '甲子',
              topicId: tid,
              relation: rel,
            );
            expect(copy.bodyLine1.length, lessThanOrEqualTo(300));
            expect(copy.bodyLine2.length, lessThanOrEqualTo(300));
            expect(copy.title.length, lessThanOrEqualTo(120));
          }
        }
      }
    });
  });

  group('③ 단정 금지 가드 — 감정·반응·상태 예측 0', () {
    test('모든 일진 × 주제 × 관계 × 30 dayOffset — 단정 표현 0', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (final rel in relations) {
            for (var off = 0; off < 30; off++) {
              final copy = NotificationPoolService.pickMystery(
                date: date,
                todayPillar: tp,
                day60ji: '辛卯',
                topicId: tid,
                relation: rel,
                dayOffset: off,
              );
              final all =
                  '${copy.title} ${copy.bodyLine1} ${copy.bodyLine2}';
              expect(forbiddenAssertion.hasMatch(all), isFalse,
                  reason: '단정 표현 발견: $all');
            }
          }
        }
      }
    });

    test('총평형(topicId null) 도 모든 관계에서 단정 표현 0', () {
      for (final tp in todayPillars) {
        for (final rel in relations) {
          final copy = NotificationPoolService.pickMystery(
            date: date,
            todayPillar: tp,
            day60ji: '辛卯',
            topicId: null,
            relation: rel,
          );
          final all = '${copy.title} ${copy.bodyLine1} ${copy.bodyLine2}';
          expect(forbiddenAssertion.hasMatch(all), isFalse,
              reason: '총평형 단정 표현: $all');
        }
      }
    });

    test('"오늘 기분 완전 좋았는데?" 반증 불가 — 행동이 기분 무관 유효', () {
      final feelingPrereq = RegExp('기분이 (나쁘|안 좋|우울)|힘들 때만|짜증날 때');
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (final rel in relations) {
            final copy = NotificationPoolService.pickMystery(
              date: date,
              todayPillar: tp,
              day60ji: '戊寅',
              topicId: tid,
              relation: rel,
            );
            expect(feelingPrereq.hasMatch(copy.bodyLine2), isFalse,
                reason: '행동이 감정 전제: ${copy.bodyLine2}');
          }
        }
      }
    });
  });

  group('④ topic-aware — selector 주제 반영', () {
    test('주제마다 다른 카피 — money vs love vs work 구분됨', () {
      final money = NotificationPoolService.pickMystery(
        date: date, todayPillar: '丙寅', day60ji: '辛卯',
        topicId: 'money_spending', relation: MysteryRelation.neutral,
      );
      final love = NotificationPoolService.pickMystery(
        date: date, todayPillar: '丙寅', day60ji: '辛卯',
        topicId: 'love_connection', relation: MysteryRelation.neutral,
      );
      final work = NotificationPoolService.pickMystery(
        date: date, todayPillar: '丙寅', day60ji: '辛卯',
        topicId: 'work_career', relation: MysteryRelation.neutral,
      );
      expect(money.topicId, 'money_spending');
      expect(love.topicId, 'love_connection');
      expect(work.topicId, 'work_career');
      final bodies = {money.body, love.body, work.body};
      expect(bodies.length, greaterThan(1),
          reason: 'topic-aware 아님 — 주제별 카피 동일');
    });

    test('재물/관계 주제 — 카피가 그 영역 어휘 포함', () {
      final money = NotificationPoolService.pickMystery(
        date: date, todayPillar: '庚午', day60ji: '辛卯',
        topicId: 'money_spending', relation: MysteryRelation.neutral,
      );
      expect(RegExp('재물|돈').hasMatch(money.title + money.bodyLine1), isTrue);
      final rel = NotificationPoolService.pickMystery(
        date: date, todayPillar: '庚午', day60ji: '辛卯',
        topicId: 'relationship_conflict', relation: MysteryRelation.neutral,
      );
      expect(RegExp('사람|일지').hasMatch(rel.title + rel.bodyLine1), isTrue);
    });

    test('selected topic id 전부 — 유효 카피 생성 (10 주제 모두 매핑)', () {
      for (final t in DailyTopic.values) {
        for (final rel in relations) {
          final copy = NotificationPoolService.pickMystery(
            date: date, todayPillar: '壬申', day60ji: '辛卯',
            topicId: t.id, relation: rel,
          );
          expect(copy.title.isNotEmpty, isTrue, reason: '미매핑 주제: ${t.id}');
          expect(copy.bodyLine1.isNotEmpty, isTrue);
          expect(copy.bodyLine2.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('⑤ 기능 발견 훅 rotate', () {
    test('30일 스케줄 — 기능 훅이 7회 중 1회 근방으로 등장', () {
      var hookCount = 0;
      for (var off = 0; off < 70; off++) {
        final copy = NotificationPoolService.pickMystery(
          date: date.add(Duration(days: off)),
          todayPillar: todayPillars[off % todayPillars.length],
          day60ji: '辛卯',
          topicId: 'mental_emotion',
          relation: MysteryRelation.neutral,
          dayOffset: off,
        );
        if (copy.isFeatureHook) hookCount++;
      }
      expect(hookCount, greaterThan(0), reason: '기능 훅 한 번도 안 나옴');
      expect(hookCount, lessThan(35), reason: '기능 훅 과다');
    });

    test('기능 훅 — 글자 호기심 유지 + 기능 안내 어휘', () {
      for (var off = 0; off < 70; off++) {
        final copy = NotificationPoolService.pickMystery(
          date: date,
          todayPillar: '丙子',
          day60ji: '辛卯',
          topicId: 'work_career',
          relation: MysteryRelation.chung,
          dayOffset: off,
        );
        if (copy.isFeatureHook) {
          expect(copy.bodyLine1.contains('子'), isTrue);
          final feature = RegExp('그래프|흐름|체크|칩|오늘의 사주');
          expect(feature.hasMatch(copy.body), isTrue,
              reason: '기능 훅 안내 누락: ${copy.body}');
          return;
        }
      }
      fail('70 dayOffset 안에 기능 훅이 안 나옴');
    });
  });

  group('⑥ 결정성 + 회귀', () {
    test('pickMystery 결정성 — 같은 입력 100회 동일', () {
      MysteryNotificationCopy? prev;
      for (var i = 0; i < 100; i++) {
        final copy = NotificationPoolService.pickMystery(
          date: date, todayPillar: '丙寅', day60ji: '辛卯',
          topicId: 'love_connection', relation: MysteryRelation.hap,
          dayOffset: 3,
        );
        prev ??= copy;
        expect(copy.title, prev.title);
        expect(copy.body, prev.body);
        expect(copy.isFeatureHook, prev.isFeatureHook);
      }
    });

    test('relation 미공급(null) — 안전하게 neutral 카피 (관계 단정 0)', () {
      final noRel = NotificationPoolService.pickMystery(
        date: date, todayPillar: '丙寅', day60ji: '辛卯',
        topicId: 'communication',
      );
      final neutral = NotificationPoolService.pickMystery(
        date: date, todayPillar: '丙寅', day60ji: '辛卯',
        topicId: 'communication', relation: MysteryRelation.neutral,
      );
      // relation null == neutral 동일 출력.
      expect(noRel.body, neutral.body);
      // 관계 단정(맞서/부딪/맞물/끌어당/엇갈) 없음.
      expect(RegExp('맞서|부딪|맞물|끌어당|엇갈').hasMatch(noRel.bodyLine1),
          isFalse,
          reason: 'relation 미공급인데 관계 단정: ${noRel.bodyLine1}');
    });

    test('회귀 — pickDeep 기존 동작 보존', () {
      final saju = SajuResult.dummy();
      final p = NotificationPoolService.pickDeep(
        date: date, saju: saju, todayPillar: '丙戌', todayScore: 60,
      );
      expect(p.ko.isNotEmpty, isTrue);
      expect(p.en.isNotEmpty, isTrue);
    });

    test('회귀 — pickFor (fallback) 기존 동작 보존', () {
      final p = NotificationPoolService.pickFor(date, '丙戌');
      expect(p.ko.isNotEmpty, isTrue);
      expect(p.en.isNotEmpty, isTrue);
      final mz = NotificationPoolService.pickFor(
        date, '丙戌', tone: NotificationTone.mz,
      );
      expect(mz.ko.isNotEmpty, isTrue);
    });
  });

  group('⑥ 회귀 — 알림 토글·시간설정·스케줄링 보존', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('알림 시간 디폴트 8:00 + setTime 라운드트립', () async {
      final t0 = await NotificationService.loadTime();
      expect(t0.hour, 8);
      expect(t0.minute, 0);
      await NotificationService.setTime(21, 15);
      final t1 = await NotificationService.loadTime();
      expect(t1.hour, 21);
      expect(t1.minute, 15);
    });

    test('알림 토글 ON/OFF 영속', () async {
      expect(await NotificationService.isEnabled(), isFalse);
      await NotificationService.setEnabled(true);
      expect(await NotificationService.isEnabled(), isTrue);
      await NotificationService.setEnabled(false);
      expect(await NotificationService.isEnabled(), isFalse);
    });

    test('needsReschedule — 시간 변경 감지 보존 (nosaju)', () async {
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig': 'ko|t|b||08:00|nosaju',
      });
      final same = await NotificationService.needsReschedule(
        title: 't', body: 'b', useKo: true, hour: 8, minute: 0,
      );
      expect(same, isFalse);
      final diff = await NotificationService.needsReschedule(
        title: 't', body: 'b', useKo: true, hour: 9, minute: 30,
      );
      expect(diff, isTrue);
    });

    test('Fix3 — 미스터리 알고리즘 버전 변경 시 재스케줄 필요', () async {
      final saju = SajuResult.dummy();
      // 구버전 signature (mystery 마커 없음) 가 저장돼 있던 사용자.
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig':
            'ko|t|b||08:00|deep:${saju.dayPillar.text}:'
                '${saju.monthPillar.jiJi}:${saju.dayMaster}',
      });
      // 미스터리형(saju!=null && useKo) — 새 signature 에 mystery 마커가 박혀
      // 구버전 signature 와 mismatch → reschedule 필요.
      final needs = await NotificationService.needsReschedule(
        title: 't', body: 'b', useKo: true, hour: 8, minute: 0, saju: saju,
      );
      expect(needs, isTrue,
          reason: '미스터리 알고리즘 버전 변경인데 재스케줄 안 함');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ⑦ raw 풀(JSON) 전수 스캔 — design doc §2/§3 금지어가 풀 자체에 0.
  //    pickMystery 가 골라낸 결과뿐 아니라 풀에 *적힌* 모든 문자열을 본다.
  // ─────────────────────────────────────────────────────────────────
  group('⑦ raw 미스터리 풀 전수 스캔', () {
    late Map<String, dynamic> pool;
    final allStrings = <String>[];

    setUpAll(() {
      final raw = File('assets/data/r106_mystery_notification_pool.json')
          .readAsStringSync();
      pool = jsonDecode(raw) as Map<String, dynamic>;

      void collect(dynamic node) {
        if (node is String) {
          allStrings.add(node);
        } else if (node is List) {
          for (final e in node) {
            collect(e);
          }
        } else if (node is Map) {
          node.forEach((k, v) {
            // _comment / _schema 등 메타 키는 카피 검사 대상 아님.
            if (k is String && k.startsWith('_')) return;
            if (k == 'label') return;
            collect(v);
          });
        }
      }

      collect(pool);
    });

    test('풀 JSON 파싱 OK + titles/interactions/actions 전부 비어있지 않음', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      expect(topics.length, 10);
      for (final entry in topics.entries) {
        final node = entry.value as Map<String, dynamic>;
        final titles = (node['titles'] as List).cast<String>();
        final actions = (node['actions'] as List).cast<String>();
        expect(titles, isNotEmpty, reason: '${entry.key} titles 비었음');
        expect(actions, isNotEmpty, reason: '${entry.key} actions 비었음');
        final interactions = node['interactions'] as Map<String, dynamic>;
        // P2b-fix — interactions 는 관계타입별 맵 (4 key 모두 존재·비어있지 않음).
        for (final relKey in ['chung', 'hap', 'friction', 'neutral']) {
          final list = (interactions[relKey] as List?)?.cast<String>();
          expect(list, isNotNull,
              reason: '${entry.key}.interactions.$relKey 누락');
          expect(list, isNotEmpty,
              reason: '${entry.key}.interactions.$relKey 비었음');
        }
      }
      // no_topic 도 관계타입별 맵.
      final noTopic = pool['no_topic'] as Map<String, dynamic>;
      final ntInteractions = noTopic['interactions'] as Map<String, dynamic>;
      for (final relKey in ['chung', 'hap', 'friction', 'neutral']) {
        expect((ntInteractions[relKey] as List?)?.isNotEmpty, isTrue,
            reason: 'no_topic.interactions.$relKey 비었음');
      }
    });

    test('raw 풀 — 단정·반응 예측·헤드라인체 금지 정규식군 0', () {
      expect(allStrings, isNotEmpty);
      for (final s in allStrings) {
        expect(forbiddenAssertion.hasMatch(s), isFalse,
            reason: '풀에 금지 표현: "$s"');
      }
    });

    test('raw 풀 — 의료/금융/법률 단정어 0 (design doc §3-7)', () {
      final medico = RegExp('병원|진단|투자|주식|코인|소송|확실히 (벌|딴)');
      for (final s in allStrings) {
        expect(medico.hasMatch(s), isFalse, reason: '풀에 의료/금융 단정: "$s"');
      }
    });

    test('raw 풀 — chung interactions 만 충 어휘, hap 만 합 어휘 (관계 누출 0)', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      final nodes = <Map<String, dynamic>>[
        ...topics.values.cast<Map<String, dynamic>>(),
        pool['no_topic'] as Map<String, dynamic>,
      ];
      // 충 전용 어휘는 hap/friction/neutral 배열에 없어야.
      final chungWord = RegExp('맞서|부딪');
      // 합 전용 어휘는 chung/friction/neutral 배열에 없어야.
      final hapWord = RegExp('맞물|끌어당');
      for (final node in nodes) {
        final inter = node['interactions'] as Map<String, dynamic>;
        for (final s in (inter['hap'] as List).cast<String>()) {
          expect(chungWord.hasMatch(s), isFalse,
              reason: 'hap 카피에 충 어휘 누출: "$s"');
        }
        for (final s in (inter['friction'] as List).cast<String>()) {
          expect(chungWord.hasMatch(s), isFalse,
              reason: 'friction 카피에 충 어휘 누출: "$s"');
          expect(hapWord.hasMatch(s), isFalse,
              reason: 'friction 카피에 합 어휘 누출: "$s"');
        }
        for (final s in (inter['neutral'] as List).cast<String>()) {
          expect(chungWord.hasMatch(s), isFalse,
              reason: 'neutral 카피에 충 어휘 누출: "$s"');
          expect(hapWord.hasMatch(s), isFalse,
              reason: 'neutral 카피에 합 어휘 누출: "$s"');
        }
        for (final s in (inter['chung'] as List).cast<String>()) {
          expect(hapWord.hasMatch(s), isFalse,
              reason: 'chung 카피에 합 어휘 누출: "$s"');
        }
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ⑧ P2b-fix 거짓말 0 — relation 별 카피가 실제 관계에만 매칭.
  // ─────────────────────────────────────────────────────────────────
  group('⑧ P2b-fix 거짓말 0 — relation-honest body', () {
    test('충/합 없는(neutral) 케이스 — body 에 부딪/맞물/끌어당/맞서 0', () {
      final forbiddenRelWord = RegExp('부딪|맞물|끌어당|맞서|엇갈');
      for (final tp in todayPillars) {
        for (final tid in [...topicIds, null]) {
          for (var off = 0; off < 7; off++) {
            final copy = NotificationPoolService.pickMystery(
              date: date,
              todayPillar: tp,
              day60ji: '辛卯',
              topicId: tid,
              relation: MysteryRelation.neutral,
              dayOffset: off,
            );
            if (copy.isFeatureHook) continue;
            expect(forbiddenRelWord.hasMatch(copy.bodyLine1), isFalse,
                reason: '관계 없는 날 관계 단정: ${copy.bodyLine1}');
          }
        }
      }
    });

    test('충 케이스 — body line1 이 충 어휘, 합/엇갈 어휘 0', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (var off = 0; off < 7; off++) {
            final copy = NotificationPoolService.pickMystery(
              date: date, todayPillar: tp, day60ji: '辛卯',
              topicId: tid, relation: MysteryRelation.chung, dayOffset: off,
            );
            if (copy.isFeatureHook) continue;
            expect(RegExp('맞서|부딪').hasMatch(copy.bodyLine1), isTrue,
                reason: '충인데 충 어휘 없음: ${copy.bodyLine1}');
            expect(RegExp('맞물|끌어당').hasMatch(copy.bodyLine1), isFalse,
                reason: '충인데 합 어휘: ${copy.bodyLine1}');
          }
        }
      }
    });

    test('합 케이스 — body line1 이 합 어휘, 충 어휘 0', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (var off = 0; off < 7; off++) {
            final copy = NotificationPoolService.pickMystery(
              date: date, todayPillar: tp, day60ji: '辛卯',
              topicId: tid, relation: MysteryRelation.hap, dayOffset: off,
            );
            if (copy.isFeatureHook) continue;
            expect(RegExp('맞물|끌어당').hasMatch(copy.bodyLine1), isTrue,
                reason: '합인데 합 어휘 없음: ${copy.bodyLine1}');
            expect(RegExp('맞서|부딪').hasMatch(copy.bodyLine1), isFalse,
                reason: '합인데 충 어휘: ${copy.bodyLine1}');
          }
        }
      }
    });

    test('형/파/해(friction) 케이스 — 엇갈/걸리는 어휘, 충·합 어휘 0', () {
      for (final tp in todayPillars) {
        for (final tid in topicIds) {
          for (var off = 0; off < 7; off++) {
            final copy = NotificationPoolService.pickMystery(
              date: date, todayPillar: tp, day60ji: '辛卯',
              topicId: tid, relation: MysteryRelation.friction, dayOffset: off,
            );
            if (copy.isFeatureHook) continue;
            expect(RegExp('엇갈|걸리는').hasMatch(copy.bodyLine1), isTrue,
                reason: '형/파/해인데 엇갈 어휘 없음: ${copy.bodyLine1}');
            expect(RegExp('맞서|부딪|맞물|끌어당').hasMatch(copy.bodyLine1),
                isFalse,
                reason: '형/파/해인데 충·합 어휘: ${copy.bodyLine1}');
          }
        }
      }
    });

    test('MysteryRelation.fromHapChungType — 합충 라벨 → 관계 매핑 정확', () {
      expect(MysteryRelationKey.fromHapChungType('충'),
          MysteryRelation.chung);
      expect(MysteryRelationKey.fromHapChungType('합'), MysteryRelation.hap);
      expect(MysteryRelationKey.fromHapChungType('형'),
          MysteryRelation.friction);
      expect(MysteryRelationKey.fromHapChungType('파'),
          MysteryRelation.friction);
      expect(MysteryRelationKey.fromHapChungType('해'),
          MysteryRelation.friction);
      // '없음' 및 미상 → neutral (관계 단정 금지).
      expect(MysteryRelationKey.fromHapChungType('없음'),
          MysteryRelation.neutral);
      expect(MysteryRelationKey.fromHapChungType(null),
          MysteryRelation.neutral);
      expect(MysteryRelationKey.fromHapChungType('xyz'),
          MysteryRelation.neutral);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ⑧b scheduleDaily 미스터리 경로 — 실제 사주로 30일 스케줄이 죽지 않고,
  //     생성된 알림이 거짓말 0 / 단정 0 인지 (통합 경로 검증).
  // ─────────────────────────────────────────────────────────────────
  group('⑧b scheduleDaily 미스터리 경로 — 실제 사주 파이프라인', () {
    // flutter_local_notifications 플러그인은 unit test 환경에서 플랫폼 인터페이스
    // _instance 미등록으로 NotificationService.scheduleDaily 를 직접 못 돌린다
    // (이 레포 전체 test 중 scheduleDaily 직접 호출이 0인 이유). 그래서 여기서는
    // notification_service.dart 의 미스터리 경로가 *내부적으로 수행하는 정확한
    // 파이프라인* (DailyService → SajuContext → TodayEventService →
    // TopicSelectorService → MysteryRelationKey.fromHapChungType → pickMystery)
    // 을 그대로 재현해, 실제 사주로 30일분 알림이 거짓말·단정 0 인지 검증한다.
    test('실제 사주 30일 — 미스터리 경로 알림이 거짓말·단정 0', () {
      final saju = SajuResult.dummy();
      final daily = DailyService();
      final start = DateTime(2026, 5, 21);
      var produced = 0;
      for (var i = 0; i < 30; i++) {
        final dayDate = start.add(Duration(days: i));
        final fortune = daily.calculate(saju, today: dayDate);
        final ctx = SajuContext.from(saju, today: dayDate);
        final event = TodayEventService.build(
          userDayStem: saju.dayPillar.chunGan,
          userDayBranch: saju.dayPillar.jiJi,
          userMonthBranch: saju.monthPillar.jiJi,
          todayPillar: fortune.dayPillar,
          todayScore: fortune.totalScore,
        );
        final selection = TopicSelectorService.select(
          saju: saju,
          ctx: ctx,
          event: event,
          date: dayDate,
        );
        // notification_service.dart 와 동일 — 실제 합충 관계를 relation 으로.
        final relation =
            MysteryRelationKey.fromHapChungType(event.hapChungType);
        final copy = NotificationPoolService.pickMystery(
          date: dayDate,
          todayPillar: fortune.dayPillar,
          day60ji: saju.dayPillar.text,
          topicId: selection.selected?.id,
          relation: relation,
          dayOffset: i,
        );
        produced++;
        final all = '${copy.title} ${copy.bodyLine1} ${copy.bodyLine2}';
        expect(forbiddenAssertion.hasMatch(all), isFalse,
            reason: '미스터리 경로 알림 단정 표현 (day $i): $all');
        // 거짓말 0 — 실제 충 아닌 날 충 어휘가 line1 에 없는지.
        if (relation != MysteryRelation.chung && !copy.isFeatureHook) {
          expect(RegExp('맞서|부딪').hasMatch(copy.bodyLine1), isFalse,
              reason: '충 아닌 날(day $i, $relation) 충 어휘: ${copy.bodyLine1}');
        }
        if (relation != MysteryRelation.hap && !copy.isFeatureHook) {
          expect(RegExp('맞물|끌어당').hasMatch(copy.bodyLine1), isFalse,
              reason: '합 아닌 날(day $i, $relation) 합 어휘: ${copy.bodyLine1}');
        }
      }
      expect(produced, 30);
    });

    test('Fix3 — scheduleSignature 가 미스터리 버전 마커를 포함', () {
      // saju!=null && useKo 경로의 signature 에 mystery 마커가 박혀,
      // 알고리즘 버전이 바뀌면 needsReschedule==true 가 된다 (Fix3 회귀 가드).
      final src = File('lib/services/notification_service.dart')
          .readAsStringSync();
      expect(src.contains('_kMysteryAlgoVersion'), isTrue,
          reason: '미스터리 알고리즘 버전 마커 상수 누락');
      expect(RegExp("mystery_v\\d").hasMatch(src), isTrue,
          reason: '미스터리 버전 문자열 누락');
      expect(src.contains('mysteryKey'), isTrue,
          reason: 'scheduleSignature 에 mysteryKey 결합 누락');
    });
  });
}
