// Pillar Seer — 일일 체크인 streak (점신 강점 engagement 패턴).
// 매일 첫 진입 시 streak +1. 24h 안에 다음 진입 없으면 끊김.

import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _kCurrent = 'app.streak.current';
  static const _kLongest = 'app.streak.longest';
  static const _kLastCheckIn = 'app.streak.last_checkin_ms';

  /// 호출 시 오늘 첫 체크인이면 streak 증가, 어제가 아니면 reset.
  /// 반환: (current, longest, isNewDay)
  static Future<({int current, int longest, bool isNewDay})> tick() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastMs = prefs.getInt(_kLastCheckIn);
    int current = prefs.getInt(_kCurrent) ?? 0;
    int longest = prefs.getInt(_kLongest) ?? 0;
    bool isNewDay = false;
    if (lastMs == null) {
      // 첫 체크인
      current = 1;
      isNewDay = true;
    } else {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final lastDay = DateTime(last.year, last.month, last.day);
      final diffDays = today.difference(lastDay).inDays;
      if (diffDays == 0) {
        // 오늘 이미 체크인
      } else if (diffDays == 1) {
        current += 1;
        isNewDay = true;
      } else {
        // 끊김 → reset
        current = 1;
        isNewDay = true;
      }
    }
    if (current > longest) longest = current;
    if (isNewDay) {
      await prefs.setInt(_kCurrent, current);
      await prefs.setInt(_kLongest, longest);
      await prefs.setInt(_kLastCheckIn, today.millisecondsSinceEpoch);
    }
    return (current: current, longest: longest, isNewDay: isNewDay);
  }

  static Future<({int current, int longest})> read() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      current: prefs.getInt(_kCurrent) ?? 0,
      longest: prefs.getInt(_kLongest) ?? 0,
    );
  }
}
