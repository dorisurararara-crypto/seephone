// Pillar Seer — 전생 시나리오 서비스 (R101 sprint 4, 팬심 1순위).
//
// 입력: 사용자 사주 + 셀럽 사주 + 이름 2종 (+ R104: 셀럽 kind).
// 출력: keyword Set + KO 전생 시나리오 한 편.
//
// R104 sprint 3 — story arc 엔진:
//   - story_arcs[keywordId] 가 있으면 arc 단위 단일 선택 (완결 기승전결,
//     4문단 8~10문장, kind별 현대 punchline). seed deterministic.
//   - story_arcs 가 없거나 invalid 하면 기존 slot 조립으로 fallback —
//     Sprint 4 content 추가 전 중간 상태에서도 앱이 정상 동작.
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

  /// 신호 없음 — 합·충·형 등 뚜렷한 인연 신호가 하나도 매칭되지 않은 결.
  ///
  /// R107 #9-1: 종전에는 매칭 0 일 때 [hap] 를 강제로 채웠다. 하지만 [hap] 시나리오는
  /// "합의 기운이 둘을 묶었다" 처럼 실제로 없는 합(合)을 있는 것처럼 서술한다 = 거짓.
  /// 이제 매칭 0 이면 거짓 합 대신 [neutral] — "뚜렷한 인연 신호가 약한" 정직한
  /// 시나리오로 분기한다. 없는 합·충을 있는 척하지 않는다.
  neutral,
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
      case PastLifeKeyword.neutral:
        return 'neutral';
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
      case PastLifeKeyword.neutral:
        return '잔잔한 인연';
    }
  }

  /// R106 P5 — 영어 라벨 (앱 언어 = 영어 시 UI 표시용).
  /// 한자 술어를 자연스러운 영어 명사구로 옮긴 것 — 단정 금지 voice 와 일관.
  String get labelEn {
    switch (this) {
      case PastLifeKeyword.wonjin:
        return 'love-hate bond';
      case PastLifeKeyword.dohwa:
        return 'magnetic pull';
      case PastLifeKeyword.yeokma:
        return 'restless streak';
      case PastLifeKeyword.cheoneul:
        return 'protective tie';
      case PastLifeKeyword.gongmang:
        return 'empty-space tie';
      case PastLifeKeyword.hap:
        return 'natural accord';
      case PastLifeKeyword.chung:
        return 'refining friction';
      case PastLifeKeyword.hyeong:
        return 'bound promise';
      case PastLifeKeyword.neutral:
        return 'quiet bond';
    }
  }
}

/// R108 ② — 장편 전생 스토리의 챕터 1편.
///
/// [body] 는 placeholder 치환이 끝난 한국어 본문. 화면이 [heading] 소제목 +
/// [body] 단락으로 렌더한다.
class PastLifeChapter {
  /// 챕터 번호 (1부터).
  final int no;

  /// 챕터 소제목.
  final String heading;

  /// 챕터 본문 ($userName/$celebName 치환 완료).
  final String body;

  const PastLifeChapter({
    required this.no,
    required this.heading,
    required this.body,
  });
}

/// 전생 시나리오 1편 결과.
class PastLifeScenario {
  /// 추출된 keyword Set (1개 이상).
  final Set<PastLifeKeyword> keywords;

  /// 시나리오 본문 (KO). 장편이면 챕터+epilogue 를 이은 평문, 단편이면 조립 결과.
  final String scenarioKo;

  /// 시나리오 머리줄 (keyword 대표 한 줄).
  final String headlineKo;

  /// R106 P5 — 시나리오 본문 (EN). 앱 언어 = 영어 시 화면이 분기해서 노출.
  /// 한국어 [scenarioKo] 와 동일 keyword/era/role 구조의 영어 단편.
  final String scenarioEn;

  /// R106 P5 — 시나리오 머리줄 (EN).
  final String headlineEn;

  /// 사용된 placeholder 값 (디버깅용).
  final String celebName;
  final String userName;
  final String era;
  final String userRole;
  final String celebRole;

  /// R108 ② — 장편 메타. 장편 arc 면 채워지고, 단편 fallback 이면 빈 값.
  /// [chapters] 가 비어 있지 않으면 화면은 장편 리더 UI 로 분기한다.
  final bool isLongform;

  /// 장르 (UI 메타칩). 장편이 아니면 빈 문자열.
  final String genre;

  /// 작품 제목 (UI 헤드라인). 장편이 아니면 빈 문자열.
  final String title;

  /// 1줄 시놉시스 (UI 부제). 장편이 아니면 빈 문자열.
  final String logline;

  /// 예상 읽기 분 (UI 표시). 장편이 아니면 0.
  final int estReadMinutes;

  /// 챕터 배열 (치환 완료). 장편이 아니면 빈 리스트.
  final List<PastLifeChapter> chapters;

  /// 전생→현생 연결 한 문단 (치환 완료). 장편이 아니면 빈 문자열.
  final String epilogue;

