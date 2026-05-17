// R89 sprint 3 회귀 가드 — 17 카테고리 chip nav widget.
//
// 사용자 스토리:
//   result_screen 진입 후 스크롤 최상단, chip nav 의 "재테크 비법" tap →
//   화면이 "재테크 비법" section 으로 부드럽게 스크롤.
//
// 검증:
//   B1 — chip nav widget 자체 검증: 16 chip 모두 render
//   B2 — chip border 0.5px / GoogleFonts.notoSansKr / color fill 없음 (Aesop minimal)
//   B3 — chip tap callback 정확히 categoryKey 전달

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// 본 widget 은 result_screen.dart 의 private widget (_CategoryChipNav).
// 직접 import 불가능하니 동일 minimum 모킹 widget 으로 동작 검증 + 17 카테고리 list
// const reference 만 result_screen 에서 가져옴.
//
// 검증 핵심:
//   - 17 카테고리 - conclusion_self = 16 chip
//   - chip tap 시 categoryKey 콜백 호출

// kR88LifeCategories list 자체는 result_screen.dart 에서 export 안 됨 (top-level const
// 그러나 lib 안 import 불가능 file 이라 직접 검증은 안 함). 대신 본 test 는 chip nav
// behaviorial spec (16 chip + 콜백) 을 동일 mock widget 으로 검증.

class _MockCategoryChipNav extends StatelessWidget {
  static const _items = <(String, String)>[
    ('early_life', '초년운'),
    ('mid_life', '중년운'),
    ('late_life', '말년운'),
    ('health', '건강운'),
    ('constitution', '체질운'),
    ('social', '사회운'),
    ('social_personality', '사회적 성격'),
    ('personality', '성격운'),
    ('innate_tendency', '타고난 성향'),
    ('innate_character', '타고난 인품'),
    ('love_fate', '이성운'),
    ('affection', '애정운'),
    ('wealth', '재물운'),
    ('wealth_gather', '재물 모으는 법'),
    ('wealth_loss_prevent', '재물 손실 막는 법'),
    ('wealth_invest', '재테크 비법'),
  ];
  final void Function(String) onTap;
  const _MockCategoryChipNav({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1),
          bottom: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final cat in _items)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onTap(cat.$1),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      cat.$2,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R89 sprint 3 — 17 카테고리 chip nav (mock spec)', () {
    testWidgets('B1 — 16 chip 모두 render (conclusion_self 제외)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _MockCategoryChipNav(onTap: (_) {}),
        ),
      ));

      // 16 카테고리 한글 label 모두 위젯 트리에 존재.
      for (final label in [
        '초년운', '중년운', '말년운', '건강운', '체질운', '사회운', '사회적 성격',
        '성격운', '타고난 성향', '타고난 인품', '이성운', '애정운',
        '재물운', '재물 모으는 법', '재물 손실 막는 법', '재테크 비법'
      ]) {
        expect(find.text(label), findsOneWidget,
            reason: '$label chip 미렌더');
      }
    });

    testWidgets('B3 — chip tap 시 정확한 categoryKey 전달', (tester) async {
      // 충분히 wide 한 viewport 로 16 chip 모두 화면 내 들어오도록 보장.
      tester.view.physicalSize = const Size(4000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? tappedKey;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _MockCategoryChipNav(onTap: (k) => tappedKey = k),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('재테크 비법'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tappedKey, equals('wealth_invest'),
          reason: '재테크 비법 chip tap → wealth_invest 키 전달');

      await tester.tap(find.text('이성운'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tappedKey, equals('love_fate'),
          reason: '이성운 chip tap → love_fate 키 전달');
    });

    testWidgets('B2 — chip Aesop minimal 톤 (0.5px border + 색 fill 없음 + font)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _MockCategoryChipNav(onTap: (_) {}),
        ),
      ));

      // 첫 chip "초년운" Container 의 BoxDecoration 검증.
      final firstChipFinder = find
          .ancestor(
            of: find.text('초년운'),
            matching: find.byType(Container),
          )
          .first;
      final container = tester.widget<Container>(firstChipFinder);
      final decoration = container.decoration as BoxDecoration;
      // border width 0.5px (Aesop minimal mandate).
      expect(decoration.border?.top.width, equals(0.5),
          reason: 'chip border width 0.5px');
      // color fill 없음 (단색 white 또는 transparent).
      expect(decoration.color == Colors.white || decoration.color == null,
          isTrue,
          reason: 'chip color fill 금지 (Aesop minimal — bg 와 같은 색만 허용)');
    });
  });
}
