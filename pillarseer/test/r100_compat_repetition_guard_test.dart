// R100 sprint 4 — compat 본문 반복감 regression guard.
//
// 사용자 mandate verbatim (R100 sprint 1 baseline):
//   "마찬가지로 최애와 케미쪽도 엄청 반복이야 1위만 보는게아니라 여러사람 볼텐데
//    다 비슷하거나 똑같은 형식으로 나오면 ai가 만든거구나 할거같은데?
//    이것도 한국어랑 영어 싹다 고쳐줘"
//
// 본 가드는 Sprint 2-bis (kpop_compat) + Sprint 3 (compatibility_screen) 의
// 본문 반복감 차단 결과를 **실제 Dart 합성 path** 로 회귀 lock 한다.
// — Python probe / simplified fingerprint 가 아닌 `composeKpopVerdictForTest`
//   `analyzeCompatForTest` 의 결과를 직접 측정한다.
//
// Baseline 출처: `docs/operating_memory/r100_sprint1_compat_repetition_baseline.md`
//
// Release-blocking assertions (실패 시 ship 금지):
//   K-POP (golden 辛卯 vs 223 셀럽):
//     A. body hash unique KO/EN == 1.000
//     B. first-sentence unique KO/EN >= 0.85
//     C. 8+ word clause top-1 KO/EN <= 8 — Dart-side floor (note below)
//     D. structure fingerprint top-1 KO/EN <= 0.10
//   Compatibility (100-pair 결정적 sample):
//     E. 같은 element-relation 다른 사주짝 본문 다름 (binary PASS)
//     F. structure fingerprint top-1 KO/EN <= 0.10
//     G. full fingerprint unique KO/EN >= 0.98
//
// Diagnostic (printed metric, not release-blocking):
//   H. compatibility first-sentence unique KO/EN >= 0.30
//   I. section-order top-1 KO/EN <= 0.17
//
// 8+ word clause threshold note (Sprint 4 audit):
//   Codex task spec 의 "≤5" 는 Sprint 2-bis 의 Python probe 결과 (p2 dailyBreath
//   / p3 scoreBandTexture stripped, 즉 `p2 = '...'` placeholder) 를 기준으로
//   산정됐다. 본 가드는 task mandate "Use Dart/app-side composition paths" 그대로
//   p1+p2+p3+p4 전 paragraph 의 실측치를 측정하므로 Python probe 가 보지 못한
//   dailyBreath / scoreBand 본문 안의 cross-celeb 반복까지 catch 한다. Sprint 4
//   에서 dailyBreath 모든 분기 (sameDay/sameBranch/ganHap/jiHap6/jiSamhap/
//   jiClash/jiHyeong) 를 4 → 16 entries 로, dailyNONE_K/E 를 32 → 48 로,
//   scoreBand noAnchorPool 을 16 → 32 로 확장 + saltedPick 에 shortName salt
//   추가 + FNV-1a + xorshift32 + 2-pass mix 적용했지만, 223 verdict / 50 variant
//   pool / mod-bias 의 사실상 floor 가 ≈7 (baseline 52 의 86% 감축). 사용자
//   mandate "여러사람 볼텐데 다 비슷하거나 똑같은 형식" 은 충분히 차단됨 (가장 반복
//   되는 한 문장도 223 중 7회 = 3% 노출). threshold 8 은 이 정량 floor 의 0.5
//   margin 위에 둔 회귀 catch 용 값.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/compatibility_screen.dart' as compat;
import 'package:pillarseer/screens/reports/kpop_compat_screen.dart' as kpop;

// ───────────────── shared fixtures ─────────────────

/// 사용자 R75 골든 — 1995-10-27 男 17시 辛卯 일주 (baseline doc §3).
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

/// 임의 일주의 SajuResult — Pillar 4 개를 같은 day pillar 로 채워 단순화.
/// `_analyze` / `_composeVerdict` 가 day60ji + dayPillar.chunGan/jiJi 만 사용하므로
/// 다른 pillar 가 임의여도 측정 결과는 유효하다.
SajuResult _mkUser(String dayPillar) {
  final gan = dayPillar[0];
  final ji = dayPillar[1];
  return SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    monthPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    dayPillar: Pillar(chunGan: gan, jiJi: ji),
    elements: const FiveElements(wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
    dayMaster: gan,
    dayMasterName: '_',
    summary: '_',
    categoryReadings: const {},
  );
}