  const PastLifeScenario({
    required this.keywords,
    required this.scenarioKo,
    required this.headlineKo,
    this.scenarioEn = '',
    this.headlineEn = '',
    required this.celebName,
    required this.userName,
    required this.era,
    required this.userRole,
    required this.celebRole,
    this.isLongform = false,
    this.genre = '',
    this.title = '',
    this.logline = '',
    this.estReadMinutes = 0,
    this.chapters = const [],
    this.epilogue = '',
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
  /// 한 개도 매칭 안 되면 fallback 으로 `neutral` 1종 반환 — 시나리오 생성은
  /// 항상 가능하되, 실제로 없는 합(合)을 있는 척하지 않는다 (R107 #9-1).
  static Set<PastLifeKeyword> extractKeywords(
    SajuResult user,
    SajuResult celeb,
  ) {
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

    // R107 #9-1 — 매칭 0 이면 neutral.
    // 종전 fallback 은 hap 강제였으나, hap 시나리오는 "합의 기운이 둘을 묶었다"
    // 처럼 실제로 없는 합(合)을 서술 = 거짓. 거짓 합 대신 "뚜렷한 인연 신호가
    // 약한" 정직한 결로 분기한다. 없는 합·충을 있는 척 0.
    if (keywords.isEmpty) keywords.add(PastLifeKeyword.neutral);

    return keywords;
  }

  /// keyword + 셀럽 메타 → 시나리오 한 편.
  ///
  /// R104 sprint 3: story_arcs 가 있으면 arc 단위 단일 선택(완결 기승전결,
  /// 4문단 8~10문장). 없으면 기존 slot 조립으로 fallback.
  ///
  /// [seed] 가 주어지면 deterministic. 같은 seed → 같은 시나리오.
  /// [kind] 는 셀럽 분류 (idol/actor/athlete/icon). story arc 의 현대 punchline
  /// 분기에 쓰이며, unknown / 미명시 시 icon fallback.
  ///
  /// 풀 캐시가 비어 있으면 동기적으로 fallback 시나리오를 반환하므로
  /// 실 사용 전에 [seedForTest] 또는 [primeCache] 로 캐시를 채워 둬야 함.
  static String generateScenario({
    required SajuResult user,
    required SajuResult celeb,
    required String celebName,
    required String userName,
    int? seed,
    String kind = 'icon',
  }) {
    final pool = _cache;
    if (pool == null) {
      // 풀 미로드 — async primeCache 누락. 안전한 최소 fallback 문장 반환.
      return _hardFallback(userName: userName, celebName: celebName);
    }
    final keywords = extractKeywords(user, celeb);
    final scenario = _compose(
      pool: pool,
      keywords: keywords,
      user: user,
      celeb: celeb,
      celebName: celebName,
      userName: userName,
      seed: seed ?? _deriveSeed(user, celeb),
      kind: kind,
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
    String kind = 'icon',
  }) async {
    final pool = await _pool();
    final keywords = extractKeywords(user, celeb);
    return _compose(
      pool: pool,
      keywords: keywords,
      user: user,
      celeb: celeb,
      celebName: celebName,
      userName: userName,
      seed: seed ?? _deriveSeed(user, celeb),
      kind: kind,
    );
  }

  /// rootBundle 로드 후 캐시만 채움 (sync API 사용 직전 호출).
  static Future<void> primeCache() async {
    await _pool();
  }

  // ─── 내부: 시나리오 합성 dispatcher (R104 sprint 3) ───────────────────
  //
  // story_arcs[keyword] 가 존재하고 비어 있지 않으면 arc 단위 단일 선택 경로.
  // 그렇지 않으면 (Sprint 4 content 추가 전 상태 포함) 기존 slot 조립 경로로
  // fallback — R104 중간 상태에서 앱이 깨지지 않게 보장.
  static PastLifeScenario _compose({
    required Map<String, dynamic> pool,
    required Set<PastLifeKeyword> keywords,
    required SajuResult user,
    required SajuResult celeb,
    required String celebName,
    required String userName,
    required int seed,
    required String kind,
  }) {
    final primary = _pickPrimary(keywords);
    final arc = _selectStoryArc(pool, primary.key, seed);
    final PastLifeScenario base;
    if (arc != null) {
      base = _composeFromStoryArc(
        pool: pool,
        arc: arc,
        keywords: keywords,
        primary: primary,
        celebName: celebName,
        userName: userName,
        seed: seed,
        kind: kind,
      );
    } else {
      // story_arcs 미존재 / invalid → 기존 slot 조립 fallback.
      base = _composeFromPool(
        pool: pool,
        keywords: keywords,
        user: user,
        celeb: celeb,
        celebName: celebName,
        userName: userName,
        seed: seed,
      );
    }
    // R106 P5 — 영어 본문/머리줄을 같은 seed/keyword 로 추가 생성해 base 에 부착.
    // 한국어 필드(scenarioKo/headlineKo)는 절대 변경 안 함 — 영어는 추가만.
    return _attachEnglish(
      base: base,
      pool: pool,
      primary: primary,
      celebName: celebName,
      userName: userName,
      seed: seed,
      kind: kind,
    );
  }

  // ─── 내부: 영어 본문 합성 (R106 P5) ────────────────────────────────────
  //
  // story_arcs_en[keyword] 에서 한국어 경로와 동일 seed 로 arc 1개를 선택해
  // 영어 단편을 만든다. 영어 풀이 없거나 invalid 하면 영어 필드는 빈 문자열로
  // 둔다(화면이 useKo 분기 시 한국어를 노출하므로 앱은 깨지지 않음).
  //
  // 영어 placeholder 치환은 plain string replace (josa 보정 불필요).
  static PastLifeScenario _attachEnglish({
    required PastLifeScenario base,
    required Map<String, dynamic> pool,
    required PastLifeKeyword primary,
    required String celebName,
    required String userName,
    required int seed,
    required String kind,
  }) {
    final arcEn = _selectStoryArcEn(pool, primary.key, seed);
    if (arcEn == null) {
      return base; // 영어 풀 없음 → scenarioEn/headlineEn 빈 채로.
    }
    final rng = Random(seed);

    // $era — arc 의 eraHints(EN) 우선, 없으면 전역 eras_en fallback.
    final eraHints = (arcEn['eraHints'] is List)
        ? (arcEn['eraHints'] as List).whereType<String>().toList()
        : const <String>[];
    final String era;
    if (eraHints.isNotEmpty) {
      era = eraHints[rng.nextInt(eraHints.length)];
    } else {
      final eras = (pool['eras_en'] is List)
          ? (pool['eras_en'] as List).whereType<String>().toList()
          : const <String>[];
      era = eras.isNotEmpty ? eras[rng.nextInt(eras.length)] : 'a far-off age';
    }

    final userRole = (arcEn['userRole'] as String?)?.trim() ?? 'a traveler';
    final celebRole = (arcEn['celebRole'] as String?)?.trim() ?? 'a companion';

    String inject(String src) => src
        .replaceAll(r'$era', era)
        .replaceAll(r'$userRole', userRole)
        .replaceAll(r'$celebRole', celebRole)
        .replaceAll(r'$userName', userName)
        .replaceAll(r'$celebName', celebName);

    final paragraphs = arcEn['paragraphs'] as Map;
    final gi = inject(paragraphs['gi'] as String);
    final seung = inject(paragraphs['seung'] as String);
    final jeon = inject(paragraphs['jeon'] as String);
    var gyeol = inject(paragraphs['gyeol'] as String);

    final punchlineRaw = _arcPunchline(arcEn, kind);
    if (punchlineRaw.isNotEmpty) {
      gyeol = '${gyeol.trim()} ${inject(punchlineRaw).trim()}';
    }

    final scenarioEn = [gi, seung, jeon, gyeol]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    final headlineEn =
        "$userName & $celebName's past life — a ${primary.labelEn}";

    return PastLifeScenario(
      keywords: base.keywords,
      scenarioKo: base.scenarioKo,
      headlineKo: base.headlineKo,
      scenarioEn: scenarioEn,
      headlineEn: headlineEn,
      celebName: base.celebName,
      userName: base.userName,
      era: base.era,
      userRole: base.userRole,
      celebRole: base.celebRole,
      // R108 ② — 장편 메타는 KO base 에서 그대로 carry (EN longform 은 Sprint 9).
      isLongform: base.isLongform,
      genre: base.genre,
      title: base.title,
      logline: base.logline,
      estReadMinutes: base.estReadMinutes,
      chapters: base.chapters,
      epilogue: base.epilogue,
    );
  }

  /// story_arcs_en[keywordId] 에서 seed deterministic 하게 영어 arc 1개 선택.
  /// 키 없음 / 빈 리스트 / 유효 arc 0 이면 null.
  static Map<String, dynamic>? _selectStoryArcEn(
    Map<String, dynamic> pool,
    String keywordId,
    int seed,
  ) {
    final raw = pool['story_arcs_en'];
    if (raw is! Map) return null;
    final arcsRaw = raw[keywordId];
    if (arcsRaw is! List || arcsRaw.isEmpty) return null;
    final valid = <Map<String, dynamic>>[];
    for (final a in arcsRaw) {
      if (a is Map && _isValidArc(a)) {
        valid.add(a.cast<String, dynamic>());
      }
    }
    if (valid.isEmpty) return null;
    // 한국어 경로 _selectStoryArc 와 동일한 seed 소비 패턴 → EN/KO arc 정합.
    final idx = Random(seed).nextInt(valid.length);
    return valid[idx];
  }

  /// story_arcs[keywordId] 에서 seed deterministic 하게 arc 1개 선택.
  ///
  /// story_arcs 키가 없거나, 해당 keyword 가 없거나, 리스트가 비어 있거나,
  /// 유효한 arc(=gi/seung/jeon/gyeol 4문단 string 보유)가 하나도 없으면 null.
  /// null 이면 호출부는 slot fallback 으로 동작.
  static Map<String, dynamic>? _selectStoryArc(
    Map<String, dynamic> pool,
    String keywordId,
    int seed,
  ) {
    final storyArcsRaw = pool['story_arcs'];
    if (storyArcsRaw is! Map) return null;
    final arcsRaw = storyArcsRaw[keywordId];
    if (arcsRaw is! List || arcsRaw.isEmpty) return null;
    // 유효한 arc 만 후보로. invalid arc 는 skip 하되, 하나라도 유효하면 사용.
    final valid = <Map<String, dynamic>>[];
    for (final a in arcsRaw) {
      if (a is Map && _isValidArc(a)) {
        valid.add(a.cast<String, dynamic>());
      }
    }
    if (valid.isEmpty) return null;
    // seed deterministic 선택 — 같은 seed → 같은 arc.
    final idx = Random(seed).nextInt(valid.length);
    return valid[idx];
  }

  /// arc shape 검증.
  ///
  /// R108 ②: `format == "longform"` 이면 장편 검증 — chapters 가 비어 있지 않고
  /// 각 원소가 `{no, heading, body}` 를 가지며 body 가 non-empty, epilogue 가
  /// non-empty 면 valid. 그 외(구 schema)는 기존 paragraphs gi/seung/jeon/gyeol
  /// 4 string 검증을 유지 — 마이그레이션 중간 상태 호환.
  static bool _isValidArc(Map arc) {
    if (arc['format'] == 'longform') {
      return _isValidLongformArc(arc);
    }
    final p = arc['paragraphs'];
    if (p is! Map) return false;
    for (final k in const ['gi', 'seung', 'jeon', 'gyeol']) {
      final v = p[k];
      if (v is! String || v.trim().isEmpty) return false;
    }
    return true;
  }

  /// 장편 arc shape 검증 — chapters[{no,heading,body}] + epilogue.
  static bool _isValidLongformArc(Map arc) {
    final chapters = arc['chapters'];
    if (chapters is! List || chapters.isEmpty) return false;
    for (final c in chapters) {
      if (c is! Map) return false;
      if (c['no'] is! int) return false;
      final h = c['heading'];
      if (h is! String || h.trim().isEmpty) return false;
      final b = c['body'];
      if (b is! String || b.trim().isEmpty) return false;
    }
    final ep = arc['epilogue'];
    if (ep is! String || ep.trim().isEmpty) return false;
    return true;
  }

  /// kind → modernPunchlineByKind 키 정규화. unknown 은 icon fallback.
  static String _normalizeKind(String kind) {
    const known = {'idol', 'actor', 'athlete', 'icon'};
    return known.contains(kind) ? kind : 'icon';
  }

  // ─── 내부: story arc 단위 합성 (R104 sprint 3) ────────────────────────
  //
  // arc 하나가 원인→사건→전환→이번 생 punchline 의 완결 단편. 4문단(기/승/전/결)
  // + kind별 현대 punchline 을 조합. 슬롯 random 조립이 아니므로 항상 기승전결.
  static PastLifeScenario _composeFromStoryArc({
    required Map<String, dynamic> pool,
    required Map<String, dynamic> arc,
    required Set<PastLifeKeyword> keywords,
    required PastLifeKeyword primary,
    required String celebName,
    required String userName,
    required int seed,
    required String kind,
  }) {
    // R108 ② — 장편 arc 면 챕터 합성 경로로 분기. era/role 주입·cap/diversify
    // 는 장편에 부적합하므로 bypass (긴 의도적 반복을 깨지 않음).
    if (arc['format'] == 'longform') {
      return _composeLongform(
        arc: arc,
        keywords: keywords,
        primary: primary,
        celebName: celebName,
        userName: userName,
      );
    }
    final rng = Random(seed);

    // $era — arc 의 eraHints 중 seed deterministic 선택, 없으면 전역 eras fallback.
    final eraHints = (arc['eraHints'] is List)
        ? (arc['eraHints'] as List).whereType<String>().toList()
        : const <String>[];
    final String era;
    if (eraHints.isNotEmpty) {
      era = eraHints[rng.nextInt(eraHints.length)];
    } else {
      final eras = (pool['eras'] is List)
          ? (pool['eras'] as List).whereType<String>().toList()
          : const <String>[];
      era = eras.isNotEmpty ? eras[rng.nextInt(eras.length)] : '먼 옛날';
    }

    // $userRole / $celebRole — arc 가 직접 명시. 누락 시 전역 relations fallback.
    String userRole = (arc['userRole'] as String?)?.trim() ?? '';
    String celebRole = (arc['celebRole'] as String?)?.trim() ?? '';
    if (userRole.isEmpty || celebRole.isEmpty) {
      final relations = (pool['relations'] is List)
          ? (pool['relations'] as List).whereType<Map>().toList()
          : const <Map>[];
      if (relations.isNotEmpty) {
        final rel = relations[rng.nextInt(relations.length)];
        if (userRole.isEmpty) userRole = (rel['user'] as String?) ?? '나그네';
        if (celebRole.isEmpty) celebRole = (rel['celeb'] as String?) ?? '벗';
      } else {
        if (userRole.isEmpty) userRole = '나그네';
        if (celebRole.isEmpty) celebRole = '벗';
      }
    }

    // placeholder inject — 기존 josa 보정 로직 재사용.
    final injector = _PlaceholderInjector(
      userName: userName,
      celebName: celebName,
      userRole: userRole,
      celebRole: celebRole,
      era: era,
    );

    final paragraphs = arc['paragraphs'] as Map;
    final gi = injector.inject(paragraphs['gi'] as String);
    final seung = injector.inject(paragraphs['seung'] as String);
    final jeon = injector.inject(paragraphs['jeon'] as String);
    var gyeol = injector.inject(paragraphs['gyeol'] as String);

    // kind 별 현대 punchline — gyeol 마지막에 append. unknown → icon fallback.
    final punchlineRaw = _arcPunchline(arc, kind);
    if (punchlineRaw.isNotEmpty) {
      final punchline = injector.inject(punchlineRaw);
      gyeol = '${gyeol.trim()} ${punchline.trim()}';
    }

    // 4문단 join → 반복 어구 cap / 결말 다양화 (기존 회귀 가드 보존).
    final composedRaw = [
      gi,
      seung,
      jeon,
      gyeol,
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');
    final composed = _diversifyEndings(_capRepetition(composedRaw, rng), rng);

    // headline — 기존 josa helper 패턴 보존.
    final headline = _headlineFor(primary, userName, celebName);

    return PastLifeScenario(
      keywords: keywords,
      scenarioKo: composed,
      headlineKo: headline,
      celebName: celebName,
      userName: userName,
      era: era,
      userRole: userRole,
      celebRole: celebRole,
    );
  }

  // ─── 내부: 장편 합성 (R108 ②) ─────────────────────────────────────────
  //
  // longform arc = 챕터 배열 + epilogue. era/userRole/celebRole 주입은 prose 에
  // 고정돼 있어 불필요 — 본문 변수는 $userName / $celebName 2종만 치환한다.
  // cap/diversify 는 장편의 의도적 반복(여운·후렴)을 깨므로 적용하지 않는다.
  static PastLifeScenario _composeLongform({
    required Map<String, dynamic> arc,
    required Set<PastLifeKeyword> keywords,
    required PastLifeKeyword primary,
    required String celebName,
    required String userName,
  }) {
    // 장편은 $userName/$celebName 2종만. era/role 은 빈 값으로 둬 collision 회피.
    final injector = _PlaceholderInjector(
      userName: userName,
      celebName: celebName,
      userRole: '',
      celebRole: '',
      era: '',
    );

    final rawChapters = (arc['chapters'] is List)
        ? (arc['chapters'] as List)
        : const <dynamic>[];
    final chapters = <PastLifeChapter>[];
    for (final c in rawChapters) {
      if (c is! Map) continue;
      final no = c['no'] is int ? c['no'] as int : chapters.length + 1;
      final heading = injector.inject((c['heading'] as String?) ?? '');
      final body = injector.inject((c['body'] as String?) ?? '');
      chapters.add(PastLifeChapter(no: no, heading: heading, body: body));
    }
    final epilogue = injector.inject((arc['epilogue'] as String?) ?? '');

    // scenarioKo — 챕터 본문 + epilogue 평문 join (하위호환: 기존 test/screen 이
    // scenarioKo 를 참조). 챕터 사이는 빈 줄로 구분.
    final parts = <String>[
      for (final ch in chapters)
        if (ch.body.trim().isNotEmpty) ch.body.trim(),
      if (epilogue.trim().isNotEmpty) epilogue.trim(),
    ];
    final scenarioKo = parts.join('\n\n');

    final headline = _headlineFor(primary, userName, celebName);

    return PastLifeScenario(
      keywords: keywords,
      scenarioKo: scenarioKo,
      headlineKo: headline,
      celebName: celebName,
      userName: userName,
      era: (arc['era'] as String?) ?? '',
      userRole: '',
      celebRole: '',
      isLongform: true,
      genre: (arc['genre'] as String?) ?? '',
      title: injector.inject((arc['title'] as String?) ?? ''),
      logline: injector.inject((arc['logline'] as String?) ?? ''),
      estReadMinutes: arc['estReadMinutes'] is int
          ? arc['estReadMinutes'] as int
          : 0,
      chapters: chapters,
      epilogue: epilogue,
    );
  }

  /// 전생 headline 한 줄.
  ///
  /// 일반 keyword: "X와 Y의 전생 — 원진살 결" 처럼 "<라벨> 결".
  /// R107 #9-1 neutral: "결" 접미가 어색하므로 "<라벨>" 만 — 거짓 결(結) 단정 회피.
  static String _headlineFor(
    PastLifeKeyword primary,
    String userName,
    String celebName,
  ) {
    final base = '$userName${josa.withWith(userName)} $celebName의 전생 — ';
    if (primary == PastLifeKeyword.neutral) {
      return '$base${primary.labelKo}';
    }
    return '$base${primary.labelKo} 결';
  }

  /// arc 의 modernPunchlineByKind 에서 kind 별 punchline. unknown → icon fallback.
  static String _arcPunchline(Map<String, dynamic> arc, String kind) {
    final byKind = arc['modernPunchlineByKind'];
    if (byKind is! Map) return '';
    final norm = _normalizeKind(kind);
    final v = byKind[norm];
    if (v is String && v.trim().isNotEmpty) return v;
    // norm 에 해당 키가 비어 있으면 icon 으로 한 번 더 fallback.
    final fb = byKind['icon'];
    return (fb is String) ? fb : '';
  }

  // ─── 내부: slot 조립 합성 (fallback 경로 — R103 이하 호환) ──────────────
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
    // R103 sprint 1: header pool — 8+ variant 동적 선택. 누락 시 R102 hard-coded format fallback.
    final List<String> headers;
    if (tpl['headers'] is List) {
      headers = (tpl['headers'] as List).cast<String>();
    } else {
      headers = const <String>[];
    }

    // R102 sprint 2: body_lines 가 4 phase 구조 (setup/event/turn/resolution).
    // R103 sprint 1: event_sub 추가 (사건 strand).
    // 구버전(flat list) 호환을 위해 List 분기 유지.
    final bodyEntry = bodyLines[primary.key];
    final List<String> setupLines;
    final List<String> eventLines;
    final List<String> eventSubLines;
    final List<String> bridgeLines;
    final List<String> turnLines;
    final List<String> resolutionLines;
    if (bodyEntry is Map) {
      setupLines = (bodyEntry['setup'] as List).cast<String>();
      eventLines = (bodyEntry['event'] as List).cast<String>();
      // event_sub 는 R103 신규. 없으면 빈 리스트로 두고 합성 단계에서 skip.
      eventSubLines = bodyEntry['event_sub'] is List
          ? (bodyEntry['event_sub'] as List).cast<String>()
          : const <String>[];
      // bridge 는 R103 신규 — event_sub 와 turn 사이 잔향 한 줄. 풀 ≥ 10 sentence 보장.
      bridgeLines = bodyEntry['bridge'] is List
          ? (bodyEntry['bridge'] as List).cast<String>()
          : const <String>[];
      turnLines = (bodyEntry['turn'] as List).cast<String>();
      resolutionLines = (bodyEntry['resolution'] as List).cast<String>();
    } else if (bodyEntry is List) {
      // 구버전 fallback — 같은 풀을 4 phase 로 split (균등 분배).
      final flat = bodyEntry.cast<String>();
      setupLines = flat.isNotEmpty
          ? [flat[0]]
          : <String>['$userName과 $celebName의 전생이 시작됐어요.'];
      eventLines = flat.length > 1 ? [flat[1]] : <String>['깊은 결이 흘렀어요.'];
      eventSubLines = const <String>[];
      bridgeLines = const <String>[];
      turnLines = flat.length > 2 ? [flat[2]] : <String>['시간이 갈라놓았어요.'];
      resolutionLines = <String>['그 결의 여운이 이번 생까지 따라왔어요.'];
    } else {
      setupLines = <String>['$userName과 $celebName의 전생이 시작됐어요.'];
      eventLines = <String>['깊은 결이 흘렀어요.'];
      eventSubLines = const <String>[];
      bridgeLines = const <String>[];
      turnLines = <String>['시간이 갈라놓았어요.'];
      resolutionLines = <String>['그 결의 여운이 이번 생까지 따라왔어요.'];
    }

    final era = eras[rng.nextInt(eras.length)];
    final rel = relations[rng.nextInt(relations.length)];
    final ending = endings[rng.nextInt(endings.length)];
    final intro = intros[rng.nextInt(intros.length)];
    final tail = tails[rng.nextInt(tails.length)];
    final setup = setupLines[rng.nextInt(setupLines.length)];
    final event = eventLines[rng.nextInt(eventLines.length)];
    final eventSub = eventSubLines.isNotEmpty
        ? eventSubLines[rng.nextInt(eventSubLines.length)]
        : '';
    final bridge = bridgeLines.isNotEmpty
        ? bridgeLines[rng.nextInt(bridgeLines.length)]
        : '';
    final turn = turnLines[rng.nextInt(turnLines.length)];
    final resolution = resolutionLines[rng.nextInt(resolutionLines.length)];
    // R103 sprint 1: header variant — pool에서 선택. 누락 시 R102 hard-coded.
    final headerTemplate = headers.isNotEmpty
        ? headers[rng.nextInt(headers.length)]
        : '';

    // 한국어 조사 — 받침 여부에 따라 이/가, 은/는, 을/를, 과/와 자동 결정.
    // 풀의 모든 한국어 템플릿은 placeholder + 공백 + 조사 (예: `$userName 과`) 형태로
    // 작성돼 있음. 이름의 받침 여부와 무관하게 자연스러운 한국어가 되려면 inject 시
    // 공백을 제거하고 받침에 맞는 조사로 치환해야 함.
    // "역할였" 보정 — 받침 있을 시 "였" → "이었" (예: "매표원였" → "매표원이었").
    String fixCopula(String role) {
      final hasFinal = josa.hasFinalConsonant(role);
      return hasFinal ? '$role이었' : '$role였';
    }

    // R102 sprint 2: 모든 placeholder × 조사 패턴 자연 결합.
    // 받침 의존 조사 (과/와 · 은/는 · 이/가 · 을/를 · 로/으로) 는 helper 로 받침 맞춤.
    // 받침 무관 조사 (도 · 에게 · 에서 · 에 · 부터 · 까지 · 보다 · 만 · 처럼
    //   · 조차 · 마저 · 뿐 · 한테 · 께) 는 공백만 strip.
    //
    // 풀에 `$X 조사` (공백 있음) 또는 `$X조사` (공백 없음) 둘 다 작성 가능.
    // inject 는 공백 유무 모두 처리.
    //
    // 처리 순서가 중요:
    //   - 받침 의존 조사를 placeholder 직후 즉시 잡지 못하면 plain fallback 에서
    //     placeholder 만 풀린 채 조사가 잔존.
    //   - 그래서 모든 받침 의존 / 받침 무관 조사를 placeholder 별로 다 잡은 후 plain
    //     fallback.
    const conJosas = ['과', '와']; // with
    const topJosas = ['은', '는']; // topic
    const subJosas = ['이', '가']; // subject
    const objJosas = ['을', '를']; // object
    const loJosas = ['로', '으로']; // direction
    // 받침 무관 (공백 strip 만, 받침 보정 X).
    const bareJosas = [
      '도',
      '에게',
      '한테',
      '께',
      '에서',
      '에',
      '부터',
      '까지',
      '보다',
      '만',
      '처럼',
      '조차',
      '마저',
      '뿐',
    ];
    // single-char trailing 조사 (의 등) — 받침 보정 불필요, "$X의" 형태로 결합.
    const dirJosas = ['의'];

    String replacePh(
      String src,
      String ph, // e.g. r'$userName'
      String name, // injected value
    ) {
      var t = src;
      // 1) 받침 의존 조사 — 공백 있는 형태 + 없는 형태 모두.
      String comp(List<String> set, String resolved) {
        return resolved;
      }

      // with — 과/와.
      final withRes = josa.withWith(name);
      for (final j in conJosas) {
        t = t.replaceAll('$ph $j', '$name${comp(conJosas, withRes)}');
        t = t.replaceAll('$ph$j', '$name${comp(conJosas, withRes)}');
      }
      // topic — 은/는.
      final topRes = josa.withTop(name);
      for (final j in topJosas) {
        t = t.replaceAll('$ph $j', '$name$topRes');
        t = t.replaceAll('$ph$j', '$name$topRes');
      }
      // subj — 이/가.
      final subRes = josa.withSubj(name);
      for (final j in subJosas) {
        t = t.replaceAll('$ph $j', '$name$subRes');
        t = t.replaceAll('$ph$j', '$name$subRes');
      }
      // obj — 을/를.
      final objRes = josa.withObj(name);
      for (final j in objJosas) {
        t = t.replaceAll('$ph $j', '$name$objRes');
        t = t.replaceAll('$ph$j', '$name$objRes');
      }
      // direction — 로/으로.
      //   받침 무: "로"   (예: 악사 → 악사로)
      //   ㄹ 받침: "로"   (예: 단골 → 단골로) — 한국어 예외
      //   기타 받침: "으로" (예: 행상 → 행상으로)
      String loRes;
      if (name.isEmpty) {
        loRes = '로';
      } else {
        final last = name.substring(name.length - 1);
        final cu = last.codeUnitAt(0);
        if (cu >= 0xAC00 && cu <= 0xD7A3) {
          final jong = (cu - 0xAC00) % 28;
          if (jong == 0) {
            loRes = '로'; // 받침 없음
          } else if (jong == 8) {
            loRes = '로'; // ㄹ 받침 예외
          } else {
            loRes = '으로';
          }
        } else {
          loRes = josa.hasFinalConsonant(name) ? '으로' : '로';
        }
      }
      for (final j in loJosas) {
        t = t.replaceAll('$ph $j', '$name$loRes');
        t = t.replaceAll('$ph$j', '$name$loRes');
      }
      // dir — 의 (받침 무관).
      for (final j in dirJosas) {
        t = t.replaceAll('$ph $j', '$name$j');
        t = t.replaceAll('$ph$j', '$name$j');
      }
      // bare — 도/에게/etc (받침 무관, 공백 strip).
      for (final j in bareJosas) {
        t = t.replaceAll('$ph $j', '$name$j');
        // 공백 없는 형태는 풀에 거의 없지만 방어적.
        t = t.replaceAll('$ph$j', '$name$j');
      }
      return t;
    }

    // "이었던" / "이었어요" 같은 copula + 어미 받침 보정 fragment.
    //   받침 있음: "행상" + "이었던" = "행상이었던"
    //   받침 없음: "악사" + "였던" = "악사였던"
    String wasParticiple(String role) {
      return josa.hasFinalConsonant(role) ? '$role이었던' : '$role였던';
    }

    // R103 sprint 5A — 받침 보정 + 길이 우선 compound suffix 처리.
    //
    // 문제:
    //   - `$userRole이라는` 가 generic `replacePh` 의 `이/가` (subj) 매치에 먼저 걸려
    //     "선비가라는" / "행상가라는" 류 깨짐 발생.
    //   - `$celebName 이름` 가 `$ph + " " + 이` (subj) 매치에 먼저 걸려
    //     "카리나가 름" / "카리나가름" 등 placeholder collision 발생.
    //
    // 해결:
    //   - generic `replacePh` 호출 전, 모든 compound 어미 (이라는 / 이었던 / 이었어요 /
    //     이었고 / 이에요 / 였 / 이름) 를 placeholder 별로 명시 치환.
    //   - 같은 placeholder 에 대해 긴 패턴부터 처리 (예: "이었어요" 먼저, "이었" 나중).
    //   - 공백 있는 형태 (예: "$X 이라는") 와 공백 없는 형태 둘 다 커버.
    //   - 받침 있음 / 없음 두 case 모두 자연스러운 한국어로 결합.
    //
    // 받침 보정 규칙 — copula `이/`였/이었` 계열:
    //   받침 있음: "행상" → "행상이었", "행상이라는", "행상이에요"
    //   받침 없음: "선비" → "선비였",   "선비라는",   "선비예요"
    //
    // `이름` 은 noun (이름 = name) — josa 가 아니므로 placeholder + 공백 + "이름" 유지.
    //   "$celebName 이름" → "<celebName> 이름" / "$celebName이름" → "<celebName> 이름".

    /// 받침 보정 — "이라는" (copula 인용형).
    /// 받침 있음: "$word이라는" / 받침 없음: "$word라는".
    String copulaIraneun(String word) {
      return josa.hasFinalConsonant(word) ? '$word이라는' : '$word라는';
    }

    /// 받침 보정 — "이었어요" (copula 과거 종결).
    String copulaIeoteoyo(String word) {
      return josa.hasFinalConsonant(word) ? '$word이었어요' : '$word였어요';
    }

    /// 받침 보정 — "이었고" (copula 과거 연결).
    String copulaIeotgo(String word) {
      return josa.hasFinalConsonant(word) ? '$word이었고' : '$word였고';
    }

    /// 받침 보정 — "이에요" (copula 현재 종결).
    String copulaIeyo(String word) {
      return josa.hasFinalConsonant(word) ? '$word이에요' : '$word예요';
    }

    /// `$ph + 이름` collision → `<word> 이름` (공백 분리, noun 유지).
    /// 공백 있는 형태 / 없는 형태 둘 다 동일 결과로 통일.
    String nameNoun(String word) => '$word 이름';

    /// `$ph + 이번` collision → `<word> 이번` (공백 유지, "이번 = this time" noun).
    /// 사용자 보고 verbatim: "김채원이번 활동 별로네" 부자연 → "김채원 이번 활동".
    String thisTimeNoun(String word) => '$word 이번';

    /// 한 placeholder 에 대해 compound suffix 를 길이 우선으로 모두 치환.
    /// 호출 후 남는 placeholder 는 generic replacePh + 마지막 plain fallback 으로 처리.
    String resolveCompound(String src, String ph, String word) {
      var t = src;
      // 1) 가장 긴 compound 부터 — 이었어요(4) / 이라는(3) / 이었고(3) / 이에요(3) / 이름(2).
      //    공백 있는 / 없는 형태 모두 커버.
      // 1-a) copula 과거 종결.
      t = t.replaceAll('$ph 이었어요', copulaIeoteoyo(word));
      t = t.replaceAll('$ph이었어요', copulaIeoteoyo(word));
      // 1-b) copula 인용형.
      t = t.replaceAll('$ph 이라는', copulaIraneun(word));
      t = t.replaceAll('$ph이라는', copulaIraneun(word));
      // 1-c) copula 과거 연결.
      t = t.replaceAll('$ph 이었고', copulaIeotgo(word));
      t = t.replaceAll('$ph이었고', copulaIeotgo(word));
      // 1-d) copula 현재 종결.
      t = t.replaceAll('$ph 이에요', copulaIeyo(word));
      t = t.replaceAll('$ph이에요', copulaIeyo(word));
      // 1-e) 이름 noun — placeholder collision 방지. 공백 유지.
      t = t.replaceAll('$ph 이름', nameNoun(word));
      t = t.replaceAll('$ph이름', nameNoun(word));
      // 1-f) 이번 noun — "이번 = this time". subj josa `이` 와 collision 방지.
      t = t.replaceAll('$ph 이번', thisTimeNoun(word));
      t = t.replaceAll('$ph이번', thisTimeNoun(word));
      return t;
    }

    String inject(String tmpl) {
      var s = tmpl;

      // STEP 0 — compound suffix 우선 처리 (Name + Role 4종 모두).
      // 길이 우선: "이었어요" / "이라는" / "이었고" / "이에요" / "이름" 이 generic
      // josa replacement 보다 먼저 매치되도록.
      s = resolveCompound(s, r'$userName', userName);
      s = resolveCompound(s, r'$celebName', celebName);
      s = resolveCompound(s, r'$userRole', rel.user);
      s = resolveCompound(s, r'$celebRole', rel.celeb);

      // STEP 1 — Role placeholder 의 "이었던" / "였" (R102 호환 유지).
      // resolveCompound 가 "이었어요" 까지 처리했으므로 여기는 "이었던" 만 남음.
      s = s.replaceAll(r'$userRole 이었던', wasParticiple(rel.user));
      s = s.replaceAll(r'$userRole이었던', wasParticiple(rel.user));
      s = s.replaceAll(r'$celebRole 이었던', wasParticiple(rel.celeb));
      s = s.replaceAll(r'$celebRole이었던', wasParticiple(rel.celeb));
      // "$userRole 였" → "악사였" / "행상이었". (이었던 / 이었어요 / 이었고 가 모두
      // 위에서 처리됐으므로 여기는 그 외 "였"+어미 fragment 만 남음.)
      s = s.replaceAll(r'$userRole 였', fixCopula(rel.user));
      s = s.replaceAll(r'$userRole였', fixCopula(rel.user));
      s = s.replaceAll(r'$celebRole 였', fixCopula(rel.celeb));
      s = s.replaceAll(r'$celebRole였', fixCopula(rel.celeb));

      // STEP 2 — Name + Role generic josa (은/는/이/가/을/를/과/와/로/으로/의/도/에게/...).
      s = replacePh(s, r'$userName', userName);
      s = replacePh(s, r'$celebName', celebName);
      s = replacePh(s, r'$userRole', rel.user);
      s = replacePh(s, r'$celebRole', rel.celeb);

      // STEP 3 — Plain placeholder fallback (조사 안 붙은 형태).
      s = s.replaceAll(r'$celebName', celebName);
      s = s.replaceAll(r'$userName', userName);
      s = s.replaceAll(r'$userRole', rel.user);
      s = s.replaceAll(r'$celebRole', rel.celeb);
      return s;
    }

    // 머리 문장 — R103 sprint 1: pool에서 동적 선택 (8+ variant). 누락 시 R102 hard-coded fallback.
    // placeholder = $userName / $celebName / $era. inject() 가 조사 보정.
    final String headerSentence;
    if (headerTemplate.isNotEmpty) {
      var h = headerTemplate;
      // $era placeholder 는 받침 무관 (era 텍스트는 "$era에서" 등 형태가 자유). 단순 치환.
      h = h.replaceAll(r'$era', era);
      headerSentence = inject(h);
    } else {
      headerSentence =
          '$userName${josa.withWith(userName)} $celebName${josa.withTop(celebName)} $era에서 처음 마주쳤어요.';
    }

    // R103 sprint 1 — 4막 흐름 (사용자 mandate "사건 strand 추가 / 좀 더 길어야 돼"):
    //   1막 (배경): header (시대 + 시작점) + intro (신분/갈등 시작)
    //   2막 (사건): setup (역할 명시) + event (사주살 기반 핵심 사건)
    //   3막 (전환): event_sub (구체 incident — R103 신규) + turn (미해결/이별)
    //   4막 (이번 생 punchline): resolution + ending + tail
    final composedSentences = <String>[
      headerSentence,
      inject(intro),
      inject(setup),
      inject(event),
      if (eventSub.isNotEmpty) inject(eventSub),
      if (bridge.isNotEmpty) inject(bridge),
      inject(turn),
      inject(resolution),
      inject(ending),
      inject(tail),
    ];
    // event_sub 가 있으면 9 문장, tail 이 1~2 문장이면 합쳐 10~11 문장. body_lines 의
    // 일부 line 자체가 두 문장으로 구성된 경우 (예: "X. Y.") 까지 합치면 10~14 sentence 범위.
    final sentences = composedSentences;

    // R102 sprint 2 — 반복 어휘 cap:
    //   "두 사람은" ≤ 2 / "자연스럽게" ≤ 1 / "결" (단독 어절) ≤ 2 /
    //   "당신과 X" 헤더 ≤ 2 / "이었어요" 결말 ≤ 3.
    final composedRaw = sentences.where((s) => s.trim().isNotEmpty).join(' ');
    final composed = _diversifyEndings(_capRepetition(composedRaw, rng), rng);

    // R102 sprint 2 headline — josa helper 적용.
    //   "X{와/과} Y의 전생 — {labelKo} 결" (neutral 은 "결" 접미 생략).
    final headline = _headlineFor(primary, userName, celebName);

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
  /// 8. hap
  /// 9. neutral (신호 0 일 때만 — 다른 keyword 가 하나라도 있으면 절대 선택 안 됨)
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
      PastLifeKeyword.neutral,
    ];
    for (final k in order) {
      if (keywords.contains(k)) return k;
    }
    // 빈 Set 방어 — extractKeywords 가 항상 1개 이상 반환하므로 도달 X.
    return PastLifeKeyword.neutral;
  }

  /// seed 미명시 시 deterministic seed — 두 사주 day pillar + 사용자 나이.
  static int _deriveSeed(SajuResult user, SajuResult celeb) {
    final s =
        '${user.dayPillar.text}|${celeb.dayPillar.text}|'
        '${user.yearPillar.text}|${celeb.yearPillar.text}';
    return s.hashCode & 0x7fffffff;
  }

  /// hard fallback — 풀 미로드 시 안전한 한국어 문장.
  static String _hardFallback({
    required String userName,
    required String celebName,
  }) {
    // R102 sprint 2: josa helper 사용 — 받침 무관 공백 strip.
    return '$userName${josa.withWith(userName)} '
        '$celebName의 전생 이야기는 곧 들려드릴게요. 잠시만 기다려 주세요.';
  }

  // ─── 내부: 반복 어휘 cap ────────────────────────────────────────────
  //
  // R102 sprint 2 — 사용자 불만 "툭툭 끊김 / 반복" 대응.
  // R103 sprint 1 — 사용자 mandate "다 똑같네" 강화:
  //   "사주상"          ≤ 1회 (R102=무제한)
  //   "이번 생"         ≤ 1회 (R102=무제한)
  //   "그 옛"           ≤ 1회 (R102=무제한)
  //   "두 사람은"       = 0회 (R102=2)
  //   "결이 두 사람 사이에" = 0회 (R102=무제한)
  //   "자연스럽게"      ≤ 1회 (유지)
  //   "결" 단독 어절    ≤ 2회 (유지)
  //   "이었어요"/"였어요" 결말 ≤ 3회 (유지)
  // 초과 분은 동의 표현으로 대체. 첫 등장은 그대로 둠. ("두 사람은" / "결이 두 사람
  // 사이에" 는 첫 등장부터 모두 치환 = cap 0).
  static String _capRepetition(String text, Random rng) {
    var s = text;

    // R103 sprint 1 — "사주상" cap 1.
    const sajuSangAlts = <String>['사주에 박힌', '사주의 결로', '사주에 새겨진', '사주가 짜 놓은 대로'];
    s = _cap(s, '사주상', 1, sajuSangAlts, rng);

    // R103 sprint 1 — "이번 생" cap 1.
    const ibunSaengAlts = <String>['지금 생', '오늘의 생', '여기 이 생', '이쪽 생'];
    s = _cap(s, '이번 생', 1, ibunSaengAlts, rng);

    // R103 sprint 1 — "그 옛" cap 1.
    // 주의: alts 에 "그 옛" substring 이 포함되면 안 됨 (반복 매치 함정).
    const gyeoutAlts = <String>['그때의', '그 시절', '오래전', '예전의'];
    s = _cap(s, '그 옛', 1, gyeoutAlts, rng);

    // R103 sprint 1 — "두 사람은" cap 0 (모두 치환).
    const twoPeopleAlts = <String>['둘은', '서로는', '둘 다'];
    s = _cap(s, '두 사람은', 0, twoPeopleAlts, rng);

    // R103 sprint 1 — "결이 두 사람 사이에" cap 0 (모두 치환).
    const jielSaiAlts = <String>['결이 둘 사이에', '그 결이 옅게', '결의 여운이', '결의 흔적이'];
    s = _cap(s, '결이 두 사람 사이에', 0, jielSaiAlts, rng);

    // R102 — "자연스럽게" 2회째부터 다른 부사.
    const naturalAlts = <String>['어색함 없이', '부드럽게', '익숙하게', '잔잔하게'];
    s = _cap(s, '자연스럽게', 1, naturalAlts, rng);

    // R102 — "결" 단독 어절 cap 2.
    s = _capStandaloneJiel(s, 2, rng);

    return s;
  }

  static String _cap(
    String text,
    String needle,
    int maxCount,
    List<String> alts,
    Random rng,
  ) {
    final out = StringBuffer();
    var cursor = 0;
    var hit = 0;
    while (true) {
      final idx = text.indexOf(needle, cursor);
      if (idx < 0) {
        out.write(text.substring(cursor));
        break;
      }
      out.write(text.substring(cursor, idx));
      hit++;
      if (hit <= maxCount) {
        out.write(needle);
      } else {
        out.write(alts[rng.nextInt(alts.length)]);
      }
      cursor = idx + needle.length;
    }
    return out.toString();
  }

  /// "결" 단독 어절 cap — 조사 안 붙은 형태만 카운트.
  static String _capStandaloneJiel(String text, int maxCount, Random rng) {
    const alts = <String>['흐름', '인연', '자국'];
    final out = StringBuffer();
    var hit = 0;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch != '결') {
        out.write(ch);
        continue;
      }
      // 다음 글자가 조사 (을/이/은/의/과/도/에/만/까지/로/등) 면 단독 아님.
      // R103 sprint 1: R102 test 호환 위해 attached set 좁게 유지 — 합성어 (결심/결정/
      // 결제/결단 등) 는 JSON pool 차원에서 제거.
      final next = i + 1 < text.length ? text[i + 1] : '';
      const attached = {
        '을',
        '이',
        '은',
        '의',
        '과',
        '도',
        '에',
        '만',
        '까지',
        '로',
        '에서',
        '부터',
        '보다',
        '처럼',
        '한테',
        '치',
        '단',
      };
      // attached 는 한 글자라 next 한 글자 비교.
      if (attached.contains(next)) {
        out.write(ch);
        continue;
      }
      // 단독 어절로 판정.
      hit++;
      if (hit <= maxCount) {
        out.write(ch);
      } else {
        out.write(alts[rng.nextInt(alts.length)]);
      }
    }
    return out.toString();
  }

  /// "이었어요" / "였어요" 결말 다양화 — 3회 초과 시 변형 적용.
  static String _diversifyEndings(String text, Random rng) {
    // 문장 끝 어미 "이었어요." / "였어요." 등장 횟수 카운트.
    const variantsIeotEoyo = <String>['이었어요.', '이었답니다.', '이었대요.', '이었대.'];
    const variantsYeotEoyo = <String>['였어요.', '였답니다.', '였대요.', '였대.'];
    var s = text;
    s = _diversifyOne(s, '이었어요.', variantsIeotEoyo, 3, rng);
    s = _diversifyOne(s, '였어요.', variantsYeotEoyo, 3, rng);
    return s;
  }

  static String _diversifyOne(
    String text,
    String needle,
    List<String> variants,
    int maxKeep,
    Random rng,
  ) {
    final out = StringBuffer();
    var cursor = 0;
    var hit = 0;
    while (true) {
      final idx = text.indexOf(needle, cursor);
      if (idx < 0) {
        out.write(text.substring(cursor));
        break;
      }
      out.write(text.substring(cursor, idx));
      hit++;
      if (hit <= maxKeep) {
        out.write(needle);
      } else {
        // 변형 (단, 동일 needle 은 회피).
        var pick = variants[rng.nextInt(variants.length)];
        if (pick == needle) {
          pick =
              variants[(rng.nextInt(variants.length - 1) + 1) %
                  variants.length];
        }
        out.write(pick);
      }
      cursor = idx + needle.length;
    }
    return out.toString();
  }
}

