// Pillar Seer — 60일주 deep content 로더.
// 8섹션 × ko/en 콘텐츠 + 대운/세운 procedural 보강.
//
// JSON 소스: assets/data/saju_deep_slice_0_19.json, 20_39.json, 40_59.json
// 누락된 슬라이스가 있어도 fallback 으로 동작.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/saju_result.dart';
import 'solar_term_service.dart';

class DeepContentService {
  static Map<String, Map<String, dynamic>>? _enCache;
  static Map<String, Map<String, dynamic>>? _koCache;
  static bool _loaded = false;

  /// codex 가 생성한 60일주 ko 본문에 "Wood Pig", "Metal Rabbit" 같은 영문 페어가
  /// 섞여 있는 경우를 한국어 모드에서 제거 (사용자 실기 피드백).
  static const _elNames = ['Wood', 'Fire', 'Earth', 'Metal', 'Water'];
  static const _animNames = [
    'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake',
    'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig'
  ];

  static String _sanitizeKo(String text) {
    var t = text;
    for (final el in _elNames) {
      for (final an in _animNames) {
        t = t.replaceAll(' $el $an', '').replaceAll('$el $an ', '');
      }
    }
    // 남은 단독 영문 element/animal 도 (단독 단어 단위) 제거
    for (final el in _elNames) {
      t = t.replaceAll(RegExp(r'(?<!\w)' + el + r'(?!\w)'), '');
    }
    for (final an in _animNames) {
      t = t.replaceAll(RegExp(r'(?<!\w)' + an + r'(?!\w)'), '');
    }
    // Round 77 sprint 2 — 영문 element/animal strip 후 남은 빈 괄호 ` ( )` / `()` 제거.
    t = t.replaceAll(RegExp(r'\(\s*\)'), '');
    // 연속 공백 정리 + "는" "이" 앞 공백 정리
    return t.replaceAll(RegExp(r'\s+'), ' ').replaceAll(' ,', ',').trim();
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final en = <String, Map<String, dynamic>>{};
    final ko = <String, Map<String, dynamic>>{};
    const slices = [
      'assets/data/saju_deep_slice_0_19.json',
      'assets/data/saju_deep_slice_20_39.json',
      'assets/data/saju_deep_slice_40_59.json',
    ];
    for (final path in slices) {
      try {
        final raw = await rootBundle.loadString(path);
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        for (final entry in list) {
          final ji = entry['ji60'] as String?;
          if (ji == null) continue;
          if (entry['en'] is Map) {
            en[ji] = (entry['en'] as Map).cast<String, dynamic>();
          }
          if (entry['ko'] is Map) {
            ko[ji] = (entry['ko'] as Map).cast<String, dynamic>();
          }
        }
      } catch (_) {
        // missing slice OK, fallback will cover
      }
    }
    _enCache = en;
    _koCache = ko;
    _loaded = true;
  }

  /// 8섹션 풀이 (en + ko) 빌드. 대운/세운/Lucky 는 procedural 추가.
  /// [allStems] = 년/월/일/시 4 천간 (시 없으면 3). 십신 음양 10분류용.
  static Future<({DeepReading en, DeepReading ko})> buildFor({
    required String day60ji,
    required String dayMaster,
    required String dayMasterName,
    required String currentYearGanji,
    required int userAge,
    required String dominantElement,
    required String deficitElement,
    required Map<String, String> shortReadings,
    List<String> allStems = const [],
  }) async {
    await _ensureLoaded();
    final enRaw = _enCache?[day60ji];
    final koRaw = _koCache?[day60ji];

    final en = _buildLang(
      lang: 'en',
      day60ji: day60ji,
      dayMaster: dayMaster,
      name: dayMasterName,
      raw: enRaw,
      shortReadings: shortReadings,
      currentYearGanji: currentYearGanji,
      userAge: userAge,
      dominant: dominantElement,
      deficit: deficitElement,
      allStems: allStems,
    );
    final ko = _buildLang(
      lang: 'ko',
      day60ji: day60ji,
      dayMaster: dayMaster,
      name: dayMasterName,
      raw: koRaw,
      shortReadings: shortReadings,
      currentYearGanji: currentYearGanji,
      userAge: userAge,
      dominant: dominantElement,
      deficit: deficitElement,
      allStems: allStems,
    );
    return (en: en, ko: ko);
  }

  static DeepReading _buildLang({
    required String lang,
    required String day60ji,
    required String dayMaster,
    required String name,
    required Map<String, dynamic>? raw,
    required Map<String, String> shortReadings,
    required String currentYearGanji,
    required int userAge,
    required String dominant,
    required String deficit,
    List<String> allStems = const [],
  }) {
    final isKo = lang == 'ko';
    String pickField(String key, String fallback) {
      final v = (raw?[key] as String?) ?? fallback;
      return isKo ? _sanitizeKo(v) : v;
    }
    final dmDeep = pickField('dayMasterDeep', _fallbackDayMasterDeep(isKo, day60ji, name));
    final career = pickField('career',
        _expandShort(shortReadings['career'] ?? '', isKo, 'career', day60ji));
    final wealth = pickField('wealth',
        _expandShort(shortReadings['money'] ?? '', isKo, 'wealth', day60ji));
    final love = pickField('love',
        _expandShort(shortReadings['love'] ?? '', isKo, 'love', day60ji));
    final health = pickField('health', _fallbackHealth(isKo, day60ji, deficit));
    final family = pickField('family', _fallbackFamily(isKo, day60ji));
    final fame = pickField('fame', _fallbackFame(isKo, day60ji, name));
    final luckyColor = raw?['luckyColor'] as String? ??
        _luckyColorFor(isKo, dominant);
    final luckyNumber = (raw?['luckyNumber'] is int)
        ? raw!['luckyNumber'] as int
        : _luckyNumberFor(dominant);
    final luckyDirection = raw?['luckyDirection'] as String? ??
        _luckyDirectionFor(isKo, dominant);

    final elementsNote = _elementsNoteFor(isKo, dayMaster, dominant, deficit);
    final tenGodsNote = _tenGodsNoteFor(isKo, dayMaster, dominant, allStems);
    final hooks = _threeHits(
      isKo: isKo,
      day60ji: day60ji,
      name: name,
      dominant: dominant,
      deficit: deficit,
      personalityFull: dmDeep,
      loveFull: love,
      thisYearFull: _thisYear(isKo, day60ji, currentYearGanji),
    );

    return DeepReading(
      dayMasterDeep: dmDeep,
      career: career,
      wealth: wealth,
      love: love,
      health: health,
      family: family,
      fame: fame,
      luckyColor: luckyColor,
      luckyNumber: luckyNumber,
      luckyDirection: luckyDirection,
      tenYearLuck: _tenYearLuck(isKo, day60ji, userAge),
      thisYear: _thisYear(isKo, day60ji, currentYearGanji),
      oneLineYouAre: hooks.oneLine,
      personalityHook: hooks.personality,
      loveHook: hooks.love,
      todayHook: hooks.today,
      whyReason: hooks.why,
      elementsNote: elementsNote,
      tenGodsNote: tenGodsNote,
    );
  }

