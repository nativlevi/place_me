import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'participant_final_screen.dart';
import 'preferences_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ParticipantEventsScreen extends StatefulWidget {
  final String phone;

  const ParticipantEventsScreen({
    Key? key,
    required this.phone,
  }) : super(key: key);

  @override
  _ParticipantEventsScreenState createState() =>
      _ParticipantEventsScreenState();
}

class _ParticipantEventsScreenState extends State<ParticipantEventsScreen> {
  int _selectedIndex = 0;
  String searchQuery = '';
  String? participantPhone;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    // נניח שהמשתמש נרשם עם מספר טלפון, אז:
    participantPhone = currentUser?.phoneNumber;
  }

  // מעבר בין לשוניות תחתית המסך (All/Open/Closed)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // פונקציה שמחזירה את שם האייקון לפי סוג האירוע
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
    final normalizedPhone = widget.phone.startsWith('+')
        ? widget.phone
        : '+972${widget.phone.substring(1)}';
    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0), // רקע ירוק בהיר
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hi Friend,',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF727D73)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // שדה חיפוש
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3D3D3D)),
                hintText: 'Search all events',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // כאן נשתמש ב-StreamBuilder כדי להאזין לשינויים באוסף האירועים
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('allowedParticipants', arrayContains: normalizedPhone)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}"),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // המרת המסמכים לרשימה
                  final docs = snapshot.data!.docs;

                  // המרה למבנה מפה
                  final allEvents = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // נוסיף גם את ה-ID של המסמך (eventId) אם נרצה
                    data['id'] = doc.id;
                    return data;
                  }).toList();

                  // סינון לפי searchQuery
                  final filteredBySearch = allEvents.where((event) {
                    final title = (event['eventName'] ?? '').toString();
                    return title
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  }).toList();

                  // חלוקה לפי status = 'open' או 'closed'
                  final openEvents = filteredBySearch
                      .where((e) => (e['status'] ?? 'open') == 'open')
                      .toList();
                  final closedEvents = filteredBySearch
                      .where((e) => (e['status'] ?? 'open') == 'closed')
                      .toList();

                  // לפי הלשונית הנוכחית (_selectedIndex)
                  // 0 => All, 1 => Open, 2 => Closed
                  List<Map<String, dynamic>> finalList;
                  if (_selectedIndex == 0) {
                    finalList = [...openEvents, ...closedEvents];
                  } else if (_selectedIndex == 1) {
                    finalList = openEvents;
                  } else {
                    finalList = closedEvents;
                  }

                  if (finalList.isEmpty) {
                    return const Center(child: Text("No events found"));
                  }

                  return ListView.builder(
                    itemCount: finalList.length,
                    itemBuilder: (context, index) {
                      final event = finalList[index];
                      final eventName = event['eventName'] ?? 'Unnamed Event';
                      String rawDateString = event['date'] ?? '';
                      String rawTimeString = event['time'] ?? '';
                      DateTime parsedDate = DateTime.parse(rawDateString);
                      String formattedDate =
                          DateFormat('MMM d, yyyy').format(parsedDate);
                      String formattedTime;
                      try {
                        final parts = rawTimeString.split(':');
                        final h = int.parse(parts[0]);
                        final m = int.parse(parts[1]);
                        final dt = DateTime(0, 0, 0, h, m);
                        formattedTime = DateFormat('HH:mm').format(dt);
                      } catch (_) {
                        formattedTime = '00:00';
                      }
                      final location = event['location'] ?? '';
                      final eventType = event['eventType'] ?? '';
                      final status = event['status'] ?? 'open';

                      return GestureDetector(
                        onTap: () {
                          if (status == 'closed') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParticipantFinalScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeatingPreferencesScreen(
                                    eventId: event['id'],
                                    eventType: eventType,
                                    phone: widget.phone, // <-- העברת ה-phone
                                    eventName: event['eventName']),
                              ),
                            );
                          }
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
                              // הצגת האייקון
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
                                          '$formattedDate   $formattedTime',
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
              ),
            ),
          ],
        ),
      ),

      // תחתית המסך (ניווט)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3D3D3D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'All Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Open Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: 'Closed Events',
          ),
        ],
      ),
    );
  }
}
