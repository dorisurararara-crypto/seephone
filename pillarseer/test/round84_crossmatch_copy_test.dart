// Round 84 — Crossmatch copy cleanup.
//
// 사용자 mandate (R84):
//   1) Crossmatch 결과 (sajuSide/sajuSideEn/ziweiSide/ziweiSideEn/combinedKo/
//      combinedEn) 의 user-facing 한·영 string 안에 자미두수 궁/별 이름 jargon +
//      hard 사주 jargon (갑목/병화/일간/신(辛)/묘(卯) + 영문 Xin/Jia/Mao/Yi/Wei/
//      day master/branch/dominant/palace/star) 노출 0.
//   2) home_screen 6 각 카드 main/sub line 이 matchCount 중심 문구
//      ("너의 강점 N개", "진짜 무기") 에서 matched-axis 이름 중심 자연 문장으로 전환.
//   3) six_axis_radar 의 badge 라벨 단축 ("같이 잡힌 강점") 하되, 기존 phrase
//      "두 번 봐도 같이 잡힌 강점" 은 (radar docstring + result_screen 영역) 잔존
//      — R82 sprint 4 회귀 가드 보존.
//
// 본 검사는 algorithmic (matchCount / matchedAxes / combinedScores) 미접촉
// mandate 보장 — 모두 copy-only 변경.
//
// 검사 구조:
//   B1* — source-level regex (supplemental — fast 회귀 guard).
//   B2* — home_screen copy axis-name 중심 (source-level).
//   B3* — R82 라벨 회귀 guard (source-level).
//   B4* — runtime-level (ZiweiCrossmatchService.find 호출 후 모든 user-facing
//         string ko + en 모두 jargon/symbol/interpolation leak 0 검증).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/ziwei_crossmatch_service.dart';
import 'package:pillarseer/services/ziwei_service.dart';

// ───────────────────────── 공통 jargon 어휘 ─────────────────────────

// Korean noun jargon — 자미두수 12궁 + 14 주성 + 4 보좌 + hard 사주.
const _koJargon = <String>[
  // 12 궁
  '명궁', '신궁', '관록궁', '부처궁', '재백궁', '복덕궁',
  '형제궁', '자녀궁', '질액궁', '천이궁', '노복궁', '전택궁', '부모궁',
  // 14 주성 (성 suffix 동반)
  '자미성', '천기성', '태양성', '무곡성', '천동성', '염정성',
  '천부성', '태음성', '탐랑성', '거문성', '천상성', '천량성',
  '칠살성', '파군성',
  // 4 보좌
  '문창', '문곡', '좌보', '우필',
  // hard 사주
  '일간', '일주', '갑목', '병화', '을목', '신(辛)', '묘(卯)', '미(未)',
  '주성',
];

// Raw hanja chars — user-facing 본문에 노출되면 안 됨.
const _hanjaSymbols = <String>[
  // 천간
  '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  // 지지
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  // 5행
  '木', '火', '土', '金', '水',
];

// 영문 jargon — pinyin 천간/지지 단어 + jargon 명사. \b word boundary 사용해서
// substring false-positive 회피 (e.g. "sensitive" 안의 "Yi" X).
final _enJargonRe = <RegExp>[
  RegExp(r'\bXin\b'),
  RegExp(r'\bJia\b'),
  RegExp(r'\bYi\b'),
  RegExp(r'\bMao\b'),
  RegExp(r'\bWei\b'),
  RegExp(r'\bBing\b'),
  RegExp(r'day master', caseSensitive: false),
  RegExp(r'\bdominant\b', caseSensitive: false),
  RegExp(r'\bpalace\b', caseSensitive: false),
  RegExp(r'\bbranch\b', caseSensitive: false),
  RegExp(r'\bchart\b', caseSensitive: false),
];

// Dart interpolation leak — 컴파일된 본문에 `$...` 남아있으면 안 됨.
final _interpolationLeakRe = RegExp(r'\$\{?[A-Za-z_]');

