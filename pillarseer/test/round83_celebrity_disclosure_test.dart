// Round 83 sprint 3 — Discover 셀럽 출생정보 신뢰도 라벨 (P1-F) 회귀 가드.
//
// 사용자 verbatim mapping (R83 backlog P1-F + 외부 reviewer 권고):
//   "유명인의 출생시간은 대체로 공개되지 않기 때문에 시주를 쓰면 위험. 셀럽 비교에는
//    반드시 '출생시간 미상 기준, 공개 생일 기반의 가벼운 비교' 라고 표시."
//
// ── Sprint 계약 = testable 4 행동 ──
//   행동 1 = Discover 화면 첫 fold (filter chip 위) 영역에 disclaimer banner 1회
//     mount — celebDisclosureBanner + celebDisclosureBannerHelper text 둘 다 노출.
//   행동 2 = 셀럽 카드 widget 안에 celebCardConfidenceLabel 1줄이 카드마다 mount
//     (`Key('discover_celeb_confidence_label_<idx>')`).
//   행동 3 = 신규 arb key 3종 (celebDisclosureBanner, celebDisclosureBannerHelper,
//     celebCardConfidenceLabel) 이 ko + en 둘 다 존재 + 빈 값 X + generated
//     getter 존재 + 한자 jargon / AI 슬롭 / 의료 단정 / 자미두수 별 이름 leak 0.
//   행동 4 = celebrities.json 데이터 schema 보존 — entry 수 207 (R84 sprint 1
//     셀럽 확장: 62 baseline + 28 K-pop idol 추가 = 90 + sprint 1b STAYC 6명
//     = 96 + sprint 1c 한류 배우 12명 = 108 + sprint 1d NMIXX +6 = 114 +
//     sprint 1e SEVENTEEN +8 = 122 + sprint 1f RIIZE +4 + LE SSERAFIM +1 +
//     i-dle +5 = 132 + sprint 1g BABYMONSTER +7 + ILLIT +5 = 144 +
//     sprint 1h KISS OF LIFE +4 = 148 + sprint 1i ZEROBASEONE +5 = 153 +
//     sprint 1i ext ZEROBASEONE 잔여 +4 = 157 + sprint 1j BOYNEXTDOOR +6
//     (Sungho / Riwoo / Jaehyun / Taesan / Leehan / Woonhak) = 163 +
//     sprint 1k TWS +6 (Shinyu / Dohoon / Youngjae / Hanjin / Jihoon /
//     Kyungmin) = 169 + sprint 1l NCT DREAM +7 (Mark / Renjun / Jeno /
//     Haechan / Jaemin / Chenle / Jisung) = 176 + sprint 1m NCT WISH +6
//     (Sion / Riku / Yushi / Jaehee / Ryo / Sakuya) = 182 + sprint 1n XG +7
//     (Jurin / Chisa / Hinata / Harvey / Juria / Maya / Cocona) = 189 +
//     sprint 1o KATSEYE +6 (Sophia / Manon / Daniela / Lara / Megan /
//     Yoonchae) = 195 + sprint 1p Red Velvet +5 (Irene / Seulgi / Wendy /
//     Joy / Yeri) + MAMAMOO +3 (Solar / Moonbyul / Wheein) + solo +4
//     (Jeon Somi / Chungha / Sunmi / Kwon Eunbi) = 207 + sprint 1q TREASURE
//     +10 (Choi Hyunsuk / Jihoon / Yoshi / Junkyu / Jaehyuk / Asahi /
//     Doyoung / Haruto / Park Jeongwoo / Junghwan) = 217) + 각 entry key 10개
//     (id, nameEn, nameKo, kind, birth, dayPillar, dayPillarName, blurbEn,
//     blurbKo, gender) baseline 보존 (라벨 widget 추가는 widget level 만 허용).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/screens/discover_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R83 sprint 3 — 셀럽 출생정보 신뢰도 라벨 (P1-F)', () {
    const newArbKeys = <String>[
      'celebDisclosureBanner',
      'celebDisclosureBannerHelper',
      'celebCardConfidenceLabel',
    ];

    // ── 공용 widget pump scaffold ──
    // `_DiscoverScreen` 은 rootBundle.loadString('assets/data/celebrities.json')
    // 호출. test 환경의 rootBundle 은 AssetManifest 부재 → 빈 list fallback.
    // 행동 2 검증을 위해 DefaultAssetBundle 을 file 시스템 fixture bundle 로
    // override. discover_screen 내부의 rootBundle.loadString 가 DefaultAssetBundle.of
    // 를 직접 사용하지 X 이므로, `_load()` 함수 catch 가 빈 list 로 fallback —
    // 행동 1 (banner) 은 셀럽 0개여도 mount, 행동 2 는 _TestFixtureCelebrities
    // 데이터를 router 의 별도 fixture screen 으로 검증.
    Widget discoverScaffold() {
      final router = GoRouter(
        initialLocation: '/reports/discover',
        routes: [
          GoRoute(
            path: '/reports/discover',
            builder: (c, s) => const DiscoverScreen(),
          ),
          // Fallback routes (PillarBottomNav 가 push 할 수 있는 곳).
          GoRoute(
            path: '/reports',
            builder: (c, s) => const Scaffold(body: Text('reports')),
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
          locale: const Locale('ko'),
        ),
      );
    }

    // ── 행동 1 — disclaimer banner mount (widget pump) ──
    // test 환경의 rootBundle 은 assets/data/celebrities.json 을 로딩할 수 없어
    // _DiscoverScreen 의 `catch (_) { _loaded = true; }` fallback → 빈 list.
    // 빈 list 에서도 disclaimer banner 는 filter chip 위 (`first-fold`) 영역이라
    // mount 됨 → 행동 1 widget pump 로 검증 가능.
    testWidgets('행동1.B1 — Discover 화면 disclaimer banner 1회 mount + helper 노출', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(discoverScaffold());
      // pumpAndSettle 은 _load() async 가 끝나야 settle. setState 이후 1프레임만
      // pump 하고 종료 (banner 는 _loaded 와 무관하므로 첫 build 에서 이미 mount).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // disclaimer banner key 1회 mount.
      expect(
        find.byKey(const Key('discover_celeb_disclosure_banner')),
        findsOneWidget,
        reason: 'disclaimer banner key 미발견 (first-fold 마운트 누락)',
      );

      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      final banner = ko['celebDisclosureBanner'] as String;
      final helper = ko['celebDisclosureBannerHelper'] as String;
      // 본문 text 둘 다 노출.
      expect(
        find.text(banner),
        findsWidgets,
        reason: 'celebDisclosureBanner 본문 노출 누락: "$banner"',
      );
      expect(
        find.text(helper),
        findsWidgets,
        reason: 'celebDisclosureBannerHelper 본문 노출 누락: "$helper"',
      );
    });

    // ── 행동 2 — 카드별 confidence label widget wire (소스 정적 검증) ──
    // test 환경에서 rootBundle 의 celebrities.json 로딩이 차단되어 (asset
    // manifest 부재) 카드 widget pump 검증이 불가능. 대신 discover_screen.dart
    // 소스에서 confidence label widget 의 5가지 핵심 요소가 모두 wire 되어
    // 있는지 정적 검증.
    test('행동2.B2 — _CelebRow 안에 celebCardConfidenceLabel widget wire 확인', () {
      final src = File('lib/screens/discover_screen.dart').readAsStringSync();
      // (1) confidence label key naming 패턴.
      expect(
        src.contains("Key('discover_celeb_confidence_label_"),
        isTrue,
        reason:
            '카드별 confidence label key 미정의 (discover_celeb_confidence_label_*)',
      );
      // (2) listIndex 가 _CelebRow constructor 인자.
      expect(
        src.contains('required this.listIndex'),
        isTrue,
        reason: '_CelebRow constructor 에 listIndex 인자 누락',
      );
      // (3) listIndex 가 itemBuilder 에서 wire.
      expect(
        src.contains('listIndex: i'),
        isTrue,
        reason: 'itemBuilder 에서 listIndex 전달 누락',
      );
      // (4) celebCardConfidenceLabel getter 사용.
      expect(
        src.contains('l.celebCardConfidenceLabel'),
        isTrue,
        reason: 'l.celebCardConfidenceLabel getter 호출 누락',
      );
      // (5) disclaimer banner widget 안 celebDisclosureBanner + helper 둘 다 wire.
      expect(
        src.contains('l.celebDisclosureBanner'),
        isTrue,
        reason: 'l.celebDisclosureBanner getter 호출 누락',
      );
      expect(
        src.contains('l.celebDisclosureBannerHelper'),
        isTrue,
        reason: 'l.celebDisclosureBannerHelper getter 호출 누락',
      );
    });

    // ── 행동 3 — 신규 arb key 존재 + slop / jargon / 자미두수 leak 0 ──
    test('행동3.B3 — 신규 arb key 가 ko + en 둘 다 존재 + 빈 값 X', () {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final k in newArbKeys) {
        expect(ko.containsKey(k), isTrue, reason: 'app_ko.arb 에 key "$k" 누락');
        expect(en.containsKey(k), isTrue, reason: 'app_en.arb 에 key "$k" 누락');
        expect(
          (ko[k] as String).isNotEmpty,
          isTrue,
          reason: 'app_ko.arb["$k"] 빈 값',
        );
        expect(
          (en[k] as String).isNotEmpty,
          isTrue,
          reason: 'app_en.arb["$k"] 빈 값',
        );
      }
    });

    test('행동3.B3b — generated app_localizations.dart 에 신규 getter 존재', () {
      final src = File('lib/l10n/app_localizations.dart').readAsStringSync();
      for (final k in newArbKeys) {
        expect(
          src.contains('String get $k'),
          isTrue,
          reason: 'app_localizations.dart 에 getter $k 누락',
        );
      }
    });

    test('행동3.B3c — ko 본문에 한자 jargon noun blacklist 0', () {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      const jargonBlacklist = <String>['본질', '정수', '운기', '운명'];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final jargon in jargonBlacklist) {
          expect(
            v.contains(jargon),
            isFalse,
            reason: 'arb key "$k" 의 ko value 에 한자 jargon "$jargon" 노출: "$v"',
          );
        }
      }
    });

    test('행동3.B3d — ko 본문에 AI 슬롭 / Apologetic AI 패턴 0', () {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      const slopBlacklist = <String>[
        '죄송하지만',
        '단정 짓기 어렵',
        '말씀드리기 어렵',
        '센터처럼',
        '본인의 결',
        '벼린 칼',
        '도검의 끝',
      ];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final slop in slopBlacklist) {
          expect(
            v.contains(slop),
            isFalse,
            reason: 'arb key "$k" 의 ko value 에 AI 슬롭 "$slop" 노출: "$v"',
          );
        }
      }
    });

    test('행동3.B3e — ko 본문에 의료 단정 phrase 0', () {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      const medicalBlacklist = <String>['진단', '치료해', '병원 가야', '약 먹어야'];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final med in medicalBlacklist) {
          expect(
            v.contains(med),
            isFalse,
            reason: 'arb key "$k" 의 ko value 에 의료 단정 "$med" 노출: "$v"',
          );
        }
      }
    });

    test('행동3.B3f — ko 본문에 자미두수 별 nameKo 0 (R70 mandate)', () {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      const starNamesKo = <String>[
        '자미성',
        '천기성',
        '태양성',
        '무곡성',
        '천동성',
        '염정성',
        '천부성',
        '태음성',
        '탐랑성',
        '거문성',
        '천상성',
        '천량성',
        '칠살성',
        '파군성',
        '문창성',
        '문곡성',
        '천괴성',
        '천월성',
        '좌보성',
        '우필성',
        '녹존성',
        '천마성',
      ];
      for (final k in newArbKeys) {
        final v = (ko[k] as String?) ?? '';
        for (final star in starNamesKo) {
          expect(
            v.contains(star),
            isFalse,
            reason:
                'R70 mandate 위반: arb key "$k" 의 ko value 에 자미두수 별 이름 "$star" leak: "$v"',
          );
        }
      }
    });

    test('행동3.B3g — ko 본문에 "출생시간 미상" 핵심 carve-out phrase 존재', () {
      // 외부 reviewer 권고의 핵심 핵심: "출생시간 미상" / "공개 생일 기반" 단어 둘 다
      // 사용자에게 transparent. arb 본문 합쳐서 두 phrase 모두 출현 확인.
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
              as Map<String, dynamic>;
      final blob = newArbKeys.map((k) => ko[k] as String? ?? '').join('\n');
      expect(
        blob.contains('출생시간 미상'),
        isTrue,
        reason: '"출생시간 미상" carve-out phrase 누락',
      );
      expect(
        blob.contains('공개 생일'),
        isTrue,
        reason: '"공개 생일" carve-out phrase 누락',
      );
    });

    // ── 행동 4 — celebrities.json 데이터 schema 보존 + R84 sprint 1 확장 ──
    // R84 sprint 1g — BABYMONSTER +7 (Ruka / Pharita / Asa / Ahyeon / Rami /
    // Rora / Chiquita) + ILLIT +5 (Yunah / Minju / Moka / Wonhee / Iroha)
    // 추가로 entry 수 baseline = 132 + 12 = 144.
    // R84 sprint 1h — KISS OF LIFE +4 (Julie / Natty / Belle / Haneul) 추가로
    // entry 수 baseline = 144 + 4 = 148.
    // R84 sprint 1i — ZEROBASEONE +5 (Sung Hanbin / Kim Jiwoong / Zhang Hao /
    // Seok Matthew / Kim Taerae) 추가로 entry 수 baseline = 148 + 5 = 153.
    // R84 sprint 1i ext — ZEROBASEONE 잔여 +4 (Kim Gyuvin / Park Gunwook /
    // Han Yujin / Ricky) 추가로 entry 수 baseline = 153 + 4 = 157
    // (제로베이스원 9인 전원 커버 완성).
    // R84 sprint 1j — BOYNEXTDOOR +6 (Sungho / Riwoo / Jaehyun / Taesan /
    // Leehan / Woonhak) 추가로 entry 수 baseline = 157 + 6 = 163.
    // R84 sprint 1k — TWS +6 (Shinyu / Dohoon / Youngjae / Hanjin / Jihoon /
    // Kyungmin) 추가로 entry 수 baseline = 163 + 6 = 169.
    // R84 sprint 1l — NCT DREAM +7 (Mark / Renjun / Jeno / Haechan / Jaemin /
    // Chenle / Jisung) 추가로 entry 수 baseline = 169 + 7 = 176.
    // R84 sprint 1m — NCT WISH +6 (Sion / Riku / Yushi / Jaehee / Ryo /
    // Sakuya) 추가로 entry 수 baseline = 176 + 6 = 182.
    // R84 sprint 1n — XG +7 (Jurin / Chisa / Hinata / Harvey / Juria / Maya /
    // Cocona) 추가로 entry 수 baseline = 182 + 7 = 189.
    // R84 sprint 1o — KATSEYE +6 (Sophia / Manon / Daniela / Lara / Megan /
    // Yoonchae) 추가로 entry 수 baseline = 189 + 6 = 195.
    // R84 sprint 1p — Red Velvet +5 (Irene / Seulgi / Wendy / Joy / Yeri) +
    // MAMAMOO +3 (Solar / Moonbyul / Wheein) + solo +4 (Jeon Somi / Chungha /
    // Sunmi / Kwon Eunbi) 추가로 entry 수 baseline = 195 + 12 = 207.
    // R84 sprint 1q — TREASURE +10 (Choi Hyunsuk / Jihoon / Yoshi / Junkyu /
    // Jaehyuk / Asahi / Doyoung / Haruto / Park Jeongwoo / Junghwan) 추가로
    // entry 수 baseline = 207 + 10 = 217.
    // R84 sprint 1r — P1Harmony +6 (Keeho / Theo / Jiung / Intak / Soul /
    // Jongseob) 추가로 entry 수 baseline = 217 + 6 = 223.
    test('행동4.B4 — celebrities.json schema 보존 (entry 223 + key 10/entry)', () {
      final raw = File('assets/data/celebrities.json').readAsStringSync();
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      expect(
        data.length,
        223,
        reason:
            'celebrities.json entry 수 위반 (R84 sprint 1r baseline = 217 + P1Harmony 6 = 223, 실제 ${data.length})',
      );
      // baseline schema = 정확히 10 key (R84 확장 시에도 schema 동일 유지).
      const baselineKeys = <String>{
        'id',
        'nameEn',
        'nameKo',
        'kind',
        'birth',
        'dayPillar',
        'dayPillarName',
        'blurbEn',
        'blurbKo',
        'gender',
      };
      for (var i = 0; i < data.length; i++) {
        final entry = data[i];
        expect(
          entry.keys.toSet(),
          baselineKeys,
          reason:
              'celebrities.json[$i] key schema baseline 위반 (라벨 추가는 widget level 만 허용)',
        );
      }
    });

    // ── 행동 4b — R84 sprint 1 셀럽 확장: 28 K-pop idol 추가 검증 ──
    test('행동4.B4b — R84 sprint 1 신규 28 idol id + dayPillar 스팟체크', () {
      final raw = File('assets/data/celebrities.json').readAsStringSync();
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      const newIds = <String>[
        'rm',
        'suga',
        'jhope',
        'jimin',
        'bangchan_skz',
        'leeknow_skz',
        'changbin_skz',
        'han_skz',
        'felix_skz',
        'seungmin_skz',
        'in_skz',
        'hongjoong_atz',
        'seonghwa_atz',
        'yunho_atz',
        'yeosang_atz',
        'san_atz',
        'mingi_atz',
        'wooyoung_atz',
        'jongho_atz',
        'nayeon_twice',
        'jeongyeon_twice',
        'momo_twice',
        'sana_twice',
        'jihyo_twice',
        'mina_twice',
        'dahyun_twice',
        'chaeyoung_twice',
        'tzuyu_twice',
      ];
      final byId = {for (final e in data) e['id'] as String: e};
      for (final id in newIds) {
        expect(
          byId.containsKey(id),
          isTrue,
          reason: 'R84 sprint 1 신규 idol id "$id" 누락',
        );
        final e = byId[id]!;
        expect(
          e['kind'],
          'idol',
          reason: 'R84 sprint 1 idol "$id" kind 가 "idol" 가 아님: ${e['kind']}',
        );
        expect(
          (e['blurbKo'] as String).isNotEmpty,
          isTrue,
          reason: 'R84 sprint 1 idol "$id" blurbKo 빈 값',
        );
        expect(
          (e['blurbEn'] as String).isNotEmpty,
          isTrue,
          reason: 'R84 sprint 1 idol "$id" blurbEn 빈 값',
        );
      }
      // dayPillar 스팟체크 (사용자 mandate 매핑 보존).
      expect(byId['rm']!['dayPillar'], '辛丑');
      expect(byId['jimin']!['dayPillar'], '丁未');
      expect(byId['felix_skz']!['dayPillar'], '丙子');
      expect(byId['hongjoong_atz']!['dayPillar'], '戊午');
      expect(byId['tzuyu_twice']!['dayPillar'], '丁酉');
      expect(byId['nayeon_twice']!['dayPillar'], '丙辰');
    });

    // ── 행동 4c — R84 sprint 1b STAYC 6명 확장 검증 ──
    // 사용자 mandate (R84 hand-off): STAYC 6 멤버 추가. dayPillar/dayPillarName 은
    // 앱 만세력 (klc) 계산값으로 wire — 본 테스트는 그 계산 결과의 회귀 가드.
    test(
      '행동4.B4c — R84 sprint 1b STAYC 6 멤버 확장 (id + birth + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const staycExpected = <String, Map<String, String>>{
          'sumin_stayc': {
            'nameEn': 'Sumin (STAYC)',
            'nameKo': '수민 (스테이씨)',
            'birth': '2001-03-13',
            'dayPillar': '乙亥',
            'dayPillarName': 'Wood Pig',
          },
          'sieun_stayc': {
            'nameEn': 'Sieun (STAYC)',
            'nameKo': '시은 (스테이씨)',
            'birth': '2001-08-01',
            'dayPillar': '丙申',
            'dayPillarName': 'Fire Monkey',
          },
          'isa_stayc': {
            'nameEn': 'Isa (STAYC)',
            'nameKo': '아이사 (스테이씨)',
            'birth': '2002-01-23',
            'dayPillar': '辛卯',
            'dayPillarName': 'Metal Rabbit',
          },
          'seeun_stayc': {
            'nameEn': 'Seeun (STAYC)',
            'nameKo': '세은 (스테이씨)',
            'birth': '2003-06-14',
            'dayPillar': '戊午',
            'dayPillarName': 'Earth Horse',
          },
          'yoon_stayc': {
            'nameEn': 'Yoon (STAYC)',
            'nameKo': '윤 (스테이씨)',
            'birth': '2004-04-14',
            'dayPillar': '癸巳',
            'dayPillarName': 'Water Snake',
          },
          'j_stayc': {
            'nameEn': 'J (STAYC)',
            'nameKo': '재이 (스테이씨)',
            'birth': '2004-12-09',
            'dayPillar': '壬戌',
            'dayPillarName': 'Water Dog',
          },
        };
        for (final entry in staycExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1b STAYC id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['kind'],
            'idol',
            reason: 'STAYC "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(
            e['gender'],
            'F',
            reason: 'STAYC "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(e['nameEn'], exp['nameEn'], reason: 'STAYC "$id" nameEn 불일치');
          expect(e['nameKo'], exp['nameKo'], reason: 'STAYC "$id" nameKo 불일치');
          expect(e['birth'], exp['birth'], reason: 'STAYC "$id" birth 불일치');
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'STAYC "$id" dayPillar 불일치 (앱 만세력 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'STAYC "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'STAYC "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'STAYC "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4d — R84 sprint 1c 한류 배우 12명 확장 검증 ──
    // 사용자 mandate (R84 hand-off): 글로벌 한류 배우 12명 추가. dayPillar/
    // dayPillarName 은 앱 만세력 (klc) 계산값으로 wire — 본 테스트는 그 계산
    // 결과의 회귀 가드. 모든 entry kind=actor, blurb 비어있지 않음, 출생시간/
    // hour 단정 0 (사용자 mandate "No birth-time/hour claims").
    test(
      '행동4.B4d — R84 sprint 1c 한류 배우 12 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const actorExpected = <String, Map<String, String>>{
          'kim-soohyun': {
            'nameEn': 'Kim Soo-hyun',
            'nameKo': '김수현',
            'birth': '1988-02-16',
            'gender': 'M',
            'dayPillar': '辛丑',
            'dayPillarName': 'Metal Ox',
          },
          'lee-minho': {
            'nameEn': 'Lee Min-ho',
            'nameKo': '이민호',
            'birth': '1987-06-22',
            'gender': 'M',
            'dayPillar': '壬寅',
            'dayPillarName': 'Water Tiger',
          },
          'cha-eunwoo': {
            'nameEn': 'Cha Eun-woo',
            'nameKo': '차은우',
            'birth': '1997-03-30',
            'gender': 'M',
            'dayPillar': '辛未',
            'dayPillarName': 'Metal Goat',
          },
          'song-kang': {
            'nameEn': 'Song Kang',
            'nameKo': '송강',
            'birth': '1994-04-23',
            'gender': 'M',
            'dayPillar': '己卯',
            'dayPillarName': 'Earth Rabbit',
          },
          'byeon-wooseok': {
            'nameEn': 'Byeon Woo-seok',
            'nameKo': '변우석',
            'birth': '1991-10-31',
            'gender': 'M',
            'dayPillar': '甲戌',
            'dayPillarName': 'Wood Dog',
          },
          'hwang-inyoup': {
            'nameEn': 'Hwang In-youp',
            'nameKo': '황인엽',
            'birth': '1991-01-19',
            'gender': 'M',
            'dayPillar': '己丑',
            'dayPillarName': 'Earth Ox',
          },
          'kim-seonho': {
            'nameEn': 'Kim Seon-ho',
            'nameKo': '김선호',
            'birth': '1986-05-08',
            'gender': 'M',
            'dayPillar': '壬子',
            'dayPillarName': 'Water Rat',
          },
          'ji-changwook': {
            'nameEn': 'Ji Chang-wook',
            'nameKo': '지창욱',
            'birth': '1987-07-05',
            'gender': 'M',
            'dayPillar': '乙卯',
            'dayPillarName': 'Wood Rabbit',
          },
          'kim-jiwon': {
            'nameEn': 'Kim Ji-won',
            'nameKo': '김지원',
            'birth': '1992-10-19',
            'gender': 'F',
            'dayPillar': '戊辰',
            'dayPillarName': 'Earth Dragon',
          },
          'kim-hyeyoon': {
            'nameEn': 'Kim Hye-yoon',
            'nameKo': '김혜윤',
            'birth': '1996-11-10',
            'gender': 'F',
            'dayPillar': '辛亥',
            'dayPillarName': 'Metal Pig',
          },
          'han-sohee': {
            'nameEn': 'Han So-hee',
            'nameKo': '한소희',
            'birth': '1993-11-18',
            'gender': 'F',
            'dayPillar': '癸卯',
            'dayPillarName': 'Water Rabbit',
          },
          'bae-suzy': {
            'nameEn': 'Bae Suzy',
            'nameKo': '배수지',
            'birth': '1994-10-10',
            'gender': 'F',
            'dayPillar': '己巳',
            'dayPillarName': 'Earth Snake',
          },
        };
        for (final entry in actorExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1c actor id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['kind'],
            'actor',
            reason: 'Actor "$id" kind 가 "actor" 가 아님: ${e['kind']}',
          );
          expect(e['nameEn'], exp['nameEn'], reason: 'Actor "$id" nameEn 불일치');
          expect(e['nameKo'], exp['nameKo'], reason: 'Actor "$id" nameKo 불일치');
          expect(e['birth'], exp['birth'], reason: 'Actor "$id" birth 불일치');
          expect(e['gender'], exp['gender'], reason: 'Actor "$id" gender 불일치');
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'Actor "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'Actor "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'Actor "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'Actor "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4e — 신규 12 한류 배우 blurb 위생 (출생시간 단정 / 한자 dayPillar
    //              leak / 의료 단정 / romantic-delusion / controversies) 0 ──
    test('행동4.B4e — R84 sprint 1c actor blurb 위생 (시간단정·hanja·의료·delusion 0)', () {
      final raw = File('assets/data/celebrities.json').readAsStringSync();
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final byId = {for (final e in data) e['id'] as String: e};
      const actorIds = <String>[
        'kim-soohyun',
        'lee-minho',
        'cha-eunwoo',
        'song-kang',
        'byeon-wooseok',
        'hwang-inyoup',
        'kim-seonho',
        'ji-changwook',
        'kim-jiwon',
        'kim-hyeyoon',
        'han-sohee',
        'bae-suzy',
      ];
      // 한자 일주 chars (사용자 mandate "avoid raw hanja dayPillar in blurbKo").
      const hanjaChars = <String>[
        '甲',
        '乙',
        '丙',
        '丁',
        '戊',
        '己',
        '庚',
        '辛',
        '壬',
        '癸',
        '子',
        '丑',
        '寅',
        '卯',
        '辰',
        '巳',
        '午',
        '未',
        '申',
        '酉',
        '戌',
        '亥',
      ];
      // 시간 단정 phrase (사용자 mandate "No birth-time/hour claims").
      const timeClaimPhrasesKo = <String>['시에 태어', '시생', '오전', '오후', '시주'];
      const timeClaimPhrasesEn = <String>[
        'born at',
        'hour pillar',
        'a.m.',
        'p.m.',
      ];
      // 의료 단정 + romantic-delusion + controversy blacklist.
      const blurbBlacklistKo = <String>[
        '진단',
        '치료해',
        '병원 가야',
        '약 먹어야',
        '운명적 연애',
        '반드시 결혼',
        '벼린 칼',
        '도검의 끝',
      ];
      for (final id in actorIds) {
        final e = byId[id]!;
        final ko = e['blurbKo'] as String;
        final en = e['blurbEn'] as String;
        for (final ch in hanjaChars) {
          expect(
            ko.contains(ch),
            isFalse,
            reason:
                'Actor "$id" blurbKo 에 raw hanja dayPillar char "$ch" leak: "$ko"',
          );
        }
        for (final p in timeClaimPhrasesKo) {
          expect(
            ko.contains(p),
            isFalse,
            reason: 'Actor "$id" blurbKo 시간 단정 "$p" leak: "$ko"',
          );
        }
        for (final p in timeClaimPhrasesEn) {
          expect(
            en.toLowerCase().contains(p),
            isFalse,
            reason: 'Actor "$id" blurbEn time claim "$p" leak: "$en"',
          );
        }
        for (final p in blurbBlacklistKo) {
          expect(
            ko.contains(p),
            isFalse,
            reason: 'Actor "$id" blurbKo blacklist "$p" leak: "$ko"',
          );
        }
      }
    });

    // ── 행동 4f — R84 sprint 1d NMIXX 6 멤버 확장 검증 ──
    // 사용자 mandate (R84 hand-off): NMIXX 6 멤버 (Lily / Haewon / Sullyoon /
    // Bae / Jiwoo / Kyujin) 추가. dayPillar/dayPillarName 은 앱 만세력 (klc)
    // 계산값으로 wire — 본 테스트는 그 계산 결과의 회귀 가드.
    test(
      '행동4.B4f — R84 sprint 1d NMIXX 6 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const nmixxExpected = <String, Map<String, String>>{
          'lily_nmixx': {
            'nameEn': 'Lily (NMIXX)',
            'nameKo': '릴리 (엔믹스)',
            'birth': '2002-10-17',
            'dayPillar': '戊午',
            'dayPillarName': 'Earth Horse',
          },
          'haewon_nmixx': {
            'nameEn': 'Haewon (NMIXX)',
            'nameKo': '해원 (엔믹스)',
            'birth': '2003-02-25',
            'dayPillar': '己巳',
            'dayPillarName': 'Earth Snake',
          },
          'sullyoon_nmixx': {
            'nameEn': 'Sullyoon (NMIXX)',
            'nameKo': '설윤 (엔믹스)',
            'birth': '2004-01-26',
            'dayPillar': '甲辰',
            'dayPillarName': 'Wood Dragon',
          },
          'bae_nmixx': {
            'nameEn': 'Bae (NMIXX)',
            'nameKo': '배이 (엔믹스)',
            'birth': '2004-12-28',
            'dayPillar': '辛巳',
            'dayPillarName': 'Metal Snake',
          },
          'jiwoo_nmixx': {
            'nameEn': 'Jiwoo (NMIXX)',
            'nameKo': '지우 (엔믹스)',
            'birth': '2005-04-13',
            'dayPillar': '丁卯',
            'dayPillarName': 'Fire Rabbit',
          },
          'kyujin_nmixx': {
            'nameEn': 'Kyujin (NMIXX)',
            'nameKo': '규진 (엔믹스)',
            'birth': '2006-05-26',
            'dayPillar': '乙卯',
            'dayPillarName': 'Wood Rabbit',
          },
        };
        for (final entry in nmixxExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1d NMIXX id "$id" 누락',
          );
          final e = byId[id]!;
          expect(e['nameEn'], exp['nameEn'], reason: 'NMIXX "$id" nameEn 불일치');
          expect(e['nameKo'], exp['nameKo'], reason: 'NMIXX "$id" nameKo 불일치');
          expect(
            e['kind'],
            'idol',
            reason: 'NMIXX "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'NMIXX "$id" birth 불일치');
          expect(
            e['gender'],
            'F',
            reason: 'NMIXX "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'NMIXX "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'NMIXX "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'NMIXX "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'NMIXX "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4g — R84 sprint 1e SEVENTEEN 8 멤버 확장 검증 ──
    // 사용자 mandate (R84 hand-off): SEVENTEEN 8 멤버 (S.Coups / Jeonghan / Jun /
    // Hoshi / Wonwoo / The8 / Seungkwan / Dino) 추가. dayPillar/dayPillarName 은
    // 앱 만세력 (klc) 계산값으로 wire — 본 테스트는 그 계산 결과의 회귀 가드.
    test(
      '행동4.B4g — R84 sprint 1e SEVENTEEN 8 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const seventeenExpected = <String, Map<String, String>>{
          'scoups_svt': {
            'nameEn': 'S.Coups (SEVENTEEN)',
            'nameKo': '에스쿱스 (세븐틴)',
            'birth': '1995-08-08',
            'dayPillar': '辛未',
            'dayPillarName': 'Metal Goat',
          },
          'jeonghan_svt': {
            'nameEn': 'Jeonghan (SEVENTEEN)',
            'nameKo': '정한 (세븐틴)',
            'birth': '1995-10-04',
            'dayPillar': '戊戌',
            'dayPillarName': 'Earth Dog',
          },
          'jun_svt': {
            'nameEn': 'Jun (SEVENTEEN)',
            'nameKo': '준 (세븐틴)',
            'birth': '1996-06-10',
            'dayPillar': '戊寅',
            'dayPillarName': 'Earth Tiger',
          },
          'hoshi_svt': {
            'nameEn': 'Hoshi (SEVENTEEN)',
            'nameKo': '호시 (세븐틴)',
            'birth': '1996-06-15',
            'dayPillar': '癸未',
            'dayPillarName': 'Water Goat',
          },
          'wonwoo_svt': {
            'nameEn': 'Wonwoo (SEVENTEEN)',
            'nameKo': '원우 (세븐틴)',
            'birth': '1996-07-17',
            'dayPillar': '乙卯',
            'dayPillarName': 'Wood Rabbit',
          },
          'the8_svt': {
            'nameEn': 'The8 (SEVENTEEN)',
            'nameKo': '디에잇 (세븐틴)',
            'birth': '1997-11-07',
            'dayPillar': '癸丑',
            'dayPillarName': 'Water Ox',
          },
          'seungkwan_svt': {
            'nameEn': 'Seungkwan (SEVENTEEN)',
            'nameKo': '승관 (세븐틴)',
            'birth': '1998-01-16',
            'dayPillar': '癸亥',
            'dayPillarName': 'Water Pig',
          },
          'dino_svt': {
            'nameEn': 'Dino (SEVENTEEN)',
            'nameKo': '디노 (세븐틴)',
            'birth': '1999-02-11',
            'dayPillar': '甲午',
            'dayPillarName': 'Wood Horse',
          },
        };
        for (final entry in seventeenExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1e SEVENTEEN id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'SEVENTEEN "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'SEVENTEEN "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'SEVENTEEN "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'SEVENTEEN "$id" birth 불일치');
          expect(
            e['gender'],
            'M',
            reason: 'SEVENTEEN "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'SEVENTEEN "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'SEVENTEEN "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'SEVENTEEN "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'SEVENTEEN "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4h — R84 sprint 1f RIIZE +4 + LE SSERAFIM +1 + i-dle +5 확장 검증 ──
    // 사용자 mandate (R84 hand-off): RIIZE 4 멤버 (Shotaro / Eunseok / Sungchan /
    // Sohee, 현재 라인업 — Seunghan 미포함) + LE SSERAFIM Yunjin + i-dle 5 멤버
    // (Miyeon / Minnie / Soyeon / Yuqi / Shuhua) 추가. dayPillar/dayPillarName 은
    // 앱 만세력 (klc) 계산값으로 wire — 본 테스트는 그 계산 결과의 회귀 가드.
    test(
      '행동4.B4h — R84 sprint 1f RIIZE+LES+i-dle 10 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1fExpected = <String, Map<String, String>>{
          'shotaro_riize': {
            'nameEn': 'Shotaro (RIIZE)',
            'nameKo': '쇼타로 (라이즈)',
            'birth': '2000-11-25',
            'gender': 'M',
            'dayPillar': '丁亥',
            'dayPillarName': 'Fire Pig',
          },
          'eunseok_riize': {
            'nameEn': 'Eunseok (RIIZE)',
            'nameKo': '은석 (라이즈)',
            'birth': '2001-03-19',
            'gender': 'M',
            'dayPillar': '辛巳',
            'dayPillarName': 'Metal Snake',
          },
          'sungchan_riize': {
            'nameEn': 'Sungchan (RIIZE)',
            'nameKo': '성찬 (라이즈)',
            'birth': '2001-09-13',
            'gender': 'M',
            'dayPillar': '己卯',
            'dayPillarName': 'Earth Rabbit',
          },
          'sohee_riize': {
            'nameEn': 'Sohee (RIIZE)',
            'nameKo': '소희 (라이즈)',
            'birth': '2003-11-21',
            'gender': 'M',
            'dayPillar': '戊戌',
            'dayPillarName': 'Earth Dog',
          },
          'yunjin_les': {
            'nameEn': 'Yunjin (LE SSERAFIM)',
            'nameKo': '윤진 (르세라핌)',
            'birth': '2001-10-08',
            'gender': 'F',
            'dayPillar': '甲辰',
            'dayPillarName': 'Wood Dragon',
          },
          'miyeon_idle': {
            'nameEn': 'Miyeon (i-dle)',
            'nameKo': '미연 (아이들)',
            'birth': '1997-01-31',
            'gender': 'F',
            'dayPillar': '癸酉',
            'dayPillarName': 'Water Rooster',
          },
          'minnie_idle': {
            'nameEn': 'Minnie (i-dle)',
            'nameKo': '민니 (아이들)',
            'birth': '1997-10-23',
            'gender': 'F',
            'dayPillar': '戊戌',
            'dayPillarName': 'Earth Dog',
          },
          'soyeon_idle': {
            'nameEn': 'Soyeon (i-dle)',
            'nameKo': '소연 (아이들)',
            'birth': '1998-08-26',
            'gender': 'F',
            'dayPillar': '乙巳',
            'dayPillarName': 'Wood Snake',
          },
          'yuqi_idle': {
            'nameEn': 'Yuqi (i-dle)',
            'nameKo': '우기 (아이들)',
            'birth': '1999-09-23',
            'gender': 'F',
            'dayPillar': '戊寅',
            'dayPillarName': 'Earth Tiger',
          },
          'shuhua_idle': {
            'nameEn': 'Shuhua (i-dle)',
            'nameKo': '슈화 (아이들)',
            'birth': '2000-01-06',
            'gender': 'F',
            'dayPillar': '癸亥',
            'dayPillarName': 'Water Pig',
          },
        };
        for (final entry in sprint1fExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1f id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'sprint 1f "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'sprint 1f "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'sprint 1f "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'sprint 1f "$id" birth 불일치');
          expect(
            e['gender'],
            exp['gender'],
            reason: 'sprint 1f "$id" gender 불일치',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'sprint 1f "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'sprint 1f "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1f "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1f "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4i — R84 sprint 1g BABYMONSTER 7 + ILLIT 5 확장 검증 ──
    // 사용자 mandate (R84 hand-off): BABYMONSTER 7 멤버 (Ruka / Pharita / Asa /
    // Ahyeon / Rami / Rora / Chiquita) + ILLIT 5 멤버 (Yunah / Minju / Moka /
    // Wonhee / Iroha) 추가. dayPillar/dayPillarName 은 앱 만세력 (klc) 계산값으로
    // wire — 본 테스트는 그 계산 결과의 회귀 가드.
    test(
      '행동4.B4i — R84 sprint 1g BABYMONSTER+ILLIT 12 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1gExpected = <String, Map<String, String>>{
          'ruka_bm': {
            'nameEn': 'Ruka (BABYMONSTER)',
            'nameKo': '루카 (베이비몬스터)',
            'birth': '2002-03-20',
            'dayPillar': '丁亥',
            'dayPillarName': 'Fire Pig',
          },
          'pharita_bm': {
            'nameEn': 'Pharita (BABYMONSTER)',
            'nameKo': '파리타 (베이비몬스터)',
            'birth': '2005-08-26',
            'dayPillar': '壬午',
            'dayPillarName': 'Water Horse',
          },
          'asa_bm': {
            'nameEn': 'Asa (BABYMONSTER)',
            'nameKo': '아사 (베이비몬스터)',
            'birth': '2006-04-17',
            'dayPillar': '丙子',
            'dayPillarName': 'Fire Rat',
          },
          'ahyeon_bm': {
            'nameEn': 'Ahyeon (BABYMONSTER)',
            'nameKo': '아현 (베이비몬스터)',
            'birth': '2007-04-11',
            'dayPillar': '乙亥',
            'dayPillarName': 'Wood Pig',
          },
          'rami_bm': {
            'nameEn': 'Rami (BABYMONSTER)',
            'nameKo': '라미 (베이비몬스터)',
            'birth': '2007-10-17',
            'dayPillar': '甲申',
            'dayPillarName': 'Wood Monkey',
          },
          'rora_bm': {
            'nameEn': 'Rora (BABYMONSTER)',
            'nameKo': '로라 (베이비몬스터)',
            'birth': '2008-08-14',
            'dayPillar': '丙戌',
            'dayPillarName': 'Fire Dog',
          },
          'chiquita_bm': {
            'nameEn': 'Chiquita (BABYMONSTER)',
            'nameKo': '치키타 (베이비몬스터)',
            'birth': '2009-02-17',
            'dayPillar': '癸巳',
            'dayPillarName': 'Water Snake',
          },
          'yunah_illit': {
            'nameEn': 'Yunah (ILLIT)',
            'nameKo': '윤아 (아일릿)',
            'birth': '2004-01-15',
            'dayPillar': '癸巳',
            'dayPillarName': 'Water Snake',
          },
          'minju_illit': {
            'nameEn': 'Minju (ILLIT)',
            'nameKo': '민주 (아일릿)',
            'birth': '2004-05-11',
            'dayPillar': '庚寅',
            'dayPillarName': 'Metal Tiger',
          },
          'moka_illit': {
            'nameEn': 'Moka (ILLIT)',
            'nameKo': '모카 (아일릿)',
            'birth': '2004-10-08',
            'dayPillar': '庚申',
            'dayPillarName': 'Metal Monkey',
          },
          'wonhee_illit': {
            'nameEn': 'Wonhee (ILLIT)',
            'nameKo': '원희 (아일릿)',
            'birth': '2007-06-26',
            'dayPillar': '辛卯',
            'dayPillarName': 'Metal Rabbit',
          },
          'iroha_illit': {
            'nameEn': 'Iroha (ILLIT)',
            'nameKo': '이로하 (아일릿)',
            'birth': '2008-02-04',
            'dayPillar': '甲戌',
            'dayPillarName': 'Wood Dog',
          },
        };
        for (final entry in sprint1gExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1g id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'sprint 1g "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'sprint 1g "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'sprint 1g "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'sprint 1g "$id" birth 불일치');
          expect(
            e['gender'],
            'F',
            reason: 'sprint 1g "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'sprint 1g "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'sprint 1g "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1g "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1g "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4j — R84 sprint 1h KISS OF LIFE 4 멤버 확장 검증 ──
    // 사용자 mandate (R84 hand-off): KISS OF LIFE 4 멤버 (Julie / Natty / Belle /
    // Haneul) 추가. dayPillar/dayPillarName 은 앱 만세력 (klc) 계산값으로 wire —
    // 본 테스트는 그 계산 결과의 회귀 가드.
    test(
      '행동4.B4j — R84 sprint 1h KISS OF LIFE 4 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1hExpected = <String, Map<String, String>>{
          'julie_kiof': {
            'nameEn': 'Julie (KISS OF LIFE)',
            'nameKo': '쥴리 (키스오브라이프)',
            'birth': '2000-03-29',
            'dayPillar': '丙戌',
            'dayPillarName': 'Fire Dog',
          },
          'natty_kiof': {
            'nameEn': 'Natty (KISS OF LIFE)',
            'nameKo': '나띠 (키스오브라이프)',
            'birth': '2002-05-30',
            'dayPillar': '戊戌',
            'dayPillarName': 'Earth Dog',
          },
          'belle_kiof': {
            'nameEn': 'Belle (KISS OF LIFE)',
            'nameKo': '벨 (키스오브라이프)',
            'birth': '2004-03-20',
            'dayPillar': '戊戌',
            'dayPillarName': 'Earth Dog',
          },
          'haneul_kiof': {
            'nameEn': 'Haneul (KISS OF LIFE)',
            'nameKo': '하늘 (키스오브라이프)',
            'birth': '2005-05-25',
            'dayPillar': '己酉',
            'dayPillarName': 'Earth Rooster',
          },
        };
        for (final entry in sprint1hExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1h KISS OF LIFE id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'KISS OF LIFE "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'KISS OF LIFE "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'KISS OF LIFE "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(
            e['birth'],
            exp['birth'],
            reason: 'KISS OF LIFE "$id" birth 불일치',
          );
          expect(
            e['gender'],
            'F',
            reason: 'KISS OF LIFE "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'KISS OF LIFE "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'KISS OF LIFE "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'KISS OF LIFE "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'KISS OF LIFE "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4k — R84 sprint 1i ZEROBASEONE 5명 확장 검증 ──
    // 사용자 mandate (R84 hand-off 글로벌 한류 idol 확장): ZEROBASEONE 5 멤버 추가.
    // dayPillar/dayPillarName 은 ManseryeokService (klc 만세력) 계산값 — 본
    // 테스트는 그 계산 결과 회귀 가드.
    test(
      '행동4.B4k — R84 sprint 1i ZEROBASEONE 5 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1iExpected = <String, Map<String, String>>{
          'sung_hanbin_zb1': {
            'nameEn': 'Sung Hanbin (ZEROBASEONE)',
            'nameKo': '성한빈 (제로베이스원)',
            'birth': '2001-06-13',
            'dayPillar': '戊寅',
            'dayPillarName': 'Earth Tiger',
          },
          'kim_jiwoong_zb1': {
            'nameEn': 'Kim Jiwoong (ZEROBASEONE)',
            'nameKo': '김지웅 (제로베이스원)',
            'birth': '1998-12-14',
            'dayPillar': '乙未',
            'dayPillarName': 'Wood Goat',
          },
          'zhang_hao_zb1': {
            'nameEn': 'Zhang Hao (ZEROBASEONE)',
            'nameKo': '장하오 (제로베이스원)',
            'birth': '2000-07-25',
            'dayPillar': '甲申',
            'dayPillarName': 'Wood Monkey',
          },
          'seok_matthew_zb1': {
            'nameEn': 'Seok Matthew (ZEROBASEONE)',
            'nameKo': '석매튜 (제로베이스원)',
            'birth': '2002-05-28',
            'dayPillar': '丙申',
            'dayPillarName': 'Fire Monkey',
          },
          'kim_taerae_zb1': {
            'nameEn': 'Kim Taerae (ZEROBASEONE)',
            'nameKo': '김태래 (제로베이스원)',
            'birth': '2002-07-14',
            'dayPillar': '癸未',
            'dayPillarName': 'Water Goat',
          },
        };
        for (final entry in sprint1iExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1i ZEROBASEONE id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'ZEROBASEONE "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'ZEROBASEONE "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'ZEROBASEONE "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(
            e['birth'],
            exp['birth'],
            reason: 'ZEROBASEONE "$id" birth 불일치',
          );
          expect(
            e['gender'],
            'M',
            reason: 'ZEROBASEONE "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'ZEROBASEONE "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'ZEROBASEONE "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'ZEROBASEONE "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'ZEROBASEONE "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4l — R84 sprint 1i ext ZEROBASEONE 잔여 4명 확장 검증 ──
    // 사용자 mandate (R84 hand-off 글로벌 한류 idol 확장 / ZEROBASEONE 9인 전원
    // 커버 완성): 기존 5명에 더해 잔여 4명 추가.
    // dayPillar/dayPillarName 은 ManseryeokService (klc 만세력) 계산값 — 본
    // 테스트는 그 계산 결과 회귀 가드.
    test(
      '행동4.B4l — R84 sprint 1i ext ZEROBASEONE 잔여 4 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1iExtExpected = <String, Map<String, String>>{
          'kim_gyuvin_zb1': {
            'nameEn': 'Kim Gyuvin (ZEROBASEONE)',
            'nameKo': '김규빈 (제로베이스원)',
            'birth': '2004-08-30',
            'dayPillar': '辛巳',
            'dayPillarName': 'Metal Snake',
          },
          'park_gunwook_zb1': {
            'nameEn': 'Park Gunwook (ZEROBASEONE)',
            'nameKo': '박건욱 (제로베이스원)',
            'birth': '2005-01-10',
            'dayPillar': '甲午',
            'dayPillarName': 'Wood Horse',
          },
          'han_yujin_zb1': {
            'nameEn': 'Han Yujin (ZEROBASEONE)',
            'nameKo': '한유진 (제로베이스원)',
            'birth': '2007-03-20',
            'dayPillar': '癸丑',
            'dayPillarName': 'Water Ox',
          },
          'ricky_zb1': {
            'nameEn': 'Ricky (ZEROBASEONE)',
            'nameKo': '리키 (제로베이스원)',
            'birth': '2004-05-20',
            'dayPillar': '己亥',
            'dayPillarName': 'Earth Pig',
          },
        };
        for (final entry in sprint1iExtExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1i ext ZEROBASEONE id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'ZEROBASEONE ext "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'ZEROBASEONE ext "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'ZEROBASEONE ext "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(
            e['birth'],
            exp['birth'],
            reason: 'ZEROBASEONE ext "$id" birth 불일치',
          );
          expect(
            e['gender'],
            'M',
            reason: 'ZEROBASEONE ext "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'ZEROBASEONE ext "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'ZEROBASEONE ext "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'ZEROBASEONE ext "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'ZEROBASEONE ext "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4m — R84 sprint 1j BOYNEXTDOOR 6명 확장 검증 ──
    // 사용자 mandate (R84 hand-off 글로벌 한류 idol 확장 / BOYNEXTDOOR 6인 전원
    // 커버): Sungho / Riwoo / Jaehyun / Taesan / Leehan / Woonhak.
    // dayPillar/dayPillarName 은 ManseryeokService (klc 만세력) 계산값 — 본
    // 테스트는 그 계산 결과 회귀 가드.
    test(
      '행동4.B4m — R84 sprint 1j BOYNEXTDOOR 6 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1jExpected = <String, Map<String, String>>{
          'sungho_bnd': {
            'nameEn': 'Sungho (BOYNEXTDOOR)',
            'nameKo': '성호 (보이넥스트도어)',
            'birth': '2003-09-04',
            'dayPillar': '庚辰',
            'dayPillarName': 'Metal Dragon',
          },
          'riwoo_bnd': {
            'nameEn': 'Riwoo (BOYNEXTDOOR)',
            'nameKo': '리우 (보이넥스트도어)',
            'birth': '2003-10-22',
            'dayPillar': '戊辰',
            'dayPillarName': 'Earth Dragon',
          },
          'jaehyun_bnd': {
            'nameEn': 'Jaehyun (BOYNEXTDOOR)',
            'nameKo': '명재현 (보이넥스트도어)',
            'birth': '2003-12-04',
            'dayPillar': '辛亥',
            'dayPillarName': 'Metal Pig',
          },
          'taesan_bnd': {
            'nameEn': 'Taesan (BOYNEXTDOOR)',
            'nameKo': '태산 (보이넥스트도어)',
            'birth': '2004-08-10',
            'dayPillar': '辛酉',
            'dayPillarName': 'Metal Rooster',
          },
          'leehan_bnd': {
            'nameEn': 'Leehan (BOYNEXTDOOR)',
            'nameKo': '이한 (보이넥스트도어)',
            'birth': '2004-10-20',
            'dayPillar': '壬申',
            'dayPillarName': 'Water Monkey',
          },
          'woonhak_bnd': {
            'nameEn': 'Woonhak (BOYNEXTDOOR)',
            'nameKo': '운학 (보이넥스트도어)',
            'birth': '2006-11-29',
            'dayPillar': '壬戌',
            'dayPillarName': 'Water Dog',
          },
        };
        for (final entry in sprint1jExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1j BOYNEXTDOOR id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'BOYNEXTDOOR "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'BOYNEXTDOOR "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'BOYNEXTDOOR "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(
            e['birth'],
            exp['birth'],
            reason: 'BOYNEXTDOOR "$id" birth 불일치',
          );
          expect(
            e['gender'],
            'M',
            reason: 'BOYNEXTDOOR "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'BOYNEXTDOOR "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'BOYNEXTDOOR "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'BOYNEXTDOOR "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'BOYNEXTDOOR "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4n — R84 sprint 1k TWS 6 멤버 확장 (id + birth + gender + dayPillar 회귀) ──
    test(
      '행동4.B4n — R84 sprint 1k TWS 6 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1kExpected = <String, Map<String, String>>{
          'shinyu_tws': {
            'nameEn': 'Shinyu (TWS)',
            'nameKo': '신유 (투어스)',
            'birth': '2003-11-07',
            'dayPillar': '甲申',
            'dayPillarName': 'Wood Monkey',
          },
          'dohoon_tws': {
            'nameEn': 'Dohoon (TWS)',
            'nameKo': '도훈 (투어스)',
            'birth': '2005-01-30',
            'dayPillar': '甲寅',
            'dayPillarName': 'Wood Tiger',
          },
          'youngjae_tws': {
            'nameEn': 'Youngjae (TWS)',
            'nameKo': '영재 (투어스)',
            'birth': '2005-05-31',
            'dayPillar': '乙卯',
            'dayPillarName': 'Wood Rabbit',
          },
          'hanjin_tws': {
            'nameEn': 'Hanjin (TWS)',
            'nameKo': '한진 (투어스)',
            'birth': '2006-01-05',
            'dayPillar': '甲午',
            'dayPillarName': 'Wood Horse',
          },
          'jihoon_tws': {
            'nameEn': 'Jihoon (TWS)',
            'nameKo': '지훈 (투어스)',
            'birth': '2006-03-28',
            'dayPillar': '丙辰',
            'dayPillarName': 'Fire Dragon',
          },
          'kyungmin_tws': {
            'nameEn': 'Kyungmin (TWS)',
            'nameKo': '경민 (투어스)',
            'birth': '2007-10-02',
            'dayPillar': '己巳',
            'dayPillarName': 'Earth Snake',
          },
        };
        for (final entry in sprint1kExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1k TWS id "$id" 누락',
          );
          final e = byId[id]!;
          expect(e['nameEn'], exp['nameEn'], reason: 'TWS "$id" nameEn 불일치');
          expect(e['nameKo'], exp['nameKo'], reason: 'TWS "$id" nameKo 불일치');
          expect(
            e['kind'],
            'idol',
            reason: 'TWS "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'TWS "$id" birth 불일치');
          expect(
            e['gender'],
            'M',
            reason: 'TWS "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'TWS "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'TWS "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'TWS "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'TWS "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4o — R84 sprint 1l NCT DREAM 7 멤버 확장 (id + birth + gender + dayPillar 회귀) ──
    test(
      '행동4.B4o — R84 sprint 1l NCT DREAM 7 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1lExpected = <String, Map<String, String>>{
          'mark_nct': {
            'nameEn': 'Mark (NCT DREAM)',
            'nameKo': '마크 (NCT DREAM)',
            'birth': '1999-08-02',
            'dayPillar': '丙戌',
            'dayPillarName': 'Fire Dog',
          },
          'renjun_nct': {
            'nameEn': 'Renjun (NCT DREAM)',
            'nameKo': '런쥔 (NCT DREAM)',
            'birth': '2000-03-23',
            'dayPillar': '庚辰',
            'dayPillarName': 'Metal Dragon',
          },
          'jeno_nct': {
            'nameEn': 'Jeno (NCT DREAM)',
            'nameKo': '제노 (NCT DREAM)',
            'birth': '2000-04-23',
            'dayPillar': '辛亥',
            'dayPillarName': 'Metal Pig',
          },
          'haechan_nct': {
            'nameEn': 'Haechan (NCT DREAM)',
            'nameKo': '해찬 (NCT DREAM)',
            'birth': '2000-06-06',
            'dayPillar': '乙未',
            'dayPillarName': 'Wood Goat',
          },
          'jaemin_nct': {
            'nameEn': 'Jaemin (NCT DREAM)',
            'nameKo': '재민 (NCT DREAM)',
            'birth': '2000-08-13',
            'dayPillar': '癸卯',
            'dayPillarName': 'Water Rabbit',
          },
          'chenle_nct': {
            'nameEn': 'Chenle (NCT DREAM)',
            'nameKo': '천러 (NCT DREAM)',
            'birth': '2001-11-22',
            'dayPillar': '己丑',
            'dayPillarName': 'Earth Ox',
          },
          'jisung_nct': {
            'nameEn': 'Jisung (NCT DREAM)',
            'nameKo': '지성 (NCT DREAM)',
            'birth': '2002-02-05',
            'dayPillar': '甲辰',
            'dayPillarName': 'Wood Dragon',
          },
        };
        for (final entry in sprint1lExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1l NCT DREAM id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'NCT DREAM "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'NCT DREAM "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'NCT DREAM "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'NCT DREAM "$id" birth 불일치');
          expect(
            e['gender'],
            'M',
            reason: 'NCT DREAM "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'NCT DREAM "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'NCT DREAM "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'NCT DREAM "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'NCT DREAM "$id" blurbEn 빈 값',
          );
        }
      },
    );

    test(
      '행동4.B4p — R84 sprint 1m NCT WISH 6 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1mExpected = <String, Map<String, String>>{
          'sion_wish': {
            'nameEn': 'Sion (NCT WISH)',
            'nameKo': '시온 (NCT WISH)',
            'birth': '2002-05-11',
            'dayPillar': '己卯',
            'dayPillarName': 'Earth Rabbit',
          },
          'riku_wish': {
            'nameEn': 'Riku (NCT WISH)',
            'nameKo': '리쿠 (NCT WISH)',
            'birth': '2003-06-28',
            'dayPillar': '壬申',
            'dayPillarName': 'Water Monkey',
          },
          'yushi_wish': {
            'nameEn': 'Yushi (NCT WISH)',
            'nameKo': '유우시 (NCT WISH)',
            'birth': '2004-04-05',
            'dayPillar': '甲申',
            'dayPillarName': 'Wood Monkey',
          },
          'jaehee_wish': {
            'nameEn': 'Jaehee (NCT WISH)',
            'nameKo': '재희 (NCT WISH)',
            'birth': '2005-06-21',
            'dayPillar': '丙子',
            'dayPillarName': 'Fire Rat',
          },
          'ryo_wish': {
            'nameEn': 'Ryo (NCT WISH)',
            'nameKo': '료 (NCT WISH)',
            'birth': '2007-08-04',
            'dayPillar': '庚午',
            'dayPillarName': 'Metal Horse',
          },
          'sakuya_wish': {
            'nameEn': 'Sakuya (NCT WISH)',
            'nameKo': '사쿠야 (NCT WISH)',
            'birth': '2007-11-18',
            'dayPillar': '丙辰',
            'dayPillarName': 'Fire Dragon',
          },
        };
        for (final entry in sprint1mExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1m NCT WISH id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'NCT WISH "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'NCT WISH "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'NCT WISH "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'NCT WISH "$id" birth 불일치');
          expect(
            e['gender'],
            'M',
            reason: 'NCT WISH "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'NCT WISH "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'NCT WISH "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'NCT WISH "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'NCT WISH "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4q — R84 sprint 1n XG 7 멤버 확장 (id + birth + gender + dayPillar 회귀) ──
    test(
      '행동4.B4q — R84 sprint 1n XG 7 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1nExpected = <String, Map<String, String>>{
          'jurin_xg': {
            'nameEn': 'Jurin (XG)',
            'nameKo': '주린 (XG)',
            'birth': '2002-06-19',
            'dayPillar': '戊午',
            'dayPillarName': 'Earth Horse',
          },
          'chisa_xg': {
            'nameEn': 'Chisa (XG)',
            'nameKo': '치사 (XG)',
            'birth': '2002-01-17',
            'dayPillar': '乙酉',
            'dayPillarName': 'Wood Rooster',
          },
          'hinata_xg': {
            'nameEn': 'Hinata (XG)',
            'nameKo': '히나타 (XG)',
            'birth': '2002-06-11',
            'dayPillar': '庚戌',
            'dayPillarName': 'Metal Dog',
          },
          'harvey_xg': {
            'nameEn': 'Harvey (XG)',
            'nameKo': '하비 (XG)',
            'birth': '2002-12-18',
            'dayPillar': '庚申',
            'dayPillarName': 'Metal Monkey',
          },
          'juria_xg': {
            'nameEn': 'Juria (XG)',
            'nameKo': '쥬리아 (XG)',
            'birth': '2004-11-28',
            'dayPillar': '辛亥',
            'dayPillarName': 'Metal Pig',
          },
          'maya_xg': {
            'nameEn': 'Maya (XG)',
            'nameKo': '마야 (XG)',
            'birth': '2005-08-10',
            'dayPillar': '丙寅',
            'dayPillarName': 'Fire Tiger',
          },
          'cocona_xg': {
            'nameEn': 'Cocona (XG)',
            'nameKo': '코코나 (XG)',
            'birth': '2005-12-06',
            'dayPillar': '甲子',
            'dayPillarName': 'Wood Rat',
          },
        };
        for (final entry in sprint1nExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1n XG id "$id" 누락',
          );
          final e = byId[id]!;
          expect(e['nameEn'], exp['nameEn'], reason: 'XG "$id" nameEn 불일치');
          expect(e['nameKo'], exp['nameKo'], reason: 'XG "$id" nameKo 불일치');
          expect(
            e['kind'],
            'idol',
            reason: 'XG "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'XG "$id" birth 불일치');
          expect(
            e['gender'],
            'F',
            reason: 'XG "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'XG "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'XG "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'XG "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'XG "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4r — R84 sprint 1o KATSEYE 6 멤버 확장 (id + birth + gender + dayPillar 회귀) ──
    test(
      '행동4.B4r — R84 sprint 1o KATSEYE 6 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1oExpected = <String, Map<String, String>>{
          'sophia_katseye': {
            'nameEn': 'Sophia (KATSEYE)',
            'nameKo': '소피아 (캣츠아이)',
            'birth': '2002-12-31',
            'dayPillar': '癸酉',
            'dayPillarName': 'Water Rooster',
          },
          'manon_katseye': {
            'nameEn': 'Manon (KATSEYE)',
            'nameKo': '마농 (캣츠아이)',
            'birth': '2002-06-26',
            'dayPillar': '乙丑',
            'dayPillarName': 'Wood Ox',
          },
          'daniela_katseye': {
            'nameEn': 'Daniela (KATSEYE)',
            'nameKo': '다니엘라 (캣츠아이)',
            'birth': '2004-07-01',
            'dayPillar': '辛巳',
            'dayPillarName': 'Metal Snake',
          },
          'lara_katseye': {
            'nameEn': 'Lara (KATSEYE)',
            'nameKo': '라라 (캣츠아이)',
            'birth': '2005-11-03',
            'dayPillar': '辛卯',
            'dayPillarName': 'Metal Rabbit',
          },
          'megan_katseye': {
            'nameEn': 'Megan (KATSEYE)',
            'nameKo': '메간 (캣츠아이)',
            'birth': '2006-02-10',
            'dayPillar': '庚午',
            'dayPillarName': 'Metal Horse',
          },
          'yoonchae_katseye': {
            'nameEn': 'Yoonchae (KATSEYE)',
            'nameKo': '윤채 (캣츠아이)',
            'birth': '2007-12-06',
            'dayPillar': '甲戌',
            'dayPillarName': 'Wood Dog',
          },
        };
        for (final entry in sprint1oExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1o KATSEYE id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'KATSEYE "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'KATSEYE "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'KATSEYE "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'KATSEYE "$id" birth 불일치');
          expect(
            e['gender'],
            'F',
            reason: 'KATSEYE "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'KATSEYE "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'KATSEYE "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'KATSEYE "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'KATSEYE "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4s — R84 sprint 1p Red Velvet 5 + MAMAMOO 3 + solo 4 확장 ──
    // 사용자 mandate (R84 hand-off 확장): 글로벌 한류 여성 idol 12명 추가.
    // dayPillar/dayPillarName 은 앱 만세력 (klc) 계산값으로 wire — 본 테스트는
    // 그 계산 결과의 회귀 가드. 모든 entry kind=idol, gender=F, blurbKo+blurbEn
    // 비어있지 않음.
    test(
      '행동4.B4s — R84 sprint 1p Red Velvet 5 + MAMAMOO 3 + solo 4 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1pExpected = <String, Map<String, String>>{
          'irene_rv': {
            'nameEn': 'Irene (Red Velvet)',
            'nameKo': '아이린 (레드벨벳)',
            'birth': '1991-03-29',
            'dayPillar': '戊戌',
            'dayPillarName': 'Earth Dog',
          },
          'seulgi_rv': {
            'nameEn': 'Seulgi (Red Velvet)',
            'nameKo': '슬기 (레드벨벳)',
            'birth': '1994-02-10',
            'dayPillar': '丁卯',
            'dayPillarName': 'Fire Rabbit',
          },
          'wendy_rv': {
            'nameEn': 'Wendy (Red Velvet)',
            'nameKo': '웬디 (레드벨벳)',
            'birth': '1994-02-21',
            'dayPillar': '戊寅',
            'dayPillarName': 'Earth Tiger',
          },
          'joy_rv': {
            'nameEn': 'Joy (Red Velvet)',
            'nameKo': '조이 (레드벨벳)',
            'birth': '1996-09-03',
            'dayPillar': '癸卯',
            'dayPillarName': 'Water Rabbit',
          },
          'yeri_rv': {
            'nameEn': 'Yeri (Red Velvet)',
            'nameKo': '예리 (레드벨벳)',
            'birth': '1999-03-05',
            'dayPillar': '丙辰',
            'dayPillarName': 'Fire Dragon',
          },
          'solar_mamamoo': {
            'nameEn': 'Solar (MAMAMOO)',
            'nameKo': '솔라 (마마무)',
            'birth': '1991-02-21',
            'dayPillar': '壬戌',
            'dayPillarName': 'Water Dog',
          },
          'moonbyul_mamamoo': {
            'nameEn': 'Moonbyul (MAMAMOO)',
            'nameKo': '문별 (마마무)',
            'birth': '1992-12-22',
            'dayPillar': '壬申',
            'dayPillarName': 'Water Monkey',
          },
          'wheein_mamamoo': {
            'nameEn': 'Wheein (MAMAMOO)',
            'nameKo': '휘인 (마마무)',
            'birth': '1995-04-17',
            'dayPillar': '戊寅',
            'dayPillarName': 'Earth Tiger',
          },
          'somi_solo': {
            'nameEn': 'Jeon Somi',
            'nameKo': '전소미',
            'birth': '2001-03-09',
            'dayPillar': '辛未',
            'dayPillarName': 'Metal Goat',
          },
          'chungha_solo': {
            'nameEn': 'Chungha',
            'nameKo': '청하',
            'birth': '1996-02-09',
            'dayPillar': '丙子',
            'dayPillarName': 'Fire Rat',
          },
          'sunmi_solo': {
            'nameEn': 'Sunmi',
            'nameKo': '선미',
            'birth': '1992-05-02',
            'dayPillar': '戊寅',
            'dayPillarName': 'Earth Tiger',
          },
          'eunbi_solo': {
            'nameEn': 'Kwon Eunbi',
            'nameKo': '권은비',
            'birth': '1995-09-27',
            'dayPillar': '辛卯',
            'dayPillarName': 'Metal Rabbit',
          },
        };
        for (final entry in sprint1pExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1p id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'sprint 1p "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'sprint 1p "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'sprint 1p "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'sprint 1p "$id" birth 불일치');
          expect(
            e['gender'],
            'F',
            reason: 'sprint 1p "$id" gender 가 "F" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'sprint 1p "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'sprint 1p "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1p "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1p "$id" blurbEn 빈 값',
          );
        }
      },
    );

    // ── 행동 4t — R84 sprint 1q TREASURE 10 멤버 확장 ──
    // 사용자 mandate (R84 hand-off 확장): 글로벌 한류 남성 idol 10명 (TREASURE)
    // 추가. dayPillar/dayPillarName 은 앱 만세력 (klc) 계산값으로 wire — 본
    // 테스트는 그 계산 결과의 회귀 가드. 모든 entry kind=idol, gender=M,
    // blurbKo+blurbEn 비어있지 않음.
    test(
      '행동4.B4t — R84 sprint 1q TREASURE 10 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1qExpected = <String, Map<String, String>>{
          'hyunsuk_trsr': {
            'nameEn': 'Choi Hyunsuk (TREASURE)',
            'nameKo': '최현석 (트레저)',
            'birth': '1999-04-21',
            'dayPillar': '癸卯',
            'dayPillarName': 'Water Rabbit',
          },
          'jihoon_trsr': {
            'nameEn': 'Jihoon (TREASURE)',
            'nameKo': '지훈 (트레저)',
            'birth': '2000-03-14',
            'dayPillar': '辛未',
            'dayPillarName': 'Metal Goat',
          },
          'yoshi_trsr': {
            'nameEn': 'Yoshi (TREASURE)',
            'nameKo': '요시 (트레저)',
            'birth': '2000-05-15',
            'dayPillar': '癸酉',
            'dayPillarName': 'Water Rooster',
          },
          'junkyu_trsr': {
            'nameEn': 'Junkyu (TREASURE)',
            'nameKo': '준규 (트레저)',
            'birth': '2000-09-09',
            'dayPillar': '庚午',
            'dayPillarName': 'Metal Horse',
          },
          'jaehyuk_trsr': {
            'nameEn': 'Jaehyuk (TREASURE)',
            'nameKo': '재혁 (트레저)',
            'birth': '2001-07-23',
            'dayPillar': '丁亥',
            'dayPillarName': 'Fire Pig',
          },
          'asahi_trsr': {
            'nameEn': 'Asahi (TREASURE)',
            'nameKo': '아사히 (트레저)',
            'birth': '2001-08-20',
            'dayPillar': '乙卯',
            'dayPillarName': 'Wood Rabbit',
          },
          'doyoung_trsr': {
            'nameEn': 'Doyoung (TREASURE)',
            'nameKo': '도영 (트레저)',
            'birth': '2003-12-04',
            'dayPillar': '辛亥',
            'dayPillarName': 'Metal Pig',
          },
          'haruto_trsr': {
            'nameEn': 'Haruto (TREASURE)',
            'nameKo': '하루토 (트레저)',
            'birth': '2004-04-05',
            'dayPillar': '甲申',
            'dayPillarName': 'Wood Monkey',
          },
          'jeongwoo_trsr': {
            'nameEn': 'Park Jeongwoo (TREASURE)',
            'nameKo': '박정우 (트레저)',
            'birth': '2004-09-28',
            'dayPillar': '庚戌',
            'dayPillarName': 'Metal Dog',
          },
          'junghwan_trsr': {
            'nameEn': 'Junghwan (TREASURE)',
            'nameKo': '정환 (트레저)',
            'birth': '2005-02-18',
            'dayPillar': '癸酉',
            'dayPillarName': 'Water Rooster',
          },
        };
        for (final entry in sprint1qExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1q id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'sprint 1q "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'sprint 1q "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'sprint 1q "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'sprint 1q "$id" birth 불일치');
          expect(
            e['gender'],
            'M',
            reason: 'sprint 1q "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'sprint 1q "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'sprint 1q "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1q "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1q "$id" blurbEn 빈 값',
          );
        }
      },
    );

    test(
      '행동4.B4u — R84 sprint 1r P1Harmony 6 멤버 확장 (id + birth + gender + dayPillar 회귀)',
      () {
        final raw = File('assets/data/celebrities.json').readAsStringSync();
        final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        final byId = {for (final e in data) e['id'] as String: e};
        const sprint1rExpected = <String, Map<String, String>>{
          'keeho_p1h': {
            'nameEn': 'Keeho (P1Harmony)',
            'nameKo': '기호 (피원하모니)',
            'birth': '2001-09-27',
            'dayPillar': '癸巳',
            'dayPillarName': 'Water Snake',
          },
          'theo_p1h': {
            'nameEn': 'Theo (P1Harmony)',
            'nameKo': '테오 (피원하모니)',
            'birth': '2001-07-01',
            'dayPillar': '乙丑',
            'dayPillarName': 'Wood Ox',
          },
          'jiung_p1h': {
            'nameEn': 'Jiung (P1Harmony)',
            'nameKo': '지웅 (피원하모니)',
            'birth': '2001-10-07',
            'dayPillar': '癸卯',
            'dayPillarName': 'Water Rabbit',
          },
          'intak_p1h': {
            'nameEn': 'Intak (P1Harmony)',
            'nameKo': '인탁 (피원하모니)',
            'birth': '2003-08-31',
            'dayPillar': '丙子',
            'dayPillarName': 'Fire Rat',
          },
          'soul_p1h': {
            'nameEn': 'Soul (P1Harmony)',
            'nameKo': '소울 (피원하모니)',
            'birth': '2005-02-01',
            'dayPillar': '丙辰',
            'dayPillarName': 'Fire Dragon',
          },
          'jongseob_p1h': {
            'nameEn': 'Jongseob (P1Harmony)',
            'nameKo': '종섭 (피원하모니)',
            'birth': '2005-11-19',
            'dayPillar': '丁未',
            'dayPillarName': 'Fire Goat',
          },
        };
        for (final entry in sprint1rExpected.entries) {
          final id = entry.key;
          final exp = entry.value;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: 'R84 sprint 1r id "$id" 누락',
          );
          final e = byId[id]!;
          expect(
            e['nameEn'],
            exp['nameEn'],
            reason: 'sprint 1r "$id" nameEn 불일치',
          );
          expect(
            e['nameKo'],
            exp['nameKo'],
            reason: 'sprint 1r "$id" nameKo 불일치',
          );
          expect(
            e['kind'],
            'idol',
            reason: 'sprint 1r "$id" kind 가 "idol" 가 아님: ${e['kind']}',
          );
          expect(e['birth'], exp['birth'], reason: 'sprint 1r "$id" birth 불일치');
          expect(
            e['gender'],
            'M',
            reason: 'sprint 1r "$id" gender 가 "M" 가 아님: ${e['gender']}',
          );
          expect(
            e['dayPillar'],
            exp['dayPillar'],
            reason: 'sprint 1r "$id" dayPillar 불일치 (앱 만세력 klc 계산값 회귀)',
          );
          expect(
            e['dayPillarName'],
            exp['dayPillarName'],
            reason: 'sprint 1r "$id" dayPillarName 불일치',
          );
          expect(
            (e['blurbKo'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1r "$id" blurbKo 빈 값',
          );
          expect(
            (e['blurbEn'] as String).isNotEmpty,
            isTrue,
            reason: 'sprint 1r "$id" blurbEn 빈 값',
          );
        }
      },
    );
  });
}
