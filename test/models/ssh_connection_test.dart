import 'package:flutter_test/flutter_test.dart';
import 'package:blink_android/models/ssh_connection.dart';

void main() {
  group('SSHConnection', () {
    group('Constructor', () {
      test('creates connection with required fields', () {
        final connection = SSHConnection(
          name: 'My Server',
          host: '192.168.1.100',
          username: 'root',
        );

        expect(connection.name, 'My Server');
        expect(connection.host, '192.168.1.100');
        expect(connection.port, 22); // default
        expect(connection.username, 'root');
        expect(connection.password, null);
        expect(connection.privateKeyPath, null);
        expect(connection.privateKeyContent, null);
        expect(connection.hostKeyFingerprints, null);
        expect(connection.isFavorite, false);
        expect(connection.id, isNotEmpty);
        expect(connection.lastConnected, isNotNull);
      });

      test('creates connection with custom port', () {
        final connection = SSHConnection(
          name: 'Custom Port',
          host: 'example.com',
          port: 2222,
          username: 'user',
        );

        expect(connection.port, 2222);
      });

      test('creates connection with password', () {
        final connection = SSHConnection(
          name: 'With Password',
          host: 'localhost',
          username: 'admin',
          password: 'secret123',
        );

        expect(connection.password, 'secret123');
      });

      test('creates connection with private key path', () {
        final connection = SSHConnection(
          name: 'With Key Path',
          host: 'server.example.com',
          username: 'deploy',
          privateKeyPath: '/home/user/.ssh/id_rsa',
        );

        expect(connection.privateKeyPath, '/home/user/.ssh/id_rsa');
      });

      test('creates connection with private key content', () {
        final keyContent = '-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----';
        final connection = SSHConnection(
          name: 'With Key Content',
          host: 'keyserver.com',
          username: 'git',
          privateKeyContent: keyContent,
        );

        expect(connection.privateKeyContent, keyContent);
      });

      test('creates connection with host key fingerprints', () {
        final fingerprints = ['SHA256:abc123', 'SHA256:def456'];
        final connection = SSHConnection(
          name: 'With Fingerprints',
          host: 'secure.com',
          username: 'user',
          hostKeyFingerprints: fingerprints,
        );

        expect(connection.hostKeyFingerprints, fingerprints);
      });

      test('creates connection marked as favorite', () {
        final connection = SSHConnection(
          name: 'Favorite',
          host: 'fav.com',
          username: 'me',
          isFavorite: true,
        );

        expect(connection.isFavorite, true);
      });

      test('generates unique IDs for each connection', () {
        final conn1 = SSHConnection(
          name: 'Server 1',
          host: 'host1.com',
          username: 'user',
        );
        final conn2 = SSHConnection(
          name: 'Server 2',
          host: 'host2.com',
          username: 'user',
        );

        expect(conn1.id, isNot(equals(conn2.id)));
      });

      test('sets lastConnected to current time', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final connection = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
        );
        final after = DateTime.now().add(const Duration(seconds: 1));

        expect(connection.lastConnected.isAfter(before), true);
        expect(connection.lastConnected.isBefore(after), true);
      });
    });

    group('toJson', () {
      test('serializes connection to JSON', () {
        final connection = SSHConnection(
          name: 'Test Server',
          host: 'test.com',
          port: 2222,
          username: 'testuser',
          password: 'testpass',
          privateKeyPath: '/path/to/key',
          privateKeyContent: 'key content',
          hostKeyFingerprints: ['fingerprint1', 'fingerprint2'],
          isFavorite: true,
        );
        connection.lastConnected = DateTime(2024, 1, 1, 12, 0, 0);

        final json = connection.toJson();

        expect(json['name'], 'Test Server');
        expect(json['host'], 'test.com');
        expect(json['port'], 2222);
        expect(json['username'], 'testuser');
        expect(json['password'], 'testpass');
        expect(json['privateKeyPath'], '/path/to/key');
        expect(json['privateKeyContent'], 'key content');
        expect(json['hostKeyFingerprints'], ['fingerprint1', 'fingerprint2']);
        expect(json['isFavorite'], true);
        expect(json['lastConnected'], '2024-01-01T12:00:00.000');
      });

      test('serializes connection with minimal fields', () {
        final connection = SSHConnection(
          name: 'Minimal',
          host: 'min.com',
          username: 'min',
        );
        connection.lastConnected = DateTime(2024, 6, 15, 10, 30, 45);

        final json = connection.toJson();

        expect(json['name'], 'Minimal');
        expect(json['host'], 'min.com');
        expect(json['port'], 22);
        expect(json['username'], 'min');
        expect(json['password'], null);
        expect(json['privateKeyPath'], null);
        expect(json['privateKeyContent'], null);
        expect(json['hostKeyFingerprints'], null);
        expect(json['isFavorite'], false);
      });
    });

    group('fromJson', () {
      test('deserializes JSON to connection', () {
        final json = {
          'id': 'test-id',
          'name': 'From JSON',
          'host': 'fromjson.com',
          'port': 2222,
          'username': 'jsonuser',
          'password': 'jsonpass',
          'privateKeyPath': '/json/path',
          'privateKeyContent': 'json key',
          'hostKeyFingerprints': ['fp1', 'fp2'],
          'lastConnected': '2024-01-01T12:00:00.000',
          'isFavorite': true,
        };

        final connection = SSHConnection.fromJson(json);

        expect(connection.id, 'test-id');
        expect(connection.name, 'From JSON');
        expect(connection.host, 'fromjson.com');
        expect(connection.port, 2222);
        expect(connection.username, 'jsonuser');
        expect(connection.password, 'jsonpass');
        expect(connection.privateKeyPath, '/json/path');
        expect(connection.privateKeyContent, 'json key');
        expect(connection.hostKeyFingerprints, ['fp1', 'fp2']);
        expect(connection.isFavorite, true);
        expect(connection.lastConnected, DateTime(2024, 1, 1, 12, 0, 0));
      });

      test('handles missing port with default', () {
        final json = {
          'id': 'id',
          'name': 'No Port',
          'host': 'noport.com',
          'username': 'user',
          'lastConnected': '2024-01-01T00:00:00.000',
          'isFavorite': false,
        };

        final connection = SSHConnection.fromJson(json);

        expect(connection.port, 22); // default
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'id',
          'name': 'Minimal',
          'host': 'minimal.com',
          'username': 'user',
          'lastConnected': '2024-01-01T00:00:00.000',
          'isFavorite': false,
        };

        final connection = SSHConnection.fromJson(json);

        expect(connection.password, null);
        expect(connection.privateKeyPath, null);
        expect(connection.privateKeyContent, null);
        expect(connection.hostKeyFingerprints, null);
      });

      test('handles missing isFavorite with default', () {
        final json = {
          'id': 'id',
          'name': 'No Fav',
          'host': 'nofav.com',
          'username': 'user',
          'lastConnected': '2024-01-01T00:00:00.000',
        };

        final connection = SSHConnection.fromJson(json);

        expect(connection.isFavorite, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated name', () {
        final original = SSHConnection(
          name: 'Original',
          host: 'original.com',
          username: 'user',
        );
        original.lastConnected = DateTime(2024, 1, 1);

        final copy = original.copyWith(name: 'Updated');

        expect(copy.name, 'Updated');
        expect(copy.host, 'original.com');
        expect(copy.username, 'user');
        expect(copy.id, original.id); // preserves ID
        expect(copy.lastConnected, original.lastConnected);
      });

      test('creates copy with multiple updated fields', () {
        final original = SSHConnection(
          name: 'Original',
          host: 'original.com',
          port: 22,
          username: 'user',
        );
        original.lastConnected = DateTime(2024, 1, 1);

        final copy = original.copyWith(
          name: 'Updated',
          host: 'updated.com',
          port: 2222,
        );

        expect(copy.name, 'Updated');
        expect(copy.host, 'updated.com');
        expect(copy.port, 2222);
        expect(copy.username, 'user');
        expect(copy.id, original.id);
      });

      test('creates copy with updated password', () {
        final original = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
          password: 'oldpass',
        );

        final copy = original.copyWith(password: 'newpass');

        expect(copy.password, 'newpass');
        expect(original.password, 'oldpass'); // original unchanged
      });

      test('creates copy with updated isFavorite', () {
        final original = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
          isFavorite: false,
        );

        final favoriteCopy = original.copyWith(isFavorite: true);

        expect(favoriteCopy.isFavorite, true);
        expect(original.isFavorite, false);
      });

      test('creates copy with updated lastConnected', () {
        final original = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
        );
        original.lastConnected = DateTime(2024, 1, 1);

        final newDate = DateTime(2024, 2, 1);
        final copy = original.copyWith(lastConnected: newDate);

        expect(copy.lastConnected, newDate);
        expect(original.lastConnected, DateTime(2024, 1, 1));
      });

      test('creates independent copy', () {
        final original = SSHConnection(
          name: 'Original',
          host: 'original.com',
          username: 'user',
        );

        final copy = original.copyWith(name: 'Copy');

        // Modifying copy should not affect original
        copy.name = 'Modified';

        expect(original.name, 'Original');
        expect(copy.name, 'Modified');
      });

      test('creates copy with all null values preserves original', () {
        final original = SSHConnection(
          name: 'Original',
          host: 'original.com',
          port: 2222,
          username: 'user',
          password: 'pass',
        );
        original.lastConnected = DateTime(2024, 1, 1);

        final copy = original.copyWith();

        expect(copy.name, original.name);
        expect(copy.host, original.host);
        expect(copy.port, original.port);
        expect(copy.username, original.username);
        expect(copy.password, original.password);
        expect(copy.id, original.id);
        expect(copy.lastConnected, original.lastConnected);
      });

      test('creates copy with updated host key fingerprints', () {
        final original = SSHConnection(
          name: 'Test',
          host: 'test.com',
          username: 'user',
          hostKeyFingerprints: ['old1', 'old2'],
        );

        final newFingerprints = ['new1', 'new2', 'new3'];
        final copy = original.copyWith(hostKeyFingerprints: newFingerprints);

        expect(copy.hostKeyFingerprints, newFingerprints);
        expect(original.hostKeyFingerprints, ['old1', 'old2']);
      });
    });

    group('Round-trip serialization', () {
      test('toJson and fromJson are inverse operations', () {
        final original = SSHConnection(
          name: 'Round Trip',
          host: 'roundtrip.com',
          port: 2222,
          username: 'tripper',
          password: 'password',
          privateKeyPath: '/path/to/key',
          privateKeyContent: 'key content',
          hostKeyFingerprints: ['fp1', 'fp2'],
          isFavorite: true,
        );
        original.lastConnected = DateTime(2024, 6, 15, 10, 30, 45);

        final json = original.toJson();
        final restored = SSHConnection.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.host, original.host);
        expect(restored.port, original.port);
        expect(restored.username, original.username);
        expect(restored.password, original.password);
        expect(restored.privateKeyPath, original.privateKeyPath);
        expect(restored.privateKeyContent, original.privateKeyContent);
        expect(restored.hostKeyFingerprints, original.hostKeyFingerprints);
        expect(restored.isFavorite, original.isFavorite);
        expect(restored.lastConnected, original.lastConnected);
      });

      test('handles round-trip with minimal connection', () {
        final original = SSHConnection(
          name: 'Minimal',
          host: 'min.com',
          username: 'user',
        );
        original.lastConnected = DateTime(2024, 1, 1);

        final json = original.toJson();
        final restored = SSHConnection.fromJson(json);

        expect(restored.name, original.name);
        expect(restored.host, original.host);
        expect(restored.username, original.username);
        expect(restored.password, original.password);
        expect(restored.isFavorite, original.isFavorite);
      });
    });
  });
}
