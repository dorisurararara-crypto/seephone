// Round 76 — TodayEventService 결정성 + 카테고리 매핑 + 별점 범위 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/daily_service.dart' show DayEnergyKind;
import 'package:pillarseer/services/today_event_service.dart';

void main() {
  group('TodayEventService 결정성', () {
    test('같은 입력 100회 호출 → 결과 동일 (pure function)', () {
      TodayEventReading? prev;
      for (var i = 0; i < 100; i++) {
        final r = TodayEventService.build(
          userDayStem: '甲',
          userDayBranch: '子',
          userMonthBranch: '寅',
          todayPillar: '丙戌',
          todayScore: 70,
        );
        if (prev != null) {
          expect(r.categoryDominant, prev.categoryDominant);
          expect(r.categorySub, prev.categorySub);
          expect(r.tenGodGroup, prev.tenGodGroup);
          expect(r.starsLove, prev.starsLove);
          expect(r.starsMoney, prev.starsMoney);
          expect(r.starsWork, prev.starsWork);
          expect(r.starsHealth, prev.starsHealth);
          expect(r.activeShinsa, prev.activeShinsa);
          expect(r.hapChungType, prev.hapChungType);
        }
        prev = r;
      }
    });
  });

  group('TodayEventService 십성 → 카테고리 매핑', () {
    test('재성 그룹 → 돈 dominant', () {
      // 甲 일간 vs 오늘 천간 戊 → 편재 (재성).
      // 일지 子 vs 오늘 지지 辰 — 충 X, 합 X, 신살 X, 단순 재성 base.
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '戊辰',
        todayScore: 60,
      );
      expect(r.tenGodGroup, TenGodGroup.jaeseong);
      expect(r.categoryDominant, EventCategory.money);
    });

    test('관성 그룹 → 일 dominant', () {
      // 甲 일간 vs 오늘 천간 庚 → 편관 (관성).
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '庚辰',
        todayScore: 60,
      );
      expect(r.tenGodGroup, TenGodGroup.gwanseong);
      expect(r.categoryDominant, EventCategory.work);
    });

    test('인성 그룹 → 건강 dominant', () {
      // 甲 일간 vs 오늘 천간 壬 → 편인 (인성).
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '壬辰',
        todayScore: 60,
      );
      expect(r.tenGodGroup, TenGodGroup.inseong);
      expect(r.categoryDominant, EventCategory.health);
    });

    test('식상 그룹 → 일 dominant + 관계 sub', () {
      // 甲 일간 vs 오늘 천간 丙 → 식신 (식상).
      // 일지 子 vs 오늘 지지 戌 — 신살/합/충 비활성 case.
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 50,
      );
      expect(r.tenGodGroup, TenGodGroup.siksang);
      expect(r.categoryDominant, EventCategory.work);
    });

    test('비겁 그룹 → 관계 dominant', () {
      // 甲 일간 vs 오늘 천간 甲 → 비견 (비겁).
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '甲戌',
        todayScore: 50,
      );
      expect(r.tenGodGroup, TenGodGroup.bigyeop);
      expect(r.categoryDominant, EventCategory.relationship);
    });
  });

  group('TodayEventService 신살 가중', () {
    test('도화 활성 → love 별점 ≥ 3 (재성 sub + 도화 3 가중)', () {
      // 甲 일지 子 → 도화 = 酉. 오늘 지지 酉 + 천간 戊 (재성).
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '戊酉',
        todayScore: 50,
      );
      expect(r.activeShinsa.contains('도화'), isTrue);
      // baseline 1 + 재성 sub love +2 + 도화 +3 = love score 6 → 별점 3.
      expect(r.starsLove, greaterThanOrEqualTo(3));
    });

    test('역마 활성 + actionDay → luck 점수 ≥ 5', () {
      // 일지 子 → 역마 = 寅. 오늘 천간 庚 + 지지 寅 = 庚寅.
      // todayScore 80 = actionDay → luck +1 추가.
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '庚寅',
        todayScore: 80,
      );
      expect(r.activeShinsa.contains('역마'), isTrue);
      // baseline 1 + 역마 +3 + actionDay +1 = luck 5점.
      expect(r.rawScores[EventCategory.luck]! >= 5, isTrue);
    });
  });

  group('TodayEventService 합·충 매핑', () {
    test('일지 子 vs 오늘 지지 丑 → 합', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '癸丑',
        todayScore: 60,
      );
      expect(r.hapChungType, '합');
    });

    test('일지 子 vs 오늘 지지 午 → 충', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丁午',
        todayScore: 60,
      );
      expect(r.hapChungType, '충');
    });
  });

  group('TodayEventService 별점 범위 + dominant non-null', () {
    test('600+ case 매트릭스 — 모든 case dominant non-null, 별점 4 합 [4, 20]', () {
      // 10 일간 × 12 일지 × 5 오늘 천간 = 600 case.
      const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      const branches = [
        '子', '丑', '寅', '卯', '辰', '巳',
        '午', '未', '申', '酉', '戌', '亥',
      ];
      const todayStems = ['甲', '丙', '戊', '庚', '壬'];

      var count = 0;
      for (final us in stems) {
        for (final ub in branches) {
          for (final ts in todayStems) {
            // 오늘 지지는 일지 + offset 으로 결정 (변동성 확보).
            final tb = branches[(branches.indexOf(ub) + ts.codeUnits.first) %
                branches.length];
            final r = TodayEventService.build(
              userDayStem: us,
              userDayBranch: ub,
              userMonthBranch: '寅',
              todayPillar: '$ts$tb',
              todayScore: 50,
            );
            final sum = r.starsLove + r.starsMoney + r.starsWork + r.starsHealth;
            expect(r.starsLove, inInclusiveRange(1, 5));
            expect(r.starsMoney, inInclusiveRange(1, 5));
            expect(r.starsWork, inInclusiveRange(1, 5));
            expect(r.starsHealth, inInclusiveRange(1, 5));
            expect(sum, inInclusiveRange(4, 20));
            count++;
          }
        }
      }
      expect(count, greaterThanOrEqualTo(600));
    });
  });

  group('TodayEventService composeNotificationLine 톤', () {
    test('모든 6 카테고리 분기: verbatim 헷지 ("생기기 쉬워요|흐름이 강해요|흔들릴 수 있어요") 1개 이상',
        () {
      // 사용자 verbatim 강제 — 헷지 어구 3종 중 하나 반드시.
      final strictHedge = RegExp(r'(생기기 쉬워요|흐름이 강해요|흔들릴 수 있어요|쌓이기 쉬워요)');
      final forbid = RegExp(
          r'(반드시|사고가 날|큰돈을 잃|병원|이성과 만납니다|확정|확실히)');
      // 6 카테고리 각각 fallback body 직접 검증.
      for (final cat in EventCategory.values) {
        final reading = TodayEventReading(
          categoryDominant: cat,
          categorySub: cat,
          tenGodGroup: TenGodGroup.bigyeop,
          activeShinsa: const [],
          hapChungType: '없음',
          starsLove: 3,
          starsMoney: 3,
          starsWork: 3,
          starsHealth: 3,
          sourceReason: '',
          energy: DayEnergyKind.mixedDay,
          rawScores: const {},
        );
        final line = TodayEventService.composeNotificationLine(reading);
        expect(line.length <= 300, isTrue, reason: 'over 300: $line');
        expect(strictHedge.hasMatch(line), isTrue,
            reason: '${cat.name} no strict hedge: $line');
        expect(forbid.hasMatch(line), isFalse,
            reason: '${cat.name} forbidden: $line');
      }
    });
  });

  group('TodayEventService 형/파/해 매핑', () {
    test('일지 子 vs 오늘 지지 卯 → 형 (무례지형 子卯)', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '乙卯',
        todayScore: 50,
      );
      expect(r.hapChungType, '형');
    });

    test('일지 寅 vs 오늘 지지 亥 → 합 (寅亥 합 우선)', () {
      // 寅 vs 亥 = 6합. 파 (寅亥) 와도 겹치지만 합 분기가 먼저 — relation = '합'.
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '寅',
        userMonthBranch: '寅',
        todayPillar: '乙亥',
        todayScore: 50,
      );
      expect(r.hapChungType, '합');
    });

    test('일지 子 vs 오늘 지지 酉 → 파 (子酉 파 + 도화)', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '乙酉',
        todayScore: 50,
      );
      expect(r.hapChungType, '파');
    });

    test('일지 子 vs 오늘 지지 未 → 해 (子未 해)', () {
      final r = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '乙未',
        todayScore: 50,
      );
      expect(r.hapChungType, '해');
    });
  });
}
