import 'dart:io';
import 'dart:convert';
import 'package:integration_test/integration_test_driver.dart';

/// Integration test driver that receives screenshots from the device
/// and saves them to the host machine.
/// 
/// Usage:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_flow_test.dart \
///     -d emulator-5554
Future<void> main() async {
  final screenshotsDir = Directory('screenshots/e2e');
  if (!screenshotsDir.existsSync()) {
    screenshotsDir.createSync(recursive: true);
  }

  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      
      // Check for screenshots in response data
      if (data.containsKey('screenshots')) {
        final screenshots = data['screenshots'];
        print('📸 Found ${(screenshots as List).length} screenshots');
        
        int index = 0;
        for (final screenshot in screenshots) {
          index++;
          try {
            if (screenshot is Map) {
              final name = screenshot['screenshotName']?.toString() ?? 
                          screenshot['name']?.toString() ?? 
                          'screenshot_$index';
              final bytesData = screenshot['bytes'];
              
              List<int> bytes;
              if (bytesData is String) {
                // Base64 encoded
                bytes = base64Decode(bytesData);
              } else if (bytesData is List) {
                // List of ints
                bytes = bytesData.cast<int>();
              } else {
                print('⚠️ Unknown bytes format for $name: ${bytesData.runtimeType}');
                continue;
              }
              
              final file = File('screenshots/e2e/$name.png');
              await file.writeAsBytes(bytes);
              print('📸 Saved: $name.png (${bytes.length} bytes)');
            } else {
              print('⚠️ Screenshot $index is not a Map: ${screenshot.runtimeType}');
            }
          } catch (e) {
            print('⚠️ Failed to save screenshot $index: $e');
          }
        }
      }
      
      // Also write response data to file
      await writeResponseData(data);
    },
  );
}
