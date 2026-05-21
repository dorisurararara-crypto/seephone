// Pillar Seer — 일일 알림 문구 풀 (50+ 변주).
// 매일 8시 푸시가 같은 문구면 끄게 됨. 50개 풀에서 일자별 deterministic 선택.
// Round 76 sprint 6 — pickDeep 신규: 사용자 사주 + 오늘 일진 기반 calibrate.
// Round 77 sprint 7 — MZ 톤 50 ko/en 풀 추가 + tone selector.
//   기본 'adult' = 기존 50 ko/en. 'mz' = 신규 50 ko/en (단톡/야자/시험/최애/굿즈/짝꿍/엄마).
// Round 106 P2b — pickMystery 신규: 사주 미스터리형 알림 (design doc §6).
//   오늘 일진 글자를 신비하게 던지는 title + body 2줄(글자×차트 관계 + 행동).
//   topic-aware (P1 TopicSelector 가 고른 주제 반영). 7회 중 1회 기능 발견 훅.
//   기존 pickDeep / pickFor / adult·mz 풀 — 전부 보존 (회귀 0).
// Round 106 P2b-fix — 거짓말 0: body line1 은 그날 실제 계산된 일진 지지↔사용자
//   일지 관계(event.hapChungType — TodayEventService 산출)로만 선택된다. 실제 충이
//   있을 때만 "맞서는/부딪치는", 실제 합일 때만 "맞물리는/끌어당기는", 실제 형/파/해
//   일 때만 "살짝 엇갈리는", 셋 다 없으면 관계-중립("스쳐가는/곁을 지나가는") 표현만.
//   계산 로직 신규 작성 X — TodayEventService 가 이미 HapchungService 로 산출한 값 사용.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'today_event_service.dart';

/// 알림 톤 — 어른 (기본) / MZ 중고생.
enum NotificationTone { adult, mz }

/// R106 P2b-fix — 오늘 일진 지지 ↔ 사용자 일지 사이 실제 계산된 관계.
/// TodayEventService.hapChungType(합/충/형/파/해/없음) 을 미스터리 알림 카피
/// 선택용 4 분류로 접는다. 이 분류가 body line1 의 차트 관계 표현을 강제한다.
/// 충/합/형·파·해가 없으면 [neutral] — 어떤 날이든 사실인 관계-중립 표현만.
enum MysteryRelation {
  /// 실제 지지충 — "맞서는 / 부딪치는 / 맞부딪치는" 표현 허용.
  chung,

  /// 실제 지지합(또는 천간합) — "맞물리는 / 끌어당기는" 표현 허용.
  hap,

  /// 실제 형(刑)/파(破)/해(害) — "살짝 엇갈리는 / 한 끗 어긋나는" 표현 허용.
  friction,

  /// 충·합·형·파·해 모두 없음 — 관계-중립("스쳐가는 / 곁을 지나가는") 표현만.
  neutral,
}

extension MysteryRelationKey on MysteryRelation {
  /// 미스터리 풀 JSON 의 interactions 하위 key.
  String get key {
    switch (this) {
      case MysteryRelation.chung:
        return 'chung';
      case MysteryRelation.hap:
        return 'hap';
      case MysteryRelation.friction:
        return 'friction';
      case MysteryRelation.neutral:
        return 'neutral';
    }
  }

  /// TodayEventService.hapChungType('합'/'충'/'형'/'파'/'해'/'없음') →
  /// MysteryRelation. 미스/null/'없음' 은 모두 [neutral] (관계 단정 금지).
  static MysteryRelation fromHapChungType(String? hapChungType) {
    switch (hapChungType) {
      case '충':
        return MysteryRelation.chung;
      case '합':
        return MysteryRelation.hap;
      case '형':
      case '파':
      case '해':
        return MysteryRelation.friction;
      default:
        // '없음' 또는 미상 — 관계 단정 금지, 중립 표현만.
        return MysteryRelation.neutral;
    }
  }
}

/// R106 P2b — 사주 미스터리형 알림 카피 (design doc §6).
/// title = 오늘 일진 글자를 신비하게 던지는 호기심 훅.
/// body  = 2줄. line1 = 글자 × 사용자 차트 관계, line2 = 바로 할 행동 1개.
/// 단정 0 — 사용자 감정·사건을 단정하지 않고 글자×차트 "구조" 만 말한다.
class MysteryNotificationCopy {
  final String title;

  /// body line 1 — 오늘 글자가 사용자 일주/일지와 만나는 자리(실제 사주 관계).
  final String bodyLine1;

