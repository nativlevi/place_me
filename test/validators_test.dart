import 'package:flutter_test/flutter_test.dart';
import 'package:place_me/general/validators.dart';

void main() {
  group('Email Validator', () {
    test('Empty email returns error', () {
      expect(validateEmail(''), 'Please enter your email');
      expect(validateEmail(null), 'Please enter your email');
    });

    test('Invalid email returns error', () {
      expect(validateEmail('abc'), 'Please enter a valid email');
      expect(validateEmail('abc@'), 'Please enter a valid email');
      expect(validateEmail('abc.com'), 'Please enter a valid email');
    });

    test('Valid email returns null', () {
      expect(validateEmail('test@example.com'), null);
      expect(validateEmail('abc.def@mail.co.il'), null);
    });
  });

  group('Login Password Validator', () {
    test('Empty password returns error', () {
      expect(validatePassword(''), 'Please enter your password');
      expect(validatePassword(null), 'Please enter your password');
    });

    test('Any non-empty password returns null', () {
      expect(validatePassword('123456'), null);
      expect(validatePassword('myPass!@#'), null);
    });
  });

  group('Register Password Validator', () {
    test('Empty password returns error', () {
      expect(validatePasswordRegister(''), 'Please enter your password');
      expect(validatePasswordRegister(null), 'Please enter your password');
    });

    test('Short/weak password returns error', () {
      expect(
        validatePasswordRegister('abcdefg'),
        isNotNull,
      );
      expect(
        validatePasswordRegister('abcdefgh'),
        isNotNull,
      );
      expect(
        validatePasswordRegister('abcdefG1'), // no special char
        isNotNull,
      );
    });

    test('Valid password returns null', () {
      expect(validatePasswordRegister('Testpass1!'), null);
      expect(validatePasswordRegister('Abcdefg1@'), null);
    });
  });

  group('Confirm Password Validator', () {
    test('Passwords do not match', () {
      expect(
          validateConfirmPassword('1234', '12345'), 'Passwords do not match');
      expect(validateConfirmPassword('pass', 'PASS'), 'Passwords do not match');
    });

    test('Passwords match', () {
      expect(validateConfirmPassword('pass', 'pass'), null);
      expect(validateConfirmPassword('', ''), null);
    });
  });

  group('Phone Validator', () {
    test('Empty phone number returns error', () {
      expect(validatePhone(''), 'Please enter your phone number');
      expect(validatePhone(null), 'Please enter your phone number');
    });

    test('Invalid phone number returns error', () {
      expect(validatePhone('123'), 'Enter a valid phone number');
      expect(validatePhone('abcdefg'), 'Enter a valid phone number');
      expect(validatePhone('+123'), 'Enter a valid phone number');
    });

    test('Valid phone number returns null', () {
      expect(validatePhone('+972501234567'), null);
      expect(validatePhone('0501234567'), null);
    });
  });
}
