// R102 Sprint 3 — Music Pharmacy "idol only" 가드 회귀 테스트.
//
// 사용자 verbatim (R102 Sprint 1 baseline):
//   "한소희는 가수도 아니고 나의아저씨는 없는노랜데 ??"
//
// 차단 정책:
//   - 후보 선정 및 fallback 풀에서 kind == 'actor' / 'athlete' / 'icon' 셀럽 제외.
//   - 단, idol 활동 이력 있는 actor/icon 4명은 hardcoded 예외로 retain:
//       cha-eunwoo / lee-junho / bae-suzy / gdragon
//
// 검증:
//   1) 5행 deficit (wood/fire/earth/metal/water) × 10 seed = 50 prescribe 호출
//      → 결과 celebId 의 kind 가 actor/athlete/icon 이면 예외 4명 외 FAIL.
//   2) 한소희 / 김연아 / 손흥민 / 박서준 / 송혜교 5명 explicit 차단 verify
//      (각자 dayPillar 천간 element 에 맞는 user 30 seed 돌려도 결과로 안 나옴).
//   3) 차은우 / 이준호 / 배수지 / 지드래곤 4명은 처방 후보 풀 안에 살아 있음
//      (해당 element seed 충분히 돌리면 최소 1회 등장 또는 _musicEligibleException
//       정책이 production filter 를 통과하는지 직접 검증).
//   4) fallback path — 모든 후보가 non-eligible 인 가짜 데이터에서도 actor/athlete
//      는 절대 노출되지 않음 (pool null 반환 OK).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/music_pharmacy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> songs;
  late List<Map<String, dynamic>> celebs;
  late Map<String, Map<String, dynamic>> celebById;

  /// musicEligible 예외 — service 와 동일하게 sync 유지.
  const Set<String> exceptionIds = <String>{
    'cha-eunwoo',
    'lee-junho',
    'bae-suzy',
    'gdragon',
  };

  /// 사용자 mandate: actor/athlete/icon 중에서 가수 활동 이력이 없는 셀럽 —
  /// 어떤 deficit / seed 조합에서도 절대 처방되어선 안 됨.
  const List<String> blockedExplicit = <String>[
    'han-sohee',
    'kim-yuna',
    'son-heungmin',
    'park-seojoon',
    'song-hyekyo',
    'squidgame-lee',
    'kim-soohyun',
    'lee-minho',
    'song-kang',
    'byeon-wooseok',
    'hwang-inyoup',
    'kim-seonho',
    'ji-changwook',
    'kim-jiwon',
    'kim-hyeyoon',
    'jin-seyeon',
  ];

  setUpAll(() async {
    final songsFile = File('assets/data/celeb_songs.json');
    final celebsFile = File('assets/data/celebrities.json');
    songs = json.decode(await songsFile.readAsString()) as Map<String, dynamic>;
    celebs = (json.decode(await celebsFile.readAsString()) as List)
        .cast<Map<String, dynamic>>();
    celebById = <String, Map<String, dynamic>>{
      for (final c in celebs) c['id'] as String: c,
    };
    MusicPharmacyService.resetCacheForTest();
    MusicPharmacyService.seedForTest(celebs: celebs, songs: songs);
  });

  tearDownAll(() {
    MusicPharmacyService.resetCacheForTest();
  });

  SajuResult makeSaju({
    required int wood,
    required int fire,
    required int earth,
    required int metal,
    required int water,
    String dGan = '戊',
    String dJi = '寅',
  }) {
    return SajuResult(
      yearPillar: const Pillar(chunGan: '癸', jiJi: '卯'),
      monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
      dayPillar: Pillar(chunGan: dGan, jiJi: dJi),
      hourPillar: const Pillar(chunGan: '己', jiJi: '未'),
      elements: FiveElements(
        wood: wood,
        fire: fire,
        earth: earth,
        metal: metal,
        water: water,
      ),
      dayMaster: dGan,
      dayMasterName: 'Test',
      summary: 'test',
      categoryReadings: const {},
    );
  }

  /// 5행 deficit 별 fixture — 다른 4행은 25, 부족 5행은 5.
  List<(String, SajuResult)> deficitFixtures() {
    return <(String, SajuResult)>[
      ('wood', makeSaju(wood: 5, fire: 25, earth: 25, metal: 25, water: 20)),
      ('fire', makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20)),
      ('earth', makeSaju(wood: 25, fire: 25, earth: 5, metal: 25, water: 20)),
      ('metal', makeSaju(wood: 25, fire: 25, earth: 25, metal: 5, water: 20)),
      ('water', makeSaju(wood: 25, fire: 25, earth: 25, metal: 20, water: 5)),
    ];
  }

  group('R102 Sprint 3 — kind/musicEligible 가드', () {
    test(
        '5행 × 10 seed = 50 prescribe — 결과 celeb kind 가 actor/athlete/icon 이면 '
        '예외 4명 외 FAIL', () {
      final fixtures = deficitFixtures();
      for (final f in fixtures) {
        final (label, user) = f;
        for (var seed = 1; seed <= 10; seed++) {
          final p =
              MusicPharmacyService.prescribeSync(user: user, seed: seed);
          expect(p, isNotNull,
              reason: 'deficit=$label seed=$seed: no prescription');
          final celeb = celebById[p!.celebId];
          expect(celeb, isNotNull,
              reason: 'returned celebId ${p.celebId} not in celebrities.json');
          final kind = (celeb!['kind'] as String?) ?? '';
          final isException = exceptionIds.contains(p.celebId);
          if (kind != 'idol' && !isException) {
            fail('deficit=$label seed=$seed → ${p.celebId} '
                '(${celeb['nameKo']}, kind=$kind) leaked. '
                'Only idol or hardcoded exception allowed.');
          }
        }
      }
    });

    test(
        '한소희 / 김연아 / 손흥민 / 박서준 / 송혜교 등 actor·athlete — '
        '5행 deficit × 30 seed 전수 verify 후 결과 0', () {
      // 각 차단 셀럽의 dayPillar 천간 element 가 무엇이든 — 5행 deficit 5종 ×
      // seed 30 = 150 prescribe call 전부 돌려서 차단 셀럽 id 가 결과로 안 나옴.
      final fixtures = deficitFixtures();
      final hits = <String, int>{
        for (final id in blockedExplicit) id: 0,
      };
      for (final f in fixtures) {
        final (_, user) = f;
        for (var seed = 1; seed <= 30; seed++) {
          final p =
              MusicPharmacyService.prescribeSync(user: user, seed: seed);
          if (p == null) continue;
          if (hits.containsKey(p.celebId)) {
            hits[p.celebId] = hits[p.celebId]! + 1;
          }
        }
      }
      for (final entry in hits.entries) {
        expect(entry.value, equals(0),
            reason:
                'blocked celeb ${entry.key} leaked ${entry.value} times');
      }
    });

    test('예외 retain — 차은우 / 이준호 / 배수지 / 지드래곤 4명은 가드 통과', () {
      // _musicEligibleException 정책이 service candidates filter 를 통과하는지
      // 직접 확인 — 4명 모두 dayPillar element 에 맞는 deficit user 에 seed 50
      // 돌려서 최소 1회 등장 확인.
      // dayPillar 매핑:
      //   cha-eunwoo  = 辛未 → metal
      //   lee-junho   = 庚寅 → metal
      //   bae-suzy    = 己巳 → earth
      //   gdragon     = 乙巳 → wood
      final retainCases = <(String, String)>[
        ('cha-eunwoo', 'metal'),
        ('lee-junho', 'metal'),
        ('bae-suzy', 'earth'),
        ('gdragon', 'wood'),
      ];

      // service 가 idol 정책으로 데이터 자체를 차단하면 이 test FAIL 됨 →
      // _musicEligibleException 가드가 살아있다는 증거.
      // 다만 후보 풀이 큰 element 에서는 4명 중 1명이 seed 50 안에 안 뽑힐 수도
      // 있음 → 직접 service _Celeb.musicEligible getter 가 true 인지 검증.
      // (private class 라 reflection 불가 → 후보 풀 안에 존재 verify 로 대체.)
      for (final r in retainCases) {
        final (id, elementKey) = r;
        final celeb = celebById[id];
        expect(celeb, isNotNull, reason: '$id not in celebrities.json');
        // sanity: kind 가 actor / icon — 아니면 hardcoded 예외 정책 자체가
        // 의미 없음 (cleanup 끝났다는 신호).
        final kind = celeb!['kind'] as String? ?? '';
        expect(['actor', 'icon'].contains(kind), isTrue,
            reason: '$id kind=$kind — 예외 정책 재검토 필요');
        // 곡 데이터 있는지 확인 (filter 통과 조건).
        expect(songs.containsKey(id), isTrue,
            reason: '$id celeb_songs.json 에 곡 없음 → filter 통과 불가');

        // service prescribe 로 element 매칭 user × seed 100 돌려서 최소 1회 hit
        // (셀럽 풀 크기에 따라 확률 다름 — 가드 통과 확인 목적).
        final user = _makeUserForElement(elementKey);
        var hit = 0;
        for (var seed = 1; seed <= 100; seed++) {
          final p =
              MusicPharmacyService.prescribeSync(user: user, seed: seed);
          if (p == null) continue;
          if (p.celebId == id) hit++;
        }
        expect(hit, greaterThan(0),
            reason:
                '$id (element=$elementKey) — 예외 retain 정책이 후보 풀에서 작동 안 함. '
                'seed 100 중 hit=$hit');
      }
    });

    test(
        'fallback path — 모든 후보가 non-eligible 인 가짜 데이터에서 actor 처방 X', () {
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(
        celebs: const [
          {
            'id': 'fake_actor1',
            'nameKo': '배우1',
            'dayPillar': '甲子',
            'kind': 'actor',
            'birth': '2000-01-01',
          },
          {
            'id': 'fake_actor2',
            'nameKo': '배우2',
            'dayPillar': '乙丑',
            'kind': 'actor',
            'birth': '2000-01-02',
          },
          {
            'id': 'fake_athlete1',
            'nameKo': '선수1',
            'dayPillar': '丙寅',
            'kind': 'athlete',
            'birth': '2000-01-03',
          },
        ],
        songs: const {
          'fake_actor1': [
            {
              'titleKo': '배우 곡 1',
              'artistKo': '헌정',
              'element': 'wood',
              'moodKo': '봄',
            }
          ],
          'fake_actor2': [
            {
              'titleKo': '배우 곡 2',
              'artistKo': '헌정',
              'element': 'wood',
              'moodKo': '여름',
            }
          ],
          'fake_athlete1': [
            {
              'titleKo': '응원곡',
              'artistKo': '응원곡',
              'element': 'fire',
              'moodKo': '챔피언',
            }
          ],
        },
      );
      // user fire deficit — 후보 0, fallback 도 모두 non-eligible.
      final user = makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20);
      final p = MusicPharmacyService.prescribeSync(user: user, seed: 1);
      // service 정책: pool empty → null. 가드가 fallback 까지 적용되었다는 증거.
      expect(p, isNull,
          reason: 'fallback path 에서 actor/athlete 가 처방되어 leak: '
              '${p?.celebId} ${p?.celebNameKo}');

      // 원본 데이터 복원.
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(celebs: celebs, songs: songs);
    });

    test(
        'fallback path — actor + idol 혼합 가짜 데이터에서 idol 만 풀에 잡힘', () {
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(
        celebs: const [
          // user deficit = fire 인데 fire 셀럽은 actor — 후보 0 → fallback.
          {
            'id': 'fake_actor_fire',
            'nameKo': '배우불',
            'dayPillar': '丙寅',
            'kind': 'actor',
            'birth': '2000-01-01',
          },
          // fallback 풀에서 잡혀야 할 idol.
          {
            'id': 'fake_idol_wood',
            'nameKo': '아이돌나무',
            'dayPillar': '甲子',
            'kind': 'idol',
            'birth': '2000-02-01',
          },
        ],
        songs: const {
          'fake_actor_fire': [
            {
              'titleKo': '배우불 곡',
              'artistKo': '헌정',
              'element': 'fire',
              'moodKo': '열',
            }
          ],
          'fake_idol_wood': [
            {
              'titleKo': '아이돌나무 곡',
              'artistKo': '아이돌나무',
              'element': 'wood',
              'moodKo': '봄',
            }
          ],
        },
      );
      final user = makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20);
      // 여러 seed 돌려서 actor 가 한 번이라도 노출되면 FAIL.
      for (var seed = 1; seed <= 20; seed++) {
        final p =
            MusicPharmacyService.prescribeSync(user: user, seed: seed);
        expect(p, isNotNull,
            reason: 'fallback should produce a prescription with idol pool');
        expect(p!.celebId, equals('fake_idol_wood'),
            reason: 'fallback path leaked non-idol: ${p.celebId}');
      }

      // 원본 데이터 복원.
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(celebs: celebs, songs: songs);
    });
  });
}

