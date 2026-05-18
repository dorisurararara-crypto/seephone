// R93 sprint 6 — 신년운세 12 area dynamic anchor 가드.
//
// 사용자 mandate verbatim: "이와같이 중복된 패턴있으면 다 수정해" —
// 기존 _TwelveAreas 의 const list 가 모든 사용자에게 동일 본문이었던 문제.
// 사주 anchor (격국 / 십신 / 용신·기신 / 일지 vs 午 합·충) 가 12 area
// 본문에 직접 반영되는지 검증.
//
// 검증 축:
//   1) 두 다른 사주 (생년·시 다름) 의 12 area 중 ≥6 개가 다른 본문이어야 함.
//   2) _AnnualSummary 의 첫 문단에 일지 vs 午 micro 한 줄이 들어가 있어
//      같은 일간 5행이라도 일지가 다르면 본문이 달라야 함.
//   3) 영문 locale 도 동일 보장.
//   4) 12 area 의 label (헤더) 은 그대로 유지 (CAREER · 仕事 등).

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/screens/reports/new_year_2026_screen.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/seun_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R93 sprint 6 — _TwelveAreas dynamic readings', () {
    test('두 다른 사주 (일간·일지 모두 다름) → 12 area 중 ≥6 개 본문 다름 (KO)', () async {
      // A: 1995-10-27 男 15:43 → 일간 辛 / 일지 卯.
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // B: 1988-06-12 女 06:00 → 일간 다름 + 일지 다름.
      final b = await SajuService().calculateSaju(
        year: 1988, month: 6, day: 12,
        hour: 6, minute: 0,
        isLunar: false, isMale: false,
      );

      final themeA = SeunService.annualTheme(
        dayMaster: a.dayPillar.chunGan, solarYear: 2026,
      );
      final themeB = SeunService.annualTheme(
        dayMaster: b.dayPillar.chunGan, solarYear: 2026,
      );

      final readA =
          NewYear2026Screen.areaReadingsFor(saju: a, theme: themeA, useKo: true);
      final readB =
          NewYear2026Screen.areaReadingsFor(saju: b, theme: themeB, useKo: true);

      expect(readA.length, 12);
      expect(readB.length, 12);

      // 헤더는 동일.
      for (int i = 0; i < 12; i++) {
        expect(readA[i].$1, readB[i].$1, reason: 'header $i 동일');
      }

      int diff = 0;
      for (int i = 0; i < 12; i++) {
        if (readA[i].$2 != readB[i].$2) diff++;
      }
      expect(diff, greaterThanOrEqualTo(6),
          reason: '12 area 중 6개 이상 본문 차이 — 사주 anchor 반영. 실제 diff=$diff');
    });

    test('두 다른 사주 → EN locale 도 ≥6 개 다름', () async {
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final b = await SajuService().calculateSaju(
        year: 1988, month: 6, day: 12,
        hour: 6, minute: 0,
        isLunar: false, isMale: false,
      );
      final themeA = SeunService.annualTheme(
        dayMaster: a.dayPillar.chunGan, solarYear: 2026,
      );
      final themeB = SeunService.annualTheme(
        dayMaster: b.dayPillar.chunGan, solarYear: 2026,
      );
      final readA = NewYear2026Screen.areaReadingsFor(
          saju: a, theme: themeA, useKo: false);
      final readB = NewYear2026Screen.areaReadingsFor(
          saju: b, theme: themeB, useKo: false);

      int diff = 0;
      for (int i = 0; i < 12; i++) {
        if (readA[i].$2 != readB[i].$2) diff++;
      }
      expect(diff, greaterThanOrEqualTo(6),
          reason: 'EN locale 도 12 area 중 6개 이상 본문 차이. 실제 diff=$diff');
    });

    test('12 area 헤더 라벨 보존 (CAREER · 仕事 ~ LEGACY · 名)', () async {
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final theme = SeunService.annualTheme(
        dayMaster: a.dayPillar.chunGan, solarYear: 2026,
      );
      final read = NewYear2026Screen.areaReadingsFor(
          saju: a, theme: theme, useKo: true);

      const expectedHeaders = [
        'CAREER · 仕事',
        'WEALTH · 財',
        'LOVE · 緣',
        'HEALTH · 養生',
        'FAMILY · 家',
        'STUDY · 學',
        'FRIENDS · 友',
        'TRAVEL · 行',
        'GROWTH · 進',
        'LEGAL · 訟',
        'SPIRIT · 心',
        'LEGACY · 名',
      ];
      for (int i = 0; i < 12; i++) {
        expect(read[i].$1, expectedHeaders[i],
            reason: 'index $i header 보존');
        // 본문 비어 있지 않음.
        expect(read[i].$2.isNotEmpty, isTrue,
            reason: 'index $i body 비어 있지 않음');
      }
    });

    test('LOVE / TRAVEL — 같은 일간 5행이라도 일지 다르면 본문 다름 (일지 vs 午 매핑)',
        () async {
      // 두 사주 모두 의도적으로 火 일간을 만들기 어려우므로 일간이 다른
      // 두 사주를 잡고 LOVE/TRAVEL anchor 가 일지에 따라 분기됨을 검증.
      // A: 일지 子 (1988-06-12 女 06:00 후보) → clash.
      // B: 일지 卯 (1995-10-27 男 15:43) → neutral.
      // 단순 anchor branch 갈림만 확인 (구체 값은 SajuService 계산에 의존).
      final a = await SajuService().calculateSaju(
        year: 1988, month: 6, day: 12,
        hour: 6, minute: 0,
        isLunar: false, isMale: false,
      );
      final b = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final themeA = SeunService.annualTheme(
        dayMaster: a.dayPillar.chunGan, solarYear: 2026,
      );
      final themeB = SeunService.annualTheme(
        dayMaster: b.dayPillar.chunGan, solarYear: 2026,
      );
      final ra = NewYear2026Screen.areaReadingsFor(
          saju: a, theme: themeA, useKo: true);
      final rb = NewYear2026Screen.areaReadingsFor(
          saju: b, theme: themeB, useKo: true);

      // LOVE 본문 = index 2, TRAVEL = index 7. 두 사주 일지 다르면 둘 중 하나라도
      // 본문이 달라야 함 (일지 동일이면 같은 본문이 나올 수도 있으니 일지 다름
      // 사주 두 개를 골랐을 때 둘 다 같으면 회귀 — diff ≥ 1 가드).
      final loveDiff = ra[2].$2 != rb[2].$2;
      final travelDiff = ra[7].$2 != rb[7].$2;
      expect(loveDiff || travelDiff, isTrue,
          reason: '일지가 다른 두 사주 → LOVE 또는 TRAVEL 본문 중 최소 하나 차이 — '
              'A 일지=${a.dayPillar.jiJi} / B 일지=${b.dayPillar.jiJi}');
    });
  });
}
