// R102 sprint 2 — placeholder + 공백 + 조사 잔존 가드.
//
// 사용자 OCR verbatim ("당신 과 김채원 의 / 김채원 도") 회귀.
// 150 시나리오 sample = 10 celeb name × 15 seed.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> pool;

  setUpAll(() async {
    final f = File('assets/data/past_life_pool.json');
    pool = json.decode(await f.readAsString()) as Map<String, dynamic>;
    PastLifeService.resetCacheForTest();
    PastLifeService.seedForTest(pool);
  });

  tearDownAll(() {
    PastLifeService.resetCacheForTest();
  });

  SajuResult makeSaju({
    required String yGan,
    required String yJi,
    required String mGan,
    required String mJi,
    required String dGan,
    required String dJi,
  }) {
    return SajuResult(
      yearPillar: Pillar(chunGan: yGan, jiJi: yJi),
      monthPillar: Pillar(chunGan: mGan, jiJi: mJi),
      dayPillar: Pillar(chunGan: dGan, jiJi: dJi),
      hourPillar: null,
      elements: const FiveElements(
          wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
      dayMaster: dGan,
      dayMasterName: 'Test',
      summary: 'test',
      categoryReadings: const {},
    );
  }

  // 다양한 받침 / 무받침 / 한자 / 영문 / 1글자 / 긴 글자 등 셀럽 이름 10종.
  final celebNames = <String>[
    '김채원',
    '솔라',
    '아이유',
    '뷔',
    '카리나',
    '윈터',
    '닝닝',
    '지젤',
    '하니',
    '민지',
  ];

  // 받침/무받침 다양한 사용자 이름.
  final userNames = <String>['당신', '너', '주현', '도리'];

  // 조사 + 공백 잔존 패턴.
  //  - placeholder × 조사: "$X 도" / "$X 에게" 같은 잔존 케이스가 단순 한글 사이에
  //    " 도 " " 의 " 등으로 남으면 안 됨.
  //  - 단, 한국어 자연 어순에서 " 도 " 같은 패턴이 정상적으로 나올 수 있으므로
  //    실명 직후의 공백 + 조사 패턴만 본다.
  //  - 즉 user/celeb name 직후의 " (과|와|은|는|이|가|을|를|의|도|에게|에서|에|부터|까지|보다|만|처럼) " 가
  //    placeholder 잔존의 표식.
  bool hasLooseJosaAdjacent(String s, String name) {
    if (name.isEmpty) return false;
    // 정규식 그룹: name 직후 공백 + 조사 + 공백/문장끝.
    final escaped = RegExp.escape(name);
    final re = RegExp(
      '$escaped '
      r'(과|와|은|는|이|가|을|를|의|도|에게|에서|에|부터|까지|보다|만|처럼|로|으로|한테|뿐|조차|마저)'
      r'(\s|\.|,|!|\?|$)',
    );
    return re.hasMatch(s);
  }

  group('R102 — placeholder × 공백 + 조사 0 회귀', () {
    final caseDefs = <(String, SajuResult Function(), SajuResult Function())>[
      (
        'wonjin#子-未',
        () => makeSaju(
            yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰',
            dGan: '戊', dJi: '子'),
        () => makeSaju(
            yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉',
            dGan: '己', dJi: '未'),
      ),
      (
        'hap#子-丑',
        () => makeSaju(
            yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰',
            dGan: '戊', dJi: '子'),
        () => makeSaju(
            yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉',
            dGan: '辛', dJi: '丑'),
      ),
      (
        'chung#子-午',
        () => makeSaju(
            yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰',
            dGan: '戊', dJi: '子'),
        () => makeSaju(
            yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉',
            dGan: '辛', dJi: '午'),
      ),
    ];

    test('150 시나리오 — placeholder + 공백 + 조사 잔존 0', () {
      var totalChecked = 0;
      for (final cd in caseDefs) {
        final (label, mkU, mkC) = cd;
        for (final celebName in celebNames) {
          for (var seed = 0; seed < 5; seed++) {
            final u = mkU();
            final c = mkC();
            final scenario = PastLifeService.generateScenario(
              user: u,
              celeb: c,
              celebName: celebName,
              userName: '당신',
              seed: seed,
            );
            // user/celeb name 직후 공백+조사 잔존이 없어야 함.
            expect(hasLooseJosaAdjacent(scenario, celebName), isFalse,
                reason: '[$label seed=$seed celeb=$celebName] '
                    'loose josa after celeb in: $scenario');
            expect(hasLooseJosaAdjacent(scenario, '당신'), isFalse,
                reason: '[$label seed=$seed celeb=$celebName] '
                    'loose josa after user in: $scenario');
            // placeholder 잔존 0.
            expect(scenario.contains(r'$celebName'), isFalse);
            expect(scenario.contains(r'$userName'), isFalse);
            expect(scenario.contains(r'$userRole'), isFalse);
            expect(scenario.contains(r'$celebRole'), isFalse);
            totalChecked++;
          }
        }
      }
      // 3 case × 10 celeb × 5 seed = 150 sample 보장.
      expect(totalChecked, greaterThanOrEqualTo(150));
    });

    test('다양한 user name 받침 × 잔존 0', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅', mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳', mGan: '丁', mJi: '酉',
          dGan: '己', dJi: '未');
      for (final uname in userNames) {
        for (var seed = 0; seed < 3; seed++) {
          final scenario = PastLifeService.generateScenario(
            user: u,
            celeb: c,
            celebName: '솔라',
            userName: uname,
            seed: seed,
          );
          expect(hasLooseJosaAdjacent(scenario, uname), isFalse,
              reason: '[seed=$seed user=$uname] loose: $scenario');
          expect(hasLooseJosaAdjacent(scenario, '솔라'), isFalse);
        }
      }
    });
  });
}
