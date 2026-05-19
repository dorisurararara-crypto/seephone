// R102 sprint 2 — headline raw " 과 " / " 의 " 0 회귀.
//
// L445 / L495 hard fallback 에서 placeholder 우회된 raw 공백 + 조사 잔존을 가드.

import 'dart:convert';
import 'dart:io';

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

  SajuResult makeSaju({
    required String dJi,
  }) {
    return SajuResult(
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
  }

  group('R102 headline — korean_josa helper 적용', () {
    final celebNames = <String>['김채원', '솔라', '아이유', '뷔', '카리나'];
    final userNames = <String>['당신', '주현', '도리', '너'];

    test('headlineKo 에 raw " 과 " 또는 " 의 " 잔존 0', () async {
      for (final celebName in celebNames) {
        for (final userName in userNames) {
          for (var seed = 0; seed < 3; seed++) {
            final u = makeSaju(dJi: '子');
            final c = makeSaju(dJi: '未');
            final result = await PastLifeService.generate(
              user: u,
              celeb: c,
              celebName: celebName,
              userName: userName,
              seed: seed,
            );
            final h = result.headlineKo;
            // user name 직후 공백 + "과"/"와" 잔존 0.
            expect(h.contains('$userName 과 '), isFalse,
                reason: 'raw " 과 " in headline: $h');
            expect(h.contains('$userName 와 '), isFalse,
                reason: 'raw " 와 " in headline: $h');
            // celeb name 직후 공백 + "의" 잔존 0.
            expect(h.contains('$celebName 의 '), isFalse,
                reason: 'raw " 의 " in headline: $h');
            // user/celeb 이름이 모두 헤드라인에 등장.
            expect(h.contains(userName), isTrue,
                reason: 'userName 누락: $h');
            expect(h.contains(celebName), isTrue,
                reason: 'celebName 누락: $h');
            // "전생" 키워드 포함.
            expect(h.contains('전생'), isTrue,
                reason: '전생 누락: $h');
          }
        }
      }
    });

    test('받침 있는 이름 → "과" 조사', () async {
      // "당신" — 받침 ㄴ → "당신과".
      final result = await PastLifeService.generate(
        user: makeSaju(dJi: '子'),
        celeb: makeSaju(dJi: '未'),
        celebName: '솔라',
        userName: '당신',
        seed: 1,
      );
      expect(result.headlineKo.contains('당신과'), isTrue,
          reason: '받침 있는 user → "과" 미적용: ${result.headlineKo}');
    });

    test('받침 없는 이름 → "와" 조사', () async {
      // "뷔" — 받침 없음 → "뷔와".
      // 단, 사용자 이름 자리에 받침 없는 이름을 넣어야 검증 가능.
      final result = await PastLifeService.generate(
        user: makeSaju(dJi: '子'),
        celeb: makeSaju(dJi: '未'),
        celebName: '아이유',
        userName: '뷔',
        seed: 1,
      );
      expect(result.headlineKo.contains('뷔와'), isTrue,
          reason: '받침 없는 user → "와" 미적용: ${result.headlineKo}');
    });
  });
}
