/// Utility class for stripping ANSI escape codes and control sequences
/// from terminal output strings.
class AnsiFormatter {
  /// Strips ANSI escape codes and control sequences from the input string.
  ///
  /// This removes:
  /// - CSI (Control Sequence Introducer) sequences like \x1b[31m (colors)
  /// - OSC (Operating System Command) sequences like \x1b]0;Title\x07
  /// - Other control characters like \x07 (bell), \b (backspace)
  ///
  /// Carriage returns are applied with terminal semantics:
  /// - \r resets the cursor to the start of the current line (does not add a newline)
  /// - \x1b[K clears content from the cursor to end-of-line
  ///
  /// Returns the cleaned text without any ANSI formatting.
  static String stripAnsiCodes(String input) {
    // Remove OSC sequences: ESC ] ... BEL or ST
    // Examples: \x1b]0;Title\x07, \x1b]2;Title\x1b\
    String result = input.replaceAll(RegExp(r'\x1b\][^\x07\x1b]*[\x07\x1b\\]'), '');

    // Remove bell characters
    result = result.replaceAll('\x07', '');

    // Remove backspace characters
    result = result.replaceAll('\x08', '');
    result = result.replaceAll('\x7f', '');

    final output = StringBuffer();
    final lineBuffer = <String>[];
    var cursorX = 0;

    void writeChar(String char) {
      if (cursorX < lineBuffer.length) {
        lineBuffer[cursorX] = char;
      } else {
        while (lineBuffer.length < cursorX) {
          lineBuffer.add(' ');
        }
        lineBuffer.add(char);
      }
      cursorX++;
    }

    void clearToEndOfLine() {
      if (cursorX < lineBuffer.length) {
        lineBuffer.removeRange(cursorX, lineBuffer.length);
      }
    }

    var index = 0;
    while (index < result.length) {
      final char = result[index];

      if (char == '\n') {
        output.write(lineBuffer.join());
        output.write('\n');
        lineBuffer.clear();
        cursorX = 0;
        index++;
        continue;
      }

      if (char == '\r') {
        cursorX = 0;
        index++;
        continue;
      }

      // Handle CSI escape sequences: ESC [ ... <final byte>
      if (char == '\x1b' && index + 1 < result.length && result[index + 1] == '[') {
        var sequenceEnd = index + 2;
        while (sequenceEnd < result.length) {
          final codeUnit = result.codeUnitAt(sequenceEnd);
          // CSI final byte range is ASCII '@' (0x40) through '~' (0x7E).
          if (codeUnit >= 0x40 && codeUnit <= 0x7E) {
            break;
          }
          sequenceEnd++;
        }

        if (sequenceEnd < result.length) {
          final finalByte = result[sequenceEnd];
          if (finalByte == 'K') {
            clearToEndOfLine();
          }
          // Other CSI commands are formatting/cursor control and are stripped.
          index = sequenceEnd + 1;
          continue;
        }

        // Incomplete CSI sequence at end of input, drop it.
        break;
      }

      writeChar(char);
      index++;
    }

    output.write(lineBuffer.join());
    return output.toString();
  }
}
