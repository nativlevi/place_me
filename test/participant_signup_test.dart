// import 'package:flutter_test/flutter_test.dart';
// import 'package:place_me/general/phone_helpers.dart';
//
// void main() {
//   group('convertToInternational', () {
//     test('Converts 0521234567 to +972521234567', () {
//       expect(convertToInternational('0521234567'), '+972521234567');
//     });
//
//     test('Does not double add + if already international', () {
//       expect(convertToInternational('+972521234567'), '+972521234567');
//     });
//
//     test('Trims spaces', () {
//       expect(convertToInternational(' 0521234567 '), '+972521234567');
//     });
//   });
//
//   group('convertPhoneToPseudoEmail', () {
//     test('Converts +972521234567 to 972521234567@myapp.com', () {
//       expect(
//           convertPhoneToPseudoEmail('+972521234567'), '972521234567@myapp.com');
//     });
//
//     test('Removes plus and formats', () {
//       expect(convertPhoneToPseudoEmail('+123456789'), '123456789@myapp.com');
//     });
//
//     test('Works without plus', () {
//       expect(convertPhoneToPseudoEmail('0521234567'), '0521234567@myapp.com');
//     });
//   });
// }
