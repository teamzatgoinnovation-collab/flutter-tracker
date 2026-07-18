import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracker/app.dart';

void main() {
  testWidgets('login screen shows brand', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProjectTrackerApp()));
    await tester.pumpAndSettle();
    expect(find.text('Project Tracker'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
