// Round 76 — NotificationService 사용자 시간 설정 검증.
// SharedPreferences 영속 + clamp 만 검증 (zonedSchedule 은 platform plugin
// 의존이라 unit test 환경에서 호출 X).

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService 알림 시간 영속', () {
    test('디폴트 시간은 8:00', () async {
      final t = await NotificationService.loadTime();
      expect(t.hour, 8);
      expect(t.minute, 0);
    });

    test('setTime + loadTime 라운드트립', () async {
      await NotificationService.setTime(13, 30);
      final t = await NotificationService.loadTime();
      expect(t.hour, 13);
      expect(t.minute, 30);
    });

    test('setTime 은 범위 초과 시 clamp', () async {
      await NotificationService.setTime(25, 70);
      final t = await NotificationService.loadTime();
      expect(t.hour, 23);
      expect(t.minute, 59);

      await NotificationService.setTime(-1, -1);
      final t2 = await NotificationService.loadTime();
      expect(t2.hour, 0);
      expect(t2.minute, 0);
    });

    test('needsReschedule — 저장된 signature 없으면 true', () async {
      // 초기 prefs 빈 상태 → 어떤 시그너처도 mismatch → true.
      final need = await NotificationService.needsReschedule(
        title: 't',
        body: 'b',
        useKo: true,
        hour: 8,
        minute: 0,
      );
      expect(need, isTrue);
    });

    test('needsReschedule — 시간 변경 감지', () async {
      // 직접 prefs 에 signature 주입 (8:00, nosaju) 후 시간 9:30 으로 비교 → true.
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig': 'ko|t|b||08:00|nosaju',
      });
      // 동일 시간 — false.
      final same = await NotificationService.needsReschedule(
        title: 't',
        body: 'b',
        useKo: true,
        hour: 8,
        minute: 0,
      );
      expect(same, isFalse);
      // 다른 시간 — true.
      final diff = await NotificationService.needsReschedule(
        title: 't',
        body: 'b',
        useKo: true,
        hour: 9,
        minute: 30,
      );
      expect(diff, isTrue);
    });

    test('Round 76 sprint 6 — fallback (nosaju) → deep (saju) 전환 시 reschedule', () async {
      // 직접 prefs 에 fallback signature 주입.
      SharedPreferences.setMockInitialValues({
        'app.notif.daily8am.scheduleSig': 'ko|t|b||08:00|nosaju',
      });
      final dummy = SajuResult.dummy();
      // saju 받으면 → signature deep:... 와 mismatch → true.
      final need = await NotificationService.needsReschedule(
        title: 't',
        body: 'b',
        useKo: true,
        hour: 8,
        minute: 0,
        saju: dummy,
      );
      expect(need, isTrue);
    });
  });
}
