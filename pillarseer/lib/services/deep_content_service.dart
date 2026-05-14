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

  /// "큰 산 같은" / "like a tall mountain" — 5행 dominant 기반 짧은 형용사구
  static String _oneLinerFor(bool ko, String day60ji, String name, String dom) {
    const koMap = {
      '木': '쭉 뻗는 나무 같은',
      '火': '환하게 타오르는 불 같은',
      '土': '큰 산 같은',
      '金': '벼린 칼 같은',
      '水': '깊은 물 같은',
    };
    const enMap = {
      '木': 'tall-tree',
      '火': 'bright-flame',
      '土': 'mountain',
      '金': 'forged-blade',
      '水': 'deep-water',
    };
    final fallback = enMap[dom] ?? 'steady';
    return ko ? (koMap[dom] ?? '한결같은') : '$fallback-energy';
  }

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

  static String _todayHookFor(bool ko, String ji, String dom) {
    const koMap = {
      '木': '오늘은 새 아이디어 한 줄을 메모해 두면 일주일 뒤 쓰임이 와요.',
      '火': '오늘은 말보다 타이밍이 중요한 날. 답장·제안은 오전보다 오후가 나아요.',
      '土': '오늘은 결정을 늦추지 말고, 하나를 매듭짓는 데 집중해 보세요.',
      '金': '오늘은 디테일이 평가를 가려요. 한 줄 더 확인하고 보내세요.',
      '水': '오늘은 듣는 시간이 길수록 좋아요. 말은 마지막 5분만.',
    };
    const enMap = {
      '木': 'Note one fresh idea today — it pays off within a week.',
      '火': 'Today, timing beats words. Send replies after noon, not before.',
      '土': "Today, don't postpone — pick one thing and close it.",
      '金': 'Today, details decide reviews. Re-check once before you send.',
      '水': 'Today, listen long. Save your words for the last 5 minutes.',
    };
    return (ko ? koMap[dom] : enMap[dom]) ?? '';
  }

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
      return '$ji 일주는 $domName 기운이 강하고 $defName 기운이 약해서, 위와 같은 결로 풀어드린 거예요.';
    }
    final domName = enElName[dom] ?? 'one';
    final defName = enElName[def] ?? 'one';
    return 'Your $ji day pillar runs strong on $domName and short on $defName — that\'s why the reading reads this way.';
  }

  // ──────── fallback content (콘텐츠 부족 시 사용)

  static String _fallbackDayMasterDeep(bool ko, String ji, String name) {
    if (ko) {
      // Round 77 sprint 2 — `($name)` 영문 페어 제거. sanitize 후 빈 괄호 누출 0.
      return '당신의 일간 $ji 은 60갑자 사이클 속에서 고유한 진동을 가져요. '
          '본능은 환경의 압력을 견디며 자기 색을 다듬는 데서 강해져요. '
          '내면의 리듬을 따라갈 때 가장 자기다운 결과를 만들어요. '
          '서두르기보다 자기 흐름을, 흉내보다 자기 색을 따르는 사주예요.';
    }
    return 'Your $ji day master ($name) carries a singular pulse within the '
        '60-pillar cycle. The $name nature sharpens under steady pressure, '
        'shaping its grain rather than performing identity. When you obey '
        'your inner rhythm — not market trends — your work reads as inevitable.';
  }

  static String _expandShort(String short, bool ko, String key, String ji) {
    if (short.isEmpty) {
      return ko
          ? '당신의 $ji 일주는 $key 영역에서 자기 결을 따를 때 가장 빛나요.'
          : 'Your $ji day pillar grows in $key when you follow your native '
              'grain rather than copy strategies built for other charts.';
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
      return '$ji 의 몸은 결핍 오행($deficit)이 약속한 신호를 가장 먼저 알려요. '
          '특히 $koArea 의 컨디션을 정기적으로 점검하세요. 작은 신호를 무시하지 않을 때 장기적인 안정이 와요.';
    }
    return 'Your $ji body whispers first through the deficit element ($deficit). '
        'Track $enArea regularly — what you notice early, you never have to fix late.';
  }

  static String _fallbackFamily(bool ko, String ji) {
    if (ko) {
      return '$ji 일주의 가정은 자기 정체성을 닦는 거울이에요. '
          '말보다는 함께 보내는 시간의 결이 가족 운을 만들어요. 사랑의 형태가 표현될 때, 관계의 운도 함께 살아나요.';
    }
    return 'Family for $ji is the soft mirror that returns your real self. '
        'Time spent together — not perfect words — composes the chord of belonging '
        'that quietly heals the rest of your chart.';
  }

  static String _fallbackFame(bool ko, String ji, String name) {
    if (ko) {
      return '$name 의 무대는 진정성에서 빛나요. 흉내가 아닌 자신만의 색으로 공개될 때, '
          '$ji 의 명예 운이 환경을 끌어와요. 검색량보다 깊이가 자산이에요.';
    }
    return 'The $name stage glows brightest in authenticity. When $ji shows its '
        'own grain — not a replicated formula — public energy moves toward you. '
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
        'grain you set in spring compounds by harvest. The annual cycle '
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
