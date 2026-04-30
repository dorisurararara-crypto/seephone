import 'dart:math';

/// 거짓말 점수 산출 v2 — 8가지 신호 결합.
///
/// 가중치는 deception detection 연구 (2024-2025) 의 신호 강도 우선순위 기반:
/// - saccade & gaze 관련   : 가장 강한 신호 (40%)
/// - facial asymmetry      : 강한 신호 (15%)
/// - blink anomaly         : 중간 (15%)
/// - micro-expression      : 중간 (10%)
/// - 기타 (head, smile)    : 보조 (10%)
/// - 결정론적 노이즈        : 질문별 차별화 (10%)
class LieScore {
  final double magnitude; // 0.0 ~ 10.0
  final String verdict;
  final double truthProbability;

  const LieScore({
    required this.magnitude,
    required this.verdict,
    required this.truthProbability,
  });
}

class LieDetector {
  /// 모든 신호는 정규화 후 0~1 로 클램프하고 가중합.
  static LieScore compute({
    required double pupilJitter, // 정규화 좌표 stdev. 0.05 = max
    required int saccadeBurst, // 3초간 점프 횟수. 12 = max
    required double gazeAversion, // 0~0.3 = max
    required int blinkCount, // 6 = max
    required double blinkAnomaly, // 0~1
    required double facialAsymmetry, // 정규화 거리. 0.06 = max
    required double microFlicker, // smile diff stdev. 0.15 = max
    required double headRotationDelta, // 60deg = max
    required double smileProbabilityAvg, // 0~1
    required int questionHash,
  }) {
    final jitterN = (pupilJitter / 0.05).clamp(0.0, 1.0);
    final saccadeN = (saccadeBurst / 12.0).clamp(0.0, 1.0);
    final gazeN = (gazeAversion / 0.3).clamp(0.0, 1.0);
    final blinkRateN = (blinkCount / 6.0).clamp(0.0, 1.0);
    final asymN = (facialAsymmetry / 0.06).clamp(0.0, 1.0);
    final flickerN = (microFlicker / 0.15).clamp(0.0, 1.0);
    final headN = (headRotationDelta / 60.0).clamp(0.0, 1.0);
    final smileN = smileProbabilityAvg.clamp(0.0, 1.0);

    // 가중 합 — 0~1
    final raw = jitterN * 0.15 +
        saccadeN * 0.15 +
        gazeN * 0.10 +
        asymN * 0.15 +
        // blink 는 횟수와 anomaly 둘 다 (각각 절반 비중)
        blinkRateN * 0.075 +
        blinkAnomaly.clamp(0.0, 1.0) * 0.075 +
        flickerN * 0.10 +
        headN * 0.10 +
        smileN * 0.05;

    // 결정론적 미세 노이즈 — 질문 차별화 (전체의 10%)
    final noise = (questionHash.abs() % 1000) / 1000.0;
    final mixed = (raw * 0.90 + noise * 0.10).clamp(0.0, 1.0);

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

  /// 카메라 권한 거부, 얼굴 미감지 등 → 의사 결정론적 폴백.
  static LieScore fallback(String question) {
    final h = question.hashCode;
    final r = Random(h).nextDouble();
    return compute(
      pupilJitter: r * 0.05,
      saccadeBurst: (r * 12).round(),
      gazeAversion: r * 0.3,
      blinkCount: (r * 6).round(),
      blinkAnomaly: r,
      facialAsymmetry: r * 0.06,
      microFlicker: r * 0.15,
      headRotationDelta: r * 60,
      smileProbabilityAvg: r,
      questionHash: h,
    );
  }
}
