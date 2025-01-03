import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('מדריך למשתמש'),
      ),
      body: Center(
        child: Text(
          'זהו מדריך למשתמש.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
