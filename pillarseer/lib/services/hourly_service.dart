// Pillar Seer — 시진별 운세 (Hourly Flow).
// 12 시진 (子丑寅卯辰巳午未申酉戌亥) × 사용자 일간 5행 상호작용 → 점수 + 한 줄 가이드.
// 점신·평생사주 가 강한 데일리 리텐션 영역.

import '../models/saju_result.dart';

/// 시진 1슬롯
class HourlySlot {
  final String jiJi;         // 子 ~ 亥
  final String animal;       // Rat ~ Pig
  final int startHour;       // 23 → next-day start
  final int endHour;         // exclusive
  final String element;      // 木火土金水
  final int score;           // 0~100
  final String guideEn;
  final String guideKo;
  final String mood;         // peak/good/neutral/watch/avoid
  final bool isCurrent;
  final bool isNext;

  const HourlySlot({
    required this.jiJi,
    required this.animal,
    required this.startHour,
    required this.endHour,
    required this.element,
    required this.score,
    required this.guideEn,
    required this.guideKo,
    required this.mood,
    this.isCurrent = false,
    this.isNext = false,
  });

  static String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  String label(bool useKo) {
    final s = _fmt(startHour);
    final e = _fmt(endHour);
    return useKo ? '$s ~ $e  ·  $jiJi' : '$s–$e · $animal';
  }
}

class HourlyService {
  static const _slots = [
    ('子', 'Rat',     23, 1,  '水'),
    ('丑', 'Ox',       1, 3,  '土'),
    ('寅', 'Tiger',    3, 5,  '木'),
    ('卯', 'Rabbit',   5, 7,  '木'),
    ('辰', 'Dragon',   7, 9,  '土'),
    ('巳', 'Snake',    9, 11, '火'),
    ('午', 'Horse',   11, 13, '火'),
    ('未', 'Goat',    13, 15, '土'),
    ('申', 'Monkey',  15, 17, '金'),
    ('酉', 'Rooster', 17, 19, '金'),
    ('戌', 'Dog',     19, 21, '土'),
    ('亥', 'Pig',     21, 23, '水'),
  ];

  /// 12 시진 모두 계산. now 시각 기준 isCurrent/isNext flag 설정.
  static List<HourlySlot> twelveSlots(SajuResult saju, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final hour = t.hour;
    final dm = saju.dayPillar.chunGanElement;

    int currentIdx = -1;
    for (var i = 0; i < _slots.length; i++) {
      final s = _slots[i];
      final start = s.$3;
      final end = s.$4;
      final inRange = start < end
          ? (hour >= start && hour < end)
          : (hour >= start || hour < end);
      if (inRange) {
        currentIdx = i;
        break;
      }
    }

    return List<HourlySlot>.generate(_slots.length, (i) {
      final s = _slots[i];
      final el = s.$5;
      final (score, mood) = _interact(dm, el);
      final hooks = _hookFor(s.$1, dm, el, mood);
      return HourlySlot(
        jiJi: s.$1,
        animal: s.$2,
        startHour: s.$3,
        endHour: s.$4,
        element: el,
        score: score,
        guideEn: hooks.en,
        guideKo: hooks.ko,
        mood: mood,
        isCurrent: i == currentIdx,
        isNext: currentIdx >= 0 && i == ((currentIdx + 1) % 12),
      );
    });
  }

  /// 5행 상호작용 score + mood label
  static (int, String) _interact(String dm, String slotEl) {
    if (dm == slotEl) return (78, 'good');
    const generates = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    const overcomes = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
    if (generates[dm] == slotEl) return (90, 'peak');
    if (generates[slotEl] == dm) return (82, 'good');
    if (overcomes[dm] == slotEl) return (55, 'neutral');
    if (overcomes[slotEl] == dm) return (35, 'avoid');
    return (62, 'neutral');
  }

  /// mood 별 한 줄 가이드 + 시진별 살짝 다른 표현
  static ({String en, String ko}) _hookFor(
      String jiJi, String dm, String slotEl, String mood) {
    // 시진 동물 기반 톤
    const animalMoodKo = {
      '子': '집중해서 결과 만들기 좋은',
      '丑': '꾸준히 쌓는',
      '寅': '먼저 움직여 분위기를 만드는',
      '卯': '부드럽게 풀어가는',
      '辰': '큰 그림을 정하는',
      '巳': '논리적 결정에 좋은',
      '午': '드러내고 발표하기 좋은',
      '未': '관계 조율에 좋은',
      '申': '정리·끝맺음에 좋은',
      '酉': '디테일을 다듬는',
      '戌': '검토·신뢰 다지는',
      '亥': '쉬며 회복하는',
    };
    const animalMoodEn = {
      '子': 'deep-focus',
      '丑': 'steady-build',
      '寅': 'first-move',
      '卯': 'soft-flow',
      '辰': 'big-picture',
      '巳': 'logic-call',
      '午': 'spotlight',
      '未': 'social-mend',
      '申': 'close-out',
      '酉': 'detail-polish',
      '戌': 'trust-check',
      '亥': 'rest-recover',
    };
    final base = animalMoodKo[jiJi] ?? '잔잔한';
    final baseEn = animalMoodEn[jiJi] ?? 'steady';
    switch (mood) {
      case 'peak':
        return (
          ko: '$base 시간. 큰 결정·발표·약속 OK.',
          en: '$baseEn window — green light for big calls.',
        );
      case 'good':
        return (
          ko: '$base 시간. 평소보다 잘 풀려요.',
          en: '$baseEn window — smoother than usual.',
        );
      case 'neutral':
        return (
          ko: '$base 시간. 무리한 시도는 후회만 남아요.',
          en: '$baseEn window — push only what is essential.',
        );
      case 'avoid':
        return (
          ko: '$base 시간이지만 오늘 당신엔 피곤한 흐름. 미루세요.',
          en: '$baseEn but tilts against you — defer big asks.',
        );
      default:
        return (ko: '$base 시간.', en: '$baseEn window.');
    }
  }
}
