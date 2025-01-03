import 'package:flutter/material.dart';


class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return Scaffold(
      backgroundColor: Color(0xFFefefef),
      body: Center(
        child: Image.asset(
          'images/PlaceMe.png',
          width: 400,
          height: 400,
        ),
      ),
    );
  }
}