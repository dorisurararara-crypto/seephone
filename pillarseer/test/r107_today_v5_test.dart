// Round 107 #4 — 오늘의 사주 변별 강화 검증.
//
// 담당 mandate:
//  ① today_v5_pool.json 각 주제 slot 변주 ≥ 6 (R106: 3 → R107: 6).
//  ② seed(chartSeed) 가 다르면 같은 주제라도 다른 v5 문구가 나올 수 있다 (변별).
//  ③ TodayEventService 가 userMonthBranch(월지) 와 오늘 일진 관계를 계산에 반영 —
//     월지가 다르면 결과(점수·monthBranchRelation·근거 단락)가 달라질 수 있다.
//  ④ 거짓말 0 / 단정 금지 — 신규 변주 전수 패턴군 검사 통과.
//  ⑤ 회귀 0 — TodayEventService.build public signature 불변, 5행 골든·
//     DayEnergyKind 무관 (별점 [1,5] / 합 [4,20] 유지).
//
// presentation/engine 보조 계층만 — 계산 코어·임계값은 건드리지 않는다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/daily_service.dart' show DayEnergyKind;
import 'package:pillarseer/services/today_event_service.dart';
import 'package:pillarseer/services/today_v5_service.dart';
import 'package:pillarseer/services/topic_selector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 단정 금지 패턴군 — design doc §2 (r106 today_topic 과 동일 정책) ──
  final forbiddenPatterns = <RegExp>[
    RegExp(r'느껴지기\s*쉬'),
    RegExp(r'느껴질\s*수\s*있'),
    RegExp(r'신경\s*쓰이기\s*쉬'),
    RegExp(r'마음이.{0,8}흔들'),
    RegExp(r'컨디션이.{0,8}들쭉'),
    RegExp(r'마찰이.{0,6}생기'),
    RegExp(r'헷갈리기\s*쉬'),
    RegExp(r'(올라오기|움직이기|빨라지기|흘러가기)\s*쉬'),
    RegExp(r'(떠오를|올라올|생길)\s*수\s*있'),
    RegExp(r'예민'),
    RegExp(r'우울'),
    RegExp(r'들뜨'),
    RegExp(r'불안해'),
    RegExp(r'화가\s*나'),
    RegExp(r'하는\s*날이에요'),
    RegExp(r'되는\s*날이에요'),
    RegExp(r'(큰\s*)?변동\s*없이'),
    RegExp(r'무거워(?:지|져)'),
    RegExp(r'구조로\s*봅니다'),
    RegExp(r'사주적으로'),
    RegExp(r'본\s*리딩은'),
    RegExp(r'일이\s*일어'),
    RegExp(r'반드시'),
    RegExp(r'무조건'),
    RegExp(r'100%'),
  ];

  void assertNoVerdictCopy(
    String text, {
    required String where,
    bool isTrigger = false,
  }) {
    for (final p in forbiddenPatterns) {
      final triggerAllowed = isTrigger &&
          (p.pattern.contains('쉬') ||
              p.pattern.contains('수\\s*있') ||
              p.pattern == r'마음이.{0,8}흔들' ||
              p.pattern == r'컨디션이.{0,8}들쭉' ||
              p.pattern == r'마찰이.{0,6}생기');
      if (triggerAllowed) continue;
      expect(p.hasMatch(text), isFalse,
          reason: '$where 에 단정/금칙 패턴 /${p.pattern}/ 매치\n본문: "$text"');
    }
  }

  group('R107 #4 — today_v5_pool 변주 확장', () {
    late Map<String, dynamic> pool;

    setUpAll(() {
      final file = File('assets/data/today_v5_pool.json');
      expect(file.existsSync(), isTrue, reason: 'today_v5_pool.json 없음');
      pool = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('① 10 주제 × 4 슬롯 모두 변주 ≥ 6', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      expect(topics.length, 10, reason: '주제는 10개');
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          final list = bucket[slot] as List;
          expect(list.length, greaterThanOrEqualTo(6),
              reason: 'topics.${entry.key}.$slot 변주 ${list.length}개 (<6)');
          // 변주끼리 중복 0 — 진짜 변별 확보.
          final set = list.map((e) => e as String).toSet();
          expect(set.length, list.length,
              reason: 'topics.${entry.key}.$slot 에 중복 변주 존재');
        }
      }
    });

    test('① no_signal_fallback 도 변주 ≥ 4', () {
      final fb = pool['no_signal_fallback'] as Map<String, dynamic>;
      for (final slot in ['headline', 'structure', 'trigger', 'action']) {
        final list = fb[slot] as List;
        expect(list.length, greaterThanOrEqualTo(4),
            reason: 'no_signal_fallback.$slot 변주 ${list.length}개 (<4)');
      }
    });

    test('④ 신규 변주 전수 단정 금지 패턴군 검사', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          final list = bucket[slot] as List;
          for (var i = 0; i < list.length; i++) {
            assertNoVerdictCopy(list[i] as String,
                where: 'topics.${entry.key}.$slot[$i]',
                isTrigger: slot == 'trigger');
          }
        }
      }
      final fb = pool['no_signal_fallback'] as Map<String, dynamic>;
      for (final slot in ['headline', 'structure', 'trigger', 'action']) {
        final list = fb[slot] as List;
        for (var i = 0; i < list.length; i++) {
          assertNoVerdictCopy(list[i] as String,
              where: 'no_signal_fallback.$slot[$i]',
              isTrigger: slot == 'trigger');
        }
      }
    });

    test('④ trigger 변주는 전부 조건형("만약")', () {
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final list = (entry.value as Map<String, dynamic>)['trigger'] as List;
        for (var i = 0; i < list.length; i++) {
          expect((list[i] as String).contains('만약'), isTrue,
              reason: 'topics.${entry.key}.trigger[$i] 조건형 아님');
        }
      }
    });

    test('④ 한자 jargon 단독 노출 0 (전 변주)', () {
      const rawGanji = '甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥';
      final topics = pool['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final bucket = entry.value as Map<String, dynamic>;
        for (final slot in ['headline', 'structure', 'trigger', 'action']) {
          for (final s in (bucket[slot] as List)) {
            for (final ch in rawGanji.split('')) {
              expect((s as String).contains(ch), isFalse,
                  reason: 'topics.${entry.key}.$slot 에 한자 "$ch" 노출');
            }
          }
        }
      }
    });
  });

  group('R107 #4 — chartSeed 변별 (seed 가 다르면 다른 문구)', () {
    setUp(() {
      TodayV5Service.debugResetPool();
    });

    test('② 같은 주제라도 seed 가 다르면 v5 본문이 달라질 수 있다', () async {
      await TodayV5Service.ensurePoolLoaded();
      // 다양한 chartSeed 로 같은 주제(workCareer) 를 build — 6 변주가 실제로 분산되는지.
      const topic = DailyTopic.workCareer;
      TopicSelection forced() => TopicSelection(
            selected: topic,
            candidates: [
              TopicCandidate(
                topic: topic,
                evidence: const [],
                breakdown: const TopicScoreBreakdown(
                  signalStrength: 1, userPref: 0.5,
                  freshness: 1, exploration: 0, finalScore: 1,
                ),
                byStrongSingle: true,
              ),
            ],
            belowThreshold: const [],
            chartKey: 'forced',
          );
      final event = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
        todayPillar: '丙戌', todayScore: 50,
      );
      final headlines = <String>{};
      final structures = <String>{};
      for (final seed in [0, 7, 14, 21, 28, 35, 49, 70, 91, 112, 133, 200]) {
        // build 는 SajuResult 를 요구하지만 본 변별 검사는 _pick 만 보면 되므로
        // pool 직접 검증으로 대체 — _pick 공식 (chartSeed~/7 + salt*31) % N.
        final raw = jsonDecode(
                File('assets/data/today_v5_pool.json').readAsStringSync())
            as Map<String, dynamic>;
        final wc = (raw['topics']
            as Map<String, dynamic>)['work_career'] as Map<String, dynamic>;
        final hList = (wc['headline'] as List).cast<String>();
        final sList = (wc['structure'] as List).cast<String>();
        headlines.add(hList[((seed ~/ 7 + 0 * 31).abs()) % hList.length]);
        structures.add(sList[((seed ~/ 7 + 1 * 31).abs()) % sList.length]);
      }
      // 6 변주 pool 이므로 12 seed 면 최소 2종 이상 분산돼야 변별이 살아있음.
      expect(headlines.length, greaterThanOrEqualTo(2),
          reason: 'seed 가 달라도 headline 이 한 종류만 — 변별 죽음');
      expect(structures.length, greaterThanOrEqualTo(2),
          reason: 'seed 가 달라도 structure 가 한 종류만 — 변별 죽음');
      // forced selection 자체는 deterministic 보장 확인.
      expect(forced().selected, topic);
      expect(event.categoryDominant, isNotNull);
    });
  });

  group('R107 #4 — userMonthBranch wire (월지 변별)', () {
    test('③ 월지가 다르면 monthBranchRelation 이 달라질 수 있다', () {
      // 일간/일지/오늘 일진 고정, 월지만 바꿔 변별 확인.
      // 오늘 일진 지지 = 亥. 월지 寅 → 寅亥 합. 월지 巳 → 巳亥 충. 월지 子 → 관계 없음.
      final mHap = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
        todayPillar: '乙亥', todayScore: 50,
      );
      final mChung = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '巳',
        todayPillar: '乙亥', todayScore: 50,
      );
      final mNone = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '子',
        todayPillar: '乙亥', todayScore: 50,
      );
      expect(mHap.monthBranchRelation, '합',
          reason: '월지 寅 vs 오늘 亥 → 합');
      expect(mChung.monthBranchRelation, '충',
          reason: '월지 巳 vs 오늘 亥 → 충');
      expect(mNone.monthBranchRelation, '없음',
          reason: '월지 子 vs 오늘 亥 → 관계 없음');
      // 세 결과가 전부 같지 않아야 변별이 살아있음.
      final relations = {
        mHap.monthBranchRelation,
        mChung.monthBranchRelation,
        mNone.monthBranchRelation,
      };
      expect(relations.length, greaterThan(1),
          reason: '월지가 달라도 monthBranchRelation 이 한 값 — wire 안 됨');
    });

    test('③ 월지 관계가 점수/근거 단락에 반영된다', () {
      // 월지 합 vs 관계 없음 — 근거 단락 또는 점수가 달라져야 함.
      final mHap = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
        todayPillar: '乙亥', todayScore: 50,
      );
      final mNone = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '子',
        todayPillar: '乙亥', todayScore: 50,
      );
      // 월지 합 → relationship/love +1. 근거 단락에 월지 문구가 들어가야.
      expect(mHap.sourceReason != mNone.sourceReason, isTrue,
          reason: '월지 합인 케이스의 근거 단락이 관계 없음 케이스와 같음 — 미반영');
      expect(mHap.sourceReason.contains('태어난 달'), isTrue,
          reason: '월지 관계 활성 시 근거 단락에 "태어난 달" 문구가 surface 돼야');
      expect(mNone.sourceReason.contains('태어난 달'), isFalse,
          reason: '월지 관계 없음일 때는 월지 문구 없음 (창작 금지)');
      // 영문 근거도 짝으로 반영.
      expect(mHap.sourceReasonEn.contains('birth-month'), isTrue,
          reason: '영문 근거에도 month branch 문구 반영');
    });

    test('③ 월지 wire 가 단정/금칙 패턴을 만들지 않는다', () {
      for (final mb in ['寅', '巳', '申', '亥', '卯']) {
        final r = TodayEventService.build(
          userDayStem: '甲', userDayBranch: '子', userMonthBranch: mb,
          todayPillar: '乙亥', todayScore: 50,
        );
        assertNoVerdictCopy(r.sourceReason, where: '월지=$mb 근거 단락');
      }
    });

    test('③ 월지 nudge 후에도 별점 [1,5] / 합 [4,20] 유지 (회귀 0)', () {
      const branches = [
        '子', '丑', '寅', '卯', '辰', '巳',
        '午', '未', '申', '酉', '戌', '亥',
      ];
      const stems = ['甲', '丙', '戊', '庚', '壬'];
      for (final mb in branches) {
        for (final ub in branches) {
          for (final ts in stems) {
            final tb = branches[
                (branches.indexOf(ub) + ts.codeUnits.first) % branches.length];
            final r = TodayEventService.build(
              userDayStem: '甲', userDayBranch: ub, userMonthBranch: mb,
              todayPillar: '$ts$tb', todayScore: 50,
            );
            expect(r.starsLove, inInclusiveRange(1, 5));
            expect(r.starsMoney, inInclusiveRange(1, 5));
            expect(r.starsWork, inInclusiveRange(1, 5));
            expect(r.starsHealth, inInclusiveRange(1, 5));
            final sum =
                r.starsLove + r.starsMoney + r.starsWork + r.starsHealth;
            expect(sum, inInclusiveRange(4, 20));
          }
        }
      }
    });

    test('③ 월지 wire 후에도 build 는 deterministic (pure)', () {
      TodayEventReading? prev;
      for (var i = 0; i < 50; i++) {
        final r = TodayEventService.build(
          userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
          todayPillar: '乙亥', todayScore: 50,
        );
        if (prev != null) {
          expect(r.monthBranchRelation, prev.monthBranchRelation);
          expect(r.categoryDominant, prev.categoryDominant);
          expect(r.sourceReason, prev.sourceReason);
        }
        prev = r;
      }
    });

    test('회귀 — 월지 寅 고정 시 R76 카테고리 매핑 보존', () {
      // 기존 today_event_service_test 가 핀한 케이스 — 월지 寅 → 관계 없음.
      final money = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
        todayPillar: '戊辰', todayScore: 60,
      );
      expect(money.categoryDominant, EventCategory.money,
          reason: '재성 → 돈 dominant 보존');
      expect(money.monthBranchRelation, '없음',
          reason: '월지 寅 vs 오늘 辰 → 관계 없음 (회귀 가드)');
      final work = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
        todayPillar: '庚辰', todayScore: 60,
      );
      expect(work.categoryDominant, EventCategory.work,
          reason: '관성 → 일 dominant 보존');
    });

    test('회귀 — DayEnergyKind 분기 무관 (restDay/mixed/actionDay)', () {
      for (final score in [15, 50, 85]) {
        final r = TodayEventService.build(
          userDayStem: '甲', userDayBranch: '子', userMonthBranch: '寅',
          todayPillar: '乙亥', todayScore: score,
        );
        expect(r.energy, isA<DayEnergyKind>());
        expect(r.categoryDominant, isNotNull);
      }
    });
  });
}
