import 'package:flutter/material.dart';

class PreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('העדפות'),
      ),
      body: Center(
        child: Text(
          'זהו מסך ההעדפות.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
