import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:charset_converter/charset_converter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../general/event_helpers.dart';

class ManagerEditEventScreen extends StatefulWidget {
  final String eventId;
  ManagerEditEventScreen({required this.eventId});

  @override
  _ManagerEditEventScreenState createState() => _ManagerEditEventScreenState();
}

class _ManagerEditEventScreenState extends State<ManagerEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantNameController = TextEditingController();
  final _participantPhoneController = TextEditingController();

  // Event type & date
  String? _selectedEventType;
  final List<String> _eventTypeOptions = [
    'Classroom/Workshop',
    'Family/Social Event',
    'Conference/Professional Event'
  ];
  DateTime? _selectedDateTime;
  final _dateFormat = DateFormat('MMM d, yyyy, HH:mm');

  // Firebase
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Images
  List<String> _imageUrls = [];
  List<String> _imageUrlsToRemove = [];
  List<XFile> _newImages = [];
  final _picker = ImagePicker();

  List<Map<String, dynamic>> _participants = [];

  //Csv
  FilePickerResult? _csvResult;
  List<Map<String, String>> _parsedCsv = [];

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _participantNameController.dispose();
    _participantPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
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

  Future<void> _pickCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _csvResult = result);
        await _parseCsv(result.files.single.path!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נבחר קובץ CSV')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בבחירת הקובץ: $e')),
      );
    }
  }

  Future<void> _parseCsv(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = await CharsetConverter.decode("windows-1255", bytes);
      }

      final tmp = parseCsvContent(content);
      setState(() => _parsedCsv = tmp);
      await _addParticipantsFromCsv();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בקריאת קובץ ה־CSV: $e')),
      );
    }
  }

  Future<void> _addParticipantsFromCsv() async {
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);

    // מחיקת כל המשתתפים הישנים
    final existing = await eventRef.collection('participants').get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    // איפוס allowedParticipants
    await eventRef.update({'allowedParticipants': []});

    // הוספת משתתפים חדשים
    for (var p in _parsedCsv) {
      await eventRef.collection('participants').add({
        'name': p['name'],
        'phone': p['phone'],
        'addedAt': FieldValue.serverTimestamp(),
      });
      await eventRef.update({
        'allowedParticipants': FieldValue.arrayUnion([p['phone']]),
      });
    }

    // שמירת קובץ ה־CSV ב־Firebase Storage
    final csvPath = _csvResult?.files.single.path;
    if (csvPath != null) {
      final ref = FirebaseStorage.instance
          .ref('events/${widget.eventId}/participants.csv');
      await ref.putFile(File(csvPath));
      final url = await ref.getDownloadURL();
      await eventRef.update({'participantFileUrl': url});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('משתתפי CSV עודכנו בהצלחה')),
    );
  }

  void _showParticipantsDialog() {
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: eventRef.collection('participants').snapshots(),
        builder: (ctx2, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'כל המשתתפים',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ListView(
                  shrinkWrap: true,
                  children: docs.map((d) {
                    final p = d.data()! as Map<String, dynamic>;
                    return ListTile(
                      title: Text(p['name']),
                      subtitle: Text(p['phone']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final participantData =
                              d.data() as Map<String, dynamic>;
                          final rawPhone = participantData['phone'];
                          final phoneToRemove =
                              rawPhone.toString().trim(); // ביטחון מלא

                          print(
                              '🗑 Deleting participant with phone: $phoneToRemove');

                          await d.reference.delete(); // מחיקה מה-collection

                          final eventDoc = FirebaseFirestore.instance
                              .collection('events')
                              .doc(widget.eventId);

                          await eventDoc.update({
                            'allowedParticipants':
                                FieldValue.arrayRemove([phoneToRemove]),
                          });

                          print(
                              '✅ Removed $phoneToRemove from allowedParticipants');
                        },
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('סגירה'),
                ),
                SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);

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
        future: eventRef.get(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          if (!snap.data!.exists)
            return Center(child: Text('Event does not exist'));

          final data = snap.data!.data() as Map<String, dynamic>;
          // Use the widget.eventId directly for participants
          final eventRef = FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId);

          // INIT
          if (_eventNameController.text.isEmpty)
            _eventNameController.text = data['eventName'] ?? '';
          if (_locationController.text.isEmpty)
            _locationController.text = data['location'] ?? '';
          if (_selectedEventType == null)
            _selectedEventType = data['eventType'];
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

                    // CSV Upload Section
                    Text('העלאת CSV של משתתפים:'),
                    ElevatedButton.icon(
                      onPressed: _pickCsv,
                      icon: Icon(Icons.upload_file),
                      label: Text(
                          _csvResult == null ? 'בחר קובץ CSV' : 'CSV נבחר'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D3D3D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    if (_csvResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            'קובץ שנבחר: ${_csvResult!.files.single.name}',
                            style: TextStyle(color: Colors.green)),
                      ),

                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showParticipantsDialog,
                      icon: Icon(Icons.group),
                      label: Text('ניהול משתתפים'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D3D3D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),

                    // Add manually
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
                              color: Color(0xFF3D3D3D), shape: BoxShape.circle),
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
                                          'Please enter both name and phone')),
                                );
                                return;
                              }
                              await eventRef.collection('participants').add({
                                'name': name,
                                'phone': phone,
                                'addedAt': FieldValue.serverTimestamp(),
                              });
                              final normalized = phone.startsWith('+')
                                  ? phone
                                  : '+972${phone.substring(1)}';
                              await eventRef.update({
                                'allowedParticipants':
                                    FieldValue.arrayUnion([normalized]),
                              });
                              _participantNameController.clear();
                              _participantPhoneController.clear();
                            },
                          ),
                        ),
                      ],
                    ),

                    // Display participants list with delete button
                    ..._participants.map((p) => ListTile(
                          title: Text(p['name']),
                          subtitle: Text(p['phone']),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(widget.eventId)
                                  .collection('participants')
                                  .doc(p['docId'])
                                  .delete();

                              setState(() {
                                _participants.remove(p);
                              });
                            },
                          ),
                        )),

                    // Save changes
                    SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Update manager's metadata
                          final updateData = <String, dynamic>{
                            'eventName': _eventNameController.text.trim(),
                            'eventType': _selectedEventType,
                            'location': _locationController.text.trim(),
                          };

                          if (_selectedDateTime != null) {
                            final formattedDate = DateFormat('yyyy-MM-dd')
                                .format(_selectedDateTime!);
                            final formattedTime =
                                DateFormat('HH:mm').format(_selectedDateTime!);
                            updateData['date'] = formattedDate;
                            updateData['time'] = formattedTime;
                          }

                          // Delete removed images
                          for (var url in _imageUrlsToRemove) {
                            try {
                              await FirebaseStorage.instance
                                  .refFromURL(url)
                                  .delete();
                            } catch (_) {}
                          }

                          // Upload new images
                          final newUrls = <String>[];
                          for (var f in _newImages) {
                            final fn =
                                '${DateTime.now().millisecondsSinceEpoch}_${f.name}';
                            final ref = FirebaseStorage.instance
                                .ref('events/${widget.eventId}/images/$fn');
                            await ref.putFile(File(f.path));
                            newUrls.add(await ref.getDownloadURL());
                          }
                          final allImages = [..._imageUrls, ...newUrls];
                          updateData['imageUrls'] = allImages;

                          await eventRef.update(updateData);

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
        items: _eventTypeOptions
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
