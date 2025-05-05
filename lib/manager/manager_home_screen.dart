import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'manager_event_type_screen.dart';
import 'manager_edit_event_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  @override
  _ManagerHomeScreenState createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // פורמט שמציג תאריך ושעה
  final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy HH:mm');

  String getIconForEventType(String type) {
    switch (type) {
      case 'Classroom/Workshop':
        return 'images/classroom.png';
      case 'Family/Social Event':
        return 'images/family_Event.png';
      case 'Conference/Professional Event':
        return 'images/Professional_Event.png';
      default:
        return 'images/default_icon.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('No user is currently logged in')),
      );
    }

    final managerEventsRef = FirebaseFirestore.instance
        .collection('managers')
        .doc(currentUser!.uid)
        .collection('events');

    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Events',
          style: TextStyle(
            fontFamily: 'Source Sans Pro',
            color: Color(0xFF727D73),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF727D73)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: managerEventsRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return Center(child: Text('No events found'));

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final docSnapshot = docs[index];
                final data = docSnapshot.data() as Map<String, dynamic>;
                final eventDocId = data['ref'] as String?;
                if (eventDocId == null || eventDocId.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('No reference to event'),
                  );
                }

                final eventRef = FirebaseFirestore.instance.collection('events').doc(eventDocId);

                return StreamBuilder<DocumentSnapshot>(
                  stream: eventRef.snapshots(),
                  builder: (context, eventSnapshot) {
                    if (!eventSnapshot.hasData) return Center(child: CircularProgressIndicator());
                    final eventDoc = eventSnapshot.data;
                    if (eventDoc == null || !eventDoc.exists) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Event document not found'),
                      );
                    }

                    final eventData = eventDoc.data() as Map<String, dynamic>;
                    final eventName = eventData['eventName'] ?? 'No Event Name';
                    final eventType = eventData['eventType'] ?? 'No Event Type';
                    final location = eventData['location'] ?? 'No Location';

                    // שליפת המחרוזת date
                    final dateString = eventData['date'] as String?;
                    String displayDateTime = 'No Date/Time';
                    if (dateString != null && dateString.isNotEmpty) {
                      try {
                        final parsed = DateTime.parse(dateString);
                        displayDateTime = _dateTimeFormat.format(parsed);
                      } catch (_) {
                        displayDateTime = 'Invalid date';
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManagerEditEventScreen(eventId: eventDoc.id),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              getIconForEventType(eventType),
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eventName,
                                    style: const TextStyle(
                                      fontFamily: 'Source Sans Pro',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3D3D3D),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF727D73), size: 16),
                                      const SizedBox(width: 5),
                                      Text(
                                        displayDateTime,
                                        style: const TextStyle(
                                          fontFamily: 'Source Sans Pro',
                                          fontSize: 16,
                                          color: Color(0xFF727D73),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Color(0xFF727D73), size: 16),
                                      const SizedBox(width: 5),
                                      Text(
                                        location,
                                        style: const TextStyle(
                                          fontFamily: 'Source Sans Pro',
                                          fontSize: 16,
                                          color: Color(0xFF727D73),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF3D3D3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ManagerEventTypeScreen()),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
