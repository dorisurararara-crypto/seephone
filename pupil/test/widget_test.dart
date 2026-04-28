import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pupil/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PupilApp()));
    await tester.pump();
    expect(find.textContaining('동공 지진'), findsWidgets);
  });
}
