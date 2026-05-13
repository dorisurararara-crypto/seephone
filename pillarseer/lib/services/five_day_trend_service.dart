// Pillar Seer — 5 일 trend service.
//
// 1등 운세 앱: 그제 → 어제 → 오늘 → 내일 → 모레 라인 그래프.
// "내일 점수 보고 싶어서 매일 들어옴" 효과 노림.
//
// 산식: DailyService 의 totalScore 패턴을 5 일에 적용 (같은 날 = 같은 점수, 일관성 보장).

import '../models/saju_result.dart';
import 'daily_service.dart';

class FiveDayPoint {
  final DateTime date;
  final int score;

  /// 한글 라벨 '그제'·'어제'·'오늘'·'내일'·'모레'.
  final String label;

  /// 영문 라벨 '−2D'·'−1D'·'TODAY'·'+1D'·'+2D'.
  final String labelEn;

  /// 오늘 marker 강조용.
  final bool isToday;

  const FiveDayPoint({
    required this.date,
    required this.score,
    required this.label,
    required this.labelEn,
    required this.isToday,
  });

  /// useKo flag → 노출용 라벨.
  String labelFor({required bool useKo}) => useKo ? label : labelEn;
}

class FiveDayTrendService {
  /// 한글 라벨 (UI 노출 — useKo == true).
  static const labelsKo = ['그제', '어제', '오늘', '내일', '모레'];

  /// 영문 라벨 (UI 노출 — useKo == false). labelsKo 와 1:1 대응.
  static const labelsEn = ['−2D', '−1D', 'TODAY', '+1D', '+2D'];

  /// [today] 기준 5 일 (-2 ~ +2 day) 의 점수 list.
  static List<FiveDayPoint> compute(SajuResult saju, {DateTime? today}) {
    final t = today ?? DateTime.now();
    final t0 = DateTime(t.year, t.month, t.day);
    final daily = DailyService();
    final out = <FiveDayPoint>[];
    for (var i = -2; i <= 2; i++) {
      final d = t0.add(Duration(days: i));
      final f = daily.calculate(saju, today: d);
      out.add(FiveDayPoint(
        date: d,
        score: f.totalScore,
        label: labelsKo[i + 2],
        labelEn: labelsEn[i + 2],
        isToday: i == 0,
      ));
    }
    return out;
  }
}
