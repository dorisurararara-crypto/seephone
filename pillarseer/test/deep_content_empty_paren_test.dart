// Round 77 sprint 2 — deep_content_service 한국어 본문 빈 괄호 / 영문 leak 가드.
// `_fallbackDayMasterDeep` 의 ko 분기에서 `($name)` 제거 + `_sanitizeKo` 의
// 빈 괄호 제거가 회귀 시 fail.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/deep_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('60일주 sample × ko 본문 — 빈 괄호 " ( )" / "()" + 영문 element/animal 0건',
      () async {
    const englishPairs = [
      ('Wood Rat', '甲子'),
      ('Wood Rooster', '乙酉'),
      ('Water Rooster', '癸酉'),
      ('Metal Tiger', '庚寅'),
      ('Earth Tiger', '戊寅'),
      ('Wood Dragon', '甲辰'),
    ];
    const banned = [
      'Wood', 'Fire', 'Earth', 'Metal', 'Water',
      'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake',
      'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
    ];
    for (final pair in englishPairs) {
      final res = await DeepContentService.buildFor(
        day60ji: pair.$2,
        dayMaster: pair.$2[0],
        dayMasterName: pair.$1, // 영문 페어 — sanitize 대상
        currentYearGanji: '甲辰',
        userAge: 30,
        dominantElement: '水',
        deficitElement: '火',
        shortReadings: const {},
        allStems: const ['甲', '乙', '丙', '丁'],
      );
      final ko = res.ko;
      final joined = [
        ko.dayMasterDeep,
        ko.career,
        ko.wealth,
        ko.love,
        ko.health,
        ko.family,
        ko.fame,
      ].join('\n');
      expect(joined.contains('( )'), isFalse,
          reason: '${pair.$1} (${pair.$2}) 본문에 " ( )" 누출: $joined');
      expect(joined.contains('()'), isFalse,
          reason: '${pair.$1} (${pair.$2}) 본문에 "()" 누출');
      for (final b in banned) {
        // 단독 영문 단어 매칭 — `(?<!\w)$b(?!\w)`
        final re = RegExp(r'(?<!\w)' + b + r'(?!\w)');
        expect(re.hasMatch(joined), isFalse,
            reason: '$b 영문 단어 누출 — sanitize 미통과: $joined');
      }
    }
  });
}
