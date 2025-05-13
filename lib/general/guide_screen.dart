import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  final String section;

  GuideScreen({required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFD0DDD0), // Light green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'User Guide',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              'Welcome to the User Guide',
              style: TextStyle(
                fontFamily: 'Source Sans Pro',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 20),
            // Guide text
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''
This guide provides detailed instructions on using the app:
1. Logging in: Click the "Login" button on the home screen.
2. Creating events: Create new events by clicking "Create Event".
3. Adding participants: Upload participant lists in CSV or Excel format.
4. Managing seating preferences: Set your seating preferences based on the event type.
                  

                  Thank you for using our app!
                  ''',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Display specific section
            if (section == 'Upload Participant List')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload Participant List Guidelines', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('1. Ensure your file is in CSV format.', style: TextStyle(fontSize: 16)),
                  Text('2. The first row should contain: name, phone.', style: TextStyle(fontSize: 16)),
                  Text('3. Ensure there are no empty rows.', style: TextStyle(fontSize: 16)),
                  Text('4. Avoid special characters in phone numbers.', style: TextStyle(fontSize: 16)),
                ],
              ),
            SizedBox(height: 20),
            // Back button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D3D3D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
