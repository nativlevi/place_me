
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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash':            (_) => SplashScreen(),
          '/login':             (_) => LoginScreen(),
          '/guide':             (_) => GuideScreen(section: ''),
          '/manager_login':     (_) => ManagerLoginScreen(),
          '/participant_login': (_) => ParticipantLoginScreen(),
          '/loading':           (_) => LoadingScreen(routeName: ''),
          '/manager_signup':    (_) => ManagerRegisterScreen(),
          '/participant_signup':(_) => ParticipantSignupScreen(),
          '/manager_dashboard': (_) => ManagerEventTypeScreen(),
          '/manager_event_type_screen': (_) => ManagerEventTypeScreen(),
          '/event_details':     (_) => ManagerDetailsUpdateScreen(),
          '/seating_preferences': (_) => SeatingPreferencesScreen(
            eventType: 'Classroom/Workshop',
            phone: '',
            eventId: null,
          ),
          '/add_participant':   (_) => AddParticipantScreen(),
          '/manager_home':      (_) => ManagerHomeScreen(),
        },
      ),
    );
  }
}

/// This is your landing login screen
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
                    child: buildCustomButton('Manager'),
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
