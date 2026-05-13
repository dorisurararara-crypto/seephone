// Round 71 회귀 — home_screen _OracleHero (사용자 불만 #8 + #3).
//
// 1) _OracleHero 의 ment pool 30 (천간 10 × dayEnergy 3) 모두 사용자 불만 #3 invariant 통과:
//    - restDay ment 에 "공식 자리·발표·승진·도전·승부" 0회
//    - actionDay ment 에 "쉬어가·아끼" 0회
// 2) 각 ment 가 단정 종결 ≥3 (3 줄 최소 1 단정 종결 / 줄)
// 3) 단정 톤 (~다 / ~한다 / ~온다 / ~정답이다 등) — 헷지 종결 0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Round 71 — _OracleHero ment pool (불만 #8 first-fold + #3 모순 0)', () {
    // _OracleHero 클래스 안 _pool 정의를 추출.
    final src = File('lib/screens/home_screen.dart').readAsStringSync();
    final classStart = src.indexOf('class _OracleHero');
    final classEnd = src.indexOf('class _HeroGreeting');
    final block = src.substring(classStart, classEnd);
    final poolStart = block.indexOf('_pool = <');
    final poolEnd = block.indexOf('};', poolStart);
    final pool = block.substring(poolStart, poolEnd);

    test('ment pool 추출 — 30 entry (천간 10 × dayEnergy 3)', () {
      // restDay 10 + mixedDay 10 + actionDay 10 = 30.
      final gans = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      var count = 0;
      for (final g in gans) {
        count += "'$g':".allMatches(pool).length;
      }
      expect(count, 30, reason: '천간 10 × dayEnergy 3 = 30 ment 필수');
    });

    test('restDay ment 에 "공식 자리·발표·승진·도전·승부" 0회', () {
      // restDay 섹션 추출.
      final restStart = pool.indexOf('DayEnergyKind.restDay:');
      final mixedStart = pool.indexOf('DayEnergyKind.mixedDay:');
      final restSection = pool.substring(restStart, mixedStart);
      const banned = ['공식 자리', '발표', '승진', '도전·승부', '도전 승부'];
      for (final w in banned) {
        expect(restSection.contains(w), isFalse,
            reason: 'restDay ment 에 "$w" 발견 — 불만 #3 모순');
      }
    });

    test('actionDay ment 에 "쉬어가·아끼" 0회', () {
      final actionStart = pool.indexOf('DayEnergyKind.actionDay:');
      final actionSection = pool.substring(actionStart);
      const banned = ['쉬어가', '아끼'];
      for (final w in banned) {
        expect(actionSection.contains(w), isFalse,
            reason: 'actionDay ment 에 "$w" 발견 — 불만 #3 모순');
      }
    });

    test('헷지 어휘 (있어요/할 수 있어요/편이에요/도움됩니다) ≤2건 / pool 전체', () {
      const hedge = ['있어요', '없어요', '할 수 있어요', '편이에요', '도움됩니다',
          '조심하세요', '추천드려요'];
      var total = 0;
      for (final w in hedge) {
        total += RegExp(RegExp.escape(w)).allMatches(pool).length;
      }
      expect(total <= 2, isTrue,
          reason: '_OracleHero ment 헷지 합산 $total — ≤2 필요');
    });

    test('단정 동사 종결 ≥30 / pool 전체 (평균 1 / ment line)', () {
      // 30 ment × 3 줄 = 90 줄 — 단정 동사 종결 ≥30 (1/3 이상 단정).
      const verbs = ['다.', '한다.', '온다.', '된다.', '간다.', '닫힌다.', '열린다.',
          '시작된다.', '정답이다.', '분기점이다.', '마라.', '늦춰라.',
          '본다.', '들어온다.', '바뀐다.', '남는다.'];
      var n = 0;
      for (final w in verbs) {
        n += RegExp(RegExp.escape(w)).allMatches(pool).length;
      }
      expect(n >= 30, isTrue,
          reason: '단정 동사 종결 $n — ≥30 필요 (30 ment 평균 1+ 줄)');
    });

    test('AI 슬롭 (흐름이/결을 가/본질/정수/운기) 0회', () {
      const slop = ['흐름이', '흐름을', '결을 가', '결이다', '본질', '정수', '운기',
          '입니다', 'K팝', '무대 위'];
      for (final w in slop) {
        expect(pool.contains(w), isFalse,
            reason: '_OracleHero ment pool 안 슬롭 "$w" 발견');
      }
    });

    test('home_screen Column 안 _OracleHero 가 _AppBarBlock 다음 위치', () {
      final appBarPos = src.indexOf('_AppBarBlock()');
      final oracleHeroPos = src.indexOf('_OracleHero(');
      final scoreBlockPos = src.indexOf('_ScoreBlock(');
      // _OracleHero 가 _AppBarBlock 다음 + _ScoreBlock 보다 위에 등장 (250px 안 first-fold 보장).
      expect(oracleHeroPos > appBarPos, isTrue);
      expect(oracleHeroPos < scoreBlockPos, isTrue,
          reason: '_OracleHero 가 _ScoreBlock 보다 위 — first-fold 도파민');
    });
  });
}
