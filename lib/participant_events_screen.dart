import 'package:flutter/material.dart';

class ParticipantEventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('אירועים של המשתתף'),
      ),
      body: Center(
        child: Text(
          'זהו מסך האירועים של המשתתף.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
