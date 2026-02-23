import 'package:blink_android/screens/terminal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeTerminalLineEndings', () {
    test('converts LF to CRLF for terminal cursor rewind', () {
      const input = 'line 1\nline 2';
      const expected = 'line 1\r\nline 2';

      expect(normalizeTerminalLineEndings(input), expected);
    });

    test('keeps CRLF intact without adding extra carriage returns', () {
      const input = 'line 1\r\nline 2';
      const expected = 'line 1\r\nline 2';

      expect(normalizeTerminalLineEndings(input), expected);
    });

    test('normalizes mixed line endings consistently', () {
      const input = 'line 1\r\nline 2\nline 3';
      const expected = 'line 1\r\nline 2\r\nline 3';

      expect(normalizeTerminalLineEndings(input), expected);
    });
  });
}
