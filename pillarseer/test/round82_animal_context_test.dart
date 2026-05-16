// Round 82 sprint 6 회귀 가드 — 한글 동물 / 일진 / 알림 호명 단독 노출 영역에
// 사주와 관계 1줄 helper wire (#7+#8+#9 통합 fix).
//
// 사용자 verbatim (R82 인수인계.md line 14):
//   #7 "금토끼 금원숭이 이런거 나오는데 그게 뭔지 설명도 없고"
//   #8 "조승현아 오늘은 금토끼에 날이야 이건 또 갑자기 뭐하는거며 설명도 없고"
//   #9 "오늘의 일진은 토 쥐 이것만있는데 이것도 설명도 없고"
//
// ── Sprint 계약 = testable 5 행동 ──
//   행동 1 = AnimalContextService.selfPairHelperKo 가 모든 천간 10 × 지지 12 = 120
//     조합에서 비어있지 않은 1줄 helper 반환. 한자 jargon X / Apologetic AI 어조 X.
//   행동 2 = AnimalContextService.todayPillarHelperKo 가 모든 천간 10 × 60갑자 일진
//     조합에서 "= ..." prefix 로 시작하는 1줄 helper 반환. 한자 jargon X.
//   행동 3 = home_screen.dart 에서 _PillarOfTheDay / _FirstFoldGreeting 제거.
//     사용자 R85 mandate: "조승현아, 오늘은 금 토끼 분위기가 강해" / "오늘의 일진 토 소"
//     단독 카드 노출 금지.
//   행동 4 = 자미두수 별 이름 nameKo (자미성·천기성·태양성·태음성·천기성·천부성·
//     무곡성 등) 가 AnimalContextService 출력에 0 회 노출 (R70 mandate 보존).
//   행동 5 = 1995-10-27 男 17시 (5행 골든 baseline) 의 일주 辛卯 + 임의 오늘 일진
//     6 sample 에서 helper 가 자연스러운 한국어 문장으로 반환.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/animal_context_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R82 sprint 6 — 한글 동물 / 일진 / 호명 context 1줄 wire 가드', () {
    const tenGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const twelveJi = [
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
    ];
    // 한자 jargon blacklist (사용자 노출 본문 0회 — R74 / R78 baseline).
    // "결" 은 단독 어휘 ("결이 살아" 류 R74 어색 어휘) 만 잡고 "결과" / "결정" 등
    // 평이한 한국어 단어와의 충돌 X. blacklist 는 한자 일·천간 + 십신 jargon 만.
    const jargonBlacklist = [
      '본질',
      '정수',
      '운기',
      '甲',
      '乙',
      '丙',
      '丁',
      '戊',
      '己',
      '庚',
      '辛',
      '壬',
      '癸',
      '비견',
      '겁재',
      '식신',
      '상관',
      '편재',
      '정재',
      '편관',
      '정관',
      '편인',
      '정인',
    ];
    // 자미두수 별 이름 nameKo — R70 mandate (사용자 노출 0).
    const ziweiStarsKo = [
      '자미성',
      '천기성',
      '태양성',
      '무곡성',
      '천동성',
      '염정성',
      '천부성',
      '태음성',
      '탐랑성',
      '거문성',
      '천상성',
      '천량성',
      '칠살성',
      '파군성',
    ];

    test('행동 1: selfPairHelperKo 120 조합 모두 비어있지 않고 한자 jargon 0', () {
      for (final g in tenGan) {
        for (final j in twelveJi) {
          final s = AnimalContextService.selfPairHelperKo(
            dayChunGan: g,
            dayJiJi: j,
          );
          expect(s.isNotEmpty, isTrue, reason: '$g$j helper 비어있음');
          // R2 codex feedback: "= <5행 layer> + <12 동물 layer>. <suffix>." 패턴.
          expect(
            s.startsWith('= '),
            isTrue,
            reason: '$g$j helper prefix 미일치: $s',
          );
          // suffix 에 "평소 본인 분위기" 가 포함되어야 (selfPair 식별).
          expect(
            s.contains('평소 본인 분위기'),
            isTrue,
            reason: '$g$j helper 에 selfPair anchor "평소 본인 분위기" 미포함: $s',
          );
          // ≤80자 cap (UI 압축 인증, R2 codex feedback).
          expect(s.length <= 80, isTrue, reason: '$g$j helper > 80자: $s');
          for (final j2 in jargonBlacklist) {
            expect(
              s.contains(j2),
              isFalse,
              reason: '$g$j helper 에 한자 jargon "$j2" 포함: $s',
            );
          }
          for (final star in ziweiStarsKo) {
            expect(
              s.contains(star),
              isFalse,
              reason: '$g$j helper 에 자미두수 별 "$star" 노출 (R70 위반): $s',
            );
          }
        }
      }
    });

    test('행동 2: todayPillarHelperKo 600 조합 (60갑자 sixty cycle × 사용자 10 천간)', () {
      // 진짜 60갑자 sixty-cycle fixture — 천간(10) 과 지지(12) 가 각각 +1 씩 진행해서
      // lcm(10, 12) = 60 조합. cf. saju 60갑자 cycle.
      final sixtyCycle = <String>[];
      for (var i = 0; i < 60; i++) {
        sixtyCycle.add('${tenGan[i % 10]}${twelveJi[i % 12]}');
      }
      expect(sixtyCycle.length, 60);
      // 60갑자 × 사용자 10 천간 = 600 조합.
      for (final ugan in tenGan) {
        for (final todayPillar in sixtyCycle) {
          final s = AnimalContextService.todayPillarHelperKo(
            userDayChunGan: ugan,
            todayPillar: todayPillar,
          );
          expect(
            s.isNotEmpty,
            isTrue,
            reason: 'user=$ugan today=$todayPillar helper 비어있음',
          );
          expect(
            s.startsWith('= '),
            isTrue,
            reason: 'user=$ugan today=$todayPillar prefix 미일치: $s',
          );
          expect(
            s.length <= 80,
            isTrue,
            reason: 'user=$ugan today=$todayPillar helper > 80자: $s',
          );
          // R3 codex feedback: 모든 today helper 가 일진 지지 동물 suffix
          // "(오늘 <동물>)" 포함 (천간합 분기 포함). 동물 매핑 12 중 1 hit.
          final todayJi = todayPillar[1];
          final expectedAnimal = AnimalContextService.animalShort[todayJi];
          expect(expectedAnimal, isNotNull, reason: '$todayJi 동물 매핑 누락');
          expect(
            s.contains('(오늘 $expectedAnimal)'),
            isTrue,
            reason:
                'user=$ugan today=$todayPillar helper 에 "(오늘 $expectedAnimal)" suffix 누락: $s',
          );
          for (final j2 in jargonBlacklist) {
            expect(
              s.contains(j2),
              isFalse,
              reason:
                  'user=$ugan today=$todayPillar helper 에 한자 jargon "$j2": $s',
            );
          }
          for (final star in ziweiStarsKo) {
            expect(
              s.contains(star),
              isFalse,
              reason:
                  'user=$ugan today=$todayPillar helper 에 자미두수 별 "$star" 노출 (R70 위반)',
            );
          }
        }
      }
    });

    test('행동 3: home_screen.dart 에 호명/일진 단독 카드가 없다', () {
      final src = File('lib/screens/home_screen.dart').readAsStringSync();
      expect(
        src.contains('_FirstFoldGreeting'),
        isFalse,
        reason: '호명 + 일주 별명 카드가 다시 들어오면 사용자 불만 #8 재발',
      );
      expect(
        src.contains('_PillarOfTheDay'),
        isFalse,
        reason: '오늘의 일진 단독 카드가 다시 들어오면 사용자 불만 #9 재발',
      );
      expect(
        src.contains('오늘은 \$dayMasterKo 분위기가 강해'),
        isFalse,
        reason: '금 토끼/금 원숭이류 단독 headline 금지',
      );
      expect(src.contains('오늘의 60갑자'), isFalse, reason: '일진 한자/동물 단독 설명 카드 금지');
      expect(src.contains('AnimalContextService.selfPairHelperKo'), isFalse);
      expect(src.contains('AnimalContextService.todayPillarHelperKo'), isFalse);
    });

    test('행동 4: 자미두수 별 이름 nameKo (R70 mandate) 회귀 가드', () {
      // AnimalContextService 소스에 자미두수 별 이름 0 회.
      final src = File(
        'lib/services/animal_context_service.dart',
      ).readAsStringSync();
      for (final star in ziweiStarsKo) {
        expect(
          src.contains(star),
          isFalse,
          reason: 'animal_context_service.dart 에 자미두수 별 "$star" 포함 (R70 위반)',
        );
      }
    });

    test('행동 5: 5행 골든 baseline (1995-10-27 男 17시 = 일주 辛卯) helper sample', () {
      // 사용자 본인 (辛卯) → 본인 분위기 helper.
      final self = AnimalContextService.selfPairHelperKo(
        dayChunGan: '辛',
        dayJiJi: '卯',
      );
      // 辛卯 = "단단한 금 + 다정한 토끼". 5행 + 동물 layer 모두 포함.
      expect(
        self.contains('단단한 금'),
        isTrue,
        reason: '辛 (금) 5행 layer 미반영: $self',
      );
      expect(
        self.contains('다정한 토끼'),
        isTrue,
        reason: '卯 (토끼) 동물 layer 미반영: $self',
      );
      expect(
        self.contains('평소 본인 분위기'),
        isTrue,
        reason: 'selfPair anchor 미포함: $self',
      );

      // 사용자 일간 辛 + 오늘 일진 sample 6 (TenGod 5 + 천간합 1).
      // 辛 + 辛卯 = 비견 / 辛 + 庚午 = 겁재 / 辛 + 壬辰 = 식신 / 辛 + 癸亥 = 상관
      // 辛 + 甲申 = 정재 / 辛 + 丙子 = 천간합.
      final samples = <(String, String)>[
        ('辛', '辛卯'),
        ('辛', '庚午'),
        ('辛', '壬辰'),
        ('辛', '癸亥'),
        ('辛', '甲申'),
        ('辛', '丙子'),
      ];
      for (final s in samples) {
        final h = AnimalContextService.todayPillarHelperKo(
          userDayChunGan: s.$1,
          todayPillar: s.$2,
        );
        expect(
          h.startsWith('= '),
          isTrue,
          reason: '${s.$1}/${s.$2} prefix 실패: $h',
        );
        expect(
          h.length >= 8,
          isTrue,
          reason: '${s.$1}/${s.$2} helper 너무 짧음: $h',
        );
      }

      // 천간합 sample (辛 + 丙) — 강한 신호 1줄.
      final hapHelper = AnimalContextService.todayPillarHelperKo(
        userDayChunGan: '辛',
        todayPillar: '丙子',
      );
      expect(
        hapHelper.contains('마음이 맞'),
        isTrue,
        reason: '辛+丙 천간합 helper 가 "마음이 맞" anchor 미포함: $hapHelper',
      );
    });

    test('행동 6: 알림/홈 모두 호명 + 한글 동물 단독 톤 금지 (#8)', () {
      // 사용자 R85 mandate: helper 를 붙여 보강하는 대신 홈 화면 호명/일주 별명
      // 카드 자체를 제거한다. notification_pool_service.dart 의 알림 풀에도
      // 호명 reverbal ("OO야 / OO아 오늘은") phrase 가 들어가 있으면 안 된다.
      final homeSrc = File('lib/screens/home_screen.dart').readAsStringSync();
      expect(
        homeSrc.contains('오늘은 \$dayMasterKo 분위기가 강해'),
        isFalse,
        reason: '홈 화면에 호명+한글 동물 headline 재유입',
      );
      expect(
        homeSrc.contains('selfPairHelperKo'),
        isFalse,
        reason: '홈 화면 호명 helper card 재유입',
      );
      expect(
        homeSrc.contains('todayPillarHelperKo'),
        isFalse,
        reason: '홈 화면 일진 helper card 재유입',
      );

      // notification_pool_service.dart 의 50 ko + 50 mz 풀 안에 "{이름}야 오늘은" /
      // "{이름}아 오늘은" 같은 호명 phrase 가 들어가 있지 않은지 가드.
      // 호명 phrase 가 들어가야 한다면 helper context 1줄이 같이 따라가야.
      final notifSrc = File(
        'lib/services/notification_pool_service.dart',
      ).readAsStringSync();
      // 호명 + 한글 동물 단독 phrase ("야 오늘은 금토끼") 0 회 (사용자 verbatim 무서움).
      const dangerPhrases = [
        '야 오늘은 금',
        '아 오늘은 금',
        '야 오늘은 화',
        '아 오늘은 화',
        '야 오늘은 목',
        '아 오늘은 목',
        '야 오늘은 수',
        '아 오늘은 수',
        '야 오늘은 토',
        '아 오늘은 토',
      ];
      for (final p in dangerPhrases) {
        expect(
          notifSrc.contains(p),
          isFalse,
          reason:
              'notification_pool_service.dart 에 호명+한글동물 위험 phrase "$p" 발견 — 사용자 무서움 risk (R82 sprint 6 #8)',
        );
      }
    });

    test('행동 보너스: TenGod enum 10 모두 helper 매핑 (fallback 의존 X)', () {
      // user 甲 (양목) + 오늘 천간 10 → TenGod 매핑 모두 존재 (fallback 미발동).
      const fallback = '평범하게';
      for (final g in tenGan) {
        final h = AnimalContextService.todayPillarHelperKo(
          userDayChunGan: '甲',
          todayPillar: '$g子',
        );
        // 천간합 (甲己) 은 별도 anchor 라 fallback 미발동 정상.
        expect(
          h.contains(fallback),
          isFalse,
          reason: '甲 vs $g 에서 fallback "평범하게" 발동 — TenGod 매핑 누락: $h',
        );
      }
    });
  });
}
