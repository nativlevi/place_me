import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:place_me/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Participant sign up integration test',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // במסך הראשי, לחץ על "Participant"
    await tester.tap(find.textContaining('Participant'));
    await tester.pumpAndSettle();

    // במסך הכניסה, לחץ על "SIGN UP" או "Log in" (לפי מה שמופיע בפועל אצלך)
    await tester.tap(find.textContaining('SIGN UP')); // עדכן ל"Log in" אם צריך
    await tester.pumpAndSettle();

    // ודא שאנחנו במסך הרשמה (חפש טקסט ייחודי, למשל: 'Get started')
    expect(find.text('Get started'), findsOneWidget);

    // מלא טופס הרשמה
    final now = DateTime.now().millisecondsSinceEpoch;
    final phone = '054${now % 10000000}'; // ייחודי בכל הרצה
    final password = 'TestPassword1!';
    final name = 'בדיקה${now % 1000}';

    await tester.enterText(find.byType(TextFormField).at(0), phone);
    await tester.enterText(find.byType(TextFormField).at(1), name);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.enterText(find.byType(TextFormField).at(3), password);

    // לחץ על כפתור SET PASSWORD
    await tester.tap(find.text('SET PASSWORD'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // בדוק הופעת SnackBar הצלחה (אם לא מופיע, תוכל לדלג)
    // expect(find.text('User registered successfully!'), findsOneWidget);

    // ודא שמעבירים למסך login (הטקסט 'Welcome back')
    expect(find.text('Welcome back'), findsOneWidget);

    // (אופציונלי) נסה להתחבר מיד אחרי הרשמה (אם אתה רוצה לבדוק זרימת רישום+כניסה)
    // ...
  });
}
