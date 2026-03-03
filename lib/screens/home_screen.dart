import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ssh_connection.dart';
import '../services/connection_service.dart';
import 'add_connection_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blink Android'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddConnectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ConnectionService>(
        builder: (context, connectionService, child) {
          if (connectionService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = connectionService.favoriteConnections;
          final recent = connectionService.recentConnections;

          if (favorites.isEmpty && recent.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.terminal,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No connections yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first SSH connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              if (favorites.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Favorites',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...favorites.map((conn) => _buildConnectionTile(context, conn)),
              ],
              if (recent.isNotEmpty) ...[
                if (favorites.isNotEmpty) const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Recent',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...recent.map((conn) => _buildConnectionTile(context, conn)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionTile(BuildContext context, SSHConnection connection) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(connection.username[0].toUpperCase()),
      ),
      title: Text(connection.name),
      subtitle: Text('${connection.username}@${connection.host}:${connection.port}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              connection.isFavorite ? Icons.star : Icons.star_border,
              color: connection.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              context
                  .read<ConnectionService>()
                  .toggleFavorite(connection.id);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddConnectionScreen(connection: connection),
                  ),
                );
              } else if (value == 'delete') {
                _showDeleteDialog(context, connection);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      onTap: () {
        _connectToServer(context, connection);
      },
    );
  }

  void _connectToServer(BuildContext context, SSHConnection connection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TerminalScreen(connection: connection),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SSHConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Delete "${connection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ConnectionService>().deleteConnection(connection.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
