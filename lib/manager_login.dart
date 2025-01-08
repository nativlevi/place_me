import 'package:flutter/material.dart';

import 'loading.dart';
import 'manager_signup.dart';

class ManagerLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFD0DDD0),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                      )
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ManagerRegisterScreen()),
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
                  prefixIcon: Icon(Icons.person, color: Color(0xFF3D3D3D),),
                  hintText: 'EMAIL',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 15),
              // שדה סיסמה
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF3D3D3D),),
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
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoadingScreen(routeName: '/manager_dashboard'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D3D3D),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
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
    );
  }
}