  /// body line 2 — 바로 할 행동 1개 (앱 열면 자세히).
  final String bodyLine2;

  /// 이 알림이 기능 발견 훅(7회 중 1회)인지.
  final bool isFeatureHook;

  /// 반영된 주제 id (R106 10 주제 string 중 하나). 신호 없으면 null.
  final String? topicId;

  const MysteryNotificationCopy({
    required this.title,
    required this.bodyLine1,
    required this.bodyLine2,
    required this.isFeatureHook,
    required this.topicId,
  });

  /// flutter_local_notifications body 슬롯용 — 2줄을 줄바꿈으로 합친다.
  String get body => '$bodyLine1\n$bodyLine2';
}

class NotificationPoolService {
  // R107 #3 — 기본 풀(사주 미상 last-resort fallback)도 v5 voice 로 정리.
  // 사건·결과 단정("you'll meet / the third opinion is right / money goes
  // well") 금지 → 조건형·경향형("if ~ / tends to / can / may"). 사주가 있는
  // 사용자는 항상 pickDeep/pickMystery(실제 일진 계산 기반)를 쓰므로 이 풀은
  // 사주 미상에서만 노출되지만, 그래도 거짓말 0 원칙을 동일하게 적용한다.
  static const _enPool = [
    'Today\'s flow tends to feel soft — speak gentle, move slow.',
    'Mid-morning tends to be your clearest window. Big asks before noon.',
    'If money comes up today, lean in and negotiate rather than avoid it.',
    'If you take a small risk, make it the one you wrote down — not a new one.',
    'Listen more than you speak. The room may be reading you.',
    'If you want help, just ask out loud — your peers tend to say yes.',
    'Before an impulse purchase, sleep on it — the deal can wait till tomorrow.',
    'If an old plan resurfaces, check whether it\'s finally ready to move.',
    'Rest early if you can. Your body tends to be the wallet today.',
    'If you say something honest, keep it simple — the honest version lands best.',
    'Finishing tends to pay more than starting today. Close one tab.',
    'Watch your phone tone. A call may carry better than a text today.',
    'If a family member calls, picking up may surface a useful clue.',
    'If a small gain in money shows up, try not to spend it the same day.',
    'Public energy can run loud — consider dropping one no-show plan.',
    'Today tends to reward precise over pretty.',
    'Pause before you reply. That thirty-second gap can be the win.',
    'Keep goals snack-sized. One step at a time.',
    'If you have a bold compliment, it tends to be well received. Try it.',
    'Consider skipping the side quest. Main story tends to fit today.',
    'Your strong element can fuel you — wearing its color may help.',
    'If a money idea has merit, a one-page memo can sharpen it.',
    'If a friend offers an introduction, replying within 24h tends to help.',
    'If you\'re right but quiet, voicing it before sunset may serve you.',
    'A small break in routine can actually serve work today.',
    'Evening tends to suit big decisions. Sleep on the rest.',
    'The love window may open late today — the patient hours can matter.',
    'If a long-running tension softens, try not to reopen it.',
    'One open loop can quietly drain the day. Handle it before you forget.',
    'Today\'s mood tends to prefer depth — say less, mean more.',
    'If a creative spark shows up, capture it before it fades.',
    'If a travel idea appeals, picking a date first tends to help.',
    'You may cross paths with someone worth remembering. Stay open.',
    'If you can, skip the 11AM thing and reserve that brain.',
    'If opinions differ, a third one is often worth a real listen today.',
    'Your love language today may be timing more than words.',
    'A career conversation can be closer than it feels.',
    'Quiet morning, bold afternoon, soft evening tends to fit today.',
    'You don\'t need to prove anything today. Just show up.',
    'If someone has been waiting on you, a short text can lighten things.',
    'A small detail can make a big difference. Re-read once.',
    'If a lucky direction matters to you, a walk that way can help.',
    'If you sense a clash with a senior, deferring it 24h tends to help.',
    'Money tends to follow one concrete thing — pick a specific target.',
    'A gentle no can protect your week.',
    'If an old friend resurfaces, decide what version of you they meet.',
    'Cold water and a bit of sun can recharge you today.',
    'Today tends to reward specifics. Numbers often beat a feeling.',
    'A surprise can come from below your radar. Stay open.',
    'Tonight\'s sleep can shape how clear tomorrow\'s answer feels.',
  ];

