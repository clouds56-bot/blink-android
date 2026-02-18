import 'package:flutter/material.dart';
import '../models/ssh_connection.dart';

class TerminalScreen extends StatefulWidget {
  final SSHConnection connection;

  const TerminalScreen({super.key, required this.connection});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  bool _isConnected = false;
  final List<String> _output = [];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    // TODO: Implement SSH connection using dartssh2
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isConnected = true;
      _output.addAll([
        'Connecting to ${widget.connection.username}@${widget.connection.host}:${widget.connection.port}...',
        'SSH connection established',
        '',
        'Welcome to Blink Android',
        'Terminal implementation in progress...',
        '',
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              // TODO: Open file explorer
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _output.length,
                itemBuilder: (context, index) {
                  return Text(
                    _output[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
          ),
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
                  ),
                ),
                Expanded(
                  child: TextField(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type a command...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (command) {
                      if (command.isNotEmpty) {
                        setState(() {
                          _output.add('\$ $command');
                          _output.add('Command execution not implemented yet');
                          _output.add('');
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
