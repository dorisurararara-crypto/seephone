// R104 sprint 6b — life_paragraphs.json 받침-조사 불일치 0 회귀 가드.
//
// 배경: Sprint 6 의 r91 "본인" dedup 이 받침 ㄴ 있는 "본인"을 받침 없는
// 단어("자기/스스로/그")로 치환하면서 뒤따르는 한국어 조사를 안 고쳤다.
// → "자기을"(43건), "자기 인장로"(7건) 등 조사 불일치 발생.
//
// codex git diff 검수 verbatim:
//   "자기을" → "자기를", "자기 인장로" → "자기 인장으로".
//
// 이 가드는 life_paragraphs.json 전체 문자열에서 받침 없는 단어 +
// 받침 있는 조사, 받침 명사 + 받침 없는 조사 패턴을 검출해 0 을 보장한다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String raw;
  late List<String> paragraphs;

  // dedup 치환어. 받침 여부:
  //  - "자기"  : 받침 X
  //  - "스스로": 받침 X
  //  - "그"    : 받침 X
  //  - "자신"  : 받침 O (ㄴ) — 본인과 동일 패턴이라 조사 그대로 OK
  // 받침 없는 단어 뒤에 와서는 안 되는(받침용) 조사.
  const badAfterNoBatchim = <String>['을', '이', '은', '으로', '과'];

  setUpAll(() async {
    final f = File('assets/data/life_paragraphs.json');
    raw = await f.readAsString();
    final Map<String, dynamic> map =
        json.decode(raw) as Map<String, dynamic>;
    paragraphs = <String>[];
    void collect(dynamic v) {
      if (v is String) {
        paragraphs.add(v);
      } else if (v is List) {
        for (final e in v) {
          collect(e);
        }
      } else if (v is Map) {
        for (final e in v.values) {
          collect(e);
        }
      }
    }

    collect(map);
  });

  group('R104 — life_paragraphs.json 받침-조사 불일치 0', () {
    test('JSON 은 유효하고 문단이 존재한다', () {
      expect(paragraphs, isNotEmpty);
      expect(paragraphs.length, greaterThan(300));
    });

    test('받침 없는 단어("자기/스스로/그") + 받침용 조사 0', () {
      // 단어 자체로 끝나고 바로 조사가 붙는 경우만.
      // "자기소개"·"그것" 같은 다른 단어의 일부는 제외 (조사 목록이 명사 시작
      // 글자와 겹치지 않게 한정).
      final offenders = <String>[];
      for (final word in <String>['자기', '스스로', '그']) {
        for (final josa in badAfterNoBatchim) {
          final re = RegExp('$word$josa');
          for (final p in paragraphs) {
            for (final m in re.allMatches(p)) {
              // "그" 는 단어 경계 확인 — 직전이 한글이면 다른 단어의 일부.
              if (word == '그') {
                final i = m.start;
                if (i > 0) {
                  final prev = p[i - 1];
                  if (RegExp('[가-힣]').hasMatch(prev)) continue;
                }
              }
              final s = m.start;
              final e = (m.end + 12).clamp(0, p.length);
              offenders.add('[$word+$josa] ...'
                  '${p.substring((s - 12).clamp(0, p.length), e)}...');
            }
          }
        }
      }
      expect(offenders, isEmpty,
          reason: '받침-조사 불일치 ${offenders.length}건:\n'
              '${offenders.take(20).join('\n')}');
    });

    test('codex 가 짚은 구체 패턴 0 — "자기을", "자기 인장로"', () {
      expect(raw.contains('자기을'), isFalse,
          reason: '"자기을" 잔존 — "자기를" 이어야 함');
      expect(raw.contains('자기 인장로'), isFalse,
          reason: '"자기 인장로" 잔존 — "자기 인장으로" 이어야 함');
    });

    test('"자기 NN로" — 받침 명사는 모두 "으로"', () {
      // "자기 " + 명사 + "로" 패턴에서 명사 끝 글자가 받침을 가지면
      // "으로"여야 한다. 단 ㄹ받침은 "로" 허용. "대로" 같은 의존명사는 제외.
      final re = RegExp('자기 ([가-힣]+)로');
      final offenders = <String>[];
      for (final p in paragraphs) {
        for (final m in re.allMatches(p)) {
          final noun = m.group(1)!;
          if (noun.isEmpty) continue;
          // "대"로 끝나면 "대로"(의존명사) → 제외.
          if (noun.endsWith('대')) continue;
          final last = noun.codeUnitAt(noun.length - 1);
          // 한글 음절 받침 추출: (code-0xAC00) % 28, 0=받침없음.
          if (last < 0xAC00 || last > 0xD7A3) continue;
          final jong = (last - 0xAC00) % 28;
          // jong 8 = ㄹ → "로" OK. 0 = 받침없음 → "로" OK.
          if (jong == 0 || jong == 8) continue;
          // "으로"였다면 명사 안에 "으"가 안 들어왔을 것 — 즉 noun 자체가
          // "으"로 끝나 "으로"로 매칭됐는지 확인. "으로" 정상은 noun 이
          // 실제 명사+"으"가 아니라 re 가 "...으" 까지 noun 으로 먹은 경우.
          if (noun.endsWith('으')) continue; // 정상 "...으로"
          offenders.add('자기 $noun' '로 (받침 → "으로" 필요)');
        }
      }
      expect(offenders, isEmpty,
          reason: '도구격 조사 불일치:\n${offenders.join('\n')}');
    });

    test('의미·길이 회귀 가드 — 모든 문단 >= 80자 유지', () {
      // 받침-조사 1글자 치환은 길이를 거의 안 바꾸지만 ≥80자 invariant 확인.
      final shorts = paragraphs
          .where((p) =>
              RegExp('[가-힣]').hasMatch(p) && p.runes.length < 80)
          .toList();
      expect(shorts, isEmpty,
          reason: '<80자 문단 ${shorts.length}건:\n'
              '${shorts.take(5).join('\n')}');
    });
  });

  // R104 sprint 6c — "결" 일괄치환 오염 회귀 가드.
  //
  // 배경: 과거 라운드의 "결" → ['톤','쪽','느낌'] 류 일괄치환 cap 로직이
  // "결정"·"결제" 안의 "결"까지 깨뜨려 "톤정/쪽정/느낌정"(←결정),
  // "톤제/쪽제/느낌제"(←결제) 비문이 생겼다. 같은 cap 이 "톤" 받침 ㄴ
  // 명사 뒤 도구격을 "톤로"(←톤으로)로도 깨뜨렸다.
  //
  // codex 발견 verbatim: 본인잘 1 / 본인가 5 / 쪽제 12 / 느낌제 14 /
  //   톤제 18 / 톤정 19 — 추가로 톤로(15) 도 같은 family 로 검출.
  //
  // 이 가드는 오염 토큰이 0 임을 보장한다. "톤"·"쪽"·"느낌"이 정상 단어로
  // 쓰인 경우(밝은 톤, 한쪽, 느낌이 좋아요)는 패턴에 안 걸린다.
  group('R104 sprint 6c — "결" 치환 오염 토큰 0', () {
    test('결정/결제 합성어 오염 토큰 0 — 톤정·쪽정·느낌정·톤제·쪽제·느낌제', () {
      const dirty = <String>[
        '톤정', '쪽정', '느낌정', // ← 결정
        '톤제', '쪽제', '느낌제', // ← 결제
      ];
      final offenders = <String>[];
      for (final t in dirty) {
        if (raw.contains(t)) {
          offenders.add('"$t" 잔존 (count=${t.allMatches(raw).length})');
        }
      }
      expect(offenders, isEmpty,
          reason: '"결" 치환 오염 토큰:\n${offenders.join('\n')}');
    });

    test('도구격 오염 토큰 0 — "톤로" 는 "톤으로" 여야 함', () {
      // "톤" 은 받침 ㄴ → 도구격 조사는 "으로". "톤로" 는 깨진 형태.
      expect(raw.contains('톤로'), isFalse,
          reason: '"톤로" 잔존 — "톤으로" 이어야 함');
    });

    test('"본인" 조사 오염 토큰 0 — 본인가·본인잘', () {
      // "본인" 은 받침 ㄴ → 주격 조사는 "이". "본인가" 는 깨진 형태.
      expect(raw.contains('본인가'), isFalse,
          reason: '"본인가" 잔존 — "본인이" 이어야 함');
      // "본인잘" 은 "본인" 이 잘못 접두된 형태 — 정상은 그냥 "잘".
      expect(raw.contains('본인잘'), isFalse,
          reason: '"본인잘" 잔존 — 잘못 접두된 "본인" 제거 필요');
    });

    test('정상 단어 "톤/쪽/느낌" 은 보존된다 (오수정 가드)', () {
      // 정상 용법이 살아있어야 한다 — 전수 제거가 아님을 보장.
      expect(raw.contains('톤이에요'), isTrue);
      expect(raw.contains('톤으로'), isTrue);
      expect(raw.contains('느낌이'), isTrue);
      expect(raw.contains('쪽이'), isTrue);
    });
  });
}
