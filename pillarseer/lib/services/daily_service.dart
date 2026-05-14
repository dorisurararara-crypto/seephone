import '../models/daily_fortune.dart';
import '../models/saju_result.dart';
import 'saju_service.dart';

/// 하루 에너지 분류 — Round 71 사용자 불만 #3 (모순 0).
///
/// 한 사용자의 한 날 출력되는 score-driven 멘트 (home `_ScoreBlock` label/hint,
/// today deep service headline/body/actions/caution/mood) 가 같은 분류에서만
/// 흐름. `classifyDayEnergy(score)` 가 단일 source of truth.
/// lucky_chips_service / result_screen 은 score 직접 분기 X (영향 X — wire 불필요).
enum DayEnergyKind {
  /// score < 50 — 쉬어가는 날. "발표/승진/공식 자리/도전·승부" 어휘 출력 금지.
  restDay,

  /// 50 ≤ score < 75 — 보통보다 조심. 보수적 행동만.
  mixedDay,

  /// score ≥ 75 — 좋은 날. "쉬어가/아끼" 어휘 출력 금지.
  actionDay,
}

DayEnergyKind classifyDayEnergy(int totalScore) {
  if (totalScore < 50) return DayEnergyKind.restDay;
  if (totalScore < 75) return DayEnergyKind.mixedDay;
  return DayEnergyKind.actionDay;
}

/// 데일리 운세 서비스 — 사용자 사주 vs 오늘 일진 충합 분석.
///
/// 단순화 알고리즘 (Phase 1):
/// - 오늘 일진 (`SajuService` 의 `_dayPillarIndex`) 추출
/// - 사용자 일간 vs 오늘 일진의 5행 상극/상생 → 점수 계산
/// - 4 카테고리 점수: 일간 천간 + 오늘 천간 비교
/// - Lucky Color/Number/Direction: 오늘 5행 dominant 매핑
///
/// Phase 2: 12지 충합형파해, 절기 고려, 시간대별 변동.

class DailyService {
  final SajuService _saju = SajuService();

  // 5행 상생/상극 (천간 기준)
  // 상생: 木→火→土→金→水→木
  // 상극: 木→土→水→火→金→木
  int _elementInteraction(String userEl, String dayEl) {
    if (userEl == dayEl) return 80; // 비화
    const generates = {
      '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
    };
    const overcomes = {
      '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
    };
    if (generates[userEl] == dayEl) return 90; // 사용자가 오늘을 생함 (좋음)
    if (generates[dayEl] == userEl) return 75;  // 오늘이 사용자를 생함 (좋음)
    if (overcomes[userEl] == dayEl) return 55;  // 사용자가 오늘을 극함 (보통)
    if (overcomes[dayEl] == userEl) return 35;  // 오늘이 사용자를 극함 (주의)
    return 60;
  }

  /// 5행 → 행운의 색 (Water 는 'Deep Ocean Blue' — 'Midnight Purple' 은 앱 배경색이라 혼동 방지)
  /// locale-aware: ko=true → 한국어, false → 영문.
  String _luckyColorFor(String element, {bool ko = false}) {
    const enMap = {
      '木': 'Forest Jade',
      '火': 'Phoenix Red',
      '土': 'Ancient Bronze',
      '金': 'Lunar Silver',
      '水': 'Deep Ocean Blue',
    };
    const koMap = {
      '木': '숲의 옥색 (Forest Jade)',
      '火': '봉황의 붉은빛 (Phoenix Red)',
      '土': '고대 청동빛 (Ancient Bronze)',
      '金': '달의 은빛 (Lunar Silver)',
      '水': '심해의 푸른빛 (Deep Ocean Blue)',
    };
    return ko ? (koMap[element] ?? '천계의 황금빛') : (enMap[element] ?? 'Celestial Gold');
  }

  /// 5행 → 행운의 방향
  String _luckyDirectionFor(String element, {bool ko = false}) {
    const enMap = {
      '木': 'East',
      '火': 'South',
      '土': 'Center',
      '金': 'West',
      '水': 'North',
    };
    const koMap = {
      '木': '동쪽',
      '火': '남쪽',
      '土': '중앙',
      '金': '서쪽',
      '水': '북쪽',
    };
    return ko ? (koMap[element] ?? '동쪽') : (enMap[element] ?? 'East');
  }

  /// 5행 → 행운의 숫자 (河圖洛書 기반)
  int _luckyNumberFor(String element) {
    const map = {
      '木': 3,
      '火': 7,
      '土': 5,
      '金': 9,
      '水': 1,
    };
    return map[element] ?? 7;
  }

