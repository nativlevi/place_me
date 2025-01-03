import 'package:flutter/material.dart';

class ManagerDetailsUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('עדכון פרטי המנהל'),
      ),
      body: Center(
        child: Text(
          'זהו מסך עדכון פרטי המנהל.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
