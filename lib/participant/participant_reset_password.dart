// Function to reset password
Future<void> _resetPassword() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
  });

  try {
    // Get the email from Firestore based on phone number
    final docSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.phoneNumber)
        .get();

    if (docSnapshot.exists) {
      final email = docSnapshot.data()?["email"];

      // Make sure email is not null before proceeding
      if (email != null && email.isNotEmpty) {
        // Send password reset email to the stored email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        setState(() {
          _successMessage = 'Password reset email sent to $email';
        });
      } else {
        setState(() {
          _errorMessage = 'No email associated with this phone number';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'User not found';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to send password reset email. Try again.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
