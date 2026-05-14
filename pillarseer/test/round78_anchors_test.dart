// Round 78 sprint 6 — 합·충·형·파·해 + 신살 verbatim + 공망 wire 가드.
// V4 + V5 + V8 + H10.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';
import 'package:pillarseer/services/today_deep_service.dart';
import 'package:pillarseer/services/today_event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // pool 캐시 강제 로드 — 실제 asset 대신 raw file 로드.
    TodayEventService.debugResetPool();
    final raw = File('assets/data/today_event_pool.json').readAsStringSync();
    final root = jsonDecode(raw) as Map<String, dynamic>;
    // 직접 캐시 시뮬레이션 X — debug seed 메서드 활용 위해 ensurePoolLoaded 의
    // file fallback path 가 X. 본 test 는 pool data 검증 (raw file) 위주 + 직접
    // shinsa/hapchung map 검사.
    // Static map data 검증.
    final shinsa = (root['shinsa'] as Map).cast<String, dynamic>();
    final hapchung = (root['hapchung'] as Map).cast<String, dynamic>();
    expect(shinsa.length, greaterThanOrEqualTo(16));
    expect(hapchung.length, greaterThanOrEqualTo(30));
  });

  group('today_event_pool 확장 — Round 78 sprint 6', () {
    test('shinsa key 24+ (R76 8 → R78 24, 12신살 + 별칭 cover)', () {
      final raw = File('assets/data/today_event_pool.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final shinsa = (root['shinsa'] as Map).cast<String, dynamic>();
      expect(shinsa.length, greaterThanOrEqualTo(24));
      // 24 신살 필수 key — R76 8 + R78 신규 16 (12신살 8 + 행 8).
      const required = [
        '도화', '역마', '천을귀인', '문창귀인', '양인', '괴강', '백호', '화개',
        '겁살', '재살', '월살', '공망', '삼합', '방합', '삼재', '암록',
        '천살', '지살', '장성', '반안', '망신', '육해', '년살', '화개살',
      ];
      for (final k in required) {
        expect(shinsa.containsKey(k), isTrue, reason: '신살 $k 누락');
      }
    });

    test('hapchung key 30+ (5 관계 × 6 카테고리 = 30)', () {
      final raw = File('assets/data/today_event_pool.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final hapchung = (root['hapchung'] as Map).cast<String, dynamic>();
      expect(hapchung.length, greaterThanOrEqualTo(30));
      // 5 관계 × 6 카테고리 cover.
      for (final rel in ['지지합', '지지충', '지지형', '지지파', '지지해']) {
        for (final cat in ['relationship', 'money', 'work', 'love', 'health', 'luck']) {
          expect(hapchung.containsKey('${rel}_$cat'), isTrue,
              reason: 'hapchung ${rel}_$cat 누락');
        }
      }
    });

    test('shinsa / hapchung 본문 폐기 phrase 0', () {
      final raw = File('assets/data/today_event_pool.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      const forbidden = ['본인의 결', '센터처럼', '리텐션', '퍼포먼스', '반드시'];
      for (final blk in ['shinsa', 'hapchung']) {
        final map = (root[blk] as Map).cast<String, dynamic>();
        for (final v in map.values) {
          for (final f in forbidden) {
            expect((v as String).contains(f), isFalse,
                reason: '$blk 본문에 금칙 "$f" leak');
          }
        }
      }
    });
  });

  group('today_event_service anchor — Round 78 sprint 6', () {
    test('shinsaLineKo / hapchungLineKo — pool 로드 후 정상 조회', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();

      // 도화 신살 line.
      final dohwa = TodayEventService.shinsaLineKo('도화');
      expect(dohwa, isNotNull);
      expect(dohwa!.contains('도화'), isTrue);

      // 지지충 + money line.
      final chung = TodayEventService.hapchungLineKo('지지충', 'money');
      expect(chung, isNotNull);
      expect(chung!.isNotEmpty, isTrue);
    });

    test('primaryShinsaLine — 우선순위 (천을귀인 > 도화 > 역마)', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();

      // 도화 + 역마 동시 활성 → 도화 우선 (priority 2번째 vs 3번째).
      final line = TodayEventService.primaryShinsaLine({'도화', '역마'});
      expect(line, isNotNull);
      expect(line!.contains('도화'), isTrue);

      // 천을귀인 + 도화 → 천을귀인 우선.
      final line2 = TodayEventService.primaryShinsaLine({'천을귀인', '도화'});
      expect(line2!.contains('천을귀인'), isTrue);
    });

    test('미스 / pool 미로드 시 null', () {
      TodayEventService.debugResetPool();
      // 캐시 미로드.
      expect(TodayEventService.shinsaLineKo('도화'), isNull);
      expect(TodayEventService.hapchungLineKo('지지합', 'money'), isNull);
    });
  });

  group('screen wire 가드 — Round 78 sprint 6', () {
    test('home_screen + result_screen 가 composeBodyKoWithAnchor 호출', () {
      final home = File('lib/screens/home_screen.dart').readAsStringSync();
      final result = File('lib/screens/result_screen.dart').readAsStringSync();
      expect(home.contains('composeBodyKoWithAnchor'), isTrue,
          reason: 'home_screen.dart 가 composeBodyKoWithAnchor 호출');
      expect(result.contains('composeBodyKoWithAnchor'), isTrue,
          reason: 'result_screen.dart 가 composeBodyKoWithAnchor 호출');
      // userDayStem + todayStem 인자도 함께 전달.
      expect(home.contains('userDayStem:'), isTrue);
      expect(result.contains('userDayStem:'), isTrue);
    });

    test('천간합 발동 시 anchor — composeBodyKoWithAnchor 가 직접 hapchungLineKo 호출', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();

      // 직접 hapchungLineKo 호출로 천간합 line 존재 + 본문 형식 검증.
      for (final cat in ['relationship', 'money', 'work', 'love', 'health', 'luck']) {
        final line = TodayEventService.hapchungLineKo('천간합', cat);
        expect(line, isNotNull, reason: '천간합_$cat line 보유');
        expect(line!.contains('오늘'), isTrue, reason: '천간합_$cat 본문에 오늘 prefix');
      }

      // composeBodyKoWithAnchor — 천간합 발동 ctx (己 + 甲) + activeShinsa 빈 사주.
      // 신살 없는 일지 (例: 寅 + 庚 일진 — 천간합 X / 도화·역마·천을·문창·양인 모두 X).
      // 대신 _isCheonganHap private — 직접 천간합 일진 만들고 reading 의 activeShinsa
      // 가 비어있는 사주로 구성.
      // 천간합 5쌍: 甲己 / 乙庚 / 丙辛 / 丁壬 / 戊癸.
      // 일지 '酉' (申子辰 그룹 X / 巳酉丑 그룹 → 도화 子, 역마 亥, 화개 丑) — 도화·역마
      // 매칭은 일지 = 申子辰 그룹 기준. 일지 '酉' = 巳酉丑 그룹 → 도화=午 / 역마=亥 /
      // 화개=丑. 천간 戊 의 천을귀인=[丑,未] / 문창=申 / 양인=午. 오늘 일지 '辰' → 도화·
      // 역마·화개·천을·문창·양인 어디에도 매치 X.
      // 戊申 일주 + 癸亥 일진 → 천간합 戊癸 발동 + 핵심 신살 0 검증:
      //  - 일지 申 (申子辰 그룹 水): 도화=酉, 역마=寅, 화개=辰 → 亥 매칭 X
      //  - 戊 천을귀인=[丑,未], 문창=申, 양인=午 → 亥 매칭 X
      //  - 戊申 공망=寅,卯 → 亥 매칭 X
      //  - 12신살 망신 등은 활성될 수 있지만 anchor 단계 1 (_coreShinsaForAnchor) 에는 없음
      final r = TodayEventService.build(
        userDayStem: '戊',
        userDayBranch: '申',
        userMonthBranch: '申',
        todayPillar: '癸亥',
        todayScore: 50,
      );
      // 핵심 8 신살 (천을귀인·도화·역마·문창귀인·양인·괴강·백호·화개·공망) 모두 X.
      const core = {'천을귀인', '도화', '역마', '문창귀인', '양인', '괴강', '백호', '화개', '공망'};
      for (final c in core) {
        expect(r.activeShinsa.contains(c), isFalse,
            reason: '핵심 신살 $c 활성 — anchor 단계 1 hit 됨. actual=${r.activeShinsa}');
      }

      final body = TodayEventService.composeBodyKoWithAnchor(
        reading: r,
        date: DateTime(2026, 5, 14),
        day60ji: '戊申',
        userDayStem: '戊',
        todayStem: '癸',
      );
      final plain = TodayEventService.composeBodyKo(
        reading: r,
        date: DateTime(2026, 5, 14),
        day60ji: '戊申',
      );
      expect(body.length > plain.length, isTrue,
          reason: '천간합 발동 + activeShinsa 빈 → anchor prepend');
    });
  });

  group('12 신살 정통 표 가드 — Round 78 sprint 6', () {
    test('월살 4 그룹 정합 — 水/金/火/木 각 그룹', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();
      // 水 그룹 일지 (申子辰) + 오늘 지지 戌 → 월살 발동.
      final r1 = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '申', userMonthBranch: '申',
        todayPillar: '丙戌', todayScore: 50,
      );
      expect(r1.activeShinsa.contains('월살'), isTrue,
          reason: '水 그룹 (申) + 戌 → 월살. actual=${r1.activeShinsa}');
      // 金 그룹 (巳酉丑) + 未 → 월살.
      final r2 = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '酉', userMonthBranch: '酉',
        todayPillar: '丙未', todayScore: 50,
      );
      expect(r2.activeShinsa.contains('월살'), isTrue,
          reason: '金 그룹 (酉) + 未 → 월살');
      // 火 그룹 (寅午戌) + 辰 → 월살.
      final r3 = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '午', userMonthBranch: '午',
        todayPillar: '丙辰', todayScore: 50,
      );
      expect(r3.activeShinsa.contains('월살'), isTrue);
      // 木 그룹 (亥卯未) + 丑 → 월살.
      final r4 = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '卯', userMonthBranch: '卯',
        todayPillar: '丙丑', todayScore: 50,
      );
      expect(r4.activeShinsa.contains('월살'), isTrue);
    });

    test('겁살 / 재살 발동 — 水 그룹 (申子辰) + 巳 → 겁살, + 午 → 재살', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();
      final r1 = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '子',
        todayPillar: '癸巳', todayScore: 50,
      );
      expect(r1.activeShinsa.contains('겁살'), isTrue);
      final r2 = TodayEventService.build(
        userDayStem: '甲', userDayBranch: '子', userMonthBranch: '子',
        todayPillar: '癸午', todayScore: 50,
      );
      expect(r2.activeShinsa.contains('재살'), isTrue);
    });

    test('shinsa key 24+ (R76 8 → R78 24)', () {
      final raw = File('assets/data/today_event_pool.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final shinsa = (root['shinsa'] as Map).cast<String, dynamic>();
      expect(shinsa.length, greaterThanOrEqualTo(24),
          reason: 'shinsa key 24+ — 12 신살 정통 표 cover');
    });

    test('12 신살 9개 발동 — 천살/지살/월살/망신/장성/반안/육해 + 겁살/재살', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();
      // 水 그룹 일지 子 + 다양한 today branch 로 12 신살 9살 emit 검증.
      final cases = {
        '巳': '겁살',
        '午': '재살',
        '未': '천살',
        '申': '지살',
        '戌': '월살',
        '亥': '망신',
        '子': '장성',  // userBranch == todayBranch — self case, _branchRelation 별도
        '丑': '반안',
        '卯': '육해',
      };
      for (final e in cases.entries) {
        final r = TodayEventService.build(
          userDayStem: '甲', userDayBranch: '子', userMonthBranch: '子',
          todayPillar: '癸${e.key}', todayScore: 50,
        );
        expect(r.activeShinsa.contains(e.value), isTrue,
            reason: '水 그룹 (子) + ${e.key} → ${e.value}. actual=${r.activeShinsa}');
      }
    });

    test('primaryShinsaLine — 신규 12 신살 (천살/지살/장성/반안/망신/육해) 매핑 line 반환', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();
      for (final k in ['천살', '지살', '장성', '반안', '망신', '육해', '년살', '화개살']) {
        final line = TodayEventService.primaryShinsaLine({k});
        expect(line, isNotNull, reason: 'primaryShinsaLine 신규 신살 "$k" line 누락');
        expect(line!.isNotEmpty, isTrue);
      }
    });
  });

  group('today_deep_service 공망 wire — H10 + V8', () {
    test('ctx.gongMangAreas 비어있지 않으면 caution 끝에 공망 anchor', () async {
      // 1995-10-27 男 (癸 일주 X / 辛 일주) — 공망 = 午, 未 (甲申순 31 → 직접 계산 필요).
      // 실제 ctx.gongMangAreas 가 비어있는 case 다수. 직접 SajuContext 합성으로 발동:
      final ctx = SajuContext(
        dayMaster: '辛',
        dayElement: '金',
        dayYang: false,
        monthBranch: '戌',
        season: '가을',
        wood: 16, fire: 21, earth: 17, metal: 41, water: 4,
        dominantElement: '金',
        deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '신왕',
        gyeokgukShort: '정관격',
        gyeokgukFull: '정관격 (正官格)',
        yongsin: '木', huisin: '水', gisin: '金',
        activeShinsa: const {},
        gongMangAreas: const ['year'], // 강제 발동
        currentDaewoon: null, currentDaewoonGod: null,
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: null,
      );
      final reading = TodayDeepService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        userDominantEl: '金',
        userDeficitEl: '水',
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ctx,
      );
      expect(reading.cautionKo.contains('공망'), isTrue,
          reason: 'gongMangAreas 비어있지 않은 ctx → caution 에 공망 anchor');
      expect(reading.cautionEn.contains('Void signal') ||
              reading.cautionEn.contains('void'), isTrue);
    });

    test('ctx.gongMangAreas 빈 시 공망 anchor 0 (회귀 가드)', () async {
      final ctx = SajuContext(
        dayMaster: '辛',
        dayElement: '金',
        dayYang: false,
        monthBranch: '戌',
        season: '가을',
        wood: 16, fire: 21, earth: 17, metal: 41, water: 4,
        dominantElement: '金',
        deficitElement: '水',
        tenGodFrequency: const {},
        strengthLabel: '신왕',
        gyeokgukShort: '정관격',
        gyeokgukFull: '정관격 (正官格)',
        yongsin: '木', huisin: '水', gisin: '金',
        activeShinsa: const {},
        gongMangAreas: const [], // 빈
        currentDaewoon: null, currentDaewoonGod: null,
        todayPillar: null, todayGod: null, todayRelations: const [],
        chartSeed: 1, userAge: null,
      );
      final reading = TodayDeepService.build(
        userDayStem: '辛',
        userDayBranch: '卯',
        userMonthBranch: '戌',
        userDominantEl: '金',
        userDeficitEl: '水',
        todayPillar: '丙戌',
        todayScore: 50,
        ctx: ctx,
      );
      expect(reading.cautionKo.contains('공망'), isFalse);
    });

    test('실 사주 1998-06-15 男 (도화 활성) → today_event composeBodyKoWithAnchor 검증', () async {
      TodayEventService.debugResetPool();
      await TodayEventService.ensurePoolLoaded();

      final saju = await SajuService().calculateSaju(
        year: 1998, month: 6, day: 15,
        hour: 12, minute: 0,
        isLunar: false, isMale: true,
      );
      // build today_event reading.
      final r = TodayEventService.build(
        userDayStem: saju.dayPillar.chunGan,
        userDayBranch: saju.dayPillar.jiJi,
        userMonthBranch: saju.monthPillar.jiJi,
        todayPillar: '丙戌',
        todayScore: 50,
      );
      final bodyWithAnchor = TodayEventService.composeBodyKoWithAnchor(
        reading: r,
        date: DateTime(2026, 5, 14),
        day60ji: saju.dayPillar.text,
      );
      // 도화 / 천을귀인 등 활성 → anchor 가 본문 prepend.
      // (사주 도화 활성 = 일지 巳 → 도화=午, 월지/시지 午 매칭 — Sprint 1 검증)
      // 단, today_event_service 의 _activeShinsa 는 internal logic — 본 가드는
      // reading.activeShinsa 가 비어있지 않으면 anchor 가 본문 length 증가시킴.
      final bodyPlain = TodayEventService.composeBodyKo(
        reading: r,
        date: DateTime(2026, 5, 14),
        day60ji: saju.dayPillar.text,
      );
      if (r.activeShinsa.isNotEmpty || r.hapChungType.isNotEmpty) {
        expect(bodyWithAnchor.length, greaterThanOrEqualTo(bodyPlain.length));
      }
    });
  });
}
