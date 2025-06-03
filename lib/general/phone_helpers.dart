String convertToInternational(String phone) {
  phone = phone.trim();
  if (!phone.startsWith('+')) {
    phone = '+972' + phone.substring(1);
  }
  return phone;
}

String convertPhoneToPseudoEmail(String phone) {
  String email = phone.replaceAll('+', '');
  return '$email@myapp.com';
}
