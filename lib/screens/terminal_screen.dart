import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import 'package:xterm/ui.dart' as xterm_ui;
import 'package:provider/provider.dart';
import '../models/ssh_connection.dart';
import '../services/connection_service.dart';

class TerminalScreen extends StatefulWidget {
  final SSHConnection connection;

  const TerminalScreen({super.key, required this.connection});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

// Password prompt dialog
class _PasswordDialog extends StatefulWidget {
  final String host;
  final String username;
  final String? initialPassword;
  final bool hasPrivateKey;
  final Future<String?> Function(String password) onSubmit;
  final VoidCallback onCancel;

  const _PasswordDialog({
    super.key,
    required this.host,
    required this.username,
    this.initialPassword,
    required this.hasPrivateKey,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _savePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = widget.initialPassword ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_passwordController.text);
      widget.onSubmit(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Authenticate',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.username}@${widget.host}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.hasPrivateKey
                  ? 'Enter password for private key (if encrypted):'
                  : 'Enter SSH password:',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: widget.hasPrivateKey
                  ? [AutofillHints.password]
                  : [AutofillHints.password, AutofillHints.username],
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value!.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Save password securely'),
              value: _savePassword,
              onChanged: (value) {
                setState(() {
                  _savePassword = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
        ),
        FilledButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Connect'),
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _TerminalScreenState extends State<TerminalScreen> {
  SSHClient? _client;
  SSHSession? _session;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _error = '';

  // xterm terminal
  late final Terminal _terminal;
  final _terminalController = xterm_ui.TerminalController();
  final _terminalKey = GlobalKey<xterm_ui.TerminalViewState>();

  // Buffer for handling incomplete UTF-8 sequences
  final _decodeBuffer = <int>[];

  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;

  // Password management
  String? _currentPassword;
  bool _hasPromptedForPassword = false;

  // Terminal dimensions
  static const int _defaultCols = 80;
  static const int _defaultRows = 24;

  @override
  void initState() {
    super.initState();

    // Initialize xterm terminal
    _terminal = Terminal(
      maxLines: 10000,
      onOutput: _onTerminalOutput,
    );

    _terminal.write('Connecting to ${widget.connection.username}@${widget.connection.host}:${widget.connection.port}...\n');

    _connect();
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _session?.close();
    _client?.close();
    _terminalController.dispose();
    super.dispose();
  }

  void _onTerminalOutput(String data) {
    // Handle terminal output from xterm and send to SSH
    if (_isConnected && _session != null) {
      _session!.stdin.add(utf8.encode(data));
    }
  }

  String _normalizeLineEndings(String text) {
    // Keep SSH output line endings as-is to avoid altering terminal output.
    return text;
  }

  /// Decode bytes with proper UTF-8 handling for incomplete sequences
  String _decodeUtf8(List<int> bytes) {
    // Add new bytes to buffer
    _decodeBuffer.addAll(bytes);

    // Try to decode and remove successfully decoded bytes
    String result = '';
    while (_decodeBuffer.isNotEmpty) {
      try {
        // Try to decode as much as possible
        final decoded = utf8.decode(_decodeBuffer, allowMalformed: false);
        result += decoded;
        _decodeBuffer.clear();
        break;
      } on FormatException {
        // Incomplete UTF-8 sequence - remove one byte and try again
        // This handles multi-byte characters split across stream chunks
        if (_decodeBuffer.length > 4) {
          // If we have more than 4 bytes and still can't decode,
          // something is wrong - just decode what we can
          final decoded = utf8.decode(_decodeBuffer, allowMalformed: true);
          result += decoded;
          _decodeBuffer.clear();
          break;
        }
        // Remove the last byte (incomplete sequence starter)
        // and keep it for next chunk
        _decodeBuffer.removeLast();
      }
    }

    return result;
  }

  void _resizeTerminal(int cols, int rows) {
    if (_isConnected && _session != null) {
      // Send resize signal to the PTY
      // Note: dartssh2 doesn't support dynamic PTY resizing after creation
      // The terminal will be resized on the next connection
    }
  }

  Future<void> _connect() async {
    final connectionService = context.read<ConnectionService>();

    // First, try to get saved password
    final savedPassword = await connectionService.getSavedPassword(widget.connection.id);

    // If we have a saved password or private key, try connecting directly
    if (savedPassword != null || widget.connection.privateKeyContent != null) {
      await _attemptConnection(savedPassword);
    } else {
      // No saved credentials - prompt user
      await _promptForPasswordAndConnect();
    }
  }

  Future<void> _promptForPasswordAndConnect([String? initialPassword]) async {
    final connectionService = context.read<ConnectionService>();

    final password = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(
        host: widget.connection.host,
        username: widget.connection.username,
        initialPassword: initialPassword ?? _currentPassword,
        hasPrivateKey: widget.connection.privateKeyContent != null,
        onSubmit: (password) async {
          _currentPassword = password;
          await _attemptConnection(password);
        },
        onCancel: () {
          setState(() {
            _isConnecting = false;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _attemptConnection(String? password) async {
    setState(() {
      _isConnecting = true;
      if (_hasPromptedForPassword) {
        _terminal.eraseDisplay();
        _terminal.eraseScrollbackOnly();
        _error = '';
      }
    });

    _terminal.write('Connecting to ${widget.connection.username}@${widget.connection.host}:${widget.connection.port}...\n');

    try {
      // Create socket
      final socket = await SSHSocket.connect(
        widget.connection.host,
        widget.connection.port,
        timeout: const Duration(seconds: 15),
      );

      _terminal.write('Socket connected, establishing SSH session...\n');

      final connectionService = context.read<ConnectionService>();

      // Determine if we should use key authentication
      final useKeyAuth = widget.connection.privateKeyContent != null && password == null;

      // Helper to save password after successful authentication
      Future<void> savePasswordIfNeeded() async {
        if (password != null && !useKeyAuth) {
          _hasPromptedForPassword = true;
          await connectionService.savePassword(widget.connection.id, password!);
          _terminal.write('Password saved securely.\n');
        }
      }

      // Create SSH client
      _client = SSHClient(
        socket,
        username: widget.connection.username,
        onPasswordRequest: () async {
          // Return provided password or saved password
          return password ?? await context.read<ConnectionService>().getSavedPassword(widget.connection.id);
        },
        identities: useKeyAuth
            ? SSHKeyPair.fromPem(widget.connection.privateKeyContent!)
            : null,
      );

      _terminal.write('SSH client created, authenticating...\n');

      _terminal.write(useKeyAuth ? 'Authenticating with private key...\n' : 'Authenticating with password...\n');

      // Authenticate
      await _client!.authenticated;
      _terminal.write('Authentication successful!\n');

      // Save password on successful authentication (if provided and not using key)
      await savePasswordIfNeeded();

      // Create PTY session
      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: _defaultCols,
          height: _defaultRows,
        ),
      );

      _terminal.write('PTY session created.\n');

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      // Listen for output from stdout
      _stdoutSubscription = _session!.stdout.listen(
        (data) {
          // Decode UTF-8 properly to handle multi-byte characters and incomplete sequences
          // Normalize line endings to prevent double newlines
          final output = _normalizeLineEndings(_decodeUtf8(data));
          _terminal.write(output);
        },
        onError: (error) {
          _addError('Session error: $error');
        },
        onDone: () {
          _addError('Connection closed');
        },
      );

      // Listen for stderr
      _stderrSubscription = _session!.stderr.listen(
        (data) {
          final error = _normalizeLineEndings(_decodeUtf8(data));
          _terminal.write('\x1b[31m$error\x1b[0m'); // Red color for stderr
        },
      );
    } on SocketException catch (e) {
      _addError('Connection failed: ${e.message}');
      await _promptForPasswordAndConnect(password ?? _currentPassword);
    } catch (e) {
      _addError('Connection failed: $e');
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _addError(String error) {
    setState(() {
      _error = error;
    });
    _terminal.write('\x1b[31m[ERROR] $error\x1b[0m\n');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.connection.name),
            actions: [
              if (_isConnected)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _session?.close();
                    _client?.close();
                    setState(() {
                      _isConnected = false;
                      _terminal.eraseDisplay();
                      _terminal.eraseScrollbackOnly();
                    });
                    _connect();
                  },
                  tooltip: 'Reconnect',
                ),
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: () {
                  // TODO: Open file explorer (SFTP)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SFTP file explorer coming soon')),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Connection status
              if (_isConnecting || _error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: _error.isNotEmpty ? Colors.red.shade900 : Colors.blue.shade900,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: _isConnecting
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Icon(Icons.error, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error.isNotEmpty ? _error : 'Connecting...',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // Terminal output using xterm
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: xterm_ui.TerminalView(
                    _terminal,
                    controller: _terminalController,
                    key: _terminalKey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
