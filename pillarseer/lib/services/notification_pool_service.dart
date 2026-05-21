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
  static const _enPool = [
    'Today\'s flow leans soft — speak gentle, move slow.',
    'Mid-morning is your green light. Big asks before noon.',
    'Money chat goes well today. Negotiate, don\'t avoid.',
    'A small risk pays off — but only the one you wrote down.',
    'Listen more than you speak. The room is reading you.',
    'Your peers want to help. Just ask out loud.',
    'Avoid impulse purchases — the deal will still be there tomorrow.',
    'Old plans return. One of them is finally ready.',
    'Sleep early. Your body is the wallet today.',
    'A confession lands well — but only the honest one.',
    'Today rewards finishing, not starting. Close one tab.',
    'Watch your phone tone. Voice over text today.',
    'Family call brings a clue. Pick up.',
    'A small win in money. Don\'t spend it the same day.',
    'Public energy is loud — drop one no-show plan.',
    'Today wants you precise, not pretty.',
    'Pause before you reply. The thirty-second gap is the win.',
    'Snack-sized goals only. One step at a time.',
    'A bold compliment is well received. Try it.',
    'Skip the side quest. Main story today.',
    'Your strong element fuels you. Wear its color.',
    'Money idea has merit — write the one-page memo.',
    'A friend\'s introduction matters. Reply within 24h.',
    'You\'re right but quiet. Voice it before sunset.',
    'A break in routine actually serves work today.',
    'Tonight is best for big decisions. Sleep on the rest.',
    'The love window opens late today. The patient hours matter.',
    'A long-running tension softens. Don\'t reopen it.',
    'Handle it before you forget. One open loop quietly drains the day.',
    'Today\'s mood prefers depth — say less, mean more.',
    'A creative cycle restarts. Capture the spark.',
    'Travel idea is good — pick a date, not a destination.',
    'You\'ll meet someone you remember in 6 months.',
    'Skip the 11AM thing if you can. Reserve that brain.',
    'Listen to the third opinion today. It\'s right.',
    'Your love language today is timing, not words.',
    'A career conversation is closer than it feels.',
    'Quiet morning, bold afternoon, soft evening.',
    'Don\'t prove anything today. Just show up.',
    'Family fortune chord — text the one who waited.',
    'A small detail makes a big difference. Re-read once.',
    'Lucky direction matters today. Walk that side.',
    'Skip arguments with seniors today. Defer 24h.',
    'Money follows one concrete thing. Pick a specific target today.',
    'A gentle no protects your week.',
    'Old friend returns. Decide what version of you they meet.',
    'Cold water and a bit of sun — that combo recharges you today.',
    'Today rewards specifics. Numbers beat a feeling.',
    'A surprise comes from below your radar. Stay open.',
    'Tonight\'s sleep decides tomorrow\'s answer.',
  ];

  static const _koPool = [
    '오늘의 흐름은 부드러워요. 말도 천천히, 행동도 천천히.',
    '오늘 오전 중간이 가장 좋은 타이밍. 큰 요청은 점심 전.',
    '돈 얘기가 잘 풀려요. 피하지 말고 협상하세요.',
    '메모해 둔 작은 도전이 결실. 적어두지 않은 건 미루세요.',
    '말하기보다 듣기. 오늘 사람들이 당신을 읽고 있어요.',
    '주변 사람들이 도와주고 싶어해요. 그냥 말로 부탁하면 OK.',
    '충동 지출 금물. 그 거래는 내일도 있어요.',
    '오래된 계획 하나가 드디어 준비됐어요.',
    '일찍 자세요. 오늘은 몸이 곧 지갑.',
    '솔직한 한 마디가 잘 받아져요. 가식만 빼면 됩니다.',
    '시작보다 끝내기가 보상받는 날. 탭 하나만 닫으세요.',
    '문자보다 통화가 효과적. 톤 신경 쓰기.',
    '가족 전화에 단서가 있어요. 받으세요.',
    '작은 돈의 이득이 와요. 같은 날 쓰지 마세요.',
    '바깥 에너지가 시끄러워요. 안 가도 되는 약속 하나 빼세요.',
    '오늘은 정확함이 예쁨을 이깁니다.',
    '답장 전 30초 쉬기. 그 침묵이 승부수예요.',
    '한 입 크기 목표만. 한 걸음씩.',
    '대범한 칭찬이 잘 먹혀요. 한 번 시도.',
    '사이드 퀘스트 패스. 오늘은 메인 스토리만.',
    '강한 오행이 당신을 살려요. 그 색의 옷·소품을.',
    '돈 아이디어가 괜찮아요. 한 페이지로 정리하세요.',
    '친구의 소개가 중요해요. 24시간 안에 답장.',
    '맞는 말인데 조용해요. 해 지기 전에 한 번 말하세요.',
    '루틴을 잠시 깨는 게 오히려 일에 도움.',
    '오늘 밤은 큰 결정에 좋은 시간. 나머진 자고 결정.',
    '연애의 창은 늦게 열려요. 인내한 시간이 빛납니다.',
    '오래 끌던 긴장이 풀려요. 다시 건드리지 마세요.',
    '잊기 전에 처리하세요. 밀린 한 가지가 에너지를 새고 있어요.',
    '오늘 분위기는 깊이를 좋아해요. 적게 말하고 진심을 담아요.',
    '창작 사이클이 다시 돌기 시작. 영감을 기록.',
    '여행 아이디어 OK. 목적지보다 날짜부터.',
    '6개월 후 기억할 사람을 오늘 만나요.',
    '11시 약속 패스해도 OK라면 뇌를 아끼세요.',
    '오늘은 세 번째 의견이 맞아요.',
    '오늘 연애 언어는 말이 아니라 타이밍.',
    '진로 대화가 생각보다 가까워요.',
    '조용한 오전, 대담한 오후, 부드러운 저녁.',
    '오늘은 증명하지 마세요. 그냥 나타나기만.',
    '가족 운의 흐름 — 기다린 사람에게 문자 한 통.',
    '작은 디테일이 큰 차이를 만들어요. 한 번 더 읽기.',
    '오늘은 행운의 방향이 의미 있어요. 그쪽으로 산책.',
    '윗사람과 의견 충돌은 패스. 24시간 미루기.',
    '구체적인 한 가지에 집중하면 돈이 따라와요. 막연한 여러 개보다 하나만.',
    '부드러운 거절이 이번 주를 지켜줍니다.',
    '옛 친구가 돌아와요. 어떤 버전의 당신을 만날지 결정.',
    '차가운 물 + 햇빛 — 오늘 몸을 다시 채우는 두 가지.',
    '오늘은 구체적인 게 보상받아요. 숫자 > 분위기.',
    '레이더 밖에서 깜짝 등장. 열린 마음으로.',
    '오늘 밤 잠이 내일의 답을 정해요.',
  ];

  // Round 77 sprint 7 — MZ 중고생 톤 50개 풀 (단톡/야자/시험/최애/굿즈/짝꿍/엄마/학원).
  // 50개 중 ≥35개에 MZ mandate 단어 1개 이상 포함.
  static const _koPoolMz = [
    '단톡에서 한 마디만 더 적게 하면 오늘 하루가 가벼워요.',
    '야자 끝나고 한 곡만 듣고 자기. 그게 내일 컨디션을 바꿔요.',
    '오늘은 시험 점수보다 오답 한 문제 짚는 게 보상이에요.',
    '최애 컴백 영상 하나는 오늘 봐도 OK. 두 개부터 시간을 갉아먹어요.',
    '굿즈 충동구매 패스. 다음 주에도 그 굿즈는 있어요.',
    '짝꿍한테 미안하다는 말, 해 지기 전에.',
    '학원 가는 길에 햇빛 5분. 그게 오늘 뇌의 충전.',
    '엄마 잔소리는 오늘 한 박자 늦게 받기. 24시간 미루기.',
    '콘서트 티켓팅 알람 다시 확인. 캡쳐 떠놓기.',
    '단톡 답장 30초 쉬고. 그 침묵이 오늘 승부수.',
    '오늘은 친구 한 명한테 먼저 물어봐주세요. 단답이면 OK.',
    '야자 시작 전 물 한 잔. 졸음 한 줄이 빠져요.',
    '시험 직전 새 인강 X. 오답노트 한 번 더가 답이에요.',
    '최애 직캠 한 영상 보고 5분 스트레칭. 손이 가벼워져요.',
    '굿즈 정리 10분만. 책상이 풀리면 머리가 풀려요.',
    '짝꿍이 오늘 좀 조용해도 캐묻지 마세요. 내일 먼저 말해줘요.',
    '학원 끝나고 단톡 끄고 10분만 누워요. 진짜 회복.',
    '엄마한테 잘 자고 한 마디. 분위기가 풀려요.',
    '시험 범위 한 페이지 더 욕심내지 말기. 한 단원 정확이 이깁니다.',
    '오늘 단톡 음소거 OK. 진짜 친구는 음소거 안 풀어도 챙겨줘요.',
    '학원 셔틀에서 음악 한 곡. 그 하루치 BGM이 너의 배경이에요.',
    '최애 신곡 첫 소절 5번 듣지 말기. 한 번 들으면 더 박혀요.',
    '굿즈 사진 친구한테 자랑 한 번. 자랑할 줄 아는 게 덕질의 기본.',
    '짝꿍이 오늘 노트 빌려달라 하면 OK. 다음 주에 너가 빌려요.',
    '엄마가 오늘 야식 사주면 한 마디 고맙다고. 그게 오늘의 동전.',
    '단톡 답장 안 한 사람 한 명. 오늘 안에 가볍게 한 줄.',
    '시험 망친 친구 위로는 길게 X. "괜찮아" 한 줄이 가장 따뜻해요.',
    '야자 30분만 진지하게. 나머지는 흘려도 OK.',
    '최애 멤버 생일 D-Day. 메모에 한 줄 적어두기.',
    '굿즈 박스 정리하면서 사진 한 장. 인스타 스토리 1초.',
    '짝꿍이랑 한 끼는 같이 먹기. 매점 빵 한 개도 OK.',
    '학원 빠지고 싶은 날. 한 강의만 듣고 가도 너의 승리예요.',
    '엄마가 시험 점수 물어보면 정직하게 한 번. 그 뒤가 더 편해요.',
    '오늘 단톡 안 읽음 3개. 자기 전에 한 줄씩만 답해도 충분.',
    '시험 직전 1시간은 새 문제 X. 풀었던 문제 다시 보는 게 답.',
    '최애 컴백 무대 직캠 한 번. 그 다음은 공부.',
    '굿즈 알림 어플 알람 끄고 30분. 너의 시간이 돌아와요.',
    '짝꿍한테 오늘 한 번만 더 웃어줘요. 분위기가 풀려요.',
    '엄마 잔소리 한 번은 그냥 듣기. 그 다음 한 번은 짧게 답해도 OK.',
    '학원 가방에서 안 쓰는 책 한 권 빼기. 어깨가 가벼워져요.',
    '단톡에서 누군가 욕하면 너는 한 줄 침묵. 그 침묵이 너의 자리.',
    '야자 마지막 10분에 내일 시간표 한 번. 내일 아침이 가벼워져요.',
    '오늘 최애 노래로 알람 바꿔보기. 내일 아침이 살아요.',
    '굿즈 친구한테 빌려달라면 OK. 그 친구 너 굿즈도 빌려줘요.',
    '시험 끝나고 짝꿍한테 한 마디. "수고했어" 그 한 줄이 다 해요.',
    '학원 가는 길 6분 일찍. 그 6분이 오늘의 여유.',
    '엄마한테 오늘 한 마디. "오늘 잘 잤어?" 그게 분위기를 풀어요.',
    '단톡에서 답장 늦은 친구한테 답 재촉 X. 내일 한 줄로 와요.',
    '시험 직전 단톡 알람 끄기. 5분만이라도.',
    '최애 직캠 본 후 한 줄 메모. 그 곡이 너의 색으로 자리잡아요.',
  ];

  static const _enPoolMz = [
    'One fewer reply in the groupchat keeps today lighter.',
    "After school night, one song then sleep. That changes tomorrow's condition.",
    'A wrong answer reviewed beats one more test point today.',
    "One fancam of your bias is fine. Two starts eating your time.",
    'Skip the impulse merch buy. That photocard will still be there next week.',
    'Say sorry to your seatmate before sunset.',
    'Five minutes of sunlight on the way to cram class. Brain charge.',
    "Take mom's nagging one beat late today. Defer 24h.",
    'Recheck your concert ticket alarm. Screenshot it.',
    "Wait 30s before replying in the groupchat. That silence is today's win.",
    'Ask one friend something first today. A short reply is OK.',
    'Glass of water before school night session. One yawn fewer.',
    "Before the test, no new lecture. One more pass at your wrong-answer notes wins.",
    'One bias fancam then five-minute stretch. Hands lighter.',
    'Ten minutes to tidy merch shelf. Desk loose, head loose.',
    "If your seatmate is quiet today, don't push. They'll speak first tomorrow.",
    'After cram class, mute the groupchat and lie down 10 min. Real recovery.',
    "Tell mom good night. The mood softens.",
    "Don't push for one extra chapter before the exam. One clean chapter wins.",
    'Mute the groupchat today is OK. Real friends still find you.',
    'One song on the cram-class shuttle. That BGM is your background today.',
    "Don't loop the first line of the new bias track 5x. Once lands deeper.",
    'Brag your merch photo to one friend. Bragging is core to stanning.',
    "If seatmate borrows your notebook today, OK. You'll borrow next week.",
    "If mom buys late-night snack, say thanks once. That's today's coin.",
    'One person you ghosted in the groupchat — short line today.',
    "Don't long-comfort a friend who failed an exam. 'It's okay' is the warmest.",
    'Thirty minutes of focused school-night study. The rest can drift.',
    "Bias member's birthday today. Note one line.",
    'One snap of your merch box while tidying. One-second IG story.',
    'Share one meal with your seatmate. A bakery bun is fine.',
    'On days you want to skip cram class, attending one lecture is still your win.',
    'If mom asks about your test score, be honest once. After that gets lighter.',
    'Three unread in the groupchat. One line each before bed is enough.',
    'In the hour before the exam, no new problems. Re-read what you solved.',
    'One bias comeback stage fancam. Then back to study.',
    "Mute merch-app alarms for 30 min. Your time returns.",
    'Smile at your seatmate one more time today. The mood softens.',
    "Listen to mom's nag once today. The next one you can reply short.",
    'Pull one unused book from your school bag. Shoulders lighter.',
    "If someone trash-talks in the groupchat, your one line of silence is your seat.",
    "Last 10 min of school night, check tomorrow's schedule. Morning lighter.",
    'Switch your alarm to a bias track. Tomorrow morning comes alive.',
    "If a friend asks to borrow your merch, OK. They'll lend you theirs too.",
    'After the test, one line to your seatmate. "Good job" carries all of it.',
    'Six minutes early to cram class. That six is your slack today.',
    "Ask mom one thing today: 'Did you sleep well?' Mood opens.",
    "Don't chase a slow groupchat replier. Their line comes tomorrow.",
    'Mute groupchat right before the test. Even five minutes.',
    "Note one line after the bias fancam. That track becomes your signature.",
  ];

  /// 사용자 사주 (dayPillar) + 날짜 seed → deterministic 풀 선택.
  /// 같은 사용자 같은 날 → 항상 같은 문구 (알림 일관성).
  /// Round 77 sprint 7 — tone 파라미터 추가 (기본 adult, mz 선택 시 MZ 풀).
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
