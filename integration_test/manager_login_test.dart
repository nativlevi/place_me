import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:place_me/general/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Manager login integration test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. כניסה כאדמין
    await tester.tap(find.textContaining('Manager'));
    await tester.pumpAndSettle();

    // ודא שמופיע 'Welcome back'
    expect(find.text('Welcome back'), findsOneWidget);

    // הכנס אימייל (של משתמש קיים ומאומת)
    await tester.enterText(
        find.byType(TextFormField).at(0), 'neria126@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Neria1997!');

    // לחץ על כפתור SIGN IN
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle(
        const Duration(seconds: 5)); // תוכל להגדיל זמן אם לוקח יותר

    // ודא שהגעת למסך הניהול (עדכן לטקסט אמיתי שמופיע שם!)
    expect(find.text('My Events'),
        findsOneWidget); // או כל טקסט ייחודי במסך הבית של מנהל
  });

  testWidgets('Manager login with wrong password shows error',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // לחץ על "Manager"
    await tester.tap(find.text('Manager'));
    await tester.pumpAndSettle();

    // ודא שמופיע 'Welcome back'
    expect(find.text('Welcome back'), findsOneWidget);

    // הכנס אימייל נכון וסיסמה לא נכונה
    await tester.enterText(
        find.byType(TextFormField).at(0), 'neria126@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongPassword');

    // לחץ על כפתור SIGN IN
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ודא שהופיעה הודעת שגיאה
    expect(find.textContaining('An internal error has occurred'),
        findsOneWidget); // או חלק מהשגיאה שמתקבלת
  });
}
