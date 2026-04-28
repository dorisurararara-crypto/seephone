/// 분노 에너지 (W) → 킹받는 비유 멘트.
class AngerVerdict {
  final String headline; // 눈에 띄는 한 줄
  final String comparison; // "전자레인지 X분 작동" 같은 비유
  final String mockery; // 약간 킹받는 멘트
  const AngerVerdict({
    required this.headline,
    required this.comparison,
    required this.mockery,
  });
}

class AngerCalc {
  /// 가속도 magnitude 누적 + 터치 카운트 → W 변환.
  ///
  /// 가속도 magnitude 합 (m/s²·s) × 0.5 + 터치 × 8 = W.
  /// 사람이 폰 미친듯이 흔드는 10초 = ~1500W 나오게 캘리브레이션.
  static double computeWatts({
    required double accelMagnitudeSum, // 10초간 magnitude 합
    required int touchCount,
  }) {
    return accelMagnitudeSum * 0.5 + touchCount * 8.0;
  }

  /// W → 비유. B급 톤.
  static AngerVerdict verdict(double watts) {
    if (watts < 30) {
      return const AngerVerdict(
        headline: '10W',
        comparison: '모기 날갯짓 수준',
        mockery: '이게 분노냐? 졸린거지.',
      );
    } else if (watts < 100) {
      return AngerVerdict(
        headline: '${watts.toStringAsFixed(0)}W',
        comparison: 'LED 전구 1개 켤 수 있음',
        mockery: '이걸로 누구 협박하려고?',
      );
    } else if (watts < 500) {
      return AngerVerdict(
        headline: '${watts.toStringAsFixed(0)}W',
        comparison: '선풍기 2시간 돌릴 수 있음',
        mockery: '평범한 빡침. 한 단계 더 가라.',
      );
    } else if (watts < 1000) {
      return AngerVerdict(
        headline: '${watts.toStringAsFixed(0)}W',
        comparison: '전자레인지 2분 작동',
        mockery: '제법인데? 그래도 부족.',
      );
    } else if (watts < 2000) {
      return AngerVerdict(
        headline: '${watts.toStringAsFixed(0)}W',
        comparison: '전자레인지 ${(watts / 700).toStringAsFixed(1)}분 작동',
        mockery: '진짜 빡쳤구나. 폰 부서질 뻔.',
      );
    } else if (watts < 5000) {
      return AngerVerdict(
        headline: '${watts.toStringAsFixed(0)}W',
        comparison: '에어컨 ${(watts / 1500).toStringAsFixed(1)}시간 작동',
        mockery: '🔥 분노 마스터. 이건 사회 부적응자 수준.',
      );
    } else {
      return AngerVerdict(
        headline: '${watts.toStringAsFixed(0)}W',
        comparison: '소형 발전소 1초 가동',
        mockery: '🚨 정신과 가셔야 할 분노. 폰 멀쩡한지 확인.',
      );
    }
  }
}
