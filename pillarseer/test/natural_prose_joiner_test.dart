// R96 hotfix — natural prose joiner 는 mechanical hygiene 만 한다.
// (trim / 중복 공백 정리 / 마침표 보정 / 인접 중복 dedup)
//
// 1.0.0+55 실기기 사용자 verbatim:
//   "말 자체가 어색한데 본인스타일대로 가서 사람들이 나를 기억한다?
//    그 흐름위에 그게 장점이라고??"
//
// → connector 강제 inject ("그래서/그 흐름 위에/덕분에/한편/다만/동시에/
//    거기에/그 분위기 그대로/한 발 더 가면/그러니까") 금지.
// → 종결 변형 (...에요. → ...죠) 금지.
// → 단조해도 의미 무결한 본문이 fake causation 보다 낫다.

import 'package:test/test.dart';
import 'package:pillarseer/services/natural_prose_joiner.dart';

void main() {
  group('NaturalProseJoiner — mechanical hygiene only', () {
    // 사용자가 직접 캡처해 보고한 실기기 atom 5종.
    const atoms = [
      '오늘은 본인 스타일대로 가는 쪽이 정답이에요.',
      '사람들이 본인을 바로 기억해요.',
      '그게 오늘 본인의 장점이에요.',
      '배움이 잘 자리잡는 흐름이에요.',
      '오늘 충분한 수면 한 시간이 다음날 컨디션을 두 배로 만들어줘요.',
    ];

    // R96 회귀 가드 — fake causation 단어 blacklist.
    // 위 atom 5개를 join 했을 때, 입력에 없던 connector 가 들어가면 안 됨.
    const bannedConnectors = [
      '그래서',
      '그 흐름 위에',
      '덕분에',
      '한편',
      '다만',
      '동시에',
      '거기에',
      '그 분위기 그대로',
      '한 발 더 가면',
      '그러니까',
    ];

    test('determinism — 같은 입력은 같은 출력', () {
      final a = NaturalProseJoiner.join(atoms);
      final b = NaturalProseJoiner.join(atoms);
      expect(a, equals(b));
    });

    test('R96 — 무관 sentence 5개 join 시 fake causation connector 0개', () {
      final body = NaturalProseJoiner.join(atoms);
      for (final c in bannedConnectors) {
        expect(
          body.contains(c),
          isFalse,
          reason:
              'R96 fake causation guard — atom 입력에 없던 connector "$c" 가 자동 삽입되면 안 됨',
        );
      }
      // 줄바꿈 정리 OK.
      expect(body.contains('\n'), isFalse);
      // 인접 atom 사이에 마침표는 살아있어야 함.
      expect(body, contains('정답이에요. 사람들이'));
    });

    test('R96 — 입력에 connector 가 이미 있으면 그대로 보존', () {
      // upstream service 가 의도적으로 connector 를 포함시킨 경우는 통과.
      const intentional = [
        '오늘은 차분히 다지는 날이에요.',
        '그래서 무리한 약속은 다음 주로 넘기는 게 좋아요.',
      ];
      final body = NaturalProseJoiner.join(intentional);
      expect(body, contains('그래서'));
    });

    test('R96 — 종결 변형 (...에요. → ...죠 / 좋아요. → 좋죠) 자동 적용 0', () {
      const flat = [
        '오늘은 평소보다 말과 행동이 밖으로 잘 드러나는 날이에요.',
        '미뤄둔 일 하나는 오늘 시작해도 좋아요.',
        '평소 망설이던 일도 오늘은 한 번 꺼내볼 만해요.',
        '새 판을 벌리기보다 단단하게 다지는 편이 좋아요.',
        '오늘은 한 발 빠르게 가는 쪽이 돼요.',
      ];
      final body = NaturalProseJoiner.join(flat);
      // 입력 종결을 그대로 보존 — 자동 mutation 으로 ...죠. ...네요. ...될 거예요.
      // 들어가면 R96 회귀.
      expect(body.contains('흐름이죠.'), isFalse);
      expect(body.contains('날이네요.'), isFalse);
      expect(body.contains('좋죠.'), isFalse);
      expect(body.contains('될 거예요.'), isFalse);
      // 입력 종결은 그대로.
      expect(body.contains('날이에요.'), isTrue);
      expect(body.contains('좋아요.'), isTrue);
    });

    test('polish — 단일 paragraph 정리 (공백/줄바꿈 → 단일 공백, 마침표 보정)', () {
      const raw = '오늘은 차분히 다지는 날이에요.\n  큰 결정은 미루세요\n\n확인이 필요한 일 하나만 끝내요';
      final body = NaturalProseJoiner.polish(raw);
      expect(body.contains('\n'), isFalse);
      expect(body.contains('  '), isFalse);
      // 마침표 보정 적용.
      expect(body.endsWith('.'), isTrue);
      // 의미는 그대로.
      expect(body, contains('차분히 다지는'));
      expect(body, contains('큰 결정은 미루세요'));
      expect(body, contains('확인이 필요한 일 하나만'));
    });

    test('append — base + extras 자연 join, connector 자동 inject 0', () {
      final body = NaturalProseJoiner.append(
        '오늘은 본인 스타일대로 가는 쪽이 정답이에요.',
        const ['배움이 잘 자리잡는 흐름이에요.', '충분한 수면 한 시간이 컨디션을 챙겨줘요.'],
      );
      for (final c in bannedConnectors) {
        expect(body.contains(c), isFalse, reason: 'R96 append guard — "$c"');
      }
    });

    test('인접 동일 sentence dedup — upstream 중복 atom 방어', () {
      const dup = [
        '오늘은 차분히 다지는 날이에요.',
        '오늘은 차분히 다지는 날이에요.',
        '확인이 필요한 일 하나만 끝내세요.',
      ];
      final body = NaturalProseJoiner.join(dup);
      // 같은 문장이 두 번 연속 나오면 1번으로 줄어야 함.
      final first = body.indexOf('차분히 다지는');
      final second = body.indexOf('차분히 다지는', first + 1);
      expect(second, equals(-1));
    });
  });
}
