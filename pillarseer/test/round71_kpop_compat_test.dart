// Round 71 회귀 — kpop_compat_screen 로맨스 톤 (사용자 불만 #5).
// Round 77 sprint 7 update — verdict 가 아이돌/배우·스포츠 팬-셀럽 시너지 톤으로 통일.
// 1:1 망상 시나리오 제거 (어휘 0회 가드). K-POP 페르소나 (MZ 중고생) 에게 맞춘
// 무대/컴백/직캠/굿즈/팬싸/명대사/명장면/시즌 어휘로 두 분기 모두 검증.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _extractFn(String fnSig) {
  final src = File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
  final start = src.indexOf(fnSig);
  if (start < 0) {
    throw StateError('$fnSig 함수 못 찾음');
  }
  var depth = 0;
  var i = src.indexOf('{', start);
  if (i < 0) throw StateError('$fnSig 시작 brace 못 찾음');
  for (; i < src.length; i++) {
    if (src[i] == '{') depth++;
    if (src[i] == '}') {
      depth--;
      if (depth == 0) return src.substring(start, i + 1);
    }
  }
  throw StateError('$fnSig 끝 brace 못 찾음');
}

void main() {
  group('Round 77 sprint 7 — _verdictIdol K-POP 팬-아티스트 톤 (mandate 7)', () {
    final idolBlock = _extractFn('String _verdictIdol()');

    test('idol — "사귀면" 어휘 0회 (팬-아티스트 톤, 망상 X)', () {
      expect(idolBlock.contains('사귀면'), isFalse,
          reason: 'idol verdict 에 "사귀면" 잔존 — 팬-아티스트 톤 X');
    });

    test('idol — K-POP 어휘 ≥3종 (무대/컴백/직캠/굿즈/팬싸/콘서트)', () {
      const kpop = ['무대', '컴백', '직캠', '굿즈', '팬싸', '콘서트', '앨범'];
      var hits = 0;
      for (final w in kpop) {
        if (idolBlock.contains(w)) hits++;
      }
      expect(hits >= 3, isTrue,
          reason: 'idol verdict K-POP 어휘 hits=$hits — ≥3 필요');
    });
  });

  group('Round 77 sprint 7 — _verdictRomance 배우/스포츠 팬-셀럽 시너지 (mandate 7)', () {
    final romanceBlock = _extractFn('String _verdictRomance()');

    test('romance — "사귀면" 망상 톤 0회 (팬-셀럽 시너지)', () {
      expect(romanceBlock.contains('사귀면'), isFalse,
          reason: 'romance verdict 에 "사귀면" 잔존 — 망상 톤 X');
    });

    test('romance — 팬-셀럽 어휘 ≥3종 (필모/명대사/명장면/시즌/인터뷰/직관/굿즈)', () {
      const fanSynergy = [
        '필모', '명대사', '명장면', '시즌', '인터뷰', '직관', '굿즈',
        '경기', '작품', 'OST'
      ];
      var hits = 0;
      for (final w in fanSynergy) {
        if (romanceBlock.contains(w)) hits++;
      }
      expect(hits >= 3, isTrue,
          reason: 'romance verdict 팬-셀럽 어휘 hits=$hits — ≥3 필요');
    });
  });
}
