import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:achivo/main.dart';

void main() {
  testWidgets('App launches and shows WelcomeScreen', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify app title or main text exists
    expect(find.text('Achivo'), findsOneWidget);

    // Verify Next button exists
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Tapping Next navigates forward', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the Next button
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // After tapping, check if it navigates to next screen
    // (replace "WelcomeForm" with whatever screen appears after Next)
    expect(find.text('WelcomeForm'), findsOneWidget);
  });
}