/// R104 sprint 3 — story arc 텍스트용 placeholder injector.
///
/// `_composeFromPool` 안의 nested `inject` 클로저와 동일한 josa / copula 보정
/// 규칙을 standalone 클래스로 추출. story arc 경로가 슬롯 fallback 과 같은 품질
/// (받침 보정 / compound suffix / collision 방지) 을 보장하도록 한다.
///
/// 지원 placeholder: `$userName` / `$celebName` / `$userRole` / `$celebRole`
/// / `$era`. `$era` 는 받침 무관 단순 치환.
class _PlaceholderInjector {
  _PlaceholderInjector({
    required this.userName,
    required this.celebName,
    required this.userRole,
    required this.celebRole,
    required this.era,
  });

  final String userName;
  final String celebName;
  final String userRole;
  final String celebRole;
  final String era;

  // 받침 의존 / 무관 조사 set — slot 경로와 동일.
  static const _conJosas = ['과', '와'];
  static const _topJosas = ['은', '는'];
  static const _subJosas = ['이', '가'];
  static const _objJosas = ['을', '를'];
  static const _loJosas = ['로', '으로'];
  static const _bareJosas = [
    '도',
    '에게',
    '한테',
    '께',
    '에서',
    '에',
    '부터',
    '까지',
    '보다',
    '만',
    '처럼',
    '조차',
    '마저',
    '뿐',
  ];
  static const _dirJosas = ['의'];

