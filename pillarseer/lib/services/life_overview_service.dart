// Pillar Seer — R88 sprint 8 LifeOverviewService.
//
// "내 사주 큰 그림" 평생 총평 generator. 일주 60 paragraph DB 직참조 아닌 anchor
// 동적 조합으로 한 단락 essay (600~900자 목표) 빌드.
//
// anchor (spec 2.2.c):
//   1. 일주 첫 인상 (60 일주 → 일간 fallback)
//   2. 5행 dominant 강점 (5 종)
//   3. 5행 deficient 약점 (5 종)
//   4. 인생 흐름 (초년/중년/말년 중 강한 phase)
//   5~9. 17 카테고리 중 강한 5 영역 한 줄씩 (early/social/personality/wealth/conclusion)
//   10. 마무리
//
// idempotent — 같은 사주 → 같은 essay.

import '../models/saju_result.dart';
import 'life_paragraph_service.dart';

class LifeOverviewService {
  /// 한자 → 한글 5행 라벨.
  static const Map<String, String> _elKo = {
    '木': '나무',
    '火': '불',
    '土': '흙',
    '金': '금속',
    '水': '물',
  };

  /// 5행 dominant 한 줄 강점 anchor.
  static const Map<String, String> _dominantStrength = {
    '木': '뻗어 나가는 결이 강해서 새 일을 시작하는 자리에 잘 어울려요',
    '火': '밝게 발산하는 결이 강해서 어딜 가도 분위기를 빠르게 풀어요',
    '土': '듬직하게 자리 잡는 결이 강해서 사람들이 본인 옆을 편하게 느껴요',
    '金': '날카롭게 정리하는 결이 강해서 빠르게 결단 내리는 자리에 어울려요',
    '水': '흐르듯 자연스러운 결이 강해서 변화 많은 환경에서 빛이 나요',
  };

  /// 5행 deficient 한 줄 약점 anchor.
  static const Map<String, String> _deficitWeakness = {
    '木': '새로 시작하는 추진력이 살짝 약한 편이라 작은 도전부터 챙겨두면 좋아요',
    '火': '확 펼치는 화력이 살짝 약한 편이라 의식적으로 표현을 더 보태주면 좋아요',
    '土': '뿌리 내리는 안정감이 살짝 약한 편이라 반복 루틴을 챙겨두면 좋아요',
    '金': '딱 잘라 결정 내리는 힘이 살짝 약한 편이라 마감 기한을 미리 적어두면 좋아요',
    '水': '흘러가는 적응력이 살짝 약한 편이라 갑작스러운 변화 전에 한 박자 쉬어주면 좋아요',
  };

  /// 인생 흐름 phase anchor (DaewoonService 의존 X — 단순 5행 기반 분기).
  static String _lifeFlow(SajuResult saju) {
    final el = saju.elements;
    // 木·火 강 → 초년 중년이 빠름. 土·金 강 → 중년 말년이 단단. 水 강 → 흐름 변화 많음.
    final wf = el.wood + el.fire;
    final eg = el.earth + el.metal;
    final w = el.water;
    if (wf >= eg && wf >= w * 2) {
      return '초년부터 중년까지 흐름이 빠르게 잡혀서, 좋아하는 분야에 일찍 자리 잡는 시기가 와요';
    }
    if (eg >= wf && eg >= w * 2) {
      return '중년부터 말년까지 자리가 단단하게 쌓여서, 오래 가는 평판으로 후반이 풍성해져요';
    }
    if (w * 2 > wf && w * 2 > eg) {
      return '변화의 흐름이 많아 보여서, 한 자리에 묶이지 않을 때 본인 매력이 살아나는 시기가 자주 와요';
    }
    return '초년 중년 말년이 비교적 고르게 흘러서, 어떤 시기든 본인 페이스를 잡고 가면 안정감이 좋아요';
  }

