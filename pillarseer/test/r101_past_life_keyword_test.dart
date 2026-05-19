// R101 Sprint 4 — 전생 시나리오(팬심 1순위) keyword 회귀 가드.
//
// 목표:
//   1. past_life_pool.json parse OK + 구조 무결성
//   2. 원진살 6쌍 양방향 감지 (子-未 / 丑-午 / 寅-酉 / 卯-申 / 辰-亥 / 巳-戌)
//   3. 8 keyword 모두 최소 1개 시나리오 생성 가능 (template 3 minimum)
//   4. 8 keyword × 최소 3 sample = 24 case → 한국어 출력 0 영어 leak
//   5. seed deterministic — 같은 seed → 같은 시나리오 / 다른 seed → 다른 시나리오
//   6. KO 본문에 anchor / Water Rabbit / 그룹명 영문 head 0

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

  // ───────────────── helpers ─────────────────

  SajuResult makeSaju({
    required String yGan,
    required String yJi,
    required String mGan,
    required String mJi,
    required String dGan,
    required String dJi,
    String? hGan,
    String? hJi,
  }) {
    return SajuResult(
      yearPillar: Pillar(chunGan: yGan, jiJi: yJi),
      monthPillar: Pillar(chunGan: mGan, jiJi: mJi),
      dayPillar: Pillar(chunGan: dGan, jiJi: dJi),
      hourPillar:
          hGan != null && hJi != null ? Pillar(chunGan: hGan, jiJi: hJi) : null,
      elements: const FiveElements(
          wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
      dayMaster: dGan,
      dayMasterName: 'Test',
      summary: 'test',
      categoryReadings: const {},
    );
  }

  // ───────────────── 1. JSON 구조 ─────────────────

  group('past_life_pool.json — 구조', () {
    test('parse OK + 필수 키 존재', () {
      expect(pool['eras'], isA<List>());
      expect(pool['relations'], isA<List>());
      expect(pool['endings'], isA<List>());
      expect(pool['templates'], isA<Map>());
      expect(pool['body_lines'], isA<Map>());
    });

    test('시대 ≥ 12', () {
      expect((pool['eras'] as List).length, greaterThanOrEqualTo(12));
    });

    test('관계 ≥ 24', () {
      expect((pool['relations'] as List).length, greaterThanOrEqualTo(24));
    });

    test('결말 ≥ 12', () {
      expect((pool['endings'] as List).length, greaterThanOrEqualTo(12));
    });

    test('8 keyword 각각 templates intros/tails ≥ 3, body_lines ≥ 3', () {
      const keys = [
        'wonjin',
        'dohwa',
        'yeokma',
        'cheoneul',
        'gongmang',
        'hap',
        'chung',
        'hyeong',
      ];
      final templates = pool['templates'] as Map<String, dynamic>;
      final bodies = pool['body_lines'] as Map<String, dynamic>;
      for (final k in keys) {
        final tpl = templates[k] as Map<String, dynamic>?;
        expect(tpl, isNotNull, reason: 'missing template: $k');
        expect((tpl!['intros'] as List).length, greaterThanOrEqualTo(3),
            reason: 'intros < 3 for $k');
        expect((tpl['tails'] as List).length, greaterThanOrEqualTo(3),
            reason: 'tails < 3 for $k');
        expect((bodies[k] as List).length, greaterThanOrEqualTo(3),
            reason: 'body_lines < 3 for $k');
      }
    });
  });

  // ───────────────── 2. 원진살 양방향 6쌍 ─────────────────

  group('PastLifeService.hasWonjin — 6쌍 양방향', () {
    const pairs = [
      ['子', '未'],
      ['丑', '午'],
      ['寅', '酉'],
      ['卯', '申'],
      ['辰', '亥'],
      ['巳', '戌'],
    ];

    for (final p in pairs) {
      test('${p[0]}-${p[1]} 양방향 true', () {
        expect(PastLifeService.hasWonjin(p[0], p[1]), isTrue);
        expect(PastLifeService.hasWonjin(p[1], p[0]), isTrue);
      });
    }

    test('원진 아닌 쌍 false (子-午 충 / 子-丑 합 / 子-子 자기 자신)', () {
      expect(PastLifeService.hasWonjin('子', '午'), isFalse);
      expect(PastLifeService.hasWonjin('子', '丑'), isFalse);
      expect(PastLifeService.hasWonjin('子', '子'), isFalse);
    });

    test('빈 문자열 false', () {
      expect(PastLifeService.hasWonjin('', '未'), isFalse);
      expect(PastLifeService.hasWonjin('子', ''), isFalse);
    });
  });

  // ───────────────── 3. extractKeywords ─────────────────

  group('PastLifeService.extractKeywords', () {
    test('원진살 (사용자 子일지 + 셀럽 未일지) → wonjin', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '己', dJi: '未');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.wonjin));
    });

    test('지지합 (子-丑) → hap', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '辛', dJi: '丑');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.hap));
    });

    test('지지충 (子-午) → chung', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '辛', dJi: '午');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.chung));
    });

    test('천간합 (甲-己) → hap', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '甲', dJi: '寅');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '己', dJi: '丑');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.hap));
    });

    test('도화 (사용자 子일지의 도화 = 酉, 셀럽 일지 酉) → dohwa', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      // 셀럽 일지 = 酉 (사용자 도화). 단 子-酉 = 파(破)지만 충/합/원진 아님
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '丑',
          dGan: '辛', dJi: '酉');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.dohwa));
    });

    test('역마 (사용자 子일지의 역마 = 寅, 셀럽 일지 寅) → yeokma', () {
      final u = makeSaju(
          yGan: '甲', yJi: '辰',
          mGan: '丙', mJi: '午',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '甲', dJi: '寅');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.yeokma));
    });

    test('천을귀인 (甲 일간 → 丑/未, 셀럽 일지 丑) → cheoneul', () {
      final u = makeSaju(
          yGan: '癸', yJi: '亥',
          mGan: '丙', mJi: '辰',
          dGan: '甲', dJi: '寅');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '辛', dJi: '丑');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.cheoneul));
    });

    test('공망 (甲子 일주 → 戌/亥 공망, 셀럽 일지 戌) → gongmang', () {
      // 甲子 일주
      final u = makeSaju(
          yGan: '甲', yJi: '辰',
          mGan: '丙', mJi: '寅',
          dGan: '甲', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '戊', dJi: '戌');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.gongmang));
    });

    test('매칭 0 → fallback hap', () {
      // 寅(인) 일지 + 丑(축) 일지 — 합/충/원진/도화/역마/공망 모두 미해당.
      // 寅 도화 = 卯, 역마 = 申. 丑 도화 = 午, 역마 = 亥.
      // 甲 일간 천을 = 丑/未 (셀럽 丑 → cheoneul 매칭!) → 회피.
      // 丙 일간 (천을 = 亥/酉) 사용. 丙寅 일주 → 공망 戌/亥. 丑 ≠ 戌/亥 → 공망 X.
      // 자형(自刑) 회피: 사용자/셀럽 본인 4기둥에 辰/午/酉/亥 중복 0.
      // 寅巳申 三刑 회피: 사용자 pillars 에 寅·巳·申 동시 등장 0 (사용자 寅 only).
      // 셀럽 pillars 에 寅(=hour borrow) + 자기 巳·申 동시 등장 0.
      // 사용자 천간: 丙(丙-辛 합 가능) 셀럽 천간 乙 (丙-乙 합 X).
      final u = makeSaju(
          yGan: '癸', yJi: '亥', // 亥 — 사용자 본인 1회만, 자형 회피
          mGan: '乙', mJi: '卯',
          dGan: '丙', dJi: '寅'); // 丙寅 일주, 공망 戌/亥 (셀럽 일지와 무관)
      final c = makeSaju(
          yGan: '丙', yJi: '寅', // 寅 — 셀럽 본인 1회
          mGan: '辛', mJi: '卯',
          dGan: '乙', dJi: '丑'); // 乙丑 일주, 공망 申/酉
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, isNotEmpty);
      expect(kws, contains(PastLifeKeyword.hap),
          reason: 'fallback should be hap. got=$kws');
    });
  });

  // ───────────────── 4. generateScenario — 8 keyword × 3 sample = 24 case ─────────────────

  group('PastLifeService.generateScenario — 24 case 한국어 leak 가드', () {
    // KO 본문에 절대 안 나와야 하는 영어 단어 / 그룹명 영문 head.
    // 5행 영문(Water/Wood/Fire/Earth/Metal) + 12지 동물 영문 + anchor / signature.
    final forbidden = <String>[
      // 5행 영문 (Pillar.pairEnglish 의 head)
      'Water ', 'Wood ', 'Fire ', 'Earth ', 'Metal ',
      // 12지 영문 동물 ( Pillar.jiJiEnglish )
      'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake',
      'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
      // anchor leak (R101 sprint 2 가드 대상)
      'anchor', 'Anchor',
      // signature leak
      'signature',
      // K-POP 그룹명 영문 (R101 sprint 1 baseline §2.2)
      'LE SSERAFIM', 'BLACKPINK', 'SEVENTEEN', 'BTS', 'TWICE',
      'aespa', 'IVE', 'ITZY', 'STAYC', 'ATEEZ',
    ];

    // 24 케이스 = 8 keyword × 3 (다른 seed).
    // 각 케이스를 만들기 위해 keyword 별 user/celeb saju 1개 + seed 3개 회전.
    final cases = <(String, PastLifeKeyword, SajuResult Function(),
        SajuResult Function())>[
      // wonjin: 子-未
      ('wonjin#1', PastLifeKeyword.wonjin,
          () => makeSaju(
              yGan: '甲', yJi: '寅',
              mGan: '丙', mJi: '辰',
              dGan: '戊', dJi: '子'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '己', dJi: '未')),
      // dohwa: 卯 일지의 도화 = 子. 사용자 卯 + 셀럽 子.
      ('dohwa#1', PastLifeKeyword.dohwa,
          () => makeSaju(
              yGan: '癸', yJi: '亥',
              mGan: '乙', mJi: '丑',
              dGan: '甲', dJi: '卯'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '丙', dJi: '子')),
      // yeokma: 子 일지의 역마 = 寅. 사용자 子 + 셀럽 寅.
      ('yeokma#1', PastLifeKeyword.yeokma,
          () => makeSaju(
              yGan: '甲', yJi: '辰',
              mGan: '丙', mJi: '午',
              dGan: '戊', dJi: '子'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '甲', dJi: '寅')),
      // cheoneul: 甲 일간 천을 = 丑/未. 사용자 甲 + 셀럽 丑.
      ('cheoneul#1', PastLifeKeyword.cheoneul,
          () => makeSaju(
              yGan: '癸', yJi: '亥',
              mGan: '丙', mJi: '辰',
              dGan: '甲', dJi: '寅'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '辛', dJi: '丑')),
      // gongmang: 甲子 일주 → 戌/亥. 셀럽 戌.
      ('gongmang#1', PastLifeKeyword.gongmang,
          () => makeSaju(
              yGan: '甲', yJi: '辰',
              mGan: '丙', mJi: '寅',
              dGan: '甲', dJi: '子'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '戊', dJi: '戌')),
      // hap: 子-丑 지지합.
      ('hap#1', PastLifeKeyword.hap,
          () => makeSaju(
              yGan: '甲', yJi: '寅',
              mGan: '丙', mJi: '辰',
              dGan: '戊', dJi: '子'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '辛', dJi: '丑')),
      // chung: 子-午 지지충.
      ('chung#1', PastLifeKeyword.chung,
          () => makeSaju(
              yGan: '甲', yJi: '寅',
              mGan: '丙', mJi: '辰',
              dGan: '戊', dJi: '子'),
          () => makeSaju(
              yGan: '乙', yJi: '巳',
              mGan: '丁', mJi: '酉',
              dGan: '辛', dJi: '午')),
      // hyeong: 寅巳申 三刑 — 사용자 寅·巳 + 셀럽 申 (申은 셀럽 일지) → hour 슬롯 borrow.
      // 사용자 yearJi 寅 + monthJi 巳 + dayJi 子, 셀럽 dayJi 申.
      ('hyeong#1', PastLifeKeyword.hyeong,
          () => makeSaju(
              yGan: '甲', yJi: '寅',
              mGan: '丁', mJi: '巳',
              dGan: '戊', dJi: '子'),
          () => makeSaju(
              yGan: '乙', yJi: '丑',
              mGan: '丁', mJi: '酉',
              dGan: '庚', dJi: '申')),
    ];

    final seeds = <int>[1, 2, 3];
    final celebNames = <String>['솔라', '아이유', '뷔'];

    for (final c in cases) {
      final (label, expectedKw, mkU, mkC) = c;
      for (var i = 0; i < seeds.length; i++) {
        final seed = seeds[i];
        final celebName = celebNames[i];
        test('$label seed=$seed celeb=$celebName — 한국어 leak 0 + keyword 포함',
            () {
          final u = mkU();
          final c2 = mkC();
          final kws = PastLifeService.extractKeywords(u, c2);
          expect(kws, contains(expectedKw),
              reason: '$label expected $expectedKw, got=$kws');
          final scenario = PastLifeService.generateScenario(
            user: u,
            celeb: c2,
            celebName: celebName,
            userName: '너',
            seed: seed,
          );
          expect(scenario.length, greaterThanOrEqualTo(80),
              reason: 'scenario too short: $scenario');
          // 사용자 이름 / 셀럽 이름 inject 검증.
          expect(scenario.contains(celebName), isTrue,
              reason: 'celebName not injected: $scenario');
          expect(scenario.contains('너'), isTrue,
              reason: 'userName not injected: $scenario');
          // 영어 leak 0.
          for (final f in forbidden) {
            expect(scenario.contains(f), isFalse,
                reason: 'forbidden "$f" in $label seed=$seed: $scenario');
          }
          // placeholder 잔존 0.
          expect(scenario.contains(r'$celebName'), isFalse);
          expect(scenario.contains(r'$userName'), isFalse);
          expect(scenario.contains(r'$userRole'), isFalse);
          expect(scenario.contains(r'$celebRole'), isFalse);
        });
      }
    }
  });

  // ───────────────── 5. seed determinism ─────────────────

  group('PastLifeService — seed determinism', () {
    test('같은 seed → 같은 시나리오', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '己', dJi: '未');
      final a = PastLifeService.generateScenario(
        user: u,
        celeb: c,
        celebName: '솔라',
        userName: '너',
        seed: 42,
      );
      final b = PastLifeService.generateScenario(
        user: u,
        celeb: c,
        celebName: '솔라',
        userName: '너',
        seed: 42,
      );
      expect(a, equals(b));
    });

    test('다른 seed → 다른 시나리오 (대부분 케이스)', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '己', dJi: '未');
      // 10개 seed 중 적어도 5개는 seed=0 결과와 달라야 한다 — variance 가드.
      final base = PastLifeService.generateScenario(
        user: u,
        celeb: c,
        celebName: '솔라',
        userName: '너',
        seed: 0,
      );
      var diff = 0;
      for (var s = 1; s <= 10; s++) {
        final other = PastLifeService.generateScenario(
          user: u,
          celeb: c,
          celebName: '솔라',
          userName: '너',
          seed: s,
        );
        if (other != base) diff++;
      }
      expect(diff, greaterThanOrEqualTo(5),
          reason: 'seed variance too low: $diff/10 differ from seed=0');
    });

    test('seed 미명시 → 같은 사주짝이면 deterministic (재호출 결과 같음)', () {
      final u = makeSaju(
          yGan: '甲', yJi: '寅',
          mGan: '丙', mJi: '辰',
          dGan: '戊', dJi: '子');
      final c = makeSaju(
          yGan: '乙', yJi: '巳',
          mGan: '丁', mJi: '酉',
          dGan: '己', dJi: '未');
      final a = PastLifeService.generateScenario(
          user: u, celeb: c, celebName: '솔라', userName: '너');
      final b = PastLifeService.generateScenario(
          user: u, celeb: c, celebName: '솔라', userName: '너');
      expect(a, equals(b));
    });
  });
}
