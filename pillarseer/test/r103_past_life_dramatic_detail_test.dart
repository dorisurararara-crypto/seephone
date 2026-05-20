// R103 sprint 1 — dramatic detail ≥ 2 가드.
//
// 사용자 mandate verbatim: "소설 내용도 별로야 처음에 예시로 줬던 느낌으로 해야돼".
// 사용자 verbatim 예시: "몰락한 귀족" + "감시하던 스파이" + "원진살이 껴있는 걸 보니"
//   + "이번 생에도 돈 뺏기지만 행복할 운명".
// → 각 시나리오에 dramatic detail (role / conflict / object / event 중 2+) 존재.

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

  SajuResult mk(String dJi) => SajuResult(
        yearPillar: const Pillar(chunGan: '甲', jiJi: '寅'),
        monthPillar: const Pillar(chunGan: '丙', jiJi: '辰'),
        dayPillar: Pillar(chunGan: '戊', jiJi: dJi),
        hourPillar: null,
        elements: const FiveElements(
            wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
        dayMaster: '戊',
        dayMasterName: 'Test',
        summary: 'test',
        categoryReadings: const {},
      );

  // Drama signal keywords — 사용자 verbatim spirit ("몰락한 귀족" / "스파이" /
  // 사주살 명시 / "돈 뺏기지만 행복" 같은 어두운 농담).
  //   bucket1 = 신분/역할 (몰락한 / 스파이 / 검객 / 도굴꾼 / 첩자 / 자객 / 비밀결사 ...)
  //   bucket2 = 사건/objects (옥패 / 손수건 / 부적 / 편지 / 쪽지 / 도망 / 추격 / 잡혔 ...)
  //   bucket3 = 사주살 명시 (원진살 / 도화살 / 역마살 / 천을귀인 / 공망 / 합 결 / 충 결 / 형 결)
  //   bucket4 = 이번 생 punchline (앨범 / 굿즈 / 콘서트 / 직캠 / 응원봉 / 알고리즘 / 카드값 / 티켓팅 / 비행기표 / 음원)
  const bucketRole = <String>[
    '몰락한', '스파이', '검객', '도굴꾼', '첩자', '자객', '비밀',
    '망명', '추방', '도망', '광대', '무희', '의원', '도제',
    '봇짐장수', '인력거꾼', '약초상', '시인', '화공', '악사',
    '독약', '독을', '음모', '소문', '신분', '가짜',
  ];
  const bucketObject = <String>[
    '옥패', '손수건', '부적', '편지', '쪽지', '도망', '잡혔', '비밀',
    '담요', '책', '돌', '꽃', '메모', '편지', '약속',
    '신호', '암호', '쫓기', '면회', '회합', '추격',
  ];
  const bucketSajuSal = <String>[
    '원진살', '도화살', '역마살', '천을귀인', '공망', '합 결',
    '충 결', '형 결', '원진', '도화', '역마',
  ];
  const bucketPunchline = <String>[
    '앨범', '굿즈', '콘서트', '직캠', '응원봉', '알고리즘',
    '카드값', '티켓팅', '비행기표', '음원', '플레이리스트',
    '음원 1위', '인스타', '브이로그', '포카', '신곡', '컴백',
    '라이브 방송', '월드 투어',
  ];

  int bucketHits(String s, List<String> bucket) {
    return bucket.where((w) => s.contains(w)).length;
  }

  /// 시나리오에 4 bucket 중 2 bucket 이상 매칭 → dramatic detail ≥ 2.
  int dramaticDetailScore(String s) {
    var score = 0;
    if (bucketHits(s, bucketRole) > 0) score++;
    if (bucketHits(s, bucketObject) > 0) score++;
    if (bucketHits(s, bucketSajuSal) > 0) score++;
    if (bucketHits(s, bucketPunchline) > 0) score++;
    return score;
  }

  group('R103 — dramatic detail ≥ 2 per scenario', () {
    final cases = <(String, SajuResult Function(), SajuResult Function())>[
      ('wonjin', () => mk('子'), () => mk('未')),
      ('hap', () => mk('子'), () => mk('丑')),
      ('chung', () => mk('子'), () => mk('午')),
      ('gongmang', () => mk('子'), () => mk('戌')),
      ('cheoneul', () => mk('子'), () => mk('丑')), // 천을귀인 hit 안 될 수 있으나 hap fallback OK
    ];

    final celebs = <String>['솔라', '카리나', '뷔', '아이유', '이찬원'];

    test('50 sample dramatic detail ≥ 2', () {
      var failures = 0;
      final failureExamples = <String>[];
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (final celeb in celebs) {
          for (var seed = 0; seed < 2; seed++) {
            final scenario = PastLifeService.generateScenario(
              user: mkU(),
              celeb: mkC(),
              celebName: celeb,
              userName: '당신',
              seed: seed,
            );
            final score = dramaticDetailScore(scenario);
            if (score < 2) {
              failures++;
              if (failureExamples.length < 5) {
                failureExamples.add(
                    '[$label/$celeb/seed=$seed] score=$score: $scenario');
              }
            }
          }
        }
      }
      expect(failures, 0,
          reason: 'dramatic detail < 2 → ${failureExamples.join("\n\n")}');
    });

    test('사주살 bucket 50 sample 모두 hit (≥ 1)', () {
      for (final cd in cases) {
        final (label, mkU, mkC) = cd;
        for (final celeb in celebs) {
          for (var seed = 0; seed < 2; seed++) {
            final scenario = PastLifeService.generateScenario(
              user: mkU(),
              celeb: mkC(),
              celebName: celeb,
              userName: '당신',
              seed: seed,
            );
            final hits = bucketHits(scenario, bucketSajuSal);
            expect(hits, greaterThan(0),
                reason: '[$label/$celeb/seed=$seed] 사주살 명시 0: $scenario');
          }
        }
      }
    });
  });
}
