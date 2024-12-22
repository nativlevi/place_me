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
      backgroundColor: Color(0xFFa5bfcc),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/PlaceMe.png',
              width: 400,
              height: 400,
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
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/first_screen.jpg"), // Path to your image
                  fit: BoxFit.cover, // Adjusts the image to cover the screen
                ),
              ),
              child: Container(
                color: Colors.black.withAlpha(75),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => navigateToUserGuide(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparent background
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.white, // White icon color
                    size: 24.0,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => navigateToUserGuide(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.black,
                    size: 24.0,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top), // רווח מעל התוכן
                  Text('PlaceMe',style: TextStyle(color: Colors.white,fontSize: 100.0,fontFamily:'Satreva')),
                  Text('Smart Seating, Perfect Placement',style: TextStyle(color: Colors.white,fontFamily: 'Source Sans 3',fontSize: 20.0)),
                  SizedBox(height: 100.0),
                  GestureDetector(
                    onTap: () => navigateToManager(context),
                    child: buildCustomButton('Manager   '),
                  ),
                  SizedBox(height: 10.0),
                  GestureDetector(
                    onTap: () => navigateToParticipant(context),
                    child: buildCustomButton('Participant'),
                  ),
                  SizedBox(height: 10.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomButton(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        border: Border.all(
          color: Colors.white, // White border color
          width: 1.5, // Border width
        ),
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white, // White text color
          fontSize: 16,
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
