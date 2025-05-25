// lib/participant/participant_reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantResetPasswordScreen extends StatefulWidget {
  const ParticipantResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ParticipantResetPasswordScreenState createState() =>
      _ParticipantResetPasswordScreenState();
}

class _ParticipantResetPasswordScreenState
    extends State<ParticipantResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _message; // גם הודעות שגיאה וגם הצלחה

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    // המרת הפלאפון לפורמט +972...
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+972${phone.substring(1)}';
    }

    try {
      // שליפה מה־Firestore
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(phone).get();

      if (!doc.exists) {
        setState(() => _message = 'User not found');
      } else {
        final recoveryEmail = doc.data()?['recoveryEmail'] as String?;
        if (recoveryEmail == null || recoveryEmail.isEmpty) {
          setState(() => _message = 'No email on file for this user');
        } else {
          // שליחת המייל לשחזור סיסמה
          await FirebaseAuth.instance
              .sendPasswordResetEmail(email: recoveryEmail);
          setState(
              () => _message = 'Password reset link sent to $recoveryEmail');
        }
      }
    } catch (e) {
      setState(() => _message = 'Error: please try again');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Enter your phone number to receive a reset link:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'PHONE NUMBER',
                  prefixIcon: Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter phone';
                  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(v.trim()))
                    return 'Enter valid phone';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D3D3D),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Send Reset Email'),
                  ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _message!.startsWith('Error') ||
                          _message == 'User not found'
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