  /// 사주 → 600~900자 한 단락 essay.
  ///
  /// anchor 10 동적 조합 + 5행 dominant 기반 deterministic 카테고리 5 선정.
  /// 출력은 한글 only (한자 일주명 → 한글 변환).
  static Future<String> compose(SajuResult saju, {bool isMale = true}) async {
    // 한자 일주 → 한글 표기 (예: '辛卯' → '신묘'). 본문에서 한자 jargon 금지.
    final stemHan = saju.dayPillar.chunGan;
    final branchHan = saju.dayPillar.jiJi;
    final stemKo = _stemHanToKo[stemHan] ?? stemHan;
    final branchKo = _branchHanToKo[branchHan] ?? branchHan;
    final dayPillarKo = '$stemKo$branchKo'; // 예: '신묘'.

    // Anchor 1 — 일주 첫 인상 (early_life 활용). dayPillarKo 정확 매칭 → 일간 fallback.
    final firstImpression = await LifeParagraphService.paragraphStatic(
      dayPillar: dayPillarKo,
      category: LifeCategory.earlyLife,
    );
    final fallbackFirst = firstImpression.isEmpty
        ? await LifeParagraphService.paragraphStatic(
            dayPillar: stemKo,
            category: LifeCategory.earlyLife,
          )
        : firstImpression;
    final firstSentence = _firstTwoSentences(fallbackFirst);

    // Anchor 2 — 5행 dominant 강점.
    final dominant = _elKo[saju.elements.dominant] ?? saju.elements.dominant;
    final domStrength = _dominantStrength[saju.elements.dominant] ?? '';

    // Anchor 3 — 5행 deficient 약점.
    final deficit = _elKo[saju.elements.deficit] ?? saju.elements.deficit;
    final defWeakness = _deficitWeakness[saju.elements.deficit] ?? '';

    // Anchor 4 — 인생 흐름.
    final flow = _lifeFlow(saju);

    // Anchor 5~9 — 5행 dominant 별 강세 카테고리 5 (deterministic).
    final genderStr = isMale ? 'M' : 'F';
    final strongCats = _strongCategories(saju.elements.dominant);
    final anchors5to9 = <String>[];
    for (final cat in strongCats) {
      final p = await LifeParagraphService.paragraphStatic(
        dayPillar: stemKo,
        category: cat,
        gender: genderStr,
      );
      final s = _firstTwoSentences(p);
      if (s.isNotEmpty) anchors5to9.add('${_categoryLabel(cat)} — $s');
    }

    // Anchor 10 — 마무리 (5행 dominant 별 closing 분기 → 페르소나 친근 톤).
    final closing = _closing(saju.elements.dominant, isMale: isMale);

    // essay 조립 (한 단락, 공백 1칸 join).
    final parts = <String>[
      '$dayPillarKo 일주는 ${firstSentence.isEmpty ? "어딜 가도 사람들이 빠르게 본인을 알아봐 주는 결이에요" : firstSentence}.',
      '5행 중 가장 강하게 자리 잡은 결은 $dominant이고, $domStrength.',
      '반대로 가장 비어 있는 결은 $deficit이라서 $defWeakness.',
      '인생 흐름을 한 줄로 보면 $flow.',
      if (anchors5to9.isNotEmpty) anchors5to9.join(' '),
      closing,
    ];
    var essay = parts.where((s) => s.isNotEmpty).join(' ');

    // 600자 미만이면 buffer 추가 (anchor 짧으면 일반 본문 보강).
    if (essay.length < 600) {
      final extra = await _extraBuffer(stemKo, genderStr);
      essay = '$essay $extra'.trim();
    }
    // 600자 이상이 될 때까지 padding loop (hard gate 보장).
    const padSentences = [
      '내 사주 큰 그림은 이 6 가지 결을 천천히 합쳐서 본인 페이스를 잡으면 또렷해져요.',
      '서두르지 않고 한 영역씩 챙기면 자기 사주가 더 단단해져요.',
      '결국 본인 매력은 한 가지 결로 끝나는 게 아니라 여러 결의 조합이라는 걸 기억하면 좋아요.',
    ];
    var padIdx = 0;
    while (essay.length < 600) {
      essay = '$essay ${padSentences[padIdx % padSentences.length]}'.trim();
      padIdx += 1;
      if (padIdx > 10) break; // 무한 루프 방어.
    }
    // 900자 over 시 cap (spec mandate 600~900자) — 마지막 마침표 단위로 자름.
    if (essay.length > 900) {
      final cut = essay.substring(0, 900);
      final lastSentenceEnd = cut.lastIndexOf('. ');
      essay = lastSentenceEnd > 600 ? cut.substring(0, lastSentenceEnd + 1) : cut;
    }
    return essay;
  }

  /// 카테고리 short 라벨 (한글, 본문 mount 용).
  static String _categoryLabel(LifeCategory cat) {
    switch (cat) {
      case LifeCategory.social:
        return '사회';
      case LifeCategory.personality:
        return '성격';
      case LifeCategory.wealth:
        return '재물';
      case LifeCategory.loveFate:
        return '연애';
      case LifeCategory.midLife:
        return '중년';
      case LifeCategory.health:
        return '건강';
      case LifeCategory.lateLife:
        return '말년';
      case LifeCategory.earlyLife:
        return '초년';
      case LifeCategory.innateTendency:
        return '타고난 성향';
      case LifeCategory.innateCharacter:
        return '타고난 인품';
      case LifeCategory.socialPersonality:
        return '사회적 모습';
      case LifeCategory.affection:
        return '애정';
      case LifeCategory.constitution:
        return '체질';
      case LifeCategory.wealthGather:
        return '저축';
      case LifeCategory.wealthLossPrevent:
        return '지출 관리';
      case LifeCategory.wealthInvest:
        return '투자';
      case LifeCategory.conclusionSelf:
        return '한 줄 요약';
    }
  }

