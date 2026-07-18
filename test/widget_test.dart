import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/app.dart';

void main() {
  testWidgets('login screen shows brand', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TrackerApp()));
    await tester.pumpAndSettle();
    expect(find.text('Tracker'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
