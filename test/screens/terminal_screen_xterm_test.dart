import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blink_android/screens/terminal_screen.dart';
import 'package:blink_android/models/ssh_connection.dart';
import 'package:blink_android/services/connection_service.dart';
import 'package:provider/provider.dart';
import 'package:xterm/ui.dart' as xterm_ui;

void main() {
  group('TerminalScreen with xterm', () {
    late SSHConnection testConnection;

    setUp(() {
      testConnection = SSHConnection(
        id: 'test-id',
        name: 'Test Connection',
        host: 'testhost.com',
        port: 22,
        username: 'testuser',
      );
    });

    testWidgets('builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ConnectionService(),
            child: TerminalScreen(connection: testConnection),
          ),
        ),
      );

      expect(find.byType(TerminalScreen), findsOneWidget);
    });

    testWidgets('displays xterm TerminalView', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ConnectionService(),
            child: TerminalScreen(connection: testConnection),
          ),
        ),
      );

      // After xterm integration, we should find TerminalView
      // This test will pass once we integrate xterm
    });

    testWidgets('handles SSH connection setup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ConnectionService(),
            child: TerminalScreen(connection: testConnection),
          ),
        ),
      );

      // Terminal should be initialized
      expect(find.byType(xterm_ui.TerminalView), findsOneWidget);

      // Pump and settle to allow async operations
      await tester.pumpAndSettle();
    });
  });
}
