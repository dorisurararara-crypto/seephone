// R88 sprint 1 회귀 가드 — 오늘 탭 widget 순서 재배치.
//
// 사용자 mandate (R88 spec sprint 1 verbatim):
//   "맨 위에 오늘 한 줄 → 바로 아래 오늘 사주 총평 → 그 다음에 오늘 이렇게 해 봐
//   → 그 아래로는 기존 widget 들이 원래 순서대로 이어진다."
//
// home_screen.dart 의 build() Column.children 안에서:
//   - 첫 번째 콘텐츠 = `_OracleHero` (오늘 한 줄)
//   - 두 번째 = `TodayDeepReadingSection` (오늘 사주 총평)
//   - 세 번째 = `_CategoryGuides` (오늘 이렇게 해 봐)
//   - 그 아래 `_DeepDiveSection` 안에 기존 위젯 보존
//
// 검증 방식: source 안의 string offset 순서. 무거운 pump 없이 빠른 회귀 guard.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R88 sprint 1 — home 탭 widget 순서 재배치', () {
    final src = File('lib/screens/home_screen.dart').readAsStringSync();

    /// build() 메서드 안의 슬라이스 — '_HomeScreenState' 의 첫 'build(' 부터 끝까지.
    String buildScope() {
      final stateIdx = src.indexOf('class _HomeScreenState');
      expect(stateIdx, greaterThan(-1), reason: '_HomeScreenState 클래스 미발견');
      final buildIdx = src.indexOf('Widget build(', stateIdx);
      expect(buildIdx, greaterThan(-1), reason: '_HomeScreenState.build 미발견');
      // 다음 'class ' 직전까지 잘라냄.
      final nextClass = src.indexOf('\nclass ', buildIdx);
      return src.substring(buildIdx, nextClass > 0 ? nextClass : src.length);
    }

    test('B1 — first-fold 세 widget 순서 = OracleHero → TodayDeepReading → CategoryGuides',
        () {
      final scope = buildScope();
      final oracle = scope.indexOf('_OracleHero(');
      final todayDeep = scope.indexOf('TodayDeepReadingSection(');
      final categoryGuides = scope.indexOf('_CategoryGuides(');
      expect(oracle, greaterThan(-1), reason: '_OracleHero mount 미발견');
      expect(todayDeep, greaterThan(-1),
          reason: 'TodayDeepReadingSection mount 미발견');
      expect(categoryGuides, greaterThan(-1),
          reason: '_CategoryGuides mount 미발견');
      expect(oracle < todayDeep, isTrue,
          reason: '오늘 한 줄(_OracleHero) 이 오늘 사주 총평(TodayDeepReadingSection) 보다 위에 있어야 함');
      expect(todayDeep < categoryGuides, isTrue,
          reason: '오늘 사주 총평이 오늘 이렇게 해 봐(_CategoryGuides) 보다 위에 있어야 함');
    });

    test('B2 — DeepDiveSection 은 first-fold 세 위젯 다음에 위치', () {
      final scope = buildScope();
      final categoryGuides = scope.indexOf('_CategoryGuides(');
      final deepDive = scope.indexOf('_DeepDiveSection(');
      expect(deepDive, greaterThan(-1), reason: '_DeepDiveSection mount 미발견');
      expect(categoryGuides < deepDive, isTrue,
          reason: '_CategoryGuides 가 _DeepDiveSection 보다 먼저 와야 함');
    });

    test('B3 — 기존 위젯 삭제 0 (재배치만): SixAxis / FiveDay / Hourly / TodayEvent / Lucky 등 보존',
        () {
      // build() 안에서 사용되는 위젯 클래스명 — 삭제 X.
      for (final widget in [
        '_OracleHero',
        '_TodayEventCard',
        '_SixAxisCard',
        '_FiveDayTrendCard',
        '_HourlyFlowSection',
        '_ScoreBlock',
        '_LuckyChipsCard',
        '_StreakLine',
        'TodayDeepReadingSection',
        '_CategorySection',
        '_CategoryGuides',
        '_LuckySection',
        '_DeepDiveSection',
      ]) {
        expect(src.contains(widget), isTrue,
            reason: '$widget 삭제됨 (R88 sprint 1 = 재배치만, 삭제 0)');
      }
    });

    test('B4 — _OracleHero 가 build() 안에서 가장 먼저 mount (AppBar 제외 첫 콘텐츠)', () {
      final scope = buildScope();
      // build() 안 _OracleHero 출현이 다른 어떤 콘텐츠 위젯보다 빠름.
      final oracle = scope.indexOf('_OracleHero(');
      for (final later in [
        '_TodayEventCard(',
        '_SixAxisCard(',
        '_FiveDayTrendCard(',
        '_HourlyFlowSection(',
        '_ScoreBlock(',
        'TodayDeepReadingSection(',
        '_CategorySection(',
        '_CategoryGuides(',
        '_LuckySection(',
      ]) {
        final idx = scope.indexOf(later);
        if (idx > -1) {
          expect(oracle < idx, isTrue,
              reason: '_OracleHero 가 $later 보다 먼저 mount 되어야 함');
        }
      }
    });
  });
}
