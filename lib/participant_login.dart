import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:place_me/participant_events_screen.dart';
import 'participant_signup.dart';
import 'loading.dart';

class ParticipantLoginScreen extends StatefulWidget {
  @override
  _ParticipantLoginScreenState createState() => _ParticipantLoginScreenState();
}

class _ParticipantLoginScreenState extends State<ParticipantLoginScreen> {
  bool _isLoading = false;

  void _handleLogin() {
    setState(() {
      _isLoading = true;
    });

    // המתן 3 שניות לפני הניווט למסך הבא
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParticipantEventsScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFD0DDD0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Color(0xFF727D73),
                    fontWeight: FontWeight.bold,
                    fontSize: 60,
                    fontFamily: 'Satreva',
                  ),
                ),
                Image.asset(
                  'images/icon.png',
                  height: 250,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account ? ",
                      style: TextStyle(
                        color: Color(0xFF727D73),
                        fontFamily: 'Source Sans 3',
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParticipantSignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                          color: Color(0xFF727D73),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Source Sans 3',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                    hintText: 'PHONE NUMBER',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF3D3D3D)),
                    hintText: 'PASSWORD',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // נווט למסך שחזור סיסמה
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF727D73),
                        fontFamily: 'Source Sans 3',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // כפתור התחברות
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    disabledBackgroundColor: Color(0xFF3D3D3D), // שמירה על צבע קבוע גם במצב טעינה
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 50,
                    width: 50,
                    child: Lottie.network(
                      'https://lottie.host/86d6dc6e-3e3d-468c-8bc6-2728590bb291/HQPr260dx6.json',
                    ),
                  )
                      : Text(
                    'SIGN IN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
