import 'package:flutter_test/flutter_test.dart';
import 'package:blink_android/utils/ansi_formatter.dart';

void main() {
  group('AnsiFormatter', () {
    group('stripAnsiCodes', () {
      test('removes ANSI color codes', () {
        const input = '\x1b[31mRed text\x1b[0m';
        const expected = 'Red text';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('removes multiple ANSI codes', () {
        const input = '\x1b[31m\x1b[1mBold red text\x1b[0m';
        const expected = 'Bold red text';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('removes cursor movement codes', () {
        const input = '\x1b[2K\x1b[1GHello\x1b[0K';
        const expected = 'Hello';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles mixed content with and without ANSI codes', () {
        const input = 'Normal \x1b[32mGreen\x1b[0m and \x1b[34mBlue\x1b[0m text';
        const expected = 'Normal Green and Blue text';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('preserves regular text without ANSI codes', () {
        const input = 'Just regular text';
        const expected = 'Just regular text';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles empty string', () {
        const input = '';
        const expected = '';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('removes OSC (Operating System Command) sequences', () {
        const input = '\x1b]0;Title\x07Some text';
        const expected = 'Some text';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('removes CSI (Control Sequence Introducer) sequences', () {
        const input = '\x1b[?25lHide cursor\x1b[?25hShow cursor';
        const expected = 'Hide cursorShow cursor';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles real terminal output with multiple control sequences', () {
        const input = '\x1b[?2004l\x1b[?2004h\x1b[?2004h\x1b[?2004h\x1b[1;34muser@host\x1b[0m:\x1b[1;36m~\x1b[0m\$ ';
        const expected = 'user@host:~\$ ';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles bell characters', () {
        const input = 'Alert!\x07';
        const expected = 'Alert!';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles backspace characters', () {
        const input = 'Hello\b\x7fWorld';
        const expected = 'HelloWorld';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles carriage return and line feed combinations', () {
        const input = 'Line 1\r\nLine 2';
        const expected = 'Line 1\nLine 2';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('applies carriage return as cursor reset on same line', () {
        const input = 'abcdef\r12';
        const expected = '12cdef';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });

      test('handles zsh partial line cleanup using ESC[K', () {
        const input = 'user@host:~ %\r\x1b[Kuser@host:~ \$ ';
        const expected = 'user@host:~ \$ ';
        expect(AnsiFormatter.stripAnsiCodes(input), expected);
      });
    });
  });
}
