// Round 71 회귀 — `DayEnergyKind` 단일 source-of-truth 모순 0 검증.
//
// 사용자 불만 #3: score < 50 (restDay) 일 때 "공식 자리·발표·승진·도전·승부" 어휘 출력 0회.
//                score ≥ 75 (actionDay) 일 때 "쉬어가·아끼" 어휘 출력 0회.
//
// 십신 10종 × restDay/actionDay 모두 검사 — 한 entry 도 모순 X.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/daily_service.dart';
import 'package:pillarseer/services/today_deep_service.dart';

const _restForbiddenKo = ['공식 자리', '발표', '승진', '도전·승부', '도전 승부', '큰 돈 기회'];
const _actionForbiddenKo = ['쉬어가', '아끼', '에너지를 다 쓰지'];

void main() {
  group('Round 71 — DayEnergyKind classifier', () {
    test('totalScore < 50 → restDay', () {
      expect(classifyDayEnergy(0), DayEnergyKind.restDay);
      expect(classifyDayEnergy(45), DayEnergyKind.restDay);
      expect(classifyDayEnergy(49), DayEnergyKind.restDay);
    });
    test('50 ≤ totalScore < 75 → mixedDay', () {
      expect(classifyDayEnergy(50), DayEnergyKind.mixedDay);
      expect(classifyDayEnergy(60), DayEnergyKind.mixedDay);
      expect(classifyDayEnergy(74), DayEnergyKind.mixedDay);
    });
    test('totalScore ≥ 75 → actionDay', () {
      expect(classifyDayEnergy(75), DayEnergyKind.actionDay);
      expect(classifyDayEnergy(85), DayEnergyKind.actionDay);
      expect(classifyDayEnergy(100), DayEnergyKind.actionDay);
    });
  });

  group('Round 71 — TodayDeepService 모순 0 (restDay)', () {
    // restDay: score=45. 모든 십신 + 모든 지지 관계 조합에서
    // "공식 자리·발표·승진·도전·승부" 어휘 출력 금지.
    test('score=45 → restDay 어휘만 (action 어휘 0회)', () {
      // 60갑자 12지지 × 12간 일부 샘플.
      const todayPillars = ['甲子', '丙寅', '戊午', '庚申', '壬戌', '癸亥', '乙丑', '己未'];
      const userStems = ['甲', '丙', '戊', '庚', '壬'];
      for (final today in todayPillars) {
        for (final userStem in userStems) {
          final reading = TodayDeepService.build(
            userDayStem: userStem,
            userDayBranch: today[1],
            userMonthBranch: '子',
            userDominantEl: '木',
            userDeficitEl: '金',
            todayPillar: today,
            todayScore: 45,
          );
          // codex Round 1 FIX#2 — actions + caution 뿐 아니라 headline / body /
          // moodTag 까지 합쳐 invariant 검증.
          final combined = [
            reading.headlineKo,
            reading.bodyKo,
            ...reading.actionsKo,
            reading.cautionKo,
            reading.moodTagKo,
          ].join(' / ');
          for (final word in _restForbiddenKo) {
            expect(combined.contains(word), isFalse,
                reason: 'restDay (score=45) 에 금지어 "$word" 발견: today=$today userStem=$userStem → $combined');
          }
        }
      }
    });
  });

  group('Round 71 — TodayDeepService 모순 0 (actionDay)', () {
    // actionDay: score=85. "쉬어가·아끼" 어휘 0회.
    test('score=85 → actionDay 어휘만 (쉬어가/아끼 0회)', () {
      const todayPillars = ['甲子', '丙寅', '戊午', '庚申', '壬戌', '癸亥', '乙丑', '己未'];
      const userStems = ['甲', '丙', '戊', '庚', '壬'];
      for (final today in todayPillars) {
        for (final userStem in userStems) {
          final reading = TodayDeepService.build(
            userDayStem: userStem,
            userDayBranch: today[1],
            userMonthBranch: '子',
            userDominantEl: '木',
            userDeficitEl: '金',
            todayPillar: today,
            todayScore: 85,
          );
          final combined = [
            reading.headlineKo,
            reading.bodyKo,
            ...reading.actionsKo,
            reading.cautionKo,
            reading.moodTagKo,
          ].join(' / ');
          for (final word in _actionForbiddenKo) {
            expect(combined.contains(word), isFalse,
                reason: 'actionDay (score=85) 에 금지어 "$word" 발견: today=$today userStem=$userStem → $combined');
          }
        }
      }
    });
  });
}