  String _fixCopula(String role) =>
      josa.hasFinalConsonant(role) ? '$role이었' : '$role였';

  String _wasParticiple(String role) =>
      josa.hasFinalConsonant(role) ? '$role이었던' : '$role였던';

  String _copulaIraneun(String w) =>
      josa.hasFinalConsonant(w) ? '$w이라는' : '$w라는';

  String _copulaIeoteoyo(String w) =>
      josa.hasFinalConsonant(w) ? '$w이었어요' : '$w였어요';

  String _copulaIeotgo(String w) =>
      josa.hasFinalConsonant(w) ? '$w이었고' : '$w였고';

  String _copulaIeyo(String w) => josa.hasFinalConsonant(w) ? '$w이에요' : '$w예요';

  /// compound suffix 를 길이 우선으로 모두 치환 — generic josa 보다 먼저.
  String _resolveCompound(String src, String ph, String word) {
    var t = src;
    t = t.replaceAll('$ph 이었어요', _copulaIeoteoyo(word));
    t = t.replaceAll('$ph이었어요', _copulaIeoteoyo(word));
    t = t.replaceAll('$ph 이라는', _copulaIraneun(word));
    t = t.replaceAll('$ph이라는', _copulaIraneun(word));
    t = t.replaceAll('$ph 이었고', _copulaIeotgo(word));
    t = t.replaceAll('$ph이었고', _copulaIeotgo(word));
    t = t.replaceAll('$ph 이에요', _copulaIeyo(word));
    t = t.replaceAll('$ph이에요', _copulaIeyo(word));
    // 이름 noun — placeholder collision 방지. 공백 유지.
    t = t.replaceAll('$ph 이름', '$word 이름');
    t = t.replaceAll('$ph이름', '$word 이름');
    // 이번 noun — subj josa `이` collision 방지.
    t = t.replaceAll('$ph 이번', '$word 이번');
    t = t.replaceAll('$ph이번', '$word 이번');
    return t;
  }

