// Pillar Seer — 전생 시나리오 서비스 (R101 sprint 4, 팬심 1순위).
//
// 입력: 사용자 사주 + 셀럽 사주 + 이름 2종.
// 출력: keyword Set + KO 전생 시나리오 한 편 (5~8 문장).
//
// 재사용:
//   - ShinsaService    — 역마 / 도화 / 천을귀인
//   - GongMangService  — 공망 (일주 기준)
//   - HapchungService  — 천간합 / 지지합 / 충 / 형
//
// 신규:
//   - 원진살(怨嗔煞) 6쌍 양방향: 子-未 / 丑-午 / 寅-酉 / 卯-申 / 辰-亥 / 巳-戌
//     사용자 spec verbatim. 일지 기준 둘 사이 원진살 검출.
//
// Sprint 4 범위:
//   - 데이터 모델 + service skeleton 만. UI / route / menu 연결은 sprint 5+ 에서.
//   - 한국어 본문 only. 영어 단어 / 영문 그룹명 head 금지 (R101 sprint 2 가드 통과).
//   - 셀럽 + 사용자 두 명 케이스만. 일반 사주짝 확장은 추후.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'gong_mang_service.dart';
import 'hapchung_service.dart';
import 'korean_josa.dart' as josa;
import 'shinsa_service.dart';

/// 전생 시나리오 keyword.
///
/// 사용자 mandate (verbatim):
///   wonjin / dohwa / yeokma / cheoneul / gongmang / hap / chung / hyeong (8종)
enum PastLifeKeyword {
  /// 원진살 — 미움과 끌림이 한 줄에 함께 걸린 결.
  wonjin,

  /// 도화살 — 시선이 모이고 매력으로 닿는 결.
  dohwa,

  /// 역마살 — 이동과 떠남으로 이어지는 결.
  yeokma,

  /// 천을귀인 — 위기에서 만난 보호 결.
  cheoneul,

  /// 공망 — 비어 있는 자리가 함께 있는 결.
  gongmang,

  /// 합 — 자연스럽게 결합되는 결 (천간합 / 지지합).
  hap,

  /// 충 — 흔들리며 다듬어지는 결 (지지충).
  chung,

  /// 형 — 약속과 책임이 깊게 묶인 결.
  hyeong,
}

extension PastLifeKeywordKey on PastLifeKeyword {
  /// JSON 풀의 templates / body_lines 키.
  String get key {
    switch (this) {
      case PastLifeKeyword.wonjin:
        return 'wonjin';
      case PastLifeKeyword.dohwa:
        return 'dohwa';
      case PastLifeKeyword.yeokma:
        return 'yeokma';
      case PastLifeKeyword.cheoneul:
        return 'cheoneul';
      case PastLifeKeyword.gongmang:
        return 'gongmang';
      case PastLifeKeyword.hap:
        return 'hap';
      case PastLifeKeyword.chung:
        return 'chung';
      case PastLifeKeyword.hyeong:
        return 'hyeong';
    }
  }

  /// 한국어 라벨 (UI 표시용).
  String get labelKo {
    switch (this) {
      case PastLifeKeyword.wonjin:
        return '원진살';
      case PastLifeKeyword.dohwa:
        return '도화살';
      case PastLifeKeyword.yeokma:
        return '역마살';
      case PastLifeKeyword.cheoneul:
        return '천을귀인';
      case PastLifeKeyword.gongmang:
        return '공망';
      case PastLifeKeyword.hap:
        return '합';
      case PastLifeKeyword.chung:
        return '충';
      case PastLifeKeyword.hyeong:
        return '형';
    }
  }
}

/// 전생 시나리오 1편 결과.
class PastLifeScenario {
  /// 추출된 keyword Set (1개 이상).
  final Set<PastLifeKeyword> keywords;

  /// 시나리오 본문 (KO, 5~8 문장).
  final String scenarioKo;

  /// 시나리오 머리줄 (keyword 대표 한 줄).
  final String headlineKo;

  /// 사용된 placeholder 값 (디버깅용).
  final String celebName;
  final String userName;
  final String era;
  final String userRole;
  final String celebRole;

