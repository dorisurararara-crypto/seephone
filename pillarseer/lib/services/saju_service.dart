import '../models/saju_result.dart';

class SajuService {
  Future<SajuResult> calculateSaju({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required bool isLunar,
    required bool isMale,
  }) async {
    // 실제 계산 로직은 나중에 구현
    // 지금은 1초 대기 후 더미 데이터 반환
    await Future.delayed(const Duration(seconds: 1));
    return SajuResult.dummy();
  }
}