  /// 5행 dominant/deficit 한 줄 해석 (Round 4 codex 권장)
  static String _elementsNoteFor(bool ko, String dayMaster, String dom, String def) {
    const koDomDesc = {
      '木': '나무 기운(추진력·성장)이 강해 새 도전·확장에 유리해요.',
      '火': '불 기운(표현·열정)이 강해 무대·발표·관계 확장에서 빛나요.',
      '土': '흙 기운(안정·신뢰)이 강해 책임감과 약속을 지키는 힘이 커요.',
      '金': '쇠 기운(정밀·판단)이 강해 결정·정리·비판적 사고가 뛰어나요.',
      '水': '물 기운(직관·깊이)이 강해 통찰과 흐름을 읽는 감각이 좋아요.',
    };
    const koDefDesc = {
      '木': '나무가 부족해 시작이 늦거나 추진력이 약해요. 식물·산책 자주 해요.',
      '火': '불이 부족해 표현·감정 분출이 어려운 편이에요. 따뜻한 빛·운동 권장.',
      '土': '흙이 부족해 약속·끝맺음에 흔들리기 쉬워요. 루틴·기록이 도움 돼요.',
      '金': '쇠가 부족해 결단력·정리정돈이 약해요. 청소·일정 정리 의식으로 보완.',
      '水': '물이 부족해 흐름을 맡기는 감각이 약해질 수 있어요. 조용한 이동·기록·사색으로 보완해요.',
    };
    const enDomDesc = {
      '木': 'Strong Wood energy — pushy, growth-prone, great for new ventures.',
      '火': 'Strong Fire energy — expressive, magnetic, shines on stage.',
      '土': 'Strong Earth energy — grounded, reliable, you finish what you start.',
      '金': 'Strong Metal energy — sharp judgment, decisive, sees what others miss.',
      '水': 'Strong Water energy — intuitive, deep, reads currents others don\'t.',
    };
    const enDefDesc = {
      '木': 'Light on Wood — slow starts. Walks and greenery help.',
      '火': 'Light on Fire — expression can stall. Sunlight and movement help.',
      '土': 'Light on Earth — follow-through wavers. Build a routine.',
      '金': 'Light on Metal — decisions linger. Clean a closet to reset.',
      '水': 'Light on Water — intuition needs quiet flow. Walk, journal, and make room for reflection.',
    };
    final domRole = _fiveElementRoleFor(dayMaster, dom, ko);
    final defRole = _fiveElementRoleFor(dayMaster, def, ko);
    if (ko) {
      return '${koDomDesc[dom] ?? ''} 본인 기준으로는 $domRole 쪽이 제일 세요. '
          '${koDefDesc[def] ?? ''} 채워야 할 쪽은 $defRole 쪽이에요.';
    }
    return '${enDomDesc[dom] ?? ''} For you, the strongest side is $domRole. '
        '${enDefDesc[def] ?? ''} The area to balance is $defRole.';
  }

  /// 십신 핵심 관계 한 줄 (가장 강한 신 → 의미).
  /// [allStems] 가 있으면 음양 분리 10분류 (정관/편관, 정인/편인, 정재/편재,
  /// 식신/상관, 비견/겁재), 없으면 기본 5분류로 fallback.
  static String _tenGodsNoteFor(
      bool ko, String dayMaster, String dom, List<String> allStems) {
    final role = _fiveElementRoleKey(dayMaster, dom);
    if (role.isEmpty) return '';
    final ten = _tenGodKey(dayMaster, dom, allStems);
    if (ten.isNotEmpty) {
      const ko10 = {
        'bigyun': '비견 기운 — 자기 페이스·동료와 어깨 나란히 가는 힘이 또렷해요.',
        'gupjae': '겁재 기운 — 강한 경쟁심·승부욕이 살아 있고 친구·라이벌과 부딪혀요.',
        'siksin': '식신 기운 — 부드러운 표현·창작·먹고 노는 즐거움이 본인 자원이에요.',
        'sanggwan': '상관 기운 — 톡톡 튀는 말·재능·자기 표현이 강하게 흘러요.',
        'jeongjae': '정재 기운 — 꾸준한 돈·현실 관리·약속 지키는 힘이 본인 자원이에요.',
        'pyeonjae': '편재 기운 — 큰 기회·유동 자산·발 빠른 현실 감각이 무기예요.',
        'jeonggwan': '정관 기운 — 책임감·규칙·인정 받는 자리에서 성과가 따라와요.',
        'pyeongwan': '편관 기운 — 도전·압박·돌파력이 본인을 성장시키는 라이벌이에요.',
        'jeongin': '정인 기운 — 차분한 배움·후원·문서·자격이 본인 자원이에요.',
        'pyeonin': '편인 기운 — 직관·예술·비주류 지식·독학력이 본인 자원이에요.',
      };
      const en10 = {
        'bigyun': 'Friend energy — peer-paced, side-by-side strength runs strong.',
        'gupjae': 'Rival energy — competitive drive flares with friends and rivals.',
        'siksin': 'Producer energy — soft expression, creating, and enjoyment fuel you.',
        'sanggwan': 'Spark energy — sharp talk, talent, and self-expression flow.',
        'jeongjae': 'Steady wealth — patient money, follow-through, promises.',
        'pyeonjae': 'Big-shot wealth — large flows, quick reads, deal sense.',
        'jeonggwan': 'Officer energy — responsibility and recognized roles reward you.',
        'pyeongwan': 'Challenger energy — pressure and breakthroughs grow you.',
        'jeongin': 'Mentor energy — calm learning, support, papers, credentials.',
        'pyeonin': 'Insight energy — intuition, art, niche knowledge, self-teaching.',
      };
      return (ko ? ko10[ten] : en10[ten]) ?? '';
    }
    // fallback 5분류 (allStems 비었을 때)
    const ko10g = {
      'peer': '비겁 기운 — 자기 주도·동료·경쟁심이 또렷하게 살아요.',
      'output': '식상 기운 — 표현·창작·말이 본인 무기예요.',
      'wealth': '재성 기운 — 돈·기회·현실 감각을 다루는 힘이 커요.',
      'authority': '관성 기운 — 책임·규칙·인정 받는 자리에서 성과가 생겨요.',
      'resource': '인성 기운 — 배움·후원·기록이 본인 자원이에요.',
    };
    const en10g = {
      'peer': 'Peer energy — self-direction, allies, and rivalry run strong.',
      'output': 'Output energy — your expression and what you create are your edge.',
      'wealth': 'Wealth energy — money, opportunity, and practical control are active.',
      'authority': 'Authority energy — recognition and responsibility come through pressure.',
      'resource': 'Resource energy — learning, mentors, and notes are your base.',
    };
    return (ko ? ko10g[role] : en10g[role]) ?? '';
  }

