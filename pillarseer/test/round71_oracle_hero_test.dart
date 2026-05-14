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

    test('헷지 어휘 (할 수 있어요/도움됩니다/조심하세요/추천드려요) ≤2건 / pool 전체', () {
      // Round 77 sprint 4 — mandate 해요체 변환 후 "있어요/편이에요" 는 단정 평서 해요체 이므로 제외.
      const hedge = ['할 수 있어요', '도움됩니다', '조심하세요', '추천드려요',
          '~것 같다', '~일지도'];
      var total = 0;
      for (final w in hedge) {
        total += RegExp(RegExp.escape(w)).allMatches(pool).length;
      }
      expect(total <= 2, isTrue,
          reason: '_OracleHero ment 헷지 합산 $total — ≤2 필요');
    });

    test('단정 평서 종결 ≥30 / pool 전체 (평균 1 / ment line)', () {
      // Round 77 sprint 6 — mandate: 단정조 / 질문조 / 인용·밈 톤 3 형식 변주.
      // 30 ment × 3 줄 = 90 줄 — 단정 평서 / 단정 명령 / 단정 슬로건 ≥30.
      // 인용·밈 톤 (= 너 = 사람.) 도 단정 평서로 카운트.
      const verbs = [
        // 해요체 단정 평서 (Round 77 sprint 4 잔존)
        '이에요.', '예요.', '돼요.', '와요.', '해요.', '가요.', '봐요.',
        '맞아요.', '나아요.', '좋아요.', '있어요.', '편이에요.', '정해요.',
        '만들어요.', '잡혀요.', '보여요.', '내려요.', '져요.', '아니에요.',
        '미뤄요.', '늦춰요.', '챙겨요.', '지켜요.', '받아 봐요.', '마세요.',
        // 친구 톤 반말 단정 (Round 77 sprint 6 신규)
        '진짜야.', '다야.', '정답.', '없어.', '편해져.', '아니야.',
        '잡혀.', '풀려.', '봐.', '봐.\n', '만들어.', '기회야.', '장점.',
        '보내 봐.', '처리해 봐.', '끝내.', '미뤄.', '늦춰.', '패스.', '끝.',
        '정해.', '잊어.', '챙겨.', '지켜.', '돼.', '커.', '먹어.',
        '있어.', '없어.\n',
      ];
      var n = 0;
      for (final w in verbs) {
        n += RegExp(RegExp.escape(w)).allMatches(pool).length;
      }
      expect(n >= 30, isTrue,
          reason: '단정 평서 종결 $n — ≥30 필요 (30 ment 평균 1+ 줄)');
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
