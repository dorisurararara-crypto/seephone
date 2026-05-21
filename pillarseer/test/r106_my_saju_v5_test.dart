// Round 106 (P3) — 내 사주(평생사주) v5 검증.
//
// design doc §3 / §5 / §9(내 사주) / 톤 ground truth:
//  ① v5 리딩이 사용자 full chart 로 생성 — 일주/일간/십신/합/격국/용신 anchor.
//  ② 증거 띠가 실제 차트 anchor 를 노출 (일주 60갑자 + 일간 + 핵심 십신 등).
//  ③ 헤드라인 = 강점 + 그림자 구조 (강점만 칭찬 X).
//  ④ 메타·헤드라인체·codex 말투 가드 — 본문 전수.
//  ⑤ 한자 즉시 풀이 — 한자/십신 jargon 단독 노출 0.
//  ⑥ 오늘 연결 CTA 존재.
//  ⑦ 기존 17섹션 회귀 — LifeOverview / SelfConclusion 보존.
//
// presentation layer only — 계산 엔진은 호출만.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/life_overview_service.dart';
import 'package:pillarseer/services/my_saju_v5_service.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/self_conclusion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── pool 적재 (실제 asset). ──
  setUpAll(() async {
    MySajuV5Service.debugResetPool();
    final raw =
        await File('assets/data/my_saju_v5_pool.json').readAsString();
    MySajuV5Service.debugSeedPool(jsonDecode(raw) as Map<String, dynamic>);
  });

  Future<SajuResult> sajuOf(
    int y, int m, int d, int hh, int mm, {
    bool isMale = true,
  }) {
    return SajuService().calculateSaju(
      year: y, month: m, day: d, hour: hh, minute: mm,
      isLunar: false, isMale: isMale,
    );
  }

  // 골든: 1995-10-27 男 15:43 → 辛卯 일주, 정인격, 용신 水, 신왕.
  Future<SajuResult> goldenSaju() => sajuOf(1995, 10, 27, 15, 43);

  // ── §1 — full chart 생성 ──
  group('§1 v5 리딩 = full chart 생성', () {
    test('골든케이스 reading 생성 — 헤드라인 + 본문 + 증거 + CTA 모두 채워짐', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      expect(r.headline.trim().isNotEmpty, isTrue);
      expect(r.bodyParagraphs.isNotEmpty, isTrue);
      expect(r.bodyParagraphs.every((p) => p.trim().isNotEmpty), isTrue);
      expect(r.evidenceChips.isNotEmpty, isTrue);
      expect(r.todayCta.trim().isNotEmpty, isTrue);
      // 본문은 평생 '바탕' 임을 명시.
      expect(r.bodyJoined.contains('바탕'), isTrue);
    });

    test('deterministic — 같은 사주면 같은 리딩', () async {
      final s1 = await goldenSaju();
      final s2 = await goldenSaju();
      final a = MySajuV5Service.build(saju: s1);
      final b = MySajuV5Service.build(saju: s2);
      expect(a.headline, b.headline);
      expect(a.bodyJoined, b.bodyJoined);
      expect(a.evidenceChips.map((c) => c.value).join('|'),
          b.evidenceChips.map((c) => c.value).join('|'));
    });

    test('다른 일주 → 다른 리딩 (full chart keying)', () async {
      final golden = await goldenSaju(); // 辛卯
      final other = await sajuOf(1988, 3, 14, 9, 0); // 다른 일주
      final a = MySajuV5Service.build(saju: golden);
      final b = MySajuV5Service.build(saju: other);
      // 일간이 다르면 본문이 달라야 한다 (Barnum 복붙 차단).
      expect(a.headline == b.headline && a.bodyJoined == b.bodyJoined,
          isFalse);
    });

    test('같은 일간 + 다른 일지 → 본문이 갈린다 (일주 60갑자 변별)', () async {
      // 같은 일간(辛金)이라도 일지가 다르면 — 십신/합/용신이 우연히 겹쳐도
      // 일지(日支) fragment 때문에 bodyJoined 가 반드시 달라야 한다.
      // 辛卯(辛金·卯) vs 辛酉(辛金·酉) 두 일주를 골라 검증.
      SajuResult? sinMyo; // 辛卯
      SajuResult? sinYu; // 辛酉
      // 1990~2000 범위에서 辛卯·辛酉 일주를 가진 날을 탐색.
      outer:
      for (var y = 1990; y <= 2000 && (sinMyo == null || sinYu == null); y++) {
        for (var m = 1; m <= 12; m++) {
          for (var d = 1; d <= 28; d++) {
            final s = await sajuOf(y, m, d, 12, 0);
            if (s.dayMaster != '辛') continue;
            if (s.dayPillar.jiJi == '卯' && sinMyo == null) sinMyo = s;
            if (s.dayPillar.jiJi == '酉' && sinYu == null) sinYu = s;
            if (sinMyo != null && sinYu != null) break outer;
          }
        }
      }
      expect(sinMyo, isNotNull, reason: '辛卯 일주 케이스를 찾지 못함');
      expect(sinYu, isNotNull, reason: '辛酉 일주 케이스를 찾지 못함');
      // 두 케이스 모두 일간은 辛으로 동일.
      expect(sinMyo!.dayMaster, '辛');
      expect(sinYu!.dayMaster, '辛');
      // 일지는 다름.
      expect(sinMyo.dayPillar.jiJi, '卯');
      expect(sinYu.dayPillar.jiJi, '酉');
      final rMyo = MySajuV5Service.build(saju: sinMyo);
      final rYu = MySajuV5Service.build(saju: sinYu);
      // 일간이 같아도 일지 fragment 때문에 본문이 반드시 달라야 한다.
      expect(rMyo.bodyJoined != rYu.bodyJoined, isTrue,
          reason: '같은 辛金 일간인데 일지(卯/酉)가 달라도 본문이 동일하다 — '
              '일지 fragment 변별 실패');
      // 각 일지 fragment 가 본문에 실제로 박혔는지 직접 확인.
      expect(rMyo.bodyJoined.contains('卯'), isTrue);
      expect(rYu.bodyJoined.contains('酉'), isTrue);
    });
  });

  // ── §2 — 증거 띠 ──
  group('§2 증거 띠 = 실제 차트 anchor', () {
    test('증거 띠에 일주 60갑자 + 일간 + 핵심 십신 노출', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      final labels = r.evidenceChips.map((c) => c.label).toList();
      expect(labels, contains('일주'));
      expect(labels, contains('일간'));
      expect(labels, contains('핵심 십신'));
      // 일주 칩은 실제 일주 한자 + 한글 풀이.
      final ilju = r.evidenceChips.firstWhere((c) => c.label == '일주');
      expect(ilju.value.contains(saju.dayPillar.text), isTrue);
      expect(ilju.value.contains('신묘'), isTrue); // 辛卯 한글 풀이.
      // 일간 칩은 실제 일간 한자.
      final dm = r.evidenceChips.firstWhere((c) => c.label == '일간');
      expect(dm.value.contains(saju.dayMaster), isTrue); // 辛.
    });

    test('골든케이스 — 천간합 / 격국 / 용신 칩이 실제 차트값으로 노출', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      final labels = r.evidenceChips.map((c) => c.label).toList();
      // 1995-10-27 辛卯 = 丙辛합 (月-日 천간합) 존재.
      expect(labels, contains('천간합'));
      final hap = r.evidenceChips.firstWhere((c) => c.label == '천간합');
      expect(hap.value.contains('丙辛'), isTrue);
      expect(hap.value.contains('병신'), isTrue); // 한자 즉시 풀이.
      // 격국 = 정인격.
      expect(labels, contains('격국'));
      final gye = r.evidenceChips.firstWhere((c) => c.label == '격국');
      expect(gye.value.contains('정인격'), isTrue);
      // 용신 = 水.
      expect(labels, contains('용신'));
      final ys = r.evidenceChips.firstWhere((c) => c.label == '용신');
      expect(ys.value.contains('水'), isTrue);
      expect(ys.value.contains('수'), isTrue); // 한자 즉시 풀이.
    });
  });

  // ── §3 — 헤드라인 강점 + 그림자 ──
  group('§3 헤드라인 = 강점 + 그림자', () {
    test('헤드라인이 한 문장이 아니라 강점+그림자 두 조각', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      // 그림자 신호 — "대신" 으로 그림자를 붙임.
      expect(r.headline.contains('대신'), isTrue,
          reason: '헤드라인에 강점 뒤 그림자가 와야 함: ${r.headline}');
      // 골든케이스 헤드라인은 승인 예시 톤 — "쉽게 안 휘는" + "혼자 너무 오래".
      expect(r.headline.contains('쉽게 안 휘는'), isTrue);
      expect(r.headline.contains('혼자 너무 오래'), isTrue);
    });

    test('10 일간 전부 헤드라인에 강점+그림자 구조', () async {
      // 일간 10천간을 커버하는 birthday set.
      const cases = [
        (1990, 1, 5, '甲'), (1990, 2, 10, '乙'), (1990, 3, 20, '丙'),
        (1990, 4, 25, '丁'), (1990, 5, 30, '戊'), (1990, 7, 5, '己'),
        (1990, 8, 12, '庚'), (1990, 9, 18, '辛'), (1990, 10, 24, '壬'),
        (1990, 12, 1, '癸'),
      ];
      for (final c in cases) {
        final saju = await sajuOf(c.$1, c.$2, c.$3, 10, 0);
        final r = MySajuV5Service.build(saju: saju);
        expect(r.headline.contains('대신'), isTrue,
            reason: '${saju.dayMaster} 일간 헤드라인에 그림자 없음: ${r.headline}');
        expect(r.bodyParagraphs.length >= 3, isTrue,
            reason: '${saju.dayMaster} 본문 문단 부족');
      }
    });
  });

  // ── §4 — 메타·헤드라인체·codex 말투 가드 ──
  group('§4 톤 가드 — 메타·헤드라인체·codex 말투 0', () {
    // pool 의 모든 fragment 를 전수 검사.
    test('pool 모든 fragment 에 금지 표현 0', () async {
      final raw =
          await File('assets/data/my_saju_v5_pool.json').readAsString();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final strings = <String>[];
      void collect(dynamic v) {
        if (v is String) {
          strings.add(v);
        } else if (v is Map) {
          v.forEach((_, val) => collect(val));
        } else if (v is List) {
          for (final e in v) {
            collect(e);
          }
        }
      }
      // notes / schema 는 메타라 제외.
      root.forEach((k, v) {
        if (k == 'notes' || k == 'schema') return;
        collect(v);
      });
      expect(strings.isNotEmpty, isTrue);

      // 메타 / 헤드라인체 / codex 말투 금지 패턴.
      const forbidden = [
        '하는 날이에요',
        '하는 날입니다',
        '구조로 봅니다',
        '구조로 보입니다',
        '사주적으로',
        '본 리딩은',
        '나의 ',
        '오늘의 사주운',
        '평생사주운',
      ];
      for (final s in strings) {
        for (final f in forbidden) {
          expect(s.contains(f), isFalse,
              reason: '금지 표현 "$f" 발견: $s');
        }
      }
    });

    test('생성된 reading 본문에 금지 표현 0', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      final full = '${r.headline} ${r.bodyJoined} ${r.todayCta}';
      const forbidden = [
        '하는 날이에요',
        '구조로 봅니다',
        '사주적으로',
        '본 리딩은',
      ];
      for (final f in forbidden) {
        expect(full.contains(f), isFalse,
            reason: '생성 본문에 금지 표현 "$f"');
      }
    });
  });

  // ── §5 — 한자 즉시 풀이 ──
  group('§5 한자 즉시 풀이 — jargon 단독 노출 0', () {
    // 본문의 한자/십신 jargon 은 반드시 한글 풀이를 동반한다 — 단독 노출 0.
    // 한자 jargon 이 한글과 일체로 쓰였는지 = 모든 한자 블록 각각에 대해
    //   ① 직후 또는 직전이 한글 음절   (예 辛金, 丙辛합) OR
    //   ② 직후가 "(한글풀이)"          (예 甲木(갑목)) OR
    //   ③ 직전이 "한글(" 형으로 한글 음·뜻이 선행 (예 비견(比肩))
    // 셋 다 아니면 한자가 한글에서 고립된 단독 노출 → fail.
    bool hanjaHasGloss(String text) {
      for (final m in RegExp(r'[一-鿿]+').allMatches(text)) {
        final before = m.start > 0 ? text[m.start - 1] : '';
        final after = m.end < text.length ? text[m.end] : '';
        final isKo = RegExp(r'[가-힣]');
        final adjacentKo = isKo.hasMatch(before) || isKo.hasMatch(after);
        final parenGloss = after == '(';
        final koPrefixed = before == '(' &&
            m.start >= 2 &&
            isKo.hasMatch(text[m.start - 2]);
        if (!(adjacentKo || parenGloss || koPrefixed)) return false;
      }
      return true;
    }

    test('pool 본문의 한자 십신/일간이 한글 풀이를 동반', () async {
      final raw =
          await File('assets/data/my_saju_v5_pool.json').readAsString();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final bodies = <String>[];
      final dm = root['day_master'] as Map<String, dynamic>;
      dm.forEach((_, v) => bodies.add((v as Map)['body'] as String));
      final sip = root['sipsin'] as Map<String, dynamic>;
      sip.forEach((_, v) => bodies.add((v as Map)['body'] as String));
      final hap = root['natal_hap'] as Map<String, dynamic>;
      hap.forEach((_, v) => bodies.add(v as String));

      for (final b in bodies) {
        final hanjaCount = RegExp(r'[一-鿿]').allMatches(b).length;
        if (hanjaCount == 0) continue;
        expect(hanjaHasGloss(b), isTrue,
            reason: '한자 jargon 풀이 누락: $b');
      }
    });

    test('생성 reading 본문 — 한자 노출 시 한글 풀이 동반', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      for (final p in r.bodyParagraphs) {
        final hanjaCount = RegExp(r'[一-鿿]').allMatches(p).length;
        if (hanjaCount == 0) continue;
        expect(hanjaHasGloss(p), isTrue,
            reason: '본문 한자 풀이 누락: $p');
      }
    });
  });

  // ── §6 — 오늘 CTA ──
  group('§6 오늘 연결 CTA', () {
    test('CTA 가 오늘의 사주로 연결 + 화살표', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      expect(r.todayCta.contains('오늘'), isTrue);
      expect(r.todayCta.contains('→'), isTrue);
    });

    test('관심 주제 주입 시 CTA 가 그 주제로 연결', () async {
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(
        saju: saju,
        topTopicId: 'love_connection',
      );
      expect(r.todayCta.contains('연애'), isTrue);
      // 미지정/미스 토픽 → default CTA.
      final d = MySajuV5Service.build(saju: saju, topTopicId: null);
      expect(d.todayCta.contains('오늘'), isTrue);
    });
  });

  // ── §7 — 기존 17섹션 회귀 ──
  group('§7 기존 17섹션 회귀 — LifeOverview / SelfConclusion 보존', () {
    test('LifeOverviewService.compose 정상 동작 (5행 골든 보존)', () async {
      final saju = await goldenSaju();
      // 5행 골든 16/21/17/41/4.
      expect(saju.elements.wood, 16);
      expect(saju.elements.fire, 21);
      expect(saju.elements.earth, 17);
      expect(saju.elements.metal, 41);
      expect(saju.elements.water, 4);
      final essay = await LifeOverviewService.compose(saju, isMale: true);
      expect(essay.length >= 400, isTrue);
    });

    test('SelfConclusionService.conclude 정상 동작', () async {
      final saju = await goldenSaju();
      final c = await SelfConclusionService.conclude(saju, isMale: true);
      expect(c.trim().isNotEmpty, isTrue);
    });
  });

  // ── pool 미적재 graceful ──
  group('pool 미적재 graceful', () {
    test('pool 없어도 내장 fallback 으로 reading 생성', () async {
      MySajuV5Service.debugResetPool();
      MySajuV5Service.debugSeedPool(const {}); // 빈 pool.
      final saju = await goldenSaju();
      final r = MySajuV5Service.build(saju: saju);
      expect(r.headline.trim().isNotEmpty, isTrue);
      expect(r.bodyParagraphs.isNotEmpty, isTrue);
      expect(r.evidenceChips.isNotEmpty, isTrue);
      expect(r.headline.contains('대신'), isTrue);
      // 원복.
      MySajuV5Service.debugResetPool();
      final raw =
          await File('assets/data/my_saju_v5_pool.json').readAsString();
      MySajuV5Service.debugSeedPool(jsonDecode(raw) as Map<String, dynamic>);
    });
  });
}
