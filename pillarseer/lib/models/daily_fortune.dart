// Pillar Seer — 데일리 운세 모델 (Today's Energy)

class DailyFortune {
  final DateTime date;
  final int totalScore;       // 0~100
  final int loveScore;
  final int workScore;
  final int wealthScore;
  final int energyScore;
  final String quote;          // 한 줄 메시지
  final String luckyColor;
  final int luckyNumber;
  final String luckyDirection; // East / West / North / South / NE...
  final String dayPillar;      // 오늘의 일진 (예: 丙午)

  const DailyFortune({
    required this.date,
    required this.totalScore,
    required this.loveScore,
    required this.workScore,
    required this.wealthScore,
    required this.energyScore,
    required this.quote,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyDirection,
    required this.dayPillar,
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
