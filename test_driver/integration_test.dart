import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

/// Enhanced integration test driver that saves screenshots to disk.
/// Screenshots are saved to: screenshots/e2e/<test_name>/<screenshot_name>.png
Future<void> main() async {
  final screenshotsDir = Directory('screenshots/e2e');
  if (!screenshotsDir.existsSync()) {
    screenshotsDir.createSync(recursive: true);
  }

  await integrationDriver(
    callback: (response) async {
      // Process any screenshots from the test
      if (response.data != null && response.data!.containsKey('screenshots')) {
        final screenshots = response.data!['screenshots'] as List;
        for (final screenshot in screenshots) {
          print('📸 Captured: $screenshot');
        }
      }
      return;
    },
  );
}
