import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ManagerEditEventScreen extends StatefulWidget {
  final String eventId;

  ManagerEditEventScreen({required this.eventId});

  @override
  _ManagerEditEventScreenState createState() => _ManagerEditEventScreenState();
}

class _ManagerEditEventScreenState extends State<ManagerEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantNameController = TextEditingController();
  final _participantPhoneController = TextEditingController();

  String? _selectedEventType;
  final List<String> eventTypeOptions = [
    'Classroom/Workshop',
    'Family/Social Event',
    'Conference/Professional Event'
  ];

  DateTime? _selectedDateTime;
  final _dateFormat = DateFormat('MMM d, yyyy, HH:mm');

  final currentUser = FirebaseAuth.instance.currentUser;

  List<String> _imageUrls = [];
  List<String> _imageUrlsToRemove = [];
  List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _participants = [];

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _participantNameController.dispose();
    _participantPhoneController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
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
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists)
            return Center(child: Text('Event does not exist'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final eventDocId = data['ref'];

          // INIT
          if (_eventNameController.text.isEmpty)
            _eventNameController.text = data['eventName'] ?? '';
          if (_locationController.text.isEmpty)
            _locationController.text = data['location'] ?? '';
          if (_selectedEventType == null)
            _selectedEventType = data['eventType'] ?? eventTypeOptions.first;
          final rawDate = data['date'] as String?;
          final rawTime = data['time'] as String?; // תופס גם את השעה
          if (_selectedDateTime == null && rawDate != null) {
            try {
              // אם אין time, נניח 00:00
              final timePart =
                  (rawTime != null && rawTime.isNotEmpty) ? rawTime : '00:00';
              // נבנה מחרוזת כמו "2025-05-23 14:30"
              final combined = '$rawDate $timePart';
              _selectedDateTime =
                  DateFormat('yyyy-MM-dd HH:mm').parseStrict(combined);
            } catch (e) {
              // נ fallback רק ל־date בלי שעה
              _selectedDateTime = DateTime.parse(rawDate);
            }
          }
          if (_imageUrls.isEmpty && data['imageUrls'] != null) {
            _imageUrls = List<String>.from(data['imageUrls']);
          }

          // Load participants once
          if (_participants.isEmpty && eventDocId != null) {
            FirebaseFirestore.instance
                .collection('events')
                .doc(eventDocId)
                .collection('manualParticipants')
                .get()
                .then((snap) {
              setState(() {
                _participants = snap.docs.map((doc) {
                  final p = doc.data();
                  p['docId'] = doc.id;
                  return p;
                }).toList();
              });
            });
          }

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Enter Event Name', _eventNameController),
                    SizedBox(height: 16),
                    _buildDropdown(),
                    SizedBox(height: 16),
                    _buildDatePicker(),
                    SizedBox(height: 16),
                    _buildTextField('Enter Location', _locationController),
                    SizedBox(height: 16),
                    Text('Event Images:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        ..._imageUrls.map((url) => Stack(
                              children: [
                                Image.network(url, width: 100, height: 100),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _imageUrls.remove(url);
                                      _imageUrlsToRemove.add(url);
                                    }),
                                    child: Icon(Icons.close, color: Colors.red),
                                  ),
                                ),
                              ],
                            )),

                        // Show newly added images
                        ..._newImages.map((f) =>
                            Image.file(File(f.path), width: 100, height: 100)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickMultiImage();
                        if (picked != null) {
                          setState(() => _newImages.addAll(picked));
                        }
                      },
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Add Images'),
                    ),
                    SizedBox(height: 16),
                    Text('Add participants manually:'),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _buildIconInput(_participantNameController,
                                Icons.person, 'Name')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _buildIconInput(_participantPhoneController,
                                Icons.phone, 'Phone')),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF3D3D3D),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: () async {
                              final name =
                                  _participantNameController.text.trim();
                              final phone =
                                  _participantPhoneController.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please enter both name and phone number')),
                                );
                                return;
                              }
                              final eventRef = FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventDocId);
                              await eventRef.collection('participants').add({
                                'name': name,
                                'phone': phone,
                                'addedAt': FieldValue.serverTimestamp(),
                              });

                              await eventRef.update({
                                'allowedParticipants':
                                    FieldValue.arrayUnion([phone]),
                              });

                              _participantNameController.clear();
                              _participantPhoneController.clear();
                            },
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 10),

                    // Display participants list with delete button
                    ..._participants.map((p) => ListTile(
                          title: Text(p['name']),
                          subtitle: Text(p['phone']),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventDocId)
                                  .collection('participants')
                                  .doc(p['docId'])
                                  .delete();

                              setState(() {
                                _participants.remove(p);
                              });
                            },
                          ),
                        )),

                    SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final updateData = <String, dynamic>{
                            'eventName': _eventNameController.text.trim(),
                            'eventType': _selectedEventType,
                            'location': _locationController.text.trim(),
                            'date': _selectedDateTime != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_selectedDateTime!)
                                : null,
                          };

                          if (_selectedDateTime != null) {
                            final formattedTime =
                                DateFormat('HH:mm').format(_selectedDateTime!);
                            updateData['time'] = formattedTime;
                          }

                          await docRef.update(updateData);

                          final eventRef = FirebaseFirestore.instance
                              .collection('events')
                              .doc(eventDocId);

                          // Delete removed images
                          for (var url in _imageUrlsToRemove) {
                            try {
                              final ref =
                                  FirebaseStorage.instance.refFromURL(url);
                              await ref.delete();
                            } catch (_) {}
                          }

                          // Upload new images
                          final newUrls = <String>[];
                          for (var file in _newImages) {
                            final filename =
                                '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                            final ref = FirebaseStorage.instance
                                .ref('events/$eventDocId/images/$filename');
                            await ref.putFile(File(file.path));
                            final url = await ref.getDownloadURL();
                            newUrls.add(url);
                          }

                          final updatedImages = [..._imageUrls, ...newUrls];
                          await eventRef.update(
                              {...updateData, 'imageUrls': updatedImages});

                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Event updated')));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 100),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('Save Changes',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
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

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Widget _buildIconInput(
      TextEditingController controller, IconData icon, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF3D3D3D)),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration:
                  InputDecoration(hintText: hint, border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: DropdownButtonFormField<String>(
        value: _selectedEventType,
        decoration: InputDecoration(border: InputBorder.none),
        items: eventTypeOptions
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (val) => setState(() => _selectedEventType = val),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Text(
              _selectedDateTime == null
                  ? 'No Date/Time selected'
                  : _dateFormat.format(_selectedDateTime!),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        SizedBox(width: 10),
        Container(
          decoration:
              BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(Icons.calendar_today, color: Color(0xFF3D3D3D)),
            onPressed: _pickDateTime,
          ),
        ),
      ],
    );
  }
}
