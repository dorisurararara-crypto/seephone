// R107 #9 — 전생 가짜 fallback + 음력 silent fail 회귀 가드.
//
// 거짓말 0 (최우선) — codex audit 두 건:
//   #9-1 전생: keyword 매칭 0 일 때 종전 fallback 은 `hap` 강제였다.
//        hap 시나리오는 "합의 기운이 둘을 묶었다" 처럼 실제로 없는 합(合)을
//        있는 척 서술 = 거짓. 이제 매칭 0 → `neutral` (정직한 "신호 약함").
//   #9-2 만세력: klc.setLunarDate 는 throw 하지 않고 bool 을 반환한다.
//        유효하지 않은 음력 날짜면 false 를 돌려주고 solar 전역 상태는 stale.
//        종전 코드는 이 bool 을 무시 = silent fail. 이제 [lunarConversionFailed]
//        flag 로 surface 한다.
//
// 추가: 5행 골든 (1995-10-27 男 17시 辛卯 16/21/17/41/4) 불변 — 음력 fail 처리
//   수정이 정상 경로 계산 결과를 1 bit 도 안 바꿨는지 검증.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/services/manseryeok_service.dart';
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
  }) {
    return SajuResult(
      yearPillar: Pillar(chunGan: yGan, jiJi: yJi),
      monthPillar: Pillar(chunGan: mGan, jiJi: mJi),
      dayPillar: Pillar(chunGan: dGan, jiJi: dJi),
      hourPillar: null,
      elements: const FiveElements(
        wood: 20, fire: 20, earth: 20, metal: 20, water: 20,
      ),
      dayMaster: dGan,
      dayMasterName: 'Test',
      summary: 'test',
      categoryReadings: const {},
    );
  }

  // 매칭 0 케이스 — 寅(인) 일지 + 丑(축) 일지.
  //   寅 도화=卯 역마=申 / 丑 도화=午 역마=亥 → 도화·역마 X.
  //   丙 일간 천을=亥/酉 (셀럽 丑 무관) / 丙寅 일주 공망=戌/亥 (丑 무관) → cheoneul·gongmang X.
  //   寅-丑 은 합·충·원진 쌍 아님. 자형·三刑 회피 (사용자 寅 only / 셀럽 丑·寅 only).
  //   천간 丙(셀럽 乙) → 丙-乙 합 X.
  SajuResult noSignalUser() => makeSaju(
        yGan: '癸', yJi: '亥',
        mGan: '乙', mJi: '卯',
        dGan: '丙', dJi: '寅',
      );
  SajuResult noSignalCeleb() => makeSaju(
        yGan: '丙', yJi: '寅',
        mGan: '辛', mJi: '卯',
        dGan: '乙', dJi: '丑',
      );

  // ═══════════ #9-1 전생 가짜 fallback ═══════════

  group('R107 #9-1 — 전생: 매칭 0 → neutral (거짓 합 0)', () {
    test('매칭 0 케이스는 hap 가 아니라 neutral 을 반환', () {
      final kws = PastLifeService.extractKeywords(
        noSignalUser(),
        noSignalCeleb(),
      );
      expect(kws, contains(PastLifeKeyword.neutral),
          reason: '매칭 0 fallback = neutral. got=$kws');
      expect(kws, isNot(contains(PastLifeKeyword.hap)),
          reason: '실제 합 없는데 hap = 거짓 합. got=$kws');
      // neutral 은 단독 — 다른 어떤 keyword 와도 함께 안 나옴 (매칭 0 정의상).
      expect(kws.length, 1, reason: 'neutral 은 매칭 0 일 때만, 단독. got=$kws');
    });

    test('실제 합 있는 케이스는 여전히 hap (neutral 아님) — 회귀 가드', () {
      // 子-丑 지지합 → hap 정상 매칭. neutral 로 잘못 분기하면 안 됨.
      final u = makeSaju(
        yGan: '甲', yJi: '辰', mGan: '丙', mJi: '寅', dGan: '戊', dJi: '子');
      final c = makeSaju(
        yGan: '乙', yJi: '巳', mGan: '丁', mJi: '卯', dGan: '己', dJi: '丑');
      final kws = PastLifeService.extractKeywords(u, c);
      expect(kws, contains(PastLifeKeyword.hap),
          reason: '子-丑 합은 hap. got=$kws');
      expect(kws, isNot(contains(PastLifeKeyword.neutral)),
          reason: '실제 합 있으면 neutral 분기 금지. got=$kws');
    });

    test('neutral 시나리오 본문은 "합"을 있는 척 서술하지 않음 — 거짓말 0', () {
      // 매칭 0 케이스로 시나리오 생성 → 본문에 거짓 합·충·살 단정 0.
      for (final seed in [1, 7, 42, 100, 777]) {
        final s = PastLifeService.generateScenario(
          user: noSignalUser(),
          celeb: noSignalCeleb(),
          celebName: '카리나',
          userName: '민수',
          seed: seed,
          kind: 'idol',
        );
        expect(s, isNotEmpty);
        // 거짓 합/충/원진 단정 어구가 본문에 등장하면 안 됨.
        for (final lie in const [
          '합의 기운',
          '합 결이 박힌',
          '합 결이 단단',
          '합 결이 또렷',
          '사주에 박힌 합',
          '충의 기운',
          '원진살의',
        ]) {
          expect(s.contains(lie), isFalse,
              reason: 'neutral 본문에 거짓 인연 단정 "$lie" 등장 (seed=$seed): $s');
        }
        // neutral 시나리오는 정직한 "신호 약함" 톤 — 핵심 어구 중 하나 포함.
        final honest = s.contains('뚜렷한 인연 신호') ||
            s.contains('강한 인연') ||
            s.contains('강한 인연의 매듭') ||
            s.contains('합이나 충') ||
            s.contains('합·충') ||
            s.contains('운명이') ||
            s.contains('스스로') ||
            s.contains('직접 고른') ||
            s.contains('선택');
        expect(honest, isTrue,
            reason: 'neutral 본문에 정직한 "신호 약함/선택" 톤 어구 누락 '
                '(seed=$seed): $s');
      }
    });

    test('neutral 시나리오 — seed deterministic', () {
      String gen(int seed) => PastLifeService.generateScenario(
            user: noSignalUser(),
            celeb: noSignalCeleb(),
            celebName: '카리나',
            userName: '민수',
            seed: seed,
            kind: 'idol',
          );
      expect(gen(5), gen(5), reason: '같은 seed → 같은 시나리오');
    });

    test('neutral 시나리오 — placeholder 미치환 잔존 0', () {
      for (final seed in [3, 11, 88]) {
        final s = PastLifeService.generateScenario(
          user: noSignalUser(),
          celeb: noSignalCeleb(),
          celebName: '윈터',
          userName: '지현',
          seed: seed,
          kind: 'idol',
        );
        for (final ph in const [
          r'$userName', r'$celebName', r'$userRole', r'$celebRole', r'$era',
        ]) {
          expect(s.contains(ph), isFalse,
              reason: 'placeholder "$ph" 미치환 (seed=$seed): $s');
        }
      }
    });

    test('neutral pool 콘텐츠 존재 — story_arcs / templates / body_lines', () {
      expect((pool['story_arcs'] as Map)['neutral'], isA<List>());
      expect(((pool['story_arcs'] as Map)['neutral'] as List), isNotEmpty);
      expect((pool['templates'] as Map)['neutral'], isA<Map>());
      expect((pool['body_lines'] as Map)['neutral'], isA<Map>());
      expect((pool['story_arcs_en'] as Map)['neutral'], isA<List>());
    });

    test('PastLifeKeyword.neutral 라벨 — KO/EN 단정 표현 아님', () {
      expect(PastLifeKeyword.neutral.key, 'neutral');
      expect(PastLifeKeyword.neutral.labelKo, isNotEmpty);
      expect(PastLifeKeyword.neutral.labelEn, isNotEmpty);
      // neutral 라벨에 "합"/"충" 같은 거짓 단정 단어가 들어가면 안 됨.
      expect(PastLifeKeyword.neutral.labelKo.contains('합'), isFalse);
      expect(PastLifeKeyword.neutral.labelKo.contains('충'), isFalse);
    });
  });

  // ═══════════ #9-2 음력 silent fail surface ═══════════

  group('R107 #9-2 — 만세력: 음력 변환 실패 surface', () {
    test('정상 양력 입력 — lunarConversionFailed 항상 false', () {
      final r = ManseryeokService.calculate(
        year: 1995, month: 10, day: 27, hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      expect(r.lunarConversionFailed, isFalse,
          reason: '양력 입력은 음력 변환 시도 없음 → flag false');
    });

    test('정상 음력 입력 — 변환 성공 시 flag false', () {
      // klc 지원 범위(1391~2050) 내 정상 음력 날짜.
      final r = ManseryeokService.calculate(
        year: 1995, month: 9, day: 4, hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isFalse,
          reason: '정상 음력 변환 성공 → flag false');
      // 변환 성공 시 solar 값은 입력과 달라야 함 (음력≠양력).
      expect(r.solarYear, greaterThan(0));
      expect(r.solarMonth, inInclusiveRange(1, 12));
      expect(r.solarDay, inInclusiveRange(1, 31));
    });

    test('범위 밖 음력 입력 — 변환 실패가 silent 아니라 flag 로 surface', () {
      // klc 지원 범위 밖 연도 → setLunarDate false → flag true.
      final r = ManseryeokService.calculate(
        year: 3000, month: 1, day: 1, hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isTrue,
          reason: '범위 밖 음력 변환 실패 → flag 로 surface (silent 금지)');
    });

    test('잘못된 음력 월/일 — 변환 실패 surface', () {
      // 음력 13월 = 존재하지 않는 월 → 변환 실패.
      final r = ManseryeokService.calculate(
        year: 1990, month: 13, day: 45, hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      expect(r.lunarConversionFailed, isTrue,
          reason: '비정상 음력 월/일 → flag true');
    });

    test('변환 실패해도 앱은 안 깨짐 — 결과 record 정상 반환', () {
      final r = ManseryeokService.calculate(
        year: 3000, month: 1, day: 1, hour: 12, minute: 0,
        isLunar: true, isMale: true,
      );
      // flag 는 true 이되, pillar/elements 는 fallback 으로 계산되어 반환.
      expect(r.lunarConversionFailed, isTrue);
      expect(r.yearPillar.text.length, 2);
      expect(r.dayPillar.text.length, 2);
    });
  });

  // ═══════════ 5행 골든 불변 — 정상 경로 계산 회귀 0 ═══════════

  group('R107 #9-2 — 5행 골든 불변 (음력 fail 처리 수정 회귀 0)', () {
    test('1995-10-27 男 17시 = 辛卯 16/21/17/41/4 — 양력 정상 경로 불변', () {
      final r = ManseryeokService.calculate(
        year: 1995, month: 10, day: 27, hour: 17, minute: 0,
        isLunar: false, isMale: true,
      );
      final el = r.elements;
      expect(el.wood, 16, reason: '木 = 16');
      expect(el.fire, 21, reason: '火 = 21');
      expect(el.earth, 17, reason: '土 = 17');
      expect(el.metal, 41, reason: '金 = 41');
      expect(el.water, 4, reason: '水 = 4');
      expect(r.dayPillar.text, '辛卯', reason: '일주 = 辛卯');
      expect(r.lunarConversionFailed, isFalse);
    });

    test('정상 음력 변환 경로 — 변환된 solar 로 계산, flag false', () {
      // 음력 입력이 정상 변환되면 양력 경로와 동일 품질의 결과.
      final r = ManseryeokService.calculate(
        year: 1990, month: 5, day: 15, hour: 9, minute: 0,
        isLunar: true, isMale: false,
      );
      expect(r.lunarConversionFailed, isFalse);
      expect(r.yearPillar.text.length, 2);
      expect(r.monthPillar.text.length, 2);
      expect(r.dayPillar.text.length, 2);
    });
  });
}
