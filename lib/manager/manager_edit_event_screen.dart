import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:charset_converter/charset_converter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'interactive_room_editor.dart';

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
  final _participantEmailController = TextEditingController();

  // Event type & date
  String? _selectedEventType;
  final List<String> _eventTypeOptions = [
    'Classroom/Workshop',
    'Family/Social Event',
    'Conference/Professional Event'
  ];
  DateTime? _selectedDateTime;
  final _dateFormat = DateFormat('MMM d, yyyy, HH:mm');

  List<Map<String, String>> _manualParticipants = [];
  //Csv
  FilePickerResult? _csvResult;
  List<Map<String, String>> _parsedCsv = [];
  String? _existingCsvUrl;

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
    setState(() {
      _csvResult = null;
      _parsedCsv.clear();
    });
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
      final lines = content
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return;
      String headerLine = lines.first;
      if (headerLine.startsWith('\uFEFF')) headerLine = headerLine.substring(1);
      final header = headerLine.split(',');
      final nameIdx = header.indexOf('name');
      final phoneIdx = header.indexOf('phone');
      final emailIdx = header.indexOf('mail');

      if (nameIdx == -1 || phoneIdx == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('העמודות name,phone and mail לא נמצאו בקובץ')),
        );
        return;
      }
      final tmp = <Map<String, String>>[];
      for (var i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',');
        if (cols.length > max(nameIdx, phoneIdx)) {
          final name = cols[nameIdx].trim();
          final phone = cols[phoneIdx].trim();
          final email = cols[emailIdx].trim();

          if (name.isNotEmpty && phone.isNotEmpty) {
            tmp.add({'name': name, 'phone': phone, 'mail': email});
          }
        }
      }
      setState(() => _parsedCsv = tmp);
      await _addParticipantsFromCsv();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בקריאת קובץ ה־CSV: $e')),
      );
    }
  }

  Future<void> _addParticipantsFromCsv() async {
    final eventRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId);

    // 1. תביא את הרשימה הישנה של הטלפונים (או המיילים) – זו רשימת ה־allowedParticipants
    final snapshot = await eventRef.get();
    final oldAllowed = List<String>.from(snapshot.data()?['allowedParticipants'] ?? []);

    // 2. בנה קבוצת טלפונים חדשה מה־CSV
    final newPhones = _parsedCsv
        .map((p) => p['phone']!)
        .map((phone) => phone.startsWith('+') ? phone : '+972${phone.substring(1)}')
        .toSet();

    // 3. חשב מי חדש: פילטר רק את אלו שב־newPhones אבל **לא** ב־oldAllowed
    final toAdd = newPhones.where((phone) => !oldAllowed.contains(phone)).toList();

    // 4. מחק קודם, אם זה ההתנהגות שלך
    final existingDocs = await eventRef.collection('participants').get();
    for (var doc in existingDocs.docs) {
      await doc.reference.delete();
    }
    await eventRef.update({'allowedParticipants': []});

    // 5. הוסף את כולם (או רק את toAdd, תלוי האם אתה רוצה לשמור את כל הרשימה או רק את החדשים)
    for (var p in _parsedCsv) {
      final rawPhone = p['phone']!;
      final phone = rawPhone.startsWith('+') ? rawPhone : '+972${rawPhone.substring(1)}';
      final email = p['email']?.trim() ?? '';
      final name  = p['name']!;

      // הוסף למסד
      await eventRef.collection('participants').add({
        'name': name,
        'phone': phone,
        'email': email,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // עדכן allowedParticipants
      await eventRef.update({
        'allowedParticipants': FieldValue.arrayUnion([phone]),
      });

      // 6. אם זה אחד מהמספרים שב-toAdd, שלח לו מייל
      if (toAdd.contains(phone) && email.isNotEmpty) {
        await FirebaseFirestore.instance.collection('mail').add({
          'to': email,
          'message': {
            'subject': 'You have been invited to an event',
            'text': 'שלום $name,\n'
                'הוזמנת לאירוע ${_eventNameController.text.trim()} במיקום ${_locationController.text.trim()}.\n'
                'אנא התקן את האפליקציה והירשם.'
          }
        });
      }
    }

    // 7. בינתיים -- שמירת הקובץ כפי שהיה
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
                color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: eventRef.collection('participants').snapshots(),
              builder: (ctx2, snap) {
                if (!snap.hasData)
                  return Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'All Participants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = docs[index].data()! as Map<String, dynamic>;
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.person, color: Color(0xFF727D73)),
                                title: Text(
                                  p['name'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(p['phone'] ?? ''),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Color(0xFF3D3D3D)),
                                  onPressed: () async {
                                    final rawPhone =
                                    p['phone'].toString().trim();
                                    await docs[index].reference.delete();
                                    await eventRef.update({
                                      'allowedParticipants':
                                      FieldValue.arrayRemove([rawPhone]),
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Color(0xFF3D3D3D),
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 48),
                          shape: StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                );
              },
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
            fontFamily: 'Satreva',
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
          if (_existingCsvUrl == null && data['participantFileUrl'] != null) {
            _existingCsvUrl = data['participantFileUrl'] as String;
          }
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
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InteractiveRoomEditor(eventId: widget.eventId),
                          ),
                        );
                      },
                      icon: Icon(Icons.design_services, color: Colors.white),
                      label: Text(
                        'Edit Layout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D3D3D),              // your purple accent
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        elevation: 0,                                     // flat look
                      ),
                    ),
                    const SizedBox(height: 8),
                    // CSV Upload Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickCsv,
                          icon: Icon(Icons.upload_file, color: Colors.white),
                          label: Text(
                            _csvResult == null ? 'Choose New File' : 'CSV Selected',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3D3D3D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            elevation: 0,
                          ),
                        ),

                        if (_existingCsvUrl != null && _csvResult == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file, color: Color(0xFF4A7C59)),
                                SizedBox(width: 8),
                                Text(
                                  // מוציאים רק את השם של הקובץ
                                  'Existing file: participants.csv',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3D3D3D),
                                  ),
                                ),
                              ],
                            ),
                          ),




                        // אם בחרנו קובץ חדש, איך שהייתה
                        if (_csvResult != null) ...[
                          const SizedBox(height: 12),
                          Chip(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            avatar: Icon(Icons.insert_drive_file, color: Color(0xFF4A7C59)),
                            label: Text(
                              _csvResult!.files.single.name,
                              style: TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ],
                    ),


                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showParticipantsDialog,
                      icon: Icon(Icons.group, color: Colors.white),
                      label: Text(
                        'Manage Participants',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D3D3D),               // muted teal-green
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        elevation: 0,
                      ),
                    ),

                    // Add manually
                    SizedBox(height: 16),
                    Text(
                      'Add participants manually:',
                      style: TextStyle(fontSize: 16, color: Color(0xFF727D73)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Name field
                        Expanded(
                          child: TextFormField(
                            controller: _participantNameController,
                            decoration: InputDecoration(
                              hintText: 'Name',
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Phone field
                        Expanded(
                          child: TextFormField(
                            controller: _participantPhoneController,
                            decoration: InputDecoration(
                              hintText: 'Phone',
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Email field
                        Expanded(
                          child: TextFormField(
                            controller: _participantEmailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Add button
                        ElevatedButton(
                          onPressed: () async {
                            final name = _participantNameController.text.trim();
                            final phone = _participantPhoneController.text.trim();
                            final email = _participantEmailController.text.trim();

                            if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please fill all fields: name, phone, and email'),
                                ),
                              );
                              return;
                            }

                            await eventRef.collection('participants').add({
                              'name': name,
                              'phone': phone,
                              'email': email,
                              'addedAt': FieldValue.serverTimestamp(),
                            });

                            final normalized = phone.startsWith('+')
                                ? phone
                                : '+972${phone.substring(1)}';

                            await eventRef.update({
                              'allowedParticipants': FieldValue.arrayUnion([normalized]),
                            });

                            await FirebaseFirestore.instance.collection('mail').add({
                              'to': email,
                              'message': {
                                'subject': 'You have been invited to an event',
                                'text':
                                'Hi $name,\nYou were added to the event.\nPlease install the app and register.'
                              }
                            });

                            _participantNameController.clear();
                            _participantPhoneController.clear();
                            _participantEmailController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D3D3D),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                    // Display participants list with delete button
                    if (_manualParticipants.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _manualParticipants.length,
                        itemBuilder: (ctx, i) {
                          final p = _manualParticipants[i];
                          return Card(
                            color: Colors.white.withOpacity(0.8),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Color(0xFF3D3D3D)),
                              title: Text(
                                p['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${p['phone']} • ${p['email']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFF3D3D3D)),
                                onPressed: () async {
                                  // 1) Remove from Firestore
                                  await FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(widget.eventId)
                                      .collection('participants')
                                      .where('phone', isEqualTo: p['phone'])
                                      .limit(1)
                                      .get()
                                      .then((snap) {
                                    if (snap.docs.isNotEmpty) {
                                      snap.docs.first.reference.delete();
                                    }
                                  });

                                  // 2) Also remove from allowedParticipants array
                                  await FirebaseFirestore.instance
                                      .collection('events')
                                      .doc(widget.eventId)
                                      .update({
                                    'allowedParticipants': FieldValue.arrayRemove([p['phone']])
                                  });

                                  // 3) Remove locally so UI updates
                                  setState(() {
                                    _manualParticipants.removeAt(i);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],



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

                          await eventRef.update(updateData);
                          // עדכון גם באוסף המנהל
                          await FirebaseFirestore.instance
                              .collection('managers')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('events')
                              .where('ref', isEqualTo: widget.eventId) // שדה ref מחזיק את מזהה האירוע
                              .get()
                              .then((snap) async {
                            if (snap.docs.isNotEmpty) {
                              await snap.docs.first.reference.update(updateData);
                            }
                          });


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
