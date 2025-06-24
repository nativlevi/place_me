import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:place_me/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Manager sign up integration test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // לחץ על "Manager"
    await tester.tap(find.textContaining('Manager'));
    await tester.pumpAndSettle();

    // במסך login של המנהל, לחץ על "SIGN UP"
    await tester.tap(find.text('SIGN UP'));
    await tester.pumpAndSettle();

    // ודא שאנחנו במסך הרשמה (חפש טקסט ייחודי, למשל: 'Get started')
    expect(find.text('Get started'), findsOneWidget);

    // הכנס אימייל, סיסמה, ואישור סיסמה
    await tester.enterText(find.byType(TextFormField).at(0),
        'test.manager${DateTime.now().millisecondsSinceEpoch}@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'testPassword1!');
    await tester.enterText(find.byType(TextFormField).at(2), 'testPassword1!');

    // לחץ על כפתור SIGN UP
    await tester.tap(find.text('SIGN UP'));
    await tester.pumpAndSettle(
        const Duration(seconds: 3)); // אפשר לשנות את הזמן אם לוקח יותר

    // בדוק שמופיע דיאלוג אימות מייל (זה הדיאלוג בקוד שלך)
    expect(find.text('Email Verification'), findsOneWidget);
    expect(find.textContaining('A verification email has been sent'),
        findsOneWidget);

    // לחץ על OK לסגירת הדיאלוג
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // אפשר לבדוק שהמסך נשאר במסך הרשמה או עבר, תלוי בלוגיקה שלך
    // לדוג': expect(find.text('Get started'), findsOneWidget);
  });
}
