import 'package:flutter_test/flutter_test.dart';

import 'package:layout/main.dart';

void main() {
  testWidgets('App loads and shows main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pumpAndSettle();

    // Check bottom navigation labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Alert'), findsOneWidget);
    expect(find.text('Distress'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Check that dashboard loads by default
    expect(find.text('Dashboard'), findsOneWidget);
  });
}