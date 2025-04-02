import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'participant_choose_password.dart';

class ParticipantSignupScreen extends StatefulWidget {
  @override
  _ParticipantSignupScreenState createState() => _ParticipantSignupScreenState();
}

class _ParticipantSignupScreenState extends State<ParticipantSignupScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;


  Future<void> _sendOtp() async {
    String phoneNumber = phoneController.text.trim();

    // בדיקה אם מספר הטלפון חוקי
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phoneNumber)) {
      setState(() {
        _errorMessage = 'Enter a valid phone number';
      });
      return;
    }

    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+972${phoneNumber.substring(1)}'; // הוספת קידומת ישראל אם חסרה
    }

    setState(() {
      _isLoading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) async {
        setState(() {
          _isLoading = false;
        });

        // ✅ שמירת מספר הטלפון ב-Firestore
        await FirebaseFirestore.instance.collection("users").doc(phoneNumber).set({
          "phone": phoneNumber,
          "createdAt": FieldValue.serverTimestamp(), // מוסיף חותמת זמן
          "otpSent": true // מציין שה-OTP נשלח
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChoosePasswordScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
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
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                    hintText: 'PHONE NUMBER',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D3D3D),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'SEND OTP',
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