/// 부족 5행이 명시 element 가 되도록 사주를 만든다.
SajuResult _makeUserForElement(String element) {
  switch (element) {
    case 'wood':
      return _saju(wood: 5, fire: 25, earth: 25, metal: 25, water: 20);
    case 'fire':
      return _saju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20);
    case 'earth':
      return _saju(wood: 25, fire: 25, earth: 5, metal: 25, water: 20);
    case 'metal':
      return _saju(wood: 25, fire: 25, earth: 25, metal: 5, water: 20);
    case 'water':
      return _saju(wood: 25, fire: 25, earth: 25, metal: 20, water: 5);
  }
  return _saju(wood: 5, fire: 25, earth: 25, metal: 25, water: 20);
}

SajuResult _saju({
  required int wood,
  required int fire,
  required int earth,
  required int metal,
  required int water,
}) {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '癸', jiJi: '卯'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
    dayPillar: const Pillar(chunGan: '戊', jiJi: '寅'),
    hourPillar: const Pillar(chunGan: '己', jiJi: '未'),
    elements: FiveElements(
      wood: wood,
      fire: fire,
      earth: earth,
      metal: metal,
      water: water,
    ),
    dayMaster: '戊',
    dayMasterName: 'Test',
    summary: 'test',
    categoryReadings: const {},
  );
}
