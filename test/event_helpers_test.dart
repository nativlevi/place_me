import 'package:flutter_test/flutter_test.dart';
import 'package:place_me/general/event_helpers.dart';

void main() {
  group('parseCsvContent', () {
    test('parses valid csv', () {
      final csv = 'name,phone\nYossi,0521234567\nDana,0547654321';
      final result = parseCsvContent(csv);
      expect(result.length, 2);
      expect(result[0]['name'], 'Yossi');
      expect(result[0]['phone'], '0521234567');
      expect(result[1]['name'], 'Dana');
    });

    test('throws if columns missing', () {
      final csv = 'foo,bar\nYossi,0521234567';
      expect(() => parseCsvContent(csv), throwsException);
    });

    test('skips empty lines', () {
      final csv = 'name,phone\n\nYossi,052\n\nDana,053\n';
      final result = parseCsvContent(csv);
      expect(result.length, 2);
    });
  });
}
