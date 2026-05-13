// Round 73 sprint 4 — additional_life_service 회귀 테스트.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/additional_life_service.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final f = File('assets/data/additional_life_pool.json');
    AdditionalLifeService.seedForTest(
        json.decode(await f.readAsString()) as Map<String, dynamic>);
  });

  group('AdditionalLifeService — Round 73 sprint 4', () {
    test('1995-10-27 신묘 case — 6 paragraph 모두 ≥80자 (ko)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final r = await AdditionalLifeService.compute(saju);
      expect(r.healthKo.length, greaterThanOrEqualTo(80),
          reason: 'healthKo: ${r.healthKo}');
      expect(r.bodyKo.length, greaterThanOrEqualTo(80));
      expect(r.socialKo.length, greaterThanOrEqualTo(80));
      expect(r.socialPersonaKo.length, greaterThanOrEqualTo(80));
      expect(r.innateNatureKo.length, greaterThanOrEqualTo(80));
      expect(r.innateCharacterKo.length, greaterThanOrEqualTo(80));
      // EN
      expect(r.healthEn.length, greaterThanOrEqualTo(60));
      expect(r.bodyEn.length, greaterThanOrEqualTo(60));
      expect(r.socialEn.length, greaterThanOrEqualTo(60));
      expect(r.socialPersonaEn.length, greaterThanOrEqualTo(60));
      expect(r.innateNatureEn.length, greaterThanOrEqualTo(60));
      expect(r.innateCharacterEn.length, greaterThanOrEqualTo(60));
    });

    test('일관성 — 같은 사주 두 번 호출 = 같은 결과', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final a = await AdditionalLifeService.compute(saju);
      final b = await AdditionalLifeService.compute(saju);
      expect(a.healthKo, b.healthKo);
      expect(a.bodyKo, b.bodyKo);
      expect(a.socialKo, b.socialKo);
    });

    test('다른 dominant 5행 → 다른 paragraph', () async {
      final svc = SajuService();
      final a = await svc.calculateSaju(
        year: 1995, month: 10, day: 27, hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final b = await svc.calculateSaju(
        year: 1990, month: 5, day: 15, hour: 12, minute: 0,
        isLunar: false, isMale: false,
      );
      final ra = await AdditionalLifeService.compute(a);
      final rb = await AdditionalLifeService.compute(b);
      // dominant 5행이 다르면 paragraph 도 달라야 함
      if (ra.dominantEl != rb.dominantEl) {
        expect(ra.healthKo == rb.healthKo, false,
            reason: 'different dominant elements should yield different paragraphs');
      }
    });

    test('17 라벨 grep — result_screen 에 6 신규 라벨 모두 노출', () async {
      // 6 라벨: 건강운/체질운/사회운/사회적 성격/타고난 성향/타고난 인품
      final src = File('lib/screens/result_screen.dart');
      final content = await src.readAsString();
      const labels = [
        '건강운', '체질운', '사회운',
        '사회적 성격', '타고난 성향', '타고난 인품',
      ];
      for (final label in labels) {
        expect(content.contains(label), true,
            reason: '$label not found in result_screen.dart');
      }
    });
  });
}
