// Pillar Seer — 일일 알림 문구 풀 (50+ 변주).
// 매일 8시 푸시가 같은 문구면 끄게 됨. 50개 풀에서 일자별 deterministic 선택.
// Round 76 sprint 6 — pickDeep 신규: 사용자 사주 + 오늘 일진 기반 calibrate.

import '../models/saju_result.dart';
import 'today_event_service.dart';

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
    'Pay before you forget. One unpaid thing is leaking energy.',
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
    'Avoid argument with elders. Defer 24h.',
    'Money flows toward the named project. Name yours.',
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
    '잊기 전에 지불하세요. 미지급 한 가지가 에너지를 새고 있어요.',
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
    '연장자와 논쟁은 패스. 24시간 미루기.',
    '이름 붙은 프로젝트로 돈이 흘러요. 이름을 정하세요.',
    '부드러운 거절이 이번 주를 지켜줍니다.',
    '옛 친구가 돌아와요. 어떤 버전의 당신을 만날지 결정.',
    '차가운 물 + 햇빛 — 오늘 몸을 다시 채우는 두 가지.',
    '오늘은 구체적인 게 보상받아요. 숫자 > 분위기.',
    '레이더 밖에서 깜짝 등장. 열린 마음으로.',
    '오늘 밤 잠이 내일의 답을 정해요.',
  ];

  /// 사용자 사주 (dayPillar) + 날짜 seed → deterministic 풀 선택.
  /// 같은 사용자 같은 날 → 항상 같은 문구 (알림 일관성).
  static ({String en, String ko}) pickFor(DateTime date, String day60ji) {
    final seed = (date.year * 366 + date.month * 31 + date.day) ^
        day60ji.codeUnits.fold<int>(0, (a, b) => a + b);
    final idx = (seed % _enPool.length).abs();
    return (en: _enPool[idx], ko: _koPool[idx]);
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
