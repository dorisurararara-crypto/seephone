class SajuResult {
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String hourPillar;
  final String summary;
  final List<String> details;

  SajuResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.summary,
    required this.details,
  });

  factory SajuResult.dummy() {
    return SajuResult(
      yearPillar: '甲子',
      monthPillar: '丙寅',
      dayPillar: '戊辰',
      hourPillar: '庚午',
      summary: '당신은 봄의 기운을 타고난 웅장한 산과 같습니다.',
      details: [
        '자수성가할 운명으로 초년에 고생이 있으나 중년 이후 크게 번창합니다.',
        '솔직하고 담백한 성격으로 주변의 신뢰를 한몸에 받습니다.',
        '재물운이 강하여 평생 의식주 걱정이 없는 복을 타고났습니다.',
      ],
    );
  }
}
