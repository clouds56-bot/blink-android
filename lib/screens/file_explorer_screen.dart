import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../models/ssh_connection.dart';
import '../services/sftp_service.dart';

class FileExplorerScreen extends StatefulWidget {
  final SSHConnection connection;
  final SSHClient sshClient;

  const FileExplorerScreen({
    super.key,
    required this.connection,
    required this.sshClient,
  });

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  late SFTPService _sftpService;
  String _currentPath = '.';
  List<RemoteFile> _files = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sftpService = SFTPService(widget.sshClient);
    _connectAndLoad();
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _sftpService.connect();
      await _loadDirectory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDirectory() async {
    try {
      final files = await _sftpService.listDirectory(_currentPath);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateTo(RemoteFile file) async {
    if (!file.isDirectory) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newPath = await _sftpService.changeDirectory(_currentPath, file.name);
      setState(() {
        _currentPath = newPath;
      });
      await _loadDirectory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _goBack() async {
    if (_currentPath == '/' || _currentPath == '.') {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newPath = await _sftpService.changeDirectory(_currentPath, '..');
      setState(() {
        _currentPath = newPath;
      });
      await _loadDirectory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _goToRoot() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newPath = await _sftpService.changeDirectory(_currentPath, '/');
      setState(() {
        _currentPath = newPath;
      });
      await _loadDirectory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _sftpService.disconnect();
    super.dispose();
  }

  void _showFileActions(RemoteFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _downloadFile(file);
              },
            ),
            if (!file.isDirectory)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(file);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(RemoteFile file) async {
    try {
      final data = await _sftpService.downloadFile(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${file.name} (${data.length} bytes)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(RemoteFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (file.isDirectory) {
        await _sftpService.deleteDirectory(file.path);
      } else {
        await _sftpService.deleteFile(file.path);
      }

      await _loadDirectory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            hintText: 'Enter folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (folderName == null) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final remotePath = _currentPath.endsWith('/')
          ? '$_currentPath$folderName'
          : '$_currentPath/$folderName';

      await _sftpService.createDirectory(remotePath);

      // Refresh directory listing
      await _loadDirectory();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder created: $folderName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create folder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    // Pick a file from the device
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final fileName = file.name;
    final filePath = file.path;

    if (filePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access file path'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Read file bytes
      final bytes = await File(filePath).readAsBytes();

      // Upload to SFTP
      final remotePath = _currentPath.endsWith('/')
          ? '$_currentPath$fileName'
          : '$_currentPath/$fileName';

      await _sftpService.uploadFile(remotePath, Stream.value(Uint8List.fromList(bytes)));

      // Refresh directory listing
      await _loadDirectory();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded $fileName (${bytes.length} bytes)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SFTP: ${widget.connection.name} (${_files.length} items)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _isLoading ? null : _showCreateFolderDialog,
            tooltip: 'Create folder',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goToRoot,
            tooltip: 'Go to root',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDirectory,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _isLoading ? null : _uploadFile,
            tooltip: 'Upload file',
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          if (_currentPath != '.')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  if (_currentPath != '/')
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBack,
                    ),
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: const TextStyle(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),

          // File list
          if (!_isLoading)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDirectory,
                child: _files.isEmpty
                    ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Directory is empty',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return ListTile(
                            leading: Icon(
                              file.isDirectory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                              color: file.isDirectory ? Colors.amber : Colors.blue,
                            ),
                            title: Text(file.name),
                            subtitle: Text(
                              file.size > 0
                                    ? '${_formatSize(file.size)} ${file.modifiedTime != null ? "• ${_formatDate(file.modifiedTime!)}" : ""}'
                                    : 'Directory',
                            ),
                            trailing: file.isDirectory
                                ? const Icon(Icons.chevron_right)
                                : const Icon(Icons.more_vert),
                            onTap: () => _navigateTo(file),
                            onLongPress: () => _showFileActions(file),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
