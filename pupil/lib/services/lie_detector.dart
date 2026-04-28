import 'dart:math';

/// 얼굴 트래킹 신호 → "동공 지진 진도" 점수.
///
/// 결정론적 (재현성 있음): 같은 입력 → 같은 결과.
/// 그래야 "오 진짜 측정하나?" 신뢰감 + 친구한테 다시 보여줄 때 결과 일관.
class LieScore {
  final double magnitude; // 0.0 ~ 10.0 (지진 진도 스타일)
  final String verdict; // '거짓말!' / '진실!' / '의심스러움'
  final double truthProbability; // 0.0 ~ 1.0

  const LieScore({
    required this.magnitude,
    required this.verdict,
    required this.truthProbability,
  });
}

class LieDetector {
  /// 입력:
  /// - blinkCount: 3초간 깜빡인 횟수
  /// - headRotationDelta: 머리 회전 누적 (degree)
  /// - smileProbabilityAvg: 0~1 (mlkit smiling probability 평균)
  /// - questionHash: 질문 텍스트 해시 (결정론용)
  static LieScore compute({
    required int blinkCount,
    required double headRotationDelta,
    required double smileProbabilityAvg,
    required int questionHash,
  }) {
    // 신호 정규화
    final blinkScore = (blinkCount / 6.0).clamp(0.0, 1.0); // 3초 6번 = max
    final headScore = (headRotationDelta / 30.0).clamp(0.0, 1.0); // 30deg = max
    final smileScore = smileProbabilityAvg; // 너무 웃으면 거짓말 가능

    // 가중치 (실제 거짓말 단서 연구가 아니라 농담용 — 그럴듯하면 OK)
    final raw = blinkScore * 0.4 + headScore * 0.4 + smileScore * 0.2;

    // 결정론적 노이즈 (질문별로 결과가 달라지게)
    final noise = (questionHash % 1000) / 1000.0;
    final mixed = (raw * 0.7 + noise * 0.3).clamp(0.0, 1.0);

    final magnitude = (mixed * 10).clamp(0.0, 10.0).toDouble();

    String verdict;
    if (magnitude >= 7.5) {
      verdict = '🚨 새빨간 거짓말!';
    } else if (magnitude >= 5.0) {
      verdict = '⚠️ 거짓말 의심';
    } else if (magnitude >= 2.5) {
      verdict = '🤔 약간 수상함';
    } else {
      verdict = '✅ 진실로 추정';
    }

    return LieScore(
      magnitude: magnitude,
      verdict: verdict,
      truthProbability: 1 - mixed,
    );
  }

  /// 측정 데이터 없을 때 (카메라 권한 거부 등) 폴백 — 의사 결정론적.
  static LieScore fallback(String question) {
    final h = question.hashCode;
    final r = Random(h).nextDouble();
    return compute(
      blinkCount: (r * 6).round(),
      headRotationDelta: r * 30,
      smileProbabilityAvg: r,
      questionHash: h,
    );
  }
}
