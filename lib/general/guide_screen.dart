import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manager Guide',
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
              const Text(
                'Manager Guide',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '• Select the event type (Classroom/Workshop, Family/Social, Professional)\n'
                    '• Enter a clear name, date & time, and exact location\n'
                    '• Upload participants via CSV or add manually.\n'
                    '  Ensure the file uses a ".csv" extension and that each phone number is prefixed with an apostrophe (the \' key on your keyboard) so Excel recognizes it as text.\n'
                    '  Columns must appear in this exact order: name, phone, mail.As in the example below ↓',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  'images/csv_exm.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Interactive Seating Editor',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '• Drag and drop tables, chairs, and features onto the layout.\n'
                    '• Use the floating menu to add, rotate, duplicate, or group items.\n'
                    '• Tap an existing table to change its shape options.\n'
                    '• Tap an existing chair to edit its features based on the event type.\n'
                    '• Long-press any object to delete it.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  'images/csv_exm.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Finalize Participant Preferences',
                style: TextStyle(
                  fontFamily: 'Source Sans Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '• Review and confirm attendee preferences.\n'
                    '• Tap the blue table-icon button to manually close registrations and lock in choices (events automatically close 48 hours before start).\n'
                    '• Tap an existing event to edit all details.\n'
                    '• Delete an event at any time by tapping the trash-can icon.\n'
                    '• Once closed, participants can no longer submit preferences.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF727D73),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  'images/csv_exm.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}