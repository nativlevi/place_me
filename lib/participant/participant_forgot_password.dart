import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'participant_reset_password.dart';

class ParticipantForgotPasswordScreen extends StatefulWidget {
  @override
  _ParticipantForgotPasswordScreenState createState() => _ParticipantForgotPasswordScreenState();
}

class _ParticipantForgotPasswordScreenState extends State<ParticipantForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // קבלת מספר הטלפון והמרתו לפורמט בינלאומי, אם יש צורך
    String phone = phoneController.text.trim();
    if (!phone.startsWith('+')) {
      // לדוגמה: אם המשתמש הכניס "0501234567", נהפוך ל"+972501234567"
      phone = '+972${phone.substring(1)}';
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) {
        // ניתן לטפל באימות אוטומטי, אך במקרה זה נעדיף שהמשתמש יזין את הקוד ידנית
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
        });
        // // נווט למסך להזנת הקוד והסיסמה החדשה
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ParticipantResetPasswordScreen(
        //       verificationId: verificationId,
        //       phoneNumber: phone, email: '',
        //     ),
        //   ),
        // );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // ניתן לטפל במקרה זה אם יש צורך
      },
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('שחזור סיסמה (משתתף)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'הכנס את מספר הטלפון שלך לקבלת קוד אימות',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'מספר טלפון',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'אנא הכנס את מספר הטלפון';
                  }
                  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                    return 'אנא הכנס מספר טלפון תקין';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _sendVerificationCode,
                child: Text('שלח קוד אימות'),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
