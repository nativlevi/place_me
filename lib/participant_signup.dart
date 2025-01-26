import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'participant_events_screen.dart';

class ParticipantSignupScreen extends StatefulWidget {
  @override
  _ParticipantSignupScreenState createState() => _ParticipantSignupScreenState();
}

class _ParticipantSignupScreenState extends State<ParticipantSignupScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ParticipantEventsScreen()),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtpAndSignUp() async {
    if (_verificationId == null || otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid OTP.';
      });
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParticipantEventsScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify OTP.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
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
                if (_verificationId != null)
                  TextField(
                    controller: otpController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.sms, color: Color(0xFF3D3D3D)),
                      hintText: 'ENTER OTP',
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
                  onPressed: _isLoading
                      ? null
                      : (_verificationId == null ? _sendOtp : _verifyOtpAndSignUp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D3D3D),
                    disabledBackgroundColor: const Color(0xFF3D3D3D),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
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
                    _verificationId == null ? 'SEND OTP' : 'VERIFY OTP',
                    style: const TextStyle(
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
