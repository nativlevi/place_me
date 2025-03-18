import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'forgat_password.dart';
import 'manager_event_type_screen.dart';
import 'manager_signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class ManagerLoginScreen extends StatefulWidget {
  @override
  _ManagerLoginScreenState createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // המשתמש ביטל את תהליך ההתחברות
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // התחברות לפיירבייס
      await FirebaseAuth.instance.signInWithCredential(credential);

      // מעבר למסך הבא לאחר התחברות מוצלחת
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ManagerEventTypeScreen()),
      );
    } catch (e) {
      print('Error with Google Sign-In: $e');
      // הצג שגיאה או הודעה למשתמש
    }
  }

  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final appleCredential = OAuthProvider('apple.com').credential(
        accessToken: credential.authorizationCode,
        idToken: credential.identityToken,
      );

      // התחברות לפיירבייס
      await FirebaseAuth.instance.signInWithCredential(appleCredential);

      // מעבר למסך הבא
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ManagerEventTypeScreen()),
      );
    } catch (e) {
      print('Error with Apple Sign-In: $e');
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final facebookAuthCredential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        // התחברות לפיירבייס
        await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);

        // מעבר למסך הבא
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ManagerEventTypeScreen()),
        );
      } else {
        print('Facebook login failed: ${result.status}');
      }
    } catch (e) {
      print('Error with Facebook Sign-In: $e');
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!userCredential.user!.emailVerified) {
        setState(() {
          _errorMessage =
              'Your email is not verified. Please verify your email.';
        });
        await FirebaseAuth.instance.signOut();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManagerEventTypeScreen(),
          ),
        );
      }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 60,
                        fontFamily: 'Satreva',
                      ),
                    ),
                    Image.asset(
                      'images/icon.png',
                      height: 230,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontFamily: 'Source Sans 3',
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManagerRegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'Source Sans 3',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.person, color: Color(0xFF3D3D3D)),
                        hintText: 'EMAIL',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.lock, color: Color(0xFF3D3D3D)),
                        hintText: 'PASSWORD',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF3D3D3D),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontFamily: 'Source Sans 3',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D3D3D),
                        disabledBackgroundColor: const Color(0xFF3D3D3D),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 100),
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
                          : const Text(
                              'SIGN IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 25),
                    // or continue with
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                  color: Colors.grey[700],
                                  fontFamily: 'Source Sans 3'),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // google + apple sign in buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => signInWithGoogle(),
                          child: Image.asset('images/google.png', height: 35),
                        ),
                        SizedBox(width: 25),
                        GestureDetector(
                          onTap: () => signInWithApple(),
                          child: Image.asset('images/apple.png', height: 35),
                        ),
                        SizedBox(width: 25),
                        GestureDetector(
                          onTap: () => signInWithFacebook(),
                          child: Image.asset('images/facebook.png', height: 35),
                        ),
                      ],
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
