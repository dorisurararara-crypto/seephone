// Pillar Seer — R90 sprint 4 LifeOverviewService (anchor 6 다층화 rewrite).
//
// "내 사주 큰 그림" 평생 총평 generator. 일주 60 paragraph DB 직참조 아닌 anchor
// 동적 조합으로 한 단락 essay (600~900자 목표) 빌드.
//
// R89 결함 (사용자 verbatim):
//   "원래 사주는 일주로만 봐?? 내 사주가 곧 평생사주인데 왜 신묘일주만 말하지??"
//
// R90 새 anchor 6 (운세의신 사상 정합 — 일간 30 + 월령 25 + 십성 20 + 5행 20 + 격국 5):
//   1. 일간 형용 (10천간 — saju.dayPillar.chunGan)
//   2. 월령 계절 (봄/여름/가을/겨울 — saju.monthPillar.jiJi)
//   3. 5행 압도 + 공허 대조 (5×5=25 조합)
//   4. 십성 주력 (10 — 사주 8글자 빈도 1위)
//   5. 격국 (8 — 정관/편관/정인/편인/정재/편재/식신/상관/건록/양인격)
//   6. 인생 phase 마무리 (5행 dominant + 초/중/말 phase)
//
// 첫 문장 "<일주> 일주는 ~" 패턴 금지 (R89 결함).
// 본문에 한자 일주명 노출 X (한글만).
//
// idempotent — 같은 사주 → 같은 essay.

import '../models/saju_result.dart';
import 'gyeokguk_service.dart';
import 'life_category_fragment_service.dart';
import 'life_paragraph_service.dart';
import 'ten_gods_service.dart';

class LifeOverviewService {
  /// 한자 → 한글 5행 라벨.
  static const Map<String, String> _elKo = {
    '木': '나무',
    '火': '불',
    '土': '흙',
    '金': '금속',
    '水': '물',
  };

  /// 천간 한자 → 한글.
  static const Map<String, String> _stemHanToKo = {
    '甲': '갑', '乙': '을', '丙': '병', '丁': '정', '戊': '무',
    '己': '기', '庚': '경', '辛': '신', '壬': '임', '癸': '계',
  };

  /// 지지 한자 → 계절.
  static const Map<String, String> _branchSeason = {
    '寅': '봄', '卯': '봄', '辰': '봄',
    '巳': '여름', '午': '여름', '未': '여름',
    '申': '가을', '酉': '가을', '戌': '가을',
    '亥': '겨울', '子': '겨울', '丑': '겨울',
  };

  /// Anchor 1 — 일간 형용 (10천간 → 자연 형용 한 줄).
  /// "신묘 일주는 ~" prefix 금지. 첫 문장은 본인 + 일간 형용으로 시작.
  static const Map<String, String> _stemPersona = {
    '갑': '본인은 곧게 뻗어가는 나무 같은 결을 가진 사람이에요',
    '을': '본인은 부드럽게 휘어지면서도 끈기 있는 결을 가진 사람이에요',
    '병': '본인은 한낮 햇볕처럼 환하게 비추는 결을 가진 사람이에요',
    '정': '본인은 따뜻한 촛불처럼 섬세하게 챙기는 결을 가진 사람이에요',
    '무': '본인은 든든하게 자리 잡은 큰 산 같은 결을 가진 사람이에요',
    '기': '본인은 편안하게 받쳐주는 논밭 같은 결을 가진 사람이에요',
    '경': '본인은 단단한 쇠처럼 결단이 빠른 결을 가진 사람이에요',
    '신': '본인은 예리한 보석처럼 세련된 감각을 가진 사람이에요',
    '임': '본인은 넓게 흐르는 큰 강처럼 시야가 트인 사람이에요',
    '계': '본인은 깊게 스며드는 옹달샘 같은 결을 가진 사람이에요',
  };

