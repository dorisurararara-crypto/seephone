// Pillar Seer — Round 82 sprint 5.
//
// PalaceHelperAnchorService:
// 12 결 풀이 카드 (`_ZiweiPalaceBlock`) 의 support/caution row 라벨 옆 보강 helper
// (= 십신/용신/신살 anchor + 1줄 설명) 생성.
//
// 사용자 mandate (R82 인수인계.md line 14):
//   support / caution row 옆에 그게 무엇인지 안 나오고 설명이 약하다고 사용자 지적.
//   → 라벨 옆에 사주 근거 (십신/용신/신살) + 1줄 설명을 붙인다.
//
// ## 보존 mandate
//   1. R70 자미두수 hidden — `palace.luckyStars` / `palace.badStars` 의 nameKo
//      (자미성·천기성·태양성 등) 사용자 노출 0. 본 service 도 별 이름 X.
//   2. R78 SajuContext 4단계 chain — 십신/용신/신살 anchor 는 SajuContext 1차 source
//      에서 직접 추출. 추가 계산 X.
//   3. R69 lock + 5행 골든 (1995-10-27 男 17시 16/21/17/41/4) 보존 — 본 service 는
//      anchor lookup 만 수행, 사주 자체 데이터 변형 0.
//
// ## anchor 결정 규칙
//
// support row:
//   - 12궁 gungKo 의 영역 의미 (재백=돈/관록=일·꿈/부처=연애 등) 와 SajuContext 의
//     활성 십신 + 용신을 매칭. 우선 영역과 직접 관련된 십신 (예: 재백궁 = 정재/편재,
//     관록궁 = 정관/편관, 부처궁 = 일간 기준 배우자성) 빈도 1+ 면 anchor.
//     없으면 용신 5행 anchor 로 fallback.
//
// caution row:
//   - SajuContext.todayRelations (지지충 등) → 활성 신살 (역마/도화 등) → 공망 영역
//     순으로 anchor. 모두 비어있으면 영역 친근 어휘로 일반 행동 처방.
//
// ## 톤
//   - 직설 친근 해요체, 한국 MZ 중학생 K-POP 팬 페르소나
//   - 한자 jargon 본문 X (사용자 노출 명사 blacklist 검사는 sprint 5 test 참조)
//     (단 "사주/십신/용신/신살" 같이 사용자가 자주 듣는 도메인 단어는 OK)
//   - AI 슬롭 본문 노출 X (sprint 2 oneline_jargon scanner 와 동일 blacklist 준수)
//   - Apologetic AI 어조 X
//   - 의료 단정 X

import 'saju_context.dart';
import '../models/saju_result.dart';

class PalaceHelperAnchorService {
  /// 12궁 + SajuContext → support/caution anchor pair.
  ///
  /// [gungKo] : 12궁 내부 키 ('명궁' / '재백궁' / '관록궁' 등).
  /// [ctx] : SajuContext (R78 1차 source).
  /// [useKo] : true=ko / false=en.
  /// [luckyCount] : palace.luckyStars.length (개수만 사용 — nameKo 노출 X).
  /// [badCount]   : palace.badStars.length (개수만 사용 — nameKo 노출 X).
  static PalaceAnchorPair resolve({
    required String gungKo,
    required SajuContext ctx,
    required bool useKo,
    required int luckyCount,
    required int badCount,
  }) {
    final support = _supportAnchor(
      gungKo: gungKo,
      ctx: ctx,
      useKo: useKo,
      luckyCount: luckyCount,
    );
    final caution = _cautionAnchor(
      gungKo: gungKo,
      ctx: ctx,
      useKo: useKo,
      badCount: badCount,
    );
    return PalaceAnchorPair(support: support, caution: caution);
  }

  // ── support anchor ───────────────────────────────────────────

