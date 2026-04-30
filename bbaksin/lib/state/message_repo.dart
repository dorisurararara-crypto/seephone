import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Message {
  final String text;
  final String category;
  const Message(this.text, this.category);
}

class MessageRepository {
  MessageRepository(this._messages);

  final List<Message> _messages;
  final _rand = Random();

  // === 강한 카테고리 시그널 (weight 3) ===
  // 명확하게 주제를 가리키는 키워드. 이게 hit 하면 decision 키워드 무시.
  static const _strongKeywords = <String, String>{
    // LOVE
    '연애': 'love', '카톡': 'love', '디엠': 'love', 'dm': 'love',
    '전남친': 'love', '전여친': 'love',
    '짝사랑': 'love', '썸': 'love', '결혼': 'love', '이혼': 'love',
    '데이트': 'love', '자니': 'love', '이별': 'love', '헤어졌': 'love',
    '헤어지': 'love', '사귀': 'love', '좋아한': 'love', '좋아해': 'love',
    '사랑': 'love', '고백': 'love', '답장': 'love', '그놈': 'love',
    '그년': 'love', '매달리': 'love', '인스타': 'love',
    '소개팅': 'love', '연인': 'love', '남친': 'love', '여친': 'love',
    '남자친구': 'love', '여자친구': 'love', '커플': 'love',

    // MONEY
    '돈': 'money', '통장': 'money', '월급': 'money', '카드값': 'money',
    '명품': 'money', '저축': 'money', '적금': 'money', '예금': 'money',
    '빚': 'money', '대출': 'money', '주식': 'money', '코인': 'money',
    '비트코인': 'money', '부자': 'money', '가난': 'money', '월세': 'money',
    '전세': 'money', '아파트': 'money', '부동산': 'money', '투자': 'money',
    '할부': 'money', '돈벌': 'money', '돈모으': 'money',
    '재테크': 'money', '연봉': 'money', '보너스': 'money', '세금': 'money',
    '쇼핑': 'money', '명품백': 'money', '신용카드': 'money',

    // DIET — 다이어트·식사·음식 결정
    '다이어트': 'diet', '살빼': 'diet', '살찌': 'diet', '체중': 'diet',
    '몸무게': 'diet', '운동': 'diet', '헬스': 'diet', '폭식': 'diet',
    '야식': 'diet', '치킨': 'diet', '피자': 'diet', '햄버거': 'diet',
    '맥주': 'diet', '소주': 'diet', '안주': 'diet',
    '배달': 'diet', '디저트': 'diet', '케이크': 'diet', '아이스크림': 'diet',
    '칼로리': 'diet', '과자': 'diet', '콜라': 'diet',
    '간식': 'diet', '뱃살': 'diet', '복근': 'diet',
    '식단': 'diet', '단식': 'diet', '러닝': 'diet',
    '필라테스': 'diet', '요가': 'diet',
    // 식사 결정 (뭐 먹을까 류) — diet 카테고리로
    '점심': 'diet', '저녁': 'diet', '아침': 'diet', '식사': 'diet',
    '메뉴': 'diet', '뭐먹': 'diet', '뭐 먹': 'diet', '먹을까': 'diet',
    '굶을까': 'diet', '시켜먹': 'diet', '시켜 먹': 'diet',
    '음식': 'diet', '맛집': 'diet',

    // WORK
    '회사': 'work', '상사': 'work', '사장': 'work', '학교': 'work',
    '시험': 'work', '발표': 'work', '진로': 'work', '사직': 'work',
    '퇴사': 'work', '야근': 'work', '면접': 'work', '합격': 'work',
    '취직': 'work', '취업': 'work', '이직': 'work', '동료': 'work',
    '보고서': 'work', '출근': 'work', '퇴근': 'work', '워라밸': 'work',
    '업무': 'work', '프로젝트': 'work', '회의': 'work',
    '월요일': 'work', '월욜': 'work', '학원': 'work', '대학': 'work',
    '자격증': 'work', '공부': 'work', '논문': 'work',
    '졸업': 'work', '인턴': 'work', '신입사원': 'work',
    '교수': 'work', '담임': 'work',
  };

  // === Decision 보조 키워드 (weight 1) ===
  // strong keyword 가 0개일 때만 decision 카테고리 매칭에 활용.
  // (식사 관련 키워드는 strong → diet 로 옮김)
  static const _decisionHelperKeywords = <String>[
    '뭐로', '결정', '골라', '고를', '선택', '망설',
    '할까', '말까', '살까', '갈까',
    '어디', '어느', '두 가지', '두가지',
  ];

  Message pickRandom() => _messages[_rand.nextInt(_messages.length)];

  Message pickFor(String question, {bool isRepeat = false}) {
    if (isRepeat) {
      final repeats = _messages.where((m) => m.category == 'repeat').toList();
      if (repeats.isNotEmpty) {
        return repeats[_rand.nextInt(repeats.length)];
      }
    }

    final lower = question.toLowerCase();

    // Phase 1: strong keyword 점수 (weight 3)
    final scores = <String, int>{};
    for (final entry in _strongKeywords.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        scores[entry.value] = (scores[entry.value] ?? 0) + 3;
      }
    }

    // Phase 2: strong 매칭 0 → decision helper 키워드 검사
    if (scores.isEmpty) {
      var decisionHits = 0;
      for (final kw in _decisionHelperKeywords) {
        if (lower.contains(kw)) decisionHits++;
      }
      if (decisionHits > 0) {
        scores['decision'] = decisionHits;
      }
    }

    String chosenCategory = 'general';
    if (scores.isNotEmpty) {
      final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
      final topCategories = scores.entries
          .where((e) => e.value == maxScore)
          .map((e) => e.key)
          .toList();
      // 단독 1위면 그 카테고리, tie 면 general (애매한 답 방지)
      if (topCategories.length == 1) {
        chosenCategory = topCategories.first;
      }
    }

    final filtered =
        _messages.where((m) => m.category == chosenCategory).toList();
    if (filtered.isEmpty) {
      final general =
          _messages.where((m) => m.category == 'general').toList();
      if (general.isNotEmpty) return general[_rand.nextInt(general.length)];
      return pickRandom();
    }
    return filtered[_rand.nextInt(filtered.length)];
  }
}

final messageRepoProvider = FutureProvider<MessageRepository>((ref) async {
  final raw = await rootBundle.loadString('assets/data/messages.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final list = (json['messages'] as List)
      .map((e) => Message(e['text'] as String, e['category'] as String))
      .toList();
  return MessageRepository(list);
});
