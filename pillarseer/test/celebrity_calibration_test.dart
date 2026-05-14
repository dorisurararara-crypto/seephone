// 셀럽 calibration test — 알려진 성격 vs 앱 출력 비교.
// 시간 미공개 셀럽이 대부분이라 unknownTime: true (시주 X).
// expect 는 형식 통과만, 실제 검증은 print 출력으로 사람이 비교.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';

class _Celeb {
  final String name;
  final int y, m, d;
  final bool isMale;
  final String knownPersona;
  const _Celeb(this.name, this.y, this.m, this.d, this.isMale, this.knownPersona);
}

void main() {
  group('Celebrity calibration — known persona vs app output', () {
    const celebs = <_Celeb>[
      _Celeb('아이유 (이지은)',    1993, 5, 16, false, '성실·노력파·자기절제·음악천재·책임감·신중'),
      _Celeb('BTS RM (김남준)',    1994, 9, 12, true,  '지적·리더십·책임감·깊이·사색·언어감각'),
      _Celeb('BTS V (김태형)',     1995, 12, 30, true, '4차원·예술감성·자유·사교·감성·즉흥'),
      _Celeb('BLACKPINK 제니',     1996, 1, 16, false, '카리스마·도도·직설·패션감각·확고함'),
      _Celeb('류현진',             1987, 3, 25, true,  '우직·평정심·멘탈강함·끈기·과묵'),
      _Celeb('김연아',             1990, 9, 5,  false, '완벽주의·강인·카리스마·집중·자기관리'),
      _Celeb('봉준호',             1969, 9, 14, true,  '디테일·사회의식·예술·관찰력·끈기'),
    ];

    test('각 셀럽 사주 결과 출력', () async {
      final svc = SajuService();
      final lines = <String>[];
      lines.add('');
      lines.add('===== 셀럽 calibration 결과 =====');
      for (final c in celebs) {
        final r = await svc.calculateSaju(
          year: c.y, month: c.m, day: c.d,
          hour: 0, minute: 0,
          isLunar: false, isMale: c.isMale,
          unknownTime: true,
          applyTrueSunTime: true,
          birthCity: '서울',
        );
        lines.add('');
        lines.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        lines.add('🌟 ${c.name}  (${c.y}-${c.m.toString().padLeft(2, '0')}-${c.d.toString().padLeft(2, '0')})');
        lines.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        lines.add('  년주 ${r.yearPillar.text}   월주 ${r.monthPillar.text}   일주 ${r.dayPillar.text}');
        lines.add('  일간 ${r.dayMaster} (${r.dayMasterName})');
        lines.add('  5행: 木${r.elements.wood}% 火${r.elements.fire}% 土${r.elements.earth}% 金${r.elements.metal}% 水${r.elements.water}%');
        lines.add('  dominant: ${r.elements.dominant}   deficit: ${r.elements.deficit}');
        lines.add('');
        lines.add('  ✅ 알려진 성격: ${c.knownPersona}');
        if (r.deepKo != null) {
          final dk = r.deepKo!;
          lines.add('');
          lines.add('  📱 앱 출력 — oneLineYouAre:');
          lines.add('     ${dk.oneLineYouAre}');
          lines.add('  📱 personalityHook:');
          lines.add('     ${dk.personalityHook}');
          lines.add('  📱 elementsNote:');
          lines.add('     ${dk.elementsNote}');
          lines.add('  📱 tenGodsNote:');
          lines.add('     ${dk.tenGodsNote}');
          lines.add('  📱 whyReason:');
          lines.add('     ${dk.whyReason}');
        } else {
          lines.add('  (deepKo null — asset load 실패 가능. 5행/dominant 기반 추정만)');
        }
      }
      lines.add('');
      lines.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // 한 번에 print
      // ignore: avoid_print
      print(lines.join('\n'));
      expect(celebs.length, 7);
    });
  });
}