  /// Anchor 2 — 월령 계절 (4).
  static const Map<String, String> _seasonFlavor = {
    '봄': '봄 기운이 본인 안에 또렷해서 새 시작이나 변화 자리에서 에너지가 빠르게 살아나요',
    '여름': '여름 화력이 본인 안에 또렷해서 사람 모이는 자리에서 본인 매력이 두 배로 진해져요',
    '가을': '가을 정리력이 본인 안에 또렷해서 흩어진 걸 한 데 모으는 자리에서 진가가 나와요',
    '겨울': '겨울 안정이 본인 안에 또렷해서 깊이 있는 분야에서 길게 가는 결이에요',
  };

  /// Anchor 3 — 5행 압도 + 공허 대조 (5×5 = 25 조합 — 동적 생성).
  static String _domDefContrast(String dominant, String deficit) {
    final domKo = _elKo[dominant] ?? dominant;
    final defKo = _elKo[deficit] ?? deficit;
    final domTone = _dominantTone[dominant] ?? '본인 색이 또렷한 매력이 있어요';
    final defTone = _deficitTone[deficit] ?? '한 박자 천천히 챙기면 좋아요';
    return '본인 안에서 가장 강한 결은 $domKo이라 $domTone, 가장 비어 있는 결은 $defKo이라 $defTone';
  }

  static const Map<String, String> _dominantTone = {
    '木': '추진력이 강하고 새 도전을 잘 잡아요',
    '火': '주변을 빠르게 풀어주는 매력이 진해요',
    '土': '듬직하게 자리 잡는 분위기가 자연스러워요',
    '金': '결단이 빠르고 정리하는 자리에서 빛이 나요',
    '水': '변화 많은 환경에서도 적응이 자연스러워요',
  };

  static const Map<String, String> _deficitTone = {
    '木': '새로 시작하는 추진력은 한 박자 모아두면 좋아요',
    '火': '확 펼치는 화력은 의식해서 표현을 한 번 더 보태주면 좋아요',
    '土': '뿌리 내리는 안정감은 매일 작은 루틴으로 보완하면 좋아요',
    '金': '딱 잘라 결정 내리는 힘은 마감 기한을 미리 적어두면 좋아져요',
    '水': '흘러가는 적응력은 새 환경 들어가기 전에 한 박자 쉬어주면 좋아요',
  };

  /// Anchor 4 — 십성 주력 (10).
  static const Map<String, String> _sipsinFlavor = {
    '비견': '본인 주관이 또렷해서 누가 흔들어도 본인 페이스가 잘 안 무너져요',
    '겁재': '경쟁심이 또렷한 결이라 자극받는 환경에서 본인 페이스가 더 살아나요',
    '식신': '만들어내는 결이 강해서 글, 영상, 음악 같은 표현 분야에서 빛이 잘 나요',
    '상관': '본인 표현이 또렷한 결이라 본인이 좋아하는 분야는 또래보다 한 박자 빨라요',
    '편재': '변동 큰 자리에 감각이 또렷한 사람이라 기회가 빠르게 보이는 편이에요',
    '정재': '신용 잘 쌓는 결이 진해서 본인 약속은 가까운 사람들 사이에서 신뢰가 두꺼워요',
    '편관': '압박 큰 자리에서 본인 페이스가 단단해지는 결이라 도전 자리가 본인한테 잘 맞아요',
    '정관': '원칙 지키는 자리에서 진가가 나오는 결이라 신뢰 받는 자리가 본인한테 잘 맞아요',
    '편인': '혼자 파고드는 결이 강한 사람이라 깊이 있는 분야에서 본인 색이 또렷하게 나와요',
    '정인': '배움과 안목이 단단한 결이라 새 분야 익히는 속도가 또래보다 빠른 편이에요',
  };

