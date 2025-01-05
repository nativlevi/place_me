import 'package:flutter/material.dart';

class SeatingPreferencesScreen extends StatefulWidget {
  final String eventType;

  SeatingPreferencesScreen({required this.eventType});

  @override
  _SeatingPreferencesScreenState createState() =>
      _SeatingPreferencesScreenState();
}

class _SeatingPreferencesScreenState extends State<SeatingPreferencesScreen> {
  bool allowNearbySelection = true;
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
          'Close to the board': false,
          'Far from the board': false,
          'Near air conditioner': false,
          'Far from air conditioner': false,
          'Near window': false,
          'Far from window': false,
          'Close to entrance': false,
          'Far from entrance': false,
        };
        break;
      case 'Family/Social Event':
        preferences = {
          'Near dance floor': false,
          'Far from dance floor': false,
          'Close to speakers': false,
          'Far from speakers': false,
          'Near exit': false,
          'Far from exit': false,
        };
        break;
      case 'Conference/Professional Event':
        preferences = {
          'Close to stage': false,
          'Far from stage': false,
          'Near writing table': false,
          'Far from writing table': false,
          'Close to projector/screens': false,
          'Far from projector/screens': false,
          'Near charging point': false,
          'Far from charging point': false,
        };
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seating Preferences'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your preferences for ${widget.eventType}:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CheckboxListTile(
              title: Text('Allow others to choose to sit near me'),
              value: allowNearbySelection,
              onChanged: (value) {
                setState(() {
                  allowNearbySelection = value!;
                });
              },
            ),
            Expanded(
              child: ListView(
                children: preferences.keys.map((preference) {
                  return CheckboxListTile(
                    title: Text(preference),
                    value: preferences[preference],
                    onChanged: (value) {
                      setState(() {
                        preferences[preference] = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save preferences
                Navigator.pop(context);
              },
              child: Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}