  static PalaceAnchor _supportAnchor({
    required String gungKo,
    required SajuContext ctx,
    required bool useKo,
    required int luckyCount,
  }) {
    if (luckyCount <= 0) {
      // 받쳐주는 단서 0 — 일반 fallback (영역 친근 어휘).
      return PalaceAnchor(
        anchorLabelKo: '받쳐주는 사주가 살짝 약해요',
        anchorLabelEn: 'Light support in this area',
        helperKo: _areaSelfCareKo(gungKo),
        helperEn: _areaSelfCareEn(gungKo),
      );
    }
    // 1순위: 영역별 직접 매칭 십신.
    final preferred = _preferredGodsFor(gungKo);
    TenGod? hit;
    for (final g in preferred) {
      final n = ctx.tenGodFrequency[g] ?? 0;
      if (n > 0) {
        hit = g;
        break;
      }
    }
    // 2순위: 활성 십신 중 빈도 최고.
    if (hit == null && ctx.tenGodFrequency.isNotEmpty) {
      final sorted = ctx.tenGodFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      hit = sorted.first.key;
    }
    if (hit != null) {
      final godKo = _tenGodShortKo(hit);
      final godEn = _tenGodShortEn(hit);
      return PalaceAnchor(
        anchorLabelKo: '= 사주의 $godKo 십신',
        anchorLabelEn: '= $godEn ten-god',
        helperKo: _supportHelperByGodKo(gungKo, hit),
        helperEn: _supportHelperByGodEn(gungKo, hit),
      );
    }
    // 3순위: 용신 5행 fallback.
    if (ctx.yongsin.isNotEmpty) {
      final elKo = SajuContext.elementKo(ctx.yongsin);
      final elEn = SajuContext.elementEn(ctx.yongsin);
      return PalaceAnchor(
        anchorLabelKo: '= 사주의 $elKo 용신',
        anchorLabelEn: '= $elEn yongsin',
        helperKo: _supportHelperByYongsinKo(gungKo, ctx.yongsin),
        helperEn: _supportHelperByYongsinEn(gungKo, ctx.yongsin),
      );
    }
    // 최종 fallback — 영역 친근 어휘.
    return PalaceAnchor(
      anchorLabelKo: '= 사주에서 받쳐주는 자리',
      anchorLabelEn: '= Saju supportive area',
      helperKo: _areaSupportKo(gungKo),
      helperEn: _areaSupportEn(gungKo),
    );
  }

  // ── caution anchor ───────────────────────────────────────────

  static PalaceAnchor _cautionAnchor({
    required String gungKo,
    required SajuContext ctx,
    required bool useKo,
    required int badCount,
  }) {
    if (badCount <= 0) {
      return PalaceAnchor(
        anchorLabelKo: '특별히 걸리는 자리는 없어요',
        anchorLabelEn: 'No tense area pulled',
        helperKo: _areaCalmKo(gungKo),
        helperEn: _areaCalmEn(gungKo),
      );
    }
    // 1순위: 오늘 일진 관계 — 지지충 (즉시 걸림). today_event 와 동선 일치.
    if (ctx.todayRelations.contains('지지충')) {
      return PalaceAnchor(
        anchorLabelKo: '= 오늘 일진과 지지충 자리',
        anchorLabelEn: '= Branch-clash with today saju',
        helperKo: '오늘 사주와 살짝 부딪히는 자리예요, ${_areaKo(gungKo)} 부분은 한 박자 쉬어가요.',
        helperEn:
            'Branch-clash with today — pause a beat before pushing your ${_areaEn(gungKo)} side.',
      );
    }
    // 2순위: 활성 신살 — 도화/역마/양인/괴강/백호 우선.
    const shinsaPriority = ['역마', '도화', '양인', '괴강', '백호', '화개', '천을귀인', '문창귀인'];
    for (final s in shinsaPriority) {
      if (ctx.activeShinsa.contains(s)) {
        return PalaceAnchor(
          anchorLabelKo: '= 사주의 $s 신살',
          anchorLabelEn: '= ${_shinsaEn(s)} shinsa',
          helperKo: _cautionHelperByShinsaKo(gungKo, s),
          helperEn: _cautionHelperByShinsaEn(gungKo, s),
        );
      }
    }
    // 3순위: 공망 영역.
    if (ctx.gongMangAreas.isNotEmpty) {
      return PalaceAnchor(
        anchorLabelKo: '= 사주의 공망 자리',
        anchorLabelEn: '= Saju void area',
        helperKo: _cautionHelperByGongMangKo(gungKo),
        helperEn: _cautionHelperByGongMangEn(gungKo),
      );
    }
    // 4순위: 일간 음양 + 강약 일반 처방.
    if (ctx.strengthLabel == '신약' || ctx.strengthLabel == '신쇠') {
      return PalaceAnchor(
        anchorLabelKo: '= 사주가 살짝 약한 자리',
        anchorLabelEn: '= Saju soft area',
        helperKo: _cautionHelperByWeakKo(gungKo),
        helperEn: _cautionHelperByWeakEn(gungKo),
      );
    }
    // 최종 fallback.
    return PalaceAnchor(
      anchorLabelKo: '= 살짝 천천히 가는 자리',
      anchorLabelEn: '= Take-it-slow area',
      helperKo: _cautionHelperGenericKo(gungKo),
      helperEn: _cautionHelperGenericEn(gungKo),
    );
  }

