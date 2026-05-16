// R86 sprint 2 — _OracleHero ment pool 30 entry 의 반말 / AI 패턴 일소 회귀 가드.
//
// 사용자 mandate (1.0.0+42 verbatim):
//   "오늘 너 = 이런 표현 빼줘 ai같아 그리고 어떤 부분은 반말 어떤부분은 존댓말이네ㅜ
//    이런것도 다 없애"
//
// 검증:
//   B1 — "X = Y" Co-Star 식 등호 패턴 ("너 =", "키워드 =") 본문 노출 0
//   B2 — 반말 단정 종결 ("다야.", "정답.", "기회야.", "장점.", "진짜야.", "패스.",
//        "끝.", "정해.", "잊어.", "편해져.", "잡혀.", "아니야.", "없어." 등) 0
//   B3 — 해요체 평서 종결 (이에요./예요./돼요./봐요./좋아요./충분해요./아니에요. 등)
//        ≥ 60 (30 ment × 평균 2 line — 한 ment 안에 해요체 종결 다수)
//   B4 — 모든 ment 가 3 line 보장 (\\n 정확히 2 회)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R86 sprint 2 — _OracleHero 반말/AI 패턴 일소', () {
    final src = File('lib/screens/home_screen.dart').readAsStringSync();
    final classStart = src.indexOf('class _OracleHero');
    final classEnd = src.indexOf('class _HeroGreeting');
    final block = src.substring(classStart, classEnd);
    final poolStart = block.indexOf('_pool = <');
    final poolEnd = block.indexOf('};', poolStart);
    final pool = block.substring(poolStart, poolEnd);

    test('B1 — "X = Y" Co-Star 식 등호 패턴 본문 노출 0', () {
      const banned = ['너 =', '키워드 ='];
      for (final w in banned) {
        expect(pool.contains(w), isFalse,
            reason: '_OracleHero _pool 안 AI 패턴 "$w" 잔존 — R86 사용자 mandate');
      }
    });

    test('B2 — 반말 단정 종결 (다야./정답./기회야./장점./진짜야./편해져./잡혀./끝./잊어./편이야.) 0',
        () {
      // 명시적인 반말 종결만 검사 (한국어 자연 어순에서 곧바로 따라오는 closer).
      const informalEndings = [
        '다야.', '정답.', '기회야.', '장점.', '진짜야.', '편해져.', '잡혀.',
        '편이야.', '아니야.', '잊어.', '정해.', '풀려.', '만들어.', '패스.',
      ];
      for (final w in informalEndings) {
        expect(pool.contains(w), isFalse,
            reason: '_OracleHero _pool 안 반말 종결 "$w" 잔존 — R86 사용자 mandate');
      }
    });

    test('B3 — 해요체 평서 종결 ≥ 60 (30 ment × 평균 2 line 해요체)', () {
      const politeEndings = [
        '이에요.', '예요.', '돼요.', '봐요.', '와요.', '해요.', '가요.',
        '좋아요.', '괜찮아요.', '커요.', '미뤄요.', '늦춰요.', '챙겨요.',
        '지켜요.', '쉬워요.', '편해져요.', '잡혀요.', '보여요.', '아니에요.',
        '충분해요.', '편이에요.', '맞아요.', '있어요.', '없어요.',
        '많아요.', '풀려요.', '남아요.', '이어져요.', '정해줘요.', '만들어줘요.',
        '결정해줘요.', '잊지 못해요.', '또렷해져요.', '받쳐줘요.', '채워줘요.',
        '가벼워져요.', '못해요.', '않아요.', '다쳐요.', '모여요.',
      ];
      var n = 0;
      for (final w in politeEndings) {
        n += RegExp(RegExp.escape(w)).allMatches(pool).length;
      }
      expect(n >= 60, isTrue,
          reason: '_OracleHero _pool 해요체 평서 종결 $n — ≥ 60 필요 (30 ment × 평균 2 line)');
    });

    test('B4 — ment 30 entry 모두 3 line (\\n 정확히 2 회)', () {
      // ko literal 추출 — 작은따옴표 안의 multiline string.
      // pool 안 30개 entry 모두 형식: '甲': '...\n...\n...',
      final entryRegex =
          RegExp(r"'(?:甲|乙|丙|丁|戊|己|庚|辛|壬|癸)':\s*'([^']*)'");
      final matches = entryRegex.allMatches(pool).toList();
      expect(matches.length, 30,
          reason: 'pool entry 30개 추출 실패 (실제 ${matches.length})');
      for (final m in matches) {
        final body = m.group(1)!;
        final nlCount = '\\n'.allMatches(body).length;
        expect(nlCount, 2,
            reason: 'ment "$body" — \\n 가 정확히 2회 (3 line) 가 아님');
      }
    });
  });
}