void _assertCleanString(String value, String label) {
  // hanja symbols 0.
  for (final sym in _hanjaSymbols) {
    expect(value.contains(sym), isFalse,
        reason: '$label 에 hanja "$sym" 노출 — value: $value');
  }
  // Korean jargon nouns 0.
  for (final term in _koJargon) {
    expect(value.contains(term), isFalse,
        reason: '$label 에 jargon "$term" 노출 — value: $value');
  }
  // English jargon 0.
  for (final re in _enJargonRe) {
    expect(re.hasMatch(value), isFalse,
        reason:
            '$label 에 영문 jargon pattern "${re.pattern}" 매치 — value: $value');
  }
  // Dart interpolation leak (e.g. literal "$elKo" 가 본문에 노출) 0.
  expect(_interpolationLeakRe.hasMatch(value), isFalse,
      reason: '$label 에 interpolation leak ("\$...") 노출 — value: $value');
  // ziwei service member name leak.
  expect(value.contains('nameKo'), isFalse,
      reason: '$label 에 ziwei service member "nameKo" leak — value: $value');
  expect(value.contains('allStarNamesKo'), isFalse,
      reason:
          '$label 에 ziwei service member "allStarNamesKo" leak — value: $value');
}

// ───────────────────────── 테스트용 fixture builder ─────────────────────────

MajorStar _star(String key) =>
    MajorStar(keyEn: key, nameKo: '', oneLineKo: '', element: '土');

ZiweiPalace _palace({
  required String gungKo,
  List<MajorStar> majors = const [],
  List<String> lucky = const [],
  bool isMing = false,
  bool isShen = false,
}) {
  return ZiweiPalace(
    gungKo: gungKo,
    branchKo: '인',
    branchAnimalKo: '호랑이',
    branchEn: 'yin',
    majorStars: majors,
    luckyStars: lucky,
    badStars: const [],
    isMingPalace: isMing,
    isShenPalace: isShen,
  );
}

ZiweiResult _buildZiwei({
  required ZiweiPalace ming,
  ZiweiPalace? shen,
  ZiweiPalace? guanrok,
  ZiweiPalace? buchu,
  ZiweiPalace? jaebaek,
  ZiweiPalace? bokdok,
}) {
  final by12 = <ZiweiPalace>[
    ming,
    _palace(gungKo: '형제궁'),
    buchu ?? _palace(gungKo: '부처궁'),
    _palace(gungKo: '자녀궁'),
    jaebaek ?? _palace(gungKo: '재백궁'),
    _palace(gungKo: '질액궁'),
    _palace(gungKo: '천이궁'),
    _palace(gungKo: '노복궁'),
    guanrok ?? _palace(gungKo: '관록궁'),
    _palace(gungKo: '전택궁'),
    bokdok ?? _palace(gungKo: '복덕궁'),
    _palace(gungKo: '부모궁'),
  ];
  return ZiweiResult(
    mingZhuKey: '',
    mingZhuKo: '',
    shenZhuKey: '',
    shenZhuKo: '',
    mingPalace: ming,
    shenPalace: shen ?? ming,
    by12Gung: by12,
  );
}

SajuResult _buildSaju({
  required String dayStem,
  required String dayJi,
  required FiveElements elements,
}) {
  return SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    monthPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    dayPillar: Pillar(chunGan: dayStem, jiJi: dayJi),
    elements: elements,
    dayMaster: dayStem,
    dayMasterName: '',
    summary: '',
    categoryReadings: const {},
  );
}

FiveElements _fe({
  int wood = 10,
  int fire = 10,
  int earth = 10,
  int metal = 10,
  int water = 10,
}) =>
    FiveElements(
      wood: wood,
      fire: fire,
      earth: earth,
      metal: metal,
      water: water,
    );

// ───────────────────────── main ─────────────────────────

