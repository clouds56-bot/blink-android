import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;

  // Password management
  String? _currentPassword;
  bool _hasPromptedForPassword = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _session?.close();
    _client?.close();
    _commandController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
        _output.clear();
        _error = '';
      }
    });

    _addOutput('Connecting to ${widget.connection.username}@${widget.connection.host}:${widget.connection.port}...');

    try {
      // Create socket
      final socket = await SSHSocket.connect(
        widget.connection.host,
        widget.connection.port,
        timeout: const Duration(seconds: 15),
      );

      _addOutput('Socket connected, establishing SSH session...');

      final connectionService = context.read<ConnectionService>();

      // Determine if we should use key authentication
      final useKeyAuth = widget.connection.privateKeyContent != null && password == null;

      // Helper to save password after successful authentication
      Future<void> savePasswordIfNeeded() async {
        if (password != null && !useKeyAuth) {
          _hasPromptedForPassword = true;
          await connectionService.savePassword(widget.connection.id, password!);
          _addOutput('Password saved securely.');
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

      _addOutput('SSH client created, authenticating...');

      _addOutput(useKeyAuth ? 'Authenticating with private key...' : 'Authenticating with password...');

      // Authenticate
      await _client!.authenticated;
      _addOutput('Authentication successful!');

      // Save password on successful authentication (if provided and not using key)
      await savePasswordIfNeeded();

      // Create PTY session
      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: 80,
          height: 24,
        ),
      );

      _addOutput('PTY session created.\n');

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      // Listen for output from stdout
      _stdoutSubscription = _session!.stdout.listen(
        (data) {
          final output = utf8.decode(data);
          _addOutput(output);
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
          final error = utf8.decode(data);
          _addError('Remote error: $error');
        },
      );

      // Request focus for keyboard
      _focusNode.requestFocus();
    } on Exception catch (e) {
      _addError('Authentication failed: $e');

      // If authentication failed, prompt for password again
      await _promptForPasswordAndConnect(password ?? _currentPassword);
    } on Exception catch (e) {
      _addError('Connection failed: $e');
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _addOutput(String text) {
    setState(() {
      _output.add(text);
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addError(String error) {
    setState(() {
      _error = error;
    });
    _addOutput('[ERROR] $error');
  }

  Future<void> _sendCommand(String command) async {
    if (!_isConnected || _session == null) return;

    _addOutput('\$ $command');

    try {
      // Send command with newline
      _session!.stdin.add(utf8.encode('$command\n'));
    } catch (e) {
      _addError('Failed to send command: $e');
    }

    _commandController.clear();
  }

  Future<void> _handleSpecialKey(RawKeyEvent event) async {
    if (!_isConnected || _session == null) return;

    // Handle special keys
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        // Enter key is handled by the TextField onSubmitted
        return;
      } else if (key == LogicalKeyboardKey.control) {
        // Ctrl+C
        if (event.data.logicalKey == LogicalKeyboardKey.keyC) {
          _session!.stdin.add(utf8.encode('\x03')); // SIGINT
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        _session!.stdin.add(utf8.encode('\x1b[A')); // Up arrow
      } else if (key == LogicalKeyboardKey.arrowDown) {
        _session!.stdin.add(utf8.encode('\x1b[B')); // Down arrow
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        _session!.stdin.add(utf8.encode('\x1b[D')); // Left arrow
      } else if (key == LogicalKeyboardKey.arrowRight) {
        _session!.stdin.add(utf8.encode('\x1b[C')); // Right arrow
      } else if (key == LogicalKeyboardKey.tab) {
        _session!.stdin.add(utf8.encode('\t')); // Tab
      }
    }
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
                      _output.clear();
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
                        : Icon(Icons.error, size: 16, color: Colors.white),
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

          // Terminal output
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: _output.isEmpty
                  ? Center(
                      child: Text(
                        _isConnecting ? 'Connecting...' : 'Disconnected',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _output.length,
                      itemBuilder: (context, index) {
                        final line = _output[index];
                        return Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: line.contains('[ERROR]') ? Colors.red : Colors.green,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Command input
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text(
                  '\$ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    child: TextField(
                      controller: _commandController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: _isConnected ? 'Type a command...' : 'Not connected',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      enabled: _isConnected,
                      onSubmitted: _isConnected ? _sendCommand : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
