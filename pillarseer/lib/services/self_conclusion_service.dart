// Pillar Seer — R88 sprint 9 SelfConclusionService (R90 sprint 6 round 3 톤 보강).
//
// "나는 어떤 사람?" 결론형 generator. 일간 + 5행 dominant anchor 로 80~200자
// 한 단락 결론 paragraph.
//
// R88 baseline 보존 (사용자 mandate "회귀 가드"):
//   - 80~200자 hard cap
//   - conclusion_self 카테고리 = split X (M/F 동일 출력)
//
// R90 sprint 6 round 3 톤 fix (R88 회귀 갓ne 깨지 않는 범위 안):
//   - "X이라" 어색 조사 → "X 쪽이라" 보정
//   - "있는 그대로의 본인 모습이 가장 강한 매력이에요" → 동일 (R88 baseline 보존).
//   - prefix-db 중복 첫 sentence skip 로직 유지.

import '../models/saju_result.dart';
import 'life_paragraph_service.dart';
import 'natural_prose_joiner.dart';

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
  /// R90 sprint 6 — "X이라" → "X 쪽이라" 어색 조사 보정.
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
    return '본인은 한 마디로 \'$stemDesc 사람\'이에요. 본인 안에서 가장 강한 색이 $domKo 쪽이라 $domDesc.';
  }

  /// 사주 → 80~200자 결론 paragraph.
  /// R88 baseline (200 cap + gender X) 보존. R90 anchor 다층화 효과는
  /// LifeOverviewService + paragraphForSaju 가 처리.
  static Future<String> conclude(SajuResult saju, {bool isMale = true}) async {
    final stemHan = saju.dayPillar.chunGan;
    final stemKo = _stemHanToKo[stemHan] ?? stemHan;
    final dominant = saju.elements.dominant;

    // 1. anchor prefix (50 case).
    final prefix = _conclusionPrefix(stemKo, dominant);

    // 2. LifeParagraphService 의 conclusion_self paragraph (일간 fallback).
    final dbConcl = await LifeParagraphService.paragraphStatic(
      dayPillar: stemKo,
      category: LifeCategory.conclusionSelf,
    );
    // dbConcl 첫 마침표 단위 — prefix 와 중복되는 첫 sentence 는 skip.
    final dbSentence = _secondOrFirstSentence(dbConcl);

    // 3. 마무리 (페르소나 친근 톤 — 사주 도메인 용어 없이).
    final closing = '있는 그대로의 본인 모습이 가장 강한 매력이에요.';

    final parts = <String>[
      prefix,
      if (dbSentence.isNotEmpty) dbSentence,
      closing,
    ];
    var result = NaturalProseJoiner.join(parts);

    // 80자 미만이면 anchor padding (예외 상황 방어).
    if (result.length < 80) {
      result = NaturalProseJoiner.append(result, [
        '한 가지 모습으로 본인을 다 설명하지 말고 여러 면을 다 살려봐요.',
      ]);
    }
    // 200자 over 시 잘라내기 (R88 baseline mandate).
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

  /// R90 sprint 6 — prefix 와 중복되는 첫 sentence skip.
  ///
  /// db 본문 첫 sentence 가 "본인은 한 마디로" 또는 "한 마디로" 시작이면 prefix 와 중복
  /// → 두 번째 sentence 부터 추출. 아니면 첫 sentence 그대로.
  static String _secondOrFirstSentence(String paragraph) {
    if (paragraph.isEmpty) return '';
    final first = _firstSentence(paragraph);
    final firstTrim = first.trim();
    if (firstTrim.startsWith('본인은 한 마디로') || firstTrim.startsWith('한 마디로')) {
      // 첫 sentence 잘라내고 두 번째 sentence 반환.
      final firstDot = paragraph.indexOf('. ');
      if (firstDot > 0 && firstDot + 2 < paragraph.length) {
        final rest = paragraph.substring(firstDot + 2);
        return _firstSentence(rest);
      }
    }
    return first;
  }
}
