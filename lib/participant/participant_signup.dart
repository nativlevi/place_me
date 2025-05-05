import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'participant_login.dart';

class ParticipantSignupScreen extends StatefulWidget {
  @override
  _ParticipantSignupScreenState createState() =>
      _ParticipantSignupScreenState();
}

class _ParticipantSignupScreenState extends State<ParticipantSignupScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  /// ממיר מספר טלפון לפורמט בינלאומי
  /// לדוגמה: "0524559623" → "+972524559623"
  String convertToInternational(String phone) {
    phone = phone.trim();
    if (!phone.startsWith('+')) {
      phone = '+972' + phone.substring(1);
    }
    return phone;
  }

  /// ממיר מספר טלפון לפורמט "pseudo email"
  /// לדוגמה: "+972524559623" → "972524559623@myapp.com"
  String convertPhoneToPseudoEmail(String phone) {
    String email = phone.replaceAll('+', '');
    return '$email@myapp.com';
  }

  Future<void> _registerUser() async {
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty || confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'יש למלא את כל השדות.';
      });
      return;
    }

    if (password != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'הסיסמאות לא תואמות.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // המרה לפורמט בינלאומי והמרה לפורמט pseudo email
      String internationalPhone = convertToInternational(phone);
      String pseudoEmail = convertPhoneToPseudoEmail(internationalPhone);

      // יצירת משתמש באמצעות Firebase Auth עם הפורמט הפיקטיבי כאימייל
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: pseudoEmail,
        password: password,
      );

      // ניתן לשמור גם מידע נוסף ב־Firestore, לדוגמה:
      await FirebaseFirestore.instance.collection("users").doc(internationalPhone).set({
        'phone': internationalPhone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('משתמש נרשם בהצלחה!')),
      );

      // מעבר למסך ההתחברות או למסך הראשי, לדוגמה:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParticipantLoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Get started',
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
                const Text(
                  'בחר סיסמה',
                  style: TextStyle(
                    color: Color(0xFF727D73),
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                    hintText: 'Phone Number',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF3D3D3D)),
                    hintText: 'סיסמה חדשה',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF3D3D3D)),
                    hintText: 'אשר סיסמה',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D3D3D),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'אמת והגדר סיסמה',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // אפשר להוסיף קישור חזרה למסך ההתחברות:
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParticipantLoginScreen(),
                      ),
                    );
                  },
                  child: const Text('כבר רשום? התחבר'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