  /// 일간 음양 + dominant 5행 + 같은 5행 천간 음양 다수 → 10분류 key.
  /// 같은 5행 천간이 사주에 없으면 빈 문자열 (fallback 발동).
  ///
  /// Tie 규칙: 일간(dayMaster) 자체가 dominant 5행에 속하면 domStems 에 항상
  /// 포함되어 sameCount 가 자동으로 +1 가산됨 → tie 시 same 우세가 자연스러움.
  /// 일간이 dominant 외 5행이고 외부 천간이 같은 수면 same 우세로 보정 (>=).
  static String _tenGodKey(
      String dayMaster, String dom, List<String> allStems) {
    if (dayMaster.isEmpty || dom.isEmpty || allStems.isEmpty) return '';
    final domStems = allStems
        .where((s) => s.isNotEmpty && _ganElement(s) == dom)
        .toList();
    if (domStems.isEmpty) return '';
    // 같은 음양 vs 다른 음양 천간 개수 비교 — 더 많은 쪽으로 결정.
    final dmYang = _ganIsYang(dayMaster);
    int sameCount = 0;
    int otherCount = 0;
    for (final s in domStems) {
      if (_ganIsYang(s) == dmYang) {
        sameCount++;
      } else {
        otherCount++;
      }
    }
    // tie 시 일간 음양 우세 (앱은 일간 중심 해석이라 자연스러운 default).
    final sameYinYang = sameCount >= otherCount;
    final role = _fiveElementRoleKey(dayMaster, dom);
    switch (role) {
      case 'peer':
        return sameYinYang ? 'bigyun' : 'gupjae';
      case 'output':
        return sameYinYang ? 'siksin' : 'sanggwan';
      case 'wealth':
        // 정재 = 음양 다름, 편재 = 음양 같음
        return sameYinYang ? 'pyeonjae' : 'jeongjae';
      case 'authority':
        // 정관 = 음양 다름, 편관 = 음양 같음 (七殺)
        return sameYinYang ? 'pyeongwan' : 'jeonggwan';
      case 'resource':
        // 정인 = 음양 다름, 편인 = 음양 같음
        return sameYinYang ? 'pyeonin' : 'jeongin';
      default:
        return '';
    }
  }

  static bool _ganIsYang(String gan) {
    const yangSet = {'甲', '丙', '戊', '庚', '壬'};
    return yangSet.contains(gan);
  }

  static String _fiveElementRoleFor(String dayMaster, String target, bool ko) {
    final key = _fiveElementRoleKey(dayMaster, target);
    const koMap = {
      'peer': '비겁(자기 힘·동료·경쟁)',
      'output': '식상(표현·창작·말)',
      'wealth': '재성(돈·현실·관리)',
      'authority': '관성(책임·규칙·직함)',
      'resource': '인성(배움·후원·문서)',
    };
    const enMap = {
      'peer': 'peer/self-drive',
      'output': 'output/expression',
      'wealth': 'wealth/practical control',
      'authority': 'authority/responsibility',
      'resource': 'resource/support',
    };
    return (ko ? koMap[key] : enMap[key]) ?? target;
  }

  static String _fiveElementRoleKey(String dayMaster, String target) {
    final dm = _ganElement(dayMaster);
    if (dm.isEmpty || target.isEmpty) return '';
    const generates = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    const overcomes = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
    if (dm == target) return 'peer';
    if (generates[dm] == target) return 'output';
    if (overcomes[dm] == target) return 'wealth';
    if (overcomes[target] == dm) return 'authority';
    if (generates[target] == dm) return 'resource';
    return '';
  }

  static String _ganElement(String gan) {
    const map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[gan] ?? '';
  }

  // ──────── 3-hit summary (codex PM 권고: 성격/연애/오늘 액션 + why)

  static ({String oneLine, String personality, String love, String today, String why}) _threeHits({
    required bool isKo,
    required String day60ji,
    required String name,
    required String dominant,
    required String deficit,
    required String personalityFull,
    required String loveFull,
    required String thisYearFull,
  }) {
    // 일주별 임팩트 라인 (성격 짧은 형용사구)
    final oneLine = _oneLinerFor(isKo, day60ji, name, dominant);
    final personality = _firstSentence(personalityFull, isKo: isKo);
    final love = _firstSentence(loveFull, isKo: isKo);
    final today = _todayHookFor(isKo, day60ji, dominant);
    final why = _whyReasonFor(isKo, day60ji, name, dominant, deficit);
    return (oneLine: oneLine, personality: personality, love: love, today: today, why: why);
  }

