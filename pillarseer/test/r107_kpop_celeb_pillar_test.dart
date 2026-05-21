// R107 #2 — K-POP 궁합 셀럽 사주 거짓말 0 회귀 가드.
//
// 문제 (codex audit): `_starToSajuResult` 가 셀럽의 年柱·月柱 자리를 `dayPillar`
// 로 임시(가짜) 복사했다. "셀럽 전체 사주 궁합" 처럼 보이지만 실제로는 일주만
// 진짜이고 年/月이 가짜 = 거짓.
//
// 수정: `CelebChartValidator`(= `ManseryeokService` 엔진) 로 셀럽 출생일에서 실제
// 年柱·月柱·日柱 3주를 계산해 채운다. 時柱는 출생 시 미상 → null 유지.
//
// 본 가드:
//   A. 셀럽 SajuResult 의 year/month/day pillar 가 서로 다르다 (가짜 copy 0).
//   B. 생년월일 → 3주 매핑이 `ManseryeokService` 엔진 계산값과 정확히 일치.
//   C. day60ji 가 celebrities.json 의 dayPillar 와 일치 (엔진 ↔ 기록 정합).
//   D. hourPillar 는 항상 null (시간 모름 mandate 보존).
//   E. elements.dominant 는 일간 천간 5행 기준 (R100/R101 점수 회귀 0 보존).
//   F. celebrities.json 전수 — 가짜 3주-동일 copy entry 0.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:pillarseer/screens/reports/kpop_compat_screen.dart' as kpop;
import 'package:pillarseer/services/celeb_chart_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R107 #2 — 셀럽 사주 거짓말 0 (실제 3주 계산)', () {
    // IU — 1993-05-16, 일주 丁卯 (Fire Rabbit).
    final iuJson = {
      'id': 'iu',
      'nameKo': '아이유',
      'nameEn': 'IU',
      'kind': 'icon',
      'birth': '1993-05-16',
      'dayPillar': '丁卯',
      'dayPillarName': 'Fire Rabbit',
      'gender': 'F',
      'blurbKo': '아이유.',
      'blurbEn': 'IU.',
    };

    test('A. year/month/day pillar 가 서로 다르다 — 가짜 copy 0', () {
      final r = kpop.starToSajuResultForTest(iuJson);
      // IU 1993-05-16 의 실제 3주는 모두 다르다.
      final ys = r.yearPillar.text;
      final ms = r.monthPillar.text;
      final ds = r.dayPillar.text;
      expect(
        ys == ms && ms == ds,
        isFalse,
        reason: '年/月/日 3주가 전부 동일하면 가짜 dayPillar copy 흔적. '
            'year=$ys month=$ms day=$ds',
      );
    });

    test('B. 생년월일 → 3주 매핑이 ManseryeokService 엔진 계산값과 일치', () {
      final r = kpop.starToSajuResultForTest(iuJson);
      final chart = CelebChartValidator.computeChart(
        celebId: 'iu',
        birth: '1993-05-16',
        isMale: false,
      );
      expect(chart, isNotNull);
      expect(r.yearPillar.text, chart!.yearPillar,
          reason: '年柱는 엔진 계산값과 일치해야 한다.');
      expect(r.monthPillar.text, chart.monthPillar,
          reason: '月柱는 엔진 계산값과 일치해야 한다.');
      expect(r.dayPillar.text, chart.dayPillar,
          reason: '日柱는 엔진 계산값과 일치해야 한다.');
    });

    test('C. day60ji 가 celebrities.json 의 기록 dayPillar 와 일치', () {
      final r = kpop.starToSajuResultForTest(iuJson);
      expect(r.day60ji, '丁卯',
          reason: '엔진 계산 日柱가 기록 dayPillar 와 정합해야 한다.');
    });

    test('D. hourPillar 는 항상 null — 시간 모름 mandate 보존', () {
      final r = kpop.starToSajuResultForTest(iuJson);
      expect(r.hourPillar, isNull,
          reason: '셀럽 출생 시 미상 — 時柱 절대 생성 금지.');
    });

    test('E. elements.dominant 는 일간 천간 5행 기준 — R100/R101 회귀 0', () {
      final r = kpop.starToSajuResultForTest(iuJson);
      // 丁 = 火.
      expect(r.elements.dominant, '火',
          reason: 'compat _score complementary 분기 회귀 0 보존.');
    });

    test('F. celebrities.json 전수 — 가짜 3주-동일 copy entry 0', () async {
      final raw =
          await rootBundle.loadString('assets/data/celebrities.json');
      final decoded = jsonDecode(raw);
      final List list = decoded is List
          ? decoded
          : (decoded['stars'] ?? decoded['celebrities']) as List;
      expect(list, isNotEmpty);

      int allSameCopy = 0;
      int checked = 0;
      final samples = <String>[];
      for (final entry in list) {
        final j = Map<String, dynamic>.from(entry as Map);
        final birth = (j['birth'] as String?) ?? '';
        if (birth.isEmpty) continue;
        checked++;
        final r = kpop.starToSajuResultForTest(j);
        // 日柱는 기록 dayPillar 와 일치해야 한다.
        final recordedDay = (j['dayPillar'] as String?) ?? '';
        if (recordedDay.length >= 2) {
          expect(r.day60ji, recordedDay,
              reason: '${j['id']} 日柱 불일치 — 엔진 ↔ 기록 정합 깨짐.');
        }
        // 3주가 전부 동일 = 옛 가짜 copy 흔적.
        if (r.yearPillar.text == r.monthPillar.text &&
            r.monthPillar.text == r.dayPillar.text) {
          allSameCopy++;
          if (samples.length < 5) samples.add('${j['id']}($birth)');
        }
        // 時柱는 항상 null.
        expect(r.hourPillar, isNull, reason: '${j['id']} 時柱 누수.');
      }
      expect(checked, greaterThan(200),
          reason: 'celebrities.json 전 entry 검사.');
      // 60갑자상 한 사람의 年=月=日 가 우연히 모두 같을 확률은 사실상 0.
      // 한 명도 없어야 가짜 copy 가 완전히 제거된 것.
      expect(allSameCopy, 0,
          reason: '3주가 전부 동일한 entry = 가짜 copy 잔존: $samples');
    });
  });
}
