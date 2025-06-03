// validators.dart

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}

/// Validator for simple password fields (login).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  return null;
}

String? validatePasswordRegister(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  if (value.length < 8 ||
      !RegExp(r'[A-Z]').hasMatch(value) ||
      !RegExp(r'\d').hasMatch(value) ||
      !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'Password must be at least 8 characters, include an uppercase letter, number, and special character.';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your phone number';
  }
  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
    return 'Enter a valid phone number';
  }
  return null;
}
