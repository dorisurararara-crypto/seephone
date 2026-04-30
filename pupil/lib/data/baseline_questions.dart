import 'dart:math';
import 'dart:ui';

/// baseline 측정 시 친구에게 던질 "진실로 쉽게 답할 수 있는" 질문 풀.
///
/// - 누구나 거짓말할 이유가 없는 사실 질문
/// - 답변 길이가 1-3초 정도 (4초 baseline 측정 윈도우와 맞음)
/// - 매번 같은 질문이면 사용자가 외워서 분산 ↑ → 랜덤 풀 20개로 선택
class BaselineQuestions {
  static const Map<String, List<String>> _byLocale = {
    'ko': [
      '이름을 말해보세요',
      '나이를 말해보세요',
      '오늘 무슨 요일이에요?',
      '어디 살아요?',
      '좋아하는 색은?',
      '좋아하는 음식은?',
      '형제가 몇 명?',
      '어디서 일하거나 공부해요?',
      '오늘 점심 뭐 먹었어요?',
      '좋아하는 계절은?',
      '키가 몇이에요?',
      '어디서 태어났어요?',
      '좋아하는 영화 하나만?',
      '쓰는 휴대폰 회사는?',
      '강아지파, 고양이파?',
      '운전면허 있어요?',
      '어제 몇 시에 잤어요?',
      '제일 친한 친구 이름?',
      '좋아하는 음악 장르는?',
      '오늘 아침 뭐 먹었어요?',
    ],
    'en': [
      "What's your name?",
      "How old are you?",
      "What day is it today?",
      "What city do you live in?",
      "What's your favorite color?",
      "What's your favorite food?",
      "How many siblings do you have?",
      "Where do you work or study?",
      "What did you eat for lunch?",
      "What's your favorite season?",
      "How tall are you?",
      "Where were you born?",
      "Name a movie you like.",
      "What phone brand do you use?",
      "Cats or dogs?",
      "Do you have a driver's license?",
      "What time did you sleep last night?",
      "Best friend's name?",
      "Favorite music genre?",
      "What did you have for breakfast?",
    ],
  };

  static String pick(Locale locale) {
    final list = _byLocale[locale.languageCode] ?? _byLocale['en']!;
    return list[Random().nextInt(list.length)];
  }
}