  const PastLifeScenario({
    required this.keywords,
    required this.scenarioKo,
    required this.headlineKo,
    required this.celebName,
    required this.userName,
    required this.era,
    required this.userRole,
    required this.celebRole,
  });
}

class PastLifeService {
  static const String pathPool = 'assets/data/past_life_pool.json';

  static Map<String, dynamic>? _cache;

  /// 풀 비동기 로드 (런타임).
  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(pathPool);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  /// 테스트용 — JSON map 직접 주입 (rootBundle 없이 동작).
  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 캐시 초기화 (테스트 격리용).
  static void resetCacheForTest() {
    _cache = null;
  }

  // ─── 원진살(怨嗔煞) 6쌍 — 사용자 spec verbatim ────────────────────────────
  //   子-未 / 丑-午 / 寅-酉 / 卯-申 / 辰-亥 / 巳-戌
  //
  // 양방향: 子-未 == 未-子. 일지 기준 두 사람 사이 검출.
  static const List<Set<String>> _wonjinPairs = [
    {'子', '未'},
    {'丑', '午'},
    {'寅', '酉'},
    {'卯', '申'},
    {'辰', '亥'},
    {'巳', '戌'},
  ];

  /// 두 지지 사이 원진살 양방향 감지.
  ///
  /// 같은 지지(예: 子-子) 는 원진살이 아니므로 false. 6쌍 모두 서로 다른 두 지지의 결합.
  static bool hasWonjin(String userBranch, String celebBranch) {
    if (userBranch.isEmpty || celebBranch.isEmpty) return false;
    if (userBranch == celebBranch) return false;
    for (final pair in _wonjinPairs) {
      if (pair.contains(userBranch) && pair.contains(celebBranch)) {
        return true;
      }
    }
    return false;
  }

