import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SeatingPreferencesScreen extends StatefulWidget {
  final String eventType;

  SeatingPreferencesScreen({required this.eventType});

  @override
  _SeatingPreferencesScreenState createState() =>
      _SeatingPreferencesScreenState();
}

class _SeatingPreferencesScreenState extends State<SeatingPreferencesScreen> {
  Map<String, bool> preferences = {};
  String preferToSitWith = '';
  String preferNotToSitWith = '';
  bool _isSaving = false;
  bool showInLists = true; // משתנה לבחירה אם להופיע ברשימות

  @override
  void initState() {
    super.initState();
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      preferToSitWith = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Color(0xFF3D3D3D)),
                    hintText: 'I want to sit next to:',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
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
                    prefixIcon: Icon(Icons.person_off, color: Color(0xFF3D3D3D)),
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
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
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
