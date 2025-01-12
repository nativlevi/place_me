import 'package:flutter/material.dart';
import 'package:place_me/preferences_screen.dart';
import 'package:place_me/participant_final_screen.dart';

class ParticipantEventsScreen extends StatefulWidget {
  @override
  _ParticipantEventsScreenState createState() => _ParticipantEventsScreenState();
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
      'color': '#f8d37d',
      'status': 'open',
    },
    {
      'title': 'Team Meeting',
      'date': 'January 20, 2025',
      'location': 'Conference Room A',
      'type': 'Conference/Professional Event',
      'color': '#d6e7f3',
      'status': 'closed',
    },
    {
      'title': 'Annual Gala',
      'date': 'February 5, 2025',
      'location': 'Grand Ballroom',
      'type': 'Family/Social Event',
      'color': '#EFD29E',
      'status': 'open',
    },
    {
      'title': 'Meeting',
      'date': 'January 20, 2025',
      'location': 'Conference Room A',
      'type': 'Conference/Professional Event',
      'color': '#d6e7f3',
      'status': 'open',
    },
    // הוסף עוד אירועים בהתאם לצורך
  ];

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
      backgroundColor: Color(0xFFF8F4EF),
      appBar: AppBar(
        title: Text(
          'Hi Friend,',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _selectedIndex == 0
          ? buildEventList(context, 'all')
          : _selectedIndex == 1
          ? buildEventList(context, 'open')
          : buildEventList(context, 'closed'),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
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

  Widget buildEventList(BuildContext context, String status) {
    List<Map<String, String>> filteredEvents = status == 'all'
        ? getFilteredEvents('open') + getFilteredEvents('closed')
        : getFilteredEvents(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search all events',
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
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
                      color: Color(int.parse(
                          filteredEvents[index]['color']!.substring(1, 7),
                          radix: 16) +
                          0xFF000000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filteredEvents[index]['title']!,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.black54, size: 16),
                            SizedBox(width: 5),
                            Text(
                              filteredEvents[index]['date']!,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.black54, size: 16),
                            SizedBox(width: 5),
                            Text(
                              filteredEvents[index]['location']!,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
    );
  }
}
