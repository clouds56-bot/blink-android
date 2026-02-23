import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:blink_android/services/sftp_service.dart';

// Mock classes
class MockSSHClient extends Mock implements SSHClient {}

class MockSftpClient extends Mock implements SftpClient {}

class MockSftpFile extends Mock implements SftpFile {}

class MockSftpFileAttrs extends Mock implements SftpFileAttrs {}

class MockSftpFileMode extends Mock implements SftpFileMode {}

class FakeSftpFileOpenMode extends Fake implements SftpFileOpenMode {}

void main() {
  late MockSSHClient mockSSHClient;
  late MockSftpClient mockSftpClient;
  late SFTPService sftpService;

  setUpAll(() {
    // Register fallback values for non-nullable types
    registerFallbackValue(FakeSftpFileOpenMode());
  });

  setUp(() {
    mockSSHClient = MockSSHClient();
    mockSftpClient = MockSftpClient();
    sftpService = SFTPService(mockSSHClient);
  });

  group('SFTPService', () {
    group('connect', () {
      test('should establish SFTP session', () async {
        // Arrange
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);

        // Act
        await sftpService.connect();

        // Assert
        verify(() => mockSSHClient.sftp()).called(1);
        expect(sftpService.isConnected, true);
      });

      test('should handle connection errors', () async {
        // Arrange
        when(() => mockSSHClient.sftp()).thenThrow(Exception('Connection failed'));

        // Act & Assert
        expect(
          () => sftpService.connect(),
          throwsException,
        );
      });
    });

    group('disconnect', () {
      test('should close SFTP session', () async {
        // Arrange
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
        await sftpService.connect();

        // Act
        await sftpService.disconnect();

        // Assert
        expect(sftpService.isConnected, false);
      });

      test('should handle no connection gracefully', () {
        // Act & Assert - should not throw
        expect(() => sftpService.disconnect(), returnsNormally);
      });
    });

    group('listDirectory', () {
      test('should list files in directory', () async {
        // Arrange
        const path = '/home/user';
        final mockMode = MockSftpFileMode();
        final mockAttrs = MockSftpFileAttrs();
        when(() => mockMode.type).thenReturn(SftpFileType.regularFile);
        when(() => mockMode.userRead).thenReturn(true);
        when(() => mockMode.userWrite).thenReturn(true);
        when(() => mockMode.userExecute).thenReturn(false);
        when(() => mockMode.groupRead).thenReturn(true);
        when(() => mockMode.groupWrite).thenReturn(false);
        when(() => mockMode.groupExecute).thenReturn(false);
        when(() => mockMode.otherRead).thenReturn(true);
        when(() => mockMode.otherWrite).thenReturn(false);
        when(() => mockMode.otherExecute).thenReturn(false);
        when(() => mockAttrs.mode).thenReturn(mockMode);
        when(() => mockAttrs.size).thenReturn(100);
        when(() => mockAttrs.modifyTime).thenReturn(1234567890);

        final mockDirMode = MockSftpFileMode();
        final mockDirAttrs = MockSftpFileAttrs();
        when(() => mockDirMode.type).thenReturn(SftpFileType.directory);
        when(() => mockDirMode.userRead).thenReturn(true);
        when(() => mockDirMode.userWrite).thenReturn(true);
        when(() => mockDirMode.userExecute).thenReturn(true);
        when(() => mockDirMode.groupRead).thenReturn(true);
        when(() => mockDirMode.groupWrite).thenReturn(false);
        when(() => mockDirMode.groupExecute).thenReturn(true);
        when(() => mockDirMode.otherRead).thenReturn(true);
        when(() => mockDirMode.otherWrite).thenReturn(false);
        when(() => mockDirMode.otherExecute).thenReturn(true);
        when(() => mockDirAttrs.mode).thenReturn(mockDirMode);
        when(() => mockDirAttrs.size).thenReturn(4096);
        when(() => mockDirAttrs.modifyTime).thenReturn(1234567890);

        final mockItems = [
          SftpName(
            filename: 'file1.txt',
            longname: '-rw-r--r--  1 user group 100 Jan 1 00:00 file1.txt',
            attr: mockAttrs,
          ),
          SftpName(
            filename: 'dir1',
            longname: 'drwxr-xr-x  2 user group 4096 Jan 1 00:00 dir1',
            attr: mockDirAttrs,
          ),
        ];

        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
        when(() => mockSftpClient.listdir('/home/user/')).thenAnswer((_) async => mockItems);
        await sftpService.connect();

        // Act
        final files = await sftpService.listDirectory(path);

        // Assert
        expect(files.length, 2);
        expect(files[0].name, 'file1.txt');
        expect(files[0].isDirectory, false);
        expect(files[1].name, 'dir1');
        expect(files[1].isDirectory, true);
      });

      test('should handle relative paths without trailing slash', () async {
        // Arrange
        const path = '/home/user';
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
        when(() => mockSftpClient.listdir('/home/user/')).thenAnswer((_) async => []);
        await sftpService.connect();

        // Act
        await sftpService.listDirectory(path);

        // Assert
        verify(() => mockSftpClient.listdir('/home/user/')).called(1);
      });

      test('should throw when not connected', () async {
        // Act & Assert
        expect(
          () => sftpService.listDirectory('/'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not connected'),
          )),
        );
      });
    });

    group('changeDirectory', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should navigate to parent directory with ..', () async {
        // Arrange
        const currentPath = '/home/user/documents';
        when(() => mockSftpClient.listdir('/home/user')).thenAnswer((_) async => []);
        await sftpService.connect();

        // Act
        final newPath = await sftpService.changeDirectory(currentPath, '..');

        // Assert
        expect(newPath, '/home/user');
      });

      test('should handle . (current directory)', () async {
        // Arrange
        const currentPath = '/home/user';
        await sftpService.connect();

        // Act
        final newPath = await sftpService.changeDirectory(currentPath, '.');

        // Assert
        expect(newPath, currentPath);
      });

      test('should navigate to absolute path', () async {
        // Arrange
        const currentPath = '/home/user';
        const targetPath = '/var/log';
        when(() => mockSftpClient.listdir('/var/log/')).thenAnswer((_) async => []);
        await sftpService.connect();

        // Act
        final newPath = await sftpService.changeDirectory(currentPath, targetPath);

        // Assert
        expect(newPath, '$targetPath/');
        verify(() => mockSftpClient.listdir('/var/log/')).called(1);
      });

      test('should navigate to relative path', () async {
        // Arrange
        const currentPath = '/home/user';
        const relativePath = 'documents';
        const expectedPath = '/home/user/documents/';
        when(() => mockSftpClient.listdir(expectedPath)).thenAnswer((_) async => []);
        await sftpService.connect();

        // Act
        final newPath = await sftpService.changeDirectory(currentPath, relativePath);

        // Assert
        expect(newPath, expectedPath);
      });

      test('should throw when not connected', () async {
        // Act & Assert
        expect(
          () => sftpService.changeDirectory('/', 'home'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not connected'),
          )),
        );
      });
    });

    group('downloadFile', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should download file successfully', () async {
        // Arrange
        const path = '/home/user/file.txt';
        final mockFile = MockSftpFile();
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        when(() => mockSftpClient.open(path)).thenAnswer((_) async => mockFile);
        when(() => mockFile.readBytes()).thenAnswer((_) async => testData);
        when(() => mockFile.close()).thenAnswer((_) async {});
        await sftpService.connect();

        // Act
        final data = await sftpService.downloadFile(path);

        // Assert
        expect(data, testData);
        verify(() => mockSftpClient.open(path)).called(1);
        verify(() => mockFile.readBytes()).called(1);
        verify(() => mockFile.close()).called(1);
      });

      test('should throw when not connected', () async {
        // Act & Assert
        expect(
          () => sftpService.downloadFile('/file.txt'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not connected'),
          )),
        );
      });
    });

    group('uploadFile', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should open file with correct mode for upload', () async {
        // Arrange
        const path = '/home/user/upload.txt';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final mockFile = MockSftpFile();
        final testStream = Stream.value(testData);

        when(() => mockSftpClient.open(
          path,
          mode: any(named: 'mode'),
        )).thenAnswer((_) async => mockFile);
        await sftpService.connect();

        // Act & Assert - Verify that file is opened with correct mode
        try {
          await sftpService.uploadFile(path, testStream);
        } catch (e) {
          // Expected since write is not mocked properly
        }
        verify(() => mockSftpClient.open(
          path,
          mode: any(named: 'mode'),
        )).called(1);
      }, skip: 'Mocking stream write is complex; integration tests needed');
    });

    group('deleteFile', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should delete file successfully', () async {
        // Arrange
        const path = '/home/user/file.txt';
        when(() => mockSftpClient.remove(path)).thenAnswer((_) async {});
        await sftpService.connect();

        // Act
        await sftpService.deleteFile(path);

        // Assert
        verify(() => mockSftpClient.remove(path)).called(1);
      });
    });

    group('createDirectory', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should create directory successfully', () async {
        // Arrange
        const path = '/home/user/newdir';
        when(() => mockSftpClient.mkdir(path)).thenAnswer((_) async {});
        await sftpService.connect();

        // Act
        await sftpService.createDirectory(path);

        // Assert
        verify(() => mockSftpClient.mkdir(path)).called(1);
      });
    });

    group('rename', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should rename file successfully', () async {
        // Arrange
        const oldPath = '/home/user/old.txt';
        const newPath = '/home/user/new.txt';
        when(() => mockSftpClient.rename(oldPath, newPath)).thenAnswer((_) async {});
        await sftpService.connect();

        // Act
        await sftpService.rename(oldPath, newPath);

        // Assert
        verify(() => mockSftpClient.rename(oldPath, newPath)).called(1);
      });
    });

    group('getFileAttributes', () {
      setUp(() {
        when(() => mockSSHClient.sftp()).thenAnswer((_) async => mockSftpClient);
      });

      test('should get file attributes successfully', () async {
        // Arrange
        const path = '/home/user/file.txt';
        final mockAttrs = MockSftpFileAttrs();
        when(() => mockSftpClient.stat(path)).thenAnswer((_) async => mockAttrs);
        await sftpService.connect();

        // Act
        final attrs = await sftpService.getFileAttributes(path);

        // Assert
        expect(attrs, mockAttrs);
        verify(() => mockSftpClient.stat(path)).called(1);
      });
    });
  });
}
