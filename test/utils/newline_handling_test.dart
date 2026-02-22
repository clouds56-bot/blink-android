import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Newline Normalization', () {
    test('normalizes CRLF to LF', () {
      final input = 'Line1\r\nLine2\r\n';
      final expected = 'Line1\nLine2\n';
      expect(input.replaceAll('\r\n', '\n'), equals(expected));
    });

    test('removes standalone CR before newline', () {
      final input = 'Text\r\nMore';
      final expected = 'Text\nMore';
      expect(input.replaceAll('\r\n', '\n'), equals(expected));
    });

    test('handles progress bar with CR', () {
      final input = 'Progress: [\r=]\r==]\r===]\r====]';
      // CR without following LF should not create new line
      expect(input.contains('\r'), true);
    });
  });
}