  /// 60일주별 한 줄 형용사구 (사용자 = 결정자 라 일주 = 첫 인상).
  /// Round 80 sprint 2 — 사용자 피드백 ("벼린 칼 같은 사람 본인+여친 동일") 직발.
  /// Round 82 sprint 3 — 사용자 피드백 ("벼린칼 같은사람이에요 이 단어도 너무 어렵고")
  ///                     직발. 5종 fallback 도 쉬운 단어로 전면 교체.
  /// 5종 dominant 매핑은 fallback 으로만 유지 (60일주 lookup 미스 시).
  static String _oneLinerFor(bool ko, String day60ji, String name, String dom) {
    if (ko) {
      final base = _oneLineByJi60Ko[day60ji];
      if (base != null && base.isNotEmpty) return base;
      // R82 sprint 3 — 폐기 5종 (R80 sprint 2 의 추상 비유 fallback) 을 모두
      //                 사용자 직관 단어 (단단한·다정한·꾸준한 류) 로 교체.
      const koMap = {
        '木': '천천히 자라고 사람을 잘 챙기는',
        '火': '환하고 분위기를 살리는',
        '土': '듬직하고 약속을 지키는',
        '金': '단단하고 마무리가 깔끔한',
        '水': '차분하고 상황을 잘 보는',
      };
      return koMap[dom] ?? '한결같은';
    }
    const enMap = {
      '木': 'tall-tree',
      '火': 'bright-flame',
      '土': 'mountain',
      '金': 'forged-blade',
      '水': 'deep-water',
    };
    final fallback = enMap[dom] ?? 'steady';
    return '$fallback-energy';
  }

  /// 60일주 한국어 oneLine — 천간 element 형용사 + 지지 동물/계절 조합.
  /// 한자 jargon 0 / 한국 MZ 친근 해요체 / 양면 단정 톤 / 끝은 "사람" 또는 무종결.
  /// R82 sprint 3 — 사용자 verbatim ("벼린칼 같은사람이에요 이 단어도 너무 어렵고")
  /// 직발. "벼린 / 도검 / 정수 / 본질 / 결을 / 운기 / 기운" 0
  /// + 추상 어휘 "결 / 결단 / 결과 만드는 / 우직함 / 거침없이 / 충견 / 영리함 / 그릇이"
  /// 도 사용자 직관 단어 (단단한·다정한·꾸준한·재빠른·차분한·솔직한·유연한·씩씩한·
  /// 느긋한·기민한·끈기 있는·다정한·꼼꼼한 류) 로 전면 교체.
  static const Map<String, String> _oneLineByJi60Ko = {
    // 甲(곧은 나무) ──
    '甲子': '시작은 늦어도 끝까지 확인하는',
    '甲戌': '한 번 한 약속은 꼭 지키는',
    '甲申': '진중한데 머리도 빠르게 굴리는',
    '甲午': '조용한데 할 말은 또박또박 하는',
    '甲辰': '서두르지 않고 큰 그림을 보는',
    '甲寅': '차분한데 할 때는 밀어붙이는',
    // 乙(휘는 풀) ──
    '乙丑': '차가운 데서도 끈질기게 버티는',
    '乙亥': '잘 안 떠나고 옆에 오래 머무는',
    '乙酉': '부드러운데 시간은 똑 부러지게 지키는',
    '乙未': '주변 사람을 한결같이 살뜰히 챙기는',
    '乙巳': '말랑하면서 눈치는 센스 있게 챙기는',
    '乙卯': '말은 부드럽지만 자기 페이스는 잃지 않는',
    // 丙(밝은 불) ──
    '丙寅': '들어오면 분위기를 한 번에 살리는',
    '丙子': '작아 보여도 자기 생각이 분명한',
    '丙戌': '곁 사람을 먼저 챙기는 따뜻한',
    '丙申': '밝은데 머리 회전이 한 박자 빠른',
    '丙午': '거리낌 없이 자기를 표현하는',
    '丙辰': '사람들 앞에서도 흔들리지 않는',
    // 丁(촛불) ──
    '丁卯': '조용히 있어도 사람 눈길이 가는',
    '丁丑': '곁에 있으면 마음이 풀어지게 만드는',
    '丁亥': '말없이 상대 기분을 살피는',
    '丁酉': '다정한데 약속은 깔끔하게 지키는',
    '丁未': '챙길 사람은 끝까지 챙기는',
    '丁巳': '다정한데 눈치도 빠른',
    // 戊(큰 산) ──
    '戊辰': '한 번 자리잡으면 잘 흔들리지 않는',
    '戊寅': '듬직한데 시야가 넓은',
    '戊子': '작은 선택을 차근차근 모아 큰일로 만드는',
    '戊戌': '말 적어도 사람을 묵묵히 지키는',
    '戊申': '듬직한데 판단은 한 박자 빠른',
    '戊午': '눈앞보다 멀리 보고 움직이는',
    // 己(부드러운 흙) ──
    '己巳': '부드러운데 눈치는 끝까지 챙기는',
    '己卯': '말랑하게 다가가서 사람을 살랑살랑 끄는',
    '己丑': '묵묵히 한 길을 가는',
    '己亥': '말없이 사람을 푹 안아주는',
    '己酉': '부드러운데 시간 약속은 또박또박 지키는',
    '己未': '평온하고 다정해서 곁에 머물게 되는',
    // 庚(쇠) ──
    '庚午': '곧장 가서 끝맺음이 깔끔한',
    '庚辰': '한 번 시작하면 끝까지 가는',
    '庚寅': '겁 안 내고 한 발 앞서 움직이는',
    '庚子': '조용한데 마무리는 야무진',
    '庚戌': '의리 지키고 약속 어기지 않는',
    '庚申': '똑 부러지면서 판단도 빠른',
    // 辛(다듬어진 금속) ── 1995-10-27 男 골든 = 辛卯
    '辛未': '부드러워 보여도 속은 야무진',
    '辛巳': '차분해 보여도 결정할 땐 망설이지 않는',
    '辛卯': '단단한데 말투는 부드러운',
    '辛丑': '꼼꼼하게 천천히 정확함을 쌓아가는',
    '辛亥': '꼼꼼한데 사람한테는 따뜻한',
    '辛酉': '꼼꼼하면서 약속은 꼭 지키는',
    // 壬(큰 물) ──
    '壬申': '차분한데 생각은 빠르게 굴리는',
    '壬午': '거리낌 없이 새 일에 뛰어드는',
    '壬辰': '튀지 않아도 사람들이 편하게 따르는',
    '壬寅': '겁 안 내고 시야 넓게 움직이는',
    '壬子': '말수는 적어도 한 번 시작하면 꾸준한',
    '壬戌': '조용하게 의리를 지키는 친구 같은',
    // 癸(이슬) ──
    '癸酉': '가볍게 다가가서 마음에 깊게 남는',
    '癸未': '부드러운데 분위기는 빠르게 읽는',
    '癸巳': '조용한데 핵심은 정확히 짚어내는',
    '癸卯': '조용한데 사람한테 편하게 다가가는',
    '癸丑': '묵묵히 한 길을 끝까지 가는',
    '癸亥': '말 안 해도 상대를 먼저 헤아리는',
  };

