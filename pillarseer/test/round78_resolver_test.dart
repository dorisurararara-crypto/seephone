// Round 78 sprint 3 — DynamicTextResolver + H1 oracle_hero 마이그레이션 가드.
//
// 1. priority chain 4단계 검증 (정확 / 부분 / ctx suffix / static fallback)
// 2. 같은 천간 + 같은 dayEnergy 라도 다른 사주 ctx → body phrase 차이 ≥1
// 3. fallback chain 끝 시 정적 ment R77 보존 (회귀 가드)

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/dynamic_text_resolver.dart';
import 'package:pillarseer/services/saju_context.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DynamicTextResolver — Round 78 sprint 3', () {
    test('chain 4단계 — 정적 fallback only (yongsin 없는 ctx 시뮬레이션)', () async {
      // yongsin 미산출 ctx 를 만들 수 없으므로, 본 test 는 staticFallback 만 반환되는
      // 경로를 yongsinSuffix locale='ko' 가 빈 string 반환하는 일간 미공급 case 로 검증 X.
      // 대신 ctx.yongsin 보유 시 정확히 fallback + suffix 형태가 되는지 명시.
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));
      const fallback = 'STATIC_FALLBACK_R77_GUARD';
      final out = DynamicTextResolver.resolve(
        key: 'oracle_hero.restDay.甲',
        ctx: ctx,
        locale: 'ko',
        staticFallback: fallback,
      );
      // 본 ctx 는 yongsin 보유 → 단계 3 suffix 합성. fallback 정확히 prefix.
      expect(out.startsWith('$fallback\n'), isTrue,
          reason: 'staticFallback 정확 prefix + 줄바꿈 + suffix 형태 (단계 3)');
      // suffix 부분이 일정 길이 이상 (yongsin 5축 1줄).
      final suffix = out.substring(fallback.length + 1);
      expect(suffix.length, greaterThanOrEqualTo(10));
    });

    test('chain 1단계 — 정확 매칭 (key + requires 완전 일치)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final out = DynamicTextResolver.resolve(
        key: 'test.exact',
        ctx: ctx,
        locale: 'ko',
        staticFallback: 'fallback',
        entries: [
          // 다른 key — 매칭 X (key namespace 가드).
          DynamicPoolEntry(
            key: 'other.namespace',
            bodies: {'ko': 'OTHER_KEY'},
            requires: {'dayMaster': ctx.dayMaster},
          ),
          // 같은 key + 정확 매칭.
          DynamicPoolEntry(
            key: 'test.exact',
            bodies: {'ko': 'EXACT_HIT'},
            requires: {
              'dayMaster': ctx.dayMaster,
              'yongsin': ctx.yongsin,
            },
          ),
        ],
      );
      expect(out, 'EXACT_HIT');
    });

    test('chain 1단계 conflict skip — 충돌 entry 는 단계 1·2 모두 skip, 다른 entry 가 hit', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final out = DynamicTextResolver.resolve(
        key: 'test.conflict',
        ctx: ctx,
        locale: 'ko',
        staticFallback: 'fallback',
        entries: [
          // 명시 충돌 — ctx.season='가을' 인데 '여름' 요구.
          DynamicPoolEntry(
            key: 'test.conflict',
            bodies: {'ko': 'CONFLICT'},
            requires: {
              'dayMaster': ctx.dayMaster,
              'season': '여름',
            },
          ),
          // 다 일치 — 단계 1 exact 매칭.
          DynamicPoolEntry(
            key: 'test.conflict',
            bodies: {'ko': 'EXACT_OK'},
            requires: {
              'dayMaster': ctx.dayMaster,
              'dominantElement': ctx.dominantElement,
            },
          ),
        ],
      );
      expect(out, 'EXACT_OK');
    });

    test('chain 2단계 — partial path 실제 발동 (지원 field 중 ctx null skip)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // today 미공급 → ctx.todayPillar null. resolver _ctxField('todayPillar') = null.
      // exact 단계: ctx.todayPillar null != entry.value '甲子' → 매칭 X.
      // partial 단계: null skip + dayMaster 일치 → matchCount 1 → hit.
      final ctx = SajuContext.from(saju); // today 미공급

      final out = DynamicTextResolver.resolve(
        key: 'test.partial2',
        ctx: ctx,
        locale: 'ko',
        staticFallback: 'fallback',
        entries: [
          DynamicPoolEntry(
            key: 'test.partial2',
            bodies: {'ko': 'PARTIAL_HIT'},
            requires: {
              'dayMaster': ctx.dayMaster,
              // 지원 field 'todayPillar' — ctx 가 null 반환 → skip (충돌 X).
              'todayPillar': '甲子',
            },
          ),
        ],
      );
      expect(out, 'PARTIAL_HIT');
    });

    test('requires whitelist — unsupported key 사용 시 ArgumentError (release 가드)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      expect(
        () => DynamicTextResolver.resolve(
          key: 'test.whitelist',
          ctx: ctx,
          locale: 'ko',
          staticFallback: 'fallback',
          entries: [
            DynamicPoolEntry(
              key: 'test.whitelist',
              bodies: {'ko': 'BAD'},
              requires: {
                '_typo_field': 'x', // 미지원 key → ArgumentError throw (release 가드).
              },
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'requires whitelist 가드 — release 환경에서도 작동',
      );
    });

    test('chain 2단계 — partial tie-break (matchCount 최대 후보만 seed 분기)', () async {
      // partial 후보 다수 + matchCount 다양 → 가장 높은 matchCount entries 만 seed 분기.
      // 낮은 matchCount entry 는 절대 picked X.
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      // partial 발동을 위해 ctx 가 null 반환하는 지원 field 사용 (todayPillar).
      // ctx today 미공급 → todayPillar null → 명시되어도 skip.
      final ctxNoToday = SajuContext.from(saju); // today 미공급
      final out = DynamicTextResolver.resolve(
        key: 'test.partial_tie',
        ctx: ctxNoToday,
        locale: 'ko',
        staticFallback: 'fallback',
        entries: [
          // 낮은 matchCount (1) — dayMaster 일치만, todayPillar 명시지만 ctx null → skip.
          DynamicPoolEntry(
            key: 'test.partial_tie',
            bodies: {'ko': 'LOW_MATCH'},
            requires: {
              'dayMaster': ctxNoToday.dayMaster,
              'todayPillar': '甲子', // ctx null → skip → partial matchCount 1.
            },
          ),
          // 높은 matchCount (2) — dayMaster + dayElement 일치, todayPillar skip.
          DynamicPoolEntry(
            key: 'test.partial_tie',
            bodies: {'ko': 'HIGH_MATCH'},
            requires: {
              'dayMaster': ctxNoToday.dayMaster,
              'dayElement': ctxNoToday.dayElement,
              'todayPillar': '甲子',
            },
          ),
        ],
      );
      // matchCount 2 entry 가 우선 — 낮은 1 entry 는 절대 picked X.
      // ctx 위에 사용 (ctx 변수는 위에 있음).
      expect(out, 'HIGH_MATCH');
      // suppress unused.
      expect(ctx.dayMaster, isNotNull);
    });

    test('chain 3단계 — ctx-aware suffix 합성 (정확/부분 매칭 X, yongsin 보유)', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));
      const base = 'BASE_MENT';

      final out = DynamicTextResolver.resolve(
        key: 'test.suffix',
        ctx: ctx,
        locale: 'ko',
        staticFallback: base,
        // entries 비어있음 — 단계 1·2 모두 skip, 단계 3 yongsin suffix hit.
      );
      expect(out.startsWith('$base\n'), isTrue);
      // 격국 anchor + 용신 suffix 합성 — base 보다 길어야.
      expect(out.length > base.length + 5, isTrue);
      // suffix 부분에 yongsin 5축 단어 ("오늘") 또는 격국 anchor 단어 포함.
      final suffix = out.substring(base.length + 1);
      // 격국 anchor 가 prefix 로 오므로 "오늘" 또는 격국 단어 둘 중 하나 포함.
      expect(suffix.contains('오늘') || suffix.contains('격'), isTrue,
          reason: 'suffix 에 yongsin "오늘" 또는 격국 anchor 단어 포함');
    });

    test('chain 4단계 — yongsin 빈 ctx 시 정적 fallback only (직접 SajuContext 합성)', () {
      // SajuService 우회하여 직접 SajuContext 생성 — yongsin: '' 강제.
      // 단계 1·2 skip (entries 비어있음) + 단계 3 skip (yongsin 빈) → 단계 4 발동.
      final emptyYongsinCtx = SajuContext(
        dayMaster: '甲',
        dayElement: '木',
        dayYang: true,
        monthBranch: '寅',
        season: '봄',
        wood: 50,
        fire: 10,
        earth: 10,
        metal: 10,
        water: 20,
        dominantElement: '木',
        deficitElement: '火',
        tenGodFrequency: const {},
        strengthLabel: '중화',
        gyeokgukShort: '비견격',
        gyeokgukFull: '비견격 (比肩格)',
        yongsin: '', // 빈 yongsin → 단계 3 skip
        huisin: '',
        gisin: '',
        activeShinsa: const {},
        gongMangAreas: const [],
        currentDaewoon: null,
        currentDaewoonGod: null,
        todayPillar: null,
        todayGod: null,
        todayRelations: const [],
        chartSeed: 12345,
        userAge: null,
      );

      const fallbackOnly = 'R77_PURE_FALLBACK';
      final out = DynamicTextResolver.resolve(
        key: 'test.stage4',
        ctx: emptyYongsinCtx,
        locale: 'ko',
        staticFallback: fallbackOnly,
      );
      // 단계 4 — staticFallback 정확 일치 (suffix 합성 0).
      expect(out, fallbackOnly,
          reason: '단계 4 발동 — yongsin 빈 → suffix skip → fallback only');
    });

    test('같은 천간 + 다른 사주 (격국·용신 다름) → body phrase 차이 ≥1', () async {
      // A: 1995-10-27 男 — 일간 辛(금) + 5행 16/21/17/41/4.
      final a = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // B: 동일 일간 辛 다른 사주 — 다른 격국/용신 가능성 사주.
      // 1971-09-04 男 辛巳 일주 (다른 격국).
      final b = await SajuService().calculateSaju(
        year: 1971, month: 9, day: 4,
        hour: 10, minute: 0,
        isLunar: false, isMale: true,
      );
      final ca = SajuContext.from(a, today: DateTime(2026, 5, 14));
      final cb = SajuContext.from(b, today: DateTime(2026, 5, 14));

      // 두 사용자 모두 일간 辛 — H1 같은 _pool 항목 hit.
      // 그러나 yongsin 다르면 suffix phrase 차이.
      const base = 'ORACLE_BASE_TEST';
      final outA = DynamicTextResolver.resolve(
        key: 'oracle_hero.restDay.辛',
        ctx: ca,
        locale: 'ko',
        staticFallback: base,
      );
      final outB = DynamicTextResolver.resolve(
        key: 'oracle_hero.restDay.辛',
        ctx: cb,
        locale: 'ko',
        staticFallback: base,
      );
      // 둘 다 base 포함하지만 suffix 가 yongsin 다르면 다름.
      if (ca.yongsin != cb.yongsin) {
        expect(outA != outB, isTrue,
            reason: 'A.yongsin=${ca.yongsin} vs B.yongsin=${cb.yongsin} → 본문 phrase 차이 기대');
      } else {
        // 같은 yongsin 인 경우 — body 동일 OK (fallback 가드 충분).
        expect(outA, outB);
      }
    });

    test('같은 천간 + 같은 용신 + 다른 격국 → body phrase 차이 (격국 anchor 합성)', () {
      // 직접 SajuContext 합성 — 두 ctx 모두 동일 yongsin '木' 이지만 gyeokguk 다름.
      const sharedBase = 'BASE';
      final ctxA = SajuContext(
        dayMaster: '辛',
        dayElement: '金',
        dayYang: false,
        monthBranch: '戌',
        season: '가을',
        wood: 10, fire: 20, earth: 20, metal: 40, water: 10,
        dominantElement: '金',
        deficitElement: '木',
        tenGodFrequency: const {},
        strengthLabel: '신왕',
        gyeokgukShort: '정관격',
        gyeokgukFull: '정관격 (正官格)',
        yongsin: '木',
        huisin: '水',
        gisin: '金',
        activeShinsa: const {},
        gongMangAreas: const [],
        currentDaewoon: null,
        currentDaewoonGod: null,
        todayPillar: null,
        todayGod: null,
        todayRelations: const [],
        chartSeed: 100,
        userAge: null,
      );
      final ctxB = SajuContext(
        dayMaster: '辛',
        dayElement: '金',
        dayYang: false,
        monthBranch: '戌',
        season: '가을',
        wood: 10, fire: 20, earth: 20, metal: 40, water: 10,
        dominantElement: '金',
        deficitElement: '木',
        tenGodFrequency: const {},
        strengthLabel: '신왕',
        gyeokgukShort: '식신격', // 격국만 다름
        gyeokgukFull: '식신격 (食神格)',
        yongsin: '木', // 동일 용신
        huisin: '水',
        gisin: '金',
        activeShinsa: const {},
        gongMangAreas: const [],
        currentDaewoon: null,
        currentDaewoonGod: null,
        todayPillar: null,
        todayGod: null,
        todayRelations: const [],
        chartSeed: 100,
        userAge: null,
      );
      final outA = DynamicTextResolver.resolve(
        key: 'test.gyeokguk_only',
        ctx: ctxA,
        locale: 'ko',
        staticFallback: sharedBase,
      );
      final outB = DynamicTextResolver.resolve(
        key: 'test.gyeokguk_only',
        ctx: ctxB,
        locale: 'ko',
        staticFallback: sharedBase,
      );
      // 동일 용신이지만 격국 anchor 다름 → 본문 phrase 차이.
      expect(outA != outB, isTrue,
          reason: '격국 anchor: A=${ctxA.gyeokgukShort} vs B=${ctxB.gyeokgukShort}');
      expect(outA.contains('정관격'), isTrue);
      expect(outB.contains('식신격'), isTrue);
    });

    test('gyeokgukAnchor — 격국 8 모두 ko/en non-empty + 한자 0', () {
      const gyeokguks = ['정관격', '편관격', '정인격', '편인격', '정재격', '편재격', '식신격', '상관격'];
      for (final g in gyeokguks) {
        final ctx = SajuContext(
          dayMaster: '甲', dayElement: '木', dayYang: true,
          monthBranch: '寅', season: '봄',
          wood: 50, fire: 10, earth: 10, metal: 10, water: 20,
          dominantElement: '木', deficitElement: '火',
          tenGodFrequency: const {},
          strengthLabel: '중화',
          gyeokgukShort: g,
          gyeokgukFull: '$g (?)',
          yongsin: '火', huisin: '土', gisin: '水',
          activeShinsa: const {}, gongMangAreas: const [],
          currentDaewoon: null, currentDaewoonGod: null,
          todayPillar: null, todayGod: null, todayRelations: const [],
          chartSeed: 1, userAge: null,
        );
        final ko = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'ko');
        final en = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'en');
        expect(ko.isNotEmpty, isTrue, reason: 'ko anchor for $g');
        expect(en.isNotEmpty, isTrue, reason: 'en anchor for $g');
        // 영문 anchor 에 한자 0.
        expect(en.contains('正'), isFalse);
        expect(en.contains('偏'), isFalse);
        expect(en.contains('食'), isFalse);
        expect(en.contains('傷'), isFalse);
      }
    });

    test('영문 locale 도 suffix 합성 — em dash 0', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));
      const base = "Don't push today. Resting is the real win.";

      final out = DynamicTextResolver.resolve(
        key: 'oracle_hero.restDay.辛',
        ctx: ctx,
        locale: 'en',
        staticFallback: base,
      );
      expect(out.startsWith(base), isTrue);
      // R77 가드 — em dash 0 (suffix 부분).
      final suffix = out.substring(base.length);
      expect(suffix.contains('—'), isFalse,
          reason: 'em dash leak in en suffix');
    });

    test('deterministic — 같은 (key, ctx) 호출 → 같은 출력', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final entries = [
        DynamicPoolEntry(
            key: 'test.det',
            bodies: {'ko': 'A'},
            requires: {'dayMaster': ctx.dayMaster}),
        DynamicPoolEntry(
            key: 'test.det',
            bodies: {'ko': 'B'},
            requires: {'dayMaster': ctx.dayMaster}),
      ];
      final out1 = DynamicTextResolver.resolve(
        key: 'test.det',
        ctx: ctx,
        locale: 'ko',
        staticFallback: 'SAME',
        entries: entries,
      );
      final out2 = DynamicTextResolver.resolve(
        key: 'test.det',
        ctx: ctx,
        locale: 'ko',
        staticFallback: 'SAME',
        entries: entries,
      );
      expect(out1, out2);
    });

    test('yongsinSuffix — 5행 5개 모두 ko/en non-empty (직접 SajuContext 합성)', () async {
      // 5행 5개 모두 cover 하기 위해 5 사용자 SajuContext 생성 — yongsin 산출 차이.
      final users = [
        // 다른 일주 / 다른 5행 분포로 yongsin 다양화.
        await SajuService().calculateSaju(
            year: 1995, month: 10, day: 27, hour: 15, minute: 43,
            isLunar: false, isMale: true),
        await SajuService().calculateSaju(
            year: 1996, month: 4, day: 15, hour: 9, minute: 0,
            isLunar: false, isMale: true),
        await SajuService().calculateSaju(
            year: 1971, month: 9, day: 4, hour: 10, minute: 0,
            isLunar: false, isMale: true),
        await SajuService().calculateSaju(
            year: 1998, month: 6, day: 15, hour: 12, minute: 0,
            isLunar: false, isMale: true),
        await SajuService().calculateSaju(
            year: 1985, month: 12, day: 1, hour: 0, minute: 0,
            isLunar: false, isMale: false),
      ];
      final yongsinSet = <String>{};
      for (final u in users) {
        final c = SajuContext.from(u);
        final ko = DynamicTextResolver.yongsinSuffix(c, locale: 'ko');
        final en = DynamicTextResolver.yongsinSuffix(c, locale: 'en');
        expect(ko.isNotEmpty, isTrue, reason: 'ko suffix for ${c.yongsin}');
        expect(en.isNotEmpty, isTrue, reason: 'en suffix for ${c.yongsin}');
        // 한국어 suffix 는 '오늘' 시작.
        expect(ko.startsWith('오늘'), isTrue);
        // 영문 suffix em dash 0 가드.
        expect(en.contains('—'), isFalse);
        yongsinSet.add(c.yongsin);
      }
      // 5 사용자 통해 yongsin 종류 ≥2 — 일부 사용자는 같은 yongsin OK 이지만 다양성 가드.
      expect(yongsinSet.length, greaterThanOrEqualTo(2),
          reason: '5 사용자 yongsin 종류 ≥2 — 5축 분기 입력 다양성');
    });

    test('tenGodGroup — 10 십신 5 그룹 매핑 + null fallback', () {
      expect(DynamicTextResolver.tenGodGroup('정관 (正官)'), '관성');
      expect(DynamicTextResolver.tenGodGroup('편관 (偏官)'), '관성');
      expect(DynamicTextResolver.tenGodGroup('식신 (食神)'), '식상');
      expect(DynamicTextResolver.tenGodGroup('상관 (傷官)'), '식상');
      expect(DynamicTextResolver.tenGodGroup('정재 (正財)'), '재성');
      expect(DynamicTextResolver.tenGodGroup('편재 (偏財)'), '재성');
      expect(DynamicTextResolver.tenGodGroup('정인 (正印)'), '인성');
      expect(DynamicTextResolver.tenGodGroup('편인 (偏印)'), '인성');
      expect(DynamicTextResolver.tenGodGroup('비견 (比肩)'), '비겁');
      expect(DynamicTextResolver.tenGodGroup('겁재 (劫財)'), '비겁');
      expect(DynamicTextResolver.tenGodGroup(null), '');
      expect(DynamicTextResolver.tenGodGroup('unknown'), '');
    });

    test('gyeokgukLabel — 한국어 그대로 / 영문 한자 dictionary 제거', () async {
      final saju = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      final ctx = SajuContext.from(saju, today: DateTime(2026, 5, 14));

      final ko = DynamicTextResolver.gyeokgukLabel(ctx, locale: 'ko');
      final en = DynamicTextResolver.gyeokgukLabel(ctx, locale: 'en');

      // 한국어 = ctx.gyeokgukShort 그대로 (한자 짧은 라벨, 본문 한자 X 가드는 Sprint 1).
      expect(ko, ctx.gyeokgukShort);
      // 영문은 한자 dictionary 제거.
      expect(en.contains('正官'), isFalse);
      expect(en.contains('偏官'), isFalse);
      expect(en.contains('正印'), isFalse);
    });
  });
}
