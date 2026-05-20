// R103 sprint 5A — past life inject() placeholder collision 회귀 가드.
//
// 사용자 verbatim 깨짐 보고:
//   1) "카리나가름" — `$celebName 이름` 가 `$celebName 이` (subj josa) 매치에 먼저
//      걸려 "카리나가" + "름" 으로 합쳐진 collision.
//   2) "선비가라는" — `$userRole이라는` 가 `$userRole이` (subj josa) 매치에 먼저
//      걸려 "선비가" + "라는" 으로 합쳐진 collision (받침 없음 case).
//   3) "선비이라는" — 받침 보정 실패 (받침 없는 단어에 "이라는" 그대로 붙음).
//
// Sprint 5A fix:
//   - past_life_service.dart inject() 안에서 compound suffix
//     (이라는 / 이었어요 / 이었고 / 이에요 / 이름) 를 generic josa replacement
//     보다 먼저, placeholder 별로 명시 치환.
//   - 받침 보정:
//       받침 있음: "$word이라는", "$word이에요", "$word이었어요"
//       받침 없음: "$word라는",   "$word예요",   "$word였어요"
//   - "이름" noun collision 방지: placeholder + 공백 + 이름 으로 통일.
//
// 본 회귀 테스트는:
//   - 실 pool + 실 celeb 이름 (카리나) 으로 자연 collision 재현 시도.
//   - 합성 pool + 받침 있음/없음 role (행상 / 선비) 로 받침 보정 정확성 검증.
//   - 모든 generated scenario 에서 raw placeholder 잔존 0 검증.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/past_life_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> livePool;

  setUpAll(() async {
    final f = File('assets/data/past_life_pool.json');
    livePool = json.decode(await f.readAsString()) as Map<String, dynamic>;
  });

  tearDown(() {
    PastLifeService.resetCacheForTest();
  });

  SajuResult mk(String dJi, {String dGan = '戊'}) => SajuResult(
        yearPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
        monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
        dayPillar: Pillar(chunGan: dGan, jiJi: dJi),
        hourPillar: null,
        elements: const FiveElements(
            wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
        dayMaster: dGan,
        dayMasterName: 'Test',
        summary: 'test',
        categoryReadings: const {},
      );

  // ─── 1. 실 pool 회귀 — 자연 collision 재현 시도 ───────────────────────────
  group('R103 sprint 5A — 실 pool collision 회귀 가드', () {
    setUp(() {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(livePool);
    });

    // wonjin (子-未) / gongmang (子-戌) / hap (子-丑) / chung (子-午) 4 case.
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('gongmang', () => mk('子'), () => mk('戌')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
    ];

    // 받침 없음 (카리나, 아이유, 솔라) / 받침 있음 (김채원, 도현, 진영) 모두 커버.
    final celebNames = <String>['카리나', '아이유', '솔라', '김채원', '진영', '도현'];
    final userNames = <String>['주현', '도리', '하나', '윤서', '지훈'];

    test('200+ 시나리오 — collision 패턴 0', () {
      var n = 0;
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (final cn in celebNames) {
          for (final un in userNames) {
            for (var s = 0; s < 4; s++) {
              final scenario = PastLifeService.generateScenario(
                user: mkU(),
                celeb: mkC(),
                celebName: cn,
                userName: un,
                seed: s,
              );
              // 1) "$cn가름" / "$un가름" 패턴 0 (받침 없는 이름 + subj josa + "름").
              expect(scenario.contains('$cn가름'), isFalse,
                  reason: '[$label seed=$s cn=$cn] "$cn가름" collision: $scenario');
              expect(scenario.contains('${un}가름'), isFalse,
                  reason: '[$label seed=$s un=$un] "${un}가름" collision: $scenario');
              // 2) "$cn이름" 공백 없는 collision 형태도 0 (모든 형태는 공백 분리).
              //    "카리나이름" / "김채원이름" 둘 다 부자연 → 항상 공백 추가.
              expect(scenario.contains('${cn}이름'), isFalse,
                  reason: '[$label seed=$s cn=$cn] "${cn}이름" 공백 누락: $scenario');
              expect(scenario.contains('${un}이름'), isFalse,
                  reason: '[$label seed=$s un=$un] "${un}이름" 공백 누락: $scenario');
              // 3) "$cn가에요" / "$cn가었어요" / "$cn가었고" 패턴 0
              //    (받침 없는 이름 + subj josa + copula 잔존).
              expect(scenario.contains('${cn}가에요'), isFalse,
                  reason: '[$label seed=$s cn=$cn] "${cn}가에요" collision: $scenario');
              expect(scenario.contains('${un}가에요'), isFalse,
                  reason: '[$label seed=$s un=$un] "${un}가에요" collision: $scenario');
              expect(scenario.contains('${cn}가었어요'), isFalse,
                  reason: '[$label seed=$s cn=$cn] "${cn}가었어요" collision: $scenario');
              expect(scenario.contains('${un}가었어요'), isFalse,
                  reason: '[$label seed=$s un=$un] "${un}가었어요" collision: $scenario');
              // 4) raw placeholder 잔존 0.
              expect(scenario.contains(r'$celebName'), isFalse,
                  reason: '[$label seed=$s] raw \$celebName 잔존: $scenario');
              expect(scenario.contains(r'$userName'), isFalse,
                  reason: '[$label seed=$s] raw \$userName 잔존: $scenario');
              expect(scenario.contains(r'$userRole'), isFalse,
                  reason: '[$label seed=$s] raw \$userRole 잔존: $scenario');
              expect(scenario.contains(r'$celebRole'), isFalse,
                  reason: '[$label seed=$s] raw \$celebRole 잔존: $scenario');
              expect(scenario.contains(r'$era'), isFalse,
                  reason: '[$label seed=$s] raw \$era 잔존: $scenario');
              n++;
            }
          }
        }
      }
      // 4 case × 6 celeb × 5 user × 4 seed = 480 샘플.
      expect(n, greaterThanOrEqualTo(200));
    });
  });

  // ─── 2. 합성 pool — 받침 보정 정확성 검증 ─────────────────────────────────
  // 사용자 mandate (verbatim):
  //   - "선비라는" appears for 받침 없는 role (선비 — 비 받침 없음)
  //   - "행상이라는" appears for 받침 있는 role (행상 — 상 받침 ㅇ)
  //   - "선비이라는" 0 (받침 보정 실패 패턴)
  //   - "선비가라는" 0 (subj josa collision 패턴)
  group('R103 sprint 5A — 받침 보정 정확성 (합성 pool)', () {
    Map<String, dynamic> mkSyntheticPool({
      required String userRole,
      required String celebRole,
    }) {
      // 최소 pool — 모든 keyword 가 동일 합성 line 만 가짐.
      // body_lines 의 setup 에 "$userRole이라는" / "$celebRole이라는" 명시 삽입.
      const eras = ['고려 시대'];
      final relations = [
        {'user': userRole, 'celeb': celebRole},
      ];
      const intros = ['그 시대 두 사람의 이야기.'];
      const tails = ['결의 여운이 남았어요.'];
      const endings = ['그 결이 이번 생까지 따라왔어요.'];
      final bodyLines = <String, dynamic>{
        for (final k in [
          'wonjin',
          'dohwa',
          'yeokma',
          'cheoneul',
          'gongmang',
          'hap',
          'chung',
          'hyeong'
        ])
          k: <String, List<String>>{
            // raw 문자열 — placeholder 가 Dart 보간에 잡히지 않게.
            'setup': [
              r'$userRole이라는 자리와 $celebRole이라는 자리가 만났어요.',
            ],
            'event': ['중요한 일이 있었어요.'],
            'turn': ['시간이 흘렀어요.'],
            'resolution': ['그 결이 남았어요.'],
          },
      };
      final templates = <String, dynamic>{
        for (final k in [
          'wonjin',
          'dohwa',
          'yeokma',
          'cheoneul',
          'gongmang',
          'hap',
          'chung',
          'hyeong'
        ])
          k: <String, dynamic>{
            'intros': intros,
            'tails': tails,
          },
      };
      return {
        'eras': eras,
        'relations': relations,
        'endings': endings,
        'templates': templates,
        'body_lines': bodyLines,
      };
    }

    test('받침 없는 role (선비) → "선비라는" 자연 결합', () {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(
        mkSyntheticPool(userRole: '선비', celebRole: '선비'),
      );
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '주현',
        seed: 0,
      );
      // 받침 없는 role → "선비라는" (받침 보정 성공).
      expect(scenario.contains('선비라는'), isTrue,
          reason: '받침 없는 role "선비" + "라는" 결합 누락: $scenario');
      // bug 패턴 0.
      expect(scenario.contains('선비가라는'), isFalse,
          reason: 'subj josa collision 잔존: $scenario');
      expect(scenario.contains('선비이라는'), isFalse,
          reason: '받침 보정 실패 (받침 없는 role 에 "이라는" 그대로): $scenario');
    });

    test('받침 있는 role (행상) → "행상이라는" 자연 결합', () {
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(
        mkSyntheticPool(userRole: '행상', celebRole: '행상'),
      );
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '주현',
        seed: 0,
      );
      // 받침 있는 role → "행상이라는" (받침 보정 성공).
      expect(scenario.contains('행상이라는'), isTrue,
          reason: '받침 있는 role "행상" + "이라는" 결합 누락: $scenario');
      // bug 패턴 0.
      expect(scenario.contains('행상가라는'), isFalse,
          reason: 'subj josa collision 잔존: $scenario');
      expect(scenario.contains('행상라는'), isFalse,
          reason: '받침 보정 실패 (받침 있는 role 에 "라는" 그대로): $scenario');
    });

    test('카리나 (받침 없음) + 이름 collision 재현 시도 → "카리나가름" 0', () {
      // 합성 pool 에 "$celebName 이름" / "$celebName이름" 둘 다 line 으로 넣고
      // collision 발생 가능성 자체를 0 으로 가드.
      final pool = <String, dynamic>{
        'eras': ['고려 시대'],
        'relations': [
          {'user': '선비', 'celeb': '사환'},
        ],
        'endings': ['결의 여운이 남았어요.'],
        'templates': {
          for (final k in [
            'wonjin',
            'dohwa',
            'yeokma',
            'cheoneul',
            'gongmang',
            'hap',
            'chung',
            'hyeong'
          ])
            k: {
              'intros': ['그 시대 두 사람의 이야기.'],
              'tails': ['결의 여운이 남았어요.'],
            }
        },
        'body_lines': {
          for (final k in [
            'wonjin',
            'dohwa',
            'yeokma',
            'cheoneul',
            'gongmang',
            'hap',
            'chung',
            'hyeong'
          ])
            k: {
              'setup': [
                r'$celebName 이름을 처음 들었어요. $userName 이름도 함께였어요.',
              ],
              'event': [r'$celebName이름이 사방에 퍼졌어요. $userName이름도.'],
              'turn': [r'$celebName 이름과 $userName 이름이 함께 새겨졌어요.'],
              'resolution': ['그 결이 남았어요.'],
            },
        },
      };
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '주현',
        seed: 0,
      );
      // collision 패턴 0.
      expect(scenario.contains('카리나가름'), isFalse,
          reason: '"카리나가름" collision 잔존: $scenario');
      expect(scenario.contains('주현가름'), isFalse,
          reason: '"주현가름" collision 잔존: $scenario');
      // 공백 없는 collision 형태도 0 — 모든 "이름" 은 공백 분리 형태로 통일.
      expect(scenario.contains('카리나이름'), isFalse,
          reason: '"카리나이름" 공백 누락 collision 잔존: $scenario');
      expect(scenario.contains('주현이름'), isFalse,
          reason: '"주현이름" 공백 누락 collision 잔존: $scenario');
      // 정상 결과 = "카리나 이름" / "주현 이름".
      expect(scenario.contains('카리나 이름'), isTrue,
          reason: '"카리나 이름" 정상 형태 누락: $scenario');
      expect(scenario.contains('주현 이름'), isTrue,
          reason: '"주현 이름" 정상 형태 누락: $scenario');
    });

    test('합성 pool — 모든 compound suffix 정확 치환', () {
      // 받침 있음 + 없음 role 두 case 의 풀에 다양한 copula 형태 삽입.
      final pool = <String, dynamic>{
        'eras': ['조선 후기'],
        'relations': [
          {'user': '선비', 'celeb': '행상'},
        ],
        'endings': ['결이 남았어요.'],
        'templates': {
          for (final k in [
            'wonjin',
            'dohwa',
            'yeokma',
            'cheoneul',
            'gongmang',
            'hap',
            'chung',
            'hyeong'
          ])
            k: {
              'intros': ['그 시대.'],
              'tails': ['결의 여운.'],
            }
        },
        'body_lines': {
          for (final k in [
            'wonjin',
            'dohwa',
            'yeokma',
            'cheoneul',
            'gongmang',
            'hap',
            'chung',
            'hyeong'
          ])
            k: {
              'setup': [
                r'$userRole이라는 신분의 $userName과 $celebRole이라는 자리의 $celebName이 만났어요.',
              ],
              'event': [r'$userName이었어요. $celebName이에요.'],
              'turn': [r'$userRole이었고 $celebRole이었고 모두 흘러갔어요.'],
              'resolution': ['결이 남았어요.'],
            },
        },
      };
      PastLifeService.resetCacheForTest();
      PastLifeService.seedForTest(pool);
      final scenario = PastLifeService.generateScenario(
        user: mk('子'),
        celeb: mk('未'),
        celebName: '카리나',
        userName: '주현',
        seed: 0,
      );
      // 받침 없는 role/name: "선비라는" / "주현예요" / "주현이었어요"는 받침 ㄴ 이라 "이었어요"
      // 주의: "주현" 의 끝 글자 "현" 은 받침 ㄴ → 받침 있음 → "주현이었어요" / "주현이에요".
      // "카리나" 의 끝 글자 "나" 받침 없음 → "카리나예요".
      expect(scenario.contains('선비라는'), isTrue,
          reason: '"선비라는" 누락: $scenario');
      expect(scenario.contains('행상이라는'), isTrue,
          reason: '"행상이라는" 누락: $scenario');
      // bug 패턴 0.
      expect(scenario.contains('선비가라는'), isFalse,
          reason: '"선비가라는" collision 잔존: $scenario');
      expect(scenario.contains('선비이라는'), isFalse,
          reason: '"선비이라는" 받침 보정 실패: $scenario');
      expect(scenario.contains('행상가라는'), isFalse,
          reason: '"행상가라는" collision 잔존: $scenario');
      // raw placeholder 잔존 0.
      expect(scenario.contains(r'$'), isFalse,
          reason: 'raw \$ placeholder 잔존: $scenario');
    });
  });
}
