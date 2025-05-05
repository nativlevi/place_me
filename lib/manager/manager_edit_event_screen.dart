import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManagerEditEventScreen extends StatefulWidget {
  final String eventId;

  ManagerEditEventScreen({required this.eventId});

  @override
  _ManagerEditEventScreenState createState() => _ManagerEditEventScreenState();
}

class _ManagerEditEventScreenState extends State<ManagerEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // שדות טקסט
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantNameController = TextEditingController();
  final _participantPhoneController = TextEditingController();

  // סוג האירוע
  String? _selectedEventType;
  final List<String> eventTypeOptions = [
    'Classroom/Workshop',
    'Family/Social Event',
    'Conference/Professional Event'
  ];

  // תאריך/שעה
  DateTime? _selectedDateTime;
  final _dateFormat = DateFormat('MMM d, yyyy, HH:mm');

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _participantNameController.dispose();
    _participantPhoneController.dispose();
    super.dispose();
  }

  // בחירת תאריך/שעה
  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime initialDate = _selectedDateTime ?? now;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // הוספת משתתף ידנית למסמך האירוע
  Future<void> _addParticipantManually(DocumentReference eventDocRef) async {
    final name = _participantNameController.text.trim();
    final phone = _participantPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both name and phone number')),
      );
      return;
    }

    // שמירה בתת-אוסף "participants"
    await eventDocRef.collection('manualParticipants').add({
      'name': name,
      'phone': phone,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // איפוס השדות
    _participantNameController.clear();
    _participantPhoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // הפניה למסמך האירוע בתת-אוסף managers/{uid}/events/{eventId}
    final docRef = FirebaseFirestore.instance
        .collection('managers')
        .doc(currentUser!.uid)
        .collection('events')
        .doc(widget.eventId);

    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Event',
          style: TextStyle(
            fontFamily: 'Source Sans Pro',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return Center(child: Text('Event does not exist'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // אתחול השדות
          if (_eventNameController.text.isEmpty) {
            _eventNameController.text = data['eventName'] ?? '';
          }
          if (_locationController.text.isEmpty) {
            _locationController.text = data['location'] ?? '';
          }
          if (_selectedEventType == null) {
            _selectedEventType = data['eventType'] ?? eventTypeOptions.first;
          }
          if (_selectedDateTime == null) {
            final dateString = data['date'] as String?;
            if (dateString != null && dateString.isNotEmpty) {
              try {
                _selectedDateTime = DateTime.parse(dateString);
              } catch (e) {
                _selectedDateTime = DateTime.now();
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name (pill style)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: TextFormField(
                        controller: _eventNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter Event Name',
                          hintStyle: TextStyle(fontFamily: 'Source Sans Pro'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Event Type (pill style dropdown)
                    Text(
                      'Event Type:',
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 16,
                        color: Color(0xFF727D73),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedEventType,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: eventTypeOptions.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontFamily: 'Source Sans Pro',
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedEventType = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Date/Time row (pill + icon)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: Text(
                              _selectedDateTime == null
                                  ? 'No Date/Time selected'
                                  : _dateFormat.format(_selectedDateTime!),
                              style: TextStyle(
                                fontFamily: 'Source Sans Pro',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.calendar_today, color: Color(0xFF3D3D3D)),
                            onPressed: _pickDateTime,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Location (pill style)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'Enter Location',
                          hintStyle: TextStyle(fontFamily: 'Source Sans Pro'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Add participants row
                    Text(
                      'Add participants manually:',
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 16,
                        color: Color(0xFF727D73),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        // Name pill
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Color(0xFF3D3D3D)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _participantNameController,
                                    decoration: InputDecoration(
                                      hintText: 'Name',
                                      hintStyle: TextStyle(fontFamily: 'Source Sans Pro'),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Phone pill
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _participantPhoneController,
                                    decoration: InputDecoration(
                                      hintText: 'Phone',
                                      hintStyle: TextStyle(fontFamily: 'Source Sans Pro'),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Plus button
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF3D3D3D),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: () async {
                              // הוספת המשתתף ישירות לתת-אוסף "participants"
                              final name = _participantNameController.text.trim();
                              final phone = _participantPhoneController.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Please enter both name and phone number')),
                                );
                                return;
                              }
                              await docRef.collection('participants').add({
                                'name': name,
                                'phone': phone,
                                'addedAt': FieldValue.serverTimestamp(),
                              });
                              // איפוס השדות
                              _participantNameController.clear();
                              _participantPhoneController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),

                    // Save Changes button
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final updateData = <String, dynamic>{};
                          if (_eventNameController.text.trim().isNotEmpty) {
                            updateData['eventName'] = _eventNameController.text.trim();
                          }
                          if (_selectedEventType != null && _selectedEventType!.isNotEmpty) {
                            updateData['eventType'] = _selectedEventType;
                          }
                          if (_locationController.text.trim().isNotEmpty) {
                            updateData['location'] = _locationController.text.trim();
                          }
                          if (_selectedDateTime != null) {
                            updateData['date'] = _selectedDateTime!.toIso8601String();
                          }
                          await docRef.update(updateData);

                          final String? eventDocId = data['ref'];
                          if (eventDocId != null && eventDocId.isNotEmpty) {
                            final eventDocRef = FirebaseFirestore.instance
                                .collection('events')
                                .doc(eventDocId);
                            await eventDocRef.update(updateData);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Event updated')),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: 'Source Sans Pro',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
