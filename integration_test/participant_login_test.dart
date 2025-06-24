import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:place_me/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Participant login integration test',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ודא שיש כפתור/טקסט "Participant" במסך הראשי
    final participantBtn = find.textContaining('Participant');
    expect(participantBtn, findsOneWidget);
    await tester.tap(participantBtn);
    await tester.pumpAndSettle();

    // ודא שהגענו למסך login של המשתתף
    expect(find.text('Welcome back'), findsOneWidget);

    // הזן מספר טלפון (יש להזין מספר קיים ב-Firestore תחת users)
    await tester.enterText(find.byType(TextFormField).at(0), '0526071633');
    // הזן סיסמה תואמת (כפי ששמור במסמך של המשתמש)
    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    // לחץ על SIGN IN
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ודא שהמשתמש מועבר למסך האירועים של משתתף
    // אתה יכול לבדוק טקסט ייחודי מהמסך הזה (למשל: "My Events", או טקסט אחר שמופיע בוודאות)
    expect(find.textContaining('Hi Friend,'),
        findsOneWidget); // דוג' בעברית: "האירועים שלי"
    // או לדוג' אם יש לך טקסט אחר במסך:
    // expect(find.text('My Events'), findsOneWidget);
  });
}
