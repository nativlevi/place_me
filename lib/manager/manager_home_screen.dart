import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../general/seating_service.dart';
import 'manager_event_type_screen.dart';
import 'manager_edit_event_screen.dart';
import 'manager_final_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  @override
  _ManagerHomeScreenState createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy HH:mm');

  String _sortOption = 'Nearest Date';
  final List<String> _sortOptions = ['Nearest Date', 'Name (A–Z)'];

  // 🔍 משתנה חיפוש
  String _searchQuery = '';

  String getIconForEventType(String type) {
    switch (type) {
      case 'Classroom/Workshop':
        return 'assets/classroom.png';
      case 'Family/Social Event':
        return 'assets/family_Event.png';
      case 'Conference/Professional Event':
        return 'assets/Professional_Event.png';
      default:
        return 'assets/Professional_Event.png';
    }
  }

  Future<void> _generateSeating(String eventId) async {
    final participantsSnap = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .get();

    final participants = participantsSnap.docs;
    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אין משתתפים, אנא הוסף משתתפים לפני יצירת סידור ישיבה')),
      );
      return;
    }

    // רק אם יש משתתפים ממשיכים
    try {
      final seatingService = SeatingService();
      await seatingService.generateSmartSeating(eventId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Seating arrangement generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error generating seating: $e')),
      );
    }
  }



  List<QueryDocumentSnapshot> sortDocs(
      List<QueryDocumentSnapshot> docs, String sortBy) {
    if (sortBy == 'Name (A–Z)') {
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
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String newValue) => setState(() => _sortOption = newValue),
            icon: Icon(Icons.sort, color: Color(0xFF727D73)),
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white.withOpacity(0.95),
            elevation: 6,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Nearest Date',
                child: Text(
                  'Nearest Date',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontWeight: _sortOption == 'Nearest Date' ? FontWeight.bold : FontWeight.normal,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'Name (A–Z)',
                child: Text(
                  'Name (A–Z)',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontWeight: _sortOption == 'Name (A–Z)' ? FontWeight.bold : FontWeight.normal,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
            ],
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
                hintText: 'Search events by name or type',
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
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.table_chart, color: const Color(0xFF727D73)),
                                    tooltip: 'Generate Seating',
                                    onPressed: () async {
                                      final proceed = await showDialog<bool>(
                                        context: context,
                                        barrierColor: Colors.black26,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.white.withOpacity(0.95),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Generate Seating?',
                                                  style: TextStyle(
                                                    fontFamily: 'Source Sans Pro',
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3D3D3D),
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Text(
                                                  'Are you sure you want to automatically generate the seating arrangement?',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFF727D73),
                                                    height: 1.4,
                                                  ),
                                                ),
                                                SizedBox(height: 24),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Color(0xFF6E6A8E),
                                                        textStyle: TextStyle(
                                                          fontSize: 16,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                      child: Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0xFF3D3D3D),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                      ),
                                                      child: Text(
                                                        'Generate',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );

                                      if (proceed == true) {
                                        try {
                                          await SeatingService().generateSmartSeating(eventDocId);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ManagerFinalScreen(eventId: eventDocId),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('❌ Error generating seating: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),

                                  SizedBox(height: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFF3D3D3D)),
                                    tooltip: 'Delete Event',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        barrierColor: Colors.black26,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.white.withOpacity(0.95),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Delete Event',
                                                  style: TextStyle(
                                                    fontFamily: 'Source Sans Pro',
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3D3D3D),
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Text(
                                                  'Are you sure you want to delete this event?',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFF727D73),
                                                    height: 1.4,
                                                  ),
                                                ),
                                                SizedBox(height: 24),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Color(0xFF6E6A8E),
                                                        textStyle: TextStyle(
                                                          fontSize: 16,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                      child: Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0xFFB33E5A),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                      ),
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );

                                      if (confirm != true) return;

                                      try {
                                        // Remove Firestore document
                                        await FirebaseFirestore.instance
                                            .collection('events')
                                            .doc(eventDocId)
                                            .delete();

                                        // Remove manager's reference
                                        await FirebaseFirestore.instance
                                            .collection('managers')
                                            .doc(currentUser!.uid)
                                            .collection('events')
                                            .doc(doc.id)
                                            .delete();

                                        // Delete any stored files in Firebase Storage
                                        final storageRef = FirebaseStorage.instance.ref('events/$eventDocId');
                                        final items = await storageRef.listAll();
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
                                          SnackBar(content: Text('✅ Event deleted successfully')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('❌ Error deleting event: $e')),
                                        );
                                      }
                                    },
                                  ),

                                ],
                              )

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