  /// 일진별 한 줄 메시지 — ko/en 둘 다 반환.
  /// dayPillar 의 chunGan 첫 코드 + score 로 seed 만들어 variation 5개 중 하나 선택.
  /// 같은 일주여도 score 와 dayPillar 조합으로 다양한 메시지 노출.
  ({String ko, String en}) _quoteFor(String dayPillar, int score) {
    final seed = (dayPillar.isEmpty ? 0 : dayPillar.codeUnits.first) % 3;
    if (score >= 85) {
      const pool = [
        (ko: '먼 곳에서 비밀스러운 인연이 다가오는 날.',
            en: 'A secret friend arrives from afar.'),
        (ko: '오늘 만난 한 사람이 다음 1년의 결을 바꿉니다.',
            en: 'One person you meet today reshapes the next year.'),
        (ko: '의도 없이 흘려보낸 말이 가장 큰 다리가 됩니다.',
            en: 'A word you spoke without weight becomes the longest bridge.'),
      ];
      return pool[seed];
    }
    if (score >= 70) {
      const pool = [
        (ko: '아이디어는 점심 전에 말하고, 오후에는 듣는 날.',
            en: 'Speak your idea before noon. Listen after.'),
        (ko: '오후의 작은 침묵이 오전의 결정보다 큰 결과를 낳습니다.',
            en: 'An afternoon pause weighs more than a morning decision.'),
        (ko: '오늘은 빠른 답보다 정확한 질문이 가치 있습니다.',
            en: 'A precise question is worth more than a quick answer today.'),
      ];
      return pool[seed];
    }
    if (score >= 55) {
      const pool = [
        (ko: '오늘의 고요함이 다음 달의 수확을 심습니다.',
            en: 'Stillness today plants the harvest of next month.'),
        (ko: '한 번 더 자라가는 길이 정답입니다.',
            en: 'The longer way around is the right way today.'),
        (ko: '꾸준한 한 발이 큰 발자국보다 깊습니다.',
            en: 'A steady step prints deeper than a big leap.'),
      ];
      return pool[seed];
    }
    if (score >= 40) {
      const pool = [
        (ko: '점심 무렵 충동 지출 조심하는 날.',
            en: 'Watch for impulsive spending mid-day.'),
        (ko: '오늘 결정은 24시간 보류하는 편이 안전합니다.',
            en: 'Sit on today\'s decisions for 24 hours before acting.'),
        (ko: '말의 톤을 한 단계 낮추세요 — 의도가 더 잘 전해집니다.',
            en: 'Cool your tone by one notch — intent travels better.'),
      ];
      return pool[seed];
    }
    const pool = [
      (ko: '천천히 움직이세요. 얼음 아래의 물은 자기 시간이 있습니다.',
          en: 'Move slow. The water beneath the ice has its own time.'),
      (ko: '오늘은 안에 머무는 날 — 밖이 아니라 안을 살피세요.',
          en: 'Stay in today — look inward, not outward.'),
      (ko: '잠시 멈추는 것도 행동입니다. 결의 결을 다듬으세요.',
          en: 'Pausing is also action — refine your edge.'),
    ];
    return pool[seed];
  }

  /// 메인: 사용자 사주 + 오늘 날짜로 데일리 운세 계산
  DailyFortune calculate(SajuResult userSaju, {DateTime? today}) {
    final t = today ?? DateTime.now();

    // 오늘 일진 계산 (시간 0시 기준)
    final dayIdx = _calculateDayPillarIndex(t.year, t.month, t.day);
    final todayPillar = _saju.pillarFromIndex(dayIdx);

    final userElement = userSaju.dayPillar.chunGanElement;
    final todayElement = todayPillar.chunGanElement;

    final base = _elementInteraction(userElement, todayElement);
    // 카테고리별 변동 (간단 시드)
    final seed = (dayIdx + userSaju.dayPillar.text.codeUnits.first) % 30;
    final loveScore = (base + (seed % 11) - 5).clamp(20, 100);
    final workScore = (base + ((seed * 3) % 11) - 5).clamp(20, 100);
    final wealthScore = (base + ((seed * 7) % 11) - 5).clamp(20, 100);
    final energyScore = (base + ((seed * 11) % 11) - 5).clamp(20, 100);
    final total = ((loveScore + workScore + wealthScore + energyScore) / 4).round();

    final love = _categoryGuide('love', loveScore);
    final work = _categoryGuide('work', workScore);
    final wealth = _categoryGuide('wealth', wealthScore);
    final energy = _categoryGuide('energy', energyScore);

    final quote = _quoteFor(todayPillar.text, total);

    return DailyFortune(
      date: t,
      totalScore: total,
      loveScore: loveScore,
      workScore: workScore,
      wealthScore: wealthScore,
      energyScore: energyScore,
      quote: quote.en, // backward-compat
      quoteEn: quote.en,
      quoteKo: quote.ko,
      luckyColor: _luckyColorFor(userElement),
      luckyColorEn: _luckyColorFor(userElement),
      luckyColorKo: _luckyColorFor(userElement, ko: true),
      luckyNumber: _luckyNumberFor(userElement),
      luckyDirection: _luckyDirectionFor(userElement),
      luckyDirectionEn: _luckyDirectionFor(userElement),
      luckyDirectionKo: _luckyDirectionFor(userElement, ko: true),
      dayPillar: todayPillar.text,
      loveGuideEn: love.en,
      loveGuideKo: love.ko,
      workGuideEn: work.en,
      workGuideKo: work.ko,
      wealthGuideEn: wealth.en,
      wealthGuideKo: wealth.ko,
      energyGuideEn: energy.en,
      energyGuideKo: energy.ko,
    );
  }

