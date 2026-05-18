// Pillar Seer — R88 sprint 9 SelfConclusionService.
//
// "나는 어떤 사람?" 결론형 generator. 일간 + 5행 dominant anchor 로 80~200자
// 한 단락 결론 paragraph. spec sprint 9: "당신은 ~ 같은 사람이에요" 패턴.
//
// 일간 10 × 5행 dominant 5 = 50 baseline + LifeParagraphService 의 conclusion_self
// 일간 fallback 까지. idempotent.

import '../models/saju_result.dart';
import 'life_paragraph_service.dart';

class SelfConclusionService {
  /// 한자 천간 → 한글.
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

  /// 5행 한자 → 한글.
  static const Map<String, String> _elKo = {
    '木': '나무',
    '火': '불',
    '土': '흙',
    '金': '금속',
    '水': '물',
  };

  /// 일간 + dominant 별 결론 prefix (50 case anchor).
  /// '당신은 ~ 같은 사람이에요' 패턴으로 첫 줄 변별력 확보.
  static String _conclusionPrefix(String stemKo, String dominant) {
    final domKo = _elKo[dominant] ?? dominant;
    // 일간별 키워드.
    const stemKey = {
      '갑': '곧게 뻗어가는',
      '을': '부드럽게 적응하는',
      '병': '주변을 빠르게 풀어주는',
      '정': '섬세하게 챙기는',
      '무': '듬직하게 자리 잡는',
      '기': '편안하게 받쳐주는',
      '경': '딱 잘라 정리하는',
      '신': '예민하게 알아보는',
      '임': '흐름을 넓게 읽는',
      '계': '깊게 스며드는',
    };
    final stemDesc = stemKey[stemKo] ?? '자기 색이 또렷한';
    // dominant 별 핵심.
    const domTone = {
      '木': '추진력이 강하고 새 도전을 잘 잡아요',
      '火': '주변을 빠르게 풀어주는 매력이 커요',
      '土': '주변 사람들이 본인 옆을 편하게 느껴요',
      '金': '결단이 빠르고 정리하는 자리에서 빛이 나요',
      '水': '변화 많은 환경에서도 적응이 자연스러워요',
    };
    final domDesc = domTone[dominant] ?? '자기 색이 또렷한 매력이 있어요';
    return '본인은 한 마디로 \'$stemDesc 사람\'이에요. 본인 안에서 가장 강한 색이 $domKo이라 $domDesc.';
  }

  /// 사주 → 80~200자 결론 paragraph.
  static Future<String> conclude(SajuResult saju, {bool isMale = true}) async {
    final stemHan = saju.dayPillar.chunGan;
    final stemKo = _stemHanToKo[stemHan] ?? stemHan;
    final dominant = saju.elements.dominant;

    // 1. anchor prefix (50 case).
    final prefix = _conclusionPrefix(stemKo, dominant);

    // 2. LifeParagraphService 의 conclusion_self paragraph (일간 fallback).
    //    R90 sprint 5 — conclusion_self 카테고리는 anchor fragment matrix 가 empty 라
    //    fragment 결합 X (LifeOverviewService 가 anchor 7 직접 빌드). paragraphStatic 유지.
    final dbConcl = await LifeParagraphService.paragraphStatic(
      dayPillar: stemKo,
      category: LifeCategory.conclusionSelf,
    );
    // dbConcl 첫 마침표 단위.
    final dbSentence = _firstSentence(dbConcl);

    // 3. 마무리 (페르소나 친근 톤 — 사주 도메인 용어 없이).
    final closing = '있는 그대로의 본인 모습이 가장 강한 매력이에요.';

    final parts = <String>[prefix, if (dbSentence.isNotEmpty) dbSentence, closing];
    var result = parts.join(' ');

    // 80자 미만이면 anchor padding (예외 상황 방어).
    if (result.length < 80) {
      result = '$result 한 가지 모습으로 본인을 다 설명하지 말고 여러 면을 다 살려봐요.';
    }
    // 200자 over 시 잘라내기.
    if (result.length > 200) {
      final cut = result.substring(0, 200);
      final lastDot = cut.lastIndexOf('. ');
      result = lastDot > 80 ? cut.substring(0, lastDot + 1) : cut;
    }
    return result;
  }

  /// paragraph 첫 마침표 단위.
  static String _firstSentence(String paragraph) {
    if (paragraph.isEmpty) return '';
    final idx = paragraph.indexOf('. ');
    final raw = idx > 0 ? paragraph.substring(0, idx + 1) : paragraph;
    return raw.length > 100 ? '${raw.substring(0, 100)}…' : raw;
  }
}
