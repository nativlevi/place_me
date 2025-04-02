import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'participant_login.dart';

class ChoosePasswordScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const ChoosePasswordScreen({required this.verificationId, required this.phoneNumber, Key? key})
      : super(key: key);

  @override
  _ChoosePasswordScreenState createState() => _ChoosePasswordScreenState();
}

class _ChoosePasswordScreenState extends State<ChoosePasswordScreen> {
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _verifyOtpAndSetPassword() async {
    if (otpController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'יש למלא את כל השדות.';
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'הסיסמאות לא תואמות.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      await userCredential.user!.updatePassword(passwordController.text);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParticipantLoginScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'אימות נכשל. נסה שוב.';
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
                  'בחר סיסמה',
                  style: TextStyle(
                    color: Color(0xFF727D73),
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.sms, color: Color(0xFF3D3D3D)),
                    hintText: 'הזן OTP',
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
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtpAndSetPassword,
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
                    'אמת והגדר סיסמה',
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
