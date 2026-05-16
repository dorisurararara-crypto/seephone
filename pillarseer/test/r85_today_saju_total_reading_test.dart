import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/today_deep_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R85 today saju total reading', () {
    test('TodayDeepService 한국어 출력이 평생사주식 오늘 총평으로 확장된다', () {
      final reading = TodayDeepService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        userDominantEl: '金',
        userDeficitEl: '水',
        todayPillar: '丙戌',
        todayScore: 72,
      );

      expect(reading.headlineKo.startsWith('오늘 사주 총평'), isTrue);
      expect(reading.headlineKo.contains('분위기의 하루'), isFalse);
      expect(reading.headlineEn.startsWith("Today's Saju Summary"), isTrue);
      expect(reading.headlineEn.contains("Today's mood"), isFalse);

      final sentenceCount = RegExp(r'[.!?。]').allMatches(reading.bodyKo).length;
      expect(
        sentenceCount,
        greaterThanOrEqualTo(5),
        reason: '오늘사주 본문은 짧은 일진 메모가 아니라 5문장 이상 총평이어야 함',
      );

      const rawGanji = '甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥';
      for (final ch in rawGanji.split('')) {
        expect(
          reading.bodyKo.contains(ch),
          isFalse,
          reason: '오늘 사주 본문에 한자 jargon "$ch" 노출',
        );
      }

      expect(reading.bodyEn.contains('Your chart opens outward'), isFalse);
      expect(reading.bodyEn.contains('Ride this energy'), isFalse);
      expect(reading.bodyEn.contains('Consolidating where you stand'), isFalse);
      final enSentenceCount = RegExp(
        r'[.!?]',
      ).allMatches(reading.bodyEn).length;
      expect(
        enSentenceCount,
        greaterThanOrEqualTo(5),
        reason: 'English today-saju body should also read as a full summary',
      );
    });

    test('home_screen 오늘사주 섹션 라벨이 한영 모두 새 톤을 사용한다', () {
      final src = File('lib/screens/home_screen.dart').readAsStringSync();

      expect(src.contains('오늘 사주 총평'), isTrue);
      expect(src.contains('오늘 살릴 부분'), isTrue);
      expect(src.contains("Today's Saju Summary"), isTrue);
      expect(src.contains('Use this today'), isTrue);
      expect(src.contains('오늘 내 사주 풀이'), isFalse);
      expect(src.contains("useKo ? '오늘 추천' : 'Try today'"), isFalse);
      expect(src.contains("Today's deep reading"), isFalse);
      expect(src.contains('Try today'), isFalse);
      expect(src.contains('_FirstFoldGreeting'), isFalse);
      expect(src.contains('_PillarOfTheDay'), isFalse);
    });

    test('today_screen 은 오늘 사주 총평을 사건 카드보다 먼저 보여준다', () {
      final src = File('lib/screens/today_screen.dart').readAsStringSync();

      final childrenIndex = src.indexOf('children: [');
      final summaryIndex = src.indexOf(
        'TodayDeepReadingSection',
        childrenIndex,
      );
      final eventIndex = src.indexOf('TodayEventDetailSection', childrenIndex);
      expect(summaryIndex, greaterThanOrEqualTo(0));
      expect(eventIndex, greaterThanOrEqualTo(0));
      expect(
        summaryIndex,
        lessThan(eventIndex),
        reason: '오늘 탭 첫 화면은 사건 카드보다 오늘 사주 총평이 먼저 나와야 함',
      );
    });
  });
}
