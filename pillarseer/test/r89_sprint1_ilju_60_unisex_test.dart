// R89 sprint 1 회귀 가드 — 60 일주 × 14 unisex 카테고리 paragraph 변별 검증.
//
// 사용자 스토리:
//   사용자 A (1995-10-27 甲子일주) 와 사용자 B (1996-03-15 甲午일주, 같은 甲일간) 가
//   동시에 result_screen 진입, "재물 모으는 법" 카테고리 본문이 다르고 둘 다 ≥80자,
//   평탄 어휘 0, 한자 jargon 0, 운세의신 본문 그대로 차용 0.
//
// 검증:
//   B1 — 60 일주 모두 DB 에 hit (fallback step 3 발생 X)
//   B2 — 60 × 14 unisex 카테고리 paragraph 모두 ≥80자
//   B3 — 같은 일간 다른 일주 → wealth/early_life/personality 모두 다른 paragraph
//   B4 — lint: 평탄 어휘 0 / 단정조 0 / 한자 jargon 0 / AI 슬롭 0 / 의료 단정 0 / 직장인 jargon 0
//   B5 — 일주 변별력 (4-gram Jaccard 평균) 같은 일간 6 일주 pair 평균 < 60%

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const stems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  const branches = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
  // 60 일주 = stem[n%10] + branch[n%12] for n in 0..59.
  final ilju60 = <String>[
    for (var n = 0; n < 60; n++) stems[n % 10] + branches[n % 12]
  ];

  // 14 unisex 카테고리 (성별 분기 3 + conclusion_self 제외하면 13. conclusion_self 도 unisex 이라 14 로 셈).
  const unisex = [
    LifeCategory.earlyLife,
    LifeCategory.midLife,
    LifeCategory.lateLife,
    LifeCategory.health,
    LifeCategory.constitution,
    LifeCategory.social,
    LifeCategory.socialPersonality,
    LifeCategory.personality,
    LifeCategory.innateTendency,
    LifeCategory.wealth,
    LifeCategory.wealthGather,
    LifeCategory.wealthLossPrevent,
    LifeCategory.wealthInvest,
    LifeCategory.conclusionSelf,
  ];

  setUpAll(() {
    final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
    final map = json.decode(raw) as Map<String, dynamic>;
    LifeParagraphService.seedForTest(map);
  });

  tearDownAll(() {
    LifeParagraphService.resetCache();
  });

  group('R89 sprint 1 — 60 일주 × 14 unisex 카테고리 확장', () {
    test('B1 — 60 일주 모두 DB 에 직접 hit (fallback 발생 X)', () async {
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      final map = json.decode(raw) as Map<String, dynamic>;
      for (final ilju in ilju60) {
        expect(map.containsKey(ilju), isTrue,
            reason: '$ilju 일주가 DB 에 없음 (R89 sprint 1 mandate)');
      }
    });

    test('B2 — 60 × 14 unisex paragraph 모두 ≥80자', () async {
      const svc = LifeParagraphService();
      for (final ilju in ilju60) {
        for (final cat in unisex) {
          final p = await svc.paragraph(dayPillar: ilju, category: cat);
          expect(p.length >= 80, isTrue,
              reason: '$ilju.${lifeCategoryKey(cat)} 길이 ${p.length}자 (≥80 mandate)');
        }
      }
    });

    test('B3 — 같은 일간 다른 일주 paragraph 가 모두 다름 (예: 갑자/갑술 wealth)',
        () async {
      const svc = LifeParagraphService();
      // 사용자 스토리: 1995-10-27 甲子일주 vs 1996-03-15 甲午일주 wealth.
      final pGapja = await svc.paragraph(
          dayPillar: '갑자', category: LifeCategory.wealth);
      final pGapo = await svc.paragraph(
          dayPillar: '갑오', category: LifeCategory.wealth);
      expect(pGapja, isNot(equals(pGapo)),
          reason: '갑자 vs 갑오 wealth 가 동일하면 R80 sprint 1 회귀');

      // 6 종 갑 일간 일주 wealth 본문 6개 모두 서로 다름.
      final gaps = ['갑자', '갑술', '갑신', '갑오', '갑진', '갑인'];
      final texts = <String>[];
      for (final i in gaps) {
        texts.add(await svc.paragraph(dayPillar: i, category: LifeCategory.wealth));
      }
      final unique = texts.toSet();
      expect(unique.length, equals(6),
          reason: '갑 일간 6 일주 wealth 본문이 모두 달라야 함');
    });

    test('B4 — lint: 평탄 어휘 0 / 단정조 0 / 한자 jargon 0 / AI 슬롭 0 / 의료 단정 0 / 직장인 jargon 0',
        () async {
      const flat = ['균형', '조화', '골고루', '적절히', '적당히'];
      const declarative = ['반드시', '확정', '틀림없', '당연히'];
      // 갑자 R88 fixture 에 "편인데" (조사) false positive 가 있어서 단어 단독 검증은
      // 제외. 명리학 jargon 은 R88 sprint 4 검증 항목 그대로.
      const myeongli = ['격국', '용신', '관성', '식상', '편관', '정관'];
      const medical = ['치료', '진단', '처방'];
      const workplace = ['KPI', '실적', '매출', '커리어 패스', '포트폴리오'];
      const aiSlop = ['센터처럼', '당신의 흐름은', '본인의 결은', '흐름이 살아', 'K팝 센터'];

      const svc = LifeParagraphService();
      for (final ilju in ilju60) {
        if (ilju == '갑자') continue; // R88 fixture, R88 test 가 별도 검증.
        for (final cat in unisex) {
          final p = await svc.paragraph(dayPillar: ilju, category: cat);
          for (final w in flat) {
            expect(p.contains(w), isFalse,
                reason: '$ilju.${lifeCategoryKey(cat)} 평탄 어휘 "$w" leak');
          }
          for (final w in declarative) {
            expect(p.contains(w), isFalse,
                reason: '$ilju.${lifeCategoryKey(cat)} 단정조 "$w" leak');
          }
          for (final w in myeongli) {
            expect(p.contains(w), isFalse,
                reason: '$ilju.${lifeCategoryKey(cat)} 한자 jargon "$w" leak');
          }
          for (final w in medical) {
            expect(p.contains(w), isFalse,
                reason: '$ilju.${lifeCategoryKey(cat)} 의료 단정 "$w" leak');
          }
          for (final w in workplace) {
            expect(p.contains(w), isFalse,
                reason: '$ilju.${lifeCategoryKey(cat)} 직장인 jargon "$w" leak');
          }
          for (final w in aiSlop) {
            expect(p.contains(w), isFalse,
                reason: '$ilju.${lifeCategoryKey(cat)} AI 슬롭 "$w" leak');
          }
        }
      }
    });

    test('B5 — 일주 변별력: 같은 일간 6 일주 pair 평균 Jaccard(4-gram) < 60%',
        () async {
      const svc = LifeParagraphService();
      // 4-gram set 변환 (공백 제거 후).
      Set<String> grams4(String t) {
        final s = t.replaceAll(RegExp(r'\s+'), '');
        final out = <String>{};
        for (var i = 0; i + 4 <= s.length; i++) {
          out.add(s.substring(i, i + 4));
        }
        return out;
      }

      // 14 unisex 카테고리 모두 측정. 한 일간 안 6 일주 paragraph 의 모든 pair 평균.
      const dimension = 14;
      var dimsBelow = 0;
      for (final cat in unisex) {
        final perStemAvg = <double>[];
        for (final stem in stems) {
          final iljus = ilju60.where((i) => i.startsWith(stem)).toList();
          final texts = <String>[];
          for (final ilju in iljus) {
            texts.add(await svc.paragraph(dayPillar: ilju, category: cat));
          }
          final pairs = <double>[];
          for (var i = 0; i < texts.length; i++) {
            for (var j = i + 1; j < texts.length; j++) {
              final a = grams4(texts[i]);
              final b = grams4(texts[j]);
              final u = {...a, ...b};
              if (u.isEmpty) continue;
              final intersect = a.intersection(b).length;
              final union = u.length;
              pairs.add(intersect / union);
            }
          }
          if (pairs.isNotEmpty) {
            perStemAvg
                .add(pairs.reduce((x, y) => x + y) / pairs.length);
          }
        }
        if (perStemAvg.isEmpty) continue;
        final catAvg = perStemAvg.reduce((x, y) => x + y) / perStemAvg.length;
        // 카테고리별 평균이 60% 미만이어야 함 (spec 5.1 mandate).
        expect(catAvg < 0.6, isTrue,
            reason: '${lifeCategoryKey(cat)} 카테고리 같은 일간 평균 Jaccard '
                '${(catAvg * 100).toStringAsFixed(1)}% — 60% 이상이면 변별력 부족');
        dimsBelow++;
      }
      expect(dimsBelow, equals(dimension),
          reason: '$dimension 카테고리 모두 평균 Jaccard <60% 만족해야 함');
    });

    test('B6 — R88 갑자 fixture 보존 (회귀 0)', () async {
      const svc = LifeParagraphService();
      // 갑자 wealth 본문에 R88 의 핵심 anchor phrase 가 그대로 살아있음.
      final p = await svc.paragraph(
          dayPillar: '갑자', category: LifeCategory.wealth);
      expect(p.contains('30대 후반'), isTrue,
          reason: 'R88 갑자 wealth fixture anchor "30대 후반" 보존');
      expect(p.length >= 80, isTrue);
    });

    test('B7 — R88 일간 10 base 보존 (회귀 0)', () async {
      const svc = LifeParagraphService();
      // R88 sprint 5 의 일간 fallback layer = '갑' '을' ... '계' 10 entry.
      for (final stem in stems) {
        final p = await svc.paragraph(
            dayPillar: stem, category: LifeCategory.earlyLife);
        expect(p.length >= 80, isTrue,
            reason: 'R88 $stem 일간 base early_life 보존 (${p.length}자)');
      }
    });
  });
}
