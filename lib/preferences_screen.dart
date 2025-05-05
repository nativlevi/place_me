import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatingPreferencesScreen extends StatefulWidget {
  final String eventId;
  final String eventType;

  SeatingPreferencesScreen({required this.eventId, required this.eventType});

  @override
  _SeatingPreferencesScreenState createState() =>
      _SeatingPreferencesScreenState();
}

class _SeatingPreferencesScreenState extends State<SeatingPreferencesScreen> {
  Map<String, bool> preferences = {};
  // משתנה לשמירת רשימת המשתתפים שנבחרו באמצעות בחירה בדיאלוג
  Set<String> selectedParticipantPhones = {};
  // משתנה טקסטואלי אם רוצים להציג את השמות שנבחרו בשדה (למשל, כמחרוזת)
  String selectedParticipantsText = '';
  List<Map<String, dynamic>> eventParticipants = [];
  String? selectedParticipant;
  String preferToSitWith = '';
  String preferNotToSitWith = '';
  bool _isSaving = false;
  bool showInLists = true; // משתנה לבחירה אם להופיע ברשימות

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    initializePreferences();
  }

  void initializePreferences() {
    switch (widget.eventType) {
      case 'Classroom/Workshop':
        preferences = {
          'Board': false,
          'Air Conditioner': false,
          'Window': false,
          'Entrance': false,
        };
        break;
      case 'Family/Social Event':
        preferences = {
          'Dance Floor': false,
          'Speakers': false,
          'Exit': false,
        };
        break;
      case 'Conference/Professional Event':
        preferences = {
          'Stage': false,
          'Writing Table': false,
          'Screen': false,
          'Charging Point': false,
        };
        break;
    }
  }

  Future<void> _loadParticipants() async {
    try {
      // שליפת משתתפים מתוך תת-הקולקציה 'manualParticipants' במסמך האירוע
      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('manualParticipants')
          .get();

      setState(() {
        eventParticipants = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error loading participants: $e');
    }
  }

  Future<void> _openParticipantSelection() async {
    // דוגמה: שליפת משתתפים מתת-אוסף participants במסמך האירוע
    final participantsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('manualParticipants')
        .get();

    // המרת המסמכים לרשימה של מפות (כל מפה מייצגת משתתף)
    final participants = participantsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'No Name',
        'phone': data['phone'] ?? '',
      };
    }).toList();

    // פתיחת דיאלוג לבחירת משתתפים
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        // נשתמש במשתנה פנימי לשמירת הבחירה
        Set<String> tempSelected = Set.from(selectedParticipantPhones);
        return AlertDialog(
          title: Text('Select Participants'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                final phone = participant['phone']!;
                return CheckboxListTile(
                  title: Text(participant['name']!),
                  subtitle: Text(phone),
                  value: tempSelected.contains(phone),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        tempSelected.add(phone);
                      } else {
                        tempSelected.remove(phone);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedParticipantPhones = selected;
        // עדכון טקסט להציג את המשתתפים שנבחרו (ניתן לשנות לפי הצורך)
        selectedParticipantsText = selectedParticipantPhones.join(', ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFD0DDD0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Choose Preferences',
            style: TextStyle(
              fontFamily: 'Satreva',
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF727D73),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                // Dropdown להצגת המשתתפים שנשלפו מה־Firestore
                // שדה בחירה למשתתפים (במקום טקסט חופשי)
                GestureDetector(
                  onTap: _openParticipantSelection,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(color: Color(0xFF3D3D3D), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedParticipantsText.isEmpty
                              ? 'I want to sit next to:'
                              : selectedParticipantsText,
                          style: TextStyle(
                            color: Color(0xFF3D3D3D),
                            fontSize: 16,
                            fontFamily: 'Source Sans Pro',
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Color(0xFF3D3D3D)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      preferNotToSitWith = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.person_off, color: Color(0xFF3D3D3D)),
                    hintText: 'I don’t want to sit next to:',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  children: preferences.keys.map((preference) {
                    bool isClose = preferences[preference] ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.grey[200],
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              leading: _getIconForPreference(preference),
                              title: Text(
                                preference,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Source Sans Pro',
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: Switch(
                                value: isClose,
                                onChanged: (value) {
                                  setState(() {
                                    preferences[preference] = value;
                                  });
                                },
                                activeColor: Color(0xFFF3B519),
                                inactiveThumbColor: Colors.grey,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                isClose
                                    ? 'You prefer to be close to the $preference.'
                                    : 'You prefer to be far from the $preference.',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                // כפתור שמירה
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // כאן ניתן לשלוח את כל העדפות המשתתפים ל-Firestore
                      print(
                          "Selected participants: $selectedParticipantPhones");
                      // המשך בתהליך שמירת ההעדפות
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3D3D3D),
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      'SAVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // מתג לבחירה אם להופיע ברשימות
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.grey[200],
                  child: ListTile(
                    leading: Icon(
                      showInLists ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFF3D3D3D),
                    ),
                    title: Text(
                      showInLists
                          ? 'You are visible in the lists'
                          : 'You are hidden from the lists',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    trailing: Switch(
                      value: showInLists,
                      onChanged: (value) {
                        setState(() {
                          showInLists = value;
                        });
                      },
                      activeColor: Color(0xFFF3B519),
                      inactiveThumbColor: Colors.grey,
                    ),
                  ),
                ),

                // רשימת ההעדפות
                Column(
                  children: preferences.keys.map((preference) {
                    bool isClose = preferences[preference] ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.grey[200],
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              leading: _getIconForPreference(preference),
                              title: Text(
                                preference,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Source Sans Pro',
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: Switch(
                                value: isClose,
                                onChanged: (value) {
                                  setState(() {
                                    preferences[preference] = value;
                                  });
                                },
                                activeColor: Color(0xFFF3B519),
                                inactiveThumbColor: Colors.grey,
                              ),
                            ),
                            // טקסט הסבר דינמי
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                isClose
                                    ? 'You prefer to be close to the $preference.'
                                    : 'You prefer to be far from the $preference.',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20),
                // כפתור שמירה
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _isSaving = true;
                          });
                          Future.delayed(Duration(seconds: 2), () {
                            setState(() {
                              _isSaving = false;
                            });
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    padding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 50,
                          width: 50,
                          child: Lottie.network(
                            'https://lottie.host/86d6dc6e-3e3d-468c-8bc6-2728590bb291/HQPr260dx6.json',
                          ),
                        )
                      : Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getIconForPreference(String preference) {
    switch (preference) {
      case 'Board':
        return Image.asset('icons/board_icon.png', width: 32, height: 32);
      case 'Air Conditioner':
        return Image.asset('icons/ac_icon.png', width: 32, height: 32);
      case 'Window':
        return Image.asset('icons/window_icon.png', width: 32, height: 32);
      case 'Entrance':
        return Image.asset('icons/door_icon.png', width: 32, height: 32);
      case 'Dance Floor':
        return Image.asset('icons/dance_icon.png', width: 32, height: 32);
      case 'Speakers':
        return Image.asset('icons/speaker_icon.png', width: 32, height: 32);
      case 'Exit':
        return Image.asset('icons/exit_icon.png', width: 32, height: 32);
      case 'Stage':
        return Image.asset('icons/stage_icon.png', width: 32, height: 32);
      case 'Writing Table':
        return Image.asset('icons/table_icon.png', width: 32, height: 32);
      case 'Screen':
        return Image.asset('icons/screen_icon.png', width: 32, height: 32);
      case 'Charging Point':
        return Image.asset('icons/charging_icon.png', width: 32, height: 32);
      default:
        return Image.asset('icons/default_icon.png', width: 32, height: 32);
    }
  }
}
