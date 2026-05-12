import '../models/daily_fortune.dart';
import '../models/saju_result.dart';
import 'saju_service.dart';

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
  String _luckyColorFor(String element) {
    const map = {
      '木': 'Forest Jade',
      '火': 'Phoenix Red',
      '土': 'Ancient Bronze',
      '金': 'Lunar Silver',
      '水': 'Deep Ocean Blue',
    };
    return map[element] ?? 'Celestial Gold';
  }

  /// 5행 → 행운의 방향
  String _luckyDirectionFor(String element) {
    const map = {
      '木': 'East',
      '火': 'South',
      '土': 'Center',
      '金': 'West',
      '水': 'North',
    };
    return map[element] ?? 'East';
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
          en: 'Pausing is also action — refine the grain of your grain.'),
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
      luckyNumber: _luckyNumberFor(userElement),
      luckyDirection: _luckyDirectionFor(userElement),
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
        'high': (en: 'Make the move — chemistry is on your side today.', ko: '먼저 다가가도 좋아요. 오늘은 케미가 당신 편이에요.'),
        'mid': (en: 'Listen more than you speak — depth beats charm today.', ko: '말보다 듣기. 오늘은 깊이가 매력을 이깁니다.'),
        'low': (en: 'Hold off on big confessions — give it 24 hours.', ko: '큰 고백은 미루세요. 24시간만 기다려도 OK.'),
      },
      'work': {
        'high': (en: 'Pitch the bold idea — your timing window is open.', ko: '용감한 제안을 던지세요. 타이밍의 창이 열렸어요.'),
        'mid': (en: 'Steady execution today — close one task fully.', ko: '꾸준한 실행의 날. 한 가지를 끝까지 매듭짓기.'),
        'low': (en: 'Defer big decisions — protect your bandwidth.', ko: '큰 결정은 미루기. 에너지를 보호하세요.'),
      },
      'wealth': {
        'high': (en: 'Cash flow window — sign, invoice, or negotiate today.', ko: '돈의 창이 열렸어요. 서명·청구·협상에 좋아요.'),
        'mid': (en: 'Review before you spend — smart audit today.', ko: '쓰기 전 점검. 오늘은 똑똑한 감사의 날.'),
        'low': (en: 'Avoid impulse purchases — sit on it for 48 hours.', ko: '충동 지출 금물. 48시간만 참아 보세요.'),
      },
      'energy': {
        'high': (en: 'High vitality — push the workout, do the call.', ko: '활력 최고치. 운동·통화 같은 액션 일로 풀어보세요.'),
        'mid': (en: 'Pace yourself — don\'t burn the whole battery.', ko: '페이스 조절. 배터리 한 번에 다 쓰지 마세요.'),
        'low': (en: 'Rest is productive today — recovery > output.', ko: '오늘은 쉬는 게 생산이에요. 회복 > 산출.'),
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
