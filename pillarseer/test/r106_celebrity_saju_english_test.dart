// R106 P5 — 최애의 사주 / Bias Saju 영문 모드 가드.
//
// 검증 (mandate — 거짓말·창작 0 + 영어 leak 0):
//   1) celeb_saju_readings.json 는 valid JSON + _meta 보존.
//   2) 모든 셀럽 section 에 bodyEn 키가 존재 + 비어있지 않음 (210개).
//   3) bodyEn 에 한글(가-힣) 0 — 영어 모드에서 한국어 leak 금지.
//   4) bodyEn / bodyKo 모두에 시주/時柱/"birth time" 류 단정 0 — 출생 시(時)
//      누출 금지 (_meta.rules 준수).
//   5) bodyKo 는 모두 그대로 보존 (개수 = bodyEn 개수, 모두 비어있지 않음).
//   6) celebrity_saju_screen.dart 가 useKo 분기를 가짐 + 영어 모드 widget
//      렌더에 한글 라벨 leak 0.
//
// 이 테스트가 fail 하면 영어 모드에서 한국어가 새거나 출생 시(時) 단정이
// 침투한 것이다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/reports/celebrity_saju_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final hangul = RegExp('[가-힣]');

  // 출생 시(時) 단정 금지 표현 — ko/en 양쪽.
  const forbiddenHourTermsKo = <String>[
    '시주',
    '時柱',
    '태어난 시간',
    '태어난 시각',
    '출생 시간',
    '출생시간',
    '출생 시각',
  ];
  const forbiddenHourTermsEn = <String>[
    'hour pillar',
    'hour-pillar',
    'birth time',
    'birth hour',
    'time of birth',
    'born at',
  ];

  group('celeb_saju_readings.json — bodyEn 완비', () {
    late Map<String, dynamic> readings;

    setUpAll(() {
      final raw = File(
        'assets/data/celeb_saju_readings.json',
      ).readAsStringSync();
      readings = json.decode(raw) as Map<String, dynamic>;
    });

    test('valid JSON + _meta 보존', () {
      expect(readings.containsKey('_meta'), isTrue, reason: '_meta 누락');
      final meta = readings['_meta'] as Map<String, dynamic>;
      expect(meta.containsKey('schema'), isTrue);
      expect(meta.containsKey('rules'), isTrue);
    });

    test('모든 셀럽 section 에 bodyEn 존재 + 비어있지 않음 (210개)', () {
      var sectionCount = 0;
      var bodyEnCount = 0;
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        final sections = reading['sections'] as List;
        for (final s in sections) {
          final sec = s as Map<String, dynamic>;
          sectionCount++;
          expect(
            sec.containsKey('bodyEn'),
            isTrue,
            reason: '$id / ${sec['id']} — bodyEn 키 누락',
          );
          final en = (sec['bodyEn'] as String?)?.trim() ?? '';
          expect(en, isNotEmpty, reason: '$id / ${sec['id']} — bodyEn 비어있음');
          bodyEnCount++;
        }
      });
      expect(sectionCount, 210, reason: '셀럽 30 × 7섹션 = 210 기대');
      expect(bodyEnCount, 210, reason: 'bodyEn 210개 기대');
    });

    test('bodyEn 에 한글(가-힣) 0 — 영어 모드 leak 금지', () {
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        for (final s in reading['sections'] as List) {
          final sec = s as Map<String, dynamic>;
          final en = sec['bodyEn'] as String;
          expect(
            hangul.hasMatch(en),
            isFalse,
            reason: '$id / ${sec['id']} — bodyEn 에 한글 leak',
          );
        }
      });
    });

    test('bodyKo 모두 보존 + 비어있지 않음', () {
      var bodyKoCount = 0;
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        for (final s in reading['sections'] as List) {
          final sec = s as Map<String, dynamic>;
          final ko = (sec['bodyKo'] as String?)?.trim() ?? '';
          expect(ko, isNotEmpty, reason: '$id / ${sec['id']} — bodyKo 비어있음');
          bodyKoCount++;
        }
      });
      expect(bodyKoCount, 210, reason: 'bodyKo 210개 보존 기대');
    });

    test('bodyEn 에 화자·주체로서의 "chart" 노출 0 (v5 메타 금지)', () {
      // bodyEn 본문은 "chart" 를 화자/주체/대상으로 노출하면 안 된다.
      // JSON 키 "chart" 와 무관 — bodyEn 문자열 안의 chart 단어만 검사.
      final chartWord = RegExp(r'\bchart', caseSensitive: false);
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        for (final s in reading['sections'] as List) {
          final sec = s as Map<String, dynamic>;
          final en = sec['bodyEn'] as String;
          expect(
            chartWord.hasMatch(en),
            isFalse,
            reason: '$id / ${sec['id']} — bodyEn 에 "chart" 노출',
          );
        }
      });
    });

    test('bodyEn 에 흐름·감정 절대 단정(never/always) 0', () {
      final absolute = RegExp(r'\b(never|always)\b', caseSensitive: false);
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        for (final s in reading['sections'] as List) {
          final sec = s as Map<String, dynamic>;
          final en = sec['bodyEn'] as String;
          expect(
            absolute.hasMatch(en),
            isFalse,
            reason: '$id / ${sec['id']} — bodyEn 에 절대 단정(never/always)',
          );
        }
      });
    });

    test('bodyEn / bodyKo 에 출생 시(時) 단정 0', () {
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        for (final s in reading['sections'] as List) {
          final sec = s as Map<String, dynamic>;
          final ko = sec['bodyKo'] as String;
          final en = sec['bodyEn'] as String;
          for (final term in forbiddenHourTermsKo) {
            expect(
              ko.contains(term),
              isFalse,
              reason: '$id / ${sec['id']} — bodyKo 에 시주 단정 "$term"',
            );
          }
          for (final term in forbiddenHourTermsEn) {
            expect(
              en.toLowerCase().contains(term),
              isFalse,
              reason: '$id / ${sec['id']} — bodyEn 에 시주 단정 "$term"',
            );
          }
        }
      });
    });

    test('chart.hourPillar 는 항상 null (時柱 미생성)', () {
      readings.forEach((id, value) {
        if (id == '_meta') return;
        final reading = value as Map<String, dynamic>;
        final chart = reading['chart'] as Map<String, dynamic>;
        expect(
          chart['hourPillar'],
          isNull,
          reason: '$id — hourPillar 가 null 이 아님',
        );
      });
    });
  });

  group('celebrity_saju_screen.dart — useKo 분기 source 가드', () {
    final src = File(
      'lib/screens/reports/celebrity_saju_screen.dart',
    ).readAsStringSync();

    test('useKo 분기 존재 + locale 기반', () {
      expect(
        src.contains("Localizations.localeOf(context).languageCode == 'ko'"),
        isTrue,
        reason: 'useKo 가 locale 에서 파생되지 않음',
      );
      // 본문이 ko/en 분기.
      expect(src.contains('bodyEn'), isTrue, reason: 'bodyEn wire 누락');
      expect(src.contains('body(useKo)'), isTrue);
    });

    test('영문 모드 라벨 — 7섹션 영문 매핑 존재', () {
      for (final label in const [
        'FIRST IMPRESSION',
        'CORE OF THE DAY PILLAR',
        'MONTH & YEAR FRAME',
        'FLOW OF THE TEN GODS',
        'TRACE LEFT IN THE CHART',
        'A WORD FOR FANS',
        'CLOSING',
      ]) {
        expect(src.contains("'$label'"), isTrue, reason: '영문 라벨 $label 누락');
      }
    });

    test('시주 칸은 영어 모드에서도 "—" 고정', () {
      // ko / en 두 형태 모두 pillar 가 "—".
      expect(
        src.contains("_PillarChip(label: '시주', pillar: '—'"),
        isTrue,
        reason: '한국어 시주 칸 "—" 고정 누락',
      );
      expect(
        src.contains("_PillarChip(label: 'HOUR', pillar: '—'"),
        isTrue,
        reason: '영어 HOUR 칸 "—" 고정 누락',
      );
    });
  });

  // ── 영어 모드 사용자 노출 라벨이 모두 useKo 분기를 갖는지 — 위젯 빌더 본문의
  //    한국어 UI 리터럴을 표적으로 검사한다. (build() ~ '// model + helpers'
  //    경계 위쪽 = 위젯 영역. const lookup map 은 그 아래라 제외된다.) ──
  group('celebrity_saju_screen.dart — 위젯 영역 한국어 UI 리터럴 useKo 가드', () {
    final src = File(
      'lib/screens/reports/celebrity_saju_screen.dart',
    ).readAsStringSync();

    test('위젯 영역의 한국어 UI 리터럴은 모두 useKo 분기 안에 위치', () {
      // 위젯 영역 = 파일 시작 ~ 'model + helpers' 구분선. 그 아래는 const
      // 데이터 맵(_ganKo / _jiKo / _sectionLabelKo 등)이라 callers 가 useKo
      // 로 분기하므로 검사 대상에서 제외한다.
      final boundary = src.indexOf('// ─────────────────'
          ' model + helpers ─────────────────');
      expect(boundary, greaterThan(0), reason: 'model + helpers 경계 누락');
      final widgetArea = src.substring(0, boundary);
      final lines = widgetArea.split('\n');
      final offenders = <int>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        // 순수 주석 라인 제외.
        if (trimmed.startsWith('//')) continue;
        // string literal 안 한글만 본다 (따옴표가 있는 라인).
        if (!hangul.hasMatch(line)) continue;
        if (!line.contains("'")) continue;
        // 인접 ±2줄 안에 useKo 가 있으면 분기된 것으로 간주
        // (삼항 분기 / if(useKo) / 멀티라인 string 모두 포괄).
        var branched = false;
        for (var j = i - 2; j <= i + 2; j++) {
          if (j < 0 || j >= lines.length) continue;
          if (lines[j].contains('useKo')) {
            branched = true;
            break;
          }
        }
        if (!branched) offenders.add(i + 1);
      }
      expect(
        offenders,
        isEmpty,
        reason: 'useKo 분기 밖 한국어 UI 리터럴 라인: $offenders',
      );
    });

    test('영문 모드 helper — displayName / dayMasterEn / dayElementEn 존재', () {
      expect(src.contains('String displayName(bool useKo)'), isTrue);
      expect(src.contains('dayMasterEn'), isTrue);
      expect(src.contains('dayElementEn'), isTrue);
      expect(src.contains('_pillarRomanFromHanja'), isTrue);
    });
  });

  // ── widget 첫 frame 가드 — bootstrap 비동기 IO 는 frame pump 만으로 안 풀려
  //    (r105 와 동일 사유), 여기서는 첫 frame 안정성만 확인한다. ──
  Widget host(Locale locale) {
    final router = GoRouter(
      initialLocation: '/reports/celebrity-saju',
      routes: [
        GoRoute(
          path: '/reports/celebrity-saju',
          builder: (c, s) => const CelebritySajuScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (c, s) => const Scaffold(body: Text('reports-home')),
        ),
        GoRoute(
          path: '/home',
          builder: (c, s) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/today',
          builder: (c, s) => const Scaffold(body: Text('today')),
        ),
        GoRoute(
          path: '/settings',
          builder: (c, s) => const Scaffold(body: Text('settings')),
        ),
      ],
    );
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: locale,
      ),
    );
  }

  /// 화면에 mount 된 모든 Text 의 한글 여부를 모은다.
  List<String> hangulTexts(WidgetTester tester) {
    final out = <String>[];
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final data = w.data;
      if (data != null && hangul.hasMatch(data)) out.add(data);
    }
    return out;
  }

  group('CelebritySajuScreen — widget 첫 frame', () {
    testWidgets('영어 로케일 — appBar 영문 타이틀 + spinner + 한글 leak 0', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Locale('en')));
      await tester.pump();
      // appBar 영문 타이틀 (loading state 에서도 항상 mount).
      expect(find.text('BIAS SAJU'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 첫 frame 에 노출된 Text 중 한글 0.
      final leaked = hangulTexts(tester);
      expect(leaked, isEmpty, reason: '영어 모드 첫 frame 한글 leak: $leaked');
    });

    testWidgets('한국어 로케일 — 한국어 appBar 타이틀 정상 노출', (tester) async {
      await tester.pumpWidget(host(const Locale('ko')));
      await tester.pump();
      expect(find.text('최애의 사주'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
