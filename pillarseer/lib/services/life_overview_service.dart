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
import 'life_paragraph_service.dart';
import 'natural_prose_joiner.dart';
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

  /// 지지 한자 → 계절.
  static const Map<String, String> _branchSeason = {
    '寅': '봄',
    '卯': '봄',
    '辰': '봄',
    '巳': '여름',
    '午': '여름',
    '未': '여름',
    '申': '가을',
    '酉': '가을',
    '戌': '가을',
    '亥': '겨울',
    '子': '겨울',
    '丑': '겨울',
  };

  /// Anchor 1 — 일간 형용 (10천간 → my_saju_v5 메타포 톤).
  /// R108 ③ — 추상어 제거, 구체적 비유 + 강점 한 문장. 한자 노출 X (한글만).
  /// "<일주> 일주는 ~" prefix 금지. 첫 문장은 "당신은 <비유> 같은 사람이에요".
  static const Map<String, String> _stemPersona = {
    '갑': '당신은 곧게 위로 자라는 큰 나무 같은 사람이에요. 휘청거리는 어린 나무가 아니라 줄기가 굵게 잡힌 나무라, 한번 \'이쪽이다\' 정하면 그 길로 쭉 밀고 가는 힘이 있어요',
    '을': '당신은 바위틈에서도 길을 찾아 휘어 자라는 풀이나 덩굴 같은 사람이에요. 한 방향으로 우직하진 않아도, 어떤 자리에 놓여도 살아남을 길을 기어이 찾아내는 적응력이 무기예요',
    '병': '당신은 한낮의 해처럼 있는 자리를 환하게 밝히는 사람이에요. 표현이 시원시원하고 숨기는 게 없어서, 당신이 들어서면 그 자리 분위기가 금세 밝아져요',
    '정': '당신은 어두운 데를 비추는 촛불이나 등불 같은 사람이에요. 크게 떠들진 않지만 곁에 있는 사람이 뭘 필요로 하는지 빨리 알아채고 조용히 챙겨주는 따뜻함이 있어요',
    '무': '당신은 자리를 묵직하게 잡은 큰 산 같은 사람이에요. 어지간한 일에는 흔들리지 않아서, 주변 사람들이 위기일수록 당신을 \'믿고 기댈 자리\'로 여겨요',
    '기': '당신은 무엇이든 길러내는 비옥한 밭흙 같은 사람이에요. 앞에서 끌기보다 옆에서 받쳐주며 사람과 일을 부드럽게 키워서, 당신 곁에 있으면 사람이 편하다고 느껴요',
    '경': '당신은 아직 다듬지 않은 무쇠나 큰 쇳덩이 같은 사람이에요. 재고 따지기보다 \'할지 말지\'를 빠르게 정하고 바로 움직여서, 결정이 필요한 자리에서 진가가 나와요',
    '신': '당신은 잘 벼려진 칼이나 보석 같은 사람이에요. 무른 쇳덩이가 아니라 이미 모양이 잡힌 금속이라, 기준이 뚜렷하고 어지간한 압력엔 잘 안 휘어요',
    '임': '당신은 넓게 흐르는 큰 강이나 바다 같은 사람이에요. 한 군데 갇혀 있지 않고 넓게 보니까 시야가 트여 있고, 성향이 다른 사람도 큰 물처럼 다 품어내요',
    '계': '당신은 땅속으로 조용히 스며드는 이슬이나 옹달샘 같은 사람이에요. 요란하지 않게 한 분야를 깊게 파고들어서, 남들이 못 보는 결을 먼저 알아채는 눈이 있어요',
  };

  /// Anchor 2 — 월령 계절 (4 → my_saju_v5 톤).
  static const Map<String, String> _seasonFlavor = {
    '봄': '거기에 봄 기운을 받고 태어나서, 새로 시작하거나 판을 바꾸는 자리에서 에너지가 빠르게 살아나요',
    '여름': '거기에 여름 화력을 받고 태어나서, 사람이 모이는 자리에 서면 매력이 한층 더 진해져요',
    '가을': '거기에 가을 기운을 받고 태어나서, 흐트러진 걸 한자리에 모으고 매듭짓는 일에서 진가가 나와요',
    '겨울': '거기에 겨울의 차분함을 받고 태어나서, 깊이 들어가야 하는 분야에서 남보다 오래 버텨요',
  };

  /// Anchor 3 — 5행 압도 + 공허 대조 (5×5 = 25 조합 — 동적 생성, my_saju_v5 톤).
  static String _domDefContrast(String dominant, String deficit) {
    final domKo = _elKo[dominant] ?? dominant;
    final defKo = _elKo[deficit] ?? deficit;
    final domTone = _dominantTone[dominant] ?? '\'자기 색이 또렷하다\'는 인상이 따라와요';
    final defTone = _deficitTone[deficit] ?? '한 박자 천천히 챙기면 부드럽게 풀려요';
    return '여덟 글자 중에서는 $domKo 기운이 제일 진해서 $domTone. 대신 $defKo 기운이 제일 옅어서, $defTone';
  }

  static const Map<String, String> _dominantTone = {
    '木': '\'뭔가를 시작하고 키워내는 힘\'이 당신을 설명하는 큰 색이에요',
    '火': '\'환하고 표현이 분명한 사람\'이라는 인상이 늘 따라다녀요',
    '土': '\'듬직하다, 옆에 있으면 안심된다\'는 말을 자주 들었을 거예요',
    '金': '\'쟤는 줏대 있다, 자기 색이 분명하다\'는 인상이 자연스럽게 따라와요',
    '水': '\'생각이 깊고 상황을 넓게 본다\'는 게 당신의 큰 색이에요',
  };

  static const Map<String, String> _deficitTone = {
    '木': '새로 시작하는 추진력은 한 박자 모았다가 터뜨리면 더 잘 풀려요',
    '火': '확 펼치는 표현은 가끔 의식해서 한 번 더 보태주면 좋아요',
    '土': '한자리에 뿌리내리는 안정감은 작은 습관으로 천천히 채워가면 좋아요',
    '金': '딱 잘라 끊어내는 결단은 마감을 미리 적어두면 한결 수월해져요',
    '水': '낯선 자리엔 곧장 뛰어들기보다 한 박자 멈췄다 들어갈 때 부드럽게 풀려요',
  };

  /// Anchor 4 — 십성 주력 (10 → my_saju_v5 톤, 강점 + 그림자 한 쌍).
  static const Map<String, String> _sipsinFlavor = {
    '비견': '속을 보면 누가 흔들어도 본인 중심이 잘 안 무너지는 비견 기운이 두드러져요. 다만 그 단단함이 셀 땐, 도움받아도 될 자리에서까지 혼자 다 짊어지려 해요',
    '겁재': '속을 보면 경쟁하고 자극이 있는 자리에서 오히려 더 살아나는 겁재 기운이 두드러져요. 다만 그 승부욕이 가까운 사람한테까지 향하면 관계가 피곤해질 수 있어요',
    '식신': '속을 보면 무언가를 만들어내고 베푸는 식신 기운이 두드러져요. 다만 베푸는 게 익숙해서, 정작 본인이 받아야 할 몫은 자주 놓쳐요',
    '상관': '속을 보면 표현이 또렷하고 남이 못 보는 걸 먼저 짚어내는 상관 기운이 두드러져요. 다만 보이는 게 많으니 말이 그대로 나가서 \'날카롭다\'는 인상을 줄 때가 있어요',
    '편재': '속을 보면 기회와 흐름을 빨리 읽는 편재 기운이 두드러져요. 다만 눈에 보이는 기회가 많다 보니, 한 가지에 진득하게 머무는 게 늘 숙제예요',
    '정재': '속을 보면 신용을 차곡차곡 쌓는 정재 기운이 두드러져요. 다만 안정을 워낙 중히 여겨서, 한 번쯤 걸어볼 기회 앞에서도 너무 재다 타이밍을 놓쳐요',
    '편관': '속을 보면 압박이 큰 자리에서 오히려 단단해지는 편관 기운이 두드러져요. 다만 늘 본인을 긴장 상태에 두는 게 익숙해서, 쉬어도 될 때조차 스스로를 몰아세워요',
    '정관': '속을 보면 \'해야 하는 일\'을 눈앞에 두고 모른 척을 못 하는 정관 기운이 두드러져요. 다만 그 책임감이 빤히 보여서, 일을 자꾸 당신한테 미루는 사람이 생겨요',
    '편인': '속을 보면 혼자 깊게 파고드는 직관, 편인 기운이 두드러져요. 다만 혼자가 편하다 보니 사람들과 자연스럽게 섞이는 자리에서는 한 발 물러나 있게 돼요',
    '정인': '속을 보면 배우고 받아들이는 안목, 정인 기운이 두드러져요. 다만 받쳐주고 품는 게 익숙해서, 정작 본인이 도움을 청해야 할 때 입을 잘 못 떼요',
  };

  /// Anchor 5 — 격국 (8 정격 + 건록/양인 + 불명 fallback, my_saju_v5 톤).
  static const Map<String, String> _gyeokgukFlavor = {
    '정관격': '사람들 사이에서는 책임을 회피하지 않는 사람이라, 신뢰가 필요한 역할이 자연스럽게 당신한테 와요',
    '편관격': '큰 결정이 필요한 자리일수록 판단이 빨라져서, 도전적인 자리가 당신한테 잘 맞아요',
    '정인격': '기대도 되는 어른 같은 분위기가 자연스러워서, 후배나 동생들이 곧잘 당신을 따라요',
    '편인격': '남들이 못 보는 각도를 먼저 보는 직관이 빨라서, 그 시선 자체가 당신의 무기예요',
    '정재격': '한 걸음씩 꾸준히 쌓는 흐름이 잘 맞아서, 매달 조금씩 모으는 방식이 당신한텐 자연스러워요',
    '편재격': '사람을 두루 만나는 데 거리낌이 없어서, 처음 만난 사이에서도 호감을 빨리 얻어요',
    '식신격': '여유 있게 베푸는 분위기가 몸에 배어 있어서, 사람들이 당신 곁에서 편안함을 자주 느껴요',
    '상관격': '좋아하는 분야에 들어서면 또래보다 한 박자 빨라서, 거기서 당신 색이 또렷하게 나와요',
    '건록격': '혼자서도 결과를 내는 독립심이 강해서, 누가 안 봐도 본인 몫은 끝까지 해내요',
    '양인격': '큰일이 닥쳐도 본인 중심이 잘 안 무너지는 강한 결단이, 위기에서 진가를 보여요',
    '불명': '한 가지 색으로만 묶이지 않는 사람이라, 여러 분야를 두루 겪을수록 매력이 살아나요',
  };

  /// Anchor 6 — 인생 phase 마무리 (my_saju_v5 톤).
  static String _lifePhaseClosing(SajuResult saju) {
    final el = saju.elements;
    final wf = el.wood + el.fire;
    final eg = el.earth + el.metal;
    final w = el.water;
    if (wf >= eg && wf >= w * 2) {
      return '큰 그림으로 보면 어릴 때부터 본인 색이 빠르게 자리 잡는 흐름이에요. 좋아하는 분야를 일찍 정하고 그 안에서 당신답게 가면, 나이가 들수록 자연스럽게 단단해져요.';
    }
    if (eg >= wf && eg >= w * 2) {
      return '큰 그림으로 보면 빠르게 터지는 타입이 아니라, 시간이 지날수록 자리가 단단해지는 흐름이에요. 빠른 결과보다 천천히 쌓이는 모습이 더 어울리니, 조급해 말고 본인 속도를 믿어도 괜찮아요.';
    }
    if (w * 2 > wf && w * 2 > eg) {
      return '큰 그림으로 보면 한자리에 묶여 있을 때보다, 자리를 옮기고 바꿀 때 매력이 더 살아나는 흐름이에요. 변화 자체가 무기라서 새 환경, 새 사람, 새 분야에 당신을 두면 색이 더 또렷해져요.';
    }
    return '큰 그림으로 보면 어느 시기든 당신답게만 가면 안정감이 좋은 흐름이에요. 한쪽으로 치우치지 않는다는 점이 당신의 강점이에요.';
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
      if (r.chunGanGod != null) {
        freq[r.chunGanGod!] = (freq[r.chunGanGod!] ?? 0) + 1;
      }
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
        ? '남자인 당신은 듬직하면서 속이 따뜻해서, 가까운 친구나 가족이 힘들 때 가장 먼저 당신을 찾아요.'
        : '여자인 당신은 섬세하면서 감이 또렷해서, 당신이 챙기는 사람들이 곁에서 안정감을 자주 느껴요.';

    // Anchor 8 — '바탕' 마무리 (R108 ③ — my_saju_v5 closing 톤).
    const a8 = '이건 오늘 하루치 운세가 아니라, 평생 잘 안 바뀌는 당신의 \'바탕\'이에요. '
        '바탕은 못 바꿔도, 그 위에서 오늘 어떻게 움직일지는 매일 당신이 새로 고를 수 있어요.';

    // essay 조립 — 마침표로 끝나는 sentence join.
    final parts = [a1, a2, a3, a4, a5, a6, a7, a8]
        .where((s) => s.trim().isNotEmpty)
        .map((s) {
          var t = s.trim();
          if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) {
            t = '$t.';
          }
          return t;
        })
        .toList();
    var essay = NaturalProseJoiner.join(parts);

    // 600자 미만이면 padding sentence (my_saju_v5 톤 — R108 ③ 에서 '결' jargon
    // 유발하던 fragment 보강 block 제거. anchor 8 합산만으로 통상 ≥700자).
    const padSentences = [
      '한 가지 면만 보고 당신을 묶지 말고, 강점도 그림자도 같이 데리고 가면 훨씬 당신다워요.',
      '오늘 하루는 못 바꿔도, 그 하루가 어느 쪽으로 쌓일지는 당신이 정할 수 있어요.',
      '서두르지 말고 한 영역씩 챙기면, 당신의 큰 그림이 한결 또렷해져요.',
    ];
    var padIdx = 0;
    while (essay.length < 600) {
      essay = NaturalProseJoiner.append(essay, [
        padSentences[padIdx % padSentences.length],
      ]);
      padIdx += 1;
      if (padIdx > 10) break;
    }

    // 900자 over 시 cap (마지막 마침표 단위로 자름).
    if (essay.length > 900) {
      final cut = essay.substring(0, 900);
      final lastSentenceEnd = cut.lastIndexOf('. ');
      essay = lastSentenceEnd > 600
          ? cut.substring(0, lastSentenceEnd + 1)
          : cut;
    }
    return essay;
  }

  // ──────────── R106 P5 — 영어 모드 anchor (English-only 추가, 한국어 schema 불변) ────────────
  //
  // 영어 본문은 한국어 essay 와 동일한 anchor 6 구조를 영어 carrier 로 재구성한다.
  // 별도 1MB JSON 없이 service 안에서 영어 carrier 를 빌드 — 한국어 필드/id 변경 0.
  // v5 voice: 단정 금지(tends to / can / often), 메타 금지(chart/saju 노출 X),
  // 자연 구어 영어(번역체·헤드라인체 금지).

  /// 5행 한자 → 영어 자연 라벨.
  static const Map<String, String> _elEn = {
    '木': 'wood',
    '火': 'fire',
    '土': 'earth',
    '金': 'metal',
    '水': 'water',
  };

  /// Anchor 1 (En) — 일간 형용 (R108 ③ — my_saju_v5 메타포 톤).
  static const Map<String, String> _stemPersonaEn = {
    '갑': 'You tend to grow like a tall, upright tree — not a swaying sapling but one with a thick, settled trunk, so once you decide "this is the way," you can push down that path without wavering',
    '을': 'You tend to grow like a vine that finds a way through any crack in the rock — not stubbornly fixed to one direction, but able to find a way to survive wherever life sets you down, and that adaptability is a real strength',
    '병': 'You tend to light up a room the way the midday sun does — your expression is open and you hide little, so the mood often lifts the moment you walk in',
    '정': 'You tend to look after people the way a candle lights a dark corner — you make no noise, but you quickly catch what the person beside you needs and quietly take care of it',
    '무': 'You tend to hold your ground like a wide mountain — most things do not rattle you, so the people around you often treat you as a place to lean on, especially in a crisis',
    '기': 'You tend to nurture people and work the way rich soil grows a garden — you support from beside rather than pull from the front, so people often feel at ease near you',
    '경': 'You tend to move like raw, unworked iron — rather than weighing things endlessly, you decide "yes or no" fast and act, so you show your real worth wherever a decision is needed',
    '신': 'You tend to be like a well-honed blade or a cut jewel — not soft metal but already a shaped one, so your standards are clear and you rarely bend under ordinary pressure',
    '임': 'You tend to flow like a wide river or the open sea — you are not boxed into one spot, so your view stays broad and you can take in people quite different from yourself',
    '계': 'You tend to seep in quietly like dew or a spring soaking into the ground — without any fuss you can dig deep into one field, and you often notice a texture that others miss',
  };

  /// Anchor 2 (En) — 월령 계절.
  static const Map<String, String> _seasonFlavorEn = {
    '봄': 'Born under spring energy, you often come most alive where something is just starting or where the board is being reshaped',
    '여름': 'Born under summer warmth, your charm tends to deepen further whenever you stand in a lively, crowded place',
    '가을': 'Born under autumn\'s sense of order, you tend to show your real worth wherever scattered things need gathering and tying off',
    '겨울': 'Born under winter\'s calm, you can stay with a deep subject far longer than most people',
  };

  /// Anchor 3 (En) — 5행 압도/공허 대조.
  static String _domDefContrastEn(String dominant, String deficit) {
    final domEn = _elEn[dominant] ?? dominant;
    final defEn = _elEn[deficit] ?? deficit;
    final domTone = _dominantToneEn[dominant] ?? 'a clear personal colour tends to come through';
    final defTone = _deficitToneEn[deficit] ?? 'it can help to slow a half-step there';
    return 'Of your eight characters, the strongest current is $domEn, so $domTone. '
        'The lightest is $defEn, so $defTone';
  }

  static const Map<String, String> _dominantToneEn = {
    '木': 'a knack for starting things and growing them is the big colour that explains you',
    '火': 'an impression of being bright and openly expressive tends to follow you around',
    '土': 'people have often told you that you feel steady and reassuring to be near',
    '金': 'an impression of having a clear backbone and a defined character comes naturally',
    '水': 'thinking deeply and reading the wider situation tends to be your big colour',
  };

  static const Map<String, String> _deficitToneEn = {
    '木': 'the drive to start something brand new tends to land better when you gather it first, then release',
    '火': 'open self-expression is worth adding on purpose now and then',
    '土': 'a rooted, settled feeling tends to grow best through small daily habits',
    '金': 'a clean, decisive cut comes easier when you note your deadlines in advance',
    '水': 'rather than diving straight into unfamiliar places, you often settle in more smoothly after a short pause',
  };

  /// Anchor 4 (En) — 십성 주력 (강점 + 그림자 한 쌍).
  static const Map<String, String> _sipsinFlavorEn = {
    '비견': 'Inside, a firm-centre quality stands out — you tend not to wobble even when others push. The shadow comes with it: when that firmness runs strong, you can try to carry everything alone even where help is offered',
    '겁재': 'Inside, a quality that comes alive in competitive, stimulating places stands out. The shadow comes with it: when that drive turns toward people close to you, the relationship can grow tiring',
    '식신': 'Inside, an instinct for making things and for giving stands out. The shadow comes with it: giving is so familiar that you can often miss the share you yourself should receive',
    '상관': 'Inside, a quality of vivid expression — catching what others miss — stands out. The shadow comes with it: because you see so much, your words can come out plainly and leave an impression of being sharp',
    '편재': 'Inside, a quick read of opportunity and flow stands out. The shadow comes with it: with so many visible chances, staying put with one thing can be a constant piece of homework',
    '정재': 'Inside, a quality of building trust steadily stands out. The shadow comes with it: you value stability so much that you can over-weigh a worthwhile chance and miss the timing',
    '편관': 'Inside, a quality that grows steadier under heavy pressure stands out. The shadow comes with it: keeping yourself on alert is so familiar that you can drive yourself even when it is fine to rest',
    '정관': 'Inside, a quality that cannot look away from "what needs doing" stands out. The shadow comes with it: that sense of responsibility is so visible that some people keep handing their work to you',
    '편인': 'Inside, an intuition for digging in alone stands out. The shadow comes with it: because solitude feels comfortable, you can step back where people mix naturally',
    '정인': 'Inside, an eye for learning and taking things in stands out. The shadow comes with it: supporting and holding others is so familiar that you can struggle to ask for help when you need it',
  };

  /// Anchor 5 (En) — 격국 (격국 한국어 key → 영어 carrier).
  static const Map<String, String> _gyeokgukFlavorEn = {
    '정관격': 'Among people, you tend to be someone who does not dodge responsibility, so roles that need trust come to you naturally',
    '편관격': 'The bigger the call that is needed, the faster your judgement tends to get, so demanding settings can suit you well',
    '정인격': 'A dependable, grown-up presence comes naturally, so juniors and younger friends often look up to you',
    '편인격': 'Your intuition for seeing an angle others miss tends to be quick, and that way of seeing is itself a strength',
    '정재격': 'A steady, step-by-step build suits you, so setting a little aside each month tends to feel natural',
    '편재격': 'You meet people easily with no hesitation, so even at a first meeting you tend to win warmth fast',
    '식신격': 'An easy, generous warmth is part of you, so people often feel relaxed beside you',
    '상관격': 'In a field you love you tend to move a beat ahead of your peers, and your colour shows clearly there',
    '건록격': 'A strong independent streak means you tend to finish your share even when no one is watching',
    '양인격': 'A firm decisiveness that holds its centre even in big moments tends to show its worth in a crisis',
    '불명': 'You do not fold into one single colour, so the more varied the fields you experience, the more your charm comes alive',
  };

  /// Anchor 6 (En) — 인생 phase 마무리.
  static String _lifePhaseClosingEn(SajuResult saju) {
    final el = saju.elements;
    final wf = el.wood + el.fire;
    final eg = el.earth + el.metal;
    final w = el.water;
    if (wf >= eg && wf >= w * 2) {
      return 'Looking at the big picture, your own colour tends to settle in early. '
          'If you choose a field you love sooner rather than later and stay true to it, '
          'you can grow naturally solid as the years go on.';
    }
    if (eg >= wf && eg >= w * 2) {
      return 'Looking at the big picture, you are not the type to flare up fast — your footing tends to grow firmer over time. '
          'A slow, accumulating arc suits you more than quick results, so it is fine not to rush and to trust your own pace.';
    }
    if (w * 2 > wf && w * 2 > eg) {
      return 'Looking at the big picture, your charm tends to come alive more when you move and change place than when you stay fixed. '
          'Change itself is a strength for you, so new settings, new people, and new fields bring out your colour.';
    }
    return 'Looking at the big picture, you can feel steady in any season as long as you stay true to yourself. '
        'Not leaning too far in one direction is one of your strengths.';
  }

  /// 사주 → 영어 한 단락 essay (한국어 compose 와 동일 anchor 6 구조).
  ///
  /// R106 P5 — 영어 모드 LIFE OVERVIEW 본문. placeholder 제거.
  static Future<String> composeEn(SajuResult saju, {bool isMale = true}) async {
    final stemHan = saju.dayPillar.chunGan;
    final stemKo = _stemHanToKo[stemHan] ?? stemHan;
    final season = _branchSeason[saju.monthPillar.jiJi] ?? '봄';

    final rows = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final r in rows) {
      if (r.chunGanGod != null) {
        freq[r.chunGanGod!] = (freq[r.chunGanGod!] ?? 0) + 1;
      }
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

    final gye = GyeokgukService.judge(
      dayMaster: saju.dayMaster,
      monthJi: saju.monthPillar.jiJi,
    );
    final gyeKey = _gyeokgukKey(gye.name);

    final a1 = _stemPersonaEn[stemKo] ??
        'You tend to carry a clear personal colour';
    final a2 = _seasonFlavorEn[season] ?? '';
    final a3 = _domDefContrastEn(saju.elements.dominant, saju.elements.deficit);
    final a4 = _sipsinFlavorEn[sipsinKey] ?? '';
    final a5 = _gyeokgukFlavorEn[gyeKey] ?? _gyeokgukFlavorEn['불명']!;
    final a6 = _lifePhaseClosingEn(saju);
    final a7 = isMale
        ? 'As a man, you tend to be dependable yet warm inside, so when things get hard your close '
            'friends and family often turn to you first.'
        : 'As a woman, you tend to be delicate yet clear in your read, so the people you look after '
            'often feel steady beside you.';

    // Anchor 8 (En) — '바탕' 마무리 (R108 ③).
    const a8 = 'This is not about a single day — it is your base, the part of you that barely shifts '
        'across a lifetime. The base does not change, but how you move on top of it is yours to '
        'choose, fresh, every day.';

    final parts = [a1, a2, a3, a4, a5, a6, a7, a8]
        .where((s) => s.trim().isNotEmpty)
        .map((s) {
          var t = s.trim();
          if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) {
            t = '$t.';
          }
          return t;
        })
        .toList();
    return parts.join(' ');
  }

  /// 카테고리 영어 본문 (17 카테고리, 일간 무관 generic).
  /// R107 부터 일주별 개인화가 mandate — 가능하면 `categoryBodyEnFor` 사용.
  /// 이 method 는 R106 호환·일간 unknown fallback 용으로 보존.
  static String categoryBodyEn(LifeCategory cat) =>
      LifeParagraphService.categoryBodyEn(cat);

  /// R107 — 카테고리 영어 본문 (일간별 개인화).
  /// 사용자 사주의 일간으로 170 맵에서 lookup. life_paragraph_service delegate.
  static String categoryBodyEnFor(SajuResult saju, LifeCategory cat) =>
      LifeParagraphService.categoryBodyEnFor(saju, cat);

  /// JSON key → 영어 카테고리 제목 (chip nav + section card 공용).
  static String categoryTitleEn(String key) => lifeCategoryTitleEn(key);

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
