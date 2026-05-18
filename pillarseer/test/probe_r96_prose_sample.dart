// R96 hotfix — 사람 검수용 sample 출력 probe.
// 실행: flutter test test/probe_r96_prose_sample.dart
//
// 오늘의 한 줄 (home_screen `_OracleHero._pool` polish) + 오늘 사주 총평
// (TodayDeepService.build bodyKo) sample 을 콘솔에 찍어 사람이 어색함 0 검증.
// 회귀 가드 아님 — 항상 PASS, expect 없음.

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/natural_prose_joiner.dart';
import 'package:pillarseer/services/today_deep_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('R96 sample — 오늘의 한 줄 10개 (home_screen _pool polish)', () {
    // home_screen.dart _OracleHero._pool 의 30 entry 중 dayEnergy 3 × stem 10
    // 풀에서 sample 추출. polish() 가 connector 자동 inject 안 함을 사람이 확인.
    const samples = <(String tag, String raw)>[
      (
        'actionDay / 辛 (사용자 보고 atom)',
        '오늘은 본인 스타일대로 가는 쪽이 정답이에요.\n사람들이 본인을 바로 기억해요.\n그게 오늘 본인의 장점이에요.',
      ),
      (
        'actionDay / 甲',
        '오늘은 본인이 먼저 움직이는 게 답이에요.\n망설이지 말고 한 번 던져 봐요.\n그 첫 한마디가 오늘 하루를 만들어요.',
      ),
      (
        'actionDay / 丙',
        '오늘은 본인 분위기 자체가 무기예요.\n한 발 앞에서 끌고 가는 자리가 맞아요.\n사람들이 본인 쪽으로 모여요.',
      ),
      (
        'mixedDay / 乙',
        '오늘은 한 박자 늦게 가도 본인 자리는 지켜져요.\n급한 결정은 하루 미뤄도 괜찮아요.\n작은 정리 하나가 본인 페이스를 만들어줘요.',
      ),
      (
        'mixedDay / 戊',
        '오늘은 미루던 한 가지를 끝낼 수 있는 텐션이에요.\n끝까지 한 번 가 봐요.\n그 결과는 딱 본인 이름으로 남아요.',
      ),
      (
        'mixedDay / 庚',
        '오늘은 바로 정하고 가도 좋아요.\n그 한 번이 본인 이미지를 만들어줘요.\n망설일 일이 아니에요.',
      ),
      (
        'restDay / 己',
        '오늘은 한 사람을 도와주기 좋은 날이에요.\n그 사람이 본인한테 고맙다고 해줘요.\n그 한마디로 본인 자리가 더 또렷해져요.',
      ),
      (
        'restDay / 壬',
        '오늘 키워드는 새 방향이에요.\n다음 할 일이 본인한테 먼저 보여요.\n그 결대로 가면 돼요.',
      ),
      (
        'restDay / 癸',
        '오늘은 한 사람 기억에 박히는 쪽이 본인이에요.\n그 사람이 본인을 쉽게 잊지 못해요.\n그게 다음 기회로 이어져요.',
      ),
      (
        'restDay / 丁',
        '오늘은 따뜻한 한마디가 본인의 무기예요.\n한 사람에게 말 한마디 더 챙겨봐요.\n그 사람이 본인 옆에서 안정감을 느껴요.',
      ),
    ];

    // ignore: avoid_print
    print('\n============ R96 SAMPLE — 오늘의 한 줄 (polish 결과) ============');
    for (final s in samples) {
      // ignore: avoid_print
      print('\n[${s.$1}]');
      // ignore: avoid_print
      print(NaturalProseJoiner.polish(s.$2));
    }
    // ignore: avoid_print
    print('\n=========================================================');
  });

  test('R96 sample — 오늘 사주 총평 10개 (TodayDeepService.build bodyKo)', () {
    // 다양한 일주 + 오늘 pillar + score 조합으로 dayEnergy / godPhrase / branch
    // 변주를 보장. ctx 미주입 (default body 만).
    const cases = <
      ({
        String label,
        String dayStem,
        String dayBranch,
        String monthBranch,
        String dom,
        String def,
        String todayPillar,
        int score,
      })
    >[
      (
        label: '1995-10-27 男 (사용자 골든 sample / 辛卯 / actionDay)',
        dayStem: '辛',
        dayBranch: '卯',
        monthBranch: '戌',
        dom: '金',
        def: '水',
        todayPillar: '丙戌',
        score: 72,
      ),
      (
        label: '甲寅 / 木 dominant / actionDay 高',
        dayStem: '甲',
        dayBranch: '寅',
        monthBranch: '寅',
        dom: '木',
        def: '土',
        todayPillar: '乙卯',
        score: 80,
      ),
      (
        label: '乙巳 / 木 dominant / mixedDay',
        dayStem: '乙',
        dayBranch: '巳',
        monthBranch: '午',
        dom: '木',
        def: '水',
        todayPillar: '戊午',
        score: 55,
      ),
      (
        label: '丙午 / 火 dominant / actionDay',
        dayStem: '丙',
        dayBranch: '午',
        monthBranch: '巳',
        dom: '火',
        def: '金',
        todayPillar: '丁未',
        score: 70,
      ),
      (
        label: '丁酉 / 火 dominant / restDay 低',
        dayStem: '丁',
        dayBranch: '酉',
        monthBranch: '申',
        dom: '金',
        def: '木',
        todayPillar: '癸亥',
        score: 28,
      ),
      (
        label: '戊辰 / 土 dominant / mixedDay',
        dayStem: '戊',
        dayBranch: '辰',
        monthBranch: '未',
        dom: '土',
        def: '水',
        todayPillar: '己丑',
        score: 50,
      ),
      (
        label: '己未 / 土 dominant / restDay',
        dayStem: '己',
        dayBranch: '未',
        monthBranch: '戌',
        dom: '土',
        def: '木',
        todayPillar: '甲子',
        score: 30,
      ),
      (
        label: '庚申 / 金 dominant / actionDay',
        dayStem: '庚',
        dayBranch: '申',
        monthBranch: '酉',
        dom: '金',
        def: '木',
        todayPillar: '辛酉',
        score: 78,
      ),
      (
        label: '壬子 / 水 dominant / mixedDay',
        dayStem: '壬',
        dayBranch: '子',
        monthBranch: '亥',
        dom: '水',
        def: '火',
        todayPillar: '癸丑',
        score: 60,
      ),
      (
        label: '癸亥 / 水 dominant / restDay',
        dayStem: '癸',
        dayBranch: '亥',
        monthBranch: '子',
        dom: '水',
        def: '火',
        todayPillar: '丙午',
        score: 25,
      ),
    ];

    // ignore: avoid_print
    print('\n============ R96 SAMPLE — 오늘 사주 총평 (TodayDeepService bodyKo) ============');
    for (final c in cases) {
      final r = TodayDeepService.build(
        userDayStem: c.dayStem,
        userDayBranch: c.dayBranch,
        userMonthBranch: c.monthBranch,
        userDominantEl: c.dom,
        userDeficitEl: c.def,
        todayPillar: c.todayPillar,
        todayScore: c.score,
      );
      final sentenceCount = RegExp(r'[.!?。]').allMatches(r.bodyKo).length;
      // ignore: avoid_print
      print('\n[${c.label}] — ${sentenceCount}문장');
      // ignore: avoid_print
      print('headline: ${r.headlineKo}');
      // ignore: avoid_print
      print('body    : ${r.bodyKo}');
    }
    // ignore: avoid_print
    print('\n========================================================================\n');
  });
}