  // ── 영역별 우선 십신 (12궁 → 핵심 십신 후보 1~3) ─────────────────

  static List<TenGod> _preferredGodsFor(String gungKo) {
    switch (gungKo) {
      case '재백궁':
        return [TenGod.jeongjae, TenGod.pyeonjae, TenGod.siksin];
      case '관록궁':
        return [TenGod.jeonggwan, TenGod.pyeongwan];
      case '부처궁':
        return [TenGod.jeongjae, TenGod.jeonggwan];
      case '자녀궁':
        return [TenGod.siksin, TenGod.sanggwan];
      case '부모궁':
        return [TenGod.jeongin, TenGod.pyeonin];
      case '형제궁':
        return [TenGod.bigyeon, TenGod.geopjae];
      case '복덕궁':
        return [TenGod.jeongin, TenGod.siksin];
      case '천이궁':
        return [TenGod.pyeonjae, TenGod.sanggwan];
      case '노복궁':
        return [TenGod.bigyeon, TenGod.geopjae, TenGod.siksin];
      case '질액궁':
        return [TenGod.jeongin, TenGod.bigyeon];
      case '전택궁':
        return [TenGod.jeongjae, TenGod.jeongin];
      case '명궁':
        return [TenGod.bigyeon, TenGod.jeongin, TenGod.jeonggwan];
      default:
        return const <TenGod>[];
    }
  }

  // ── 십신 라벨 (짧은 한국어/영문, 한자 X) ─────────────────────────

  static String _tenGodShortKo(TenGod g) {
    switch (g) {
      case TenGod.bigyeon: return '비견';
      case TenGod.geopjae: return '겁재';
      case TenGod.siksin: return '식신';
      case TenGod.sanggwan: return '상관';
      case TenGod.pyeonjae: return '편재';
      case TenGod.jeongjae: return '정재';
      case TenGod.pyeongwan: return '편관';
      case TenGod.jeonggwan: return '정관';
      case TenGod.pyeonin: return '편인';
      case TenGod.jeongin: return '정인';
    }
  }

  static String _tenGodShortEn(TenGod g) {
    switch (g) {
      case TenGod.bigyeon: return 'Peer';
      case TenGod.geopjae: return 'Rival';
      case TenGod.siksin: return 'Output';
      case TenGod.sanggwan: return 'Rebel-Output';
      case TenGod.pyeonjae: return 'Windfall';
      case TenGod.jeongjae: return 'Stable-Wealth';
      case TenGod.pyeongwan: return 'Authority';
      case TenGod.jeonggwan: return 'Officer';
      case TenGod.pyeonin: return 'Side-Resource';
      case TenGod.jeongin: return 'Direct-Resource';
    }
  }

  static String _shinsaEn(String s) {
    switch (s) {
      case '역마': return 'Travel';
      case '도화': return 'Charm';
      case '양인': return 'Sharp-edge';
      case '괴강': return 'Mighty';
      case '백호': return 'White-tiger';
      case '화개': return 'Solitude';
      case '천을귀인': return 'Heavenly-Aid';
      case '문창귀인': return 'Scholar';
      default: return s;
    }
  }

  // ── support helper (십신 anchor 별 1줄 친근 설명) ────────────────

  static String _supportHelperByGodKo(String gungKo, TenGod g) {
    // 영역 + 십신 조합 — 한 줄, 직설 친근 해요체.
    final area = _areaKo(gungKo);
    switch (g) {
      case TenGod.jeongjae:
        return '꾸준한 돈 감각이 $area 자리를 든든하게 받쳐줘요.';
      case TenGod.pyeonjae:
        return '뜻밖의 기회를 잡는 감이 $area 자리에서 빛을 봐요.';
      case TenGod.siksin:
        return '재능을 풀어내는 힘이 $area 자리에 새 길을 열어줘요.';
      case TenGod.sanggwan:
        return '톡톡 튀는 표현력이 $area 자리에 새 바람을 넣어요.';
      case TenGod.jeonggwan:
        return '책임감과 원칙이 $area 자리를 단단하게 잡아줘요.';
      case TenGod.pyeongwan:
        return '큰일을 밀고 가는 추진력이 $area 자리에서 받쳐줘요.';
      case TenGod.jeongin:
        return '배운 걸 단단히 쌓는 힘이 $area 자리를 받쳐줘요.';
      case TenGod.pyeonin:
        return '남다른 관점이 $area 자리에 깊이를 더해줘요.';
      case TenGod.bigyeon:
        return '내 줏대와 친구들 응원이 $area 자리에서 힘이 돼요.';
      case TenGod.geopjae:
        return '경쟁심과 승부욕이 $area 자리에서 에너지로 풀려요.';
    }
  }

