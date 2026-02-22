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
  StreamSubscription<String>? _outputSubscription;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _session?.close();
    _client?.close();
    _commandController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _output.clear();
      _error = '';
    });

    _addOutput('Connecting to ${widget.connection.username}@${widget.connection.host}:${widget.connection.port}...');

    try {
      // Create socket
      final socket = await Socket.connect(
        widget.connection.host,
        widget.connection.port,
        timeout: const Duration(seconds: 15),
      );

      _addOutput('Socket connected, establishing SSH session...');

      // Get password from secure storage
      final connectionService = context.read<ConnectionService>();
      final savedPassword = await connectionService.getSavedPassword(widget.connection.id);

      // Create SSH client
      _client = SSHClient(
        socket,
        username: widget.connection.username,
        onPasswordRequest: () async {
          // Return saved password if available
          return savedPassword;
        },
        onPrivateKeyRequest: () async {
          // Return private key if available
          if (widget.connection.privateKeyContent != null) {
            return SSHKeyPair(
              privateKey: widget.connection.privateKeyContent!,
            );
          }
          return null;
        },
      );

      _addOutput('SSH client created, authenticating...');

      // Authenticate
      await _client!.authenticated;
      _addOutput('Authentication successful!');

      // Create PTY session
      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: 80,
          height: 24,
          term: 'xterm-256color',
        ),
      );

      _addOutput('PTY session created.\n');

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      // Listen for output
      _outputSubscription = _session!.stream.listen(
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

      // Request focus for keyboard
      _focusNode.requestFocus();
    } catch (e) {
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
      _session!.write('$command\n');
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
          _session!.write('\x03'); // SIGINT
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        _session!.write('\x1b[A'); // Up arrow
      } else if (key == LogicalKeyboardKey.arrowDown) {
        _session!.write('\x1b[B'); // Down arrow
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        _session!.write('\x1b[D'); // Left arrow
      } else if (key == LogicalKeyboardKey.arrowRight) {
        _session!.write('\x1b[C'); // Right arrow
      } else if (key == LogicalKeyboardKey.tab) {
        _session!.write('\t'); // Tab
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
