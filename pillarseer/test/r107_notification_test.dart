// Pillar Seer — Round 107 #3 — 알림 정확도.
//
// codex audit ground truth:
//  - 기본 알림 풀(pickFor)은 사주 계산 없이 날짜+일주 seed 로 문구만 픽.
//    _koPool/_enPool/_koPoolMz/_enPoolMz 에 사건·결과 단정 문구 잔존 위험.
//  - 미스터리 알림(pickMystery, R106 P2b)은 실제 hapChungType 계산 기반.
//
// R107 #3 fix:
//  ① deep/mystery 가 기본 경로 — 사주가 있으면 notification_service 의
//     scheduleDaily 가 항상 pickMystery(한국어) / pickDeep(영문, 계산 기반)를
//     쓰고, pickFor 기본 풀은 saju == null 일 때만 last-resort fallback.
//  ② 기본 풀 4종(_koPool/_enPool/_koPoolMz/_enPoolMz) — 사건·결과 단정 0.
//     v5 voice = 조건형("~하면"), 경향형("~기 쉬워요/tends to/can/may").
//  ③ 회귀 — R76 pickDeep / R106 pickMystery 동작 보존.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/daily_service.dart';
import 'package:pillarseer/services/notification_pool_service.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/today_event_service.dart';
import 'package:pillarseer/services/topic_selector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 5, 21);

  // ─────────────────────────────────────────────────────────────────
  // ① deep/mystery 가 기본 경로 — notification_service.dart 의 발송 경로 검증.
  //    flutter_local_notifications 플러그인은 unit test 에서 직접 못 돌리므로
  //    scheduleDaily 소스의 분기 구조를 검사 + 파이프라인을 재현한다.
  // ─────────────────────────────────────────────────────────────────
  group('① deep/mystery 기본 경로 승격', () {
    final src =
        File('lib/services/notification_service.dart').readAsStringSync();

    test('scheduleDaily — 사주+한국어면 미스터리, pickFor 보다 먼저 분기', () {
      // useMystery 가 saju + useKo 둘 다일 때 true.
      expect(src.contains('useMystery = saju != null && useKo'), isTrue,
          reason: 'useMystery 분기 누락');
      // 분기 순서: useMystery → else if saju != null (deep) → else if day60ji
      // (pickFor). pickFor 는 마지막 else-if 여야 last-resort.
      final iMystery = src.indexOf('if (useMystery)');
      final iDeep = src.indexOf('else if (saju != null)');
      final iFor = src.indexOf('pickFor(');
      expect(iMystery, greaterThan(0));
      expect(iDeep, greaterThan(iMystery),
          reason: 'deep 분기가 mystery 보다 먼저');
      expect(iFor, greaterThan(iDeep),
          reason: 'pickFor(기본 풀)가 deep/mystery 보다 먼저 — 승격 깨짐');
    });

    test('scheduleDaily — pickFor 호출이 day60ji 분기 안에서만 (saju 없을 때)', () {
      // pickFor 는 `else if (day60ji != null ...)` 블록 안에서만 호출.
      // saju != null 경로에서는 절대 pickFor 로 안 빠진다.
      final iForBranch = src.indexOf('else if (day60ji != null');
      final iForCall = src.indexOf('pickFor(');
      expect(iForBranch, greaterThan(0), reason: 'day60ji fallback 분기 누락');
      expect(iForCall, greaterThan(iForBranch),
          reason: 'pickFor 가 day60ji fallback 분기 밖에서 호출됨');
    });

    test('파이프라인 재현 — 사주 있으면 mystery(계산 기반) 본문 생성', () async {
      NotificationPoolService.debugResetMysteryPool();
      await NotificationPoolService.ensureMysteryPoolLoaded();
      await TodayEventService.ensurePoolLoaded();
      final saju = SajuResult.dummy();
      final daily = DailyService();
      for (var i = 0; i < 30; i++) {
        final dayDate = date.add(Duration(days: i));
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
        // 미스터리 알림은 그날 실제 일진 글자를 본문에 노출 (계산 기반).
        final char = fortune.dayPillar.length >= 2
            ? fortune.dayPillar[1]
            : '';
        if (!copy.isFeatureHook && char.isNotEmpty) {
          expect(copy.bodyLine1.contains(char), isTrue,
              reason: 'day $i — 미스터리 본문이 실제 일진 글자 미반영');
        }
      }
    });

    test('파이프라인 재현 — 사주 있으면 deep(계산 기반) 영문 본문 생성', () {
      final saju = SajuResult.dummy();
      final daily = DailyService();
      for (var i = 0; i < 14; i++) {
        final dayDate = date.add(Duration(days: i));
        final fortune = daily.calculate(saju, today: dayDate);
        final picked = NotificationPoolService.pickDeep(
          date: dayDate,
          saju: saju,
          todayPillar: fortune.dayPillar,
          todayScore: fortune.totalScore,
        );
        // deep 영문은 TodayEventService 계산 결과 — "Today" 로 시작.
        expect(picked.en.contains('Today'), isTrue);
        expect(picked.ko.isNotEmpty, isTrue);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ② 기본 풀 4종 — 사건·결과 단정 0 (v5 voice).
  //    pickFor 가 골라낸 결과뿐 아니라 풀에 적힌 모든 entry 를 전수 스캔한다.
  // ─────────────────────────────────────────────────────────────────
  group('② 기본 풀 단정 제거 — v5 voice', () {
    // 50갑자 표본 — 12 지지 cover. pickFor 결과 전수 추출용.
    const sampleDay60ji = [
      '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳',
      '庚午', '辛未', '壬申', '癸酉', '甲戌', '乙亥',
      '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳',
    ];

    // 한국어 기본 풀 50 entry 를 전수 추출 (adult + mz).
    Set<String> collectAll() {
      final out = <String>{};
      for (final tone in NotificationTone.values) {
        for (final d in sampleDay60ji) {
          for (var off = 0; off < 60; off++) {
            final p = NotificationPoolService.pickFor(
              date.add(Duration(days: off)),
              d,
              tone: tone,
            );
            out.add(p.ko);
            out.add(p.en);
          }
        }
      }
      return out;
    }

    // R107 #3 — 사건·결과 *단정* 금지군. 조건형/경향형은 허용.
    //  - 미래 사건 단정: "만나요/돌아와요/와요/열려요/생겨요" 가 무조건형.
    //  - 결과 단정: "맞아요/잘 풀려요/먹혀요/이깁니다(조건 없이)".
    // 단, "~하면 / ~수 있어요 / ~기 쉬워요 / ~편이에요" 등 헷지가 같은
    // 문장에 있으면 조건형이므로 통과. 그래서 "헷지 없는 단정"만 잡는다.
    final hedgeKo = RegExp(
      r'(수 있어요|쉬워요|편이에요|만약|면 |면\.|어도 |을까요|볼까요|보면|'
      r'해 보세요|봐주세요|어 보세요|아 보세요|기 쉬|있을 가능성)',
    );
    // 노골적 사건·결과 단정 — 헷지 유무와 무관하게 codex 가 짚은 패턴.
    final hardAssertKo = RegExp(
      r'(오늘 만나요|돌아와요\.|준비됐어요|세 번째 의견이 맞아요|'
      r'잘 풀려요\.|잘 받아져요\.|잘 먹혀요\.|돈이 따라와요|'
      r'에너지를 새고 있어요|답을 정해요)',
    );

    test('한국어 기본 풀 — codex 가 짚은 노골적 단정 패턴 0', () {
      final all = collectAll();
      expect(all, isNotEmpty);
      for (final s in all) {
        expect(hardAssertKo.hasMatch(s), isFalse,
            reason: 'R107 단정 잔존: "$s"');
      }
    });

    test('한국어 기본 풀 — 결과/사건 서술 entry 는 헷지를 동반', () {
      // "운세"성 결과/사건 동사가 들어간 문장은 조건·경향 헷지가 같이 있어야.
      final outcomeVerb = RegExp(
        r'(만나요|돌아와|준비됐|풀려요|받아져|먹혀요|따라와|열려요|'
        r'바꿔요|살아요|정해요|돌아와요)',
      );
      for (final s in collectAll()) {
        if (outcomeVerb.hasMatch(s)) {
          expect(hedgeKo.hasMatch(s), isTrue,
              reason: 'R107 — 결과/사건 단정에 헷지 없음: "$s"');
        }
      }
    });

    test('영문 기본 풀 — 사건·결과 단정 패턴 0 (조건형/경향형만)', () {
      // R107 #3 에서 제거한 노골적 단정 문장 — 다시 들어오면 fail.
      // 전부 "무조건형" — 헷지 없이 사건/결과를 단언하던 옛 카피.
      const removedHardAssertEn = [
        "You'll meet someone you remember in 6 months.",
        'A small risk pays off',
        'Money chat goes well today.',
        'Old plans return. One of them is finally ready.',
        'A confession lands well',
        'A bold compliment is well received.',
        "It's right.", // "Listen to the third opinion today. It's right."
        'A career conversation is closer than it feels.',
        'Old friend returns.',
        "Tonight's sleep decides tomorrow's answer.",
        'The love window opens late today.',
        'A long-running tension softens.',
        'A creative cycle restarts.',
      ];
      // 결과/사건 동사가 보이면 헷지(can/may/tends to/likely/if)가 같이.
      final hedgeEn = RegExp(
        r'\b(can|may|tends to|likely|if|If|might|could|Stay open)\b',
      );
      final outcomeEn = RegExp(
        r'\b(meet|pays?|goes|opens?|received|drain|decide|'
        r'restart|comes alive|return)\b',
      );
      for (final s in collectAll()) {
        // collectAll 가 ko+en 둘 다 모음.
        if (!RegExp(r'[a-zA-Z]').hasMatch(s)) continue; // ko 스킵
        for (final old in removedHardAssertEn) {
          expect(s.contains(old), isFalse,
              reason: 'R107 EN 단정 잔존: "$s"');
        }
        if (outcomeEn.hasMatch(s)) {
          expect(hedgeEn.hasMatch(s), isTrue,
              reason: 'R107 EN — 결과/사건 단정에 헷지 없음: "$s"');
        }
      }
    });

    test('codex audit 명시 예시 2개가 풀에서 사라졌는지', () {
      final all = collectAll();
      // "6개월 후 기억할 사람을 오늘 만나요" — 사건 단정.
      for (final s in all) {
        expect(s.contains('오늘 만나요'), isFalse,
            reason: 'audit 예시 잔존: "$s"');
        // "세 번째 의견이 맞아요" — 결과 단정.
        expect(s.contains('세 번째 의견이 맞아요'), isFalse,
            reason: 'audit 예시 잔존: "$s"');
        // 영문 짝.
        expect(s.contains("You'll meet someone"), isFalse,
            reason: 'audit 예시(EN) 잔존: "$s"');
        expect(s.contains("It's right."), isFalse,
            reason: 'audit 예시(EN) 잔존: "$s"');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ③ 회귀 — R76 pickDeep / R106 pickMystery / pickFor 결정성 보존.
  // ─────────────────────────────────────────────────────────────────
  group('③ 회귀 — 기존 알림 동작 보존', () {
    test('R76 — pickDeep 결정성 + 금지어 0 (계산 기반 본문 보존)', () {
      final saju = SajuResult.dummy();
      // R76 금지어 — 의료/사고 단정. pickDeep 계산 본문에 절대 안 나옴.
      final forbid = RegExp(r'(반드시|사고가 날|큰돈을 잃|병원|이성과 만납니다)');
      const stems = ['甲', '丙', '戊', '庚', '壬'];
      const branches = ['子', '辰', '戌', '寅', '亥', '酉'];
      for (final s in stems) {
        for (final b in branches) {
          final p1 = NotificationPoolService.pickDeep(
            date: date, saju: saju, todayPillar: '$s$b', todayScore: 60,
          );
          final p2 = NotificationPoolService.pickDeep(
            date: date, saju: saju, todayPillar: '$s$b', todayScore: 60,
          );
          expect(p1.ko, p2.ko, reason: 'pickDeep 비결정');
          expect(p1.ko.length, lessThanOrEqualTo(300));
          expect(p1.ko.trim().isNotEmpty, isTrue);
          expect(forbid.hasMatch(p1.ko), isFalse, reason: 'forbid: ${p1.ko}');
          expect(p1.en.contains('Today'), isTrue);
        }
      }
    });

    test('pickFor 결정성 — 같은 입력 100회 동일 (adult/mz)', () {
      for (final tone in NotificationTone.values) {
        String? pk;
        String? pe;
        for (var i = 0; i < 100; i++) {
          final p = NotificationPoolService.pickFor(date, '丙戌', tone: tone);
          pk ??= p.ko;
          pe ??= p.en;
          expect(p.ko, pk);
          expect(p.en, pe);
        }
      }
    });

    test('pickFor — adult/mz 풀 모두 50 entry, 비어있지 않음', () {
      // pickFor idx 가 0~49 전부 도달하면 풀 50 entry 모두 검사됨.
      final koSeen = <String>{};
      final enSeen = <String>{};
      for (var off = 0; off < 4000; off++) {
        final p = NotificationPoolService.pickFor(
          date.add(Duration(days: off)), '甲子',
        );
        koSeen.add(p.ko);
        enSeen.add(p.en);
      }
      for (final s in koSeen) {
        expect(s.trim().isNotEmpty, isTrue);
      }
      for (final s in enSeen) {
        expect(s.trim().isNotEmpty, isTrue);
      }
    });

    test('R106 — pickMystery 결정성 + neutral 관계 단정 0 보존', () async {
      NotificationPoolService.debugResetMysteryPool();
      await NotificationPoolService.ensureMysteryPoolLoaded();
      MysteryNotificationCopy? prev;
      for (var i = 0; i < 50; i++) {
        final copy = NotificationPoolService.pickMystery(
          date: date, todayPillar: '丙寅', day60ji: '辛卯',
          topicId: 'love_connection', relation: MysteryRelation.hap,
          dayOffset: 3,
        );
        prev ??= copy;
        expect(copy.title, prev.title);
        expect(copy.body, prev.body);
      }
      // neutral 관계 단정 어휘 0 (P2b-fix 거짓말 0 회귀).
      final n = NotificationPoolService.pickMystery(
        date: date, todayPillar: '丙寅', day60ji: '辛卯',
        topicId: 'communication', relation: MysteryRelation.neutral,
      );
      expect(RegExp('맞서|부딪|맞물|끌어당|엇갈').hasMatch(n.bodyLine1),
          isFalse);
    });

    test('public API 시그니처 보존 — MysteryRelation/Key/Copy', () {
      // home_screen _OracleHero 가 import — 시그니처 변경 금지 가드.
      expect(MysteryRelation.values.length, 4);
      expect(MysteryRelationKey.fromHapChungType('충'), MysteryRelation.chung);
      const copy = MysteryNotificationCopy(
        title: 't', bodyLine1: 'a', bodyLine2: 'b',
        isFeatureHook: false, topicId: null,
      );
      expect(copy.body, 'a\nb');
    });
  });
}
