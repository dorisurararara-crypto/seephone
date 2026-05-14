// Pillar Seer — 행운 칩 (Lucky Chips) 6 개 + 근거 popup 본문 서비스.
//
// 1등 운세 앱: 황금색 · 도가니탕 · 1,29 · 동료/주씨 · 북동쪽 · 방향제 (구체적 6 항목).
// 우리 흡수: 색 · 숫자 · 방향 · 음식 · 사람띠 · 물건 — 6 카테고리.
// 차별: chip 탭 → "왜 행운인지" 근거 본문 (사주 5행 기반 직설 친근 톤).
//
// 본문 톤 절대 준수 (codex 9.9+ PASS 라인):
// - "당신은 X 같은 사람" 직설
// - 한자 jargon X, 직장인 jargon X
// - K-POP 중학생 페르소나도 한 번에 이해

import '../models/saju_result.dart';
import 'ziwei_service.dart';

class LuckyChip {
  /// 카테고리 라벨 (색·숫자·방향·음식·사람띠·물건).
  final String category;

  /// 한 글자 아이콘 (이모지).
  final String icon;

  /// 값 (예: '황금색', '9', '서쪽', '도가니탕').
  final String value;

  /// 왜 행운인지 — popup 본문 (직설 친근 톤, 2~4문장).
  final String reasonKo;

  /// 어떤 5 행 기반인지 (debug/test).
  final String basisEl;

  const LuckyChip({
    required this.category,
    required this.icon,
    required this.value,
    required this.reasonKo,
    required this.basisEl,
  });
}

class LuckyChipsService {
  /// 6 개 chip 생성 — 부족한(deficit) 5 행 보충 우선, 그다음 dominant 활용.
  static List<LuckyChip> compute(
    SajuResult saju,
    ZiweiResult ziwei, {
    DateTime? today,
  }) {
    final dayStem = saju.dayPillar.chunGan;
    final dayEl = saju.dayPillar.chunGanElement;
    final deficit = saju.elements.deficit;
    final dominant = saju.elements.dominant;
    // 보충 우선 5행 (부족 = 가장 효과 큼). dayEl 와 같지 않을 때만.
    final supplyEl = (deficit == dayEl) ? _secondDeficit(saju) : deficit;

    return [
      _chipColor(saju, supplyEl, dayStem),
      _chipNumber(saju, supplyEl),
      _chipDirection(saju, supplyEl, dayEl),
      _chipFood(saju, supplyEl, dayEl, dominant),
      _chipPerson(saju, ziwei, supplyEl, dayStem),
      _chipObject(saju, supplyEl, dayEl),
    ];
  }