  /// 두 사주 (사용자 + 셀럽) → keyword 추출.
  ///
  /// 추출 규칙:
  ///   - 원진살: 두 일지 사이 원진 쌍 → wonjin
  ///   - 지지합: 두 일지 사이 합 → hap
  ///   - 지지충: 두 일지 사이 충 → chung
  ///   - 천간합: 두 일간 사이 합 → hap
  ///   - 형: 두 일지 사이 형(三刑/自刑/子卯刑) → hyeong
  ///   - 도화: 사용자 일지 기준 도화 = 셀럽 일지, 또는 그 반대 → dohwa
  ///   - 역마: 사용자 일지 기준 역마 = 셀럽 일지, 또는 그 반대 → yeokma
  ///   - 천을귀인: 사용자 일간 기준 천을지지에 셀럽 일지 포함, 또는 반대 → cheoneul
  ///   - 공망: 사용자 일주 기준 공망지에 셀럽 일지 포함, 또는 반대 → gongmang
  ///
  /// 한 개도 매칭 안 되면 fallback 으로 `hap` 1종 반환 — 시나리오 생성이 항상 가능하게.
  static Set<PastLifeKeyword> extractKeywords(SajuResult user, SajuResult celeb) {
    final keywords = <PastLifeKeyword>{};

    final uJi = user.dayPillar.jiJi;
    final cJi = celeb.dayPillar.jiJi;
    final uGan = user.dayPillar.chunGan;
    final cGan = celeb.dayPillar.chunGan;
    final uDp = user.dayPillar.text;
    final cDp = celeb.dayPillar.text;

    // 원진살 — 신규 로직.
    if (hasWonjin(uJi, cJi)) keywords.add(PastLifeKeyword.wonjin);

    // 천간합 / 지지합.
    if (HapchungService.isCheonganHap(uGan, cGan)) {
      keywords.add(PastLifeKeyword.hap);
    }
    if (HapchungService.isJijiHap(uJi, cJi)) {
      keywords.add(PastLifeKeyword.hap);
    }

    // 충.
    if (HapchungService.isJijiChung(uJi, cJi)) {
      keywords.add(PastLifeKeyword.chung);
    }

    // 형 — 두 일지를 가상의 4기둥에 넣어 검사 (분리 호출).
    final hyungUserPerspective = HapchungService.findHyung(
      yearJi: user.yearPillar.jiJi,
      monthJi: user.monthPillar.jiJi,
      dayJi: uJi,
      hourJi: cJi, // 셀럽 일지를 hour 자리에 빌려 넣음 — 형(刑) 감지용
    );
    final hyungCelebPerspective = HapchungService.findHyung(
      yearJi: celeb.yearPillar.jiJi,
      monthJi: celeb.monthPillar.jiJi,
      dayJi: cJi,
      hourJi: uJi,
    );
    if (hyungUserPerspective.isNotEmpty || hyungCelebPerspective.isNotEmpty) {
      // 단, 자형(自刑) 만 잡힐 경우는 두 일지 같음이 조건이므로 skip.
      final hasRealHyung = [
        ...hyungUserPerspective,
        ...hyungCelebPerspective,
      ].any((h) => h.type != '自刑' || uJi != cJi);
      if (hasRealHyung) keywords.add(PastLifeKeyword.hyeong);
    }

    // 도화 — 일지 기준 도화 지지.
    final uDohwa = ShinsaService.dohwaFor(uJi);
    final cDohwa = ShinsaService.dohwaFor(cJi);
    if (uDohwa.isNotEmpty && cJi == uDohwa) keywords.add(PastLifeKeyword.dohwa);
    if (cDohwa.isNotEmpty && uJi == cDohwa) keywords.add(PastLifeKeyword.dohwa);

    // 역마 — 일지 기준 역마 지지.
    final uYeokma = ShinsaService.yokmaFor(uJi);
    final cYeokma = ShinsaService.yokmaFor(cJi);
    if (uYeokma.isNotEmpty && cJi == uYeokma) {
      keywords.add(PastLifeKeyword.yeokma);
    }
    if (cYeokma.isNotEmpty && uJi == cYeokma) {
      keywords.add(PastLifeKeyword.yeokma);
    }

    // 천을귀인 — 일간 기준 천을 2지지 set.
    final uCheonEul = ShinsaService.cheonEulGwiInFor(uGan);
    final cCheonEul = ShinsaService.cheonEulGwiInFor(cGan);
    if (uCheonEul.contains(cJi) || cCheonEul.contains(uJi)) {
      keywords.add(PastLifeKeyword.cheoneul);
    }

    // 공망 — 일주 기준 공망 2지지.
    final uGongMang = GongMangService.forDayPillar(uDp);
    final cGongMang = GongMangService.forDayPillar(cDp);
    if (uGongMang.contains(cJi) || cGongMang.contains(uJi)) {
      keywords.add(PastLifeKeyword.gongmang);
    }

    // Fallback — 한 개도 매칭 안 되면 hap (가장 무난한 결).
    if (keywords.isEmpty) keywords.add(PastLifeKeyword.hap);

    return keywords;
  }

  /// keyword + 셀럽 메타 → 시나리오 한 편 (5~8 문장).
  ///
  /// [seed] 가 주어지면 deterministic. 같은 seed → 같은 시나리오.
  /// 다른 seed → 다른 era / role / ending 조합.
  ///
  /// 풀 캐시가 비어 있으면 동기적으로 fallback 시나리오를 반환하므로
  /// 실 사용 전에 [seedForTest] 또는 [primeCache] 로 캐시를 채워 둬야 함.
  static String generateScenario({
    required SajuResult user,
    required SajuResult celeb,
    required String celebName,
    required String userName,
    int? seed,
  }) {
    final pool = _cache;
    if (pool == null) {
      // 풀 미로드 — async primeCache 누락. 안전한 최소 fallback 문장 반환.
      return _hardFallback(userName: userName, celebName: celebName);
    }
    final keywords = extractKeywords(user, celeb);
    final scenario = _composeFromPool(
      pool: pool,
      keywords: keywords,
      user: user,
      celeb: celeb,
      celebName: celebName,
      userName: userName,
      seed: seed ?? _deriveSeed(user, celeb),
    );
    return scenario.scenarioKo;
  }

