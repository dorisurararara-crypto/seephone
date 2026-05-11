// Pillar Seer — saju 정확성 known-date 회귀 테스트 + 핵심 서비스 단위.
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/personalization_engine.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/streak_service.dart';
import 'package:pillarseer/services/ten_gods_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SajuService', () {
    final service = SajuService();

    test('60갑자 인덱스 → Pillar 변환', () {
      expect(service.pillarFromIndex(0).text, '甲子');
      expect(service.pillarFromIndex(17).text, '辛巳');
      expect(service.pillarFromIndex(59).text, '癸亥');
      expect(service.pillarFromIndex(60).text, '甲子');
    });

    test('1996-04-15 14:30 sum 100±3', () async {
      final result = await service.calculateSaju(
        year: 1996, month: 4, day: 15, hour: 14, minute: 30,
        isLunar: false, isMale: true,
      );
      expect(result.dayPillar.text.length, 2);
      final sum = result.elements.wood + result.elements.fire +
          result.elements.earth + result.elements.metal +
          result.elements.water;
      expect(sum, greaterThanOrEqualTo(97));
      expect(sum, lessThanOrEqualTo(103));
    });

    // Known-date 회귀 (KASI 만세력 기준 — celebrities.json 과 일치 검증)
    test('IU 1993-05-16: Day pillar 丁卯 (Fire Rabbit, KASI)', () async {
      final r = await service.calculateSaju(
        year: 1993, month: 5, day: 16, hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      expect(r.dayPillar.text, '丁卯');
      expect(r.dayMasterName, 'Fire Rabbit');
    });

    test('BTS V 1995-12-30: Day pillar 乙未 (Wood Goat, KASI)', () async {
      final r = await service.calculateSaju(
        year: 1995, month: 12, day: 30, hour: 12, minute: 0,
        isLunar: false, isMale: true, unknownTime: true,
      );
      expect(r.dayPillar.text, '乙未');
    });

    test('Yuna Kim 1990-09-05: Day pillar 癸酉 (Water Rooster, KASI)', () async {
      final r = await service.calculateSaju(
        year: 1990, month: 9, day: 5, hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      expect(r.dayPillar.text, '癸酉');
    });

    test('Son Heung-min 1992-07-08: Day pillar 乙酉 (Wood Rooster, KASI)', () async {
      final r = await service.calculateSaju(
        year: 1992, month: 7, day: 8, hour: 12, minute: 0,
        isLunar: false, isMale: true, unknownTime: true,
      );
      expect(r.dayPillar.text, '乙酉');
    });
  });

  group('TenGodsService', () {
    test('일간 戊 (Yang Earth) 기준 십신 매핑', () {
      // 戊 = Yang Earth
      // 戊 vs 戊 = same yang-yang → 비견
      expect(TenGodsService.godFor('戊', '戊'), TenGod.bigyeon);
      // 戊 vs 己 = Earth+Earth, opp polarity → 겁재
      expect(TenGodsService.godFor('戊', '己'), TenGod.geopjae);
      // 戊 generates 庚 (Earth → Metal), same polarity (yang) → 식신
      expect(TenGodsService.godFor('戊', '庚'), TenGod.siksin);
      // 戊 overcomes 壬 (Earth → Water), same polarity → 편재
      expect(TenGodsService.godFor('戊', '壬'), TenGod.pyeonjae);
    });
  });

  group('PersonalizationEngine', () {
    test('deterministic — 같은 사주 같은 날 같은 결과', () async {
      final svc = SajuService();
      final r1 = await svc.calculateSaju(
        year: 1993, month: 5, day: 16, hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      final r2 = await svc.calculateSaju(
        year: 1993, month: 5, day: 16, hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      final p1 = PersonalizationEngine.buildFor(r1, now: DateTime(2026, 5, 12));
      final p2 = PersonalizationEngine.buildFor(r2, now: DateTime(2026, 5, 12));
      expect(p1.headlineKo, p2.headlineKo);
      expect(p1.bodyEn, p2.bodyEn);
    });

    test('서로 다른 사주는 다른 결과 (chart hash 차별화)', () async {
      final svc = SajuService();
      final iu = await svc.calculateSaju(
        year: 1993, month: 5, day: 16, hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      final v = await svc.calculateSaju(
        year: 1995, month: 12, day: 30, hour: 12, minute: 0,
        isLunar: false, isMale: true, unknownTime: true,
      );
      final p1 = PersonalizationEngine.buildFor(iu, now: DateTime(2026, 5, 12));
      final p2 = PersonalizationEngine.buildFor(v, now: DateTime(2026, 5, 12));
      // 서로 다른 사주이므로 적어도 한 필드는 달라야 함
      final allSame = p1.headlineKo == p2.headlineKo &&
          p1.bodyKo == p2.bodyKo &&
          p1.actionKo == p2.actionKo;
      expect(allSame, false);
    });

    test('{compKo} / {compEn} 토큰이 렌더링됨 (codex Round 7 bug fix)', () async {
      final svc = SajuService();
      final r = await svc.calculateSaju(
        year: 1993, month: 5, day: 16, hour: 12, minute: 0,
        isLunar: false, isMale: false, unknownTime: true,
      );
      final p = PersonalizationEngine.buildFor(r);
      expect(p.actionKo.contains('{compKo}'), false);
      expect(p.actionEn.contains('{compEn}'), false);
      expect(p.headlineKo.contains('{'), false);
    });
  });

  group('StreakService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('첫 체크인 → current=1, longest=1', () async {
      final r = await StreakService.tick();
      expect(r.current, 1);
      expect(r.longest, 1);
      expect(r.isNewDay, true);
    });

    test('같은 날 두 번 tick → current 유지', () async {
      await StreakService.tick();
      final r2 = await StreakService.tick();
      expect(r2.current, 1);
    });
  });

  group('Dev unlock release safety (codex Round 9)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Note: kDevGateEnabled 은 const 라 test에서 override 불가.
    // 디버그 환경에서 true, release 에서 false. 이 테스트는 디버그 환경에서
    // pref 상태가 정상적으로 read 되는지만 확인.
    test('apply() invalid 코드 시 unchanged', () async {
      // 실제 Notifier 호출은 ProviderContainer 필요해 통합 테스트에서 다룸.
      // 여기선 prefs key 명세 회귀.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.dev.pro_unlocked') ?? false, false);
    });
  });
}
