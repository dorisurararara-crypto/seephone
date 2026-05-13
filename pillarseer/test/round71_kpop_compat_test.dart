// Round 71 회귀 — kpop_compat_screen 로맨스 톤 (사용자 불만 #5).
//
// 4 band 의 _verdict() 출력에서:
// 1) K-POP 추상 비유 어휘 (무대/시너지/퍼포먼스/팬덤/응원/센터/컴백/카메라 워크) 0회
// 2) 1:1 로맨스 어휘 (사귀면/첫 만남/카톡/답장/만나서/데이트/표현/마음/먼저) ≥10회 (4 band 합산)
// 3) 헷지 어휘 (입니다/있어요/할 수 있어요/도움됩니다/조심하세요) ≤ 2건

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _extractVerdictBlock() {
  final src = File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
  final verdictStart = src.indexOf('String _verdict()');
  if (verdictStart < 0) {
    throw StateError('_verdict() 함수 못 찾음');
  }
  // `String _verdict() {` 시작 이후 brace depth 추적해서 함수 끝 찾기.
  var depth = 0;
  var i = src.indexOf('{', verdictStart);
  if (i < 0) throw StateError('_verdict 시작 brace 못 찾음');
  for (; i < src.length; i++) {
    if (src[i] == '{') depth++;
    if (src[i] == '}') {
      depth--;
      if (depth == 0) return src.substring(verdictStart, i + 1);
    }
  }
  throw StateError('_verdict 끝 brace 못 찾음');
}

void main() {
  group('Round 71 — kpop_compat_screen 로맨스 톤 (불만 #5)', () {
    final verdictBlock = _extractVerdictBlock();

    test('K-POP 추상 비유 어휘 0회 (무대/시너지/퍼포먼스/팬덤/응원/센터/컴백/카메라 워크)', () {
      const banned = ['무대', '시너지', '퍼포먼스', '팬덤', '응원', '센터', '컴백', '카메라 워크', 'fancam'];
      for (final w in banned) {
        expect(verdictBlock.contains(w), isFalse,
            reason: 'verdict 안 "$w" 등장 — 사용자 불만 #5 무대 비유 X');
      }
    });

    test('1:1 로맨스 어휘 ≥10회 (사귀면/첫 만남/카톡/답장/만나서/데이트/표현/마음/먼저)', () {
      const romance = ['사귀면', '첫 만남', '카톡', '답장', '만나서', '만난', '데이트', '표현', '마음', '먼저'];
      var total = 0;
      for (final w in romance) {
        total += RegExp(RegExp.escape(w)).allMatches(verdictBlock).length;
      }
      expect(total >= 10, isTrue,
          reason: '1:1 로맨스 어휘 합산 $total — ≥10 필요 (사용자 불만 #5)');
    });

    test('헷지 어휘 ≤2건 (있어요/할 수 있어요/도움됩니다/조심하세요)', () {
      const hedge = ['있어요', '없어요', '할 수 있어요', '편이에요', '도움됩니다', '조심하세요', '추천드려요'];
      var total = 0;
      for (final w in hedge) {
        total += RegExp(RegExp.escape(w)).allMatches(verdictBlock).length;
      }
      expect(total <= 2, isTrue,
          reason: '헷지 어휘 합산 $total — ≤2 필요 (단정 톤)');
    });

    test('단정 종결 (다./한다./온다./된다./준다./많아진다./잡는다./않는다./비슷하다.) 비율 높음', () {
      // verdictBlock 안 단정 종결 동사 ≥10 개.
      const assertVerbs = ['다.', '한다.', '온다.', '된다.', '준다.', '많아진다.',
          '잡는다.', '아진다.', '비슷하다.', '되면', '아니다.'];
      var n = 0;
      for (final w in assertVerbs) {
        n += RegExp(RegExp.escape(w)).allMatches(verdictBlock).length;
      }
      expect(n >= 10, isTrue,
          reason: '단정 동사 종결 $n — ≥10 필요 (단정 톤)');
    });
  });
}
