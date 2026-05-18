// R93 sprint 2 — kpop_compat verdict 사주 anchor 톤 가드.
// 사용자 mandate verbatim: "무대나 이런 내용은 필요없어 그냥 진짜 연인 사주보듯이"
// → K-POP 어휘 (무대/팬싸/굿즈/직캠/컴백/명대사/필모/명장면/시즌/직관/OST) 잔존 0
// → 사주 anchor 어휘 (오행/상생/상극/일주/천간합/지지/합/충/형/십성/$shortName) ≥ 3
//
// 이전 R71/R77 test 는 그 반대를 강제했었으나 R93 사용자 mandate 로 폐기.
//
// R96 sprint 1 — 사용자 mandate verbatim: "최애와의 케미가 아직도 다 복사 붙여넣기네
// 그냥 이름만 다르고 ?" → 같은 user + 같은 일주 셀럽 7명이라도 본문이 서로 달라야 한다.
// 기존 fixed relationLine / p4 closer 템플릿 (시그니처 케미 / signature chemistry /
// 이 결이 너의 같은 오행과 만나면 / Place this grain ...) 잔존 시 fail.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readSource() {
  return File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
}

String _extractVerdict() {
  final src = _readSource();
  // R93 sprint 2 → _composeVerdict() body 추출.
  const sig = 'String _composeVerdict()';
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
    final src = _readSource();

    test('K-POP/엔터 어휘 0회 (사용자 mandate verbatim)', () {
      const banned = [
        '무대',
        '팬싸',
        '굿즈',
        '직캠',
        '컴백',
        '명대사',
        '필모',
        '명장면',
        '직관',
        'OST',
        '플레이리스트',
        '응원봉',
      ];
      final hits = <String>[];
      for (final w in banned) {
        if (block.contains(w)) hits.add(w);
      }
      expect(
        hits,
        isEmpty,
        reason: 'K-POP/엔터 어휘 잔존: $hits. 사용자 mandate "무대나 이런 내용은 필요없어".',
      );
    });

    test('사주 anchor 어휘 ≥ 5 (오행·상생·상극·천간합·지지·합·충·형·일주)', () {
      const anchors = ['오행', '상생', '상극', '천간', '지지', '일주', '합', '충', '형'];
      var hits = 0;
      for (final w in anchors) {
        if (block.contains(w)) hits++;
      }
      expect(
        hits >= 5,
        isTrue,
        reason: '사주 anchor 어휘 hits=$hits — ≥5 필요 (진짜 연인 사주 톤).',
      );
    });

    test(r'동적 합성 (shortName inject) — 셀럽 이름 inject 가 본문에 있음', () {
      // R96 sprint 1 — 본문 templating 이 variant pool 로 이동했으므로 _composeVerdict
      // 안에서는 shortName 변수가 (1) helper 호출 args 로 넘어가거나 (2) 본문에
      // 직접 interpolated 돼야 한다.
      final hasShortNameArg =
          block.contains('shortName: shortName') ||
          block.contains('shortName,');
      final hasShortNameInterp = block.contains(r'$shortName');
      expect(
        hasShortNameArg || hasShortNameInterp,
        isTrue,
        reason: '본문에 셀럽 이름 동적 inject 없음 — generic hardcode.',
      );
      // pool 안에서도 셀럽 이름이 inject 되는 placeholder 가 있어야 함.
      expect(
        src.contains(r'$shortName'),
        isTrue,
        reason: r'variant pool 어디에도 $shortName placeholder 가 없음.',
      );
    });

    // R95 sprint 1 — 첫 문장 셀럽별 변별 guard.
    // 사용자 mandate verbatim: "최애와의 케미에 맨 첫문장이 다 똑같아 점수로 매칭하지
    // 말라니까 각각 궁합보듯이 하게하라니까".
    test('R95 — _starIdentityLead helper + 셀럽 고유 lead anchor ≥3/4', () {
      // (1) helper 함수 자체 존재.
      expect(
        src.contains('_starIdentityLead('),
        isTrue,
        reason: '_starIdentityLead helper 가 없음 (R95 mandate).',
      );
      // (2) 셀럽 고유 4 신호 중 최소 3개를 lead 가 사용해야 함 (blurbKo/blurbEn,
      // dayPillarName, birth, 그리고 _composeVerdict 가 lead 를 invoke 하는지).
      final usesBlurb =
          src.contains('star.blurbKo') || src.contains('star.blurbEn');
      final usesPillarName = src.contains('star.dayPillarName');
      final usesBirth = src.contains('star.birth');
      final verdictInvokesLead = block.contains('_starIdentityLead(');
      final hits = [
        usesBlurb,
        usesPillarName,
        usesBirth,
        verdictInvokesLead,
      ].where((b) => b).length;
      expect(
        hits >= 3,
        isTrue,
        reason:
            'R95 셀럽 lead 신호 hits=$hits — ≥3 필요 (blurb / dayPillarName / birth / verdict invoke).',
      );
    });

    // R95 sprint 1 — daily breath + score band helper 분리 guard.
    test(
      'R95 — _composeDailyBreathDetail + _composeScoreBandTexture helper 존재',
      () {
        expect(
          src.contains('_composeDailyBreathDetail('),
          isTrue,
          reason: '_composeDailyBreathDetail helper 누락 — p2 셀럽별 변별 mandate.',
        );
        expect(
          src.contains('_composeScoreBandTexture('),
          isTrue,
          reason: '_composeScoreBandTexture helper 누락 — p3 점수 매칭 금지 mandate.',
        );
      },
    );

    // R95 sprint 1 — p3 "점수 N점 —" prefix 금지 (사용자 mandate "점수로 매칭하지 말라").
    test('R95 — p3 본문이 "점수 N점 —" 로 시작하는 hardcode 사라짐', () {
      // 정규식: \$score 가 본문 첫 머리(점수 _점 — ...) 형태로 직접 박혀 있으면 fail.
      final banned = RegExp(r"'점수 \$score점 —");
      expect(
        banned.hasMatch(block),
        isFalse,
        reason: '"점수 \$score점 —" hardcode 잔존. helper 로 옮겨야 함.',
      );
    });

    // ─────────────────────────────────────────────────────────────
    // R96 sprint 1 — 복사 붙여넣기 fix.
    // 사용자 mandate verbatim: "최애와의 케미가 아직도 다 복사 붙여넣기네 그냥 이름만
    // 다르고 ?" → relation 별 fixed 한 줄 + closer fixed 한 줄 폐기, variant pool 도입.
    // ─────────────────────────────────────────────────────────────

    test('R96 — 폐기된 fixed relation 한 줄이 source 안에 잔존하지 않음', () {
      const bannedSnippets = [
        // KO relation 고정 prose (전체 일치하는 sentinel — 같은 user 의 같은 relation
        // 셀럽 7명이 모두 똑같이 받던 문장).
        '이 결이 너의 같은 오행과 만나면',
        '이 결을 너의 기운이 살리는 상생 자리에 두면',
        '이 결이 오히려 너의 부족한 자리를',
        '이 결을 너의 기운이 누르는 상극 자리에 두면',
        '이 결이 오히려 너의 페이스를 흔드는 상극 자리에 들어와요',
        '이 결과 너 사이엔 자극도 충돌도 크지 않아서',
        // KO closer fixed (전 셀럽 동일).
        '두 사람만의 시그니처 케미가 만들어져요',
        // EN relation/closer fixed.
        'Place this grain against your same element',
        'Set this grain into your producing position',
        'This grain fills the gaps in your own',
        'When this grain meets your overcoming side',
        'This grain shifts your pace with a single word',
        'Mild interaction with your grain',
        'signature chemistry',
      ];
      final hits = <String>[];
      for (final s in bannedSnippets) {
        if (src.contains(s)) hits.add(s);
      }
      expect(
        hits,
        isEmpty,
        reason:
            'R96 — 폐기된 fixed relation/closer 한 줄이 잔존: $hits. variant pool 로 교체했어야 함 (사용자 mandate "복사 붙여넣기").',
      );
    });

    test('R96 — variant pool + seed helper 존재', () {
      // (1) seed 산출 helper.
      expect(
        src.contains('_verdictSeed('),
        isTrue,
        reason:
            '_verdictSeed helper 누락 — star.id 기반 deterministic variation 신호.',
      );
      // (2) variant pool 자체.
      expect(
        src.contains('_relPoolKo'),
        isTrue,
        reason: '_relPoolKo variant pool 누락.',
      );
      expect(
        src.contains('_relPoolEn'),
        isTrue,
        reason: '_relPoolEn variant pool 누락.',
      );
      expect(
        src.contains('_closerPoolKo'),
        isTrue,
        reason: '_closerPoolKo variant pool 누락.',
      );
      expect(
        src.contains('_closerPoolEn'),
        isTrue,
        reason: '_closerPoolEn variant pool 누락.',
      );
      // (3) verdict 가 variant helper 를 invoke 해야 함.
      expect(
        block.contains('relationVariant('),
        isTrue,
        reason: '_composeVerdict 가 relationVariant(...) 를 invoke 하지 않음.',
      );
      expect(
        block.contains('closerVariant('),
        isTrue,
        reason: '_composeVerdict 가 closerVariant(...) 를 invoke 하지 않음.',
      );
      // (4) seed 가 star 고유 신호로 산출돼야 (star.id 기반).
      expect(
        block.contains('starId: star.id'),
        isTrue,
        reason: 'seed 산출에 star.id 가 빠져 있음 — 같은 일주 셀럽 7명 변별 mandate.',
      );
    });

    test('R96 — variant pool 각 relation 당 ≥6 항목 (KO + EN, 6 relation × 2 lang = 12)', () {
      // _relPoolKo / _relPoolEn 각 enum 별 list 항목 개수가 6 이상이어야 한다는
      // 가드 — 같은 일주 6 셀럽 (또는 7명) 모두 unique relation line 보장.
      // codex 8.6/10 rework 3 (variant pool 4 → 6+ 확장) 회귀 방지.
      // 가벼운 source-grep: relation pool 시작과 끝 사이의 line-leading 따옴표 개수.
      // KO/EN 두 pool 영역을 분리해서 enum marker 가 겹치지 않도록 한다.
      const koStartMarker = '_relPoolKo = {';
      const enStartMarker = '_relPoolEn = {';
      final koStart = src.indexOf(koStartMarker);
      final enStart = src.indexOf(enStartMarker);
      expect(koStart >= 0, isTrue, reason: '_relPoolKo 시작 marker 없음');
      expect(enStart > koStart, isTrue, reason: '_relPoolEn 시작 marker 없음');
      // 두 pool 의 닫는 brace 위치 (다음 `};` 까지).
      final koEnd = src.indexOf('};', koStart);
      final enEnd = src.indexOf('};', enStart);
      expect(koEnd > koStart && koEnd < enStart, isTrue);
      expect(enEnd > enStart, isTrue);
      final koSection = src.substring(koStart, koEnd);
      final enSection = src.substring(enStart, enEnd);

      void checkInSection(String langLabel, String section, String enumKey) {
        final openMarker = '$enumKey: [';
        final relStart = section.indexOf(openMarker);
        expect(
          relStart >= 0,
          isTrue,
          reason: '$langLabel / $enumKey 시작 marker 없음',
        );
        final relEnd = section.indexOf('],', relStart);
        expect(
          relEnd > relStart,
          isTrue,
          reason: '$langLabel / $enumKey 끝 marker 없음',
        );
        final body = section.substring(relStart, relEnd);
        // list 항목 = pool block 안에서 line-leading 따옴표 항목 (들여쓰기 6 spaces).
        // raw (r'...' / r"...") 와 일반 ('...' / "...") 모두 카운트.
        final itemPattern = RegExp("\\n      r?['\"]");
        final items = itemPattern.allMatches('\n$body').length;
        expect(
          items >= 6,
          isTrue,
          reason:
              '$langLabel / $enumKey variant 항목 $items 개 — 최소 6 필요 '
              '(같은 일주 6+ 셀럽 unique relation line 보장 mandate).',
        );
      }

      const enums = [
        '_ElRel.same',
        '_ElRel.iGenerate',
        '_ElRel.theyGenerate',
        '_ElRel.iOvercome',
        '_ElRel.theyOvercome',
        '_ElRel.neutral',
      ];
      for (final e in enums) {
        checkInSection('KO', koSection, e);
        checkInSection('EN', enSection, e);
      }
    });
  });
}
