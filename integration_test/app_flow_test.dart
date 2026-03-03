import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:blink_android/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Flow Tests', () {
    setUpAll(() async {
      // Required for Android screenshots
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      await binding.convertFlutterSurfaceToImage();
      print('📸 Ready for screenshots (capture via host script)');
    });

    testWidgets('App navigation flow', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const BlinkApp());
      
      // Wait for app to fully render (critical for headless emulator)
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await Future.delayed(const Duration(seconds: 2)); // Extra time for GPU rendering

      print('📸 STEP: home_screen');
      // Screenshot 1: Home screen

      // Verify we're on the home screen
      expect(find.text('Blink Android'), findsOneWidget);

      // Tap the add button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 1)); // Extra time for GPU rendering

      print('📸 STEP: add_connection_screen');
      // Screenshot 2: Add connection screen

      // Verify form fields exist
      expect(find.byKey(const Key('connection_name_field')), findsOneWidget);
      expect(find.byKey(const Key('host_field')), findsOneWidget);
      expect(find.byKey(const Key('port_field')), findsOneWidget);
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Fill in test data
      await tester.enterText(
        find.byKey(const Key('connection_name_field')),
        'Test Connection',
      );
      await tester.enterText(
        find.byKey(const Key('host_field')),
        '192.168.1.1',
      );
      await tester.enterText(
        find.byKey(const Key('port_field')),
        '22',
      );
      await tester.enterText(
        find.byKey(const Key('username_field')),
        'testuser',
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 1)); // Extra time for GPU rendering

      print('📸 STEP: form_filled');
      // Screenshot 3: Form filled

      // Go back to home
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 1)); // Extra time for GPU rendering

      print('📸 STEP: back_to_home');
      // Screenshot 4: Back to home

      print('✅ App flow test completed!');
    });

    testWidgets('UI Components visibility', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const BlinkApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await Future.delayed(const Duration(seconds: 2)); // Extra time for GPU rendering

      print('📸 STEP: empty_state');
      // Screenshot 5: Empty state

      // Verify empty state
      expect(find.text('No connections yet'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Check app bar
      expect(find.text('Blink Android'), findsOneWidget);

      print('✅ UI components test completed!');
    });
  });
}
