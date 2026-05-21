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

  /// Anchor 1 — 일간 형용 (10천간 → 자연 형용 한 줄).
  /// "신묘 일주는 ~" prefix 금지. 첫 문장은 본인 + 일간 형용으로 시작.
  /// R90 sprint 6 round 2 — "결" 남발 회피.
  static const Map<String, String> _stemPersona = {
    '갑': '본인은 곧게 뻗어가는 큰 나무 같은 사람이에요',
    '을': '본인은 부드럽게 휘어지면서도 끈질긴 풀 같은 사람이에요',
    '병': '본인은 한낮 햇볕처럼 환하게 비추는 사람이에요',
    '정': '본인은 따뜻한 촛불처럼 섬세하게 챙기는 사람이에요',
    '무': '본인은 든든하게 자리 잡은 큰 산 같은 사람이에요',
    '기': '본인은 편안하게 받쳐주는 비옥한 땅 같은 사람이에요',
    '경': '본인은 단단한 쇠처럼 결단이 빠른 사람이에요',
    '신': '본인은 예리한 보석처럼 세련된 감각을 가진 사람이에요',
    '임': '본인은 넓게 흐르는 큰 강처럼 시야가 트인 사람이에요',
    '계': '본인은 깊게 스며드는 옹달샘 같은 사람이에요',
  };

  /// Anchor 2 — 월령 계절 (4).
  /// R90 sprint 6 round 2 — "본인 안에" 반복 회피.
  static const Map<String, String> _seasonFlavor = {
    '봄': '봄 기운을 받고 태어나서 새 시작이나 변화 자리에서 에너지가 빠르게 살아나요',
    '여름': '여름 화력을 받고 태어나서 사람 모이는 자리에서 매력이 한층 더 진해져요',
    '가을': '가을 정리력을 받고 태어나서 흩어진 걸 한 데 모으는 자리에서 진가가 나와요',
    '겨울': '겨울 안정을 받고 태어나서 깊이 있는 분야에서 오래 가는 편이에요',
  };

  /// Anchor 3 — 5행 압도 + 공허 대조 (5×5 = 25 조합 — 동적 생성).
  /// R90 sprint 6 round 2 — "본인 안에서 가장 강한 결" → "사주에서 가장 진한 색".
  static String _domDefContrast(String dominant, String deficit) {
    final domKo = _elKo[dominant] ?? dominant;
    final defKo = _elKo[deficit] ?? deficit;
    final domTone = _dominantTone[dominant] ?? '본인 색이 또렷한 매력이 있어요';
    final defTone = _deficitTone[deficit] ?? '한 박자 천천히 챙기면 좋아요';
    return '사주에서 가장 진한 색은 $domKo이고 $domTone. 반대로 가장 옅은 색은 $defKo이라 $defTone';
  }

  static const Map<String, String> _dominantTone = {
    '木': '추진력이 강해서 새 도전을 잘 잡아요',
    '火': '주변 분위기를 빠르게 풀어주는 매력이 진해요',
    '土': '듬직한 분위기가 자연스러워서 친구들이 본인 옆을 편하게 느껴요',
    '金': '결단이 빠르고 정리하는 자리에서 빛이 나요',
    '水': '변화 많은 환경에서도 적응이 자연스러워요',
  };

  static const Map<String, String> _deficitTone = {
    '木': '새로 시작하는 추진력은 한 박자 모아두면 좋아요',
    '火': '확 펼치는 표현은 의식해서 한 번 더 보태주면 좋아요',
    '土': '뿌리 내리는 안정감은 매일 작은 습관으로 보완하면 좋아요',
    '金': '딱 잘라 결정 내리는 힘은 마감을 미리 적어두면 자연스러워져요',
    '水': '낯선 환경 적응력은 한 박자 쉬고 들어가면 부드러워져요',
  };

  /// Anchor 4 — 십성 주력 (10).
  /// R90 sprint 6 round 2 — "본인 페이스" 반복 회피, MZ 톤 강화.
  static const Map<String, String> _sipsinFlavor = {
    '비견': '주관이 단단해서 누가 흔들어도 본인 중심이 잘 안 무너져요',
    '겁재': '경쟁심이 또렷해서 자극받는 환경에서 본인 매력이 더 살아나요',
    '식신': '만들어내는 감각이 강해서 글이나 영상, 음악 쪽에서 빛이 잘 나요',
    '상관': '표현이 또렷해서 좋아하는 분야에서는 또래보다 한 박자 빠른 편이에요',
    '편재': '기회 잘 보는 감각이 또렷해서 변동 많은 자리에서도 본인 자리를 빠르게 잡아요',
    '정재': '신용 잘 쌓는 분위기가 진해서 본인 약속은 친구들 사이에서 신뢰가 두꺼워요',
    '편관': '압박 큰 자리에서 오히려 단단해지는 편이라 도전 자리가 본인한테 잘 맞아요',
    '정관': '원칙 지키는 자리에서 진가가 나와서 신뢰 받는 역할이 본인한테 잘 맞아요',
    '편인': '혼자 파고드는 힘이 강해서 깊이 있는 분야에서 본인 색이 또렷하게 나와요',
    '정인': '배움과 안목이 단단해서 새 분야 익히는 속도가 또래보다 빠른 편이에요',
  };

  /// Anchor 5 — 격국 (8 정격 + 건록/양인 + 불명 fallback).
  /// R90 sprint 6 round 2 — "결" / "본인 페이스" 반복 회피.
  static const Map<String, String> _gyeokgukFlavor = {
    '정관격': '책임 의식이 또렷해서 한 번 한 약속은 끝까지 지키는 편이에요',
    '편관격': '큰 결정이 필요한 자리에서 본인 판단이 한 박자 빠른 편이에요',
    '정인격': '기댈 수 있는 어른 분위기가 자연스러워서 후배들이 본인을 많이 따라요',
    '편인격': '직관이 빠른 편이라 남들이 못 보는 본인 시선이 무기예요',
    '정재격': '꾸준한 적립이 잘 맞아서 매달 조금씩 모으는 흐름이 본인한테 자연스러워요',
    '편재격': '사람 잘 만나는 분위기가 진해서 새 친구한테 호감을 빨리 얻는 편이에요',
    '식신격': '여유 있게 베푸는 분위기가 자연스러워서 사람들이 본인 곁에서 편안함을 자주 느껴요',
    '상관격': '창의성이 강해서 좋아하는 분야에서 본인 색이 또렷하게 나와요',
    '건록격': '독립심이 강해서 혼자 하는 작업에서도 결과가 잘 나오는 편이에요',
    '양인격': '강한 결단이 무기라 큰 일이 닥쳐도 본인 중심이 잘 안 무너져요',
    '불명': '본인 색이 한 가지로 묶이지 않아서 여러 분야를 두루 경험할수록 매력이 살아나요',
  };

  /// Anchor 6 — 인생 phase 마무리.
  /// R90 sprint 6 round 2 — "인생 흐름을 한 줄로 보면" → "큰 그림으로 보면". MZ 톤 강화.
  static String _lifePhaseClosing(SajuResult saju) {
    final el = saju.elements;
    final wf = el.wood + el.fire;
    final eg = el.earth + el.metal;
    final w = el.water;
    if (wf >= eg && wf >= w * 2) {
      return '큰 그림으로 보면 어릴 때부터 본인 색이 빠르게 자리 잡는 편이에요. 좋아하는 분야를 일찍 정하고 그 안에서 본인답게 가면 어른이 됐을 때 자연스럽게 단단해져요.';
    }
    if (eg >= wf && eg >= w * 2) {
      return '큰 그림으로 보면 시간이 지날수록 자리가 단단해지는 편이에요. 빠른 결과보다 천천히 쌓이는 모습이 더 어울리니까 본인 속도를 믿고 가도 괜찮아요.';
    }
    if (w * 2 > wf && w * 2 > eg) {
      return '큰 그림으로 보면 한 자리에 묶이지 않을 때 본인 매력이 더 살아나요. 변화 자체가 무기라서 새 환경, 새 사람, 새 분야에 본인을 두면 본인 색이 더 또렷해져요.';
    }
    return '큰 그림으로 보면 어느 시기든 본인답게 가면 안정감이 좋은 편이에요. 한쪽으로 치우치지 않는 점이 본인 강점이에요.';
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
        ? '남자 본인은 든든하면서도 따뜻한 분위기가 자연스러워서 가까운 친구나 가족이 본인을 자주 의지해요.'
        : '여자 본인은 섬세하고 또렷한 감각이 강해서 본인이 챙기는 사람들이 본인 옆에서 안정감을 자주 느껴요.';

    // essay 조립 — 마침표로 끝나는 sentence join.
    final parts = [a1, a2, a3, a4, a5, a6, a7]
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

    // 600자 미만이면 fragment 보강 (anchor 추가 — innateTendency + lateLife).
    // 중복 방지: essay 안에 이미 있는 fragment 는 추가 X.
    if (essay.length < 600) {
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
      final seen = <String>{};
      for (final f in [...fragsTen, ...fragsLate]) {
        if (essay.length >= 700) break;
        final t = f.trim();
        if (t.isEmpty || seen.contains(t)) continue;
        // essay 본문에 이미 동일 fragment 들어있으면 skip.
        if (essay.contains(t)) {
          seen.add(t);
          continue;
        }
        seen.add(t);
        essay = NaturalProseJoiner.append(essay, [t]);
      }
    }

    // 여전히 600 미만이면 padding sentence.
    const padSentences = [
      '한 가지 색으로만 본인을 묶지 말고 여러 면을 다 살리면 본인답게 자연스러워요.',
      '서두르지 않고 한 영역씩 챙기면 본인 사주 큰 그림이 더 또렷해져요.',
      '본인 속도를 믿고 가면 또래 사이에서 자연스럽게 본인 자리가 정해져요.',
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

  /// Anchor 1 (En) — 일간 형용.
  static const Map<String, String> _stemPersonaEn = {
    '갑': 'You tend to move like a tall, upright tree — you set a direction and grow toward it steadily',
    '을': 'You tend to bend without breaking, like a supple plant that keeps its grip through any weather',
    '병': 'You tend to light up a room the way midday sun does — warm, open, and easy to be around',
    '정': 'You tend to look after people with a quiet, candle-like warmth, noticing the small things',
    '무': 'You tend to feel grounded and dependable, like a wide mountain that does not get rattled easily',
    '기': 'You tend to support the people near you the way rich soil holds a garden — calm and giving',
    '경': 'You tend to decide fast and cleanly, with a clear edge once you have made up your mind',
    '신': 'You tend to have a refined, precise eye, picking up on details others move straight past',
    '임': 'You tend to read situations from a wide angle, like a broad river that sees the whole landscape',
    '계': 'You tend to take things in deeply and quietly, the way a spring seeps into everything around it',
  };

  /// Anchor 2 (En) — 월령 계절.
  static const Map<String, String> _seasonFlavorEn = {
    '봄': 'Born under spring energy, you often come alive fastest where something is just beginning or changing',
    '여름': 'Born under summer warmth, your charm tends to deepen in lively places where people gather',
    '가을': 'Born under autumn\'s sense of order, you tend to shine wherever scattered things need pulling together',
    '겨울': 'Born under winter\'s steadiness, you can stay with a deep subject far longer than most people',
  };

  /// Anchor 3 (En) — 5행 압도/공허 대조.
  static String _domDefContrastEn(String dominant, String deficit) {
    final domEn = _elEn[dominant] ?? dominant;
    final defEn = _elEn[deficit] ?? deficit;
    final domTone = _dominantToneEn[dominant] ?? 'a clear personal signature comes through';
    final defTone = _deficitToneEn[deficit] ?? 'it can help to slow down a half-step there';
    return 'The strongest colour running through you is $domEn, so $domTone. '
        'The lightest one is $defEn, so $defTone';
  }

  static const Map<String, String> _dominantToneEn = {
    '木': 'you tend to have real drive and pick up new challenges easily',
    '火': 'you can warm up the mood around you faster than most',
    '土': 'a steady, reassuring presence comes naturally and people feel at ease beside you',
    '金': 'you tend to decide quickly and do well wherever things need tidying up',
    '水': 'you tend to adapt comfortably even when the environment keeps shifting',
  };

  static const Map<String, String> _deficitToneEn = {
    '木': 'the drive to start something brand new can use a little gathering first',
    '火': 'open self-expression is worth adding on purpose now and then',
    '土': 'a sense of being rooted can grow through small daily habits',
    '金': 'sharp, clean decisions come easier when deadlines are noted in advance',
    '水': 'adapting to unfamiliar settings feels smoother after a short pause',
  };

  /// Anchor 4 (En) — 십성 주력.
  static const Map<String, String> _sipsinFlavorEn = {
    '비견': 'Your sense of self runs firm, so you tend not to wobble even when others push',
    '겁재': 'A clear competitive streak means your spark can show more in lively, challenging settings',
    '식신': 'You have a strong making instinct, so writing, video, or music can be where you shine',
    '상관': 'Your expression is vivid, so in a field you love you can move a beat faster than your peers',
    '편재': 'You read opportunity well, so you tend to find your footing fast even where things keep changing',
    '정재': 'You build trust steadily, so a promise from you tends to carry real weight with friends',
    '편관': 'You can grow steadier under pressure, so demanding situations often suit you',
    '정관': 'You shine where principles are kept, so a role built on trust tends to fit you well',
    '편인': 'You have a strong instinct for digging in alone, so deep subjects can really suit you',
    '정인': 'Learning and good judgement run deep, so you can pick up new fields faster than most',
  };

  /// Anchor 5 (En) — 격국 (격국 한국어 key → 영어 carrier).
  static const Map<String, String> _gyeokgukFlavorEn = {
    '정관격': 'A clear sense of responsibility means a promise once made tends to be kept to the end',
    '편관격': 'Where a big call is needed, your judgement can land a beat ahead of others',
    '정인격': 'You can carry a steady, mentor-like presence, so people often look up to you',
    '편인격': 'Your intuition tends to be quick, and a way of seeing things others miss is a real strength',
    '정재격': 'Steady saving suits you, so setting a little aside each month feels natural',
    '편재격': 'You meet people easily, so new acquaintances tend to warm to you quickly',
    '식신격': 'A generous, easygoing warmth comes naturally, and people feel relaxed around you',
    '상관격': 'Creativity runs strong, so your personal colour shows clearly in a field you love',
    '건록격': 'A strong independent streak means solo work can still turn out well for you',
    '양인격': 'A firm, decisive nature is a real strength, so you tend to hold your centre even in big moments',
    '불명': 'Your character does not fold into one type, so the more varied your experience, the more your charm shows',
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
      return 'Looking at the big picture, your footing tends to grow firmer over time. '
          'A slow, accumulating arc suits you more than fast results, so it is fine to trust your own pace.';
    }
    if (w * 2 > wf && w * 2 > eg) {
      return 'Looking at the big picture, your charm tends to come alive when you are not tied to one spot. '
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
        ? 'As a man, a steady and warm presence comes naturally to you, so close friends and family '
            'often find themselves leaning on you.'
        : 'As a woman, a sharp and caring instinct runs strong, so the people you look after tend to '
            'feel safe beside you.';

    final parts = [a1, a2, a3, a4, a5, a6, a7]
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

  /// 카테고리 영어 본문 (17 카테고리). life_paragraph_service 의 공용 carrier 사용.
  static String categoryBodyEn(LifeCategory cat) =>
      LifeParagraphService.categoryBodyEn(cat);

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
