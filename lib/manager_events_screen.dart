import 'package:flutter/material.dart';

class ManagerEventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('אירועים של המנהל'),
      ),
      body: Center(
        child: Text(
          'זהו מסך האירועים של המנהל.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
