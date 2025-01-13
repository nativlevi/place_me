import 'package:flutter/material.dart';

class SeatingPreferencesScreen extends StatefulWidget {
  final String eventType;

  SeatingPreferencesScreen({required this.eventType});

  @override
  _SeatingPreferencesScreenState createState() =>
      _SeatingPreferencesScreenState();
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
        child: ListView(
          children: preferences.keys.map((preference) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Color(0xFFF8F4EF), // רקע בהיר
                child: ListTile(
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  trailing: _buildCustomSwitch(
                    value: preferences[preference] ?? false,
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

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 50,
        height: 25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? Color(0xFFF3B519) : Color(0xFFE8E8E8),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              left: value ? 26 : 2,
              top: 2,
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