  static const _koPool = [
    '오늘의 흐름은 부드러운 편이에요. 말도 천천히, 행동도 천천히.',
    '오늘은 오전 중간이 가장 또렷한 타이밍이기 쉬워요. 큰 요청은 점심 전.',
    '돈 얘기가 나오면 피하지 말고 한 번 협상해 보면 좋아요.',
    '도전을 한다면 메모해 둔 그 하나로. 새로 떠오른 건 적어두고 미루세요.',
    '말하기보다 듣기. 오늘은 사람들이 당신을 읽고 있을 수 있어요.',
    '도움이 필요하면 그냥 말로 부탁해 보세요. 주변이 도와주려는 편이에요.',
    '충동 지출은 하루만 재워두세요. 그 거래는 내일도 있을 가능성이 커요.',
    '오래된 계획이 다시 떠오르면, 이제 움직일 때가 됐는지 한 번 점검해요.',
    '여유가 되면 일찍 자요. 오늘은 몸이 곧 지갑이 되기 쉬워요.',
    '솔직한 말을 한다면 짧게. 가식만 빼면 가장 잘 받아지는 편이에요.',
    '오늘은 시작보다 끝내기가 더 보상받기 쉬워요. 탭 하나만 닫으세요.',
    '문자보다 통화가 더 잘 닿을 수 있어요. 톤 한 번 신경 쓰기.',
    '가족이 전화하면 받아보세요. 쓸 만한 단서가 나올 수 있어요.',
    '작은 돈의 이득이 생기면 같은 날 쓰지 않는 게 좋아요.',
    '바깥 에너지가 시끄러울 수 있어요. 안 가도 되는 약속 하나 빼볼까요.',
    '오늘은 정확함이 예쁨을 이기기 쉬워요.',
    '답장 전 30초 쉬기. 그 침묵이 오늘의 승부수가 될 수 있어요.',
    '목표는 한 입 크기로만. 한 걸음씩.',
    '대범한 칭찬이 있다면 한 번 건네보세요. 잘 먹히는 편이에요.',
    '사이드 퀘스트는 잠시 미뤄도 좋아요. 오늘은 메인 스토리가 더 맞아요.',
    '강한 오행이 당신을 받쳐줄 수 있어요. 그 색의 옷·소품이 도움될 수 있어요.',
    '돈 아이디어가 떠오르면 한 페이지로 정리하면 더 또렷해져요.',
    '친구가 소개를 건네면 24시간 안에 답장하는 게 도움이 되기 쉬워요.',
    '맞는 말인데 조용히 있다면, 해 지기 전에 한 번 말해보면 좋아요.',
    '루틴을 잠시 깨는 게 오히려 일에 도움이 될 수 있어요.',
    '오늘 밤은 큰 결정에 어울리는 편이에요. 나머진 자고 결정해요.',
    '연애의 창은 늦게 열릴 수 있어요. 인내한 시간이 빛날 수 있어요.',
    '오래 끌던 긴장이 풀리면 다시 건드리지 않는 게 좋아요.',
    '밀린 한 가지가 조용히 에너지를 샐 수 있어요. 잊기 전에 처리해요.',
    '오늘 분위기는 깊이를 좋아하기 쉬워요. 적게 말하고 진심을 담아요.',
    '창작 영감이 떠오르면 사라지기 전에 기록해 두세요.',
    '여행 아이디어가 끌리면 목적지보다 날짜부터 잡으면 좋아요.',
    '기억할 만한 사람과 스칠 수 있어요. 마음을 열어두세요.',
    '11시 약속을 패스할 수 있다면, 그 시간만큼 뇌를 아껴두세요.',
    '의견이 엇갈리면, 오늘은 세 번째 의견도 한 번 진지하게 들어볼 만해요.',
    '오늘 연애 언어는 말보다 타이밍 쪽일 수 있어요.',
    '진로 대화가 생각보다 가까이 와 있을 수 있어요.',
    '조용한 오전, 대담한 오후, 부드러운 저녁이 오늘과 잘 맞아요.',
    '오늘은 증명하지 않아도 돼요. 그냥 나타나기만.',
    '기다리던 사람이 있다면 짧은 문자 한 통이 분위기를 풀 수 있어요.',
    '작은 디테일이 큰 차이를 만들 수 있어요. 한 번 더 읽기.',
    '행운의 방향이 마음에 걸리면 그쪽으로 산책해 보면 좋아요.',
    '윗사람과 의견이 부딪칠 것 같으면 24시간 미루는 게 도움이 되기 쉬워요.',
    '돈은 구체적인 한 가지를 따라오기 쉬워요. 막연한 여러 개보다 하나만.',
    '부드러운 거절이 이번 주를 지켜줄 수 있어요.',
    '옛 친구가 다시 나타나면, 어떤 버전의 당신을 만날지 정해두세요.',
    '차가운 물 + 햇빛이 오늘 몸을 다시 채워줄 수 있어요.',
    '오늘은 구체적인 게 보상받기 쉬워요. 숫자 > 분위기.',
    '레이더 밖에서 깜짝 등장이 있을 수 있어요. 열린 마음으로.',
    '오늘 밤 잠이 내일의 답을 얼마나 또렷하게 할지 좌우할 수 있어요.',
  ];

