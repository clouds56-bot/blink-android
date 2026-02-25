import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/ssh_connection.dart';
import '../services/connection_service.dart';

class AddConnectionScreen extends StatefulWidget {
  final SSHConnection? connection;

  const AddConnectionScreen({super.key, this.connection});

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String _privateKeyContent = '';
  bool _savePassword = true;

  @override
  void initState() {
    super.initState();
    final conn = widget.connection;
    _nameController = TextEditingController(text: conn?.name ?? '');
    _hostController = TextEditingController(text: conn?.host ?? '');
    _portController = TextEditingController(text: conn?.port.toString() ?? '22');
    _usernameController = TextEditingController(text: conn?.username ?? '');
    _passwordController = TextEditingController(text: '');
    _privateKeyContent = conn?.privateKeyContent ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection == null ? 'Add Connection' : 'Edit Connection'),
        actions: [
          if (widget.connection != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('connection_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'My Server',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('host_field'),
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a host';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('port_field'),
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '22',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a port';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Please enter a valid port';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('username_field'),
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'root',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('password_field'),
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (optional)',
                hintText: '•••••••',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _importPrivateKey,
              icon: const Icon(Icons.key),
              label: const Text('Import Private Key'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (_privateKeyContent.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Private key imported'),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _privateKeyContent = '';
                      });
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveConnection,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                widget.connection == null ? 'Save Connection' : 'Update Connection',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPrivateKey() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'key', 'pem'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _privateKeyContent = String.fromCharCodes(result.files.single.bytes!);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Private key imported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing private key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final connection = SSHConnection(
      name: _nameController.text,
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text,
      privateKeyContent: _privateKeyContent.isEmpty ? null : _privateKeyContent,
    );

    final connectionService = context.read<ConnectionService>();
    final password = _passwordController.text;
    final connectionId = widget.connection?.id ?? connection.id;
    if (widget.connection == null) {
      await connectionService.addConnection(connection);
    }

    // Handle password saving/deleting
    if (_savePassword && password.isNotEmpty) {
      // Save password securely
      connectionService.savePassword(connectionId, password);
    } else if (!_savePassword && widget.connection != null) {
      // New connection, don't save password
      // Password won't be saved
    } else if (!_savePassword && widget.connection != null && password.isEmpty) {
      // Editing, password field cleared and checkbox unchecked
      // Delete saved password
      connectionService.deletePassword(connectionId);
    }

    if (widget.connection != null) {
      final updated = widget.connection!.copyWith(
        name: connection.name,
        host: connection.host,
        port: connection.port,
        username: connection.username,
        privateKeyContent: connection.privateKeyContent,
      );
      await connectionService.updateConnection(updated);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Delete "${widget.connection!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ConnectionService>()
                  .deleteConnection(widget.connection!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