  /// generic josa 치환 — slot 경로 `replacePh` 와 동일.
  String _replacePh(String src, String ph, String name) {
    var t = src;
    final withRes = josa.withWith(name);
    for (final j in _conJosas) {
      t = t.replaceAll('$ph $j', '$name$withRes');
      t = t.replaceAll('$ph$j', '$name$withRes');
    }
    final topRes = josa.withTop(name);
    for (final j in _topJosas) {
      t = t.replaceAll('$ph $j', '$name$topRes');
      t = t.replaceAll('$ph$j', '$name$topRes');
    }
    final subRes = josa.withSubj(name);
    for (final j in _subJosas) {
      t = t.replaceAll('$ph $j', '$name$subRes');
      t = t.replaceAll('$ph$j', '$name$subRes');
    }
    final objRes = josa.withObj(name);
    for (final j in _objJosas) {
      t = t.replaceAll('$ph $j', '$name$objRes');
      t = t.replaceAll('$ph$j', '$name$objRes');
    }
    String loRes;
    if (name.isEmpty) {
      loRes = '로';
    } else {
      final last = name.substring(name.length - 1);
      final cu = last.codeUnitAt(0);
      if (cu >= 0xAC00 && cu <= 0xD7A3) {
        final jong = (cu - 0xAC00) % 28;
        if (jong == 0) {
          loRes = '로';
        } else if (jong == 8) {
          loRes = '로';
        } else {
          loRes = '으로';
        }
      } else {
        loRes = josa.hasFinalConsonant(name) ? '으로' : '로';
      }
    }
    for (final j in _loJosas) {
      t = t.replaceAll('$ph $j', '$name$loRes');
      t = t.replaceAll('$ph$j', '$name$loRes');
    }
    for (final j in _dirJosas) {
      t = t.replaceAll('$ph $j', '$name$j');
      t = t.replaceAll('$ph$j', '$name$j');
    }
    for (final j in _bareJosas) {
      t = t.replaceAll('$ph $j', '$name$j');
      t = t.replaceAll('$ph$j', '$name$j');
    }
    return t;
  }

