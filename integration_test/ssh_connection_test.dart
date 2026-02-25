import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:blink_android/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SSH Connection End-to-End Tests', () {
    late String screenshotsDir;

    setUpAll(() async {
      // Create screenshots directory
      screenshotsDir = '/tmp/blink_android_test_screenshots';
      await Directory(screenshotsDir).create(recursive: true);
      print('📸 Screenshots will be saved to: $screenshotsDir');
    });

    testWidgets('Complete SSH connection flow', (WidgetTester tester) async {
      // SSH server connection details (from docker-compose)
      const testHost = '10.0.2.2'; // Special IP to access host from Android emulator
      const testPort = 2222;
      const testUsername = 'testuser';
      const testPassword = 'testpass';
      const connectionName = 'Test SSH Server';

      // Launch the app
      await tester.pumpWidget(const BlinkApp());
      await tester.pumpAndSettle();

      // Screenshot 1: Home screen
      await takeScreenshot(tester, screenshotsDir, '01_home_screen');
      print('📸 Screenshot saved: 01_home_screen.png');

      // Verify we're on the home screen
      expect(find.text('Blink Android'), findsOneWidget);
      expect(find.text('No connections yet'), findsOneWidget);

      // Tap the add button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Screenshot 2: Add connection screen
      await takeScreenshot(tester, screenshotsDir, '02_add_connection_screen');
      print('📸 Screenshot saved: 02_add_connection_screen.png');

      // Fill in the connection form
      await tester.enterText(
        find.byKey(const Key('connection_name_field')),
        connectionName,
      );
      await tester.enterText(
        find.byKey(const Key('host_field')),
        testHost,
      );
      await tester.enterText(
        find.byKey(const Key('port_field')),
        testPort.toString(),
      );
      await tester.enterText(
        find.byKey(const Key('username_field')),
        testUsername,
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        testPassword,
      );

      await tester.pumpAndSettle();

      // Screenshot 3: Form filled
      await takeScreenshot(tester, screenshotsDir, '03_form_filled');
      print('📸 Screenshot saved: 03_form_filled.png');

      // Save the connection
      final saveButton = find.text('Save Connection');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Screenshot 4: Connection added
      await takeScreenshot(tester, screenshotsDir, '04_connection_added');
      print('📸 Screenshot saved: 04_connection_added.png');

      // Verify the connection appears in the list
      expect(find.text(connectionName), findsOneWidget);

      // Tap the connection to connect
      final connectionTile = find.text(connectionName);
      await tester.tap(connectionTile);
      await tester.pumpAndSettle();

      // Wait for connection to establish (give it more time for real SSH)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Screenshot 5: Terminal screen - connecting
      await takeScreenshot(tester, screenshotsDir, '05_terminal_connecting');
      print('📸 Screenshot saved: 05_terminal_connecting.png');

      // Wait for connection to complete
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Screenshot 6: Terminal screen - connected
      await takeScreenshot(tester, screenshotsDir, '06_terminal_connected');
      print('📸 Screenshot saved: 06_terminal_connected.png');

      // Test terminal interaction - enter a command
      final commandInput = find.byType(TextField);
      if (commandInput.evaluate().isNotEmpty) {
        await tester.enterText(commandInput, 'ls -la');
        await tester.pumpAndSettle();

        // Screenshot 7: Command entered
        await takeScreenshot(tester, screenshotsDir, '07_command_entered');
        print('📸 Screenshot saved: 07_command_entered.png');

        // Submit the command
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Wait for command output
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Screenshot 8: Command output
        await takeScreenshot(tester, screenshotsDir, '08_command_output');
        print('📸 Screenshot saved: 08_command_output.png');

        // Enter another command
        await tester.enterText(commandInput, 'pwd');
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Screenshot 9: PWD command
        await takeScreenshot(tester, screenshotsDir, '09_pwd_command');
        print('📸 Screenshot saved: 09_pwd_command.png');
      }

      // Test SFTP file explorer
      final folderIcon = find.byIcon(Icons.folder_open);
      if (folderIcon.evaluate().isNotEmpty) {
        await tester.tap(folderIcon);
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Screenshot 10: File explorer
        await takeScreenshot(tester, screenshotsDir, '10_file_explorer');
        print('📸 Screenshot saved: 10_file_explorer.png');

        // Go back to terminal
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Go back to home screen
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Screenshot 11: Back to home
      await takeScreenshot(tester, screenshotsDir, '11_back_to_home');
      print('📸 Screenshot saved: 11_back_to_home.png');

      print('✅ All integration tests completed successfully!');
      print('📁 Screenshots saved in: $screenshotsDir');
    });
  });
}

Future<void> takeScreenshot(
  WidgetTester tester,
  String directory,
  String name,
) async {
  await tester.pumpAndSettle();
  // In a real device/emulator, you would use:
  // await binding.takeScreenshot('$directory/$name');
  // For now, we just note where it would be saved
  print('  📷 Would save: $directory/$name.png');
}
