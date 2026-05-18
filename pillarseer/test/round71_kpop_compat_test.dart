// R93 sprint 2 — kpop_compat verdict 사주 anchor 톤 가드.
// 사용자 mandate verbatim: "무대나 이런 내용은 필요없어 그냥 진짜 연인 사주보듯이"
// → K-POP 어휘 (무대/팬싸/굿즈/직캠/컴백/명대사/필모/명장면/시즌/직관/OST) 잔존 0
// → 사주 anchor 어휘 (오행/상생/상극/일주/천간합/지지/합/충/형/십성/$shortName) ≥ 3
//
// 이전 R71/R77 test 는 그 반대를 강제했었으나 R93 사용자 mandate 로 폐기.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _extractVerdict() {
  final src =
      File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
  // R93 sprint 2 → _composeVerdict() body 추출.
  final sig = 'String _composeVerdict()';
  final start = src.indexOf(sig);
  if (start < 0) throw StateError('$sig not found');
  var depth = 0;
  var i = src.indexOf('{', start);
  if (i < 0) throw StateError('$sig open brace not found');
  for (; i < src.length; i++) {
    if (src[i] == '{') depth++;
    if (src[i] == '}') {
      depth--;
      if (depth == 0) return src.substring(start, i + 1);
    }
  }
  throw StateError('$sig close brace not found');
}

void main() {
  group('R93 sprint 2 — kpop_compat verdict 사주 anchor 톤 가드', () {
    final block = _extractVerdict();

    test('K-POP/엔터 어휘 0회 (사용자 mandate verbatim)', () {
      const banned = [
        '무대', '팬싸', '굿즈', '직캠', '컴백', '명대사', '필모',
        '명장면', '직관', 'OST', '플레이리스트', '응원봉',
      ];
      final hits = <String>[];
      for (final w in banned) {
        if (block.contains(w)) hits.add(w);
      }
      expect(hits, isEmpty,
          reason: 'K-POP/엔터 어휘 잔존: $hits. 사용자 mandate "무대나 이런 내용은 필요없어".');
    });

    test('사주 anchor 어휘 ≥ 5 (오행·상생·상극·천간합·지지·합·충·형·일주)', () {
      const anchors = [
        '오행', '상생', '상극', '천간', '지지', '일주',
        '합', '충', '형',
      ];
      var hits = 0;
      for (final w in anchors) {
        if (block.contains(w)) hits++;
      }
      expect(hits >= 5, isTrue,
          reason: '사주 anchor 어휘 hits=$hits — ≥5 필요 (진짜 연인 사주 톤).');
    });

    test(r'동적 합성 ($shortName 사용) — 셀럽 이름 inject 가 본문에 있음', () {
      expect(block.contains(r'$shortName'), isTrue,
          reason: '본문에 셀럽 이름 동적 inject 없음 — generic hardcode.');
    });
  });
}
