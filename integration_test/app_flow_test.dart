import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:blink_android/main.dart';

/// Limits settling to avoid CI hangs from unbounded pumpAndSettle waits.
Future<void> pumpAndSettleSafely(WidgetTester tester) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) {
      break;
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Flow Tests', () {
    setUpAll(() async {
      // Required for Android screenshots - converts Flutter surface to image
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }
      print('📸 Ready for screenshots');
    });

    testWidgets('App navigation flow', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const BlinkApp());
      await pumpAndSettleSafely(tester);
      await Future.delayed(const Duration(milliseconds: 500));

      // Screenshot 1: Home screen
      await binding.takeScreenshot('01_home_screen');
      print('📸 Captured: 01_home_screen');

      // Verify we're on the home screen
      expect(find.text('Blink Android'), findsOneWidget);

      // Tap the add button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await pumpAndSettleSafely(tester);
      await Future.delayed(const Duration(milliseconds: 500));

      // Screenshot 2: Add connection screen
      await binding.takeScreenshot('02_add_connection_screen');
      print('📸 Captured: 02_add_connection_screen');

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

      await pumpAndSettleSafely(tester);
      await Future.delayed(const Duration(milliseconds: 500));

      // Screenshot 3: Form filled
      await binding.takeScreenshot('03_form_filled');
      print('📸 Captured: 03_form_filled');

      // Go back to home
      await tester.pageBack();
      await pumpAndSettleSafely(tester);
      await Future.delayed(const Duration(milliseconds: 500));

      // Screenshot 4: Back to home
      await binding.takeScreenshot('04_back_to_home');
      print('📸 Captured: 04_back_to_home');

      print('✅ App flow test completed!');
    });

    testWidgets('UI Components visibility', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const BlinkApp());
      await pumpAndSettleSafely(tester);
      await Future.delayed(const Duration(milliseconds: 500));

      // Screenshot 5: Empty state
      await binding.takeScreenshot('05_empty_state');
      print('📸 Captured: 05_empty_state');

      // Verify empty state
      expect(find.text('No connections yet'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Check app bar
      expect(find.text('Blink Android'), findsOneWidget);

      print('✅ UI components test completed!');
    });
  });
}
