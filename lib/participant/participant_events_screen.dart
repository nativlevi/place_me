import 'package:flutter/material.dart';
import 'package:place_me/preferences_screen.dart';
import 'package:place_me/participant_final_screen.dart';

class ParticipantEventsScreen extends StatefulWidget {
  @override
  _ParticipantEventsScreenState createState() =>
      _ParticipantEventsScreenState();
}

class _ParticipantEventsScreenState extends State<ParticipantEventsScreen> {
  int _selectedIndex = 0;
  String searchQuery = '';

  // רשימת אירועים מורחבת
  final List<Map<String, String>> events = [
    {
      'title': 'Company Workshop',
      'date': 'January 15, 2025',
      'location': 'Room 101, Main Building',
      'type': 'Classroom/Workshop',
      'status': 'open',
    },
    {
      'title': 'Team Meeting',
      'date': 'January 20, 2025',
      'location': 'Conference Room A',
      'type': 'Conference/Professional Event',
      'status': 'closed',
    },
    {
      'title': 'Annual Gala',
      'date': 'February 5, 2025',
      'location': 'Grand Ballroom',
      'type': 'Family/Social Event',
      'status': 'open',
    },
    {
      'title': 'Meeting',
      'date': 'January 20, 2025',
      'location': 'Conference Room A',
      'type': 'Conference/Professional Event',
      'status': 'open',
    },
  ];

  // פונקציה להחזרת שם הקובץ של האייקון לפי סוג האירוע
  String getIconForEventType(String type) {
    switch (type) {
      case 'Classroom/Workshop':
        return 'images/classroom.png'; // אייקון לסדנה
      case 'Family/Social Event':
        return 'images/family_Event.png'; // אייקון לאירוע משפחתי
      case 'Conference/Professional Event':
        return 'images/Professional_Event.png'; // אייקון לכנס מקצועי
      default:
        return 'images/default_icon.png'; // אייקון ברירת מחדל
    }
  }

  List<Map<String, String>> getFilteredEvents(String status) {
    return events
        .where((event) =>
    event['status'] == status &&
        event['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFD0DDD0), // צבע רקע ירוק בהיר
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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
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
                prefixIcon: Icon(Icons.search, color: Color(0xFF3D3D3D)),
                hintText: 'Search all events',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),

            // רשימת אירועים
            Expanded(
              child: ListView.builder(
                itemCount: _selectedIndex == 0
                    ? getFilteredEvents('open').length +
                    getFilteredEvents('closed').length
                    : getFilteredEvents(
                    _selectedIndex == 1 ? 'open' : 'closed').length,
                itemBuilder: (context, index) {
                  var filteredEvents = _selectedIndex == 0
                      ? getFilteredEvents('open') + getFilteredEvents('closed')
                      : getFilteredEvents(
                      _selectedIndex == 1 ? 'open' : 'closed');

                  return GestureDetector(
                    onTap: () {
                      if (filteredEvents[index]['status'] == 'closed') {
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
                              eventType: filteredEvents[index]['type']!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // הצגת האייקון
                          Image.asset(
                            getIconForEventType(
                                filteredEvents[index]['type']!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filteredEvents[index]['title']!,
                                  style: TextStyle(
                                    fontFamily: 'Source Sans Pro',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3D3D3D),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: Color(0xFF727D73), size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      filteredEvents[index]['date']!,
                                      style: TextStyle(
                                        fontFamily: 'Source Sans Pro',
                                        fontSize: 16,
                                        color: Color(0xFF727D73),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Color(0xFF727D73), size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      filteredEvents[index]['location']!,
                                      style: TextStyle(
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
        selectedItemColor: Color(0xFF3D3D3D),
        unselectedItemColor: Colors.grey,
        items: [
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