  // Round 77 sprint 7 — MZ 중고생 톤 50개 풀 (단톡/야자/시험/최애/굿즈/짝꿍/엄마/학원).
  // 50개 중 ≥35개에 MZ mandate 단어 1개 이상 포함.
  static const _koPoolMz = [
    '단톡에서 한 마디만 더 적게 하면 오늘 하루가 가벼워질 수 있어요.',
    '야자 끝나고 한 곡만 듣고 자기. 그게 내일 컨디션을 바꿀 수 있어요.',
    '오늘은 시험 점수보다 오답 한 문제 짚는 게 더 남기 쉬워요.',
    '최애 컴백 영상 하나는 오늘 봐도 OK. 두 개부터는 시간을 갉아먹기 쉬워요.',
    '굿즈 충동구매는 패스. 다음 주에도 그 굿즈는 있을 가능성이 커요.',
    '짝꿍한테 미안하다는 말이 있다면, 해 지기 전에.',
    '학원 가는 길에 햇빛 5분. 그게 오늘 뇌의 충전이 될 수 있어요.',
    '엄마 잔소리는 오늘 한 박자 늦게 받아도 돼요. 24시간 미루기.',
    '콘서트 티켓팅 알람 다시 확인. 캡쳐 떠놓기.',
    '단톡 답장 30초 쉬고. 그 침묵이 오늘 승부수가 될 수 있어요.',
    '오늘은 친구 한 명한테 먼저 물어봐주세요. 단답이어도 OK.',
    '야자 시작 전 물 한 잔. 졸음 한 줄이 빠질 수 있어요.',
    '시험 직전 새 인강은 패스. 오답노트 한 번 더가 더 맞기 쉬워요.',
    '최애 직캠 한 영상 보고 5분 스트레칭. 손이 가벼워질 수 있어요.',
    '굿즈 정리 10분만. 책상이 풀리면 머리도 풀리기 쉬워요.',
    '짝꿍이 오늘 좀 조용해도 캐묻지 마세요. 내일 먼저 말해줄 수 있어요.',
    '학원 끝나고 단톡 끄고 10분만 누워요. 회복에 도움이 될 수 있어요.',
    '엄마한테 잘 자고 한 마디. 분위기가 풀릴 수 있어요.',
    '시험 범위 한 페이지 더 욕심내지 말기. 한 단원 정확이 더 멀리 가기 쉬워요.',
    '오늘 단톡 음소거해도 OK. 진짜 친구는 음소거여도 챙겨주는 편이에요.',
    '학원 셔틀에서 음악 한 곡. 그 하루치 BGM이 오늘의 배경이 될 수 있어요.',
    '최애 신곡 첫 소절 5번 반복은 패스. 한 번 들으면 더 박히기 쉬워요.',
    '굿즈 사진 친구한테 자랑 한 번. 자랑할 줄 아는 게 덕질의 기본.',
    '짝꿍이 오늘 노트 빌려달라 하면 OK. 다음 주엔 네가 빌릴 수 있어요.',
    '엄마가 오늘 야식 사주면 한 마디 고맙다고. 그게 오늘의 동전이 될 수 있어요.',
    '단톡에 답장 안 한 사람 한 명. 오늘 안에 가볍게 한 줄.',
    '시험 망친 친구 위로는 길게 안 해도 돼요. "괜찮아" 한 줄이 가장 따뜻하기 쉬워요.',
    '야자 30분만 진지하게. 나머지는 흘려도 OK.',
    '최애 멤버 생일 D-Day. 메모에 한 줄 적어두기.',
    '굿즈 박스 정리하면서 사진 한 장. 인스타 스토리 1초.',
    '짝꿍이랑 한 끼는 같이 먹기. 매점 빵 한 개여도 OK.',
    '학원 빠지고 싶은 날엔, 한 강의만 듣고 가도 그게 너의 승리예요.',
    '엄마가 시험 점수 물어보면 정직하게 한 번. 그 뒤가 더 편해지기 쉬워요.',
    '오늘 단톡 안 읽음 3개. 자기 전에 한 줄씩만 답해도 충분해요.',
    '시험 직전 1시간은 새 문제 패스. 풀었던 문제 다시 보는 게 더 맞기 쉬워요.',
    '최애 컴백 무대 직캠 한 번. 그 다음은 공부.',
    '굿즈 알림 어플 알람 끄고 30분. 너의 시간이 돌아올 수 있어요.',
    '짝꿍한테 오늘 한 번만 더 웃어줘요. 분위기가 풀릴 수 있어요.',
    '엄마 잔소리 한 번은 그냥 듣기. 그 다음 한 번은 짧게 답해도 OK.',
    '학원 가방에서 안 쓰는 책 한 권 빼기. 어깨가 가벼워질 수 있어요.',
    '단톡에서 누군가 욕하면 너는 한 줄 침묵. 그 침묵이 너의 자리.',
    '야자 마지막 10분에 내일 시간표 한 번. 내일 아침이 가벼워질 수 있어요.',
    '오늘 최애 노래로 알람 바꿔보기. 내일 아침이 살아날 수 있어요.',
    '굿즈 친구한테 빌려달라면 OK. 그 친구도 네 굿즈 빌려줄 수 있어요.',
    '시험 끝나고 짝꿍한테 한 마디. "수고했어" 그 한 줄로 충분하기 쉬워요.',
    '학원 가는 길 6분 일찍. 그 6분이 오늘의 여유가 될 수 있어요.',
    '엄마한테 오늘 한 마디. "오늘 잘 잤어?" 그게 분위기를 풀 수 있어요.',
    '단톡에서 답장 늦은 친구한테 답 재촉은 패스. 내일 한 줄로 올 수 있어요.',
    '시험 직전 단톡 알람 끄기. 5분만이라도.',
    '최애 직캠 본 후 한 줄 메모. 그 곡이 너의 색으로 자리잡을 수 있어요.',
  ];

