// test/widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fyp/main.dart';  // This imports TankerTapApp

void main() {
  testWidgets('App launches and shows Login screen', (WidgetTester tester) async {
    // Build your app and trigger a frame
    await tester.pumpWidget(const TankerTapApp());  // ← Fixed: Use TankerTapApp

    // Wait for any async initialization (Firebase, etc.)
    await tester.pumpAndSettle();

    // Verify that the app starts on Login screen
    expect(find.text('Hi, Welcome Back!'), findsOneWidget);
    // or check for email field
    expect(find.widgetWithText(TextField, 'Enter your email'), findsOneWidget);
    // or check for Login button
    expect(find.text('Login'), findsOneWidget);

    // Optional: Test Google Sign-In button exists
    expect(find.text('Continue with Google'), findsOneWidget);

    // Optional: Test navigation to Sign Up
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create an account'), findsOneWidget);
  });

  // Bonus: Simple smoke test
  testWidgets('App has a title', (WidgetTester tester) async {
    await tester.pumpWidget(const TankerTapApp());
    await tester.pumpAndSettle();

    final titleFinder = find.text('Tanker Tap');
    expect(titleFinder, findsWidgets); // Could be in AppBar or elsewhere
  });
}