  static String _supportHelperByGodEn(String gungKo, TenGod g) {
    final area = _areaEn(gungKo);
    switch (g) {
      case TenGod.jeongjae:
        return 'Steady money sense backs your $area side.';
      case TenGod.pyeonjae:
        return 'A sharp eye for chance lights up your $area side.';
      case TenGod.siksin:
        return 'Your craft energy keeps your $area side flowing.';
      case TenGod.sanggwan:
        return 'A bold voice freshens up your $area side.';
      case TenGod.jeonggwan:
        return 'Responsibility holds your $area side steady.';
      case TenGod.pyeongwan:
        return 'Big-push drive backs your $area side.';
      case TenGod.jeongin:
        return 'Study and depth back your $area side.';
      case TenGod.pyeonin:
        return 'A different angle adds depth to your $area side.';
      case TenGod.bigyeon:
        return 'Self-trust and friends back your $area side.';
      case TenGod.geopjae:
        return 'Healthy rivalry fuels your $area side.';
    }
  }

  // ── support helper (용신 fallback) ──────────────────────────────

  static String _supportHelperByYongsinKo(String gungKo, String yongsin) {
    final area = _areaKo(gungKo);
    final el = SajuContext.elementKo(yongsin);
    return '사주가 필요로 하는 $el 용신이 $area 자리를 부드럽게 받쳐줘요.';
  }

  static String _supportHelperByYongsinEn(String gungKo, String yongsin) {
    final area = _areaEn(gungKo);
    final el = SajuContext.elementEn(yongsin);
    return 'Your needed-element ($el) softly backs your $area side.';
  }

  // ── caution helper (신살 anchor 별 1줄 행동 처방) ────────────────

  static String _cautionHelperByShinsaKo(String gungKo, String shinsa) {
    final area = _areaKo(gungKo);
    switch (shinsa) {
      case '역마':
        return '역마 자리라 $area 부분은 한자리에 오래 못 머무를 수 있어요, 이동·변화는 미리 챙겨봐요.';
      case '도화':
        return '도화 자리라 $area 부분에 시선이 많이 모여요, 흔들리지 않게 페이스 지켜요.';
      case '양인':
        return '양인 자리라 $area 부분에서 욱하기 쉬워요, 한 번 더 숨 고르고 가요.';
      case '괴강':
        return '괴강 자리라 $area 부분이 세게 부딪힐 수 있어요, 빠른 결정은 천천히 다시 봐요.';
      case '백호':
        return '백호 자리라 $area 부분에 큰 변동이 따라올 수 있어요, 안전장치 하나 둬요.';
      case '화개':
        return '화개 자리라 $area 부분이 살짝 외로워질 수 있어요, 혼자 충전 시간도 같이 챙겨요.';
      case '천을귀인':
        return '천을귀인 자리라 $area 부분에 도움이 오긴 와요, 다만 너무 기대지는 말아요.';
      case '문창귀인':
        return '문창귀인 자리라 $area 부분이 공부 모드로 빠지기 쉬워요, 쉬는 시간도 챙겨요.';
      default:
        return '$shinsa 자리라 $area 부분은 살짝 천천히 가요.';
    }
  }

  static String _cautionHelperByShinsaEn(String gungKo, String shinsa) {
    final area = _areaEn(gungKo);
    switch (shinsa) {
      case '역마':
        return 'Travel shinsa — your $area side may keep shifting, plan moves ahead.';
      case '도화':
        return 'Charm shinsa — eyes land on your $area side, keep your own pace.';
      case '양인':
        return 'Sharp-edge shinsa — quick anger near your $area side, breathe first.';
      case '괴강':
        return 'Mighty shinsa — strong collisions near your $area side, re-check fast calls.';
      case '백호':
        return 'White-tiger shinsa — big swings near your $area side, keep a safety net.';
      case '화개':
        return 'Solitude shinsa — your $area side feels lonely sometimes, schedule recharge.';
      case '천을귀인':
        return 'Heavenly-aid shinsa — help comes for your $area side, just do not lean too hard.';
      case '문창귀인':
        return 'Scholar shinsa — study pulls hard near your $area side, also book real rest.';
      default:
        return 'Shinsa near your $area side — take it slower.';
    }
  }

  // ── caution helper (공망 / 신약 / generic) ─────────────────────

  static String _cautionHelperByGongMangKo(String gungKo) {
    final area = _areaKo(gungKo);
    return '공망 자리라 $area 부분의 큰 약속·계약은 한 박자 미뤄봐요.';
  }

