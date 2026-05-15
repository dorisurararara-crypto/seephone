// Round 82 sprint 3 — _oneLineByJi60Ko 60 entry 한자 jargon 일소 회귀 가드.
//
// 사용자 verbatim (인수인계.md line 14):
//   "벼린칼 같은사람이에요 이 단어도 너무 어렵고"
//
// → 60 entry + 5종 dom fallback 안에 한자 jargon (벼린·도검·정수·본질·결을·
//    운기·기운) 0 + 추상 어휘 (결/결단/우직함/거침없이/충견/영리함/그릇이) 0
//    + R71/R77 blacklist 0 가드.
//
// 60 entry 수 보존 (60 == 60) + 폐기 5종 fallback "벼린 칼 같은" 부활 차단.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final src = File('lib/services/deep_content_service.dart').readAsStringSync();

  // _oneLineByJi60Ko { ... }; 블록을 추출.
  final blockMatch = RegExp(
    r'_oneLineByJi60Ko\s*=\s*\{([\s\S]*?)\};',
  ).firstMatch(src);

  group('Round 82 sprint 3 — _oneLineByJi60Ko jargon 일소', () {
    test('블록 추출 성공', () {
      expect(blockMatch, isNotNull,
          reason: '_oneLineByJi60Ko 블록 grep 실패 — 코드 구조 변경 의심');
    });

    test('60 entry 보존 (수 == 60)', () {
      final block = blockMatch!.group(1)!;
      // 'XX': 'phrase', 패턴 카운트 (한자 2글자 일주 key)
      final entries = RegExp(r"'[^']{2}':\s*'").allMatches(block).length;
      expect(entries, 60,
          reason: '60 entry 수 변경 — 60일주 cover 깨짐 ($entries / 60)');
    });

    test('A1. R82 task blacklist 0 (벼린/도검/정수/본질/결을/운기/기운)', () {
      final block = blockMatch!.group(1)!;
      const blacklist = ['벼린', '도검', '정수', '본질', '결을', '운기', '기운'];
      for (final w in blacklist) {
        expect(block.contains(w), isFalse,
            reason: '60 entry 안에 task blacklist "$w" 발견 — 한자 jargon 잔존');
      }
    });

    test('A2. 추상 어휘 0 (결 단독·결단·우직함·거침없이·충견·영리함·그릇이)', () {
      final block = blockMatch!.group(1)!;
      // 사용자 verbatim "이 단어도 너무 어렵고" 의 spirit — 추상 어휘 전수 제거.
      // "결 더한" / "결 가진" / "결 품은" / "결 숨긴" / "결과 만드는" / "결정 끝내는"
      // 류 모두 차단. 단독 "결" 또는 "결 X" 패턴.
      const slop = [
        '결 더', '결 가', '결 품', '결 숨', '결단', '결과 만',
        '우직', '거침없이', '충견', '영리', '그릇이', '그릇 ',
      ];
      for (final w in slop) {
        expect(block.contains(w), isFalse,
            reason: '60 entry 안에 추상 어휘 "$w" 발견 — 사용자 mandate "쉬운 단어"');
      }
    });

    test('A3. R71 _OracleHero slop blacklist 0 (회귀 가드)', () {
      final block = blockMatch!.group(1)!;
      // R71 lock — 60 entry 도 같은 mandate.
      const r71slop = [
        '흐름이', '흐름을', '본질', '정수', '운기', '센터처럼', '본인의 결은',
      ];
      for (final w in r71slop) {
        expect(block.contains(w), isFalse,
            reason: '60 entry 안에 R71 slop "$w" 발견');
      }
    });

    test('A4. Apologetic AI 어조 0 (죄송하지만/단정 짓기 어렵지만)', () {
      final block = blockMatch!.group(1)!;
      const apol = ['죄송하지만', '단정 짓기 어렵', '확실하진 않지만', '아마도'];
      for (final w in apol) {
        expect(block.contains(w), isFalse,
            reason: '60 entry 안에 apologetic AI tone "$w" 발견');
      }
    });

    test('B1. 5종 dom fallback "벼린 칼 같은" 부활 차단', () {
      // 폐기 5종 fallback — R80 sprint 2 의 사용자 verbatim "벼린 칼 같은
      // 사람 본인+여친 동일" 직발 phrase. R82 sprint 3 에서 전면 교체.
      // 검증 대상: _oneLinerFor 함수 본문의 koMap 5종 string literal 만.
      // (코멘트 안 변경 이력 phrase 는 정당 — 테스트는 실행 phrase 만 검사.)
      final fallbackBlock = RegExp(
        r"koMap\s*=\s*\{\s*"
        r"'木':\s*'([^']*)',\s*"
        r"'火':\s*'([^']*)',\s*"
        r"'土':\s*'([^']*)',\s*"
        r"'金':\s*'([^']*)',\s*"
        r"'水':\s*'([^']*)',\s*\}",
      ).allMatches(src);
      // 두 번째 koMap (en) 은 _oneLinerFor 함수 안 _oneLineByJi60Ko 다음 block 이
      // 아니라 _todayHookFor 안. 첫 매치 = _oneLinerFor 의 ko fallback.
      expect(fallbackBlock.isNotEmpty, isTrue,
          reason: '_oneLinerFor ko fallback 5종 추출 실패');
      final first = fallbackBlock.first;
      final phrases = [
        first.group(1)!,
        first.group(2)!,
        first.group(3)!,
        first.group(4)!,
        first.group(5)!,
      ];

      const rejected = [
        '벼린 칼 같은',
        '쭉 뻗는 나무 같은',
        '환하게 타오르는 불 같은',
        '큰 산 같은',
        '깊은 물 같은',
      ];
      for (final w in rejected) {
        for (final p in phrases) {
          expect(p.contains(w), isFalse,
              reason: 'koMap 5종 phrase "$p" 안에 폐기 fallback "$w" 부활');
        }
      }
    });

    test('B2. 새 5종 fallback 한자 jargon 0', () {
      final fallbackBlock = RegExp(
        r"koMap\s*=\s*\{\s*"
        r"'木':\s*'([^']*)',\s*"
        r"'火':\s*'([^']*)',\s*"
        r"'土':\s*'([^']*)',\s*"
        r"'金':\s*'([^']*)',\s*"
        r"'水':\s*'([^']*)',\s*\}",
      ).allMatches(src).first;
      final phrases = [
        fallbackBlock.group(1)!,
        fallbackBlock.group(2)!,
        fallbackBlock.group(3)!,
        fallbackBlock.group(4)!,
        fallbackBlock.group(5)!,
      ];
      const blacklist = ['벼린', '도검', '정수', '본질', '결을', '운기', '기운'];
      for (final w in blacklist) {
        for (final p in phrases) {
          expect(p.contains(w), isFalse,
              reason: '_oneLinerFor fallback phrase "$p" 안에 jargon "$w" 발견');
        }
      }
    });

    test('C1. 60 entry phrase 끝 — 동사형 어미 (는/한/인) 또는 무종결', () {
      final block = blockMatch!.group(1)!;
      // 'XX': 'phrase', 의 phrase 마지막 글자 추출.
      final entries = RegExp(r"'([^']{2})':\s*'([^']+)'").allMatches(block);
      var bad = <String>[];
      for (final m in entries) {
        final phrase = m.group(2)!;
        final last = phrase.runes.last;
        final lastCh = String.fromCharCode(last);
        // 허용 종결: 는 / 한 / 인 / 가진 / 은 / ㄴ받침 류.
        // 너무 엄격하게 strict 하지 않고, '요' 또는 '다' 같은 종결어미만 차단.
        if (phrase.endsWith('요') || phrase.endsWith('다')) {
          bad.add('${m.group(1)}: $phrase');
        }
        // 사용 안 함 경고
        // ignore: unused_local_variable
        final _ = lastCh;
      }
      expect(bad, isEmpty,
          reason: '60 entry 종결 어미 — "요/다" 종결 phrase 차단 (oneLine 은 형용사구).\n${bad.join('\n')}');
    });
  });
}
