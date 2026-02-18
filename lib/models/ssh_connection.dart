import 'package:uuid/uuid.dart';

class SSHConnection {
  final String id;
  String name;
  String host;
  int port;
  String username;
  String? password;
  String? privateKeyPath;
  String? privateKeyContent; // Stored encrypted
  List<String>? hostKeyFingerprints;
  DateTime lastConnected;
  bool isFavorite;

  SSHConnection({
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.password,
    this.privateKeyPath,
    this.privateKeyContent,
    this.hostKeyFingerprints,
    this.isFavorite = false,
  }) : id = const Uuid().v4(),
       lastConnected = DateTime.now();

  SSHConnection copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKeyPath,
    String? privateKeyContent,
    List<String>? hostKeyFingerprints,
    DateTime? lastConnected,
    bool? isFavorite,
  }) {
    return SSHConnection(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      privateKeyContent: privateKeyContent ?? this.privateKeyContent,
      hostKeyFingerprints: hostKeyFingerprints ?? this.hostKeyFingerprints,
      isFavorite: isFavorite ?? this.isFavorite,
    )..lastConnected = lastConnected ?? this.lastConnected;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'privateKeyPath': privateKeyPath,
      'privateKeyContent': privateKeyContent,
      'hostKeyFingerprints': hostKeyFingerprints,
      'lastConnected': lastConnected.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory SSHConnection.fromJson(Map<String, dynamic> json) {
    return SSHConnection(
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      password: json['password'] as String?,
      privateKeyPath: json['privateKeyPath'] as String?,
      privateKeyContent: json['privateKeyContent'] as String?,
      hostKeyFingerprints: (json['hostKeyFingerprints'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
    )..lastConnected = DateTime.parse(json['lastConnected'] as String);
  }
}