  static String _secondDeficit(SajuResult saju) {
    final el = saju.elements;
    final m = {
      '木': el.wood, '火': el.fire, '土': el.earth,
      '金': el.metal, '水': el.water,
    };
    // dayEl 빼고 가장 작은 거.
    final dayEl = saju.dayPillar.chunGanElement;
    m.remove(dayEl);
    return m.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  // ─────────────────────────────────────────────
  // 색
  // ─────────────────────────────────────────────
  static LuckyChip _chipColor(SajuResult saju, String el, String dayStem) {
    final v = const {
      '木': '초록색', '火': '빨강색', '土': '황금색',
      '金': '흰색', '水': '검정색',
    }[el] ?? '황금색';
    final stemKo = _stemKo[dayStem] ?? '본인 페이스의';
    final elKo = _elKo[el] ?? el;
    final subj = _subjMark(v);
    final reason =
        '본인은 $stemKo 사람이라 $elKo 기운이 살짝 부족해요. $v$subj 그걸 채워줘요. '
        '옷, 폰케이스, 액세서리 한 가지만 $v 톤으로 바꿔도 흐름이 달라져요.';
    return LuckyChip(
      category: '색',
      icon: '🎨',
      value: v,
      reasonKo: reason,
      basisEl: el,
    );
  }

  // ─────────────────────────────────────────────
  // 숫자
  // ─────────────────────────────────────────────
  static LuckyChip _chipNumber(SajuResult saju, String el) {
    final v = const {'木': 3, '火': 9, '土': 5, '金': 7, '水': 1}[el] ?? 5;
    final elKo = _elKo[el] ?? el;
    // 1·3·5·7·9 — 모두 받침 없음.
    final reason =
        '$elKo 기운이랑 짝이 잘 맞는 숫자예요. 비밀번호 끝자리, 좌석 번호, 가게 줄 번호처럼 '
        '오늘 우연히 "$v"이 보이면 그 흐름을 잡으세요.';
    return LuckyChip(
      category: '숫자',
      icon: '🔢',
      value: '$v',
      reasonKo: reason,
      basisEl: el,
    );
  }

  // ─────────────────────────────────────────────
  // 방향
  // ─────────────────────────────────────────────
  static LuckyChip _chipDirection(SajuResult saju, String el, String dayEl) {
    final v = const {
      '木': '동쪽', '火': '남쪽', '土': '북동쪽',
      '金': '서쪽', '水': '북쪽',
    }[el] ?? '북동쪽';
    final elKo = _elKo[el] ?? el;
    final reason =
        '집·방·책상에서 $elKo 기운을 받기 좋은 자리예요. 공부할 때 책상을 $v 방향으로 두고, '
        '잠시 멍 때릴 때 그쪽 창문이나 벽을 보세요. 작은 방향 한 번이 하루 흐름을 바꿔요.';
    return LuckyChip(
      category: '방향',
      icon: '🧭',
      value: v,
      reasonKo: reason,
      basisEl: el,
    );
  }

  // ─────────────────────────────────────────────
  // 음식 (한국 음식 위주)
  // ─────────────────────────────────────────────
  static LuckyChip _chipFood(
      SajuResult saju, String el, String dayEl, String dominant) {
    final v = const {
      '木': '시금치 된장국',
      '火': '매운 닭갈비',
      '土': '도가니탕',
      '金': '맑은 콩나물국',
      '水': '생선 미역국',
    }[el] ?? '도가니탕';
    final elKo = _elKo[el] ?? el;
    final domKo = _elKo[dominant] ?? dominant;
    final topic = _topicMark(v);
    final reason =
        '$domKo 기운이 강한 편이라 속을 부드럽게 풀어주는 게 잘 맞아요. $v$topic $elKo 기운을 '
        '보충해서 부족한 부분을 채워줘요. 점심이나 저녁 메뉴 고민될 때 한 번 가보세요.';
    return LuckyChip(
      category: '음식',
      icon: '🍲',
      value: v,
      reasonKo: reason,
      basisEl: el,
    );
  }

  // ─────────────────────────────────────────────
  // 사람띠 + 성씨
  // ─────────────────────────────────────────────
  static LuckyChip _chipPerson(
      SajuResult saju, ZiweiResult ziwei, String el, String dayStem) {
    final pair = const {
      '木': ('토끼띠', '김씨'),
      '火': ('말띠', '이씨'),
      '土': ('소띠', '주씨'),
      '金': ('닭띠', '박씨'),
      '水': ('돼지띠', '최씨'),
    }[el] ?? ('소띠', '주씨');
    final v = '${pair.$1} 또는 ${pair.$2}';
    final elKo = _elKo[el] ?? el;
    final stemKo = _stemKo[dayStem] ?? '본인 페이스의';
    final reason =
        '본인은 $stemKo 사람이라 $elKo 쪽이 강한 사람과 오늘 잘 통해요. '
        '${pair.$1} 친구나 ${pair.$2} 성을 가진 사람이랑 대화하면 평소보다 답답한 게 풀려요. '
        '특히 고민 상담은 그쪽이 잘 받아줘요.';
    return LuckyChip(
      category: '사람띠',
      icon: '👥',
      value: v,
      reasonKo: reason,
      basisEl: el,
    );
  }

  // ─────────────────────────────────────────────
  // 물건
  // ─────────────────────────────────────────────
  static LuckyChip _chipObject(SajuResult saju, String el, String dayEl) {
    final v = const {
      '木': '식물 화분',
      '火': '향초',
      '土': '방향제',
      '金': '금속 액세서리',
      '水': '물병',
    }[el] ?? '방향제';
    final elKo = _elKo[el] ?? el;
    final topic = _topicMark(v);
    final reason =
        '$v$topic $elKo 기운을 옆에 두는 가장 가벼운 방법이에요. 책상 한쪽이나 가방 안에 '
        '하나 두면 공간 분위기가 바뀌고, 마음도 조금 차분해져요. 큰 게 아니라도 효과 있어요.';
    return LuckyChip(
      category: '물건',
      icon: '💼',
      value: v,
      reasonKo: reason,
      basisEl: el,
    );
  }

  static const Map<String, String> _stemKo = {
    '甲': '큰 나무 같은', '乙': '여린 나무 같은',
    '丙': '태양 같은', '丁': '촛불 같은',
    '戊': '큰 산 같은', '己': '논밭 같은',
    '庚': '날카로운 쇠 같은', '辛': '섬세한 쇠 같은',
    '壬': '큰 강 같은', '癸': '이슬비 같은',
  };

  static const Map<String, String> _elKo = {
    '木': '나무', '火': '불', '土': '흙', '金': '쇠', '水': '물',
  };

  /// 한국어 조사 — 받침 유무로 '이'/'가' 선택. value 마지막 문자가 한글일 때만.
  static String _subjMark(String v) {
    if (v.isEmpty) return '이';
    final last = v.runes.last;
    // 한글 음절 범위 (가–힣)
    if (last >= 0xAC00 && last <= 0xD7A3) {
      final hasJong = (last - 0xAC00) % 28 != 0;
      return hasJong ? '이' : '가';
    }
    return '이';
  }

  /// 한국어 조사 — '은'/'는' 선택.
  static String _topicMark(String v) {
    if (v.isEmpty) return '은';
    final last = v.runes.last;
    if (last >= 0xAC00 && last <= 0xD7A3) {
      final hasJong = (last - 0xAC00) % 28 != 0;
      return hasJong ? '은' : '는';
    }
    return '은';
  }
}
