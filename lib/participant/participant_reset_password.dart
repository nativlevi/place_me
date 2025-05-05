import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParticipantResetPasswordScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber; // למקרה שתרצה להציג למשתמש את המספר
  ParticipantResetPasswordScreen({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _ParticipantResetPasswordScreenState createState() =>
      _ParticipantResetPasswordScreenState();
}

class _ParticipantResetPasswordScreenState
    extends State<ParticipantResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _message;

  Future<void> _verifyCodeAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _message = null;
    });

    String smsCode = codeController.text.trim();
    try {
      // יצירת אישור אימות עם הקוד שקיבלנו
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );
      // ניסיון להתחבר עם האישורים שקיבלנו
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // לאחר התחברות מוצלחת, עדכן את הסיסמה
      await userCredential.user!.updatePassword(newPasswordController.text.trim());

      setState(() {
        _message = 'הסיסמה עודכנה בהצלחה.';
      });
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
  void dispose() {
    codeController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('איפוס סיסמה - שלב 2'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'הזן את קוד האימות שקיבלת והסיסמה החדשה',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'קוד אימות',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'אנא הכנס את קוד האימות';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'סיסמה חדשה',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'אנא הכנס סיסמה חדשה';
                  }
                  if (value.length < 6) {
                    return 'הסיסמה חייבת להיות באורך 6 תווים לפחות';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _verifyCodeAndResetPassword,
                child: Text('עדכן סיסמה'),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_message != null) ...[
                SizedBox(height: 20),
                Text(
                  _message!,
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
