// Pillar Seer — 데일리 운세 모델 (Today's Energy)

class DailyFortune {
  final DateTime date;
  final int totalScore;       // 0~100
  final int loveScore;
  final int workScore;
  final int wealthScore;
  final int energyScore;
  final String quote;          // 한 줄 메시지 (deprecated — quoteEn/Ko 사용)
  final String quoteEn;
  final String quoteKo;
  final String luckyColor;
  final int luckyNumber;
  final String luckyDirection; // East / West / North / South / NE...
  final String dayPillar;      // 오늘의 일진 (예: 丙午)
  // 카테고리별 한 줄 가이드 (codex Round 3 권장 — 점신 대비 데일리 리텐션)
  final String loveGuideEn;
  final String loveGuideKo;
  final String workGuideEn;
  final String workGuideKo;
  final String wealthGuideEn;
  final String wealthGuideKo;
  final String energyGuideEn;
  final String energyGuideKo;

  const DailyFortune({
    required this.date,
    required this.totalScore,
    required this.loveScore,
    required this.workScore,
    required this.wealthScore,
    required this.energyScore,
    required this.quote,
    this.quoteEn = '',
    this.quoteKo = '',
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyDirection,
    required this.dayPillar,
    this.loveGuideEn = '',
    this.loveGuideKo = '',
    this.workGuideEn = '',
    this.workGuideKo = '',
    this.wealthGuideEn = '',
    this.wealthGuideKo = '',
    this.energyGuideEn = '',
    this.energyGuideKo = '',
  });

  factory DailyFortune.dummy() {
    return DailyFortune(
      date: DateTime.now(),
      totalScore: 85,
      loveScore: 90,
      workScore: 75,
      wealthScore: 60,
      energyScore: 88,
      quote: 'A secret friend arrives from afar.',
      luckyColor: 'Deep Ocean Blue',
      luckyNumber: 7,
      luckyDirection: 'East',
      dayPillar: '丙午',
    );
  }
}
