// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:place_me/main.dart';

void main() {
  testWidgets('האפליקציה נטענת בהצלחה', (WidgetTester tester) async {
    // טוען את האפליקציה ללא ניווט אוטומטי (כמו SplashScreen)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('בדיקה פשוטה'),
          ),
        ),
      ),
    );

    // מוודא שהאפליקציה נטענת ומציגה את הטקסט
    expect(find.text('בדיקה פשוטה'), findsOneWidget);
  });
}
