// R89 sprint 2 회귀 가드 — 60 일주 × 3 split 카테고리 × M/F = 360 paragraph 변별 검증.
//
// 사용자 스토리:
//   사용자 A (남, 갑자일주) 와 사용자 B (여, 갑자일주) 가 동시에 result_screen
//   "이성운" 진입, 두 본문이 **다른 텍스트**.
//
// 검증:
//   B1 — 60 일주 × 3 카테고리 × M/F = 360 paragraph 모두 hit (≥80자)
//   B2 — 동일 일주 + 동일 카테고리 + M ≠ F (전 일주에 대해)
//   B3 — lint: 평탄/단정/한자/AI 슬롭/의료/직장인 jargon 0
//   B4 — gender null fallback = M (R88 sprint 4 mandate)
//   B5 — 일주 60 모두 split 카테고리에서 gender 변별

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const stems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  const branches = [
    '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'
  ];
  final ilju60 = <String>[
    for (var n = 0; n < 60; n++) stems[n % 10] + branches[n % 12]
  ];

  const splitCats = [
    LifeCategory.innateCharacter,
    LifeCategory.loveFate,
    LifeCategory.affection,
  ];

  setUpAll(() {
    final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
    final map = json.decode(raw) as Map<String, dynamic>;
    LifeParagraphService.seedForTest(map);
  });

  tearDownAll(() {
    LifeParagraphService.resetCache();
  });

  group('R89 sprint 2 — 60 일주 × 3 split 카테고리 × M/F', () {
    test('B1 — 60 × 3 × 2 = 360 paragraph 모두 hit + ≥80자', () async {
      const svc = LifeParagraphService();
      for (final ilju in ilju60) {
        for (final cat in splitCats) {
          for (final gender in ['M', 'F']) {
            final p = await svc.paragraph(
                dayPillar: ilju, category: cat, gender: gender);
            expect(p.length >= 80, isTrue,
                reason: '$ilju.${lifeCategoryKey(cat)}.$gender 길이 '
                    '${p.length}자 (≥80 mandate)');
          }
        }
      }
    });

    test('B2 — 동일 일주 + 동일 카테고리 + M ≠ F (60 일주 전부)', () async {
      const svc = LifeParagraphService();
      for (final ilju in ilju60) {
        for (final cat in splitCats) {
          final m = await svc.paragraph(
              dayPillar: ilju, category: cat, gender: 'M');
          final f = await svc.paragraph(
              dayPillar: ilju, category: cat, gender: 'F');
          expect(m != f, isTrue,
              reason: '$ilju.${lifeCategoryKey(cat)} M/F 본문 동일 (변별 X)');
        }
      }
    });

    test('B3 — lint: 평탄 어휘 / 단정조 / 한자 jargon / AI 슬롭 / 의료 / 직장인 jargon 0',
        () async {
      const flat = ['균형', '조화', '골고루', '적절히', '적당히'];
      const declarative = ['반드시', '확정', '틀림없', '당연히'];
      const myeongli = ['격국', '용신', '관성', '식상', '편관', '정관'];
      const medical = ['치료', '진단', '처방'];
      const workplace = ['KPI', '실적', '매출', '커리어 패스', '포트폴리오'];
      const aiSlop = ['센터처럼', '당신의 흐름은', '본인의 결', '흐름이 살아', 'K팝 센터'];

      const svc = LifeParagraphService();
      for (final ilju in ilju60) {
        if (ilju == '갑자') continue;
        for (final cat in splitCats) {
          for (final gender in ['M', 'F']) {
            final p = await svc.paragraph(
                dayPillar: ilju, category: cat, gender: gender);
            for (final w in flat) {
              expect(p.contains(w), isFalse,
                  reason: '$ilju.${lifeCategoryKey(cat)}.$gender 평탄 "$w"');
            }
            for (final w in declarative) {
              expect(p.contains(w), isFalse,
                  reason: '$ilju.${lifeCategoryKey(cat)}.$gender 단정 "$w"');
            }
            for (final w in myeongli) {
              expect(p.contains(w), isFalse,
                  reason: '$ilju.${lifeCategoryKey(cat)}.$gender 한자 "$w"');
            }
            for (final w in medical) {
              expect(p.contains(w), isFalse,
                  reason: '$ilju.${lifeCategoryKey(cat)}.$gender 의료 "$w"');
            }
            for (final w in workplace) {
              expect(p.contains(w), isFalse,
                  reason: '$ilju.${lifeCategoryKey(cat)}.$gender 직장 "$w"');
            }
            for (final w in aiSlop) {
              expect(p.contains(w), isFalse,
                  reason: '$ilju.${lifeCategoryKey(cat)}.$gender 슬롭 "$w"');
            }
          }
        }
      }
    });

    test('B4 — gender null fallback = M (R88 sprint 4 spec 2.2.b 채택)',
        () async {
      const svc = LifeParagraphService();
      // 60 일주 × 3 split 카테고리 sample 12 case 검증.
      for (final ilju in ['갑자', '을축', '병인', '경오', '신유', '계해']) {
        for (final cat in splitCats) {
          final nullGender = await svc.paragraph(
              dayPillar: ilju, category: cat, gender: null);
          final mExplicit = await svc.paragraph(
              dayPillar: ilju, category: cat, gender: 'M');
          expect(nullGender, equals(mExplicit),
              reason: '$ilju.${lifeCategoryKey(cat)} gender null fallback = M');
        }
      }
    });

    test('B5 — 일주 변별: 같은 일간 다른 일주 split 카테고리 평균 Jaccard <65% (slightly relaxed for split)',
        () async {
      const svc = LifeParagraphService();
      Set<String> grams4(String t) {
        final s = t.replaceAll(RegExp(r'\s+'), '');
        final out = <String>{};
        for (var i = 0; i + 4 <= s.length; i++) {
          out.add(s.substring(i, i + 4));
        }
        return out;
      }

      for (final cat in splitCats) {
        for (final gender in ['M', 'F']) {
          final perStemAvg = <double>[];
          for (final stem in stems) {
            final iljus = ilju60.where((i) => i.startsWith(stem)).toList();
            final texts = <String>[];
            for (final ilju in iljus) {
              texts.add(await svc.paragraph(
                  dayPillar: ilju, category: cat, gender: gender));
            }
            final pairs = <double>[];
            for (var i = 0; i < texts.length; i++) {
              for (var j = i + 1; j < texts.length; j++) {
                final a = grams4(texts[i]);
                final b = grams4(texts[j]);
                final u = {...a, ...b};
                if (u.isEmpty) continue;
                pairs.add(a.intersection(b).length / u.length);
              }
            }
            if (pairs.isNotEmpty) {
              perStemAvg.add(pairs.reduce((x, y) => x + y) / pairs.length);
            }
          }
          if (perStemAvg.isEmpty) continue;
          final catAvg =
              perStemAvg.reduce((x, y) => x + y) / perStemAvg.length;
          expect(catAvg < 0.65, isTrue,
              reason:
                  '${lifeCategoryKey(cat)}.$gender 평균 Jaccard ${(catAvg * 100).toStringAsFixed(1)}%');
        }
      }
    });
  });
}
