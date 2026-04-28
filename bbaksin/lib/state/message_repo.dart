import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 톤 검증 후 assets/data/messages.json 로드로 전환.
// 현재는 인라인 stub (content-draft/messages_batch1.md 에서 가져온 12개 샘플).

class Message {
  final String text;
  final String category;
  const Message(this.text, this.category);
}

const _stubMessages = <Message>[
  Message('야 이놈아, 자니 치는 손가락부터 부러뜨려라.', 'love'),
  Message('어허, 또 그놈이냐? 신령님께서 노하셨다.', 'love'),
  Message('야 이놈아, 통장이 텅장이다. 치킨은 무슨 치킨.', 'money'),
  Message('어허, 또 카드 긁었느냐? 다음 달 너의 곡소리가 들리는구나.', 'money'),
  Message('야 이놈아, 뱃살이 곧 산이로다. 샐러드나 씹어라.', 'diet'),
  Message('자고로 다이어트는 내일부터인 놈은 평생 살이 빠지지 않느니라.', 'diet'),
  Message('야 이놈아, 점심 메뉴 30분째 고르느냐? 굶어라.', 'decision'),
  Message('자고로 0과 1 사이에서 결정 못 하는 놈은 0이다.', 'decision'),
  Message('야 이놈아, 야근 또 하느냐? 너의 시간은 부적도 못 살린다.', 'work'),
  Message('어허, 또 회의에서 침묵했느냐? 너의 의견은 무덤 속이로다.', 'work'),
  Message('야 이놈아, 또 폰 보느냐? 네 인생이나 켜라.', 'general'),
  Message('자고로 게으른 놈은 부적도 못 살린다.', 'general'),
];

class MessageRepository {
  final _rand = Random();

  Message pickRandom() {
    return _stubMessages[_rand.nextInt(_stubMessages.length)];
  }

  Message pickFor(String question) {
    // TODO: 질문 키워드 기반 카테고리 매칭 (전남친·돈 등 키워드 → 해당 카테고리에서 픽)
    return pickRandom();
  }
}

final messageRepoProvider = Provider<MessageRepository>((ref) => MessageRepository());
