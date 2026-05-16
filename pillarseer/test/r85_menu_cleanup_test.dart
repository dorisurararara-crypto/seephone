import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R85 menu cleanup', () {
    test('bottom nav uses simple labels without hanja helper glyphs', () {
      final src = File('lib/widgets/bottom_nav.dart').readAsStringSync();

      expect(src.contains('glyph'), isFalse);
      expect(src.contains("'譜'"), isFalse);
      expect(src.contains("'日'"), isFalse);
      expect(src.contains("'柱'"), isFalse);
      expect(src.contains("'我'"), isFalse);
    });

    test('reports home exposes only high-signal menu cards', () {
      final src = File(
        'lib/screens/reports/reports_home_screen.dart',
      ).readAsStringSync();

      expect(src.contains("route: '/reports/compatibility'"), isTrue);
      expect(src.contains("route: '/reports/new-year-2026'"), isTrue);
      expect(src.contains("route: '/reports/dream'"), isTrue);
      expect(src.contains("route: '/reports/kpop-compat'"), isTrue);

      expect(src.contains("route: '/reports/tojeong'"), isFalse);
      expect(src.contains("route: '/reports/date-picking'"), isFalse);
      expect(src.contains("route: '/discover'"), isFalse);
      expect(src.contains('土 亭'), isFalse);
      expect(src.contains('擇 日'), isFalse);
      expect(src.contains('名 譜'), isFalse);
    });

    test('visible l10n labels say More, not Reports/리포트', () {
      final ko = File('lib/l10n/app_ko.arb').readAsStringSync();
      final en = File('lib/l10n/app_en.arb').readAsStringSync();

      expect(ko.contains('"navReports": "더 보기"'), isTrue);
      expect(en.contains('"navReports": "More"'), isTrue);
      expect(ko.contains('"reportsHomeTitle": "더 보기"'), isTrue);
      expect(en.contains('"reportsHomeTitle": "More"'), isTrue);
      expect(ko.contains('궁합, 토정비결, 택일'), isFalse);
      expect(en.contains('Tojeong yearly fortune, date picking'), isFalse);
    });
  });
}
