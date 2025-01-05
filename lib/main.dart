import 'package:flutter/material.dart';
import 'manager_login.dart';
import 'manager_signup.dart';
import 'participant_login.dart';
import 'participant_signup.dart';
import 'manager_events_screen.dart';
import 'participant_events_screen.dart';
import 'guide_screen.dart';
import 'splash_screen.dart';
import 'manager_event_type_screen.dart';
import 'manager_event_details_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/guide': (context) => GuideScreen(),
        '/manager_login': (context) => ManagerLoginScreen(),
        '/participant_login': (context) => ParticipantLoginScreen(),
        '/manager_signup': (context) => ManagerRegisterScreen(),
        '/participant_signup': (context) => ParticipantSignupScreen(),
        '/manager_dashboard': (context) => ManagerEventTypeScreen(),
        '/participant_dashboard': (context) => ParticipantEventsScreen(),
        '/manager_event_type_screen': (context) => ManagerEventTypeScreen(),
        '/event_details': (context) => ManagerDetailsUpdateScreen(),
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  void navigateToManagerLogin(BuildContext context) {
    Navigator.pushNamed(context, '/manager_login');
  }

  void navigateToParticipantLogin(BuildContext context) {
    Navigator.pushNamed(context, '/participant_login');
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
                  image: AssetImage("images/first_screen.jpg"),
                  fit: BoxFit.cover,
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
                child: Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 50.0,
                      color: Colors.white,
                      fontFamily: 'Source Sans 3',
                    ),
                  ),
                  Text(
                    'To',
                    style: TextStyle(
                      fontSize: 35.0,
                      color: Colors.white,
                      fontFamily: 'Source Sans 3',
                    ),
                  ),
                  Text(
                    'PlaceMe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 100.0,
                      fontFamily: 'Satreva',
                    ),
                  ),
                  Text(
                    'Smart Seating, Perfect Placement',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Source Sans 3',
                      fontSize: 20.0,
                    ),
                  ),
                  SizedBox(height: 50.0),
                  Text(
                    'Continue as:',
                    style: TextStyle(color: Colors.white, fontSize: 25.0),
                  ),
                  SizedBox(height: 15.0),
                  GestureDetector(
                    onTap: () => navigateToManagerLogin(context),
                    child: buildCustomButton('Manager   '),
                  ),
                  SizedBox(height: 10.0),
                  GestureDetector(
                    onTap: () => navigateToParticipantLogin(context),
                    child: buildCustomButton('Participant'),
                  ),
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
        color: Colors.transparent,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}
