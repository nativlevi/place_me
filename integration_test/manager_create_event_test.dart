import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:place_me/general/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Manager creates a new event', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // הדפסה של כל הטקסטים במסך
    final texts = find.byType(Text);
    for (final e in texts.evaluate()) {
      final text = e.widget as Text;
      print('TEXT FOUND: "${text.data}"');
    }

    // 1. כניסה כאדמין
    await tester.tap(find.textContaining('Manager'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    // עדכן כאן למייל+סיסמה של מנהל אמיתי
    await tester.enterText(
        find.byType(TextFormField).at(0), 'neria126@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Neria1997!');

    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. מסך הבית
    expect(find.text('My Events'), findsOneWidget);

    // 3. לחיצה על כפתור הפלוס (FAB)
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // 4. בחירת סוג אירוע (אם יש מסך בחירה, יש להוסיף כאן פעולה/לחיצה)
    if (find.text('Classroom/Workshop').evaluate().isNotEmpty) {
      await tester.tap(find.text('Classroom/Workshop'));
      await tester.pumpAndSettle();
    }

    // 5. מסך פרטי האירוע (Event Details)
    expect(find.text('Event Details'), findsOneWidget);

    // 6. מילוי שדות (Event Name, Location)
    final eventName = 'אירוע בדיקה ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.byType(TextFormField).at(0), eventName);
    await tester.enterText(find.byType(TextFormField).at(1), 'חדר 101');

    // בחירת תאריך
    if (find.text('Select Date').evaluate().isNotEmpty) {
      await tester.tap(find.text('Select Date'));
      await tester.pumpAndSettle();
      final day = DateTime.now().day;
      await tester.tap(find.text('$day'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }
    if (find.text('Select Time').evaluate().isNotEmpty) {
      await tester.tap(find.text('Select Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    // גלילה ל-Submit (לפעמים הכפתור לא גלוי!)
    final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // וידוא שהגענו למסך סידור ישיבה
    expect(find.text('Seating Arrangement'), findsOneWidget);

    // לחץ על כפתור שמירה (אייקון דיסקט)
    final saveIcon = find.byIcon(Icons.save);
    expect(saveIcon, findsOneWidget, reason: 'אייקון השמירה לא נמצא');
    await tester.tap(saveIcon);
    await tester.pumpAndSettle();

    // חזרה למסך הבית + בדיקה שהאירוע ברשימה
    expect(find.text('My Events'), findsOneWidget);

    // מצא את שדה החיפוש (TextField הראשון)
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, eventName);
    await tester.pumpAndSettle();

    final allEventTexts =
        find.byWidgetPredicate((w) => w is Text && w.data == eventName);
    // נוודא שיש לפחות אחד (כלומר האירוע מופיע, גם אם הוא מופיע גם בשדה החיפוש)
    expect(allEventTexts, findsAtLeastNWidgets(1),
        reason: 'האירוע לא נמצא אחרי חיפוש');
  });
}
