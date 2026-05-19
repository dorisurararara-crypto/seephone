// R101 Sprint 6 — 디지털 기운 처방전 (팬심 2순위) 회귀 가드.
//
// 목표:
//   1. celeb_songs.json parse OK + 5 element coverage (>= 12 each)
//   2. service.prescribe(): deficit 5행 → 같은 5행 셀럽 매칭
//   3. seed determinism (같은 seed = 같은 prescription, 다른 seed = 다른 가능성)
//   4. KO prescription 본문 영문 leak 0 (Water/Wood/Fire/Earth/Metal head /
//      Rabbit/Tiger 등 동물 영문 / anchor / signature / 그룹명 영문 head)
//   5. fallback (모든 셀럽이 한 element 만 있는 가짜 데이터) → 처방 생성
//   6. screen smoke test (build OK + share button + reroll button)

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/music_pharmacy_screen.dart';
import 'package:pillarseer/services/music_pharmacy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> songs;
  late List<Map<String, dynamic>> celebs;

  setUpAll(() async {
    final songsFile = File('assets/data/celeb_songs.json');
    final celebsFile = File('assets/data/celebrities.json');
    songs = json.decode(await songsFile.readAsString()) as Map<String, dynamic>;
    celebs = (json.decode(await celebsFile.readAsString()) as List)
        .cast<Map<String, dynamic>>();
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

  group('celeb_songs.json — 구조 + 커버리지', () {
    test('parse OK + entry count >= 60', () {
      expect(songs, isA<Map>());
      expect(songs.length, greaterThanOrEqualTo(60));
    });

    test('각 entry list 비어있지 않음 + 필수 키', () {
      for (final id in songs.keys) {
        final list = (songs[id] as List).cast<Map<String, dynamic>>();
        expect(list, isNotEmpty, reason: '$id has no song');
        for (final song in list) {
          expect(song['titleKo'], isA<String>());
          expect(song['artistKo'], isA<String>());
          expect(song['element'], isA<String>());
          expect((song['titleKo'] as String).isNotEmpty, isTrue,
              reason: '$id titleKo empty');
          expect((song['artistKo'] as String).isNotEmpty, isTrue,
              reason: '$id artistKo empty');
        }
      }
    });

    test('5 element 커버리지 — 각 element 셀럽 수 >= 12', () {
      const elementMap = {
        '甲': 'wood', '乙': 'wood',
        '丙': 'fire', '丁': 'fire',
        '戊': 'earth', '己': 'earth',
        '庚': 'metal', '辛': 'metal',
        '壬': 'water', '癸': 'water',
      };
      final counts = <String, int>{
        'wood': 0,
        'fire': 0,
        'earth': 0,
        'metal': 0,
        'water': 0,
      };
      for (final c in celebs) {
        final id = c['id'] as String;
        if (!songs.containsKey(id)) continue;
        final dp = c['dayPillar'] as String? ?? '';
        if (dp.isEmpty) continue;
        final elem = elementMap[dp[0]];
        if (elem != null) counts[elem] = counts[elem]! + 1;
      }
      for (final entry in counts.entries) {
        expect(entry.value, greaterThanOrEqualTo(12),
            reason: 'element ${entry.key} celeb count too low: $counts');
      }
    });
  });

  group('MusicPharmacyService.prescribeSync — element matching', () {
    test('fire 가 가장 부족 → fire 셀럽 매칭 (element=fire)', () {
      final user = makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20);
      final p = MusicPharmacyService.prescribeSync(user: user, seed: 1);
      expect(p, isNotNull);
      expect(p!.element, equals('fire'));
      // 셀럽 dayPillar 천간이 丙/丁 (fire) 중 하나여야 한다.
      final celeb = celebs.firstWhere((c) => c['id'] == p.celebId);
      final chun = (celeb['dayPillar'] as String)[0];
      expect(['丙', '丁'].contains(chun), isTrue,
          reason: 'celeb ${celeb['nameKo']} chunGan=$chun not in fire');
    });

    test('wood 가 가장 부족 → wood 셀럽 매칭', () {
      final user = makeSaju(wood: 5, fire: 25, earth: 25, metal: 25, water: 20);
      final p = MusicPharmacyService.prescribeSync(user: user, seed: 1);
      expect(p, isNotNull);
      expect(p!.element, equals('wood'));
      final celeb = celebs.firstWhere((c) => c['id'] == p.celebId);
      final chun = (celeb['dayPillar'] as String)[0];
      expect(['甲', '乙'].contains(chun), isTrue);
    });

    test('water 가 가장 부족 → water 셀럽 매칭', () {
      final user =
          makeSaju(wood: 25, fire: 25, earth: 25, metal: 20, water: 5);
      final p = MusicPharmacyService.prescribeSync(user: user, seed: 1);
      expect(p, isNotNull);
      expect(p!.element, equals('water'));
      final celeb = celebs.firstWhere((c) => c['id'] == p.celebId);
      final chun = (celeb['dayPillar'] as String)[0];
      expect(['壬', '癸'].contains(chun), isTrue);
    });

    test('earth / metal 도 동일 매칭', () {
      final pEarth = MusicPharmacyService.prescribeSync(
          user: makeSaju(wood: 25, fire: 25, earth: 5, metal: 25, water: 20),
          seed: 1);
      expect(pEarth, isNotNull);
      expect(pEarth!.element, equals('earth'));
      final cE = celebs.firstWhere((c) => c['id'] == pEarth.celebId);
      expect(['戊', '己'].contains((cE['dayPillar'] as String)[0]), isTrue);

      final pMetal = MusicPharmacyService.prescribeSync(
          user: makeSaju(wood: 25, fire: 25, earth: 25, metal: 5, water: 20),
          seed: 1);
      expect(pMetal, isNotNull);
      expect(pMetal!.element, equals('metal'));
      final cM = celebs.firstWhere((c) => c['id'] == pMetal.celebId);
      expect(['庚', '辛'].contains((cM['dayPillar'] as String)[0]), isTrue);
    });
  });

  group('seed determinism', () {
    test('같은 seed → 같은 prescription', () {
      final user = makeSaju(wood: 20, fire: 5, earth: 25, metal: 25, water: 25);
      final a = MusicPharmacyService.prescribeSync(user: user, seed: 42)!;
      final b = MusicPharmacyService.prescribeSync(user: user, seed: 42)!;
      expect(a.celebId, equals(b.celebId));
      expect(a.songTitleKo, equals(b.songTitleKo));
      expect(a.effectKo, equals(b.effectKo));
      expect(a.sideEffectKo, equals(b.sideEffectKo));
      expect(a.dosageKo, equals(b.dosageKo));
      expect(a.prescriptionText, equals(b.prescriptionText));
    });

    test('seed 미명시 → 같은 사주면 deterministic', () {
      final user = makeSaju(wood: 20, fire: 5, earth: 25, metal: 25, water: 25);
      final a = MusicPharmacyService.prescribeSync(user: user)!;
      final b = MusicPharmacyService.prescribeSync(user: user)!;
      expect(a.prescriptionText, equals(b.prescriptionText));
    });

    test('다른 seed → variance 확보 (10 seed 중 5+ 다른 prescription)', () {
      final user = makeSaju(wood: 20, fire: 5, earth: 25, metal: 25, water: 25);
      final base = MusicPharmacyService.prescribeSync(user: user, seed: 0)!;
      var diff = 0;
      for (var s = 1; s <= 10; s++) {
        final p = MusicPharmacyService.prescribeSync(user: user, seed: s)!;
        if (p.prescriptionText != base.prescriptionText) diff++;
      }
      expect(diff, greaterThanOrEqualTo(5),
          reason: 'seed variance too low: $diff/10 differ');
    });
  });

  group('KO 본문 English leak 가드', () {
    final forbidden = <String>[
      // 5행 영문 (Pillar.pairEnglish head)
      'Water ', 'Wood ', 'Fire ', 'Earth ', 'Metal ',
      // 12지 영문 동물
      'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake',
      'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
      // 키워드 영문 leak
      'anchor', 'Anchor', 'signature',
      // K-POP 그룹명 영문 (sprint 1 baseline §2.2)
      'LE SSERAFIM', 'BLACKPINK', 'SEVENTEEN', 'BTS', 'TWICE',
      'aespa', 'IVE', 'ITZY', 'STAYC', 'ATEEZ', 'BABYMONSTER',
    ];

    final cases = <(int, int, int, int, int)>[
      (5, 25, 25, 25, 20), // wood deficit
      (25, 5, 25, 25, 20), // fire deficit
      (25, 25, 5, 25, 20), // earth deficit
      (25, 25, 25, 5, 20), // metal deficit
      (25, 25, 25, 20, 5), // water deficit
    ];

    for (final c in cases) {
      final (w, f, e, m, wa) = c;
      for (var seed = 1; seed <= 4; seed++) {
        test('w=$w f=$f e=$e m=$m wa=$wa seed=$seed — leak 0', () {
          final user = makeSaju(
              wood: w, fire: f, earth: e, metal: m, water: wa);
          final p = MusicPharmacyService.prescribeSync(
              user: user, userName: '너', seed: seed)!;
          final text = p.prescriptionText;
          for (final bad in forbidden) {
            expect(text.contains(bad), isFalse,
                reason: 'forbidden "$bad" leaked: $text');
          }
          // 5~7 줄 본문 길이 가드 (한국어 안 들어가도 80자 이상).
          expect(text.length, greaterThanOrEqualTo(80),
              reason: 'prescription too short: $text');
          // 셀럽 이름·곡 제목·효능·부작용·복용법 모두 본문에 포함.
          expect(text.contains(p.celebNameKo.split('(').first.trim()), isTrue);
          expect(text.contains(p.songTitleKo), isTrue);
          expect(text.contains(p.effectKo), isTrue);
          expect(text.contains(p.sideEffectKo), isTrue);
          expect(text.contains(p.dosageKo), isTrue);
        });
      }
    }

    test('userName null → "당신" 사용', () {
      final user = makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20);
      final p = MusicPharmacyService.prescribeSync(
          user: user, userName: null, seed: 7)!;
      expect(p.prescriptionText.contains('당신'), isTrue,
          reason: '당신 not in: ${p.prescriptionText}');
    });
  });

  group('fallback — element 후보 0 edge case', () {
    test('가짜 데이터: 모든 셀럽이 wood 만 → user fire deficit → 그래도 처방 생성', () {
      // 격리된 fake set — sprint 6 가드 격리용. setUpAll 의 cache 를 잠시 가린다.
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(
        celebs: const [
          {
            'id': 'fake_wood1',
            'nameKo': '나무1',
            'dayPillar': '甲子',
            'kind': 'idol',
            'birth': '2000-01-01',
          },
          {
            'id': 'fake_wood2',
            'nameKo': '나무2',
            'dayPillar': '乙丑',
            'kind': 'idol',
            'birth': '2000-01-02',
          },
        ],
        songs: const {
          'fake_wood1': [
            {
              'titleKo': '봄나무 곡',
              'artistKo': '나무1',
              'element': 'wood',
              'moodKo': '봄빛',
            }
          ],
          'fake_wood2': [
            {
              'titleKo': '잎새 곡',
              'artistKo': '나무2',
              'element': 'wood',
              'moodKo': '여름 잎새',
            }
          ],
        },
      );
      final user = makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20);
      final p = MusicPharmacyService.prescribeSync(user: user, seed: 1);
      expect(p, isNotNull, reason: 'fallback should return a prescription');
      // element 자체는 user deficit (fire) 그대로.
      expect(p!.element, equals('fire'));
      // celeb 은 fallback 으로 wood 셀럽 중 하나.
      expect(['fake_wood1', 'fake_wood2'].contains(p.celebId), isTrue);

      // 격리 끝 — 원본 데이터 복원.
      MusicPharmacyService.resetCacheForTest();
      MusicPharmacyService.seedForTest(celebs: celebs, songs: songs);
    });
  });

  group('Screen smoke test', () {
    testWidgets('MusicPharmacyScreen builds with empty state if no sajuResult',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('ko'),
            home: const MusicPharmacyScreen(),
          ),
        ),
      );
      await tester.pump();
      // 가장 기본 — empty state 또는 loading 둘 중 하나는 builds.
      expect(find.byType(MusicPharmacyScreen), findsOneWidget);
    });
  });
}
