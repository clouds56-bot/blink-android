import 'package:blink_android/screens/terminal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTerminalStatusLine', () {
    test('adds CRLF line ending for terminal status output', () {
      expect(formatTerminalStatusLine('Connecting...'), 'Connecting...\r\n');
    });

    test('handles empty status line', () {
      expect(formatTerminalStatusLine(''), '\r\n');
    });

    test('preserves ANSI content while appending CRLF', () {
      expect(
        formatTerminalStatusLine('\x1b[31m[ERROR] boom\x1b[0m'),
        '\x1b[31m[ERROR] boom\x1b[0m\r\n',
      );
    });
  });
}