  /// 첫 문장만 추출 (마침표 / 句점 기준).
  static String _firstSentence(String full, {required bool isKo}) {
    if (full.isEmpty) return '';
    final ko = full.split(RegExp(r'(?<=[.다요!?])\s'));
    final firstKo = ko.isNotEmpty ? ko.first.trim() : full;
    final en = firstKo.split(RegExp(r'(?<=[.!?])\s'));
    final result = en.isNotEmpty ? en.first.trim() : firstKo;
    if (result.length > 130) {
      return '${result.substring(0, 127)}...';
    }
    return result;
  }

  /// Round 80 sprint 3 — _todayHookFor 60일주 base + dominant suffix 하이브리드.
  /// 같은 dominant (예: 金) 여도 일주 다르면 hook 다름 → 본인 vs 여친 변별 가드.
  static String _todayHookFor(bool ko, String ji, String dom) {
    if (ko) {
      final base = _todayHookByJi60Ko[ji];
      final suffix = _todayHookSuffixKo[dom] ?? '';
      if (base != null && base.isNotEmpty) {
        return suffix.isEmpty ? base : '$base $suffix';
      }
      const koMap = {
        '木': '오늘은 새 아이디어 한 줄을 메모해 두면 일주일 뒤 쓰임이 와요.',
        '火': '오늘은 말보다 타이밍이 중요한 날. 답장·제안은 오전보다 오후가 나아요.',
        '土': '오늘은 결정을 늦추지 말고, 하나를 매듭짓는 데 집중해 보세요.',
        '金': '오늘은 디테일이 평가를 가려요. 한 줄 더 확인하고 보내세요.',
        '水': '오늘은 듣는 시간이 길수록 좋아요. 말은 마지막 5분만.',
      };
      return koMap[dom] ?? '';
    }
    const enMap = {
      '木': 'Note one fresh idea today — it pays off within a week.',
      '火': 'Today, timing beats words. Send replies after noon, not before.',
      '土': "Today, don't postpone — pick one thing and close it.",
      '金': 'Today, details decide reviews. Re-check once before you send.',
      '水': 'Today, listen long. Save your words for the last 5 minutes.',
    };
    return enMap[dom] ?? '';
  }

  /// Round 80 sprint 3 — _whyReasonFor 60일주 + dominant 보조 phrase.
  /// 같은 (dom, def) 페어여도 일주 다르면 phrase 다름.
  static String _whyReasonFor(bool ko, String ji, String name, String dom, String def) {
    const koElName = {
      '木': '나무', '火': '불', '土': '흙·산', '金': '쇠·칼', '水': '물',
    };
    const enElName = {
      '木': 'wood', '火': 'fire', '土': 'earth/mountain', '金': 'metal/blade', '水': 'water',
    };
    if (ko) {
      final domName = koElName[dom] ?? '하나';
      final defName = koElName[def] ?? '하나';
      final intro = _whyReasonIntroKo[ji];
      if (intro != null && intro.isNotEmpty) {
        return '$intro $domName 쪽이 두드러지고 $defName 쪽이 비어 있어서, 위처럼 풀어드렸어요.';
      }
      return '$ji 일주는 $domName 쪽이 강하고 $defName 쪽이 약해서, 위처럼 풀어드린 거예요.';
    }
    final domName = enElName[dom] ?? 'one';
    final defName = enElName[def] ?? 'one';
    return 'Your $ji day pillar runs strong on $domName and short on $defName — that\'s why the reading reads this way.';
  }

