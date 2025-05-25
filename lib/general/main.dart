import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase/firebase_options.dart';
import '../manager/manager_home_screen.dart';
import 'loading.dart';
import '../manager/manager_login.dart';
import '../manager/manager_signup.dart';
import '../manager/manager_event_type_screen.dart';
import '../manager/manager_event_details_screen.dart';
import '../participant/participant_login.dart';
import '../participant/participant_signup.dart';
import 'guide_screen.dart';
import '../participant/preferences_screen.dart';
import 'splash_screen.dart';
import '../participant/add_participant_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/guide': (context) => GuideScreen(
                section: '',
              ),
          '/manager_login': (context) => ManagerLoginScreen(),
          '/participant_login': (context) => ParticipantLoginScreen(),
          '/loading': (context) => LoadingScreen(
                routeName: '',
              ),
          '/manager_signup': (context) => ManagerRegisterScreen(),
          '/participant_signup': (context) => ParticipantSignupScreen(),
          '/manager_dashboard': (context) => ManagerEventTypeScreen(),
          '/manager_event_type_screen': (context) => ManagerEventTypeScreen(),
          '/event_details': (context) => ManagerDetailsUpdateScreen(),
          '/seating_preferences': (context) => SeatingPreferencesScreen(
                eventType: 'Classroom/Workshop',
                phone: '',
                eventId: 'temp',
                eventName: 'temp',
              ),
          '/add_participant': (context) => AddParticipantScreen(),
          '/manager_home': (context) => ManagerHomeScreen(),
        },
      ),
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
                  image: AssetImage("images/first_screen.webp"),
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
                  Icons.live_help_outlined,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