  static const _enPoolMz = [
    'One fewer reply in the groupchat can keep today lighter.',
    "After school night, one song then sleep. That can shift tomorrow's condition.",
    'A wrong answer reviewed tends to beat one more test point today.',
    "One fancam of your bias is fine. Two can start eating your time.",
    'Skip the impulse merch buy. That photocard will likely be there next week.',
    'If you owe your seatmate a sorry, say it before sunset.',
    'Five minutes of sunlight on the way to cram class can charge your brain.',
    "Taking mom's nagging one beat late today is OK. Defer 24h.",
    'Recheck your concert ticket alarm. Screenshot it.',
    "Wait 30s before replying in the groupchat. That silence can be today's win.",
    'Ask one friend something first today. A short reply is OK.',
    'Glass of water before school night session can mean one yawn fewer.',
    "Before the test, skip the new lecture. Another pass at your notes tends to win.",
    'One bias fancam then a five-minute stretch can leave your hands lighter.',
    'Ten minutes to tidy the merch shelf — desk loose, head tends to loosen too.',
    "If your seatmate is quiet today, don't push. They may speak first tomorrow.",
    'After cram class, mute the groupchat and lie down 10 min. It can help recovery.',
    "Tell mom good night. The mood can soften.",
    "Don't push for one extra chapter before the exam. One clean chapter tends to win.",
    'Muting the groupchat today is OK. Real friends still tend to find you.',
    'One song on the cram-class shuttle can be your background today.',
    "Don't loop the first line of the new bias track 5x. Once tends to land deeper.",
    'Brag your merch photo to one friend. Bragging is core to stanning.',
    "If seatmate borrows your notebook today, OK. You may borrow next week.",
    "If mom buys a late-night snack, say thanks once. That can be today's coin.",
    'One person you ghosted in the groupchat — a short line today.',
    "Don't long-comfort a friend who failed an exam. 'It's okay' tends to be warmest.",
    'Thirty minutes of focused school-night study. The rest can drift.',
    "Bias member's birthday today. Note one line.",
    'One snap of your merch box while tidying. One-second IG story.',
    'Share one meal with your seatmate. A bakery bun is fine.',
    'On days you want to skip cram class, attending one lecture is still your win.',
    'If mom asks about your test score, be honest once. After that tends to get lighter.',
    'Three unread in the groupchat. One line each before bed is enough.',
    'In the hour before the exam, skip new problems. Re-read what you solved.',
    'One bias comeback stage fancam. Then back to study.',
    "Mute merch-app alarms for 30 min — your time can return.",
    'Smile at your seatmate one more time today. The mood can soften.',
    "Listen to mom's nag once today. The next one you can reply short.",
    'Pull one unused book from your school bag. Shoulders can feel lighter.',
    "If someone trash-talks in the groupchat, your one line of silence is your seat.",
    "Last 10 min of school night, check tomorrow's schedule. Morning can feel lighter.",
    'Switch your alarm to a bias track. Tomorrow morning can feel more alive.',
    "If a friend asks to borrow your merch, OK. They may lend you theirs too.",
    'After the test, one line to your seatmate. "Good job" tends to carry it all.',
    'Six minutes early to cram class. That six can be your slack today.',
    "Ask mom one thing today: 'Did you sleep well?' The mood can open.",
    "Don't chase a slow groupchat replier. Their line may come tomorrow.",
    'Mute the groupchat right before the test. Even five minutes.',
    "Note one line after the bias fancam. That track can become your signature.",
  ];