  /// 60일주별 today hook base — dominant suffix 가 뒤에 붙을 수 있음.
  static const Map<String, String> _todayHookByJi60Ko = {
    '甲子': '오늘은 조용한 한 줄 메모가 다음 주 큰 열쇠가 돼요.',
    '甲戌': '오늘은 약속 한 가지 먼저 지키면 신뢰가 한 단계 올라가요.',
    '甲申': '오늘은 영리하게 한 발만 빠르게 움직여 보세요.',
    '甲午': '오늘은 직진해도 좋아요. 망설이지 마세요.',
    '甲辰': '오늘은 큰 그림 한 장 그려두면 다음 주가 가벼워져요.',
    '甲寅': '오늘은 한 가지를 끝까지 밀어붙이면 결과가 따라와요.',
    '乙丑': '오늘은 천천히, 하지만 멈추지 말고 한 발씩 가요.',
    '乙亥': '오늘은 옆 사람 한 명한테 안부 한 줄 먼저 보내요.',
    '乙酉': '오늘은 시간 약속 한 번 먼저 잡아 두면 답이 빨리 와요.',
    '乙未': '오늘은 따뜻한 말 한 마디가 분위기를 바꿔요.',
    '乙巳': '오늘은 영리하게 한 가지만 골라서 깊게 가요.',
    '乙卯': '오늘은 살랑살랑 사람 사이를 부드럽게 지나가는 게 잘 통해요.',
    '丙寅': '오늘은 분위기 한 번 환하게 바꾸는 한 마디를 던져 보세요.',
    '丙子': '오늘은 작은 빛 하나가 큰 변화의 시작이 돼요.',
    '丙戌': '오늘은 옆 사람 지켜주는 따뜻한 한 마디가 평판을 만들어요.',
    '丙申': '오늘은 영리한 결단 한 가지가 결과를 끌어와요.',
    '丙午': '오늘은 거침없이 빛나도 좋은 날. 무대를 잡으세요.',
    '丙辰': '오늘은 큰 자리 한 번 만들면 흐름이 본인 쪽으로 와요.',
    '丁卯': '오늘은 부드러운 한 마디가 사람 마음을 끌어요.',
    '丁丑': '오늘은 옆 사람 한 명 데우는 한 가지 행동이 돈 돼요.',
    '丁亥': '오늘은 깊은 마음 한 줄이 누군가에게 큰 위안이 돼요.',
    '丁酉': '오늘은 정확한 시간 약속 한 가지가 신뢰를 키워요.',
    '丁未': '오늘은 사람 옆에 머무는 시간을 충분히 잡아요.',
    '丁巳': '오늘은 비밀 한 가지를 영리하게 풀어내면 결과가 따라와요.',
    '戊辰': '오늘은 자리 한 번 잡으면 흔들리지 마세요.',
    '戊寅': '오늘은 시야 넓게 잡고 한 발 멀리 봐요.',
    '戊子': '오늘은 작은 결정 모아 큰 그림 한 장 만들어요.',
    '戊戌': '오늘은 우직하게 한 가지만 끝까지 지켜요.',
    '戊申': '오늘은 영리한 길 한 가지를 골라서 가요.',
    '戊午': '오늘은 큰 그림 그리며 거침없이 내달려 보세요.',
    '己巳': '오늘은 비밀 한 줌 풀어 놓으면 분위기가 바뀌어요.',
    '己卯': '오늘은 살랑살랑 분위기에 맞춰서 가도 답이 와요.',
    '己丑': '오늘은 묵묵하게 한 길만 가요. 지름길은 오늘 X.',
    '己亥': '오늘은 옆 사람 한 명 푹 안아주는 한 마디를 던져요.',
    '己酉': '오늘은 정확한 시간 잡아 두면 본인 페이스가 살아요.',
    '己未': '오늘은 평온한 결로 분위기 한 번 정리해요.',
    '庚午': '오늘은 직진으로 결과 만들어요. 한 번에 가요.',
    '庚辰': '오늘은 큰 일 하나만 끝까지 끌고 가요.',
    '庚寅': '오늘은 한 발 앞서 움직이면 흐름이 본인 쪽으로 와요.',
    '庚子': '오늘은 조용히 결정 한 번 끝내요. 말은 그 다음.',
    '庚戌': '오늘은 약속 한 가지 끝까지 지키면 평판이 한 단계 올라가요.',
    '庚申': '오늘은 영리한 한 수가 결과를 결정해요.',
    '辛未': '오늘은 단단한 결을 부드럽게 보여주면 사람이 따라와요.',
    '辛巳': '오늘은 뜨거운 결단 한 번이 답이에요.',
    '辛卯': '오늘은 부드러운 봄 결로 사람 마음 한 명 잡아요.',
    '辛丑': '오늘은 느린 정확함이 답. 빠르게 가지 마세요.',
    '辛亥': '오늘은 따뜻한 결단 한 마디가 분위기를 바꿔요.',
    '辛酉': '오늘은 정확한 시간 감각으로 한 발 먼저 움직여요.',
    '壬申': '오늘은 머리 빠르게 돌아가는 한 수를 던져요.',
    '壬午': '오늘은 거침없이 도전 한 가지 시작해도 좋아요.',
    '壬辰': '오늘은 그릇 큰 한 마디가 사람을 움직여요.',
    '壬寅': '오늘은 깊고 넓게 한 가지를 살펴봐요.',
    '壬子': '오늘은 조용히 흘러가요. 흐름에 한 번 맡겨요.',
    '壬戌': '오늘은 의리 한 가지 지키는 한 마디가 사람을 잡아요.',
    '癸酉': '오늘은 가볍게 다가가도 깊게 남는 한 마디를 던져요.',
    '癸未': '오늘은 부드러운 영리함으로 한 가지를 풀어요.',
    '癸巳': '오늘은 비밀 한 가지를 정확히 짚어내면 답이 와요.',
    '癸卯': '오늘은 부드럽게 사람을 끄는 한 마디를 던져 보세요.',
    '癸丑': '오늘은 묵묵하게 한 가지만 끝까지 가요.',
    '癸亥': '오늘은 푹 안아주는 한 마디가 옆 사람에게 큰 힘이 돼요.',
  };

  /// dominant 5종 suffix — base 뒤에 한 문장 더 붙음 (변동 채널 보강).
  static const Map<String, String> _todayHookSuffixKo = {
    '木': '결정은 오전이 좋아요.',
    '火': '답장·제안은 오후 타이밍이 잘 풀려요.',
    '土': '하나만 매듭지으면 오늘이 가벼워져요.',
    '金': '한 줄 더 확인하고 보내세요.',
    '水': '말보다 듣는 시간이 길수록 잘 흘러가요.',
  };

