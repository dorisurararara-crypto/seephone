// R103 sprint 5B — QA sample evidence (50 past-life wonjin samples).
//
// 실행: flutter test test/probe_r103_sprint5b_qa.dart
//
// 사용자 mandate verify:
//   - "카리나가름" 0
//   - "선비가라는" 0
//   - "선비이라는" 0
//   - raw "$" placeholder 잔존 0
//   - "두 사람은" 0
//   - "결이 두 사람 사이에" 0
// + 콘솔 sample 출력 (사람 검수용).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> pool;

  setUpAll(() async {
    final f = File('assets/data/past_life_pool.json');
    pool = json.decode(await f.readAsString()) as Map<String, dynamic>;
    PastLifeService.resetCacheForTest();
    PastLifeService.seedForTest(pool);
  });

  tearDownAll(() {
    PastLifeService.resetCacheForTest();
  });

  SajuResult mk(String dJi) => SajuResult(
        yearPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
        monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
        dayPillar: Pillar(chunGan: '戊', jiJi: dJi),
        hourPillar: null,
        elements: const FiveElements(
            wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
        dayMaster: '戊',
        dayMasterName: 'Test',
        summary: 'test',
        categoryReadings: const {},
      );

  test('R103 sprint 5B QA — 50 wonjin (子-未) samples', () {
    final samples = <String>[];
    final celebNames = ['카리나', '김채원', '아이유', '솔라', '진영'];
    final userNames = ['주현', '도리', '하나', '윤서', '지훈'];
    var hitKarinaGareum = 0;
    var hitSeonbiGaraneun = 0;
    var hitSeonbiIraneun = 0;
    var hitRawDollar = 0;
    var hitTwoPeople = 0;
    var hitJielSaiSae = 0;

    for (var i = 0; i < 50; i++) {
      final cn = celebNames[i % celebNames.length];
      final un = userNames[i % userNames.length];
      final s = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: cn,
        userName: un,
        seed: i,
      );
      samples.add('[seed=$i cn=$cn un=$un] $s');
      if (s.contains('카리나가름')) hitKarinaGareum++;
      if (s.contains('선비가라는')) hitSeonbiGaraneun++;
      if (s.contains('선비이라는')) hitSeonbiIraneun++;
      if (s.contains(r'$')) hitRawDollar++;
      if (s.contains('두 사람은')) hitTwoPeople++;
      if (s.contains('결이 두 사람 사이에')) hitJielSaiSae++;
    }

    // ─── 콘솔 sample 출력 (첫 5개 + 마지막 5개) ─────────────────────────────
    debugPrint('═══ R103 sprint 5B QA — 50 wonjin samples 처음 5개 ═══');
    for (var i = 0; i < 5; i++) {
      debugPrint('${samples[i]}\n');
    }
    debugPrint('═══ R103 sprint 5B QA — 50 wonjin samples 마지막 5개 ═══');
    for (var i = 45; i < 50; i++) {
      debugPrint('${samples[i]}\n');
    }
    debugPrint('═══ grep 결과 ═══');
    debugPrint('"카리나가름"           = $hitKarinaGareum (목표 0)');
    debugPrint('"선비가라는"           = $hitSeonbiGaraneun (목표 0)');
    debugPrint('"선비이라는"           = $hitSeonbiIraneun (목표 0)');
    debugPrint('raw "\$" placeholder = $hitRawDollar (목표 0)');
    debugPrint('"두 사람은"            = $hitTwoPeople (목표 0)');
    debugPrint('"결이 두 사람 사이에"  = $hitJielSaiSae (목표 0)');

    expect(hitKarinaGareum, 0, reason: '"카리나가름" 잔존: $samples');
    expect(hitSeonbiGaraneun, 0, reason: '"선비가라는" 잔존');
    expect(hitSeonbiIraneun, 0, reason: '"선비이라는" 잔존');
    expect(hitRawDollar, 0, reason: 'raw \$ placeholder 잔존');
    expect(hitTwoPeople, 0, reason: '"두 사람은" 잔존');
    expect(hitJielSaiSae, 0, reason: '"결이 두 사람 사이에" 잔존');
  });
}
