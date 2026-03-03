import 'package:flutter_test/flutter_test.dart';

/// Pumps frames with a bounded timeout to avoid hanging on continuous
/// animations (e.g. CircularProgressIndicator) in CI emulators.
///
/// Unlike [WidgetTester.pumpAndSettle], this always completes in bounded time
/// (frames × 100ms) even when widgets have ongoing animations.
Future<void> settle(WidgetTester tester, {int frames = 20}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
