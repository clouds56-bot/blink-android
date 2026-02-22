import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink_android/models/ssh_connection.dart';
import 'package:blink_android/services/connection_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionService', () {
    late ConnectionService connectionService;
    late MockFlutterSecureStorage mockSecureStorage;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      mockPrefs = MockSharedPreferences();

      // Setup mock behavior
      when(() => mockPrefs.getString('connections')).thenReturn(null);
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      connectionService = ConnectionService();
    });

    group('Initial State', () {
      test('starts with empty connections list', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(connectionService.connections, isEmpty);
      });

      test('starts with isLoading false', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(connectionService.isLoading, false);
      });

      test('starts with empty favorites list', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(connectionService.favoriteConnections, isEmpty);
      });

      test('starts with empty recent connections list', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        expect(connectionService.recentConnections, isEmpty);
      });
    });

    group('Add Connection', () {
      test('adds connection to list', () async {
        final connection = SSHConnection(
          name: 'Test Server',
          host: 'test.com',
          username: 'user',
        );

        await connectionService.addConnection(connection);

        expect(connectionService.connections.length, 1);
        expect(connectionService.connections.first.name, 'Test Server');
      });

      test('adds multiple connections', () async {
        final conn1 = SSHConnection(name: 'Server 1', host: 's1.com', username: 'user');
        final conn2 = SSHConnection(name: 'Server 2', host: 's2.com', username: 'user');

        await connectionService.addConnection(conn1);
        await connectionService.addConnection(conn2);

        expect(connectionService.connections.length, 2);
      });

      test('notifies listeners when adding connection', () async {
        var notified = false;
        connectionService.addListener(() => notified = true);

        final connection = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
        );

        await connectionService.addConnection(connection);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notified, true);
      });
    });

    group('Update Connection', () {
      test('updates existing connection', () async {
        final original = SSHConnection(
          name: 'Original',
          host: 'original.com',
          username: 'user',
        );

        await connectionService.addConnection(original);

        final updated = original.copyWith(
          name: 'Updated',
          host: 'updated.com',
        );

        await connectionService.updateConnection(updated);

        expect(connectionService.connections.length, 1);
        expect(connectionService.connections.first.name, 'Updated');
        expect(connectionService.connections.first.host, 'updated.com');
      });

      test('does not add new connection when ID does not exist', () async {
        final conn1 = SSHConnection(name: 'Server 1', host: 's1.com', username: 'user');
        final conn2 = SSHConnection(name: 'Server 2', host: 's2.com', username: 'user');

        await connectionService.addConnection(conn1);
        await connectionService.updateConnection(conn2);

        expect(connectionService.connections.length, 1);
        expect(connectionService.connections.first.name, 'Server 1');
      });

      test('notifies listeners when updating connection', () async {
        var notified = false;
        connectionService.addListener(() => notified = true);

        final connection = SSHConnection(name: 'Test', host: 'test.com', username: 'user');
        await connectionService.addConnection(connection);

        final updated = connection.copyWith(name: 'Updated');
        await connectionService.updateConnection(updated);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notified, true);
      });
    });

    group('Delete Connection', () {
      test('removes connection from list', () async {
        final conn1 = SSHConnection(name: 'Server 1', host: 's1.com', username: 'user');
        final conn2 = SSHConnection(name: 'Server 2', host: 's2.com', username: 'user');
        final conn3 = SSHConnection(name: 'Server 3', host: 's3.com', username: 'user');

        await connectionService.addConnection(conn1);
        await connectionService.addConnection(conn2);
        await connectionService.addConnection(conn3);

        await connectionService.deleteConnection(conn2.id);

        expect(connectionService.connections.length, 2);
        expect(connectionService.connections.any((c) => c.id == conn2.id), false);
      });

      test('handles non-existent connection ID gracefully', () async {
        final conn = SSHConnection(name: 'Test', host: 'test.com', username: 'user');
        await connectionService.addConnection(conn);

        await connectionService.deleteConnection('non-existent-id');

        expect(connectionService.connections.length, 1);
      });

      test('notifies listeners when deleting connection', () async {
        var notified = false;
        connectionService.addListener(() => notified = true);

        final connection = SSHConnection(name: 'Test', host: 'test.com', username: 'user');
        await connectionService.addConnection(connection);

        await connectionService.deleteConnection(connection.id);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notified, true);
      });
    });

    group('Toggle Favorite', () {
      test('toggles isFavorite from false to true', () async {
        final connection = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
          isFavorite: false,
        );

        await connectionService.addConnection(connection);
        await connectionService.toggleFavorite(connection.id);

        expect(connectionService.connections.first.isFavorite, true);
      });

      test('toggles isFavorite from true to false', () async {
        final connection = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
          isFavorite: true,
        );

        await connectionService.addConnection(connection);
        await connectionService.toggleFavorite(connection.id);

        expect(connectionService.connections.first.isFavorite, false);
      });

      test('notifies listeners when toggling favorite', () async {
        var notified = false;
        connectionService.addListener(() => notified = true);

        final connection = SSHConnection(name: 'Test', host: 'test.com', username: 'user');
        await connectionService.addConnection(connection);

        await connectionService.toggleFavorite(connection.id);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notified, true);
      });
    });

    group('Get Favorite Connections', () {
      test('returns only favorite connections', () async {
        final fav1 = SSHConnection(name: 'Fav 1', host: 'f1.com', username: 'user', isFavorite: true);
        final fav2 = SSHConnection(name: 'Fav 2', host: 'f2.com', username: 'user', isFavorite: true);
        final nonFav = SSHConnection(name: 'Non', host: 'n.com', username: 'user', isFavorite: false);

        await connectionService.addConnection(fav1);
        await connectionService.addConnection(fav2);
        await connectionService.addConnection(nonFav);

        final favorites = connectionService.favoriteConnections;
        expect(favorites.length, 2);
        expect(favorites.every((c) => c.isFavorite), true);
      });

      test('returns empty list when no favorites', () async {
        final conn1 = SSHConnection(name: 'Conn 1', host: 'c1.com', username: 'user', isFavorite: false);
        final conn2 = SSHConnection(name: 'Conn 2', host: 'c2.com', username: 'user', isFavorite: false);

        await connectionService.addConnection(conn1);
        await connectionService.addConnection(conn2);

        expect(connectionService.favoriteConnections, isEmpty);
      });

      test('sorts favorites by lastConnected (newest first)', () async {
        final now = DateTime.now();
        final older = now.subtract(const Duration(hours: 2));
        final newest = now;

        final conn1 = SSHConnection(name: 'Old', host: 'old.com', username: 'user', isFavorite: true);
        final conn2 = SSHConnection(name: 'New', host: 'new.com', username: 'user', isFavorite: true);
        conn1.lastConnected = older;
        conn2.lastConnected = newest;

        await connectionService.addConnection(conn1);
        await connectionService.addConnection(conn2);

        final favorites = connectionService.favoriteConnections;
        expect(favorites.first.name, 'New');
        expect(favorites.last.name, 'Old');
      });
    });

    group('Get Recent Connections', () {
      test('returns only non-favorite connections', () async {
        final recent1 = SSHConnection(name: 'Recent 1', host: 'r1.com', username: 'user', isFavorite: false);
        final recent2 = SSHConnection(name: 'Recent 2', host: 'r2.com', username: 'user', isFavorite: false);
        final fav = SSHConnection(name: 'Fav', host: 'f.com', username: 'user', isFavorite: true);

        await connectionService.addConnection(recent1);
        await connectionService.addConnection(recent2);
        await connectionService.addConnection(fav);

        final recent = connectionService.recentConnections;
        expect(recent.length, 2);
        expect(recent.every((c) => !c.isFavorite), true);
      });

      test('returns empty list when all are favorites', () async {
        final conn1 = SSHConnection(name: 'Fav 1', host: 'f1.com', username: 'user', isFavorite: true);
        final conn2 = SSHConnection(name: 'Fav 2', host: 'f2.com', username: 'user', isFavorite: true);

        await connectionService.addConnection(conn1);
        await connectionService.addConnection(conn2);

        expect(connectionService.recentConnections, isEmpty);
      });

      test('sorts recent by lastConnected (newest first)', () async {
        final now = DateTime.now();
        final older = now.subtract(const Duration(hours: 2));
        final newest = now;

        final conn1 = SSHConnection(name: 'Old', host: 'old.com', username: 'user', isFavorite: false);
        final conn2 = SSHConnection(name: 'New', host: 'new.com', username: 'user', isFavorite: false);
        conn1.lastConnected = older;
        conn2.lastConnected = newest;

        await connectionService.addConnection(conn1);
        await connectionService.addConnection(conn2);

        final recent = connectionService.recentConnections;
        expect(recent.first.name, 'New');
        expect(recent.last.name, 'Old');
      });
    });

    group('Update Last Connected', () {
      test('updates lastConnected timestamp', () async {
        final now = DateTime.now();
        final before = now.subtract(const Duration(hours: 1));

        final connection = SSHConnection(name: 'Test', host: 'test.com', username: 'user');
        connection.lastConnected = before;

        await connectionService.addConnection(connection);

        await Future.delayed(const Duration(milliseconds: 10));
        await connectionService.updateLastConnected(connection.id);

        expect(connectionService.connections.first.lastConnected.isAfter(before), true);
      });

      test('notifies listeners when updating lastConnected', () async {
        var notified = false;
        connectionService.addListener(() => notified = true);

        final connection = SSHConnection(name: 'Test', host: 'test.com', username: 'user');
        await connectionService.addConnection(connection);

        await connectionService.updateLastConnected(connection.id);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notified, true);
      });
    });

    group('Password Storage', () {
      test('saves password for connection (integration test)', () async {
        // Note: Secure storage requires actual platform binding
        // This would need integration tests on real device/emulator
        // Skipping in unit tests since platform channels aren't available
        expect(true, isTrue);
      }, skip: 'Requires platform binding - integration test only');

      test('retrieves saved password (integration test)', () async {
        // Note: This returns null in test environment without real secure storage
        // Skipping in unit tests since platform channels aren't available
        expect(true, isTrue);
      }, skip: 'Requires platform binding - integration test only');
    });

    group('Private Key Storage', () {
      test('saves private key for connection (integration test)', () async {
        // Note: Secure storage requires actual platform binding
        // This would need integration tests on real device/emulator
        // Skipping in unit tests since platform channels aren't available
        expect(true, isTrue);
      }, skip: 'Requires platform binding - integration test only');

      test('retrieves saved private key (integration test)', () async {
        // Note: This returns null in test environment without real secure storage
        // Skipping in unit tests since platform channels aren't available
        expect(true, isTrue);
      }, skip: 'Requires platform binding - integration test only');
    });
  });
}