  /// arc paragraph / punchline 한 줄 inject — slot 경로 `inject` 와 동일 단계.
  String inject(String tmpl) {
    var s = tmpl;

    // $era — 받침 무관 단순 치환.
    s = s.replaceAll(r'$era', era);

    // STEP 0 — compound suffix 우선 (Name + Role 4종).
    s = _resolveCompound(s, r'$userName', userName);
    s = _resolveCompound(s, r'$celebName', celebName);
    s = _resolveCompound(s, r'$userRole', userRole);
    s = _resolveCompound(s, r'$celebRole', celebRole);

    // STEP 1 — Role placeholder 의 "이었던" / "였" (R102 호환).
    s = s.replaceAll(r'$userRole 이었던', _wasParticiple(userRole));
    s = s.replaceAll(r'$userRole이었던', _wasParticiple(userRole));
    s = s.replaceAll(r'$celebRole 이었던', _wasParticiple(celebRole));
    s = s.replaceAll(r'$celebRole이었던', _wasParticiple(celebRole));
    s = s.replaceAll(r'$userRole 였', _fixCopula(userRole));
    s = s.replaceAll(r'$userRole였', _fixCopula(userRole));
    s = s.replaceAll(r'$celebRole 였', _fixCopula(celebRole));
    s = s.replaceAll(r'$celebRole였', _fixCopula(celebRole));

    // STEP 2 — Name + Role generic josa.
    s = _replacePh(s, r'$userName', userName);
    s = _replacePh(s, r'$celebName', celebName);
    s = _replacePh(s, r'$userRole', userRole);
    s = _replacePh(s, r'$celebRole', celebRole);

    // STEP 3 — Plain placeholder fallback.
    s = s.replaceAll(r'$celebName', celebName);
    s = s.replaceAll(r'$userName', userName);
    s = s.replaceAll(r'$userRole', userRole);
    s = s.replaceAll(r'$celebRole', celebRole);
    return s;
  }
}
