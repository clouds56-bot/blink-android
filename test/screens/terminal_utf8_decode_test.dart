import 'package:blink_android/screens/terminal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeTerminalUtf8Chunk', () {
    test('decodes plain ASCII output', () {
      final buffer = <int>[];
      expect(
        decodeTerminalUtf8Chunk('file1 file2\n'.codeUnits, buffer),
        'file1 file2\n',
      );
      expect(buffer, isEmpty);
    });

    test('preserves split multi-byte sequence across chunks', () {
      final buffer = <int>[];

      expect(
        decodeTerminalUtf8Chunk([0xF0, 0x9F, 0x98], buffer),
        '',
      );
      expect(buffer, [0xF0, 0x9F, 0x98]);

      expect(
        decodeTerminalUtf8Chunk([0x80], buffer),
        '😀',
      );
      expect(buffer, isEmpty);
    });

    test('preserves split two-byte UTF-8 sequence across chunks', () {
      final buffer = <int>[];

      expect(
        decodeTerminalUtf8Chunk([0xC2], buffer),
        '',
      );
      expect(buffer, [0xC2]);

      expect(
        decodeTerminalUtf8Chunk([0xA2], buffer),
        '¢',
      );
      expect(buffer, isEmpty);
    });

    test('flushes malformed leading continuation byte', () {
      final buffer = <int>[];

      expect(
        decodeTerminalUtf8Chunk([0x80], buffer),
        '�',
      );
      expect(buffer, isEmpty);
    });
  });
}
