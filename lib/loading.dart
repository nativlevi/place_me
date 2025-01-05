import 'package:flutter/material.dart';
import 'dart:async';

import 'package:lottie/lottie.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _ManagerLoadingScreenState createState() => _ManagerLoadingScreenState();
}

class _ManagerLoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacementNamed(context, '/participant_events');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.network('https://lottie.host/71e7aed6-aee3-4737-bcdd-8bd8581dc4ab/BBKVm9zQwf.json')
        ),
      );
  }
}
