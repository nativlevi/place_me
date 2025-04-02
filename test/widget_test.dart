import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_me/start/main.dart';
import 'package:place_me/general/splash_screen.dart';

void main() {
  group('App Tests', () {
    testWidgets('Splash Screen navigates to Login Screen',
        (WidgetTester tester) async {
      // Load the app
      await tester.pumpWidget(MyApp());

      // Verify that the Splash Screen is displayed
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for the navigation to complete (Splash Screen duration is 3 seconds)
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify that the app navigated to the Login Screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login Screen has Manager and Participant buttons',
        (WidgetTester tester) async {
      // Load the Login Screen directly
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify that the "Manager" button exists
      expect(find.text('Manager   '), findsOneWidget);

      // Verify that the "Participant" button exists
      expect(find.text('Participant'), findsOneWidget);
    });
  });
}
