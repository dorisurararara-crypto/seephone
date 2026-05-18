import 'package:test/test.dart';
import 'package:pillarseer/services/natural_prose_joiner.dart';

void main() {
  group('NaturalProseJoiner', () {
    test('injects deterministic connectors into Korean sentence atoms', () {
      const atoms = [
        '오늘은 본인 스타일대로 가는 쪽이 정답이에요.',
        '사람들이 본인을 바로 기억해요.',
        '그게 오늘 본인의 장점이에요.',
        '배움이 잘 자리잡는 흐름이에요.',
        '오늘 충분한 수면 한 시간이 다음날 컨디션을 두 배로 만들어줘요.',
      ];

      final a = NaturalProseJoiner.join(atoms);
      final b = NaturalProseJoiner.join(atoms);

      expect(a, equals(b), reason: '같은 입력은 같은 출력이어야 함');
      expect(a.contains('\n'), isFalse);
      expect(a, contains('그래서'));
      expect(a, contains('그 흐름 위에'));
      expect(a, contains('덕분에'));
      expect(a, contains('한편'));
      expect(a, isNot(contains('정답이에요. 사람들이')));
    });

    test('keeps long generated paragraph as a coherent single paragraph', () {
      final body = NaturalProseJoiner.join([
        '오늘은 평소보다 말과 행동이 밖으로 잘 드러나는 날이에요.',
        '오늘은 친구나 동료처럼 비슷한 자리 사람이 가까워지는 신호가 있어요.',
        '오늘은 평소 습관과 말버릇이 더 선명하게 드러나요.',
        '평소 망설이던 일도 오늘은 한 번 꺼내볼 만해요.',
        '평소 강한 쇠 성향이 오늘 더 선명해져요.',
        '미뤄둔 일 하나는 오늘 시작해도 좋아요.',
      ]);

      final connectors = RegExp(
        r'(그래서|그 흐름 위에|덕분에|한편|다만|동시에|거기에|그 분위기 그대로|한 발 더 가면|그러니까)',
      ).allMatches(body).length;
      final sentences = RegExp(r'[.!?。]').allMatches(body).length;

      expect(sentences, greaterThanOrEqualTo(5));
      expect(connectors, greaterThanOrEqualTo(2));
      expect(body, isNot(contains('날이에요. 오늘은')));
    });
  });
}