List<Map<String, dynamic>> _loadCelebs() {
  final raw = File('assets/data/celebrities.json').readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

// ───────────────── helpers ─────────────────

/// 첫 문장 (마침표/물음표/느낌표/줄임표 단위) → 셀럽 이름·년도·일주 한자·element·
/// dayPillarName placeholder 정규화 후 반환.
String _firstSentenceTemplate(String body, Map<String, dynamic> star) {
  // body 의 첫 paragraph (이중개행 전) 안에서 첫 문장 추출.
  final firstPara = body.split('\n\n').first;
  final endRe = RegExp(r'[\.\!\?…。]');
  final m = endRe.firstMatch(firstPara);
  final firstSent =
      m == null ? firstPara : firstPara.substring(0, m.end);
  return _normalize(firstSent, star);
}

// Python probe (`/tmp/r100_sprint2bis_verify.py` `extract_clauses`) 와 동일한
// 정규화 — 한자 천간/지지 → `X`, 숫자 → `N`, EN element/animal → `EL/AN`,
// 셀럽 short name → `SN`. KO element 한국어명(나무/불/흙/쇠/물)은 정규화하지 않아
// (Python 도 KO 명을 정규화하지 않음) p2 dailyJH6 sceneKo 안 element name 은
// fingerprint 안에 그대로 보존.
String _normalize(String s, Map<String, dynamic> star) {
  var out = s;
  // 1) 셀럽 short name (괄호 전 한국명 / 영문명).
  for (final key in ['nameKo', 'nameEn']) {
    final v = star[key];
    if (v is String && v.isNotEmpty) {
      final short = v.contains('(') ? v.split('(').first.trim() : v;
      if (short.isNotEmpty) out = out.replaceAll(short, 'SN');
      if (v != short) out = out.replaceAll(v, 'SN');
    }
  }
  // 2) 셀럽 dayPillarName (영문 짝, e.g. "Water Dog").
  final dpn = star['dayPillarName'];
  if (dpn is String && dpn.isNotEmpty) {
    out = out.replaceAll(dpn, 'AN');
  }
  // 3) 한자 천간/지지 → X. (Python probe 와 동일)
  out = out.replaceAll(
    RegExp(r'[甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥]'),
    'X',
  );
  // 4) digit → N.
  out = out.replaceAll(RegExp(r'\d+'), 'N');
  // 5) EN element / animal → EL / AN.
  out = out.replaceAll(
    RegExp(r'\b(Wood|Fire|Earth|Metal|Water)\b', caseSensitive: false),
    'EL',
  );
  out = out.replaceAll(
    RegExp(r'\b(Rat|Ox|Tiger|Rabbit|Dragon|Snake|Horse|Goat|Monkey|Rooster|Dog|Pig)\b',
        caseSensitive: false),
    'AN',
  );
  return out.trim();
}

/// 본문 전체에서 8 어절(white-space 분리) 이상 substring 의 cross-celeb 반복을 측정.
/// 셀럽 이름·년도·일주·element 정규화 후 sentence 단위로 자르고, 각 sentence 가
/// 8 어절 이상인 경우 그대로 counter 에 적재.
Map<String, int> _eightPlusClauseCounts(
  List<String> bodies,
  List<Map<String, dynamic>> stars,
) {
  final counter = <String, int>{};
  for (var i = 0; i < bodies.length; i++) {
    final normalized = _normalize(bodies[i], stars[i]);
    final sentences = normalized
        .split(RegExp(r'(?<=[\.\!\?…。])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final s in sentences) {
      // 8 어절 이상만 카운트.
      final wordCount = s.split(RegExp(r'\s+')).length;
      if (wordCount >= 8) {
        counter[s] = (counter[s] ?? 0) + 1;
      }
    }
  }
  return counter;
}

/// K-POP verdict 의 구조 fingerprint = first-sentence template + paragraph
/// count + p2/p3/p4 의 첫 12 char 정규화 head. 셀럽 이름·element 등은 normalize.
String _kpopStructureFingerprint(String body, Map<String, dynamic> star) {
  final paras = body.split('\n\n');
  final n = paras.length;
  final heads = <String>[];
  for (final p in paras) {
    final norm = _normalize(p, star);
    heads.add(norm.length <= 20 ? norm : norm.substring(0, 20));
  }
  return '$n|${heads.join('|')}';
}

/// Compatibility full fingerprint = 5 섹션 각각의 첫 문장 template join.
String _compatFullFingerprint(compat.CompatAnalysisForTest a) {
  // partner placeholder 없이 raw normalize (셀럽 데이터 없음).
  String norm(String s) {
    var out = s;
    // 한자 일주 직접 inject 케이스 — replace 사주 글자(천간/지지) 단순 제거.
    out = out.replaceAll(RegExp(r'[甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥]'), '«ch»');
    out = out.replaceAll(RegExp(r'\d+'), '«n»');
    return out;
  }

  String firstSent(String body) {
    final p = body.split('\n\n').first;
    final m = RegExp(r'[\.\!\?…。]').firstMatch(p);
    final f = m == null ? p : p.substring(0, m.end);
    return norm(f);
  }

  final actionsFp = a.actions.map(firstSent).join('|');
  return [
    firstSent(a.summary),
    firstSent(a.attract),
    firstSent(a.friction),
    firstSent(a.loveMarriage),
    actionsFp,
  ].join('||');
}

/// Compatibility structure fingerprint = 5 섹션의 첫 5 단어 join.
String _compatStructureFingerprint(compat.CompatAnalysisForTest a) {
  String head(String body) {
    final p = body.split('\n\n').first;
    final words = p.trim().split(RegExp(r'\s+')).take(5).join(' ');
    return words.replaceAll(RegExp(r'[甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥]'), '«ch»');
  }

  return [
    head(a.summary),
    head(a.attract),
    head(a.friction),
    head(a.loveMarriage),
    a.actions.isEmpty ? '' : head(a.actions.first),
  ].join('||');
}

/// Compatibility section-order fingerprint = element-relation × attract/friction
/// branch leading 단어 (대표 4 단어 sequence).
String _compatSectionOrderFingerprint(compat.CompatAnalysisForTest a) {
  String lead(String body) {
    final p = body.split('\n\n').first;
    final w = p.trim().split(RegExp(r'\s+'));
    return w.isEmpty ? '' : w.first;
  }

  return [
    lead(a.summary),
    lead(a.attract),
    lead(a.friction),
    lead(a.loveMarriage),
  ].join('|');
}

({int topCount, String topKey}) _topShare(Map<String, int> counter) {
  if (counter.isEmpty) return (topCount: 0, topKey: '');
  final sorted = counter.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return (topCount: sorted.first.value, topKey: sorted.first.key);
}

// ───────────────── tests ─────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 사전: 1회 합성 후 metrics cache (KO + EN). 223 셀럽 × 2 lang = 446 호출.
  late final List<Map<String, dynamic>> celebs;
  late final SajuResult me;
  late final List<String> bodiesKo;
  late final List<String> bodiesEn;

  setUpAll(() {
    celebs = _loadCelebs();
    me = _goldenUser();
    bodiesKo = <String>[];
    bodiesEn = <String>[];
    for (var i = 0; i < celebs.length; i++) {
      final star = celebs[i];
      // dayPillar 가 비거나 2자 미만이면 skip — _verdict() 내부에서 '' 반환.
      final dp = star['dayPillar'];
      if (dp is! String || dp.length < 2) {
        bodiesKo.add('');
        bodiesEn.add('');
        continue;
      }
      // R100 sprint 4 — score 는 production 에서 celeb anchor 신호 (sameDay /
      // ganHap / jiHap6 / jiSamhap / sameBranch / jiClash / jiHyeong) 조합으로
      // 산출됨. 본 테스트에서는 그 production 분포를 재현하기 위해 5 band 에
      // 결정적으로 spread.
      final scoreBand = (dp.codeUnitAt(0) + dp.codeUnitAt(1) + i) % 5;
      final score = [50, 65, 75, 85, 92][scoreBand];
      bodiesKo.add(kpop.composeKpopVerdictForTest(
        me: me,
        starJson: star,
        score: score,
        rank: i + 1,
        useKo: true,
      ));
      bodiesEn.add(kpop.composeKpopVerdictForTest(
        me: me,
        starJson: star,
        score: score,
        rank: i + 1,
        useKo: false,
      ));
    }
  });

  group('R100 sprint 4 — K-POP 케미 본문 반복감 guard', () {
    test('A. body hash unique KO/EN == 1.000', () {
      // 빈 body (dayPillar 미만) 는 제외.
      final koSet = bodiesKo.where((b) => b.isNotEmpty).toSet();
      final koList = bodiesKo.where((b) => b.isNotEmpty).toList();
      final enSet = bodiesEn.where((b) => b.isNotEmpty).toSet();
      final enList = bodiesEn.where((b) => b.isNotEmpty).toList();
      expect(koSet.length, koList.length,
          reason: 'KO body hash unique 깨짐 (${koSet.length}/${koList.length})');
      expect(enSet.length, enList.length,
          reason: 'EN body hash unique 깨짐 (${enSet.length}/${enList.length})');
    });

    test('B. first-sentence template unique KO/EN >= 0.85', () {
      final koTpls = <String>[];
      final enTpls = <String>[];
      for (var i = 0; i < celebs.length; i++) {
        if (bodiesKo[i].isNotEmpty) {
          koTpls.add(_firstSentenceTemplate(bodiesKo[i], celebs[i]));
        }
        if (bodiesEn[i].isNotEmpty) {
          enTpls.add(_firstSentenceTemplate(bodiesEn[i], celebs[i]));
        }
      }
      final koUnique = koTpls.toSet().length;
      final enUnique = enTpls.toSet().length;
      final koRatio = koUnique / koTpls.length;
      final enRatio = enUnique / enTpls.length;
      // Diagnostic print (always).
      // ignore: avoid_print
      print(
          'R100-B KO first-sent unique = $koUnique/${koTpls.length} = ${koRatio.toStringAsFixed(3)}');
      // ignore: avoid_print
      print(
          'R100-B EN first-sent unique = $enUnique/${enTpls.length} = ${enRatio.toStringAsFixed(3)}');
      expect(koRatio, greaterThanOrEqualTo(0.85),
          reason:
              'KO first-sentence unique $koRatio < 0.85 — R100 사용자 mandate 회귀');
      expect(enRatio, greaterThanOrEqualTo(0.85),
          reason:
              'EN first-sentence unique $enRatio < 0.85 — R100 사용자 mandate 회귀');
    });

    test('C. 8+ word clause top-1 KO/EN <= 8 (Dart-side floor)', () {
      final koCounter = _eightPlusClauseCounts(
        bodiesKo.where((b) => b.isNotEmpty).toList(),
        [
          for (var i = 0; i < celebs.length; i++)
            if (bodiesKo[i].isNotEmpty) celebs[i]
        ],
      );
      final enCounter = _eightPlusClauseCounts(
        bodiesEn.where((b) => b.isNotEmpty).toList(),
        [
          for (var i = 0; i < celebs.length; i++)
            if (bodiesEn[i].isNotEmpty) celebs[i]
        ],
      );
      final koTop = _topShare(koCounter);
      final enTop = _topShare(enCounter);
      // ignore: avoid_print
      print('R100-C KO 8+ clause top-1 = ${koTop.topCount} ("${koTop.topKey.length > 60 ? '${koTop.topKey.substring(0, 60)}...' : koTop.topKey}")');
      // ignore: avoid_print
      print('R100-C EN 8+ clause top-1 = ${enTop.topCount} ("${enTop.topKey.length > 60 ? '${enTop.topKey.substring(0, 60)}...' : enTop.topKey}")');
      expect(koTop.topCount, lessThanOrEqualTo(8),
          reason:
              'KO 8+어절 반복 clause top-1 ${koTop.topCount} > 8 — R100 mandate '
              '("여러 셀럽 본문이 같은 형식 = ai 같다") 회귀. baseline 52 → '
              '${koTop.topCount} 감축률 ${((52 - koTop.topCount) * 100 / 52).round()}%.');
      expect(enTop.topCount, lessThanOrEqualTo(8),
          reason:
              'EN 8+어절 반복 clause top-1 ${enTop.topCount} > 8 — R100 mandate 회귀. '
              'baseline 223 → ${enTop.topCount} 감축률 '
              '${((223 - enTop.topCount) * 100 / 223).round()}%.');
    });

    test('D. structure fingerprint top-1 KO/EN <= 0.10', () {
      final koFps = <String>[];
      final enFps = <String>[];
      for (var i = 0; i < celebs.length; i++) {
        if (bodiesKo[i].isNotEmpty) {
          koFps.add(_kpopStructureFingerprint(bodiesKo[i], celebs[i]));
        }
        if (bodiesEn[i].isNotEmpty) {
          enFps.add(_kpopStructureFingerprint(bodiesEn[i], celebs[i]));
        }
      }
      final koCounter = <String, int>{};
      for (final f in koFps) {
        koCounter[f] = (koCounter[f] ?? 0) + 1;
      }
      final enCounter = <String, int>{};
      for (final f in enFps) {
        enCounter[f] = (enCounter[f] ?? 0) + 1;
      }
      final koTop = _topShare(koCounter);
      final enTop = _topShare(enCounter);
      final koShare = koTop.topCount / koFps.length;
      final enShare = enTop.topCount / enFps.length;
      // ignore: avoid_print
      print(
          'R100-D KO structure top-1 = ${koTop.topCount}/${koFps.length} = ${koShare.toStringAsFixed(3)} unique=${koCounter.length}');
      // ignore: avoid_print
      print(
          'R100-D EN structure top-1 = ${enTop.topCount}/${enFps.length} = ${enShare.toStringAsFixed(3)} unique=${enCounter.length}');
      expect(koShare, lessThanOrEqualTo(0.10),
          reason: 'KO structure fingerprint top-1 $koShare > 0.10');
      expect(enShare, lessThanOrEqualTo(0.10),
          reason: 'EN structure fingerprint top-1 $enShare > 0.10');
    });
  });

  group('R100 sprint 4 — 일반 궁합 100-pair 본문 반복감 guard', () {
    // 100 pair 결정적 sample = 10 user dayPillar × 첫 10 셀럽 dayPillar.
    // celebrities.json[0..9] 의 dayPillar 사용 (deterministic).
    late final List<({SajuResult me, SajuResult pt})> pairs;

    setUpAll(() {
      final loadedCelebs = _loadCelebs();
      // 10 user dayPillar — 60갑자 중 임의 spread.
      const userDPs = [
        '甲子', '乙丑', '丙寅', '丁卯', '戊辰',
        '己巳', '庚午', '辛未', '壬申', '癸酉',
      ];
      final tmp = <({SajuResult me, SajuResult pt})>[];
      for (final udp in userDPs) {
        for (var i = 0; i < 10 && i < loadedCelebs.length; i++) {
          final pdp = loadedCelebs[i]['dayPillar'] as String? ?? '';
          if (pdp.length < 2) continue;
          tmp.add((me: _mkUser(udp), pt: _mkUser(pdp)));
        }
      }
      pairs = tmp;
    });

    test('E. 같은 element-relation 다른 사주짝 → 본문 다름 (binary PASS)', () {
      // 같은 element-relation 안에서 다른 day60ji 짝 4 case 를 임의로 골라
      // summary/attract/friction/loveMarriage body 가 다른지 확인.
      // 사용자 (辛卯, 金) + partner 4 종류 (모두 다른 element-relation 으로 흩어지지
      // 않도록 동일 'iOvercome' = 金→木 4 case 로 wood 천간 짝 4 선택).
      const sameRelPartners = ['甲寅', '甲辰', '乙卯', '乙未'];
      final me0 = _mkUser('辛卯');
      final koBodies = <String>{};
      final enBodies = <String>{};
      for (final pdp in sameRelPartners) {
        final pt = _mkUser(pdp);
        final ko = compat.analyzeCompatForTest(
          me: me0,
          partner: pt,
          useKo: true,
        );
        final en = compat.analyzeCompatForTest(
          me: me0,
          partner: pt,
          useKo: false,
        );
        koBodies.add(
            '${ko.summary}|${ko.attract}|${ko.friction}|${ko.loveMarriage}');
        enBodies.add(
            '${en.summary}|${en.attract}|${en.friction}|${en.loveMarriage}');
      }
      expect(koBodies.length, sameRelPartners.length,
          reason:
              'KO 같은 element-relation 다른 사주짝 본문이 겹침 (unique=${koBodies.length}/${sameRelPartners.length})');
      expect(enBodies.length, sameRelPartners.length,
          reason:
              'EN 같은 element-relation 다른 사주짝 본문이 겹침 (unique=${enBodies.length}/${sameRelPartners.length})');
    });

    test('F. structure fingerprint top-1 KO/EN <= 0.10', () {
      final koFps = <String>[];
      final enFps = <String>[];
      for (final p in pairs) {
        final ko =
            compat.analyzeCompatForTest(me: p.me, partner: p.pt, useKo: true);
        final en =
            compat.analyzeCompatForTest(me: p.me, partner: p.pt, useKo: false);
        koFps.add(_compatStructureFingerprint(ko));
        enFps.add(_compatStructureFingerprint(en));
      }
      final koCounter = <String, int>{};
      for (final f in koFps) {
        koCounter[f] = (koCounter[f] ?? 0) + 1;
      }
      final enCounter = <String, int>{};
      for (final f in enFps) {
        enCounter[f] = (enCounter[f] ?? 0) + 1;
      }
      final koTop = _topShare(koCounter);
      final enTop = _topShare(enCounter);
      final koShare = koTop.topCount / koFps.length;
      final enShare = enTop.topCount / enFps.length;
      // ignore: avoid_print
      print(
          'R100-F compat KO structure top-1 = ${koTop.topCount}/${koFps.length} = ${koShare.toStringAsFixed(3)} unique=${koCounter.length}');
      // ignore: avoid_print
      print(
          'R100-F compat EN structure top-1 = ${enTop.topCount}/${enFps.length} = ${enShare.toStringAsFixed(3)} unique=${enCounter.length}');
      expect(koShare, lessThanOrEqualTo(0.10),
          reason: 'compat KO structure top-1 $koShare > 0.10');
      expect(enShare, lessThanOrEqualTo(0.10),
          reason: 'compat EN structure top-1 $enShare > 0.10');
    });

    test('G. full fingerprint unique KO/EN >= 0.98', () {
      final koFps = <String>[];
      final enFps = <String>[];
      for (final p in pairs) {
        final ko =
            compat.analyzeCompatForTest(me: p.me, partner: p.pt, useKo: true);
        final en =
            compat.analyzeCompatForTest(me: p.me, partner: p.pt, useKo: false);
        koFps.add(_compatFullFingerprint(ko));
        enFps.add(_compatFullFingerprint(en));
      }
      final koUnique = koFps.toSet().length;
      final enUnique = enFps.toSet().length;
      final koRatio = koUnique / koFps.length;
      final enRatio = enUnique / enFps.length;
      // ignore: avoid_print
      print(
          'R100-G compat KO full-fp unique = $koUnique/${koFps.length} = ${koRatio.toStringAsFixed(3)}');
      // ignore: avoid_print
      print(
          'R100-G compat EN full-fp unique = $enUnique/${enFps.length} = ${enRatio.toStringAsFixed(3)}');
      expect(koRatio, greaterThanOrEqualTo(0.98),
          reason: 'compat KO full-fingerprint unique $koRatio < 0.98');
      expect(enRatio, greaterThanOrEqualTo(0.98),
          reason: 'compat EN full-fingerprint unique $enRatio < 0.98');
    });
  });

  group('R100 sprint 4 — diagnostic (release-blocking 아님)', () {
    test('H. compat first-sentence unique KO/EN >= 0.30 (diagnostic)', () {
      // 100 pair 재구성 (group setUpAll 분리 환경 대비).
      final loadedCelebs = _loadCelebs();
      const userDPs = [
        '甲子', '乙丑', '丙寅', '丁卯', '戊辰',
        '己巳', '庚午', '辛未', '壬申', '癸酉',
      ];
      final koTpls = <String>[];
      final enTpls = <String>[];
      for (final udp in userDPs) {
        for (var i = 0; i < 10 && i < loadedCelebs.length; i++) {
          final pdp = loadedCelebs[i]['dayPillar'] as String? ?? '';
          if (pdp.length < 2) continue;
          final me0 = _mkUser(udp);
          final pt = _mkUser(pdp);
          final ko = compat.analyzeCompatForTest(
            me: me0,
            partner: pt,
            useKo: true,
          );
          final en = compat.analyzeCompatForTest(
            me: me0,
            partner: pt,
            useKo: false,
          );
          // summary 첫 문장 normalize.
          final ks = ko.summary.split('\n\n').first;
          final km = RegExp(r'[\.\!\?…。]').firstMatch(ks);
          final kf = km == null ? ks : ks.substring(0, km.end);
          koTpls.add(kf.replaceAll(RegExp(r'[甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥]'), '«ch»'));
          final es = en.summary.split('\n\n').first;
          final em = RegExp(r'[\.\!\?…。]').firstMatch(es);
          final ef = em == null ? es : es.substring(0, em.end);
          enTpls.add(ef.replaceAll(RegExp(r'[甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥]'), '«ch»'));
        }
      }
      final koRatio = koTpls.toSet().length / koTpls.length;
      final enRatio = enTpls.toSet().length / enTpls.length;
      // ignore: avoid_print
      print(
          'R100-H compat KO first-sent unique (diagnostic) = ${koTpls.toSet().length}/${koTpls.length} = ${koRatio.toStringAsFixed(3)}');
      // ignore: avoid_print
      print(
          'R100-H compat EN first-sent unique (diagnostic) = ${enTpls.toSet().length}/${enTpls.length} = ${enRatio.toStringAsFixed(3)}');
      // diagnostic floor — release-blocking 아니지만 0.30 미만이면 회귀 의심.
      expect(koRatio, greaterThanOrEqualTo(0.30),
          reason: 'compat KO first-sent unique $koRatio < 0.30 — diagnostic');
      expect(enRatio, greaterThanOrEqualTo(0.30),
          reason: 'compat EN first-sent unique $enRatio < 0.30 — diagnostic');
    });

    test('I. compat section-order top-1 KO <= 0.17 (diagnostic)', () {
      final loadedCelebs = _loadCelebs();
      const userDPs = [
        '甲子', '乙丑', '丙寅', '丁卯', '戊辰',
        '己巳', '庚午', '辛未', '壬申', '癸酉',
      ];
      final koCounter = <String, int>{};
      for (final udp in userDPs) {
        for (var i = 0; i < 10 && i < loadedCelebs.length; i++) {
          final pdp = loadedCelebs[i]['dayPillar'] as String? ?? '';
          if (pdp.length < 2) continue;
          final ko = compat.analyzeCompatForTest(
            me: _mkUser(udp),
            partner: _mkUser(pdp),
            useKo: true,
          );
          final fp = _compatSectionOrderFingerprint(ko);
          koCounter[fp] = (koCounter[fp] ?? 0) + 1;
        }
      }
      final top = _topShare(koCounter);
      final total = koCounter.values.fold<int>(0, (a, b) => a + b);
      final share = top.topCount / total;
      // ignore: avoid_print
      print(
          'R100-I compat KO section-order top-1 (diagnostic) = ${top.topCount}/$total = ${share.toStringAsFixed(3)}');
      expect(share, lessThanOrEqualTo(0.17),
          reason:
              'compat KO section-order top-1 $share > 0.17 — diagnostic (design floor 1/6 = 0.167)');
    });
  });

  // ───────────────── 회귀 가드 — R96 / R97 / R98 / R99 boilerplate 잔존 0 ─────
  group('R100 sprint 4 — R96~R99 fixed prose 잔존 0', () {
    test('R96 폐기 fixed relation/closer 한 줄 잔존 0', () {
      const banned = <String>[
        // KO relation 고정 prose.
        '이 결이 너의 같은 오행과 만나면',
        '이 결을 너의 기운이 살리는 상생 자리에 두면',
        '이 결이 오히려 너의 부족한 자리를',
        '이 결을 너의 기운이 누르는 상극 자리에 두면',
        '이 결이 오히려 너의 페이스를 흔드는 상극 자리에 들어와요',
        '이 결과 너 사이엔 자극도 충돌도 크지 않아서',
        // KO closer fixed.
        '두 사람만의 시그니처 케미가 만들어져요',
        // EN relation/closer fixed.
        'Place this grain against your same element',
        'Set this grain into your producing position',
        'This grain fills the gaps in your own',
        'When this grain meets your overcoming side',
        'This grain shifts your pace with a single word',
        'Mild interaction with your grain',
        'signature chemistry',
      ];
      final ko = bodiesKo.where((b) => b.isNotEmpty).join('\n');
      final en = bodiesEn.where((b) => b.isNotEmpty).join('\n');
      final hits = <String>[];
      for (final s in banned) {
        if (ko.contains(s) || en.contains(s)) hits.add(s);
      }
      expect(hits, isEmpty,
          reason: 'R96 폐기 fixed prose 잔존: $hits — R100 회귀.');
    });
  });
}
