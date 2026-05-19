// R101 sprint 3 — 최애와의 궁합보기 = compatibility _analyze 본문 엔진 재사용 가드.
//
// 사용자 mandate verbatim (R101 sprint 1 baseline §1.3):
//   "그냥 최애와의 궁합보기로 메뉴명을 바꾸고 우리 궁합보는거 그대로 사용해서
//    설명나오게 해줘 그냥 우리 앱에 있는 궁합보기를 연예인이랑 하는 느낌"
//
// 본 가드는 sprint 3 의 thin-wrapper 전환을 회귀 lock:
//   A. kpop_compat_screen.dart detail 본문이 compatibility_screen._analyze() 5섹션
//      구조 (summary / attract / friction / loveMarriage / actions) 를 mount.
//      → source-level grep: `CompatDetailSection(` 호출 존재.
//   B. KO branch detail header / blurb 영역에 영문 60갑자 element+animal 페어
//      (`Water Rabbit` / `Fire Snake` …) 0.
//   C. KO branch 5섹션 합본에 "anchor" 평문 0 (compatibility sprint 2 가드와
//      독립 path — 셀럽 adapter 가 통과한 본문에서도 영문 leak 0 보장).
//   D. KO blurbKo 본문 영문 그룹명 head (LE SSERAFIM / BLACKPINK / SEVENTEEN /
//      ENHYPEN / NewJeans / aespa / ITZY / IVE / TXT / NCT / ATEEZ / RIIZE 등)
//      잔존 0 — `_localizeGroupPrefixKo` 가 한국 미디어 표기로 정규화.
//   E. reports_home_screen.dart 메뉴 라벨 "최애와의 궁합보기" 존재, 이전 "최애와
//      케미" 잔존 0.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/compatibility_screen.dart' as compat;
import 'package:pillarseer/screens/reports/kpop_compat_screen.dart' as kpop;

const List<String> _elementsEn = <String>[
  'Wood', 'Fire', 'Earth', 'Metal', 'Water',
];
const List<String> _animalsEn = <String>[
  'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake',
  'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
];

List<String> _allElementAnimalPairs() {
  final out = <String>[];
  for (final el in _elementsEn) {
    for (final an in _animalsEn) {
      out.add('$el $an');
    }
  }
  return out;
}

