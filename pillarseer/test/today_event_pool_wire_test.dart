// Round 77 sprint 2 — today_event_pool.json wire 검증.
// - ensurePoolLoaded 후 90 entries (30 key × 3) 로드
// - composeBodyKo / Caution / Recommend deterministic
// - pool 미적재 시 graceful (fallback 6분기)

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/today_event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TodayEventService.ensurePoolLoaded();
  });

  group('today_event_pool wire', () {
    test('ensurePoolLoaded 후 pool 적재 — debugHasPoolEntry true', () {
      final reading = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      final has = TodayEventService.debugHasPoolEntry(
        reading: reading,
        date: DateTime(2026, 5, 14),
        day60ji: '甲子',
      );
      expect(has, isTrue, reason: 'pool 적재 후 entry 미스 — 매핑 깨짐');
    });

    test('composeBodyKo deterministic — 같은 입력 → 같은 body', () {
      final reading = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      final d = DateTime(2026, 5, 14);
      final a = TodayEventService.composeBodyKo(
          reading: reading, date: d, day60ji: '甲子');
      final b = TodayEventService.composeBodyKo(
          reading: reading, date: d, day60ji: '甲子');
      expect(a, equals(b));
    });

    test('composeBodyKo ≤300자 + non-empty', () {
      final reading = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      final body = TodayEventService.composeBodyKo(
        reading: reading,
        date: DateTime(2026, 5, 14),
        day60ji: '甲子',
      );
      expect(body, isNotEmpty);
      expect(body.length, lessThanOrEqualTo(300));
    });

    test('composeCautionKo / composeRecommendKo non-null + 가능성 헷지 톤', () {
      final reading = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      final caution = TodayEventService.composeCautionKo(
        reading: reading,
        date: DateTime(2026, 5, 14),
        day60ji: '甲子',
      );
      final recommend = TodayEventService.composeRecommendKo(
        reading: reading,
        date: DateTime(2026, 5, 14),
        day60ji: '甲子',
      );
      expect(caution, isNotNull);
      expect(caution, isNotEmpty);
      expect(recommend, isNotNull);
      expect(recommend, isNotEmpty);
      // 단정 톤 금지 — "반드시" / "큰돈을 잃" / "병원" / "사고가" 패턴 X.
      for (final s in [caution!, recommend!]) {
        for (final banned in ['반드시', '큰돈을 잃', '병원', '사고가']) {
          expect(s.contains(banned), isFalse,
              reason: 'pool 톤 위반: "$banned" in "$s"');
        }
      }
    });

    test('pool 미적재 (debugResetPool) 시 composeBodyKo 가 fallback 6분기 사용', () async {
      TodayEventService.debugResetPool();
      addTearDown(() async {
        await TodayEventService.ensurePoolLoaded();
      });
      final reading = TodayEventService.build(
        userDayStem: '甲',
        userDayBranch: '子',
        userMonthBranch: '寅',
        todayPillar: '丙戌',
        todayScore: 60,
      );
      final body = TodayEventService.composeBodyKo(
        reading: reading,
        date: DateTime(2026, 5, 14),
        day60ji: '甲子',
      );
      // fallback 6분기 본문은 항상 "오늘은" 으로 시작 — graceful 확인.
      expect(body, isNotEmpty);
      expect(body.startsWith('오늘은'), isTrue,
          reason: 'fallback 6분기 미적용: "$body"');
      // caution/recommend 는 미적재 시 null.
      final caution = TodayEventService.composeCautionKo(
        reading: reading,
        date: DateTime(2026, 5, 14),
        day60ji: '甲子',
      );
      expect(caution, isNull, reason: 'pool 미적재 시 caution 은 null 이어야');
    });
  });
}