  /// 5행 dominant 별 강세 카테고리 5 (deterministic scoring).
  /// 木 → 시작 결단 영역. 火 → 외향 표현 영역. 土 → 안정 신뢰 영역.
  /// 金 → 정리 결단 영역. 水 → 흐름 적응 영역.
  static List<LifeCategory> _strongCategories(String dominant) {
    switch (dominant) {
      case '木':
        return const [
          LifeCategory.midLife,
          LifeCategory.social,
          LifeCategory.personality,
          LifeCategory.innateCharacter,
          LifeCategory.innateTendency,
        ];
      case '火':
        return const [
          LifeCategory.social,
          LifeCategory.personality,
          LifeCategory.loveFate,
          LifeCategory.socialPersonality,
          LifeCategory.earlyLife,
        ];
      case '土':
        return const [
          LifeCategory.midLife,
          LifeCategory.lateLife,
          LifeCategory.affection,
          LifeCategory.innateCharacter,
          LifeCategory.constitution,
        ];
      case '金':
        return const [
          LifeCategory.personality,
          LifeCategory.social,
          LifeCategory.wealth,
          LifeCategory.wealthGather,
          LifeCategory.innateCharacter,
        ];
      case '水':
        return const [
          LifeCategory.innateTendency,
          LifeCategory.social,
          LifeCategory.loveFate,
          LifeCategory.midLife,
          LifeCategory.wealthInvest,
        ];
    }
    return const [
      LifeCategory.social,
      LifeCategory.personality,
      LifeCategory.wealth,
      LifeCategory.loveFate,
      LifeCategory.midLife,
    ];
  }

  /// 5행 dominant 별 closing.
  static String _closing(String dominant, {required bool isMale}) {
    switch (dominant) {
      case '木':
        return '방향이 또렷한 사람이라 새 길을 여는 자리에 잘 어울려요. 빠른 결단을 살리되 가까운 사람 챙기는 박자만 한 번씩 잡아주면 사주 그림이 더 완성돼요.';
      case '火':
        return '주변을 빠르게 풀어주는 사람이라 모임이나 무대 자리에서 매력이 진해져요. 한 가지에 몰입할 때 잠깐 쉬어가는 박자를 챙기면 후반이 더 단단해져요.';
      case '土':
        return '듬직하게 자리 잡는 사람이라 사람들이 본인 옆을 편하게 느껴요. 작은 변화에도 부드럽게 움직이는 박자를 챙기면 후반이 더 풍성해져요.';
      case '金':
        return '딱 잘라 정리하는 사람이라 결단이 필요한 자리에서 진가가 나와요. 가까운 사람한테는 한 박자 부드럽게 말하는 습관만 챙기면 평판이 더 단단해져요.';
      case '水':
        return '흐름을 빠르게 읽는 사람이라 변화 많은 환경에서 빛이 나요. 자주 옮겨 다닐 때마다 자리 잡는 한 박자를 챙기면 후반이 더 안정돼요.';
    }
    return '본인 페이스를 믿고 가면 사주 그림이 더 또렷해져요.';
  }

  /// 600자 미만일 때 anchor 보강 — wealth_invest + late_life paragraph 합성.
  static Future<String> _extraBuffer(String stemKo, String gender) async {
    final invest = await LifeParagraphService.paragraphStatic(
      dayPillar: stemKo,
      category: LifeCategory.wealthInvest,
    );
    final late = await LifeParagraphService.paragraphStatic(
      dayPillar: stemKo,
      category: LifeCategory.lateLife,
    );
    final concl = await LifeParagraphService.paragraphStatic(
      dayPillar: stemKo,
      category: LifeCategory.conclusionSelf,
    );
    return [
      if (invest.isNotEmpty) '돈 흐름은 — ${_firstTwoSentences(invest)}',
      if (late.isNotEmpty) '말년 흐름은 — ${_firstTwoSentences(late)}',
      if (concl.isNotEmpty) _firstTwoSentences(concl),
    ].where((s) => s.isNotEmpty).join(' ');
  }

  /// 천간 한자 → 한글 매핑.
  static const Map<String, String> _stemHanToKo = {
    '甲': '갑',
    '乙': '을',
    '丙': '병',
    '丁': '정',
    '戊': '무',
    '己': '기',
    '庚': '경',
    '辛': '신',
    '壬': '임',
    '癸': '계',
  };

  /// 지지 한자 → 한글 매핑.
  static const Map<String, String> _branchHanToKo = {
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

  /// paragraph 의 첫 두 문장 추출 (~150자 한도).
  static String _firstTwoSentences(String paragraph) {
    if (paragraph.isEmpty) return '';
    // '. ' 또는 '요. ' 구분자로 두 문장 추출.
    final sentences = paragraph.split(RegExp(r'\.\s+'));
    if (sentences.length <= 1) {
      final trim = paragraph.length > 200 ? paragraph.substring(0, 200) : paragraph;
      return trim;
    }
    final two = sentences.take(2).join('. ');
    final ended = two.endsWith('.') ? two : '$two.';
    return ended.length > 250 ? ended.substring(0, 250) : ended;
  }
}
