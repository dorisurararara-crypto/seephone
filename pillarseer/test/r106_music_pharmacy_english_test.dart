// R106 P5 — 디지털 기운 처방전 (음악 처방) 영어 모드 가드.
//
// 문제: music_pharmacy 화면이 100% 한국어 — useKo 분기 0개. 영어 모드에서
// UI 라벨·본문(effect/sideEffect/dosage/prescriptionText/celebName/songTitle)이
// 전부 한국어로 샌다.
//
// 검증:
//   1) MusicPrescription 영어 carrier 필드 완비 (elementEn / celebNameEn /
//      songTitleEn / songArtistEn / effectEn / sideEffectEn / dosageEn /
//      prescriptionTextEn).
//   2) 영어 carrier 에 한글(가-힣) 0 — 단, songTitleEn/songArtistEn 은 매핑
//      미존재 시 KO 유지 정책이므로 본문/pool 만 strict 가드.
//   3) prescriptionTextEn = v5 voice — 단정 금지 표현 / 메타 금지(chart 는 허용).
//   4) screen 영어 모드 렌더 — 화면 UI 라벨에 한글 0, useKo 분기 동작.
//   5) screen 한국어 모드 렌더 — 기존 한국어 그대로 (회귀 0).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/providers/premium_provider.dart';
import 'package:pillarseer/providers/saju_provider.dart';
import 'package:pillarseer/screens/reports/music_pharmacy_screen.dart';
import 'package:pillarseer/services/music_pharmacy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hangul = RegExp(r'[가-힣]');

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

  final deficitCases = <(String, int, int, int, int, int)>[
    ('wood', 5, 25, 25, 25, 20),
    ('fire', 25, 5, 25, 25, 20),
    ('earth', 25, 25, 5, 25, 20),
    ('metal', 25, 25, 25, 5, 20),
    ('water', 25, 25, 25, 20, 5),
  ];

  group('MusicPrescription — 영어 carrier 완비', () {
    test('영어 필드 모두 non-empty', () {
      for (final c in deficitCases) {
        final (label, w, f, e, m, wa) = c;
        for (var seed = 1; seed <= 6; seed++) {
          final p = MusicPharmacyService.prescribeSync(
              user: makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
              userName: 'Mina',
              seed: seed);
          expect(p, isNotNull, reason: '$label seed=$seed null');
          expect(p!.elementEn.isNotEmpty, isTrue, reason: '$label elementEn');
          expect(p.celebNameEn.isNotEmpty, isTrue,
              reason: '$label celebNameEn');
          expect(p.songTitleEn.isNotEmpty, isTrue, reason: '$label songTitleEn');
          expect(p.songArtistEn.isNotEmpty, isTrue,
              reason: '$label songArtistEn');
          expect(p.effectEn.isNotEmpty, isTrue, reason: '$label effectEn');
          expect(p.sideEffectEn.isNotEmpty, isTrue,
              reason: '$label sideEffectEn');
          expect(p.dosageEn.isNotEmpty, isTrue, reason: '$label dosageEn');
          expect(p.prescriptionTextEn.isNotEmpty, isTrue,
              reason: '$label prescriptionTextEn');
        }
      }
    });

    test('영어 필드 != 한국어 필드 (실제 번역됨)', () {
      final p = MusicPharmacyService.prescribeSync(
          user: makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20),
          userName: 'Mina',
          seed: 3)!;
      expect(p.elementEn, isNot(equals(p.elementKo)));
      expect(p.effectEn, isNot(equals(p.effectKo)));
      expect(p.sideEffectEn, isNot(equals(p.sideEffectKo)));
      expect(p.dosageEn, isNot(equals(p.dosageKo)));
      expect(p.prescriptionTextEn, isNot(equals(p.prescriptionText)));
    });

    test('한국어 필드 보존 (회귀 0) — 기존 KO carrier 그대로', () {
      final p = MusicPharmacyService.prescribeSync(
          user: makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20),
          userName: '미나',
          seed: 3)!;
      expect(p.prescriptionText.contains('효능'), isTrue);
      expect(p.prescriptionText.contains('부작용'), isTrue);
      expect(p.prescriptionText.contains('복용법'), isTrue);
      expect(p.effectKo.isNotEmpty, isTrue);
    });
  });

  group('영어 carrier — 한글 leak 0 가드', () {
    test('elementEn / effectEn / sideEffectEn / dosageEn 에 한글 0', () {
      for (final c in deficitCases) {
        final (label, w, f, e, m, wa) = c;
        for (var seed = 1; seed <= 8; seed++) {
          final p = MusicPharmacyService.prescribeSync(
              user: makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
              userName: 'Mina',
              seed: seed)!;
          expect(hangul.hasMatch(p.elementEn), isFalse,
              reason: '$label elementEn 한글 leak: ${p.elementEn}');
          expect(hangul.hasMatch(p.effectEn), isFalse,
              reason: '$label effectEn 한글 leak: ${p.effectEn}');
          expect(hangul.hasMatch(p.sideEffectEn), isFalse,
              reason: '$label sideEffectEn 한글 leak: ${p.sideEffectEn}');
          expect(hangul.hasMatch(p.dosageEn), isFalse,
              reason: '$label dosageEn 한글 leak: ${p.dosageEn}');
          expect(hangul.hasMatch(p.celebNameEn), isFalse,
              reason: '$label celebNameEn 한글 leak: ${p.celebNameEn}');
        }
      }
    });

    test('prescriptionTextEn 본문 한글 leak 0 (전 5행 × 8 seed)', () {
      for (final c in deficitCases) {
        final (label, w, f, e, m, wa) = c;
        for (var seed = 1; seed <= 8; seed++) {
          final p = MusicPharmacyService.prescribeSync(
              user: makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
              userName: 'Mina',
              seed: seed)!;
          // celeb_songs.json 매핑 미존재 시 songTitleEn 만 KO 유지 정책 →
          // 본문에서 곡 제목 부분을 제외하고 한글 검사.
          final cleaned =
              p.prescriptionTextEn.replaceAll(p.songTitleEn, '');
          expect(hangul.hasMatch(cleaned), isFalse,
              reason: '$label seed=$seed prescriptionTextEn 한글 leak: '
                  '${p.prescriptionTextEn}');
        }
      }
    });

    test('곡 제목/아티스트 영어 매핑 — 실데이터 대부분 영어화 (창작 0 정책)', () {
      // 매핑 미존재면 KO 유지가 정책 — 그래도 실데이터에서 대다수는 매핑됨.
      var total = 0;
      var enTitle = 0;
      var enArtist = 0;
      for (final c in deficitCases) {
        final (_, w, f, e, m, wa) = c;
        for (var seed = 1; seed <= 30; seed++) {
          final p = MusicPharmacyService.prescribeSync(
              user: makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
              seed: seed);
          if (p == null) continue;
          total++;
          if (!hangul.hasMatch(p.songTitleEn)) enTitle++;
          if (!hangul.hasMatch(p.songArtistEn)) enArtist++;
        }
      }
      expect(total, greaterThan(0));
      // 아티스트는 전수 매핑 (57종) → 100% 영어.
      expect(enArtist, equals(total),
          reason: 'songArtistEn 일부 한글 leak: $enArtist/$total');
      // 곡 제목은 192종 매핑 → 거의 100%.
      expect(enTitle / total, greaterThanOrEqualTo(0.95),
          reason: 'songTitleEn 영어화율 낮음: $enTitle/$total');
    });
  });

  group('prescriptionTextEn — v5 voice (단정·메타 가드)', () {
    test('단정 금지 — can / tends / might 같은 조건형 포함', () {
      for (final c in deficitCases) {
        final (label, w, f, e, m, wa) = c;
        final p = MusicPharmacyService.prescribeSync(
            user: makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
            userName: 'Mina',
            seed: 2)!;
        final t = p.prescriptionTextEn.toLowerCase();
        final hasHedge = t.contains('can ') ||
            t.contains('tends') ||
            t.contains('might') ||
            t.contains('if ');
        expect(hasHedge, isTrue,
            reason: '$label prescriptionTextEn 조건형 없음 (단정조 의심): '
                '${p.prescriptionTextEn}');
      }
    });

    test('메타 금지 — saju 단어 노출 X (day pillar / element 는 허용)', () {
      for (final c in deficitCases) {
        final (label, w, f, e, m, wa) = c;
        for (var seed = 1; seed <= 6; seed++) {
          final p = MusicPharmacyService.prescribeSync(
              user: makeSaju(wood: w, fire: f, earth: e, metal: m, water: wa),
              userName: 'Mina',
              seed: seed)!;
          expect(p.prescriptionTextEn.toLowerCase().contains('saju'), isFalse,
              reason: '$label seed=$seed saju 메타 leak');
        }
      }
    });

    test('영어 본문에 셀럽·곡·효능·부작용·복용법 포함', () {
      final p = MusicPharmacyService.prescribeSync(
          user: makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20),
          userName: 'Mina',
          seed: 5)!;
      final t = p.prescriptionTextEn;
      final shortEn = p.celebNameEn.contains('(')
          ? p.celebNameEn.split('(').first.trim()
          : p.celebNameEn;
      expect(t.contains(shortEn), isTrue, reason: 'celeb 누락: $t');
      expect(t.contains(p.songTitleEn), isTrue, reason: 'song 누락: $t');
      expect(t.contains(p.effectEn), isTrue, reason: 'effect 누락: $t');
      expect(t.contains(p.sideEffectEn), isTrue, reason: 'side 누락: $t');
      expect(t.contains(p.dosageEn), isTrue, reason: 'dosage 누락: $t');
    });

    test('userName null → 영어 본문 "you" 사용', () {
      final p = MusicPharmacyService.prescribeSync(
          user: makeSaju(wood: 25, fire: 5, earth: 25, metal: 25, water: 20),
          userName: null,
          seed: 7)!;
      expect(p.prescriptionTextEn.contains('you'), isTrue,
          reason: 'you 누락: ${p.prescriptionTextEn}');
    });
  });

  group('seed determinism — 영어 carrier', () {
    test('같은 seed → 같은 영어 처방', () {
      final user = makeSaju(wood: 20, fire: 5, earth: 25, metal: 25, water: 25);
      final a = MusicPharmacyService.prescribeSync(user: user, seed: 42)!;
      final b = MusicPharmacyService.prescribeSync(user: user, seed: 42)!;
      expect(a.songTitleEn, equals(b.songTitleEn));
      expect(a.effectEn, equals(b.effectEn));
      expect(a.sideEffectEn, equals(b.sideEffectEn));
      expect(a.dosageEn, equals(b.dosageEn));
      expect(a.prescriptionTextEn, equals(b.prescriptionTextEn));
    });
  });

  group('Screen — 영어 모드 useKo 분기', () {
    Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
      // 처방 카드 + 버튼 모두 한 화면에 들어오도록 surface 를 충분히 크게.
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // R110 Sprint 2 — 효능/부작용/복용법/다시 처방은 프리미엄 게이트 뒤.
      // 영어/한글 라벨 회귀를 보려면 unlocked 상태에서 검증한다.
      final container = ProviderContainer(
        overrides: [isPremiumUnlockedProvider.overrideWithValue(true)],
      );
      container.read(sajuResultProvider.notifier).set(_buildSaju());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: locale,
            home: const MusicPharmacyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('영어 모드 — 화면 UI 라벨에 한글 0', (tester) async {
      await pumpScreen(tester, const Locale('en'));

      // 처방 카드의 라벨/본문 텍스트 위젯 전수 — 한글 0.
      final texts = tester.widgetList<Text>(find.byType(Text));
      final leaks = <String>[];
      for (final t in texts) {
        final s = t.data ?? '';
        if (hangul.hasMatch(s)) leaks.add(s);
      }
      expect(leaks, isEmpty,
          reason: '영어 모드 화면 한글 leak: $leaks');

      // 영어 UI 라벨 존재 확인.
      expect(find.text('EFFECT'), findsOneWidget);
      expect(find.text('SIDE EFFECT'), findsOneWidget);
      expect(find.text('DOSAGE'), findsOneWidget);
      expect(find.text('PRESCRIBED'), findsOneWidget);
      expect(find.text('Get another'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('한국어 모드 — 한국어 라벨 그대로 (회귀 0)', (tester) async {
      await pumpScreen(tester, const Locale('ko'));

      expect(find.text('효능'), findsOneWidget);
      expect(find.text('부작용'), findsOneWidget);
      expect(find.text('복용법'), findsOneWidget);
      expect(find.text('처방 항목'), findsOneWidget);
      expect(find.text('다시 처방 받기'), findsOneWidget);
      expect(find.text('공유'), findsOneWidget);
    });
  });
}

/// 화면 smoke 용 — fire deficit 사주.
SajuResult _buildSaju() {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '癸', jiJi: '卯'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
    dayPillar: const Pillar(chunGan: '戊', jiJi: '寅'),
    hourPillar: const Pillar(chunGan: '己', jiJi: '未'),
    elements: FiveElements(
      wood: 25,
      fire: 5,
      earth: 25,
      metal: 25,
      water: 20,
    ),
    dayMaster: '戊',
    dayMasterName: 'Test',
    summary: 'test',
    categoryReadings: const {},
  );
}
