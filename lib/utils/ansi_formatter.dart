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
    final line = <String>[];
    var cursorX = 0;

    void writeChar(String char) {
      if (cursorX < line.length) {
        line[cursorX] = char;
      } else {
        while (line.length < cursorX) {
          line.add(' ');
        }
        line.add(char);
      }
      cursorX++;
    }

    void clearToEndOfLine() {
      if (cursorX < line.length) {
        line.removeRange(cursorX, line.length);
      }
    }

    var i = 0;
    while (i < result.length) {
      final char = result[i];

      if (char == '\n') {
        output.write(line.join());
        output.write('\n');
        line.clear();
        cursorX = 0;
        i++;
        continue;
      }

      if (char == '\r') {
        cursorX = 0;
        i++;
        continue;
      }

      // Handle CSI escape sequences: ESC [ ... <final byte>
      if (char == '\x1b' && i + 1 < result.length && result[i + 1] == '[') {
        var j = i + 2;
        while (j < result.length) {
          final codeUnit = result.codeUnitAt(j);
          if (codeUnit >= 0x40 && codeUnit <= 0x7E) {
            break;
          }
          j++;
        }

        if (j < result.length) {
          final finalByte = result[j];
          if (finalByte == 'K') {
            clearToEndOfLine();
          }
          i = j + 1;
          continue;
        }
      }

      writeChar(char);
      i++;
    }

    output.write(line.join());
    return output.toString();
  }
}