  /// _whyReasonFor 60일주 intro phrase (한자 jargon "일주" 1회 사용 — UX 텍스트 노출 영역
  /// 이지만 사용자 멘트에서 일주 (60갑자) 자체 언급은 R71 invariant 허용 범위).
  static const Map<String, String> _whyReasonIntroKo = {
    '甲子': '본인 사주는 어둠 속에서도 천천히 키 키우는 결이라,',
    '甲戌': '본인 사주는 충직한 나무 결이라,',
    '甲申': '본인 사주는 영리한 가지 뻗는 결이라,',
    '甲午': '본인 사주는 한낮을 직진하는 결이라,',
    '甲辰': '본인 사주는 그릇 큰 나무 결이라,',
    '甲寅': '본인 사주는 단단한 의지의 결이라,',
    '乙丑': '본인 사주는 차가운 땅도 뚫고 올라오는 결이라,',
    '乙亥': '본인 사주는 따뜻하게 머무는 결이라,',
    '乙酉': '본인 사주는 정확한 시간 감각의 결이라,',
    '乙未': '본인 사주는 따뜻한 마음 끝까지 가는 결이라,',
    '乙巳': '본인 사주는 영리하게 깊게 가는 결이라,',
    '乙卯': '본인 사주는 살랑살랑 사람을 끄는 결이라,',
    '丙寅': '본인 사주는 분위기를 환하게 바꾸는 결이라,',
    '丙子': '본인 사주는 작은 빛이 강하게 빛나는 결이라,',
    '丙戌': '본인 사주는 옆 사람 지키는 결이라,',
    '丙申': '본인 사주는 영리한 빛의 결이라,',
    '丙午': '본인 사주는 거침없이 빛나는 결이라,',
    '丙辰': '본인 사주는 큰 자리 만드는 결이라,',
    '丁卯': '본인 사주는 부드럽게 마음을 끄는 결이라,',
    '丁丑': '본인 사주는 옆 사람을 데우는 결이라,',
    '丁亥': '본인 사주는 깊은 마음을 품은 결이라,',
    '丁酉': '본인 사주는 정확한 시간의 결이라,',
    '丁未': '본인 사주는 사람 옆에 머무는 결이라,',
    '丁巳': '본인 사주는 비밀을 영리하게 푸는 결이라,',
    '戊辰': '본인 사주는 흔들리지 않는 큰 산 결이라,',
    '戊寅': '본인 사주는 시야 넓게 잡는 결이라,',
    '戊子': '본인 사주는 작은 결정 모아 큰일 만드는 결이라,',
    '戊戌': '본인 사주는 우직하게 지키는 결이라,',
    '戊申': '본인 사주는 영리한 길 찾는 결이라,',
    '戊午': '본인 사주는 큰 그림 그리며 내달리는 결이라,',
    '己巳': '본인 사주는 따뜻한 흙 안의 비밀 결이라,',
    '己卯': '본인 사주는 살랑살랑 분위기의 결이라,',
    '己丑': '본인 사주는 묵묵하게 한 길 가는 결이라,',
    '己亥': '본인 사주는 옆 사람 푹 안는 결이라,',
    '己酉': '본인 사주는 정확한 시간 감각의 결이라,',
    '己未': '본인 사주는 평온한 양의 결이라,',
    '庚午': '본인 사주는 직진으로 결과 만드는 결이라,',
    '庚辰': '본인 사주는 큰 일 끝내는 결이라,',
    '庚寅': '본인 사주는 한 발 앞선 결이라,',
    '庚子': '본인 사주는 조용히 결정 끝내는 결이라,',
    '庚戌': '본인 사주는 약속 끝까지 지키는 결이라,',
    '庚申': '본인 사주는 단단한 영리함의 결이라,',
    '辛未': '본인 사주는 부드러운 결 안의 칼날이라,',
    '辛巳': '본인 사주는 뜨거운 결단의 결이라,',
    '辛卯': '본인 사주는 부드러운 봄 결을 품은 결이라,',
    '辛丑': '본인 사주는 느린 정확함의 결이라,',
    '辛亥': '본인 사주는 따뜻한 결단의 결이라,',
    '辛酉': '본인 사주는 정확한 시간 감각의 결이라,',
    '壬申': '본인 사주는 머리 빠른 큰 강 결이라,',
    '壬午': '본인 사주는 거침없이 도전하는 결이라,',
    '壬辰': '본인 사주는 그릇 큰 깊은 바다 결이라,',
    '壬寅': '본인 사주는 깊고 넓은 결이라,',
    '壬子': '본인 사주는 조용히 흘러가는 결이라,',
    '壬戌': '본인 사주는 조용한 의리의 결이라,',
    '癸酉': '본인 사주는 가볍게 다가가서 깊게 남는 결이라,',
    '癸未': '본인 사주는 부드러운 영리함의 결이라,',
    '癸巳': '본인 사주는 비밀을 정확히 아는 결이라,',
    '癸卯': '본인 사주는 부드럽게 사람을 끄는 결이라,',
    '癸丑': '본인 사주는 묵묵하게 끝까지 가는 결이라,',
    '癸亥': '본인 사주는 따뜻한 마음으로 푹 안는 결이라,',
  };

  // ──────── fallback content (콘텐츠 부족 시 사용)

  static String _fallbackDayMasterDeep(bool ko, String ji, String name) {
    if (ko) {
      // Round 77 sprint 2 — `($name)` 영문 페어 제거. sanitize 후 빈 괄호 누출 0.
      // Round 77 sprint 4 — 한자 jargon (일간/60갑자 사이클/진동/결/색) 제거.
      return '$ji 일주는 비슷한 일주끼리도 살짝 다른 느낌을 만드는 사주예요. '
          '본인은 환경의 압력을 견디며 자기다움을 다듬는 데서 강해져요. '
          '본인 안의 리듬을 따라갈 때 가장 본인다운 결과가 나와요. '
          '서두르기보다 본인 호흡대로, 흉내보다 본인 스타일대로 가는 사람이에요.';
    }
    return 'Your $ji day master ($name) carries a singular pulse within the '
        '60-pillar cycle. The $name nature sharpens under steady pressure, '
        'shaping its own pattern rather than performing identity. When you obey '
        'your inner rhythm — not market trends — your work reads as inevitable.';
  }

  static String _expandShort(String short, bool ko, String key, String ji) {
    if (short.isEmpty) {
      return ko
          ? '당신의 $ji 일주는 $key 영역에서 본인 스타일대로 갈 때 가장 빛나요.'
          : 'Your $ji day pillar grows in $key when you follow your native '
              'own pattern rather than copy strategies built for other charts.';
    }
    // existing short reading already authored — use it as-is
    return short;
  }

