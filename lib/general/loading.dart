import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatefulWidget {
  final String routeName;

  const LoadingScreen({Key? key, required this.routeName}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // ניווט לנתיב הרצוי לאחר 3 שניות
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, widget.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.network(
          'https://lottie.host/71e7aed6-aee3-4737-bcdd-8bd8581dc4ab/BBKVm9zQwf.json',
        ),
      ),
    );
  }
}
