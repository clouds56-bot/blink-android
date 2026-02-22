import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ssh_connection.dart';

class ConnectionService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<SSHConnection> _connections = [];
  bool _isLoading = false;

  List<SSHConnection> get connections => _connections;
  bool get isLoading => _isLoading;

  List<SSHConnection> get favoriteConnections =>
      _connections.where((c) => c.isFavorite).toList()
        ..sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

  List<SSHConnection> get recentConnections =>
      _connections
          .where((c) => !c.isFavorite)
          .toList()
        ..sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

  ConnectionService() {
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = prefs.getString('connections');

      if (connectionsJson != null) {
        final List<dynamic> decoded = json.decode(connectionsJson);
        _connections = decoded
            .map((json) => SSHConnection.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = json.encode(
        _connections.map((c) => c.toJson()).toList(),
      );
      await prefs.setString('connections', connectionsJson);
    } catch (e) {
      debugPrint('Error saving connections: $e');
    }
  }

  Future<void> addConnection(SSHConnection connection) async {
    _connections.add(connection);
    await _saveConnections();
    notifyListeners();
  }

  Future<void> updateConnection(SSHConnection connection) async {
    final index = _connections.indexWhere((c) => c.id == connection.id);
    if (index != -1) {
      _connections[index] = connection;
      await _saveConnections();
      notifyListeners();
    }
  }

  Future<void> deleteConnection(String id) async {
    _connections.removeWhere((c) => c.id == id);
    await _saveConnections();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final connection = _connections.firstWhere((c) => c.id == id);
    connection.isFavorite = !connection.isFavorite;
    await _saveConnections();
    notifyListeners();
  }

  Future<void> updateLastConnected(String id) async {
    final connection = _connections.firstWhere((c) => c.id == id);
    connection.lastConnected = DateTime.now();
    await _saveConnections();
    notifyListeners();
  }

  Future<String?> getSavedPassword(String connectionId) async {
    return await _secureStorage.read(key: 'password_$connectionId');
  }

  Future<void> savePassword(String connectionId, String password) async {
    await _secureStorage.write(key: 'password_$connectionId', value: password);
  }

  Future<void> deletePassword(String connectionId) async {
    await _secureStorage.delete(key: 'password_$connectionId');
  }

  Future<String?> getSavedPrivateKey(String connectionId) async {
    return await _secureStorage.read(key: 'privatekey_$connectionId');
  }

  Future<void> savePrivateKey(String connectionId, String privateKey) async {
    await _secureStorage.write(key: 'privatekey_$connectionId', value: privateKey);
  }
}
