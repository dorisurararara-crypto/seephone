// R106 P4a (rewrite) — 궁합 카피 v5 voice 전면 재작성 회귀 가드.
//
// R106 design doc §2 / §3 / §9 ground truth:
//   궁합(일반·최애) 카피 corpus 전체를 v5 voice 로 재작성한다.
//   - v5 궁합 voice = 「두 사주의 관계가 무엇인지(합·충·삼합·형·상생·상극·비화·중립)
//     + 그게 관계에서 어떻게 작동하기 쉬운지(경향) + 어떻게 다루면 좋은지(조언)」.
//   - 절대 금지(codex 위반유형 A~E):
//       A. 관계 결과·미래 단정 — "오래 간다 / 단단해져요 / 깊어져요 / 멀어져요 /
//          다툼이 줄어요·사라져요 / 시간이 갈수록 ~해진다".
//       B. 상대·나의 변화 단정 — "상대가 자라요 / 자라는 모습 / 내 결정이 정해져요".
//       C. 자녀·결혼 결과 단정 — "결혼이 단단해져요 / 자녀가 ~한 색을 가져요".
//       D. 운명 voice — "운명 같은 / fated / destined".
//       E. 메타 — "사주적으로 / 사주가 권하는 / in saju / the chart ~".
//   - 허용: 두 사주의 실제 관계 anchor 사실(합·충·오행·일주), 경향(헷지: ~기 쉬운
//     자리), 조건(만약 ~하면), 조언(미리 영역을 나눠두면 …).
//   - QA 기준: 두 사람 관계가 그날·앞으로 어떻든 틀린 문장이 0.
//
// 본 가드는 실제 Dart 합성 path 의 *출력 본문*을 직접 측정한다:
//   analyzeCompatForTest      = compatibility_screen `_analyze`  (일반 궁합 5섹션)
//   composeKpopVerdictForTest = kpop_compat `_composeVerdict`     (최애 궁합 verdict)
// 두 path 모두 합성 마지막에 CompatV5Service.soften 을 통과한다 — 즉 모든
// 궁합 fragment 가 출력 시점에 v5 voice 로 재작성된다.
//
// Release-blocking assertions:
//   ① 일반 궁합 — 위반유형 A~E 0 (pillar 짝 전수, KO/EN).
//   ② 최애 궁합 — 위반유형 A~E 0 (celebrities.json 전 셀럽 × 5 band × KO/EN).
//   ③ 거짓말 0 — 본문이 실제 합충/오행 anchor 어휘에 근거 + 한자 즉시 풀이.
//   ④ 회귀 — 5섹션 구조 보존 + element-relation 변별(다른 짝 = 다른 본문) 보존.
//   ⑤ source 전수 — 두 궁합 screen 카피 소스에 단정·메타 패턴 0.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/compat_v5_service.dart';
import 'package:pillarseer/screens/reports/compatibility_screen.dart' as compat;
import 'package:pillarseer/screens/reports/kpop_compat_screen.dart' as kpop;

// ───────────────── fixtures ─────────────────

/// 사용자 R75 골든 — 1995-10-27 男 17시 辛卯 일주.
SajuResult _goldenUser() {
  return const SajuResult(
    yearPillar: Pillar(chunGan: '乙', jiJi: '亥'),
    monthPillar: Pillar(chunGan: '丙', jiJi: '戌'),
    dayPillar: Pillar(chunGan: '辛', jiJi: '卯'),
    hourPillar: Pillar(chunGan: '丁', jiJi: '酉'),
    elements: FiveElements(wood: 16, fire: 21, earth: 17, metal: 41, water: 4),
    dayMaster: '辛',
    dayMasterName: 'Metal Rabbit',
    summary: 'Polished metal grain.',
    categoryReadings: {},
  );
}

