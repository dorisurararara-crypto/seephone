import 'dart:math';

/// 거짓말 점수 산출 v3 — 캘리브레이션 + 비선형 응답.
///
/// v2 의 linear gain 은 5초 자연 측정에서 raw ≈ 0.25 → 2.5점만 나와
/// 거짓말해도 결과가 낮게 깔리는 문제. v3 변경:
///   1. threshold 를 5초 측정 현실값으로 절반 수준 낮춤
///   2. sqrt 응답 곡선 — 약한 신호도 중간 점수로 끌어올림 (entertainment용)
///   3. 약한 bias — face lock 만 되면 시작점 약간 ↑
///
/// 분포 목표:
///   - 진실 + 침착 →  1~3점
///   - 보통/긴장 →    4~6점
///   - 거짓말 시도 → 5~8점 (재밌는 의심 점수)
///   - 신호 강함 →    8~10점
class LieScore {
  final double magnitude;
  final String verdict;
  final double truthProbability;

  const LieScore({
    required this.magnitude,
    required this.verdict,
    required this.truthProbability,
  });
}

/// 진실 질문(이름 등) 측정으로 잡은 개인 baseline.
/// 본 측정 결과에서 차감하여 "원래 눈 잘 흔들리는 사람" 의 편차를 제거.
class BaselineSignals {
  final double pupilJitter;
  final int saccadeBurst;
  final double gazeAversion;
  final int blinkCount;
  final double facialAsymmetry;
  final double microFlicker;
  final double headRotationDelta;
  final double smileProbabilityAvg;

  const BaselineSignals({
    required this.pupilJitter,
    required this.saccadeBurst,
    required this.gazeAversion,
    required this.blinkCount,
    required this.facialAsymmetry,
    required this.microFlicker,
    required this.headRotationDelta,
    required this.smileProbabilityAvg,
  });

  static const empty = BaselineSignals(
    pupilJitter: 0,
    saccadeBurst: 0,
    gazeAversion: 0,
    blinkCount: 0,
    facialAsymmetry: 0,
    microFlicker: 0,
    headRotationDelta: 0,
    smileProbabilityAvg: 0,
  );
}

class LieDetector {
  /// baseline 차감 비율. 0 = 차감 안 함 (v3), 1 = baseline 만큼 빼고 그 위로만 점수.
  /// 0.7 = baseline 의 70% 까지 빼서 (개인차 보정 + 약간의 절대값 유지).
  static const double _baselineWeight = 0.7;

  static LieScore compute({
    required double pupilJitter,
    required int saccadeBurst,
    required double gazeAversion,
    required int blinkCount,
    required double blinkAnomaly,
    required double facialAsymmetry,
    required double microFlicker,
    required double headRotationDelta,
    required double smileProbabilityAvg,
    required int questionHash,
    BaselineSignals baseline = BaselineSignals.empty,
  }) {
    // baseline 차감 — 측정값에서 평소값(× weight) 을 빼고 음수는 0
    double sub(double v, double b) =>
        (v - b * _baselineWeight).clamp(0.0, double.infinity);
    int subInt(int v, int b) =>
        (v - (b * _baselineWeight).round()).clamp(0, 1 << 30);

    final adjJitter = sub(pupilJitter, baseline.pupilJitter);
    final adjSaccade = subInt(saccadeBurst, baseline.saccadeBurst);
    final adjGaze = sub(gazeAversion, baseline.gazeAversion);
    final adjBlink = subInt(blinkCount, baseline.blinkCount);
    final adjAsym = sub(facialAsymmetry, baseline.facialAsymmetry);
    final adjFlicker = sub(microFlicker, baseline.microFlicker);
    final adjHead = sub(headRotationDelta, baseline.headRotationDelta);
    final adjSmile =
        sub(smileProbabilityAvg, baseline.smileProbabilityAvg);
    pupilJitter = adjJitter;
    saccadeBurst = adjSaccade;
    gazeAversion = adjGaze;
    blinkCount = adjBlink;
    facialAsymmetry = adjAsym;
    microFlicker = adjFlicker;
    headRotationDelta = adjHead;
    smileProbabilityAvg = adjSmile;
    // 캘리브레이션: 5초 측정의 자연 max 기준 (실측 추정 절반 수준)
    final jitterN = (pupilJitter / 0.025).clamp(0.0, 1.0); // 0.05 → 0.025
    final saccadeN = (saccadeBurst / 6.0).clamp(0.0, 1.0); // 12 → 6
    final gazeN = (gazeAversion / 0.15).clamp(0.0, 1.0); // 0.3 → 0.15
    final blinkRateN = (blinkCount / 3.0).clamp(0.0, 1.0); // 6 → 3
    final asymN = (facialAsymmetry / 0.03).clamp(0.0, 1.0); // 0.06 → 0.03
    final flickerN = (microFlicker / 0.08).clamp(0.0, 1.0); // 0.15 → 0.08
    final headN = (headRotationDelta / 30.0).clamp(0.0, 1.0); // 60 → 30
    final smileN = smileProbabilityAvg.clamp(0.0, 1.0);

    // 가중합 (raw 0~1)
    final raw = jitterN * 0.15 +
        saccadeN * 0.15 +
        gazeN * 0.10 +
        asymN * 0.15 +
        blinkRateN * 0.075 +
        blinkAnomaly.clamp(0.0, 1.0) * 0.075 +
        flickerN * 0.10 +
        headN * 0.10 +
        smileN * 0.05;

    // 비선형 응답 — sqrt 로 약신호도 눈에 띄게
    final shaped = sqrt(raw.clamp(0.0, 1.0));

    // 결정론적 노이즈 — ±15% 변화 (같은 사람 여러 측정해도 매번 약간 다름)
    final noise = (questionHash.abs() % 1000) / 1000.0;
    final mixed = (shaped * 0.85 + noise * 0.15).clamp(0.0, 1.0);

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

  static LieScore fallback(String question) {
    final h = question.hashCode;
    final r = Random(h).nextDouble();
    return compute(
      pupilJitter: r * 0.025,
      saccadeBurst: (r * 6).round(),
      gazeAversion: r * 0.15,
      blinkCount: (r * 3).round(),
      blinkAnomaly: r,
      facialAsymmetry: r * 0.03,
      microFlicker: r * 0.08,
      headRotationDelta: r * 30,
      smileProbabilityAvg: r,
      questionHash: h,
    );
  }
}
