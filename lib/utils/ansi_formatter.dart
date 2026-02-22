/// Utility class for stripping ANSI escape codes and control sequences
/// from terminal output strings.
class AnsiFormatter {
  /// Strips ANSI escape codes and control sequences from the input string.
  ///
  /// This removes:
  /// - CSI (Control Sequence Introducer) sequences like \x1b[31m (colors)
  /// - OSC (Operating System Command) sequences like \x1b]0;Title\x07
  /// - Other control characters like \x07 (bell), \b (backspace), \r (carriage return)
  ///
  /// Returns the cleaned text without any ANSI formatting.
  static String stripAnsiCodes(String input) {
    // Remove CSI sequences: ESC [ ... (letter or ~)
    // Examples: \x1b[31m, \x1b[2K, \x1b[1G, \x1b[?25l
    String result = input.replaceAll(RegExp(r'\x1b\[[?0-9;]*[a-zA-Z~]'), '');

    // Remove OSC sequences: ESC ] ... BEL or ST
    // Examples: \x1b]0;Title\x07, \x1b]2;Title\x1b\
    result = result.replaceAll(RegExp(r'\x1b\][^\x07\x1b]*[\x07\x1b\\]'), '');

    // Remove bell characters
    result = result.replaceAll('\x07', '');

    // Remove backspace characters
    result = result.replaceAll('\x08', '');
    result = result.replaceAll('\x7f', '');

    // Handle carriage returns - convert to newlines or remove if followed by newline
    result = result.replaceAll('\r\n', '\n');
    result = result.replaceAll('\r', '');

    return result;
  }
}