  static String _cautionHelperByGongMangEn(String gungKo) {
    final area = _areaEn(gungKo);
    return 'Void area — push big commitments on your $area side by a beat.';
  }

  static String _cautionHelperByWeakKo(String gungKo) {
    final area = _areaKo(gungKo);
    return '사주가 살짝 약한 자리라 $area 부분은 무리하지 말고 페이스 지켜요.';
  }

  static String _cautionHelperByWeakEn(String gungKo) {
    final area = _areaEn(gungKo);
    return 'Soft saju spot — keep pace, do not overdo your $area side.';
  }

  static String _cautionHelperGenericKo(String gungKo) {
    final area = _areaKo(gungKo);
    return '$area 부분은 빠른 결정보다 살짝 더 보고 결정해요.';
  }

  static String _cautionHelperGenericEn(String gungKo) {
    final area = _areaEn(gungKo);
    return 'Take a second look before fast calls on your $area side.';
  }

  // ── 영역 친근 어휘 (gungKo → 사용자 어휘) ─────────────────────

  static String _areaKo(String gungKo) {
    switch (gungKo) {
      case '명궁': return '나의 중심';
      case '형제궁': return '친구·동료';
      case '부처궁': return '연애';
      case '자녀궁': return '창작·후배';
      case '재백궁': return '돈';
      case '질액궁': return '건강';
      case '천이궁': return '바깥 활동';
      case '노복궁': return '사람 네트워크';
      case '관록궁': return '꿈·진로';
      case '전택궁': return '내 공간';
      case '복덕궁': return '마음·취향';
      case '부모궁': return '어른·윗사람';
      default: return '이';
    }
  }

  static String _areaEn(String gungKo) {
    switch (gungKo) {
      case '명궁': return 'core';
      case '형제궁': return 'friends';
      case '부처궁': return 'love';
      case '자녀궁': return 'creative';
      case '재백궁': return 'money';
      case '질액궁': return 'health';
      case '천이궁': return 'outside';
      case '노복궁': return 'network';
      case '관록궁': return 'path';
      case '전택궁': return 'home';
      case '복덕궁': return 'inner';
      case '부모궁': return 'elder';
      default: return 'this';
    }
  }

  // 영역 일반 자기관리 (luckyCount == 0) — 친근 행동 처방.
  static String _areaSelfCareKo(String gungKo) {
    return '${_areaKo(gungKo)} 부분은 사주가 직접 짚어주는 자리가 적어요, 가까운 사람과 짧게 의논해봐요.';
  }
  static String _areaSelfCareEn(String gungKo) {
    return 'Light direct read on your ${_areaEn(gungKo)} side — talk it through with a close friend.';
  }

  // 영역 일반 받침 (3순위 fallback).
  static String _areaSupportKo(String gungKo) {
    return '${_areaKo(gungKo)} 부분에 사주가 조용히 힘을 보태고 있어요.';
  }
  static String _areaSupportEn(String gungKo) {
    return 'Your saju quietly backs your ${_areaEn(gungKo)} side.';
  }

  // 영역 일반 calm (badCount == 0).
  static String _areaCalmKo(String gungKo) {
    return '${_areaKo(gungKo)} 부분에 큰 사주 부담은 안 보여요, 평소 페이스로 가도 돼요.';
  }
  static String _areaCalmEn(String gungKo) {
    return 'No heavy saju load on your ${_areaEn(gungKo)} side — keep your usual pace.';
  }
}

/// 12궁 카드 한 영역의 support/caution anchor pair.
class PalaceAnchorPair {
  final PalaceAnchor support;
  final PalaceAnchor caution;
  const PalaceAnchorPair({required this.support, required this.caution});
}

/// 단일 anchor — 라벨 (= 사주의 X 십신) + 1줄 helper.
class PalaceAnchor {
  /// 라벨 텍스트 (한국어). 예: "= 사주의 식신 십신" / "= 사주의 木 용신" / "= 사주의 도화 신살".
  final String anchorLabelKo;
  /// 라벨 텍스트 (영문).
  final String anchorLabelEn;
  /// 1줄 helper text (한국어, 친근 해요체).
  final String helperKo;
  /// 1줄 helper text (영문).
  final String helperEn;

  const PalaceAnchor({
    required this.anchorLabelKo,
    required this.anchorLabelEn,
    required this.helperKo,
    required this.helperEn,
  });

  String labelFor({required bool useKo}) => useKo ? anchorLabelKo : anchorLabelEn;
  String helperFor({required bool useKo}) => useKo ? helperKo : helperEn;
}
