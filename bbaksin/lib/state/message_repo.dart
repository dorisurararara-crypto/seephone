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

  // 카테고리 매칭용 키워드 → 카테고리 ID.
  // 키워드 hit하면 그 카테고리 안에서만 픽. 안 맞으면 전체에서 픽.
  static const _keywords = <String, String>{
    '연애': 'love', '카톡': 'love', '전남친': 'love', '전여친': 'love',
    '짝사랑': 'love', '썸': 'love', '결혼': 'love', '데이트': 'love', '자니': 'love',
    '돈': 'money', '통장': 'money', '월급': 'money', '카드': 'money',
    '명품': 'money', '저축': 'money', '적금': 'money', '치킨': 'money',
    '다이어트': 'diet', '살': 'diet', '운동': 'diet', '헬스': 'diet',
    '폭식': 'diet', '야식': 'diet', '배달': 'diet',
    '점심': 'decision', '메뉴': 'decision', '고민': 'decision', '결정': 'decision',
    '회사': 'work', '상사': 'work', '학교': 'work', '시험': 'work',
    '발표': 'work', '진로': 'work', '사직': 'work', '야근': 'work',
  };

  Message pickRandom() => _messages[_rand.nextInt(_messages.length)];

  Message pickFor(String question, {bool isRepeat = false}) {
    if (isRepeat) {
      final repeats = _messages.where((m) => m.category == 'repeat').toList();
      if (repeats.isNotEmpty) {
        return repeats[_rand.nextInt(repeats.length)];
      }
    }
    String? matchedCategory;
    for (final entry in _keywords.entries) {
      if (question.contains(entry.key)) {
        matchedCategory = entry.value;
        break;
      }
    }
    if (matchedCategory == null) return pickRandom();
    final filtered =
        _messages.where((m) => m.category == matchedCategory).toList();
    if (filtered.isEmpty) return pickRandom();
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
