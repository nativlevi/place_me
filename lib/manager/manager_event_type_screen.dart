import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manager_login.dart'; // ודא שהנתיב נכון למסך ההתחברות

class ManagerEventTypeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFD0DDD0), // צבע רקע ירוק בהיר
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Event Type',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF727D73)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // נווט חזרה למסך ההתחברות – ניתן לשנות לפי המבנה שלך
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ManagerLoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // כותרת משנית
            Text(
              'Choose an Event Type',
              style: TextStyle(
                fontFamily: 'Source Sans Pro',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 20),
            // רשימת כרטיסים
            Expanded(
              child: ListView(
                children: [
                  buildEventCard(
                    context,
                    title: 'Classroom/Workshop',
                    description: 'Setup seating for educational events.',
                    iconPath: 'images/classroom.png',
                    onTap: () =>
                        navigateToNextScreen(context, 'Classroom/Workshop'),
                  ),
                  buildEventCard(
                    context,
                    title: 'Family/Social Event',
                    description:
                    'Organize seating for family or social gatherings.',
                    iconPath: 'images/family_Event.png',
                    onTap: () =>
                        navigateToNextScreen(context, 'Family/Social Event'),
                  ),
                  buildEventCard(
                    context,
                    title: 'Conference/Professional Event',
                    description: 'Plan seating for professional conferences.',
                    iconPath: 'images/Professional_Event.png',
                    onTap: () => navigateToNextScreen(
                        context, 'Conference/Professional'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEventCard(
      BuildContext context, {
        required String title,
        required String description,
        required String iconPath,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[200], // צבע רקע לכרטיס
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // אייקון מותאם לכל כרטיס
              Image.asset(
                iconPath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 15),
              // כותרת ותיאור הכרטיס
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 14,
                        color: Color(0xFF727D73),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // חץ לעבור למסך הבא
              Icon(Icons.arrow_forward_ios, color: Color(0xFF727D73)),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToNextScreen(BuildContext context, String eventType) {
    Navigator.pushNamed(
      context,
      '/event_details',
      arguments: {'eventType': eventType},
    );
  }
}