/// 임의 일주의 SajuResult — `_analyze` 가 day60ji + dayPillar 만 사용하므로 valid.
SajuResult _mkUser(String dayPillar) {
  final gan = dayPillar[0];
  final ji = dayPillar[1];
  return SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    monthPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    dayPillar: Pillar(chunGan: gan, jiJi: ji),
    elements: const FiveElements(
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
    dayMaster: gan,
    dayMasterName: '_',
    summary: '_',
    categoryReadings: const {},
  );
}

const List<String> _gans = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> _jis = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'
];

/// 60갑자 — k=0..59 → gan[k%10]·ji[k%12].
List<String> _all60Gapja() {
  final out = <String>[];
  for (var k = 0; k < 60; k++) {
    out.add('${_gans[k % 10]}${_jis[k % 12]}');
  }
  return out;
}

/// 60갑자 × 60갑자 = 3600 짝 전수 — 모든 element relation / 합·충·형·삼합 분기를
/// 빠짐없이 커버한다. codex mandate: offset 샘플 금지, 진짜 60×60 전수.
List<List<String>> _pillarPairs() {
  final g = _all60Gapja();
  final out = <List<String>>[];
  for (final a in g) {
    for (final b in g) {
      out.add([a, b]);
    }
  }
  return out;
}

List<Map<String, dynamic>> _loadCelebs() {
  final raw = File('assets/data/celebrities.json').readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

// ───────────────── v5 위반 패턴 (codex 위반유형 A~E) ─────────────────
//
// 각 패턴은 *출력 본문*에 한 번이라도 나오면 fail. QA 기준: 두 사람 관계가
// 그날·앞으로 어떻든 틀리면 안 되는 문장만 잡는다. 조건형("~기 쉬운 자리",
// "만약 ~하면", "~다 느끼면")·조언("~하는 데 도움돼요")은 v5 허용 — 잡지 않는다.

/// 위반유형 A — 관계 결과·미래 단정 (KO).
/// "단단해져요 / 깊어져요 / 진해져요" = 관계가 그렇게 "된다"는 단정. 종결형만 잡는다
/// (조건 "단단해진다 느끼면"·헷지 "단단해지기 좋아요" 는 제외).
final List<RegExp> _forbidAKo = <RegExp>[
  RegExp(r'단단해져요'),
  RegExp(r'깊어져요'),
  RegExp(r'진해져요'),
  RegExp(r'또렷해져요'),
  RegExp(r'점점 진해진다는'),
  RegExp(r'시간이 (지날|갈)수록 [^.]*?(단단해지는|깊어지는|진해지는)'),
  RegExp(r'누구도 못 깨는'),
  RegExp(r'평생 인연'),
  RegExp(r'평생 단단'),
  RegExp(r'자연스럽게 (거리가 )?멀어져요'),
  RegExp(r'그대로 (거리가 )?(멀어져요|벌어져요)'),
  RegExp(r'자연스럽게 거리가 벌어져요'),
  RegExp(r'다툼이 안 와요'),
  RegExp(r'다툼이 거의 사라'),
  RegExp(r'충돌이 거의 사라'),
  RegExp(r'갈등이 줄어요'),
  RegExp(r'빈도가 절반'),
  RegExp(r'한 번에 폭발해요'),
  RegExp(r'큰 한 마디가 폭발해요'),
  RegExp(r'갑자기 폭발하는 결'),
  RegExp(r'의견이 자주 엇갈려요'),
  RegExp(r'관계가 유지돼요'),
  RegExp(r'자연 소멸'),
  RegExp(r'정답이에요'),
  RegExp(r'정답인 만남'),
];

/// 위반유형 A — 관계 결과·미래 단정 (EN).
final List<RegExp> _forbidAEn = <RegExp>[
  RegExp(r'\bdeepens\b'),
  RegExp(r'grows? (deeper|stronger|tougher|fastest)\b'),
  RegExp(r'\boutlast(s)? (loud|many)'),
  RegExp(r'the bond hardens over time into something hard to break'),
  RegExp(r'gets better in year (five|ten)'),
  RegExp(r'\bbreak-ups\b'),
  RegExp(r'halve clash frequency'),
  RegExp(r'shrinks 80% of'),
  RegExp(r'kills (most|half) of the'),
  RegExp(r'distance grows by default', caseSensitive: false),
  // R106 P4a EN 재작성 — codex 확정 위반군.
  RegExp(r'will be visible in'),
  RegExp(r'almost unbreakable'),
  RegExp(r'(mood )?lifts faster'),
  RegExp(r'\bfor life\b'),
  RegExp(r'grows only by choice'),
  RegExp(r'decides what .{0,40}? become'),
  RegExp(r'stops voicing opinions'),
  RegExp(r'closeness grows the more'),
];

/// 위반유형 B — 상대·나의 변화 단정 (KO).
final List<RegExp> _forbidBKo = <RegExp>[
  RegExp(r'자라는 모습'),
  RegExp(r'능력을 펴요'),
  RegExp(r'결과물이 살아나요'),
  RegExp(r'내 결정이 정해져요'),
  RegExp(r'미루던 결정이 자연스럽게 정해지는'),
  RegExp(r'한 뼘씩 자라는 게 보일'),
  RegExp(r'네가 더 단단해지는 관계'),
];

/// 위반유형 B — 상대·나의 변화 단정 (EN).
final List<RegExp> _forbidBEn = <RegExp>[
  RegExp(r'watching .*? grow steadies you'),
  RegExp(r'catches up to themselves beside you'),
  RegExp(r'becomes their best self beside you'),
];

/// 위반유형 C — 자녀·결혼 결과 단정 (KO).
final List<RegExp> _forbidCKo = <RegExp>[
  RegExp(r'결혼이 단단해져요'),
  RegExp(r'자녀가 자기 결을 또렷이 가지는 결'),
  RegExp(r'단단한 자기 색을 가져요'),
  RegExp(r'통합해 더 단단해져요'),
];

/// 위반유형 C — 자녀·결혼 결과 단정 (EN).
/// R106 P4a — 직전 EN 은 A·B·D·E 만 스캔하고 C 가 누락돼 있었다. 자녀가 그렇게
/// "된다"는 결과 단정("Children absorb/inherit/thrive/sense/...")을 잡는다.
final List<RegExp> _forbidCEn = <RegExp>[
  RegExp(r'\bChildren absorb\b'),
  RegExp(r'children absorb the parental'),
  RegExp(r'children inherit'),
  RegExp(r'\bChildren thrive\b'),
  RegExp(r'\bChildren sense\b'),
  RegExp(r'children grow their own grain'),
  RegExp(r'\bChildren get a quiet floor'),
];

/// 위반유형 D — 운명 voice.
final List<RegExp> _forbidDKo = <RegExp>[RegExp(r'운명')];
// caseSensitive:false — 'Fated'/'Fate' 같은 문장 첫 글자 대문자형도 잡는다.
final List<RegExp> _forbidDEn = <RegExp>[
  RegExp(r'\bfated\b', caseSensitive: false),
  RegExp(r'\bfate\b', caseSensitive: false),
  RegExp(r'\bdestined\b', caseSensitive: false),
];

/// 위반유형 E — 메타 (사주·chart 를 화자처럼 노출).
/// 주의: "두 사주가 [관계]" 처럼 두 사주의 관계를 *묘사*하는 건 v5 허용.
/// saju/chart 가 *주체*("권한다·말한다·좋다고")일 때만 잡는다.
final List<RegExp> _forbidEKo = <RegExp>[
  RegExp(r'사주적으로'),
  RegExp(r'사주가 권하'),
  RegExp(r'사주가 좋다고'),
  RegExp(r'사주가 무난하게 좋다고'),
  RegExp(r'사주가 가장 강하게 권하는'),
  RegExp(r'본 리딩'),
  RegExp(r'구조예요'),
  RegExp(r'구조죠'),
  RegExp(r'구조로 봅니다'),
];
final List<RegExp> _forbidEEn = <RegExp>[
  RegExp(r'\bin saju\b'),
  RegExp(r'\bsaju recommends\b', caseSensitive: false),
  RegExp(r'\bSaju calls\b'),
  RegExp(r'\bSaju-favorable\b'),
  RegExp(r'\bSaju triad\b'),
  RegExp(r'[Dd]irect saju signal'),
  RegExp(r'decided by saju'),
  RegExp(r'the chart (recommends|asks for|bookmarks|rates|stamps|etches|endorses)'),
  RegExp(r'\bChart signals?\b'),
  RegExp(r'etches in by the chart'),
  RegExp(r'by chart signal'),
  RegExp(r'by chart tone'),
  // R106 P4a EN 재작성 — chart 를 화자·주체로 노출하는 메타.
  RegExp(r'in the chart', caseSensitive: false),
  RegExp(r'your chart', caseSensitive: false),
  RegExp(r'\bchart as\b'),
  RegExp(r'chart-side'),
  RegExp(r'chart pull'),
  RegExp(r'chart event'),
];

/// KO 전 위반유형 통합.
List<List<RegExp>> _forbidKoAll() => [
      _forbidAKo,
      _forbidBKo,
      _forbidCKo,
      _forbidDKo,
      _forbidEKo,
    ];

/// EN 전 위반유형 통합.
/// R106 P4a — C(자녀 결과 단정) 그룹 신규 추가. 직전 EN 스캔은 A·B·D·E 만.
List<List<RegExp>> _forbidEnAll() => [
      _forbidAEn,
      _forbidBEn,
      _forbidCEn,
      _forbidDEn,
      _forbidEEn,
    ];

/// [text] 에서 위반유형 A~E 패턴을 스캔, 첫 위반 (label) 을 반환. 없으면 null.
String? _firstViolation(String text, {required bool useKo}) {
  final groups = useKo ? _forbidKoAll() : _forbidEnAll();
  const koLabels = ['A', 'B', 'C', 'D', 'E'];
  const enLabels = ['A', 'B', 'C', 'D', 'E'];
  final labels = useKo ? koLabels : enLabels;
  for (var g = 0; g < groups.length; g++) {
    for (final r in groups[g]) {
      final m = r.firstMatch(text);
      if (m != null) {
        return '위반유형 ${labels[g]} — "${m.group(0)}"';
      }
    }
  }
  return null;
}

// ───────────────── tests ─────────────────

void main() {
  // ── ① 일반 궁합 — v5 voice 위반유형 A~E 0 (pillar 짝 전수, KO/EN) ──
  test('① 일반 궁합 — 위반유형 A~E 0 (KO/EN, 60×60 전수)', () {
    final pairs = _pillarPairs();
    expect(pairs.length, 3600,
        reason: '60갑자 × 60갑자 전수 — 모든 element-relation 분기 커버');
    var checked = 0;
    for (final p in pairs) {
      final partner = _mkUser(p[1]);
      final user = _mkUser(p[0]);
      for (final useKo in [true, false]) {
        final a = compat.analyzeCompatForTest(
          me: user,
          partner: partner,
          useKo: useKo,
          partnerName: useKo ? '민서' : 'Minseo',
        );
        final full = [
          a.summary,
          a.attract,
          a.friction,
          a.loveMarriage,
          ...a.actions,
        ].join('\n');
        final v = _firstViolation(full, useKo: useKo);
        expect(v, isNull,
            reason: '일반 궁합 $v 검출 — 짝 ${p[0]}×${p[1]} (useKo=$useKo). '
                'R106 v5 §2/§3/§9 위반 — 두 사람 관계가 그날·앞으로 어떻든 '
                '틀리면 안 됨.');
        checked++;
      }
    }
    expect(checked, 7200);
  });

  // ── ② 최애 궁합 — v5 voice 위반유형 A~E 0 (전 셀럽 × 5 band × KO/EN) ──
  test('② 최애 궁합 — 위반유형 A~E 0 (celebrities.json 전 셀럽 × 5 band × KO/EN)',
      () {
    final celebs = _loadCelebs();
    expect(celebs.length, greaterThan(20));
    final me = _goldenUser();
    // score 5 band (90/78/62/48/30) — band-prefix pool 5 band 전수 커버.
    const scores = [90, 78, 62, 48, 30];
    var checked = 0;
    for (final star in celebs) {
      for (final score in scores) {
        for (final useKo in [true, false]) {
          final verdict = kpop.composeKpopVerdictForTest(
            me: me,
            starJson: star,
            score: score,
            rank: 3,
            useKo: useKo,
          );
          if (verdict.isEmpty) continue;
          final v = _firstViolation(verdict, useKo: useKo);
          expect(v, isNull,
              reason: '최애 궁합 $v 검출 — 셀럽 ${star['id']} score=$score '
                  '(useKo=$useKo). R106 v5 §2/§3/§9 위반.');
          checked++;
        }
      }
    }
    // 전 셀럽 × 5 band × 2 lang. celebrities.json 전체가 커버되어야 함.
    expect(checked, greaterThanOrEqualTo(celebs.length * scores.length * 2),
        reason: '전 셀럽 × 5 band × 2 lang 전수 스캔 — 누락 없이 모두 검증');
  });

  test('② 최애 궁합 — detail 본문도 일반 궁합 _analyze 통해 v5 통과 (전 셀럽)', () {
    // R101: 최애 궁합 detail dialog 는 CompatDetailSection (= _analyze) 사용.
    // 셀럽 일주 → _analyze 직결 path 를 celebrities.json 전체에 대해 전수 스캔.
    final celebs = _loadCelebs();
    final me = _goldenUser();
    for (final star in celebs) {
      final dp = (star['dayPillar'] as String?) ?? '';
      if (dp.length < 2) continue;
      final partner = _mkUser(dp);
      for (final useKo in [true, false]) {
        final a = compat.analyzeCompatForTest(
          me: me,
          partner: partner,
          useKo: useKo,
          partnerName: useKo ? '셀럽' : 'Star',
        );
        final full = [
          a.summary,
          a.attract,
          a.friction,
          a.loveMarriage,
          ...a.actions,
        ].join('\n');
        final v = _firstViolation(full, useKo: useKo);
        expect(v, isNull,
            reason: '최애 detail _analyze $v — 셀럽 ${star['id']} '
                '(useKo=$useKo).');
      }
    }
  });

  // ── ③ 거짓말 0 — 본문이 실제 합충/오행 anchor 어휘에 근거 ──
  test('③ 일반 궁합 — 본문이 실제 합충/오행 anchor 어휘에 근거 + 한자 즉시 풀이', () {
    final me = _mkUser('甲子'); // 木 / 子
    // partner 甲午 — 子午 충.
    final clash = compat.analyzeCompatForTest(
      me: me,
      partner: _mkUser('甲午'),
      useKo: true,
      partnerName: '윤아',
    );
    expect(clash.friction.contains('충'), isTrue,
        reason: '子午 충 짝 — friction 본문에 "충" anchor 가 드러나야 함.');
    // partner 丙寅 — 木→火 상생.
    final gen = compat.analyzeCompatForTest(
      me: me,
      partner: _mkUser('丙寅'),
      useKo: true,
      partnerName: '윤아',
    );
    final genBody = '${gen.summary}\n${gen.attract}';
    expect(
        genBody.contains('木') ||
            genBody.contains('火') ||
            genBody.contains('상생'),
        isTrue,
        reason: '木→火 상생 짝 — 오행/상생 anchor 가 본문에 드러나야 함.');
    // 한자 즉시 풀이 — "충" 등장 시 풀이 어휘(밤·낮 / 리듬 / 자리 등)도 함께.
    expect(
        clash.friction.contains('밤') ||
            clash.friction.contains('낮') ||
            clash.friction.contains('리듬') ||
            clash.friction.contains('자리'),
        isTrue,
        reason: '한자 anchor 는 즉시 풀이되어야 함 (R86 보존).');
  });

  // ── ④ 회귀 — 5섹션 구조 + element-relation 변별 보존 ──
  test('④ 회귀 — 5섹션 비어있지 않음 + 같은 element-relation 다른 사주 본문 다름', () {
    final me = _mkUser('甲子');
    final a1 = compat.analyzeCompatForTest(
        me: me, partner: _mkUser('丙寅'), useKo: true, partnerName: '윤아');
    final a2 = compat.analyzeCompatForTest(
        me: me, partner: _mkUser('丁卯'), useKo: true, partnerName: '윤아');
    for (final a in [a1, a2]) {
      expect(a.summary.trim().isNotEmpty, isTrue);
      expect(a.attract.trim().isNotEmpty, isTrue);
      expect(a.friction.trim().isNotEmpty, isTrue);
      expect(a.loveMarriage.trim().isNotEmpty, isTrue);
      expect(a.actions.length, greaterThanOrEqualTo(4));
    }
    // 둘 다 木→火 상생이지만 day60ji 짝이 달라 본문이 달라야 함 (R100 보존).
    expect(a1.summary == a2.summary, isFalse,
        reason: '같은 상생 분기라도 다른 사주 짝은 다른 본문 (R100 회귀).');
  });

  test('④ 회귀 — soften 은 anchor 어휘·길이를 파괴하지 않음', () {
    // 정규화는 치환만 — anchor 어휘·본문 길이가 크게 줄지 않아야.
    final me = _mkUser('辛卯');
    final a = compat.analyzeCompatForTest(
        me: me, partner: _mkUser('丙申'), useKo: true, partnerName: '민서');
    expect(a.summary.length, greaterThan(40));
    expect(a.loveMarriage.length, greaterThan(80));
    // 합·충·오행 anchor 어휘가 5섹션 어딘가에 보존되어 있어야 함.
    final body = [a.summary, a.attract, a.friction, a.loveMarriage].join();
    expect(
        body.contains('합') ||
            body.contains('충') ||
            body.contains('상생') ||
            body.contains('상극') ||
            body.contains('비화') ||
            body.contains('木') ||
            body.contains('火') ||
            body.contains('土') ||
            body.contains('金') ||
            body.contains('水'),
        isTrue,
        reason: 'v5 재작성 후에도 두 사주의 실제 관계 anchor 어휘는 보존.');
  });

  // ── ⑤ source 전수 — 두 궁합 screen 카피 소스에 단정·메타 패턴 0 ──
  // compatibility_screen.dart + kpop_compat_screen.dart 카피 소스에 단정·메타
  // 패턴이 한 건이라도 남으면 FAIL. 코드 주석(`//`)은 제외 — production 카피만.
  test('⑤ source 전수 — 두 궁합 screen 카피 소스에 단정·메타 패턴 0', () {
    // 위반유형 A~E 의 source-level 단정·메타 패턴군 (regex 단편).
    const forbiddenSrc = <String>[
      // A — 관계 결과·미래 단정.
      '평생 인연',
      '평생 단단한',
      '큰 다툼을 막',
      '큰 갈등이 거의',
      '큰 충돌이 거의 사라',
      '관계가 한 단계 깊',
      '더 건강하게 자라',
      '관계가 유지',
      '자연 소멸',
      '폭발할 때',
      '한 번에 폭발해요',
      '헤어졌다가 다시 만나는',
      '정답인 만남',
      '게 정답이에요',
      '점점 진해진다는',
      '누구도 못 깨는',
      // B — 변화 단정.
      '상대가 능력을 펴요',
      '상대가 깊어져요',
      // D — 운명 voice.
      "처음엔 '운명' 같지만",
      '운명 같은 끌림이지만',
      '운명에 기대기보다',
      // E — 메타.
      '구조예요',
      '구조죠',
      '사주적으로',
      '사주가 권하',
      'the chart bookmark',
      'the chart rate',
      'the chart stamp',
      'the chart etch',
      'the chart ask',
      'the chart recommend',
      'in saju',
      'Saju calls',
      'Saju recommends',
      'Saju triad',
      'Direct saju signal',
      'decided by saju',
      'Chart signals',
      'Fated-pull',
      'etches in by the chart',
      // R106 P4a EN 재작성 — chart 메타 + 관계/자녀 결과 단정 (EN source).
      'in the chart',
      'chart-side',
      'chart pull',
      'chart event',
      'How your chart receives',
      'meets your chart',
      'as the third voice in the room',
      'will be visible in',
      'almost unbreakable',
      'lifts faster than it would alone',
      'grows fastest',
      'grows only by choice',
      'keep beside you for life',
      'Children absorb the parental',
      'children inherit that ease',
      'Children thrive when',
      'Children sense parental friction',
      'children grow their own grain',
      'Children get a quiet floor',
      'decides what the two of you become',
      // R106 P4a EN 전면 재작성 (instance-fixing 비수렴 → corpus 통째 재작성) —
      // codex 8.1 verdict 잔존 위반군 + grain 남용 회귀 가드.
      'two charts',
      'charts can carry',
      'eight-character chart',
      'child-palace',
      'Children tend to sense',
      'decides depth',
      'decide depth',
      'grows only when',
      'break-and-rejoin',
      'lifelong',
      'You control them',
      'voice disappears',
      'essentially disappears',
      'growth engine',
      'grain',
    ];
    for (final path in const [
      'lib/screens/reports/compatibility_screen.dart',
      'lib/screens/reports/kpop_compat_screen.dart',
    ]) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // 코드 주석 라인은 제외 (mandate: "코드 주석 제외").
        if (line.trimLeft().startsWith('//')) continue;
        for (final bad in forbiddenSrc) {
          expect(line.contains(bad), isFalse,
              reason: '$path:${i + 1} — 카피 소스에 단정/메타 "$bad" 잔존. '
                  'R106 P4a §2/§3 위반.');
        }
      }
    }
  });

  // ── CompatV5Service.soften 단위 검증 ──
  group('CompatV5Service.soften 단위', () {
    test('KO — 메타 "사주적으로" 치환', () {
      const input = '사주적으로 결혼 잘 어울리는 결이에요.';
      final out = CompatV5Service.soften(input, useKo: true);
      expect(out.contains('사주적으로'), isFalse);
      expect(out.isNotEmpty, isTrue);
    });

    test('KO — 관계 결과 단정 verb 치환 (단단해져요/깊어져요/진해져요)', () {
      for (final input in const [
        '시간이 갈수록 결이 단단해져요.',
        '같이 보내면 자연스럽게 깊어져요.',
        '시간이 갈수록 결이 진해져요.',
      ]) {
        final out = CompatV5Service.soften(input, useKo: true);
        expect(out.contains('단단해져요'), isFalse, reason: input);
        expect(out.contains('깊어져요'), isFalse, reason: input);
        expect(out.contains('진해져요'), isFalse, reason: input);
        // 헷지·조언형으로 전환되어야 함.
        expect(out.contains('좋아요') || out.contains('도움돼요'), isTrue,
            reason: '단정 → 경향·조언형으로 전환: $input');
      }
    });

    test('KO — break-up 미래 단정 치환', () {
      const input = '헤어졌다가 다시 만나는 사이클이 평균보다 잘 일어나요. '
          '한 번 끝낸 결정은 적어도 6개월은 묵히는 둘만의 룰이 도움돼요.';
      final out = CompatV5Service.soften(input, useKo: true);
      expect(out.contains('헤어졌다가 다시 만나는 사이클'), isFalse);
      expect(out.contains('쉬워요') || out.contains('쉬우니') || out.contains('쉬워서'),
          isTrue,
          reason: '단정 → 헷지형(~기 쉬워요)으로 전환되어야 함.');
      expect(out.contains('구조예요'), isFalse,
          reason: 'codex말투 "구조예요" 종결 금지.');
    });

    test('KO — 운명 voice 치환', () {
      const input = '운명 같은 끌림이에요. 운명에 기대기보다 노력이 필요해요.';
      final out = CompatV5Service.soften(input, useKo: true);
      expect(out.contains('운명'), isFalse,
          reason: 'D — 운명 voice 0.');
    });

    test('KO — "정답이에요" 단정 치환', () {
      const input = '너 자신의 행복을 최우선에 두는 게 정답이에요.';
      final out = CompatV5Service.soften(input, useKo: true);
      expect(out.contains('정답이에요'), isFalse);
    });

    test('EN — "saju recommends" 메타 치환', () {
      const input = 'Saju recommends this marriage. Build rituals.';
      final out = CompatV5Service.soften(input, useKo: false);
      expect(out.contains('Saju recommends'), isFalse);
    });

    test('EN — fated/destined voice 치환', () {
      const input = 'A fated pull. The bond reads as destined.';
      final out = CompatV5Service.soften(input, useKo: false);
      expect(RegExp(r'\bfated\b').hasMatch(out), isFalse);
      expect(RegExp(r'\bdestined\b').hasMatch(out), isFalse);
    });

    test('EN — 대문자 Fated / Fated-pull 도 치환 (case-insensitive 누락 방지)', () {
      const input = 'Fated-pull signals align. A Fated bond here.';
      final out = CompatV5Service.soften(input, useKo: false);
      expect(RegExp(r'fated', caseSensitive: false).hasMatch(out), isFalse,
          reason: 'D — 문장 첫 글자 대문자 Fated 도 fate voice — 잡혀야 함.');
    });

    test('EN — "Direct saju signal" / "decided by saju" 메타 치환', () {
      const input =
          'Direct saju signal is faint. Depth is not decided by saju here.';
      final out = CompatV5Service.soften(input, useKo: false);
      expect(out.toLowerCase().contains('saju'), isFalse,
          reason: 'E — saju 메타 0 (Direct saju signal / decided by saju).');
    });

    test('EN — break-up 미래 단정 치환', () {
      const input = 'time between you is easy to shake by outside events '
          '(break-ups, moves, career shifts). Double-check-in seasons '
          'protect the bond.';
      final out = CompatV5Service.soften(input, useKo: false);
      expect(out.contains('break-ups'), isFalse);
    });

    test('빈 입력 — 그대로 반환', () {
      expect(CompatV5Service.soften('', useKo: true), '');
      expect(CompatV5Service.soften('', useKo: false), '');
    });

    test('위반 없는 본문 — 변형 0 (멱등)', () {
      const clean = '두 사람 모두 木 결을 타고난 동기예요. 만약 누가 말을 '
          '강하게 하면 한 박자 쉬어보세요.';
      expect(CompatV5Service.soften(clean, useKo: true), clean);
    });

    test('멱등 — soften 두 번 적용해도 동일', () {
      const input = '시간이 갈수록 결이 단단해져요. 운명 같은 끌림이에요.';
      final once = CompatV5Service.soften(input, useKo: true);
      final twice = CompatV5Service.soften(once, useKo: true);
      expect(twice, once, reason: 'soften 은 멱등 — 재적용 시 변형 0.');
    });
  });
}
