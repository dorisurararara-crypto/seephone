// R86 — 사용자 mandate (verbatim):
//   "오늘 너 = 이런 표현 빼줘 ai같아 그리고 어떤 부분은 반말 어떤부분은 존댓말이네ㅜ
//    이런것도 다 없애 정인격 이라던지 이런것도 무슨말인지 몰라 금토끼에 결
//    이것도 없어도 될거같아 kpop궁합도 스크롤하면 전체스크롤이 되야하는데
//    아래만 스크롤이 되고 아래에 너무 많으니까 검색을 할수있게 해야돼
//    이름 또는 그룹으로 할수있게 그리고 신년운세에서 이건 없어도돼(사진4)
//    절기별로 표현한거 같은데 없어도돼"
//
// 본 sprint 회귀 가드 (4 fix):
//   B1 — 격국 jargon ("정인격" 등) 본문 노출 0 (dynamic_text_resolver.gyeokgukAnchor)
//   B2 — "X 의 결" 명사화 (result_screen 일주 본성 subtitle) 노출 0
//   B3 — 신년운세 화면에서 _MonthlyFlow widget 호출 0 (절기 카드 섹션 비노출)
//   B4 — K-POP 화면 _SearchBar / CustomScrollView 존재 (스크롤·검색)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/dynamic_text_resolver.dart';
import 'package:pillarseer/services/saju_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R86 — 카피 위생 + 화면 정리', () {
    test('B1 — DynamicTextResolver.gyeokgukAnchor 본문에 격국 단어 노출 0', () {
      const labels = ['정관격', '편관격', '정인격', '편인격', '정재격', '편재격', '식신격', '상관격'];
      for (final g in labels) {
        final ctx = SajuContext(
          dayMaster: '甲', dayElement: '木', dayYang: true,
          monthBranch: '寅', season: '봄',
          wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
          dominantElement: '木', deficitElement: '水',
          tenGodFrequency: const {},
          strengthLabel: '중화',
          gyeokgukShort: g,
          gyeokgukFull: '$g (정밀)',
          yongsin: '火', huisin: '土', gisin: '水',
          activeShinsa: const {}, gongMangAreas: const [],
          currentDaewoon: null, currentDaewoonGod: null,
          todayPillar: null, todayGod: null, todayRelations: const [],
          chartSeed: 1, userAge: null,
        );
        final anchor = DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'ko');
        expect(anchor.isNotEmpty, isTrue,
            reason: '$g — 격국 anchor phrase 가 비어있음');
        expect(anchor.contains(g), isFalse,
            reason: '$g — 격국 단어 자체가 사용자 본문에 노출되면 안 됨 (R86 mandate)');
      }
    });

    test('B1b — 8 격국 anchor 가 서로 다른 phrase (변별력 R78 sprint 7 시그니처 보존)', () {
      const labels = ['정관격', '편관격', '정인격', '편인격', '정재격', '편재격', '식신격', '상관격'];
      final phrases = <String>{};
      for (final g in labels) {
        final ctx = SajuContext(
          dayMaster: '甲', dayElement: '木', dayYang: true,
          monthBranch: '寅', season: '봄',
          wood: 30, fire: 20, earth: 20, metal: 20, water: 10,
          dominantElement: '木', deficitElement: '水',
          tenGodFrequency: const {},
          strengthLabel: '중화',
          gyeokgukShort: g,
          gyeokgukFull: '$g (정밀)',
          yongsin: '火', huisin: '土', gisin: '水',
          activeShinsa: const {}, gongMangAreas: const [],
          currentDaewoon: null, currentDaewoonGod: null,
          todayPillar: null, todayGod: null, todayRelations: const [],
          chartSeed: 1, userAge: null,
        );
        phrases.add(DynamicTextResolver.gyeokgukAnchor(ctx, locale: 'ko'));
      }
      expect(phrases.length, labels.length,
          reason: '8 격국 anchor 가 모두 달라야 변별력 R78 sprint 7 시그니처 보존');
    });

    test('B2 — result_screen 의 본성 카드 subtitle 에 "의 결" 명사화 노출 0', () {
      final src = File('lib/screens/result_screen.dart').readAsStringSync();
      // 본성 카드 영역 — "당신의 기본 성향" 직후 "의 결" 잔존 X.
      expect(
        src.contains("'의 결\\n(태어난 날 기준"),
        isFalse,
        reason: '"X 의 결" 명사화 표현 잔존 — R86 mandate 위반',
      );
      // 새 subtitle 형태는 "당신의 기본 성향\n(태어난 날 기준 …)" 1 TextSpan.
      expect(
        src.contains("'당신의 기본 성향\\n(태어난 날 기준"),
        isTrue,
        reason: '본성 카드 subtitle 이 R86 패턴으로 갱신되지 않음',
      );
    });

    test('B3 — 신년운세 화면 build 에서 _MonthlyFlow 호출 노출 0', () {
      final src =
          File('lib/screens/reports/new_year_2026_screen.dart').readAsStringSync();
      // class 정의 + static moodFor 위임은 R78 sprint 7 test 보존 위해 유지.
      // 단 widget tree 안에서 인스턴스 생성 (`_MonthlyFlow(` + `saju:`) 는 0.
      final monthlyFlowInstance =
          RegExp(r'^\s*_MonthlyFlow\(\s*$', multiLine: true).hasMatch(src);
      expect(monthlyFlowInstance, isFalse,
          reason: '신년운세 화면에서 _MonthlyFlow widget 이 build tree 에 살아있음');
    });

    test('B4 — K-POP 화면 — CustomScrollView + 이름/그룹 검색바 wire', () {
      final src = File('lib/screens/reports/kpop_compat_screen.dart')
          .readAsStringSync();
      expect(src.contains('CustomScrollView('), isTrue,
          reason: 'K-POP 화면이 CustomScrollView 로 통합 스크롤되지 않음');
      expect(src.contains('class _SearchBar'), isTrue,
          reason: 'K-POP 화면에 _SearchBar widget 누락');
      expect(src.contains('이름 또는 그룹 검색'), isTrue,
          reason: '_SearchBar 한국어 hint 누락');
      expect(src.contains('Search by name or group'), isTrue,
          reason: '_SearchBar 영문 hint 누락');
      expect(src.contains('class _EmptySearchResult'), isTrue,
          reason: '검색 결과 0 empty state widget 누락');
    });
  });
}
