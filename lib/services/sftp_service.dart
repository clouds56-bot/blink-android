import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Represents a remote file or directory
class RemoteFile {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedTime;
  final String? permissions;

  RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    this.modifiedTime,
    this.permissions,
  });

  factory RemoteFile.fromSftpName(SftpName item, String parentPath) {
    final path = parentPath.endsWith('/')
        ? '$parentPath${item.filename}'
        : '$parentPath/${item.filename}';

    return RemoteFile(
      name: item.filename,
      path: path,
      isDirectory: item.attr.mode?.type == SftpFileType.directory,
      size: item.attr.size ?? 0,
      modifiedTime: item.attr.modifyTime != null
          ? DateTime.fromMillisecondsSinceEpoch(item.attr.modifyTime! * 1000)
          : null,
      permissions: item.attr.mode != null
          ? _formatPermissions(item.attr.mode!)
          : null,
    );
  }

  static String _formatPermissions(SftpFileMode mode) {
    final type = switch (mode.type) {
      SftpFileType.directory => 'd',
      SftpFileType.symbolicLink => 'l',
      SftpFileType.regularFile => '-',
      _ => '?',
    };
    final perms = [
      mode.userRead ? 'r' : '-',
      mode.userWrite ? 'w' : '-',
      mode.userExecute ? 'x' : '-',
      mode.groupRead ? 'r' : '-',
      mode.groupWrite ? 'w' : '-',
      mode.groupExecute ? 'x' : '-',
      mode.otherRead ? 'r' : '-',
      mode.otherWrite ? 'w' : '-',
      mode.otherExecute ? 'x' : '-',
    ].join();
    return '$type$perms';
  }

  @override
  String toString() => 'RemoteFile($name, ${isDirectory ? "dir" : "file"}, ${_formatSize(size)})';

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteFile &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// Service for SFTP operations
class SFTPService {
  final SSHClient _sshClient;
  SftpClient? _sftpClient;

  SFTPService(this._sshClient);

  bool _isConnected() => _sftpClient != null;

  /// Initialize SFTP session
  Future<void> connect() async {
    if (_isConnected()) {
      debugPrint('SFTP already connected');
      return;
    }

    try {
      _sftpClient = await _sshClient.sftp();
      debugPrint('SFTP session established');
    } catch (e) {
      debugPrint('Failed to establish SFTP session: $e');
      rethrow;
    }
  }

  /// Disconnect SFTP session
  Future<void> disconnect() async {
    _sftpClient = null;
    debugPrint('SFTP session closed');
  }

  /// List files in a directory
  Future<List<RemoteFile>> listDirectory(String path) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      // Normalize path - ensure it has trailing slash
      final normalizedPath = path.endsWith('/') ? path : '$path/';

      debugPrint('Listing directory: $normalizedPath');
      final items = await _sftpClient!.listdir(normalizedPath);

      return items
          .map((item) => RemoteFile.fromSftpName(item, normalizedPath))
          .toList();
    } catch (e) {
      debugPrint('Error listing directory $path: $e');
      rethrow;
    }
  }

  /// Change directory (returns the new path)
  Future<String> changeDirectory(String currentPath, String target) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      // Handle .. and .
      if (target == '..') {
        final parts = currentPath.split('/');
        if (parts.length > 1) {
          parts.removeLast();
          return parts.join('/') == '' ? '/' : parts.join('/');
        }
        return '/';
      }

      if (target == '.') {
        return currentPath;
      }

      // Handle absolute paths
      if (target.startsWith('/')) {
        final normalizedPath = target.endsWith('/') ? target : '$target/';
        // Verify the path exists by listing it
        await _sftpClient!.listdir(normalizedPath);
        return normalizedPath;
      }

      // Handle relative paths
      final newPath = currentPath.endsWith('/')
          ? '$currentPath$target'
          : '$currentPath/$target';
      final normalizedPath = newPath.endsWith('/') ? newPath : '$newPath/';

      // Verify the path exists
      await _sftpClient!.listdir(normalizedPath);

      return normalizedPath;
    } catch (e) {
      debugPrint('Error changing directory to $target: $e');
      rethrow;
    }
  }

  /// Download a file
  Future<Uint8List> downloadFile(String path) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      debugPrint('Downloading file: $path');
      final file = await _sftpClient!.open(path);
      final data = await file.readBytes();
      await file.close();
      debugPrint('Downloaded ${data.length} bytes from $path');
      return data;
    } catch (e) {
      debugPrint('Error downloading file $path: $e');
      rethrow;
    }
  }

  /// Upload a file
  Future<void> uploadFile(String remotePath, Stream<Uint8List> data) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      debugPrint('Uploading file to: $remotePath');
      final file = await _sftpClient!.open(
        remotePath,
        mode: SftpFileOpenMode.write |
              SftpFileOpenMode.create |
              SftpFileOpenMode.truncate,
      );
      await file.write(data);
      await file.close();
      debugPrint('Uploaded $remotePath successfully');
    } catch (e) {
      debugPrint('Error uploading file to $remotePath: $e');
      rethrow;
    }
  }

  /// Delete a file
  Future<void> deleteFile(String path) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      await _sftpClient!.remove(path);
      debugPrint('Deleted file: $path');
    } catch (e) {
      debugPrint('Error deleting file $path: $e');
      rethrow;
    }
  }

  /// Delete a directory (must be empty)
  Future<void> deleteDirectory(String path) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      await _sftpClient!.rmdir(path);
      debugPrint('Deleted directory: $path');
    } catch (e) {
      debugPrint('Error deleting directory $path: $e');
      rethrow;
    }
  }

  /// Create a directory
  Future<void> createDirectory(String path) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      await _sftpClient!.mkdir(path);
      debugPrint('Created directory: $path');
    } catch (e) {
      debugPrint('Error creating directory $path: $e');
      rethrow;
    }
  }

  /// Rename a file or directory
  Future<void> rename(String oldPath, String newPath) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      await _sftpClient!.rename(oldPath, newPath);
      debugPrint('Renamed $oldPath to $newPath');
    } catch (e) {
      debugPrint('Error renaming from $oldPath to $newPath: $e');
      rethrow;
    }
  }

  /// Get file attributes
  Future<SftpFileAttrs> getFileAttributes(String path) async {
    if (!_isConnected()) {
      throw Exception('SFTP not connected. Call connect() first.');
    }

    try {
      return await _sftpClient!.stat(path);
    } catch (e) {
      debugPrint('Error getting attributes for $path: $e');
      rethrow;
    }
  }

  /// Check if connected
  bool get isConnected => _isConnected();
}
