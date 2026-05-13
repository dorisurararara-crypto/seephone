// Round 73 sprint 6 — career_recommend + wealth_strategy 회귀 테스트.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/career_recommend_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/wealth_strategy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final career = File('assets/data/career_pool.json');
    CareerRecommendService.seedForTest(
        json.decode(await career.readAsString()) as Map<String, dynamic>);
    final wealth = File('assets/data/wealth_detail.json');
    WealthStrategyService.seedForTest(
        json.decode(await wealth.readAsString()) as Map<String, dynamic>);
  });

  group('CareerRecommendService — Round 73 sprint 6', () {
    test('1995-10-27 신묘 case — 직업 list ≥3, "언론/글/방송/미디어" 매칭 ≥1', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final r = await CareerRecommendService.compute(saju);
      expect(r.careersKo.length, greaterThanOrEqualTo(3),
          reason: 'careersKo too few: ${r.careersKo}');

      // 운세의신 본문 "언론인·기고가·영화인" 의미 매칭
      final keywords = ['언론', '기고', '작가', '방송', '미디어', 'PD', '큐레이터', '콘텐츠', '강사', '교사'];
      final matched = r.careersKo.any((c) => keywords.any((k) => c.contains(k)));
      expect(matched, true,
          reason: '운세의신 본문 매칭 키워드 1개 이상 필요. 출력: ${r.careersKo}');
    });

    test('직업 list ko / en 각각 5-7개', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final r = await CareerRecommendService.compute(saju);
      expect(r.careersKo.length, inInclusiveRange(5, 7));
      expect(r.careersEn.length, inInclusiveRange(5, 7));
    });

    test('일관성 — 같은 사주 두 번 호출 = 같은 결과', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final a = await CareerRecommendService.compute(saju);
      final b = await CareerRecommendService.compute(saju);
      expect(a.careersKo, b.careersKo);
    });
  });

  group('WealthStrategyService — Round 73 sprint 6', () {
    test('1995-10-27 신묘 case — 3 phase 모두 ≥80자 (ko)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final w = await WealthStrategyService.compute(saju);
      expect(w.accumKo.length, greaterThanOrEqualTo(80),
          reason: 'accumKo too short: ${w.accumKo}');
      expect(w.lossKo.length, greaterThanOrEqualTo(80),
          reason: 'lossKo too short: ${w.lossKo}');
      expect(w.techKo.length, greaterThanOrEqualTo(80),
          reason: 'techKo too short: ${w.techKo}');
      // EN check
      expect(w.accumEn.length, greaterThanOrEqualTo(60));
      expect(w.lossEn.length, greaterThanOrEqualTo(60));
      expect(w.techEn.length, greaterThanOrEqualTo(60));
    });

    test('일관성 — 같은 사주 = 같은 paragraph', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final a = await WealthStrategyService.compute(saju);
      final b = await WealthStrategyService.compute(saju);
      expect(a.accumKo, b.accumKo);
      expect(a.lossKo, b.lossKo);
      expect(a.techKo, b.techKo);
    });
  });
}