  /// 사용자 사주 (dayPillar) + 날짜 seed → deterministic 풀 선택.
  /// 같은 사용자 같은 날 → 항상 같은 문구 (알림 일관성).
  /// Round 77 sprint 7 — tone 파라미터 추가 (기본 adult, mz 선택 시 MZ 풀).
  ///
  /// R107 #3 — 이 풀은 **사주 미상 last-resort fallback 전용**.
  /// 사용자 사주가 있으면 notification_service 가 항상 pickDeep(영문) /
  /// pickMystery(한국어) — 실제 일진 계산 기반 — 을 쓴다. 그래도 이 풀의
  /// 모든 문구는 v5 voice(조건형·경향형 — 사건/결과 단정 0)로 유지한다.
  static ({String en, String ko}) pickFor(
    DateTime date,
    String day60ji, {
    NotificationTone tone = NotificationTone.adult,
  }) {
    final seed = (date.year * 366 + date.month * 31 + date.day) ^
        day60ji.codeUnits.fold<int>(0, (a, b) => a + b);
    final koPool = tone == NotificationTone.mz ? _koPoolMz : _koPool;
    final enPool = tone == NotificationTone.mz ? _enPoolMz : _enPool;
    final idx = (seed % enPool.length).abs();
    return (en: enPool[idx], ko: koPool[idx]);
  }

  /// Round 76 sprint 6 — 사용자 사주 + 오늘 일진 기반 deep pick.
  /// today_event_service.build + composeNotificationLine 결과 (ko+en) 반환.
  /// saju null 시 호출 측에서 pickFor fallback.
  static ({String en, String ko}) pickDeep({
    required DateTime date,
    required SajuResult saju,
    required String todayPillar,
    required int todayScore,
  }) {
    final reading = TodayEventService.build(
      userDayStem: saju.dayPillar.chunGan,
      userDayBranch: saju.dayPillar.jiJi,
      userMonthBranch: saju.monthPillar.jiJi,
      todayPillar: todayPillar,
      todayScore: todayScore,
    );
    // Round 77 sprint 2 — ko 본문은 pool entry 우선, 미스 시 6분기 fallback.
    // ensurePoolLoaded() 가 부팅 시 이미 끝났다는 가정. 미적재여도 graceful.
    return (
      ko: TodayEventService.composeBodyKo(
        reading: reading,
        date: date,
        day60ji: saju.dayPillar.text,
      ),
      en: TodayEventService.composeNotificationLineEn(reading),
    );
  }

  // ─────────────── Round 106 P2b — 사주 미스터리형 알림 ───────────────
  //
  // design doc §6: 오늘 실제 일진(글자)을 신비하게 던져 "어떤 글자? 왜?" 호기심을
  // 만들고 tap 을 유도한다. title + body 2줄. body 1줄 = 글자×차트 관계,
  // body 2줄 = 행동 1개. P1 TopicSelector 가 고른 주제 반영 (topic-aware).
  // 7회 중 1회는 기능 발견 훅. 단정 0 — 글자가 차트와 만나는 "구조" 만 말한다.

  /// 지지 한자 → 한글 음. 한자를 본문에서 즉시 풀이하기 위한 map (R86 jargon 가드).
  static const Map<String, String> _branchKo = {
    '子': '자',
    '丑': '축',
    '寅': '인',
    '卯': '묘',
    '辰': '진',
    '巳': '사',
    '午': '오',
    '未': '미',
    '申': '신',
    '酉': '유',
    '戌': '술',
    '亥': '해',
  };

  /// design doc §6 — 기능 발견 훅 빈도. 7회 중 1회.
  static const int featureHookEvery = 7;