  /// Anchor 5 — 격국 (8 정격 + 건록/양인 + 불명 fallback).
  static const Map<String, String> _gyeokgukFlavor = {
    '정관격': '책임 의식이 또렷한 사람이라 본인이 한 약속은 끝까지 가는 결이에요',
    '편관격': '큰 결정이 필요한 자리에서 본인 결단이 한 박자 빠른 결이에요',
    '정인격': '기댈 수 있는 어른 분위기가 자연스러운 사람이라 후배들이 본인을 많이 따라요',
    '편인격': '직관이 빠른 결이라 남들이 못 보는 본인 시선이 본인 매력이에요',
    '정재격': '꾸준한 자산 잘 쌓는 결이라 매일 작은 적립 같은 흐름이 본인한테 잘 맞아요',
    '편재격': '사람 잘 만나는 결이 진해서 새 사람한테 호감을 빨리 얻는 편이에요',
    '식신격': '여유 있게 베푸는 분위기가 자연스러워서 사람들이 본인 곁에서 편안함을 자주 느껴요',
    '상관격': '창의성이 강한 결이라 본인이 좋아하는 분야는 본인 색이 또렷하게 나와요',
    '건록격': '독립심이 강한 결이라 혼자 하는 작업에서도 결과가 잘 나오는 편이에요',
    '양인격': '강한 결단이 본인 무기라 본인 페이스가 누가 흔들어도 잘 안 무너져요',
    '불명': '본인 색이 한 가지로 묶이지 않는 결이라 여러 분야를 두루 경험할수록 매력이 살아나요',
  };

  /// Anchor 6 — 인생 phase 마무리.
  static String _lifePhaseClosing(SajuResult saju) {
    final el = saju.elements;
    final wf = el.wood + el.fire;
    final eg = el.earth + el.metal;
    final w = el.water;
    if (wf >= eg && wf >= w * 2) {
      return '인생 흐름을 한 줄로 보면 초년부터 중년까지 본인 색이 빠르게 자리 잡는 시기예요. 좋아하는 분야를 일찍 정하고 그 안에서 본인 페이스를 길게 끌고 가면 후반이 자연스럽게 풍성해져요.';
    }
    if (eg >= wf && eg >= w * 2) {
      return '인생 흐름을 한 줄로 보면 중년 이후 자리가 단단하게 쌓이는 시기예요. 단기 성과보다 1년, 3년 단위 결과가 더 잘 나오는 편이라 본인 페이스를 믿고 가는 게 본인 무기예요.';
    }
    if (w * 2 > wf && w * 2 > eg) {
      return '인생 흐름을 한 줄로 보면 한 자리에 묶이지 않을 때 본인 매력이 살아나는 시기예요. 변화 자체가 본인 무기라 새 환경, 새 사람, 새 분야에 본인을 두면 본인 색이 더 또렷하게 나와요.';
    }
    return '인생 흐름을 한 줄로 보면 초년 중년 말년이 비교적 고르게 흘러서 어떤 시기든 본인 페이스를 잡고 가면 안정감이 좋아요. 한쪽으로 치우치지 않는 결이 본인 강점이에요.';
  }

  /// TenGod → 한글 키.
  static const Map<TenGod, String> _sipsinKey = {
    TenGod.bigyeon: '비견',
    TenGod.geopjae: '겁재',
    TenGod.siksin: '식신',
    TenGod.sanggwan: '상관',
    TenGod.pyeonjae: '편재',
    TenGod.jeongjae: '정재',
    TenGod.pyeongwan: '편관',
    TenGod.jeonggwan: '정관',
    TenGod.pyeonin: '편인',
    TenGod.jeongin: '정인',
  };

  /// 격국 name (예: '정관격 (正官格)') → fragment key.
  static String _gyeokgukKey(String name) {
    final idx = name.indexOf('(');
    if (idx > 0) return name.substring(0, idx).trim();
    return name.trim();
  }

  /// 사주 → 600~900자 한 단락 essay.
  ///
  /// anchor 6 다층화 — 일간 + 월령 + 5행 대조 + 십성 + 격국 + 인생 phase 결합.
  static Future<String> compose(SajuResult saju, {bool isMale = true}) async {
    final stemHan = saju.dayPillar.chunGan;
    final stemKo = _stemHanToKo[stemHan] ?? stemHan;
    final season = _branchSeason[saju.monthPillar.jiJi] ?? '봄';

    // 십성 주력 — 사주 8글자 빈도 1위 (LifeCategoryFragmentService 와 동일 룰).
    final rows = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final r in rows) {
      if (r.chunGanGod != null) freq[r.chunGanGod!] = (freq[r.chunGanGod!] ?? 0) + 1;
      if (r.jiJiGod != null) freq[r.jiJiGod!] = (freq[r.jiJiGod!] ?? 0) + 1;
    }
    TenGod topGod = TenGod.bigyeon;
    int topCount = 0;
    for (final g in TenGod.values) {
      final c = freq[g] ?? 0;
      if (c > topCount) {
        topCount = c;
        topGod = g;
      }
    }
    final sipsinKey = _sipsinKey[topGod] ?? '비견';