  /// 셀럽 + 사용자 → 전체 결과 (디버깅·UI 확장용).
  static Future<PastLifeScenario> generate({
    required SajuResult user,
    required SajuResult celeb,
    required String celebName,
    required String userName,
    int? seed,
  }) async {
    final pool = await _pool();
    final keywords = extractKeywords(user, celeb);
    return _composeFromPool(
      pool: pool,
      keywords: keywords,
      user: user,
      celeb: celeb,
      celebName: celebName,
      userName: userName,
      seed: seed ?? _deriveSeed(user, celeb),
    );
  }

  /// rootBundle 로드 후 캐시만 채움 (sync API 사용 직전 호출).
  static Future<void> primeCache() async {
    await _pool();
  }

  // ─── 내부: 시나리오 합성 ────────────────────────────────────────────
  static PastLifeScenario _composeFromPool({
    required Map<String, dynamic> pool,
    required Set<PastLifeKeyword> keywords,
    required SajuResult user,
    required SajuResult celeb,
    required String celebName,
    required String userName,
    required int seed,
  }) {
    final rng = Random(seed);

    final eras = (pool['eras'] as List).cast<String>();
    final relations = (pool['relations'] as List)
        .cast<Map<String, dynamic>>()
        .map((m) => (user: m['user'] as String, celeb: m['celeb'] as String))
        .toList();
    final endings = (pool['endings'] as List).cast<String>();
    final templates = pool['templates'] as Map<String, dynamic>;
    final bodyLines = pool['body_lines'] as Map<String, dynamic>;

    // primary keyword = priority 순서로 첫 매칭.
    final primary = _pickPrimary(keywords);
    final tpl = templates[primary.key] as Map<String, dynamic>;
    final intros = (tpl['intros'] as List).cast<String>();
    final tails = (tpl['tails'] as List).cast<String>();
    final bodies = (bodyLines[primary.key] as List).cast<String>();

    final era = eras[rng.nextInt(eras.length)];
    final rel = relations[rng.nextInt(relations.length)];
    final ending = endings[rng.nextInt(endings.length)];
    final intro = intros[rng.nextInt(intros.length)];
    final tail = tails[rng.nextInt(tails.length)];

    // 한국어 조사 — 받침 여부에 따라 이/가, 은/는, 을/를, 과/와 자동 결정.
    // 풀의 모든 한국어 템플릿은 placeholder + 공백 + 조사 (예: `$userName 과`) 형태로
    // 작성돼 있음. 이름의 받침 여부와 무관하게 자연스러운 한국어가 되려면 inject 시
    // 공백을 제거하고 받침에 맞는 조사로 치환해야 함.
    // "역할였" 보정 — 받침 있을 시 "였" → "이었" (예: "매표원였" → "매표원이었").
    String fixCopula(String role) {
      final hasFinal = josa.hasFinalConsonant(role);
      return hasFinal ? '$role이었' : '$role였';
    }

    String inject(String tmpl) {
      var s = tmpl;
      // userName 조사 — 공백 strip + 받침 맞춤.
      s = s.replaceAll(
          r'$userName 과', '$userName${josa.withWith(userName)}');
      s = s.replaceAll(
          r'$userName 와', '$userName${josa.withWith(userName)}');
      s = s.replaceAll(r'$userName 은', '$userName${josa.withTop(userName)}');
      s = s.replaceAll(r'$userName 는', '$userName${josa.withTop(userName)}');
      s = s.replaceAll(r'$userName 이', '$userName${josa.withSubj(userName)}');
      s = s.replaceAll(r'$userName 을', '$userName${josa.withObj(userName)}');
      s = s.replaceAll(r'$userName 의', '$userName의');
      // celebName 조사.
      s = s.replaceAll(
          r'$celebName 과', '$celebName${josa.withWith(celebName)}');
      s = s.replaceAll(
          r'$celebName 와', '$celebName${josa.withWith(celebName)}');
      s = s.replaceAll(
          r'$celebName 은', '$celebName${josa.withTop(celebName)}');
      s = s.replaceAll(
          r'$celebName 는', '$celebName${josa.withTop(celebName)}');
      s = s.replaceAll(
          r'$celebName 이', '$celebName${josa.withSubj(celebName)}');
      s = s.replaceAll(
          r'$celebName 을', '$celebName${josa.withObj(celebName)}');
      s = s.replaceAll(r'$celebName 의', '$celebName의');
      // userRole + 였 → 받침 맞춰 "이었" 또는 "였".
      s = s.replaceAll(r'$userRole 였', fixCopula(rel.user));
      s = s.replaceAll(r'$userRole 은', '${rel.user}${josa.withTop(rel.user)}');
      // celebRole + 였.
      s = s.replaceAll(r'$celebRole 였', fixCopula(rel.celeb));
      s = s.replaceAll(
          r'$celebRole 은', '${rel.celeb}${josa.withTop(rel.celeb)}');
      s = s.replaceAll(
          r'$celebRole 이', '${rel.celeb}${josa.withSubj(rel.celeb)}');
      // Plain placeholder fallback — 남은 placeholder 모두 치환.
      s = s.replaceAll(r'$celebName', celebName);
      s = s.replaceAll(r'$userName', userName);
      s = s.replaceAll(r'$userRole', rel.user);
      s = s.replaceAll(r'$celebRole', rel.celeb);
      return s;
    }

    // 머리 문장 — "당신과 솔라는 1800년대 ... 에서 만났습니다" 톤.
    // 사용자 verbatim 첫 예시 그대로: "당신과 솔라는 ..." 형.
    final headerSentence =
        '$userName${josa.withWith(userName)} $celebName${josa.withTop(celebName)} $era에서 처음 마주쳤어요.';

    final sentences = <String>[
      headerSentence,
      inject(intro),
      ...bodies.map(inject),
      inject(ending),
      inject(tail),
    ];

    // 5~8 문장으로 다듬기 — body 3 + 4 fixed = 7. 안전 범위.
    final composed = sentences.where((s) => s.trim().isNotEmpty).join(' ');
    final headline = '$userName 과 $celebName 의 전생 — ${primary.labelKo} 결';

    return PastLifeScenario(
      keywords: keywords,
      scenarioKo: composed,
      headlineKo: headline,
      celebName: celebName,
      userName: userName,
      era: era,
      userRole: rel.user,
      celebRole: rel.celeb,
    );
  }

