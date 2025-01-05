import 'package:flutter/material.dart';
import 'package:place_me/preferences_screen.dart';
import 'package:place_me/preferences_screen.dart';

class ParticipantEventsScreen extends StatelessWidget {
  // רשימת אירועים לדוגמה
  final List<Map<String, String>> events = [
    {
      'title': 'Company Workshop',
      'date': 'January 15, 2025',
      'location': 'Room 101, Main Building',
      'type': 'Classroom/Workshop'
    },
    {
      'title': 'Team Meeting',
      'date': 'January 20, 2025',
      'location': 'Conference Room A',
      'type': 'Conference/Professional Event'
    },
    {
      'title': 'Annual Gala',
      'date': 'February 5, 2025',
      'location': 'Grand Ballroom',
      'type': 'Family/Social Event'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Events'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.event,
                color: Colors.teal,
              ),
              title: Text(
                events[index]['title']!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  '${events[index]['date']} \nLocation: ${events[index]['location']}'),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeatingPreferencesScreen(
                      eventType: events[index]['type']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