/// 사용자 me — 임의 4기둥 8자. _analyze 가 day60ji + dayPillar 만 사용하므로
/// year/month/hour 는 안정값.
SajuResult _mkMe(String dayPillar) {
  final gan = dayPillar[0];
  final ji = dayPillar[1];
  return SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    monthPillar: const Pillar(chunGan: '丙', jiJi: '寅'),
    dayPillar: Pillar(chunGan: gan, jiJi: ji),
    elements: const FiveElements(
      wood: 30, fire: 20, earth: 15, metal: 25, water: 10,
    ),
    dayMaster: gan,
    dayMasterName: '_',
    summary: '_',
    categoryReadings: const {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R101 sprint 3 — celeb compat thin wrapper', () {
    // ─────────────────────────────────────────────────────────────
    // A. detail 본문이 CompatDetailSection 을 mount.
    // ─────────────────────────────────────────────────────────────
    test('A. kpop_compat detail dialog 가 CompatDetailSection 을 mount', () {
      final src =
          File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();

      expect(
        src.contains('CompatDetailSection('),
        isTrue,
        reason:
            'kpop_compat_screen.dart 가 CompatDetailSection 을 mount 하지 않음. '
            '사용자 mandate "우리 궁합보는거 그대로 사용해서 설명나오게 해줘" 회귀.',
      );

      // detail dialog 본문에서 _verdict() 직접 호출이 사라졌는지 확인.
      // _composeVerdict() 자체는 dead path 로 보존 (R71/R96/R100 source 가드).
      // _verdict() 메서드 정의는 보존하되 dialog widget tree 안에서의 호출은 0.
      // 정규식: `Text(\s*_verdict(),` 패턴.
      final verdictTextRender = RegExp(r'Text\(\s*_verdict\(\),').hasMatch(src);
      expect(
        verdictTextRender,
        isFalse,
        reason:
            'detail dialog 가 여전히 Text(_verdict(), …) 로 4-paragraph verdict 본문을 mount. '
            'R101 sprint 3 thin wrapper 전환 누락 — CompatDetailSection 으로 교체했어야 함.',
      );

      // 회귀 lock: _composeVerdict source body 자체는 보존 (R71/R96/R100 가드 호환).
      expect(
        src.contains('String _composeVerdict()'),
        isTrue,
        reason:
            'dead path (_composeVerdict) 가 삭제됨. R71/R96/R100 source-level 가드와 '
            '회귀 lock 호환을 위해 보존되어야 한다.',
      );
    });

    // ─────────────────────────────────────────────────────────────
    // B. KO detail header / blurb 영역에 60갑자 영문 페어 0.
    // ─────────────────────────────────────────────────────────────
    test('B. KO detail header / blurb 영역에 60갑자 영문 일주명 (Element + Animal) 0', () {
      final src =
          File('lib/screens/reports/kpop_compat_screen.dart').readAsStringSync();
      // detail dialog body (개략): `_openDetail` 진입 ~ `_verdict` method 위까지.
      const openMarker = 'void _openDetail(';
      final openIdx = src.indexOf(openMarker);
      expect(openIdx >= 0, isTrue, reason: '_openDetail 진입점 없음');
      const closeMarker = 'String _verdict()';
      final closeIdx = src.indexOf(closeMarker, openIdx);
      expect(closeIdx > openIdx, isTrue, reason: '_verdict marker 없음');
      final body = src.substring(openIdx, closeIdx);

      // KO branch 에서 영문 dayPillarName 을 직접 inject 하는 패턴 잔존 0.
      // (`star.dayPillarName` 자체 reference 는 EN 분기에서만 허용).
      // 정확한 검사: useKo true 분기 안에서 `star.dayPillarName` 이 직접 노출되면 fail.
      // 단순 source contains 로는 EN 분기 허용을 구분 못 하므로, KO 분기 가독성 위해
      // header 라인에 KO 분기 한자 표기 ("일주") 가 추가됐는지 확인.
      expect(
        body.contains('일주'),
        isTrue,
        reason:
            'KO detail header 가 한자 일주 표기 ("계묘일주" 같은) 를 mount 하지 않음. '
            '영문 element+animal 페어가 그대로 노출될 위험 — sprint 3 라벨 누락.',
      );

      // 영문 dayPillarName 이 KO 분기에서 직접 inject 되는 위치를 한 번 더 검사:
      // `useKo ? '${star.dayPillar} · ${star.dayPillarName}'` 같은 패턴이면 fail.
      final koHeaderEnLeak = RegExp(
        r'useKo\s*\?\s*[\x27"][^\x27"]*\$\{?star\.dayPillarName\}?',
      ).hasMatch(body);
      expect(
        koHeaderEnLeak,
        isFalse,
        reason:
            'KO 분기에서 star.dayPillarName 영문이 직접 inject 됨 — '
            '한국어 음 (예: "계묘일주") 또는 한자만 노출해야 함.',
      );
    });

    // ─────────────────────────────────────────────────────────────
    // C. KO 5섹션 본문에 "anchor" 평문 0 (셀럽 adapter path).
    // ─────────────────────────────────────────────────────────────
    test('C. 셀럽 adapter path 의 KO 5섹션 합본에 "anchor" 평문 0', () {
      // 실제 셀럽 dayPillar sample 10종 × user 10종 = 100 pair.
      const celebDPs = <String>[
        '癸卯', // 홍은채 등.
        '壬子', '丙午', '甲寅', '辛酉',
        '戊戌', '丁巳', '庚申', '乙卯', '己未',
      ];
      const userDPs = <String>[
        '甲子', '乙丑', '丙寅', '丁卯', '戊辰',
        '己巳', '庚午', '辛未', '壬申', '癸酉',
      ];
      final hits = <String>[];
      for (final udp in userDPs) {
        for (final cdp in celebDPs) {
          final me = _mkMe(udp);
          final celeb = kpop.starToSajuResultForTest({
            'id': 't_$cdp',
            'nameKo': '셀럽$cdp',
            'nameEn': 'Celeb $cdp',
            'kind': 'idol',
            'birth': '1996-03-15',
            'dayPillar': cdp,
            'dayPillarName': 'Test Pair',
            'blurbKo': '테스트',
            'blurbEn': 'test',
          });
          final a = compat.analyzeCompatForTest(
            me: me,
            partner: celeb,
            useKo: true,
            partnerName: '셀럽$cdp',
          );
          final body = '${a.summary}\n${a.attract}\n${a.friction}\n'
              '${a.loveMarriage}\n${a.actions.join('\n')}';
          if (body.contains('anchor')) {
            final idx = body.indexOf('anchor');
            final start = (idx - 15).clamp(0, body.length);
            final end = (idx + 25).clamp(0, body.length);
            hits.add('$udp×$cdp: "${body.substring(start, end)}"');
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            '셀럽 adapter path 의 KO 본문에 "anchor" 평문 잔존 (${hits.length}건). '
            '예시: ${hits.take(3).toList()}. 사용자 mandate "왜 한국어에 영어가 들어와" 회귀.',
      );
    });

    test('C-2. 셀럽 adapter path 의 KO 5섹션 합본에 60갑자 영문 페어 0', () {
      final pairs = _allElementAnimalPairs();
      const celebDPs = <String>['癸卯', '壬子', '丙午', '甲寅', '辛酉'];
      const userDPs = <String>['甲子', '丙寅', '戊辰', '庚午', '壬申'];
      final hits = <String>[];
      for (final udp in userDPs) {
        for (final cdp in celebDPs) {
          final me = _mkMe(udp);
          final celeb = kpop.starToSajuResultForTest({
            'id': 't_$cdp',
            'nameKo': '셀럽$cdp',
            'nameEn': 'Celeb $cdp',
            'kind': 'idol',
            'birth': '1996-03-15',
            'dayPillar': cdp,
            'dayPillarName': 'Test Pair',
            'blurbKo': '테스트',
            'blurbEn': 'test',
          });
          final a = compat.analyzeCompatForTest(
            me: me,
            partner: celeb,
            useKo: true,
            partnerName: '셀럽$cdp',
          );
          final body = '${a.summary}\n${a.attract}\n${a.friction}\n'
              '${a.loveMarriage}\n${a.actions.join('\n')}';
          for (final ep in pairs) {
            if (body.contains(ep)) {
              hits.add('$udp×$cdp: "$ep"');
            }
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            '셀럽 adapter path 의 KO 본문에 60갑자 영문 페어 (예: "Water Rabbit") 잔존: '
            '${hits.take(5).toList()}.',
      );
    });

    // ─────────────────────────────────────────────────────────────
    // D. blurbKo 영문 그룹명 head 한국어 정규화.
    // ─────────────────────────────────────────────────────────────
    test('D. blurbKo 영문 그룹명 prefix 가 한국어 표기로 정규화', () {
      // 사용자 verbatim 4-line OCR 의 직접 케이스 — "LE SSERAFIM 홍은채".
      const cases = <String, String>{
        'LE SSERAFIM 홍은채. 기본 성향은 비/이슬 물과 토끼띠가 만나는 모습이에요.':
            '르세라핌 홍은채',
        'BLACKPINK 제니. 무대의 여왕.': '블랙핑크 제니',
        'BTS 정국. 황금 막내.': '방탄소년단 정국',
        'NewJeans 민지. 태양 불.': '뉴진스 민지',
        'aespa 윈터. 큰 나무.': '에스파 윈터',
        'ITZY 예지. 리더.': '있지 예지',
        'IVE 안유진. 리더.': '아이브 안유진',
        'NCT DREAM 마크. 형.': '엔시티 드림 마크',
        'NCT WISH 시온. 막내.': '엔시티 위시 시온',
      };
      for (final entry in cases.entries) {
        final out = kpop.localizeGroupPrefixKoForTest(entry.key);
        final inSnippet =
            entry.key.substring(0, entry.key.length.clamp(0, 20));
        final outSnippet = out.substring(0, out.length.clamp(0, 25));
        expect(
          out.startsWith(entry.value),
          isTrue,
          reason:
              '"$inSnippet..." 가 "${entry.value}" 로 시작하지 않음. '
              '실제: "$outSnippet".',
        );
        // 정규화 결과에서 영문 그룹명 prefix 자체가 첫 단어로 등장하지 않음을 확인.
        final firstWord = out.split(' ').first;
        expect(
          RegExp(r'^[A-Z][A-Za-z]+$').hasMatch(firstWord),
          isFalse,
          reason:
              '정규화 후에도 영문 그룹명 prefix ($firstWord) 가 첫 단어로 잔존 — '
              '한국 미디어 표기 매핑 누락.',
        );
      }
    });

    test('D-2. 홍은채 OCR 케이스가 본문 첫머리에 "LE SSERAFIM 홍은채" 그대로 노출되지 않음', () {
      // 사용자 OCR 4-line 직격 — INSIGHT 영역의 blurbKo 가 KO 분기에서
      // _localizeGroupPrefixKo 를 통과해서 mount 되는지 widget-mount 가 아닌
      // helper-level 로 검사.
      const rawBlurb =
          'LE SSERAFIM 홍은채. 기본 성향은 비/이슬 물과 토끼띠가 만나는 모습이에요. '
          '혼란을 카메라 매직으로 바꾸는 미소 에너지 막내.';
      final out = kpop.localizeGroupPrefixKoForTest(rawBlurb);
      expect(
        out.startsWith('LE SSERAFIM'),
        isFalse,
        reason:
            'KO 분기 INSIGHT 본문이 여전히 "LE SSERAFIM" 으로 시작 — 사용자 OCR '
            '직격 회귀. _localizeGroupPrefixKo 매핑 누락.',
      );
      expect(out.startsWith('르세라핌 홍은채'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────
    // E. reports home 메뉴 라벨 "최애와의 궁합보기".
    // ─────────────────────────────────────────────────────────────
    test('E. reports_home_screen 메뉴 라벨이 "최애와의 궁합보기" 로 변경됐는지', () {
      final src = File(
        'lib/screens/reports/reports_home_screen.dart',
      ).readAsStringSync();

      expect(
        src.contains('최애와의 궁합보기'),
        isTrue,
        reason:
            '메뉴 라벨이 "최애와의 궁합보기" 로 변경되지 않음 — 사용자 mandate '
            '"최애와의 궁합보기로 메뉴명을 바꾸고" 회귀.',
      );
      // 이전 라벨 잔존 0.
      expect(
        src.contains("'최애와 케미'"),
        isFalse,
        reason: '이전 라벨 "최애와 케미" 가 src 안에 잔존.',
      );
      // route 자체는 보존 (router.dart 에 변경 없음 mandate).
      expect(
        src.contains("route: '/reports/kpop-compat'"),
        isTrue,
        reason:
            'kpop-compat route 가 메뉴 list 에서 빠짐 — sprint 3 는 라벨만 교체, '
            'route 보존 mandate.',
      );
    });

    // ─────────────────────────────────────────────────────────────
    // F. _starToSajuResult adapter 안정성 — 시간 모름 처리.
    // ─────────────────────────────────────────────────────────────
    test('F. _starToSajuResult adapter — 시간 모름 + dayPillar wire 정확', () {
      final r = kpop.starToSajuResultForTest({
        'id': 'test',
        'nameKo': '홍은채',
        'nameEn': 'Hong Eunchae',
        'kind': 'idol',
        'birth': '2006-11-10',
        'dayPillar': '癸卯',
        'dayPillarName': 'Water Rabbit',
        'blurbKo': '르세라핌 홍은채.',
        'blurbEn': 'LE SSERAFIM Hong Eunchae.',
      });
      expect(r.dayPillar.chunGan, '癸');
      expect(r.dayPillar.jiJi, '卯');
      expect(r.day60ji, '癸卯');
      expect(
        r.hourPillar,
        isNull,
        reason: '시간 모름 — R83 sprint P1-E 와 동일 처리, hourPillar=null.',
      );
      // 5행 분포 — 癸 (水) 가 dominant.
      expect(r.elements.dominant, '水');
    });
  });
}
