// Pillar Seer — 일일 알림 문구 풀 (50+ 변주).
// 매일 8시 푸시가 같은 문구면 끄게 됨. 50개 풀에서 일자별 deterministic 선택.
// Round 76 sprint 6 — pickDeep 신규: 사용자 사주 + 오늘 일진 기반 calibrate.
// Round 77 sprint 7 — MZ 톤 50 ko/en 풀 추가 + tone selector.
//   기본 'adult' = 기존 50 ko/en. 'mz' = 신규 50 ko/en (단톡/야자/시험/최애/굿즈/짝꿍/엄마).

import '../models/saju_result.dart';
import 'today_event_service.dart';

/// 알림 톤 — 어른 (기본) / MZ 중고생.
enum NotificationTone { adult, mz }

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
    'Your love window opens late. Patient hours matter.',
    'A long-running tension softens. Don\'t reopen it.',
    'Handle it before you forget. One open loop is leaking your energy.',
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
    'Cold water + sunlight — your body recharges in those.',
    'Today rewards specifics. Numbers > vibes.',
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
}
