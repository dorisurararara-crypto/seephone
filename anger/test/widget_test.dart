import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anger/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AngerApp()));
    await tester.pump();
    expect(find.text('분노'), findsOneWidget);
  });
}
