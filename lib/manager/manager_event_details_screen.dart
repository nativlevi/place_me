import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:charset_converter/charset_converter.dart';
import '../general/guide_screen.dart';
import '../general/event_helpers.dart';
import 'interactive_room_editor.dart';
import 'package:excel/excel.dart';

class ManagerDetailsUpdateScreen extends StatefulWidget {
  @override
  _ManagerDetailsUpdateScreenState createState() =>
      _ManagerDetailsUpdateScreenState();
}

class _ManagerDetailsUpdateScreenState
    extends State<ManagerDetailsUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _participantNameCtrl = TextEditingController();
  final _participantPhoneCtrl = TextEditingController();
  final _participantEmailCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _eventType;

  List<Map<String, String>> _manualParticipants = [];
  FilePickerResult? _csvResult;
  List<Map<String, String>> _parsedCsv = [];

  bool _isSaving = false;
  String? _createdEventId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('eventType')) {
      _eventType = args['eventType'] as String;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _participantNameCtrl.dispose();
    _participantPhoneCtrl.dispose();
    _participantEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );
      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נבחר קובץ')),
        );
        return;
      }

      final path = result.files.single.path!;
      final ext  = result.files.single.extension?.toLowerCase();

      // 1) רק עדכון ה־state – בלי await כאן!
      setState(() {
        _csvResult = result;
      });

      // 2) מחוץ ל־setState קוראים לפונקציה האסינכרונית
      if (ext == 'xlsx') {
        await _parseXlsx(path); // Future<void> – זה תקין
      } else {
        await _parseCsv(path);  // Future<void> – גם זה
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
      } catch (e) {
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
          SnackBar(content: Text('העמודות name ו־phone לא נמצאו בקובץ')),
        );
        return;
      }

      final tmp = <Map<String, String>>[];
      for (var i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',');
        if (cols.length > max(nameIdx, max(phoneIdx, emailIdx))) {
          final name = cols[nameIdx].trim();
          final phone = cols[phoneIdx].trim();
          final rawEmail = (emailIdx != -1 && emailIdx < cols.length)
              ? cols[emailIdx].trim()
              : '';
          final email = rawEmail;

          if (name.isNotEmpty && phone.isNotEmpty) {
            tmp.add({'name': name, 'phone': phone, 'email': email});
          }
        }
      }

      setState(() => _parsedCsv = tmp);
      await _addParticipantsToUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בקריאת ה־CSV: $e')),
      );
    }
  }


  Future<void> _addParticipantsToUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var participant in _parsedCsv) {
      final phone = participant['phone']!;
      final email = participant['email'] ?? '${phone}@example.com'; // השתמש במייל מהCSV אם קיים
      final password = 'defaultPassword';

      await FirebaseFirestore.instance.collection('users').doc(phone).set({
        'phone': phone,
        'email': email,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נא לבחור גם תאריך וגם שעה')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final deadline = eventDateTime.subtract(Duration(hours: 48));

    setState(() => _isSaving = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('events').doc();
      _createdEventId = docRef.id;

      await docRef.set({
        'managerId': user.uid,
        'eventType': _eventType,
        'eventName': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
        'preferenceDeadline': deadline.toIso8601String(),
      });

      final csvPath = _csvResult?.files.single.path;
      if (csvPath != null) {
        final f = File(csvPath);
        final ref = FirebaseStorage.instance.ref('events/${docRef.id}/participants.csv');
        await ref.putFile(f);
        final url = await ref.getDownloadURL();
        await docRef.update({'participantFileUrl': url});
      }

      final allParticipants = [..._parsedCsv, ..._manualParticipants];

      final participantPhones = allParticipants
          .map((p) => p['phone']!.startsWith('+') ? p['phone']! : '+972${p['phone']!.substring(1)}')
          .toSet()
          .toList();

      await docRef.update({'allowedParticipants': participantPhones});

      // כאן יוצרים מפת מיילים ייחודית
      final Map<String, Map<String, String>> uniqueByEmail = {};

      for (var p in allParticipants) {
        final email = p['email']?.trim() ?? '';
        if (email.isNotEmpty) {
          uniqueByEmail[email] = p;
        }
      }

      final uniqueParticipants = uniqueByEmail.values.toList();

      // שומרים את המשתתפים ב-firestore ויוצרים מיילים ייחודיים
      for (var p in uniqueParticipants) {
        final name = p['name']!;
        final phone = p['phone']!.startsWith('+') ? p['phone']! : '+972${p['phone']!.substring(1)}';
        final email = p['email']?.trim();

        await docRef.collection('participants').add({
          'name': name,
          'phone': phone,
          'email': email,
          'addedAt': FieldValue.serverTimestamp(),
        });

        await _addAllowedUser(phone, docRef.id);

        if (email?.isNotEmpty == true) {
          await FirebaseFirestore.instance.collection('mail').add({
            'to': email,
            'message': {
              'subject': 'You have been invited to an event',
              'text': 'שלום $name,\n'
                  'הוזמנת לאירוע ${_nameCtrl.text.trim()} במיקום ${_locationCtrl.text.trim()}.\n'
                  'אנא התקן את אפליקצית PlaceMe והירשם.'
            }
          });
        }
      }

      await FirebaseFirestore.instance
          .collection('managers')
          .doc(user.uid)
          .collection('events')
          .doc(docRef.id)
          .set({
        'ref': docRef.id,
        'eventName': _nameCtrl.text.trim(),
        'eventType': _eventType,
        'location': _locationCtrl.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InteractiveRoomEditor(eventId: docRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addAllowedUser(String phone, String eventId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .update({
      'allowedParticipants': FieldValue.arrayUnion([phone]),
    });

    await FirebaseFirestore.instance
        .collection('allowed_users')
        .doc(phone)
        .set({
      'phone': phone,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _parseXlsx(String path) async {
    final bytes = File(path).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final tmp = <Map<String, String>>[];

    // נניח שהגיליון הראשון הוא זה עם הכותרות
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.maxRows < 2) return;

    // כותרות בשורה הראשונה
    final header = sheet.row(0).map((e) => e?.value.toString().toLowerCase()).toList();
    final nameIdx  = header.indexOf('name');
    final phoneIdx = header.indexOf('phone');
    final emailIdx = header.indexOf('mail') >= 0
        ? header.indexOf('mail')
        : (header.indexOf('email'));

    if (nameIdx < 0 || phoneIdx < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('העמודות name ו־phone לא נמצאו בגיליון')),
      );
      return;
    }

    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      final name  = row[nameIdx]?.value.toString().trim() ?? '';
      final phone = row[phoneIdx]?.value.toString().trim() ?? '';
      String rawEmail = '';
      if (emailIdx >= 0 && emailIdx < row.length) {
        rawEmail = row[emailIdx]?.value.toString().trim() ?? '';
      }
      final email = rawEmail.isNotEmpty ? rawEmail : '${phone}@example.com';

      if (name.isNotEmpty && phone.isNotEmpty) {
        tmp.add({'name': name, 'phone': phone, 'email': email});
      }
    }

    setState(() => _parsedCsv = tmp);
    await _addParticipantsToUsers();
  }




  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Event Details',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Type: $_eventType', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3D3D3D))),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.event, color: Color(0xFF3D3D3D)),
                    hintText: 'Enter Event Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'נא למלא שם אירוע' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF3D3D3D)),
                    hintText: 'Enter Location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'נא למלא מיקום' : null,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickDate,                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          _selectedDate == null ? 'Select Date' : dateFmt.format(_selectedDate!),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          _selectedTime == null ? 'Select Time' : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text('Upload a participant list in CSV format.', style: TextStyle(fontSize: 16, color: Color(0xFF727D73))),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                      _csvResult == null ? 'בחר קובץ CSV/XLSX' : '${_csvResult!.files.single.name} נבחר',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                if (_csvResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Chip(
                      backgroundColor: Colors.green.shade50,
                      avatar: Icon(Icons.insert_drive_file, color: Color(0xFF4A7C59)),
                      label: Text(
                        _csvResult!.files.single.name,
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => GuideScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View Guidelines',
                    style: TextStyle(
                      color: Color(0xFF3D3D3D),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add participants manually:',
                  style: TextStyle(fontSize: 16, color: Color(0xFF727D73)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Name
                    Expanded(
                      child: TextField(
                        controller: _participantNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Phone
                    Expanded(
                      child: TextField(
                        controller: _participantNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Phone ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Email
                    Expanded(
                      child: TextField(
                        controller: _participantNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Add button
                    ElevatedButton(
                      onPressed: () {
                        final name  = _participantNameCtrl.text.trim();
                        final phone = _participantPhoneCtrl.text.trim();
                        final email = _participantEmailCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                          _showSnackBar('Please fill all fields');
                          return;
                        }
                        setState(() {
                          _manualParticipants.add({
                            'name':  name,
                            'phone': phone,
                            'email': email,
                          });
                          _participantNameCtrl.clear();
                          _participantPhoneCtrl.clear();
                          _participantEmailCtrl.clear();
                        });
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
                if (_manualParticipants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // רשימה לא ממוסגרת של כרטיסים
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _manualParticipants.length,
                    itemBuilder: (ctx, i) {
                      final p = _manualParticipants[i];
                      return Card(
                        color: Colors.white.withOpacity(0.8),  // כאן מגדירים שקיפות של 80%
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Color(0xFF3D3D3D)),
                          title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p['phone']} • ${p['email']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFF3D3D3D)),
                            onPressed: () {
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

                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveEvent,
                    child: _isSaving
                        ? CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : Text('Submit', style: TextStyle(color: Colors.white,fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3D3D3D),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
