// R88 sprint 4 회귀 가드 — LifeParagraphService + 17 카테고리 DB schema 검증.
//
// 사용자 mandate (R88 spec sprint 4 verbatim):
//   "개발자가 LifeParagraphService().paragraph(dayPillar: '갑자',
//    category: LifeCategory.earlyLife) 를 호출하면 갑자 일주의 초년운 paragraph string
//    이 반환된다. 성별 분기 카테고리 (타고난 인품 / 이성운 / 애정운)는 gender: 'M' 또는
//    gender: 'F' 를 함께 넘기면 다른 paragraph 가 반환된다."
//
// 검증:
//   B1 — LifeCategory enum 17 entry + conclusionSelf
//   B2 — kGenderSplitCategories = {innateCharacter, loveFate, affection} 3 entry
//   B3 — 갑자 fixture: 17 카테고리 + 성별 분기 3 종 모두 채워짐
//   B4 — paragraph(갑자, earlyLife) 호출 시 한국어 paragraph 반환 (≥80자)
//   B5 — paragraph(갑자, innateCharacter, gender: 'M') ≠ paragraph(..., 'F')
//   B6 — paragraph(갑자, innateCharacter, gender: null) = M fallback
//   B7 — paragraph(갑자, earlyLife, gender: 'F') = paragraph(...) (성별 무시)
//   B8 — paragraph(없는 일주, ...) = ''
//   B9 — paragraph(갑자, conclusionSelf) ≥80자
//   B10 — 모든 갑자 paragraph 평탄 어휘 ("균형" / "조화" / "골고루") 0 + 단정조 "~합니다" leak 0
//   B11 — seedForTest / resetCache 동작

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/life_paragraph_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
    final map = json.decode(raw) as Map<String, dynamic>;
    LifeParagraphService.seedForTest(map);
  });

  tearDownAll(() {
    LifeParagraphService.resetCache();
  });

  // spec mandate (R88 sprint 4) 호출 형태 — instance method `LifeParagraphService().paragraph(...)`.
  const svc = LifeParagraphService();

  group('R88 sprint 4 — LifeParagraphService + DB schema', () {
    test('B1 — LifeCategory enum 17 entry + conclusionSelf', () {
      // 17 카테고리 + conclusion_self = enum entry 17 (conclusion_self 가 마지막 1).
      // spec 4.3 의 "19 section" = 5행 차트 + 큰 그림 + 17 카테고리 + 결론 → 그 중
      // service 가 다루는 건 17 카테고리 + conclusion_self = 17 enum entry.
      expect(LifeCategory.values.length, equals(17),
          reason: 'LifeCategory enum 17 entry (16 카테고리 + conclusion_self)');
      // 카테고리 키 모두 등장.
      final keys = LifeCategory.values.map(lifeCategoryKey).toSet();
      for (final expected in const [
        'early_life',
        'mid_life',
        'late_life',
        'health',
        'constitution',
        'social',
        'social_personality',
        'personality',
        'innate_tendency',
        'innate_character',
        'love_fate',
        'affection',
        'wealth',
        'wealth_gather',
        'wealth_loss_prevent',
        'wealth_invest',
        'conclusion_self',
      ]) {
        expect(keys.contains(expected), isTrue,
            reason: 'LifeCategory key "$expected" 누락');
      }
    });

    test('B2 — kGenderSplitCategories = {innateCharacter, loveFate, affection}', () {
      expect(kGenderSplitCategories,
          equals({
            LifeCategory.innateCharacter,
            LifeCategory.loveFate,
            LifeCategory.affection,
          }),
          reason: '성별 분기 카테고리 정확히 3 종');
    });

    test('B3 — 갑자 fixture: 17 카테고리 + 성별 분기 sub-object 모두 채워짐 + paragraph 총량 20', () async {
      expect(await LifeParagraphService.hasDayPillar('갑자'), isTrue);
      // 갑자 안에 17 카테고리 key 모두 존재.
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      final map = json.decode(raw) as Map<String, dynamic>;
      final gapja = map['갑자'] as Map<String, dynamic>;
      var paragraphCount = 0;
      for (final cat in LifeCategory.values) {
        final key = lifeCategoryKey(cat);
        expect(gapja.containsKey(key), isTrue,
            reason: '갑자.$key 카테고리 누락');
        // 성별 분기 = sub-object {M, F}.
        if (kGenderSplitCategories.contains(cat)) {
          final sub = gapja[key];
          expect(sub is Map, isTrue,
              reason: '갑자.$key 가 성별 분기 sub-object 가 아님');
          expect((sub as Map).containsKey('M'), isTrue,
              reason: '갑자.$key.M 누락');
          expect(sub.containsKey('F'), isTrue,
              reason: '갑자.$key.F 누락');
          expect((sub['M'] as String).isNotEmpty, isTrue,
              reason: '갑자.$key.M 빈 값');
          expect((sub['F'] as String).isNotEmpty, isTrue,
              reason: '갑자.$key.F 빈 값');
          paragraphCount += 2;
        } else {
          expect(gapja[key] is String, isTrue,
              reason: '갑자.$key 가 string 카테고리가 아님');
          expect((gapja[key] as String).isNotEmpty, isTrue,
              reason: '갑자.$key 빈 값');
          paragraphCount += 1;
        }
      }
      // 갑자 fixture paragraph 총량 = 13 일반 + 3 split × 2 + 1 conclusion = 20.
      expect(paragraphCount, equals(20),
          reason: '갑자 fixture paragraph 총량 = 20 (13 일반 + 3 split × 2 + 1 conclusion)');
    });

    test('B4 — paragraph(갑자, earlyLife) 호출 시 한국어 paragraph 반환 (≥80자)', () async {
      final p = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.earlyLife,
      );
      expect(p.isNotEmpty, isTrue, reason: '갑자 초년운 paragraph 빈 값');
      expect(p.length >= 80, isTrue,
          reason: '갑자 초년운 paragraph ≥80자 (실제 ${p.length}자): $p');
      // 한국어 본문 — '요' 또는 '에요' 종결.
      expect(p.contains('요'), isTrue, reason: '해요체 본문 보장');
    });

    test('B5 — paragraph(갑자, innateCharacter, M) ≠ paragraph(..., F)', () async {
      final m = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.innateCharacter,
        gender: 'M',
      );
      final f = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.innateCharacter,
        gender: 'F',
      );
      expect(m.isNotEmpty, isTrue);
      expect(f.isNotEmpty, isTrue);
      expect(m != f, isTrue,
          reason: '성별 분기 카테고리에서 M/F 본문 달라야 함\nM: $m\nF: $f');
    });

    test('B6 — paragraph(갑자, innateCharacter, gender: null) = M fallback', () async {
      final mExplicit = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.innateCharacter,
        gender: 'M',
      );
      final genderNull = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.innateCharacter,
        gender: null,
      );
      expect(genderNull, equals(mExplicit),
          reason: 'gender null fallback = M paragraph (spec 2.2.b 채택)');
    });

    test('B7 — paragraph(갑자, earlyLife, gender: F) = paragraph(...) (성별 무시 카테고리)',
        () async {
      final withGender = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.earlyLife,
        gender: 'F',
      );
      final noGender = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.earlyLife,
      );
      expect(withGender, equals(noGender),
          reason: '성별 분기 X 카테고리 — gender 전달해도 동일 paragraph');
    });

    test('B8 — paragraph(없는 일주) = ""', () async {
      final p = await svc.paragraph(
        dayPillar: '없는일주',
        category: LifeCategory.earlyLife,
      );
      expect(p, equals(''), reason: 'DB 에 없는 일주 → 빈 값');
    });

    test('B9 — paragraph(갑자, conclusionSelf) ≥80자', () async {
      final p = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.conclusionSelf,
      );
      expect(p.length >= 80, isTrue,
          reason: '갑자 결론 paragraph ≥80자 (실제 ${p.length}자)');
    });

    test('B10 — 갑자 paragraph 평탄 어휘 0 + 단정조 "~합니다" leak 0 + 한자 jargon 일부 검증 + AI 슬롭 0',
        () async {
      const flatWords = ['균형', '조화', '골고루'];
      const declarative = ['습니다.', '입니다.'];
      const myeongliJargon = ['재성', '관성', '식상', '인성', '비겁'];
      // R88 sprint 4 round 2 codex audit 보강 — AI 슬롭 blacklist 강화.
      const aiSlop = [
        '센터처럼',
        '당신의 흐름은',
        '본인의 결은',
        '흐름이 살아',
        'K팝 센터',
      ];
      const medicalDeclarative = ['진단', '처방', '치료'];
      const workplaceJargon = ['커리어 패스', '포트폴리오', 'ROI', '리텐션', 'PT 잡'];

      for (final cat in LifeCategory.values) {
        final paragraphs = <String>[];
        if (kGenderSplitCategories.contains(cat)) {
          paragraphs.add(await svc.paragraph(
              dayPillar: '갑자', category: cat, gender: 'M'));
          paragraphs.add(await svc.paragraph(
              dayPillar: '갑자', category: cat, gender: 'F'));
        } else {
          paragraphs.add(await svc.paragraph(
              dayPillar: '갑자', category: cat));
        }
        for (final p in paragraphs) {
          for (final flat in flatWords) {
            expect(p.contains(flat), isFalse,
                reason: '${lifeCategoryKey(cat)} 평탄 어휘 "$flat" leak: $p');
          }
          for (final dec in declarative) {
            expect(p.contains(dec), isFalse,
                reason: '${lifeCategoryKey(cat)} 단정조 "$dec" leak: $p');
          }
          for (final jargon in myeongliJargon) {
            expect(p.contains(jargon), isFalse,
                reason: '${lifeCategoryKey(cat)} 한자 jargon "$jargon" leak: $p');
          }
          for (final slop in aiSlop) {
            expect(p.contains(slop), isFalse,
                reason: '${lifeCategoryKey(cat)} AI 슬롭 "$slop" leak: $p');
          }
          for (final med in medicalDeclarative) {
            expect(p.contains(med), isFalse,
                reason: '${lifeCategoryKey(cat)} 의료 단정 "$med" leak: $p');
          }
          for (final jargon in workplaceJargon) {
            expect(p.contains(jargon), isFalse,
                reason: '${lifeCategoryKey(cat)} 직장인 jargon "$jargon" leak: $p');
          }
        }
      }
    });

    test('B11 — seedForTest / resetCache 동작', () async {
      // seed 가 적용된 상태에서 hasDayPillar('갑자') = true.
      expect(await LifeParagraphService.hasDayPillar('갑자'), isTrue);

      // resetCache 후 fake seed.
      LifeParagraphService.resetCache();
      LifeParagraphService.seedForTest({
        '계해': {'early_life': '계해 일주 초년운은 본인의 침착함이 어릴 때부터 또렷하게 보였어요. 어른들이 자주 칭찬할 만큼 차분한 분위기였어요.'},
      });
      expect(await LifeParagraphService.hasDayPillar('갑자'), isFalse);
      expect(await LifeParagraphService.hasDayPillar('계해'), isTrue);
      final p = await svc.paragraph(
          dayPillar: '계해', category: LifeCategory.earlyLife);
      expect(p.contains('계해 일주'), isTrue);

      // 다시 진짜 fixture 로 복구.
      LifeParagraphService.resetCache();
      final raw = File('assets/data/life_paragraphs.json').readAsStringSync();
      LifeParagraphService.seedForTest(
          json.decode(raw) as Map<String, dynamic>);
    });

    test('B12 — availableDayPillars() 에 갑자 포함', () async {
      final list = await LifeParagraphService.availableDayPillars();
      expect(list.contains('갑자'), isTrue,
          reason: '갑자 일주 fixture seed availableDayPillars 에 등장');
    });

    test(
        'B12c — R88 sprint 5: 일간 fallback wire — 일주 60 매칭 없으면 일간 1글자 base 사용',
        () async {
      // sprint 5 의 lookup chain mandate (R89 sprint 1 에서 60 일주 완성 후 갱신):
      //   1. 일주 60 정확 매칭 → paragraph
      //   2. 매칭 없음 + dayPillar 첫 글자 (일간) base 매칭 → 일간 base paragraph
      //   3. 둘 다 없음 → ''
      // R89 sprint 1 mandate 후: 60 갑자 일주는 모두 fixture 에 채워짐.
      // fallback 동작 검증은 fixture 에 없는 dummy 일주로 진행 (실제 운영에서는
      // 변형 일주 입력이나 fixture 부족 시 fallback 안정성 보장).
      // dummy = '갑Z' (Z 는 fixture 에 등록되지 않은 지지) — '갑' 일간 fallback 보장.
      const dummyIlju = '갑Z';
      final pDummy = await svc.paragraph(
        dayPillar: dummyIlju,
        category: LifeCategory.earlyLife,
      );
      final pGap = await svc.paragraph(
        dayPillar: '갑',
        category: LifeCategory.earlyLife,
      );
      expect(pDummy.isNotEmpty, isTrue,
          reason: '$dummyIlju 일주 매칭 없으면 갑 일간 fallback 적용 → 빈 값 X');
      expect(pDummy, equals(pGap),
          reason: '$dummyIlju fallback = 갑 일간 base 와 동일');
    });

    test('B12d — R88 sprint 5: 일간 fallback 도 성별 분기 정확 동작', () async {
      // R89 sprint 1 mandate 후: 60 일주 모두 fixture 에 있어서 직접 매칭.
      // fallback 동작은 fixture 에 없는 dummy 일주로 검증.
      const dummyIlju = '을Z';
      final m = await svc.paragraph(
        dayPillar: dummyIlju,
        category: LifeCategory.loveFate,
        gender: 'M',
      );
      final f = await svc.paragraph(
        dayPillar: dummyIlju,
        category: LifeCategory.loveFate,
        gender: 'F',
      );
      expect(m.isNotEmpty, isTrue,
          reason: '$dummyIlju fallback → 을 일간 + loveFate.M paragraph');
      expect(f.isNotEmpty, isTrue,
          reason: '$dummyIlju fallback → 을 일간 + loveFate.F paragraph');
      expect(m != f, isTrue,
          reason: 'fallback 도 성별 분기 정확 동작');
    });

    test('B12e — R88 sprint 5: 일간 10 base 모두 fixture 에 채워짐', () async {
      const stems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
      for (final stem in stems) {
        final p = await svc.paragraph(
          dayPillar: stem,
          category: LifeCategory.earlyLife,
        );
        expect(p.length >= 80, isTrue,
            reason: 'sprint 5 acceptance: $stem 일간 base early_life ≥80자 (실제 ${p.length}자)');
      }
    });

    test(
        'B13 — instance method 호출 형태 `LifeParagraphService().paragraph(...)` 동작 (spec mandate signature)',
        () async {
      // R88 spec sprint 4 verbatim:
      //   "LifeParagraphService().paragraph(dayPillar: '갑자', category: LifeCategory.earlyLife)"
      const svc = LifeParagraphService();
      final p = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.earlyLife,
      );
      expect(p.isNotEmpty, isTrue,
          reason: 'instance method 호출 → 갑자 초년운 paragraph 반환');
      // static 호출 결과와 동일.
      final pStatic = await LifeParagraphService.paragraphStatic(
        dayPillar: '갑자',
        category: LifeCategory.earlyLife,
      );
      expect(p, equals(pStatic),
          reason: 'instance 와 static 호출 결과 동일');
      // 성별 분기 카테고리 instance 호출.
      final m = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.innateCharacter,
        gender: 'M',
      );
      final f = await svc.paragraph(
        dayPillar: '갑자',
        category: LifeCategory.innateCharacter,
        gender: 'F',
      );
      expect(m != f, isTrue, reason: 'instance 호출 시 성별 분기 정확 동작');
    });
  });
}
