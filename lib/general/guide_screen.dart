import 'package:flutter/material.dart';

import 'Video_Example.dart';

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDFAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PlaceMe Guide',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        leading: const BackButton(color: Color(0xFF3D3D3D)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Manager Guide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D3D3D),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Container(
                  height: 2,
                  width: 120,
                  color: Color(0xFF727D73),
                ),
              ),
              SizedBox(height: 24),
              const Text(
                'Create an event',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                '''• Select the event type (Classroom/Workshop, Family/Social, Professional)
• Enter a clear name, date & time, and exact location
• Upload participants via CSV/XLSX or add manually.
Ensure the file uses a ".csv/.xlsx" extension and that each phone number is prefixed with an apostrophe (the ' key on your keyboard) so Excel recognizes it as text.
Columns must appear in this exact order: name, phone, mail. As in the example below ↓''',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/1.b.jpeg',
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 10), // רווח בין התמונות
                  Image.asset(
                    'assets/1.c.png',
                    width: 170,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              SizedBox(height: 24),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
                indent: 30,        // מרחק מהצד השמאלי
                endIndent: 30,     // מרחק מהצד הימני
              ),              SizedBox(height: 24),

              const Text(
                'Interactive Seating Editor',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                '''• Drag and drop tables, chairs, and features onto the layout.
• Use the floating menu to add, rotate, duplicate, or group items.
• Tap an existing table to change its shape options.
• Tap an existing chair to edit its features based on the event type.
• Long-press any object to delete it.''',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              VideoWidget(),
              SizedBox(height: 24),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
                indent: 30,        // מרחק מהצד השמאלי
                endIndent: 30,     // מרחק מהצד הימני
              ),
              SizedBox(height: 24),

              const Text(
                'Finalize Participant Preferences',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                '''
• Tap the grey table-icon button to manually close registrations and lock in choices (events automatically close 48 hours before start).
• Tap an existing event to edit all details.
• Delete an event at any time by tapping the trash-can icon.
• Once closed, participants can no longer submit preferences.''',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/2.a.jpeg',
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 16), // רווח בין התמונות
                  Image.asset(
                    'assets/2.b.jpeg',
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              SizedBox(height: 24),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
                indent: 30,        // מרחק מהצד השמאלי
                endIndent: 30,     // מרחק מהצד הימני
              ),
              SizedBox(height: 24),
              Center(
                child: Text(
                  'Participant Guide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D3D3D),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Container(
                  height: 2,
                  width: 120,
                  color: Color(0xFF727D73),
                ),
              ),
              SizedBox(height: 24),
              const Text(
                'Event Selection Screen',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                '''• Browse all events you're invited to, including open and closed ones.
• Tap an open event to submit your seating preferences.
• Tap a closed event to view your assigned seat.
• Use the search bar to quickly find an event by name.
• Switch between All, Open, and Closed tabs at the bottom.
• Tap the logout icon in the top-right corner to sign out.''',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Image.asset(
                  'assets/3.a.jpeg',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 24),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
                indent: 30,        // מרחק מהצד השמאלי
                endIndent: 30,     // מרחק מהצד הימני
              ),              SizedBox(height: 24),

              const Text(
                'Seating Preferences Screen',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                '''• Choose who you want to sit next to, and who you prefer not to sit near.
• Toggle seating preferences like "near the stage" or "away from the speakers."
• Decide whether your name appears in others’ preference lists.
• Your preferences are saved when you tap the SAVE button.
• Previously saved preferences load automatically when revisiting.
• Preferences must be submitted at least 48 hours before the event starts.''',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Image.asset(
                  'assets/3.b.jpeg',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 24),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
                indent: 30,        // מרחק מהצד השמאלי
                endIndent: 30,     // מרחק מהצד הימני
              ),
              SizedBox(height: 24),

              const Text(
                'Final Seating View',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(height: 16),
              const Text(
                '''• View your final assigned seat on the event map.
• Your seat is highlighted based on your phone number.
• This screen becomes available only after the event is closed.
• No changes can be made once seating is finalized.''',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Image.asset(
                  'assets/3.c.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 24),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
                indent: 30,        // מרחק מהצד השמאלי
                endIndent: 30,     // מרחק מהצד הימני
              ),

            ],
          ),
        ),
      ),
    );
  }
}
