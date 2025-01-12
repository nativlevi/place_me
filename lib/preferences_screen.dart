import 'package:flutter/material.dart';

class SeatingPreferencesScreen extends StatefulWidget {
  final String eventType;

  SeatingPreferencesScreen({required this.eventType});

  @override
  _SeatingPreferencesScreenState createState() => _SeatingPreferencesScreenState();
}

class _SeatingPreferencesScreenState extends State<SeatingPreferencesScreen> {
  Map<String, bool> preferences = {};

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D3D3D),
        elevation: 0,
        title: Text(
          'Seating Preferences',
          style: TextStyle(
            fontFamily: 'Source Sans Pro',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your preferences for ${widget.eventType}:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'On - Close, Off - Far',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: preferences.keys.map((preference) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: _getIconForPreference(preference), // שולח את ההעדפה הנוכחית
                        title: Text(
                          preference, // מציג את שם ההעדפה
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Switch.adaptive(
                          value: preferences[preference] ?? false,
                          activeColor: Colors.teal,
                          onChanged: (value) {
                            setState(() {
                              preferences[preference] = value;
                            });
                          },
                        ),
                      ),



                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save preferences
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D3D3D),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Save Preferences',
                  style: TextStyle(
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
    );
  }

  Widget _getIconForPreference(String preference) {
    switch (preference) {
      case 'Board':
        return Image.asset('icons/board_icon.png', width: 24, height: 24);
      case 'Air Conditioner':
        return Image.asset('icons/ac_icon.png', width: 24, height: 24);
      case 'Window':
        return Image.asset('icons/window_icon.png', width: 24, height: 24);
      case 'Entrance':
        return Image.asset('icons/door_icon.png', width: 24, height: 24);
      case 'Dance Floor':
        return Image.asset('icons/dance_icon.png', width: 24, height: 24);
      case 'Speakers':
        return Image.asset('icons/speaker_icon.png', width: 24, height: 24);
      case 'Exit':
        return Image.asset('icons/exit_icon.png', width: 24, height: 24);
      case 'Stage':
        return Image.asset('icons/stage_icon.png', width: 24, height: 24);
      case 'Writing Table':
        return Image.asset('icons/table_icon.png', width: 24, height: 24);
      case 'Screen':
        return Image.asset('icons/screen_icon.png', width: 24, height: 24);
      case 'Charging Point':
        return Image.asset('icons/charging_icon.png', width: 24, height: 24);
      default:
        return Image.asset('icons/default_icon.png', width: 24, height: 24);
    }
  }

}
