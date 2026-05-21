// R106 — home_screen _OracleHero 미스터리형 전환 회귀.
//
// '오늘의 한 줄' 이 천간×dayEnergy 30 ment pool 에서 미스터리형(오늘 일진 지지 글자 +
// 차트 관계 chung/hap/friction/neutral) 으로 전환됨. 알림(R106 P2b) 과 톤 통일.
//
// 검증:
//  1) relation 4종 × KO/EN pool — 각 5개, {B} 슬롯 주입 후 정상 텍스트, 빈 문자열 0
//  2) KO ment AI 슬롭(흐름이/흐름을/본질/정수/운기/입니다) 0
//  3) ment 가 사용자 감정·사건·미래 사실 단정 X (금지 문자열 가드)
//  4) _OracleHero 가 home build Column 에서 _AppBarBlock 다음 + _ScoreBlock/TodayV5Loader 위
//  5) 거짓말 가드 — relation 은 TodayEventService 산출만 사용 (코드 경로)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final src = File('lib/screens/home_screen.dart').readAsStringSync();
  final classStart = src.indexOf('class _OracleHero');
  final classEnd = src.indexOf('class _HeroGreeting');
  final block = src.substring(classStart, classEnd);

  // 한 relation pool (List<String>) 추출. KO/EN 각각 5개 string 리터럴.
  List<String> extractPool(String poolName, String relationKey) {
    final ps = block.indexOf('$poolName = <MysteryRelation, List<String>>{');
    expect(ps, greaterThanOrEqualTo(0), reason: '$poolName 정의 누락');
    final pe = block.indexOf('};', ps);
    final poolBlock = block.substring(ps, pe);
    final relStart = poolBlock.indexOf('MysteryRelation.$relationKey: [');
    expect(relStart, greaterThanOrEqualTo(0),
        reason: '$poolName.$relationKey 누락');
    final relEnd = poolBlock.indexOf('],', relStart);
    final relBlock = poolBlock.substring(relStart, relEnd);
    // 작은따옴표 / 큰따옴표 string 리터럴 모두 잡는다.
    final out = <String>[];
    final re = RegExp(r"""(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""");
    for (final m in re.allMatches(relBlock)) {
      final raw = m.group(1) ?? m.group(2) ?? '';
      // MysteryRelation.xxx: [ 헤더 부분 string 아님 → 모두 ment.
      out.add(raw
          .replaceAll(r'\n', '\n')
          .replaceAll(r"\'", "'")
          .replaceAll(r'\"', '"'));
    }
    return out;
  }

  const relations = ['chung', 'hap', 'friction', 'neutral'];

  group('R106 — _OracleHero 미스터리형 pool 구조', () {
    test('KO pool — relation 4종 각 5개 (총 20)', () {
      var total = 0;
      for (final r in relations) {
        final p = extractPool('_poolKo', r);
        expect(p.length, 5, reason: 'KO $r pool 은 5개여야 함 (실제 ${p.length})');
        total += p.length;
      }
      expect(total, 20);
    });

    test('EN pool — relation 4종 각 5개 (총 20)', () {
      var total = 0;
      for (final r in relations) {
        final p = extractPool('_poolEn', r);
        expect(p.length, 5, reason: 'EN $r pool 은 5개여야 함 (실제 ${p.length})');
        total += p.length;
      }
      expect(total, 20);
    });

    test('모든 ment 에 {B} 슬롯 존재 + 슬롯 주입 후 빈 문자열 0', () {
      for (final poolName in ['_poolKo', '_poolEn']) {
        for (final r in relations) {
          for (final m in extractPool(poolName, r)) {
            expect(m.contains('{B}'), isTrue,
                reason: '$poolName.$r ment 에 {B} 슬롯 없음: $m');
            // 卯(묘) 슬롯 주입 시뮬레이션.
            final filled = m.replaceAll('{B}', '卯(묘)');
            expect(filled.trim().isNotEmpty, isTrue);
            expect(filled.contains('卯(묘)'), isTrue);
          }
        }
      }
    });
  });

  group('R106 — KO ment 한글 정상 + AI 슬롭 0', () {
    test('KO ment 슬롯 주입 후 한글(가-힣) 포함', () {
      final hangul = RegExp(r'[가-힣]');
      for (final r in relations) {
        for (final m in extractPool('_poolKo', r)) {
          final filled = m.replaceAll('{B}', '卯(묘)');
          expect(hangul.hasMatch(filled), isTrue,
              reason: 'KO $r ment 에 한글 없음: $filled');
        }
      }
    });

    test('EN ment 슬롯 주입 후 영문 알파벳 포함', () {
      final alpha = RegExp(r'[A-Za-z]');
      for (final r in relations) {
        for (final m in extractPool('_poolEn', r)) {
          final filled = m.replaceAll('{B}', 'Mao');
          expect(alpha.hasMatch(filled), isTrue,
              reason: 'EN $r ment 에 영문 없음: $filled');
        }
      }
    });

    test('KO ment AI 슬롭 (흐름이/흐름을/본질/정수/운기/입니다) 0', () {
      const slop = ['흐름이', '흐름을', '본질', '정수', '운기', '입니다'];
      for (final r in relations) {
        for (final m in extractPool('_poolKo', r)) {
          for (final w in slop) {
            expect(m.contains(w), isFalse,
                reason: 'KO $r ment 에 AI 슬롭 "$w" 발견: $m');
          }
        }
      }
    });
  });

  group('R106 — 사실 단정 금지 (사용자 감정·사건·미래 단정 X)', () {
    test('KO ment 사건·미래 단정 금지 문자열 0', () {
      // 미스터리형은 차트 관계(구조)만 진술. 사용자의 하루 결과를 사실로 단정 X.
      const banned = [
        '반드시', '틀림없', '확실히', '분명히 좋', '분명히 나쁜',
        '대박', '큰돈', '돈이 들어와', '사고가 나', '이별', '합격', '불합격',
      ];
      for (final r in relations) {
        for (final m in extractPool('_poolKo', r)) {
          for (final w in banned) {
            expect(m.contains(w), isFalse,
                reason: 'KO $r ment 에 사실 단정 "$w" 발견: $m');
          }
        }
      }
    });

    test('모든 ment 가 "아래 풀이" 로 호기심 유도 (미스터리형 시그니처)', () {
      for (final r in relations) {
        for (final m in extractPool('_poolKo', r)) {
          expect(m.contains('아래 풀이'), isTrue,
              reason: 'KO $r ment 에 "아래 풀이" 유도 없음: $m');
        }
        for (final m in extractPool('_poolEn', r)) {
          expect(m.contains('reading below'), isTrue,
              reason: 'EN $r ment 에 "reading below" 유도 없음: $m');
        }
      }
    });
  });

  group('R106 — 거짓말 0 + first-fold 위치', () {
    test('relation 은 TodayEventService 산출만 사용', () {
      // _relation getter 가 TodayEventService.build → fromHapChungType 경로만 사용하는지.
      final relGetter = block.indexOf('MysteryRelation get _relation');
      expect(relGetter, greaterThanOrEqualTo(0), reason: '_relation getter 누락');
      final relEnd = block.indexOf('}', block.indexOf('{', relGetter));
      final relBody = block.substring(relGetter, relEnd);
      expect(relBody.contains('TodayEventService.build'), isTrue,
          reason: 'relation 이 TodayEventService.build 를 안 씀 — 거짓말 위험');
      expect(relBody.contains('fromHapChungType'), isTrue,
          reason: 'relation 이 fromHapChungType 를 안 씀');
    });

    test('dayEnergy 는 accent 색상에만 사용 (ment 산출 미사용)', () {
      // _pickMent 안에 dayEnergy 참조 0.
      final pmStart = block.indexOf('String _pickMent(');
      final pmEnd = block.indexOf('}', block.indexOf('{', pmStart));
      final pmBody = block.substring(pmStart, pmEnd);
      expect(pmBody.contains('dayEnergy'), isFalse,
          reason: '_pickMent 에 dayEnergy 참조 — ment 산출에 dayEnergy 사용 금지');
    });

    test('home build Column 안 _OracleHero 가 _AppBarBlock 다음 + first-fold', () {
      final appBarPos = src.indexOf('_AppBarBlock()');
      final oracleHeroPos = src.indexOf('_OracleHero(');
      final scoreBlockPos = src.indexOf('_ScoreBlock(');
      final v5LoaderPos = src.indexOf('TodayV5Loader(');
      expect(oracleHeroPos > appBarPos, isTrue,
          reason: '_OracleHero 가 _AppBarBlock 다음에 와야 함');
      expect(oracleHeroPos < scoreBlockPos, isTrue,
          reason: '_OracleHero 가 _ScoreBlock 보다 위 — first-fold');
      expect(oracleHeroPos < v5LoaderPos, isTrue,
          reason: '_OracleHero 가 TodayV5Loader 보다 위 — first-fold');
    });

    test('지지 한자 → 한글음 gloss 12지 전부 존재', () {
      const branches = ['子', '丑', '寅', '卯', '辰', '巳',
          '午', '未', '申', '酉', '戌', '亥'];
      for (final b in branches) {
        expect(block.contains("'$b':"), isTrue,
            reason: '_branchKo 에 $b gloss 누락');
      }
    });
  });
}