  /// 카테고리별 점수 → 한 줄 가이드 (mood band)
  static ({String en, String ko}) _categoryGuide(String cat, int score) {
    final band = score >= 80 ? 'high' : score >= 55 ? 'mid' : 'low';
    const map = {
      'love': {
        'high': (
          en:
              'Chemistry is on your side today. If there\'s someone on your mind, this is the day to send the message you\'ve been holding — even a simple "How are you?" lands well. A natural, slightly playful tone works better than a serious one right now.',
          ko:
              '오늘은 케미가 당신 편이에요. 마음에 두고 있던 사람이 있다면, 미뤄왔던 안부 메시지 한 통 보내기 좋은 날이에요. "잘 지내?" 같은 가벼운 톤이 무거운 고백보다 더 잘 통하는 흐름이고, 약간 장난기 섞인 표현이 자연스럽게 닿습니다.'
        ),
        'mid': (
          en:
              'Today rewards listening over talking. The other person has something they want to say but hasn\'t found the moment yet — leave space and they\'ll open up. Depth and warmth beat charm and wit today, so resist the urge to perform.',
          ko:
              '오늘은 말하기보다 듣기에 점수가 더 붙어요. 상대가 말하고 싶었던 한 가지가 있는데 타이밍을 못 잡고 있으니, 당신이 여백을 만들어 주면 자연스럽게 열려요. 재치보다 깊이와 따뜻함이 더 매력적으로 느껴지는 흐름이라, 멋있어 보이려 애쓰지 않아도 충분합니다.'
        ),
        'low': (
          en:
              'Hold off on big confessions or heavy conversations today — give it 24 hours. Words you say right now may sound heavier than you mean. Spend the day on small kindnesses instead; a quiet message tomorrow morning will land much better than a big move now.',
          ko:
              '오늘은 큰 고백이나 무거운 대화는 24시간만 미루는 게 좋아요. 지금 하는 말이 의도보다 무겁게 들릴 가능성이 있는 흐름이에요. 대신 오늘은 작은 다정함만 보여주고, 내일 아침 보내는 짧은 메시지 한 통이 지금 한 큰 행동보다 훨씬 잘 닿습니다.'
        ),
      },
      'work': {
        'high': (
          en:
              'A timing window is open — pitch the bold idea, ask for the meeting, send the proposal. Initiative is rewarded today, and decision-makers are more receptive than usual. Don\'t over-prepare; a confident outline beats a perfect deck right now.',
          ko:
              '오늘은 먼저 말 꺼내기 좋은 날이에요. 미뤄왔던 제안이나 발표 아이디어 — 먼저 움직이는 사람이 점수를 받는 날이에요. 상대도 평소보다 열려 있는 흐름이라, 완벽한 자료보다 자신감 있는 한 줄 요약이 더 강하게 작동해요.'
        ),
        'mid': (
          en:
              'Steady execution day. Pick one task you\'ve had open too long and close it fully today — even if it\'s small. The momentum from one clean finish carries into tomorrow much more than starting three new things. Avoid context-switching.',
          ko:
              '오늘은 꾸준히 실행하는 날이에요. 오래 열려 있던 작은 일 하나만 골라서 끝까지 매듭지어 보세요. 깨끗하게 끝낸 일 하나가 새로 시작한 세 가지보다 내일까지 가는 추진력을 더 만들어줍니다. 여러 일을 동시에 건드리는 건 오늘은 피하세요.'
        ),
        'low': (
          en:
              'Defer big decisions today — your bandwidth is lower than usual and you may push through what should pause. Use the day for prep, research, or quiet review instead of choices. Anything you decide today, you\'d probably revise tomorrow anyway.',
          ko:
              '오늘은 큰 결정을 미루세요. 평소보다 에너지가 낮은 흐름이라, 멈춰야 할 일도 그냥 밀어붙일 위험이 있어요. 결정 대신 자료 정리, 리서치, 조용한 점검으로 시간을 쓰세요. 오늘 정한 건 내일 다시 보면 어차피 수정하고 싶어집니다.'
        ),
      },
      'wealth': {
        'high': (
          en:
              'Cash flow window. Sign the contract, send the invoice, ask for the raise, negotiate the price — money-related conversations land better today. Don\'t miss this window on something you\'ve been postponing; even one decisive action moves the whole month forward.',
          ko:
              '돈의 창이 열린 날이에요. 용돈 협상, 알바비 정산, 가격 흥정 — 돈 관련 얘기가 평소보다 잘 통하는 흐름이에요. 미뤄왔던 한 가지를 오늘 행동으로 옮기면, 그 한 번이 이번 달 전체 흐름을 바꿀 수 있어요.'
        ),
        'mid': (
          en:
              'Smart audit day. Before you spend or commit to a recurring cost, sit with it for ten minutes. The kind of expense that feels small today often shows up bigger in the monthly view — open the bank app and look once. Clarity beats discipline today.',
          ko:
              '오늘은 똑똑한 점검의 날이에요. 새로 지출하거나 정기 결제를 늘리기 전에 10분만 앉아서 생각해 보세요. 오늘 작아 보이는 지출이 한 달 단위로 보면 의외로 커지는 경우가 많으니, 가계부 앱 한 번만 열어 보세요. 의지력보다 가시화가 더 효과적인 날입니다.'
        ),
        'low': (
          en:
              'Avoid impulse purchases — sit on anything you\'re tempted by for 48 hours. Today\'s "I really need this" often turns into next week\'s "why did I buy this?". Use the day to pay one small bill or to cancel one subscription you don\'t use; both feel surprisingly good.',
          ko:
              '오늘은 충동 지출 금물. 사고 싶다는 마음이 들면 48시간만 기다려 보세요. 오늘의 "이거 진짜 필요해" 가 다음 주의 "왜 샀지" 가 되는 패턴이 잘 나오는 흐름이에요. 그 대신 안 쓰는 구독 하나 해지하거나, 작은 결제 하나만 처리하면 의외로 기분이 가벼워져요.'
        ),
      },
      'energy': {
        'high': (
          en:
              'Vitality is high — push the workout, take the call, run the errand you\'ve been postponing. Active energy is what you have today, so converting it into something physical (or completing a stuck task) feels much better than scrolling. Use the body, save the screen for tomorrow.',
          ko:
              '오늘은 활력 최고치예요. 운동 강도 한 번 올려도 좋고, 미뤄둔 전화·외출도 처리하기 좋은 날이에요. 오늘은 활동성 에너지가 풍부하니 몸 쓰는 일이나 막혀 있던 일 해결에 쓰면 화면 보는 것보다 훨씬 만족스러워요. 몸은 오늘, 스크롤은 내일.'
        ),
        'mid': (
          en:
              'Pace yourself today — don\'t burn the whole battery before noon. Two short breaks (10 minutes each, away from the screen) keep you sharper than one long crash later. Light meal, water before coffee, one short walk — your formula today.',
          ko:
              '오늘은 페이스 조절이 핵심이에요. 오전에 배터리를 다 쓰면 오후가 흐려져요. 10분씩 두 번 짧게 쉬는 게 한 번에 길게 쉬는 것보다 효과가 커요. 가벼운 식사, 커피보다 물 먼저, 짧은 산책 한 번 — 오늘의 공식입니다.'
        ),
        'low': (
          en:
              'Rest is productive today. Recovery beats output — pushing through low energy just steals from tomorrow. Cancel one optional thing on your calendar, sleep 30 minutes earlier, and forgive yourself for the "unproductive" feeling. Your body is asking for the day.',
          ko:
              '오늘은 쉬는 게 진짜 생산이에요. 회복이 출력보다 점수가 높은 날 — 낮은 에너지로 밀어붙이면 내일을 미리 끌어다 쓰는 셈이에요. 일정 중에 안 해도 되는 것 하나 취소하고, 30분 일찍 자고, "오늘 비생산적이었다" 는 죄책감만 내려놓으세요. 몸이 하루를 요청하는 중입니다.'
        ),
      },
    };
    return map[cat]![band]!;
  }

  /// 일주 인덱스 (SajuService 와 동일 알고리즘)
  int _calculateDayPillarIndex(int year, int month, int day) {
    // Julian Day Number
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jdn = ((365.25 * (y + 4716)).floor() +
            (30.6001 * (m + 1)).floor() +
            day + b - 1524.5)
        .floor();
    const epoch = 2415021;
    return (10 + (jdn - epoch)) % 60;
  }
}