  static String _fallbackHealth(bool ko, String ji, String deficit) {
    const koMap = {
      '木': '간·담·근육·신경계',
      '火': '심장·소장·혈액순환',
      '土': '비위·소화·근육 피로',
      '金': '폐·대장·피부',
      '水': '신장·방광·호르몬',
    };
    const enMap = {
      '木': 'liver, gallbladder, muscles, nervous system',
      '火': 'heart, small intestine, circulation',
      '土': 'spleen, stomach, digestion, muscle fatigue',
      '金': 'lungs, large intestine, skin',
      '水': 'kidneys, bladder, hormonal axis',
    };
    final koArea = koMap[deficit] ?? '오장육부의 미세한 균형';
    final enArea = enMap[deficit] ?? 'subtle five-organ balance';
    if (ko) {
      return '$ji 일주의 몸은 부족한 쪽($deficit) 신호를 가장 먼저 알려줘요. '
          '특히 $koArea 의 컨디션을 정기적으로 점검하세요. 작은 신호를 무시하지 않을 때 장기적인 안정이 와요.';
    }
    return 'Your $ji body whispers first through the deficit element ($deficit). '
        'Track $enArea regularly — what you notice early, you never have to fix late.';
  }

  static String _fallbackFamily(bool ko, String ji) {
    if (ko) {
      return '$ji 일주에게 가정은 본인이 어떤 사람인지 비춰주는 거울이에요. '
          '말보다 함께 보내는 시간의 분위기가 가족 운을 만들어요. 사랑의 형태가 표현될 때 관계 운도 함께 살아나요.';
    }
    return 'Family for $ji is the soft mirror that returns your real self. '
        'Time spent together — not perfect words — composes the chord of belonging '
        'that quietly heals the rest of your chart.';
  }

  static String _fallbackFame(bool ko, String ji, String name) {
    if (ko) {
      return '$name 일주는 본인다움이 분명할수록 평판이 살아나요. 흉내가 아닌 본인 스타일로 공개될 때, '
          '$ji 일주의 명예 흐름이 환경을 끌어와요. 검색량보다 깊이가 자산이에요.';
    }
    return 'The $name stage glows brightest in authenticity. When $ji shows its '
        'own pattern — not a replicated formula — public energy moves toward you. '
        'Depth, not algorithm gymnastics, is the asset.';
  }

  static String _tenYearLuck(bool ko, String ji, int age) {
    final decade = (age ~/ 10) * 10;
    final next = decade + 10;
    if (ko) {
      return '현재 대운: $decade대 흐름. '
          '이번 10년은 $ji 의 깊이가 외부에 인정받기 시작하는 게이트예요. '
          '특히 ${next - 3}~${next - 1}살 구간이 대운 정점에 가까워요. '
          '대운은 주(週)가 아니라 10년 단위 흐름으로 읽어야 해요.';
    }
    final nextEnd = next - 1;
    return 'Current 大運 window: your $decade-decade. '
        'This is the gate where $ji depth becomes externally legible. '
        'The years between $age and $nextEnd tend to compound — '
        'read this decade as one continuous breath, not isolated months.';
  }

  static String _thisYear(bool ko, String ji, String yearGanji) {
    if (ko) {
      return '올해 세운: $yearGanji. '
          '$ji 의 일간이 $yearGanji 환경 속에서 어떤 색으로 발현될지가 올해의 주제예요. '
          '여름 ~ 가을 구간에 변동성이 가장 크고, 봄에 심은 흐름이 가을에 거두어져요. '
          '한 해의 결정은 절기(節氣) 기준 입춘부터 한 사이클이에요.';
    }
    return "This year (歲運): $yearGanji. "
        'The theme is how your $ji day master expresses inside $yearGanji '
        'energy. Volatility is highest mid-summer through autumn, while the '
        'pattern you set in spring compounds by harvest. The annual cycle '
        'begins at 立春 — not January 1st.';
  }

  static String _luckyColorFor(bool ko, String element) {
    const koMap = {
      '木': '심해 청록',
      '火': '주작 진홍',
      '土': '고대 황금',
      '金': '월광 은백',
      '水': '심해 청남',
    };
    const enMap = {
      '木': 'Forest Jade',
      '火': 'Phoenix Red',
      '土': 'Ancient Bronze',
      '金': 'Lunar Silver',
      '水': 'Deep Ocean Blue',
    };
    return (ko ? koMap[element] : enMap[element]) ?? (ko ? '천상의 금빛' : 'Celestial Gold');
  }

  static int _luckyNumberFor(String element) {
    const map = {'木': 3, '火': 7, '土': 5, '金': 9, '水': 1};
    return map[element] ?? 7;
  }

  static String _luckyDirectionFor(bool ko, String element) {
    const koMap = {'木': '동', '火': '남', '土': '중앙', '金': '서', '水': '북'};
    const enMap = {
      '木': 'East', '火': 'South', '土': 'Center', '金': 'West', '水': 'North',
    };
    return (ko ? koMap[element] : enMap[element]) ?? (ko ? '동' : 'East');
  }

  /// 현재 연도의 60갑자 (1900년 庚子 기준)
  static String currentYearGanji([DateTime? now]) {
    final t = now ?? DateTime.now();
    // 입춘 boundary 는 연도별 KST datetime (2/3~2/5 + 시분 가변) — SolarTermService 위임.
    final lipchunDt = SolarTermService.lipchun(t.year);
    int adjustedYear = t.year;
    if (t.isBefore(lipchunDt)) {
      adjustedYear -= 1;
    }
    const chunGan = ['庚', '辛', '壬', '癸', '甲', '乙', '丙', '丁', '戊', '己'];
    const jiJi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final offset = adjustedYear - 1900;
    final gIdx = ((offset % 10) + 10) % 10;
    final jIdx = ((offset % 12) + 12) % 12;
    return '${chunGan[gIdx]}${jiJi[jIdx]}';
  }
}
