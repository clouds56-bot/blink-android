import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:path_provider/path_provider.dart';
import '../models/ssh_connection.dart';
import '../services/sftp_service.dart';

class FileViewerScreen extends StatefulWidget {
  final SSHConnection connection;
  final SSHClient sshClient;
  final RemoteFile file;

  const FileViewerScreen({
    super.key,
    required this.connection,
    required this.sshClient,
    required this.file,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late SFTPService _sftpService;
  Uint8List? _fileContent;
  String? _error;
  bool _isLoading = false;
  bool _isImage = false;
  bool _isText = false;

  // Text file extensions
  static final _textExtensions = {
    '.txt', '.md', '.json', '.yaml', '.yml',
    '.xml', '.html', '.css', '.js', '.ts',
    '.py', '.dart', '.java', '.c', '.cpp',
    '.h', '.go', '.rs', '.sh', '.bat',
    '.log', '.conf', '.ini', '.env', '.gitignore',
    '.dockerfile', 'Dockerfile', 'Makefile', 'README',
    'LICENSE', 'AUTHORS', 'CHANGELOG',
  };

  // Image file extensions
  static final _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp',
    '.svg',
  };

  @override
  void initState() {
    super.initState();
    _sftpService = SFTPService(widget.sshClient);
    _detectFileType();
    _loadFile();
  }

  void _detectFileType() {
    final name = widget.file.name.toLowerCase();
    _isText = _textExtensions.any((ext) => name.endsWith(ext));
    _isImage = _imageExtensions.any((ext) => name.endsWith(ext));
  }

  Future<void> _loadFile() async {
    if (!_isText && !_isImage) {
      setState(() {
        _error = 'File type not supported for viewing';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _sftpService.connect();
      final content = await _sftpService.downloadFile(widget.file.path);
      setState(() {
        _fileContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _reload() async {
    await _loadFile();
  }

  Future<void> _saveFile() async {
    if (_fileContent == null) return;

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${widget.file.name}');
      await file.writeAsBytes(_fileContent!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${directory.path}/${widget.file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _decodeText() {
    if (_fileContent == null) return '';

    try {
      // Try UTF-8 first
      return utf8.decode(_fileContent!);
    } catch (e) {
      try {
        // Try Latin-1
        return latin1.decode(_fileContent!);
      } catch (e2) {
        return 'Failed to decode file content';
      }
    }
  }

  @override
  void dispose() {
    _sftpService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          if (_isText)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveFile,
              tooltip: 'Save to device',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _reload,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_isText) {
      return _buildTextViewer();
    }

    if (_isImage) {
      return _buildImageViewer();
    }

    return _buildUnsupported();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading file',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _reload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextViewer() {
    final content = _decodeText();
    final size = _fileContent?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.file.path} • ${_formatSize(size)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (widget.file.modifiedTime != null)
                          Text(
                            'Modified: ${_formatDate(widget.file.modifiedTime!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content.isEmpty ? '(Empty file)' : content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.grey[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    if (_fileContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: InteractiveViewer(
        image: Image.memory(
          _fileContent!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnsupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'File type not supported for viewing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.file.name,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download instead'),
              onPressed: () async {
                try {
                  await _sftpService.connect();
                  final content = await _sftpService.downloadFile(widget.file.path);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloaded ${content.length} bytes'),
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
              },
            ),
          ],
        ),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget for interactive image viewing (pinch to zoom)
class InteractiveViewer extends StatefulWidget {
  final Widget image;

  const InteractiveViewer({
    super.key,
    required this.image,
  });

  @override
  State<InteractiveViewer> createState() => _InteractiveViewerState();
}

class _InteractiveViewerState extends State<InteractiveViewer> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        HapticFeedback.lightImpact();
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = details.scale.clamp(0.1, 4.0);
        });
      },
      child: Transform.scale(
        scale: _scale,
        child: widget.image,
      ),
    );
  }
}