  /// keyword 우선순위 — 첫 매칭이 본문 톤을 결정.
  /// 1. wonjin (사용자 verbatim 예시의 핵심)
  /// 2. cheoneul (가장 보호적인 인연)
  /// 3. dohwa (덕질 일반)
  /// 4. yeokma
  /// 5. hyeong
  /// 6. chung
  /// 7. gongmang
  /// 8. hap (fallback)
  static PastLifeKeyword _pickPrimary(Set<PastLifeKeyword> keywords) {
    const order = [
      PastLifeKeyword.wonjin,
      PastLifeKeyword.cheoneul,
      PastLifeKeyword.dohwa,
      PastLifeKeyword.yeokma,
      PastLifeKeyword.hyeong,
      PastLifeKeyword.chung,
      PastLifeKeyword.gongmang,
      PastLifeKeyword.hap,
    ];
    for (final k in order) {
      if (keywords.contains(k)) return k;
    }
    return PastLifeKeyword.hap;
  }

  /// seed 미명시 시 deterministic seed — 두 사주 day pillar + 사용자 나이.
  static int _deriveSeed(SajuResult user, SajuResult celeb) {
    final s = '${user.dayPillar.text}|${celeb.dayPillar.text}|'
        '${user.yearPillar.text}|${celeb.yearPillar.text}';
    return s.hashCode & 0x7fffffff;
  }

  /// hard fallback — 풀 미로드 시 안전한 한국어 문장.
  static String _hardFallback(
      {required String userName, required String celebName}) {
    return '$userName 과 $celebName 의 전생 이야기는 곧 들려드릴게요. 잠시만 기다려 주세요.';
  }
}
