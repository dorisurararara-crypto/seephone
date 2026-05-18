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

    // R95 sprint 1 — 첫 문장 셀럽별 변별 guard.
    // 사용자 mandate verbatim: "최애와의 케미에 맨 첫문장이 다 똑같아 점수로 매칭하지
    // 말라니까 각각 궁합보듯이 하게하라니까".
    test('R95 — _starIdentityLead helper + 셀럽 고유 lead anchor ≥3/4', () {
      final src =
          File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
      // (1) helper 함수 자체 존재.
      expect(src.contains('_starIdentityLead('), isTrue,
          reason: '_starIdentityLead helper 가 없음 (R95 mandate).');
      // (2) 셀럽 고유 4 신호 중 최소 3개를 lead 가 사용해야 함 (blurbKo/blurbEn,
      // dayPillarName, birth, 그리고 _composeVerdict 가 lead 를 invoke 하는지).
      final usesBlurb =
          src.contains('star.blurbKo') || src.contains('star.blurbEn');
      final usesPillarName = src.contains('star.dayPillarName');
      final usesBirth = src.contains('star.birth');
      final verdictInvokesLead = block.contains('_starIdentityLead(');
      final hits = [usesBlurb, usesPillarName, usesBirth, verdictInvokesLead]
          .where((b) => b)
          .length;
      expect(hits >= 3, isTrue,
          reason:
              'R95 셀럽 lead 신호 hits=$hits — ≥3 필요 (blurb / dayPillarName / birth / verdict invoke).');
    });

    // R95 sprint 1 — daily breath + score band helper 분리 guard.
    test('R95 — _composeDailyBreathDetail + _composeScoreBandTexture helper 존재',
        () {
      final src =
          File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
      expect(src.contains('_composeDailyBreathDetail('), isTrue,
          reason: '_composeDailyBreathDetail helper 누락 — p2 셀럽별 변별 mandate.');
      expect(src.contains('_composeScoreBandTexture('), isTrue,
          reason: '_composeScoreBandTexture helper 누락 — p3 점수 매칭 금지 mandate.');
    });

    // R95 sprint 1 — p3 "점수 N점 —" prefix 금지 (사용자 mandate "점수로 매칭하지 말라").
    test('R95 — p3 본문이 "점수 N점 —" 로 시작하는 hardcode 사라짐', () {
      // 정규식: \$score 가 본문 첫 머리(점수 _점 — ...) 형태로 직접 박혀 있으면 fail.
      final banned = RegExp(r"'점수 \$score점 —");
      expect(banned.hasMatch(block), isFalse,
          reason: '"점수 \$score점 —" hardcode 잔존. helper 로 옮겨야 함.');
    });
  });
}