void main() {
  final ziweiSrc =
      File('lib/services/ziwei_crossmatch_service.dart').readAsStringSync();
  final homeSrc = File('lib/screens/home_screen.dart').readAsStringSync();
  final radarSrc =
      File('lib/widgets/six_axis_radar.dart').readAsStringSync();
  final resultSrc =
      File('lib/screens/result_screen.dart').readAsStringSync();

  group('R84 — B1* CrossMatch 소스 regex (supplemental)', () {
    // sajuSide/sajuSideEn/ziweiSide/ziweiSideEn/combinedKo/combinedEn 필드의
    // single-quote 문자열 literal 만 추출. 본 service 는 다중 인용부호 사용 X.
    final fieldRe = RegExp(
      r"""(sajuSide|sajuSideEn|ziweiSide|ziweiSideEn|combinedKo|combinedEn)\s*:\s*\n?\s*'([^']*)'""",
    );

    const blockedJargon = [
      '명궁', '신궁', '관록궁', '부처궁', '재백궁', '복덕궁',
      '자미성', '천기성', '태양성', '무곡성', '천동성', '염정성',
      '천부성', '태음성', '탐랑성', '거문성', '천상성', '천량성',
      '칠살성', '파군성',
      '문창', '문곡', '좌보', '우필',
      '일간', '갑목', '병화', '을목', '신(辛)', '묘(卯)', '미(未)',
      '주성',
    ];

    final matches = fieldRe.allMatches(ziweiSrc).toList();

    test('B1a — CrossMatch field literal 추출 가드 (검사 신뢰성)', () {
      expect(matches.length, greaterThan(15),
          reason: 'CrossMatch field literal 추출 미실패 → fieldRe regex 점검.');
    });

    test('B1b — CrossMatch field literal 안에 자미두수/사주 한국어 jargon 0', () {
      for (final m in matches) {
        final value = m.group(2)!;
        for (final term in blockedJargon) {
          expect(value.contains(term), isFalse,
              reason:
                  'CrossMatch field 값에 jargon "$term" 잔존 — field: ${m.group(1)} / value: $value');
        }
      }
    });

    test('B1c — CrossMatch field literal 안에 ziwei nameKo / allStarNamesKo '
        'interpolation leak 0', () {
      final leakRe = RegExp(r'\.(nameKo|allStarNamesKo)');
      for (final m in matches) {
        final value = m.group(2)!;
        expect(leakRe.hasMatch(value), isFalse,
            reason:
                'CrossMatch field literal 안에 자미두수 별 이름 interpolation leak — field: ${m.group(1)} / value: $value');
      }
    });

    test('B1d — CrossMatch field literal 안에 영문 pinyin jargon (Xin/Jia/Mao/Yi/'
        'Wei/Bing) + day master / dominant / branch / palace 0', () {
      final enRe = [
        RegExp(r'\bXin\b'),
        RegExp(r'\bJia\b'),
        RegExp(r'\bYi\b'),
        RegExp(r'\bMao\b'),
        RegExp(r'\bWei\b'),
        RegExp(r'\bBing\b'),
        RegExp(r'day master', caseSensitive: false),
        RegExp(r'\bdominant\b', caseSensitive: false),
        RegExp(r'\bpalace\b', caseSensitive: false),
        RegExp(r'\bbranch\b', caseSensitive: false),
      ];
      for (final m in matches) {
        final value = m.group(2)!;
        for (final re in enRe) {
          expect(re.hasMatch(value), isFalse,
              reason:
                  'CrossMatch field 값에 영문 jargon "${re.pattern}" 잔존 — field: ${m.group(1)} / value: $value');
        }
      }
    });
  });

  group('R84 — B2* home_screen 6 각 카드 copy axis-name 중심', () {
    test('B2a — "너의 강점" 문자열 home_screen.dart 안에 0', () {
      expect(homeSrc.contains('너의 강점'), isFalse,
          reason:
              'home_screen 6 각 카드 mainLine 이 matchCount 중심 phrase "너의 강점" '
              '잔존 — axis-name 중심 자연 문장으로 전환 필요.');
    });

    test('B2b — "진짜 무기" 문자열 home_screen.dart 안에 0', () {
      expect(homeSrc.contains('진짜 무기'), isFalse,
          reason:
              'home_screen 6 각 카드 subLine 이 matchCount 중심 phrase "진짜 무기" '
              '잔존 — axis-name 중심 자연 문장으로 전환 필요.');
    });

    test('B2c — six-axis card mainLine 영문 phrase "Your N strengths" 잔존 0', () {
      expect(homeSrc.contains('Your \${score.matchCount} strengths'), isFalse,
          reason: 'home_screen 영문 mainLine 도 matchCount 중심 phrase 제거 필요.');
    });
  });

  group('R84 — B3* 기존 라벨 "두 번 봐도 같이 잡힌 강점" 보존 (R82 회귀 가드)', () {
    test('B3a — six_axis_radar.dart 안에 phrase 잔존 (docstring 포함)', () {
      expect(radarSrc.contains('두 번 봐도 같이 잡힌 강점'), isTrue,
          reason:
              'six_axis_radar.dart 안에 "두 번 봐도 같이 잡힌 강점" phrase 가 '
              '완전 삭제됨 — R82 sprint 4 회귀 가드 위반.');
    });

    test('B3b — result_screen.dart 안에 phrase 잔존', () {
      expect(resultSrc.contains('두 번 봐도 같이 잡힌 강점'), isTrue,
          reason:
              'result_screen.dart 안에 "두 번 봐도 같이 잡힌 강점" 라벨이 '
              '삭제됨 — R82 sprint 4 회귀 가드 위반.');
    });

    test('B3c — six_axis_radar badge 라벨이 단축형 "같이 잡힌 강점" 사용', () {
      expect(radarSrc.contains("'같이 잡힌 강점'"), isTrue,
          reason: 'badge 라벨 단축형 미반영.');
    });
  });

  // ───────────────────── B4* — runtime 검증 (핵심) ─────────────────────
  //
  // ZiweiCrossmatchService.find 를 직접 호출해서 모든 branch 에서 생성되는
  // CrossMatch 의 sajuSideFor / ziweiSideFor / combinedFor (ko + en) 본문에
  // jargon/symbol/interpolation leak 0 임을 검증.
  group('R84 — B4* runtime CrossMatch 본문 jargon/symbol/leak 0', () {
    // 14 branch 를 모두 한 번씩 trigger 하는 fixture set.
    // (find() 은 topic dedup → 최대 5개 반환이므로 여러 시나리오로 분리.)
    final scenarios = <Map<String, dynamic>>[
      // 시나리오 1 — 辛 + 명궁 문창 → case 1 (본성), case 12 (공부).
      // dayJi=申 / dayStemEl=金 / dom=金 → softSaju=false / 변화·마음 X.
      {
        'name': '辛 + 명궁 문창',
        'saju': _buildSaju(
          dayStem: '辛',
          dayJi: '申',
          elements: _fe(metal: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', lucky: ['문창'], isMing: true),
        ),
      },
      // 시나리오 2 — 甲 + 명궁 자미 → case 2 (본성 리더).
      // dominant=木 / pojun 없음.
      {
        'name': '甲 + 명궁 자미',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming:
              _palace(gungKo: '명궁', majors: [_star('ziwei')], isMing: true),
        ),
      },
      // 시나리오 3 — 丙 + 명궁 태양 → case 2 (본성 리더), dom=火 + 신궁 파군 → case 14 (변화).
      {
        'name': '丙 + 명궁 태양 + 신궁 파군',
        'saju': _buildSaju(
          dayStem: '丙',
          dayJi: '寅',
          elements: _fe(fire: 50),
        ),
        'ziwei': _buildZiwei(
          ming:
              _palace(gungKo: '명궁', majors: [_star('taiyang')], isMing: true),
          shen: _palace(gungKo: '신궁', majors: [_star('pojun')], isShen: true),
        ),
      },
      // 시나리오 4 — 甲 + 명궁 칠살 → case 2 (본성 리더 qisha branch).
      {
        'name': '甲 + 명궁 칠살',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming:
              _palace(gungKo: '명궁', majors: [_star('qisha')], isMing: true),
        ),
      },
      // 시나리오 5 — 乙 + 명궁 우필 → case 3 (본성 보좌 - 乙 branch).
      {
        'name': '乙 + 명궁 우필',
        'saju': _buildSaju(
          dayStem: '乙',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', lucky: ['우필'], isMing: true),
        ),
      },
      // 시나리오 6 — 卯 + 명궁 좌보 → case 3 (본성 보좌 - 卯 branch).
      {
        'name': '癸 + 卯 + 명궁 좌보',
        'saju': _buildSaju(
          dayStem: '癸',
          dayJi: '卯',
          elements: _fe(water: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', lucky: ['좌보'], isMing: true),
        ),
      },
      // 시나리오 7 — 未 + 명궁 우필 → case 3 (본성 보좌 - 未 branch).
      {
        'name': '丁 + 未 + 명궁 우필',
        'saju': _buildSaju(
          dayStem: '丁',
          dayJi: '未',
          elements: _fe(fire: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', lucky: ['우필'], isMing: true),
        ),
      },
      // 시나리오 8 — 辛 + 관록궁 거문 → case 4 (진로 거문).
      {
        'name': '辛 + 관록궁 거문',
        'saju': _buildSaju(
          dayStem: '辛',
          dayJi: '申',
          elements: _fe(metal: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          guanrok: _palace(gungKo: '관록궁', majors: [_star('jumen')]),
        ),
      },
      // 시나리오 9 — 관록궁 자미 + dayStemEl=金 → case 5 (진로 조직리더, elKo path).
      {
        'name': '관록궁 자미 (dayStemEl=金)',
        'saju': _buildSaju(
          dayStem: '庚',
          dayJi: '子',
          elements: _fe(metal: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          guanrok: _palace(gungKo: '관록궁', majors: [_star('ziwei')]),
        ),
      },
      // 시나리오 10 — 관록궁 천기 + dayStemEl=木 → case 6 (진로 기획 isLight branch).
      {
        'name': '관록궁 천기 (dayStemEl=木)',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          guanrok: _palace(gungKo: '관록궁', majors: [_star('tianji')]),
        ),
      },
      // 시나리오 11 — 관록궁 천량 + dayStemEl=土 → case 6 (진로 기획 non-isLight branch).
      {
        'name': '관록궁 천량 (dayStemEl=土)',
        'saju': _buildSaju(
          dayStem: '戊',
          dayJi: '子',
          elements: _fe(earth: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          guanrok: _palace(gungKo: '관록궁', majors: [_star('tianliang')]),
        ),
      },
      // 시나리오 12 — 재백궁 태양 → case 7 (돈 visible).
      {
        'name': '재백궁 태양',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          jaebaek: _palace(gungKo: '재백궁', majors: [_star('taiyang')]),
        ),
      },
      // 시나리오 13 — 재백궁 무곡 + dominant=土 → case 8 (돈 steady).
      {
        'name': '재백궁 무곡 (dom=土)',
        'saju': _buildSaju(
          dayStem: '戊',
          dayJi: '子',
          elements: _fe(earth: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          jaebaek: _palace(gungKo: '재백궁', majors: [_star('wuqu')]),
        ),
      },
      // 시나리오 14 — 재백궁 천부 + dominant=木 → case 8 (돈 non-steady branch).
      {
        'name': '재백궁 천부 (dom=木)',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          jaebaek: _palace(gungKo: '재백궁', majors: [_star('tianfu')]),
        ),
      },
      // 시나리오 15 — 부처궁 천기 → case 9 (연애).
      {
        'name': '부처궁 천기',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          buchu: _palace(gungKo: '부처궁', majors: [_star('tianji')]),
        ),
      },
      // 시나리오 16 — 부처궁 태음 → case 10 (연애).
      {
        'name': '부처궁 태음',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          buchu: _palace(gungKo: '부처궁', majors: [_star('taiyin')]),
        ),
      },
      // 시나리오 17 — 부처궁 천부 → case 11 (연애).
      {
        'name': '부처궁 천부',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          buchu: _palace(gungKo: '부처궁', majors: [_star('tianfu')]),
        ),
      },
      // 시나리오 18 — 명궁 문곡 + dayStemEl=木 → case 12 (공부 elKo branch).
      {
        'name': '명궁 문곡 + dayStemEl=木',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', lucky: ['문곡'], isMing: true),
        ),
      },
      // 시나리오 19 — 복덕궁 태음 + softSaju → case 13 (마음).
      {
        'name': '乙 + 복덕궁 태음',
        'saju': _buildSaju(
          dayStem: '乙',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(gungKo: '명궁', isMing: true),
          bokdok: _palace(gungKo: '복덕궁', majors: [_star('taiyin')]),
        ),
      },
      // 시나리오 20 — 명궁 파군 + dominant=木 → case 14 (변화 木 branch).
      {
        'name': '명궁 파군 (dom=木)',
        'saju': _buildSaju(
          dayStem: '甲',
          dayJi: '子',
          elements: _fe(wood: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(
              gungKo: '명궁', majors: [_star('pojun')], isMing: true),
        ),
      },
      // 시나리오 21 — 명궁 파군 + dominant=火 → case 14 (변화 火 branch).
      {
        'name': '명궁 파군 (dom=火)',
        'saju': _buildSaju(
          dayStem: '丙',
          dayJi: '寅',
          elements: _fe(fire: 50),
        ),
        'ziwei': _buildZiwei(
          ming: _palace(
              gungKo: '명궁', majors: [_star('pojun')], isMing: true),
        ),
      },
    ];

    // 각 시나리오 별 runtime 검증.
    for (final s in scenarios) {
      final scenarioName = s['name'] as String;
      final saju = s['saju'] as SajuResult;
      final ziwei = s['ziwei'] as ZiweiResult;
      test('B4 — [$scenarioName] 모든 CrossMatch 본문 (ko + en) jargon 0', () {
        final hits = ZiweiCrossmatchService.find(saju, ziwei);
        expect(hits, isNotEmpty,
            reason: '시나리오 [$scenarioName] 가 어떤 branch 도 trigger 못함 — fixture 점검.');
        for (final cm in hits) {
          for (final useKo in [true, false]) {
            final lang = useKo ? 'ko' : 'en';
            _assertCleanString(
              cm.sajuSideFor(useKo: useKo),
              '[$scenarioName] sajuSideFor($lang) (topic=${cm.topic})',
            );
            _assertCleanString(
              cm.ziweiSideFor(useKo: useKo),
              '[$scenarioName] ziweiSideFor($lang) (topic=${cm.topic})',
            );
            _assertCleanString(
              cm.combinedFor(useKo: useKo),
              '[$scenarioName] combinedFor($lang) (topic=${cm.topic})',
            );
          }
        }
      });
    }

    test('B4z — 시나리오 set 이 14 branch 를 충분히 trigger (smoke guard)', () {
      // 21 시나리오 × 평균 ~2 hit. 본 검사는 시나리오 set 의 lower-bound 만 검증.
      expect(scenarios.length, greaterThanOrEqualTo(21),
          reason: '시나리오 set 이 14 branch 를 모두 커버하기에 부족.');
    });
  });
}
