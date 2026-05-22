// R88 sprint 3 회귀 가드 — result_screen.dart 17 카테고리 skeleton 검증.
//
// 사용자 mandate (R88 spec sprint 3 verbatim):
//   "사용자가 내 사주 탭을 열면 (1) 4기둥 8글자 / (2) 5행 차트 / (3) '내 사주 큰 그림'
//   placeholder / (4) 초년운~재테크 비법 placeholder 17 카테고리 / (5) '나는 어떤 사람?'
//   placeholder 가 순서대로 보인다."
//
// 검증:
//   B1 — result_screen build 의 첫 두 콘텐츠 widget = _FourPillarsSection / _FiveElementsSection
//   B2 — _LifeOverviewHero (큰 그림 hero) 가 5행 차트 다음에 mount
//   B3 — kR88LifeCategories 17 카테고리 + conclusion_self enum 19 entry 정의
//   B4 — _CategorySectionCard 가 16 개 mount (conclusion_self 제외)
//   B5 — _SelfConclusionCard ("나는 어떤 사람?") 가 17 카테고리 다음에 mount
//   B6 — build 안에서 deep myeongli widget mount 0 (8 종 모두)
//   B7 — service-level raw 계산 코드 보존 (lib/services/*.dart 안 manseryeok / five_elements / 십신)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R88 sprint 3 — result_screen 17 카테고리 skeleton', () {
    final src = File('lib/screens/result_screen.dart').readAsStringSync();

    /// ResultScreen.build() 슬라이스.
    /// R88 = `class ResultScreen extends ConsumerWidget`,
    /// R89 sprint 3 = `class ResultScreen extends ConsumerStatefulWidget` + `_ResultScreenState`.
    String buildScope() {
      // R89: stateful 변환 — _ResultScreenState.build() 사용.
      var classIdx = src.indexOf('class _ResultScreenState extends');
      if (classIdx < 0) {
        // R88 fallback (정상 작동 보장).
        classIdx = src.indexOf('class ResultScreen extends ConsumerWidget');
      }
      expect(classIdx, greaterThan(-1),
          reason: 'ResultScreen build host class 미발견');
      final buildIdx = src.indexOf('Widget build(', classIdx);
      expect(buildIdx, greaterThan(-1), reason: 'build() 미발견');
      // 다음 `// ────────────` 또는 `}` 단독 class close 까지 잘라냄.
      final end = src.indexOf('// ──────────── R88 sprint 3', buildIdx);
      return src.substring(buildIdx, end > 0 ? end : src.length);
    }

    test('B1 — first 두 콘텐츠 widget = _FourPillarsSection → _FiveElementsSection', () {
      final scope = buildScope();
      final fp = scope.indexOf('_FourPillarsSection(');
      final fe = scope.indexOf('_FiveElementsSection(');
      expect(fp, greaterThan(-1), reason: '_FourPillarsSection mount 미발견');
      expect(fe, greaterThan(-1), reason: '_FiveElementsSection mount 미발견');
      expect(fp < fe, isTrue,
          reason: '4기둥 8글자가 5행 차트 보다 먼저 mount');
    });

    test('B2 — _LifeOverviewHero 가 5행 차트 다음에 mount', () {
      final scope = buildScope();
      final fe = scope.indexOf('_FiveElementsSection(');
      final overview = scope.indexOf('_LifeOverviewHero(');
      expect(overview, greaterThan(-1), reason: '_LifeOverviewHero mount 미발견');
      expect(fe < overview, isTrue,
          reason: '5행 차트가 큰 그림 hero 보다 먼저 mount');
    });

    test('B3 — kR88LifeCategories 17 카테고리 + conclusion_self entry 정의', () {
      expect(src.contains('kR88LifeCategories'),
          isTrue,
          reason: 'kR88LifeCategories 정의 미발견');
      // 17 카테고리 + conclusion_self = list length 17.
      // 카테고리 키 hard-coded list:
      const expectedKeys = <String>[
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
      ];
      for (final key in expectedKeys) {
        expect(src.contains("key: '$key'"), isTrue,
            reason: 'kR88LifeCategories 의 key "$key" 누락');
      }
    });

    test('B4 — _CategorySectionCard 가 conclusion_self 제외 16 entry mount + kR88LifeCategories length 17',
        () {
      final scope = buildScope();
      expect(scope.contains('_CategorySectionCard('), isTrue,
          reason: '_CategorySectionCard mount 미발견');
      // 명시적으로 conclusion_self 제외 filter 가 build 안에 있음.
      expect(scope.contains("cat.key != 'conclusion_self'"), isTrue,
          reason: 'conclusion_self 는 별도 _SelfConclusionCard 로 분리');
      // kR88LifeCategories 의 key 개수 — record literal `(key: '...')` 출현 17 (17 카테고리 + conclusion_self).
      // source-grep 으로 length 검증 — `key: '...'` pattern count = 17.
      final keyMatches = RegExp(r"key: '\w+'").allMatches(src).length;
      // 단, build 안 callback param `cat.key` 매칭 제외 (위 정규식은 `'\w+'` literal).
      expect(keyMatches, equals(17),
          reason: 'kR88LifeCategories length = 17 (key literal 17개)');
      // conclusion_self 제외 length = 16 (build 의 .where filter 가 처리).
      // const list 안 conclusion_self entry 가 1 개 → 16 카테고리 _CategorySectionCard mount.
    });

    test('B4b — kR88LifeCategories 의 previewKo 16 개 모두 unique + 해요체 종결', () {
      // 16 카테고리 placeholder 본문 (conclusion_self 제외) 가 서로 다른 한 줄.
      // codex evaluator 가 "skeleton 이라도 다 같은 문장이면 PASS 차감" 지적 → 강제 unique.
      final previewMatches =
          RegExp(r"previewKo: '([^']+)'", multiLine: true).allMatches(src);
      final previews = previewMatches.map((m) => m.group(1)!).toList();
      expect(previews.length, equals(17),
          reason: 'previewKo 17 entry (17 카테고리 + conclusion_self)');
      // 17 카테고리 전체 unique.
      expect(previews.toSet().length, equals(17),
          reason: 'previewKo 17 개 모두 unique (skeleton 반복 X)');
      // 모두 해요체 종결.
      for (final p in previews) {
        final ok = p.endsWith('요.') ||
            p.endsWith('어요.') ||
            p.endsWith('이에요.') ||
            p.endsWith('여요.') ||
            p.endsWith('해요.');
        expect(ok, isTrue,
            reason: '카테고리 preview 가 해요체 종결: "$p"');
      }
      // 단정조 "~합니다" leak 0.
      for (final p in previews) {
        expect(p.contains('습니다'), isFalse,
            reason: '단정조 "~습니다" leak: "$p"');
        expect(p.contains('입니다'), isFalse,
            reason: '단정조 "~입니다" leak: "$p"');
      }
    });

    test('B5 — _SelfConclusionCard 가 17 카테고리 다음에 mount', () {
      final scope = buildScope();
      final category = scope.indexOf('_CategorySectionCard(');
      final selfConc = scope.indexOf('_SelfConclusionCard(');
      expect(selfConc, greaterThan(-1),
          reason: '_SelfConclusionCard mount 미발견');
      expect(category < selfConc, isTrue,
          reason: '17 카테고리가 결론 card 보다 먼저 mount');
    });

    test('B6 — build 안에서 deep myeongli widget mount 0 (R110 무료 모듈 제외)', () {
      final scope = buildScope();
      // 사용자 mandate "원래 우리 앱에 있던 나머지 것들은 전부 없애줘".
      // result_screen build 안에서 mount 0 검증.
      //
      // R110 Sprint 2 REWORK — playbook 무료 핵심 5("나는 어떤 사람인가 +
      // 오행 균형 + 십신 성향 + 강점/주의점 + 오늘 조언")를 화면 상단 무료
      // 모듈이 함께 충족하도록 `_ChartAttributesSection`(오행/강약/용신 보조
      // 정보)·`_ForYouTodaySection`(강점·주의·오늘 조언) 두 widget 을 무료
      // 영역(PremiumGate 밖)에 다시 mount 한다. 따라서 이 둘은 더 이상 mount
      // 0 대상이 아니다 — B1b(r110_premium_gate_test) 가 두 widget 의 무료
      // mount 와 게이트 앞 위치를 별도로 가드한다.
      for (final widget in const [
        '_DayMasterHero(',
        '_SipsinPersonaSection(',
        '_LifeStageSection(',
        '_AdditionalLifeSection(',
        '_ThreeStrokesSection(',
        '_ReadingSection(',
        '_CareerSection(',
        '_WealthStrategySection(',
        '_CrossmatchSection(',
        '_ZiweiPalaceGroup(',
        '_GroupSection(',
        '_GyeokgukBlock(',
        '_YongsinBlock(',
        '_StrengthBlock(',
        '_GongMangBlock(',
        '_ShinsaBlock(',
        '_TwelveUnsungBlock(',
        '_HapchungBlock(',
        '_CalculationBasisBody(',
        '_ProHooksSection(',
        '_AccordionRow(',
        '_CollapsibleSection(',
      ]) {
        expect(scope.contains(widget), isFalse,
            reason: 'R88 sprint 3 — build 안 $widget mount 0 (deep 명리학 widget 제거)');
      }
    });

    test('B7 — service-level raw 계산 코드 보존 (lib/services/*.dart 안 manseryeok / five_elements / 십신)',
        () {
      // 사용자 mandate "service-level raw 계산 코드 보존 — 다른 미래 화면 참조 가능".
      expect(File('lib/services/manseryeok_service.dart').existsSync(), isTrue,
          reason: 'manseryeok_service.dart 파일 보존');
      expect(File('lib/services/saju_service.dart').existsSync(), isTrue,
          reason: 'saju_service.dart 파일 보존');
      // 5행 계산 — saju_result 의 elements field 또는 별도 service.
      expect(File('lib/services/ten_gods_service.dart').existsSync(), isTrue,
          reason: 'ten_gods_service.dart 파일 보존');
      // R83 P1-B 자시 학파 picker 의존 — input_screen 보존 검증.
      final inputSrc = File('lib/screens/input_screen.dart').readAsStringSync();
      expect(inputSrc.contains('_unknownTime') || inputSrc.contains('unknownTime'),
          isTrue,
          reason: 'R83 P1-E 시간 모름 처리 input_screen 보존');
    });

    test('B8 — _FourPillarsSection / _FiveElementsSection widget class 보존', () {
      // result_screen build 에서 mount 되므로 class 정의 자체 보존 필수.
      expect(src.contains('class _FourPillarsSection'), isTrue,
          reason: '_FourPillarsSection class 정의 보존');
      expect(src.contains('class _FiveElementsSection'), isTrue,
          reason: '_FiveElementsSection class 정의 보존');
    });

    test('B9 — _LifeOverviewHero / _CategorySectionCard / _SelfConclusionCard widget class 신설',
        () {
      expect(src.contains('class _LifeOverviewHero'), isTrue,
          reason: 'R88 sprint 3 — _LifeOverviewHero widget 신설');
      expect(src.contains('class _CategorySectionCard'), isTrue,
          reason: 'R88 sprint 3 — _CategorySectionCard widget 신설');
      expect(src.contains('class _SelfConclusionCard'), isTrue,
          reason: 'R88 sprint 3 — _SelfConclusionCard widget 신설');
    });
  });
}
