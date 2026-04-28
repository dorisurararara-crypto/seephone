import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbaksin/app.dart';

void main() {
  testWidgets('app boots without error', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BbaksinApp()));
    await tester.pump();
    expect(find.text('빡神'), findsOneWidget);
  });
}
