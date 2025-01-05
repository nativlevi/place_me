import 'package:flutter/material.dart';

class ManagerEventTypeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFefefef),
      appBar: AppBar(
        title: Text('Select Event Type'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an Event Type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  buildEventCard(
                    context,
                    title: 'Classroom/Workshop',
                    description: 'Setup seating for educational events.',
                    iconPath: 'images/classroom_icon.jpg',
                    onTap: () =>
                        navigateToNextScreen(context, 'Classroom/Workshop'),
                  ),
                  buildEventCard(
                    context,
                    title: 'Family/Social Event',
                    description:
                        'Organize seating for family or social gatherings.',
                    iconPath: 'images/social_event_icon.png',
                    onTap: () =>
                        navigateToNextScreen(context, 'Family/Social Event'),
                  ),
                  buildEventCard(
                    context,
                    title: 'Conference/Professional Event',
                    description: 'Plan seating for professional conferences.',
                    iconPath: 'images/conference_icon.png',
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
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Image.asset(
                iconPath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              SizedBox(width: 15),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToNextScreen(BuildContext context, String eventType) {
    Navigator.pushNamed(context, '/event_details',
        arguments: {'eventType': eventType});
  }
}
