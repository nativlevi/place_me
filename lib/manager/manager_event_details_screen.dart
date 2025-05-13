import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:charset_converter/charset_converter.dart';
import '../general/guide_screen.dart';


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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _eventType;

  List<File> _eventImages = [];
  List<Map<String, String>> _manualParticipants = [];

  FilePickerResult? _csvResult;
  List<Map<String, String>> _parsedCsv = [];

  bool _isSaving = false;

  get i_ => null;

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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null) {
      setState(() {
        _eventImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _csvResult = result);
        _parseCsv(result.files.single.path!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נבחר קובץ CSV')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בפתיחת דיאלוג הקבצים: $e')),
      );
    }
  }

  void _parseCsv(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      String content;

      // נסה קודם לקרוא כ-UTF-8
      try {
        content = utf8.decode(bytes);
      } catch (e) {
        print('⚠️ UTF-8 decoding failed, fallback to windows-1255');
        content = await CharsetConverter.decode("windows-1255", bytes);
      }

      print('📄 Raw CSV Content:\n$content');

      final lines = content.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
      if (lines.length < 2) return;

      String headerLine = lines.first;
      if (headerLine.startsWith('\uFEFF')) {
        headerLine = headerLine.substring(1); // הסרת BOM
      }

      final header = headerLine.split(',');
      print('🧩 Header columns: $header');

      final nameIdx = header.indexOf('name');
      final phoneIdx = header.indexOf('phone');
      if (nameIdx == -1 || phoneIdx == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('העמודות name ו־phone לא נמצאו בקובץ')),
        );
        return;
      }

      final tmp = <Map<String, String>>[];
      for (var i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',');
        if (cols.length > max(nameIdx, phoneIdx)) {
          final name = cols[nameIdx].trim();
          final phone = cols[phoneIdx].trim();
          if (name.isNotEmpty && phone.isNotEmpty) {
            tmp.add({'name': name, 'phone': phone});
          }
        }
      }

      setState(() => _parsedCsv = tmp);
      print('✅ Parsed CSV Participants: $_parsedCsv');

      // הוספת כל המשתתפים לקולקשן users
      await _addParticipantsToUsers();

    } catch (e) {
      print('❌ Error parsing CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בקריאת ה־CSV: $e')),
      );
    }
  }

  Future<void> _addParticipantsToUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in')));
      return;
    }

    try {
      for (var participant in _parsedCsv) {
        final phone = participant['phone']!;

        // הוספת שדות נוספים (email, password)
        final email = '${phone}@example.com'; // אפשר ליצור מייל לפי הטלפון
        final password = 'defaultPassword'; // אפשר ליצור סיסמה ברירת מחדל או לבקש מהמשתמש למלא אותה

        // הוספה לקולקשן 'users'
        await FirebaseFirestore.instance.collection('users').doc(phone).set({
          'phone': phone,
          'email': email,
          'password': password, // יש להוסיף את הסיסמה במקרה הזה
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Added user with phone: $phone');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Participants added successfully!')));
    } catch (e) {
      print('Error adding participants: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding participants: $e')));
    }
  }

  void _addManualParticipant() {
    final name = _participantNameCtrl.text.trim();
    final phone = _participantPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נא למלא שם ומספר טלפון')),
      );
      return;
    }
    setState(() {
      _manualParticipants.add({'name': name, 'phone': phone});
      _participantNameCtrl.clear();
      _participantPhoneCtrl.clear();
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('events').doc();

      // 1) בסיס האירוע
      await docRef.set({
        'managerId': user.uid,
        'eventType': _eventType,
        'eventName': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'date': _selectedDate?.toIso8601String(),
        'time': _selectedTime != null
            ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2) העלאת תמונות
      final imageUrls = <String>[];
      for (var i = 0; i < _eventImages.length; i++) {
        final f = _eventImages[i];
        final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance
            .ref('events/${docRef.id}/images/$filename');
        try {
          await ref.putFile(f);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        } catch (e) {
          print('Failed to upload image $i: $e');
        }
      }
      await docRef.update({'imageUrls': imageUrls});


      // 3) העלאת CSV
      final csvPath = _csvResult?.files.single.path;
      if (csvPath != null) {
        final f = File(csvPath);
        final ref = FirebaseStorage.instance
            .ref('events/${docRef.id}/participants.csv');
        try {
          await ref.putFile(f);
          final url = await ref.getDownloadURL();
          await docRef.update({'participantFileUrl': url});
          print('📑 Uploaded CSV: $url');
        } catch (e) {
          print('🔺 failed to upload CSV: $e');
        }
      }

// 4) שמירת המשתתפים ושמירתם גם כ־allowed_users
      final allParticipants = [..._parsedCsv, ..._manualParticipants];


      for (var p in allParticipants) {
        await docRef.collection('participants').add(p);
        await _addAllowedUser(p['phone']!);
      }

      // 5) קישור למנהל

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
        'date': _selectedDate?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event saved successfully!')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/manager_home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addAllowedUser(String phone) async {
    // אם אין + ברישום – ננרמל ל־+972...
    final normalized =
        phone.startsWith('+') ? phone : '+972${phone.substring(1)}';


    await FirebaseFirestore.instance
        .collection('allowed_users')
        .doc(normalized)
        .set({
      'phone': normalized,
      'addedAt': FieldValue.serverTimestamp(),
    });
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Type
                Text(
                  'Event Type: $_eventType',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.event, color: Color(0xFF3D3D3D)),
                    hintText: 'Enter Event Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'נא למלא שם אירוע' : null,
                ),
                SizedBox(height: 20),

                // Location
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.location_on, color: Color(0xFF3D3D3D)),
                    hintText: 'Enter Location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'נא למלא מיקום' : null,
                ),
                SizedBox(height: 20),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickDate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : dateFmt.format(_selectedDate!),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Upload Images
                Text(
                  'Upload clear and high-quality images in PNG, JPG, or JPEG format.',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.image, color: Colors.white),
                  label: Text(
                    _eventImages.isEmpty
                        ? 'Upload Images'
                        : 'Images Selected (${_eventImages.length})',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                if (_eventImages.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _eventImages
                        .map((f) => Stack(
                              children: [
                                Image.file(f, width: 100, height: 100),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _eventImages.remove(f)),
                                    child: Icon(Icons.close, color: Colors.red),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ],
                SizedBox(height: 20),

                // Upload CSV
                Text(
                  'Upload a participant list in CSV format.',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideScreen(
                          section: 'Upload Participant List', // החלק הספציפי של ההנחיות
                        ),
                      ),
                    );
                  },
                  child: Text('View Guidelines'),
                ),

                ElevatedButton.icon(
                  onPressed: _pickCsv,
                  icon: Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                    _csvResult == null
                        ? 'Upload Participant List'
                        : 'CSV Selected',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                if (_csvResult != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Selected file: ${_csvResult!.files.single.name}',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
                SizedBox(height: 20),

                // Manual Participants
                Text(
                  'Add participants manually:',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _participantNameCtrl,
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.person, color: Color(0xFF3D3D3D)),
                          hintText: 'Name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _participantPhoneCtrl,
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                          hintText: 'Phone',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addManualParticipant,
                      child: Icon(Icons.add, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D3D3D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_manualParticipants.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ..._manualParticipants
                      .map((p) => Text('- ${p['name']} (${p['phone']})')),
                ],
                SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            print('🔘 Submit pressed');
                            await _saveEvent();
                          },
                    child: _isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3D3D3D),
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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