    // 격국.
    final gye = GyeokgukService.judge(
      dayMaster: saju.dayMaster,
      monthJi: saju.monthPillar.jiJi,
    );
    final gyeKey = _gyeokgukKey(gye.name);

    // Anchor 6 조립.
    final a1 = _stemPersona[stemKo] ?? '본인은 본인 색이 또렷한 사람이에요';
    final a2 = _seasonFlavor[season] ?? '';
    final a3 = _domDefContrast(saju.elements.dominant, saju.elements.deficit);
    final a4 = _sipsinFlavor[sipsinKey] ?? '';
    final a5 = _gyeokgukFlavor[gyeKey] ?? _gyeokgukFlavor['불명']!;
    final a6 = _lifePhaseClosing(saju);

    // Anchor 7 — gender-aware 마무리 (R88 B8 회귀 가드: 같은 사주 M/F essay 달라야 함).
    final a7 = isMale
        ? '남자 본인은 든든하면서도 따뜻한 무게가 자연스러워서 가까운 친구나 가족이 본인을 자주 의지하는 편이에요.'
        : '여자 본인은 섬세하고 또렷한 감각이 강해서 본인이 챙기는 사람들이 본인 곁에서 자주 안정감을 느끼는 편이에요.';

    // essay 조립 — 마침표로 끝나는 sentence join.
    final parts = [a1, a2, a3, a4, a5, a6, a7]
        .where((s) => s.trim().isNotEmpty)
        .map((s) {
      var t = s.trim();
      if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) t = '$t.';
      return t;
    }).toList();
    var essay = parts.join(' ');

    // 600자 미만이면 fragment 보강 (anchor 추가 — innateTendency + wealth + lateLife).
    if (essay.length < 600) {
      // anchor fragment 2개 골라 추가 (사용자 사주 다층화 효과 한 번 더).
      final fragsTen = await LifeCategoryFragmentService.fragmentsFor(
        saju: saju,
        category: LifeCategory.innateTendency,
        gender: isMale ? 'M' : 'F',
      );
      final fragsLate = await LifeCategoryFragmentService.fragmentsFor(
        saju: saju,
        category: LifeCategory.lateLife,
        gender: isMale ? 'M' : 'F',
      );
      for (final f in [...fragsTen, ...fragsLate]) {
        if (essay.length >= 700) break;
        final t = f.trim();
        if (t.isEmpty) continue;
        essay = '$essay ${t.endsWith('.') ? t : '$t.'}';
      }
    }

    // 여전히 600 미만이면 padding sentence.
    const padSentences = [
      '본인 매력은 한 가지 결로 끝나는 게 아니라 여러 결의 조합이라는 걸 기억하면 본인 페이스가 더 단단해져요.',
      '서두르지 않고 한 영역씩 챙기면 본인 사주 큰 그림이 더 또렷해져요.',
      '본인 페이스를 믿고 가면 본인 매력이 또래 사이에서 자연스럽게 두드러져요.',
    ];
    var padIdx = 0;
    while (essay.length < 600) {
      essay = '$essay ${padSentences[padIdx % padSentences.length]}';
      padIdx += 1;
      if (padIdx > 10) break;
    }

    // 900자 over 시 cap (마지막 마침표 단위로 자름).
    if (essay.length > 900) {
      final cut = essay.substring(0, 900);
      final lastSentenceEnd = cut.lastIndexOf('. ');
      essay = lastSentenceEnd > 600 ? cut.substring(0, lastSentenceEnd + 1) : cut;
    }
    return essay;
  }

  /// 카테고리 short 라벨 (sprint 5 chip nav UI 호환 — 기존 caller 보존).
  static String categoryLabel(LifeCategory cat) {
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
}
