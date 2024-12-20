import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/guide': (context) => GuideScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
          'PlaceMe',
          style: TextStyle(
            fontFamily: 'DanhDa',
            fontSize: 100,
            fontWeight: FontWeight.bold,
          ),
        ),
            SizedBox(height: 20),
            Image.asset(
              'images/candidates.png',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void showAuthOptions(BuildContext context, String userType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$userType Authentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigating to $userType Registration...')),
                  );
                },
                child: Text('Register'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigating to $userType Login...')),
                  );
                },
                child: Text('Login'),
              ),
            ],
          ),
        );
      },
    );
  }

  void navigateToManager(BuildContext context) {
    showAuthOptions(context, 'Manager');
  }

  void navigateToParticipant(BuildContext context) {
    showAuthOptions(context, 'Participant');
  }

  void navigateToUserGuide(BuildContext context) {
    Navigator.pushNamed(context, '/guide');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to PlaceMe',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => navigateToManager(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Manager'),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () => navigateToParticipant(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Participant'),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () => navigateToUserGuide(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('User Guide'),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Guide'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text(
          'This is the User Guide Screen.',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