  static Map<String, dynamic>? _mysteryPoolCache;
  static bool _mysteryPoolLoaded = false;

  /// r106_mystery_notification_pool.json 1회 로드 + 캐시. 실패해도 silent.
  /// 호출 측은 부팅 시 1회 await — 이후 동기 pickMystery 호출 OK.
  /// 미적재여도 pickMystery 는 내장 fallback 으로 graceful (앱이 죽지 않는다).
  static Future<void> ensureMysteryPoolLoaded() async {
    if (_mysteryPoolLoaded) return;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/r106_mystery_notification_pool.json',
      );
      _mysteryPoolCache = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _mysteryPoolCache = <String, dynamic>{};
    }
    _mysteryPoolLoaded = true;
  }

  /// 테스트 전용 — 미스터리 풀 캐시 리셋.
  static void debugResetMysteryPool() {
    _mysteryPoolCache = null;
    _mysteryPoolLoaded = false;
  }

  /// 사주 미스터리형 알림 카피 생성 — design doc §6 + P2b-fix 거짓말 0.
  ///
  /// [date] 오늘 날짜, [todayPillar] 오늘 60갑자 (DailyService.calculate 산출),
  /// [day60ji] 사용자 일주 60갑자 (seed 분산용),
  /// [topicId] P1 TopicSelector 가 고른 오늘 주제 id (없으면 null — 총평형),
  /// [relation] 그날 실제 계산된 일진 지지↔사용자 일지 관계 (P2b-fix 핵심).
  ///   TodayEventService.hapChungType 을 [MysteryRelation] 으로 접은 값. body
  ///   line1 의 차트 관계 표현(맞서는/맞물리는/엇갈리는/스쳐가는)을 강제한다 —
  ///   실제 충일 때만 "부딪치는", 실제 합일 때만 "끌어당기는", 둘 다 없으면
  ///   관계-중립 표현만. null 이면 안전하게 [MysteryRelation.neutral] 처리.
  /// [dayOffset] scheduleDaily 의 i (0~29) — 기능 발견 훅 7회 1회 rotate anchor.
  ///
  /// pure — 같은 입력이면 항상 같은 출력 (deterministic). 캐시 미적재 시 fallback.
  static MysteryNotificationCopy pickMystery({
    required DateTime date,
    required String todayPillar,
    required String day60ji,
    String? topicId,
    MysteryRelation? relation,
    int dayOffset = 0,
  }) {
    // 오늘 일진 지지 글자 — 이게 알림이 신비하게 던지는 "글자".
    final char = todayPillar.length >= 2 ? todayPillar[1] : '子';
    final charKo = _branchKo[char] ?? char;

    // P2b-fix — relation 미공급 시 관계 단정 금지 → 중립.
    final rel = relation ?? MysteryRelation.neutral;

    // deterministic seed — 날짜 + 사용자 일주 + 오늘 일진.
    final seed = (date.year * 366 + date.month * 31 + date.day) ^
        day60ji.codeUnits.fold<int>(0, (a, b) => a + b) ^
        todayPillar.codeUnits.fold<int>(0, (a, b) => a + b);

    // 7회 중 1회 기능 발견 훅 — dayOffset 기준 deterministic rotate.
    final isFeatureHook = featureHookEvery > 0 &&
        (dayOffset % featureHookEvery == (seed.abs() % featureHookEvery));

    String sub(String tpl) =>
        tpl.replaceAll('{char}', char).replaceAll('{charKo}', charKo);

    if (isFeatureHook) {
      final hook = _pickFeatureHook(seed);
      return MysteryNotificationCopy(
        title: sub(hook.$1),
        bodyLine1: sub(hook.$2),
        bodyLine2: sub(hook.$3),
        isFeatureHook: true,
        topicId: topicId,
      );
    }

    // 주제별 카피 노드 — topicId 가 있으면 그 주제, 없으면 no_topic 총평형.
    final node = _mysteryTopicNode(topicId);
    final titles = _strList(node['titles']);
    // P2b-fix — interactions 는 관계타입별(chung/hap/friction/neutral) 맵.
    // 실제 relation 의 key 배열만 고른다 — 충 없는 날 "부딪치는" 이 안 나가게 강제.
    final interactions = _interactionsForRelation(node['interactions'], rel);
    final actions = _strList(node['actions']);

    final fb = _mysteryFallback(rel, char, charKo);
    final title = sub(_pickFrom(titles, seed, 1, fb.$1));
    final line1 = sub(_pickFrom(interactions, seed, 2, fb.$2));
    final line2 = sub(_pickFrom(actions, seed, 3, fb.$3));

    return MysteryNotificationCopy(
      title: title,
      bodyLine1: line1,
      bodyLine2: line2,
      isFeatureHook: false,
      topicId: topicId,
    );
  }

  /// P2b-fix — interactions 노드(관계타입별 맵)에서 실제 [relation] key 배열만 추출.
  /// 신버전 스키마 = `{chung:[],hap:[],friction:[],neutral:[]}`. 해당 key 가 비면
  /// neutral 로 안전 강등 (관계 단정 금지 — 충 카피가 충 아닌 날 누출되지 않게).
  static List<String> _interactionsForRelation(
    dynamic raw,
    MysteryRelation relation,
  ) {
    if (raw is! Map) return const [];
    final byKey = raw[relation.key];
    final list = _strList(byKey);
    if (list.isNotEmpty) return list;
    // 요청 관계 카피가 비어 있으면 — 관계 단정을 피해 neutral 로 폴백.
    if (relation != MysteryRelation.neutral) {
      return _strList(raw[MysteryRelation.neutral.key]);
    }
    return const [];
  }

  /// topicId → 미스터리 풀의 주제 노드. 미스/null 시 no_topic 노드.
  static Map<String, dynamic> _mysteryTopicNode(String? topicId) {
    final root = _mysteryPoolCache;
    if (root == null) return const {};
    if (topicId != null) {
      final topics = root['topics'];
      if (topics is Map) {
        final t = topics[topicId];
        if (t is Map) return t.cast<String, dynamic>();
      }
    }
    final noTopic = root['no_topic'];
    return noTopic is Map ? noTopic.cast<String, dynamic>() : const {};
  }

  /// 기능 발견 훅 1개 deterministic pick → (title, interaction, action).
  static (String, String, String) _pickFeatureHook(int seed) {
    final root = _mysteryPoolCache;
    final hooks = root == null ? null : root['feature_hooks'];
    final items = hooks is Map ? hooks['items'] : null;
    if (items is List && items.isNotEmpty) {
      final idx = (seed.abs() ~/ 11) % items.length;
      final item = items[idx];
      if (item is Map) {
        final t = item['title'];
        final i = item['interaction'];
        final a = item['action'];
        if (t is String && i is String && a is String) return (t, i, a);
      }
    }
    // 내장 fallback — 풀 미적재여도 기능 훅이 죽지 않게.
    return (
      '오늘 글자가 당신 사주에 닿은 이유, 안에서 풀어놨어요',
      "오늘 '{char}'({charKo}) 글자가 당신 사주와 만나는 자리를 그려놨어요.",
      '자세한 풀이는 오늘의 사주 안에 있어요.',
    );
  }

  /// dynamic 을 `List<String>` 로 변환 (null·타입 미스 graceful).
  static List<String> _strList(dynamic raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

  /// list 에서 seed + salt deterministic pick. 비면 fallback.
  static String _pickFrom(List<String> list, int seed, int salt, String fb) {
    if (list.isEmpty) return fb;
    final idx = ((seed.abs() ~/ 7 + salt * 31)) % list.length;
    return list[idx];
  }

  /// 풀 미적재 시 내장 fallback (title, line1, line2) — design doc §6 톤 보존.
  /// P2b-fix — line1 은 실제 [relation] 에 맞는 표현만. 충 없는 날 "부딪치는" 금지.
  static (String, String, String) _mysteryFallback(
    MysteryRelation relation,
    String char,
    String charKo,
  ) {
    const title = '오늘 들어온 글자가 당신 사주의 한 자리에 닿았어요';
    const action = '넘기는 법은 안에 적어놨어요.';
    String line1;
    switch (relation) {
      case MysteryRelation.chung:
        line1 = "'{char}'({charKo})라는 글자인데, "
            '당신 일지(태어난 날의 지지)와 맞서는 자리예요.';
        break;
      case MysteryRelation.hap:
        line1 = "'{char}'({charKo})라는 글자인데, "
            '당신 일지(태어난 날의 지지)와 맞물리는 자리예요.';
        break;
      case MysteryRelation.friction:
        line1 = "'{char}'({charKo})라는 글자인데, "
            '당신 일지(태어난 날의 지지)와 살짝 엇갈리는 자리예요.';
        break;
      case MysteryRelation.neutral:
        line1 = "'{char}'({charKo})라는 글자인데, "
            '당신 일주 곁을 스쳐가는 자리예요.';
        break;
    }
    return (title, line1, action);
  }
}
