import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:achivo/main.dart';

void main() {
  testWidgets('App launches and shows WelcomeScreen', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

   
    expect(find.text('Achivo'), findsOneWidget);

    // Verify Next button exists
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Tapping Next navigates forward', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

   
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('WelcomeForm'), findsOneWidget);
  });
}
