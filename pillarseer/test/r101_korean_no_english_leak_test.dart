// R101 sprint 2 — compatibility_screen KO 본문 영문 leak 0 가드.
//
// 사용자 mandate verbatim (R101 sprint 1 baseline §2):
//   "왜 한국어에 영어가 들어와?"
//
// 본 가드는 sprint 2 의 `compatibility_screen.dart` KO 분기 anchor 평문
// 제거 + 일주 영문명 (`Water Rabbit` / `Wood Tiger` 등 60갑자 전체) inject
// 차단을 회귀 lock 한다.
//
// kpop_compat_screen.dart 는 Sprint 3 owner — 본 가드는 의도적으로
// compatibility_screen 의 `_analyze()` 5섹션 합본만 측정한다.
//
// Release-blocking assertions:
//   A. KO `_analyze` 5섹션 합본에 "anchor" 평문 == 0
//   B. KO `_analyze` 5섹션 합본에 60갑자 영문 일주명 (Element + Animal
//      페어, 예: "Water Rabbit" / "Wood Tiger" / "Fire Snake" / "Earth
//      Dragon" / "Metal Horse") == 0

import 'package:flutter_test/flutter_test.dart';

import 'package:pillarseer/models/saju_result.dart';
import 'package:pillarseer/screens/reports/compatibility_screen.dart' as compat;

/// 60갑자 영문 일주명 — element 5 × animal 12 = 60.
/// `Water Rabbit`, `Wood Tiger`, `Fire Snake`, `Earth Dragon`, `Metal Horse` …
const List<String> _elementsEn = <String>[
  'Wood',
  'Fire',
  'Earth',
  'Metal',
  'Water',
];

const List<String> _animalsEn = <String>[
  'Rat',
  'Ox',
  'Tiger',
  'Rabbit',
  'Dragon',
  'Snake',
  'Horse',
  'Goat',
  'Monkey',
  'Rooster',
  'Dog',
  'Pig',
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

/// 임의 dayPillar 의 user/partner — `_analyze()` 가 4기둥 8자만 사용하므로
/// 다른 pillar 는 같은 값으로 채워 결과 안정성 확보.
SajuResult _mkUser(String dayPillar) {
  final gan = dayPillar[0];
  final ji = dayPillar[1];
  return SajuResult(
    yearPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    monthPillar: const Pillar(chunGan: '甲', jiJi: '子'),
    dayPillar: Pillar(chunGan: gan, jiJi: ji),
    elements: const FiveElements(wood: 20, fire: 20, earth: 20, metal: 20, water: 20),
    dayMaster: gan,
    dayMasterName: '_',
    summary: '_',
    categoryReadings: const {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 다양한 element-relation 분기를 모두 거치도록 user dayPillar 10 × partner
  // dayPillar 10 = 100 pair 결정적 sample. 5행 페어, 합/충/형, 같은 일주 등
  // 모든 branch 가 본문에 등장하게 한다.
  const userDPs = <String>[
    '甲子', '乙丑', '丙寅', '丁卯', '戊辰',
    '己巳', '庚午', '辛未', '壬申', '癸酉',
  ];
  const partnerDPs = <String>[
    '甲子', '乙丑', '丙寅', '丁卯', '戊辰',
    '己巳', '庚午', '辛未', '壬申', '癸酉',
  ];

  group('R101 sprint 2 — compatibility KO 본문 영문 leak 0', () {
    test('A. KO 5섹션 합본에 "anchor" 평문 == 0', () {
      final hits = <({String pair, String section, String snippet})>[];
      for (final udp in userDPs) {
        for (final pdp in partnerDPs) {
          final me = _mkUser(udp);
          final pt = _mkUser(pdp);
          final a = compat.analyzeCompatForTest(
            me: me,
            partner: pt,
            useKo: true,
            partnerName: '상대',
          );
          final sections = <String, String>{
            'summary': a.summary,
            'attract': a.attract,
            'friction': a.friction,
            'loveMarriage': a.loveMarriage,
            'actions': a.actions.join('\n'),
          };
          for (final entry in sections.entries) {
            if (entry.value.contains('anchor')) {
              final idx = entry.value.indexOf('anchor');
              final start = (idx - 20).clamp(0, entry.value.length);
              final end = (idx + 30).clamp(0, entry.value.length);
              hits.add((
                pair: '$udp×$pdp',
                section: entry.key,
                snippet: entry.value.substring(start, end),
              ));
            }
          }
        }
      }
      expect(hits, isEmpty,
          reason:
              'KO 본문에 "anchor" 평문 잔존 — R101 사용자 mandate "왜 한국어에 영어가 들어와" 회귀. '
              'hits=${hits.take(3).map((h) => '${h.pair}[${h.section}]:"${h.snippet}"').toList()}');
    });

    test('B. KO 5섹션 합본에 60갑자 영문 일주명 (Element + Animal) == 0', () {
      final pairs = _allElementAnimalPairs();
      expect(pairs.length, 60, reason: '60갑자 영문 페어 enumeration 깨짐');
      final hits = <({String dayPair, String section, String englishPair})>[];
      for (final udp in userDPs) {
        for (final pdp in partnerDPs) {
          final me = _mkUser(udp);
          final pt = _mkUser(pdp);
          final a = compat.analyzeCompatForTest(
            me: me,
            partner: pt,
            useKo: true,
            partnerName: '상대',
          );
          final sections = <String, String>{
            'summary': a.summary,
            'attract': a.attract,
            'friction': a.friction,
            'loveMarriage': a.loveMarriage,
            'actions': a.actions.join('\n'),
          };
          for (final entry in sections.entries) {
            for (final ep in pairs) {
              if (entry.value.contains(ep)) {
                hits.add((
                  dayPair: '$udp×$pdp',
                  section: entry.key,
                  englishPair: ep,
                ));
              }
            }
          }
        }
      }
      expect(hits, isEmpty,
          reason:
              'KO 본문에 영문 일주명 (Water Rabbit / Wood Tiger / Fire Snake / Earth Dragon / Metal Horse …) 잔존 — '
              'R101 사용자 mandate 회귀. '
              'hits=${hits.take(5).map((h) => '${h.dayPair}[${h.section}]:"${h.englishPair}"').toList()}');
    });
  });
}
