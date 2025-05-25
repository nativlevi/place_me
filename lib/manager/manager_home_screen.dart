import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import 'manager_event_type_screen.dart';
import 'manager_edit_event_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  @override
  _ManagerHomeScreenState createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy HH:mm');

  String _sortOption = 'תאריך קרוב';
  final List<String> _sortOptions = ['תאריך קרוב', 'שם (א-ב)'];

  // 🔍 משתנה חיפוש
  String _searchQuery = '';

  String getIconForEventType(String type) {
    switch (type) {
      case 'Classroom/Workshop':
        return 'images/classroom.png';
      case 'Family/Social Event':
        return 'images/family_Event.png';
      case 'Conference/Professional Event':
        return 'images/Professional_Event.png';
      default:
        return 'images/Professional_Event.png';
    }
  }

  List<QueryDocumentSnapshot> sortDocs(
      List<QueryDocumentSnapshot> docs, String sortBy) {
    if (sortBy == 'שם (א-ב)') {
      docs.sort((a, b) {
        final aName = (a.data() as Map)['eventName'] ?? '';
        final bName = (b.data() as Map)['eventName'] ?? '';
        return aName.toString().compareTo(bName.toString());
      });
    } else {
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = DateTime.tryParse(aData['date'] ?? '') ?? DateTime(2100);
        final bDate = DateTime.tryParse(bData['date'] ?? '') ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });
    }
    return docs;
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

    final eventsRef = FirebaseFirestore.instance.collection('events');

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
          PopupMenuButton<String>(
            onSelected: (String newValue) {
              setState(() {
                _sortOption = newValue;
              });
            },
            icon: Icon(Icons.sort, color: Color(0xFF727D73)),
            itemBuilder: (BuildContext context) {
              return _sortOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontFamily: 'Source Sans Pro',
                      fontWeight: choice == _sortOption
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: choice == _sortOption
                          ? Color(0xFF3D3D3D)
                          : Colors.black54,
                    ),
                  ),
                );
              }).toList();
            },
          ),
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
        child: Column(
          children: [
            // 🔍 TextField לחיפוש
            TextField(
              decoration: InputDecoration(
                hintText: 'חפש אירוע לפי שם או סוג',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => setState(() {
                _searchQuery = val.trim().toLowerCase();
              }),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: managerEventsRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                  final sorted = sortDocs(List.from(docs), _sortOption);

                  final filtered = sorted.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name =
                        (data['eventName'] ?? '').toString().toLowerCase();
                    final type =
                        (data['eventType'] ?? '').toString().toLowerCase();
                    return _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        type.contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final eventDocId = data['ref'] ?? '';
                      final eventName = data['eventName'] ?? 'No Event Name';
                      final eventType = data['eventType'] ?? 'No Event Type';
                      final location = data['location'] ?? 'No Location';
                      final rawDate = (data['date'] as String?)?.trim();
                      final rawTime = (data['time'] as String?)?.trim();

                      String displayDateTime = 'No Date/Time';

                      if (rawDate != null && rawDate.isNotEmpty) {
                        final dateOnly = rawDate.split('T').first;
                        final timeOnly = (rawTime != null && rawTime.isNotEmpty)
                            ? rawTime
                            : '00:00';
                        final combined = '$dateOnly $timeOnly';
                        try {
                          final parsed = DateFormat('yyyy-MM-dd HH:mm')
                              .parseStrict(combined);
                          displayDateTime =
                              DateFormat('MMM d, yyyy HH:mm').format(parsed);
                        } catch (e) {
                          print('❌ Parse failed for "$combined": $e');
                          displayDateTime = 'Invalid date/time';
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ManagerEditEventScreen(eventId: eventDocId),
                            ),
                          );
                        },
                        child: _buildEventContainer(
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
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Delete Event'),
                                      content: Text(
                                          'Are you sure you want to delete this event?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(eventDocId)
                                        .delete();

                                    await FirebaseFirestore.instance
                                        .collection('managers')
                                        .doc(currentUser!.uid)
                                        .collection('events')
                                        .doc(doc.id)
                                        .delete();

                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child('events/$eventDocId');
                                    final ListResult items =
                                        await storageRef.listAll();
                                    for (var item in items.items) {
                                      await item.delete();
                                    }
                                    for (var prefix in items.prefixes) {
                                      final subItems = await prefix.listAll();
                                      for (var subItem in subItems.items) {
                                        await subItem.delete();
                                      }
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Event deleted')));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error deleting event: $e')));
                                  }
                                },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF3D3D3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ManagerEventTypeScreen()));
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
